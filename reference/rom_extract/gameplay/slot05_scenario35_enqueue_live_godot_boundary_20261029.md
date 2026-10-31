# Live scenario-$35 enqueue route boundary — 2026-10-29

## Result

The production Godot route now reaches the ROM-selected scenario-$35 producer
after the live slot-$05 descriptor-row path. Its bounded worker executes the
`$DAD1->$DAD8->$DADA->$CBB0` branch and stops at the first unresolved read at
`$CB0F`. The scheduler applies the verified slot-$05 save and selects slot
`$09`. The focused route verifier passes.

This proves the route to the slot-$09 pre-dispatch boundary. It does not execute
the active `$0516=$80` slot-$09 scenario reader or prove visible field output.

## Source and state checks

- ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- Worker source manifest SHA-256: `d3f5ba788ea93fb02c6678f88efff9fe19aa303d19440b89c88ad81907a539ad`.
- The worker executes the checked `$DAD1-$DAD8`, `$DAD8-$DADC`, and
  `$CBB0-$CBC1` source spans with recorded hashes in their manifests.
- Live `$0629=$00` takes the `$DAD6->$DAD8` scenario enqueue branch.
- ROM source writes `$0518=$35` at `$CBB0`, `$0516=$80` at `$CBB5`, and
  `$0005=$00` at `$CBBA`. The `$0005` store clears the active slot-$05 ready
  byte before the verified `$CBBE->$CB0F` save call; the scheduler admits only
  this exact same-slot write from this validated transition.
- The worker reaches `$CB0F` with SP `$4C`, mapper banks `$1C/$1D`, and RAM
  `$0515-$0518 = 80 80 00 35`; `$0629` remains `$00`.
- The scheduler saves slot `$05` and selects slot `$09` with its own saved bank
  pair `$18/$19`. The selected task's mapper snapshot is taken from that slot's
  pre-dispatch boundary, not copied from slot `$05`.

## Verification

Ran:

```text
godot --headless --path . --script res://tools/diagnostics/verify_rom_slot05_live_ed01_row_bbe3.gd
```

Result: exit code 0. It replays the focused bounded route from the ROM-derived
fresh-match context, validates the source spans and queue writes, then confirms
the slot-$05 `$CB0F` save and slot-$09 selection. It is not a visual or audio
fidelity comparison.

## Next boundary

Resume the selected slot `$09` with the live `$0516=$80`, `$0518=$35`, and
`$0519` state. Integrate the hash-checked `$EC08-$EC74` path, scenario-$35
`$F9 EB 44` operand and `02 3A 8F 73` event record, and source-owned slot-$15
seed. Stop before dispatching slot `$15` unless the scheduler selects it.
Evidence: [scenario-active source audit](slot09_scenario_active_ec10_audit_20261029.md).
