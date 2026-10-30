# Cinematic RAW Studio (.CRAW) — Roadmap

| # | Milestone | Status |
|---|-----------|--------|
| 1 | Repos (Spec / Encoder / Decoder), Apache-2.0, C++20, CMake, NDK arm64 + armv7 builds, device harness | done |
| 2 | Python reference + golden vectors; real-footage benchmark | reference done; reproducible CRAW/JPEG XL comparison: [BENCHMARKS.md](BENCHMARKS.md) |
| 3 | Spec v0.2: block-adaptive Rice (per-pixel adaptive v0.1 was serial-bound on phones) | done, draft |
| 4 | C++ encoder / clean-room decoder bit-exact vs reference | done |
| 5 | Speed: NEON extract/MED/block sums, quad code-word puts, parallel CRC, zero-copy commit, big-core pinning, MT decode | done for this device (numbers below) |
| 6 | RawLens integration: CRS replaced by .CRAW (JNI, recorder, burst, reader), on-device round-trip test | done; short Camera2 tests reported in RawLens; sustained full recorder acceptance pending |
| 7 | DaVinci Resolve: `craw_mount` (fuse-t CinemaDNG mount) + `craw2dng` | done; not yet tried inside Resolve itself |
| 8 | LSHD chunk from recorder, F32 container support | done; current RawLens audio capture is PCM16 |
| 9 | Freeze v1.0 after compatibility review and reproducible performance/size gates | pending; IDs 1–4 already assigned, no future rANS ID allocated |

Current codec registry, evidence limits and reproduction instructions:
[BENCHMARKS.md](BENCHMARKS.md). IDs 1/2/3/4 mean Fast/Live v1/Live v2/Compact.
The next priority is validating these implementations, before adding a codec.

## Historical throughput reports: MT6878, 12-bit 4080×3060

These are historical reported codec/app-path throughput, not a sustained
recording acceptance result. The original reproducible harness output for
these exact rows is not attached. Do not combine them with the early synthetic
10-bit device JSONs or the new comparison as if they measured one configuration.

| path | MPix/s | fps 4080×3060 | fps UHD |
|------|--------|---------------|---------|
| craw_bench, 8 threads, intra-frame | ~650 | ~52 | ~78 |
| RawLens JNI, 4 frame workers, incl. storage | 504 | 40.4 | 60.7 |
| RawLens JNI, 8 frame workers, incl. storage | 539 | 43.2 | 65.0 |
| + quad puts, fast-core pinning, 6 workers | 653–700 | 52–56 | 79–84 |
| decode (RawLens JNI, all cores) | 256–298 | — | — |

The old “4K 12-bit ≥60 fps” statement extrapolated UHD pixel throughput;
it did not demonstrate a sustained camera-to-storage recording at that rate.
Full 4080×3060 @60 requires about 749 MPix/s before recorder overhead.
Camera-advertised durations and observed short-run cadence can differ; verify
actual timestamps and losses in a sustained recording before claiming a mode.

## Audio (phase 6)
The format supports F32 audio as `AUDI` format 2 as well as PCM16/PCM24.
Current RawLens recording uses PCM16; format support does not imply float
capture in the app. Float storage does not prevent microphone/ADC clipping.
WAV export and Broadcast WAV timecode are tested separately from capture.

## Ship gates
- bit-exact round trip on every vector and every recorded test clip
- size ≤ JPEG XL lossless (effort 1–3) on the same frames, reporting each
  CRAW codec and both Bayer/CFA-plane JPEG XL layouts separately; do not
  declare a global pass from a narrow corpus
- device_bench: no regression > 5 % throughput, none in ratio
- sustained phone codec loops and end-to-end recorder acceptance are separate
  gates; neither host speed nor a short encode benchmark substitutes for them
