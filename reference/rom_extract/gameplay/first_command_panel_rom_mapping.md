# First in-match command panel: ROM mapping

## Scope and evidence boundary

This note maps the first command panel after fresh-start `KICK OFF` to supplied-ROM data where the bytes can be verified. The emulator snapshot is used only to identify active nametable cells, palette state, and end-of-frame MMC3 selectors. It is not a runtime asset. No FCEUX process was opened for this analysis.

- ROM: `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`
- SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`
- PRG+CHR MD5 (excluding the 16-byte iNES header): `eaf2b3745263efa4b1afd2b400f68dae`
- Live observation: `reference/diagnostics/kickoff_select_test_20261027/`
- First full-panel PPU snapshot: `ppu/route_frame_008953.bin`, SHA-256 `da56b2c2dbe44a5864be61068bb23fe46f434cc2bc73a10489a471e4bfa2350e`
- Same-frame RAM/OAM snapshot: `ram/route_frame_008953.bin`, SHA-256 `a8d4cae0ed26fa6fbc01dcdcae6f076c94c33b0c295b95eca6cdbf64270a2971`
- The full panel is first sampled at frame 8953; its appearance is bounded by screenshots at frames 8938 and 8953. PPU bytes at frame 9042 are identical to frame 8953. The observation sent no input after the opening B press, and does not identify a cursor row.

All ROM file offsets below include the iNES header. Bank `$18` is at file base `0x030010`; its CPU address `$8000` maps to that base. The raw CHR resource is `reference/rom_extract/chr_rom.2bpp` (SHA-256 `721579f3a3dc2042534de98b24135371fc379958711a168a6861c989a10d85ad`).

## What is byte-confirmed

### Command-panel tilemap and labels

In the captured PPU nametable at `$2000`, the right-hand panel occupies tile columns 18–29 and rows 18–27. Its distinct tile IDs are:

```text
00 08 10 11 20 36 3A 3B 3C 43 45 50 53 61 65 69 6A 6C 6D 6E
72 73 74 75 86 92 9C 9D 9E 9F A8 A9 AA AB
```

The labels in the sampled nametable use the exact target-ROM bytes below:

| Visible row | Captured tile IDs | Target-ROM source |
|---|---|---|
| `Enerji` | `45 6E 65 72 6A 69` | CPU `$BC23`, file `0x033C33` |
| `Calim` / displayed `Çalım` | `43 61 6C 69 6D` | CPU `$BC2E`, file `0x033C3E` |
| `Pas` | `50 61 73` | CPU `$BC39`, file `0x033C49` |
| `Sut` / displayed `Şut` | `53 75 74` | CPU `$BC44`, file `0x033C54` |

The target bytes at these addresses begin with the same character codes. Descriptor strings and live nametable are separate evidence: the former are ROM source; the latter confirms those codes appeared at this endpoint. The name/position line starts at CPU `$BC21` / file `0x033C31` with control byte `$E0`; the menu renderer's control table labels `$E0` as the dynamic current-player name/position substitution. `$E1` is the current player's stats substitution. The target routine bytes at CPU `$89FA` and `$8A00` / files `0x030A0A` and `0x030A10` read the player-with-ball index from RAM `$0441` before dispatching to those output routines.

The PPU menu border uses the ROM's window-tile family at bank `$18`, CPU `$8D9E`, file `0x030DAE`:

```text
9C A8 9D
AA 00 AB
9E A9 9F
```

Those nine tile IDs match the panel corners, sides, and interior in the captured nametable. They are useful ROM-derived tile IDs for the renderer; do not use the captured nametable bytes as the shipped layout.

### Target-ROM menu descriptor and renderer

The local target-ROM pointer table begins at CPU `$B3CF`, file `0x0333DF`. Entry `$03` is pointer `$B48A` (bytes `8A B4`) at file `0x0333E5`; its descriptor begins at file `0x03349A`:

```text
32 22 0C 0A 00 01 0C 09 05
01 02 21 BC
03 01 23 BC
05 01 2E BC
07 01 39 BC
09 01 44 BC
```

This target descriptor's row pointers resolve to the dynamic player line and the four ROM strings listed above. Its `0C`/`0A` dimensions and five row records are consistent with a 12×10 panel and the observed five text lines. The low-level coordinate/first-row interpretation has not been completely reconstructed; the descriptor bytes should be preserved as-is and parsed only with a verified target-ROM routine. The captured text rows and the target string pointers match, but that alone does not prove which caller selected descriptor `$03` on this route.

Target bank `$18` code begins the shared menu renderer at CPU `$8852`, file `0x030862`. Its local bytes include the indexed reads from `$B3CF/$B3D0`, pointer storage at `$0050/$0051`, and subsequent use of the PPU transfer buffer at `$04A5` and window-tile table at `$8D9E`. The drawing loop waits on buffer flag `$0515`, builds transfer packets in `$04A5`, and increments `$05C5`. This is direct target-ROM byte evidence for the generic renderer's data path. No live gameplay PC hook captured the active caller at frame 8953, so the route-to-descriptor call remains unproven.

The English-translation disassembly at pinned revision [`ec03cf06e6bdae0bcd232e3a423e9d259757dc64`](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/tree/ec03cf06e6bdae0bcd232e3a423e9d259757dc64) is only a routine-label/structure lead. Its descriptor bytes differ from this Turkish ROM. Use the local bytes above as the target; do not transplant the English descriptor layout without checking its parser against the supplied ROM.

### Captured transfer packet shape

The live RAM snapshot has a menu transfer record at `$04A5`:

```text
0C 72 23 9E A9 A9 A9 A9 A9 A9 A9 A9 A9 9F
```

Interpreted as the queue's observed `length, PPU-address-low, PPU-address-high, data...` packet, it writes 12 tile bytes to `$2372` (nametable row 27, column 18), forming the bottom border. This packet is diagnostic corroboration for the menu renderer and is not a runtime asset. The producer routine and target-ROM tile table provide the source for reconstructing packets; exact NMI consumption cycle and the first visible pixel are not measured here.

## Background, palette, and pattern sources

### Background record candidate

ROM background record `$01` is at bank `$07`, CPU `$A0DF`, file `0x00E0EF`, and its existing extraction is `reference/rom_extract/intro/background_01_layout.json`. The record selects 2-KiB CHR banks `$3C/$3E` (1-KiB pages `$3C–$3F`), palette index `$02`, a 4×16 metatile layout, and origin `$2000`. Its block page begins at `0x010010`.

Expanding that ROM layout and comparing its left 32 columns at vertical offset 14 against captured nametable page `$2800`, rows 14–29, gives 408/512 matching tile cells (79.7%). This is a useful candidate for the field layer, but is not enough to establish the active record: 104 cells differ, and the full route did not capture a background-ID write or menu caller PC. Keep background `$01` marked as a candidate until the field/background selection routine and its live queue are traced.

### Background palette

The background palette bytes at PPU `$3F00–$3F0F` in frame 8953 are:

```text
0F 1A 18 30 0F 36 25 30 0F 21 31 30 0F 3A 1A 1A
```

They match ROM palette record `$02` byte-for-byte at file `0x00D030` (`reference/rom_extract/intro/background_palette_02.bin`). This is an exact palette-byte mapping for the sampled endpoint, independently of whether record `$01` is the active field background.

### Sprite palette and player selector

The live sprite palette at PPU `$3F10–$3F1F` is:

```text
0F 0F 0F 15 0F 0F 30 15 0F 0F 30 15 0F 0F 30 15
```

The RAM snapshot has player-with-ball index `$0441=$06`, player-data pointer `$0348`, player ID `$08`, and graphic selector `$0546=$08`. In the target ROM, bank `$14` routines at CPU `$81BA` and `$826A` (files `0x0281CA` and `0x02827A`) resolve the player ID through table `$88F0` (file `0x028900`); entry 8 gives selector `$08`. The normal-player palette path uses base `$B80C` and reads the ID-8 palette bytes `15 0F 30 30 30` at CPU `$B834`, file `0x02B844`. The palette writer distributes those values into the four sprite subpalettes, producing the captured 16-byte PPU palette exactly. This resolves the apparent conflict with the Tsubasa ID `$01` example in `first_match_asset_byte_map.md`: the observed endpoint selects ID `$08`, not that earlier conditional example. The numeric mapping is byte-verified; assigning the character name “Tsubasa” relies on the visual read and is not needed to reproduce the palette.

### CHR pages and tile lookup

At the end of the frame-8953 sample, MMC3 `$8000` is `$07` and `$8001` R0–R7 are `00 02 1F 2E 0A 0B 18 19`. Under the captured mode-0 bank arrangement, the eight 1-KiB PPU pattern slots map to ROM CHR banks:

```text
PPU slots 0–7: 00 01 02 03 1F 2E 0A 0B
```

Each captured 1-KiB slot was compared byte-for-byte with the named bank in `chr_rom.2bpp` and matched. For a renderer using background pattern table `$0000`, a tile ID `t` maps to CHR bank `t >> 6`, tile-within-bank `t & 0x3F`, and CHR byte offset `(t >> 6) * 0x400 + (t & 0x3F) * 0x10`; its ROM file offset is `0x40010 + that_offset`. This is the capture's end-of-frame mapping, not proof of the pattern-table bits or all raster-time banks. The candidate background `$01` selectors `$3C/$3E` disagree with the captured end-of-frame slots, so do not hard-code either mapping as the panel's full-frame CHR state until the raster bank sequence is traced.

## Data needed by a ROM-derived renderer

The frame should be generated from source data and execution state, not copied from the PPU snapshot:

1. Load the verified ROM CHR pages and the 16-byte background palette record. Keep the external RGB conversion table separate from ROM provenance.
2. Build the field nametable from the confirmed gameplay background record, its metatile layout, block-page bytes, and any traced PPU/raster updates. Background `$01` is only the current candidate.
3. Parse the target menu descriptor from `$B3CF`/`$B48A` with a byte-verified local parser; expand the window frame through the ROM table at `$8D9E`; decode strings from `$BC21` onward.
4. Generate the player line and stats from current match state through the ROM's `$E0/$E1` substitutions, including player ID/name, position, energy, and stat formatting. These values are not static menu art.
5. Emit the equivalent nametable transfer packets at the source-defined PPU addresses and schedule them through the traced queue/NMI timing. The sample packet at `$04A5` is a comparison target only.
6. Reconstruct player sprite tiles from the selected actor's ROM sprite descriptors/animation selectors and palette path. For this endpoint the palette path is ID `$08`; live raster-time sprite/background CHR switching is still incomplete.

The project renderer can consume a ROM-derived model containing: 1-KiB CHR bank bytes, 16-byte palettes, nametable writes as `(address, bytes)` records, attribute-table writes, OAM sprite descriptors, current scroll/control state, and source-clock event timing. Each runtime item should preserve its ROM offset/bank and decode rule in metadata. Do not serialize the capture PPU image as the model.

## First action menu input trace (ROM static analysis)

The prior assumption that the initial action cursor was unknown is superseded
by the target-ROM input-handler trace in
[`first_action_menu_input_rom_trace_20261027.md`](first_action_menu_input_rom_trace_20261027.md).
The route enters with `$061E=0`, so no action is selected and there is no
initial row cursor. For fresh-start context `$0621=0`, newly pressed Right,
Left, Down, Up select Shoot, Pass, One-two pass, and Dribble respectively.
The direction mappings are ROM table `$D6E8`; A confirms only after the
selection gate is set. This explains the unhighlighted frame-8953 panel.

## Still unresolved

- The byte-checked call chain identifies action descriptor `$02` and player/status descriptor `$03` for the fresh left-team path. The endpoint's live caller PC has not been captured in an instruction trace.
- The active gameplay background record and all map/attribute producers are not proven. Background `$01` is a partial visual/tilemap match only.
- PPUCTRL/scroll state, nametable selection across the frame, per-scanline MMC3 CHR switches, and the exact first PPU write/visible pixel are absent from the endpoint dump. End-of-frame bank selectors cannot fill this gap.
- The captured menu tilemap includes dynamic player/stat digits and game-state fields; the full target-ROM formatting path has not been traced end-to-end.
- `$05C5` is a progress/index in the shared menu drawing code and `$05C6` participates in window/frame setup; neither is the action-selection field. The handler uses `$061E` and `$043B` as documented in the input trace.
- A same-input FCEUX D-pad probe has not yet cross-checked the static direction table and resulting blink. The selected Turkish label's exact pixel timing remains unverified.
- The exact first-visible panel frame is bounded to 8938–8953; exact packet/NMI phase and subframe timing remain unknown.
