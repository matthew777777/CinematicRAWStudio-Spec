# Cinematic RAW Studio (.CRAW) — Format Specification v0.2 (draft)

SPDX-License-Identifier: Apache-2.0

Status: **draft**. Wire layout may change until v1.0 is frozen. Every rule here
is normative; the Python reference in `reference/craw.py` is the tiebreaker.

All integers are little-endian. `u8/u16/u32/u64` unsigned, `i64` signed,
`f32` IEEE-754 binary32. CRC32C is the Castagnoli CRC (poly `0x82F63B78`,
reflected, init `0xFFFFFFFF`, final xor `0xFFFFFFFF`).

---

## 1. File layout

```
FileHeader          16 bytes
Chunk*              any order after META, see 1.3
INDX chunk          last chunk
Trailer             16 bytes
```

### 1.1 FileHeader

| off | type    | field                                  |
|-----|---------|----------------------------------------|
| 0   | u8[4]   | magic `"CRAW"`                         |
| 4   | u16     | major version = 0                      |
| 6   | u16     | minor version = 2                      |
| 8   | u32     | flags (0; reserved)                    |
| 12  | u32     | reserved, 0                            |

A reader rejects files whose major version it does not know. Minor-version
bumps only add chunk types or JSON keys.

### 1.2 Chunk

| off | type   | field                                         |
|-----|--------|-----------------------------------------------|
| 0   | u8[4]  | fourcc                                        |
| 4   | u32    | flags (0; reserved)                           |
| 8   | u64    | payload size `n`                              |
| 16  | u8[n]  | payload                                       |
| 16+n| u32    | CRC32C of payload                             |

Readers **skip** unknown fourccs (forward compatibility) and report CRC
mismatches per chunk without aborting the whole file.

### 1.3 Chunk types

| fourcc | count       | payload                                     |
|--------|-------------|---------------------------------------------|
| `META` | 1, first    | UTF-8 JSON, static metadata (§2)            |
| `FRAM` | per frame   | §3                                          |
| `LSHD` | on change   | lens shading / vignetting map (§4)          |
| `AUDI` | many        | audio block (§5)                            |
| `IMU_` | many        | gyro / accelerometer block (§6)             |
| `THMB` | ~1 / second | i64 timestamp_ns, then a JPEG               |
| `INDX` | 1, last     | seek index (§7)                             |

### 1.4 Trailer

| off | type  | field                           |
|-----|-------|---------------------------------|
| 0   | u64   | file offset of the INDX chunk   |
| 8   | u8[8] | `"CRAWEND\0"`                   |

A file without a valid trailer is a crashed recording; readers recover it by
scanning chunks forward from offset 16 and stopping at the first truncated
or corrupt chunk.

---

## 2. META (static metadata, JSON)

Self-describing: no external camera database. Keys (unknown keys ignored):

```json
{
  "generator": "CinematicRAWStudio-Encoder 0.1.0",
  "camera": {"make": "...", "model": "...", "camera_id": "0"},
  "sensor": {
    "width": 4080, "height": 3060, "bit_depth": 10,
    "cfa": "RGGB",
    "black_level": [64, 64, 64, 64], "white_level": 1023,
    "active_array": [0, 0, 4080, 3060],
    "color_matrix1": [[n, d], ... 9], "color_matrix2": [...],
    "forward_matrix1": [...], "forward_matrix2": [...],
    "calibration1": [...], "calibration2": [...],
    "illuminant1": 21, "illuminant2": 17,
    "noise_profile": [[S, O], [S, O], [S, O], [S, O]],
    "timestamp_source": "REALTIME"
  },
  "lens": {
    "intrinsics": [fx, fy, cx, cy, s],
    "distortion": [k1, k2, k3, p1, p2],
    "distortion_reference": [x, y, w, h],
    "pose_rotation": [x, y, z, w],
    "pose_translation": [x, y, z],
    "pose_reference": "PRIMARY_CAMERA",
    "focal_lengths": [..], "apertures": [..],
    "facing": "BACK"
  },
  "video": {"fps_num": 30, "fps_den": 1, "timecode_start": "00:00:00:00"},
  "audio": {"sample_rate": 48000, "channels": 2, "format": "F32"}
}
```

Rationals are `[numerator, denominator]` pairs as in DNG. Camera2 key names map
1:1: `LENS_INTRINSIC_CALIBRATION`, `LENS_DISTORTION`,
`LENS_DISTORTION_MAXIMUM_RESOLUTION`, `LENS_POSE_*`, `SENSOR_*`.

---

## 3. FRAM

```
u64  frame_index
i64  timestamp_ns          SENSOR_TIMESTAMP, clock per META.timestamp_source
u32  meta_len
u8[meta_len]  per-frame JSON (exposure_ns, iso, frame_duration_ns,
              focus_distance, aperture, dynamic_black_level, dynamic_white_level,
              awb_gains, ccm, ois_samples, lshd_ref, ...)
u8[]          codec payload (§3.1), to end of chunk
```

### 3.1 Codec payload (codec id 1, "CRAW-Fast")

```
u8   codec_id = 1
u8   bit_depth        1..16; every sample < 2^bit_depth
u8   cfa              0 RGGB, 1 GRBG, 2 GBRG, 3 BGGR
u8   flags            bit 0: frame CRC omitted; other bits reserved (zero)
u32  width            even
u32  height           even
u16  tile             tile edge in plane samples (default 128)
u16  rice_init        initial A of every context (noise class, §3.5)
u32  frame_crc        CRC32C of the raw samples as u16 LE, row-major
u32  tile_count       ceil(W/2/tile) * ceil(H/2/tile)
u32  tile_offset[tile_count + 1]   relative to start of tile data
u8[] tile data
```

### 3.2 Planes

The frame is split into four half-resolution planes by position:
`P[py][px][y][x] = raw[2y+py][2x+px]`. The CFA code names which positions
are green (`G1` = first green in row-major order of the 2x2 cell, `G2` the
other) and which are R and B. Coding order and transform:

| coded plane | value         |
|-------------|---------------|
| 0           | G1            |
| 1           | G2 − G1       |
| 2           | R − G1        |
| 3           | B − G1        |

(at equal plane coordinates). The transform is exactly invertible.

### 3.3 Tiles

Plane space (W/2 × H/2) is cut row-major into `tile × tile` tiles; edge tiles
are smaller. A tile covers the same rectangle in all four planes. Each tile is
independently decodable:

```
u8  mode    0 = coded, 1 = stored
mode 0: one bit stream (§3.4) containing planes 0,1,2,3 in order
mode 1: the tile's raw samples, plane order G1,G2,R,B (untransformed),
        row-major, u16 LE each
```

An encoder must choose `stored` whenever coding would not be smaller.

### 3.4 Prediction and entropy coding

Per coded plane, samples in raster order inside the tile. Neighbours inside
the tile only: `a` left, `b` up, `c` up-left.

- first sample of the tile: `pred = 2^(bit_depth-1)` for plane 0, else `0`
- first row (x>0): `pred = a`
- first column (y>0): `pred = b`
- otherwise MED: `c >= max(a,b) → min(a,b)`, `c <= min(a,b) → max(a,b)`,
  else `a + b − c`

Residual `e = v − pred`, zigzag `u = e >= 0 ? 2e : −2e − 1`.

**Block-adaptive Golomb-Rice.** Each row of a tile plane is cut into blocks of
16 samples (the last may be shorter, length `n`). Let `S(y, bx)` be the sum of
`u` over block `bx` of row `y`. The Rice parameter of a block is derived only
from already-coded blocks, so it costs no bits:

```
up   = S(y-1, bx) * 16 / n        (integer division; y > 0 only)
left = S(y, bx-1)                 (bx > 0 only; always a full block)
s    = up + left       if both exist
       2 * up          if only up
       2 * left        if only left
       rice_init * 32  if neither
v = (s * 11) >> 4
k = min(bit_length((v >> 5) + 1) − 1, 16)
```

Code word per sample, MSB-first bits:
- `q = u >> k`; if `q < 24`: `q` zero bits, one `1` bit, then low `k` bits of `u`
- else escape: 24 zero bits, one `1` bit, then `u` in 24 bits

Planes 0..3 of a tile follow each other in one bit stream, which is
zero-padded to a byte boundary at the end of the tile.

Rationale (non-normative): with no per-sample adaptive state the encoder has
no serial dependency and vectorises; on real phone footage it costs <5 % vs
per-pixel context adaptation (4.97 vs 4.75 bpp binned, 3.62 vs 3.67 full-res).

### 3.5 Noise class

`rice_init` primes the coder for the expected noise. Encoders should derive it
from the sensor noise profile and ISO; v0.1 reference uses
`max(1, 2^(bit_depth-8)) * 4`. Any value 1..65535 decodes correctly.

### 3.6 CRAW-Live (codec id 2)

CRAW-Live is lossless fixed-width block packing. It uses the header and tile
index in §3.1 with `codec_id = 2`. `rice_init` is present but unused. Both
codecs may omit the raw-sample CRC: set flag bit 0 and write `frame_crc = 0`.
The container chunk CRC32C remains mandatory and must be checked before
using a frame without its own CRC. Standalone payloads without that CRC
provide structural validation only.

Tiles use the geometry in §3.3. There is no colour transform. Cell order is
`(py,px) = (0,0), (0,1), (1,0), (1,1)`, independent of CFA. A tile is:

```
u8 mode                  0 = coded, 1 = stored
mode 0:
    u32 width_bytes      byte length of the width-nibble stream
    u8[width_bytes] widths
    u8[] packed_blocks
mode 1:
    u16[4 * tw * th] raw samples, LE, cell order, each cell row-major
```

For mode 0, visit tile rows `y = 0..th-1`, then the four cells in order,
then blocks of 16 samples across that cell row. The last block has
`n = min(16, tw-x0)` samples. Prediction uses samples inside this tile only:

- `x = 0, y = 0`: `pred = 2^(bit_depth-1)` for every cell;
- `x = 0, y > 0`: the first sample of the preceding row of the same cell;
- `x > 0`: the preceding sample of the same cell row, including across blocks.

Compute `e = sample - pred` and `u = e >= 0 ? 2e : -2e-1`.
The block width is `w = bit_length(max(u))`, with `bit_length(0) = 0`.
Widths range from 0 through 17. Emit a width below 15 as one nibble;
otherwise emit nibbles `15, w-15`. Nibbles are packed low nibble first;
zero-pad an unused high nibble in the final byte.

Pack the block's `n` unsigned residuals in sample order, each using `w`
bits, least-significant bit first. Start each block at a byte boundary and
zero-pad its final byte. Width zero emits no block data and reconstructs
all samples from their predictors. Widths and packed blocks are separate
streams, each following the traversal order above. Reconstruct signed
residuals as `u & 1 ? -(u+1)/2 : u/2`, then add the predictor.

Choose stored mode when the coded body (the 4-byte width length, width
stream and packed blocks) is not smaller than `8 * tw * th` bytes.
Larger tiles are already representable through the header; changing the
16-sample block length requires a new codec definition.

### 3.7 CRAW-Live v2 (codec id 3)

Codec 3 has the tile layout, traversal order, stored mode, header and CRC
rules of §3.6, with two changes: the predictor, and the block header (which
can describe a patched block).

**Prediction** (cell plane, samples inside this tile only; `L` left, `U` up,
`UL` up-left, `UR` up-right in the same cell):

- `y = 0`: `pred = 2^(bit_depth-1)` for `x = 0`, otherwise `L`;
- `y > 0, x = 0`: `pred = U`;
- `y > 0, x > 0`: `pred = (L + U + UL + UR + 2) >> 2`, where `UR = U` in
  the tile's last column.

Residuals `u` are zigzagged as in §3.6.

**Blocks** (16 samples; the last block of a row has `n = min(16, tw-x0)`).
The first nibble `t` of a block selects its form:

- `t = 0..13`: plain block of width `w = t`;
- `t = 15`: plain block of width `w = 14 + next nibble` (14..29);
- `t = 14`: patched block. Nibbles follow: `k` (as `w` in §3.6: below 15
  directly, else `15, k-15`), `ne` (exception count, 1..15), `hb` (same
  coding as `k`), then `ne` sample indices `0..n-1`.

Plain block data: `n` values of `w` bits, LSB first, byte-aligned (§3.6).
Patched block data: the low `k` bits of all `n` values, byte-aligned, then
the `ne` high parts (`u >> k`) of `hb` bits each, in index order,
byte-aligned. A sample's residual is `low | high << k` for listed indices and
`low` otherwise.

Encoders choose the form; any choice decodes. The reference encoder emits
patched blocks only on request (they save 0.2-0.5 % on real footage for
about twice the encode time) and otherwise always emits the plain form.

---

## 4. LSHD

```
i64 timestamp_ns, u32 id, u16 map_w, u16 map_h,
f32[4 * map_w * map_h]   gains, 4 per grid point, colour order R, Gr, Gb, B
                         (Gr = green in red rows); row-major points over the
                         encoded (post-crop) frame, points at cell centres
```
Writers emit a new LSHD chunk only when the map changes; each frame refers to
the map in force with `"lshd_ref": id` in its per-frame JSON. Ids are unique
within a file. A frame without `lshd_ref` has no lens-shading information.

## 5. AUDI

```
i64 timestamp_ns of first sample
u8  format  1 = PCM S16, 2 = PCM F32, 3 = PCM S24 (packed 3 bytes)
u8  channels
u16 reserved
u32 sample_rate
u32 frame_count
u8[] interleaved samples
```
F32 is preferred (no digital clipping); S16 is the fallback.

## 6. IMU_

```
u8 sensor   1 = gyroscope (rad/s), 2 = accelerometer (m/s^2)
u8[3] reserved
u32 count
{ i64 timestamp_ns; f32 x, y, z; } [count]   Android sensor coordinates
```
Timestamps share the frame clock (`timestamp_source`).

## 7. INDX

```
u32 count
{ u8[4] fourcc; u32 reserved; u64 offset; i64 timestamp_ns; } [count]
```
Lists every chunk except META and INDX, in file order.

---

## 8. Roadmap (non-normative)

- codec id 2 "CRAW-Max": interleaved rANS with context modelling
- run mode for flat / black tiles
- near-lossless mode (bounded error, JPEG-LS style)
- THMB generation guidance, BWF timecode export
