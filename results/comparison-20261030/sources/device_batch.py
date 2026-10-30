#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Stage a standalone Android shell batch, or import its pulled results.

This also supports environments where only direct adb tool calls can access USB.
"""
import argparse
import json
from pathlib import Path
import random
import shlex
import time
from run import MODES, command, report, save, sha


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--host-results", type=Path)
    p.add_argument("--binary", type=Path)
    p.add_argument("--out", type=Path, required=True)
    p.add_argument("--device-info", type=Path)
    p.add_argument("--import-results", type=Path)
    p.add_argument("--sustain", type=int, default=120)
    p.add_argument("--sustain-modes", nargs="+", choices=MODES, default=["craw3", "jxl-e1-planes"])
    a = p.parse_args()
    if a.import_results:
        jobs = json.loads((a.out/"jobs.json").read_text())
        for job in jobs:
            key = job.pop("key")
            encode = a.import_results/(key+".encode.json")
            decode = a.import_results/(key+".decode.json")
            if not encode.exists() or not decode.exists():
                continue
            job["encode"] = json.loads(encode.read_text())
            job["decode"] = json.loads(decode.read_text())
            if not job["decode"]["verified"] or job["encode"]["payload_bytes"] != job["decode"]["payload_bytes"]:
                raise RuntimeError("device verification failed")
            for op in ("encode", "decode"):
                trace = a.import_results/(key+"."+op+".thermal.txt")
                if trace.exists():
                    target = a.out/"measurements"/trace.name
                    target.write_text(trace.read_text())
                    job[op+"_device_trace_file"] = target.name
            save(a.out/"measurements"/(key+".json"),job)
        report(a.out)
        return
    if not all((a.host_results,a.binary,a.device_info)):
        p.error("provide --host-results --binary --device-info")
    a.out.mkdir(parents=True,exist_ok=True); (a.out/"measurements").mkdir(exist_ok=True)
    manifest = json.loads((a.host_results/"manifest.json").read_text())
    manifest.update(platform="Android Xiaomi 25080RABDG / MT6878", system=a.device_info.read_text(),
                    device="see system details", binary_sha256=sha(a.binary),
                    started_utc=time.strftime("%Y-%m-%dT%H:%M:%SZ",time.gmtime()))
    manifest["device_batch_sha256"] = sha(Path(__file__))
    save(a.out/"manifest.json",manifest)
    remote = "/data/local/tmp/craw-comparison-20261030"
    jobs = [(s,m,t,0) for s in manifest["samples"] for m in manifest["modes"] for t in manifest["threads"]]
    random.Random(20261030).shuffle(jobs)
    jobs += [(manifest["samples"][0],m,max(manifest["threads"]),a.sustain) for m in a.sustain_modes]
    script = ["#!/system/bin/sh", "set -eu", f"cd {remote}", "mkdir -p results", "",
              "snapshot() {", "  date -u", "  dumpsys thermalservice", "  dumpsys battery", "  cat /proc/meminfo",
              "  for f in /sys/devices/system/cpu/cpufreq/policy*/scaling_cur_freq; do echo \"$f\"; cat \"$f\" || true; done", "}", ""]
    descriptions = []
    for index,(s,m,t,seconds) in enumerate(jobs):
        key = f"{s['id']}-{m}-t{t}-s{seconds}"
        job = dict(key=key,sample=s["id"],mode=m,threads=t,sustained_seconds=seconds,commands={})
        script.append(f"echo '[{index+1}/{len(jobs)}] {key}'")
        for op in ("encode","decode"):
            args = ["./craw_compare","measure",s["id"]+".raw",s["width"],s["height"],s["bits"],s["cfa"],m,t,op,"payload.bin",manifest["reps"],seconds,manifest["warmups"]]
            cmd = shlex.join([str(x) for x in args]); job["commands"][op]=cmd
            result = f"results/{key}.{op}.json"
            if seconds:
                trace = f"results/{key}.{op}.thermal.txt"
                script += [f"snapshot > {trace} 2>&1", f"{cmd} > {result} &", "worker=$!",
                           f"while kill -0 \"$worker\" 2>/dev/null; do snapshot >> {trace} 2>&1; sleep 5; done",
                           'wait "$worker"', f"snapshot >> {trace} 2>&1"]
            else:
                script.append(f"{cmd} > {result}")
        descriptions.append(job)
    script.append("echo COMPLETE")
    (a.out/"device-run.sh").write_text("\n".join(script)+"\n")
    save(a.out/"jobs.json",descriptions)
    print(f"Stage {a.binary}, corpus *.raw and device-run.sh in {remote}; run sh device-run.sh, pull results/, then --import-results.")


if __name__ == "__main__":
    main()
