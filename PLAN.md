# Cinematic RAW Studio (.CRAW) — Roadmap

| # | Milestone | Status |
|---|-----------|--------|
| 1 | Repos (Spec / Encoder / Decoder), Apache-2.0, C++20, CMake, NDK arm64 + armv7 builds, device harness | done |
| 2 | Python reference + golden vectors; real-footage benchmark vs .mcraw type 7 | done: −23 % (binned) / −14 % (full-res) vs type 7; JPEG XL comparison pending (cjxl not installed) |
| 3 | Spec v0.2: block-adaptive Rice (per-pixel adaptive v0.1 was serial-bound on phones) | done, draft |
| 4 | C++ encoder / clean-room decoder bit-exact vs reference | done |
| 5 | Speed: NEON extract/MED/block sums, quad code-word puts, parallel CRC, zero-copy commit, big-core pinning, MT decode | done for this device (numbers below) |
| 6 | RawLens integration: CRS replaced by .CRAW (JNI, recorder, burst, reader), on-device round-trip test | done; real Camera2 recording run pending |
| 7 | DaVinci Resolve: `craw_mount` (fuse-t CinemaDNG mount) + `craw2dng` | done; not yet tried inside Resolve itself |
| 8 | LSHD chunk from recorder, F32 audio | done |
| 9 | CRAW-Max (rANS, codec id 2), run mode, THMB, spec v1.0 | |

## Measured on MT6878 (Xiaomi 25080RABDG), 12-bit 4080×3060

| path | MPix/s | fps 4080×3060 | fps UHD |
|------|--------|---------------|---------|
| craw_bench, 8 threads, intra-frame | ~650 | ~52 | ~78 |
| RawLens JNI, 4 frame workers, incl. storage | 504 | 40.4 | 60.7 |
| RawLens JNI, 8 frame workers, incl. storage | 539 | 43.2 | 65.0 |
| + quad puts, fast-core pinning, 6 workers | 653–700 | 52–56 | 79–84 |
| decode (RawLens JNI, all cores) | 256–298 | — | — |

Camera limit on this phone: RAW_SENSOR minimum frame duration is 50 ms at
every advertised size (20 fps; RawLens achieves 30 in practice), so the
encoder already exceeds what this sensor delivers.

Goal "4K 12-bit ≥ 60 fps": met for UHD 3840×2160 on the app path. Full
4080×3060 @ 60 needs 749 MPix/s and ~485 MB/s sustained storage (device
measures ~563 MB/s with fsync), so it is compute- and near storage-bound.
Next levers: thread pinning to big cores, NEON bit emission, decoder threads.

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
