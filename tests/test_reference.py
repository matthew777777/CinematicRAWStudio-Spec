# SPDX-License-Identifier: Apache-2.0
import os
import pathlib
import sys
import tempfile
import unittest

import numpy as np

sys.path.insert(0, str(pathlib.Path(__file__).parent.parent / "reference"))
import craw  # noqa: E402


class RoundTrip(unittest.TestCase):
    def test_all_cfa_and_depths(self):
        rng = np.random.default_rng(1)
        for bits in (8, 10, 12, 14, 16):
            for cfa in range(4):
                raw = rng.integers(0, 1 << bits, (18, 26), dtype=np.uint16)
                back, info = craw.decode_frame(craw.encode_frame(raw, bits, cfa, tile=7))
                np.testing.assert_array_equal(back, raw)
                self.assertEqual(info["cfa"], cfa)

    def test_live_codec_all_cfa_and_depths(self):
        rng = np.random.default_rng(2)
        for bits in (8, 10, 12, 16):
            for cfa in range(4):
                raw = rng.integers(0, 1 << bits, (18, 38), dtype=np.uint16)
                back, info = craw.decode_frame(craw.encode_frame(raw, bits, cfa, tile=13, codec=2))
                np.testing.assert_array_equal(back, raw)

    def test_live2_codec_round_trip(self):
        rng = np.random.default_rng(3)
        for bits in (8, 10, 12, 16):
            for cfa in range(4):
                raw = rng.integers(0, 1 << bits, (18, 38), dtype=np.uint16)
                back, _ = craw.decode_frame(craw.encode_frame(raw, bits, cfa, tile=13, codec=3, frame_crc=False))
                np.testing.assert_array_equal(back, raw)
        yy, xx = np.mgrid[0:40, 0:70]
        smooth = ((xx * 5 + yy * 3) % 1024 + rng.integers(0, 9, xx.shape)).astype(np.uint16)
        back, _ = craw.decode_frame(craw.encode_frame(smooth, 10, 2, tile=32, codec=3))
        np.testing.assert_array_equal(back, smooth)

    def test_rgb_frame_round_trip(self):
        rng = np.random.default_rng(4)
        rgb = rng.integers(0, 1024, (11, 17, 3), dtype=np.uint16)
        cells = craw.rgb_to_cells(rgb)
        for codec in (2, 3):
            back, info = craw.decode_frame(craw.encode_frame(cells, 10, craw.CFA_RGB, tile=7, codec=codec))
            np.testing.assert_array_equal(craw.cells_to_rgb(back), rgb)
            self.assertEqual(info["cfa"], craw.CFA_RGB)
        with self.assertRaises(ValueError):
            craw.encode_frame(cells, 10, craw.CFA_RGB, codec=1)

    def test_rejects_out_of_range(self):
        with self.assertRaises(ValueError):
            craw.encode_frame(np.full((4, 4), 1024, np.uint16), 10, 0)

    def test_corruption_detected(self):
        raw = np.arange(16 * 16, dtype=np.uint16).reshape(16, 16) % 1024
        p = bytearray(craw.encode_frame(raw, 10, 0))
        p[-1] ^= 0x55
        with self.assertRaises(Exception):
            craw.decode_frame(bytes(p))

    def test_container_and_recovery(self):
        raw = (np.arange(32 * 32, dtype=np.uint16).reshape(32, 32) * 3) % 1024
        with tempfile.TemporaryDirectory() as d:
            path = os.path.join(d, "t.craw")
            w = craw.Writer(path, {"sensor": {"width": 32, "height": 32}})
            w.add_shading(0, 1, 2, 2, [1.0] * 16)
            for i in range(3):
                w.add_frame(raw, i * 33_333_333, 10, 0, {"iso": 100})
            w.add_audio(0, 2, 2, 48000, b"\0" * 64, 8)
            w.add_imu(1, [(0, 0.1, 0.2, 0.3), (5_000_000, 0.0, 0.0, 0.0)])
            w.close()
            kinds = [c[0] for c in craw.read_chunks(path)]
            self.assertEqual(kinds, [b"META", b"LSHD", b"FRAM", b"FRAM", b"FRAM",
                                     b"AUDI", b"IMU_", b"INDX"])
            data = open(path, "rb").read()
            open(path, "wb").write(data[: len(data) // 2])  # simulated crash
            got = [c for c in craw.read_chunks(path)]
            self.assertTrue(all(c[3] for c in got))
            self.assertGreaterEqual(len(got), 2)


if __name__ == "__main__":
    unittest.main()
