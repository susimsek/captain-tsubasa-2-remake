# Fresh KICK OFF `$8920` wait: source-clock runtime gap — 29 Oct 2026

## Finding

The current Godot components cannot produce the live `$8114->$8920` wait
release and `$895C RTS->$8117` return without importing trace state. No
component was added: the required runtime state and interrupt transitions are
not yet produced by the existing source-derived route.

The muted live replay in
[`fresh_kickoff_1b6_persistence_addendum_20261029.md`](fresh_kickoff_1b6_persistence_addendum_20261029.md)
observes this sequence at FCEUX's NTSC software-model timing:

1. `$8114` enters `$8920` with `$P=$22` (`I=0`), `$1B=$C0`, `$78=$04`,
   `$79=$40`, and `$3B=$55`.
2. NMI dispatch follows `$C500->$C76E->$C421`, maps bank `$02`, and calls
   `$A000`. The nonzero `$79` path writes `$04` to `$78`; it does not release
   the wait.
3. The raster IRQ dispatch follows `$C506->$C821->$C478`, maps bank `$02`,
   and calls `$A160`. Its terminal event writes `$00` to `$78` at `$A1C3`.
4. The mainline leaves the `$893B` loop, executes `$893F-$8959`, and `$895C`
   returns to `$8117` with the outer stack depth restored.

Those values and event positions are observation evidence only. They are not
valid production inputs.

## Existing component boundaries

- [`rom_fresh_match_preset_loader_prefix.gd`](../../../scripts/gameplay/rom_fresh_match_preset_loader_prefix.gd)
  now accepts the route's logical JSR-frame normalizer result and executes the
  source prefix through `$893B`, then stops with an empty return receipt. Its
  `execute_after_wait_release()` consumer can execute the checked
  `$893F-$895C` bytes, copy the 19-byte bank-$06 preset record, restore bank
  `$02`, and consume the `$8114` logical return frame after a separately
  produced ROM IRQ receipt. No production producer supplies that receipt, so
  the live route still does not read or seed `$0078`, execute the wait, or
  return to `$8117`.
- [`rom_fresh_kickoff_caller_continuation.gd`](../../../scripts/gameplay/rom_fresh_kickoff_caller_continuation.gd)
  is a bounded projection, not a 6502/task runner. Its helper returns are
  external inputs; it does not produce the complete CPU/RAM/PPU/mapper state
  required by `$8920` or execute the return path.
- [`rom_ntsc_ppu_vblank_nmi_clock.gd`](../../../scripts/gameplay/rom_ntsc_ppu_vblank_nmi_clock.gd)
  advances RP2C02 status and the delayed NMI output from caller-supplied PPU
  state and register accesses. It explicitly does not execute the CPU, sample
  the CPU interrupt boundary, or drive the game scheduler. It has no MMC3
  raster IRQ counter/A12 event model.
- [`rom_gameplay_task_scheduler.gd`](../../../scripts/gameplay/rom_gameplay_task_scheduler.gd)
  accepts an externally supplied NMI delivery. In `$001B.6` special mode it
  records `$C76E->$C421` as an event and sets `$001B.7` at `$A135`; it does not
  execute `$C421->$A000` or source instruction `$A0A6 STA $78` (FCEUX reports
  post-write PC `$A0A8`). Its normal-NMI queue
  consumer is a different path.

The gameplay runtime scripts currently contain no source-clocked MMC3 IRQ
producer or bridge that executes the `$C478->$A160` service from a PPU fetch
edge. The already checked ROM bytes for the NMI/IRQ wrappers, bank-2 service,
and wait continuation are in
[`fresh_kickoff_0078_wait_20261029/manifest.json`](fresh_kickoff_0078_wait_20261029/manifest.json);
no new source bytes or manifest are needed for this finding.

## Exact missing production chain

Before the wait can produce a legitimate return receipt, the live route must
produce, rather than seed:

1. The CPU/RAM/mapper/stack state at the `$8114` call, including `$001B.6`,
   `$003B.7`, `$0078`, `$0079`, the active PRG mapping, the JSR stack frame,
   and the actual interrupt-disable state.
2. The source-owned PPU register and dot state that makes the NMI edge
   available to the CPU. The existing PPU clock can describe that edge only
   after its initial state and intervening writes are provided.
3. The MMC3 IRQ latch, counter, reload/enable state, and source-produced A12
   fetch edges that lead to the terminal `$A160` event. A PPU vblank/NMI tick
   does not establish this raster IRQ.
4. A CPU-side source executor that dispatches the NMI and IRQ handlers,
   preserves/restores registers and stack according to their ROM wrappers,
   applies their mapped-bank and RAM/MMIO effects, and emits a provenance
   receipt. Feed that receipt into the bounded mainline consumer to resume
   `$893B`, execute `$893F-$895C`, and return to `$8117`.

At the time of this report's first logical-frame implementation, the live
route carried known P mask `$C7`, including only `I=clear` from a hash-bound
ROM-only candidate contract. The older physical-stack verifier fixture
reported `$P=$A4` at `$893B`, while FCEUX observed `$P=$22` (`I=0`) at the
caller and a maskable raster IRQ servicing the wait. Do not copy the observed P
into runtime input; derive upstream status from the ROM path.

## Next bounded implementation step

Replace the one-bit status contract with source-owned CPU status propagation
through the reset/title route. Also establish PPU dot/register, `$79`, `$1B`,
`$3B`, and MMC3 A12/IRQ state for this route. Then connect the existing PPU
clock to a production CPU interrupt boundary, produce the NMI and raster IRQ
through the checked wrappers, and execute the wait continuation and
`$893F-$895C` from that state. The current selector clock does not contain the
separate target `$893B` raster event. Until these producers exist, stop at
`$893B`; do not fabricate a `$78=0` event or a `$895C->$8117` receipt from the
observed trace.

## Godot logical-prefix update — 31 Oct 2026

The focused preset-prefix verifier passes its physical-stack fixture and the
production-shaped logical-frame path. The latter reports 232 no-interrupt
cycles from `$8112`, reaches `$893B` with A/X/Y `$07/$06/$00`, derives
`$EC/$ED=$00/$BF`, `$EA=$02`, and selects bank `$06`. It retains one pending
outer `$8114->$8920` logical frame and does not model absolute SP or a live CPU
status path. At that time, the route also supplied candidate I=clear. The
recorded-input route integration passed to this boundary. This does not verify
NMI/IRQ service, wait release, return, visible field/menu, or physical NES
timing.

The original static audit did not run an emulator or verifier. The cited live
trace establishes FCEUX behavior, not physical NES timing; the later focused
verifiers establish only the Godot source boundary described above.

## ROM-only source-clock candidate — 31 Oct 2026

The diagnostic `tools/diagnostics/step_rom_source_cpu_ppu_dmc_mmc3_assert_candidate.py`
ran the local ROM-source CPU/PPU candidate from reset using the existing recorded
input timeline. It did not load FCEUX RAM/PPU state or invoke the FCEUX
comparator. In candidate source frame 7266, it reached and repeatedly polled
`$893B` with `$78=$04`, dispatched NMI `$A0A6` (which retained `$78=$04`), then
IRQ `$A1C3` (which wrote `$78=$00`), resumed at `$893B`, and returned through
`$893F-$895C->$8117` in that same candidate frame. At `$A1C3`, the candidate
post-instruction cycle is 216,372,408; the FCEUX post-store hook reports
216,372,411, a 3-cycle difference under their respective hook conventions.
The candidate PPU fetch pipeline is simplified and this is not the production
route or physical-hardware timing proof. Treat it as a ROM-only model result,
not as a verified gameplay event producer.

## ROM-only wait-byte producer audit — 31 Oct 2026

The candidate builder now retains the recent ROM CPU writes to the four
`$893B` wait bytes and rejects a changed final writer for this input route.
With ROM SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097` and
input-route SHA-256
`6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc`, the
ROM-only candidate's last writes before the target IRQ are:

| RAM | Last source write | Frame / cycle | Value |
| --- | --- | --- | --- |
| `$001B` | bank `$02`, `$A133` | 7266 / 216,356,664 | `$C0` |
| `$0078` | bank `$02`, `$A0A6` | 7266 / 216,356,072 | `$04` |
| `$0079` | fixed bank `$00`, `$8943` | 4708 / 140,204,756 | `$40` |
| `$003B` | fixed bank `$1E`, `$C46F` | 7266 / 216,357,599 | `$55` |

The target MMC3 edge is frame 7266, cycle 216,372,246; the ROM IRQ path then
executes `$A1C3` to write `$0078: $04->$00` at cycle 216,372,408. These producer
records are build-time diagnostic evidence from the ROM-only candidate, not
Godot runtime inputs or proof of physical NES timing. They narrow the missing
source route: `$79` must be carried from an earlier `$8943` call, while the
special NMI path produces the other wait bytes immediately before the IRQ.

## Receipt-gated tail consumer — 31 Oct 2026

`execute_after_wait_release()` consumes a source-owned IRQ receipt only when it
is bound to the current `$893B` route event, returns through the checked
`$C506->$C821->$C478->$C491->$A160->$A1C3->$C4AD` path, restores the caller's
register/P contract, and records exactly `$A1C3: $78 04->00`. It then executes
the ROM-hash-checked `$893F-$895C` mainline, reads the verified 19-byte
`$BF00-$BF12` record from bank `$06`, preserves `$7B`, restores mapper bank
`$02` through `$8959->$C4B9`, and consumes both logical RTS frames to return at
`$8117`.

The focused verifier passes this consumer using an explicitly test-only IRQ
receipt fixture and rejects a trace-backed receipt. It establishes the
consumer's bounded source behavior, not a production IRQ producer, runtime
reachability, same-input visible output, or cycle-exact timing. The live route
still stops before reading `$78` at `$893B`; the source-owned PPU/MMC3/CPU
interrupt bridge remains the blocker.

## Bounded special-NMI executor draft — 31 Oct 2026

`RomFreshMatchSpecialNmiExecutor` hash-checks the extracted fixed-bank NMI
dispatch/body and bank-$02 setup spans for ROM SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`. Its
supported branch requires a source-owned `$C421` CPU/stack/RAM/mapper/PPU and
controller context, empty `$0628`, and positive `$0079`; it models the source
path through `$A000` and `$A0A6`, then enters the bank-$0C `$8000` sound-driver
call. With the synthetic fixture, it runs the first six-slot scan and stops at
`$8061`. The source span `$A1CB-$A1E3` includes the verified `$A1E2` operand
and `$A1E3 RTS` helper tail.

The focused verifier now runs the supported NMI branch with a clearly labeled
synthetic full-state fixture. It executes the six-slot sound-ID scan at
`$C449->$8000` through `$8060`, then stops at `$8061` with the driver's JSR
pending. It also confirms an empty context is rejected without advancing the
route. This verifies only the bounded executor mechanics: no production source
context supplies the required CPU/stack/RAM/mapper/PPU/APU state, the driver's
later passes and return remain unimplemented, and there is no `$C472 RTI`
receipt, IRQ wait release, or live-route consumer. Do not use candidate/FCEUX
endpoint values to drive it. See
[`rom_fresh_match_special_nmi_executor.gd`](../../../scripts/gameplay/rom_fresh_match_special_nmi_executor.gd)
and [`verify_rom_fresh_match_special_nmi_executor.gd`](../../../tools/diagnostics/verify_rom_fresh_match_special_nmi_executor.gd).

The fixed-bank `$C449` call maps physical bank `$0C` at `$8000`; that driver
entry begins `A2 05 BC 00 07 C0 32 B0 0E` at file offset `0x18010`. Its first
pass scans six sound-ID slots `$0700-$0705` and stops before the second pass at
`$8061`. A new muted FCEUX trace observes the target NMI and `$C449` call state,
including all six queue bytes, `$07FC`, full CPU RAM/PPU-memory snapshots, CPU
registers, and MMC3 registers. This supplies a same-input reference, not a
source-owned Godot state. A runtime executor still needs to derive and carry
these values through ROM writes and model live audio/APU state before it can
execute the remaining driver passes and return to `$C44C`.
`GameplayRomCueAudioPresenter` consumes source queue IDs and plays ROM-derived
renders; it is not a CPU/mapper/APU tick consumer and cannot stand in for this
call's state effects or return. The later `$55` WAV cue and its ROM-derived
onset timing do not establish the `$C449` entry state.

## `$C449` sound-driver input producer map — 31 Oct 2026

This is a source-writer map, not a reconstructed call-entry snapshot. All
addresses below are for ROM SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.

| State | ROM-owned producer or consumer | Route condition and effect |
|---|---|---|
| `$0700-$0705`, `$07FC` at cold start | Fixed `$C64E-$C679`, file `0x03C65E`, in [`fresh_kickoff_entry_context/manifest.json`](fresh_kickoff_entry_context/manifest.json) | The reset loop zero-fills all 2 KiB of CPU RAM, so these bytes begin at zero. This is only the reset state, not their values at the later NMI. |
| Queue request | Bank `$00:$85EC-$8603`, file `0x0005FC-$000613`; the shared cutscene interpreter dispatches `$ED` here | It scans `$0700-$0704` for the first zero slot, reads the request byte at `($4D:$4E)+1`, and stores at `$0700,X` from `$85FC`. If all five scanned slots are occupied, `X=5` and the store goes to `$0705`. It needs the live script pointer and all six queue bytes; an `$ED` literal alone does not determine the selected slot. See [`opening_audio_command_provenance.md`](../audio/opening_audio_command_provenance.md). |
| Direct stop requests | Bank `$00:$82DC` in the shared `$82B5` cleanup; bank `$00:$8105-$8109` in the fresh caller | The cleanup after ID-1 natural-end/Select completion writes `$01` to `$0700` at `$82DC`; after the caller resumes at `$80F1`, `$8107` stores `$01` directly to `$0700` before `$8114->$8920` (`$8105` loads the immediate value). Each overwrites only slot 0; neither clears `$0701-$0705`. The source bytes and prerequisites are in [`fresh_kickoff_caller_continuation_20261028.md`](fresh_kickoff_caller_continuation_20261028.md) and [`fresh_kickoff_80fd_to_8920_next_transition_audit_20261031.md`](fresh_kickoff_80fd_to_8920_next_transition_audit_20261031.md). |
| Later BGM request | Bank `$00:$812C`, `STX $0700` | This writes `$55` only after the `$893B` wait exits and `$895C` returns to `$8117`; it cannot supply the queue for the earlier `$C449` NMI call inside that wait. The retained ROM-only event table and muted replay corroborate this later ordering, but are validation evidence only; see [`first_match_audio_source.md`](first_match_audio_source.md) and [`fresh_kickoff_1b6_persistence_addendum_20261029.md`](fresh_kickoff_1b6_persistence_addendum_20261029.md). |
| Saved bank `$07FC` | Bank `$0C:$8025`, `$8039`, `$804D`, file `0x018035`, `0x018049`, `0x01805D` | The first driver pass writes `$0D`, `$0E`, or `$0F` here for queue IDs `$32-$43`, `$44-$50`, or `$51-$5B`. IDs below `$32` and `$5C+` select MMC3 R7 and restore the current `$07FC` value without changing it. Thus `$07FC` is a persistent driver bank latch after reset, not a value assigned by the `$C449` wrapper. The prefix executor stops at `$8061` before the second pass can consume/clear queue slots. |

On the source-order path, the ID-1 `$82B5` cleanup precedes the fresh caller's
`$8107` stop store; the caller then enters `$8114->$8920->$893B`, where the
special NMI service reaches `$C449->$8000`. The source-only queue-event table
lists an earlier cutscene `$ED $55` request and the two `$01` stop stores before
the later `$812C` `$55`. The muted cold-start trace captures the first `$58`
queue request in `$0700` at frame 282 and the sound driver's first
`$07FC=$0F` store at frame 283: the write hook reports next PC `$8050`, after
the ROM `STA $07FC` at `$804D`. The route repeats the `$58->$0F` sequence at
frame 4481. The later `$01` stop IDs restore `$07FC=$0F` and clear their queue
slot. At frame 7266 the trace observes all six slots as zero and the saved bank
still `$0F` at `$C421/$C449`. Godot does not yet derive or carry this state from
those ROM producers.

The remaining producer gap is specific: Godot has no source-owned continuation
that carries the six queue bytes and `$07FC` through prior `$ED` calls and
sound-driver passes to this NMI entry. The new FCEUX capture records queue and
saved-bank writes from cold start through frame 7300 and the target call state;
it remains observation/validation evidence rather than a runtime input. A
bank-$0C routine at
`$851A-$8531` also clears `$0700-$0705`, but its reachability on this fresh
route is not established, so it is not counted as a pre-call producer. The later
root helper `$CBF1->$CBFE` can enqueue into the first empty slot of
`$0700-$0704`, but its documented caller is downstream and it never writes
`$0705`; see [`slot09_cbf1_sound_queue_audit_20261030.md`](slot09_cbf1_sound_queue_audit_20261030.md).
The live PPU/MMC3/CPU interrupt context and the driver's APU/task state needed
after `$8061` remain unproduced.

## Muted target NMI and sound-call observation — 31 Oct 2026

The updated FCEUX trace records the cold-start queue/bank writes through the
signature-checked frame-4692 checkpoint, then replays frames 4693–7300 twice
from that checkpoint with sound disabled. Caller hooks, queue writes, and full
2 KiB RAM/16 KiB PPU-memory snapshots at `$C421` and `$C449` match between
passes. The trace is observation/validation evidence; none of these snapshots
feed the Godot route.

At frame 7266, `$C421` is reached at cycle 216,355,364 with
`A/X/Y/P/SP=$1F/$00/$00/$E6/$21`. RAM has `$003B=$55`, `$003C=$EC`,
`$0078=$00`, `$0079=$40`, `$0628=$00`, `$0629=$20`, six zero queue slots
`$0700-$0705`, and `$07FC=$0F`; MMC3 is select `$07`, R6 `$00`, R7 `$02`. At
`$C449` (cycle 216,356,696), registers are `$0C/$00/$00/$24/$21`; the same
queue and saved-bank values remain, `$0078=$04`, and MMC3 is select `$06`, R6
`$0C`, R7 `$02`. The mapped `$8000` driver reaches `$8061` at cycle 216,356,879
with `A/X/Y/P/SP=$0C/$FF/$0F/$A4/$1F`, MMC3 select `$07`, R6 `$0C`, R7 `$0F`.
These observed values confirm the first-pass six-slot behavior. The cold-start
writer is identified below; the Godot route still does not produce these state
transitions.

The first `$07FC=$0F` write is from the `$58` music queue. The checkpoint at
frame 4692 has an empty six-byte queue and retains `$07FC=$0F`; at frame 7266,
the mainline later writes `$01` to `$0700` after the observed NMI, and the sound
driver clears that slot on frame 7268. The two-pass runner validates these
snapshots and their hashes in
[`validation.json`](../../diagnostics/kickoff_select_cleanup_counters_20261031_034501_utc/validation.json);
instruction-boundary values are in
[`caller_hooks.csv`](../../diagnostics/kickoff_select_cleanup_counters_20261031_034501_utc/caller_hooks.csv),
and queue/bank writes are in
[`sound_queue_writes.csv`](../../diagnostics/kickoff_select_cleanup_counters_20261031_034501_utc/sound_queue_writes.csv)
and [`sound_queue_writes_startup.csv`](../../diagnostics/kickoff_select_cleanup_counters_20261031_034501_utc/sound_queue_writes_startup.csv).

## Post-wait caller boundary — 31 Oct 2026

The new standalone caller executor runs `$8117 LDX #$01`, `$8119->$C4B9`, and
`$811C->$A006->$A4EB` from a successful preset-tail receipt. It verifies MMC3
register-7 selection/bank `$01`, 42 caller cycles, and a pending logical JSR at
`$A4EB`. Its focused verifier uses a test-only IRQ release fixture; it does not
connect the wait producer to the live route. `$811F->$C572` is byte-checked but
not executed because `$A4EB` has not returned. The ROM body `$A4EB-$A610` has
no route executor; its cooperative input wait, table/PPU helpers, and level-up
pass remain open. See
[`fresh_match_postwait_caller_20261031.md`](fresh_match_postwait_caller_20261031.md).

## External disassembly cross-check — 31 Oct 2026

The pinned [Captain Tsubasa 2 disassembly, `bank_8C.asm`](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/blob/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/bank_8C.asm)
labels physical offset `0x018010` as
`sub_0x018010_sound_engine_update` at CPU `$0C:$8000`. Its entry bytes match
the supplied ROM's `A2 05 BC 00 07 C0 32 B0 0E`. The listing clarifies that
the routine first scans six sound-ID slots `$0700-$0705`, changes the MMC3
PRG bank according to ID ranges, then processes queued commands and music
channel state. The separate [fixed-bank listing, `bank_FF.asm`](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/blob/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/bank_FF.asm)
maps `$C449` to `JSR $8000` after selecting bank `$0C`.

This is a byte-matched naming/control-flow lead from an English-translation
disassembly whose comments are mostly Russian; it is not a runtime dependency
or a substitute for the local ROM. It confirms the call and broad driver
responsibility, but does not provide the missing live queue, stack, mapper,
PPU/MMC3, or APU context. The production route remains blocked at `$893B`.

## Godot CPU-bridge inventory — 1 Nov 2026

A search of `scripts/gameplay/` found source-specific bounded executors and an
isolated PPU vblank/NMI clock, but no reusable 6502 CPU or MMC3 raster-IRQ
engine. The separate
[`step_rom_source_cpu_ppu_dmc_mmc3_assert_candidate.py`](../../../tools/diagnostics/step_rom_source_cpu_ppu_dmc_mmc3_assert_candidate.py)
uses diagnostic-only Py65 and reads the `.nes` file; its generated schedule is
not consumed by the Godot route. It can remain a ROM-only comparison oracle,
but cannot supply runtime state. The next implementation therefore needs a
source-owned CPU/interrupt state producer in the Godot route rather than a
hidden library or candidate-schedule adapter.

## Sparse executor-write image at `$893B` — 31 Oct 2026

`KickoffRouteRuntime` now folds the explicit RAM-write receipts from cleanup,
the KICK OFF caller, mapper helper, selector, normalizer, and preset prefix
into a 2 KiB provenance-carrying image at the `$893B` stop. Bytes without a
recorded source write remain unknown; the storage's zero initialization is not
reported as game state. The image rejects results without the pinned ROM hash
and results marked as trace/emulator-derived. See
[`rom_source_ram_image.gd`](../../../scripts/gameplay/rom_source_ram_image.gd)
and [`verify_rom_source_ram_image.gd`](../../../tools/diagnostics/verify_rom_source_ram_image.gd).

The focused model-contract verifier passes with a synthetic receipt fixture.
This image is not a CPU/RAM handoff from the title, does not add writes for the
scheduled NMI/IRQ handlers, and does not supply the missing `$C421` context.
Therefore the live route remains stopped at `$893B`; no menu-visible progress
or fidelity claim follows from this accounting change.

The same-input route integration now asserts the source-owned caller's final
`$0700=$01` store at `$893B`; `$0701-$0705` and `$07FC` remain explicitly
unknown. This matches the producer audit's boundary: the direct stop store
overwrites only queue slot zero, while earlier queue-driver consumption and
the saved-bank state are not yet carried by Godot. The `$8107` RAM receipt is
now consumed by `GameplayRomCueAudioPresenter` as the source `$01` stop command
after its matching `$0700=$01` write receipt and `$8107` instruction-path
entry are both present. The recorded-input replay confirms that consumer at
route frame 7266. Subframe timing is still unresolved, and this does not
replace the missing sound-driver execution or establish route audio parity.

A recorded-input Godot replay on 31 Oct 2026 stopped at frame 7266 with stage
`match_setup_gap`, pending caller `$893B`, and continuation `$8117`. Its sparse
source-write image knew 548 of 2,048 RAM bytes; `$001B`, `$0078`, `$0079`, and
`$003B` were all unknown at that boundary. The focused replay verifier now
recognizes this documented stop and exits successfully while reporting the
route as incomplete. This confirms the specific missing wait inputs; it does
not establish a menu render, interrupt execution, or audio parity.

The `$8112->$893B` prefix receipt now also reports its relative stack contract:
the `$9DEE` and `$C4B9` nested calls return, leaving one pending `$8114->$8920`
JSR frame with return word `$8116` and SP delta `-2` from the pre-call value.
The logical route still has no absolute SP or physical stack-page bytes. The
prefix derives N/V/Z/C as clear; the separate I=clear bit entering the earlier
route implementation came from the ROM-only candidate contract, not live
execution of reset `$C6B8 CLI` through the title path.

## Live status provenance correction — 31 Oct 2026

The production-shaped route no longer copies candidate I=clear into the
selector CPU contract. The live selector entry retains I as unknown, and the
known status mask through normalization and the `$893B` prefix is `$C3`
(N/V/Z/C). The selector clock retains its hash-bound I-bit result as diagnostic
candidate evidence; it is not a live status producer. Its candidate frame/event
schedule is still consumed to pace the selector RAM-write timeline, while NMI/
IRQ handler writes and return receipts remain unexecuted. Therefore the
`$893B` wait remains unresolved.

The focused `verify_rom_fresh_match_selector_clock.gd` and
`verify_kickoff_cutscene_select_wait_integration.gd` runs passed on 31 Oct
2026. The integration replay reaches the same `$893B` boundary with I unknown
in the live selector contract. These checks do not verify the wait return,
visible field, audio parity, or the first command menu.

## Targeted external-source check — 31 Oct 2026

A search for `$893B`/`$8920` and the NMI/IRQ route in Japanese and Chinese
results found no separate address-level execution analysis. The public
[Captain Tsubasa 2 disassembly](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation)
is a useful assembly cross-check, but its repository describes most comments
as Russian and the opened `$81` bank page did not surface these addresses by
their CPU labels. The Japanese
[game cheat-code wiki](https://wikiwiki.jp/nnnes1/%E3%82%AD%E3%83%A3%E3%83%97%E3%83%86%E3%83%B3%E7%BF%BC%EF%BC%92)
lists RAM cheat locations and gameplay values, not this wait's instruction,
interrupt, or timing path. These pages add no runtime evidence for the current
gap; the supplied ROM and local FCEUX trace remain the verification sources.
