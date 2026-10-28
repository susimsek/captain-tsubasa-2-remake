# First-Match Asset Byte Map

This note records static ROM mappings useful for the fresh-start route to the
first in-match command menu. It does not identify the live first-menu field
background, sprite descriptor, or active sprite CHR pages; those require the
separate same-input FCEUX capture.

## Source and verification boundary

- Supplied ROM: `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`
- SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`
- Size: 393,232 bytes (`0x60010`, including the 16-byte iNES header)
- Existing raw CHR extraction: `reference/rom_extract/chr_rom.2bpp`, SHA-256
  `721579f3a3dc2042534de98b24135371fc379958711a168a6861c989a10d85ad`
- The offsets below are absolute file offsets in that ROM. The 6502 routines
  and table bytes called out below were compared directly with the supplied
  ROM; names and semantics from the public disassembly remain labels, not raw
  ROM text.

## Player graphic-class lookup

The byte-checked routine at bank `$14`, CPU `$826A` (file `0x02827A`), reads
`con_plr_id` through the player-data pointer, indexes the byte table at CPU
`$88F0` (file `0x028900`), and stores the result in RAM `$0546`. The local ROM
bytes at `0x02827A` are:

```text
A0 00 B1 34 08 AA BD F0 88 28 D0 08 A6 3A E0 0B D0 02 A9 04 8D 46 05 60
```

`tbl_88F0` is a player-ID-to-graphic-class map. Relevant entries verified in
the supplied ROM:

| Player ID | Public disassembly label | Selector written to `$0546` | File offset |
| --- | --- | ---: | ---: |
| `$01` | Tsubasa | `$00` | `0x028901` |
| `$02` | Renato | `$0F` | `0x028902` |
| `$2B` | Carlos | `$0A` | `0x02892B` |
| `$2C` | Santamaria | `$09` | `0x02892C` |
| `$2D` | Jetorio | `$08` | `0x02892D` |

The names come from the annotated disassembly; the target ROM verifies the
IDs and selector bytes. The Japanese address memo independently points to the
player-graphics table around `0x28901`.

## How `$0546` selects sprite tile layouts

The shared sprite renderer is in bank `$16`. For each actor record it reads
the descriptor index from record offset `+$12` (CPU `$8084`, file `0x02C094`),
then indexes `tbl_8280_sprite_data` at CPU `$8280` (file `0x02C290`) to get a
sprite-layout stream. Control opcode `$03` branches within that stream using
`$0546`. The branch routine at CPU `$8175` (file `0x02C185`) compares the
selector with `$0C`, subtracts `$0C` once for selectors `$0C` and above, doubles
the result, and adds it to the stream cursor. This selects one of twelve
layout variants. The target-ROM bytes at `0x02C185` are:

```text
AD 46 05 C9 0C 90 02 E9 0C 0A 18 65 44 85 44 4C 64 81
```

Conditional decode for descriptor index `$00` and Tsubasa selector `$00`:

1. `tbl_8280_sprite_data[0]` at `0x02C290` is pointer `$842C`.
2. The branch stream at CPU `$842C` / file `0x02C43C` begins with opcode
   `$03`; selector `$00` chooses its first pointer, `$8445`.
3. That branch at CPU `$8445` / file `0x02C455` contains:

   ```text
   10 01 0C 28 10 29 14 2E 08 02 0C 2A 10 2B 08 00 0C 2C 10 2D 01
   ```

   The stream describes seven OAM tile entries using tile IDs
   `$28,$29,$2E,$2A,$2B,$2C,$2D`, split across three Y-offset groups. These
   are 8×8 pattern tile numbers, not CHR file offsets.

This is a conditional decode only. The live actor's `+$12` descriptor value
and `$0546` at the first command menu have not yet been captured, so descriptor
`$00` is not asserted to be the active first-match pose.

The sprite-pattern selectors are separate from `$0546`. Animation command
`$F4` at bank `$14`, CPU `$8142` (file `0x028152`), copies four script bytes to
the sprite CHR selector slots RAM `$0493..$0496`. The actual first-menu selector
values are pending live PPU/MMC3 capture. In the extracted CHR resource, an
MMC3 1 KiB selector `n` addresses bytes `[n*0x400, (n+1)*0x400)` of
`reference/rom_extract/chr_rom.2bpp`.

## Player palette lookup and corrected calculation

The sprite-palette setup routine begins at bank `$14`, CPU `$81BA` (file
`0x0281CA`). It resolves the chosen player record, calls `$826A` to set
`$0546`, and builds palette bytes in RAM `$047F–$048E`. The palette pointer
table at CPU `$8264` (file `0x028274`) begins with the ordinary-player table
`$B80C` (`0C B8`), followed by alternate bases `$B6C7` and `$B767`.

The byte-checked `$81E9/$8282` resolver chooses a palette index from the live
player ID and `$002A`. For the first-command route's ordinary player ID `$08`,
`$8282` returns `$08`. The target routine multiplies this index by five before
adding `$B80C`, so the read address is `$B834`, file `0x02B844`; its five source
bytes are:

```text
15 0F 30 30 30
```

The first byte supplies the shared slot-3 color; the following four bytes
supply slot-2 colors for the four sprite subpalettes. The writer at CPU
`$8241–$8263` (files `0x028251–0x028273`) writes `$0F` into slot 1 and leaves
slot 0 untouched. For this endpoint, the generated `$3F10–$3F1F` palette bytes
match the same-input PPU validation snapshot:

```text
0F 0F 0F 15  0F 0F 30 15  0F 0F 30 15  0F 0F 30 15
```

This corrects the previous four-byte-stride interpretation and its accidental
index `$0A` label: `$0A×4` happened to point at the same bytes as `$08×5`, but
is not the ROM's index calculation. The older ID `$01` and Carlos `$2B`
examples in this note were based on that incorrect interpretation and are
withdrawn. Special IDs, the `$002A`-dependent branches, alternate table bases,
and IDs beyond the extracted normal table need their live state and branch
inputs resolved before their palettes are claimed. The dedicated target-ROM
audit documents the instruction-level path and limits:
[`first_command_actor_palette_and_mirror_source_audit_20261027.md`](first_command_actor_palette_and_mirror_source_audit_20261027.md).

## Field background candidate (not yet confirmed in match)

The project's ROM-derived background record `$01` is at file `0x00E0EF`
(bank `$07`, CPU `$A0DF`). Its header and layout are preserved in
`reference/rom_extract/intro/background_01_layout.json`:

- CHR 2 KiB selectors: `$3C,$3E` (background 1 KiB banks 60–63)
- Background palette index: `$02`, source file `0x00D030`
- Layout: 4×16 metatiles, origin `$2000`
- Referenced 4×4 block-page source begins at file `0x010010`

This is the known field-style record used by the opening renderer, and is a
plausible match-field candidate. Its use at the first in-match command menu is
not established. The first-menu background ID, palette, nametable mapping,
and active raster CHR changes remain pending the capture.

## External leads and local checks

- The [Japanese address memo](https://daymoe.com/rom/code/%E3%82%AD%E3%83%A3%E3%83%97%E3%83%86%E3%83%B3%E7%BF%BC2%E3%82%A2%E3%83%89%E3%83%AC%E3%82%B9%E3%83%A1%E3%83%A2.html)
  points to player graphics around file `0x28901` and player colors around
  `0x2B821`; both ranges agree with the local target bytes described above.
  The memo does not identify the supplied ROM hash or provide a live trace.
- The [annotated English-translation disassembly at pinned revision
  `ec03cf06e6bdae0bcd232e3a423e9d259757dc64`](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/tree/ec03cf06e6bdae0bcd232e3a423e9d259757dc64)
  supplies useful labels and routine structure. The local code/table bytes
  cited in this note were checked against the Turkish ROM before using those
  labels.
- The [Chinese CT2 code/reference index](https://daymoe.com/rom/code.html) is
  an address-index lead; it did not provide an independently verified
  first-match sprite or background mapping for this note.

## Pending evidence

Do not mark first-match assets complete until the same-input capture identifies
at the initial command-menu frame:

- the selected background record and nametable/attribute bytes;
- live `$0493..$0496` sprite CHR selectors and any raster-time replacements;
- the six sprite-order nibbles in `$0543..$0545` and active actor records;
- each relevant actor's player ID, `$0546`, descriptor index at `+$12`, and
  palette bytes committed from `$047F..$048E` to PPU memory.

Once captured, use these values to choose the matching ROM records and CHR
pages. Until then the candidate background `$01` and conditional descriptor
`$00` remain leads, not claims about the first menu's exact live composition.
