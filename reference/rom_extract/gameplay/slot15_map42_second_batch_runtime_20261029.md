# Slot `$15` Map `$42`: Second Runtime Batch

## Result

The live route now continues past the first map batch's NMI handoff without
seeding synthetic task state. The actual scheduler selects slot `$15` again at
`$CB0F`; its saved record is `00 E9 0B 12`, its map cursor is placement `3`
with `$1D` cells remaining, and the preserved block-map pointer is `$93A4`.
Dispatch restores `$8572`, where the ROM worker resets the queue write offset
and uses `$20-$05C9` to read map indices `3–5`.

All three cells are metatile `$14`. The ROM-derived packets produce placements
`3–5`, advancing `$05C7/$05C8/$05C9` to `$60/$06/$1A`. The 96-byte output matches
FCEUX snapshot 9:

`0f0c448f8edac511fe7bf548ed2259a8bd4e581cdfc660221fac97a5912fdd1b`

The next caller-supplied normal NMI consumes the queue and returns 51 `$2007`
writes. The route then completes the slot-`$09` source path and exposes the
source-produced third-batch boundary at placements `6–8`. That batch is now
ROM-decoded, integrated, and verified against FCEUX snapshot 10; see the
[third-batch runtime report](slot15_map42_third_batch_runtime_20261029.md).

## Reference evidence

The comparison uses existing two-pass diagnostics; no new FCEUX capture was
needed. The pass-2 queue record is snapshot 9 at frame 8470, cycle `252211667`,
sampled at `$C951` in bank `$1E`. Its task context is scenario `$35`, callback
`$3A`, script `$B7D4`, with MMC3 banks `$0B/$12`. The raw queue prefix and
consumer writes are in:

- [`queue_snapshots_pass2.csv`](../../diagnostics/first_command_field_packet_queue_join_20261029_101710_utc/queue_snapshots_pass2.csv), snapshot 9.
- [`packet_join_events_pass2.csv`](../../diagnostics/first_command_field_packet_queue_join_20261029_101710_utc/packet_join_events_pass2.csv), consumer 9 and its 51 ordered `$2007` writes.
- [`packet_queue_join_report_20261029.md`](../../diagnostics/first_command_field_packet_queue_join_20261029_101710_utc/packet_queue_join_report_20261029.md), capture provenance and two-pass matching details.

The runtime does not read the CSV queue bytes. It hash-checks the ROM worker,
map, and metatile resources, then generates the packets. The focused verifier
also checks the live NMI consumer count and the next scheduler-selected slot
state:

```sh
godot --headless --path . --script tools/diagnostics/verify_rom_slot05_live_ed01_row_bbe3.gd
```

## Source limits

The map-worker code at `$8572-$85C2` processes three cells per invocation,
sets `$0515=$80`, and yields through `$856F->$C515`. The executor accepts only
the first two observed source states: map indices and placements `0–2`, then
`3–5`. Both use metatile `$14`. It is a ROM-checked bounded translation, not a
general 6502 interpreter; temporary `$85C2` stack writes and physical
CPU/PPU-cycle timing are not modeled.

The verified queue and NMI writes do not establish the visible field. The
renderer still needs the live map's CHR, palette, nametable, scroll, and raster
state. The next map batch reaches placement `8`, where the trace shows nonzero
tile data; decode its block/metatile resources from ROM before expanding the
executor. Do not infer those bytes from the snapshot queue.
