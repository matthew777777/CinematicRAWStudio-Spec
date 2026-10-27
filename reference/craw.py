# SPDX-License-Identifier: Apache-2.0
"""Reference implementation of the .CRAW v0.1 codec and container (SPEC.md).

Written for clarity, not speed: it is the tiebreaker for the C++ encoder and
decoder, and the generator of the golden test vectors.
"""
from __future__ import annotations

import json
import struct

import numpy as np

MAGIC = b"CRAW"
TRAILER_MAGIC = b"CRAWEND\0"
VERSION = (0, 1)

# (G1, G2, R, B) positions in the 2x2 cell, index = py * 2 + px.
CFA_LAYOUT = {
    0: (1, 2, 0, 3),  # RGGB
    1: (0, 3, 1, 2),  # GRBG
    2: (0, 3, 2, 1),  # GBRG
    3: (1, 2, 3, 0),  # BGGR
}
CFA_NAMES = {"RGGB": 0, "GRBG": 1, "GBRG": 2, "BGGR": 3}

RICE_LIMIT = 24
ESCAPE_BITS = 24
MAX_K = 20
CONTEXTS = 16


def _crc32c_table():
    table = []
    for i in range(256):
        c = i
        for _ in range(8):
            c = (c >> 1) ^ 0x82F63B78 if c & 1 else c >> 1
        table.append(c)
    return table


_CRC_TABLE = _crc32c_table()


def crc32c(data: bytes) -> int:
    c = 0xFFFFFFFF
    for byte in data:
        c = _CRC_TABLE[(c ^ byte) & 0xFF] ^ (c >> 8)
    return c ^ 0xFFFFFFFF


def default_rice_init(bit_depth: int) -> int:
    return max(1, 1 << max(bit_depth - 8, 0)) * 4


class BitWriter:
    def __init__(self):
        self.out = bytearray()
        self.acc = 0
        self.n = 0

    def put(self, value: int, bits: int):
        self.acc = (self.acc << bits) | (value & ((1 << bits) - 1))
        self.n += bits
        while self.n >= 8:
            self.n -= 8
            self.out.append((self.acc >> self.n) & 0xFF)
        self.acc &= (1 << self.n) - 1

    def finish(self) -> bytes:
        if self.n:
            self.out.append((self.acc << (8 - self.n)) & 0xFF)
            self.n = 0
            self.acc = 0
        return bytes(self.out)


class BitReader:
    def __init__(self, data: bytes):
        self.data = data
        self.pos = 0  # bit position

    def get(self, bits: int) -> int:
        v = 0
        for _ in range(bits):
            byte = self.data[self.pos >> 3]
            v = (v << 1) | ((byte >> (7 - (self.pos & 7))) & 1)
            self.pos += 1
        return v

    def zeros_then_one(self, limit: int) -> int:
        q = 0
        while q < limit and self.get(1) == 0:
            q += 1
        if q == limit:
            if self.get(1) != 1:
                raise ValueError("bad escape")
        return q


def _neighbours(p, x, y):
    if x == 0 and y == 0:
        return None
    if y == 0:
        a = p[y][x - 1]
        return a, a, a
    if x == 0:
        b = p[y - 1][x]
        return b, b, b
    return p[y][x - 1], p[y - 1][x], p[y - 1][x - 1]


def _predict(nb, first_pred):
    if nb is None:
        return first_pred, 0
    a, b, c = nb
    if c >= max(a, b):
        pred = min(a, b)
    elif c <= min(a, b):
        pred = max(a, b)
    else:
        pred = a + b - c
    g = abs(a - c) + abs(b - c)
    return pred, min(g.bit_length(), CONTEXTS - 1)


def _k(a, n):
    k = 0
    while (n << k) < a and k < MAX_K:
        k += 1
    return k


def _encode_plane(bw, p, first_pred, rice_init):
    A = [rice_init] * CONTEXTS
    N = [1] * CONTEXTS
    h, w = len(p), len(p[0])
    for y in range(h):
        for x in range(w):
            pred, ctx = _predict(_neighbours(p, x, y), first_pred)
            e = p[y][x] - pred
            u = 2 * e if e >= 0 else -2 * e - 1
            k = _k(A[ctx], N[ctx])
            q = u >> k
            if q < RICE_LIMIT:
                bw.put(1, q + 1)
                bw.put(u, k)
            else:
                bw.put(1, RICE_LIMIT + 1)
                bw.put(u, ESCAPE_BITS)
            A[ctx] += u
            N[ctx] += 1
            if N[ctx] == 64:
                A[ctx] >>= 1
                N[ctx] >>= 1


def _decode_plane(br, w, h, first_pred, rice_init):
    A = [rice_init] * CONTEXTS
    N = [1] * CONTEXTS
    p = [[0] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            pred, ctx = _predict(_neighbours(p, x, y), first_pred)
            k = _k(A[ctx], N[ctx])
            q = br.zeros_then_one(RICE_LIMIT)
            if q < RICE_LIMIT:
                u = (q << k) | br.get(k)
            else:
                u = br.get(ESCAPE_BITS)
            e = u >> 1 if u & 1 == 0 else -((u + 1) >> 1)
            p[y][x] = pred + e
            A[ctx] += u
            N[ctx] += 1
            if N[ctx] == 64:
                A[ctx] >>= 1
                N[ctx] >>= 1
    return p


def split_planes(raw):
    return [raw[py::2, px::2] for py in (0, 1) for px in (0, 1)]


def encode_frame(raw: np.ndarray, bit_depth: int, cfa: int, tile: int = 128,
                 rice_init: int | None = None) -> bytes:
    """Encodes a (H, W) uint16 Bayer frame into a codec payload (SPEC 3.1)."""
    raw = np.ascontiguousarray(raw, dtype=np.uint16)
    h, w = raw.shape
    if w % 2 or h % 2:
        raise ValueError("width and height must be even")
    if int(raw.max(initial=0)) >= 1 << bit_depth:
        raise ValueError("sample exceeds bit depth")
    if rice_init is None:
        rice_init = default_rice_init(bit_depth)
    planes = split_planes(raw)
    g1i, g2i, ri, bi = CFA_LAYOUT[cfa]
    ordered = [planes[g1i], planes[g2i], planes[ri], planes[bi]]
    g1 = ordered[0].astype(np.int64)
    coded = [g1] + [o.astype(np.int64) - g1 for o in ordered[1:]]
    pw, ph = w // 2, h // 2
    tiles = []
    for ty in range(0, ph, tile):
        for tx in range(0, pw, tile):
            bw = BitWriter()
            for i, plane in enumerate(coded):
                sub = plane[ty:ty + tile, tx:tx + tile].tolist()
                first = 1 << (bit_depth - 1) if i == 0 else 0
                _encode_plane(bw, sub, first, rice_init)
            body = bw.finish()
            stored = b"".join(o[ty:ty + tile, tx:tx + tile].astype("<u2").tobytes()
                              for o in ordered)
            tiles.append(b"\0" + body if len(body) < len(stored) else b"\1" + stored)
    offsets = [0]
    for t in tiles:
        offsets.append(offsets[-1] + len(t))
    head = struct.pack("<BBBBIIHHII", 1, bit_depth, cfa, 0, w, h, tile, rice_init,
                       crc32c(raw.astype("<u2").tobytes()), len(tiles))
    return head + struct.pack(f"<{len(offsets)}I", *offsets) + b"".join(tiles)


def decode_frame(payload: bytes) -> tuple[np.ndarray, dict]:
    codec, bit_depth, cfa, _, w, h, tile, rice_init, crc, count = \
        struct.unpack_from("<BBBBIIHHII", payload, 0)
    if codec != 1:
        raise ValueError(f"unknown codec {codec}")
    pos = 24
    offsets = struct.unpack_from(f"<{count + 1}I", payload, pos)
    base = pos + 4 * (count + 1)
    pw, ph = w // 2, h // 2
    ordered = [np.zeros((ph, pw), np.int64) for _ in range(4)]
    t = 0
    for ty in range(0, ph, tile):
        for tx in range(0, pw, tile):
            th, tw = min(tile, ph - ty), min(tile, pw - tx)
            data = payload[base + offsets[t]: base + offsets[t + 1]]
            if data[0] == 1:
                vals = np.frombuffer(data[1:], "<u2").astype(np.int64).reshape(4, th, tw)
                for i in range(4):
                    ordered[i][ty:ty + th, tx:tx + tw] = vals[i]
            else:
                br = BitReader(data[1:])
                planes = []
                for i in range(4):
                    first = 1 << (bit_depth - 1) if i == 0 else 0
                    planes.append(np.array(_decode_plane(br, tw, th, first, rice_init)))
                ordered[0][ty:ty + th, tx:tx + tw] = planes[0]
                for i in range(1, 4):
                    ordered[i][ty:ty + th, tx:tx + tw] = planes[i] + planes[0]
            t += 1
    raw = np.zeros((h, w), np.uint16)
    g1i, g2i, ri, bi = CFA_LAYOUT[cfa]
    for plane, pos_i in zip(ordered, (g1i, g2i, ri, bi)):
        raw[pos_i // 2::2, pos_i % 2::2] = plane
    if crc32c(raw.astype("<u2").tobytes()) != crc:
        raise ValueError("frame CRC mismatch")
    return raw, {"bit_depth": bit_depth, "cfa": cfa, "tile": tile, "rice_init": rice_init}


# ---------------------------------------------------------------- container

def chunk(fourcc: bytes, payload: bytes) -> bytes:
    return fourcc + struct.pack("<IQ", 0, len(payload)) + payload + \
        struct.pack("<I", crc32c(payload))


class Writer:
    def __init__(self, path, meta: dict):
        self.f = open(path, "wb")
        self.f.write(MAGIC + struct.pack("<HHII", *VERSION, 0, 0))
        self.f.write(chunk(b"META", json.dumps(meta, sort_keys=True).encode()))
        self.index = []
        self.frames = 0

    def _put(self, fourcc, ts, payload):
        self.index.append((fourcc, self.f.tell(), ts))
        self.f.write(chunk(fourcc, payload))

    def add_frame(self, raw, ts_ns, bit_depth, cfa, frame_meta=None, **kw):
        meta = json.dumps(frame_meta or {}, sort_keys=True).encode()
        body = struct.pack("<QqI", self.frames, ts_ns, len(meta)) + meta + \
            encode_frame(raw, bit_depth, cfa, **kw)
        self._put(b"FRAM", ts_ns, body)
        self.frames += 1

    def add_audio(self, ts_ns, fmt, channels, rate, samples: bytes, frame_count):
        self._put(b"AUDI", ts_ns, struct.pack("<qBBHII", ts_ns, fmt, channels, 0, rate,
                                              frame_count) + samples)

    def add_imu(self, sensor, samples):
        ts = samples[0][0] if samples else 0
        body = struct.pack("<B3xI", sensor, len(samples)) + b"".join(
            struct.pack("<qfff", *s) for s in samples)
        self._put(b"IMU_", ts, body)

    def add_shading(self, ts_ns, map_id, w, h, gains):
        self._put(b"LSHD", ts_ns, struct.pack("<qIHH", ts_ns, map_id, w, h) +
                  np.asarray(gains, "<f4").tobytes())

    def close(self):
        idx_off = self.f.tell()
        body = struct.pack("<I", len(self.index)) + b"".join(
            fc + struct.pack("<IQq", 0, off, ts) for fc, off, ts in self.index)
        self.f.write(chunk(b"INDX", body))
        self.f.write(struct.pack("<Q", idx_off) + TRAILER_MAGIC)
        self.f.close()


def read_chunks(path):
    """Yields (fourcc, offset, payload, crc_ok); recovers crashed files."""
    data = open(path, "rb").read()
    if data[:4] != MAGIC:
        raise ValueError("not a CRAW file")
    major = struct.unpack_from("<H", data, 4)[0]
    if major != VERSION[0]:
        raise ValueError(f"unsupported major version {major}")
    pos = 16
    while pos + 20 <= len(data):
        fourcc = data[pos:pos + 4]
        if fourcc == TRAILER_MAGIC[:4] and data[pos:pos + 8] == TRAILER_MAGIC:
            break
        (n,) = struct.unpack_from("<Q", data, pos + 8)
        end = pos + 16 + n
        if end + 4 > len(data):
            break  # truncated: crashed recording
        payload = data[pos + 16:end]
        (crc,) = struct.unpack_from("<I", data, end)
        yield fourcc, pos, payload, crc == crc32c(payload)
        pos = end + 4
        if fourcc == b"INDX":
            break
