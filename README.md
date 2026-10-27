# Cinematic RAW Studio (.CRAW)

A lossless RAW video format for phone cameras — Bayer frames, 32-bit float
audio, gyro/accelerometer, lens distortion & intrinsics, and lens-shading
(vignetting) maps — with an open encoder, decoder and tools that take it into
DaVinci Resolve and other editors. Apache-2.0.

**New here? → [GETTING_STARTED.md](GETTING_STARTED.md)** (phone → Mac → Resolve in three steps).

## Repositories

| repo | what it is |
|------|-----------|
| **CinematicRAWStudio-Spec** (this) | format spec, Python reference, golden vectors, device benchmark harness, installers and helper scripts |
| [CinematicRAWStudio-Encoder](../CinematicRAWStudio-Encoder) | C++20 encoder + streaming writer (used by RawLens on Android), `craw_enc`, `craw_bench` |
| [CinematicRAWStudio-Decoder](../CinematicRAWStudio-Decoder) | C++20 decoder + reader, `craw_dec`, `craw2dng`, `craw_mount`, FSKit module |
| [CinematicRAWStudio-TUI](../CinematicRAWStudio-TUI) | `craw-tui`: terminal browser, grading and renderer (ProRes, DNxHR, HEVC, H.264, AV1, CinemaDNG) |
| RawLens (Android app) | records `.craw` via the encoder (GPL-3.0-or-later app; the CRAW libraries are Apache-2.0) |

## One-command install (macOS)

```
scripts/install-macos.sh --add-to-path
```
Installs dependencies (Homebrew: cmake, ninja, ffmpeg, fuse-t), builds all
repos in Release, runs the self-tests, installs to `~/.local/bin`:

| tool | purpose |
|------|---------|
| `craw-pull` | copy takes from the phone over adb (`--mount` to mount them) |
| `craw-mount` / `craw-unmount` | mount takes as CinemaDNG folders under `~/CRAW` for Resolve |
| `CRAW Mount.app` / `CRAW Unmount.app` | the same as one-click apps (double-click / drag & drop / *Open With*) |
| `craw-tui` | browse, preview, grade, render |
| `craw2dng` | write CinemaDNG + WAV to disk |
| `craw_dec` | inspect / verify / dump frames |
| `craw_enc` | encode raw uint16 frames into a take (testing, pipelines) |

## Format at a glance

- Chunked container (header, META JSON, FRAM, AUDI, IMU_, LSHD, THMB, INDX,
  trailer), CRC32C on every chunk and every frame, crash-recoverable.
- Codec **CRAW-Fast** (v0.2): four CFA planes with green-difference
  prediction, MED predictor, block-adaptive Golomb-Rice (16-sample blocks,
  causal parameter — no side information), 128x128 independent tiles.
- Measured: 3.6–5.0 bits/pixel on real phone footage (15–20 % smaller than
  MotionCam type 7); encode 650–700 MPix/s on a MediaTek MT6878 phone
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
