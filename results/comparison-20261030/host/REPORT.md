# CRAW / JPEG XL comparison

Platform: **macOS-27.0.1-arm64-arm-64bit**. Run started 2026-10-30T07:48:47Z.

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
| craw1 | 1 | 5.018 | 15.23 | 39.73 | 15.30 | 39.67 | 66.4 / 50.0 |
| craw1 | 4 | 5.018 | 4.81 | 11.01 | 17.35 | 42.77 | 68.4 / 50.3 |
| craw2 | 1 | 5.226 | 4.51 | 11.77 | 4.61 | 11.77 | 69.6 / 50.0 |
| craw2 | 4 | 5.226 | 2.13 | 3.69 | 6.51 | 13.85 | 70.1 / 50.3 |
| craw3 | 1 | 5.284 | 5.65 | 11.48 | 5.75 | 11.47 | 74.5 / 50.0 |
| craw3 | 4 | 5.284 | 2.46 | 3.49 | 7.69 | 13.51 | 74.7 / 50.4 |
| craw4 | 1 | 4.645 | 56.93 | 42.44 | 56.38 | 42.35 | 67.4 / 50.0 |
| craw4 | 4 | 4.645 | 16.24 | 12.45 | 61.68 | 47.20 | 78.2 / 50.4 |
| jxl-e1-mosaic | 1 | 8.807 | 19.16 | 69.45 | 19.39 | 69.42 | 83.9 / 84.0 |
| jxl-e1-mosaic | 4 | 8.807 | 6.74 | 20.04 | 22.05 | 75.70 | 87.8 / 88.5 |
| jxl-e1-planes | 1 | 5.029 | 28.83 | 79.71 | 29.00 | 79.60 | 88.5 / 68.3 |
| jxl-e1-planes | 4 | 5.029 | 16.13 | 28.13 | 33.05 | 87.72 | 91.6 / 73.2 |
| jxl-e2-mosaic | 1 | 6.979 | 149.65 | 137.25 | 149.83 | 136.74 | 198.8 / 68.3 |
| jxl-e2-mosaic | 4 | 6.979 | 52.27 | 39.60 | 177.12 | 151.53 | 215.1 / 73.6 |
| jxl-e2-planes | 1 | 4.576 | 163.25 | 125.61 | 163.90 | 125.63 | 214.3 / 68.7 |
| jxl-e2-planes | 4 | 4.576 | 58.51 | 40.50 | 181.94 | 135.61 | 228.3 / 73.8 |
| jxl-e3-mosaic | 1 | 6.737 | 325.66 | 225.45 | 325.31 | 225.33 | 199.4 / 68.5 |
| jxl-e3-mosaic | 4 | 6.737 | 98.78 | 63.85 | 360.87 | 246.82 | 215.7 / 73.9 |
| jxl-e3-planes | 1 | 4.412 | 340.76 | 222.56 | 340.05 | 222.30 | 217.1 / 68.9 |
| jxl-e3-planes | 4 | 4.412 | 108.16 | 68.45 | 376.03 | 247.09 | 231.2 / 74.3 |

## JPEG XL size gate

Compare each CRAW mode with the smallest measured JPEG XL effort/layout on each identical frame (one-thread jobs). This is a corpus-specific size comparison, not a universal codec ranking.

- craw1: size ≤ best tested JPEG XL on **0/6 frames**; aggregate difference **+13.74%** (positive means CRAW larger).
- craw2: size ≤ best tested JPEG XL on **0/6 frames**; aggregate difference **+18.44%** (positive means CRAW larger).
- craw3: size ≤ best tested JPEG XL on **0/6 frames**; aggregate difference **+19.76%** (positive means CRAW larger).
- craw4: size ≤ best tested JPEG XL on **0/6 frames**; aggregate difference **+5.28%** (positive means CRAW larger).

## Sustained isolated codec loops

These reuse one extracted frame in RAM. They do not exercise Camera2, preview, audio, storage, recorder queues or dropped capture frames. Decode loops follow encode loops; order and starting temperature can affect results. Thermal/battery snapshots are retained on Android. No cooldown, fixed-clock or equal-temperature guarantee is made.

Not measured in this run.

## Limits

The supplied corpus contains two takes from one phone; adjacent/time-spaced frames are correlated. It does not establish high-ISO, other-camera, 12/14/16-bit or cross-scene behaviour unless explicitly represented in the manifest. Payload decoding is not a security audit. End-to-end sustained recording and actual Resolve import require separate acceptance results. No new codec or wire-format change is introduced by this benchmark.
