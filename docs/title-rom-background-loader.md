# ROM title background loader

`RomTitleBackgroundLoader` decodes title background ID `$17` from the
byte-preserved ROM extracts and prepares PPU write packets. It does not own
the game's cooperative scheduler, queue back-pressure, NMI consumer, MMC3
register writes, or visible raster timing. The title handoff runner supplies
the capture-anchored packet grouping and next-frame commit schedule, but not
the original CPU execution of those systems.

## Byte-verified sources

- Target ROM SHA-256:
  `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- `$806A → $8AF7` starts title selection, ID `$17`, at source frame 4664; the
  call resumes at `$806F` on frame 4690 after the queued background load. The
  selected record is bank 87 / file `0x00E383` (CPU `$A373`). Its 56 bytes are
  preserved in `reference/rom_extract/intro/background_17.bin` and described
  by `background_17_layout.json`.
- The record header selects 2-KiB CHR banks `$7C/$7E` (1-KiB banks
  `[124, 125, 126, 127]`), palette record `$01`, a 6-row by 8-column block
  field, and packed origin `$08` (source-derived tile origin `(0, 4)`, PPU
  `$2080`). Header byte `$81` has palette index 1 in its low six bits and page
  selector 1 in bit 7. Bank-0 `$8B4E` moves that selector to `$5B.0`; `$8EF0`
  adds `$1100` to the bank-8 block pointer when set. The `$00 $A0` trailer
  separately selects the `$80` special traversal; `$8C59` configures a six-row,
  eight-column walk with four-tile horizontal steps.
- The 48 row-major block IDs reference 31 distinct preserved 17-byte block
  records on the selected page. Each has one attribute byte and sixteen 2bpp
  tile IDs. Page-1 records are preserved as `block_XX_page_11.bin`; the base
  page is preserved separately as `block_XX.bin`. The layout records both
  source offsets and raw bytes, while `used_4x4_blocks` points to the selected
  page used by the Godot loaders.
- Palette record `$01` is preserved as
  `reference/rom_extract/intro/background_palette_01.bin`; it maps to ROM file
  offset `0x00D020` and contains 16 bytes.

The target ROM's full-file SHA and the record, block pages, and palette were
checked against those offsets during extraction. For block `$04`, selector 1
uses CPU `$B144` / file `0x011154` and begins `AA 00 00 00`; the complete
record is in the sidecar. The base-page record at `0x010054` is not used by
this title load. The ROM is not opened or needed by Godot at runtime; loaders
check the extracted files against the ROM-derived sidecar metadata instead.

## Packet model

`build_packets()` validates the ROM hash metadata and source-byte manifests,
then emits one attribute packet and four 4-tile row packets per block, in
row-major block order. The attribute packet is placed at the NES attribute
table cell matching the aligned 4×4-tile block origin; tile rows use the
corresponding nametable addresses. Each packet includes a three-byte queue
header estimate, matching the packet form already traced for the opening
loader.

For ID `$17`, the builder produces 240 packets (48 attributes plus 192 tile
rows), 816 payload bytes, and 1,536 estimated encoded queue bytes from the
selected page-1 records. Comparing those 816 bytes with the source PPU snapshot
at frame 4692 gives 815 matches; the sole difference is the expected `$7F`
cursor tile at `$220A`, overlaid on the background row at `$2208`. This
confirms the static selected-page layout and final nametable bytes. A later
silent CPU trace confirms all 48 block requests in exact ROM-record order, all
768 selected tile bytes copied into the `$05E8` queue, and all 48 selected
attribute bytes written there. The title-entry trace separately reconstructs
the same 240 `$05E8–$0627` queue packets, with matching lengths, addresses,
order, and payload; see
[`f8_00_sequence_trace.md`](../reference/rom_extract/intro/f8_00_sequence_trace.md)
and `reference/diagnostics/f8_special_mode_20261024_200815/`. The live source
payload and prior captured PPU destinations/order now agree. Exact subframe
NMI commit timing, raster composition, and Godot's post-correction render are
still open.

This loader is not a frame renderer. The handoff runner now stages the decoded
packets progressively and commits them on the modeled next-frame edge. CHR
bank switching, original queue-capacity yields, CPU NMI timing, OAM, scrolling,
and PPU raster effects still need source-timed implementation/comparison before
the title loader path can be called exact.
