# First fresh callback and `$05CD` source component — 2026-10-28

## Result

A bounded Godot source component now derives the first fresh-route callback
prefix and its incoming `$05CD` value from preserved ROM bytes. The ROM setup
routine `$AA06` clears `$0468–$06FF` (664 bytes), including `$05CD/$05CE`;
therefore the first `$35/$3A` map callback enters `$8327` with `$05CD=$00`.
Applying the already byte-checked `$8327` placement formula to that source
value projects `$05CE=$00` and next `$05CD=$A0`.

This is a source projection, **not a live callback-task execution**. The
initial source scheduler scan still selects root slot `$01`; its remaining
body/continuations and NMI releases are not composed with callback slot
`$15`. The callback handler is not entered by this component, and the
`$856F → $C515 → $CB0F` worker yield/resume is not run. `KickoffRouteRuntime`
has not been wired to this component.

## Source path

The fresh KICK OFF setup `$A2AF` loads `A=$98`, `X=$02`, points `$EC/$ED` at
`$0468`, then calls `$AA06` (bank `$02`, file offset `0x004A16`). The preserved
25-byte helper is hash-checked before a narrow instruction interpreter steps
its actual branches and indirect stores. `$AA06` increments X to `$03`. Its
first pass decrements A from `$98` to zero and writes 152 bytes. The outer
`DEX/BNE` branches back to `$AA0B` (`PHA`) without reloading A. Each remaining
pass therefore decrements from zero through a complete byte wrap and writes
256 bytes. The total is `152 + 256 + 256 = 664`, from `$0468` through `$06FF`,
with the final pointer `$0700` (`$EC=$00`, `$ED=$07`). This corrects the old
write-plan claim of three `$98`-byte passes / 456 bytes.

Scenario `$35` is read from the preserved, hash-checked bank-$10 stream. Its
first record at byte offset 3 is `02 3A 8F 73`, separating callback `$3A`
from actor-animation `$8F`. The callback pointer-table entry at `$886A` is
`F3 89`; the next valid boundary at `$886C` is `F6 89`. The bounded stream
`02 00 42` at `$89F3` selects inline-dispatch index zero, whose preserved ROM
vector at `$81A7` resolves to `$8327`.

## Implementation and verification

- Source projection: `scripts/gameplay/rom_first_fresh_callback_source_component.gd`
- Added callback source spans and hashes:
  `reference/rom_extract/gameplay/first_command_field/callback_dispatch/manifest.json`
- Focused verifier:
  `tools/diagnostics/verify_first_fresh_callback_source_component.gd`
- Corrected handoff plan:
  `scripts/gameplay/rom_fresh_match_handoff_executor.gd`
- Corrected plan verifier:
  `tools/diagnostics/verify_rom_fresh_match_handoff_executor.gd`

Godot 4.7.2 verification:

```text
godot --headless --path . --script res://tools/diagnostics/verify_first_fresh_callback_source_component.gd
PASS: first fresh callback source projection derives $05CD=0 and $8327->$05CD=$A0 from ROM bytes.
LIMIT: source plan only; root task completion, slot-$15 dispatch, worker yield/resume, and live route timing remain unmodeled.

godot --headless --path . --script res://tools/diagnostics/verify_rom_fresh_match_handoff_executor.gd
PASS: fresh KICK OFF cutscene-2 completion emits hash-checked cleanup, audio, zero-fill, mapper, and pending task-write plans.
LIMIT: C557 is reached only after four named Godot-side helper results; no helper bytecode, live RAM, or general 6502 is executed.
```

The trace was not used as a runtime input. Its `$05CD/$05CE` observations are
independent validation only. This component does not prove callback dispatch,
PPU timing, worker completion, or the first command-menu endpoint.
