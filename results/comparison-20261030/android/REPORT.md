# CRAW / JPEG XL comparison

Platform: **Android Xiaomi 25080RABDG / MT6878**. Run started 2026-10-30T07:52:00Z.

Completed short-run encode/decode pairs: **120/120**.

All reported payloads decoded to the original uint16 RAW samples. No demosaic, denoise, scaling or quantization.

## Scope and method

Independent in-memory image payloads, not complete containers. CRAW tile=128, PFOR off, frame CRC off; container CRC cost is excluded. JPEG XL lossless, efforts 1–3, source bit depth, original linear grayscale profile, mosaic and reversible stacked CFA planes. CFA rearrangement and inverse are included in timings. Fresh codec objects/output allocations per iteration for both families. One thread means synchronous JXL; larger JXL settings request that many pool workers (the caller can also work), whereas CRAW bounds tile workers by its threads parameter. Thread settings are not an exact equal-CPU-budget guarantee.

Each encode/decode job has its own process. Peak RSS includes RAW, payload, libraries, retained allocator memory and verification buffers; it is an absolute process high-water mark, not incremental codec workspace. Encode RSS excludes decoding. Repeated encode bytes must match; the final payload is decoded in a separate process. Every decoded frame is checked sample for sample. Validation and file I/O are excluded from per-iteration codec times. Sustained wall time includes validation and loop overhead.

Warmups: 1; measured repetitions: 5. Jobs shuffled with seed 20261030. Raw observations and commands are retained in measurements/. Small-sample p95 is descriptive, not a tail-latency guarantee.

## Corpus

| sample | source frame (zero based) | dimensions / bits | RAW SHA-256 |
|---|---|---|---|
| take0-frame0 | IMG_20261027_124350_527_VID.craw / 0 | 4080×2040 / 10 | `cbfd2b0de58ba2b96627430020704ae690f503050523f1aa55cc8e3049566484` |
| take0-frame132 | IMG_20261027_124350_527_VID.craw / 132 | 4080×2040 / 10 | `e49146e024ceef5153fb1689167da0365b3456cc5cc95aea3e49bb68a31402e5` |
| take0-frame265 | IMG_20261027_124350_527_VID.craw / 265 | 4080×2040 / 10 | `c23da47f4ea5a66d8cca0e25e1b3e47fbf6f64b3fb75087ceda8d8633972e918` |
| take1-frame0 | IMG_20261027_124417_257_VID.craw / 0 | 4080×2040 / 10 | `bd5d3373808f83241974c5c0f8981d17e0cecd736f73accda7c5c027d003b8f2` |
| take1-frame136 | IMG_20261027_124417_257_VID.craw / 136 | 4080×2040 / 10 | `80a9fa55a9de9552a56cf0251ecf579b66b0279866e88f5b34fe01f3e7b7b67f` |
| take1-frame271 | IMG_20261027_124417_257_VID.craw / 271 | 4080×2040 / 10 | `85eae793e85f363a6a909795bcaf5732a037bf2453744ba449bf8ca283c083a1` |

Source take hashes, repository revisions, executable hash and device/host details: [manifest.json](manifest.json). RAW and original footage are external inputs, not included in this repository. The same hashes are required for exact reproduction.

## Short-run results

Unweighted means of per-frame medians and per-process peak RSS; sizes are total payload bytes divided by total sensor pixels. See [summary.csv](summary.csv) for every frame and thread setting.

| mode | threads | bpp | encode ms | decode ms | encode CPU ms | decode CPU ms | encode / decode peak MiB |
|---|---:|---:|---:|---:|---:|---:|---:|
| craw1 | 1 | 5.018 | 52.02 | 177.49 | 50.81 | 162.29 | 50.7 / 43.0 |
| craw1 | 4 | 5.018 | 26.29 | 68.47 | 71.02 | 209.20 | 52.5 / 44.0 |
| craw2 | 1 | 5.226 | 26.92 | 42.64 | 26.76 | 41.98 | 48.8 / 43.2 |
| craw2 | 4 | 5.226 | 18.20 | 27.83 | 36.79 | 61.74 | 49.9 / 44.2 |
| craw3 | 1 | 5.284 | 35.95 | 47.21 | 34.00 | 42.74 | 54.7 / 43.3 |
| craw3 | 4 | 5.284 | 19.14 | 23.11 | 36.58 | 49.44 | 55.9 / 44.3 |
| craw4 | 1 | 4.645 | 208.55 | 109.75 | 199.00 | 102.44 | 47.0 / 42.6 |
| craw4 | 4 | 4.645 | 81.82 | 52.22 | 258.84 | 136.38 | 50.7 / 43.6 |
| jxl-e1-mosaic | 1 | 8.807 | 71.44 | 187.72 | 69.44 | 182.62 | 74.6 / 67.9 |
| jxl-e1-mosaic | 4 | 8.807 | 46.43 | 121.73 | 99.90 | 262.35 | 74.4 / 72.0 |
| jxl-e1-planes | 1 | 5.029 | 92.23 | 205.57 | 90.30 | 203.25 | 83.8 / 64.5 |
| jxl-e1-planes | 4 | 5.029 | 79.99 | 106.34 | 144.34 | 290.83 | 83.7 / 68.5 |
| jxl-e2-mosaic | 1 | 6.979 | 603.87 | 315.71 | 581.84 | 313.00 | 171.6 / 66.3 |
| jxl-e2-mosaic | 4 | 6.979 | 343.70 | 124.30 | 862.52 | 394.39 | 171.8 / 70.5 |
| jxl-e2-planes | 1 | 4.576 | 531.49 | 285.02 | 517.05 | 271.72 | 181.8 / 64.1 |
| jxl-e2-planes | 4 | 4.576 | 314.79 | 129.39 | 754.67 | 320.60 | 184.7 / 68.4 |
| jxl-e3-mosaic | 1 | 6.737 | 1103.28 | 545.10 | 1079.18 | 536.14 | 171.4 / 65.0 |
| jxl-e3-mosaic | 4 | 6.737 | 448.81 | 189.88 | 1048.17 | 536.13 | 172.0 / 70.3 |
| jxl-e3-planes | 1 | 4.412 | 1104.54 | 601.39 | 1025.80 | 588.14 | 181.5 / 62.6 |
| jxl-e3-planes | 4 | 4.412 | 414.14 | 180.54 | 1127.23 | 564.75 | 184.7 / 68.6 |

## JPEG XL size gate

Compare each CRAW mode with the smallest measured JPEG XL effort/layout on each identical frame (one-thread jobs). This is a corpus-specific size comparison, not a universal codec ranking.

- craw1: size ≤ best tested JPEG XL on **0/6 frames**; aggregate difference **+13.74%** (positive means CRAW larger).
- craw2: size ≤ best tested JPEG XL on **0/6 frames**; aggregate difference **+18.44%** (positive means CRAW larger).
- craw3: size ≤ best tested JPEG XL on **0/6 frames**; aggregate difference **+19.76%** (positive means CRAW larger).
- craw4: size ≤ best tested JPEG XL on **0/6 frames**; aggregate difference **+5.28%** (positive means CRAW larger).

## Sustained isolated codec loops

These reuse one extracted frame in RAM. They do not exercise Camera2, preview, audio, storage, recorder queues or dropped capture frames. Decode loops follow encode loops; order and starting temperature can affect results. Thermal/battery snapshots are retained on Android. No cooldown, fixed-clock or equal-temperature guarantee is made.

Sustained collection is incomplete: 3/10 requested encode/decode pairs retained (Fast, Live v1, Live v2). ADB disconnected after announcing the final configuration, before final collection. Compact/JPEG XL sustained results are unavailable and are not counted as passes. All 120 short-run pairs were collected and verified.

### craw1, 4 threads, take0-frame0, 60 seconds per operation

| operation | iterations | first 10 s median ms | last 10 s median ms | median ms | p95 ms | peak MiB |
|---|---:|---:|---:|---:|---:|---:|
| encode | 1832 | 27.16 | 24.11 | 26.83 | 63.97 | 52.7 |
| decode | 930 | 61.03 | 55.91 | 57.58 | 78.12 | 44.1 |

### craw2, 4 threads, take0-frame0, 60 seconds per operation

| operation | iterations | first 10 s median ms | last 10 s median ms | median ms | p95 ms | peak MiB |
|---|---:|---:|---:|---:|---:|---:|
| encode | 3233 | 16.45 | 16.14 | 16.08 | 23.16 | 50.2 |
| decode | 1818 | 17.32 | 24.46 | 24.97 | 39.56 | 44.2 |

### craw3, 4 threads, take0-frame0, 60 seconds per operation

| operation | iterations | first 10 s median ms | last 10 s median ms | median ms | p95 ms | peak MiB |
|---|---:|---:|---:|---:|---:|---:|
| encode | 2729 | 18.18 | 19.76 | 18.37 | 33.31 | 56.0 |
| decode | 1819 | 29.79 | 18.84 | 24.88 | 39.82 | 44.3 |


## Limits

The supplied corpus contains two takes from one phone; adjacent/time-spaced frames are correlated. It does not establish high-ISO, other-camera, 12/14/16-bit or cross-scene behaviour unless explicitly represented in the manifest. Payload decoding is not a security audit. End-to-end sustained recording and actual Resolve import require separate acceptance results. No new codec or wire-format change is introduced by this benchmark.
