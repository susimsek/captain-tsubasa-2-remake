# ROM Reverse Engineering and Godot Remake Plan

> This file is the implementation sequence, not a second status log. `GOALS.md`
> owns the current objective and progress; `AGENTS.md` and the project skills
> own durable workflow and evidence rules. Later phases do not expand the active
> endpoint by themselves.

## Current work package

**Execute the ROM's Select-to-fresh-match caller/handoff path, then continue the
live match setup toward the first in-match command menu.** The recorded frame-8593 A
press reaches `$DAF2`, runs `$DC07`, applies all 22 position updates, then
executes receiver selection, `$E6EC->$CDE2` holder setup, and
`$DB0E->$CBB0->$CB0F` scenario queue and task-yield logic. All 22 position pairs
match the same-input FCEUX RAM oracle. The ROM-only RNG replay is bound to one
input hash; 3,901 retained RAM snapshots and all 133 `$C9C5` operand triples
match, and receiver selection resolves to slot 6. Arbitrary input histories
still lack live RNG event generation. See [`DC07` integration](reference/rom_extract/gameplay/dc07_position_initializer_live_route_20261030.md),
[`$E6EC` holder execution](reference/rom_extract/gameplay/first_command_field/e6ec_holder_copy_live_route_20261030.md),
and [RNG operand trace](reference/rom_extract/gameplay/first_command_rng_operand_trace_20261030.md).

The frame-8593–8606 route measurements below were produced before the live
KICK OFF route executed the Select cleanup helpers. They remain evidence for
downstream source components; the current route now reaches the verified PPU/OAM
clear at frame 7258, executes the common caller stores/RTS, derives mapper
shadow `$0022` from ROM initialization, and runs `$C4B9` plus the match-zero
`$A20F` selector, caller normalizer, and `$8920` preset prefix through `$893B`
using logical JSR frames. Absolute SP and stack-page contents are not modeled.
The route does not yet connect to those later route measurements. The selector
executor emits a cycle-ordered RAM-write timeline, and the live route now
materializes it over relative source-frame offsets 0–8 using the validated
runtime clock asset at
`assets/gameplay/rom_logic/fresh_match_selector_runtime_clock.json`. The route
reaches `$893B` at frame 7266. The ROM-only candidate model accounts for
223,242 elapsed cycles (203,333 selector cycles plus 19,909 interrupt cycles);
FCEUX measured 223,239 cycles and the same return cycle, with a three-cycle
entry-hook offset. This remains a scheduled-write model: the selector executor
precomputes its result at entry, and the 15 NMI/IRQ handler effects and return
receipts are not executed by the route. It does not establish complete PPU
timing or physical NES timing. The clock source and integration checks are
`scripts/gameplay/rom_fresh_match_selector_clock.gd`,
`tools/gameplay/build_fresh_match_selector_runtime_clock.py`,
`tools/diagnostics/verify_rom_fresh_match_selector_clock.gd`, and
`tools/diagnostics/verify_kickoff_cutscene_select_wait_integration.gd`. See the
[selector timing and IRQ candidate report](reference/rom_extract/gameplay/fresh_kickoff_selector_timing_and_irq_candidate_20261031.md).

Slot `$09` consumes scenario `$36` from ROM pointer `$B7E4`; callback slot
`$15` executes `$3A` and builds all 32 map-$42 cells in eleven batches. The two
row-wrap queues and terminal queue match same-input FCEUX RAM snapshots at
frames 8602–8604 byte-for-byte. At frame 8605, the live `$05CD=$A0` callback
branch returns through `$819C->$CAF7`, finishes slot `$15`, and reaches the
scheduler NMI wait. At frame 8606, the route source-executes slot `$11`
through `$8047->$C515->$CB0F`, but same-input trace checks fail on animation
timing/state. The expanded RAM comparison shows Godot already has scenario
`$35` state by frame 8450, while frame-end FCEUX RAM remains at `$01AC`. The
same-frame snapshots already differ by frame 8443 (`$0516-$0519` is
`$00000000` in Godot and `$01AC0000` in FCEUX; task records also differ). FCEUX
enters the fresh-match handoff at `$A2AF` on frame 8458 and its frame-end RAM
first shows scenario `$35` at frame 8467. Godot first yields slot `$11` at
frame 8463; the FCEUX hook trace first observes the actor-worker yield at frame
8480. The outer caller uses one `$82B5` Select waiter after each title cutscene;
the VM's `$EB` dialogue waits still require fresh A. The recorded input returns
ID 1 at frame 7243. Godot applies the source `$82DC` `$0700=$01` audio stop,
executes all 15 `$99F0` fade steps, and applies `$98A0/$9B7F` PPU/OAM clearing by
frame 7258. The focus check separately exercises the same waiter for ID 2.
The byte-checked caller cleanup `$82E2->$82EC` returns to `$80F1`; the live
route executes `$80F1-$80F7`, derives `$0022=$00` from reset/initializer ROM
bytes, and runs `$80F7->$C4B9->$80FA->$A20F->$80FD`, then caller normalization
and the `$8112->$893B` preset prefix. The match selector copies the 4,944-byte
source block and 11 match-zero player IDs. The next boundary is the `$893B`
NMI/IRQ wait. Automatic ID-2 dispatch,
ID-2 caller return at `$815D`, and
`$A203->$A2AF->$AA06->$C557->$C6BE` remain unresolved. FCEUX records 15 `$9FA8` yields
at `$9A06` on frames 8443–8457; source loop `$99F0` decrements live `$004A/$004B`
counters from `$0F/$0F` to `$00/$00` in same-input frame-end RAM captures.
The counter routine is identified, but its live caller and integrated handoff
remain unresolved; do not replace the source loop with a fixed delay. See the
[handoff gap audit](reference/rom_extract/gameplay/select_to_fresh_match_handoff_gap_20261031.md).
The recorded-input route now passes the ID-1 caller wait, verifies `$99F0`,
`$98A0`, and `$9B7F` through frame 7258, then applies selector writes across
source-frame offsets 0–8 and reaches `$893B` at frame 7266. It includes the
ROM-derived mapper shadow, `$A20F` match-zero selector, caller normalization,
and preset-loader setup. Logical JSR frames carry return words without
inventing absolute SP or stack-page state. The scheduled NMI/IRQ handlers,
`$78` wait producer, and live return remain unimplemented. A receipt-gated
`$893F-$895C` consumer now passes with a verifier-only IRQ receipt, but the
production route does not generate that receipt or reach `$8117`. Continuation
into ID 2 remains unimplemented.
At frame 8480 Godot already has stream `$0103`, delay `$E5`, and animation
`$0D01E9`, while FCEUX is at the initial `$8047` yield. FCEUX resumes at
`$804A` and enters
the F4/F5 parser and `$CC50` wait on frame 8481, and loads `$05E9=$E8` at frame
8494. The source transition that causes Godot to run slot `$11` 17 frames early
is not reconciled. At frame 8606, `$05E9` is `$67` in Godot and `$78` in FCEUX;
full RAM parity at frame 8605 is also not established,
with slot `$01`'s saved bank-high byte at `$0003` differing (`$00` Godot,
`$16` FCEUX). See [the route report](reference/rom_extract/gameplay/scenario36_queue_live_route_20261030.md)
and [focused verifier](tools/diagnostics/verify_slot09_scenario36_ec74_live_route.gd).

**Next sequence:**

1. Restore source-owned machine-state continuity from the title's KICK OFF
   branch into the gameplay caller. `OpeningSourceRuntime._on_kickoff_requested()`
   currently freezes the presenter and creates a separate route without CPU,
   stack, full RAM, mapper, PPU, or MMC3 state. Do not fill this gap from the
   candidate schedule or FCEUX captures. Once the state has a ROM-owned
   producer, replace the one-bit I-clear contract with source-owned status and
   wait-state propagation. The ROM-only audit identifies the target wait-byte writers:
   `$A133` for `$001B`, `$A0A6` for `$78`, earlier `$8943` for `$79`, and
   `$C46F` for `$003B`. Reproduce these through the live source path, then
   replace schedule-only NMI/IRQ entries with ROM-executed handlers at their
   source event boundaries, including RAM/PPU effects and RTI state. Produce
   the `$893B` return receipt from those effects. The bounded special-NMI
   executor reaches `$8061` only with a synthetic full-state fixture; resolve
   the remaining sound-driver path from live `$0700-$0705/$07FC` and APU state
   before claiming the NMI return. The queue-ID WAV presenter is not a driver
   substitute. Never inject
   candidate state, use a fixed delay, or copy trace values. See the
   [wait-state producer audit](reference/rom_extract/gameplay/fresh_kickoff_8920_source_clock_runtime_gap_20261029.md).
   The bounded verifier can now run the NMI and six-slot sound scan only from
   a synthetic full-state fixture; it stops at `$8061`, and the live route has
   no producer for that context. A sparse `$893B` RAM receipt image now reports
   known and unknown internal-RAM bytes, but does not provide initial state.
   Replace the VM-running Select proxy with the live `$4D/$4E` task pointer
   when its owner is known.
2. After the source-owned `$8117` return, execute `$8117-$811F` including the
   `$C4B9`, `$A006`, and `$C572` calls, then integrate ID-2 dispatch and its
   natural completion/Select wait. FCEUX now confirms
   `$A203->$A2AF->$AA06->$C557->$C6BE` by frame 8460; reproduce that path
   from source-owned state and reconcile the scenario `$35` writer and slot
   `$11` against the same-input trace.
   The receipt-gated caller verifier still stops at `$A4EB`. The first
   `$B0C0` dispatch is now decoded as a ROM stream at `$B305`, ending with the
   ROM `$0F` return at `$B327`; repeated FCEUX hooks confirm each address and
   opcode and observe `$A610 RTS->$811F->$C572`. The existing muted capture
   reaches the full command panel by frame 8953 and remains there through
   frame 9042. No Godot body executor or live route handoff reaches that panel
   yet. Implement the stream records and their ROM-backed helper effects from
   source-owned state, then execute the rest of `$A4EB-$A610` before extending
   the caller. The old `$05B3` RAM-buffer and empty-buffer-terminator
   assumptions were incorrect. See
   [post-wait caller evidence](reference/rom_extract/gameplay/fresh_match_postwait_caller_20261031.md).
3. Establish the live field's ROM-derived CHR, palette, nametable, scroll, and
   raster baseline. Apply normal-NMI `$2002/$2006/$2007` events through the
   existing PPU applier and compare visible same-input frames.
4. Continue source-selected field tasks until the ROM command-menu request, then
   feed its live player state to the existing ROM-derived panel and input
   components. Verify the unselected initial state and keyboard/controller
   navigation; do not confirm an action or enter Continue.
5. Resolve route audio and source-clock gaps, compare the complete route, and
   verify the packaged game runs without ROM/emulator files.

Keep each cycle bounded to one source transition and its Godot consumer. Do not
repeat matched snapshots 1 or 8–18. The workflow is in
`.agents/skills/nes-reverse-engineering/references/fceux-project-workflow.md`.
### Fast execution lanes

- **FCEUX:** one owner controls the shared emulator. Reuse the muted,
  signature-checked frame-4692 checkpoint and recorded Select inputs. The
  frame-7258 two-pass PPU/RAM snapshots and 15 palette packets already match.
  Two matching muted passes also show no `$0022` writes after frame 4692 through
  frame 7300; runtime derives the value from ROM bytes. FCEUX behavior at the
  `$893B` NMI/IRQ wait is already traced; investigate only a specific missing
  source-state or interrupt-phase question. Verify checkpoint signature, input
  prefix, cycle convention, and repeat-pass hashes. Do not recapture the matched
  cleanup snapshots, restart from power-on, or overwrite a user slot.
- **ROM analysis:** map only the next unresolved caller/branch and return the
  source-byte span, bank/file mapping, live input contract, writes, and stop
  boundary. Store details in a focused report, not this plan.
- **Godot:** the route runs `$DAE2->$DAF2->$DC07->$DAF5->$DC82->$E6EC->$CDE2`,
  `$DB0E->$CBB0->$CB0F`, slot `$09` through scenario `$36`, and callback slot
  `$15` through all 32 map-$42 cells. The focused same-input verifier passes
  byte parity for the three FCEUX queues at frames 8602–8604 and the
  `$05CD=$A0` terminal callback through `$CAF7` at frame 8605, then through
  the slot-$11 `$8047->$C515->$CB0F` save and NMI wait at frame 8606. Twenty-four
  selected callback/task/mapper RAM bytes match the same-input frame-8605
  capture; frame-8606 slot-$11 state fails the same-input counter check. The
  title Select cleanup now matches its 15 palette packets and frame-7258 PPU/RAM
  snapshot. The live route derives `$0022` from reset/initializer ROM bytes,
  runs match selection and normalization, then reaches the `$893B` preset wait
  with a logical JSR frame; source-owned NMI/IRQ and the wait return follow.
  Field PPU
  rendering, command-menu input, route audio, generic-input RNG, and source-clock
  accuracy remain open.
- Run independent lanes concurrently only when they have separate owners,
  outputs, and no shared emulator or conflicting files. Every task names its
  checkpoint, input sequence/hash, target source event, expected artifact, and
  acceptance/stop condition.

**Latest increment acceptance:** from the recorded ID-1 Select edge, Godot
executes `$99F0`, applies `$98A0/$9B7F`, runs the source-checked `$82E2-$82EC`
stores/RTS and caller instructions through `$893B`, including ROM-derived
`$0022`, match selection, normalization, and the `$8920/$9DEE/$C4B9` preset
prefix. The 4,944-byte source copy, 11 roster IDs, mapper writes, `$E4` branch
proof, and `$BF00` pointer arithmetic were verified; cleanup palette packets
and the frame-7258 PPU/RAM snapshot still match. The current boundary is the
ROM-owned `$78` NMI/IRQ wait. This checkpoint does not establish the preset
return, later `$C6BE` handoff, or field/menu behavior. Preserve the
single-input-hash RNG limit and use no trace RAM as runtime input.

## Active milestone boundary

Start at the title screen's selected `KICK OFF` option and stop at the first
in-match command menu with no action selected. Do not confirm a soccer action or
enter `CONTINUE`. The completed cold-start opening/title slice and its measured
status are summarized in `GOALS.md`.

## Workflow references

Follow the ROM evidence, asset provenance, FCEUX checkpoint, and fidelity rules
in `AGENTS.md` and `.agents/skills/nes-reverse-engineering/SKILL.md`. Keep exact
bytes, traces, and comparison reports under `reference/`; link to those records
instead of copying their contents into this plan.

## Work plan

### 1. Close the active KICK OFF-to-first-menu slice — ACTIVE

- [x] **Connect the live route through the first menu-window queue writes and slot-$09 prefix.** Compose
  the source-owned fresh-match task path and slot-`$09` yield, then resume root
  slot-`$01` after one explicitly labeled frame-level normal-NMI abstraction.
  Execute the supported `$EE9F` empty-actor and `$E3CA` no-direction paths,
  save at `$CA4F->$CB0F`, and continue the same scheduler scan into slot `$05`.
  Execute its `$EF->$8B48`/`$FC->$8C52` callback path, verify `$0515=$80` and
  the first two `$04A5` packets, yield at `$8886->$C515`, dispatch slot `$09`
  at `$EB8B`, and execute its verified `$0516=$00` and `$05D2=$00` paths to
  `$86F8`; read live `$0532`, execute only its `$00` branch through `$8722 RTS`,
  and return to `$EBB3`; then read live `$0534`, execute only its `$00` branch
  through `$87A3 RTS`, and return to `$EBC5`; then carry that result through
  `$EBD4->$8009->$87E6`, execute the live `$0536=0` branch through `$8814 RTS`,
  and return at `$EBD7`; then read live `$052E`, execute its zero path through
  `$EC05->$EB86`, and reach `$EB88->$CB0F`. Stop at the handler entry.
- [x] **Continue slot `$09` through worker `$8779` to `$EBC5`.** The live
  `$0534=0` branch runs from the actual `$86F8` worker result; nonzero input is
  rejected. The focused verifier checks CPU, RAM, stack, mapper, and stop
  boundary. It does not execute `$87E6`.
- [x] **Execute the root bridge and `$87E6` zero branch to `$EBD7`.** The
  executor consumes the actual `$8779` result, confirms live `$0536=0`, writes
  `$0538=0`, and rejects nonzero stream state. The focused verifier checks the
  caller, MMC3, stack, RAM, and stop boundary.
- [x] **Continue the `$EBD7` root branch to `$CB0F` handler entry.** The live
  `$052E=0` branch is ROM-checked and returns a complete `$EB88->$CB0F` call
  contract; nonzero `$052E` is rejected. The handler itself is not executed.
- [x] **Execute `$CB0F` and continue the scheduler from the live call state.**
  Save slot `$09` at resume `$EB8B`, scan empty slots `$0D/$11/$15`, and stop at
  `WAIT_FOR_NMI_READY`; reject modified state and trace-derived inputs.
- [x] **Verify the slot-`$05` `$04A5` packets with a caller-supplied normal NMI.**
  The consumer returns 20 ordered `$2002/$2006/$2007` events. The scan selects
  root slot `$01` at `$CA52`; it does not resume slot `$09`. This component check
  does not establish production NMI cadence; the live route's current
  frame-level abstraction remains an approximation.
- [x] **Resume root slot `$01` at `$CA52` from the second NMI.** The six live
  actor flags are `$00`; `$EE9F` returns, `$E3CA` takes the no-direction path,
  and `$CB0F` saves the task. The next scan selects slot `$05`.
- [x] **Resume slot `$05` through row-one `$F0,$FC` to `$C515`.** Adopt 277
  ordered RAM writes and CPU/stack state. Stop before `$CB0F`; do not save,
  scan, or generate NMI. Evidence: [slot-$05 F0/FC boundary](reference/rom_extract/gameplay/slot05_f0_worker_partial_boundary_20261029.md).
- [x] **Execute the `$BBE0` `$ED 00 FC` descriptor row.** Resume the live
  slot-$05 worker at `$89A0`, verify bank `$19` and pointer `$BBE0`, execute its
  `$ED` and `$FC` handlers from source state, and stop when the parser reaches
  `$BD9C`. Evidence: [row-$00 report](reference/rom_extract/gameplay/slot05_descriptor01_ed_row00_runtime_20261029.md)
  and [focused verifier](tools/diagnostics/verify_rom_slot05_descriptor01_ed_row00.gd).
- [x] **Join two live slot-`$15` packet snapshots to ordered PPU writes.** Two
  muted passes from the checked frame-8399 checkpoint match normalized event,
  queue, controller, and input logs. Snapshot 1 joins two `$07` records to 14
  writes; snapshot 8 joins the `$85C2` prefix to 51. Snapshot 465 remains
  pending, so queue completion and visible field output are still open. Evidence:
  [packet/PPU report](reference/rom_extract/gameplay/first_command_field_packet_queue_join_20261029.md).
- [x] **Execute `$EE 00 FC` with its ROM-produced counter.** The live row
  returns through `$8B2F->$8C55->$8C84->$8C52->$896C` and reaches the actual
  `$C515` yield. `$003C=1`, `$0028=0`, `$05C5=2`, and the pointer remains
  `$BD9C`; no later row is read. Evidence:
  [runtime report](reference/rom_extract/gameplay/slot05_descriptor01_ee_row00_runtime_20261029.md)
  and [focused verifier](tools/diagnostics/verify_rom_slot05_descriptor01_ee_row00.gd).
- [x] **Save the `$EE 00` yield and scan to the next task.** The ROM `$C515`
  trampoline and checked `$CB0F->$CAA5` scheduler save select slot `$09` at its
  pre-dispatch boundary. No NMI or task body is run. Evidence:
  [scheduler report](reference/rom_extract/gameplay/slot05_ee_row00_cb0f_scheduler_20261029.md)
  and [focused verifier](tools/diagnostics/verify_rom_slot05_ee_row00_cb0f_scheduler.gd).
- [x] **Resume the selected slot `$09` task.** Dispatch from the saved record;
  live `$0539/$0516/$05D2/$0532/$0534/$0536/$052E` gates are all zero. The
  existing source-checked zero branches save slot `$09` as `01 76 18 19`; the
  scheduler stops at `WAIT_FOR_NMI_READY`, cursor `$19`. Evidence:
  [slot-$09 root-cycle report](reference/rom_extract/gameplay/slot05_ee_to_slot09_root_cycle_20261029.md)
  and [focused verifier](tools/diagnostics/verify_rom_slot05_ee_to_slot09_root_cycle.gd).
- [x] **Service the pending normal-NMI queue from slot `$09`'s wait.** The
  unchanged queue has `$0515=$80` and two `$07` packets; one explicitly
  caller-labeled normal-NMI service returns 20 ordered bus events, clears
  `$0515`, and selects slot `$01` at `$CB0F`. No event was applied to the
  renderer and no task body ran. Evidence:
  [queue/NMI boundary report](reference/rom_extract/gameplay/slot05_ee_slot09_nmi_to_boundary_20261029.md)
  and [focused verifier](tools/diagnostics/verify_rom_slot05_ee_slot09_nmi_to_boundary.gd).
- [x] **Resume slot `$01` after the queue NMI.** The production route consumed
  the verified pending queue, selected `$01` at `$CA52`, followed six live
  inactive-actor records and the no-direction branch, saved `01 26 00 01`, then
  selected slot `$05` at `$CB0F` before dispatch. Evidence:
  [slot-$01 report](reference/rom_extract/gameplay/slot01_queue_resume_to_slot05_boundary_20261029.md)
  and [focused verifier](tools/diagnostics/verify_rom_slot01_resume_after_queue_nmi.gd).
- [x] **Resume slot `$05` and execute the live `$ED 01 FC` / `$EE 01 FC` rows.**
  The real record dispatches at `$8889`; both hash-checked rows execute through
  the `$C515` yield. The scheduler adopts 388 ordered RAM writes and selects
  slot `$09`. The subsequent live cycle evaluates `$0629=$00`, executes the
  `$DAD8->$DADA->$CBB0` scenario-$35 producer, saves slot `$05` at `$CB0F`, and
  selects slot `$09`; the focused verifier passes. Evidence: [row execution report](reference/rom_extract/gameplay/slot05_live_descriptor01_rows_to_c515_20261029.md),
  [scenario enqueue report](reference/rom_extract/gameplay/slot05_scenario35_enqueue_live_godot_boundary_20261029.md),
  and [focused verifier](tools/diagnostics/verify_rom_slot05_live_ed01_row_bbe3.gd).
- [x] **Continue the selected slot `$09` zero-state route.** Preserve the
  source RAM/mapper context through its verified `$EB8B->$EBD7->$CB0F` path and
  the following NMI/task handoff. The scenario-active `$0516=$80` branch is a
  separate unresolved path below.
- [x] **Continue the slot-`$05` worker to `$DAD1` and scenario `$35`.** Preserve
  actual queue waits and scheduler handoffs; the live `$0629=$00` branch runs
  `$DAD8->$DADA->$CBB0`. Do not infer NMI timing from frame counts. The
  second-wrapper boundary is in
  [its source report](reference/rom_extract/gameplay/slot05_second_wrapper_yield_20261029.md)
  and [focused verifier](tools/diagnostics/verify_rom_slot05_second_wrapper_yield.gd).
  The selected descriptor rows are mapped in the
  [static `$BBE0` audit](reference/rom_extract/gameplay/slot05_second_descriptor_bbe0_static_audit_20261029.md).
- [x] **Resume slot `$09` with the live scenario-active flag.** The `$0516=$80`
  path reaches `$EC74`, reads scenario `$35`'s first `$F9` callback record, and
  seeds slot `$15` from live state. The scheduler selects the callback; see the
  [scenario audit](reference/rom_extract/gameplay/slot09_scenario_active_ec10_audit_20261029.md)
  and [runtime batch report](reference/rom_extract/gameplay/slot15_map42_first_batch_runtime_20261029.md).
- [x] **Run all source-selected map-$42 batches.** The route dispatches slot
  `$15` through `$8572->$85C2`, consumes each queue through the normal-NMI path,
  and matches snapshots 8–18. The ROM's `$05C9` exhausted-row branch produces a
  final two-cell batch and yields at `$85BE`; its queue contains 64 bytes and
  emits 34 `$2007` writes. Temporary stack writes, source-cycle timing, and
  visible PPU application remain open. Evidence: [full-row report](reference/rom_extract/gameplay/slot15_map42_full_row_runtime_20261029.md).
- [x] **Classify selected slot-$15 source tasks in the production route.** The
  runtime now routes the initial `$8009` callback, saved `$CB0F` map batches,
  and exhausted-row terminal record to their corresponding source-runner
  methods. The focused verifier now exercises that classifier through all
  eleven batches and `$CAF7`; interactive same-input route integration remains
  unverified.
- [x] **Resume the source `$35` actor-worker seed after `$CAF7`.** At `$ED15`,
  parameter `$73` causes the fixed-bank code to configure slot `$11` and call
  `$CAE7`. The actor worker's register-matched first `$CB0F` is at frame
  8480/cycle 5141 after `$800F->$8047`; the route now executes and saves this
  first worker boundary before the following normal NMI. Cycle 4875 remains a
  separate caller-side yield with unknown active task owner.
  Evidence: [slot-$11 first-yield report](reference/rom_extract/gameplay/slot11_actor_worker_first_yield_20261029.md).
- [x] **Execute the `$EE9F` animation `$8F` seed prefix.** From the recorded
  slot-$01 route, execute `$F5 $0A`, `$F4`, five `$F1` packets, and `$F0`; verify
  the five live-layout actor records and stop at `$EEB1`. This bounded test does
  not execute the active-actor loop or adopt state into the route scheduler.
  Evidence: [focused verifier](tools/diagnostics/verify_rom_ee9f_actor_init_80_executor.gd)
  and [source audit](reference/rom_extract/gameplay/ee9f_active_actor_tick_20261030/README.md).
- [x] **Continue active actors from `$EEB1` through `$CA55`.** The production
  route adopts the live prefix into slot `$01`, applies ROM-derived
  appearance/motion updates for its active records, builds route-time OAM, and
  returns through the actual caller. The focused route verifier matches the
  five actor records and 34 OAM tuples against the muted FCEUX frame-8481
  trace. That state match does not establish same-frame timing or visible
  pixel parity.
- [ ] **Trace the separate pending `$0C` queue record at snapshot 465.** Resume from the
  verified frame-8399 checkpoint, preserve the recorded controller-poll phase,
  and identify the first subsequent consumer/commit for the pending `$0C`
  record. This is distinct from the completed map-$42 row snapshots 8–18. Stop
  at that source event; do not repeat the already matched snapshot 1 or 8–18 joins.
- [ ] **Connect normal-NMI PPU writes to the visible renderer.** Reuse the
  verified `RomPpuNametableWriteApplier`, preserve bus order, apply values to
  renderer-owned PPU memory only after its active field CHR/palette context is
  source-derived, and refresh at the source event boundary. Keep raster timing
  limitations explicit.
- [ ] **Expand `$EE9F` beyond the current empty-actor state.** Implement active
  actor branches only when their live records and source inputs are produced.
- [ ] **Resolve live match state.** Produce formations, player records,
  possession, active holder/receiver, RNG operands, and route flags from their
  verified ROM writers and real call sites. Integrate existing isolated
  resolvers only when their inputs are supplied by the live route.
- [ ] **Produce and render the complete kickoff field from its actual loader.**
  The packet joins for snapshots 1 and 8–10 are verified, but snapshot 465 remains
  pending and the source trace does not establish the full field or command
  panel. Trace the next queue consumer, then derive the live caller, record ID,
  and ordered CHR/nametable/palette/scroll/raster state. Integrate existing
  descriptor and map decoders only when their live inputs are proven; carry
  ordered writes through the source event into the renderer. Do not infer the
  field from scenario `$1E` map `$36` or an uncalled descriptor hook.
  Evidence: [field PPU producer audit](reference/rom_extract/gameplay/field_ppu_baseline_transition_20261029.md),
  [fresh background-loader caller audit](reference/rom_extract/gameplay/fresh_kickoff_background_loader_caller_audit_20261029.md),
  [field queue-provenance boundary](reference/rom_extract/gameplay/field_c97b_queue_provenance_boundary_20261029.md).
- [ ] **Reach the first command menu from normal play.** Install it only after
  the ROM-owned field loop and menu request/state are present. Preserve the
  observed initial “no action selected” state; map directional selection and
  confirmation to the observed inputs. Stop before action confirmation.
- [ ] **Implement the caller's `$8920` wait and return in Godot.** The live
  FCEUX trace establishes the `$78/$79/$1B.6/$3B.7` transitions, NMI write,
  raster-IRQ clear, and `$895C->$8117` return. Godot now executes the ROM prefix
  through `$893B` but stops before reading `$78`; production has no CPU
  interrupt bridge or MMC3 A12/IRQ clock. A new repeated muted trace observes
  `$0700-$0705=$00` and `$07FC=$0F` at frame-7266 `$C449`, and reaches the sound
  driver's `$8061` boundary; Godot does not yet derive this call state from
  ROM-owned producers. The logical P contract leaves the interrupt-disable bit
  unknown. Derive the wait inputs from ROM-owned runtime state; do not seed them
  from the trace or return by elapsed-frame delay. See
  [the runtime gap report](reference/rom_extract/gameplay/fresh_kickoff_8920_source_clock_runtime_gap_20261029.md).
- [ ] **Make route audio source-driven.** Continue the caller after verified
  runtime `$8920` return through the `$812C` `$0700` store, then emit its
  branch-selected `$55`/`$4C` event. The trace observes `$55` at frame 7409;
  it is not a runtime event. Connect scenario/task queue writes in source
  order. Investigate cue event-time and PCM differences; do not compensate
  with guessed frame delays or captured WAV input.
- [ ] **Compare same-input output.** Replay the same start/input sequence in
  FCEUX and Godot. Compare visible frames, cursor/menu state, source event order,
  frame/cycle timing, and audio samples. Add only focused comparisons for the
  current gap.
- [ ] **Prove standalone operation.** Launch a clean project copy without the
  `.nes` ROM, FCEUX, or diagnostic captures. Confirm the route still reaches
  the specified endpoint.

**Exit gate:** ordinary KICK OFF input reaches the first command menu without
test-only state injection; the menu is usable; same-input differences are
measured and documented; no soccer action or Continue flow is entered; runtime
has no ROM/emulator dependency.

### 2. Shared ROM maps and decoders — only as needed for the active slice

- [ ] Map and index only the banks, routines, and data used by the current route
  or its next unresolved transition. Keep addresses tied to verified source
  bytes.
- [ ] Inventory only tables and pointer formats needed to produce the active
  route's text, teams, formations, players, graphics, and audio.
- [ ] Build or reuse focused decoders with explicit inputs/outputs and
  hash-bound source spans. Keep their checks separate from, and do not let them
  postpone, production-route integration.
- [ ] Record each active question, evidence, source span, runtime consumer, and
  next action in the focused route report. Defer a game-wide inventory until a
  later milestone needs it.

### 3. Decode the complete match command loop — future scope

- [ ] Trace each menu and input branch from controller polling through
  precondition checks, resource costs, RNG calls, state writes, animations,
  audio cues, and return-to-field behavior.
- [ ] Decode movement and active-player selection, encounter/range rules,
  possession changes, passes, one-two passes, dribbles, tackles, blocks, shots,
  goalkeeper responses, and special moves.
- [ ] Reconstruct opponent decisions and randomness from ROM routines and
  source call order. Preserve deterministic seeds/inputs in replay evidence;
  do not substitute a guessed probability model where source behavior can be
  resolved.
- [ ] Represent authoritative match state separately from Godot presentation.
  Use explicit phases, action inputs/results, named costs/stats, and recoverable
  possession/transition handling as described by the gameplay skill.

### 4. Decode match lifecycle and campaign — future scope

- [ ] Trace kickoff, possession reset, goal/score updates, halftime, match end,
  win/loss/draw branches, and transitions to the next match.
- [ ] Decode story/cutscene scripts, text tables, character/scene identifiers,
  branch conditions, waits, animation commands, sound triggers, and script
  continuation rules.
- [ ] Map team/player databases, stats, levels, stamina/technique costs,
  formations, tournament schedule, save/continue records, and progression
  updates to their ROM readers/writers.
- [ ] Implement Continue/save/load only after the user expands the active scope
  beyond the current fresh-start first-menu endpoint.

### 5. Reconstruct all visual and audio paths — future scope

- [ ] Graphics: decode CHR tiles, palettes, nametable/tilemap/metatile
  compression, sprite descriptors/OAM, animation streams, scroll/camera,
  sprite priority, masking, IRQ/raster effects, and PPU update queues.
- [ ] Text/UI: decode tile-based text, glyph mapping, windows, menus, cursor
  movement, blinking, text speed, and input timing from original data/routines.
- [ ] Audio: map the ROM sound driver and track/SFX tables; decode command
  streams, channel state, tempo, envelopes, DMC state, trigger/stop ownership,
  and source-clock timing. Compare the selected renderer/mixer with FCEUX and
  report residuals rather than labeling unmatched PCM exact.
- [ ] Package extracted/converted project-owned resources with source manifests
  and checksums. Never bundle the full ROM or diagnostic-only captures.

### 6. Integrate, verify, and close each milestone

- [ ] For every milestone, retain one canonical input script and a verified
  emulator checkpoint near the target interval. Confirm checkpoint signatures
  after every load.
- [ ] Verify the smallest relevant slice: source bytes, decoder output, live
  state transitions, rendering/audio output, and clean runtime import/startup.
- [ ] Keep regression outputs under `reference/diagnostics/`; keep decoded
  source bytes/manifests under `reference/rom_extract/`; keep runtime-ready
  project assets under `assets/`.
- [ ] Update `GOALS.md`, source notes, and this plan together when evidence or
  implementation status changes. Do not duplicate long trace logs in this
  plan; link to their focused reports.
- [ ] Close a slice only when its exit gate is satisfied. Report measured
  mismatches and unmeasured hardware/desktop timing separately.

## External research

Use the focused source review at
`reference/rom_extract/gameplay/first_match_external_reverse_engineering_review_20261027.md`
as a lead list. Search only for a specific unresolved routine or data mapping,
then verify any candidate against the target ROM and local trace before using
it.
