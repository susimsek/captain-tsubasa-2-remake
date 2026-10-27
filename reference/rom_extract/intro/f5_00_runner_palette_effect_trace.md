# Opening runner F5 00 palette effect

## ROM source and selection

This trace uses the supplied Turkish ROM, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
The opening script selects background 1 with `F9 01`, loads its palette with
`F3 00`, then dispatches `F5 00` at source frame 379, CPU `$A03A`, ROM file
offset `0x00604A`. The F5 handler sets `$4C=$80` and the effect reader's stream
pointer to `$EC/$ED=$2A/$B8`, selecting effect-table entry 0.

The bank-6 pointer table is at CPU `$B800`, file offset `0x00D810`. Entry 0 is
the preserved two-byte sequence `2A B8`, which resolves to `$B82A`, file offset
`0x00D83A`. The raw pointer and stream bytes are preserved in
`palette_effect_state/effect_00_pointer.bin` and
`palette_effect_state/runner_effect_00_stream.bin`; their ROM identity and
checksums are in `palette_effect_state/runner_effect_00_metadata.json`.

The stream is:

```text
0C 04 3A 1A 1A
04 1A 1A 3A
04 1A 3A 1A
FE
```

`$82F0` treats `$0C` as the base palette offset. The three following records
each contain a four-release scheduler delay and three palette bytes. `$FE`
loops to the first record. The writer at `$8326` is `STA $062A,X`; it advances
X before each nonzero store, so the three bytes go to RAM `$0637–$0639`, which
feed PPU `$3F0D–$3F0F`.

## Execution evidence

An FCEUX Lua memory-write hook during deterministic cold-start replay observed
the writes below. The callback PC is `$8329`, immediately after the `$8326`
`STA $062A,X` instruction. The first record repeats the F3 palette values
already in RAM; the visible change begins with the next record.

| Source frame | `$0637–$0639` | Source action |
|---:|---|---|
| 379 | `3A 1A 1A` | First stream record after `F5 00` |
| 384 | `1A 1A 3A` | Second record |
| 388 | `1A 3A 1A` | Third record |
| 392 | `3A 1A 1A` | `$FE` loop returns to the first record |

The same-input PPU states at
`reference/opening_timing_capture_20261024_125300/ppu_states/` show the
one-NMI transfer after the palette packet is queued: for example, the RAM
write at frame 384 is present in PPU `$3F0D–$3F0F` at frame 385, and the frame
388 write is present at frame 389. At the weak comparison interval, the source
PPU palette is `1A 1A 3A` at frame 662, `1A 3A 1A` at frame 665, `3A 1A 1A`
at frame 669, and `1A 1A 3A` at frame 673.

The Godot presenter now reads the preserved pointer/stream bytes, applies the
three ROM palette writes, waits for the shared `$05E8` queue capacity, and
commits the resulting `$20 00 3F` packet on the modeled next NMI. A headless
presenter run produced committed `$3F0D–$3F0F` bytes matching the listed source
PPU checkpoints, including frames 662, 665, 669, and 673. The first visible
pixel within the frame remains subject to the existing unresolved PPU/NMI
subframe phase; the checkpoint match does not establish full-frame exactness.
