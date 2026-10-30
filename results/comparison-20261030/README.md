# Same-RAW CRAW / JPEG XL comparison — 2026-10-30

- [Host report](host/REPORT.md), [per-frame CSV](host/summary.csv),
  [manifest](host/manifest.json), [compiler/build commands](host/build.json).
- [Android report](android/REPORT.md), [per-frame CSV](android/summary.csv),
  [manifest](android/manifest.json), [compiler/build commands](android/build.json).
- [Method and reproduction](../../bench/comparison/README.md).
- [Source snapshot used for this run](sources/). The native source and original
  driver SHA-256 match the host manifest. Reporting-only improvements made
  after measurement do not change raw timing observations.

Six frames (first/middle/last from each of two Downloads takes) contain
4080×2040 **10-bit GBRG** RAW samples. All six selected frames report ISO 50 and
1,914,990 ns exposure (see [capture-metadata.json](capture-metadata.json)). Their container META advertises the uncropped
4080×3060 sensor size; benchmark geometry comes from the decoded frame header,
not that full-sensor metadata. No high-ISO or other-camera conclusion follows.
Source takes and RAW pixels are not redistributed. Their hashes are in the
manifests; keep the originals to reproduce this exact corpus.

## Size result

The JPEG XL size gate **fails for all four CRAW modes on all six frames** when
compared with the smallest measured JPEG XL effort/layout per frame. In this
corpus that is grouped-CFA-plane JPEG XL at effort 3. Host and phone payload
sizes agree for every frame/configuration/thread setting.

| mode | bits / sensor pixel | size versus best measured JXL |
|---|---:|---:|
| Fast (1) | 5.018 | +13.74% |
| Live v1 (2) | 5.226 | +18.44% |
| Live v2 (3) | 5.284 | +19.76% |
| Compact (4) | 4.645 | +5.28% |
| JXL effort 1, CFA planes | 5.029 | +13.99% |
| JXL effort 2, CFA planes | 4.576 | +3.72% |
| JXL effort 3, CFA planes | 4.412 | reference |

JPEG XL applied directly to the alternating Bayer mosaic is much larger:
8.807/6.979/6.737 bpp at efforts 1/2/3. A mosaic-only comparison would give
a misleading impression of CRAW's compression advantage. Both layouts remain
in the reports. The CFA layout is a reversible sample permutation, not RGB
development; rearrangement time and buffers are included.

## Speed and memory tradeoff

Short-run phone means of per-frame medians, four requested threads:

| mode | encode ms | decode ms | encode / decode process peak MiB |
|---|---:|---:|---:|
| Fast (1) | 26.29 | 68.47 | 52.5 / 44.0 |
| Live v1 (2) | 18.20 | 27.83 | 49.9 / 44.2 |
| Live v2 (3) | 19.14 | 23.11 | 55.9 / 44.3 |
| Compact (4) | 81.82 | 52.22 | 50.7 / 43.6 |
| JXL effort 1, CFA planes | 79.99 | 106.34 | 83.7 / 68.5 |
| JXL effort 2, CFA planes | 314.79 | 129.39 | 184.7 / 68.4 |
| JXL effort 3, CFA planes | 414.14 | 180.54 | 184.7 / 68.6 |

On these settings, best-size JPEG XL trades substantially more CPU, wall time
and encode memory for smaller payloads. Live v1 is slightly smaller/faster
to encode than Live v2 here; a newer codec ID does not guarantee a better
result on every scene. Compact saves about 12.1% versus Live v2 on this corpus,
with substantially higher encode cost. These are measured tradeoffs, not
evidence that another entropy coder must lose or win.

One requested JXL thread uses its synchronous path; four requests a pool of
four workers, with possible caller participation. CRAW's setting bounds tile
workers. CPU time is retained alongside wall time so a worker-count label is
not treated as an identical CPU budget. Peak RSS is an absolute process
high-water mark, not incremental codec workspace; see the method for buffers
and lifecycle included in each operation.

## Device scope and validation

Android is Xiaomi 25080RABDG, MT6878, Android 16; host is an Apple M1
MacBook Air (8 CPU cores, 8 GB RAM), macOS 27.0.1. The manifests pin library/source revisions, hashes and settings.
Both platforms complete 120 short-run encode/decode pairs: six frames × ten
configurations × two thread settings, with one warmup and five timed iterations.
Every decode checks the original RAW; every repeated encode must produce
identical bytes. Source RAW hashes were also verified after pushing to Android.
The native source is unchanged between the host and Android builds.

**All ten sustained encode/decode pairs (20 one-minute loops) completed and
were recovered from the phone after reconnection.** Every decode verified exact
RAW equality; every operation ran for at least 60 seconds. The earlier USB
disconnection prevented collection, but did not prevent the batch from finishing.
All 120 phone short-run pairs also remain verified. No reruns were needed.
See the Android report and raw thermal logs for the complete first/last-window
observations. These loops reuse one frame in RAM, run sequentially without controlled
cooldown, and are not proof of thermal steady state or sustained capture.
Charging, other device work and scheduler state are not controlled.

No Camera2 acquisition, viewfinder, audio, storage or recorder queues are
exercised. Full recorder acceptance and actual Resolve import remain separate
open gates. No codec implementation, ID or file syntax was changed.
