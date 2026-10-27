# Repeated Tecmo logo loop: source and Godot comparison

Checked 2026-10-25 against the supplied ROM
(`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`) and
the indexed FCEUX opening capture.

## ROM behavior recovered for this pass

The cutscene dispatcher records `FE 20 A0` at source frame 4207 and returns
the event-stream cursor to `$A020`; the loop handler changes the pointer, not
the rest of the scene state. The repeated script then runs:

| Source frame | ROM action | Observed effect |
| ---: | --- | --- |
| 4207 | `FE 20 A0` | Return to cutscene stream `$A020`. |
| 4207 onward | `E8 01`, `F9 00` | Select the Tecmo Theatre preset/background and load its source data. |
| 4209 | `FB 01 8D`, `E9` | Select animation `$8D` and begin the ROM fade-up/screen-enable path. |
| 4226 | `DF` | The fully bright logo remains until the later fade. |
| 4466 | `EA` | Begin the ROM fade-down and clear path. |
| 4481 | `ED 58`, `DC` | Emit the opening sound cue and enter the 60-release wait. |

The first implementation used absolute source-frame limits for showing the
logo, which suppressed this second pass. The presenter now derives logo
visibility from the current background, the E9 screen-enable state, and
whether the EA clear has run. E9 also resets the fade state. Earlier F3/F5
scene effects mutate the presenter's working palette, so the repeated E9 path
reloads the exact source palette bytes before rebuilding its fade:

- Background palette: ROM file `$D020–$D02F`, selected by background-00 record
  `reference/rom_extract/intro/background_00_layout.json`.
- Animation `$8D` sprite palette: ROM file `$D670–$D67F`, matching
  `reference/rom_extract/intro/animation_8D_sprite_palette.bin`.
- FCEUX PPU palette RAM at `$3F00–$3F1F` matches the ROM fade model at source
  frames 4212 (level 1), 4226 (level 15), 4475 (level 6), and 4480 (level 1);
  frame 4481 is the black `$0F` palette.

## Direct render comparison

Godot was run with its audio driver set to `Dummy`; no emulator audio was
started. The direct renderer capture in
`reference/diagnostics/repeated_logo_loop_direct_20261025/` contains every
source frame 4207–4481 and compares them with the same source-frame rows in
`reference/opening_full_frame_capture_20261025_101014/screen_index.csv`.
All 275 frames are 100% exact RGB and 100% foreground exact. The renderer did
24 viewport readbacks and reused identical rendered state for 251 held frames.
The PNGs and metrics are comparison evidence only, not runtime assets.

The prior complete opening capture predates this repeated-logo change. Replacing
only its 275 rows with the new direct capture yields
`reference/diagnostics/repeated_logo_loop_direct_20261025/merged_full_opening_metrics.csv`:
95.95% mean exact RGB and 70.48% mean foreground-union exactness over all 4,693
opening frames. Other scene mismatches remain. The direct captures establish
this loop's rendered output for the sampled FCEUX index; they do not imply that
the whole intro or soundtrack is exact.

The render code still does not simulate every 6502 cycle or PPU dot. No such
gap was visible in this loop's end-to-end frame comparison. Continue tracing
source timing for other sections rather than treating a passing interval as a
general timing proof.
