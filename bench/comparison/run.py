#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Extract a hashed corpus, benchmark isolated processes, and retain every timing."""
import argparse
import csv
import hashlib
import json
import os
from pathlib import Path
import platform
import random
import shlex
import shutil
import statistics
import subprocess
import threading
import time

MODES = [f"craw{i}" for i in range(1, 5)] + [f"jxl-e{e}-{layout}" for e in range(1, 4) for layout in ("mosaic", "planes")]


def command(args):
    return subprocess.check_output([str(x) for x in args], text=True, stderr=subprocess.PIPE).strip()


def sha(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(4 * 1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def save(path, obj):
    path.write_text(json.dumps(obj, indent=2) + "\n")


def quantile(values, p):
    return sorted(values)[max(0, min(len(values)-1, int((len(values)-1)*p + .5)))]


def summary(result):
    return {"median_ms": statistics.median(result["ms"]), "p95_ms": quantile(result["ms"], .95),
            "min_ms": min(result["ms"]), "max_ms": max(result["ms"]),
            "mean_cpu_ms": statistics.mean(result["cpu_ms"]), "peak_rss_bytes": result["peak_rss_bytes"],
            "iterations": len(result["ms"])}


def report(out):
    manifest = json.loads((out / "manifest.json").read_text())
    results = [json.loads(p.read_text()) for p in sorted((out / "measurements").glob("*.json"))]
    fields = ["sample", "mode", "threads", "sustained_seconds", "bytes", "bpp", "ratio", "verified",
              "encode_median_ms", "encode_p95_ms", "encode_mean_cpu_ms", "encode_peak_rss_bytes",
              "decode_median_ms", "decode_p95_ms", "decode_mean_cpu_ms", "decode_peak_rss_bytes"]
    rows = []
    for r in results:
        sample = next(s for s in manifest["samples"] if s["id"] == r["sample"])
        pixels = sample["width"] * sample["height"]
        row = {k: r[k] for k in ("sample", "mode", "threads", "sustained_seconds")}
        row.update(bytes=r["encode"]["payload_bytes"], bpp=r["encode"]["payload_bytes"]*8/pixels,
                   ratio=pixels*sample["bits"]/8/r["encode"]["payload_bytes"], verified=r["decode"]["verified"])
        for op in ("encode", "decode"):
            for k, v in summary(r[op]).items():
                row[f"{op}_{k}"] = v
        rows.append(row)
    with open(out / "summary.csv", "w", newline="") as f:
        writer = csv.DictWriter(f, fields, extrasaction="ignore"); writer.writeheader(); writer.writerows(rows)
    completed = sum(not r["sustained_seconds"] for r in results)
    expected = len(manifest["samples"])*len(manifest["modes"])*len(manifest["threads"])
    lines = ["# CRAW / JPEG XL comparison", "", f"Platform: **{manifest['platform']}**. Run started {manifest['started_utc']}.", "",
             f"Completed short-run encode/decode pairs: **{completed}/{expected}**.", "",
             "All reported payloads decoded to the original uint16 RAW samples. No demosaic, denoise, scaling or quantization.", "",
             "## Scope and method", "",
             "Independent in-memory image payloads, not complete containers. CRAW tile=128, PFOR off, frame CRC off; container CRC cost is excluded. "
             "JPEG XL lossless, efforts 1–3, source bit depth, original linear grayscale profile, mosaic and reversible stacked CFA planes. "
             "CFA rearrangement and inverse are included in timings. Fresh codec objects/output allocations per iteration for both families. "
             "One thread means synchronous JXL; larger JXL settings request that many pool workers (the caller can also work), "
             "whereas CRAW bounds tile workers by its threads parameter. Thread settings are not an exact equal-CPU-budget guarantee.", "",
             "Each encode/decode job has its own process. Peak RSS includes RAW, payload, libraries, retained allocator memory and verification buffers; "
             "it is an absolute process high-water mark, not incremental codec workspace. Encode RSS excludes decoding. "
             "Repeated encode bytes must match; the final payload is decoded in a separate process. Every decoded frame is checked sample for sample. "
             "Validation and file I/O are excluded from per-iteration codec times. Sustained wall time includes validation and loop overhead.", "",
             f"Warmups: {manifest['warmups']}; measured repetitions: {manifest['reps']}. Jobs shuffled with seed 20261030. "
             "Raw observations and commands are retained in measurements/. Small-sample p95 is descriptive, not a tail-latency guarantee.", "",
             "## Corpus", "", "| sample | source frame (zero based) | dimensions / bits | RAW SHA-256 |", "|---|---|---|---|"]
    for s in manifest["samples"]:
        lines.append(f"| {s['id']} | {s['source']} / {s['frame_index']} | {s['width']}×{s['height']} / {s['bits']} | `{s['raw_sha256']}` |")
    lines += ["", "Source take hashes, repository revisions, executable hash and device/host details: [manifest.json](manifest.json). "
              "RAW and original footage are external inputs, not included in this repository. The same hashes are required for exact reproduction.", "",
              "## Short-run results", "", "Unweighted means of per-frame medians and per-process peak RSS; sizes are total payload bytes divided by total sensor pixels. "
              "See [summary.csv](summary.csv) for every frame and thread setting.", "",
              "| mode | threads | bpp | encode ms | decode ms | encode CPU ms | decode CPU ms | encode / decode peak MiB |",
              "|---|---:|---:|---:|---:|---:|---:|---:|"]
    short = [r for r in rows if not r["sustained_seconds"]]
    for mode, threads in sorted({(r["mode"], r["threads"]) for r in short}):
        group = [r for r in short if r["mode"] == mode and r["threads"] == threads]
        mean = lambda k: statistics.mean(r[k] for r in group)
        pixels = sum(s['width']*s['height'] for s in manifest['samples'] if any(r['sample']==s['id'] for r in group))
        bpp = sum(r['bytes'] for r in group)*8/pixels
        lines.append(f"| {mode} | {threads} | {bpp:.3f} | {mean('encode_median_ms'):.2f} | {mean('decode_median_ms'):.2f} | {mean('encode_mean_cpu_ms'):.2f} | {mean('decode_mean_cpu_ms'):.2f} | {mean('encode_peak_rss_bytes')/2**20:.1f} / {mean('decode_peak_rss_bytes')/2**20:.1f} |")
    lines += ["", "## JPEG XL size gate", "", "Compare each CRAW mode with the smallest measured JPEG XL effort/layout on each identical frame (one-thread jobs). "
              "This is a corpus-specific size comparison, not a universal codec ranking.", ""]
    eligible = [r for r in short if r["threads"] == 1]
    for mode in [f"craw{i}" for i in range(1, 5)]:
        comparisons = []
        for r in eligible:
            if r["mode"] != mode:
                continue
            candidates = [j for j in eligible if j["sample"] == r["sample"] and j["mode"].startswith("jxl")]
            if candidates:
                comparisons.append((r, min(candidates, key=lambda x: x["bytes"])))
        if comparisons:
            delta = (sum(r["bytes"] for r,j in comparisons)/sum(j["bytes"] for r,j in comparisons)-1)*100
            wins = sum(r["bytes"] <= j["bytes"] for r,j in comparisons)
            lines.append(f"- {mode}: size ≤ best tested JPEG XL on **{wins}/{len(comparisons)} frames**; aggregate difference **{delta:+.2f}%** (positive means CRAW larger).")
    lines += ["", "## Sustained isolated codec loops", "", "These reuse one extracted frame in RAM. They do not exercise Camera2, preview, audio, storage, recorder queues or dropped capture frames. "
              "Decode loops follow encode loops; order and starting temperature can affect results. Thermal/battery snapshots are retained on Android. "
              "No cooldown, fixed-clock or equal-temperature guarantee is made.", ""]
    sustained = [r for r in results if r["sustained_seconds"]]
    if manifest.get("collection_status"):
        lines += [manifest["collection_status"], ""]
    if not sustained:
        lines.append("Not measured in this run.")
    for r in sustained:
        lines.append(f"### {r['mode']}, {r['threads']} threads, {r['sample']}, {r['sustained_seconds']} seconds per operation\n")
        lines += ["| operation | iterations | first 10 s median ms | last 10 s median ms | median ms | p95 ms | peak MiB |", "|---|---:|---:|---:|---:|---:|---:|"]
        for op in ("encode", "decode"):
            v = r[op]; end = v["start_seconds"][-1]
            first = [ms for t,ms in zip(v["start_seconds"],v["ms"]) if t < 10]
            last = [ms for t,ms in zip(v["start_seconds"],v["ms"]) if t >= max(0,end-10)]
            lines.append(f"| {op} | {len(v['ms'])} | {statistics.median(first):.2f} | {statistics.median(last):.2f} | {statistics.median(v['ms']):.2f} | {quantile(v['ms'],.95):.2f} | {v['peak_rss_bytes']/2**20:.1f} |")
        lines.append("")
    lines += ["", "## Limits", "", "The supplied corpus contains two takes from one phone; adjacent/time-spaced frames are correlated. "
              "It does not establish high-ISO, other-camera, 12/14/16-bit or cross-scene behaviour unless explicitly represented in the manifest. "
              "Payload decoding is not a security audit. End-to-end sustained recording and actual Resolve import require separate acceptance results. "
              "No new codec or wire-format change is introduced by this benchmark.", ""]
    (out / "REPORT.md").write_text("\n".join(lines))


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--binary", type=Path)
    p.add_argument("--host-binary", type=Path, help="Extractor executable when --device is used")
    p.add_argument("--takes", type=Path, nargs="+")
    p.add_argument("--out", type=Path, required=True)
    p.add_argument("--work", type=Path, default=Path("/tmp/craw-comparison-inputs"))
    p.add_argument("--reps", type=int, default=5)
    p.add_argument("--warmups", type=int, default=1)
    p.add_argument("--samples", type=int, default=3)
    p.add_argument("--threads", type=int, nargs="+", default=[1,4])
    p.add_argument("--modes", nargs="+", choices=MODES, default=MODES)
    p.add_argument("--device", help="ADB serial; never auto-select a device")
    p.add_argument("--adb", default=shutil.which("adb") or "adb")
    p.add_argument("--jxl-source", type=Path)
    p.add_argument("--sustain", type=int, default=0, help="Seconds per operation for --sustain-modes on first frame")
    p.add_argument("--sustain-modes", nargs="+", choices=MODES, default=["craw3", "jxl-e1-planes"])
    p.add_argument("--sustain-only", action="store_true")
    p.add_argument("--report-only", action="store_true")
    a = p.parse_args()
    if a.report_only:
        report(a.out); return
    if not a.binary or not a.takes or a.reps < 1 or a.samples < 1 or min(a.threads) < 1 or a.sustain < 0:
        p.error("provide --binary and --takes; counts must be positive")
    a.out.mkdir(parents=True, exist_ok=True); a.work.mkdir(parents=True, exist_ok=True)
    (a.out/"measurements").mkdir(exist_ok=True)
    adb = [a.adb,"-s",a.device] if a.device else None
    remote = "/data/local/tmp/craw-comparison-20261030"
    if adb:
        command(adb+["shell","mkdir","-p",remote]); command(adb+["push",a.binary,remote+"/craw_compare"])
        command(adb+["shell","chmod","755",remote+"/craw_compare"])
        device_info = command(adb+["shell", "getprop ro.product.model; getprop ro.soc.model; getprop ro.build.version.release; getprop ro.build.fingerprint; uname -a"])
    else:
        device_info = command(["uname","-a"])
    root = Path(__file__).resolve().parents[3]
    revisions = {}
    for name in ("CinematicRAWStudio-Spec","CinematicRAWStudio-Encoder","CinematicRAWStudio-Decoder","CinematicRAWStudio-TUI"):
        repo = root/name
        revisions[name] = {"head":command(["git","-C",repo,"rev-parse","HEAD"]),"status":command(["git","-C",repo,"status","--short"])}
    if a.jxl_source:
        revisions["libjxl"] = {"head":command(["git","-C",a.jxl_source,"rev-parse","HEAD"]),
                               "submodules":command(["git","-C",a.jxl_source,"submodule","status"])}
    sources = []; samples = []
    extractor = a.host_binary or a.binary
    for ti, take in enumerate(a.takes):
        source_hash = sha(take)
        sources.append({"name":take.name,"sha256":source_hash,"bytes":take.stat().st_size})
        first_path = a.work/f"take{ti}-frame0.raw"
        info = json.loads(command([extractor,"extract",take,0,first_path]))
        indices = sorted({round(i*(info["frame_count"]-1)/max(1,a.samples-1)) for i in range(a.samples)})
        for index in indices:
            sid = f"take{ti}-frame{index}"
            raw = a.work/f"{sid}.raw"
            data = info if index==0 else json.loads(command([extractor,"extract",take,index,raw]))
            sample = dict(data,id=sid,source=take.name,frame_index=index,raw_sha256=sha(raw))
            samples.append(sample)
            if adb:
                command(adb+["push",raw,remote+"/"+raw.name])
                pushed_hash = command(adb+["shell","sha256sum",remote+"/"+raw.name]).split()[0]
                if pushed_hash != sample["raw_sha256"]:
                    raise RuntimeError("pushed RAW hash differs from corpus")
    manifest = {"schema":1,"started_utc":time.strftime("%Y-%m-%dT%H:%M:%SZ",time.gmtime()),
                "platform":f"Android {a.device}" if adb else platform.platform(),"system":device_info,
                "binary_sha256":sha(a.binary),"revisions":revisions,"sources":sources,"samples":samples,
                "reps":a.reps,"warmups":a.warmups,"threads":a.threads,"modes":a.modes,
                "driver_sha256":sha(Path(__file__)),"native_source_sha256":sha(Path(__file__).with_name("compare.cpp")),
                "invocation":shlex.join(os.sys.argv),"device":a.device}
    manifest_path = a.out/"manifest.json"
    if manifest_path.exists():
        old = json.loads(manifest_path.read_text())
        for key in ("binary_sha256","sources","samples","reps","warmups","threads","modes"):
            if old[key] != manifest[key]:
                raise RuntimeError(f"Output contains a different run ({key}); use a fresh --out")
    else:
        save(manifest_path,manifest)
    jobs = [] if a.sustain_only else [(s,m,t,0) for s in samples for m in a.modes for t in a.threads]
    random.Random(20261030).shuffle(jobs)
    if a.sustain:
        jobs += [(samples[0],m,max(a.threads),a.sustain) for m in a.sustain_modes]
    def snapshot():
        return command(adb+["shell","dumpsys thermalservice; dumpsys battery; cat /proc/meminfo; for f in /sys/devices/system/cpu/cpufreq/policy*/scaling_cur_freq; do echo $f; cat $f; done"])
    for job_index,(s,mode,threads,seconds) in enumerate(jobs):
        key = f"{s['id']}-{mode}-t{threads}-s{seconds}"
        result_path = a.out/"measurements"/(key+".json")
        if result_path.exists():
            continue
        print(f"[{job_index+1}/{len(jobs)}] {key}",flush=True)
        result = {"sample":s["id"],"mode":mode,"threads":threads,"sustained_seconds":seconds,"commands":{}}
        raw = (remote+"/"+s["id"]+".raw") if adb else str(a.work/(s["id"]+".raw"))
        payload = remote+"/payload.bin" if adb else str(a.work/"payload.bin")
        for op in ("encode","decode"):
            cmd = [remote+"/craw_compare" if adb else str(a.binary),"measure",raw,s["width"],s["height"],s["bits"],s["cfa"],mode,threads,op,payload,a.reps,seconds,a.warmups]
            cmd = [str(x) for x in cmd]
            actual = adb+["shell",shlex.join(cmd)] if adb else cmd
            result["commands"][op] = actual
            stop = threading.Event(); trace = []
            def monitor():
                start = time.monotonic()
                while not stop.is_set():
                    try:
                        trace.append({"elapsed_seconds":time.monotonic()-start,"snapshot":snapshot()})
                    except subprocess.CalledProcessError as e:
                        trace.append({"error":str(e)})
                    stop.wait(5)
            thread = threading.Thread(target=monitor) if adb and seconds else None
            if thread: thread.start()
            try:
                result[op] = json.loads(command(actual))
            finally:
                stop.set()
                if thread: thread.join()
            if trace: result[op+"_device_trace"] = trace
        if not result["decode"]["verified"] or result["encode"]["payload_bytes"] != result["decode"]["payload_bytes"]:
            raise RuntimeError("round-trip verification failed")
        save(result_path,result)
        report(a.out)
    report(a.out)


if __name__ == "__main__":
    main()
