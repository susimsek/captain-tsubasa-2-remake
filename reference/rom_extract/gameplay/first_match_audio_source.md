# First-match route audio: ROM source and source-only trace

## Scope and ROM identity

This note maps audio queue writes on one fresh-start KICK OFF route through the
first command menu. It asks whether the `$55` first-match BGM can be produced
from the supplied ROM and what the source-only route trace establishes. The
captured APU log is used only as an independent register-write validation; no
captured PCM/WAV or emulator timestamps are used as synthesis or scheduling
input.

- ROM: `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`
- SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`
- PRG+CHR MD5 without the 16-byte iNES header: `eaf2b3745263efa4b1afd2b400f68dae`
- Mapper 4/MMC3; 256 KiB PRG and 128 KiB CHR.
- File offsets below include the 16-byte iNES header.

The route inputs came from
`reference/diagnostics/kickoff_select_test_20261027/opening_replay.csv` and
`post_title_inputs.csv`, merged into a source-stepper timeline. The merged
temporary input SHA-256 was
`6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc`. The
ROM-only run covered source frames 0–9042 and produced
`source_sound_queue_nonzero_writes.csv` (SHA-256
`96cfdba5086bc1dfd5b3314cbc1928075f7770aa5bbf5046478bf70b457fd62f`) and
`source_apu_writes.csv` (SHA-256
`0431f07fac824ddff396482f694fcf027a1df54ae84b3058d598b5f6987d0130`) under
`/tmp/ct2_first_match_rom_stepper_20261027/`. The stepper report SHA-256 is
`4038d7e170634c614ef7028c7bd1bd5f6033336ca53a77101a04e0b869eb8fe9`; it
records that this is source-ROM/CPU-derived event generation and that no
FCEUX trace was used as scheduler input.

## Queue events and route timing

The source-stepper queue file records the CPU PC after each store to `$0700`.
Thus `$85FF` identifies the return after the `$ED` script-command handler's
`STA $0700,X`; it is not the command's script address. The queue IDs and
source-frame/cycle positions below come directly from executing the ROM-only
stepper with the route input. “Likely script” locations are static ROM
candidate literals and are not presented as captured live script pointers.

| Source frame | Source CPU cycle | Queue ID | Post-store PC | Source attribution and evidence |
|---:|---:|---:|---:|---|
| 4816 | 143396526 | `$55` | `$85FF` | `$ED $55` occurs at scene-1 script CPU `$A2AA`, file `0x0062BA`. The queue write is a ROM-stepper event; the literal-to-live-script association is strongly supported by the matching ID and route, but the live `$4D/$4E` script pointer was not logged at this event. |
| 7243 | 215674689 | `$01` | `$82DF` | Direct code store. Bank-0 file `0x0002EC` contains `A9 01 8D 00 07` (`LDA #$01; STA $0700`); the stored value is a stop/control command. |
| 7266 | 216367134 | `$01` | `$810A` | Direct code store. Bank-0 file `0x000115` contains `A9 01 8D 00 07`; the event is the code path's stop/control write. |
| 7409 | 220630517 | `$55` | `$812F` | Direct match-setup code. Bank-0 file `0x000132` begins `A2 55 A5 26 C9 20 90 02 A2 4C 8E 00 07`; CPU `$812C` stores X to `$0700`, and the post-store hook is `$812F`. Fresh match index `$26=0` takes `$55`; the final-match branch substitutes `$4C`. |
| 8027 | 239028028 | `$31` | `$85FF` | `$ED`-handler queue write during the story sequence. A candidate `$ED $31` is present at scene-1 CPU `$A3DE`, file `0x0063EE`; no live script pointer was captured, so this literal association is not claimed as a direct address trace. |
| 8108 | 241434503 | `$01` | `$85FF` | `$ED`-handler queue write during the story sequence. Candidate `$ED $01` bytes are at scene-1 CPU `$A3E1`, file `0x0063F1`; exact live pointer association was not captured. |
| 8271 | 246288156 | `$53` | `$85FF` | `$ED`-handler queue write during the matchup sequence. Candidate `$ED $53` is at scene-2 CPU `$A62F`, file `0x00663F`; exact live pointer association was not captured. |
| 8443 | 251410847 | `$01` | `$82DF` | Direct bank-0 stop/control store on the Select transition. |
| 8460 | 251937843 | `$01` | `$CC01` | Direct source-stepper queue event in fixed-bank code; call-site meaning not assigned here. |
| 8607 | 256313339 | `$3C` | `$CC01` | Direct source-stepper event in fixed-bank code; runtime sound ID is confirmed, semantic label is not assigned here. |
| 8624 | 256809146 | `$66` | `$CC01` | Direct source-stepper event. The ROM pointer audit maps runtime ID `$66` to sound-test SFX ordinal 91; ordinal is a catalog index, not a descriptive sound name. |
| 8664 | 257998379 | `$2B` | `$CC01` | Direct source-stepper event. The ROM pointer audit maps runtime ID `$2B` to sound-test SFX ordinal 78. |
| 8786 | 261637820 | `$2C` | `$CC01` | Direct source-stepper event. The ROM pointer audit maps runtime ID `$2C` to sound-test SFX ordinal 79. |

The route trace's input checkpoints are documented in
[`kickoff_first_command_menu_trace_20261027.md`](kickoff_first_command_menu_trace_20261027.md).
The final menu sample is frame 8953; no action was selected. The APU write
capture at `reference/diagnostics/kickoff_select_test_20261027/apu_writes.csv`
has SHA-256
`4278d0c20be29cc659ae217713d767f5309685d4eb8835916c94339a8c62f148` and was
recorded with audio disabled. After excluding controller/DMA writes to
`$4016`/`$4014`, the captured and ROM-stepper APU write sequences match in
per-frame order and `(address,value)` across all 3,736 frames containing APU
writes: 42,228/42,228 writes, zero differing frames. This validates the
software-stepper register-write sequence against the capture; it does not
validate audible PCM, analog timbre, or hardware timing. Captured APU cycles
were not used to schedule or render audio.

## `$55` sound-driver lookup

The runtime queue ID `$55` resolves through the original driver, not by treating
`$55` as a sound-test ordinal:

1. The sound driver is in bank `$0C`, file `0x018010`, loaded at CPU `$8000`.
   Its queue lookup table begins at CPU `$8BDA`, file `0x018BEA`; the index is
   `(runtime_id - 1) * 2`.
2. For `$55`, the index is `$54 * 2 = $A8`; table address `$8C82` is file
   `0x018C92`. The original bytes there are `0F A3`, little-endian pointer
   `$A30F`.
3. The `$51–$5B` driver range selects PRG bank `$0F` in MMC3 R7 for `$55`.
   Bank `$0F` at CPU `$A000` maps to file base `0x01E010`; `$A30F` therefore
   resolves to file `0x01E31F`.
4. The sequence header begins `04 1C A3 05 E9 A4 06 4F A5 07 8B A5 FF`.
   The target-ROM sound-test index records this as BGM ordinal 3. The index is
   useful for navigation; the pointer bytes and bank mapping above establish
   the local ROM result.

This establishes both the cutscene's first `$55` queue event (frame 4816) and
the fresh-match setup's second `$55` write (frame 7409). The first APU driver
initialization writes occur on frame 4817 after the first queue event and on
frame 7411 after the match-setup event. Those first-write frames were read from
the ROM-only source APU trace and independently match the captured
`apu_writes.csv` by frame/address/value. They are register-activity onsets, not
measured audible or PCM onsets.

## Offline build/render path and limits

`tools/audio/build_intro_nsf.py` accepts `$55` in its ROM-hash-checked
`MUSIC_BANKS` map (`$55 -> bank $0F`). It copies the original bank-`$0C` driver,
bank-`$0F` sequence data, and bank-`$1E` DPCM data into an NSF intermediate,
and applies five verified MMC3-write-to-NOP patches so the selected music bank
stays mapped in the NSF. `tools/audio/render_rom_driver_nsf.py` runs that NSF
through libgme. A reproducible one-cue build is:

```sh
python3 tools/audio/build_intro_nsf.py --track 0x55 --output /tmp/ct2_match_55.nsf
python3 tools/audio/render_rom_driver_nsf.py \
  --nsf /tmp/ct2_match_55.nsf \
  --output /tmp/ct2_match_55.wav \
  --seconds 90 --sample-rate 44100 --preserve-initial-silence
```

This is a ROM-only single-cue render path. The commands are source-backed but
were not run as part of this trace; no rendered `$55` PCM comparison is claimed.
The diagnostics-only `tools/audio/render_rom_stepper_wavehi_candidate.py` can
consume a custom source-stepper output folder (`--stepper-dir`) to synthesize a
multi-cue route from ROM-derived APU writes, DMC reads, and frame-cycle records.
Its checked-in default input/output are only the earlier cold-start run through
frame 4662, so the first-match route requires the custom 9042-frame stepper
output and a separate render. The renderer documents unresolved DMC phase and
DMA-arbitration assumptions and does not claim NES/FCEUX audio equivalence.

Therefore `$55` is source-addressable and the offline ROM-derived toolchain can
render that track without captured WAV input. The full mixed first-match audio
route has not yet been rendered or PCM-validated. No captured PCM/WAV or APU
capture timestamps became runtime or synthesis inputs in this work.

## Reproducible `$55` queue-to-driver timing

The source-stepper event tables can be summarized without FCEUX using
`tools/audio/export_first_match_cue_timing.py`. For the retained route trace:

```sh
python3 tools/audio/export_first_match_cue_timing.py \
  --stepper-report /tmp/ct2_first_match_rom_stepper_20261027/source_stepper_report.json \
  --queue-csv /tmp/ct2_first_match_rom_stepper_20261027/source_sound_queue_nonzero_writes.csv \
  --apu-csv /tmp/ct2_first_match_rom_stepper_20261027/source_apu_writes.csv
```

The generated reference is
`first_match_cue_timing_rom_stepper_20261027.json`. It records the route's two
`$55` queue stores and, before the next queue event, the first APU register
write and first pulse-1 `$4000` write. The queue-to-`$4000` offsets are 32,762
cycles (18.305115 ms) for the frame-4816 cutscene request and 50,291 cycles
(28.099094 ms) for the frame-7409 fresh-match setup request. The exporter
checks the ROM hash, source-only stepper report, `$55` manifest, and the WAV
hash before writing its output.

This timing is now transferred to the Godot route as a limited startup-alignment
step. `tools/audio/build_match_track_55_source_timing_manifest.py` derives a
project-owned sidecar from this ROM-only timing file and the checked ROM-driver
WAV. On each of the two fresh-start `$55` occurrences, the audio presenter
removes the render's 3,065 verified leading-zero samples and adds the
source-derived queue-to-first-pulse delay: 807 samples on the first request and
1,239 on the restart. Runtime reads the original WAV PCM bytes after validating
its manifest hash; it does not load captured FCEUX PCM. The sidecar and runtime
change are documented in
[`route_cue55_asset_onset_audit_20261027.md`](../../diagnostics/audio/route_cue55_asset_onset_audit_20261027.md).

These timings align a software-driver register event, not necessarily the
first audible sample on hardware. The same-input FCEUX comparison improves
RMSE in both measured windows, but correlation remains low.

## Godot audio-server capture check

The actual cue presenter can be captured without starting FCEUX or changing
runtime audio. On Godot 4.7.2, the diagnostic adds `AudioEffectCapture` to the
Master bus, dispatches the production `$55` presenter at the first source
occurrence, and records five seconds of Godot's 44.1 kHz mix as mono 16-bit
PCM. The capture WAV and comparison JSON are written under the ignored
`reference/diagnostics/audio/godot_match_track_55_audio_server_20261028/`
directory; neither is a runtime input or asset.

```sh
godot --headless --audio-driver Dummy --path . \
  --script tools/diagnostics/capture_godot_match_track_55_audio_server.gd
python3 tools/audio/compare_godot_cue55_audio_server_capture.py
```

The comparison reads the retained same-input FCEUX route PCM only for
validation and verifies its recorded hash. The first five seconds after the
frame-4817 first-pulse setup produce 219,693 queue/source-timing-aligned
samples: Pearson `r=-0.250135`, RMSE `5612.314`, and 7 exactly equal samples.
If both signals are cropped to their first nonzero sample, 219,627 samples give
`r=0.380653`, RMSE `4004.443`, and 40 exactly equal samples. The Godot capture's
first nonzero occurs at capture sample 873, 66 samples (1.497 ms) later than
the ROM-derived 807-sample queue-to-pulse delay. Two repeated Dummy-driver
captures produced the same WAV hash, `03cdb92b8ba4bbbb13853431e4a48df4c68022663387ec82e54ba6bf11ed8787`.

This verifies that the live Godot audio-server path is measurable and
repeatable in the headless Dummy-driver setup, but the low correlation means
the `$55` waveform is not equivalent. This is a direct cue capture, not a full
route recording or physical NES output; full route/Godot PCM parity remains
unverified. Godot capture data and FCEUX PCM remain diagnostics only.

The comparator now also checks the Godot capture against the actual ROM-derived
source WAV that the presenter loads. It verifies the WAV SHA-256 from the
capture manifest, trims the manifest's 3,065 leading zeros, aligns the source
at its first audible sample with Godot's measured first nonzero sample (873),
and makes no resampling, gain fit, or additional signal processing. Across
219,627 samples the result is byte-for-byte equal: Pearson `r=1.0`, RMSE `0`,
and `219,627/219,627` exact samples. This rules out the Godot AudioServer path
as the source of the measured waveform mismatch for this capture: it preserves
the current libgme-rendered ROM/NSF PCM exactly after the source-timed trim.

The mismatch is therefore upstream of Godot playback, between the libgme
0.6.5-rendered ROM/NSF cue and the same-input FCEUX output. FCEUX's documented
path uses its own cycle-stepped pulse/triangle/noise/DMC rendering, nonlinear
mix, 1,024-tap FIR resampler, and persistent `SexyFilter` state
([implementation map](../audio/fceux_wavehi_implementation_map_20261024.md)).
The available comparison does not isolate whether the remaining difference is
libgme's APU implementation, driver/NSF initialization state, write-to-sample
phase, channel mixer, resampler, or filter behavior. The measured 66-sample
delay after the source-derived queue-to-pulse position is specific to this
headless AudioServer capture; it is not grounds to adjust the production route
timing. No production audio, cue timing, or presenter code changed in this
audit, and no captured WAV/PCM became a runtime input.

## Bounded NSF APU-reset probe

The source-only route starts from the original game's cold-start APU history:
the ROM writes `$4017=$40` at cycle 111,994, while the route's first `$55`
register setup is much later, at cycle 143,429,288. A build-only trace of the
standalone `$55` NSF shows libgme injects `$4017=$00` twice at cycle 0 from
`Nsf_Emu::start_track_`; the NSF wrapper then queues `$55` from a fresh APU
reset. This is a real initialization-context difference worth checking, but
the one-write mode correction cannot recreate the full elapsed route state.

For a bounded diagnostic, a temporary copy of the ROM-derived NSF
(`74f0fe5153b99a6ccfbdc7be45023960039223b3c74bcbbd6ba55080cda515f8`) adds
`LDA #$40; STA $4017` immediately before its `$55` queue in the NSF wrapper.
No driver, sequence, or production runtime file was changed. The candidate NSF
SHA-256 is `eb28fc3fd5c13a8978baa1b1038c59c58d9783c041197b0ad1a33bb3d00e1479`;
its 45-second libgme render SHA-256 is
`a9f068ae17cc3732aa0f27032054f8342b11ee0eaf64701ba1b71f0989957695`.
Compared over the same first-request FCEUX window `[3,534,072, 5,314,928)` with
the source's 3,065 leading-zero samples trimmed:

| Candidate | Pearson r | RMSE | Exact samples | Candidate RMS |
|---|---:|---:|---:|---:|
| Existing NSF `$4017=$00` startup | 0.0546555 | 4,732.145 | 237 / 1,780,856 | 3,854.403 |
| Diagnostic NSF `$4017=$40` write | 0.0498284 | 4,744.212 | 243 / 1,780,856 | 3,854.950 |

This does not improve the match, so the standalone frame-counter mode write
alone is not the explanation or a supported fix. It does not rule out the
different phase/history created by executing the whole route before `$55`.
As a separate renderer comparison, the existing full-route ROM-stepper
WaveHi candidate—with the pinned FCEUX mixer/resampler/filter and source DMC
state corrections—reaches `r=0.847626` / RMSE `1,681.065` in the first `$55`
window. That candidate changes the whole route context and APU/DMC rendering
path together; it does not isolate channel timing, mixer, filter, or NSF
initialization as the remaining cause. The exact subcomponent is still open.
The experiment and capture remain diagnostics only; the production WAV and
timing were not changed.

## DMC DAC state carried into the first `$55`

The first-match `$55` NSF currently begins from libgme's fresh APU reset,
while the ROM route reaches `$55` after the opening's `$01` stop. The supplied
ROM's bank-`$0C` setup at CPU `$86A3`, file `0x0186B3`, is
`A9 0F 8D 10 40 A9 00 8D 12 40 A9 0C 8D 13 40 A9 1F 8D 15 40 60`: it writes
`$4010`, `$4012`, `$4013`, and `$4015`, but does not write the DMC DAC register
`$4011`. The source route trace has the stop `$01` at frame 4661, then the
driver's `$4015=$0F` and `$4000/$4004/$4008/$400C=$30` stop writes in frame
4662; from that stop through the first `$55` setup at frame 4817 it records no
`$4011` write. In the retained FCEUX-compatible DMC trace, the last prior DMC
bit edge leaves the DAC latch at `$60`, which the stop does not clear
([stop-path audit](post_stop_filter_tail_source_trace_20261025.md)).

The pinned libgme 0.6.5 source resets `Nes_Dmc::dac` to zero in
[`Nes_Dmc::reset`](https://github.com/libgme/game-music-emu/blob/9e23d10f9fd2a6a2f33b10912dd8dc7153258995/gme/Nes_Oscs.cpp#L247-L263),
and `Nsf_Emu::start_track_` calls the APU reset before the wrapper queues the
cue ([source](https://github.com/libgme/game-music-emu/blob/9e23d10f9fd2a6a2f33b10912dd8dc7153258995/gme/Nsf_Emu.cpp#L538-L550)).
That gives the standalone `$55` candidate a DAC start of zero instead of the
route's retained `$60`. This is a byte- and trace-backed state discrepancy,
not proof that it explains the low waveform correlation or that the FCEUX
model equals a physical NES.

### Diagnostic `$4011=$60` seed probe (28 Oct 2026)

The bounded seed experiment was run offline. Starting from the ROM-derived cue
`$55` NSF, only its `$E000` wrapper was changed: bytes
`A9 60 8D 11 40` (`LDA #$60; STA $4011`) were inserted immediately before the
existing `A9 55 8D 00 07` queue write. The insertion starts at NSF file offset
`0x60A3` (wrapper offset `$23`), ends at wrapper byte `$2E`, and remains before
the fixed `$E030` PLAY entry at wrapper offset `$30`; driver, track data, and
all other wrapper bytes are unchanged. Both baseline and seeded variants were
rendered with the project's `render_rom_driver_nsf.py` / pinned libgme 0.6.5,
mono 44.1 kHz, 45 seconds, with `preserve_initial_silence=True`, matching the
project asset build mode. The baseline render's first 45 seconds were verified
sample-for-sample against `assets/gameplay/audio/match_track_55_rom_generated.wav`.
FCEUX was not launched; the retained WAV was read only.

The source ROM SHA-256 remains
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
Baseline NSF SHA-256 is
`74f0fe5153b99a6ccfbdc7be45023960039223b3c74bcbbd6ba55080cda515f8`; seeded
NSF SHA-256 is
`b51753534b922fee9f4ed43acc875439608130e973b012ff1e1847dd2d369d6a`.
The seeded 45-second PCM SHA-256 is
`7f1ca26c47dbbef590dd71346bf9b9b497a29671e17e55f0c97c0bf88ede97d8`.
The retained FCEUX PCM SHA-256 is
`900fae09d17d3b2c0c49332c5ef50948ad0c5201d651f925f0a4ec2daea15833`.
The NSF, seeded PCM, method, and full measurements are preserved in
[`first_match_4011_dac_seed_20261028`](../../diagnostics/audio/first_match_4011_dac_seed_20261028/experiment.json).

Using the measured queue-to-source-start offset of 807 samples, the event-timed
comparison over the 1,780,856-sample FCEUX first-request window did not improve:

| Candidate | Candidate index at source start | Pearson r | RMSE | Exact samples | Candidate RMS |
|---|---:|---:|---:|---:|---:|
| Baseline | 807 | -0.171442 | 5,247.739 | 174 / 1,780,856 | 3,852.043 |
| `$4011=$60` seed | 807 | -0.171785 | 5,247.469 | 190 / 1,780,856 | 3,850.819 |

As a secondary onset-only comparison, baseline first-nonzero trimming at sample
3065 reproduces the earlier result (`r=0.054655`, RMSE `4,732.145`). The seeded
candidate first becomes nonzero at sample 289; trimming there gives
`r=-0.204010`, RMSE `5,318.348`, and 155 exact samples. This onset trim is not
event-timed: the seed is applied at NSF initialization, whereas the ROM carried
the DAC latch from earlier route history. Neither alignment supports promoting
the seed as a production correction. The discrepancy is real, but this one
state value does not explain the PCM gap. The standalone-versus-route
driver/DMC event comparison is now recorded below. Production PCM and timing
were not changed.

## Standalone cue versus source-history driver events (28 Oct 2026)

The single-cue `$55` NSF starts after its wrapper clears all `$0000–$07FF`
driver RAM. To test whether the first-match route's earlier sound history
accounts for the different pulse-2 writes, a second NSF timeline was built
from the 14 ROM-only queue stores through source frame 4816, including the
opening music/effects, stops, and first `$55` request. The new
`tools/audio/build_first_match_bgm55_history_nsf.py` reads the preserved
`route_queue_history.csv`, verifies its SHA-256 and the source ROM hash, and
blocks the opening builder's default capture-derived event import. It uses no
FCEUX RAM timeline, screenshot, WAV, or PCM as synthesis input.

The isolated-cue trace was generated with:

```sh
python3 tools/audio/build_intro_nsf.py --track 0x55 \
  --output tools/audio/build/first_match_track_55.nsf
python3 tools/audio/trace_rom_driver_apu.py \
  --input-nsf tools/audio/build/first_match_track_55.nsf \
  --cpu-cycles 5360000 \
  --output-dir /tmp/ct2_match55_driver_event_trace_20261028
```

The source-history trace was generated with:

```sh
python3 tools/audio/build_first_match_bgm55_history_nsf.py \
  --output /tmp/ct2_match55_route_history.nsf
python3 tools/audio/trace_rom_driver_apu.py \
  --input-nsf /tmp/ct2_match55_route_history.nsf \
  --cpu-cycles 149000000 \
  --output-dir /tmp/ct2_match55_route_history_trace_20261028
```

Both libgme traces mute every voice and generate no PCM. The target was the
muted same-input FCEUX APU trace
`reference/diagnostics/kickoff_select_test_20261027/apu_writes.csv`; the
ROM-stepper APU sequence matched it in `(frame,address,value)` across the
route. The preserved trace outputs and their hashes are in
[`first_match_bgm55_driver_trace_20261028`](../audio/first_match_bgm55_driver_trace_20261028/README.md).

For the first 176 corresponding per-register update events after `$4000`:

- The isolated cue matches FCEUX values on `$4000–$4005`, `$4008`,
  `$400C–$400F`, and the initial `$4010/$4012/$4013/$4015` setup. The only
  value mismatches are pulse-2 `$4006` occurrences 0–39: each is `$EF` apart
  modulo 256, then all occurrences 40–175 match. Its initial `$4007` is `$18`
  versus route `$98`.
- Replaying the source-derived prior queue history removes those differences:
  all 176 compared per-register values, including the first `$4006/$4007`,
  match FCEUX. This proves that the isolated wrapper omitted driver history
  required for the initial pulse-2 register values; it does not prove that a
  particular RAM snapshot is the cause. A continuous ROM-driver timeline that
  executes the preceding source events is the verified state setup.
- Relative event timestamps, aligned at the first `$4000`, do not show
  cumulative frame drift over the 176-update window. The single-cue residual
  is -231 to +21 CPU cycles (median -40); the source-history residual is -259
  to 0 cycles (median -69). The source-history NSF's absolute first write is
  63,059 cycles early because its wrapper event/frame phase does not execute
  the game's route scheduler; this is not a source timing correction.
- The first 1,285 DMC sample-byte address/value reads in both NSF traces match
  the source route's DMC-read prefix. This verifies sample selection and byte
  order for that prefix, not hardware DMA phase or arbitration.

This narrows, but does not close, the PCM discrepancy. A single fresh cue has a
short pulse-2 startup-state mismatch, and ROM-source queue replay restores the
matching register stream. The remaining longer-window waveform gap is not
explained by that transient. Exact 2A03/APU evolution, DMC timing, FCEUX WaveHi
mix, resampling, and filter contributions remain unisolated. No production
WAV, cue timing, or runtime presenter was changed.

## Recorded-input route event parity diagnostic (28 Oct 2026)

Run the diagnostic-only replay with:

```sh
godot --headless --audio-driver Dummy --path . \
  --script tools/diagnostics/audit_kickoff_route_audio_event_parity.gd
```

It validates the post-title input-file hash, replays those input edges through
the current Godot route to frame 8953, and compares actual audio-presenter
start/stop signals with the ROM-only source queue table in
`first_match_audio_queue_events_20261027.json`. It writes a report named
`ct2_first_match_audio_event_parity_20261028.json` to the temporary system
directory. It reads no captured WAV/PCM and does not alter runtime audio
behavior.

The replay completed and reported `MISMATCH` (0/10 expected player events
matched exactly). Godot's cutscene VM emitted the first `$55` at route tick
4773; the corresponding ROM queue store is at source frame 4816, but the
route tick is not a verified ROM frame. The presenter then reported `$55`
stopped and `$53` started at route tick 8113; the source queue trace instead
has `$01` at frame 8108 and `$53` at frame 8271. The route emitted no second
`$55` from the direct `$812C/$812F` fresh-match setup store at frame 7409, no
`$53` stop at frame 8443, and no starts for fixed-bank queue events `$3C`,
`$66`, `$2B`, or `$2C` by the frame-8953 endpoint. These are event and route
integration gaps, not waveform comparisons; the source event table is
validation data and is not loaded by runtime. The inspected presenter has no
safe independent correction: it consumes queue IDs and caller-supplied route
ticks, while the source-owned task/callback events and absolute clock are not
executed. See the focused
[`audio integration boundary note`](first_match_audio_integration_boundary_20261028.md)
for the caller path and separate PCM limitation.
