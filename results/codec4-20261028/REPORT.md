# Codec 4: Desktop Compact — 2026-10-28

**Delivered the desktop fallback. The live goal was not achieved.** Compact is
52,278,526 bytes across the eight real frames: **16.29% smaller than type 7**
and **9.57% smaller than Live v2**. It does not meet the requested 20–22%
aggregate reduction. Daylight frames save 23.0–23.5% against type 7, while the
high-ISO frames save only 10.4–12.8%.

Single-thread means: Live v2 6.33 ms encode / 13.55 ms decode; type 7
5.93 / 14.35 ms; Compact **66.09 / 51.40 ms**. Compact is **10.44x encode**
and **3.79x decode** versus Live v2, well outside both live targets. This is
an offline archival option, with slower scrubbing. These experiments establish
that this implementation misses the goal; they do not prove that a different
entropy coder cannot meet it.

## Measurements

Sizes are decimal MB of frame codec payloads, excluding container overhead.
Every encode/decode uses one thread, with frame CRC disabled for both CRAW
variants to match recording cost. Compact's CLI enables raw CRC on re-encoded
frames and also checks the entire round trip, so its end-to-end cost is higher.
The tiny synthetic container integration test checks ancillary data preservation;
these size totals are not measurements of complete takes with audio/thumbnails.

| Frame | type 7 MB | Live v2 MB | Compact MB | saved vs type 7 | saved vs v2 | v2 enc / dec ms | Compact enc / dec ms | type 7 enc / dec ms |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| s0_100_4080x3060 | 9.187 | 8.726 | 8.006 | 12.86% | 8.25% | 7.60 / 16.29 | 78.18 / 61.90 | 7.41 / 17.39 |
| s0_200_4080x3060 | 9.182 | 8.725 | 8.005 | 12.82% | 8.25% | 7.63 / 16.21 | 77.71 / 62.23 | 7.42 / 17.54 |
| s1_100_4080x3060 | 9.542 | 9.275 | 8.544 | 10.46% | 7.88% | 7.61 / 16.25 | 79.59 / 62.00 | 6.47 / 16.71 |
| s1_200_4080x3060 | 9.545 | 9.272 | 8.542 | 10.51% | 7.88% | 7.64 / 16.26 | 79.48 / 61.74 | 6.47 / 16.78 |
| s2_100_4080x2040 | 6.246 | 5.455 | 4.807 | 23.04% | 11.88% | 5.03 / 10.85 | 53.42 / 40.60 | 4.89 / 11.63 |
| s2_200_4080x2040 | 6.263 | 5.459 | 4.798 | 23.38% | 12.10% | 5.03 / 10.86 | 53.52 / 40.75 | 4.93 / 11.49 |
| s3_100_4080x2040 | 6.235 | 5.439 | 4.774 | 23.44% | 12.24% | 5.06 / 10.87 | 53.31 / 41.00 | 4.95 / 11.64 |
| s3_200_4080x2040 | 6.255 | 5.459 | 4.803 | 23.21% | 12.02% | 5.05 / 10.84 | 53.53 / 41.02 | 4.91 / 11.65 |
| **Total / mean** | **62.455** | **57.811** | **52.279** | **16.29%** | **9.57%** | **6.33 / 13.55** | **66.09 / 51.40** | **5.93 / 14.35** |

The host is Apple arm64, macOS 27.0.1. Compile flags: `-O3
-march=armv8-a+crc -std=c++20` (CMake libraries use the equivalent GNU C++20
mode). The comparison harness warms once, rotates the order of all three codecs
on every repetition, and takes the independent minimum of nine subsequent
encode and decode measurements for each frame. RAW equality is checked after
every decode, outside the timing interval. The final run was made after build
jobs completed. Individual timing minima are throughput measurements, not
real-time deadline or thermal guarantees.

Frames 100 and 200 from all four requested takes were freshly extracted with
the original decoder and SHA-256 checked against the benchmark inputs:

- s0: Downloads/IMG_20261027_075859_390_VID.craw, 4080x3060, ISO 5442
- s1: Movies/CRAW/IMG_20261027_073024_185_VID.craw, 4080x3060, ISO 8431
- s2: Downloads/IMG_20261027_124350_527_VID.craw, 4080x2040, ISO 50
- s3: Downloads/IMG_20261027_124417_257_VID.craw, 4080x2040, ISO 50

## What worked and what did not

- Explicit per-block Rice parameters remove the fixed-width maximum penalty.
  Four predictors are searched per tile: avg4, MED, average of left/up, and
  weighted `(2L+U+UR+2)>>2`. Exact escaped-Rice bit cost selects predictor and k;
  no noisy/clean ISO assumption enters the bitstream. See SPEC §3.9.
- The numpy model (`model.py`) estimated 5.206 -> 5.096 bpp on s0/100 and
  4.823 -> 4.573 bpp on s2/100 when selecting among cheap predictors. It excludes
  tile boundaries and is only a screening model. Actual codec sizes above
  include boundaries, headers and stored tiles.
- A quotient-byte experiment (`qtest.cpp`) splits adaptive low bits from
  quotients and compresses quotients with Zstd 1. On the four frame-100 inputs,
  its smallest tested variants produced 8,109,172 / 8,770,796 / 4,991,714 /
  4,949,542 bytes, all larger than final Compact's corresponding frames. Larger
  k made this worse. Coarser 64-sample adaptation and byte-symbol overhead
  consumed the hoped-for gain; this does not rule out rANS or contextual models.
  Zstd is an experiment dependency only, absent from the delivered codec.
- A first scalar implementation took about 186–191 ms on 4080x3060 frames.
  Explicit NEON residual generation across all four predictor choices reduced
  that to about 78–80 ms with identical payloads. NEON k-cost reductions alone
  made little difference. Full predictor/k search and serial Rice coding still
  dominate; this cannot be represented as a near-Live-cost improvement.
- The supplied split-Rice prototype's earlier 53.4 MB / 21.9 ms result is
  historical, supplied by the task, not a fresh apples-to-apples timing here.
  Compact prioritizes smaller output and full desktop integration, at higher
  CPU cost. rANS/tANS, context models, temporal prediction and SIMD quotient
  decode were not implemented or evaluated in this iteration.

## Delivered behavior and validation

- Codec id 4, normative SPEC §3.9, independent Python reference, 13 new golden
  vectors; all 24 old payload/raw vectors remain byte-identical.
- Encoder and decoder conformance: 37 vectors, one and four threads, direct
  output buffers/strides/capacity guards, corruption and truncation rejection.
- `craw compact in.craw out.craw` calls `craw_compact`. It preserves META,
  timestamps, frame indexes/JSON, opaque chunk flags, audio, shading, IMU,
  thumbnails and unknown chunks; regenerates INDX/trailer; verifies each
  re-encoded frame bit for bit; keeps any original payload that is no larger.
  Files can therefore contain mixed codec ids. It refuses existing output,
  incomplete/unindexed inputs, and bad chunk CRCs; publishes via a hard link
  from a temporary file beside the destination. Output requires hard-link
  support. A failed operation cleans up its temporary file.
- Decoder CTest covers compaction end to end, exact RAW, opaque data, index,
  no-clobber and failure cleanup, plus existing WAV tests. Decoder and compactor
  suites also pass under AddressSanitizer and UndefinedBehaviorSanitizer. TUI tests exercise
  codec 4 through browser summaries, RAW preview/development and the same DNG
  generation path used by mount/craw2dng. Two real high-ISO frames were also
  compacted through the Python desktop wrapper; craw2dng produced byte-identical
  complete DNGs (24,970,626 bytes each) before and after compaction, and the TUI
  opened the compact take. Both tools compile. Live FUSE mounting
  and FSKit runtime were not tested; support uses their existing shared decoder.
- No RawLens changes. No GPL implementation source was read or copied, and
  the delivered codec has no GPL or Zstd dependency. Nothing was pushed.

## Reproduction

Configure the Encoder/Decoder checkouts with CMake/Ninja and
`-DCMAKE_CXX_FLAGS='-O3 -march=armv8-a+crc'`. `bench/encode.cpp` and
`bench/decode.cpp` wrap the CRAW codecs behind `bench/api.h`. The type 7
baseline is GPL-3.0, so the harness that links it (timing all three codecs on
`s[0-3]_[12]00_*.raw`) is deliberately kept out of this Apache-2.0
repository. Full measurements are in `benchmark.csv`.

The desktop installer includes `craw_compact`; run `craw compact in.craw
out.craw` after installing.
