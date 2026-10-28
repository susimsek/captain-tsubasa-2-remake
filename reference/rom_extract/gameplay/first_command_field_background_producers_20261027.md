# First command screen: field, raster, and actor producers

## Source and capture identity

This note traces the first fresh-start in-match command screen near source
frame 8953. It uses only the supplied ROM bytes and existing muted FCEUX
memory/register snapshots. No emulator session was controlled, and no captured
image or audio is proposed as a runtime asset.

- ROM: `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`
- SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`
- PPU snapshot: `reference/diagnostics/kickoff_select_test_20261027/ppu/route_frame_008953.bin`, SHA-256 `da56b2c2dbe44a5864be61068bb23fe46f434cc2bc73a10489a471e4bfa2350e`
- RAM/OAM shadow: `reference/diagnostics/kickoff_select_test_20261027/ram/route_frame_008953.bin`, SHA-256 `a8d4cae0ed26fa6fbc01dcdcae6f076c94c33b0c295b95eca6cdbf64270a2971`
- The OAM shadow is RAM `$0200–$02FF`; SHA-256 `0227bf5388bb0f5c67ad97b41aff1a531b0a20854bdb1363ee36795f8de1c339`.
- The public annotated disassembly at pinned revision [`ec03cf06e6bdae0bcd232e3a423e9d259757dc64`](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/tree/ec03cf06e6bdae0bcd232e3a423e9d259757dc64) is a structural lead. The target-ROM byte excerpts cited below were checked at the supplied ROM offsets.

## Field background: strong record candidate, active selection unproven

Background record `$01` is at bank `$07`, CPU `$A0DF`, file `0x00E0EF`.
Its target-ROM header is `3C 3E 02 04 10 00`: CHR pair selectors `$3C/$3E`,
palette `$02`, a 4-by-16 metatile map, and packed origin `$00`. Its block IDs
expand through 17-byte records from bank `$08` starting at file `0x010010`.
Palette record `$02` at file `0x00D030` begins with the exact 16 background
palette bytes sampled at frame 8953:

```text
0F 1A 18 30 0F 36 25 30 0F 21 31 30 0F 3A 1A 1A
```

Expanding record `$01` using its ROM block records gives 512 source tile
placements for the sampled 32-by-16 field window. Comparing source-map
coordinates x=14–45, y=0–15 against captured nametable `$2800`, rows 14–29,
columns 0–31, gives 412/512 matching tile IDs (80.5%). The compared rows in
`$2800` and `$2C00` are identical. This, the matching palette, and live RAM
`$0490=$3C` make record `$01` a strong field-background candidate. The
comparison is not exact: 100 tile IDs differ, live RAM `$0491=$2E` does not
match record `$01`'s `$3E`, and no captured PC or PPU write identifies the
background loader or proves that it selected ID `$01`. Do not treat this
candidate as a confirmed complete field reconstruction.

The end-of-frame mapper sample in `state_index.csv` reports select `$07` and
registers R0–R7 `00 02 1F 2E 0A 0B 18 19`. The eight 1-KiB pattern slots in the
PPU snapshot byte-match ROM CHR banks `00 01 02 03 1F 2E 0A 0B` respectively.
The same RAM snapshot has `$0490–$0497 = 3C 2E 00 00 08 09 0A 0B` and
`$0087=$02`. These are useful endpoint clues, not a raster history. The route
capture did not record the gameplay PPU `$2006/$2007` writes, scanline IRQ
callbacks, or each `$8000/$8001` write around the field transition; therefore
the visible-line CHR sequence and exact nametable producer remain unknown.

### First-command CHR animation path (ROM caller and pair confirmed)

The frame-8953 `$3C/$2E` selector pair comes from the match scenario's
background-animation path, rather than directly from background record `$01`:

1. The fresh kickoff enters scenarios `$35/$36`; opening the first command
   panel queues scenario `$44`. Its pointer word is `$B7D5` at file
   `0x020A57`, and its stream starts at file `0x0237E5` with event bytes
   `02 70 5C F0`. In the bank-`$10` scenario reader, `$804F` stores the first
   byte as its wait, `$8069` stores the second byte to `$0524`, `$8079` stores
   the third to `$0528`, and `$8089` stores the fourth to `$0529`. Thus the
   first-command route selects animation record `$70`, sequence `$5C`, and
   cloud parameter `$F0`. The same byte sequence appears embedded at offset
   `+8` in scenario `$35`, but it is not event-aligned there; do not attribute
   the live `$70` selection to that kickoff-script occurrence.
2. The scenario reader at file `0x020079` returns through its banked-call stack
   to physical PRG bank `$0B`, routine `$814C` (file `0x01615C`). That routine
   indexes pointer table `$87F6` with `$0524`. Entry `$70` is pointer `$8B38`
   (table bytes at file `0x0168E6`); the target record at file `0x016B48` starts
   `06 00 56 02 00 ...`. At the captured endpoint the related RAM values are
   `$0524=$70`, `$0525=$06`, `$0528=$5C`, `$05CC=$56`, and `$05CD=$80`.
3. The record's opcode `$00` dispatches to bank-`$0B` handler `$8327` (file
   `0x016337`). It reads operand `$56` into `$05CC` and calls `$8525` with
   `$05CD` as the Y placement. `$8525` indexes the CHR-pair table `$86EE` at
   file `0x0166FE`; entry `$56` is the pair `$3C,$2E` at file `0x0167AA`.
   The routine sets bit 7 on the first selector and stages `$0526/$0527`;
   fixed-bank code at file `0x03ECC4` consumes that request into `$0490/$0491`.
   Both staged and committed values match the frame-8953 RAM snapshot.

This identifies the ROM caller, animation record, pair-table entry, and fixed
bank consumer for the active CHR pair. The bank-`$0B` scroll/background worker
also computes 32-tile row runs from `$05D4/$05D5` and the ROM table at `$8B64`
(file `0x016B74`), then queues them through `$85C2`. This is a confirmed
ROM-derived animated-background tile producer. Its exact frame-8953 packets,
nametable addresses and attributes are not present in the endpoint snapshot.

### Executable ROM-only candidate layer

`scripts/gameplay/first_match_field_candidate_presenter.gd` now builds a
standalone candidate PPU state without reading the ROM file or any PPU/OAM
snapshot at runtime. Background `$01` goes through the existing ROM row/block
packet loader and palette `$02`. Exact source bytes for animation `$70`, the
4×8 block map `$56`, and its required metatile tile/attribute records are
preserved under `reference/rom_extract/gameplay/first_command_field/`; their
file offsets and SHA-256 values are in `manifest.json`. The presenter expands
those source records into tile rows at PPU `$2800` and attributes at `$2BC0`,
then applies the pair-table selectors `$3C/$2E` through the existing MMC3
renderer model. `KickoffCutsceneVisuals.present_first_action_menu()` invokes
this candidate layer before adding the menu panel.

This is an executable source-data candidate, not a verified full field screen:
the BG01 loader/coordinate transform is not proven active in the match route;
the `$70/$56` pair is applied as a static profile because its gameplay raster
schedule is unknown; and only one 4×8 block is decoded. ROM descriptor streams
and the frozen scenario `$44` / animation `$5C` endpoint pose are now decoded
by `FirstCommandActorSourcePresenter` and `GameplayRomActorOamBuilder`; that
presenter is not wired into this field layer because route-time actor records,
the committed `$0517` mirror state, and source call cadence are not yet
supplied. The field therefore still draws no actors. These gaps are exposed by
`first_match_field_status` and `presentation_gaps` in the runtime presenter.

### Main field map and attributes: candidate only

Background record `$01` remains the best full-pitch-map candidate: its ROM
palette `$02` exactly matches the captured background palette and its decoded
tile placements are field-like. It still matches only 412/512 tile IDs in the
previously aligned endpoint window, while `$0491=$2E` comes from the animation
path above rather than the record's `$3E`. This may be a layered composition,
but the existing evidence does not prove that interpretation. No confirmed
fresh-match call to the full background-record loader, nametable packet
sequence, or attribute-byte producer has been found. The exact main-field
record selection, tilemap-to-PPU coordinate transform, and attribute producer
remain the blockers for an exact endpoint reconstruction.

## Confirmed gameplay setup and minimap path

The byte-checked fixed-bank setup at CPU `$E233`, file `0x03E243`, writes
scenario `$1E`, selects PRG banks `$1C/$1D`, calls bank `$1C` routine
`$82CA` (global file offset `0x0382DA`), then calls `$E267`. The target bytes
begin:

```text
A9 1E 20 B0 CB 48 A5 22 A9 1C 85 24 A9 1D 85 25 20 2D CE 68 20 24 80 20 67 E2
```

At file `0x0382DA`, `$82CA` clears the lower screen, points to the ROM minimap
tile table at `$834A` / file `0x03835A`, and loops through 12 rows. Each row
queues two 24-byte tile runs through RAM `$04A5`, waiting for buffer flag
`$0515`; the table is 12 × 24 bytes and is explicitly the pre-run minimap.
This fully identifies the minimap producer, but it is not the complete pitch
background. The sampled menu's generic panel/string mappings are separately
documented in [`first_command_panel_rom_mapping.md`](first_command_panel_rom_mapping.md).

The minimap's 12 queued PPU rows start at `$2228,$2248,$2268,$2288,$22A8,$22C8`,
`$22E8,$2308,$2328,$2348,$2368,$2388` (24 tiles at columns 8–31), all on
page 0. In the retained snapshots the `$834A` bytes match there through frame
8908; the region is progressively replaced during later field/menu setup. The
frame-8953 PPUCTRL state selects page 2. This separates the pre-run minimap
producer from the visible-pitch producer.

The fixed-bank NMI path writes scroll from `$004A/$004B` plus `$0538`, calls
the CHR-bank routine, and maintains scanline IRQ state. At frame 8953 the RAM
snapshot has `$004A=$00`, `$004B=$74`, `$0538=$00`, `$0020=$8A`, and
`$008E=$00`. These values describe sampled state only; the route logger's
`pc_hooks.csv` monitored title/cutscene PCs and did not hook gameplay setup,
NMI, or IRQ entries.

### Page-2 selector and visible-pitch source boundary

The endpoint's `$0020=$8A` is the PPUCTRL shadow: its low two bits select
nametable page 2. The byte-checked fixed-bank NMI code at CPU `$C7AF` (file
`0x03C7BF`, bytes `A5 20 8D 00 20`) writes that shadow to `$2000`. It then
writes `$004A+$0538` and `$004B` to `$2005`. At frame 8953 these are `$00` and
`$74`, selecting page-2 scroll X 0, coarse Y 14, fine Y 4.

The call is now connected to the selected ROM record. Scenario `$44` selects
animation `$70`; its target-ROM record at file `0x016B48` begins
`06 00 56 02 00 80 F2 19`. Opcode `$06` dispatches through `$81A7` to `$83D2`
(file `0x0163E2`), which calls `$847F` and jumps to `$8386`. `$8386` calls
`$8525` with map `$56` at Y `$A0`, then reaches `$8393` (file `0x0163A3`):
`A9 A0 20 A1 84`. `$84A1` at file `0x0164B1` computes X=2 and Y=`$74` for
input A=`$A0`, writes the low PPUCTRL shadow bits and `$004B`, and the fixed
NMI `$C7AF` writes the state to `$2000/$2005`. These instruction bytes and the
`$70` record were checked directly against the supplied ROM; the pinned public
bank-`$8B` disassembly is a navigation/label lead, not the source of runtime
bytes.

The Godot field candidate now applies that ROM-derived initial viewport only
to the gameplay field layer. It does not yet explain the whole endpoint image:
the background-only same-input comparison is 51.97% exact with this initial
state, and a screenshot-guided `$2006=$2240` event at scanline 134 raises it to
83.81%. That second event is diagnostic-only and is not in the runtime
presenter because its scanline/address have not been traced from ROM or a live
PPU-bus capture. The visible menu split, later field palette/CHR changes, and
remaining composition still need source-backed events.

Background record `$01` at bank `$07` CPU `$A0DF`, file `0x00E0EF`, remains the
leading pitch-map candidate. It declares CHR selectors `$3C/$3E`, palette
`$02`, and a 4-by-16 block map expanded from ROM blocks. The record's palette
bytes match the endpoint's 16 background palette bytes. Decoding its tile map
and aligning source columns 14–45, rows 0–15 to PPU page-2 columns 0–31, rows
14–29 matches 412/512 tile IDs. All 100 mismatches lie in source rows 2–9;
the other eight rows match. This is substantial ROM-byte evidence for the
pitch layout, but does not establish the active loader call or exact map
transform. The endpoint CHR selector `$0490/$0491=$3C/$2E` also differs from
the record's `$3C/$3E`; `$3C/$2E` is selected by the independent `$70/$56`
background-animation path.

Animation `$70` is a separate source candidate: its record at bank `$0B`
`$8B38` / file `0x016B48` begins `06 00 56 02 00`. Opcode `$00` dispatches
through `$8327`; that handler passes block `$56` and the placement byte to
`$8525`. The block map is at `$9624` / file `0x017634`; its metatile IDs expand
through 4-by-4 tile records and the banked attribute table. `$85C2` constructs
PPU row packets from the encoded placement. A corrected muted two-pass route
trace now proves the last `$05CE` write before `$F015` is `$0B:$8342` at frame
8905, storing `$A0`; `$05CD` becomes `$80`, and neither value is overwritten
before the packet routine enters at frame 8908. The ROM-derived transition is
documented in `first_command_field_05ce_source_xref_20261028.md`. The decoded
`$56` expansion does not match the visible
page-2 tile region when using the old selector-0 tile-record export; that
comparison used the wrong tile source for selector `$02` and is superseded by
the page-correct decode below.

### ROM-derived map `$36` / `$56` field layers and PPU destinations

The ROM contains two directly addressable 8-by-4 metatile maps used by the
fresh-match setup and first command panel. This is a stronger source path than
the earlier full-background-record `$01` candidate:

| Route cue | ROM background record | Map / selector | Map bytes |
| --- | --- | --- | --- |
| Scenario `$1E` field setup selects background animation `$45` | Bank `$0B` `$8A2A`, file `0x016A3A`: `06 00 36` | Map `$36`, selector `$01` | Bank `$0B` `$9224`, file `0x017234`, 32 bytes |
| First command-panel scenario `$44` selects background animation `$70` | Bank `$0B` `$8B38`, file `0x016B48`: `06 00 56` | Map `$56`, selector `$02` | Bank `$0B` `$9624`, file `0x017634`, 32 bytes |

For `$70`, the route event at file `0x0237E5` begins `02 70 5C F0`. The
background-animation interpreter at bank `$0B` `$814C` indexes `$87F6`, then
dispatches opcode `$00` through `$81A7` to handler `$8327` / `$832B` (file
`0x016337` / `0x01633B`). `$832B` stores map ID `$56`, passes the current
placement byte `$05CD` to `$8525`, and the latter expands the 32 map entries.
Scenario `$1E`'s `$45` entry follows the same opcode/expander path with map ID
`$36`. The routine addresses and map/record bytes cited here were checked
against the supplied ROM hash above.

The selector is not inferred from the map ID name. `$86D3` at file `0x0166E3`
reads the packed 2-bit selector table `$8B42` at file `0x016B52`; its target
ROM formula is
`(table[map_id >> 2] >> (2 * (map_id & 3))) & 3`. It yields selector `$01` for
`$36` and `$02` for `$56`. `$8525` at file `0x016535` computes the block-map
address as `$8B64 + map_id * $20`; `$85C2` at file `0x0165D2` expands each of
its 32 metatile IDs into a 4-by-4 tile-ID record and one attribute byte.

The selector affects both graphics and attributes. For metatile ID `m`, the
tile-source window offset is `(selector << 12) + (m << 4)`. The bank/address
split used by `$85C2` is `bank = $12 + (window_offset >> 13)` and
`CPU = $A000 + (window_offset & $1FFF)`. In the ROM file this is the contiguous
formula `0x024010 + window_offset`, across bank `$12` at file `0x024010` and
bank `$13` at file `0x026010`. Thus map `$36` selector `$01` reads its metatile
records from bank `$12` (for example ID `$2B`: CPU `$B2B0`, file `0x0252C0),
while map `$56` selector `$02` reads its metatile records from bank `$13`
(ID `$15`: CPU `$A150`, file `0x026160`; ID `$AD`: CPU `$AAD0`, file
`0x026AE0`). Attributes use `0x017BF4 + (selector << 8) + m`: selector `$01`
uses `$9CE4`, and selector `$02` uses `$9DE4`.

This corrects a source error in the older `$56` candidate package:
`first_command_field/metatile_*_tiles.bin` was extracted from selector `$00`
bank-`$12` offsets such as ID `$AD` at `0x024AE0`. Those are not the bytes
`$85C2` uses for map `$56` with `$05CA=$02`; the correct record is bank `$13`
file `0x026AE0`. Do not promote that older tile payload for the page-2 field.
The selector-correct map bytes, packed selector table, unique tile records and
attributes are now preserved with per-file hashes in
[`page_correct_map_sources/manifest.json`](first_command_field/page_correct_map_sources/manifest.json),
and can be regenerated by
[`extract_first_command_field_page_correct_tiles.py`](../../../tools/gameplay/extract_first_command_field_page_correct_tiles.py).

The destination arithmetic in `$85C2` is also specific enough to recover the
two map placements. A starting Y byte of `$80` puts the 32-by-16 tile layer at
PPU `$2800` and its 32 attribute bytes at `$2BC0–$2BDF`; starting Y `$A0` puts
the layer at PPU `$2A00` and attributes at `$2BE0–$2BFF`. Each is 8-by-4
metatiles, or 32-by-16 NES tiles (256-by-128 pixels). The RAM snapshot's
`$05CD=$80/$05CE=$A0` is consistent with alternating those two placements,
but does not reveal the last executed handler call by itself.

As a ROM-only tile decode validated against (not generated from) the retained
frame-8953 PPU nametable, map `$36` at `$2800` plus map `$56` at `$2A00` matches
452/512 tile IDs over captured page-2 rows 14–29. Rows 14–17 and 24–29 are
exact; rows 18–23 each differ only at columns 2–11, for a 10-by-6-cell residual
rectangle (60 cells). The corresponding page-2 attribute bytes have the same
localized change: the expected map `$56` bytes match `$2BE0` at 26/32, with
only offsets 0–2 and 8–10 changed. This strongly supports the two-map field
composition and isolates a small additional tile/attribute producer. A later
same-input PPU bus trace confirms all 66 cells are written through the `$C97B`
consumer from the `$04A5` transfer queue; the upstream packet assembler remains
unknown.

A focused source-only check fed background animation `$01` through the existing
ROM packet decoder and asked whether its packets covered the 60 endpoint cells
in this residual rectangle. They covered `0/60`; no `$01` packet touches those
PPU addresses, so `$01` cannot explain this specific residual. The probe is
`tools/diagnostics/probe_first_command_field_residual_layers.gd`. The PPU
snapshot supplies comparison bytes only; no captured cell was copied into the
runtime map.

The earlier `$2BC0` 32/32 attribute match is not by itself proof that `$56`
was written there: maps `$36` and `$56` decode to the same 32 attribute bytes
for that region. The precise placements above come from `$85C2`'s address
arithmetic. A later live bus trace independently confirms the `$2BE0` writes
and final values. The separate 60-tile/six-attribute residual packet producer
is now proven as bank-$1F `$F015/$F114`; that does not establish the upstream
producer for the full `$85C2` map-$56 expansion.

`$86D3` maps block `$56` through packed table `$8B42` to selector
`$05CA=2` (entry `$8B57=$22`, shifted twice by two bits). `$85C2` reads
attributes from `$9BE4 + ($05CA << 8)`, so the correct source base is `$9DE4`,
file `0x017DF4`; it is not page-0 base `$9BE4` / file `0x017BF4`. The previous
focused audit compared those 32 bytes at `$2BC0` and observed 32/32 equality,
but that address placement is not established by the equality: map `$36`'s
attribute sequence is identical there. With the source-derived `$A0`
placement, map `$56` writes its attributes at `$2BE0`; the endpoint retains
26/32 matching bytes there, with the same six changed cells as the tile-row
residual above. The old candidate's `$2BC0` attribute comparison therefore
does not establish map `$56`'s destination or its full visible tile rows.

The older export utility `tools/gameplay/complete_first_command_field_metatile_export.py`
preserves selected page-2 attribute bytes but its map-$56 tile records came
from selector-0 bank-$12 offsets. Keep those old page-0 tiles separate from
the selector-correct tile data in `page_correct_map_sources/`. A focused Godot
route check compared its generated 32-byte attribute region to `$2BC0`; that
result remains a byte comparison only and does not verify the inferred
`$2BE0` placement or the new bank-$13 tile source.

The focused check was run with
`godot --headless --audio-driver Dummy --path . --script tools/diagnostics/verify_kickoff_route_to_first_menu.gd`.
It reports 32/32 generated page-2 bytes equal to the frame-8953 endpoint PPU
snapshot, and the same run reaches the first command menu without confirming an
action. Endpoint RAM used by this broad visual harness to fill the dynamic
panel is validation-only. A ROM-derived player-state provider and route API now
exist, but production route input/RNG and `$E14D` loop events do not call them.

**Runtime decision:** no page-2 field presenter is ready to promote. The ROM
bytes are sufficient to build the BG `$01` candidate and `$70/$56` patch
separately. A same-input trace now establishes live PPU register/mapper writes,
the `$C97B` `$04A5` packet consumer, actual residual-cell destinations, and a
menu-border packet. It does not identify the upstream residual packet builder,
prove that BG `$01` is the active full-field loader, or recover the complete
gameplay raster CHR/scroll history. PPU/RAM endpoint dumps remain validation
data, not runtime state.

## Actor records and OAM path

Fixed-bank sprite preparation at `$EE9F` iterates six packed order values in
`$0543–$0545`; its pointer table at `$EF73` / file `0x03EF83` is:

```text
47 05  5C 05  71 05  86 05  9B 05  B0 05
```

Those pointers resolve to actor records `$0547,$055C,$0571,$0586,$059B,$05B0`.
The frame-8953 order bytes are `01 23 45`; the first five records contain
state, coordinates, animation fields, and descriptor bytes at `+$12` of
`00,04,0D,0A,B9`; the sixth record `$05B0–$05C4` is zeroed. Sprite-engine
entry at file `0x02C010` is reached from fixed-bank sprite preparation; target
ROM code at file `0x02C094` reads the actor's byte at `+$12`. The existing
[`first_match_asset_byte_map.md`](first_match_asset_byte_map.md) documents the
engine's descriptor-table path, but these five live descriptor values have
not yet been decoded into exact poses or assigned to specific OAM ranges.

The sampled animation/CHR selector bytes are `$0493–$0497 = 00 08 09 0A 0B`;
the adjacent live sprite graphic selector `$0546=$08`. The fixed-bank NMI
copies the 256-byte shadow at `$0200` to PPU OAM with `$2003=0` and `$4014=2`
(target bytes at file `0x03C799`). This establishes the source chain
actor records → sprite engine → RAM OAM shadow → DMA, but the endpoint capture
does not log the live caller or per-actor OAM writes. Preserve the raw shadow
as diagnostic evidence only; derive shipped sprites from ROM descriptors,
CHR, animation state, and timing.

## What is still needed for an exact frame-8953 reconstruction

An earlier full-route PPU trace attempt in
`reference/diagnostics/match_field_source_trace_20261027_133202/` remained
CPU-bound without output. A later bounded runner fixed the cost: it warms once
to frame 8399, verifies an anonymous in-memory checkpoint, then traces frames
8400–8953 twice in 15.17 seconds. The repeated bus logs are identical after
normalizing their pass label. Results are in
`reference/diagnostics/first_command_ppu_bus_trace_20261027_181102_utc/`.

- A same-input capture that records gameplay PC hooks through the field entry
  and B-to-command-panel transition (at least frames 8443–8953), especially
  `$DAAA`, `$E0DF`, `$E233`, `$E145`, `$EE9F`, NMI, and IRQ handlers. This can
  prove whether and when the candidate field record and actor renderer run.
- A new trace should record producer writes to RAM `$04A5–$0515`, including
  `$0515` ready-state transitions, with source PC/bank/frame/cycle. Correlate
  those source bytes to the `$C97B` output writes to identify the upstream
  producer for the 60-tile/six-attribute residual. The current PPU bus runner
  records CPU-cycle labels, but FCEUX Lua does not expose scanline/dot for those
  writes.
- Exact call sites for field setup around `$DAAA`, `$E0DF`, `$E233`, `$E145`,
  `$EE9F`, NMI and IRQ still need to be joined to the bus timeline. Per-frame
  OAM-shadow writes and `$4014` DMA provenance around frames 8893–8953 would
  identify actor updates when B opens the panel.
- Per-frame RAM/OAM snapshots around the field entry and frames 8893–8953
  would identify which actor descriptors and OAM rows change when B opens the
  panel. The current 15-frame samples establish only the endpoint.

Current evidence confirms `$834A` as the minimap source, `$C97B` as the generic
queued PPU consumer, and the six-slot table as a generic OAM producer. Record
`$01` only as the leading full-pitch candidate. The active full-pitch loader,
residual packet producer, raster bank sequence, actor OAM updates, and endpoint
pose-to-OAM association remain open.
