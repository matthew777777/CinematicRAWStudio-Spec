# Desktop installer notes

The public instructions are in [GETTING_STARTED.md](../GETTING_STARTED.md).
`install.sh` handles macOS and apt/dnf/pacman Linux; `install.ps1` handles
Windows 10/11 x64. Both fetch all four repos and build Release executables.
No tests are run by the installers. No installer execution or platform tests
were performed for this change, at the user's request.

## Publication

The curl/PowerShell download commands point to **main on GitHub**. Publish
all four repositories' installer-related commits before advertising those
commands. A local commit alone does not update the download URLs. For
unpublished work, run the local installer with the repos side by side.

The scripts respect modified source checkouts: a local invocation uses its
sibling repositories as-is; managed downloaded checkouts must be clean and
update with a fast-forward only. No reset, clean, or force checkout is used.
Installers do not delete recordings or mount roots. Re-running replaces only
installed tools, launcher wrappers, menu entries and CRAW-marked PATH lines.
Unmount removes only empty mount directories and CRAW's own state records.

## Layout and options

| | Mac/Linux | Windows |
|---|---|---|
| Executables | `~/.local/bin` | `%LOCALAPPDATA%\CRAW\bin` |
| Downloaded repos | `~/.local/share/craw/src` | `%LOCALAPPDATA%\CRAW\src` |
| Mounts | `~/CRAW` | `%USERPROFILE%\CRAW` |
| Mount state/logs | `~/.local/state/CRAW` | `%LOCALAPPDATA%\CRAW` |
| Exports | `~/Movies/CRAW-Exports` | `%USERPROFILE%\Movies\CRAW-Exports` |

POSIX options: `--no-deps`, `--no-mount`, `--prefix DIR`, `--source-root DIR`.
Environment overrides: `CRAW_PREFIX`, `CRAW_SOURCE_ROOT`, `CRAW_GITHUB_OWNER`,
`CRAW_REF`, `CRAW_JOBS`. `PREFIX` is also accepted by the legacy Mac entry point.
Windows options: `-NoDeps`, `-NoMount`, `-Prefix DIR`, `-SourceRoot DIR`,
`-Owner NAME`, `-Ref BRANCH`. `CRAW_MOUNT_ROOT` overrides the mount root on
all platforms. The launcher uses Python's standard library only.

Mount support is required by default. CMake reports a specific dependency
error if it cannot build `craw_mount`; use the no-mount option for TUI/export
only. Encoder and decoder CMake installs now include command-line programs,
not just libraries. TUI supports `CRAW_BUILD_TESTS=OFF` like the other repos.

## Platform implementation

- Mac: Homebrew and Apple's command-line tools; fuse-t avoids a kernel
  extension. First-time Apple tools installation requires finishing Apple's
  dialog and rerunning the command. GUI apps resolve the installed launcher
  through `~/.local/share/craw/command`, including custom prefixes.
- Linux: prefer FUSE 3; retain FUSE 2 compatibility for developer builds.
  Do not install FUSE 2 in a way that replaces a desktop's FUSE 3 packages.
  Linux does not receive the macOS-only `volname` mount option.
- Windows: VS 2022 C++ workload, WinFsp SDK/runtime, Python 3.13, CMake,
  Git, FFmpeg and platform-tools through WinGet. Builds x64 and copies the
  matching WinFsp DLL beside `craw_mount.exe`. Native FFmpeg subprocesses
  use `CreateProcessW` and binary pipes instead of POSIX shell quoting.
- `craw mount` uses foreground mount children detached from the terminal,
  waits for DNGs before reporting readiness, and records one PID/path per
  take. On Windows, unmount filters the recorded PID by executable name.
  Unmounting is read-only and does not remove source takes or exported data.

References used: [FUSE 3 callbacks](https://libfuse.github.io/doxygen/structfuse__operations.html),
[WinFsp directory mount behavior](https://github.com/winfsp/winfsp/wiki/Frequently-Asked-Questions),
[WinFsp SDK installation](https://winfsp.dev/rel/),
[Microsoft C++ installer parameters](https://learn.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio).
