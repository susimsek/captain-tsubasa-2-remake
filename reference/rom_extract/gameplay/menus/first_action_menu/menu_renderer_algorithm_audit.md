# First action menu: bank-$18 renderer audit

This is a separate follow-up to the original raw menu-data export. It recovers
the descriptor layout and transfer-packet algorithm from the supplied Turkish
ROM bytes, then uses the frame-8953 RAM/PPU snapshots only as validation. The
original descriptor and row `.bin` exports are unchanged.

## Source and reproducible audit

- Target ROM: `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`
- Whole-file SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`
- Bank `$18` file mapping: `0x030010 + (CPU address - 0x8000)`.
- Fixed CPU `$C000–$FFFF` mapping: `0x03C010 + (CPU address - 0xC000)`.
- Rebuild packet audit and JSON: `python3 tools/gameplay/audit_first_action_menu_renderer.py`
- Verify the reusable Godot packet API: `godot --headless --path . --script tools/diagnostics/verify_first_action_menu_rom_layout.gd`
- Machine-readable byte hashes and validation results:
  [`renderer_packet_audit.json`](renderer_packet_audit.json).

The audit checks the ROM SHA and hashes every relied-on code/table window,
including the `$8852` renderer entry, its `$88B9` packet producer, the `$8986`
text parser, `$89FA` dynamic dispatch, `$8CA5` stat substitution,
`$8CDC–$8D9D` player-line expansion, the `$8D9E` window table, the descriptor
style byte at `$B3BD`, bank entry `$800C`, and fixed-bank helper/wrapper stubs.
This avoids treating the pinned English disassembly's omitted `$885E–$887C`
bytes as target-ROM facts.

## Renderer inputs and descriptor semantics

The target bank-$18 table at `$B3CF` maps descriptor `$02` to `$B47D` and `$03`
to `$B48A`. The fixed-bank wrapper `$EF7F` places the descriptor ID in both A
and Y before calling bank entry `$800C`, which jumps to `$8851` and enters the
renderer at `$8852`. `$8852` doubles A to index the descriptor pointer table.
The actual target bytes `$885E–$887C` use Y as a packed two-bit frame-family
selector: `Y >> 2` chooses a byte at `$B3BD`, and `(Y & 3)` selects one of its
two-bit fields. The selected family number is multiplied by nine and stored in
`$05C6`. For descriptor IDs `$02` and `$03`, the selected family is 0, so the
frame tiles are exactly the first nine bytes at `$8D9E`:

```text
9C A8 9D
AA 00 AB
9E A9 9F
```

Descriptor `$03` is:

```text
32 22 0C 0A 00 01 0C 09 05
01 02 21 BC
03 01 23 BC
05 01 2E BC
07 01 39 BC
09 01 44 BC
```

The nine-byte header fields used by this renderer are:

| Offset | Byte | Meaning established from target code |
|---:|---:|---|
| 0–1 | `32 22` | Base PPU address `$2232`, the start of progress row 0 at nametable row 17, column 18. |
| 2 | `0C` | Transfer packet payload length, 12 tiles. |
| 3 | `0A` | Inclusive last progress row. The producer emits rows 0 through 10. |
| 4 | `00` | Base tile column offset for the frame/text data inside the packet. |
| 5 | `01` | Top-border progress row. |
| 6 | `0C` | Window frame width, 12 tiles. |
| 7 | `09` | Offset from the top edge to the bottom edge; bottom row is progress 10. |
| 8 | `05` | Number of four-byte text-row records. |

The progress-to-PPU-address conversion in `$88C8–$88E5` is equivalent to
`base_address + progress * 32`. Progress row 0 is blank space above the
visible panel. Progress 1 draws the top edge, progress 2–9 draw the side
edges, and progress 10 draws the bottom edge. Thus the visible frame occupies
nametable rows 18–27, ten rows high, and columns 18–29, twelve tiles wide.

Each text record is `[relative_row, column, pointer_low, pointer_high]`. The
first descriptor's actual visible row coordinates are 1, 3, 5, 7, and 9;
columns are 2 for the player line and 1 for the four status rows. They map to
nametable rows 18, 20, 22, 24, and 26. The routine also probes the preceding
row with a suppression flag; in this first panel, ROM text/digit output is
suppressed there. Static text prefixes at the exact record rows were compared
against the captured nametable.

The producer emits two progress rows per queue wait: first at the current
`$05C5`, then at the next row after the first call increments `$05C5`. On the
last row, the first call compares progress 10 with the descriptor's inclusive
limit 10 and returns without the second call. Therefore at the endpoint
`$05C5` is 11 while the final record still present at `$04A5` was generated for
progress 10.

The ROM-only progress-10 packet candidate is:

```text
0C 72 23 9E A9 A9 A9 A9 A9 A9 A9 A9 A9 A9 9F
```

The header is `[payload length, PPU address low, PPU address high]`; twelve
tile IDs follow. The frame row is formed from the bottom triplet `$9E/$A9/$9F`
with ten center tiles. No captured bytes are used to construct this candidate.

## `$E0` and `$E1` substitutions

The text parser at `$8986` treats bytes below `$E0` as literal tile IDs and
dispatches `$E0+` through the ROM jump table. For this descriptor:

- `$E0` at `$BC21` reads the current-player selector from RAM `$0441`. The
  handler normalizes it to the 11-player position table at `$8D04`, emits the
  two position tiles, a blank, and the selected player's name. The name comes
  from the player's ROM-backed record/string lookup and is padded to at least
  five name tiles. The current player and resulting name tiles are caller
  state; they are not static menu art.
- `$E1` at `$BC23/$BC2E/$BC39/$BC44` consumes the following selector byte.
  Selector 0 obtains a 16-bit energy value from the selected player record at
  offsets +1/+2. Selectors 3, 2, and 1 request the status values associated
  with Çalım, Pas, and Şut. The routine masks the selector to 7 bits; for
  selectors 7–23 it adds 8 when ball-height `$044E` is not 1, then calls the
  bank-switched stat evaluator through `$C527`.
- Decimal formatting is handled by `$8C55–$8C9F`: tile IDs are digit + `$33`,
  digits are emitted least-significant first while the destination moves
  backward, so values are right-aligned after the label. Leading zeroes are
  omitted.

The renderer code and helper stubs are byte-hashed against this ROM, but the
complete `$F30F` player-name lookup and bank-$1C stat evaluator are outside this
small layout audit. A runtime caller must supply `$E0`'s position/name tile
sequence and the resolved integer for each `$E1` selector. No frame-8953 RAM
values have been baked into runtime data.

## Godot API

[`first_action_menu_rom_layout.gd`](../../../../../scripts/gameplay/first_action_menu_rom_layout.gd)
provides `FirstActionMenuRomLayout.build_packets(descriptor, frame_family_tiles,
row_streams, dynamic_token_resolver)`. It returns ordered per-row dictionaries
containing the progress index, PPU address, packet bytes, tile row, completeness
flag, and missing dynamic inputs. The callback receives `(0xE0, -1)` and returns
an `Array` or `PackedByteArray` of player-line tiles; it receives `(0xE1,
selector)` and returns the integer value. Missing dynamic values are explicit,
so a partial static frame cannot be mistaken for a complete menu. The helper
does not read the ROM or emulator at runtime and does not depend on a field
background renderer.

The focused Godot diagnostic
[`verify_first_action_menu_rom_layout.gd`](../../../../../tools/diagnostics/verify_first_action_menu_rom_layout.gd)
checks the 11 generated descriptor-$03 rows and asserts progress 10 targets
`$2372` with the exact bottom-border packet above. It does not exercise dynamic
player/stat callbacks or claim full menu rendering.

## Validation results and limits

`python3 tools/gameplay/audit_first_action_menu_renderer.py` passed against the
supplied ROM. The generated progress-10 packet equals all 15 bytes at captured
RAM `$04A5` in frame 8953, and the twelve bytes at captured PPU `$2372–$237D`
equal the generated payload. The frame-8938 PPU sample has twelve zero bytes at
`$2372–$237D`; all twelve change to the candidate border tiles by frame 8953.
Across the panel bounds (rows 18–27, columns 18–29), 65 cells change between
those two PPU snapshots. The four ROM-static label prefixes also match the
captured PPU rows. Captures are comparison-only evidence.

This audit proves descriptor interpretation and the frame/text row packet
layout for this menu context. It does not reconstruct the field background,
RGB palette selection, live CHR bank/raster state, packet-consumer timing,
first visible pixel, player-name output, or the bank-$1C stat values. The
separate frame-8953 mapping note documents the remaining CHR/palette evidence
and limits.

## Follow-up: observed queue-commit frames (2026-10-28)

The existing muted, two-pass PPU bus replay from the verified source-frame-8399
FCEUX checkpoint adds a source-frame schedule for the menu's nonzero row
transfers. The trace is
[`first_command_ppu_bus_trace_20261027_181102_utc`](../../../../diagnostics/first_command_ppu_bus_trace_20261027_181102_utc/README.md);
it records each `$2007` write, modeled PPU address, source frame, and CPU-cycle
label, but not PPU scanline/dot or menu-renderer PC/progress RAM.

- Descriptor `$02`'s six progress rows are committed two per frame on frames
  8937–8939, beginning at PPU `$224A` and ending at `$22F1`.
- Descriptor `$03`'s progress rows are committed in six batches on frames
  8940–8945: progress 0 (blank) plus 1, then pairs 2–3, 4–5, 6–7, and 8–9,
  then final progress 10. The first visible row starts at PPU `$2252`; the
  bottom-border packet `$2372–$237D` is committed at frame 8945, cycle offsets
  664–829.
- The final menu-row PPU write is therefore observed 52 source frames after
  the B edge at frame 8893. This is a bus-commit observation for that exact
  replay, not the first displayed pixel or a reusable runtime delay.

This narrows the menu transfer itself to nine batches, with two progress calls
per batch except the final progress-10 call. The expanded muted trace
[`first_command_menu_wait_and_stamina_trace_20261028.md`](../../first_command_menu_wait_and_stamina_trace_20261028.md)
adds the handoff and source queue state: B is at frame 8893; `$D575` is entered
at frame 8908; `$D5C3` at 8926; bank-$18 `$8852` starts descriptors `$02/$03`
at frames 8935/8938; the first row is in `$88B9` queue state at frame 8936.
`$0515/$05C5/$05C6` identify the nine queue cycles on frames 8936–8944. The
inclusive B-to-first-queue interval is 44 source frames for this recorded
route. PPU writes commit the visible rows on frames 8937–8945, so the measured
B-to-final-commit interval is 52 frames. Neither interval gives the first
displayed pixel: the FCEUX bus trace has no visible scanline/dot capture. These
frame observations validate this route only; Godot must execute the decoded
handoff and progress/queue state instead of substituting 52 or 60 ticks.
