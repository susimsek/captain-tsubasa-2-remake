# ROM-source opening BGM candidate (25 Oct 2026)

## Result

The diagnostics-only pipeline builds and renders the opening's `$58` BGM cue
from the supplied ROM's original sound driver, track bank, and DPCM bank. It
does not read a captured WAV/PCM file or use the captured multi-cue frame
schedule. The candidate is not installed in Godot; the shipped timeline WAV
remains unchanged.

Run from the project root:

```sh
python3 tools/audio/build_opening_bgm_source_candidate.py
```

The command refuses to overwrite its date-stamped output folder. Choose a new
folder on later runs with `--output-dir`, for example:

```sh
python3 tools/audio/build_opening_bgm_source_candidate.py \
  --output-dir reference/diagnostics/audio/opening_bgm_rom_source_candidate_rerun_01
```

The build requires the supplied ROM and the local libgme 0.6.5 runtime. Godot
does not require either one.

## Source path and candidate identity

The supplied ROM is SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
The source path is:

1. Runtime sound ID `$58` maps through the bank `$0C` driver's pointer table at
   `$8BDA`: `(0x58 - 1) * 2` selects CPU `$8C88`, file `0x18C98`, whose word is
   `$B7AD`.
2. Bank `$0F` maps `$B7AD` to the opening track header at file `0x1F7BD`.
   It lists the four sequence streams `$04–$07` and the `$FF` terminator.
3. The offline NSF includes driver bank `$0C` from file `0x18010`, music bank
   `$0F` from `0x1E010`, and fixed DPCM bank `$1E` from `0x3C010`. The NSF-only
   build replaces the driver's five verified `STY $8001` bank writes at CPU
   `$8011/$8022/$8036/$804A/$805B` with `NOP`s because the selected music bank
   is pinned in the NSF's `$A000–$BFFF` pages.
4. Its NSF INIT queues only `$58`; libgme executes the original driver/data and
   renders a 90-second, 44.1 kHz mono candidate while preserving initial
   silence.

Generated diagnostic files:

- `reference/diagnostics/audio/opening_bgm_rom_source_candidate_20261025/opening_bgm_rom_driver.nsf`
  — SHA-256 `9980cd2e0abf56ccb0b57d418e1d674129f437f52130f50cacce7b5b1692e148`.
- `reference/diagnostics/audio/opening_bgm_rom_source_candidate_20261025/opening_bgm_rom_driver.wav`
  — SHA-256 `8c5e3e2ced96b8c97abdd6dccea69989402d751d7296831d2bccd4615baac677`,
  3,969,000 samples. The generated file has nonzero PCM; its first nonzero
  sample is at candidate sample 3,054. This is a candidate-file observation,
not a measured FCEUX onset comparison. At 60.0988 Hz this is about 4.16
frames after candidate start; the cue-alignment trim has not yet been applied
to this one-cue wrapper.
- `reference/diagnostics/audio/opening_bgm_rom_source_candidate_20261025/candidate_manifest.json`
  — ROM/NSF/WAV provenance, source offsets, candidate limitations, and a guard
  showing the shipped timeline WAV stayed at SHA-256
  `325fa7947fcba0874a6b5261a03b8314d302df318a58f887eb0ee4daab8cbf4a`.

The orchestration script is
[`build_opening_bgm_source_candidate.py`](../../../tools/audio/build_opening_bgm_source_candidate.py).
It calls the existing source-hash-checking NSF builder and ROM-driver renderer
but writes only into a new diagnostics directory.

## What this enables and what remains

This gives Godot a separately generated BGM-only candidate that could be
started by the source presenter's `$58` cue signal. It avoids playing the BGM
twice when effects are later separated from the current mixed timeline. The
current runtime still loads
`assets/opening/audio/opening_timeline_rom_driver.wav`; no Godot runtime code or
shipped audio was changed.

The candidate is not yet a replacement for that timeline. It starts `$58` in
NSF INIT rather than reproducing its original cold-start frame (captured at
frame 282), and it omits the other opening IDs `$68`, `$28`, `$0E`, `$02`, `$09`,
and `$07`. The candidate also retains about four frames of libgme/NSF startup
silence; the known three-frame timeline trim has not been applied or verified
against this wrapper. It would likely sound late if started directly on the
source `$58` event without that timing step. The simple one-cue wrapper
initializes `$4015` but does not reproduce the original cold-start
`$4010/$4017` writes or their phase relative to `$58`.
The source-presenter cue frame is still replay-anchored, and libgme output has
not been shown sample-identical to the original APU mixer/resampler/filter.
Replacing the runtime mixed WAV therefore still requires source-scheduler
timing, separately handled effects, and same-input APU/mix validation. Captured
PCM remains comparison-only.
