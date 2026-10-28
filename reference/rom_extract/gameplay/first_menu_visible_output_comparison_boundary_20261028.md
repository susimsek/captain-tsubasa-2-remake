# First-menu visible-output comparison boundary — 2026-10-28

## Finding

The retained same-input PPU/RAM snapshots support useful ROM-memory checks, but they are not sufficient by themselves to reconstruct the complete visible FCEUX frame because they omit per-scanline raster state. A separate direct image comparison is now available: it reads the retained FCEUX screen only as a validation reference and compares its RGB pixels to the current Godot background capture. It does not reconstruct a frame from the incomplete PPU snapshot and does not feed screenshot pixels into runtime assets.

The source capture is `reference/diagnostics/kickoff_select_test_20261027/`. `capture.txt` records the fresh-start KICK OFF input route; its `post_title_inputs.csv` SHA-256 is `87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e`, matching the route input hash in the retained muted frame-8399 task trace. At source frame 8953, the directory has:

- `ppu/route_frame_008953.bin`: 16,384-byte PPU-memory snapshot, SHA-256 `da56b2c2dbe44a5864be61068bb23fe46f434cc2bc73a10489a471e4bfa2350e`.
- `ram/route_frame_008953.bin`: 2,048-byte CPU-RAM snapshot, including the RAM OAM shadow, SHA-256 `a8d4cae0ed26fa6fbc01dcdcae6f076c94c33b0c295b95eca6cdbf64270a2971`.
- `screens/route_frame_008953.gd`: FCEUX's separately retained 256×240 raw screen observation, indexed as a 15-frame sample. It can serve as a validation image, but it is a screenshot rather than a PPU state dump and must never become a runtime asset.

The PPU/RAM snapshots can check pattern, nametable, attribute, palette, and RAM/OAM-shadow bytes. Existing route checks already compare ROM-derived endpoint bytes with them: the live map candidate currently matches 452/512 visible page-2 tile IDs, with known remaining packet and attribute gaps. Those checks establish memory-byte correspondence, not final pixel output.

## Why a whole-frame render is not derivable from the snapshot alone

The first-command route changes PPU state mid-frame. The same-input IRQ audit records `$2006=$2200`, PPUCTRL/scroll resets, and MMC3 CHR bank writes from CPU cycles 16,462–16,554 of frame 8953. The available snapshot is taken after that activity; it does not preserve which CHR bank, scroll, or PPU address was active on each scanline. The exact PPU scanline/dot and first affected output pixel remain unmeasured. A static render from the endpoint PPU memory therefore cannot stand in for the visible 240-line frame.

`tools/render_emulator_ppu_frame.py` renders a selected static nametable page, pattern base, scroll, and optional RAM OAM shadow. It does not replay the route's raster IRQ writes. Its optional `.gd` palette calibration uses screenshot colors only to identify global RGB values; it does not recover the missing per-scanline state.

## Current Godot capture path

`tools/diagnostics/verify_kickoff_recorded_input_path.gd` replays the retained input edges through the current `KickoffRouteRuntime` and stops at source frame 8953 with stage `first_action_menu_pending`. It saves `route._visuals.screen.get_rendered_background_image()` to `/tmp/ct2_godot_first_action_menu_recorded_input_8953.png` (and selected earlier frames). That image is the ROM-derived background layer only; CanvasItem actor layers and the not-yet-produced first command menu are excluded. The script does not currently capture a complete endpoint viewport.

`tools/diagnostics/verify_kickoff_route_to_first_menu.gd` compares the route's generated PPU-memory dictionary against the retained frame-8953 PPU bytes. It checks tile and attribute counts, not pixels. The new `tools/diagnostics/compare_first_menu_visible_output.gd` compares the 256x240 Godot background capture against the retained frame-8953 FCEUX screenshot, after verifying the same-input CSV hash `87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e` and screenshot hash `cc30a78af0f1e4d5d6ceb1a78d023caec0782afcbef43539b4d1607902130559`. At source frame 8953, 31,929/61,440 RGB pixels match exactly (51.968%); 29,511 differ, with mean absolute channel error 68.2071. This is a direct visible-image comparison, not a claim of parity: the Godot capture excludes the field actors, score/status overlays, and the first command panel that are present in FCEUX. The residual also includes field/map/palette composition differences. The diff is written to `/tmp/ct2_first_menu_visible_output_diff_8953.png`.

The menu component was also rendered from the hash-pinned ROM-derived receiver/player provider, with slot 6/player `$08`, energy 397, no selected action, and the ROM-defined 13-tick label behavior available. Its 96×80 descriptor-$03 window was compared against the same frame-8953 screenshot region, accounting for the project crop from 240 to 224 lines. The comparator now applies the ROM-observed post-IRQ CHR selectors R0=`$00`, R1=`$02`; at the unregistered project crop it matches 6,214/7,680 panel pixels (80.911%), with 1,466 differing and mean absolute RGB channel error 48.6758. A separate validation-only vertical registration search over −8..+8 Godot rows finds 7,680/7,680 exact pixels at +6 rows. This establishes that the isolated panel bytes/text/palette render exactly when vertically registered, but does not establish the correct live viewport/IRQ alignment: the IRQ scanline, dot, and first affected output pixel remain unresolved. The runtime is not shifted.

The +6 registration is an empirical comparison result, not a decoded placement rule or a justified runtime correction. Descriptor `$03` puts its first border row at PPU `$2252`, nametable row 18 / pixel y=144; the isolated Godot component uses zero scroll and the project crop, so its border begins at viewport y=136. The FCEUX endpoint is a live route screenshot with the gameplay IRQ path active, while the component capture deliberately disables raster events. FCEUX's Lua documentation gives screen-pixel coordinates as y=0..239 and says the NTSC display uses y=8..231; `gui.gdscreenshot()` exports the image buffer's raw pixels ([FCEUX Lua function list](https://fceux.com/web/help/LuaFunctionsList.html)). Thus the project's −8 crop accounts for the documented visible window, but the extra +6 cannot be attributed to that crop alone. Existing IRQ evidence confirms the CPU-side `$2006/$2000/$2005` writes but lacks scanline/dot and first-output-pixel timing, so it cannot yet distinguish live raster placement from another mismatch between the two capture paths. Keep the offset validation-only until that source timing is resolved.

Run the repeatable comparison with a rendered compatibility viewport:

```sh
godot --path . --rendering-method gl_compatibility --script tools/diagnostics/capture_compare_first_action_panel_component.gd
```

This capture reads back the Godot root viewport, so `--headless` with the Dummy rendering backend is insufficient and fails before pixel comparison. The diagnostic saves `/tmp/ct2_godot_first_action_panel_component_8953.png` and `/tmp/ct2_first_action_panel_component_diff_8953.png`. It isolates the panel component and its synthetic source-state setup; it does not prove the route reaches the panel or that its live scroll/CHR/raster state matches.

## Smallest sound next comparison

Keep using the raw PPU/RAM snapshots for ROM-byte validation and the direct FCEUX screen solely as a comparison reference. Once the Godot route produces the menu and actor state, capture the complete Godot viewport and repeat the same-input pixel comparison. A PPU-only reconstruction comparator should wait until a trace preserves per-scanline PPU/CHR/scroll state (or until the comparison is restricted to a proven stable region).
