#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Friendly desktop entry point. Python standard library only."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time

BIN = Path(__file__).resolve().parent
ROOT = Path(os.environ.get('CRAW_MOUNT_ROOT', str(Path.home() / 'CRAW'))).expanduser().absolute()
STATE = Path(os.environ.get('LOCALAPPDATA', str(Path.home() / '.local' / 'state'))) / 'CRAW'
WINDOWS = os.name == 'nt'


def tool(name):
    candidate = BIN / (name + ('.exe' if WINDOWS else ''))
    found = str(candidate) if candidate.is_file() else shutil.which(name)
    if not found:
        raise RuntimeError(f'{name} is missing. Run the CRAW installer again.')
    return found


def run(args):
    subprocess.run([str(a) for a in args], check=True)


def reveal(path):
    if WINDOWS:
        os.startfile(str(path))
    elif sys.platform == 'darwin':
        run(['open', path])
    elif shutil.which('xdg-open'):
        run(['xdg-open', path])
    else:
        print(path)


def records():
    if not STATE.exists():
        return []
    result = []
    for file in STATE.glob('mount-*.json'):
        try:
            result.append((file, json.loads(file.read_text(encoding='utf-8'))))
        except (ValueError, OSError):
            continue
    return result


def mounted(path):
    return path.is_dir() and (os.path.ismount(path) or any(path.glob('*.dng')))


def forget_stale_mounts():
    """Drop records of mounts that ended without craw unmount (Finder eject,
    reboot, crash) and their empty folders, so they never block a path."""
    for file, entry in records():
        path = Path(entry['mount'])
        if mounted(path):
            continue
        if path.exists() and not os.path.ismount(path):
            try:
                path.rmdir()  # only if empty: never delete the user's files
            except OSError:
                pass
        file.unlink(missing_ok=True)


def folder_free(path, take):
    """True when `path` can host `take`: missing, or an empty unmounted folder
    no other live record claims."""
    for _, entry in records():
        if entry['mount'] == str(path) and entry['take'] != str(take):
            return False
    if not path.exists():
        return True
    if os.path.ismount(path) or not path.is_dir():
        return False
    return not any(path.iterdir())


def mount_take(take, open_folder=True):
    take = Path(take).expanduser().resolve(strict=True)
    if not take.is_file() or take.suffix.lower() != '.craw':
        raise RuntimeError(f'Choose a .craw file: {take}')
    for _, entry in records():
        if entry['take'] == str(take) and mounted(Path(entry['mount'])):
            print('Already open:', entry['mount'])
            if open_folder:
                reveal(entry['mount'])
            return
    ROOT.mkdir(parents=True, exist_ok=True)
    STATE.mkdir(parents=True, exist_ok=True)
    forget_stale_mounts()
    key = hashlib.sha256(str(take).encode()).hexdigest()[:12]
    stem = re.sub(r'[<>:"/\\|?*\x00-\x1f]', '_', take.stem).rstrip(' .')[:100] or 'take'
    # The same take always mounts at the same path, so Resolve relinks by
    # itself after an unmount/remount: ~/CRAW/<take name> unless another take
    # holds that folder or it has the user's own files; then a name derived
    # from the take's path, which is just as stable.
    destination = ROOT / stem
    if not folder_free(destination, take):
        destination = ROOT / (stem + '-' + key)
    if not folder_free(destination, take):
        raise RuntimeError(f'Folder already in use: {destination}. Unmount it first or choose another CRAW_MOUNT_ROOT.')
    # WinFsp creates/removes its directory mount point itself.
    if not WINDOWS:
        destination.mkdir(exist_ok=True)  # an empty leftover folder is reused
    log_path = STATE / ('mount-' + key + '.log')
    kwargs = {'stdin': subprocess.DEVNULL}
    if WINDOWS:
        kwargs['creationflags'] = subprocess.CREATE_NEW_PROCESS_GROUP | subprocess.DETACHED_PROCESS
    else:
        kwargs['start_new_session'] = True
    with log_path.open('wb') as log:
        child = subprocess.Popen([tool('craw_mount'), str(destination), str(take), '--flat', '-f'],
                                 stdout=log, stderr=log, **kwargs)
    entry = {'take': str(take), 'mount': str(destination), 'pid': child.pid, 'log': str(log_path)}
    state_file = STATE / ('mount-' + key + '.json')
    temp = state_file.with_suffix('.tmp')
    temp.write_text(json.dumps(entry), encoding='utf-8')
    temp.replace(state_file)
    try:
        for _ in range(150):
            if mounted(destination):
                print('Ready for Resolve:', destination)
                if open_folder:
                    reveal(destination)
                return
            if child.poll() is not None:
                break
            time.sleep(0.2)
    except KeyboardInterrupt:
        if child.poll() is None:
            child.terminate()
        raise
    if child.poll() is None:
        child.terminate()
        try:
            child.wait(timeout=5)
        except subprocess.TimeoutExpired:
            pass
    if not WINDOWS and destination.exists() and not os.path.ismount(destination):
        try:
            destination.rmdir()
        except OSError:
            pass
    if not mounted(destination):
        state_file.unlink(missing_ok=True)
    raise RuntimeError(f'Could not mount this take. Details: {log_path}\nTry: craw export "{take}"')


def unmount(name):
    selected = [(f, e) for f, e in records() if name in ('all', e['take'], e['mount'], Path(e['mount']).name, Path(e['take']).name)]
    if not selected:
        print('No matching CRAW mounts.')
        return
    failed = []
    for file, entry in selected:
        path = Path(entry['mount'])
        if mounted(path):
            if WINDOWS:
                # Stop the tracked read-only mount; WinFsp removes its mount
                # point when the process exits. Never terminate by name alone.
                pid = int(entry['pid'])
                result = subprocess.run(['taskkill', '/F', '/PID', str(pid), '/FI', 'IMAGENAME eq craw_mount.exe'],
                                        capture_output=True, text=True)
            else:
                program = 'umount' if sys.platform == 'darwin' else (shutil.which('fusermount3') or shutil.which('fusermount') or 'umount')
                command = [program, str(path)] if Path(program).name == 'umount' else [program, '-u', str(path)]
                result = subprocess.run(command, capture_output=True, text=True)
            for _ in range(25):
                if not mounted(path):
                    break
                time.sleep(0.2)
            if mounted(path):
                failed.append(str(path))
                print('Close this folder in Resolve or your file browser, then retry:', path, file=sys.stderr)
                continue
        # Never recursively delete a user's folder or anything inside a mount.
        if path.exists():
            try:
                path.rmdir()
            except OSError:
                pass
        file.unlink(missing_ok=True)
        print('Closed:', path)
    if failed:
        raise RuntimeError('Some takes are still mounted.')


def pull(mount_after):
    adb = shutil.which('adb')
    if not adb:
        raise RuntimeError('Android platform-tools is missing. Install adb, then run craw pull again.')
    remote = '/sdcard/DCIM/RawLens'
    result = subprocess.run([adb, 'shell', 'ls', '-t', remote], check=True, capture_output=True, text=True)
    names = [s.rstrip('\r') for s in result.stdout.splitlines() if s.lower().endswith('.craw')]
    if not names:
        raise RuntimeError('No takes found. Record a RAW video in RawLens first.')
    name = names[0]
    if Path(name).name != name or '/' in name or '\\' in name:
        raise RuntimeError('Unexpected filename returned by the phone.')
    output = Path.home() / 'Movies' / 'CRAW'
    output.mkdir(parents=True, exist_ok=True)
    destination = output / name
    if destination.exists():
        raise RuntimeError(f'This take is already here: {destination}\nOpen it with: craw mount "{destination}"')
    partial = destination.with_suffix('.craw.partial')
    run([adb, 'pull', remote + '/' + name, partial])
    partial.replace(destination)
    print('Copied:', destination)
    if mount_after:
        mount_take(destination)


def main():
    parser = argparse.ArgumentParser(description='CRAW: open, edit and export your RAW video.')
    commands = parser.add_subparsers(dest='command')
    p = commands.add_parser('tui', help='Open the browser and editor (also the default).')
    p.add_argument('path', nargs='?', default=str(Path.home() / 'Movies' / 'CRAW'))
    p = commands.add_parser('mount', help='Open a take as a CinemaDNG folder for Resolve.')
    p.add_argument('take', nargs='+')
    p.add_argument('--open', action='store_true', help=argparse.SUPPRESS)
    p.add_argument('--no-open', action='store_true', help='Do not open the file browser.')
    p = commands.add_parser('unmount', help='Close a mounted take; default: all.')
    p.add_argument('name', nargs='?', default='all')
    p.add_argument('--all', action='store_true', help=argparse.SUPPRESS)
    p = commands.add_parser('export', help='Save CinemaDNG frames and WAV to a normal folder.')
    p.add_argument('take')
    p.add_argument('folder', nargs='?', default=str(Path.home() / 'Movies' / 'CRAW-Exports'))
    for name in ('info', 'verify'):
        p = commands.add_parser(name, help='Show take details.' if name == 'info' else 'Check a take for corruption.')
        p.add_argument('take')
    p = commands.add_parser('pull', help='Copy the newest take from your USB-connected Android phone.')
    p.add_argument('--mount', action='store_true')
    commands.add_parser('mounts', help='List takes opened by craw mount.')
    args = parser.parse_args()
    if args.command in (None, 'tui'):
        path = Path(getattr(args, 'path', str(Path.home() / 'Movies' / 'CRAW'))).expanduser()
        if args.command is None or str(path) == str(Path.home() / 'Movies' / 'CRAW'):
            path.mkdir(parents=True, exist_ok=True)
        run([tool('craw-tui'), path])
    elif args.command == 'mount':
        for name in args.take:
            path = Path(name).expanduser()
            if path.is_dir():
                takes = sorted(list(path.glob('*.craw')) + list(path.glob('*/*.craw')))
                if not takes:
                    raise RuntimeError(f'No .craw takes found in {path}.')
                for take in takes:
                    mount_take(take, not args.no_open)
            else:
                mount_take(path, not args.no_open)
    elif args.command == 'unmount':
        unmount('all' if args.all else args.name)
    elif args.command == 'export':
        run([tool('craw2dng'), Path(args.take).expanduser().resolve(strict=True), Path(args.folder).expanduser()])
    elif args.command == 'info':
        run([tool('craw-tui'), 'info', '-f', Path(args.take).expanduser().resolve(strict=True)])
    elif args.command == 'verify':
        run([tool('craw_dec'), 'verify', Path(args.take).expanduser().resolve(strict=True)])
    elif args.command == 'pull':
        pull(args.mount)
    elif args.command == 'mounts':
        active = [entry['mount'] for _, entry in records() if mounted(Path(entry['mount']))]
        print('\n'.join(active) if active else 'No CRAW takes are mounted.')


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(130)
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        print('CRAW:', error, file=sys.stderr)
        sys.exit(1)
