#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Check actual-bit-depth round trips, both JXL layouts, and invalid inputs."""
import argparse
import json
from pathlib import Path
import random
import struct
import subprocess
import tempfile
from run import MODES


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--binary", type=Path, required=True)
    a = p.parse_args()
    count = 0
    with tempfile.TemporaryDirectory(prefix="craw-compare-selftest-") as tmp:
        root = Path(tmp); raw = root/"input.raw"; payload = root/"payload.bin"
        for bits in (10,12,14,16):
            rng = random.Random(bits)
            # Non-tile-aligned dimensions and full source range, including endpoints.
            values = [rng.randrange(1 << bits) for _ in range(34*22)]
            values[0]=0; values[-1]=(1 << bits)-1
            raw.write_bytes(struct.pack("<"+"H"*len(values), *values))
            for mode in MODES:
                for threads in (1,4):
                    prefix = [str(a.binary),"measure",str(raw),"34","22",str(bits),"2",mode,str(threads)]
                    def run(op, expect_success=True):
                        result = subprocess.run(prefix+[op,str(payload),"2","0","1"],capture_output=True,text=True)
                        if expect_success:
                            if result.returncode:
                                raise RuntimeError((bits,mode,threads,op,result.stderr))
                            data = json.loads(result.stdout)
                            if op=="decode" and not data["verified"]:
                                raise RuntimeError("unverified decode")
                        elif not result.returncode:
                            raise RuntimeError("invalid input accepted")
                    run("encode"); run("decode")
                    encoded=payload.read_bytes(); payload.write_bytes(encoded[:max(1,len(encoded)//2)])
                    run("decode",False); count += 1
        raw.write_bytes(b"\0")
        result = subprocess.run([str(a.binary),"measure",str(raw),"34","22","10","2","craw3","1","encode",str(payload),"1","0","0"],capture_output=True)
        if not result.returncode:
            raise RuntimeError("wrong RAW size accepted")
    print(f"PASS: {count} lossless configurations (4 bit depths × 10 modes × 2 thread settings), truncation rejection, invalid RAW size")


if __name__=="__main__":
    main()
