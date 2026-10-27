# E8 preset 1: ROM and RAM trace

## Source identity

This trace uses the supplied Turkish ROM, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
Emulator RAM and PPU captures are execution evidence only; no captured image or
audio is used as a runtime asset.

## Handler and source record

The bank-0 command vector at CPU `$8545` (file `0x000555`) dispatches `E8` to
`$8574` (file `0x000584`). That handler reads operand `01`, calls `$8920`, then
resumes the script. `$8920` is bank-0 file `0x000930` and begins:

```text
A2 13       LDX #$13
20 EE 9D    JSR $9DEE
A5 EC       LDA $EC
18          CLC
69 00       ADC #$00
85 EC       STA $EC
A5 ED       LDA $ED
69 BF       ADC #$BF
85 ED       STA $ED
```

`$9DEE` is bank-0 file `0x001DFE`. It initializes `$EC=0`, stores A in `$ED`,
then performs eight 16-bit shifts. For each set bit shifted out, it adds X to
`$EC`. Thus operand `$01` with X=`$13` yields `$EC/$ED = $13/$00`; `$8920`
adds `$BF` to the high byte, yielding CPU source pointer `$BF13`.

The handler maps PRG bank 6 through `$C4B9`, waits for `$78` to clear, and reads
19 bytes from `($EC),Y` at `$BF13`. In the supplied mapper layout, bank 6 at CPU
`$A000–$BFFF` maps `$BF13` to ROM file offset `0x00DF23`. The exact record is:

```text
40 80 00 22 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
```

The copy writes source byte 0 to `$0079`, explicitly clears `$007A`, then for
Y=1 through `$12` writes each source byte to `$007B,Y`, i.e. `$007C–$008D`.
It therefore copies 19 ROM bytes into `$79` and `$7C–$8D`, inserts zero at
`$7A`, and leaves `$7B` untouched. This is a 20-byte address span with a
one-byte gap, not a contiguous copy.

## Proven consumer and visual role

The bank-0 command handler and `$8920` do not write `$2006/$2007`; they select
bank 6 and populate the RAM configuration above. A bank-1 routine at file
`0x004050–0x0040B5` (CPU `$A040–$A0A5` when that bank occupies `$A000`) uses the
first fields as PPU/raster state:

- `$79` gates IRQ setup. When nonzero, the routine doubles it and writes the
  result to MMC3 IRQ latch/reload registers `$C000/$C001`, then enables the
  IRQ. Preset 1 supplies `$79=$40`, so this path uses `$80`.
- The handler uses `$7A` and `$7B` in PPU address/scroll setup. For this preset
  `$7A` is the inserted zero; the capture shows `$7B` is zero at this stage.
- The setup routine also changes PPU control/scroll and programs MMC3 CHR
  banks. This can affect the rendered logo, but it is not itself the title
  nametable tile payload.

The exact consumers and meanings of every byte in `$7C–$8D`, and the complete
IRQ/raster schedule for this preset, are not yet reduced. Do not describe all
19 bytes as a fully decoded visual-effect schema.

## Capture cross-check and separation from title tile writes

In `reference/opening_timing_capture_20261024_131316/ram_states/ram_00008.bin`,
`$EC/$ED` are `$13/$00`, `$79–$8D` begin
`40 00 00 80 00 22 00 ...`, and `$05FB=$0F`. The frame-9 snapshot has
`$05FB=$CC`. These confirm the copied fields and show that `E8 01` did not set
`$05FB` to `$33`.

Logo tile IDs are written to nametable addresses such as `$218C–$21F4` through
PPU data writes recorded in
`reference/opening_timing_capture_20261024_131000/bus_events.csv` at source
frames 10–11. Those writes are later than the E8 setup and belong to a PPU
data-transfer path; `$8920` itself does not emit them. Current evidence
separates E8's raster/render configuration from the nametable content upload.
The complete producer chain and exact first-visible edge remain open.

## BG08 selector stream and IRQ consumer (25 Oct 2026)

The remaining frame-1522 background CHR selection is now tied to the ROM's
animation stream and the generic raster consumer, rather than the unrelated
`$A2E8` field-runner delta generator.

- The exact 19-byte preset is preserved at
  `raster_event_state/preset_01.bin` (PRG bank 6, file `0x00DF23`); the exact
  bytes are `40 80 00 22 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00`.
- `$A091` (bank 2, file `0x0040A1`) loads the initial R0/R1 pair from
  `$8E/$8F`, doubles `$79` into the MMC3 IRQ reload/latch (`$80` for `$79=$40`),
  enables the IRQ, and starts `$78` at event index 4. The `$A160` consumer sees
  marker `$80` at `$7C`; `$7D/$7E = $00/$22` supplies `$2006=$2200`. The
  terminal path `$A1C0` calls `$A1CB` with Y=`$18`, which installs the lower
  pair from `$90/$91` (frame 1522: R0=`$00`, R1=`$02`).
- The upper R0 value is animated by source bank 6's stream at CPU `$BA96`, ROM
  file `0x00DAA6`; the unchanged 9 bytes are preserved as
  `raster_event_state/bg08_chr_selector_stream.bin`:
  `80 40 02 42 02 44 02 FE FF`. The local live trace ties the `FB 02 C1 82`
  animation setup at source frame 1047 and `F5 10` at 1048 to the stream
  pointer `$BA96`. The animation handler writes `$8E = $40,$42,$44` with two
  source-frame waits, then loops. For each rendered frame, the vblank setup
  consumes the preceding stream value: at frame 1522, end-of-frame RAM has
  `$8E=$40`, while the setup R0 write used the prior frame's `$44`.
- The same-input bus trace for source frame 1522 places `$2006=$2200` at PPU
  line 129 dots 284/296, `$2000=$88` at dot 322, and `$2005=$00,$00` at line
  129 dot 340 and line 130 dot 11. It places the terminal R0=`$00` write at
  line 130 dot 143 and R1=`$02` at dot 194. The enhanced FCEUX NewPPU fetch
  trace confirms subsequent CHR reads use those selections; these timings are
  validation observations, not a per-frame runtime event table.

The current Godot source model is `scripts/opening/rom_bg08_raster_model.gd`;
the renderer consumes its source-frame CHR state and scanline/dot events in
`scripts/opening/rom_ppu_nametable_screen_renderer.gd`. It validates the
preserved preset, selector stream, and BG08 record bytes. On same-input frame
1522, the Godot comparison improved from 61.07% to 92.12% exact RGB and from
32.40% to 84.83% foreground exactness after the CHR split. The `$48` dialogue
glyphs now read from the correct lower CHR pair. A ROM-derived shared C1/82
OAM composer then raised the complete frame to 96.41% RGB / 92.84% foreground;
all 2,563 opaque sprite pixels match the FCEUX frame. The OAM shadow matches
63/64 slots, with slot 5 still unresolved. This does not finish the scene:
background/raster differences remain, and frame-1522 dot positions are a
calibrated phase while the observed IRQ dot phase varies across frames.

The pending-load carry-over is now connected in Godot. The presenter captures
the live BG03 selector pair at `F9 08`, seeds the BG08 model with `$3A/$00`,
and schedules the ROM-loaded `$40/$00` pair for the frame after the packet
producer completes. A targeted runtime diagnostic confirms frame 1047 still
uses `$3A/$00` and frame 1048 begins with `$40/$00`; the same-input bus trace
shows `$A1D7/$A1E3` writing those pairs on frames 1046–1048. The diagnostic
also renders sparse reference checkpoints at frames 1050 and 1522. This closes
the specific pair-transition gap, not the varying per-frame IRQ dot phase,
sprite/OAM composition, or whole-frame pixel mapping. See
`tools/diagnostics/verify_bg08_pending_pair_runtime.gd` and
`reference/diagnostics/bg08_pending_pair_1792878047/` for the check, plus
`later_f3_f4_palette_selection_trace.md` for the producer trace.
The subsequent C1/82 OAM reconstruction and its bounded tuple/pixel checks are
documented in `bg08_c1_82_shared_oam_trace.md`.

The capture trace remains a validation cross-check, not runtime data. The
bounded FCEUX fetch mapping and physical-PPU limits are in
`reference/diagnostics/chr_plane_nt_trace_20261025/README.md`.

## Correction to earlier notes

An earlier integration note incorrectly said `$9DEE` wrote `$33` to `$05FB`
and that `$EC/$ED` was a pre-existing pointer. Neither is true for this ROM
path: `$9DEE` calculates the record's low-byte offset, `$8920` forms `$BF13`,
and the observed `$05FB` values are not written by this E8 operation.
