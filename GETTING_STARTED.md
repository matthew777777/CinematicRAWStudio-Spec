# Getting started — from the phone to DaVinci Resolve (macOS)

This guide takes a RAW video recorded in **RawLens** (`.craw`) to a DaVinci
Resolve timeline, losslessly, without converting or copying frames.

> Platforms: **macOS 14+ on Apple silicon or Intel is complete and tested.**
> Linux and Windows support is in progress (see the bottom of this page).

```
 Phone (RawLens)            Mac                                   DaVinci Resolve
 ───────────────            ───                                   ───────────────
 record RAW video  ──USB──▶ craw-pull  ─▶ ~/Movies/CRAW/*.craw
                                          │
                            CRAW Mount ◀──┘ (double-click / drop)
                                          │
                            ~/CRAW/<take>/<take>_000000.dng …  ─▶ Media Pool
                                          <take>.wav               (CinemaDNG clip)
```

---

## 1. One-time setup (≈10 minutes)

You need: macOS, an internet connection, and the four repos side by side, e.g.
`~/CinematicRAWStudio-Spec`, `-Encoder`, `-Decoder`, `-TUI`.

1. **Command Line Tools** (compilers), if you don't have them:
   ```
   xcode-select --install
   ```
2. **Homebrew** if you don't have it: see <https://brew.sh>.
3. **Run the installer** (installs cmake, ninja, ffmpeg and fuse-t through
   Homebrew, builds everything in Release, runs the self-tests, installs the
   tools and the two helper apps):
   ```
   ~/CinematicRAWStudio-Spec/scripts/install-macos.sh --add-to-path
   ```
   Open a new Terminal window afterwards so `~/.local/bin` is on your PATH.

   - **fuse-t** is a FUSE implementation for macOS that needs **no kernel
     extension** and no security changes. The installer asks Homebrew for
     `macos-fuse-t/cask/fuse-t`; macOS may ask for your password once.
   - Re-run the installer any time you update the repos.

4. **Make `.craw` open with CRAW Mount** (optional, recommended): in Finder
   select any `.craw` file → **File ▸ Get Info** → *Open with:* **CRAW Mount**
   → **Change All…**. From then on, double-clicking a take mounts it.

Check everything is in place:
```
craw-mount --help && craw2dng 2>&1 | head -1 && craw-tui profiles
```

---

## 2. Get takes from the phone

RawLens saves RAW videos to `DCIM/RawLens/` on the phone
(`IMG_<date>_<time>_VID.craw`; offline-merge bursts go to `DCIM/RawLens/Bursts/`).

**USB (adb):** enable *Developer options ▸ USB debugging* on the phone, connect it,
accept the prompt, then:

```
craw-pull                 # newest take  -> ~/Movies/CRAW
craw-pull -n 5            # five newest takes
craw-pull --all           # everything
craw-pull --bursts        # burst takes instead of videos
craw-pull --mount         # pull the newest take and mount it right away
```
Already-copied takes (same size) are skipped. `adb` is found on PATH or in the
Android SDK (`~/Library/Android/sdk/platform-tools`).

**Without adb:** copy the files with any method (Android File Transfer, a
card reader, a network share). They are ordinary files; only the location matters.

---

## 3. Mount a take for DaVinci Resolve (one click)

Any of these does the same thing:

| how | what to do |
|-----|-----------|
| **Double-click** | double-click the `.craw` (after step 1.4), or right-click ▸ *Open With* ▸ **CRAW Mount** |
| **Drag & drop** | drop one or more `.craw` files (or a folder) on **~/Applications/CRAW Mount.app** |
| **Terminal** | `craw-mount --open ~/Movies/CRAW/IMG_…_VID.craw` (add `--resolve` to launch Resolve too; pass a folder to mount every take in it) |

Each take appears as its own folder:

```
~/CRAW/IMG_20261012_155936_020_VID/
    IMG_20261012_155936_020_VID_000000.dng
    IMG_20261012_155936_020_VID_000001.dng
    …
    IMG_20261012_155936_020_VID.wav
```

Nothing is copied: frames are decoded on demand when Resolve reads them
(lossless — the DNG pixels are byte-for-byte the recorded sensor data), with
read-ahead for smooth sequential playback. The `.craw` file must stay where it
is while mounted.

**Unmount** when done (close the project or remove the clips in Resolve first):
- double-click **~/Applications/CRAW Unmount.app**, or
- `craw-unmount` (all takes) / `craw-unmount IMG_…_VID` (one take).

---

## 4. In DaVinci Resolve

1. **Media page** → in the *Media Storage* browser go to your home folder ▸
   **CRAW** ▸ the take's folder. (Tip: right-click ▸ *Add Folder to Favorites* once.)
2. Drag the take's folder (or the DNG sequence it shows as one clip) into the
   **Media Pool**. Resolve recognises it as a **CinemaDNG** clip with the
   recorded frame rate and timecode.
3. **Audio:** if the WAV is not attached automatically, drag
   `<take>.wav` into the Media Pool too, select both clips ▸ right-click ▸
   **Auto Sync Audio ▸ Based on Timecode** (both start at 00:00:00:00), or
   simply place both on the timeline at the start.
4. **Project frame rate:** set *File ▸ Project Settings ▸ Master Settings ▸
   Timeline frame rate* to the take's rate **before** adding clips to a
   timeline (RawLens records 30 fps by default; `craw-tui info -f take.craw`
   shows it).
5. **RAW controls:** *Project Settings ▸ Camera RAW ▸ RAW Profile: CinemaDNG*,
   decode using **Clip** to start from the recorded white balance and colour
   matrices, or **Project** to grade everything the same way. White balance,
   exposure, highlight recovery etc. are then adjustable losslessly in the
   *Camera RAW* panel on the Color page.
6. Lens vignetting is corrected by Resolve from the gain map embedded in each
   DNG (DNG *OpcodeList2 GainMap*), the same correction RawLens measured.

When you deliver, Resolve reads the mounted DNGs like any other media. Keep the
take mounted until the render finishes.

> If Resolve shows *Media offline* after a reboot: the mount went away — mount
> the take again (same path), then *Relink*.

---

## 5. Without Resolve: render or convert in the terminal

**craw-tui** — browse, preview, grade and render to edit-ready files:
```
craw-tui ~/Movies/CRAW
```
Arrow keys + Enter to import takes, `G` grade sliders with live preview,
`c` codec (ProRes 4444/422 HQ, DNxHR HQX, HEVC 10-bit, H.264, AV1, CinemaDNG),
`g` gamut, `t` transfer (Rec.709, S-Log3, LogC3, HLG, PQ…), `a` queue, `v` render,
`?` help. Headless:
```
craw-tui export -f take.craw -F prores4444 -g sgamut3cine -t slog3 -o ~/Movies/Export
```

**craw2dng** — write the CinemaDNG sequence to disk (e.g. to hand to someone
without the tools):
```
craw2dng take.craw ~/Movies/DNG          # -> ~/Movies/DNG/<take>/*.dng + .wav
craw2dng take.craw out --frames 0-99     # a range
```

---

## Troubleshooting

| symptom | fix |
|---------|-----|
| `fuse-t is not installed` | `brew install --cask macos-fuse-t/cask/fuse-t`, then retry |
| `command not found: craw-mount` | open a new Terminal, or `export PATH="$HOME/.local/bin:$PATH"` |
| CRAW Mount.app does nothing | run `craw-mount --open file.craw` in Terminal to see the error |
| `no phone connected over adb` | USB debugging on, accept the RSA prompt, `adb devices` must list the phone |
| `no .craw takes in …/DCIM/RawLens` | record a **RAW** video (Direct Log takes are `.mp4`, not `.craw`) |
| Resolve: clip plays slowly | the first pass decodes on demand; generate optimized media or render cache, or convert with `craw2dng` to a fast disk |
| `could not unmount` | close the clips in Resolve/Finder, then `craw-unmount` again |
| a `.craw` from a crash (no end marker) | it still mounts: readers recover every complete frame |

Command reference: `craw-mount --help`, `craw-pull --help`, `craw-unmount`,
`craw2dng`, `craw_dec info|verify|frames`, `craw-tui --help`.

---

## Other platforms (in progress)

- **Linux:** the tools build with GCC/Clang; mounting uses libfuse 2
  (`libfuse-dev`). Installer and helper scripts are being added.
- **Windows:** mounting via WinFsp; MSVC build and a PowerShell installer are
  being added.
- **macOS FSKit mount** (macOS 26+, no FUSE at all): `CinematicRAWStudio-Decoder/tools/fskit`.
  Needs an Apple Development certificate and provisioning profile; see its README.
