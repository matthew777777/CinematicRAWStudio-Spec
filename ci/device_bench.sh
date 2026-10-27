#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# Builds Release arm64 encoder+decoder, runs them on a device, gates on results.
#
#   ci/device_bench.sh                       # adb, first device
#   ANDROID_SERIAL=XYZ ci/device_bench.sh    # adb, chosen device
#   DEVICE_SSH=user@host[:port] ci/device_bench.sh   # ssh (e.g. Termux sshd)
#   UPDATE_BASELINE=1 ci/device_bench.sh     # accept current numbers as baseline
#
# Steps on device: conformance vectors (encoder byte-exact, decoder bit-exact,
# corruption rejection), 4K encode throughput, encode->decode round trip,
# then results/<device>/<timestamp>.json and a gate against perf_baseline.json.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SPEC="$(dirname "$HERE")"
ROOT="$(dirname "$SPEC")"
ENC="$ROOT/CinematicRAWStudio-Encoder"
DEC="$ROOT/CinematicRAWStudio-Decoder"
REMOTE="${REMOTE_DIR:-/data/local/tmp/craw}"
FRAMES="${FRAMES:-30}"
THRESHOLD="${THRESHOLD:-0.05}"
ADB="${ADB:-$(command -v adb || echo "$HOME/Library/Android/sdk/platform-tools/adb")}"

if [[ -n "${DEVICE_SSH:-}" ]]; then
    HOST="${DEVICE_SSH%:*}"; PORT=22; [[ "$DEVICE_SSH" == *:* ]] && PORT="${DEVICE_SSH##*:}"
    REMOTE="${REMOTE_DIR:-craw}"
    run()  { ssh -p "$PORT" -o BatchMode=yes "$HOST" "$@"; }
    push() { scp -q -P "$PORT" -r "$@" "$HOST:$REMOTE/"; }
    DEVICE_ID="$(run 'getprop ro.product.model 2>/dev/null || uname -n' | tr ' /' '__')"
else
    [[ -x "$ADB" ]] || { echo "adb not found (set ADB=...)"; exit 2; }
    "$ADB" get-state >/dev/null 2>&1 || { echo "no adb device connected"; exit 2; }
    run()  { "$ADB" shell "$@"; }
    push() { "$ADB" push "$@" "$REMOTE/" >/dev/null; }
    DEVICE_ID="$("$ADB" shell getprop ro.product.model | tr -d '\r' | tr ' /' '__')"
fi

echo "== build (Release arm64-v8a)"
"$ENC/scripts/build_android.sh" >/dev/null
"$DEC/scripts/build_android.sh" >/dev/null

echo "== push to $DEVICE_ID:$REMOTE"
run "rm -rf $REMOTE && mkdir -p $REMOTE"
push "$ENC/build-android-arm64/craw_bench" "$ENC/build-android-arm64/craw_enc" \
     "$ENC/build-android-arm64/craw_enc_conformance" \
     "$DEC/build-android-arm64/craw_dec" "$DEC/build-android-arm64/craw_dec_conformance" \
     "$SPEC/vectors"
run "chmod 755 $REMOTE/craw_*"

echo "== device info"
INFO="$(run "getprop ro.soc.model 2>/dev/null; getprop ro.build.version.release 2>/dev/null; nproc; \
  cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0" | tr -d '\r')"
SOC="$(sed -n 1p <<<"$INFO")"; ANDROID="$(sed -n 2p <<<"$INFO")"
CORES="$(sed -n 3p <<<"$INFO")"; TEMP0="$(sed -n 4p <<<"$INFO")"
echo "soc=$SOC android=$ANDROID cores=$CORES temp=$TEMP0"

echo "== conformance"
run "cd $REMOTE && ./craw_enc_conformance vectors && ./craw_dec_conformance vectors" | tail -2

echo "== encode benchmark (synthetic 4080x3060 10-bit, $FRAMES frames)"
ENC_JSON="$(run "cd $REMOTE && ./craw_bench --frames $FRAMES" | tr -d '\r' | tail -1)"
ENC1_JSON="$(run "cd $REMOTE && ./craw_bench --frames 5 --threads 1" | tr -d '\r' | tail -1)"
echo "$ENC_JSON"

echo "== round trip + decode benchmark"
run "cd $REMOTE && ./craw_dec_conformance vectors >/dev/null"
# Use the bench's synthetic frame path: encode real vectors into a container.
run "cd $REMOTE && ./craw_enc rt.craw --width 128 --height 96 --bits 10 --cfa GRBG vectors/gradient10_grbg.raw vectors/gradient10_grbg.raw \
     && ./craw_dec frames rt.craw . >/dev/null && cmp vectors/gradient10_grbg.raw frame_000001.raw && echo roundtrip-ok"
DEC_JSON="$(run "cd $REMOTE && ./craw_dec verify rt.craw" | tr -d '\r' | tail -1)"
TEMP1="$(run 'cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0' | tr -d '\r')"

mkdir -p "$SPEC/results/$DEVICE_ID"
OUT="$SPEC/results/$DEVICE_ID/$(date +%Y%m%d-%H%M%S).json"
cat > "$OUT" <<JSON
{"device":"$DEVICE_ID","soc":"$SOC","android":"$ANDROID","cores":$CORES,
 "temp_start":$TEMP0,"temp_end":$TEMP1,
 "encode":$ENC_JSON,"encode_1thread":$ENC1_JSON,"decode":$DEC_JSON}
JSON
echo "== results: $OUT"
python3 -I "$HERE/perf_gate.py" "$OUT" "$SPEC/perf_baseline.json" --threshold "$THRESHOLD" \
    ${UPDATE_BASELINE:+--update}
