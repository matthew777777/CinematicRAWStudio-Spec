# SPDX-License-Identifier: Apache-2.0
"""Compares a device_bench result against perf_baseline.json (per device).

Fails (exit 1) when encode throughput drops by more than --threshold, the
compression ratio drops at all, or decoding reported bad frames.
"""
import argparse
import json
import pathlib
import sys

# Absolute floor for real-time recording at 4080x3060 @ 30 fps.
REALTIME_MPIX = 4080 * 3060 * 30 / 1e6


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("result")
    ap.add_argument("baseline")
    ap.add_argument("--threshold", type=float, default=0.05)
    ap.add_argument("--update", action="store_true")
    a = ap.parse_args()
    res = json.loads(pathlib.Path(a.result).read_text())
    base_path = pathlib.Path(a.baseline)
    base_all = json.loads(base_path.read_text()) if base_path.exists() else {}
    dev = res["device"]
    enc = res["encode"]
    failures = []
    if res["decode"]["bad_frames"]:
        failures.append("decoder reported bad frames")
    realtime = enc["mpix_per_s"] >= REALTIME_MPIX
    print(f"{dev}: encode {enc['mpix_per_s']:.0f} MPix/s ({enc['fps']:.1f} fps 4K), "
          f"ratio {enc['ratio']:.3f}, p99 {enc['p99_ms']:.1f} ms, "
          f"real-time 4K30: {'yes' if realtime else 'NO'}")
    base = base_all.get(dev)
    if base and not a.update:
        floor = base["mpix_per_s"] * (1 - a.threshold)
        if enc["mpix_per_s"] < floor:
            failures.append(f"encode throughput {enc['mpix_per_s']:.1f} < {floor:.1f} MPix/s")
        if enc["ratio"] < base["ratio"] - 1e-6:
            failures.append(f"compression ratio {enc['ratio']:.4f} < baseline {base['ratio']:.4f}")
    if a.update or not base:
        base_all[dev] = {"mpix_per_s": enc["mpix_per_s"], "ratio": enc["ratio"],
                         "p99_ms": enc["p99_ms"], "from": pathlib.Path(a.result).name}
        base_path.write_text(json.dumps(base_all, indent=2, sort_keys=True) + "\n")
        print(f"baseline {'updated' if base else 'created'} for {dev}")
    for f in failures:
        print("FAIL:", f)
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
