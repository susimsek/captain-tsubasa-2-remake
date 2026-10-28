# Fixed task scheduler scan audit — 2026-10-28

## Scope and source identity

This is a diagnostic-only model of the fixed-bank scheduler's six-slot ready
scan. It does not modify or feed the Godot route runtime. The source is the
supplied Turkish ROM, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.

The existing preserved source span is
[`task_context/fixed_task_scheduler_CA97_CAE6.bin`](task_context/fixed_task_scheduler_CA97_CAE6.bin):
CPU `$CA97`, ROM file offset `0x03CAA7`, 80 bytes, SHA-256
`3768ab8ac0aaeace9d3d53cf92cb8fea9363c400d6b8d4a40b77619c9900c6d8`.
Its offset, length, and hash are recorded in
[`task_context/manifest.json`](task_context/manifest.json).

## Byte-confirmed scheduler rules

The first 34 bytes at `$CA97` implement the scan and ready gate. The verifier
checks the supplied ROM against the preserved span and checks these opcodes
and relative branches before the model runs.

1. `$CA97` loads X with `$01`. The loop reads `$0000,X`, the ready/delay byte
   at the current four-byte task-record base.
2. A zero byte skips that record. `$FF` branches to the initial-dispatch path
   at `$CAD4` immediately.
3. Any other nonzero byte is decremented. If it becomes zero, the scheduler
   branches to the yielded-task restore path at `$CAB9`. Otherwise it adds
   four to X and continues. The six byte-derived slot bases are
   `$01,$05,$09,$0D,$11,$15`; after `$15`, the increment reaches `$19` and
   exits the scan.
4. The first eligible slot branches out of this scan. Later slots are not
   examined during that pass.
5. Only after all six slots remain ineligible does the scheduler read `$001B`
   and loop while bit 7 is clear. When bit 7 is set, `$CAB2–$CAB6` masks it
   off with `$7F`, stores the remaining low seven bits, and jumps back to
   `$CA97`.

The diagnostic model in
[`rom_gameplay_scheduler_scan_model.gd`](../../../tools/diagnostics/rom_gameplay_scheduler_scan_model.gd)
accepts six ready/delay bytes and the current `$001B` byte. It evaluates one
bounded source scan and reports one of: initial dispatch, yielded resume, wait
for bit 7, or clear bit 7 and rescan. It does not synthesize a following NMI
or assume how many source scans fit in a frame.

## Trace-only ordering and NMI observations

The independent observation is the muted two-pass FCEUX trace in
[`first_command_task_boundary_20261028_070655_utc/`](../../diagnostics/first_command_task_boundary_20261028_070655_utc/).
It starts from a signature-verified anonymous checkpoint at source frame 8399
and traces frames 8400–8953. Both passes match the retained normalized event
and write hashes in `validation.json`; each pass contains 6,081 selected task
events and 62,357 watched writes.

The focused verifier checks the two passes' scheduler event and `$001B`
write projections independently. It confirms these observed examples:

- Frame 8460: initial dispatch hooks appear for `$01`, `$05`, then `$09`.
- Frame 8461: the scheduler latch clear is followed by resume hooks `$01`,
  `$05`, `$09`. In that frame `$C7F0` writes `$001B: $00→$80` before
  `$CAB6` writes `$80→$00`.
- Frame 8893: after the current `$01/$05/$09` task resumes, the newly seeded
  callback slot `$15` reaches its first-dispatch hook. At frame 8894 the trace
  records its yielded-resume hook.
- The route replay contains 493 `$C7F0` set writes and 493 `$CAB6` clear writes
  from frames 8461–8953. This is evidence for this captured route and input;
  it does not establish a universal NMI or scheduler cadence.

These hook sequences are observations from this replay. The ordering of all
six scan positions and the branch semantics above come from the ROM bytes,
not from the trace. The trace does not expose every skipped-slot read and is
not used to initialize model state.

## Focused verification

Run:

```sh
godot --headless --path . --script tools/diagnostics/verify_rom_gameplay_scheduler_scan_model.gd
```

Godot 4.7.2 passed. The verifier covers the ROM hash and preserved-span
provenance, all five source-relative branch targets, six scan bases, zero and
`$FF` records, finite delay decrement/resume, first-eligible-slot priority,
post-scan NMI gating, bit-7-only clearing, and the matched trace projections
from both passes. This checks the isolated model and evidence; it is not a
full CPU/scheduler emulation or production-route verification.

## Remaining inputs for live route integration

The model is not yet enough to safely drive `KickoffRouteRuntime`. A live
source-owned scheduler still needs:

- The producers and lifetimes of all six task records, including task creation
  and retirement, not only a manually supplied ready/delay byte. The route
  also has the separate `$0011` bank-`$18` worker.
- The shared 6502 stack page and exact saved SP, return/continuation bytes,
  current registers, and mapper bank pair at each task seed, yield, resume,
  and finish. Delay values alone cannot reconstruct the suspended caller.
- The source events that set `$001B.7`, the mode that selects the NMI path,
  and the actual points at which scans resume. The trace's per-frame writes
  must not become a frame-based runtime schedule.
- The bank-`$10` scenario continuation and earlier callback history that
  produce the incoming shared `$05CD` state before `$8327`; task `$15`'s
  callback is not a standalone route event.

The smallest safe next integration boundary is an explicit ROM-derived event
interface for task seed/yield/resume/finish plus NMI-ready transitions, carrying
the live task records and shared CPU stack/mapper context. Until the route can
produce that state from its own decoded source transitions, this six-slot
model remains a diagnostic verifier only. Do not feed endpoint RAM/PPU data,
captured task records, or elapsed-frame constants into the production route.
