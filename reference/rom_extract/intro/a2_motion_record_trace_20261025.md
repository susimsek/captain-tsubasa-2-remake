# A2 motion record trace — 2026-10-25

## Source identity and command path

The supplied Turkish ROM has SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
At source frame 2367 the cold-start dispatch runs `FB 03 C0 A2 7D` from
CPU `$A1BC` (bank 3, file `0x0061CC`). The A2 animation entry is PRG bank 10,
CPU `$A50E`, file `0x01451E`; its preserved 28 bytes are in
[`animation_A2.bin`](animation_A2.bin), and its expanded command/tick decode
is in [`animation_timing_entry.json`](animation_timing_entry.json).

The allocator gives the second 32-byte animation object to A2 at `$0588`.
The motion fields below are the first 16 bytes of that object. Its nine
`$ADD6` descriptors use OAM shadow entries 16–24, `$04A8–$04CB`; corresponding
hardware OAM-page entries are `$0240–$0263`.

## ROM F7 decoding and update order

The bank-0 F7 parser starts at `$93A7` (file `0x0013B7`). A2's repeated
`F7 29 00 00` takes the packed horizontal sign branch. The handler writes
vertical velocity `$0100`, vertical acceleration `$00`, horizontal velocity
`$FC80`, and horizontal acceleration `$00` to the record at `$0588`.
`F7 00 00 00` clears both velocities and accelerations. Both forms set the
motion-enabled flag at record offset `+$00`.

The operand mapping follows the handler instructions: the first parser shifts
`$29` right five times to `$01`, storing `$01` at `+$09` and the shifted carry
form `$00` at `+$08`; operand 1 becomes `+$0A=$00`. At `$93DE`, the second
parser masks `$29` to `$09`, shifts once to `$04` at `+$0D`, then takes the
bit-2 sign branch: `ORA #$F8` makes `+$0D=$FC`, and the carry rotation writes
`+$0C=$80`. Operand 2 becomes `+$0E=$00`.

The shared bank-0 integrator `$975B` (file `0x00176B`) adds the signed
one-byte acceleration to the 16-bit velocity, then adds the updated velocity
to the 16-bit position:

```text
velocity[n+1] = velocity[n] + signed8(acceleration)
position[n+1] = position[n] + velocity[n+1]  (modulo 65536)
```

For A2, Y position is `+$04..+$05`, X is `+$06..+$07`, Y velocity is
`+$08..+$09`, Y acceleration is `+$0A`, X velocity is `+$0C..+$0D`, and X
acceleration is `+$0E`. The timeline applies each frame's already-active
motion first and then applies F7/F1 commands scheduled on that source-frame
tick. This order matches the RAM snapshots: frame 2369 has moved twice before
the zero-motion F7 state is visible.

## RAM and OAM anchors

The snapshots in
[`opening_timing_capture_20261024_131726/ram_states`](../../opening_timing_capture_20261024_131726/ram_states)
show these selected states (Q8.8 words are little-endian in RAM):

| Source frame | Record PC / timer | Y / X position | Y / X velocity; acceleration | First OAM-shadow tuple |
| ---: | --- | --- | --- | --- |
| 2367 | `$A51A` / 2 | `$1200 / $8E00` | `$0100 / $FC80`; `$00 / $00` | `1C 48 07 14` |
| 2368 | `$A51A` / 1 | `$1300 / $8A80` | `$0100 / $FC80`; `$00 / $00` | `1E 48 07 0D` |
| 2369 | `$A51F` / 2 | `$1400 / $8700` | `$0000 / $0000`; `$00 / $00` | `20 48 07 06` |
| 2371 | `$A51A` / 2 | `$1400 / $8700` | `$0100 / $FC80`; `$00 / $00` | `20 48 07 06` |
| 2372 | `$A51A` / 1 | `$1500 / $8380` | `$0100 / $FC80`; `$00 / $00` | `22 48 03 FF` |
| 2373 | `$A51F` / 2 | `$1600 / $8000` | `$0000 / $0000`; `$00 / $00` | `24 48 03 F8` |
| 2411 | `$A51A` / 2 | `$2800 / $4100` | `$0100 / $FC80`; `$00 / $00` | `48 48 03 7A` |
| 2412 | `$A51A` / 1 | `$2900 / $3D80` | `$0100 / $FC80`; `$00 / $00` | `4A 48 03 73` |
| 2413 | `$A51F` / 2 | `$2A00 / $3A00` | `$0000 / $0000`; `$00 / $00` | `4C 48 03 6C` |
| 2415 | `$A51F` / 0 | `$3E00 / $BE00` | `$0000 / $0000`; `$00 / $00` | `74 48 07 74` |

The two-frame moving segment adds `$0200` to Y and `$F900` to X each repeat
(two times `$FC80`), and the twelve repeats end at Y `$2A00`, X `$3A00` before
the final `F1 3E BE` at tick 48 resets the origin. For the first `$ADD6`
descriptor, the OAM-shadow tuples agree with the doubled position and its
`(-8,-8)` descriptor offset at the listed checkpoints.

The `$0240` DMA-page behavior is separate from the motion integrator. The
source-backed OAM writer/culler now explains its `$F8` Y bytes: the unsigned
doubled Q8.8 coordinate plus each `$ADD6` descriptor offset supplies bit 8 as
attribute marker `$04/$08`, and `$A8CE` substitutes Y=`$F8` when either bit is
set. The resulting nine shadow and DMA tuples match all 49 saved frames
2367–2415. Details and the focused Godot/FCEUX comparison are in
[`a2_oam_dma_culling_trace_20261025.md`](a2_oam_dma_culling_trace_20261025.md)
and [`a2_oam_culling_fix_20261025`](../../diagnostics/a2_oam_culling_fix_20261025/README.md).

The exact A2 call-site PC and `$4014` transfer phase are not logged in the
existing `bus_events.csv`
([capture bus log](../../opening_timing_capture_20261024_131726/bus_events.csv));
it contains PPU/MMC3 events rather than PC-tagged writes to the A2 record or
OAM pages. The descriptor mapping and copied values are checked, while the
same-frame CPU/NMI timing remains open.

## Godot slice

`RomRunnerMotionRecord.configure_a2()` verifies the extracted A2 entry and
expanded timing metadata, accepts only F7 operands `$29 00 00` and `$00 00 00`,
applies F1/F7 events in source order, and shares the `$975B` fixed-point
recurrence with the existing `$6E` runner path. The presenter now uses the
record's X/Y origin for animation `$A2` and carries the unsigned doubled OAM
coordinates through the descriptor offsets so bit 8 drives the source `$04/$08`
hide marker. Its pre-F7 flag byte `$89` is inferred from the captured post-F7
`$A9` and the handler's `ORA #$20`; unrelated flag semantics are not modeled.

The first runtime capture failed when the timing guard reached the repeated
zero-form F7 at tick 2: the command is at CPU `$A51A` / file `0x01452A`, while
the code initially expected every repeated-body F7 at `$A513` / `0x014523`.
The guard now distinguishes the periodic clear at ticks 2, 6, …, 46 from the
`$29 00 00` set command at ticks 0, 4, …, 44, and from the final clear at
`$A520` / `0x014530` on tick 48.

The post-fix capture in
[`a2_runtime_validation_20261025`](../../diagnostics/a2_runtime_validation_20261025/)
covers 19 source frames, 2367–2385, with a mapped FCEUX reference for every
row. FCEUX screenshots are deduplicated: frames 2367 and 2368 both reuse
`frame_002336.gd` (`changed=0`), and their 100% whole-frame score has a
zero-pixel foreground union because both screens are black. Those two rows
provide no evidence for A2's visible motion. Frame 2369 is a separate
transition sample (68.40% RGB, 35.79% foreground exactness). The initial
capture matched frames 2370–2375 at 97.11% exact RGB and 94.21% foreground, but
reported a black Godot viewport at 2376–2385.

That black-out report was contradicted by a targeted re-render which records
live presenter state, the `FieldScreen` texture, and the actual Godot viewport.
Its JSON and 12 validation-only PNGs are in
[`a2_background_state_probe_20261025`](../../diagnostics/a2_background_state_probe_20261025/).
For every sampled frame 2374–2385, background ID `$0A` is active, the field
renderer is visible, its texture has about 30,500 nonblack pixels, and the
viewport is blue rather than black. This identified a stale Metal viewport
readback as the likely capture issue. The full capture tool now forces a draw,
waits one more process frame, then reads the viewport. Re-running the entire
opening with that order gives 2370–2375 averages of 97.11% RGB / 94.21%
foreground and 2376–2385 averages of 97.20% / 94.36%; the old black-image
scores are superseded. Current full-run PNGs and metrics are in
[`opening_runtime_full_1792924153`](../../diagnostics/opening_runtime_full_1792924153/).

The A2 stream's decoded exit is tick 48 at source frame 2415; frame 2385 is only
the end of the sample window. The FCEUX dispatch log has text-byte events at
2373 and 2378 but no background-selection or palette command at 2376. The A2
presenter path itself updates motion record and animation origin; it does not
select a background or palette. The byte-verified DMA copier's `$0C` culling
rule is documented in
[`a2_oam_dma_culling_trace_20261025.md`](a2_oam_dma_culling_trace_20261025.md),
but A2-specific per-frame call timing and the `$4014` transfer edge remain
untraced. These images and scores are diagnostics, not runtime assets, and do
not establish full-scene or whole-opening exactness.
