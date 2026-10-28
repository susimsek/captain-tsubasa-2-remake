# First-command task boundary trace — 2026-10-28

## Scope and source facts

This diagnostic-only follow-up captures task records, CPU registers, mapper
state, stack-page contents, scenario continuation fields, and actor/worker
boundaries for the fresh KICK OFF route. It does not change the Godot runtime.
The supplied Turkish ROM SHA-256 is
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.

The scheduler's active task record is four bytes: byte `+0` is the ready/delay
value, `+1` is the saved stack pointer, and `+2/+3` hold bank context. A newly
seeded task supplies a bank base in `+2`; the immediate-ready path maps that
bank and its adjacent bank. After yielding, `$CB0F` saves the current mapper
pair to `+2/+3`. The return point and suspended CPU context are held in the
6502 stack page, not in a task-record PC field. The fixed-bank scan checks task
bases `$0001,$0005,$0009,$000D,$0011,$0015` in order. `$FF` is immediately
ready; other nonzero delays are decremented and dispatch when they reach zero.
`$001B.7` is the NMI-ready latch that releases another scan.

For the bank-$10 scenario reader, `$8097–$80A8` prepares slot `$0015` with
saved SP `$F0` and bank base `$0B`, then `$C50F → $CAE7` seeds its stack return
so the first scheduler dispatch maps `$0B/$0C` and enters `$8009`, which jumps
to callback reader `$814C`. The trace observes the callback vector `$81A7`,
handler `$8327`, and map worker `$8525`. The worker yields through `$C515 →
$CB0F`; that save writes the task's next delay, current SP, and mapper pair
back into its record. A later scheduler resume returns through the saved
stack context, and `$CAF7` clears the completed slot. The scenario parser and
callback are distinct cooperative task contexts.

The `$ED15/$ED2D` path separately seeds worker slot `$0011` for bank-$18
animation work. Do not conflate it with the active-field actor update: the
`$EE9F → bank-$14:$800F` actor loop runs once per source frame from 8461
through 8953 (493 calls), with per-actor animation interpreters inside that
loop. These are different scheduler and presentation boundaries.

## Muted replay evidence

Trace outputs are in
[`reference/diagnostics/first_command_task_boundary_20261028_070655_utc/`](../../diagnostics/first_command_task_boundary_20261028_070655_utc/).
The run uses FCEUX 2.7.0, NTSC/NewPPU, muted audio, and an anonymous in-memory
checkpoint at source frame 8399 / cycle 250126423. ROM identity, the opening
and route input hashes, and checkpoint signature are recorded in
`metadata.txt`. After each load the runner checks frame/cycle, all 2 KiB RAM,
all 16 KiB PPU memory, MMC3 registers, and mapped PRG bytes. It uses no
numbered save slot.

The first warmup attempt was discarded at the 60-second no-progress bound
before frame 0 progress and before any checkpoint was created; no state from
that attempt was trusted. The successful run then created one verified
in-memory checkpoint and replayed frames 8400–8953 twice. Each pass contains
6,081 selected events and 62,357 watched writes. After normalizing the pass
number, both passes match exactly:

- Event SHA-256: `5bb43126def3352bbaeb44530ed712c16a8b112badbc300d76ef2ff33c8f9a4a`
- Write SHA-256: `c639dfb47435a5706c92cf16a7316947445ac03d4887ee1b26dbbedbd1a8dd22`

The successful run took 18.056 seconds. FCEUX exited `-11` during shutdown
after both complete trace files were written; `validation.json` records the
exit status, matching hashes, and verified checkpoint loads. The records are
observations, not runtime state or assets.

The trace scripts now call `savestate.persist(checkpoint)` after saving the
anonymous state. FCEUX's Lua API deletes a non-persistent anonymous state when
it is loaded; persistence keeps it available for the second replay pass and
still removes it when the script exits. The existing archived output was not
regenerated after adding this guard, so it remains evidence for the retained
run, not a verification of the source-only change.

## Standalone diagnostic model

Preserved source spans and their ROM offsets/hashes are listed in
[`task_context/manifest.json`](task_context/manifest.json). The standalone
model is [`tools/diagnostics/rom_gameplay_task_context_model.gd`](../../../tools/diagnostics/rom_gameplay_task_context_model.gd);
the focused verifier is
[`tools/diagnostics/verify_rom_gameplay_task_context_model.gd`](../../../tools/diagnostics/verify_rom_gameplay_task_context_model.gd).
The verifier checks each preserved span against the supplied ROM before
configuring the model. It then checks the retained two-pass trace as an
independent oracle; it does not feed captured task/RAM/stack values into model
state.

The verified transitions are:

1. The `$8097` caller decodes slot `$15`, saved SP `$F0`, bank base `$0B`, and
   return bytes `$08/$80`. `$C50F → $CAE7` produces record
   `FF F0 0B 00` and stack bytes `$01F1/$01F2 = $08/$80`. The immediate-ready
   path maps `$0B/$0C`; `RTS` enters `$8009`, whose bank-$0B jump targets `$814C`.
2. At the verified `$856F JSR $C515` call site, the diagnostic fixture uses
   delay `$01`, pre-call SP `$ED`, X `$08`, Y `$10`, and mapper `$0B/$0C`.
   `$CB0F` yields record `01 E9 0B 0C`; saved SP `$E9` addresses stack bytes
   `10 08 71 85`. One finite-delay scheduler scan decrements `01→00`; the
   `$CAB9` restore returns X/Y, bank pair, SP `$ED`, and PC `$8572`.
   A separate synthetic source-backed case confirms delay `$02` stays parked
   after its first scheduler scan and resumes after the second; this counts
   abstract scans, not video frames.
3. `$CAF7` clears task bytes `+0/+1` and leaves the bank bytes and stack page
   untouched. The trace independently shows the route's `$0015/$0016` cleanup
   writes at frame 8479.

The focused command
`godot --headless --path . --script tools/diagnostics/verify_rom_gameplay_task_context_model.gd`
passed. This model intentionally does not implement the six-slot scheduler,
NMI cadence, prior callback history, concurrent tasks, cycle timing, the
slot-`$0011` worker, or any `KickoffRouteRuntime` integration. It is diagnostic
evidence only; no production scheduler increment is justified yet.
