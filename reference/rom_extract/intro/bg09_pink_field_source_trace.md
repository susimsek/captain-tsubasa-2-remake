# BG09 pink-field source trace (frames 1779–2117)

## Scope and conclusion

This trace uses the supplied Turkish ROM (SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`) and the
same-input FCEUX capture `reference/opening_timing_capture_20261024_131726/`.
ROM bytes define the content and update logic; RAM/PPU snapshots and
`bus_events.csv` are execution evidence. The capture records CPU-cycle offsets,
but its Lua interface did not record PPU scanline/dot positions.

The pink fill missing in earlier Godot captures is produced by a ROM-driven
palette animation. BG09's field tiles
produce color index 1 with attribute subpalette 2, so they read PPU palette
byte `$3F09`. The static BG09 palette stores `$0F` there (black). At source
frame 1779, `F5 01` selects a ROM animation stream that cycles the corresponding
RAM byte `$0633` through `$30,$21,$30,$25`; the NMI palette uploader then
commits those values to `$3F09`. At frame 2034 both RAM `$0633` and PPU `$3F09`
are `$25`, which the capture's pinned FCEUX RGB palette maps to `(255,117,182)`.
This conclusion follows from ROM tile, attribute, palette, command, and bus
evidence, not from screenshot color comparison.

## BG09 content and color path

The background record at CPU `$A1C9` in PRG bank 7 is file offset `0x00E1D9`.
Its 40 bytes are:

```text
3C 3E 03 04 08 00 42 42 42 42 42 42 42 42
01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01
01 01 01 01 01 01 01 01 00 A0
```

It selects CHR 2 KiB banks `$3C/$3E` (1 KiB banks 60–63), palette index 3,
and a 4×8 metatile layout at `$2000`. Block `$42` is ROM file `0x010472`
(`AA`, eight tile IDs `$00`, then eight `$01`); block `$01` is file
`0x010021` (`AA` followed by sixteen `$01` IDs). The resulting first 16
nametable rows have tile IDs `$00` in rows 0–1 and `$01` in rows 2–15. For
frame 2034, all 512 decoded tile placements match the PPU snapshot at
`$2000–$21FF`; `$23C0–$23DF` contains the block attribute `$AA` values. Each
`$AA` selects subpalette 2 in every 2×2-tile quadrant.

With PPUCTRL `$2000=$88`, background pattern reads use `$0000–$0FFF`.
CHR bank 60 begins at ROM file `0x04F010`; tile 0 at `0x04F010` is all zero,
and tile 1 at `0x04F020` is `FF FF FF FF FF FF FF FF 00 00 00 00 00 00 00 00`.
Thus every pixel of tile 1 has color index 1. Subpalette 2, color index 1 is
palette slot `2×4+1 = 9`, PPU address `$3F09`.

The selected BG03 palette is ROM file `0x00D040`:

```text
0F 19 21 30  0F 36 25 30  0F 0F 00 30  0F 15 00 30
```

Its byte 9 is `$0F`, so the unmoving palette alone would draw tile-1 field
pixels black. The field's changing color comes from `F5 01` below.

## F5 effect selection, stream, and delay

The opening script command is `F5 01` at CPU `$A157` in cutscene PRG bank 3,
ROM file `0x006167`; the next command is `ED 0E`. The live dispatch trace places
`F5 01` at source frame 1779. The bank-0 handler at CPU `$87B8` (file
`0x0007C8`) includes `09 80 AA 86 4C`: it ORs the operand with `$80` and stores
the result in `$4C`, making this effect selector `$81`.

The bank-0 palette-effect reader at CPU `$82F0` (file `0x000300`) doubles the
active selector, then reads a 16-bit stream pointer from `$B800,X` / `$B801,X`.
With `$4C=$81`, X is 2, selecting table entry 1. Bank 6's table at CPU `$B800`
(file `0x00D810`) has entry 1 at CPU `$B802` / file `0x00D812`, bytes
`38 B8`, which point to CPU `$B838` / file `0x00D848`.

The exact stream prefix at `0x00D848` is:

```text
08 04 30 00 00  04 21 00 00  04 30 00 00  04 25 00 00  FE
```

ROM code at `$8300–$8352` treats the first byte `$08` as the base palette
offset. Each following `$04` is the delay count; it is followed by three
palette bytes. The writer sets X to `$08`, increments X before each store, and
skips zero payload bytes. Therefore the first nonzero byte lands at
`$062A+$09 = $0633`; the two zero bytes leave the neighboring palette values
unchanged. The `$FE` marker returns the stream cursor to the first delay/value
group, creating the four-value loop. The exact store opcode is `9D 2A 06`
(`STA $062A,X`) at CPU `$8326`, file `0x000336`.

Each update calls `$9A43` (file `0x001A53`), whose bytes
`A9 0F 85 4A 85 4B 4C 71 9A` restore brightness counters `$4A/$4B` to `$0F`
and enter the `$9A71` 32-byte palette-packet builder. The delay path calls
bank-0 `$838A` (file `0x00039A`), bytes
`A2 02 20 B9 C4 20 15 A2 A2 06 20 B9 C4 60`; it selects bank 2, invokes
`$A215`, then restores bank 6. Bank-2 `$A215` (file `0x004225`) jumps to
`$A8CE` (file `0x0048DE`), which begins `A9 01 20 A8 9F` (`LDA #$01; JSR
$9FA8`). This is one cooperative scheduler release. The `$04` count therefore
produces four scheduler waits between successive palette records. The live
RAM sequence confirms the resulting four-source-frame interval after the
initial dispatch phase.

## Live palette and frame-2034 check

At source frame 1778, before `F5 01`, RAM `$4C=$00` and `$0633=$0F`. At frame
1779, RAM has `$4C=$81`, `$EC/$ED=$38/$B8`, and `$0633=$30`. The next palette
records are `$21` at frame 1784, `$30` at 1788, and `$25` at 1792; the cycle
continues in four-frame steps. These are source-frame RAM snapshots, not
captured frame colors.

The `$9A71` packet is consumed by the NMI PPU queue at bank-2 CPU `$A000`;
its PPUDATA writer is tagged `$A03C` in the bus trace. Reconstructing the
effective address from the preceding `$2006=$3F,$00` and sequential `$2007`
writes gives these representative `$3F09` commits:

| Source frame | `$3F09` value | Evidence |
|---:|---:|---|
| 1780 | `$0F` | Initial F3 palette packet |
| 1781 | `$30` | First `F5 01` palette value |
| 1785 | `$21` | Next four-tick value |
| 1789 | `$30` | Next loop value |
| 1793 | `$25` | Next loop value |
| 2033 | `$25` | Frame-2034 color was already committed |
| 2117 | `$0F` | Black palette at the BG09 exit edge |

The bus CSV logs `$2007` register writes, not the effective VRAM address; the
addresses in the table are reconstructed by following `$2006` and the PPU
increment state. At the frame-2034 endpoint, PPU memory contains `$3F09=$25`
and RAM contains `$0633=$25`. In
`reference/palettes/FCEUX_internal_default_2.7.0_rgb.pal`, external palette
entry `$25` is RGB `(255,117,182)`. This pins why the ROM-derived tile fill is
pink at this checkpoint.

## BG09 raster setup and handoff

Source-frame 2034's bus trace records the vblank setup at CPU-cycle offsets
from that frame's baseline:

The capture's `cpu_pc` is the PC after the bus-writing instruction. For
example, `$A178` follows the `STY $2006` at `$A175`, and `$A17B` follows the
`STA $2006` at `$A178`.

| Cycle | Bus event | Source location / result |
|---:|---|---|
| 654 | `$2000=$88` | BG pattern table `$0000`; setup PC tag `$A086` |
| 661, 670 | `$2005=$00,$FF` | Initial scroll pair; tags `$A08B/$A091` |
| 691–712 | MMC3 R0/R1=`$3C/$3E` | BG CHR pair 60–63; tags `$A1D7/$A1E3` |
| 729–737 | `$C000/$C001=$80`, `$E001` enabled | MMC3 IRQ setup |
| 751–797 | R2–R5=`$96,$17,$2D,$5F` | Remaining 1 KiB CHR selectors |

Later in the same frame, the IRQ/event path writes `$2006=$2200` (high/low
write tags `$A178/$A17B`), restores `$2000=$88`, writes `$2005=$00,$00`,
disables the IRQ, then selects R0/R1=`$00/$02` through `$A1D4/$A1E0`
(write tags `$A1D7/$A1E3`). In this BG scene the PPU snapshot has dialogue
tile IDs in the `$2200` region. The PPU state file is a frame-end mapped view:
after the raster update it shows the later CHR pair, so use the bus writes to
identify the initial `$3C/$3E` pair.

The original capture gives cycle offsets (the frame-2034 `$2200` writes occur
at offsets 17038/17042) but no PPU dot or scanline. A later same-ROM capture,
`opening_timing_capture_20261024_125300`, records these events with scanline
and dot positions for frames 2018–2116. It places `$2006=$2200` on line 129,
the `$2005=$00,$00` reset on line 130, and the `$00/$02` R0/R1 update on line
130; measured dots vary across frames. The renderer hookup and focused results
are documented in
`reference/diagnostics/bg09_raster_renderer_fix_20261025/README.md`.

The `$2005=$00,$FF` state and subsequent `$2006=$2200` reset are separate PPU
state transitions; a single static BG09 tilemap does not encode them. Exact
fetches already latched when the CHR pair changes and the first affected output
pixel remain unresolved.

At the end of the scene, `EA` dispatches at source frame 2102. RAM brightness
counter `$4A` is `$0E` at that snapshot and reaches `$00` by frame 2116. The
frame-2117 PPU palette is all `$0F`, and `FD` dispatches at the scene boundary.
The effect does not stop when `EA` starts: `$4C=$81` remains active through
frame 2116 and is cleared by the `FD` scene transition at frame 2117. During
that fade, palette writes and fade packets share `$05E8`: the effect stores
`$21` to RAM `$0633` at frame 2104, but its next `$9A43` reservation stalls at
the `$3D` capacity check while the fade packet occupies the queue. The fade
continues from the prior base color. The modeled and captured PPU values are
`$25` through frame 2100, `$30` at 2101, `$31` at 2106, `$21` at 2108, `$11` at
2111, `$01` at 2114, and `$0F` at 2117.

## Godot implementation and focused validation

The effect's source material is preserved unchanged under
`reference/rom_extract/intro/palette_effect_state/`: the pointer bytes at
file offset `0x00D812`, the 18-byte `$B838` stream at `0x00D848`, and metadata
with ROM/payload SHA-256 values. `scripts/opening/rom_bg09_palette_effect_model.gd`
checks those bytes and hashes, decodes the four records and `$FE` loop, and
models the four scheduler waits. The presenter connects it to the existing
palette builder and NMI commit path. A full `$05E8` queue reservation delays
the animation stream until a later source frame; the `EA` fade remains active
and `FD` stops the effect at the observed scene boundary. Runtime behavior
uses the extracted source bytes, never the captured RAM/PPU/screenshot files.

The targeted headless state capture and verifier passed 32 checkpoints across
frames 1779–2117. They compare Godot's `$4C` and `$0633`, committed `$3F09`, and
renderer palette byte with the same-input FCEUX RAM/PPU snapshots. `$4C=$81`
matches through frame 2116 and becomes `$00` at frame 2117 on FD's transition.
Notable palette edges match:
RAM `$30` at 1779 and PPU `$30` at 1781; RAM `$21` at 1784 and PPU `$21` at
1785; the later `$30/$25` commits at 1788/1789 and 1792/1793; both RAM and PPU
are `$25` at frame 2034. The fade/queue overlap and black exit also match the
listed captured PPU values through `FD` at 2117. Pinned FCEUX color `$25` is
`(255,117,182)`.

Same-input viewport comparisons are validation only. The earlier palette-only
renderer check at frame 2034 was 89.74% RGB-exact / 81.76% foreground-exact.
After the BG09 scroll/address/CHR events were connected, frames 2034 and 2040
compare 100% exact; the full 2018–2116 span averages 99.99% RGB / 99.98%
foreground exact. Results and the seven-pixel portrait residual are in
`reference/diagnostics/bg09_raster_renderer_fix_20261025/README.md`. The older
palette checkpoint report
(`reference/diagnostics/bg09_palette_effect_validation/comparison_report.json`)
continues to verify the independent RAM/PPU palette values, not the updated
whole-frame renderer.

Remaining source gaps are the first affected output pixel through the 2C02
fetch/shifter pipeline and the complete mapping from executed code/CHR reads
to every output pixel. The synchronized capture covers frames 2018–2116; other
occurrences and source-frame timing outside that range need separate checks.
