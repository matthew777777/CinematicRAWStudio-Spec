# Cinematic RAW Studio (.CRAW) — Format Specification v0.1 (draft)

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
| 6   | u16     | minor version = 1                      |
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
u8   reserved = 0
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
- first row (x>0): `a` exists; set `b = c = a`
- first column (y>0): `b` exists; set `a = c = b`
- otherwise MED: `c >= max(a,b) → min(a,b)`, `c <= min(a,b) → max(a,b)`,
  else `a + b − c`

The first sample uses context 0. Others use
`g = |a − c| + |b − c|`, `ctx = min(bit_length(g), 15)` (16 contexts).

Residual `e = v − pred`, zigzag `u = e >= 0 ? 2e : −2e − 1`.

Adaptive Golomb-Rice, state per context reset at the start of every
**plane of every tile**: `A = rice_init`, `N = 1`.
`k` = smallest `k >= 0` with `N << k >= A`, capped at 20.

Code word, MSB-first bits:
- `q = u >> k`; if `q < 24`: `q` zero bits, one `1` bit, then low `k` bits of `u`
- else escape: 24 zero bits, one `1` bit, then `u` in 24 bits

Update: `A += u; N += 1; if N == 64: A >>= 1; N >>= 1`.

The bit stream of a tile is zero-padded to a byte boundary.

### 3.5 Noise class

`rice_init` primes the coder for the expected noise. Encoders should derive it
from the sensor noise profile and ISO; v0.1 reference uses
`max(1, 2^(bit_depth-8)) * 4`. Any value 1..65535 decodes correctly.

---

## 4. LSHD

```
i64 timestamp_ns, u32 id, u16 map_w, u16 map_h,
f32[4 * map_w * map_h]   gains, channel order R, G_even, G_odd, B (Camera2
                         STATISTICS_LENS_SHADING_CORRECTION_MAP layout)
```
Frames refer to it by `lshd_ref = id` in per-frame JSON.

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
