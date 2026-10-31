# Slot `$15` Map `$42`: First Runtime Batch

## Result

The live Godot route now dispatches the scheduler-selected slot `$15` at ROM
address `$8572`, resumes the map worker, reads the first three map cells, and
expands their metatile data into the source queue format. All three cells are
metatile `$14`. The resulting 96-byte queue prefix matches FCEUX snapshot 8
byte-for-byte by SHA-256:

`1af864cf8efad02dfc1f00baf08b8c7e037c5fe931ebc1a64b49ac92b2438d52`

The live normal-NMI consumer then reports 96 ordered bus events containing 51
`$2007` writes. This validates the bounded queue producer/consumer join. It
does not render the map or establish the full field.

## ROM inputs and source spans

The runtime executor hash-checks the supplied ROM and these preserved PRG bank
`$0B` spans:

| Source | CPU address range | Size | SHA-256 |
| --- | --- | ---: | --- |
| Map worker | `$8572-$85C2` | `$50` | `098a354cae578918bf54407b972e69b520327d030eb391ed3c2d476c4d337502` |
| Metatile expansion | `$85C2-$86D3` | `$111` | `1aab318fd595b2cf9f82ed8176340dfe43d4fbdc792e9204ede31c2d21c79e15` |

The selected task state supplies map `$42`, selector `$01`, and row pointer
`$93A4`. The packed selector table byte `$52` at index `$10` gives selector
`$01`. The first three bytes at `$93A4` are `$14,$14,$14`. The map data,
metatile tiles, and attribute byte are separately extracted and hash-checked by
the executor; metatile `$14` has 16 zero tile bytes and attribute `$00`.

The map-worker manifest records selector `$01`. This corrects its earlier
`$00` value; it is derived from the packed selector table and the live map ID,
not inferred from the observed queue.

## Queue and mapper effects

Each `$14` metatile yields four seven-byte tile records and one four-byte
attribute record. Three metatiles therefore produce 15 records and 96 bytes.
The first tile addresses are `$2000`, `$2004`, and `$2008`; the corresponding
attribute addresses are `$23C0`, `$23C1`, and `$23C2`. The queue ends at offset
`$60`, placement advances to `3`, and the remaining row count becomes `$1D`.
The worker sets the queue-ready flag `$0515=$80` and the mapper high bank to
`$12` before yielding through `$856F->$C515`.

The route passes the generated queue to the normal-NMI consumer. Its returned
bus log contains 51 writes to `$2007`, matching the three sets of tile and
attribute data. The bus events are not yet applied to the live field renderer.

## Verification

Run the focused route verifier:

```sh
godot --headless --path . --script tools/diagnostics/verify_rom_slot05_live_ed01_row_bbe3.gd
```

The passing check establishes the live scheduler boundary, the source-derived
queue hash, the expected queue cursors and mapper result, and the NMI write
count. The comparison reference is FCEUX snapshot 8 in the two-pass trace
described by
[`first_command_field_packet_queue_join_20261029.md`](first_command_field_packet_queue_join_20261029.md).

## Limits and next step

The executor is a bounded, source-checked translation of this worker segment,
not a general 6502 interpreter. It does not model temporary stack writes made
inside `$85C2`, physical CPU/PPU cycle timing, PPU beam position, or APU writes.
It derives the queue packet bytes from ROM resources; it does not use the FCEUX
queue bytes as runtime data. The verifier compares bytes and bus writes, not
visible pixels.

The route has since continued through all 32 map cells in eleven batches; see
the [full-row runtime report](slot15_map42_full_row_runtime_20261029.md). The
complete kickoff field still requires the actual loader's CHR and palette
context, scroll and raster state, active actors, and the initial command-menu
request. Apply ordered PPU writes to renderer-owned memory only once that field
context is established.
