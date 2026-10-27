# Cinematic RAW Studio — Format Spec (.CRAW)

Lossless cinema RAW container for phone cameras: Bayer video, audio, gyro /
accelerometer, lens distortion & intrinsics, lens shading / vignetting maps.

- [SPEC.md](SPEC.md) — normative format (v0.1 draft)
- [PLAN.md](PLAN.md) — roadmap and ship gates
- `reference/craw.py` — Python reference codec + container (tiebreaker)
- `vectors/` — golden vectors (`python3 reference/make_vectors.py`)
- `ci/device_bench.sh` — build Release arm64, run on device over adb or ssh, gate performance

```
python3 -m unittest discover -s tests
ci/device_bench.sh                 # needs a device: adb, or DEVICE_SSH=user@host:8022
```

Sibling repos: `../CinematicRAWStudio-Encoder`, `../CinematicRAWStudio-Decoder`.
License: Apache-2.0.
