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

## Historical Godot capture path — pre-live-menu baseline (2026-10-28)

`tools/diagnostics/verify_kickoff_recorded_input_path.gd` replays the retained input edges through the current `KickoffRouteRuntime` and stops at source frame 8953 with stage `first_action_menu_pending`. It saves `route._visuals.screen.get_rendered_background_image()` to `/tmp/ct2_godot_first_action_menu_recorded_input_8953.png` (and selected earlier frames). That image is the ROM-derived background layer only; CanvasItem actor layers and the not-yet-produced first command menu are excluded. The script does not currently capture a complete endpoint viewport.

`tools/diagnostics/verify_kickoff_route_to_first_menu.gd` compares the route's generated PPU-memory dictionary against the retained frame-8953 PPU bytes. It checks tile and attribute counts, not pixels. The new `tools/diagnostics/compare_first_menu_visible_output.gd` compares the 256x240 Godot background capture against the retained frame-8953 FCEUX screenshot, after verifying the same-input CSV hash `87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e` and screenshot hash `cc30a78af0f1e4d5d6ceb1a78d023caec0782afcbef43539b4d1607902130559`. At source frame 8953, 31,929/61,440 RGB pixels match exactly (51.968%); 29,511 differ, with mean absolute channel error 68.2071. This is a direct visible-image comparison, not a claim of parity: the Godot capture excludes the field actors, score/status overlays, and the first command panel that are present in FCEUX. The residual also includes field/map/palette composition differences. The diff is written to `/tmp/ct2_first_menu_visible_output_diff_8953.png`.

The menu component was also rendered from the hash-pinned ROM-derived receiver/player provider, with slot 6/player `$08`, energy 397, no selected action, and the ROM-defined 13-tick label behavior available. Its 96×80 descriptor-$03 window was compared against the same frame-8953 screenshot region, accounting for the project crop from 240 to 224 lines. The comparator now applies the ROM-observed post-IRQ CHR selectors R0=`$00`, R1=`$02`; at the unregistered project crop it matches 6,214/7,680 panel pixels (80.911%), with 1,466 differing and mean absolute RGB channel error 48.6758. A separate validation-only vertical registration search over −8..+8 Godot rows finds 7,680/7,680 exact pixels at +6 rows. This establishes that the isolated panel bytes/text/palette render exactly when vertically registered, but does not establish the correct live viewport/IRQ alignment: the IRQ scanline, dot, and first affected output pixel remain unresolved. The runtime is not shifted.

The +6 registration is an empirical comparison result, not a decoded placement rule or a justified runtime correction. Descriptor `$03` puts its first border row at PPU `$2252`, nametable row 18 / pixel y=144; the isolated Godot component uses zero scroll and the project crop, so its border begins at viewport y=136. The FCEUX endpoint is a live route screenshot with the gameplay IRQ path active, while the component capture deliberately disables raster events. FCEUX's Lua documentation gives screen-pixel coordinates as y=0..239 and says the NTSC display uses y=8..231; `gui.gdscreenshot()` exports the image buffer's raw pixels ([FCEUX Lua function list](https://fceux.com/web/help/LuaFunctionsList.html)). Thus the project's −8 crop accounts for the documented visible window, but the extra +6 cannot be attributed to that crop alone. Existing IRQ evidence confirms the CPU-side `$2006/$2000/$2005` writes but lacks scanline/dot and first-output-pixel timing, so it cannot yet distinguish live raster placement from another mismatch between the two capture paths. Keep the offset validation-only until that source timing is resolved.

Run the repeatable comparison with a rendered compatibility viewport:

```sh
godot --path . --rendering-method gl_compatibility --script tools/diagnostics/capture_compare_first_action_panel_component.gd
```

This capture reads back the Godot root viewport, so `--headless` with the Dummy rendering backend is insufficient and fails before pixel comparison. The diagnostic saves `/tmp/ct2_godot_first_action_panel_component_8953.png` and `/tmp/ct2_first_action_panel_component_diff_8953.png`. It isolates the panel component and its synthetic source-state setup; it does not prove the route reaches the panel or that its live scroll/CHR/raster state matches.

## Next comparison after live-route integration

The route and actor presenter now reach this endpoint. Continue comparing the complete visible viewport and isolate differences by field, actor, status, and panel regions. A PPU-only reconstruction comparator should wait until a trace preserves per-scanline PPU/CHR/scroll state (or until the comparison is restricted to a proven stable region).

## Live route verification — 2026-11-09

The recorded post-title input path (`post_title_inputs.csv`, SHA-256
`87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e`) now
passes through the ROM-owned scheduler boundary `$D5EA` at source frame 8953.
The menu renderer has returned and the first-action wait is live; the recorded
route has neither selected nor confirmed a soccer action and has not entered
Continue. The route verifier exits successfully at this boundary.

The route passes the live slot-$05 boundary's verified RAM image to the actor
presenter. It reports player `$08`, mirror `$40`, scroll `$00`, clip `$00–$FF`,
and 41 sprites built from the ROM animation, actor descriptors, CHR, and palette
resources. The context is marked `trace_state_used=false` and
`emulator_data_used=false`. Actor placement/palette pixels are still part of
the visible comparison below, not assumed exact from sprite count.

The same-input FCEUX endpoint screenshot (hash
`cc30a78af0f1e4d5d6ceb1a78d023caec0782afcbef43539b4d1607902130559`) is
256×240. The Godot root viewport capture is 1024×896 (integer 4× output); the
comparator nearest-downscales it to 256×224 and compares against the documented
FCEUX visible rows 8–231. At frame 8953, 36,945 of 57,344 RGB pixels match
exactly (64.427%); 20,399 differ; mean absolute channel error is 55.054.
The Godot viewport PNG SHA-256 is
`6a2e0bdfc353732f267c80643c1929df2a3388079392231ea01c0a278c255080`.
These values are a measured mismatch, not a parity claim. The full image and
difference PNG are temporary local validation outputs under `/tmp`; neither is
loaded by game runtime.

The recorded-input route diagnostic also exercises all four keyboard and
D-pad directions after capturing the unselected endpoint image. Each maps to
the ROM command and the route stays in the menu; no confirmation signal is
emitted. The separate menu integration check verifies the 13-source-tick label
blink and also remains no-confirmation. The full-route diagnostic mutes its
Master bus so the validation replay does not play audio audibly.

A Linux PCK was exported to `/tmp/ct2_first_menu_validation.pck`. The runtime
pack verifier passed: required ROM-derived resources and audio assets exist;
the ROM, emulator, save states, and reference captures are absent. The
first-menu integration check and application startup pass from the PCK. The
full recorded-input route also reached `$D5EA` with the PCK mounted as the main
pack. Its diagnostic harness reads the same-input CSV and RAM/PPU oracles from
the local project for validation only; those files remain absent from the
package and are not runtime inputs.

Remaining gaps: full-route visible parity (including the unresolved panel
registration, field/raster composition, and actor pixels), source-cycle PPU
timing, and exact route audio event/PCM parity. The isolated panel's
validation-only +6-row registration remains
unexplained and must not be applied as a runtime correction without source
timing evidence.

## Raw-to-visible crop correction — 9 November 2026

The earlier viewport comparison used a 256×224 Godot viewport against FCEUX
raw rows 8–231, but `RomPpuNametableScreenRenderer` draws a 256×240 image at
the origin. The route therefore exposed raw rows 0–223. The endpoint's live
comparison contract already defines rows 8–231 as the visible 224-line
window. `KickoffCutsceneVisuals` now applies that single shared eight-line
presentation crop to the route, keeping the field, actor, and panels in one
coordinate space; raw PPU rendering remains 256×240.

The same recorded input and screenshot were replayed after this change. The
root viewport now matches 53,020/57,344 RGB pixels (92.460%; mean absolute
channel error 12.5902), up from 36,945/57,344 (64.427%; 55.054). The new
Godot viewport PNG SHA-256 is
`827b7d26a3d06eeb3b1674ffab0387ca61c949b4d515b7b538cdbd970dd2d207`.
The comparison still reports 4,324 different pixels and does not establish
full visual parity.

The validation-only region audit after cropping reports 100% exact pixels for
the mini-field and for the main field outside the actor region; the pitch is
97.04%, the actor region is 78.90%, and the full panel region is 89.01%. The
left, center, and right panel regions are 89.73%, 94.63%, and 84.94%. This
localizes the remaining visible work to actor pixels and panel/status detail,
not a further global vertical registration. The isolated panel prototype's
historical +6-row search does not justify another runtime offset.

The crop change was followed by the full recorded-input route replay. It still
reaches `$D5EA` at source frame 8953, passes keyboard and D-pad navigation, and
does not confirm an action or enter Continue. The capture runs with the Master
audio bus muted. Same-input visual differences, earlier `$55/$53` queue
timing, route PCM, source-cycle PPU/APU timing, and a fresh packaged-route audit
remain open.

## Current live comparison and package check — 9 November 2026

After the crop change, the field renderer still reapplied accumulated title
`$2007` palette writes over the ROM field palette profile. The field presenter
now clears that stale overlay when the field profile is installed. The live
palette is `0F 1A 18 30 0F 36 25 30 0F 21 31 30 0F 3A 1A 1A`, matching ROM
background palette `$02`; this fixes the prior grayscale output.

The same-input root-viewport comparison now reports 54,618/57,344 exact RGB
pixels (95.246%), 2,726 differing pixels, and mean absolute channel error
8.1529. The mismatch is concentrated in the actor and lower HUD/panel. A
separate actor-only comparison reports 1,407/1,407 opaque actor pixels exact
after the shared 8-row crop; that does not prove correct actor composition or
frame timing. The new comparison output is
`/tmp/ct2_first_menu_visible_output_diff_8953.png`.

The live endpoint keeps MMC3 R0/R1 at `$3C/$2E`, while the same-input FCEUX
post-IRQ endpoint reads `$00/$02`. The isolated ROM-derived panel renders
exactly with `$00/$02`, but the needed IRQ scanline/dot and first affected
pixel are unmeasured. Its +6-row registration remains validation-only. No
unverified bank switch or vertical offset was added to production.

The Linux PCK content verifier passes and confirms the supplied ROM payload,
emulator/save-state files, and reference captures are absent while required
ROM-derived runtime resources and audio are present. The PCK-mounted ordinary
input route reaches the visible first menu at frame 8945 with no ROM/emulator
mounted, starts unselected, and passes keyboard/D-pad navigation. The source
route verifier captures the same endpoint at its stable frame-8953 comparison
boundary. This verifies runtime independence for the scoped route; the PCK
still includes ROM-derived files under `reference/rom_extract/` that runtime
consumers load.

Remaining visual limits are the 2,726 viewport pixels, actor/menu composition
details, and unresolved raster/IRQ phase. The route is verified to the scoped
menu endpoint, not claimed pixel-identical.

## Cursor cleanup and refreshed full-frame comparison — 9 November 2026

The prior Godot endpoint retained the pre-match `MEETING` cursor after entering
the first command menu. `KickoffCutsceneVisuals.present_first_action_menu()`
now removes that menu-only CanvasItem before presenting match actors and panel
content. This removes the stray lower-left marker visible in the previous
Godot endpoint. It does not change the ROM-derived match OAM or background.

The ordinary recorded-input route was replayed after this fix and still reaches
the unselected `$D5EA` command menu at frame 8953. Keyboard and D-pad navigation
passes without action confirmation, and Continue remains unentered. The
refreshed same-input 256×224 comparison reports 57,253/57,344 exact RGB pixels
(99.841%), 91 differing pixels, and mean absolute channel error 0.4047. The
Godot viewport PNG SHA-256 is
`eb4a52328a0ca0b38be732b0206516779fe567669073fd44cb0922207a6632c1`; the input
and FCEUX screenshot hashes are unchanged from the preceding section. The
remaining visible differences include menu energy 400 in Godot versus 397 in
the FCEUX endpoint and a small number of panel pixels. The ROM's first 3-point
run-cost rule is known, but the live `$D193` asynchronous scheduler continuation
does not yet return to `$E1F1` and execute `$E1F7->$E2BC`; the Godot endpoint
must not be patched to 397 as a screenshot-specific value.

The route and comparator were run with Godot 4.7.2. The route replay keeps audio
muted. Exact per-pixel parity, the missing field-loop stamina transition,
source-cycle PPU phase, and audio PCM parity remain open.

## Rechecked endpoint after source-route fixes — 9 November 2026

The current same-input comparison at frame 8953 reports **57,344/57,344 exact
visible RGB pixels** at 256×224, zero differing pixels, and mean absolute
channel error 0.0000. The FCEUX image remains comparison-only; the Godot image
is rendered from the production route. Input CSV SHA-256:
`87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e`;
FCEUX reference SHA-256:
`cc30a78af0f1e4d5d6ceb1a78d023caec0782afcbef43539b4d1607902130559`;
Godot viewport SHA-256:
`98ef047d3ed101289006e694c3cc1c31b7f6fad7e5a5223d164518b71ed5dea9`.

This supersedes the earlier endpoint pixel counts above. It establishes only
the captured endpoint under this recorded input sequence; intermediate
frames, subframe timing, and audio parity remain separate checks. Latest
comparator result: `PASS` from
`tools/diagnostics/compare_first_menu_visible_output.gd`.

## Final route closeout status — 10 November 2026

The earlier 91-pixel and energy-400 statements in this report are historical.
The refreshed frame-8953 comparison is 57,344/57,344 visible RGB pixels exact
at 256×224. The live stamina receipt and all eleven player records match the
same-input FCEUX frame-8863 RAM snapshot exactly; the holder energy is 397. The
production Godot AudioServer route mix matches the same-input FCEUX PCM across
3,036,345 fixed 44.1 kHz samples from the `$55` queue at frame 4816 through the
stable frame-8953 menu endpoint, after a measured 66-sample capture-start
prefix. The fresh Linux PCK passes content verification and ordinary-input
route replay: it opens the menu at frame 8945, holds it unselected through
frame 8953, passes keyboard/D-pad navigation, and omits the ROM, FCEUX,
validation captures, and reference images. Physical hardware timing and
intermediate-frame PPU phase remain unclaimed; these results apply to the
endpoint and scoped AudioServer capture.

## Final route closeout status — 10 November 2026

The earlier 91-pixel and energy-400 statements in this report are historical.
The refreshed frame-8953 comparison is 57,344/57,344 visible RGB pixels exact
at 256×224. The live stamina receipt and all eleven player records match the
same-input FCEUX frame-8863 RAM snapshot exactly; the holder energy is 397. The
production Godot AudioServer route mix matches the same-input FCEUX PCM across
3,036,345 fixed 44.1 kHz samples from the `$55` queue at frame 4816 through the
stable frame-8953 menu endpoint, after a measured 66-sample capture-start
prefix. The fresh PCK is checked separately for content and ordinary-input
route independence. Physical hardware timing and intermediate-frame PPU phase
remain unclaimed; these results apply to the endpoint and scoped AudioServer
capture.
