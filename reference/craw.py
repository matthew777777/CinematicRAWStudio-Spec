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
VERSION = (0, 2)

# (G1, G2, R, B) positions in the 2x2 cell, index = py * 2 + px.
CFA_LAYOUT = {
    0: (1, 2, 0, 3),  # RGGB
    1: (0, 3, 1, 2),  # GRBG
    2: (0, 3, 2, 1),  # GBRG
    3: (1, 2, 3, 0),  # BGGR
}
CFA_NAMES = {"RGGB": 0, "GRBG": 1, "GBRG": 2, "BGGR": 3, "RGB": 4}
CFA_RGB = 4  # SPEC 3.8: cells (0,0)=R, (0,1)=G, (1,0)=B, (1,1)=0


def rgb_to_cells(rgb: np.ndarray) -> np.ndarray:
    """(H, W, 3) RGB -> (2H, 2W) cell frame for cfa = 4."""
    h, w, _ = rgb.shape
    out = np.zeros((2 * h, 2 * w), np.uint16)
    out[0::2, 0::2], out[0::2, 1::2], out[1::2, 0::2] = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    return out


def cells_to_rgb(cells: np.ndarray) -> np.ndarray:
    return np.stack([cells[0::2, 0::2], cells[0::2, 1::2], cells[1::2, 0::2]], -1)

RICE_LIMIT = 24
ESCAPE_BITS = 24


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


BLOCK = 16
MAX_BLOCK_K = 16


def _residuals(p, first_pred):
    """Zigzag MED residuals of one tile plane (SPEC 3.4); p is a list of rows."""
    h, w = len(p), len(p[0])
    out = [[0] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            if x == 0 and y == 0:
                pred = first_pred
            elif y == 0:
                pred = p[y][x - 1]
            elif x == 0:
                pred = p[y - 1][x]
            else:
                pred = _med(p[y][x - 1], p[y - 1][x], p[y - 1][x - 1])
            e = p[y][x] - pred
            out[y][x] = 2 * e if e >= 0 else -2 * e - 1
    return out


def _med(a, b, c):
    if c >= max(a, b):
        return min(a, b)
    if c <= min(a, b):
        return max(a, b)
    return a + b - c


def _block_k(y, bx, sums, lens, rice_init):
    """k for block bx of row y from causal block sums (SPEC 3.4)."""
    n = lens[bx]
    up = (sums[y - 1][bx] * BLOCK) // n if y > 0 else None
    left = sums[y][bx - 1] if bx > 0 else None
    if up is None and left is None:
        s = rice_init * 2 * BLOCK
    elif up is None:
        s = 2 * left
    elif left is None:
        s = 2 * up
    else:
        s = up + left
    v = (s * 11) >> 4
    return min(((v >> 5) + 1).bit_length() - 1, MAX_BLOCK_K)


def _block_lens(w):
    return [min(BLOCK, w - x) for x in range(0, w, BLOCK)]


def _put_code(bw, u, k):
    q = u >> k
    if q < RICE_LIMIT:
        bw.put(1, q + 1)
        bw.put(u, k)
    else:
        bw.put(1, RICE_LIMIT + 1)
        bw.put(u, ESCAPE_BITS)


def _encode_plane(bw, p, first_pred, rice_init):
    u = _residuals(p, first_pred)
    lens = _block_lens(len(p[0]))
    sums = []
    for y, row in enumerate(u):
        sums.append([sum(row[i * BLOCK:i * BLOCK + n]) for i, n in enumerate(lens)])
        for bx, n in enumerate(lens):
            k = _block_k(y, bx, sums, lens, rice_init)
            for x in range(bx * BLOCK, bx * BLOCK + n):
                _put_code(bw, row[x], k)


def _decode_plane(br, w, h, first_pred, rice_init):
    lens = _block_lens(w)
    p = [[0] * w for _ in range(h)]
    sums = []
    for y in range(h):
        sums.append([0] * len(lens))
        for bx, n in enumerate(lens):
            k = _block_k(y, bx, sums, lens, rice_init)
            for x in range(bx * BLOCK, bx * BLOCK + n):
                q = br.zeros_then_one(RICE_LIMIT)
                u = (q << k) | br.get(k) if q < RICE_LIMIT else br.get(ESCAPE_BITS)
                sums[y][bx] += u
                e = u >> 1 if u & 1 == 0 else -((u + 1) >> 1)
                if x == 0 and y == 0:
                    pred = first_pred
                elif y == 0:
                    pred = p[y][x - 1]
                elif x == 0:
                    pred = p[y - 1][x]
                else:
                    pred = _med(p[y][x - 1], p[y - 1][x], p[y - 1][x - 1])
                p[y][x] = pred + e
    return p


# ---------------------------------------------------------- codec 2: CRAW-Live

def _live_residuals(p, first_pred):
    """CRAW-Live prediction (SPEC 3.6): left neighbour in the plane; the first
    sample of a row uses the sample above (first_pred for the very first)."""
    out = []
    for y, row in enumerate(p):
        prev = first_pred if y == 0 else p[y - 1][0]
        r = []
        for v in row:
            e = v - prev
            r.append(2 * e if e >= 0 else -2 * e - 1)
            prev = v
        out.append(r)
    return out


def _live_encode_row(widths, data, p, y, first_pred):
    """Fixed-width packing per 16-sample block of plane row y (SPEC 3.6)."""
    prev = first_pred if y == 0 else p[y - 1][0]
    row = []
    for v in p[y]:
        e = v - prev
        row.append(2 * e if e >= 0 else -2 * e - 1)
        prev = v
    if True:
        for x0 in range(0, len(row), BLOCK):
            blk = row[x0:x0 + BLOCK]
            w = max(blk).bit_length()
            if w < 15:
                widths.append(w)
            else:
                widths.extend([15, w - 15])
            acc, n = 0, 0
            for v in blk:
                acc |= v << n
                n += w
            data.extend(acc.to_bytes((n + 7) // 8, "little") if n else b"")


def _live_decode_row(nibbles, data, pos, p, y, w_, first_pred):
    if True:
        prev = first_pred if y == 0 else p[y - 1][0]
        for x0 in range(0, w_, BLOCK):
            n = min(BLOCK, w_ - x0)
            w = next(nibbles)
            if w == 15:
                w = 15 + next(nibbles)
            nbytes = (n * w + 7) // 8
            acc = int.from_bytes(data[pos:pos + nbytes], "little")
            pos += nbytes
            for i in range(n):
                u = (acc >> (i * w)) & ((1 << w) - 1)
                prev = prev + (u >> 1 if u & 1 == 0 else -((u + 1) >> 1))
                p[y][x0 + i] = prev
    return pos


# ------------------------------------------------- codec 3: CRAW-Live v2 (PFOR)

PFOR_MAX_EXC = 15


def _avg4_pred(p, x, y, first_pred):
    """SPEC 3.7 prediction inside one tile plane."""
    w = len(p[0])
    if y == 0:
        return first_pred if x == 0 else p[0][x - 1]
    if x == 0:
        return p[y - 1][0]
    L, U, UL = p[y][x - 1], p[y - 1][x], p[y - 1][x - 1]
    UR = p[y - 1][x + 1] if x + 1 < w else U
    return (L + U + UL + UR + 2) >> 2


def _width_nibbles(out, v):
    if v < 15:
        out.append(v)
    else:
        out.extend([15, v - 15])


def _read_width(nibbles):
    v = next(nibbles)
    return v + next(nibbles) if v == 15 else v


def _pack_bits(data, values, w):
    acc, n = 0, 0
    for v in values:
        acc |= v << n
        n += w
    data.extend(acc.to_bytes((n + 7) // 8, "little") if n else b"")


PFOR_TAG = 14   # first nibble: 0..13 plain width, 14 PFOR block, 15 escape (14 + next)


def _pfor_choose(blk, pfor=True):
    """(k, exceptions, bw) minimising the block's bits (SPEC 3.7)."""
    bw = max(blk).bit_length()
    plain = len(blk) * bw + (4 if bw < 14 else 8)
    best = (plain, bw, [])
    for k in (range(max(0, bw - 8), bw) if pfor else ()):
        exc = [i for i, v in enumerate(blk) if v >> k]
        if not exc or len(exc) > PFOR_MAX_EXC:
            continue
        hb = bw - k
        # tag + k + count + high width + one index nibble per exception
        cost = len(blk) * k + 4 + (4 if k < 15 else 8) + 4 + (4 if hb < 15 else 8) + len(exc) * (4 + hb)
        if cost < best[0]:
            best = (cost, k, exc)
    return best[1], best[2], bw


def _pfor_encode_row(nib, data, u, pfor=False):
    for x0 in range(0, len(u), BLOCK):
        blk = u[x0:x0 + BLOCK]
        k, exc, bw = _pfor_choose(blk, pfor)
        if not exc:
            if bw < PFOR_TAG:
                nib.append(bw)
            else:
                nib.extend([15, bw - PFOR_TAG])  # escape: width 14..29
            _pack_bits(data, blk, bw)
            continue
        nib.append(PFOR_TAG)
        _width_nibbles(nib, k)
        nib.append(len(exc))
        hb = bw - k
        _width_nibbles(nib, hb)
        nib.extend(exc)
        mask = (1 << k) - 1
        _pack_bits(data, [v & mask for v in blk], k)
        _pack_bits(data, [blk[i] >> k for i in exc], hb)


def _unpack_bits(data, pos, count, w):
    nbytes = (count * w + 7) // 8
    acc = int.from_bytes(data[pos:pos + nbytes], "little")
    return [(acc >> (i * w)) & ((1 << w) - 1) for i in range(count)], pos + nbytes


def _pfor_decode_row(nibbles, data, pos, width):
    u = []
    for x0 in range(0, width, BLOCK):
        n = min(BLOCK, width - x0)
        t = next(nibbles)
        if t != PFOR_TAG:
            w = t if t < 15 else PFOR_TAG + next(nibbles)
            vals, pos = _unpack_bits(data, pos, n, w)
            u.extend(vals)
            continue
        k = _read_width(nibbles)
        ne = next(nibbles)
        hb = _read_width(nibbles)
        idx = [next(nibbles) for _ in range(ne)]
        low, pos = _unpack_bits(data, pos, n, k)
        high, pos = _unpack_bits(data, pos, ne, hb)
        for i, h in zip(idx, high):
            low[i] |= h << k
        u.extend(low)
    return u, pos


def _unzigzag(u):
    return u >> 1 if u & 1 == 0 else -((u + 1) >> 1)


def _pack_nibbles(ns):
    out = bytearray((len(ns) + 1) // 2)
    for i, v in enumerate(ns):
        out[i // 2] |= v << (4 * (i & 1))
    return bytes(out)


def _iter_nibbles(b):
    for byte in b:
        yield byte & 15
        yield byte >> 4


def split_planes(raw):
    return [raw[py::2, px::2] for py in (0, 1) for px in (0, 1)]


# ------------------------------------------------- codec 4: Desktop Compact

def _compact_pred(p, x, y, first, mode):
    if not y:
        return p[y][x - 1] if x else first
    if not x:
        return p[y - 1][0]
    L, U, UL = p[y][x - 1], p[y - 1][x], p[y - 1][x - 1]
    UR = p[y - 1][min(x + 1, len(p[0]) - 1)]
    if mode == 1:
        return _med(L, U, UL)
    if mode == 2:
        return (L + U + 1) >> 1
    if mode == 3:
        return (2 * L + U + UR + 2) >> 2
    return (L + U + UL + UR + 2) >> 2


def _compact_encode(subs, first):
    best = None
    for mode in range(4):
        blocks, ks, cost = [], [], 0
        for p in subs:
            for y, row in enumerate(p):
                u = []
                for x, v in enumerate(row):
                    e = v - _compact_pred(p, x, y, first, mode)
                    u.append(2 * e if e >= 0 else -2 * e - 1)
                for x in range(0, len(row), 16):
                    b = u[x:x + 16]
                    costs = [sum((v >> k) + 1 + k if (v >> k) < 24 else 49 for v in b) for k in range(16)]
                    k = min(range(16), key=lambda k: costs[k])
                    blocks.append(b)
                    ks.append(k)
                    cost += costs[k]
        if best is None or cost < best[0]:
            best = cost, mode, blocks, ks
    _, mode, blocks, ks = best
    bw = BitWriter()
    for b, k in zip(blocks, ks):
        for u in b:
            q = u >> k
            if q < 24:
                bw.put(1, q + 1)
                bw.put(u, k)
            else:
                bw.put(1, 25)
                bw.put(u, 24)
    return bytes([mode]) + _pack_nibbles(ks) + bw.finish()


def _compact_decode(data, tw, th, first):
    mode = data[1]
    if mode > 3:
        raise ValueError("bad compact predictor")
    nb = (4 * th * ((tw + 15) // 16) + 1) // 2
    ks = _iter_nibbles(data[2:2 + nb])
    br = BitReader(data[2 + nb:])
    cells = [[[0] * tw for _ in range(th)] for _ in range(4)]
    for p in cells:
        for y in range(th):
            for x0 in range(0, tw, 16):
                k = next(ks)
                for x in range(x0, min(x0 + 16, tw)):
                    q = br.zeros_then_one(24)
                    u = br.get(24) if q == 24 else (q << k) | br.get(k)
                    v = _compact_pred(p, x, y, first, mode) + _unzigzag(u)
                    if not 0 <= v <= 65535:
                        raise ValueError("compact sample out of range")
                    p[y][x] = v
    return cells


def encode_frame(raw: np.ndarray, bit_depth: int, cfa: int, tile: int = 128,
                 rice_init: int | None = None, codec: int = 1, frame_crc: bool = True,
                 pfor: bool = False) -> bytes:
    """Encodes a (H, W) uint16 Bayer frame into a codec payload (SPEC 3.1)."""
    raw = np.ascontiguousarray(raw, dtype=np.uint16)
    h, w = raw.shape
    if w % 2 or h % 2:
        raise ValueError("width and height must be even")
    if cfa == CFA_RGB and codec not in (2, 3, 4):
        raise ValueError("RGB frames (cfa 4) need codec 2, 3 or 4")
    if cfa == CFA_RGB and raw[1::2, 1::2].any():
        raise ValueError("RGB frames: the unused cell must be zero")
    if int(raw.max(initial=0)) >= 1 << bit_depth:
        raise ValueError("sample exceeds bit depth")
    if rice_init is None:
        rice_init = default_rice_init(bit_depth)
    planes = split_planes(raw)
    # Codec 1 reorders planes by colour; codecs 2/3/4 code cells by position.
    g1i, g2i, ri, bi = CFA_LAYOUT[cfa] if cfa in CFA_LAYOUT else (0, 1, 2, 3)
    ordered = [planes[g1i], planes[g2i], planes[ri], planes[bi]]
    g1 = ordered[0].astype(np.int64)
    coded = [g1] + [o.astype(np.int64) - g1 for o in ordered[1:]]
    pw, ph = w // 2, h // 2
    tiles = []
    for ty in range(0, ph, tile):
        for tx in range(0, pw, tile):
            if codec == 4:
                subs = [pl[ty:ty + tile, tx:tx + tile].astype(np.int64).tolist() for pl in planes]
                body = _compact_encode(subs, 1 << (bit_depth - 1))
            elif codec == 3:
                nib, data = [], bytearray()
                subs = [pl[ty:ty + tile, tx:tx + tile].astype(np.int64).tolist() for pl in planes]
                first = 1 << (bit_depth - 1)
                for y in range(len(subs[0])):
                    for cell in range(4):
                        p = subs[cell]
                        u = []
                        for x in range(len(p[0])):
                            e = p[y][x] - _avg4_pred(p, x, y, first)
                            u.append(2 * e if e >= 0 else -2 * e - 1)
                        _pfor_encode_row(nib, data, u, pfor)
                packed = _pack_nibbles(nib)
                body = struct.pack("<I", len(packed)) + packed + bytes(data)
            elif codec == 2:
                # Rows of the tile, then cells (py, px) in order; no colour transform.
                widths, data = [], bytearray()
                subs = [pl[ty:ty + tile, tx:tx + tile].astype(np.int64).tolist() for pl in planes]
                for y in range(len(subs[0])):
                    for cell in range(4):
                        _live_encode_row(widths, data, subs[cell], y, 1 << (bit_depth - 1))
                nib = _pack_nibbles(widths)
                body = struct.pack("<I", len(nib)) + nib + bytes(data)
            else:
                bw = BitWriter()
                for i, plane in enumerate(coded):
                    sub = plane[ty:ty + tile, tx:tx + tile].tolist()
                    first = 1 << (bit_depth - 1) if i == 0 else 0
                    _encode_plane(bw, sub, first, rice_init)
                body = bw.finish()
            stored = b"".join(o[ty:ty + tile, tx:tx + tile].astype("<u2").tobytes()
                              for o in (planes if codec in (2, 3, 4) else ordered))
            tiles.append(b"\0" + body if len(body) < len(stored) else b"\1" + stored)
    offsets = [0]
    for t in tiles:
        offsets.append(offsets[-1] + len(t))
    head = struct.pack("<BBBBIIHHII", codec, bit_depth, cfa, 0 if frame_crc else 1, w, h, tile, rice_init,
                       crc32c(raw.astype("<u2").tobytes()) if frame_crc else 0, len(tiles))
    return head + struct.pack(f"<{len(offsets)}I", *offsets) + b"".join(tiles)


def decode_frame(payload: bytes) -> tuple[np.ndarray, dict]:
    codec, bit_depth, cfa, flags, w, h, tile, rice_init, crc, count = \
        struct.unpack_from("<BBBBIIHHII", payload, 0)
    if codec not in (1, 2, 3, 4):
        raise ValueError(f"unknown codec {codec}")
    pos = 24
    offsets = struct.unpack_from(f"<{count + 1}I", payload, pos)
    base = pos + 4 * (count + 1)
    pw, ph = w // 2, h // 2
    ordered = [np.zeros((ph, pw), np.int64) for _ in range(4)]
    live = [[np.zeros((ph, pw), np.int64) for _ in range(2)] for _ in range(2)]
    t = 0
    for ty in range(0, ph, tile):
        for tx in range(0, pw, tile):
            th, tw = min(tile, ph - ty), min(tile, pw - tx)
            data = payload[base + offsets[t]: base + offsets[t + 1]]
            if data[0] == 1:
                vals = np.frombuffer(data[1:], "<u2").astype(np.int64).reshape(4, th, tw)
                for i in range(4):
                    if codec in (2, 3, 4):
                        live[i >> 1][i & 1][ty:ty + th, tx:tx + tw] = vals[i]
                    else:
                        ordered[i][ty:ty + th, tx:tx + tw] = vals[i]
            elif codec == 4:
                cells = _compact_decode(data, tw, th, 1 << (bit_depth - 1))
                for cell in range(4):
                    live[cell >> 1][cell & 1][ty:ty + th, tx:tx + tw] = np.array(cells[cell])
            elif codec == 3:
                (nlen,) = struct.unpack_from("<I", data, 1)
                nibbles = _iter_nibbles(data[5:5 + nlen])
                body, pos = data[5 + nlen:], 0
                cells = [[[0] * tw for _ in range(th)] for _ in range(4)]
                first = 1 << (bit_depth - 1)
                for y in range(th):
                    for cell in range(4):
                        u, pos = _pfor_decode_row(nibbles, body, pos, tw)
                        p = cells[cell]
                        for x in range(tw):
                            p[y][x] = _avg4_pred(p, x, y, first) + _unzigzag(u[x])
                for cell in range(4):
                    live[cell >> 1][cell & 1][ty:ty + th, tx:tx + tw] = np.array(cells[cell])
            elif codec == 2:
                (nlen,) = struct.unpack_from("<I", data, 1)
                nibbles = _iter_nibbles(data[5:5 + nlen])
                body, pos = data[5 + nlen:], 0
                cells = [[[0] * tw for _ in range(th)] for _ in range(4)]
                for y in range(th):
                    for cell in range(4):
                        pos = _live_decode_row(nibbles, body, pos, cells[cell], y, tw, 1 << (bit_depth - 1))
                for cell in range(4):
                    live[cell >> 1][cell & 1][ty:ty + th, tx:tx + tw] = np.array(cells[cell])
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
    if codec in (2, 3, 4):
        for py in (0, 1):
            for px in (0, 1):
                raw[py::2, px::2] = live[py][px]
    else:
        g1i, g2i, ri, bi = CFA_LAYOUT[cfa]
        for plane, pos_i in zip(ordered, (g1i, g2i, ri, bi)):
            raw[pos_i // 2::2, pos_i % 2::2] = plane
    if not (flags & 1) and crc32c(raw.astype("<u2").tobytes()) != crc:
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
