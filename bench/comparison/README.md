# Reproducible CRAW / JPEG XL RAW comparison

This measures the implemented codecs before proposing another one. It does not
change codec syntax or integrate JPEG XL into the CRAW container.

## Dependencies and build

Use sibling Spec, Encoder and Decoder checkouts. Python 3, CMake ≥3.20 and a
C++20 compiler are required. The native harness targets little-endian macOS,
Linux and Android (POSIX process/RSS APIs); use WSL for Windows host runs.
The 2026-10-30 run uses libjxl commit
`a7a9c787341cf703dede03c2009fa460cae5e5df` (0.12.0), with the exact
submodule commits recorded in each result manifest. Another libjxl revision
is a new comparison; record it rather than silently substituting a version.

```sh
git clone --recursive https://github.com/libjxl/libjxl.git /tmp/craw-libjxl
git -C /tmp/craw-libjxl checkout a7a9c787341cf703dede03c2009fa460cae5e5df
git -C /tmp/craw-libjxl submodule update --init --recursive

cmake -S bench/comparison -B /tmp/craw-compare-host -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DLIBJXL_DIR=/tmp/craw-libjxl
cmake --build /tmp/craw-compare-host --target craw_compare -j 4
python3 bench/comparison/selftest.py --binary /tmp/craw-compare-host/craw_compare
```

Encoder/Decoder paths default to sibling checkouts; override with
`-DCRAW_ENCODER_DIR=... -DCRAW_DECODER_DIR=...` for another directory layout.
The harness links libjxl directly, avoiding CLI process startup, PGM parsing,
file I/O and bit-depth scaling differences in codec timing. Lossless effort
semantics follow libjxl's
[official effort documentation](https://github.com/libjxl/libjxl/blob/a7a9c787341cf703dede03c2009fa460cae5e5df/doc/encode_effort.md).

## Run on source takes

```sh
python3 bench/comparison/run.py \
  --binary /tmp/craw-compare-host/craw_compare \
  --takes /path/to/take0.craw /path/to/take1.craw \
  --jxl-source /tmp/craw-libjxl \
  --out results/my-comparison/host --work /tmp/craw-comparison-inputs \
  --samples 3 --threads 1 4 --reps 5 --warmups 1
```

The default corpus selects first/middle/last frames, using zero-based indices
and Python's integer rounding. Only Bayer frames are accepted. RAW is extracted
through the shared reader/decoder, including source frame/chunk CRC validation.
No source take is changed. Both whole-take and extracted-frame SHA-256 hashes
are retained; footage/RAW is not copied into the result directory.

All ten configurations run: CRAW 1–4 and JXL efforts 1–3 in both layouts.
Each frame/thread/configuration starts separate encode and decode processes.
One warmup precedes five measured iterations. Job order is shuffled with the
fixed seed 20261030; repetitions within a job are consecutive. Per-iteration
wall and process CPU times, sizes, peak RSS and exact equality checks are saved.
Results are checkpointed after each completed encode/decode pair. Re-running
the same invocation skips completed pairs; use a new `--out` for a fresh run.
Manifest compatibility checks refuse changes to binary, corpus or main settings.

Codec settings:

| family | settings |
|---|---|
| CRAW | source dimensions/CFA/bit depth, tile 128, frame CRC off, PFOR off, vector API |
| JXL | lossless, effort 1/2/3, source bit depth, grayscale linear original profile, uint16 native-endian buffers with code-stream bit depth |
| mosaic | sensor samples in original row-major order |
| planes | `(even y,even x)`, `(even y,odd x)`, `(odd y,even x)`, `(odd y,odd x)` stacked as one grayscale image of `W/2 × 2H` |

Plane rearrangement and inverse are timed. This is a reversible permutation,
not demosaic or quantization. Direct JXL mosaic tests remain visible, so a
layout unsuitable for Bayer cannot silently determine the conclusion.
CRAW payload headers and JXL image headers count toward size. CRAW chunk
checksums, audio, JSON, index and storage are excluded. JXL here is an image
payload alternative, not an implemented camera container.

Both families construct codec jobs and allocate output inside each iteration.
CRAW uses its existing reusable thread-local workspace. JXL constructs its
encoder/decoder and (for multiple threads) its runner inside the timed call.
This is an API-lifecycle comparison, not a proof of optimal JXL integration.
One requested JXL thread uses the synchronous path. Four requests four pool
workers; JXL may also use the caller, whereas CRAW's thread setting bounds its
tile workers. Compare CPU time as well as wall time; these settings do not
guarantee exactly equal CPU budgets.

RSS is an absolute process high-water mark. It includes input, output,
libraries, allocator retention and verification storage. Encode retains the
first compressed payload to verify deterministic repeats; decode holds original
RAW for sample equality. Encode processes never run a decoder. Decode verifies
every iteration outside codec timing; the final encoded payload is checked by
the separate decoder job. Repeated encode outputs must all be byte-identical.

## Android build and execution

```sh
cmake -S bench/comparison -B /tmp/craw-compare-android -G Ninja \
  -DLIBJXL_DIR=/tmp/craw-libjxl \
  -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-30 \
  -DANDROID_STL=c++_static -DCMAKE_BUILD_TYPE=Release
cmake --build /tmp/craw-compare-android --target craw_compare -j 4

python3 bench/comparison/run.py \
  --binary /tmp/craw-compare-android/craw_compare \
  --host-binary /tmp/craw-compare-host/craw_compare \
  --device YOUR_ADB_SERIAL --jxl-source /tmp/craw-libjxl \
  --takes /path/to/take0.craw /path/to/take1.craw \
  --out results/my-comparison/android --work /tmp/craw-comparison-inputs \
  --samples 3 --threads 1 4 --reps 5 --warmups 1 \
  --sustain 60 --sustain-modes craw1 craw2 craw3 craw4 \
  jxl-e1-mosaic jxl-e1-planes jxl-e2-mosaic jxl-e2-planes jxl-e3-mosaic jxl-e3-planes
```

The runner uses `/data/local/tmp/craw-comparison-20261030`, pushes only the
binary and extracted RAW, and leaves the staged files for reproduction. It
does not install an app, modify settings, lock clocks or record from a camera.
Use one runner at a time because it uses a common `payload.bin` scratch file.
Footage is loaded before timing, so this does not measure storage bandwidth.

For a standalone on-phone batch (also useful when host subprocesses cannot
access ADB), save selected device properties in `device-info.txt`, then:

```sh
python3 bench/comparison/device_batch.py \
  --host-results results/my-comparison/host \
  --binary /tmp/craw-compare-android/craw_compare \
  --device-info device-info.txt --out results/my-comparison/android \
  --sustain 60 --sustain-modes craw1 craw2 craw3 craw4 \
  jxl-e1-mosaic jxl-e1-planes jxl-e2-mosaic jxl-e2-planes jxl-e3-mosaic jxl-e3-planes
adb -s YOUR_ADB_SERIAL shell mkdir -p /data/local/tmp/craw-comparison-20261030
adb -s YOUR_ADB_SERIAL push /tmp/craw-compare-android/craw_compare \
  /tmp/craw-comparison-inputs/*.raw results/my-comparison/android/device-run.sh \
  /data/local/tmp/craw-comparison-20261030/
adb -s YOUR_ADB_SERIAL shell chmod 755 /data/local/tmp/craw-comparison-20261030/craw_compare
adb -s YOUR_ADB_SERIAL shell sh /data/local/tmp/craw-comparison-20261030/device-run.sh
adb -s YOUR_ADB_SERIAL pull /data/local/tmp/craw-comparison-20261030/results /tmp/craw-device-results
python3 bench/comparison/device_batch.py --out results/my-comparison/android \
  --import-results /tmp/craw-device-results
```

Sustained jobs use the first corpus frame, the largest requested thread setting
and at least the requested duration **per encode and per decode**. Wall duration
includes byte/equality verification overhead, which is not included in codec
times. The batch runs these jobs after short jobs, in the listed mode order,
without enforced cooling. Battery, thermal service, available memory and
readable CPU frequencies are sampled approximately every five seconds. Denied
or missing sensors remain visible in the logs. This order is not an equal-starting-
temperature comparison and charging can affect temperature. One-minute loops
are evidence about that interval, not a thermal steady-state guarantee.

## Results and acceptance

`REPORT.md` and `summary.csv` are generated from raw `measurements/*.json`.
Use `run.py --report-only --out ...` to regenerate a report without benchmarking.
Store machine/compiler/build settings next to each manifest. `jxl_version` is
reported by the native library; dependency commits identify the exact source.

The size gate compares each CRAW mode with the smallest tested JXL effort/layout
on every frame. A failure remains a failure even if CRAW is faster; both facts
are reported. Performance across ISO, cameras and scenes requires expanding
the corpus with separately hashed takes. The self-test covers 10/12/14/16-bit
inputs; the current uint16 JXL path does not support 8-bit source input in this
pinned library and fails rather than silently rescaling. Do not claim third-party adoption or
editor interoperability from these codec results.

The existing RawLens acceptance procedure additionally checks real recorded
FRAM timestamps, >=29.5 fps, <=50 ms gaps, codec, finalized footer, sound,
queue/acquisition losses and longer thermal runs. Neither the host benchmark
nor this isolated device loop replaces that test. See
[BENCHMARKS.md](../../BENCHMARKS.md).
