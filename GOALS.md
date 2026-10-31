# Active Goal: KICK OFF to the First Match Command Menu

**Status: ACTIVE — incomplete.** This file contains the current goal, a concise
status summary, and completion criteria. Detailed history and measurement
records live in the reports under reference/. The previous long GOAL log is
preserved in [the archived progress log](reference/goal_progress_history_20261028.md).

## Goal and scope

Complete a standalone Godot 4 slice that starts with KICK OFF selected on the
title screen and reaches the first match command menu. No soccer action should
be selected when the menu first appears. Do not enter the CONTINUE flow or
confirm a soccer action.

The game must not require the ROM or an emulator at runtime. Visuals, text,
audio, and behavior must derive from the supplied ROM bytes and decoded game
logic. Emulator screenshots and captured WAV files are for observation and
comparison only.

## Project-wide requirements outside the active milestone

These are standing project requirements; they do not expand the current
KICK OFF-to-first-menu milestone.

Keep the About and update flows for Windows, Linux, and macOS. Automatic update
checks must not download updates. Download and installation require an explicit
user choice and a writable destination. Use the correct package type for each
platform; release packages must include third-party notices and SHA-256/Sigstore
manifests. Desktop menus must not disrupt the 256×224 game display or gameplay
flow. Details are in the Godot skill's desktop/release reference and
.github/workflows/. This scope does not change the first-match milestone
endpoint.

## Current status — 31 October 2026

- The last full recorded-input diagnostic replay, before production was held
  at the handoff gap, sampled pad state at each source-frame boundary and
  derived `$001E` from previous/current state. The one-frame A
  press at frame 8593 reaches the ROM `$DAE2->$DAF2` path with `$001C=$80`,
  `$001E=$80`, and `$0441=8`; the `$DAF2 JSR $DC07` bytes are hash-checked.
  That diagnostic run executed the source-derived `$DC07` callee, applied
  ordered formation scratch, pointer, position-record, and stack writes, and returned
  slot `$05` to `$DAF5` with SP `$50`. It derives all 22 coordinates from the
  ROM position tables. All 22 resulting X/Y pairs match the recorded FCEUX RAM
  image at source frame 8593; that is a same-input memory-value comparison, not
  a CPU-cycle or instruction-phase comparison. The recorded release at frame
  8594 was consumed by the diagnostic route.
  The diagnostic executor applies the ROM-only, input-hash-bound RNG replay at
  source-frame NMI boundaries, then executes receiver selection through `$DC82`, holder
  copy through `$E6EC`, and the ROM `$CDE2` tile-index helper, returning to
  `$DB0E`. The replay computes `$C9C5` from each traced operand triple and
  carry. Its 3,901 retained RAM comparisons match `$E1/$E2/$E3`; frame 8593
  resolves receiver slot 6. All 133 operand triples and carry bits match the
  muted FCEUX trace. This is parity for the one SHA-256-bound recorded input
  route; arbitrary input histories still lack live RNG event generation. The
  holder result is validated for the recorded route, but frame-internal timing
  is not established. That diagnostic run executed the ROM `$DB0E->$CBB0->$CB0F`
  scenario-`$36` queue path. The live caller, three queue writes, nested JSR
  return words, and `$CB0F` yielded task record are checked against packaged
  ROM bytes. At source frame 8593, Godot reads scenario data from ROM pointer
  `$B7E4`, decodes F5/F9 and event bytes `10 3A 8F F0`, applies ordered writes,
  and returns `$EC74->$EB9E` after seeding callback slot `$15`. It resumes the
  caller through `$86F8`, selects and dispatches slot `$15`, executes callback
  `$3A` through `$8327->$8525`, and reaches the first map-worker yield
  `$856F->$C515` before returning to scheduler NMI wait. By source frame 8604,
  Godot has built all 32 ROM-derived map-$42 cells in eleven batches. The two
  row-wrap queues and terminal queue now match same-input FCEUX RAM snapshots
  byte-for-byte; this exposed and fixed a PPU nametable-page address shift. At
  frame 8605, the source-derived `$05CD=$A0` callback branch returns through
  `$819C->$CAF7`, finished slot `$15`, and returned the scheduler to its NMI
  wait. The focused verifier matches 24 selected callback, finished-task, and
  mapper RAM bytes against the same-input frame-8605 FCEUX snapshot. Full RAM
  parity is not established; slot `$01`'s saved bank-high byte at `$0003`
  differs (`$00` Godot, `$16` FCEUX). That diagnostic run reached a slot-$11
  `$8047->$C515->$CB0F` animation-countdown yield and NMI wait at frame 8606.
  A wider same-input RAM timeline shows that diagnostic route already differed
  by frame 8443: Godot's `$0516-$0519` is `$00000000` while FCEUX has `$01AC0000`, and
  their task records differ. Godot has scenario-`$35` fields by frame 8450,
  while frame-end FCEUX RAM is still in its earlier `$01AC` state. FCEUX's
  fresh-match handoff runs at frame 8458; frame-end RAM first shows scenario
  `$35` at frame 8467. Godot first yields slot `$11` at frame 8463, while the
  FCEUX hook trace first observes the actor worker yield at frame 8480. The
  exact seed/write boundary between those observations is unresolved. The
  route now uses the ROM caller's shared `$82B5` wait for cutscenes 1 and 2;
  Select does not become an A edge for the dialogue `$EB` command. With the
  recorded input, cutscene 1 returns on Select at frame 7243. The route applies
  the source `$82DC` `$0700=$01` audio stop, then executes the shared
  `$99F0->$9A71->$9FA8` cleanup fade from VM-modeled `$E9/$EA` counters. Its 15
  `$05E8` palette packets match muted FCEUX snapshots at frames 7243–7257. At
  frame 7258 it applies `$98A0`'s nametable clear and `$9B7F`'s OAM shadow/DMA
  fills; the 2 KiB PPU and RAM results match the same-input FCEUX snapshots.
  It then executes the byte-checked `$82E2-$82EC` zero stores/RTS and the
  caller's `$80F1-$80F7` prefix, including `$00E0=$C0`. The live route derives
  `$0022=$00` from the ROM reset/initializer spans, executes `$80F7->$C4B9`,
  and runs the fresh match-zero `$80FA->$A20F` selector through `$80FD`. That
  selector copies 4,944 ROM bytes to PRG RAM and the 11 player IDs into the
  match records. It then executes the caller's `$80FD-$8112` prefix, second
  `$C4B9` bank selection, and `$A20C` normalizer. The route now forwards the
  normalizer's ROM-checked `$8107` `$0700=$01` stop write to its audio presenter
  at route frame 7266; subframe timing and PCM parity are not verified. The
  integration verifier checks logical call frames, the 256-value `$E4` branch
  proof, mapper writes, and match setup RAM result. At `$893B` the prefix
  reports one pending `$8114->$8920` JSR frame and a relative SP delta of `-2`;
  absolute SP and stack-page contents remain unknown. The current route
  executes the logical-frame `$8112->$8920` preset prefix for 232 no-interrupt
  cycles, derives `$EC/$ED=$00/$BF`, selects bank
  `$06`, and stops at `$893B` before reading the unowned `$78` wait latch. The
  prefix derives clear N/V/Z/C flags. The live route now leaves I unknown at
  selector entry instead of importing the hash-bound ROM-only CPU candidate;
  that candidate remains diagnostic evidence only. Godot does not execute
  reset-to-title status propagation. D/B/unused status bits are also unproved.
  The 31 October integration replay confirms the candidate I bit is not
  applied; the production route still stops at `$893B`. Focused verifiers cover
  known-I preservation and unknown-I retention. The
  receipt-gated `$893F-$895C` consumer passes with a verifier-only IRQ receipt,
  but the production NMI/raster-IRQ source bridge and live preset return are
  still missing. The route now consumes a ROM-derived selector clock asset and
  applies the selector's RAM-write timeline across relative frame offsets 0–8.
  The focused integration check reaches `$893B` at frame 7266, rather than
  frame 7258. The route status also exposes a sparse 2 KiB RAM image of
  verified source writes, with unrecorded bytes marked unknown; it does not
  create the missing title-to-route state. The focused route-wiring check now
  sends Enter through the visible title menu with KICK OFF selected and confirms
  the route starts cutscene 1; it begins at the title endpoint, not cold boot.
  The candidate schedule accounts for
  223,242 elapsed cycles as
  203,333 selector mainline cycles plus 19,909 NMI/IRQ service cycles; FCEUX
  measured 223,239 cycles, with a three-cycle entry-hook offset and the same
  return cycle. The selector executor still precomputes its result at call
  entry; Godot exposes the writes by cycle budget but does not run a resumable
  6502 core. Fifteen interrupt events are time-scheduled, but their handler
  writes and return receipts are not applied. The timeline excludes those
  asynchronous writes, and intermediate visible output remains unverified.
  The ROM-only candidate wait has I clear, and cold-reset ROM code runs
  `$C6B8 CLI`; neither observation is used to seed live route status. A live
  CPU path from `$C6B8` to the title handoff and actual interrupt handler
  execution remain open. The ROM-only candidate now records and checks
  the last ROM writers for `$001B/$78/$79/$3B`, including `$A133`, `$A0A6`,
  the earlier `$8943`, and `$C46F`; Godot does not yet execute those producers
  or the target IRQ. See
  the
  [selector timing and IRQ candidate report](reference/rom_extract/gameplay/fresh_kickoff_selector_timing_and_irq_candidate_20261031.md).
  The bounded special-NMI executor now runs `$C421->$A000->$A0A6->$C449` and
  the six-slot sound-driver prefix through `$8060` under a synthetic full-state
  verifier fixture, then stops at `$8061`. Missing production CPU/stack/RAM/
  mapper/PPU/APU context, the driver's remaining passes and return, RTI receipt,
  IRQ release, and live-route integration remain open. The standalone
  `$8117-$A4EB` caller verifier still uses a test-only IRQ receipt. A
  pointer-endian audit corrected the first `$A500->$B0C0` analysis: it
  dispatches ROM bytes at `$B305` (bank `$01`), not RAM `$05B3`. A repeated
  muted trace matches all nine dispatch addresses/bytes through the `$0F`
  return, then observes `$A610 RTS->$811F->$C572` in FCEUX. The standalone
  caller verifier stops at `$A4EB`; the production route stops earlier at the
  `$893B` wait because its source-owned NMI/raster-IRQ bridge is not connected.
  The match field and command menu remain unreachable in Godot. The
  same-input FCEUX trace continues through `$A203->$A2AF->$AA06->$C557->$C6BE`
  by frame 8460, and the existing capture shows the full command panel at
  frame 8953, stable through frame 9042. A muted, repeated FCEUX trace also observes the frame-7266
  `$C421->$C449->$8000->$8061` handoff: queue bytes
  `$0700-$0705` are all zero and `$07FC=$0F` at `$C449`. The trace also links
  the opening `$58` queue request at frame 282 to the ROM
  `$804D` store that establishes `$07FC=$0F` at frame 283. These are reference
  measurements only; Godot still does not derive that state or execute the live
  NMI/driver return. See the
  [wait-state runtime gap report](reference/rom_extract/gameplay/fresh_kickoff_8920_source_clock_runtime_gap_20261029.md).
  Automatic
  ID-2 dispatch, field construction, and the first command menu remain open.
  It still uses VM-running state as a
  proxy for the ROM `$4D/$4E` task pointer and does not model CPU/NMI phase. The
  focused integration check also covers the ID-2 wait.
  See the [handoff audit](reference/rom_extract/gameplay/select_to_fresh_match_handoff_gap_20261031.md)
  and [ID-1 palette trace](reference/rom_extract/gameplay/id1_select_cleanup_palette_trace_20261031.md).
  FCEUX records 15 `$9FA8` yields at `$9A06` over frames 8443–8457 for the later
  handoff. A new muted two-pass trace shows the final ID-1 `$E9` at `$A38B`
  raises `$004A/$004B` to `$0F` on frames 7121–7135; they stay there until the
  Select cleanup decrements them to zero on frames 7243–7257. Every staged
  `$05E8` palette payload matches the source `$9A71->$9AA2->$9EA2` conversion,
  and the following frame-end PPU palette matches the preceding staged packet.
  Godot now connects its modeled counters to the live `$99F0` source loop,
  applies `$98A0/$9B7F`, and matches the frame-7258 PPU/RAM snapshots. It also
  derives `$0022` from ROM initialization and executes the caller through the
  `$893B` preset wait; the tail consumer is not connected because the NMI/IRQ
  wait return is not produced. Later ID-2 dispatch,
  field, and command menu remain unresolved. See the
  [ID-1 cleanup palette trace](reference/rom_extract/gameplay/id1_select_cleanup_palette_trace_20261031.md).
  The cutscene event VM now models source `$E9` fade-up and `$EA` fade-down from
  ROM palette data, then applies `$EA`'s verified nametable zero-fill. Focused
  scheduler and palette-presentation diagnostics pass. This remains a
  presentation model: the live CPU/RAM/task context, gameplay palette-buffer
  selection, and exact PPU phase are not connected. See the
  [Select-to-handoff audit](reference/rom_extract/gameplay/select_to_fresh_match_handoff_gap_20261031.md).
  The frame-8480 counter mismatch follows an earlier mismatch in task order and
  source state. FCEUX resumes at `$804A` and enters the F4/F5 parser and `$CC50`
  wait on frame 8481; it loads `$05E9=$E8` at frame 8494.
  Godot already has stream `$0103`, delay `$E5`, and animation `$0D01E9` at 8480.
  The producer transition for the 17-frame early slot-`$11` run is not yet
  reconciled. At frame 8606,
  Godot enters with `$05E9=$68` and yields with `$67`, while FCEUX enters with
  `$79` and yields with `$78`; the animation counter ends at `$0D016B` in Godot
  and `$0D017C` in FCEUX. The route is not timing/state-parity verified at this
  boundary. Do not mask this with a guessed frame delay.
  Gameplay NMI-queue PPU events still are not applied to a visible renderer,
  and the complete field
  CHR/palette/scroll/raster baseline is missing. The field, first command-menu
  input, route-audio parity, arbitrary-input RNG, and clean runtime independence
  remain open. Godot reports two ObjectDB instances and one resource still in
  use at verifier shutdown. Frame labels do not establish physical NES cycle
  timing.

### Supporting route and evidence history

- The earlier slice from cold start through the title menu is complete. A
  same-input software comparison dated 2026-10-27 reported matches for
  4,693/4,693 visible frames and 3,442,925 audio samples. This compares Godot
  with FCEUX software output; it does not claim physical NES scanout or silicon
  timing.
- A muted, signature-checked two-pass FCEUX trace confirms the fresh route from
  the first `$EF7F` worker yield through `$DADA->$CBB0` scenario-`$35` enqueue.
  It records the `$0515` poll/set/clear sites and matching event/write hashes.
  The earlier frame-8399 checkpoint was session-local, so the trace rebuilt it
  from power-on and reused the new in-memory checkpoint for both passes.
- The playable `KickoffRouteRuntime` now accepts the ROM route's actual
  `$CB0F -> WAIT_FOR_NMI_READY` result instead of treating it as an error. It
  issues frame-level normal-NMI abstractions on successive Godot `NES_FPS`
  source ticks using the live ROM `$0020` shadow (initially `$88`, later `$8A`);
  this is a coarse software clock, not a verified PPU beam/dot/CPU-cycle
  schedule. After the first NMI, the route saves slot `$09` and waits. The
  second NMI consumes the
  live `$0515/$04A5` queue through `$C799->$C8FB` and returns 20 ordered PPU bus
  events; the route does not apply those events to a visible renderer. It
  resumes root slot `$01` through the inactive-actor `$EE9F` and no-direction
  `$E3CA` branches, saves `$CA4F->$CB0F`, resumes slot `$05` through its
  `$EF->$8B48`/`$FC->$8C52` callbacks and first two menu-window packets, then
  saves/scans the live `$C515` continuation. The scheduler selects slot `$09`;
  its checked `$EB8B->$86F8->$EBB3->$EBC5->$EBD7->$CB0F` zero-branch path now
  saves again and stops at the next NMI wait. The route verifier passes for
  these two frame-level NMI events and this bounded task cycle. It does not
  establish the visible field or command menu. The current source-driven slot-`$05`
  worker executes `$BBE0 = ED 00 FC` and `$BD9C = EE 00 FC`, then reaches the real
  `$C515` yield. The checked `$C515->$CB0F->$CAA5` save/scan selects slot `$09`, whose
  seven live zero gates run through the existing `$EB8B->$EBD7->$CB0F` path.
  Slot `$09` saves as `01 76 18 19`; the scheduler scans empty slots `$0D/$11/$15`
  and returns to `WAIT_FOR_NMI_READY` at cursor `$19`. From the unchanged
  `$0515=$80` queue, one caller-labeled NMI returned 20 ordered bus events,
  cleared `$0515`, and selected slot `$01` at `$CB0F`. The production route then
  ran the six inactive-actor and no-direction branches, saved slot `$01` as
  `01 26 00 01`, and selected slot `$05` at `$CB0F` before dispatch. The caller
  label is not physical timing, and the PPU events remain unapplied. The next
  live slot-`$05` dispatch now executes hash-checked `$ED 01 FC` at `$BBE3` and
  `$EE 01 FC` at `$BD9F`, returns through `$8C52`, and yields at `$C515`. The
  scheduler adopts 388 ordered RAM writes and selects slot `$09`. On the
  following caller-labeled NMI/task cycle, the live `$DAD1` check reads
  `$0629=$00`, takes `$DAD8->$DADA->$CBB0`, and the worker writes
  `$0518=$35`, `$0516=$80`, and `$0005=$00` before reaching the checked
  `$CB0F` save. The scheduler saves slot `$05` and selects slot `$09` with its
  own `$18/$19` bank record; the worker's mapper is `$1C/$1D`. The focused
  Godot route verifier passes this bounded transition. The slot-`$09`
  scenario-active reader and selected slot-`$15` callback are now integrated.
  Active-actor
  inputs, the full-field PPU baseline, command-menu pixels, audio parity, and
  source-cycle timing remain unresolved.
- A focused route audit and live Godot components map the first resumed slot-`$09` continuation:
  `$EB8B` reaches `$EC08` and reads `$0516`, then `$ED85` reads `$05D2`. Their
  initial trace values take zero-return branches, after which bank-$18 workers
  `$86F8`, `$8779`, and `$87E6` run. The live executors now reach `$EBD7`
  through zero branches at `$0532`, `$0534`, and `$0536`. The nonzero
  `$87E6` timer/stream paths remain unsupported. The trace shows later nonzero
  `$0516/$05D2` behavior, so zero-only components cannot represent the full loop.
- A separate ROM-checked PPU write applier converts the normal-NMI consumer's
  ordered `$2002/$2006/$2007` events into nametable writes. Its two-packet
  verifier passes, and the second live source event now returns those 20 bus
  operations; they remain unapplied because the full field nametable, CHR,
  palette, scroll, and raster state are not established.
  The earliest field-entry producers are `$E0DF` descriptors `$00/$01` through
  `$EF7F->$800C->$8852`. A bounded descriptor-`$00` component produces five
  complete queue records when supplied a matching fresh-period task result;
  missing or altered inputs fail closed; this isolated descriptor-`$00`
  component is still not wired into the live route. The descriptor-`$01` row
  loop now supplies live `$003C=1`, and Godot has executed `$EE 00 FC` through
  its formatter return and `$C515` yield. The post-yield pointer and later rows
  remain unresolved. An earlier FCEUX replay window contained no `$8B2F` or
  `$8C55` callbacks; the later focused Godot run establishes this bounded row
  path, not a full field load. Scenario `$1E` event `$45` selects partial map
  `$36`, whose placement requires live `$05CD`; a separate caller audit
  confirms this is not a complete field background load. See the
  [field PPU producer audit](reference/rom_extract/gameplay/field_ppu_baseline_transition_20261029.md),
  [descriptor trace addendum](reference/rom_extract/gameplay/field_entry_window_01_descriptor_trace_addendum_20261029.md),
  and [background-loader caller audit](reference/rom_extract/gameplay/fresh_kickoff_background_loader_caller_audit_20261029.md).
- A muted, same-checkpoint two-pass FCEUX trace now resolves the live
  `$893B` wait and BGM call. At `$8114->$8920`, `$001B/$78/$79/$3B` are
  `$C0/$04/$40/$55` and `P=$22` (`I=0`). The NMI writes `$04` to `$78`; the
  raster IRQ clears it, then `$895C RTS` returns to `$8117`. The caller reaches
  `$812C` and writes BGM `$55` at frame 7409. Both loads from the frame-4692
  checkpoint matched byte-for-byte and produced identical trace logs. This is
  behavioral evidence, not a Godot return receipt: Godot still needs the ROM-
  owned CPU/NMI/MMC3-IRQ source-clock path. Runtime now supplies the single
  candidate `I=clear` evidence for diagnostics only; the live route retains I
  as unknown and does not execute the cold-start-to-title CPU path or establish
  the remaining P bits at this boundary. The prior prefix fixture's `P=$A4` and the FCEUX caller hook's
  `P=$22` use different execution contracts and do not alone establish a
  matching runtime return. Route audio sample parity is unverified.
  See the [live wait and BGM trace](reference/rom_extract/gameplay/fresh_kickoff_1b6_persistence_addendum_20261029.md).
  The [runtime source-clock gap report](reference/rom_extract/gameplay/fresh_kickoff_8920_source_clock_runtime_gap_20261029.md)
  lists the missing CPU, PPU, and MMC3 IRQ state producers.
- A separate scenario-`$35` harness exercises the `$0516=$80` path through
  `$EC08->$EC74` and generates 32 map cells in eleven batches. This does not
  establish the current live scenario-`$36` slot-`$15` cursor contract.
  With scenario `$35` and `$0519=0`, it reads the first `$F9` record, seeds
  callback slot `$15`, and the live scheduler selects and dispatches it. Its
  ROM-derived `$8572->$85C2` worker now generates all 32 cells in eleven
  batches. Queue hashes match existing FCEUX snapshots 8–18; ten batches emit
  51 `$2007` writes each, and the final two-cell batch emits 34. See the
  [slot-$09 scenario audit](reference/rom_extract/gameplay/slot09_scenario_active_ec10_audit_20261029.md)
  and [full-row runtime report](reference/rom_extract/gameplay/slot15_map42_full_row_runtime_20261029.md).
- The live route now reaches the second `$DACE->$EF7F->$800C` worker invocation
  and saves its real `$C515` yield. On the next slot-$05 resume it executes
  `$BBE0 = ED 00 FC` and `$BD9C = EE 00 FC`, then yields at `$C515`. The `$EE`
  path returns through `$8B2F->$8C55->$8C84->$8C52->$896C`; at the yield,
  `$003C=1`, `$0028=0`, `$05C5=2`, and the live text pointer remains `$BD9C`.
  The descriptor's `$BBE3` address is not loaded in this invocation. The real
  `$C515->$CB0F->$CAA5` save/scan selected slot `$09`; its live zero-branch body
  then saved record `01 76 18 19` and returned the scheduler to
  `WAIT_FOR_NMI_READY` at cursor `$19`. At that wait, the unchanged `$0515=$80`
  queue was serviced once by a caller-labeled normal-NMI transition: it returned
  20 ordered bus events, cleared `$0515`, and selected slot `$01` at `$CB0F`.
  The production route resumed `$01`, followed `$EE9F/$E3CA` with live zero
  inputs, saved record `01 26 00 01`, and selected slot `$05` at `$CB0F` before
  dispatch. The next live worker executes `$ED 01 FC` at `$BBE3`, follows the
  ROM team-`$00` name stream, executes `$EE 01 FC` at `$BD9F`, and yields at
  `$C515`. Its 388 ordered writes are adopted; the scheduler selects slot `$09`.
  The live `$DAD1->$DAD8->$DADA->$CBB0` scenario-$35 enqueue is now integrated
  and verified from that route; it saves slot `$05` at `$CB0F` and selects
  slot `$09`. The scenario-active callback reads the first `$F9` record for
  scenario `$35`, seeds slot `$15`, and reaches the map-$42 worker. Eleven live
  `$8572->$85C2` batches process cells/placements `0–31`; their queue hashes
  match FCEUX snapshots 8–18. The final two cells take the ROM's exhausted-map
  branch at `$85A7->$85B6` and yield from `$85BE`. After the final NMI the route
  resumes slot `$09` and selects slot `$15` with
  `$05C7/$05C8/$05C9=$40/$20/$00`. It now executes the worker RTS, callback
  placement tail, dispatcher tail, and `$C512->$CAF7` finish; the frame-8479
  trace's `$CAF7` A/X/Y/P=`$51/$40/$10/$20` and `$05CD/$05CE=$A0/$00` match.
  Normal NMI return restores `$20/$19` from the enabled PPUCTRL shadow, which
  also gives the yielded dispatcher the observed status flags. FCEUX shows the
  next scenario-$35 actor task seeded into slot `$11` from fixed-bank `$ED15`
  through `$CAE7`. The `$CB0F` event at frame 8480/cycle 4875 is a preceding
  caller-side yield; the actor worker's register-matched first yield is at
  cycle 5141 after bank-$18 setup through `$8047`. Its exact active-slot/call
  linkage still needs an instruction trace, and the route has not implemented
  this transition yet. The production
  runtime now classifies selected slot-$15 callback, map-row, and terminal
  boundaries, but an interactive same-input run has not verified that wiring.
  The visible renderer does not yet apply the PPU commits, and the complete
  field CHR/palette/scroll/raster profile is missing. The executor is a bounded
  ROM-checked translation; it omits temporary `$85C2` stack writes and physical
  cycle timing. A muted two-pass
  replay from the saved frame-$8399 checkpoint matches normalized
  event, queue, controller, and input logs for frames 8400–8953. Snapshot 1's
  two `$07` packets map exactly to 14 `$2007` writes; snapshot 8's `$85C2`-
  produced 96-byte queue prefix maps exactly to 51 writes. At frame 8953,
  snapshot 465 still has pending queue data with `$0515=0`, and no later
  `$C97B/$2007` commit occurs for the later pending record. These joins verify
  the checked packet production/consumption, but not that the first command
  panel or full field is visible. The bounded post-`$CAF7` actor-task evidence
  is documented in the [slot-$11 first-yield report](reference/rom_extract/gameplay/slot11_actor_worker_first_yield_20261029.md).
  Integrate that transition, then source the actual field CHR, palette, scroll,
  raster, and command-panel state before connecting ordered PPU writes to the
  renderer.
  The 31 October
  [provider-fed menu verifier](tools/diagnostics/verify_first_action_menu_route_integration.gd)
  passes the unselected-state, Right=Shoot, and blink checks; a separate input
  verifier passes keyboard/gamepad direction mapping, A gating, and direction
  priority. These are component-level checks:
  the live route still does not reach the menu, and same-input selection pixels
  remain unverified. Full-route Godot parity, audio parity, and source-cycle
  timing remain open. See the
  [field packet/PPU join report](reference/rom_extract/gameplay/first_command_field_packet_queue_join_20261029.md)
  and [queue-provenance boundary](reference/rom_extract/gameplay/field_c97b_queue_provenance_boundary_20261029.md).
- The slot-$09 extension and focused verifier are documented in the [scenario-$36 route report](reference/rom_extract/gameplay/scenario36_queue_live_route_20261030.md) and [focused verifier](tools/diagnostics/verify_slot09_scenario36_ec74_live_route.gd).
- The next source-tracing work and acceptance criteria are in the **Current
  work package** section of PLANS.md. Record each new finding in its source
  report; update this summary only when the status changes.

## Completion criteria

- Normal user input takes the ROM-derived route to the first command menu.
  Tests must not inject RAM or imitate unresolved transitions with frame delays.
- No action is selected when the first menu appears; observed keyboard and
  controller navigation works correctly. Do not open CONTINUE or confirm a
  soccer action.
- Compare visible output, menu selection, source-event order, timing, and audio
  under identical startup and input sequences. Document any remaining gaps.
- A clean Godot copy reaches the same endpoint without the ROM or FCEUX.

## Active evidence

- Source task/bootstrap and NMI:
  [first-command root-task bootstrap and NMI](reference/rom_extract/gameplay/first_command_root_task_bootstrap_and_nmi_20261028.md),
  [first-command task-boundary trace](reference/rom_extract/gameplay/first_command_task_boundary_trace_20261028.md)
- $C515/$CB0F continuation and production-route boundary:
  [callback scheduler trace](reference/rom_extract/gameplay/first_command_callback_scheduler_trace_20261028.md),
  [live-route composition boundary](reference/rom_extract/gameplay/first_command_live_route_composition_boundary_20261028.md),
  [slot-$09 `$CB0F` save and scheduler wait](reference/rom_extract/gameplay/slot09_cb0f_scheduler_save_20261029.md),
  [second-NMI queue delivery and selected task](reference/rom_extract/gameplay/slot09_second_nmi_queue_delivery_20261029.md),
  [production-route NMI/task-cycle verifier](tools/diagnostics/verify_kickoff_route_to_root_task_yield.gd)
- Live root slot-`$01` actor-call route:
  [bounded `$CA52->$EE9F` empty-actor execution](reference/rom_extract/gameplay/ee9f_empty_actor_call/README.md) and
  [bounded `$CA55->$E3CA` no-direction execution](reference/rom_extract/gameplay/e3ca_no_direction_call/README.md),
  [live second-NMI root cycle](reference/rom_extract/gameplay/slot01_second_nmi_root_cycle_20261029.md)
- Fresh worker continuation through scenario `$35`:
  [ROM-byte continuation audit](reference/rom_extract/gameplay/fresh_worker_resume_and_second_wrapper_source_20261029.md),
  [slot-`$09` `$EB8B` continuation audit](reference/rom_extract/gameplay/slot09_eb8b_continuation_audit_20261029.md),
  [slot-`$86F8` zero-branch audit](reference/rom_extract/gameplay/slot09_86f8_worker_audit_20261029.md),
  [slot-`$8779` live zero-branch audit](reference/rom_extract/gameplay/slot09_8779_worker_audit_20261029.md),
  [slot-`$87E6` live zero-branch audit](reference/rom_extract/gameplay/slot09_87e6_worker_audit_20261029.md),
  [slot-$09 post-slot-$05 continuation](reference/rom_extract/gameplay/slot09_post_slot05_resume_20261029.md),
  [slot-$05 second-wrapper yield](reference/rom_extract/gameplay/slot05_second_wrapper_yield_20261029.md),
  [live descriptor `$ED 00 FC` worker row](reference/rom_extract/gameplay/slot05_descriptor01_ed_row00_runtime_20261029.md),
  [live descriptor `$EE 00 FC` worker row](reference/rom_extract/gameplay/slot05_descriptor01_ee_row00_runtime_20261029.md),
  [live `$C515->$CB0F->$CAA5` save/scan](reference/rom_extract/gameplay/slot05_ee_row00_cb0f_scheduler_20261029.md),
  [live slot-$09 root cycle from that scan](reference/rom_extract/gameplay/slot05_ee_to_slot09_root_cycle_20261029.md),
  [slot-$09 queue delivery to slot-$01](reference/rom_extract/gameplay/slot05_ee_slot09_nmi_to_boundary_20261029.md),
  [slot-$01 resume to slot-$05 boundary](reference/rom_extract/gameplay/slot01_queue_resume_to_slot05_boundary_20261029.md),
  [slot-$05 live `$BBE3` source gap](reference/rom_extract/gameplay/slot05_after_slot01_bbe3_source_gap_20261029.md),
  [slot-$09 queue delivery to the next task boundary](reference/rom_extract/gameplay/slot05_ee_slot09_nmi_to_boundary_20261029.md),
  [slot-$05 `$BBE0` descriptor audit](reference/rom_extract/gameplay/slot05_second_descriptor_bbe0_static_audit_20261029.md),
  [slot-$05 `$003C` row-progress source](reference/rom_extract/gameplay/slot05_ee_003c_descriptor_progress_source_20261029.md),
  [slot-$09 scenario-active `$EC10` audit](reference/rom_extract/gameplay/slot09_scenario_active_ec10_audit_20261029.md),
  [slot-`$EBD7` root-loop branch audit](reference/rom_extract/gameplay/slot09_ebd7_root_checks_20261029.md),
  [live descriptor rows through `$C515`](reference/rom_extract/gameplay/slot05_live_descriptor01_rows_to_c515_20261029.md),
  [muted two-pass FCEUX trace](reference/rom_extract/gameplay/first_command_post_c515_to_scenario35_fceux_trace_20261029.md),
  [`$0515` PPU-transfer producer/consumer cross-reference](reference/rom_extract/gameplay/ppu_transfer_buffer_0515_writer_cross_reference_20261029.md)
- Field and first-menu visual gaps:
  [kickoff field-intro visual gap](reference/rom_extract/gameplay/kickoff_field_intro_visual_gap_20261028.md),
  [first-menu visible-output comparison boundary](reference/rom_extract/gameplay/first_menu_visible_output_comparison_boundary_20261028.md),
  [live PPU context prerequisites](reference/rom_extract/gameplay/ppu_live_field_context_prerequisite_audit_20261029.md),
  [field-entry PPU producer audit](reference/rom_extract/gameplay/field_ppu_baseline_transition_20261029.md),
  [single-pass field PPU trace and alignment limit](reference/rom_extract/gameplay/fresh_field_ppu_trace_20261029.md),
  [field PPU queue-provenance boundary](reference/rom_extract/gameplay/field_c97b_queue_provenance_boundary_20261029.md),
  [descriptor `$01` team/numeric-row contract](reference/rom_extract/gameplay/field_entry_window_01_descriptor_source_20261029.md),
  [fresh field background-loader caller audit](reference/rom_extract/gameplay/fresh_kickoff_background_loader_caller_audit_20261029.md)
- Route audio:
  [first-match audio source](reference/rom_extract/gameplay/first_match_audio_source.md),
  [live audio integration boundary](reference/rom_extract/gameplay/first_match_audio_integration_boundary_20261028.md),
  [fresh KICK OFF caller return-chain audit](reference/rom_extract/gameplay/fresh_kickoff_caller_return_chain_audit_20261029.md),
  [live `$893B` wait and BGM `$55` trace](reference/rom_extract/gameplay/fresh_kickoff_1b6_persistence_addendum_20261029.md),
  [Godot source-clock integration gap](reference/rom_extract/gameplay/fresh_kickoff_8920_source_clock_runtime_gap_20261029.md)
- Earlier opening-audio build and comparison:
  [opening-audio build and PCM validation](reference/rom_extract/audio/opening_audio_build_and_pcm_validation_20261027.md)
- External research sources and their limits:
  [online reverse-engineering resources](reference/rom_extract/intro/online_reverse_engineering_resources.md)

Use AGENTS.md for working rules and PLANS.md for work order. If this status
summary conflicts with a detailed report, update the status and relevant report
to reflect the newest evidence. Do not treat an old archived entry as current.
