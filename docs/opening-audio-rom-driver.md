# Opening audio from original ROM bytes

The opening cutscene's captured `$0700` queue cues are ROM-proven `ED` commands.
A silent same-input FCEUX trace confirms the live bank-0 handler, current script
pointer and argument, MMC3 PRG mapping, and queue write. This includes the later
IDs `$28`, `$0E`, `$02`, `$09`, and `$07`; see
[`opening_audio_command_provenance.md`](../reference/rom_extract/audio/opening_audio_command_provenance.md)
for source addresses, offsets, and instructions. The recurring `$58` and `$68`
cues are at frames 282/379 and 4481/4578. Start-to-title separately requests
stop ID `$01` through bank-0 code at file offset `0x000058` / CPU `$8048`.

The current Godot asset is `assets/opening/audio/opening_timeline_rom_driver.wav`.
It starts at cold-start frame 0 with the original leading silence, contains the
music and subsequent sound commands, and includes source frames 0–4661,
including the captured Start frame. Its provenance is
`assets/opening/audio/opening_timeline_rom_driver.json`. It is synthesized
offline from the supplied ROM's original sound driver and PRG data, not a WAV
recorded from the emulator. Godot can import it without the ROM or NSF wrapper.

## Observed cue timeline

The FCEUX RAM captures in `reference/opening_reference_capture/ram_states/`
show the value queued at `$0700` at the end of each cold-start frame. The live
execution trace confirms every `ED` source listed below.
Frame 4661 is
the captured Start press and the title transition; the runtime WAV includes
that final frame and Godot stops playback at frame 4662. All frame numbers
below are absolute from cold power-on.

| Frame | Queued sound ID | Provenance |
| ---: | :---: | --- |
| 282 | `$58` | Confirmed `ED $58` at `$A02A`; first APU tone at 283. |
| 379 | `$68` | Confirmed `ED $68` at `$A03C`. |
| 1048, 1068, 1088 | `$28` | `ED $28` at `$A0C7`, `$A0CA`, `$A0CD`; live bank-0 dispatch and bank-3 bytes verified. |
| 1108 | `$0E` | `ED $0E` at `$A0D0`; live bank-0 dispatch and bank-3 bytes verified. |
| 1510 | `$02` | `ED $02` at `$A11C`; live bank-0 dispatch and bank-3 bytes verified. |
| 1779 | `$0E` | `ED $0E` at `$A159`; live bank-0 dispatch and bank-3 bytes verified. |
| 1839 | `$09` | `ED $09` at `$A162`; live bank-0 dispatch and bank-3 bytes verified. |
| 2368 | `$07` | `ED $07` at `$A1C3`; live bank-0 dispatch and bank-3 bytes verified. |
| 4481 | `$58` | Confirmed repeated `$A02A` request in the captured loop; APU first activates at 4482. |
| 4578 | `$68` | Confirmed repeated `$A03C` request in the captured loop. |
| 4661 | `$01` | Confirmed bank-0 `$8048` title-entry stop; final runtime WAV frame. |

`tools/audio/derive_opening_sound_events.py` keeps every nonzero captured
`$0700` value/frame and attaches the byte-verified ROM source for each cue. The
previous FC-counted-payload parse used the wrong dispatch-target boundary. For
the captured opening path, the bank-0 vector table at `$8545` stores
target-minus-one values: `ED` value `$85EB` enters `$85EC`, and `FC` value
`$8836` enters `$8837` after `RTS`. The FC handler increments the script
pointer by one; `$9085` is not entered by that vector. At ED, the handler uses
`Y=1` to read the ROM command argument and stores it to `$0700,X`. With MMC3
selector `$06`, R6=`$00` and R7=`$03` map bank 0 at `$8000` and bank 3 at
`$A000`; live pointer, `ED` byte, argument, queue value, and bank-3 ROM bytes
agree for all 12 music/effect cues. The updated
`tools/audio/build/opening_timeline_rom_events.json` records the source proof.

The older VM export and FC analysis docs still contain the superseded counted
payload assumption and require a separate parser/data correction. This audio
provenance update does not rewrite those runtime data files. The WAV was
regenerated through the offline build pipeline; its PCM hash remained unchanged
because the verified events retain the same captured IDs and frame schedule.

The captured schedule is evidence for this cold-start input replay, not a
general audio scheduler. The ROM driver/data synthesize the mixed audio, but
the captured queue supplies all event IDs and frame positions. Full ROM-side
producer tracing and scheduler emulation are still needed before dynamic
cutscene events can drive audio independently.

## Verified Start and scheduler path

The supplied ROM bytes establish the input-dependent part of the timing. In
bank 0, file offset `0x000037` / CPU `$8027` begins the loop with `LDA #$01`.
At file `0x000039` / CPU `$8029`, `JSR $9FA8` yields through the game's
cooperative scheduler. The loop then reads controller state `$001E` at
`$802C`, masks bit `$10` at `$802E`, and branches back to `$8027` at `$8030`
while Start is clear. When Start is present it falls through at `$8032`; file
offset `0x000058` / CPU `$8048` then executes `LDA #$01; STA $0700`, queuing
the sound-stop command. These bytes prove that the stop cue is requested on
the first poll that observes Start after a scheduler yield. They do not by
themselves give that poll's absolute video-frame number.

In the existing cold-start capture, Start is present in RAM `$001E` on frame
4661, and `$0700` receives `$01` in that same frame. The opening script pointer
is `$A050` immediately before that request. Separate muted probes requesting
Start at frames 400 and 2200 show `$01` queued and the APU still active in the
input frame, then a cleared queue and silent APU on the next captured frame.
Those probes use a different frame-index convention from the cold-start
capture and do not contain instruction-level poll traces. Therefore the
verified general rule is *scheduler-observed Start → stop request*, while the
exact request-frame offset at arbitrary press times remains unverified. Do not
shift the runtime cue table or WAV based on these probes.

The compact pause operand table is at ROM file `0x000AF6` and contains
`01 0A 14 28 3C 50 78 F0` (1, 10, 20, 40, 60, 80, 120, 240 frames). The
cutscene interpreter's dispatch entry is CPU `$84E7` / file `0x0004F7`; its
text pacing and animation routines also yield through `$9FA8`. Those facts
explain part of the schedule, but a ROM-only absolute cue model still requires
the cutscene command state, animation tasks, and frame scheduler to be
reproduced together. The current cue frames remain bound to the captured RAM
snapshots, not inferred solely from the script operands.

The offline build in `tools/audio/build_opening_timeline_nsf.py` copies all
original PRG banks and replaces five `STY $8001` MMC3 bank writes with calls
to an NSF-only bank trampoline. The trampoline maps both 4 KiB NSF pages for
the original selected 8 KiB bank at `$A000-$BFFF`, preserving the accumulator
and processor flags. The wrapper queues the observed sound IDs at their frame
positions, then executes the original driver once per NTSC frame. The altered
instructions and all source offsets are recorded in the NSF metadata under
`tools/audio/build/`.

`tools/audio/render_opening_timeline.py` calls libgme with
`gme_ignore_silence(player, 1)` **before** starting the NSF. This disables
libgme's automatic leading-silence skip, which otherwise removed roughly two
seconds of the cold-start gap. With this option, the raw NSF render first had
nonzero PCM in video frame 286 for the ROM command queued at frame 282, while
FCEUX first showed an active APU channel at frame 283. The final conversion
removes a fixed three-video-frame delay from the raw PCM and then retains
frames 0–4661. Rechecking the resulting WAV found its first nonzero PCM at
frame 283 and its loop restart at frame 4482. The original command frame
numbers remain unchanged in provenance; only the offline renderer's output
alignment is corrected. Regenerate with `python3 tools/audio/render_opening_timeline.py`.

This establishes cue scheduling and first audible frame alignment, but not
sample-exact timbre, NES analog filtering, or all APU channel envelopes. The
emulator APU data is a timing/validation reference and is not used as PCM.

## Earlier single-cue render

`reference/diagnostics/audio/intro_track_58_rom_driver.wav` is an offline synthesis of
the supplied ROM's original music data and 6502 sound driver. It is not a WAV
captured from the running NES emulator. It is retained as a diagnostic; the
Godot scene loads only the full timeline WAV above.

## Source and conversion

- Supplied ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- Original sound driver: 8 KiB PRG bank `$0C`, ROM file offset `0x018010`, CPU `$8000-$9FFF`. The exact source is preserved as `reference/rom_extract/audio/bank_8c_sound_driver.bin`.
- Intro track `$58`: PRG bank `$0F`, ROM file offset `0x01E010`, mapped to CPU `$A000-$BFFF`. Its header starts at ROM file offset `0x01F7BD`; exact source bytes are in `reference/rom_extract/audio/bank_8f_music_data.bin` and `intro_track_58.bin`.
- DPCM-capable fixed PRG bank: `$1E`, ROM file offset `0x03C010`, mapped to `$C000-$DFFF` in the offline build. The known sample bytes are preserved in `reference/rom_extract/audio/dpcm_sample_blob.bin`.
- `tools/audio/build_intro_nsf.py` copies the ROM banks into an NSF-shaped offline build. Five original `STY $8001` instructions at CPU `$8011`, `$8022`, `$8036`, `$804A`, and `$805B` are changed to three `NOP` bytes each. This holds the `$0F` music bank at `$A000-$BFFF` while running this one cue. The changes are recorded in `tools/audio/build/intro_track_58_driver.json`.
- The small wrapper queues `$58` at `$0700` and calls the original driver at `$8000` once per NTSC frame. `tools/audio/render_rom_driver_nsf.py` runs that build through libgme 0.6.5 at 44.1 kHz and writes a 16-bit mono Godot WAV. No reference recording is read during the conversion.

The NSF under `tools/audio/build/` is a transformed intermediate, separate
from the unchanged ROM extracts. To regenerate the audio, run
`python3 tools/audio/build_intro_nsf.py` followed by
`python3 tools/audio/render_rom_driver_nsf.py`. The renderer needs the
`game-music-emu` Homebrew formula only on the build machine.

## Fidelity status

The ROM driver and track bank execute and the generated file contains audio.
The earlier `$58`-only WAV has 90 seconds of output with trailing silence after
the one-shot music ends. It does not include later opening sound commands or
the opening loop, so it is retained only as a diagnostic. The full timeline
WAV above is the intended runtime asset. Do not call either version
sample-exact until its APU mix/filter, DPCM behavior, and effects are compared
against the original on the same input sequence.

### Offline comparison with the existing FCEUX recording

`reference/fceux_cold_start_capture/opening_title_clean.wav` is a captured
comparison recording, not a runtime asset. It starts with nonzero PCM and does
not contain the cold-start silence or the first `$58` onset. Matching its
per-frame RMS envelope against the ROM-driver timeline at 60.0988 Hz places
its first sample about **578 NES frames (9.62 seconds)** into that timeline.
Across the 4,082 overlapping frames, RMS-envelope Pearson correlation is
0.912. Using 60 Hz sample blocks instead gives a 577-block offset; these are
two ways of binning the same approximate 9.62-second displacement, not
different cutscene events. Representative one-second windows have 80–5000 Hz
spectral cosine similarity of 0.957–0.996. These observations support the
music sequence and major effect timing, but do not prove sample equality.

The captured/rendered median RMS ratio in that overlap is about 0.773.
FCEUX's recording gain and user-adjusted volume at capture time are unknown,
so this is not evidence for changing the Godot asset's volume. Local envelope
agreement is weaker around sound IDs `$0E` at frame 1108, `$09` at frame
1839, and `$07` at frame 2368 (41-frame correlations about 0.82, 0.71, and
0.54). The cause could be synthesis/mix differences or unmodeled APU detail;
individual effect waveforms remain unverified.

The FCEUX APU trace records residual square 1, triangle, and noise volume on
the captured Start frame 4661, then zero volume on every channel at frame
4662. The runtime WAV contains frames 0–4661 and uses the same three-frame
libgme alignment correction established by the `$58` onset: the queued
frame-282 cue emits first at aligned frame 283, matching FCEUX.

A same-input PCM tail audit found that the FCEUX recording remains above a
1-LSB peak through frame 4679, about 316 ms after the stop request. The
aligned, untruncated ROM-driver/libgme render does not reproduce this tail: it
is much louder than FCEUX in frames 4662–4663 and becomes effectively silent
by frame 4665. Appending that render would make the match worse; no synthetic
fade was added. Godot stops playback at frame 4662, so the current runtime
asset omits the FCEUX post-stop filter decay. Per-frame RMS/peak metrics and
source hashes are in
`reference/diagnostics/audio/start_tail_audit_20261024.json`. A
FCEUX-equivalent APU mixer/filter model is needed to improve this boundary.

The tail source has since been identified in the pinned FCEUX 2.7.0 source
([`src/filter.cpp`](https://github.com/TASEmulators/fceux/blob/a6d03e7968bd77a8156a7c9b628a673753f2f4c6/src/filter.cpp),
[`src/sound.cpp`](https://github.com/TASEmulators/fceux/blob/a6d03e7968bd77a8156a7c9b628a673753f2f4c6/src/sound.cpp),
commit `a6d03e7968bd77a8156a7c9b628a673753f2f4c6`). With `soundq=2`,
`FlushEmulateSound` sends `WaveHi` through `NeoFilterSound` and then the
stateful `SexyFilter`; that final stage runs unconditionally at quality 1 or
2. `SexyFilter` retains two accumulators across frames, using coefficients
derived from 94 Hz and 24 Hz, so it continues emitting PCM after the game
driver clears all APU channel volumes. This is FCEUX's output-chain decay, not
a missing sound command in the ROM. The optional `SexyFilter2` low-pass is a
separate setting and is not needed to explain the captured tail. Exact source
file hashes and paths are recorded in the diagnostic JSON.

A bounded offline probe applied the exact `SexyFilter` recurrence to the
current aligned libgme output, then forced its input to zero at the observed
APU-zero frame 4662. RMS was close only for frame 4662 (FCEUX 251.65, probe
277.91); it fell to 42.06 versus 346.35 at frame 4663 and 5.91 versus 309.27
at frame 4664. The filter coefficients alone therefore do not close the tail:
the libgme stream does not carry the same upstream FCEUX `WaveHi`/FIR state.
No runtime WAV or guessed fade was added. Reproducing this without captured
PCM would require an offline renderer or port that runs the ROM sound driver
through the verified FCEUX APU, resampler, and output-filter chain; the
existing silent FCEUX recording remains validation-only.

The current Godot WAV first exceeds RMS 10 in frame 283, while the FCEUX PCM
has an active cue in frame 282. Cue-local RMS-envelope correlation mostly
peaks at `capture_frame = runtime_frame - 1` (for example, correlation 0.989
in frames 260–330 and 0.970 in 1500–1525). This consistent one-frame offset
is likely an audio/video frame-origin or renderer scheduling convention; it
does not establish that the ROM event table is wrong. Keep the ROM-derived
cue frame numbers unchanged until the emulator and renderer callback origins
are traced. Several individual sound-effect envelopes still differ even
after that one-frame alignment.

An offline FCEUX-core proof executes the generated opening-timeline NSF using
the supplied ROM's original sound driver and data. The first wrapper attempt
was silent because INIT cleared CPU page $0100, which held FCEUX's NSF NMI
return frame; the wrapper now preserves that stack page and documents the
actual fixed pages $40/$41 at CPU $E000/$F000.

A fresh reset trace showed that FCEUX's NSF bootstrap consumes three video
frames before its first scheduled PLAY call. The wrapper counter is now seeded
by three frames. In the phase-correct dummy-output render, the first cue
window (frames 260–330) correlates at 0.9985 with offset 0; the previous
unseeded candidate peaked at +3. The second cue peaks at offset 0 with 0.725
correlation, while later windows prefer offsets from -6 through +6. Across
frames 260–4660, broad correlation remains only 0.523 at +3. This fixes the
NSF startup-phase convention, but does not make the source-rendered PCM a
better complete match than the current runtime asset.

The title-stop behavior is now traced to the original driver. Queue ID $01 in
$0700 selects the first sound table entry at $8BDA, whose stream begins at
$8E42 and terminates eight channel streams with $FF. The driver's terminator
clears channel activity and writes $30 to $4000/$4004/$4008/$400C; with
$07E9=0 it does not disable the APU through $4015. The corrected NSF wrapper
dispatches this event at frame 4662, matching the original capture's frame
where all APU channel volumes reach zero. So the former apparent 20-frame
late stop was the NSF startup phase, not a missing or delayed ROM stop event.

The original silent FCEUX capture has residual output through frame 4679 after
the stop command at 4661. Its APU volumes are zero from 4662, and the pinned
FCEUX output path runs WaveHi through NeoFilterSound and a stateful SexyFilter,
which carries output state across frames. The precise same-input FCEUX capture
has 3,442,925 samples; its length is reconciled by the 139,730,109 elapsed CPU
cycles and the `soundq=2` FIR startup phase (see
`reference/diagnostics/audio/precise_pcm_sample_alignment_20261024.json`). The
first input row has zero elapsed cycles, so the source-frame-to-PCM boundary
must use emulated cycle/sample timing rather than counting CSV rows as full
frames. A separate 4,700-frameadvance NSF probe produced 3,461,217 samples
(nominally 4,716.89 frames); that probe remains unexplained and must not be used
to align the tail. Even after this boundary correction, applying only the
final SexyFilter recurrence to libgme output does not reproduce FCEUX's tail,
because the upstream mixer/resampler state differs. Full source-derived
APU/resampler/filter output and an exact PCM-tail match remain unresolved.

Captured WAV remains comparison-only, no arbitrary fade was added, and the
runtime libgme WAV remains unchanged. The local diagnostic FCEUX build writes
PCM from the ROM-driven NSF under SDL dummy output, but is not yet a portable
project build tool. The exact builder, source revision, hashes, phase-aligned
cue metrics, and stop-handler evidence are in
reference/diagnostics/audio/start_tail_audit_20261024.json; the precise capture
sample accounting is in
`reference/diagnostics/audio/precise_pcm_sample_alignment_20261024.json`. The
remaining audio gap is a source-derived renderer whose later cue envelopes
and post-stop filter tail match the original more closely. The project-owned
renderer options and their runtime-asset tradeoff are recorded in
`reference/rom_extract/audio/offline_renderer_next_step.md`.
The reproducible builder change is in
`tools/audio/build_opening_timeline_nsf.py`. The experiment used a local
FCEUX 2.7.0 diagnostic build (revision
`8cdbeeb248f5a13aa97a58b4a0437ae13fb6aea8`) with SDL dummy output and
Lua-scoped WAV recording helpers; that local diagnostic build is not a
project dependency. Its renderer output is validation evidence, not a runtime
asset. The FCEUX output chain can therefore be evaluated from ROM-driven
execution without using a captured WAV as source material, but the current
candidate is not accurate enough to integrate.

If Start is pressed at a different point in the intro, its sound timing is
controlled by the Godot transition rather than this captured frame-4661 cue;
that path has not been compared against the original.
The previous 4,661-frame ROM-driver asset and its provenance are preserved as
`reference/diagnostics/audio/opening_timeline_rom_driver_pre_start_tail_4661f.wav`
and the matching `.json`. Sample-level timbre, filter behavior, and exact
transition PCM remain unverified.
