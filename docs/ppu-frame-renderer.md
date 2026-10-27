# Diagnostic: rendering a frame from FCEUX PPU/RAM dumps

This renderer is for emulator-capture inspection and validation only. Its PNG output is **not a final/runtime game asset**. Runtime graphics must be decoded from the supplied ROM bytes and packaged as Godot-owned resources. In particular, `--calibration-gd` samples screenshot colors and must not be used to create final art.

`tools/render_emulator_ppu_frame.py` composes a 256×240 RGB PNG from FCEUX-native PPU and CPU-RAM snapshots. It does not open or parse the ROM. The raw dump files are read-only inputs; the PNG is a separate converted project resource.

Example for the title/menu frame:

```sh
python3 tools/render_emulator_ppu_frame.py \
  --capture-dir reference/opening_reference_capture \
  --frame 4692 \
  --calibration-gd reference/opening_reference_capture/screens/frame_004692.gd \
  --output reference/diagnostics/title_from_ppu.png
```

The capture index is sparse because `tools/capture_opening_reference.lua` samples PPU/RAM after every emulated frame but writes a snapshot only when those bytes change. The latest earlier snapshot therefore remains byte-applicable until the next indexed change; its older filename is not, by itself, missing PPU/RAM data. This does not record when those bytes were used during scanline rendering or when OAM was copied to the display. The renderer prints resolved frame numbers and reports a pixel-agreement metric when a calibration screenshot is provided.

## Data and rendering assumptions

- Each 12,320-byte PPU state is read as 8,192 bytes of currently mapped pattern memory, 4,096 bytes of nametable/attribute memory, then 32 bytes of palette RAM.
- The background starts from a selected 32×30 nametable page and crosses into adjacent virtual pages when scrolling passes a 256-pixel horizontal or 240-pixel vertical edge. The default page is 0, and the default pattern base is `$0000`.
- The 2 KiB RAM snapshot is read at offset `$0200` for 64 OAM-shadow entries (`Y, tile, attributes, X`). The default sprite mode is 8×8 with the NES top coordinate interpreted as OAM Y + 1. Sprites are painted from entry 63 down to 0 so lower OAM indices appear above higher indices.
- Scroll defaults to zero. The renderer has no PPUCTRL/PPUMASK snapshot, direct physical OAM dump, mirroring/register state, or scanline/mapper write history to establish those settings independently. CLI options let an investigator vary the assumptions; they do not mean those values were verified.
- Use either `--palette-file` with a 192-byte RGB palette or `--calibration-gd`. Calibration reduces the observed screenshot to one majority RGB value per decoded PPU color index. It does not copy screenshot pixels or use them for geometry; all output pixel positions and color indices come from PPU/RAM decoding. A proper emulator palette export is preferable when available.

## Current title frame result

The diagnostic image `reference/diagnostics/title_from_ppu_capture_reconstruction.png` was generated from PPU frame 4692 and RAM frame 4692. It uses nametable page 0, background pattern base `$0000`, 8×8 sprites, OAM Y + 1, and palette calibration from the corresponding FCEUX `.gd` observation. Against that observation, **56,733 of 61,440 pixels match exactly (92.34%)** after palette-index calibration. It is a capture-derived diagnostic reconstruction and must not be included in the runtime asset path. Remaining mismatches may include unrecorded PPU state, sprite/OAM details, scanline effects, or frame-timing differences.

The `.gd` capture remains under `reference/opening_reference_capture/screens/` as observation material. The unmodified source PPU/RAM snapshots remain under `reference/opening_reference_capture/ppu_states/` and `ram_states/`.

## ROM-derived raster diagnostic

`tools/render_rom_raster_frame.py` reads the original CHR banks from the supplied ROM, then uses a JSON raster plan and PPU/RAM snapshots for layout. It never reads screenshot pixels. The frame-380 plan in `reference/diagnostics/frame_000380_raster_plan.json` reflects MMC3 bank writes in `reference/opening_reference_capture/ppu_register_writes.csv`: banks 60–63 are active above visible scanline 136, then banks 0–3 below it. The resulting PNG is under `reference/diagnostics/rom_intro_raster_frame_000380.png` and remains a diagnostic candidate because scroll and sprite timing still differ from the observed frame.
