# First-match audio integration boundary — 28 Oct 2026

## Finding

The current ROM-cue presenter has no source-backed audio correction that can
be applied independently of `KickoffRouteRuntime`. It correctly plays the
ROM-derived cue resources when called, and its `$55` startup transform uses
the two verified ROM queue-to-first-pulse delays. The incomplete behavior is
upstream: the live route does not execute the ROM task/callback path that
issues most queue writes, and its cutscene VM tick is not an NES source-frame
or CPU-cycle clock. Adding cue calls at observed frame numbers would hide
those missing source events and would not reproduce the game logic.

## Queue-write and route-call boundary

The ROM-only route queue table is
[`first_match_audio_queue_events_20261027.json`](first_match_audio_queue_events_20261027.json).
It derives from the checked Turkish ROM and source-CPU stepper, not from
captured PCM. The muted FCEUX APU-write log independently agrees with the
source-stepper's `(frame,address,value)` sequence for all 42,228 writes across
the 3,736 frames containing APU writes. This validates register-write
behavior, not rendered audio.

The first `$55` request is the ID-1 cutscene stream's byte pair `$ED $55` at
script CPU `$A2AA`. Its source path reaches the fixed `$85EC` handler, stores
to `$0700` at `$85FC`, and returns at `$85FF`; the queue write is recorded at
ROM frame 4816. The Godot `RomSoundQueueWriteEvent` preserves this command,
script offset/index, and handler/store PCs. It deliberately marks absolute ROM
frame and CPU cycle unknown and `timing_verified=false`, because the VM emits
on its own route tick. The parity replay observed the corresponding Godot
presenter start at route tick 4773. The 43-tick difference cannot be fixed by
relabeling the tick as a ROM frame.

The second `$55` is a separate direct match-setup write at bank-0 `$812C`,
with post-store PC `$812F`, at ROM frame 7409 when fresh-match index `$26` is
zero. It is not a cutscene command or a menu confirmation. The false MEETING
confirmation dispatch has already been removed; the current route's ROM task
runner does not reach `$812C/$812F`, so the Godot presenter does not emit this
second request. Do not manufacture it from menu state or a frame constant.

The byte-checked caller path is the fresh KICK OFF branch at `$80E6–$80EE`:
after dispatching cutscene 1, `$80EE` calls the Select-aware `$82B5` wait. On
natural completion or Select cleanup, that helper returns to the caller at
`$80F1`; the caller performs new-game setup and reaches the direct queue block
at `$8122–$812F` before checking the `$83DC[$26]` pre-match cutscene table at
`$8145–$815C`. The queue block is:

```text
$8122  A2 55       LDX #$55
$8124  A5 26       LDA $26
$8126  C9 20       CMP #$20
$8128  90 02       BCC $812C
$812A  A2 4C       LDX #$4C
$812C  8E 00 07    STX $0700
$812F              ; post-store PC
```

Thus the ROM does not unconditionally restart `$55`: the source caller must
reach this instruction block and its live `$26` branch must select `$55`;
`$26 >= $20` selects `$4C`. The ROM-only stepper records the `$55` store at
source frame 7409 / cycle 220630517 with post-store PC `$812F`. In the retained
muted FCEUX trace, the selected PC hook is at the ID-2 stream entry `$A626`
from source frames 7408–7409, and the complete APU `(address,value)` sequence
matches the source-stepper trace. This independently corroborates the route
region and resulting register writes, but the hook list does not contain
`$812C`; it does not establish that Godot reached the caller or give it a
source-clock event.

The current production route still does not compose this caller continuation.
Its cutscene-1 completion maps to `MATCHUP_PRESENTATION`, then follows a
Godot-side `$44`/MEETING interaction before ID 2; it does not resume the ROM
caller at `$80F1`. The separate fresh-match handoff model starts at the
cutscene-2 return and stops at the `$C557->$C6BE` gameplay scheduler boundary;
it neither executes the `$80F1–$815C` caller nor runs the fixed task bodies.
The route therefore has neither a source-owned `$812C` event nor the live
`$26` value/control-flow receipt needed to produce one. Cutscene ID 1
completion, `$A626` entry, a menu action, and the observed frame 7409 are not
safe substitutes for that event.

The next required source event is the fresh KICK OFF caller resuming after
`$82B5` returns, with its new-game setup continuation and `$26` supplied by
modeled source state. A source runner must carry that continuation through
`$8122–$812F` and emit the audio queue event only when `$812C` actually stores
the branch-selected X value to `$0700`, preserving the executing source frame
and CPU cycle. Until that caller/control-flow boundary is implemented, keep
the second `$55` absent in Godot rather than attaching it to an observed route
tick.

For the retained same-input replay through frame 8953, the parity audit found
0 of 10 expected player start/stop events matched. The presenter observed
only `$55` start at route tick 4773 and `$55` stop plus `$53` start at tick
8113. The ROM queue trace instead has `$55` at 4816, `$01` at 7243 and 7266,
the direct `$55` setup write at 7409, `$01` at 8108, `$53` at 8271, `$01` at
8443 and 8460, then `$3C`, `$66`, `$2B`, and `$2C` at 8607, 8624, 8664, and
8786. The route emits no matching stop for `$53` or starts for those four
later queue IDs. Some `$ED` stream literals are statically present, but the
live script pointer was not recorded for every dispatch; those literals do
not provide a source timing schedule.

The presenter is downstream of these boundaries: `apply_rom_sound_command`
plays a checked cue manifest/WAV and emits start/stop signals at the supplied
route tick. `$01` stops current voices, empty `$31` is accepted without
playback, and unsupported IDs fail closed. For `$55`, it strips the verified
3,065 leading zero samples from the ROM-driver render and prefixes 807 or
1,239 silence samples based on ROM-stepper queue-to-first-pulse cycle deltas.
The presenter does not read the event-table JSON, ROM, emulator captures, or
captured WAV/PCM at runtime.

## Remaining PCM limitation

The Godot AudioServer path preserves the ROM/NSF-generated `$55` WAV exactly
after the source-derived trim: 219,627 compared samples were byte-identical
to the source render (`r=1.0`, RMSE 0). Against the same-input FCEUX output,
the five-second Godot capture is not equivalent: queue/source-time alignment
gave `r=-0.250135`, RMSE `5612.314`, and 7 exact samples; cropping both signals
to their first nonzero sample gave `r=0.380653`, RMSE `4004.443`, and 40 exact
samples. The 66-sample Godot capture onset offset is specific to that
headless AudioServer capture and is not a production timing adjustment.

The remaining waveform difference is upstream of Godot playback, between
libgme's ROM/NSF render and FCEUX's APU/mixer/resampler/filter output. The
28 Oct driver-event comparison now isolates one bounded initialization effect:
the single-cue `$55` NSF begins with cleared driver RAM and differs from the
first-match route for pulse-2 `$4006` over its first 40 writes and `$4007` on
the first write. A source-only NSF that replays the 14 preceding ROM queue
events reproduces all 176 compared per-register write values, including the
initial pulse-2 values; its first 1,285 DMC sample-byte address/value reads
also match the route source prefix. This shows that the standalone cue omits
history needed for those initial driver outputs. The relative APU write times
do not accumulate frame drift over that comparison window, though the history
NSF's absolute event phase is 63,059 cycles early because it does not execute
the route scheduler. These register/DMC findings do not resolve the remaining
long-window PCM mismatch or distinguish 2A03/APU state evolution, DMC timing,
WaveHi mixing, resampling, and filter behavior. Full-route PCM and SFX parity
remain unverified. Captured PCM and FCEUX APU writes remain validation
artifacts only; neither is runtime audio input. Reproduction commands, trace
hashes, and outputs are in
[`first_match_bgm55_driver_trace_20261028`](../audio/first_match_bgm55_driver_trace_20261028/README.md).

## Evidence

- [`first_match_audio_source.md`](first_match_audio_source.md): ROM queue
  sources, `$55` mapping/timing, Godot AudioServer comparison, and route event
  parity report.
- [`first_match_audio_integration_audit_20261027.md`](first_match_audio_integration_audit_20261027.md):
  ROM-derived cue assets and signal/rendering limits.
- [`first_command_callback_scheduler_trace_20261028.md`](first_command_callback_scheduler_trace_20261028.md)
  and [`first_command_live_route_composition_boundary_20261028.md`](first_match_live_route_composition_boundary_20261028.md):
  missing source-owned route/task transitions.
- `tools/diagnostics/audit_kickoff_route_audio_event_parity.gd`: same-input,
  capture-free queue/player-event comparison; report is written under `/tmp`
  and is not runtime input.
