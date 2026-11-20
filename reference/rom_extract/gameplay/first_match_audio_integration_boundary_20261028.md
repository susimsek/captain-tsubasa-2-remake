# First-match audio integration boundary — 28 Oct 2026

## Current status — 9 November 2026

This report contains historical snapshots; the 28 October finding below is
superseded by the current route audit. The production route now matches all 10
ROM-derived queue events at their source frames, including the scene-$56
`$31/$01/$53` events. The recorded-input route reaches the first command menu
without action confirmation or Continue.

The accepted FCEUX 2.7.0 capture completed the exact 9,043-frame input movie.
The ROM-only WaveHi route render matches all 6,634,919 common same-index
samples at 44.1 kHz exactly; the finalized FCEUX file has 734 additional
active samples, one output frame beyond the source-render endpoint and after
the required frame-8953 menu. No fitted offset, gain, or resampling is used.
All 42,228 APU writes now match frame/address/value/PC/cycle. The stepper's
NMI2 latch models FCEUX's one-instruction delay when `$2000` bit 7 rises during
vblank; the observed requests at frames 6513 and 7113 match FCEUX at cycles
193932668 and 211800839. The frame-8123/8124 scene-$56 pointer boundary still
does not establish physical same-frame NES CPU/PPU phase.

The host audio mixer is a separate boundary: the Dummy-driver capture produced
fewer samples than the scheduled source window, and local CoreAudio uses 48 kHz.
No 44.1 kHz host-device PCM identity is claimed. The ROM-source render and
runtime cue asset are verified; physical output-device phase is not.

## Historical finding — 28 Oct 2026

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

## 2026-10-29 live-route integration audit

The newly advanced Godot route now source-executes the post-cutscene-2 match
task path through slot `$09` to `$86F8`, then takes the live `$0532=0` path back
to `$EBB3`. This is later than the `$812C` caller block: it does not execute or
validate the missing pre-ID-2 caller path. In
`KickoffRouteRuntime`, production audio commands still enter through the
cutscene `$ED` presenter event and `RomSoundQueueWriteEvent`; the direct
`$812C` write is not connected. `RomFreshKickoffCallerContinuation.get_status()`
also reports `live_runtime_integrated=false`.

The existing component is useful as a ROM-byte projection, but cannot yet be
fed to production without inventing returns. Before it emits `$812C`, it
requires named return receipts for these caller sites:

```text
$80E6->$9BA0   $80EB->$8464   $82DF->$9BA0
$80F7->$C4B9   $80FA->$A20F   $810C->$C4B9
$810F->$A20C   $8114->$8920   $8119->$C4B9
$811C->$A006   $811F->$C572
```

The projection checks each receipt's caller/target/return PCs and a non-empty
event ID, but does not execute those helper bodies, the `$82B5` scheduler wait,
the nested stack, or CPU/NMI timing. Its accepted `$26`/`$E0` state at `$8145`
must therefore be supplied by an actual source-owned caller continuation; a
trace RAM sample or a manually assembled receipt list is not enough. After the
store, the same component also expects returns from `$813F->$C4B9` and
`$8142->$A009` before it derives the `$83DC[$26]` cutscene-2 dispatch. The
caller-span manifest already covers the `$8122-$812F` bytes (CPU `$8122` maps
to bank-$00 file offset `0x000132`; the store at `$812C` is offset
`0x00013C`), so a new asset extraction is unnecessary.

The audio presenter already accepts ROM-derived BGM `$55` and has timing
entries for its two route occurrences. Once live execution reaches `$812C`,
the production consumer can forward the actual stored X value and its source
event time. Until then, do not start the second `$55` from the later `$86F8`
boundary or from a Godot frame count; that would place the same track at the
wrong point in the ROM route.

The next required source event is the fresh KICK OFF caller resuming after
`$82B5` returns, with its new-game setup continuation and `$26` supplied by
modeled source state. A source runner must carry that continuation through
`$8122–$812F` and emit the audio queue event only when `$812C` actually stores
the branch-selected X value to `$0700`, preserving the executing source frame
and CPU cycle. Until that caller/control-flow boundary is implemented, keep
the second `$55` absent in Godot rather than attaching it to an observed route
tick.

Historical parity audit (2026-10-28; its route harness did not initialize the
production title handoff): for the retained same-input replay through frame
8953, the parity audit found
0 of 10 expected player start/stop events matched. The presenter observed
only `$55` start at route tick 4773 and `$55` stop plus `$53` start at tick
8113. The ROM queue trace instead has `$55` at 4816, `$01` at 7243 and 7266,
the direct `$55` setup write at 7409, `$01` at 8108, `$53` at 8271, `$01` at
8443 and 8460, then `$3C`, `$66`, `$2B`, and `$2C` at 8607, 8624, 8664, and
8786. The route emits no matching stop for `$53` or starts for those four
later queue IDs. The live `$ED` pointers for the earlier `$31/$01/$53` events
were captured in the 9 November trace below; the pointers alone do not provide
a Godot runtime schedule.

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

## Production integration update — 3 November 2026

The live recorded-input route now continues from the stamina return at `$8122`
through the caller's byte-checked `$8122-$812F` branch. It reads source RAM
`$0026=0`, selects BGM queue `$55`, stores that byte at `$0700` from `$812C`,
and emits a typed `rom_direct_queue_store` event to
`GameplayRomCueAudioPresenter.apply_rom_sound_command`. The focused route
verifier observes `applied=true` and holds at `$812F` on route frame 7410; the
event is labeled route frame 7409 to preserve the caller event boundary.

This verifies the caller branch, queue RAM store, and presenter handoff. It
does not verify subframe onset, loop phase, SFX mix, or same-input PCM. The
route still does not execute `$812F-$815C`, the `$A009` caller return, or the
pre-match cutscene-table dispatch. Runtime still uses ROM-derived cue assets;
captured WAV and FCEUX APU output remain validation data only.

## Full live-route audio event check — 2026-11-09

The production title handoff and recorded post-title input harness now reach
the first command menu at frame 8953. The diagnostic mutes the Godot Master
bus, listens to `GameplayRomCueAudioPresenter` start/stop signals, and compares
them with the ROM-source queue-event table. It does not read captured WAV/PCM
as runtime input.

Godot emitted these queue-driven presenter events (ticks are Godot route ticks,
not verified ROM frame numbers): `$55` start 4815, stop 7243, start 7409;
`$55` stop and `$53` start together at 8139; `$53` stop 8443; `$3C` start 8607;
`$66` start 8624; `$2B` start 8664; and `$66` start 8759. A simple numeric tuple
comparison against the ten expected source playback events matches 6/10, but
this is not timing parity because the Godot event clock is not yet bound to the
ROM source clock.

Before the 9 November correction below, four mismatches were recorded: the
first `$55` started one numeric tick early (4815 versus 4816); the expected
`$55` stop at 8108 and `$53` start at 8271 instead arrived together at 8139;
and expected `$2C` at 8786 was replaced by `$66` at 8759. The scenario-$36
`$2C` mismatch is now closed at frame-level queue-event granularity. The earlier
`$55/$53` differences remain open.

The route queue summary and player signals are in
`/tmp/ct2_recorded_input_gui_8964.log`. Same-input RAM snapshots are validation
evidence only. Full-route PCM/APU parity and exact source-cycle audio onset
remain open.

## Scenario-$36 `$F9` operand correction — 9 November 2026

A focused muted FCEUX replay from the verified frame-4692 in-session checkpoint
captured the slot-$09 root checks and writes to `$052E/$052F/$0530/$0531` in two
passes. The two `slot09_source_trace.csv` outputs are byte-identical. The trace
shows the ROM writing `$0530=$1D` and `$0531=$2C` at frame 8718; the root copies
those values into `$052E/$052F` at frame 8758, then decrements the active
counter once per frame beginning in that frame, and queues `$2C` at frame 8786. See
[`slot09_source_trace.csv`](../../diagnostics/kickoff_select_cleanup_counters_20261109_042229_utc/slot09_source_trace.csv),
its [repeat pass](../../diagnostics/kickoff_select_cleanup_counters_20261109_042229_utc/slot09_source_trace_repeat.csv),
and [trace metadata](../../diagnostics/kickoff_select_cleanup_counters_20261109_042229_utc/metadata.txt).

The source scenario stream at bank-$10 pointer `$B802` contains `$F9 1D 2C`
(scenario-$36 stream offsets `$1E–$20`). The Godot continuation had read the
first `$F9` payload at fixed offsets 9–10 even when the live pointer selected
`$B802`; it therefore reused `$02/$66`. The producer now reads the two operand
bytes relative to the selected source offset. This uses ROM bytes and the live
scenario pointer, not captured RAM values.

The recorded-input Godot route now reaches the same menu boundary and logs the
source `$2C` request at route tick 8786, with no extra `$66` request at 8759.
The same-input keyboard/D-pad route checks still pass without action
confirmation. This establishes frame-level queue-event alignment for this
scenario command, not CPU-cycle onset, APU register parity, or PCM equality.
The earlier `$55` start/stop and `$53` start timing differences remain open.

## Live story-audio stream pointers — 9 November 2026

The updated two-pass muted FCEUX route trace records the active `$004D/$004E`
pointer and mapped PRG bank at each store to `$0700`. It confirms `$ED $31` at
bank `$05:$BFD5` on frame 8027, `$ED $01` at bank `$05:$BFF0` on frame 8108,
and `$ED $53` at bank `$03:$A62F` on frame 8271. The `$55` event at frame 4816
comes from bank `$03:$A2AA`. The trace output and repeat pass are documented in
[`first_match_audio_source.md`](first_match_audio_source.md).

This replaces the earlier static `$A3E1` attribution for the `$01` event and
gives a source address for the stop command. The pointer table and menu code
identify `$BFBA` as selected scene `$56`: `$A6C4` directly loads
`tbl_B41B[$26]`, whose fresh-match byte is `$56`; its `$FE` jumps to `$BFD5`,
inside scene `$58`'s pointer span. The 17-event flattened stream is preserved
in `assets/gameplay/rom_logic/kickoff_meeting_scene_56_events.json` and passes
an isolated Godot VM check. The production route still skips scene `$56` and
starts its ID-$02 VM after the meeting-menu callback, so neither the scene's
visual command consumer nor its source return/task context is integrated.

The same-input frame-edge RAM captures make the timing gap concrete. FCEUX has
`$4D/$4E=$BFF2` after the frame-8108 `$01` write; the pointer is `$A62D` at
frames 8138–8248, `$A62E` at frame 8263, and `$A633` at frame 8271 after the
`$ED $53` write. After the recorded A edge at frame 8293 it is `$A638`. The
Godot VM starts its `$A626` stream at route frame 7993 and dispatches `$ED $53`
at tick 8139, while the ROM is still at `$A62D` on that frame. The ROM stream
bytes are `E8 01 F9 02 FB 01 15 DE E9 ED 53`; the live pointer evidence places
the `$DE` wait in progress at 8139 and the queue command at 8271. The exact
task/caller relationship between the scene-$56 branch and this resumed ID-$02
pointer is still unresolved; do not replace it with a fixed delay or call it a
single missing audio lead-in.

## Scene-$56 production route update — 9 November 2026

The preceding statement that production skips scene `$56` is superseded. The
meeting-menu selection now dispatches the ROM-selected scene `$56`; the
production VM executes its hash-checked 17-event stream, including the
`$ED $31`, `$ED $01`, `$EA`, and `$FF` path, then follows the modeled natural
wait/cleanup return into the suspended match setup. The route reaches the first
command menu without confirming an action or entering Continue. The
source-return executor is connected to the route, but models only the observed
frame-level wait boundary; `$4D/$4E` pointer reads on every physical source
frame and CPU/PPU phase are not reproduced.

The refreshed same-input route event audit now matches all 10 expected queue
events to the ROM/FCEUX source-frame table. Scene `$56` emits `$ED $31` at
frame 8027 and `$ED $01` at 8108; the resumed ID-$02 stream emits `$ED $53` at
8271. The later `$3C`, `$66`, `$2B`, and `$2C` requests also match in source
order. This closes the earlier route-tick/frame-label discrepancy; it proves
frame-level event alignment, not instruction-cycle onset, subframe timing, or
PCM/waveform equality. No captured WAV or APU capture is played by runtime.

The audit runner previously treated comparator status `MATCH` as a failure
because it expected the literal `PASS`. It now accepts `MATCH`. The refreshed
report `/tmp/ct2_first_match_audio_event_parity_20261028.json` records 10/10
matches and an empty `acceptance_failures` array.

## Fresh-period `$DAAA->$CBF1` stop request — 9 November 2026

The frame-8460 `$01` queue request is now attributed to the source-owned fresh
slot-$05 setup. A two-pass muted FCEUX capture from the verified in-session
frame-8399 checkpoint reaches `$DAAA`, calls `$CBF1` from `$DAAC`, returns at
`$DAAF`, and records the `$CBFE STA $0700,X` write at post-store PC `$CC01`.
The queue address is `$0700`, the value is `$01`, and the resulting five-byte
queue is `01 00 00 00 00`. Both passes have identical call and RAM-write hashes;
the callback is on FCEUX frame 8460 / cycle 251937939. The ROM-stepper table's
corresponding event uses its own cycle value 251937843, so the agreement is
frame/path-level, not cycle-level. See
[`fresh_period_daaa_trace_20261028_135904_utc`](../../diagnostics/fresh_period_daaa_trace_20261028_135904_utc/metadata.txt)
and the updated source attribution in
[`first_match_audio_source.md`](first_match_audio_source.md).

The existing Godot `RomFreshDaaaContinuation.execute_synchronous_prefix()`
executes this checked helper path and returns the matching source writes and
RAM. The audio-side `RomSoundQueueWriteEvent.populate_from_fresh_daaa_queue_insert()`
now converts that result into a typed `$01` command only when the ROM hash,
source manifest/helper hashes, `$DAAC->$CBF1` call, `$CBFE->$CC01` store, first
queue slot, and final queue RAM all agree. Its presenter consumer validates
the typed event before stopping playback. Focused Godot verifiers pass for the
event derivation, retained FCEUX boundary, and typed presenter behavior.

This typed bridge is not yet connected to the production route's initial
`begin_from_context()` result. That result currently drops the synchronous
continuation object before the audio event collector sees it, so the audible
request is still absent from the live route. Wiring this event into the route
requires retaining that returned source result and forwarding it once at the
existing fresh-match transition. Do not synthesize it from a frame constant.

The full source-route verifier passes at its frame-8953 comparison boundary. A
PCK-mounted ordinary-input replay reaches the visible menu at frame 8945 with
no ROM/emulator mounted and passes keyboard/D-pad navigation. The PCK content
verifier also passes while confirming that the original ROM payload,
emulator/state files, and reference captures are absent. Audio waveform parity
remains unresolved: the runtime cue assets are ROM/driver-derived, but exact
full-route PCM, APU/mixer output, and source-cycle onset are not verified.

## Scene-$56 caller wait audit — 9 November 2026

The natural-return loop at `$82A9` is the byte sequence
`A9 01 20 A8 9F A5 4D 05 4E D0 F5 60`: yield with `$9FA8(A=1)`, OR the live
script pointer bytes `$004D/$004E`, repeat while nonzero, then return. The
production route now models those yields and polls the VM's source-owned
pointer state instead of recording a fixed one-iteration wait. A focused
verifier checks the exact ROM-derived bytes/hash, repeated nonzero-pointer
polls, and return on zero.

This caller loop runs after the scene `$56` stream reaches `$FF`; it cannot
account for the earlier `$ED $31/$01/$53` onset differences. The available
same-input RAM trace brackets scene `$56`'s return with `$004D/$004E=0` at
frame 8123 and the resumed ID-$02 pointer `$A626` at frame 8124. Exact
same-frame CPU/NMI ordering remains unmeasured, so only the source loop rule
and frame-level route boundary are established. Do not use this wait as an
audio timing offset.

## Production Godot route PCM closeout — 10 November 2026

This section supersedes earlier statements in this report that the live
`$53/$3C` route mix, embedded effects, or full production Godot PCM remained
unverified. The production presenter now consumes one uninterrupted,
ROM-generated `$55`-to-menu route WAV. Later `$55/$53/$3C` queue events and
`$66/$2B/$2C` effects remain visible in the queue audit without restarting or
double-playing audio already embedded in that mixed stream. Stop commands keep
the source-rendered tail.

The runtime asset is
[`first_command_menu_route_wavehi_rom_generated.wav`](../../../assets/gameplay/audio/first_command_menu_route_wavehi_rom_generated.wav),
SHA-256 `ce1a84e97adbb0ae0fafeea282a50b4ddb554915bee3f8f2de7e7a38eaf7e5d0`.
Its source/timing metadata is
[`first_command_menu_route_wavehi_source_timing_rom_generated.json`](../../../assets/gameplay/audio/first_command_menu_route_wavehi_source_timing_rom_generated.json),
which names the verified ROM, input timeline, WaveHi source candidate, queue
events, source cycles, and asset sample windows. The route WAV is produced from
ROM-only CPU/APU/DMC execution; captured WAV data is not used by runtime or by
the asset builder.

Godot 4.7.2's production presenter was captured through its Dummy AudioServer
at 44.1 kHz while the same recorded route advanced. The fixed same-input
comparison uses FCEUX samples `[3533265,6569610)` and Godot samples
`[66,3036411)`, exactly 3,036,345 samples from the `$55` queue at frame 4816
through the stable first-menu comparison frame 8953. All samples match
exactly (RMSE 0, Pearson r=1.0). The 66-sample prefix is the measured
AudioServer capture-start latency; no time shift, resampling, or gain fit was
applied. The validation-only capture and comparison are under
`reference/diagnostics/audio/godot_route_context_audio_server_20261109/`.
Separate `$53` and `$3C` route-context checks also match their fixed windows
(501,096 and 254,074 samples, respectively) after the same measured prefix.

The ROM-only renderer's common 6,634,919-sample comparison and all 42,228
source APU writes remain separately documented above. The FCEUX recording has
734 active samples after source frame 9042, outside this goal's frame-8953
endpoint. These results establish captured Godot AudioServer PCM parity for
the scoped route window, not physical speaker latency or hardware NES
sample-phase parity. Intermediate-frame PPU scanline/dot phase is also not
established by the endpoint comparison.
