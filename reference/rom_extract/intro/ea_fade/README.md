# EA palette fade-down and clear

This records the source-derived palette fade and nametable clear used by the
active opening source presenter. It models source end states; it does not
model every within-frame PPU bus edge.

## ROM evidence

The source is the supplied Turkish ROM, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
For the first 16 KiB PRG bank, file offset is `0x10 + (CPU address - 0x8000)`.
The `.bin` files here are verbatim slices:

| File | CPU range | ROM file range | Bytes | Role |
|---|---|---:|---:|---|
| `fade_down_99F0.bin` | `$99F0–$9A30` | `0x1A00–0x1A40` | 65 | Fade routine |
| `palette_builder_9A71.bin` | `$9A71–$9AA1` | `0x1A81–0x1AB1` | 49 | Stages a 32-byte `$3F00` packet |
| `palette_lookup_9AA2.bin` | `$9AA2–$9AB8` | `0x1AB2–0x1AC8` | 23 | Converts intensity input via `$9EA2` |
| `palette_lut_9EA2.bin` | `$9EA2–$9EE1` | `0x1EB2–0x1EF1` | 64 | Exact lookup table consumed by `$9AA2` |

The observed handler for EA calls `$99F0`, then after it returns performs PPU
clears. `$99F0` checks `$4A | $4B`; while nonzero it decrements each nonzero
counter, calls `$9A71`, waits through `$9FA8` with `A=$01`, and repeats. `$9A71`
walks 16 bytes at `$062A` using `$4A`, then 16 bytes using `$4B`; each base
color is masked with `$30`, the corresponding fade level is added, and `$9AA2`
indexes the ROM table, then combines the table’s high intensity bits with the
original color’s low nibble. The 32 converted bytes are staged at `$05E8` for an NMI
consumer; capture evidence shows that consumer commits the staged packet on the
next frame's NMI.

`scripts/opening/prototypes/ea_fade/ea_palette_fade_reference.gd` implements
the source-backed color conversion, one fade-counter step, and the two
source-confirmed zero-fill address ranges. The active presenter applies those
addresses to its PPU-memory model when EA completes. This does not model the
PPU bus schedule or `$9B7F` helper side effects. The helper takes the 32
original palette color bytes as input; it does not bake
emulator-captured palette pixels or captured WAV into runtime content.

## Observed fade and display edge

The synchronized FCEUX RAM/PPU captures show `$4A=$4B=$0E` and a staged packet
at frame 267. For frames 268–281 the RAM-side staged palette walks through
levels `$0D` to `$00`, while frame-end PPU palette snapshots lag the staged
packet by one NMI. The large EA zero-fill begins in frame 282; the source
pointer has advanced past EA by that frame. The handler then invokes `$9B7F`
and `$98E8` for 16×32 zero writes at `$2000`, followed by 32×32 at `$2400`,
for 1,536 writes total. A PC-tagged trace identifies these writes at `$9953`
on scanlines 55–196 while rendering is masked. This confirms the gradual 15-step
fade and a one-NMI packet delay, but it does **not** identify the exact first
pixel using each palette or the precise displayed-frame edge for the final
`$00` state. Frame-end snapshots alone cannot exclude a last old-palette scanline.

Do not assign a frame-perfect Godot display edge from this helper. The smallest
missing evidence is a same-replay displayed-pixel or raster capture aligned to
PPU scanline/dot for frames 267–282 (including whether the final zero-level
palette is visible before the bulk PPU clear). The existing scanline/dot bus
trace proves the NMI writes occur during vblank, not the exact first visible
pixel.

The 2026-10-24 visibility-edge audit supersedes the earlier edge conclusion
above. The source-frame-282 EA handler at `$858D` calls `$98E8` for 16×32
zero writes at `$2000` and 32×32 at `$2400`, totaling 1,536 writes. A
PC-tagged trace records them from `$9953` on scanlines 55–196 while rendering
is masked. The final 32-byte `$0F` palette packet uploads on scanlines 246–250,
before visible scanline 0. A separate silent same-input capture shows frame
281's dim logo and frame 282's entirely black viewport, supporting black from
frame 282's first displayed scanline; the exact dot remains unsampled.

The same boundary capture shows frame 12 black and the first logo pixel in
frame 13 at output `(79,77)`. The output row maps to visible scanline 77; its
PPU dot is not directly measured. The two FCEUX runs were aligned using
byte-identical PPU/RAM snapshots for the sampled frames. See
`../cold_start_visible_edge_audit.md` for provenance and limits. Captures are
observation evidence only, never runtime assets.

Capture files used only for checking the trace (not shipped resources):
`reference/opening_timing_capture_20261024_131316/ram_states/ram_00267.bin`
through `ram_00282.bin`, and matching `ppu_states/ppu_00267.bin` through
`ppu_00282.bin`.
