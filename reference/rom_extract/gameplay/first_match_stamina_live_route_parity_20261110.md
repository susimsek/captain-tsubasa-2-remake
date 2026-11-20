# Live First-Match Stamina Update: Same-Input RAM Parity

## Result

The production fresh-kickoff route executes the ROM-derived asynchronous
`$D193 -> $E1F1 -> $E1F7 -> $E2BC` stamina update. At source frame 8863, all
eleven four-byte player records in the live Godot slot-$05 task RAM match the
same-input FCEUX RAM snapshot exactly. The update receipt reports holder player
`$08`, slot 6, energy 400 before the update and 397 after it.

This closes the earlier evidence gap that compared an isolated stamina
provider to FCEUX but did not compare the production route's worker output to
FCEUX RAM. Runtime state is still produced only by the ROM-derived Godot route;
the FCEUX snapshot is read by the diagnostic verifier for comparison.

## Pinned evidence

- ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- Input timeline SHA-256: `87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e`.
- FCEUX RAM reference: [`route_frame_008863.bin`](../../diagnostics/kickoff_select_test_20261027/ram/route_frame_008863.bin), 2,048 bytes, SHA-256 `7a49f4f6d36312a51a854e91d3258cf836f12cc53d01d8a2854d4b8200990589`.
- Record pointers: [`player_record_pointer_table_22.bin`](menus/first_action_menu/player_record_pointer_table_22.bin).
- Route verifier: [`verify_kickoff_recorded_input_path.gd`](../../../tools/diagnostics/verify_kickoff_recorded_input_path.gd), which asserts the receipt and all eleven record-byte comparisons at frame 8863.

## Compared records

The address comes from the ROM player-record pointer table. Godot's four-byte
record, the verifier receipt, and the same-input FCEUX RAM bytes are identical
for all rows:

| Slot | RAM address | Player ID | Energy | Record bytes |
| ---: | ---: | ---: | ---: | --- |
| 0 | `$0300` | `$02` | 400 | `02 90 01 00` |
| 1 | `$030C` | `$03` | 400 | `03 90 01 00` |
| 2 | `$0318` | `$04` | 400 | `04 90 01 00` |
| 3 | `$0324` | `$05` | 400 | `05 90 01 00` |
| 4 | `$0330` | `$06` | 400 | `06 90 01 00` |
| 5 | `$033C` | `$07` | 400 | `07 90 01 00` |
| 6 | `$0348` | `$08` | 397 | `08 8D 01 00` |
| 7 | `$0354` | `$09` | 400 | `09 90 01 00` |
| 8 | `$0360` | `$0A` | 416 | `0A A0 01 00` |
| 9 | `$036C` | `$01` | 748 | `01 EC 02 00` |
| 10 | `$0378` | `$0B` | 408 | `0B 98 01 00` |

## Reproduction

Run the recorded-input verifier from the project root:

```sh
godot --headless --path . --script res://tools/diagnostics/verify_kickoff_recorded_input_path.gd
```

It replays the pinned input through the ordinary Godot route, checks the live
stamina receipt against the eleven FCEUX records at frame 8863, and continues
to the unselected first command menu at frame 8953. No ROM, FCEUX, or captured
RAM is loaded into runtime state.
