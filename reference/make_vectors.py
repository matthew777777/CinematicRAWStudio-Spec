# SPDX-License-Identifier: Apache-2.0
"""Generates golden vectors: <name>.raw (u16 LE) + <name>.payload + manifest.json.

The C++ encoder must reproduce every payload byte-for-byte and the C++ decoder
must reproduce every raw frame.
"""
import hashlib
import json
import pathlib
import sys

import numpy as np

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import craw  # noqa: E402


def cases():
    rng = np.random.default_rng(20261027)
    yy, xx = np.mgrid[0:96, 0:128]
    grad = ((xx * 7 + yy * 3) % 1024).astype(np.uint16)
    yield "flat10_rggb", np.full((32, 48), 64, np.uint16), 10, 0, 128
    yield "gradient10_grbg", grad, 10, 1, 128
    yield "noise12_gbrg", rng.integers(0, 4096, (64, 80), dtype=np.uint16), 12, 2, 128
    scene = (np.clip(512 + 300 * np.sin(xx / 9.0) * np.cos(yy / 7.0)
                     + rng.normal(0, 6, xx.shape), 0, 1023)).astype(np.uint16)
    yield "scene10_bggr_tile16", scene, 10, 3, 16
    yield "edges_tile5", np.where(rng.random((22, 34)) < 0.5, 0, 65535).astype(np.uint16), 16, 0, 5
    yield "scene14_rggb_tile32", (scene.astype(np.uint32) * 16).astype(np.uint16), 14, 0, 32


def main(out_dir):
    out = pathlib.Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    manifest = []
    for name, raw, bits, cfa, tile in cases():
        payload = craw.encode_frame(raw, bits, cfa, tile)
        back, _ = craw.decode_frame(payload)
        assert np.array_equal(back, raw), name
        (out / f"{name}.raw").write_bytes(raw.astype("<u2").tobytes())
        (out / f"{name}.payload").write_bytes(payload)
        manifest.append({"name": name, "width": raw.shape[1], "height": raw.shape[0],
                         "bit_depth": bits, "cfa": cfa, "tile": tile,
                         "rice_init": craw.default_rice_init(bits),
                         "payload_sha256": hashlib.sha256(payload).hexdigest(),
                         "payload_size": len(payload), "raw_size": raw.nbytes})
        print(f"{name:24s} {raw.nbytes:7d} -> {len(payload):7d}  "
              f"({16 * len(payload) / raw.nbytes:.2f} bpp)")
    (out / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else pathlib.Path(__file__).parent.parent / "vectors")
