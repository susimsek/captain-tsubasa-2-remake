# First action menu ROM data export

This folder contains source-byte exports for the first fresh-match action
window and its player/status panel. The export reads the supplied ROM only;
captured screen pixels and audio are not used as source data.

## Source and rebuild

- ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`
- PRG bank window: bank `$18`, CPU `$8000–$BFFF`, file offset
  `0x030010 + (CPU - 0x8000)`.
- Rebuild: `python3 tools/gameplay/extract_first_action_menu_rom_data.py`
- Machine-readable export: [`menu_rom_data.json`](menu_rom_data.json).
- Raw descriptor and text bytes remain in this directory as `.bin` files.

The descriptor pointer table begins at CPU `$B3CF` (file `0x0333DF`). Entry
`$02` resolves to `$B47D` / file `0x03348D`; entry `$03` resolves to `$B48A` /
file `0x03349A`. Target-ROM renderer dispatch and context tables select these
IDs on the fresh left-team action-menu path; see
[`first_action_menu_input_rom_trace_20261027.md`](../../first_action_menu_input_rom_trace_20261027.md).

Each descriptor has a 9-byte header followed by a count of 4-byte text-row
records. The last header byte equals the row count. Header bytes 2 and 3 match
the observed panel dimensions (8×5 and 12×10 tiles). Descriptor bounds are
checked against the next ROM pointer-table entry. Row coordinate bytes are
preserved without assigning semantics in this raw export. Their renderer
meaning is decoded separately in
[`menu_renderer_algorithm_audit.md`](menu_renderer_algorithm_audit.md). Each
text source is read through its `$FC` terminator; `$E0` and `$E1` are retained
as dynamic player-name/position and stat substitutions respectively.

The window border family at CPU `$8D9E` / file `0x030DAE` is:

```text
9C A8 9D
AA 00 AB
9E A9 9F
```

The manifest expands this 3×3 family into relative grids using each descriptor's
width and height. These are ROM tile IDs, not rendered image assets. The four
status labels are stored with their unchanged ROM character bytes and source
addresses in the manifest: `Enerji`, `Çalım`, `Pas`, and `Şut`. `Çalım` and
`Şut` are Turkish descriptive aliases for the matching source tile sequences;
the raw bytes are preserved separately.

## Evidence limits

- The `$02` prompt row bytes begin `1B 20 58 6D 64 69 3F FC`; the custom font
  tile sequence is preserved without speculative transliteration.
- The `$03` first row contains `$E0`; its player name/position must come from
  match state. The four status rows include `$E1` stat selectors and require
  live energy/stat values.
- This raw-data export does not itself decode screen origin, renderer
  coordinates, transfer-queue timing, or dynamic substitutions; use the
  separate renderer audit for byte-verified layout findings. Neither artifact
  alone is a completed Godot menu scene.
- `kickoff_select_test_20261027` PPU/RAM captures remain comparison evidence;
  no screenshot or captured WAV is packaged here.
