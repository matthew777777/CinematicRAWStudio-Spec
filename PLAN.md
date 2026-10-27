# Cinematic RAW Studio (.CRAW) — Roadmap

| # | Milestone | Status |
|---|-----------|--------|
| 1 | Repos (Spec / Encoder / Decoder), Apache-2.0, C++20, CMake, NDK arm64 builds, device harness | done |
| 2 | Python reference codec + golden vectors; benchmark on real phone RAW vs JPEG XL and .mcraw type 7 | reference done; **needs real frames** |
| 3 | Spec v0.9 freeze | |
| 4 | C++ encoder / clean-room decoder bit-exact vs reference | done (scalar) |
| 5 | Speed: NEON + branchless k/bit I/O, target ≥ 374 MPix/s sustained (4080×3060@30) on big cores; fuzzing in CI | next |
| 6 | Android Camera2 capture module + instrumented tests (RAW_SENSOR, audio, gyro/accel, LENS_DISTORTION, intrinsics, pose, lens shading map, noise profile) | |
| 7 | DaVinci Resolve: CinemaDNG virtual mount (macFUSE/FSKit, WinFsp, FUSE) + `craw2dng` / `craw2cinemadng` | |
| 8 | CRAW-Max (rANS, codec id 2), run mode, THMB, spec v1.0 | |

## Audio (phase 6)
Capture `ENCODING_PCM_FLOAT` (no digital clipping) stored as `AUDI` format 2;
PCM16 fallback for devices without float support. Stereo L/R peak meters in
dBFS (−60…+12) instead of a single mono 0..1 peak. BWF WAV export with
timecode from `META.video.timecode_start`.

## Ship gates
- bit-exact round trip on every vector and every recorded test clip
- size ≤ JPEG XL lossless (effort 1–3) and < .mcraw type 7 on the same frames
- device_bench: no regression > 5 % throughput, none in ratio

## Licensing note
The old `MediaCinemaRAW-*` repos are GPL-3.0-only and are a behavioural
reference only; no code was copied into these Apache-2.0 repos.
