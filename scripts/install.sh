#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# One installer for macOS and Linux. Does not run tests.
set -euo pipefail
prefix="${CRAW_PREFIX:-$HOME/.local/bin}"
source_root="${CRAW_SOURCE_ROOT:-$HOME/.local/share/craw/src}"
owner="${CRAW_GITHUB_OWNER:-matthew777777}"
ref="${CRAW_REF:-main}"
deps=1; mount_tools=ON; local_source=0; explicit_source=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-deps) deps=0 ;;
        --no-mount) mount_tools=OFF ;;
        --add-to-path|--skip-tests) : ;; # Compatibility; PATH is automatic, tests are opt-in elsewhere.
        --prefix) prefix="${2:?Provide a folder after --prefix}"; shift ;;
        --source-root) source_root="${2:?Provide a folder after --source-root}"; explicit_source=1; shift ;;
        -h|--help) echo 'Install CRAW: install.sh [--no-deps] [--no-mount] [--prefix DIR] [--source-root DIR]'; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
    shift
done
say() { printf '\n%s\n' "$*"; }
fail() { printf '\nCRAW: %s\n' "$*" >&2; exit 1; }
# A local checkout uses its sibling repos without fetching or changing them.
script_file="${BASH_SOURCE[0]:-}"
if [[ -f "$script_file" && "$script_file" != /dev/* ]]; then
    script_dir="$(cd "$(dirname "$script_file")" && pwd)"
    candidate="$(dirname "$(dirname "$script_dir")")"
    if [[ -d "$candidate/CinematicRAWStudio-Encoder" && -d "$candidate/CinematicRAWStudio-Decoder" && -d "$candidate/CinematicRAWStudio-TUI" && -z "${CRAW_SOURCE_ROOT:-}" && $explicit_source == 0 ]]; then
        source_root="$candidate"; local_source=1
    fi
fi
system="$(uname -s)"
[[ "$system" == Darwin || "$system" == Linux ]] || fail 'On Windows, use install.ps1 in PowerShell.'
if [[ "$system" == Darwin ]]; then
    if ! xcode-select -p >/dev/null 2>&1; then
        xcode-select --install || true
        fail 'Finish the Apple developer tools dialog, then run this same install command again.'
    fi
    if [[ $deps == 1 ]]; then
        if ! command -v brew >/dev/null; then
            say 'Installing Homebrew (you may be asked for your Mac password).'
            bootstrap="$(mktemp)"
            curl -fSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$bootstrap"
            [[ -r /dev/tty ]] || fail 'Homebrew setup needs a terminal. Install Homebrew from https://brew.sh, then rerun.'
            /bin/bash "$bootstrap" </dev/tty
            rm -f "$bootstrap"
        fi
        if [[ -x /opt/homebrew/bin/brew ]]; then eval "$(/opt/homebrew/bin/brew shellenv)";
        elif [[ -x /usr/local/bin/brew ]]; then eval "$(/usr/local/bin/brew shellenv)"; fi
        brew install cmake ninja ffmpeg python git
        if [[ "$mount_tools" == ON && ! -e /usr/local/lib/libfuse-t.dylib ]]; then
            brew install --cask macos-fuse-t/cask/fuse-t
        fi
        if ! command -v adb >/dev/null; then brew install --cask android-platform-tools; fi
    fi
elif [[ $deps == 1 ]]; then
    elevate=()
    if [[ "$(id -u)" != 0 ]]; then
        command -v sudo >/dev/null || fail 'sudo is needed to install packages; ask your administrator, or use --no-deps.'
        elevate=(sudo)
    fi
    say 'Installing the tools CRAW needs (your system may ask for your password).'
    if command -v apt-get >/dev/null; then
        "${elevate[@]}" apt-get update
        packages=(build-essential cmake ninja-build git curl ffmpeg python3 adb pkg-config)
        [[ "$mount_tools" == OFF ]] || packages+=(libfuse3-dev fuse3)
        "${elevate[@]}" apt-get install -y "${packages[@]}"
    elif command -v dnf >/dev/null; then
        packages=(gcc-c++ cmake ninja-build git curl python3 android-tools pkgconf-pkg-config)
        [[ "$mount_tools" == OFF ]] || packages+=(fuse3-devel fuse3)
        "${elevate[@]}" dnf install -y "${packages[@]}"
        if ! command -v ffmpeg >/dev/null; then
            "${elevate[@]}" dnf install -y ffmpeg-free
        fi
    elif command -v pacman >/dev/null; then
        packages=(base-devel cmake ninja git curl ffmpeg python android-tools pkgconf)
        [[ "$mount_tools" == OFF ]] || packages+=(fuse3)
        "${elevate[@]}" pacman -S --needed --noconfirm "${packages[@]}"
    else
        fail 'Install CMake, Ninja, a C++20 compiler, Git, Python 3, FFmpeg and FUSE 3 development files with your package manager; rerun with --no-deps.'
    fi
fi
for command in git cmake ninja python3; do command -v "$command" >/dev/null || fail "$command is missing. Rerun without --no-deps."; done
if [[ $local_source == 0 ]]; then
    mkdir -p "$source_root"
    for part in Spec Encoder Decoder TUI; do
        destination="$source_root/CinematicRAWStudio-$part"
        if [[ -e "$destination" ]]; then
            [[ -d "$destination/.git" ]] || fail "$destination already exists and is not a Git checkout. Choose --source-root with another folder."
            [[ -z "$(git -C "$destination" status --porcelain)" ]] || fail "$destination has local changes. Keep them safe and use another --source-root."
            git -C "$destination" fetch origin "$ref" --depth 1
            git -C "$destination" merge --ff-only FETCH_HEAD
        else
            git clone --depth 1 --branch "$ref" "https://github.com/$owner/CinematicRAWStudio-$part.git" "$destination"
        fi
    done
fi
spec="$source_root/CinematicRAWStudio-Spec"
[[ -f "$spec/scripts/desktop/craw.py" ]] || fail 'The downloaded Spec repo does not contain the desktop installer yet. Use the published branch or a local checkout.'
say 'Building CRAW. The first installation takes a few minutes.'
build_log="$HOME/.local/state/CRAW/install.log"
mkdir -p "$(dirname "$build_log")"
: > "$build_log"
mkdir -p "$prefix"
# Separate install build dirs leave developer builds alone.
for part in Encoder Decoder TUI; do
    repo="$source_root/CinematicRAWStudio-$part"
    build="$repo/build-desktop-install"
    options=(-DCRAW_BUILD_TESTS=OFF)
    [[ "$part" != Decoder ]] || options+=(-DCRAW_BUILD_MOUNT="$mount_tools" -DCRAW_REQUIRE_MOUNT="$mount_tools")
    say "Building $part ..."
    cmake -S "$repo" -B "$build" -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$prefix/.." "${options[@]}" >> "$build_log" 2>&1 || fail "Could not configure $part. Details: $build_log"
    case "$part" in
        Encoder) targets=(craw_enc craw_bench) ;;
        Decoder) targets=(craw_dec craw2dng craw_compact); [[ "$mount_tools" == OFF ]] || targets+=(craw_mount) ;;
        TUI) targets=(craw-tui) ;;
    esac
    cmake --build "$build" --parallel "${CRAW_JOBS:-4}" --target "${targets[@]}" >> "$build_log" 2>&1 || fail "Could not build $part. Details: $build_log"
    for binary in "${targets[@]}"; do install -m 755 "$build/$binary" "$prefix/$binary"; done
done
install -m 644 "$spec/scripts/desktop/craw.py" "$prefix/craw.py"
python_path="$(command -v python3)"
# Generate wrappers without shell-interpolating installation paths.
"$python_path" - "$prefix" "$python_path" <<'PY'
import pathlib,shlex,sys
folder=pathlib.Path(sys.argv[1]).resolve()
for name, args in {'craw': [], 'craw-mount': ['mount'], 'craw-unmount': ['unmount'], 'craw-pull': ['pull']}.items():
    wrapper=folder/name
    command=' '.join(shlex.quote(v) for v in [sys.argv[2],str(folder/'craw.py')]+args)
    wrapper.write_text('#!/bin/sh\nexec '+command+' "$@"\n')
    wrapper.chmod(0o755)
# Marked lines are idempotent and quoted for paths containing spaces.
line='export PATH='+shlex.quote(str(folder))+':"$PATH" # Cinematic RAW Studio\n'
profiles=[pathlib.Path.home()/'.profile',pathlib.Path.home()/'.bashrc']
if sys.platform=='darwin': profiles += [pathlib.Path.home()/'.zprofile',pathlib.Path.home()/'.zshrc']
elif 'zsh' in __import__('os').environ.get('SHELL',''): profiles += [pathlib.Path.home()/'.zshrc']
for profile in profiles:
    previous=profile.read_text() if profile.exists() else ''
    previous='\n'.join(s for s in previous.splitlines() if '# Cinematic RAW Studio' not in s)
    profile.write_text(previous+'\n'+line)
config=pathlib.Path.home()/'.local/share/craw/command'
config.parent.mkdir(parents=True,exist_ok=True)
config.write_text(str(folder/'craw')+'\n')
PY
if [[ "$system" == Darwin ]]; then
    mkdir -p "$HOME/Applications"
    for kind in Mount Unmount; do
        app="$HOME/Applications/CRAW $kind.app"
        # osacompile replaces only the generated app, not user media.
        osacompile -o "$app" "$spec/scripts/macos/CRAW${kind}.applescript"
    done
    plist="$HOME/Applications/CRAW Mount.app/Contents/Info.plist"
    plutil -replace CFBundleIdentifier -string org.cinematicrawstudio.crawmount "$plist"
    plutil -replace CFBundleDocumentTypes -json '[{"CFBundleTypeName":"CRAW take","CFBundleTypeRole":"Viewer","CFBundleTypeExtensions":["craw","CRAW"],"LSHandlerRank":"Alternate"}]' "$plist"
    codesign --force --sign - "$HOME/Applications/CRAW Mount.app" >/dev/null 2>&1 || true
else
    mkdir -p "$HOME/.local/share/applications"
    "$python_path" - "$prefix" <<'PY'
from pathlib import Path
import sys
# Desktop Exec fields use double quotes and their own escape syntax.
exe=str(Path(sys.argv[1]).resolve()/'craw').replace('\\','\\\\').replace('"','\\"').replace('`','\\`').replace('$','\\$').replace('%','%%')
(Path.home()/'.local/share/applications/craw.desktop').write_text('[Desktop Entry]\nType=Application\nName=CRAW Studio\nComment=Browse and edit RAW video\nExec="'+exe+'" tui\nTerminal=true\nCategories=AudioVideo;Video;\n')
PY
fi
say "Installed. Open a new terminal, then type: craw"
printf '  craw tui                  Browse and edit takes\n  craw mount "take.craw"    Open a take for Resolve\n  craw unmount              Close mounted takes\n  craw export "take.craw"   Save CinemaDNG and audio\n  craw pull --mount         Copy and open the newest phone take\n'
printf '\nUse it in this terminal now: "%s/craw"\n' "$prefix"
