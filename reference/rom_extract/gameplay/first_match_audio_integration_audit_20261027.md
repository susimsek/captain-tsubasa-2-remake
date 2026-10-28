# First-match route audio integration audit — 2026-10-27

## Source identity and route queue events

The input reference is the supplied Turkish ROM, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`. The
source-only CPU route trace records stores to the sound queue through source
frame 9042. Its decoded runtime queue events are:

| Source frame | Queue ID | Evidence / route context |
|---:|---:|---|
| 4816 | `$55` | Cutscene `$ED $55`; post-handler PC `$85FF` |
| 7243 | `$01` | Select skip cleanup; direct bank-0 stop/control store |
| 7266 | `$01` | Direct bank-0 stop/control store |
| 7409 | `$55` | Fresh-match setup; post-store PC `$812F` |
| 8027 | `$31` | Cutscene ED handler; post-handler PC `$85FF` |
| 8108 | `$01` | Cutscene ED handler; post-handler PC `$85FF` |
| 8271 | `$53` | Cutscene ED handler; post-handler PC `$85FF` |
| 8443 | `$01` | Select skip cleanup |
| 8460 | `$01` | Fixed-bank source-stepper event; caller meaning not assigned |
| 8607 | `$3C` | Fixed-bank source-stepper event |
| 8624 | `$66` | Sound-test SFX ordinal 91 |
| 8664 | `$2B` | Sound-test SFX ordinal 78 |
| 8786 | `$2C` | Sound-test SFX ordinal 79 |

The source-stepper records queue values and source frames, but not a live
script pointer for every ED-handler event. IDs `$51`, `$45`, `$30`, and `$69`
also appear in the preserved linear ED command streams (ID 1: `$55,$31,$01,
$51,$31,$01,$45,$30`; ID 2: `$53,$69,$31`). They are not among the direct
queue events above. In the captured route, Select is used to leave the story
and matchup cutscenes; the script ordering suggests the later `$51/$45/$30`
and `$69` cues are bypassed, but the route capture did not hook the live script
pointer at those dispatches. Treat them as byte-verified possible script cues,
not as observed audible events.

The numbers `$35/$36/$44` are also used by separate field-scenario dispatches
in the route. That is a different ID namespace: the source queue log contains
no `$0700` audio-queue writes with these values. The audio pointer table also
has valid source-renderable entries for the same numeric audio queue values;
they are packaged below for explicit audio commands, but a field-scenario
selection by itself must not call the audio presenter. A future live trace
would be needed to establish whether this route actually issues any of those
audio commands.

## ROM-only cue renders and pointer mapping

Fourteen route/stream queue IDs now have project-owned WAVs rendered by the
original ROM sound driver and source sequence data through an offline NSF and
libgme. This is not captured FCEUX PCM. `$31` resolves to a header whose first
byte is `$FF`, so its ROM-driver render is silence. `$3C` was initially tested
with the wrong bank candidates; the driver's range selector maps IDs `$32–$43`
to bank `$0D`, resolving its sequence and producing a render.

| Runtime queue ID | Kind / sound-test ordinal | Queue table target and sequence | Runtime WAV |
|---|---|---|---|
| `$2B` | SFX / 78 | bank `$0C`, `$9453`, `0x019463` | `assets/gameplay/audio/match_sfx_2B_rom_generated.wav` |
| `$2C` | SFX / 79 | bank `$0C`, `$9803`, `0x019813` | `assets/gameplay/audio/match_sfx_2C_rom_generated.wav` |
| `$30` | SFX / 83 | bank `$0C`, `$9C13`, `0x019C23` | `assets/gameplay/audio/match_sfx_30_rom_generated.wav` |
| `$31` | Empty / no catalog entry | bank `$0C`, `$9FFE`, `0x01A00E` (header `$FF`) | `assets/gameplay/audio/match_sfx_31_rom_generated.wav` |
| `$35` | BGM / 34 | bank `$0D`, `$A5C6`, `0x01A5D6` | `assets/gameplay/audio/match_track_35_rom_generated.wav` |
| `$36` | BGM / 38 | bank `$0D`, `$B68D`, `0x01B69D` | `assets/gameplay/audio/match_track_36_rom_generated.wav` |
| `$3C` | BGM / 27 | bank `$0D`, `$B514`, `0x01B524` | `assets/gameplay/audio/match_track_3C_rom_generated.wav` |
| `$44` | BGM / 21 | bank `$0E`; fixed-bank stream `$8CC0`, `0x018CD0` | `assets/gameplay/audio/match_track_44_rom_generated.wav` |
| `$45` | BGM / 01 | bank `$0E`, `$A964`, `0x01C974` | `assets/gameplay/audio/match_track_45_rom_generated.wav` |
| `$51` | BGM / 02 | bank `$0F`, `$AAA8`, `0x01EAB8` | `assets/gameplay/audio/match_track_51_rom_generated.wav` |
| `$53` | BGM / 04 | bank `$0F`, `$A5E0`, `0x01E5F0` | `assets/gameplay/audio/match_track_53_rom_generated.wav` |
| `$55` | BGM / 03 | bank `$0F`, `$A30F`, `0x01E31F` | `assets/gameplay/audio/match_track_55_rom_generated.wav` |
| `$66` | SFX / 91 | bank `$0C`, `$99FC`, `0x019A0C` | `assets/gameplay/audio/match_sfx_66_rom_generated.wav` |
| `$69` | SFX / 93 | bank `$0C`, `$9F9C`, `0x019FAC` | `assets/gameplay/audio/match_sfx_69_rom_generated.wav` |

For each cue, the table pointer is at `0x18BEA + 2 * (queue_id - 1)` in the
bank-$0C driver's runtime pointer table. The BGM bank selection is byte-backed
at driver CPU `$8010–$805B`: `$32–$43` select bank `$0D`, `$44–$50` select
`$0E`, `$51–$5B` select `$0F`, and `$5C+` restores the saved bank. IDs below
`$32` use the saved/fixed bank path; the supplied sequence pointers for
`$2B/$2C/$30/$31/$66/$69` are in the driver bank's `$8000–$9FFF` window.

The build script is `tools/audio/build_match_route_audio_cues.py`. It copies
only ROM driver/data into ignored NSF intermediates under `tools/audio/build/`,
then renders project-owned mono 44.1 kHz WAVs. Each sidecar records the source
ROM hash, table offset, pointer, bank, source offsets, ordinal if known,
NSF/WAV hashes, and capture-free/standalone flags. Rebuild with:

```sh
python3 tools/audio/build_match_route_audio_cues.py
```

No emulator PCM, captured WAV, or capture-derived timestamps are synthesis
inputs. The runtime project uses only the generated WAVs and manifests; it
does not read the ROM, NSF intermediates, or emulator.

## Godot route audio API and remaining gaps

`GameplayRomCueAudioPresenter.apply_rom_sound_command(queue_id, source_frame)`
validates each manifest and WAV hash, dispatches one BGM plus up to four SFX
voices, handles `$01` as stop/control, and emits start/stop/unsupported
signals. It currently supports the fourteen ROM-resolved IDs above and fails
closed for unknown IDs. The separate route scene
`scenes/kickoff_route_runtime.tscn` connects cutscene `sound_command` events
to this presenter. The top-level `scenes/main.tscn` still launches only the
completed opening/title slice; the route scene's audio path is not proof of a
complete main-game integration.

`tools/diagnostics/verify_rom_cue_audio_presenter.gd` checks that all fourteen
manifests and hashes load, BGM/SFX voices coexist, `$01` stops playback, and
unknown queue IDs fail closed. It does not verify route timing or PCM
identity.

The generated cues remain ROM-only candidate renders. A muted same-input FCEUX
PCM comparison for both observed `$55` windows was completed after this audit's
initial draft; the capture is validation-only and did not enter the runtime
asset or synthesis path. The candidate/runtime WAV was not modified.

### `$55` PCM comparison and capture provenance

The reference WAV was recorded with FCEUX 2.7.0 at source revision
`a6d03e7968bd77a8156a7c9b628a673753f2f4c6`. A temporary local build enabled
the Qt wrapper's already-parsed `--soundrecord` option; no FCEUX source or
build artifact was added to the project. The exact route inputs from
`opening_replay.csv` and `post_title_inputs.csv` were replayed over source
frames 0–9042 (9,043 input frames). FCEUX used `SDL_AUDIODRIVER=dummy`, sound
enabled, master volume 255, and 44,100 Hz output, so no audio was sent to the
speakers. The merged ROM-only source input timeline SHA-256 is
`6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc`. The
resulting temporary WAV was mono signed 16-bit PCM, 6,635,653
samples (150.468322 s), SHA-256
`900fae09d17d3b2c0c49332c5ef50948ad0c5201d651f925f0a4ec2daea15833` at
`/tmp/ct2_kickoff_route_reference_volume255.wav`. It was reopened and checked
for valid WAV metadata and non-silent samples. FCEUX exited with a Qt worker
thread abort after the Lua replay called `emu.exit`, but finalized WAV data
remained readable. The capture is not tracked or used at runtime.

The two reference windows are projected from the ROM-only source-stepper CPU
cycles. Sample index is `round(cycle * 44100 / 1789773 - 25.256)`: the
25.256-sample correction is FCEUX `soundq=2` FIR priming, documented in
`reference/rom_extract/audio/offline_renderer_next_step.md` and
`reference/rom_extract/audio/fceux_wavehi_implementation_map_20261024.md`.
Start is the first `$4000` setup write for the cue; end is the driver's first
mute write `$4000=$30` after the `$01` stop/control request. For the direct
PCM comparison, candidate sample 3065 (its first nonzero sample) was aligned
with each source start. This is an explicit comparison convention; the
capture's per-device filter/phase relative to libgme is not independently
measured.

| `$55` occurrence | Source start → stop | Projected FCEUX sample window (end exclusive) | Samples / seconds | Exact equal samples | Pearson r | RMSE | Reference / candidate RMS |
|---|---|---:|---:|---:|---:|---:|---:|
| Cutscene, first request | frame 4817 cycle 143,429,288 → frame 7244 cycle 215,704,288 | `[3,534,072, 5,314,928)` | 1,780,856 / 40.382222 | 237 (0.0133082%) | 0.0546555 | 4,732.145 | 2,964.053 / 3,854.403 |
| Fresh-match setup, restart | frame 7411 cycle 220,680,808 → frame 8109 cycle 241,464,199 | `[5,437,549, 5,949,652)` | 512,103 / 11.612313 | 27 (0.00527238%) | 0.2466541 | 4,368.109 | 3,065.472 / 3,958.446 |

The compared candidate is `assets/gameplay/audio/match_track_55_rom_generated.wav`,
SHA-256 `aa297e4dd8f9bde1b6202f6075c63b28ca49eb3a93227f4c4a5a4190bf9e4f95`
(mono 44.1 kHz, 16-bit, 90-second libgme render from the ROM-derived NSF).
These direct comparisons do **not** establish PCM equivalence: exact matches
are rare and full-window correlation is low. The different master-level RMS
also affects RMSE. The result therefore does not validate replacing or
promoting the candidate; production audio remains unchanged. It does establish
that the present single-cue NSF/libgme render is not yet a verified match for
the game's `$55` output during this route. The remaining audio gap includes
driver/APU synthesis and mixing differences, cue-start phase, stop-tail/filter
state, and route SFX overlap; no capture-derived correction was fitted.

### Full-route ROM-source WaveHi diagnostic

The same route was also rendered by
`tools/audio/render_rom_stepper_wavehi_candidate.py` from the ROM-only
stepper's 87,680 APU writes, 596,576 four-cycle DMC read rows (149,144 output
bytes), 9,042 frame-cycle rows, and 269,275,286 source CPU cycles. The tool's
output is diagnostics-only, not a runtime resource. Its source event files
were copied into the ignored
`tools/audio/build/first_match_route_wavehi_20261027/` workspace because this
wrapper requires report paths beneath the project root; the event hashes
remain those from `/tmp/ct2_first_match_rom_stepper_20261027/`. No FCEUX
timestamps, pixels, or PCM were used to synthesize it. The candidate is
`rom_stepper_wavehi_candidate.wav`, SHA-256
`72dfaaf53b21c0bacc9b6cd59c1c081459865c517fbb9d8e11d20cd566322f57`, with
6,634,919 samples at 44.1 kHz. It was compared to the FCEUX capture at the
same projected sample indices in the table above, without lag fitting.

| `$55` occurrence | Exact equal samples | Pearson r | RMSE | Reference / diagnostic-candidate RMS |
|---|---:|---:|---:|---:|
| Cutscene, first request | 588 / 1,780,856 (0.0330178%) | 0.8474428 | 1,682.665 | 2,964.053 / 3,107.869 |
| Fresh-match setup, restart | 137 / 512,103 (0.0267524%) | 0.8412834 | 1,764.865 | 3,065.472 / 3,185.982 |

This improves correlation substantially over the isolated libgme track
comparison, but it is not PCM parity. The diagnostic renderer uses the pinned
FCEUX WaveHi mixer/resampler/filter over ROM-stepper events; the source
stepper's DMC arbitration remains a diagnostic model. The original run reports
54 DMC read/buffer-phase conflicts and models DMC bit-timer/DAC phase with an
assumed initial state. The route output is 734 samples shorter than the muted
FCEUX recording (about one video frame), so same-index windows do not validate
end-of-route length or stop tail. These bounded comparisons are useful
diagnostics, but the remaining timing/synthesis gaps prevent claiming
exactness or promoting the candidate. Both the libgme runtime WAV and Godot
audio assets remain untouched.

### ROM-source DMC state correction experiment

To trace the 54 buffer conflicts, the same cold-start input was executed again
through source frame 9042 with the ROM-only CPU/APU/DMC stepper. Its event
window list came from the first candidate's 54 reported conflict cycles; the
list was used only to filter which already-executed source events were
exported afterward (`used_only_for_post_run_event_export_filter=true`), not
as scheduler or synthesis input. The retained compressed file has SHA-256
`ee28ab3566268975d728486009123faaf38766a9f82ba838d972d3ce74d52647` and 3,964
events across the 54 ±600-cycle windows. The renderer consumed 1,350
`DMC_BIT_EDGE` and `DMC_BUFFER_LOAD` state rows (1,188 bit edges), with state
from this ROM-only replay. It did not consume FCEUX DMC timestamps or PCM.

The first explicit baseline conflict is source frame 385, at the fourth DMR
phase of the C1C8 read (`$C1C8=$AA`, cycle 11,436,326; DMR event index 4611).
The source event stream shows a preceding buffer load of `$C1C7=$E9` at cycle
11,436,316. A source DMC bit edge has `edge_cycle=11,436,315` and its
instruction-hook snapshot at cycle 11,436,320 records `dmc_have_dma=0`,
`dmc_bit_count=0`, and the prior byte shifted into the sample register. The
next `$C1C8` `DMC_BUFFER_LOAD` at cycle 11,436,326 reports
`dmc_have_dma_before=0`, `dmc_bit_count_before=0`, and `dmc_acc_before=49`.
The uncorrected WaveHi candidate still had its DMC DMA buffer marked full at
that read and recorded a conflict. This is the first explicit state mismatch
reported by the renderer; the exact instant of the underlying divergence
could be earlier within the hook.

Applying the source state rows around the conflict windows removed all 54
renderer buffer-phase conflict reports (0 remained). The same two
sample-index comparisons changed as follows; neither used lag fitting.

| `$55` occurrence | Baseline equal / r / RMSE | Source-state corrected equal / r / RMSE |
|---|---:|---:|
| Cutscene, first request | 588 / 1,780,856 (0.0330178%) / 0.847442830 / 1,682.665 | 608 / 1,780,856 (0.0341409%) / 0.847626225 / 1,681.065 |
| Fresh-match setup, restart | 137 / 512,103 (0.0267524%) / 0.841283377 / 1,764.865 | 142 / 512,103 (0.0277288%) / 0.841290607 / 1,764.633 |

The corrected diagnostic WAV is
`tools/audio/build/first_match_route_wavehi_20261027/source_state_corrected_candidate/rom_stepper_wavehi_candidate.wav`,
SHA-256 `7f0969bdc02a26c8be16065ec0406734bc9a9496a5e9f9793e417e7e12f8f263`.
It remains under the ignored build directory; the route audio presenter,
candidate libgme WAV, and manifests were not changed. The zero conflict count
shows that replaying the source stepper's state rows resolves its own reported
buffer-state disagreements. PCM changes are small, so it does not validate
full audio equivalence.

### Remaining DMC timing boundary

The source stepper's `_dmc_hook` refills the sample buffer before it subtracts
the completed instruction-hook cycle batch from `dmc_acc`; it then reports a
bit edge at `edge_cycle = hook_end_cycle + dmc_acc`. At the first conflict,
the resulting edge label (cycle 11,436,315) precedes the `$C1C7` refill event
(cycle 11,436,316), while the stepper's hook-end state applies that refill to
the edge. This documents the first unresolved CPU/DMA ordering boundary in
the current ROM-source model. The route state export is generated by that same
model, and direct same-input FCEUX validation of its DMC hook state extends
only through frame 380; the first route conflict is frame 385. ROM bytes and
the present event logs do not establish physical 2A03 arbitration/order
within that hook. A cycle-accurate DMA/APU schedule (or a source-backed hook
trace beyond frame 380) is still needed for a stronger result. No measured
correction was fitted, and the production WAV remains unchanged.

### 2026-10-28 full-cue source DMC-edge replay probe

To test whether the renderer's per-cycle DMC approximation explains the
remaining `$55` mismatch, a second ROM-only source-stepper pass exported DMC
state events over source frames 4817–8109 (the first `$55` request, its stop,
and the fresh-match restart). The filtered cycle interval was
`[143,422,889, 241,490,079]`; the event-window filter only restricted which
already-executed ROM-source events were retained. The input timeline SHA-256
was `6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc` and
the ROM hash remained
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
The run exported 5,689,517 ordered event rows. The compressed state stream
SHA-256 is
`e955661c6c1572aa9e9415dbb5502c235f02f2b62163167b215b486363a9c204`;
1,848,230 `DMC_BIT_EDGE`/`DMC_BUFFER_LOAD` rows were passed to the WaveHi
renderer, including 1,816,059 bit edges. This pass used no FCEUX timestamps,
state, or PCM to schedule or synthesize audio.

Against the same-input FCEUX validation WAV (SHA-256
`900fae09d17d3b2c0c49332c5ef50948ad0c5201d651f925f0a4ec2daea15833`),
replaying all of those source DMC states **worsened** both fixed sample-index
windows. The run rendered 6,634,919 samples (WAV SHA-256
`b8023a40e15c158512a9f69135d3f2e37a5c4516276169c4397faecd8e9f930d`) and
still reported 42 source-buffer phase conflicts.

| `$55` window | Baseline `r` / RMSE / RMS ratio | Full-edge replay `r` / RMSE / RMS ratio |
|---|---:|---:|
| First request, samples `[3,534,072, 5,314,928)` | `0.847443 / 1,682.665 / 1.048520` | `0.805107 / 2,311.843 / 1.311601` |
| Restart, samples `[5,437,549, 5,949,652)` | `0.841283 / 1,764.865 / 1.039312` | `0.806594 / 2,419.601 / 1.329661` |

The earlier sparse replay of only the 54 renderer-reported conflict windows
was much smaller (`r=0.847626` / `0.841291`) and changed PCM only slightly;
the all-edge replay is not a valid correction. Together with the exact
42,228/42,228 route APU `(PC,address,value)` sequence match, this rules out a
missing/wrong music command stream as the main measured residual. The
stepper's all-edge DMC state is not independently validated against FCEUX
beyond the previously documented frame-380 boundary, and replaying it does
not make the audio closer. The remaining DMC edge/DMA ordering, frame-sequencer
phase, mixer/filter history, and audible route parity remain unresolved. Keep
all candidates diagnostic-only; the production libgme WAV, manifest, and
Godot audio code were not changed.

Re-run in the existing temporary Py65 environment with the ROM-only route
timeline. The event-window JSON contains one center cycle (`192456484`) and
the `49033595` radius below; it is an export filter, not a synthesized event.
Its SHA-256 is `bb41c4bec8ef5b1e7b9587282e2d23b4d253a72c65f70859b87b8df889fa3bda`:

```sh
cat > /tmp/ct2_first_match_route_dmc_state_windows_20261028.json <<'JSON'
{"source_events":{"renderer_dmc_buffer_phase_conflicts":{"cycles":[192456484]}}}
JSON

/tmp/ct2_rom_stepper_venv/bin/python tools/diagnostics/step_rom_source_cpu_ppu_dmc.py \
  --end-frame 9042 \
  --out-dir /tmp/ct2_first_match_route_dmc_state_20261028 \
  --input-timeline /tmp/ct2_first_match_route_input_20261027.csv \
  --export-dmc-state \
  --event-cycle-windows /tmp/ct2_first_match_route_dmc_state_windows_20261028.json \
  --event-cycle-window-radius 49033595 \
  --event-windows-only

mkdir -p tools/audio/build/first_match_route_wavehi_20261027/source_state_cue_windows_20261028
cp /tmp/ct2_first_match_route_dmc_state_20261028/source_apu_dmc_state_events.csv.gz \
  tools/audio/build/first_match_route_wavehi_20261027/source_state_cue_windows_20261028/source_apu_dmc_state_events.csv.gz

python3 tools/audio/render_rom_stepper_wavehi_candidate.py \
  --stepper-dir tools/audio/build/first_match_route_wavehi_20261027/stepper_input \
  --source-dmc-state-events tools/audio/build/first_match_route_wavehi_20261027/source_state_cue_windows_20261028/source_apu_dmc_state_events.csv.gz \
  --output-dir tools/audio/build/first_match_route_wavehi_20261027/source_state_cue_windows_20261028/candidate
```

The source-state stream, route-stepper source files, and generated candidate
are under temporary or ignored build paths; their hashes above identify this
run but those large generated files are not project runtime assets.

For the observed `$55` cue, the first APU register writes follow its queue
request by one source frame at frame 4816 and two frames at frame 7409; the
Godot dispatcher currently starts at the sound-command event and does not
reproduce this driver delay. Loop points, cross-cue phase, SFX mixing/timing,
and audible equivalence remain unverified.

`$01` is treated as a stop/control request by the Godot presenter. `$3C` is no
longer unresolved: it is a bank-$0D BGM and has a ROM-only render. The event at
`$8460` has a source queue value `$01` but its caller meaning remains
unassigned. The audio pointer values `$35/$36/$44` can now be dispatched as
sound commands, but the route trace only shows those numbers as scenario IDs;
no route audio event with those values is claimed. All source-renderable IDs
found in the current ID1/ID2 ED stream inventory and direct route queue log
have ROM-only project assets; no reference PCM/timing equivalence is claimed.

Evidence: `first_match_audio_source.md`,
`kickoff_cutscene_timing_audit_20261027.md`,
`fresh_start_to_first_command_menu.md`, and the supplied ROM bytes at driver
bank `$0C` file offset `0x018010` and pointer table `0x018BEA`.
