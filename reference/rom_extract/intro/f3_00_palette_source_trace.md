# Opening `F3 00` palette sources

## Target and source bytes

The opening script's `F3 00` command is at CPU `$A038` (ROM file offset
`0x006048`) and dispatches through bank-0 handler `$8682`. The verified
`$9A35` path loads the active background and sprite palettes, sets brightness
counters `$4A/$4B` to `$0F`, and stages a 32-byte `$3F00` packet through
`$9A71`. With both counters at `$0F`, the ROM palette LUT maps each source
color back to itself.

The `F9 01` field record selects background palette index 2 at ROM file offset
`0x00D030`; the original 16 bytes are preserved in
`background_palette_02.bin` and recorded in `background_01_layout.json`.
Animation `6E` begins with palette index `00`. The corresponding sprite bytes
are ROM file `0x00D310` / bank-6 CPU `$B300`; they are preserved unchanged as
`animation_00_sprite_palette.bin`, with source offset and SHA-256 in its JSON
sidecar. `tools/extract_animation_palette_00.py` reproduces the extraction and
checks the full supplied ROM hash and expected bytes.

Combining the two ROM records gives the exact 32 source bytes for this palette
rebuild. The diagnostic PPU state at source frame 380 has background palette
`0F 1A 18 30 0F 36 25 30 0F 21 31 30 0F 3A 1A 1A` and sprite palette
`0F 0F 0F 36 0F 0F 16 36 0F 0F 30 36 0F 0F 30 36`. The sprite palette bytes
match the unique matching sequence at ROM file `0x00D310`; this capture is
cross-check evidence only and is not loaded by the running project.

## Godot model and remaining limits

The frame-378 queue cursor is `$20` after the final field packets have been
staged. F3 requests a `$20`-byte payload; `$9B28` compares `$0628+$20` to `$3D`,
so `$20+$20=$40` takes the `$9B2E` capacity retry. The saved worker stack
contains return PCs `$9B32` and `$8689`, confirming the yield is inside the F3
palette allocator. NMI drains the field queue; F3 then resumes and stages the
palette in source frame 379. The same frame continues through `F5 00`, `ED 68`,
`F2 05`, and the first text tile `$4B`.

The glyph helper `$88CA` appends packet bytes `82 49 22 00 4B` at `$05E8+$23`.
Header `$82` selects a two-byte transfer with PPU increment 32. The next NMI,
frame 380, commits palette writes to `$3F00–$3F1F`, then glyph writes
`$2249=$00` and `$2269=$4B`. The next glyph `$6F` is dispatched at frame 384
and commits to `$224A/$226A` in frame 385. Subsequent tiles in this observed
line advance one column every five source frames. Pixel-visible onset remains
unmeasured.

The isolated source presenter now checks the preserved palette metadata/hash,
runs the 32 bytes through the extracted `$9EA2` palette lookup at `$0F/$0F`,
models the frame-378 queue-capacity yield, and commits the palette and first
glyph on the next NMI. The committed palette is passed to the nametable
renderer. This matches palette/glyph packet bytes and NMI frame ordering; the
exact visible edge, later text cursor changes, and sprite/OAM/raster composition
remain unresolved. No claim of full-frame fidelity follows from this palette
match.
