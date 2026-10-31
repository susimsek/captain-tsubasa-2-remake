# Slot-$05 `$EE` Yield Through the Slot-$09 Root Cycle — 2026-10-29

## Result

The live route continues from the slot-$09 pre-dispatch boundary created by the slot-$05 `$EE 00 FC` row and its `$CB0F` save/scan. Before dispatch, the current RAM reads were `$0539=$00`, `$0516=$00`, `$05D2=$00`, `$0532=$00`, `$0534=$00`, `$0536=$00`, and `$052E=$00`. Those live zeros select the existing decoded zero branches; the route does not seed these bytes.

The scheduler restored slot `$09` at `$EB8B` with A/X/Y=`$00/$00/$05`, SP=`$7A`, and banks `$18/$19`. The `$EB8B` prefix read `$0516` at `$EC08` and took its zero return through `$EC0F`; it read `$05D2` at `$ED85` and took its zero return through `$ED8A`. The worker inputs `$0532/$0534/$0536` each selected the existing zero branch, returning to `$EBB3`, `$EBC5`, and `$EBD7`. The live `$052E=$00` root branch then reached `$CB0F`.

The second save produced slot-$09 record `01 76 18 19` and returned to the scheduler scan. The scan checked empty slots `$0D`, `$11`, and `$15`, then stopped at `WAIT_FOR_NMI_READY`, cursor `$19`. No further NMI, selected task body, or visible match output was produced.

## Source state and behavior

This transition starts from the actual slot-$09 record produced by the preceding slot-$05 scan: `00 76 18 19`, ready delay zero, pending yielded resume, context PC `$CB0F`. The scheduler dispatch derives `$EB8B` and restores its stack from that record. The continuation consumes the live dispatched RAM, stack, and mapper state. Existing components validate their respective ROM manifests and reject unsupported branches.

| Gate | Live byte before slot-$09 dispatch | Selected source path |
| --- | ---: | --- |
| `$0539` | `$00` | `$EB92` zero branch continues to `$EB99` |
| `$0516` | `$00` | `$EC0D` zero branch returns at `$EC0F` |
| `$05D2` | `$00` | `$ED88` zero branch returns at `$ED8A` |
| `$0532` | `$00` | `$86F8` returns to `$EBB3` |
| `$0534` | `$00` | `$8779` returns to `$EBC5` |
| `$0536` | `$00` | `$87E6` returns to `$EBD7` |
| `$052E` | `$00` | `$EBD7->$EC05->$EB86->$CB0F` |

The slot-$09 continuation prefix and the three bank-$18 zero-branch executors were already backed by hash-checked source packages. No new ROM bytes or manifests were needed for this transition. The existing `$CB0F` and scheduler scan model is source-semantic, not cycle-accurate emulation.

## Verification

Focused verifier: `tools/diagnostics/verify_rom_slot05_ee_to_slot09_root_cycle.gd`.

Run:

```sh
godot --headless --path . --script res://tools/diagnostics/verify_rom_slot05_ee_to_slot09_root_cycle.gd
```

It passed under Godot 4.7.2. The verifier reaches the live `$EE` row, applies the slot-$05 save/scan, reads the seven gate bytes from the selected slot-$09 RAM snapshot, checks the `$EB8B` returns and worker branch inputs, checks the second slot-$09 save record, and confirms the wait boundary without dispatching another task.

## Limits

The nonzero `$0516` scenario-active and `$05D2` branches remain unsupported in this live route. A different trace interval has evidence for later nonzero values; this result only establishes the current zero-input path. The route still does not render the first command menu or establish same-input visual/audio parity. It does not provide physical NES timing evidence.
