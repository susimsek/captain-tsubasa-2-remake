# Fresh KICK OFF `$8920` wait: source-clock runtime gap — 29 Oct 2026

## Current production result — 2 Nov 2026

The recorded-input Godot projection reaches a pending `$893B` handoff at source
frame 7266 with reset-derived `$78=0` and preset-derived `$79=$40`. It has not
executed the NMI that the same-input FCEUX route observes before `$8114`: the
trace enters `$8114` with `$78=$04`, `$79=$40`, `$001B=$C0`, and `$003B=$55`,
then the source IRQ clears `$78` before the wait returns. Therefore the current
Godot `$893B` RAM is not yet the actual interrupt-serviced wait state. The
focused verifier confirms the `$79` lineage from bank `$06:$BF13` through
`$8943` without consuming FCEUX state. At the later, interrupt-free `$893B`
projection, 588 of 2,048 CPU RAM bytes are known; 21/25 addresses in the
selected NMI context subset have full values in that ledger. This subset is
not the executor's complete transitive RAM footprint. This is not a complete
interrupt-serviced wait state. The known set includes `$001B & $7F = $40`, the
worker restore's `$0024=$00` write at `$9F5F`, the ROM-derived `$003B=$55`
interrupt-history invariant, and the source-derived `$003A=$57` counter
history. The separate pre-frame-7266 candidate context also carries the
ROM-only replay's `$E1-$E3=$85,$EB,$45`; those RNG bytes are not merged into
this later `$893B` projection because the candidate NMI has not executed.
Frame-7266 FCEUX RAM snapshots corroborate `$24`, `$003B`, and `$003A` without
feeding those values into runtime. The earlier candidate `$A15B` context now
has all 25 selected bytes known: a route-bound ROM-only source-stepper recorded
14,508 writes to `$001B` in nine writer groups through the later frame-7266
`$C421` boundary. Its last write is bank-$02 `$A133`, value `$C0`, at frame
7265/cycle `216326882`; the checked `$A133` instructions set bit 7, and no later
`$001B` writer appears before the candidate `$A15B` event. Combined with the
ROM-derived low-seven-bit invariant, this proves `$001B=$C0` for that candidate
subset without using FCEUX state or executing the NMI. The later interrupt-free
`$893B` projection remains at mask `$7F`; candidate bytes are not copied into
that separate wait state. Neither context covers the executor's full
transitive RAM footprint, and the full NMI/IRQ effects remain unresolved.
Focused Godot route verification passed on 2 Nov 2026. This does not execute or
release the route's NMI/IRQ wait.

The route still does not produce the source NMI/IRQ work that releases the
wait, continue through `$893F-$895C`, and return to `$8117`. It does not yet
reach the visible field or command menu. The older dated analyses below record
earlier component boundaries; this status paragraph reflects the current
production route.

## Candidate NMI status-byte source trace — 1 Nov 2026

An instrumented ROM-only replay of the recorded route reached the mainline
candidate at `$A15B` on source frame 7266, cycle `216355343`, with P=`$30`.
At NMI acceptance, the 2A03 hardware frame contains status `$20`, return PC
`$A15B`, and the live processor status becomes `$24` (I set, B cleared). The
decimal flag remained clear from reset; the observed V/I changes occur through
the ROM's interrupt/RTI path. The same-input event-stream hash remains
`d99f6cd031bd555474c97d130136573b46d3d79927232d8d94e66d974b121005`; status
change observations have hash
`4985cda9f1938d4fb2a631b9648e9a2f8e6668075e8159be174ecd7344928c9c` (123,311
records). The instrumented replay used ROM SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097` and route
input SHA-256
`87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e`.

This is source-trace evidence, not a production runtime receipt. Godot's
candidate CPU status is currently P=`$00` with known-mask `$83` (only N/Z/C
are known); V/D/I and other status bits have not been produced by the live
route. Therefore the source P value and hardware interrupt frame must be
derived by connected caller/interrupt execution, not copied from this endpoint.

## ROM-only CHR shadow writer chain — 1 Nov 2026

The focused `trace_rom_source_start_poll_scheduler_window.py` replay was run
from reset with the recorded route inputs and local ROM bytes. It did not use
FCEUX RAM or PPU state. At source frame 7112, `$63/$64=$37/$AE` selects address
`$AE37` in PRG bank `$07`; the bytes at ROM file offset `$00EE47` are
`3C 3E 20 02`. The fixed-bank routine at `$8B3F-$8B46` reads the first two
bytes and stores `$3C/$3E` in `$0075/$0076`. At frame 7119, `$8CA7/$8CAB`
copies those values to `$008E/$008F`. Thus the candidate NMI bytes `$8E/$8F`
have a ROM-table and writer path, but this focused replay has not connected
that writer chain to the Godot production route.

At frame 7119, `$92/$93=$52/$A5` points to `$A552` in PRG bank `$09`. The
pointer setup at `$9248/$924E` reads `93 64` from ROM file offset `$012562`
and forms `$E7/$E6=$B3/$64`, a pointer to `$B364`. Its table bytes at offset
`$013374` are `70 71 66 67`. The fixed-bank sequence at `$94D8-$94FE` sets bit
7 on the first byte and writes `$F0 71 66 67` to `$009E-$00A1`. This establishes
their source bytes and writer logic for the ROM-only replay, not a production
NMI receipt or a reason to increase the Godot candidate read-set count: the
production candidate remains 13/25 known, and the NMI has not been dispatched.

The ROM SHA-256 is
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`. Keep
these ROM-derived values out of emulator captures and endpoint-state fixtures;
the remaining work is to derive and execute their event-time producers in the
production route.

## Remaining candidate NMI bytes: source-only writer audit — 1 Nov 2026

A second ROM-only stepper run advanced the same recorded route through source
frame 7266. It used the local ROM and
`reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv`
(ROM SHA-256 `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`,
route-input SHA-256
`87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e`). The
trace's frame-7266 candidate NMI is at `$A15B`, cycle `216355343` in this
stepper's convention. The following six read-set values and their last source
writes before that event were:

| RAM | Value | Last writer | Checked source bytes |
| --- | --- | --- | --- |
| `$001B` | `$C0` | frame 7265, bank `$02`, `$A133` | bank `$02:$A12F`, ROM offset `$00413F`: `A5 1B 09 80 85 1B` (`LDA $1B; ORA #$80; STA $1B`); the preceding source history supplies the low-seven-bit `$40` invariant |
| `$001C` | `$00` | frame 7265, bank `$02`, `$A111`, X=`$01` | bank `$02:$A111`, ROM offset `$004121`: `95 1B` (`STA $1B,X`); the recorded route has no buttons held at frame 7265 |
| `$001D` | `$00` | frame 7265, bank `$02`, `$A111`, X=`$02` | same `$A111` store; controller reader's second-port sample is zero for this input |
| `$0020` | `$88` | frame 7265, bank `$02`, `$A07F` | bank `$02:$A073`, ROM offset `$004083`: `46 20 46 20 A5 45 4A 26 20 A5 7B 4A 26 20`; final `ROL $20` leaves `$88` |
| `$0021` | `$1E` | frame 7258, bank `$00`, `$98D1` | bank `$00:$98CA`, ROM offset `$0018DA`: `A5 21 09 18 8D 01 20 85 21`; the preceding `$98B0` mask write leaves `$06`, then this OR sets `$1E` |
| `$0628` | `$00` | frame 7258, bank `$02`, `$A04A` | bank `$02:$A048`, ROM offset `$004058`: `A9 00 8D 28 06` (`LDA #$00; STA $0628`) |

This run recorded 869,129 instruction events (event-stream SHA-256
`d99f6cd031bd555474c97d130136573b46d3d79927232d8d94e66d974b121005`); it
completed ROM execution before reading any FCEUX data. It is source-route
evidence, not Godot runtime state. Together with the preceding CHR-shadow
audit, it maps ROM writer chains for all 12 bytes missing from the production
candidate context. The Godot candidate remains 13/25 known because none of
these source-only receipts has been wired into the production route. The next
implementation step is to produce the same values from live route state and
then execute the NMI using a source-owned context.

## ROM wrapper counter convergence — 1 Nov 2026

The checked fixed-bank NMI and IRQ source spans both contain the wrapper
operations `SEC; ROR $003B` on entry and `LSR $003B` before `RTI`. For a
completed service they compose to `f(x)=(x>>2)|$40`. The configured selector
clock is bound to ROM SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`, input
route SHA-256
`6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc`, and
source-model SHA-256
`b0f528dfd73f79cf7148a5a2f6a9f0683cde22a03c1705deb8e5215864d888db`.

Before its frame-8 NMI candidate at `$A15B`, that clock contains 14 completed
services: seven NMI and seven IRQ events. Applying the ROM transformation to
all 256 possible initial bytes proves that `$003B` has converged to `$55` by
the candidate, without importing a captured RAM value. The production route
adds this full-byte receipt to the candidate checkpoint and sparse ledger; the
same-input FCEUX value `$55` is comparison evidence only.

This is a counter invariant only. It does not execute any of the 14 handlers or
the candidate NMI. Its candidate checkpoint now combines the counter with the
separate ROM-only RNG history below; neither receipt supplies the other CPU,
stack, mapper, PPU, controller, or APU handler effects. The event-time `$A15B`
read-set is 13/25 known bytes; the later projected `$893B` ledger remains
573/2,048 RAM bytes and 10/25 read-set bytes. At the candidate, 12 read-set
entries remain unknown: `$001B`, `$001C-$001D`, `$0020-$0021`, `$008E-$008F`,
`$009E-$00A1`, and `$0628`. `verify_kickoff_recorded_input_path.gd` passes and
still stops at the unserviced `$893B` projection; the wait release, field,
first command menu, audio parity, and ROM-free package remain unverified.

## ROM-only RNG history before candidate NMI — 1 Nov 2026

The existing route-bound RNG replay uses the cold-reset `$E1-$E3=0` state,
ROM instruction bytes for `$A117`, and the source-stepper schedule pinned to
ROM SHA-256 `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`
and input-route SHA-256
`6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc`. Advancing
through frame 7265 applies 7,255 byte-level `$A117` recurrences and yields
`$E1-$E3=$85,$EB,$45`. The three source stores are `$A11B->$E1`,
`$A121->$E2`, and `$A127->$E3`. The replay has no `$C9C5` calls before this
candidate frame. No FCEUX RAM or state snapshot is an execution input.

At frame 7266, the selector is interrupted at `$A15B` before the next NMI
handler can advance this tuple. Godot now attaches these three values only to
that candidate NMI input context, raising its 25-byte read-set coverage from
10 to 13. It intentionally leaves the later `$893B` sparse RAM ledger
unchanged: the NMI and subsequent IRQ have not run in the production route.
This narrows the missing context but does not execute either handler or
release the wait.

## First special-NMI interrupted instruction at selector return — 1 Nov 2026

The same muted two-pass replay from the validated frame-4692 checkpoint
narrows the missing interrupt context. At source frame 7266, both passes enter
fixed-bank `$C421` at cycle `216355364` with SP `$21` and MMC3 R7 `$02`. The
identical `$C421` RAM snapshots have SHA-256
`aa95f576dfb1f741e55eb013acbbcb85f71c080550c3c90455cf098a6c59dde0`; stack
bytes `$0122-$0124` are `$20,$5B,$A1`. The checked NMI vector trampoline
`$C500` jumps to `$C76E`, whose mode gate jumps to `$C421` without pushing
additional stack bytes. Interpreting the hardware NMI frame as saved P, PCL,
PCH therefore gives interrupted PC `$A15B`. With R7 `$02`, the checked bank-02
bytes at `$A15B` are `JMP $A1EB`, inside the selector's pointer-copy loop.

The route verifier now pins the two-pass `$C421` RAM snapshot hash and its
selected event-time inputs, including `$001B=$C0`, `$0020/$0021=$88/$1E`,
`$0023-$0025=$07/$00/$02`, `$003B=$55`, `$0079=$40`, and `$0628=$00`. It also
checks that the later Godot `$893B` projection has `$0025=$06` from the source
`$C4B9` bank-select call. That later bank state must not be reused to seed the
earlier `$A15B` NMI context. This remains validation-only; runtime still lacks
the event-time source transition.

The same frame then reaches `$8114` at cycle `216367219` with `$78=$04`,
`$8920` two cycles later, and `$893B` at cycle `216372514` with `$78=$00` and
R7 `$06`. Pass 2 matches these event positions and values. Thus the special
NMI begins while the selector copy is still running; the IRQ/wait release
occurs later in that same source frame. The current Godot projection reaches
the caller's `$893B` boundary without executing this earlier NMI, so the
production integration must first resume the selector at its real interrupted
instruction with source-produced CPU, stack, RAM, mapper, and PPU context. The
captures remain comparison evidence only and are not runtime inputs.

## Caller stack context before the selector — 1 Nov 2026

The reused two-pass trace narrows the missing stack context. At source frame
7258, the hooks observe the special NMI wrapper `$C421->$C449` with SP `$DD`,
then the sound driver at `$8000/$8061` with SP `$DB`. Later in that same frame,
the bank-$00 `$82E2-$82EC` cleanup runs at SP `$26`; the `RTS` at `$82EC`
returns directly to `$80F1` at SP `$28`. This is the still-active `$80EE JSR
$82B5` caller frame, not evidence of a separate stack restore from the sound
driver. The caller reaches `$80FA` at SP `$28`; `JSR $A20F` enters the selector
at SP `$26`. At `$A87E`, its nested JSR reduces SP to `$24`, which is the depth
observed when the frame-7266 NMI interrupts `$A15B`.

The frame-7258 RAM snapshot is taken at cycle `216146874`, PC `$A14A`, after
the caller hooks earlier in that frame. Its task records are not the live SP
at those earlier hooks: `$0000=$01` names the active root task; the slot-$01
record `$0001-$0004` is `00 16 00 02`; the slot-$15 record `$0015-$0018` is
`E0 00 40 00`. In particular, `$E0` is at `$0015`, not `$0016`; `$0016=$00`
is slot `$15`'s saved-SP byte, while `$0002=$16` is slot `$01`'s saved-SP
byte. These saved task-record values cannot be substituted for the hardware
SP seen at `$82E2` or `$80F1`.

The title-side Start trace gives a second, separate observation. At source
frame 4693, the `$80E6` hook is at cycle `139732791`, SP `$28`, with MMC3 R6
`$00` and R7 `$02`; the same-frame `Start_press` RAM snapshot records
`$0000=$15` and slot `$15` bytes `$0015-$0018 = 01 E0 00 02`. The hook and
frame-end snapshot are not simultaneous, so they do not prove the active task
at the exact `$80E6` instruction or explain why the task record's saved SP is
`$E0`. At the later frame-7258 snapshot, the PC is `$A14A` and `$0000=$01`.
This indicates that the task context changes somewhere across the route, but
the retained trace does not identify the precise ROM scheduler event. These
values remain validation evidence, not runtime inputs.

The frame-end RAM snapshot retains `$0125-$0128` as `$80,$A8,$FC,$80`, the
return bytes for `$A87E JSR $A8B7` and the outer `$80FA JSR $A20F`. Together
with the hook's `$80F0` return word at `$82E2`, this confirms the nested ROM
call frames, but it does not derive their entry stack from reset/title-task
execution. Do not seed `$28` or the `$A15B` stack page from these observations.

## ROM-derived cutscene worker task seed — 1 Nov 2026

The dispatcher at bank-$00 `$8494-$84A4` stages slot `$05`, return `$84C5`,
Y=`$50`, and A=`$00`, then calls `$9F69`. The helper's exact bytes at
`$9F69-$9F7D` execute `DEY; DEY` before the indexed stores. Therefore the
worker record stores SP=`$4E` at `$0006`, and the return bytes are `$C5,$84` at
`$014F/$0150`; the ready byte `$0005` becomes `$FF`. The `$9F52` dispatch path
loads SP=`$4E`, then `RTS` reaches `$84C6` with SP=`$50`. This corrects the
older [`cutscene_boot_task_install_trace.md`](../intro/cutscene_boot_task_install_trace.md),
which omitted the two `DEY` instructions and placed the stack writes two bytes
too high.

`RomFreshKickoffCutsceneWorkerSeed` verifies these extracted spans and the
live title handoff. `KickoffRouteRuntime._start_cutscene(1)` now gates VM startup
on this ROM-derived task-seed receipt; it does not use emulator SP or stack
bytes. The focused seed verifier and configured-main title-handoff verifier
passed on Godot 4.7.2. This resolves only the slot-`$05` worker seed. It does
not derive the caller's slot-`$15` context, execute the legacy scheduler as a
CPU, or reproduce NMI/IRQ timing.

## Scheduler-family exclusion — 1 Nov 2026

A muted two-pass replay from the validated frame-4692 checkpoint instrumented
the fixed-bank task seed/dispatch/yield addresses `$C50F`, `$C512`, `$C515`,
`$CA22`, `$CA97`, `$CAE7`, and `$CB0F`. None executed during the captured
KICK OFF route window, frames 4693–7266; both replay passes were identical
(40,298 hook rows; normalized SHA-256
`0ab0d0b5ea0300206847d5610f4abb4e1d6908bdcc87ba8b77e96e3bc40e9c96`). The
CSV and run metadata are retained under
`reference/diagnostics/kickoff_task_context_20261101_113411_utc/`.
The active caller instead appears in the older `$9F04/$9F0C/$9FA8` task path,
with old-task create/resume entries `$9F69/$9F52` observed at the cutscene
handoff. This rules out treating the fixed-bank `$CA97/$CB0F` scheduler model
as the producer of the `$80E6` caller stack for this route.

The same cold-start warmup recorded 23 calls to the old-task creator `$9F69`
through frame 4692. At frame 7, the hook enters with X=`$01`, Y=`$28`,
A=`$00`, and caller return word `$A291`; the corresponding bank-$02 bytes at
`$A281-$A291` initialize slot `$01` with continuation `$801F`, Y=`$28`, and
bank-low `$00` before calling `$9F69`. The checked source span is
[`legacy_title_task_seed/manifest.json`](legacy_title_task_seed/manifest.json);
the trace-only startup record is in
`reference/diagnostics/kickoff_task_context_20261101_113411_utc/startup_old_task_create_hooks.csv`.
This proves the source task's initial seed, but not its later saved SP `$1C`
at the frame-4693 `$80E6` event. The intervening old-task saves/restores still
need to be executed from ROM code.

Next, source-execute the old `$9FA8` yield/resume and `$9F52/$9F69` task
creation path far enough to derive the slot-$01 context at `$80E6` and the
later `$80EE->$82B5` waiter. Carry only that ROM-produced stack and CPU state
through `$80FA` into the selector. The special NMI and its `RTI` remain a
separate interrupt context. The existing selector executor accepts logical
JSR frames, but the NMI executor requires a materialized stack frame; the
production route currently does not produce that source-owned context.

The hash-checked selector executor now exposes an optional source-only CPU/RAM
checkpoint when its copy loop reaches `$A15B`; callers request a mainline cycle
and it returns a checkpoint only when ROM instruction stepping lands on that
exact PC/cycle. The focused verifier subtracts preceding interrupt spans from
the frame-8 NMI candidate and obtains mainline cycle `193821`. The ROM-only
executor then produces `PC/A/X/Y/P=$A15B/$1F/$00/$00/$20` and
`$D0-$D3=$1F,$BF,$6F,$72`, matching the same-input FCEUX stack/RAM observation.
The test supplies an explicit physical-stack fixture and does not import the
trace snapshot. This narrows the CPU boundary, but it does not build the live
route's absolute SP/stack history or missing `$C421` RAM/PPU/mapper context;
the scheduled clock remains diagnostic evidence, not a production interrupt
source.

## Title-menu to KICK OFF source-frame handoff — 1 Nov 2026

The cold-start command presenter freezes its source counter at frame 4661 when
the accepted Start poll begins the title transition. The checked title event
resource places the final title packet at frame 4692 and the first visible
title pixel at source frame 4692. Reading the frozen presenter counter for the
later KICK OFF input therefore started the gameplay route 31 frames too early
(4662 rather than 4693). The production handoff now anchors to the decoded
first-pixel event and starts the route on the next source frame. While the
title menu remains open, its source-frame counter advances at the project's
nominal NES frame rate.

The focused main-scene verifier passes the production Enter/KICK OFF path and
reports `4692 -> 4693`, stage `cutscene_1`. The idle-menu counter is frame-level
and uses Godot elapsed time; the ROM's subframe controller-poll phase while
waiting on the title menu is not modeled. This verifies only the title-to-route
clock handoff, not the missing `$893B` interrupt chain or first command menu.

The separate Godot diagnostic `verify_kickoff_recorded_input_path.gd` also
passes and reaches `$893B` at frame 7266 with `$0078=0`, `$0079=$40`, 568/2,048
RAM bytes known, and `$001B.7`/`$003B` unresolved. It starts the route directly,
so it does not establish an end-to-end recorded-input replay from the title.
It does not verify the wait release, field, or command menu.

For repeated FCEUX work, use the dedicated muted local checkpoints: frame 4692
(slot 0) for the early KICK OFF path, and frame 8399 (slot 1) for field packet
and PPU queue work. Both are ROM-specific and have recorded provenance under
`reference/diagnostics/local_checkpoints/`; do not cold-boot for each replay or
pass checkpoint RAM/PPU values into Godot. A direct separate-process reload of
slot 1 matched frame 8399, cycle 250126423, RAM SHA-256, and mapped PRG bytes,
but its 16 KiB PPU read differed at 48 palette-space bytes in `$3F00-$3FFF`.
The saved checkpoint had originally passed full-signature in-session reloads;
the direct disk reload is not fully PPU-signature verified and must not support
a PPU-visible comparison until that difference is resolved or explicitly
accounted for.

## Finding

The current Godot components cannot yet produce the live `$8114->$8920` wait
release and `$895C RTS->$8117` return without importing trace state. The
source-derived route now reaches the call boundary with `$79=$40`, but the
required interrupt context and transitions are not produced by the live
route.

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
  produced ROM IRQ receipt. The live route now supplies the reset `$0078=0`
  baseline and the earlier `$0079=$40` preset write, but no production
  producer supplies the IRQ receipt or executes the wait continuation.
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
   `$003B.7`, the active PRG mapping, the JSR stack frame, and the actual
   interrupt-disable state. `$0078=0` reset provenance and `$0079=$40` preset
   provenance are now carried to the `$893B` boundary.
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
through the reset/title route. Establish PPU dot/register, `$1B`, `$3B`, and
MMC3 A12/IRQ state for this route. Then connect the existing PPU
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

### Earlier ROM caller that seeds `$79` — 1 Nov 2026

The existing muted, two-pass FCEUX trace
[`fresh_kickoff_1b6_wait_trace_20261029_run5/`](../../diagnostics/fresh_kickoff_1b6_wait_trace_20261029_run5/)
captures an earlier `$8920` call at source frame `4708`. On entry it has
`A/X/Y/P/SP=$01/$00/$01/$20/$4E`, `$78=$00`, and stack bytes beginning
`7A 85`. The JSR return word `$857A` identifies caller `$8578`; the ROM bytes
at `$8578` are `20 20 89` (`JSR $8920`, file offset `0x000588`). This is the
same input route's earlier startup path, before the fresh-match call at
`$8114`.

With `$78` already zero, this call falls through `$893B->$893F` without an
interrupt. It reads the indexed preset byte at bank `$06:$BF13` (`$40`, ROM
file offset `0x00DF23`) and writes `$79=$40` at `$8943` (post-write hook PC
`$8946`). Both checkpoint replays report the same entry, stack return, branch,
and write. This explains the later fresh-match wait's `$79` precondition from
ROM bytes plus an observed caller path; the trace is not a Godot state input.

The 1 Nov production-route update now connects a reset-derived `$78=0` and a
ROM-byte-derived `$79=$40` receipt to the pending `$893B` prefix. This does not
execute the full earlier 6502 caller or establish the remaining CPU/interrupt
state. Do not seed other fields from the trace or from the build-time candidate
schedule.

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
consumer's bounded source behavior, not a production IRQ producer, same-input
visible output, or cycle-exact timing. The live route now reaches the `$893B`
boundary with `$78=0` reset lineage and `$79=$40` preset lineage; the
source-owned PPU/MMC3/CPU interrupt bridge remains the blocker.

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
At the projected `$893B` wait boundary, the route still has no absolute SP or
physical stack-page bytes. A later production increment now derives only the
four active selector return bytes at `$A15B`; it does not fill this wait-boundary
gap. See the [selector stack report](legacy_title_task_seed/title_selector_physical_stack_context_20261101.md).
The prefix derives N/V/Z/C as clear; the separate I=clear bit entering the
earlier route implementation came from the ROM-only candidate contract, not
live execution of reset `$C6B8 CLI` through the title path.

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

## Reused frame-8399 FCEUX checkpoint — 1 Nov 2026

The muted FCEUX 2.7.0 NTSC/NewPPU replay loaded the existing
`ct2_first_command_packet_join_20261029_codex.fc0` checkpoint at source frame
8399, cycle 250126423, then replayed the captured input through frame 9042;
it did not cold-boot the ROM. The input read log contains 104 comparisons and
zero mismatches, including the recorded B press at frame 8893. The raw replay
is retained locally under the ignored `reference/diagnostics/` tree.

For frames 8950–9042, `$C951` was observed 93 times. Each sampled state had
`$0498=0` and `$0515.7=0`; no `$2007` writes occurred in that window. This
establishes that the secondary packet queue did not transfer during this
sampled interval. It does not establish that the whole game route was idle or
provide the missing `$893B` interrupt state.

The separate-process state load matched frame/cycle, CPU-RAM signature, and
mapped PRG bytes. Its PPU memory still differed in 48 palette-space bytes in
`$3F00-$3FFF`, so the replay is not used for visible-pixel or palette claims.
The checkpoint is useful for RAM/CPU-route investigation; its PPU state needs
resolution before visual comparisons.

## Address-specific external disassembly cross-check — 1 Nov 2026

The pinned public
[`bank_82.asm`](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/blob/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/bank_82.asm)
contains `$02:$A160` at file offset `0x004170` and labels the `$A1CB` helper.
The repository's raw annotated bytes for this span match the local
ROM-derived `$A160-$A1E1` span; its bank names and comments still describe an
expanded mapper-5 translation build. Use it to navigate the routine only. The
supplied ROM's mapper-4/MMC3 bytes and manifest remain authoritative, and the
external listing does not provide the live IRQ event or CPU/stack/PPU entry
state needed by Godot. The project's source classification is in
[`online_reverse_engineering_resources.md`](../intro/online_reverse_engineering_resources.md).

The pinned public
[`bank_8C.asm` sound-engine listing](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/blob/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/bank_8C.asm)
also maps `$0C:$8000` and the continuation after `$8061`. Its annotated
instructions match the local, hash-checked `bank_8c_sound_driver.bin`:
`$8061` starts a second `$0700-$0705` sound-slot scan; empty slots branch to
`$80B7`, decrement X, and repeat. After the scan, `$80BA-$80C8` initializes
the `$0727` queue pointer and its `$F2/$F3` indices, and `$80CA` starts reading
queue state at `$0706`. The production NMI executor still stops at `$8061`; a
separate bounded continuation reaches `$80CA` only for an all-zero queue
fixture and does not read `$0706`. Neither component currently has production
route state needed to return through `$C472` or release the wait. The external
listing is a navigation aid only. Runtime must follow the supplied ROM bytes
and source-owned queue state; the FCEUX-observed empty slots are not runtime
inputs.

## ROM-derived `$003B` interrupt transform — 1 Nov 2026

The checked fixed-bank NMI wrapper at `$C421` and IRQ wrapper at `$C478` both
execute `SEC; ROR $003B` before dispatch and `LSR $003B` before `RTI`. For a
completed service, these exact instructions compose to
`f(x) = (x >> 2) | $40`. The ROM reset zero-fill initializes `$003B` to `$00`;
successive completed services produce `$40`, `$50`, `$54`, then `$55`, and
`$55` is a fixed point. The bytes are in the linked source manifest's
`fixed_raster_nmi_service_C421_C472.bin` and
`fixed_raster_irq_service_C478_C4AD.bin` spans.

This gives a ROM-derived explanation for the FCEUX-observed `$003B=$55` without
using that snapshot as runtime data. At the time of this analysis, the
production route did not yet derive the number of completed NMI/IRQ services
and kept `$003B` unknown at `$893B`. The current counter-only integration is
documented near the top of this report; it still does not execute the handlers.

The retained muted FCEUX two-pass replay provides an event-level cross-check.
Both passes loaded the dedicated frame-4692 checkpoint (slot 0) and replayed
the same recorded inputs; neither replay restarted from power-on. At frame
7266, both show the wrapper writes `$55->$AA` at `$C428` and `$C47F`, then
`$AA->$55` at `$C471` and `$C4AD`. The NMI enters `$C421` at cycle 29; its
`$C471` post-write hook is at cycle 2264. The IRQ `$C47F` post-write hook is
at cycle 16944, and its `$C4AD` post-write hook is at cycle 17167. Each pass
then observes `$893F` at cycle 17183, `$895C` at 17547, and `$8117` at 17549.
This confirms the wrapper transformation and interrupt order in this FCEUX
route. The raw trace is retained under the ignored
`reference/diagnostics/fresh_kickoff_1b6_wait_trace_20261029_run5/` directory;
it remains observation evidence, not state supplied to Godot. Godot still has
no source-owned PPU-to-CPU NMI boundary or MMC3 A12/IRQ producer, so it does
not yet create these writes or the wait return.

The focused Godot verifier runs the bounded, hash-checked `$C421` executor
with explicitly test-only full-state fixtures. The nonempty-slot fixture
checks the ROM-generated `$C426: $003B $55->$AA` write, `$A000` setup,
`$001B=$C0`, `$0078=$04`, and the first-pass stop at `$8061`. A separate
all-zero-slot fixture resumes the ROM's second scan through `$0700-$0705`,
executes the `$F0-$F3` pointer/index setup, and stops at `$80CA` before reading
`$0706`. It checks the NMI stack frame and rejects nonzero queue IDs on this
bounded path. Neither fixture supplies production route state: the queue/music
handler, APU work, sound-driver return, `$C472 RTI`, source IRQ producer, and
`$893B` live route continuation remain open. No emulator or candidate state is
consumed and the live route is not advanced.

## Production RAM coverage for the special-NMI entry — 1 Nov 2026

The recorded-input route verifier compares its sparse source-RAM ledger with
a targeted set of 25 fixed RAM bytes read or checked by the bounded special-NMI
path. Before the mapper-shadow receipt was connected, the `$893B` stop had
7/25 known; the historical unknown set was
`$001B`, `$001C-$001D`, `$0020-$0022`, `$0024`, `$003B`, `$008E-$008F`,
`$009E-$00A1`, `$00E1-$00E3`, and `$0628`. `$0023`, `$0025`, `$0044-$0045`,
`$0079-$007B` are known in this subset. This is a targeted fixed-input probe,
not the complete memory read set of the executor.

The OAM-DMA source page `$0200-$02FF` is known for all 256 bytes. The ledger's
last-write records attribute every byte to the ROM cleanup clear at `$9B8B`;
this supports the bounded NMI's DMA input but does not establish the remaining
NMI state. CPU registers/stack, full P, mapper/MMC3, PPU beam/register state,
controller latch values, remaining RAM dependencies, and source-owned NMI/IRQ
event production are still not connected to the production route.

For comparison only, the same-input frame-7266 `$C421` RAM capture reports the
missing bytes as `$001B=$C0`, `$001C-$001D=$00`, `$0020=$88`, `$0021=$1E`,
`$0022=$00`, `$0024=$00`, `$003B=$55`, `$008E=$3C`, `$008F=$3E`,
`$009E-$00A1=$F0,$71,$66,$67`, `$00E1-$00E3=$85,$EB,$45`, and `$0628=$00`.
The captured OAM-DMA page is `$F8` in all 256 bytes, matching the ROM cleanup
clear's value. The RAM snapshot is retained under the ignored local diagnostic
tree at
[`frame_7266_C421_ram_pass1.bin`](../../diagnostics/kickoff_select_cleanup_counters_20261031_034501_utc/frame_7266_C421_ram_pass1.bin);
the repeated FCEUX passes matched. These bytes are target observations only;
they are not inputs to Godot. Next, derive the values from the ROM route's
controller poll, PPU/mapper shadow writers, interrupt history, RNG event
stream, and packet-queue producers, then supply the resulting state to the
production NMI executor.

The focused recorded-input verifier passes and still stops at source frame
7266, at a projected `$893B` boundary before the actual NMI/IRQ chain. The
coverage report changes the next investigation target: the OAM page is not the
blocking input; resolve the listed fixed RAM values and machine context from
their ROM producers, then connect the NMI before treating `$893B` as the live
wait state.

## Two-pass inventory of the missing `$C421` RAM inputs — 1 Nov 2026

The muted FCEUX trace now records writes to the 18 selected bytes missing from
the live sparse ledger, plus the adjacent `$C421` executor inputs. It performs
one cold-start warmup to frame 4692, saves an in-session checkpoint, then runs
the same recorded route twice from that checkpoint. Both checkpoint reloads
match frame/cycle, full CPU RAM and PPU memory, MMC3 registers, and mapped PRG
bytes. The new input-writer event streams are identical after removing the
pass number: 100,585 events per route pass, normalized SHA-256
`2ae25358fa9c18244f0b3f792205e961ff603b6ff5f2c8d8c89e62f6e6e18de4`. The
frame-7266 `$C421` RAM images match at SHA-256
`aa95f576dfb1f741e55eb013acbbcb85f71c080550c3c90455cf098a6c59dde0`.

The trace stops its input-write hooks at the actual frame-7266 `$C421` entry,
cycle `216355364`. The exact values and latest observed writers before that
boundary are:

| RAM | Entry value | Latest observed writer before `$C421` |
| --- | --- | --- |
| `$001B` | `$C0` | frame 7265, `$A135` (bank `$02`), cycle `216326882` |
| `$001C` | `$00` | frame 7265, `$A113` (bank `$02`), cycle `216326836` |
| `$001D` | `$00` | frame 7265, `$A113` (bank `$02`), cycle `216326591` |
| `$0020` | `$88` | frame 7265, `$A081` (bank `$02`), cycle `216326195` |
| `$0021` | `$1E` | frame 7258, `$98D3` (bank `$00`), cycle `216138642` |
| `$0022` | `$00` | startup frame 6, `$C413` (bank `$1E`), cycle `151635`; no later route write was observed |
| `$0024` | `$00` | frame 7258, `$9F2E` (bank `$00`), cycle `216120014` |
| `$003B` | `$55` | frame 7265, `$C4AD` (bank `$1E`), cycle `216342721` |
| `$008E` | `$3C` | frame 7119, `$8CA9` (bank `$00`), cycle `211984273` |
| `$008F` | `$3E` | frame 7119, `$8CAD` (bank `$00`), cycle `211984279` |
| `$009E` | `$F0` | frame 7119, `$94E0` (bank `$00`), cycle `211988669` |
| `$009F` | `$71` | frame 7119, `$94E5` (bank `$00`), cycle `211988679` |
| `$00A0` | `$66` | frame 7119, `$94EB` (bank `$00`), cycle `211988689` |
| `$00A1` | `$67` | frame 7119, `$94F0` (bank `$00`), cycle `211988699` |
| `$00E1` | `$85` | frame 7265, `$A11D` (bank `$02`), cycle `216326850` |
| `$00E2` | `$EB` | frame 7265, `$A123` (bank `$02`), cycle `216326858` |
| `$00E3` | `$45` | frame 7265, `$A129` (bank `$02`), cycle `216326866` |
| `$0628` | `$00` | frame 7258, `$A04D` (bank `$02`), cycle `216118243` |

These are FCEUX observations that identify the next ROM paths to decode; they
are not allowed as runtime values. The trace files are in the ignored local
directory
[`kickoff_select_cleanup_counters_20261101_093929_utc/`](../../diagnostics/kickoff_select_cleanup_counters_20261101_093929_utc/).
The reproducible runner validates the two passes without restarting FCEUX via
`--validate-output`. Its event callback follows the official FCEUX contract
`(address, size, value)`; the `value` field is the byte written, not an
emulator-supplied old/new pair ([FCEUX Lua memory callbacks](https://fceux.com/web/help/LuaFunctionsList.html)).

At the time of this trace inventory, these 18 bytes remained unknown to Godot.
The next production work must execute their ROM writers and the events that
schedule them, especially the repeated `$A113` controller sample, the
`$A135/$C4AD` interrupt wrapper writes, the `$A11D-$A129` RNG update, and the
earlier fixed-bank `$8CA9/$94E0` setup. Neither the trace nor its snapshots are
to be copied into the Godot route.

## Earlier production ledger snapshot before counter convergence — 1 Nov 2026

This earlier source ledger at the later `$893B` projection reported 570/2,048
known bytes and 9/25 addresses from the special-NMI read set; it is superseded
by the counter-convergence result above. The known mapper
shadows include `$0022=$00` from reset/initializer stores and `$0024=$00` from
worker restore `$9F5F`. The two-pass FCEUX `$C421` snapshot corroborates `$24`
but does not feed it into runtime. The same verifier distinguishes the NMI
entry's `$0025=$02` from the later wait projection's `$0025=$06`. These ledger
values do not produce the selector NMI context or advance the route past
`$893B`.

The three RNG bytes `$00E1-$00E3` are a ROM recurrence, not arbitrary observed
values: `$A11D` adds `$83` to `$E1`, `$A123` adds `$0D` plus carry to `$E2`,
and `$A129` adds `$11` plus carry to `$E3`. Starting at the reset-zero state,
the startup prefix plus first route pass contains 7,255 recurrence triplets
through frame 7265; all 21,765 individual writes match the source recurrence,
ending at `$85,$EB,$45`. The repeated route pass agrees. This is validation
evidence only. The existing special-NMI
executor contains this recurrence, but the production route still lacks the
source-owned NMI context and event chain needed to produce these writes.

## Selector checkpoint known-bit propagation — 2 Nov 2026

The production selector checkpoint carries bit-level RAM provenance
separately from complete-byte values. The recorded-input verifier confirms
`$001B & $7F = $40` and proves reset-zero `$001C/$001D` remain zero through the
checked controller polling routine at bank `$02:$A0D7-$A115`. Its equality
branch stores an unchanged sample; the four-mismatch path skips both stores.
The selected 25-byte NMI context subset now has 25/25 complete values at the
candidate boundary. The candidate `$001B=$C0` byte combines the low-seven-bit
ROM invariant with a route-bound ROM-stepper history: 14,508 writes in nine
groups end with checked bank-$02 `$A133` value `$C0` at frame 7265/cycle
`216326882`, and no `$001B` writer occurs before the frame-7266 `$A15B`
candidate. The history's later `$C421` boundary is at cycle `216355361`; its
last write therefore precedes the candidate cycle `216355343`. This proves the
candidate RAM value without consuming FCEUX state or dispatching the NMI. All
eight sound branch inputs `$0700-$0706/$07E9` are also propagated into the
candidate. `$003A`, the sound-frame counter read by the handler, is source-
derived as `$57` immediately before the frame-7266 candidate NMI. Driver state
`$00F0`, `$00F2-$00F3`, and `$00FC-$00FD` is produced earlier by the driver's
first pass before its later reads, so those are internal outputs rather than
required entry bytes. This selected subset still does not cover every direct
read in the bounded NMI plus sound-driver executor. The later interrupt-free
`$893B` projection has 21/25 complete subset bytes and knows only `$001B` bits
0–6; the candidate byte is not copied there. The same verifier still stops at
frame 7266 before the interrupt-serviced FCEUX wait state: the selector NMI
and raster IRQ handlers, `$78` release, and `$8117` return are not connected
to the production route. This narrows event-time RAM uncertainty but does not
establish NMI/IRQ timing, visible field/menu parity, audio parity, or packaged
runtime independence.

## ROM-derived `$003A` pre-candidate counter — 2 Nov 2026

The route-bound ROM-only stepper schedule records all writes to `$003A` before
source frame 7266 and rejects any history other than two zero writes followed
by the bank-$02 `$A135` increments. It finds reset `$C670` at frame 4, the boot
loop's first wrapped write at `$A238` on frame 6, then 7,255 increments on the
same source frames as the 7,255 `$A117` calls through frame 7265. No other
`$003A` writer occurs before the candidate; `0 + 7,255 mod 256` yields `$57`.

Source bytes are retained and hash-checked in the
[`$A234-$A23D` boot-loop span](fresh_kickoff_0078_wait_20261029/manifest.json)
at bank-$02 file offset `0x004244`: `A9 00 A0 5A 99 E0 FF C8 D0 FA`. The
`LDA #$00; LDY #$5A; STA $FFE0,Y` sequence makes its first effective 16-bit
address `$003A`. The existing bank-$02 `$A000-$A13E` span verifies the linear
`$A116-$A137` path ending in `INC $003A; RTS`; the reset zero-fill loop is
verified at fixed-bank `$C64E-$C679`. The runtime receipt checks these bytes,
the route/stepper-bound writer history, and the ROM-only reset receipt before
merging `$003A=$57` into the candidate RAM ledger. It does not execute or claim
the candidate NMI. At the time this counter result was recorded, the eight
queue branch bytes `$0700-$0706/$07E9`, the full transitive context, and handler
dispatch remained unresolved; the next section supersedes the queue-byte
status.

## ROM-only sound-driver input boundary — 2 Nov 2026

The route-bound source-schedule builder now records the eight bank-$0C branch
inputs at the ROM-stepper opcode fetch for selector NMI entry `$C421`, frame
7266, cycle `216355361`. The source event is
`rom-source-nmi-7266-216355361`; its 2 KiB RAM hash is
`aa95f576dfb1f741e55eb013acbbcb85f71c080550c3c90455cf098a6c59dde0`. The
ROM-only execution uses ROM hash
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`, the
recorded route-input hash
`6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc`, and the
hash-pinned stepper and schedule builder. All eight event-time bytes are zero:
`$0700-$0706=$00` and `$07E9=$00`.

The builder summarizes 58,199 source writes to these addresses before the
`$C421` opcode fetch into 89 `(address, bank, PC, value)` groups rather than
shipping the repeated raw write list. Per-address counts are `$0700:46`,
`$0701-$0705:1` each, `$0706:58,147`, and `$07E9:1`. The replay class validates
the boundary identity, full RAM hash, all eight values, grouped writer counts,
and route/builder/stepper fingerprints. The production selector checkpoint
merges only these eight known bytes; it does not execute or claim the candidate
NMI. The focused recorded-input verifier passes and reports 8/8 sound-driver
inputs known. The matching muted FCEUX RAM images are corroboration only; no
FCEUX snapshot is used to build the schedule or runtime values.

This closes the eight additional sound-driver branch inputs for the candidate
boundary, not the executor's complete transitive RAM/CPU/PPU context. The NMI
and raster IRQ handlers, `$78` release, `$8117` return, field/menu output, and
route audio parity remain unresolved.

## ROM-derived bank-$0C saved-bank input — 2 Nov 2026

The same ROM-only source-stepper now records `$07FC` writes through the
frame-7266 `$C421` boundary. It observes four writes: reset fill at fixed
`$C670` sets zero, then bank-$0C `$804D` stores `$0F` three times. The final
store is at source frame 4817/cycle `143424443`; the boundary value remains
`$0F` at frame 7266/cycle `216355361`. This history comes from the pinned ROM
and route input, not FCEUX RAM.

`RomFreshMatchSpecialNmiExecutor.configure_from_project_sources()` validates
the bank-$0C driver bytes and confirms `$8025`, `$8039`, and `$804D` each contain
`STY $07FC` (`8C FC 07`). It combines the route-stepper's branch values and
writer counts with those source bytes, then emits a known-byte receipt for
`$07FC=$0F`. The production candidate `$A15B` checkpoint merges this byte; the
recorded-route verifier asserts the value and source writer. It remains
candidate context only: the NMI is not executed, the full 2 KiB context and
physical interrupt stack are not available, and the later interrupt-free
`$893B` projection is not seeded from this candidate state.

## Special-NMI zero-mask entry RAM read set — 2 Nov 2026

The production candidate checkpoint now carries a ROM-source read contract for
the bounded special NMI and zero-mask bank-$0C sound-driver route. The contract
covers 35 distinct entry RAM bytes:

`$001B-$001D`, `$0020-$0025`, `$003A-$003B`, `$0044-$0045`, `$0079-$007B`,
`$008E-$008F`, `$009E-$00A1`, `$00E1-$00E3`, `$0628`, `$0700-$0706`, `$07E9`,
and `$07FC`.

At the frame-7266 candidate `$A15B`, the production checkpoint knows all 35.
Their route values select the special-NMI branch, positive `$0079` preset,
empty PPU packet queue, zero controller bytes, six empty queue slots, zero
sound mask/enable latch, and saved sound bank `$0F`. `$0629` is not part of
this branch's entry read set because `$0628=0` returns from the packet consumer
before that byte is inspected. `$0040/$0041` and `$00F0-$00F3` are written
before their later reads on this path; `$003C-$003E` are saved by the wrapper
before restoration, so they are not candidate entry values.

The receipt is built by
`RomFreshMatchSpecialNmiExecutor.build_zero_mask_entry_ram_read_contract()`
and attached to the production `$A15B` candidate. The recorded-input verifier
checks 35/35 values and also asserts that the full RAM image, CPU/stack/mapper/
PPU/APU context, physical NES timing, and NMI dispatch remain incomplete. This
closes the path's sparse entry-RAM input set only; it does not authorize running
the NMI from an incomplete machine state or remove the `$893B` wait/IRQ gap.

## Frame-8 NMI wait-latch handoff — 2 Nov 2026

The route now merges the executed frame-8 NMI's RAM-write receipt into the
provenance-carrying source RAM image before running the `$8112->$8920` preset
prefix. `RomFreshMatchPresetLoaderPrefix` consumes `$78=$04` only when the
latest source-ledger write is the candidate NMI event at ROM `$A0A6`; it records
that provenance in `prior_nmi_wait_latch` and carries the byte into its
`$893B` caller RAM. The recorded-input verifier checks the producer PC, event
identity, and resulting value.

This closes the missing handoff for the final candidate NMI's `$78` write. It
does not replay the preceding fourteen NMI/IRQ events, establish their full
physical machine contexts, model the raster IRQ that clears `$78`, or continue
through `$8117`. The route still stops at `$893B`; no wait release or menu parity
is claimed.
