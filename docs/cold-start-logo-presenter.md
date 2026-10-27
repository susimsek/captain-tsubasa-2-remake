# Cold-start logo presenter prototype

`scenes/prototypes/cold_start_logo_presenter.tscn` composes two ROM-derived
renderers and runs `RomCutsceneVm` from
`assets/opening/rom_logic/cutscene_00_vm.json`. It is intentionally isolated
from the playable main opening scene and stops when the ROM VM dispatches the
logo segment's `EA` command.

The full byte-verified VM consumes, in source order, `E8 01` (visual preset 1), `F9 00`
(background 0), `FB 01 8D` (load animation 0x8D), `E9` (screen on), `DF`
(wait 240 ticks), then `EA` (screen off and clear). The presenter advances the
prototype VM at 60.0988 ticks per second. Once the 240-tick wait completes it
applies the final screen-off state and remains blank; it does not continue into
the next part of the intro.

The background is decoded from extracted CHR and palette bytes, a documented
frame-26 nametable layout mapping, and the external FCEUX RGB palette.
Animation 0x8D uses the ROM's static sprite
frame/OAM descriptors and extracted CHR patterns. All resources are project
owned; the scene does not load the `.nes` ROM or emulator output.

The first combined preview had no character because JSON numeric IDs are
materialized as floating-point Variants (`141.0`), while the visibility check
used `Array.has(141)`. The isolated presenter now converts each numeric ID to
an integer before matching animation `0x8D`. Its frame-26 composition includes
the ROM-derived character. For capture frame 26, the ROM `$B15B` descriptor
list predicts all 40 first-object OAM-shadow entries byte-for-byte at origin
`(80, 96)`; the four captured sprite CHR pages also byte-match ROM selectors
`7C 71 52 53`. These captures validate the reconstruction and are not runtime
inputs.

## Evidence gaps

- `E8 01`'s preset side effects are not represented visually yet.
- The sprite palette source is traced to ROM file offset `0x00D670` and its 16
  bytes match the frame-100 PPU `$3F10–$3F1F` snapshot. The exact frame when the
  staged palette update reaches the PPU remains unverified.
- Background upload, sprite OAM upload, and the actual PPU enable edge have not
  been traced to a precise visible frame. The prototype toggles its composed
renderers on the script's `E9` / `EA` state edge.
- The 240-tick VM wait is sourced from the ROM duration table; mapping the
  interpreter cadence to physical NES frames is not fully validated.

Consequently this scene is a composition/logic prototype, not a fidelity claim
and not a substitute for same-input frame comparison or main-scene integration.
The scene has been launched through Godot's OpenGL movie renderer. The
background tile mapping uses the frame-26 PPU nametable's tile IDs with
ROM-derived CHR and palette bytes; this fixes the missing/garbled lettering in
the renderer. A two-frame preview confirms that the character now renders
alongside the lettering after correcting the JSON numeric-ID check. The ROM
data source that produces those title-map writes, and the E8 preset's
relationship to them, remain untraced. Full-composition pixel agreement and
visible-frame timing have not been validated, so do not treat the presenter as
exact or integrate it into the main opening yet.

## Frame-26 pixel comparison

A direct Godot PNG (`/tmp/cold_start_logo_frame_256.png`, 256×240 RGBA) was
compared without video encoding to
`assets/opening/intro/ppu_timing/frame_000026.png` (256×240 RGB). The images
match at 61,031/61,440 pixels (99.33%). All 409 mismatches are in the
`TECMO THEATER` glyph area, bounded by x=104–175 and y=96–128. Pixels outside
that rectangle are identical, including the character's region. The same
glyph-only differences occur against the captured FCEUX frame
`reference/opening_capture/frames_png/frame_00026.png`; the sprite is present
there, and frame-26 RAM OAM still matches all 40 decoded `$B15B` entries.

The mismatch is not explained by sprite visibility, OAM position, sprite
priority, or the animation palette. Frame-26 PPU palette RAM contains the same
first 16 background bytes as ROM palette 1 and the same next 16 sprite bytes
traced for animation `0x8D`. The difference is a one-pixel vertical scroll
offset: the PPU raster plan for frame 26 records `scroll_y: 255` for scanlines
0–129, while the prototype draws the captured logo tile placements at their
unscrolled tile origins. NES loopy vertical-scroll wrap from coarse Y 31/fine Y
7 makes the captured glyph rows appear one screen pixel lower. In a raw RGB
comparison, moving the Godot logo/background image content down one pixel
matches all 3,600 pixels in the complete logo comparison region (x=104–175,
y=90–139) against both the PPU reconstruction and the captured FCEUX frame;
at zero offset, the 409 differences remain. This diagnoses the glyph mismatch
as omitted PPU scroll semantics, not incorrect tile IDs or CHR patterns. The
isolated presenter still lacks the source-timed PPU scheduler and remains a
prototype. The renderer now applies this proven background-only y=1 offset;
the screen-space OAM sprite remains unshifted. The post-edit Godot runtime was
not directly recaptured in this pass, but applying the same per-layer transform
to the prior direct viewport capture yields 61,440/61,440 exact pixels against
the PPU reconstruction, with the sprite region preserved.

The frame-26 glyph placements are captured nametable tile IDs, not guessed
letter art: row 12, x=13–21 is `28 29 2C 2D 38 37 39 3C 3D`; row 13, x=13–21
is `2A 2B 2E 2F 3A 2A 3B 3E 3F`; row 15, x=14–20 is
`14 0A 07 03 14 07 12` (hex). Their pixel patterns decode from ROM CHR pages
124–127 selected for the upper raster band in
`reference/diagnostics/rom_frame_000026.json`; the captured tile map and
palette attributes are in
`reference/rom_extract/intro/background_00_nametable_layout.json`. The exact
evidence and comparison procedure are recorded in
`reference/rom_extract/intro/logo_frame26_glyph_trace.md`.

## Cold-start timing trace (2026-10-24 capture)

The ROM stream at PRG-bank-3 CPU `$A020` begins with byte-verified commands
`E8 01`, `F9 00`, `FB 01 8D`, `E9`, `DF`, `EA`, then `ED 58`. In the source
The source-frame palette and PPU write trace corrected an earlier assumption:
the frame-26 reconstruction is a later composition target, not the first logo
frame. The fresh power-on capture has all-zero palette bytes in frames 0–8,
`$0F` across all palette entries in frames 9–12, and its first non-`$0F` palette
entries in frame 13. Logo nametable writes occur at frames 10–11, and the
display-update routine restores `PPUMASK=$1E` at cycle 1177 of frame 13 after
the palette update. This bounds the first color-capable logo state to source
frame 13, but does not locate its exact first lit pixel/scanline because the
capture API lacks PPU dot/scanline timestamps. A separate sparse screenshot
set corroborates that an early logo image exists, but its frame numbers have a
different session origin and cannot be aligned to this clean power-on replay.

The script pointer is at `E9` (`$A027`) around frame 10, `DF` (`$A028`) around
frame 27, and `EA` (`$A029`) around frame 267. The `$DF` duration is 240 from
the ROM pause table; the observed pointer interval is consistent with that
count, with a one-frame ambiguity between dispatch, scheduler yield, and
frame-end sampling. The following `$ED 58` cue is reached around frame 282.
During frames 268–281 the screen update repeatedly masks rendering while
changing palette entries; frame 282 has an all-`$0F` palette and a large PPU
data transfer. This supports a multi-frame fade/clear, but not the exact first
all-black displayed scanline/frame.

The capture also records E8's MMC3 IRQ latch/reload `$80` and enable from frame
9 onward, plus PPU mask/control/scroll updates. It has CPU-cycle offsets but
no per-event PPU scanline/dot, so the raster and render edge remain partly
unmapped. The current presenter calls `begin()` immediately in `_ready()` and
advances abstract VM ticks at 60.0988 Hz; it still skips the real cold-start
timing and must remain a composition/logic prototype, not a source-timed
scheduler. The full evidence and explicit gaps are in
`reference/rom_extract/intro/cold_start_ppu_timing_trace.md`.
