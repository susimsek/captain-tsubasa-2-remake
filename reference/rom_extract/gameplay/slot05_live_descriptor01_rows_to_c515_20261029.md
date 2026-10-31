# Live Descriptor-$01 Rows Through `$C515` — 2026-10-29

## Result

The production Godot route dispatched the source-selected slot-$05 record
`00 46 18 19` at `$8889`. It executed descriptor-$01 row 2 at bank `$19:$BBE3`
(`ED 01 FC`), followed the live team-$00 name stream at `$F776`, then executed
row 3 at `$19:$BD9F` (`EE 01 FC`). The worker reached the real `$C515` yield;
the scheduler adopted its ordered writes and selected slot `$09`.

The focused run observed:

| State | Before dispatch | At `$C515` yield |
| --- | --- | --- |
| `$002A/$002B` | `00/00` | `00/00` |
| `$003E-$003F` text pointer | `9C BD` | `9F BD` |
| `$003C` | `B0` | `00` |
| `$0629` | `00` | `00` |
| `$04A5-$04AE` | `07 01 23 AA 00 00 00 00 00 AB` | same |
| Ordered RAM writes | — | 388 |
| Next scheduler slot | — | `$09` |

The two descriptor rows and team-name source span were all loaded from the
ROM-hash-checked worker manifest. The `$EE 01` handler path includes `$8B2F`
and the inline `$FC` return through `$8C52`. This establishes source execution
and scheduler adoption for this bounded route, not visible menu output.

## Provenance

- ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`
- Worker manifest SHA-256: `d3f5ba788ea93fb02c6678f88efff9fe19aa303d19440b89c88ad81907a539ad`
- `$ED 01 FC` row: bank `$19`, `$BBE3-$BBE5`, file offset `0x033BF3`, SHA-256
  `ff4579caac8640e812546cc7649a99a939843eb1f972ccb5c5b715278c5dbd47`
- `$EE 01 FC` row: bank `$19`, `$BD9F-$BDA1`, file offset `0x033DAF`, SHA-256
  `55535becc5335f960faf89b9118f0677f4a009dffd35466781512590f9f40291`
- Team-$00 stream: fixed bank `$1F`, `$F776-$F77B`, SHA-256
  `43d56de68e6197feddf34fcb5ebf127fbd8efb3c00b8fde7232e136a9056bdea`
- Both descriptor-row extracts already existed under
  `reference/rom_extract/gameplay/field_entry_window_01/`; no new raw extraction
  was needed.

## Verification and limits

Focused verifier:
`tools/diagnostics/verify_rom_slot05_live_ed01_row_bbe3.gd`

Command:

    godot --headless --path . --script res://tools/diagnostics/verify_rom_slot05_live_ed01_row_bbe3.gd

Result: PASS on Godot 4.7.2. The verifier rebuilds the live route through the
selected scheduler record, checks row hashes and handler/return PCs, confirms
the `$C515` yield, and confirms scheduler adoption followed by slot `$09`
selection.

This run does not prove physical NMI cadence, complete PPU state, visible field
or command-menu pixels, audio parity, or the later `$DAD1` return/scenario-$35
branch. The unchanged `$0629=0` means no scenario enqueue occurred in this
transition.
