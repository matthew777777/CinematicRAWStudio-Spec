# Compression and performance evidence

CRAW is an independent-frame lossless RAW container and codec family. Its
compression advantage over other formats must be measured on identical samples;
it is not implied by the format name, prediction method or entropy coder.

## Implemented codec registry

| ID | Stable name | Method | Intended use |
|---:|---|---|---|
| 1 | CRAW-Fast | colour differences, MED, causal block-adaptive Rice | smaller recording payloads when CPU permits |
| 2 | CRAW-Live v1 | left prediction, adaptive fixed-width blocks | compatibility with existing recordings |
| 3 | CRAW-Live v2 | four-neighbour prediction, adaptive fixed-width blocks, optional patches | current RawLens Live recording choice |
| 4 | CRAW-Compact | per-tile predictor search, explicit block Rice parameters | offline compaction |

Names and IDs remain compatible with existing files. “Fast” predates Live and
does not mean fastest among these modes. No ID is reserved for a future rANS
codec. Codec 3 patched-block search is off in the comparison and in the default
live encoder. Codec 1's Rice parameter adapts from neighbouring blocks; it has
no implemented rANS coder or temporal prediction.

## Reproducible comparison

See [bench/comparison/README.md](bench/comparison/README.md) for the complete
driver, native benchmark, pinned dependency instructions, Android build and
standalone device batch. Test all four CRAW modes and JPEG XL lossless efforts
1–3 on the same uint16 samples. JPEG XL is tested both on the Bayer mosaic and
on reversibly stacked CFA planes. Neither representation demosaics or scales.

Current run: [2026-10-30 results](results/comparison-20261030/README.md).
Retain source take and extracted RAW SHA-256 hashes, revisions, executable
hashes, all timing observations, CPU time, process peak RSS and round-trip
checks. Source footage is an external input and is not redistributed here.

Size comparisons are image-payload comparisons: they exclude CRAW audio,
metadata, chunk checksums/indexes and a possible JPEG XL video container.
JPEG XL files include their own image headers. Encoding uses actual source bit
depth with no normalization. A size gate only passes on the tested corpus;
results from two correlated takes cannot establish universal superiority.

## Interpreting measurements

- Host codec timing is not phone timing or capture fps. Record the actual
  codec ID: the 2026-10-27 host report's “Live” means codec 2, not codec 3.
- Report encode and decode separately. Compact's 2026-10-28 eight-frame result
  saved 9.57% versus Live v2 but cost 10.44× encode and 3.79× decode time on
  that host. It did not meet the live-performance goal.
- Peak RSS is a process high-water mark, not incremental workspace. The
  comparison uses separate encode/decode processes and includes allocation
  and, for plane JPEG XL, rearrangement in codec timing.
- Sustained in-memory phone loops measure the isolated codec under that
  device's scheduler/thermal conditions. They do not establish sustained
  Camera2 acquisition, recorder queue health, preview, sound or storage.
- End-to-end acceptance must separately record actual frame timestamps,
  frame gaps, acquisition/queue/commit losses, memory, thermal state, sound,
  finalization and playback. See RawLens's
  [recording acceptance procedure](https://github.com/matthew777777/RawLens/blob/main/docs/refactor/craw-recording-performance.md).
  No frame duplication may
  be used to inflate capture throughput.

## Historical evidence and open gates

The README/roadmap's 650–700 MPix/s and 52–56 fps figures are historical
throughput reports for one device and configuration. The checked-in early
device JSONs represent different, slower revisions and a synthetic 10-bit
corpus. They do not independently reproduce those later claims. No sustained
recording guarantee follows from either set of numbers.

The existing golden vectors, independent reference, corruption checks, WAV
tests and compaction tests support functional correctness. They do not settle
relative compression, security, device compatibility or editor interoperability.
Actual Resolve import and a sustained full recorder run need their own dated
results. rANS, richer context models and temporal coding remain future research;
first publish reproducible evidence for the implemented modes.
