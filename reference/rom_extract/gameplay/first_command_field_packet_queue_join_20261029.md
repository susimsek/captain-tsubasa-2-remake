# First-Command Field Packet-to-PPU Join

## Finding

Two muted FCEUX 2.7.0 NTSC/NewPPU passes from the same frame-8399 checkpoint
match across normalized event, queue-snapshot, controller-bus, and input streams
for frames 8400–8953. Both reach frame 8953, cycle 266624820, PC `$CAB0`; the
four recorded one-frame input edges are consumed at the expected controller
serial index.

The trace establishes two exact queue-to-PPU joins. It does not establish that
the first command panel or full field was visibly applied: at the end of the
capture, queue snapshot 465 remains pending with `$0515=0`, and no later
`$C97B/$2007` commit is observed.

## Ordered packet joins

At frame 8462, normal-NMI consumer `$C951` sees queue snapshot 1 with
`$0515=$80` and `$0498=$00`. Its two `$07` records are:

```text
07 21 22 00 00 00 00 00 00 00
07 41 22 9C A8 20 34 2E A8 9D
```

The consumer produces fourteen ordered `$2007` writes: `$2221–$2227` receive
seven zero bytes, followed by `9C A8 20 34 2E A8 9D` at `$2241–$2247`. Each
write is followed by the ROM commit instruction at `$C97B`.

At frame 8468, the scenario-`$35` descriptor-`$00` route calls map worker
`$85C2` three times under callback `$89F3`, script `$B7D4`, event `$3A`. The
next frame's snapshot 8 contains fifteen records in its first 96 bytes: twelve
`$04` runs of four bytes and three `$01` single-byte runs. Their 51 ordered
PPU writes match the queue records exactly, including tile and attribute
addresses.

## Stop boundary

Frame-8953 snapshot 465 begins with a pending `$0C` record (`0C 72 23 9E A9 …
9F`) and further queue data. `$0515` is `$00`; the trace ends before any later
`$2007` write or `$C97B` commit. The report therefore proves packet provenance
for the joins above, but not queue completion or visible menu output.

## Provenance

- ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- Opening-input SHA-256: `195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3`.
- Post-title route-input SHA-256: `87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e`.
- FCEUX 2.7.0, NTSC, NewPPU; sound and volume zero; screenshots and WAV
  capture disabled.
- Checkpoint: frame 8399, cycle 250126423, PC `$9F06`; CPU/PPU/mapper and
  controller-phase signatures are recorded in the ignored local checkpoint
  provenance file.
- Both passes match: event stream SHA-256
  `6f5b61996f809f7278604c538dd27687a43078b6eeb0fd4099a9b6fd0bc99717`;
  queue snapshots `48519324e67b172fc8e74317e7cd56288ad1388107502aafe2c69bde330724c7`;
  controller bus `79c68c789bfcbdd01d39859b4779f86fbd72799ce9b2028bdfa812f593bb46e3`;
  frame inputs `9668154ef1889b16343996e642b127c458bc9b3fef12ceaecf28cf56228b605b`.

Raw, ignored captures and validation metadata remain under
`reference/diagnostics/first_command_field_packet_queue_join_20261029_101710_utc/`;
the reusable local checkpoint and provenance remain under
`reference/diagnostics/local_checkpoints/first_command_packet_join_20261029/`.
These files are evidence only, not Godot runtime dependencies. The trace's
source and queue limits are detailed in the
[C97B queue-provenance boundary](field_c97b_queue_provenance_boundary_20261029.md).
