# CRAW: install, open, edit

Choose your system, paste its install line, and follow any system prompts.
The installer gets all four repos, installs dependencies, and builds the
desktop tools. You do not need to clone or build each repo yourself.

## 1. Install once

### Mac — Terminal

```sh
curl -fsSL https://raw.githubusercontent.com/matthew777777/CinematicRAWStudio-Spec/main/scripts/install.sh | bash
```

The first installation may ask for your Mac password. If Apple asks you to
install developer tools, finish that dialog and run the same line again.
You also get **CRAW Mount** and **CRAW Unmount** in your Applications folder.

### Linux — Terminal

```sh
curl -fsSL https://raw.githubusercontent.com/matthew777777/CinematicRAWStudio-Spec/main/scripts/install.sh | bash
```

Supports the apt, dnf and pacman package managers (Ubuntu/Debian, Fedora,
Arch). Your system may ask for your password to install dependencies.
Mounting uses FUSE 3, with FUSE 2 supported for existing developer builds.
On a headless server, use `craw mount --no-open "take.craw"`.

### Windows 10/11, x64 — PowerShell

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/matthew777777/CinematicRAWStudio-Spec/main/scripts/install.ps1)))
```

Accept the Windows installation prompts. The installer uses WinGet for
Python, Git, CMake, FFmpeg, Android platform-tools, C++ Build Tools, and
WinFsp (the mount driver). If WinGet is missing, install Microsoft's
[App Installer](https://aka.ms/getwinget), then run the same line again.
You also get **CRAW Studio** in the Start menu and **Open with → CRAW Studio**
for `.craw` files.

**After installation, open a new terminal.** This makes the `craw` command
available.

## 2. Open your takes

```sh
craw
```

This opens the browser/editor. Press **Enter** to browse folders, **Space**
to select a take, **G** to adjust the look, and **q** to quit.

Open a specific file or folder:

```sh
craw tui "take.craw"
craw tui "my videos"
```

CRAW-Live and CRAW-Fast are detected automatically. Keep the original
`.craw` files; they are your camera originals.

## 3. Open a take in Resolve

```sh
craw mount "take.craw"
```

A folder opens under `~/CRAW` (your user folder's `CRAW` directory on
Windows). Drag the DNG sequence into Resolve's Media Pool. The files are
read directly from the take; mounting does not create a second video copy.
You can also pass a folder of takes to the same command.

In Resolve:

1. Set the timeline frame rate to the take's recorded rate before adding clips.
2. If sound is separate, import the WAV and place it at the same timeline
   start as the video. The automatic audio synchronization dialog has
   crashed with these takes; use timeline placement.
3. For Bayer CinemaDNG, open **Camera RAW → CinemaDNG** and choose **Clip**
   decoding to start from the recorded white balance and colour metadata.
   RGB/binned recordings are already demosaiced and have different RAW controls.

When finished, close the take in Resolve and run:

```sh
craw unmount
```

This closes all takes opened with `craw mount`. It does not delete your
original recordings. `craw mounts` lists the currently mounted takes.

A take keeps the same folder (`~/CRAW/<take name>`) every time you mount it,
so Resolve relinks its clips after a remount.

### Stabilise in Gyroflow

Takes with motion data show `<take>.gcsv` next to the DNGs (in the mount and
in `craw export` output): the phone's gyroscope and accelerometer on the same
clock as the frames. Open the take's DNG sequence in
[Gyroflow](https://gyroflow.xyz) 1.7 or newer; it picks up the `.gcsv` with
the same name. If the correction turns the wrong way, set *Motion data → IMU
orientation* once — the same setting fits every take from that phone.

## Prefer normal files?

```sh
craw export "take.craw"
```

This writes CinemaDNG frames and a WAV under `~/Movies/CRAW-Exports`.
It uses more disk space, but needs no mount driver. Choose a destination:

```sh
craw export "take.craw" "my export folder"
```

For ProRes, HEVC and other rendered formats, use the editor or:

```sh
craw-tui export -f "take.craw" -F prores422hq -o "my export folder"
```

Available formats depend on the installed FFmpeg build. `craw-tui profiles`
shows them. WAV exports use integer PCM; float audio becomes 24-bit PCM.

## Copy the newest take from your phone

Enable USB debugging on Android, connect the phone and accept its USB
debugging prompt. Record **RAW video** in RawLens, then:

```sh
craw pull --mount
```

The take is copied to `~/Movies/CRAW` and opened for Resolve. `craw pull`
copies it without mounting. Existing copies are never overwritten.

## Help

| Want to… | Type |
|---|---|
| See all commands | `craw --help` |
| Browse/edit | `craw` |
| Open in Resolve | `craw mount "take.craw"` |
| Close mounts | `craw unmount` |
| Save CinemaDNG + sound | `craw export "take.craw"` |
| Check recording details | `craw info "take.craw"` |
| Check for corruption | `craw verify "take.craw"` |
| Open the editor's help | `?` inside the editor |

If a take will not mount, try `craw export "take.craw"`. The mount command
prints the location of its log when something fails. Close the folder in
Resolve or your file browser before unmounting. Containers and restricted
systems may lack access to `/dev/fuse`; exporting still works.

Re-run the install line to update the tools. The installer leaves modified
source checkouts alone and asks you to choose another source folder.

## Local checkout and custom installs

With all repos side by side, run the local installer to use those versions:

```sh
bash scripts/install.sh
```

On Windows, from PowerShell in the Spec repo:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/install.ps1
```

Mac/Linux options: `--no-deps`, `--no-mount`, `--prefix DIR`,
`--source-root DIR`. Windows equivalents: `-NoDeps`, `-NoMount`,
`-Prefix DIR`, `-SourceRoot DIR`. `--no-mount`/`-NoMount` installs the editor
and exporters without a virtual filesystem. No tests run during installation.

The installers build from source, so initial setup can take several minutes.
Platform execution has not yet been verified for these installer changes.

## Make a smaller archive copy

After installing the updated tools:

```sh
craw compact in.craw out.craw
craw verify out.craw
craw mount out.craw
```

This lossless desktop operation preserves original RAW samples, frame metadata,
audio, gyro, shading and other chunks. The original take stays in place. Choose
a new output path; existing files are refused. Frames that do not become smaller
keep their original payload. Open the output in the TUI or export CinemaDNG as
usual. Compact takes decode more slowly than Live v2, and savings vary by scene.
It requires a complete indexed input and an output filesystem supporting hard
links. Recording on the phone continues to use Live v2.
