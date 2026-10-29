# Cinematic RAW Studio (.CRAW)

A lossless RAW video format for phone cameras — Bayer frames, 32-bit float
audio, gyro/accelerometer, lens distortion & intrinsics, and lens-shading
(vignetting) maps — with an open encoder, decoder and tools that take it into
DaVinci Resolve and other editors. Apache-2.0.

**New here? → [GETTING_STARTED.md](GETTING_STARTED.md)** (Mac, Linux and Windows).

## Repositories

| repo | what it is |
|------|-----------|
| **CinematicRAWStudio-Spec** (this) | format spec, Python reference, golden vectors, device benchmark harness, installers and helper scripts |
| [CinematicRAWStudio-Encoder](../CinematicRAWStudio-Encoder) | C++20 encoder + streaming writer (used by RawLens on Android), `craw_enc`, `craw_bench` |
| [CinematicRAWStudio-Decoder](../CinematicRAWStudio-Decoder) | C++20 decoder + reader, `craw_dec`, `craw2dng`, `craw_mount`, FSKit module |
| [CinematicRAWStudio-TUI](../CinematicRAWStudio-TUI) | `craw-tui`: terminal browser, grading and renderer (ProRes, DNxHR, HEVC, H.264, AV1, CinemaDNG) |
| RawLens (Android app) | records `.craw` via the encoder (GPL-3.0-or-later app; the CRAW libraries are Apache-2.0) |

## Install all desktop tools

**Mac and Linux — paste in Terminal:**

```sh
curl -fsSL https://raw.githubusercontent.com/matthew777777/CinematicRAWStudio-Spec/main/scripts/install.sh | bash
```

**Windows 10/11 x64 — paste in PowerShell:**

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/matthew777777/CinematicRAWStudio-Spec/main/scripts/install.ps1)))
```

Open a new terminal after installation. No separate repo setup is needed.
System dependencies may ask for your password or Windows permission.

```sh
craw                         # browse, preview, grade and render
craw mount "take.craw"       # open a CinemaDNG folder for Resolve
craw unmount                 # close mounted takes
craw export "take.craw"      # save CinemaDNG + WAV as normal files
craw pull --mount            # copy and open the latest phone take
```

[Step-by-step guide](GETTING_STARTED.md) ·
[Installer details for developers](scripts/INSTALLATION.md)

The shared installer fetches and builds Encoder, Decoder and TUI. It installs
`craw`, `craw-tui`, `craw_enc`, `craw_bench`, `craw_dec`, `craw2dng`,
`craw_mount`, and the `craw-mount`/`craw-unmount`/`craw-pull` aliases.
Mac gets Mount/Unmount apps; Linux gets a menu entry; Windows gets a Start
menu shortcut and Open With registration. Installers do not run tests.

## Format at a glance

- Chunked container (header, META JSON, FRAM, AUDI, IMU_, LSHD, THMB, INDX,
  trailer), CRC32C on every chunk, optional raw-frame CRC, crash-recoverable.
- Codec **CRAW-Fast** (v0.2): four CFA planes with green-difference
  prediction, MED predictor, block-adaptive Golomb-Rice (16-sample blocks,
  causal parameter — no side information), 128x128 independent tiles.
- Measured: 3.6–5.0 bits/pixel on real phone footage; encode 650–700 MPix/s
  on a MediaTek MT6878 phone
  (4080x3060 12-bit ≈ 52–56 fps), bit-exact round trip.

Details: [SPEC.md](SPEC.md) · roadmap and measurements: [PLAN.md](PLAN.md).

## Developer workflow

```
python3 -m unittest discover -s tests       # reference codec + container
python3 reference/make_vectors.py           # regenerate golden vectors
ci/device_bench.sh                          # build arm64, run on a phone (adb or DEVICE_SSH), perf gate
```
`ci/device_bench.sh` pushes Release binaries, runs the conformance vectors and
throughput benchmarks on the device, stores JSON under `results/<device>/` and
fails on >5 % throughput or any compression regression versus
`perf_baseline.json` (`UPDATE_BASELINE=1` to accept new numbers).

## License

Apache-2.0 (code). See [NOTICE](NOTICE).
