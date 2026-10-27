> **Evidence update (24 Oct 2026):** The FC-counted entry-0 parse is obsolete. The corrected live trace contains 585 dispatches: first pass `$A020` through `$FE` at `$A29E`, whose bank-0 `$8862` handler unconditionally jumps back to `$A020`; then 34 replay dispatches through `$A050`, where Start/title transition changes the shared pointer to `$00E8`. FC at `$A054` reaches `$8837` and resumes at `$A055`. See `reference/rom_extract/intro/cold_start_observed_dispatch.json` and `reference/rom_extract/intro/title_transition_pc_trace.md`.

# ROM-driven opening integration: first safe slice

> **Status (24 Oct 2026):** This proposal's runtime audit below is historical.
> `scenes/main.tscn` now opens `scenes/opening_source_runtime.tscn`, not the
> frame-manifest controller. The source-command presenter runs the ROM-backed
> intro command stream and offline ROM-driver audio render, then hands Start
> to the ROM-CHR title endpoint through a 30-frame black transition. The
> same-input PPU capture shows all 32 palette bytes as `$0F` on frames
> 4662–4691 and the title palette restored on frame 4692, supporting the black
> interval despite the `$17` loader's queued nametable updates. Silent live
> traces verify the F8/title-entry source pointers and all 240 background
> queue packets. `scripts/title_rom_handoff_queue.gd` now derives packet groups
> from the ROM `$3D` queue-capacity rule and encoded packet sizes; the output is
> the observed 26×9+6 pattern. It commits on modeled next-frame edges, then
> reveals the title when the ROM palette/cursor packets complete at elapsed
> frame 31. The initial three-frame producer release and CPU/NMI subframe timing
> remain capture-aligned. The title endpoint is pixel-exact in Godot; full intro
> raster/audio comparison remains open.

## Runtime audit

`scenes/main.tscn` currently enters `scenes/opening_controller.tscn`. The
controller plays 929 ROM-derived, pre-rendered frame textures from
`assets/opening/intro/frame_manifest.json` and a rendered audio timeline. It
does not instantiate `RomCutsceneVm`; script command order, waits, scene state,
and the frame player therefore have separate authorities today. The title
menu is separately rendered from ROM-derived title resources.

The existing VM is an isolated prototype whose JSON event array preserves a
withdrawn historical parse; do not treat it as the observed command stream.
The new dispatch trace verifies handler entries and continuation pointers, but
does not yet encode complete vector side effects or operand semantics. The
captured run ends during replay at the title handoff, so it establishes a
bounded execution trace rather than a terminal cutscene boundary. The 641-byte
pointer span remains a byte extract, not an execution boundary. The claim that
FC at `$A1B0` consumes `$A2A1–$A2A5` is withdrawn; `$FE` at `$A29E` is verified
as an unconditional jump to `$A020`.

Independent bus records associate pointer samples `$A09B–$A0A3` with `$2007`
writes at frames 837–845, without a proven FC-payload relationship. At these
writes `$2000=$84`, so PPUDATA increments PPUADDR by 32: the zero-write
addresses are `$2249–$2251`, followed by writes at `$2269–$2271`. These are
register addresses, not proven final render coordinates or raster visibility;
end-of-frame RAM pointers are one byte past the corresponding in-frame source
event. See `reference/rom_extract/intro/fc_first_payload_ppu_trace.md`.

The VM models command state, compact waits, F2-paced glyph reveals, and an EB
wait, but the former `$A326` EB event's presence in the cold-start stream is
unverified after the FC correction. Do not rely on its absolute encounter
frame until the stream has been reparsed.
The generic sprite
prototype supports timed and static ROM animations, including `0x8D`; its
palette operand is traced to ROM `0x00D670`, matching the frame-100 PPU palette.
An isolated background-00 renderer and first-six-command logo presenter now
exist. The renderer uses the observed frame-26 nametable tile map with the
original ROM CHR and palette; a Godot preview now shows the full lettering and
character. The initial missing-sprite defect was a JSON number-type mismatch
and is fixed. Frame-26 OAM shadow entries and CHR selectors match the ROM
descriptor data, but the tile-map-producing ROM table, the full E8 raster
configuration/consumer chain, visible PPU commit edge, and full source-resolution
pixel/timing comparison remain open. There is no combined OAM/PPU presentation
scheduler.

## ROM code trace: logo preset, background load, and PPU queue

The supplied ROM's bank-0 command vector table is at CPU `$8545` (file
`0x000555`): `E8` dispatches to `$8574` (file `0x000584`) and `F9` to `$8813`
(file `0x000823`). For the opening's `E8 01`, the handler reads operand `01`,
calls `$8920`, then resumes the interpreter. `$8920` calls `$9DEE` with X=`$13`;
the helper counts set operand bits and adds X for each one, so `$01` produces
`$EC/$ED = $13/$00`. `$8920` adds `$BF` to the high byte, giving CPU source
pointer `$BF13`; in bank 6 this is ROM file `0x00DF23`. The exact 19-byte record
is `40 80 00 22` followed by fifteen zero bytes. `$8920` maps bank 6, waits on
`$78`, copies source byte 0 to `$79`, clears `$7A`, and copies source bytes
1–18 to `$7C–$8D`, leaving `$7B` untouched. The bank-1 PPU/raster setup routine
consumes `$79` as an MMC3 IRQ reload setting and uses `$7A/$7B` in PPU address
or scroll setup. The full meaning of `$7C–$8D` and the preset's complete raster
schedule remain unresolved. `$05FB` is not set by this E8 path: source-frame-8
RAM has `$05FB=$0F` and `$EC/$ED=$13/$00`. See
`reference/rom_extract/intro/e8_preset_01_trace.md` for the byte and capture
trace.

`F9` clears bit 2 of `$5B`, reads the background ID into `$ED`, and calls
`$8AF7` (file `0x000B07`); `FA` sets bit 2 and uses the shared loader. The
loader maps PRG bank 7, reads the background pointer table at `$A000`, and
parses the background record. For background `00`, the existing byte-exact
record is `7C 7E 81 01 03 1B 22 23 24 00 A0` at file `0x00E0E4`: the first two
bytes are retained in `$75/$76`, palette index `$01` in `$48`, followed by
layout metadata. It issues nametable-clear operations through `$9071/$9076`
and `$98E8`, processes the metatile data, then copies `$75/$76` into `$8E/$8F`
before restoring the selected bank. The trace establishes the loader path and
RAM staging fields; it does not yet establish every CHR mapper write or the
visible commit frame for this particular background.

The background-00 path is now traced to two distinct one-count task yields: `$8BB0` in the loader and `$9B2E` when the observed `$0628=$39`, `$0629=$04` reservation reaches `$3D`. Saved task returns and local ROM bytes support both wait sites; the exact within-frame NMI/resume phase remains unresolved. See `reference/rom_extract/intro/f9_task_timing_trace.md`.

There is a separate, byte-verified **generic** vblank PPU queue. The ROM vector
bytes at file `0x04000A–0x04000F` are `00 C5 F0 FF 06 C5`, so NMI enters `$C500`
(fixed-bank file `0x03C510`) and jumps to `$C76E`. That handler writes OAM,
calls `$C8FB` (file `0x03C90B`), and later writes the PPU mask shadow `$21` to
`$2001`. `$C8FB` consumes pending entries counted by `$0498`, reads their
metadata from `$0499–$049B`, and emits packet writes through `$2006/$2007`; it
also consumes a second stream in `$04A5`. This proves that those queued PPU
packets are committed by NMI. The complete producer path from this opening's
`E8 01`/`F9 00` operations into those queues has not been established, so it
does not prove the logo's specific upload latency or first-visible frame.
`$20/$21` are shadow values written to `$2000/$2001`; `E9` itself performs a
yield and calls `$997E`, but its nested rendering path has not been reduced to
a proven logo visibility transition.

## Recommended first integration slice: cold Tecmo Theatre logo

Use the first six source events in cutscene 0 as one bounded vertical slice:

1. `E8 01` selects visual preset 1.
2. `F9 00` loads background 0.
3. `FB 01 8D` starts animation `0x8D`.
4. `E9` enables the screen.
5. `DF` waits 240 script ticks.
6. `EA` disables and clears the screen.

This is preferable to starting with dialogue: it has no text tile decoding,
portrait state, or incremental text reveal, and its sprite stream is static.
The animation data identifies frame `$B15B` (bank 10, ROM file `0x01516B`),
and the sprite decoder has the original descriptors and CHR selectors. The
frame-100 OAM sample documents an exact 40/40 entry match. The cold-start
sequence JSON and full cutscene VM both preserve the source command bytes.

Two isolated prototypes now cover adjacent parts of this sequence. The logo
presenter at `scenes/prototypes/cold_start_logo_presenter.tscn` composes the
ROM-derived background and sprite renderers and uses the traced sprite palette
at `0x00D670`. The source-command presenter at
`scenes/prototypes/cold_start_source_command_presenter.tscn` verifies consumed
script bytes through `ED $58`, models the observed command/frame order, and
applies the source-derived EA fade conversion with its observed one-NMI palette
packet delay and frame-282 clear end-state. Both are separate from the main
scene; the latter's full PPU edge and raster timing remain unresolved. Do not
use the existing composed PNG as the new background layer: it already
contains the sprite and would double draw it.

## Evidence still required before that slice can drive the main scene

- **Cold-start entry alignment:** source-pointer snapshots show `$A027` (E9
  pending) at frame 10, `$A028` (DF pending) at frame 27, `$A029` (EA pending)
  at frame 267, and `$A02C` after sound cue `$58` at frame 282. The command
  order is measured, but the exact visible logo onset is not; frame-end RAM
  snapshots leave up to a one-frame edge.
- **Wait/frame relation:** the `DF` 240-tick span is supported by the 240-frame
  pointer interval from `$A028` at frame 27 to `$A029` at frame 267. EA's
  screen-clear path takes about 15 observed frame states before the cue at 282.
  This does not yet prove the visible PPU commit boundary.
- **Background 0 renderer input:** F9's static 4x4 blocks do not contain the
  visible logo letters. The corrected prototype draws the frame-26 nametable
  tile placements from mapping metadata while decoding patterns from ROM CHR
  banks `[124,125,126,127]` and background palette record 1. PPU writes at
  `$218C–$21F4` in source frames 10–11 and candidate ROM byte runs at
  `0x02745E–0x02746D` are documented; their producer/consumer relationship is
  not proven. This validates the reconstructed frame layout, not its complete
  upload or raster behavior.
- **Animation `0x8D` runtime support:** a generic sprite renderer now selects
  frame `$B15B`, its ROM CHR selectors, and descriptor geometry. The sampled
  frame-26 OAM shadow matches all 40 decoded entries at origin `(80,96)`; the
  four PPU CHR pages byte-match ROM selectors `[124,113,82,83]`. Static
  tracing resolves the palette operand
  `0x36` through `$9ADA` to ROM file offset `0x00D670`; its 16 bytes match the
  frame-100 PPU `$3F10–$3F1F` bytes. The logo-specific PPU commit frame and
  source-resolution combined image match remain unverified. Godot's MJPEG
  movie preview is chroma-subsampled, so it is only a visual check.
- **Start interruption:** source code confirms that the outer loop polls Start
  and queues sound-stop `$01`; existing silent captures confirm the held input
  frame, 30 black frames, and title entry at tested points. The Godot event VM
  still needs to share this interrupt path, and audio cutoff/tail at arbitrary
  press frames remains unverified.
- **PPU commit path:** the generic NMI queue applies staged updates through
  `$2006/$2007`, but the complete E8/F9 logo-specific staging chain and its
  visibility latency are unresolved. Do not infer the logo's commit timing
  from the generic NMI routine alone.

## Integration order

1. Prove the opening preset/background staging and first-visible PPU edge;
   sprite palette contents are byte-verified at ROM offset `0x00D670`, while
   background palette records and EA fade packet conversion are also mapped.
2. Compare the isolated source-command presenter at source-frame boundaries,
   including source-resolution pixels, the 240-tick hold, EA fade, and exact
   PPU visibility/clear edges.
3. Integrate the field-runner region as the next dynamic slice. `F8 0A` is
   traced to bank-2 routine `$A602` and only resets `$000D/$000E`; it is not
   the per-frame movement routine. Animation `0x6E`, its ROM sprite
   descriptors/timing, and the runner's observed Q8.8 origin trajectory are
   documented in `reference/rom_extract/intro/runner_motion_trace.md` and `reference/rom_extract/intro/animation_6e_runtime_trace.md`. Adjacent RAM
   records support the capture-derived state recurrence `v[n+1]=v[n]+a`, `x[n+1]=x[n]+v[n+1]`, with
   position at runner record `$0568+06`, velocity at `+0C`, and increment at
   `+0E`. F7 dispatch to `$93A6` is decoded as packed mode/sign writes at
   `($94)+08..0A`, but the record-pointer bridge to the runner's motion fields
   and handling of its third raw byte remain unresolved. Build an isolated
   presenter from background 1 and animation `0x6E`, using the captured
   Q8.8 update as a provisional model. Compare its OAM positions and layer
   timing before connecting it to the opening controller. FC byte boundaries
   are not parsed reliably yet. Independent bus records associate pointer
   samples `$A09B–$A0A3` with `$2007` writes at frames 837–845. With `$2000=$84`,
   clear addresses are `$2249–$2251` and following writes `$2269–$2271`; these
   are register writes, not confirmed screen coordinates or evidence of an FC
   payload. Trace the producing routine before using them for dialogue.
4. Route each region into `scenes/opening_controller.tscn` only after its
   source-command timing and rendered output have been compared. Leave
   `fidelity_verified` and `complete` false until the whole requested
   opening/title slice passes.

This proposal does not claim the logo slice is integrated into the playable
main scene or exact. It identifies the route from the ROM command VM and
decoded graphics toward the main presenter without silently treating the
current frame timeline as ROM script execution.
