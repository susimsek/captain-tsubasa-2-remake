# KICK OFF cutscene timing: ROM handlers and frame-edge observations

## Scope and evidence

- Supplied Turkish ROM SHA-256:
  4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097.
- Cutscene 1/2 byte-indexed streams are the verified 901-byte and 142-byte
  records in assets/gameplay/rom_logic/kickoff_cutscene_01_events.json and
  kickoff_cutscene_02_events.json.
- Frame-edge RAM snapshots come from the muted FCEUX 2.7.0 route capture
  reference/diagnostics/kickoff_select_test_20261027/ram/, source frames
  4693–9042. Per-frame RAM snapshots span the route and include $001E (new-button edge mask) and script pointer $004D/$004E.
  Input events are recorded in
  kickoff_first_command_menu_trace_20261027.md.
- The capture's PC hooks were only $80E6, $83DC, and $A626. It did
  not hook interpreter dispatch $84E7, command handlers $85C4/$87CB/
  $8837, $9FA8, or writes to $004D/$004E. The RAM snapshots give
  frame-boundary brackets, not within-frame handler cycles.

## ROM-backed command timing

The shared bank-0 command vectors are at CPU $8545 (file 0x000555).
The target bytes confirm these relevant handler entries:

| Command | ROM handler | Source behavior |
|---|---|---|
| $EB | vector word $85C3 → entry $85C4, file 0x0005D4 | Calls $89A3; that loop yields with $9FA8(A=1) and checks newly pressed $001E & $80 each tick. It has no timeout and waits for a fresh A edge. On release it calls $88B1 before returning. Full routine bytes and controller-edge proof are in reference/rom_extract/intro/eb_input_wait_trace.md. |
| $F6 nn | vector word $87CA → entry $87CB, file 0x0007DB | Bytes 88 20 9A 89 C8 B1 4D 20 A8 9F A9 02 4C 79 88: after the shared state helper, it reads the operand and yields through $9FA8 for that count, then consumes two script bytes. Thus F6 B4 requests 180 cooperative scheduler ticks; do not convert the count to exact display/pixel time without tracing its NMI/task edges. |
| $FC | vector word $8836 → entry $8837, file 0x000847 | Calls $899A, yields through $9FA8(A=4), advances the script pointer by exactly one byte, then resumes. No inline payload. The opcode audit and source bytes are in fc_kickoff_cutscene_opcode_audit_20261027.md. |
| $D8–$DF | table at CPU $88E6, file 0x000AF6 | Compact pause operands are 1,10,20,40,60,80,120,240 cooperative ticks. |
| $FE / $FF | entry $8862 / $8870 | No reachable $FE occurs in either verified linear stream. The end-of-stream $FF returns the cooperative task; neither natural $FF was observed in this route capture. |

The counters are worker/scheduler ticks. The scheduler is serviced from the
frame/NMI loop, so idle-path examples align with source-frame deltas, but
handler start/end CPU cycles and same-frame NMI ordering are not in this
capture.

## Frame-edge checks from the existing route

These are RAM observations, not PC-hook claims. The pointer column shows the
command address while blocked/being handled, then the first observed next
pointer. The listed input edge is the one-frame A press in the same route.

| Stream command | Pointer at frame edge | Next pointer observed | Input / frame delta |
|---|---:|---:|---|
| ID 1 DD (80-tick compact pause) | $A2A8 at frame 4719 | $A2A9 at 4799 | 80-frame difference, matching the table count on this route. |
| ID 1 FC | $A2BA at 5000 | $A2BB at 5004 | 4-frame difference, matching the handler's $9FA8(A=4). |
| ID 1 FC | $A2C4 at 5076 | $A2C5 at 5080 | 4-frame difference. |
| ID 1 FC | $A2D5 at 5208 | $A2D6 at 5212 | 4-frame difference. |
| ID 1 EB | $A2E1 at 5300 | $A2E2 at 5446 | New A edge at frame 5443 ($001E=$80); pointer is still at $A2E1 at frame 5445. |
| ID 1 EB | $A2F8 at 5618 | $A2F9 at 5746 | New A edge at frame 5743; pointer is still at $A2F8 at frame 5745. |
| ID 1 EB | $A326 at 6081 | $A327 at 6196 | New A edge at frame 6193; pointer is still at $A326 at frame 6195. |
| ID 1 EB | $A343 at 6412 | $A344 at 6496 | New A edge at frame 6493; pointer is still at $A343 at frame 6495. |
| ID 1 EB | $A384 at 6968 | $A385 at 7096 | New A edge at frame 7093; pointer is still at $A384 at frame 7095. |
| ID 2 F6 B4 (180 ticks) | $A64E at frame 8353 | No natural successor observed | Select is pressed at frame 8443; pointer later resets to $0000 at 8459. This is a route skip/termination, not evidence that 180 ticks elapsed. |

The three-frame gap between each A edge and the next pointer snapshot is not
assigned to the EB poll itself: the handler performs follow-up work after the
input wait, and the capture has no handler or RAM-write cycle hooks. The
frame-edge evidence establishes “waits until A is newly pressed, then resumes”
but not the exact subframe release or helper completion cycle.

Cutscene 1's stream tail ($A3A2 onward, including both short $F6
commands and two 180-tick waits) is bypassed by the route's Select input at
7243: the previous frame-edge pointer is $A39B, and the script switches
away from that stream. Cutscene 2's natural $FF is likewise not reached.
At frame 8353, the pointer is still at its first observed F6 B4; Select is
pressed at 8443 and the pointer later resets. Whether this cancels that wait
or takes a separate skip path is not established. This capture does not
measure completion timing for any $F6 or either $FF.

## Executable clock model and remaining trace

A ROM-driven Godot runner should keep the verified event pointer and a
cooperative-tick scheduler:

1. $FC: hold the current byte through a 4-tick helper wait, then advance by
   one byte.
2. $EB: repeatedly yield one tick and test the fresh-A edge; remain blocked
   indefinitely until it arrives, then run the post-wait $88B1 work.
3. $F6 n: yield for n scheduler ticks, then advance by two bytes.
4. $D8–$DF: yield the ROM-table count, then advance by one byte.
5. $FF: end the cutscene task. Do not invent $FE branches for these
   streams; byte-verified parsing found none.

To turn the frame brackets into source-cycle boundaries, run one muted,
same-input instrumented replay with execution hooks at $84E7, $85C4, $87CB,
$8837, $8870, and $9FA8; log the decoded byte at $4D:$4E, writes to
$4D/$4E, $001E, scheduler slot/countdown state, MMC3 bank, and CPU-cycle offset
from each frame start. Keep the existing Select route as one pass, then a
second pass that supplies A only at each EB wait and does not Select-skip,
so both 180-tick F6 waits and natural FF exits are exercised. This task did
not run/control the emulator.

## Isolated Godot command VM

`scripts/gameplay/kickoff_cutscene_command_vm.gd` loads the two byte-indexed
manifests, pins their manifest SHA-256, checks the recorded supplied-ROM SHA
and pinned preserved execution-stream SHA-256, verifies every event's raw bytes, CPU/file address and contiguous
boundary, and stops only at the final `$FF`. The source stream ranges are
`$A2A1–$A625` / file `0x0062B1–0x006636` (901 bytes) and
`$A626–$A6B3` / file `0x006636–0x0066C4` (142 bytes); the second file-range
end is exclusive. Every decoded record is sent through `presenter_event`;
presentation-only records also emit `unsupported_opcode`. Unknown event kinds
and altered source-stream hashes fail with `vm_error`.

The scene-facing API is `start_cutscene(id)`,
`advance_scheduler_tick(pressed_edges)`, `cutscene_finished(id)` / `done(id)`,
and `text_glyph_requested`. Inputs are newly pressed NES bits; A is `$80`.
Timed waits consume one caller-supplied cooperative scheduler tick each:
`$D8–$DF` use 1/10/20/40/60/80/120/240 ticks, `$F6 n` consumes n ticks then
its two source bytes, `$FC` consumes four ticks then its one source byte, and
`$EB` blocks until a fresh A edge. Text-speed delays use active `$55` scheduler
ticks after every glyph, including the last glyph before the next command.
Route RAM frame 4708 records `$55=8` while ID 1 is active; frame 8124 records
`$55=8` at the ID 2 entry, before its F2 changes to 2 and 8. The VM starts both
streams with this observed route value.

The focused replay is
`godot --headless --path . --script tools/diagnostics/verify_kickoff_cutscene_command_vm.gd`.
It replays both event streams, checks byte/event boundaries and wait-completion
ticks, text glyph byte order, the fresh-A block, `$F6 $B4`, `$FF`, and rejection
of altered hashes/unknown event kinds. It passes on Godot 4.7.2. It models
cooperative scheduler ticks only: same-frame CPU/NMI ordering, exact input
release subframe, PPU pixel timing and visible raster phase remain unresolved.
The VM forwards presentation-only commands without inventing their visual or
audio effects, and it does not implement `$EB`'s post-wait `$88B1` helper work.
