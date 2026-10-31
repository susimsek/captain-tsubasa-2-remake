# Field `$C97B` PPU-write provenance boundary

## Result

In the field trace, PC `$C97B` is the instruction after the ROM's
`$C978: STA $2007`; it is not a routine entry. The static normal-NMI chain is
`$C799 -> $C8FB -> $C951 -> $C978/$C97B`. `$C951` conditionally consumes the
secondary transfer list in RAM `$04A5` when `$0498` is zero and `$0515.7` is
set, clearing `$0515` before reading the list. The precise source span and
guards are documented in
[`ppu_transfer_buffer_0515_writer_cross_reference_20261029.md`](ppu_transfer_buffer_0515_writer_cross_reference_20261029.md).

The slot-`$15` scenario callback route can produce PPU map packets that target
the observed `$2800-$2BFF` range. The existing task trace records live calls to
bank-`$0B` `$8327/$8525` for map IDs `$42,$43,$54,$52,$0E`, with placements
`$A0/$80`; ROM `$85C2` expands those metatile maps and queues their tile and
attribute runs. Source arithmetic maps placement `$80` to `$2800` plus
attributes `$2BC0-$2BDF`, and `$A0` to `$2A00` plus attributes
`$2BE0-$2BFF`. These callback/map-worker events occur during the same source
interval as the recorded `$2800-$2BFF` PPU writes. This establishes a live,
ROM-supported producer capable of writing that region; it does **not** prove
that every observed queue packet or all 1,024 distinct addresses came from
those calls.

## Hash-bound ROM evidence

Supplied ROM SHA-256:
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.

| Source | Bank / CPU range | File offset | Length | SHA-256 | Use |
| --- | --- | ---: | ---: | --- | --- |
| Normal NMI call | `$1E:$C799` call bytes | `0x03C7A9` | 3 | `77d15140839e5c0213db71f8555d4e6d19b5a903c8bdbc85f39058c5baedce8a` | Calls `$C8FB` when the normal NMI gate is open. |
| Secondary queue consumer | `$1E:$C951-$C981` | `0x03C961` | `0x31` | `85cca72362c564bc3b73c1fc8bb8c051dca00e975392963533330238037aebf9` | Reads `$04A5` after the `$0498` and `$0515` gates; writes PPU data at `$C978`. |
| Map queue writer prefix | `$0B:$85C2-$8605` | `0x0165D2` | `0x44` | `1092b5bab6e3fcbc62283d3d1f37b8371898fc84d0df6ac407c83138af18156d` | Writes packet address/data fields through indexed stores into `$04A6/$04A7/$04AE/$04B5/$04BC`. This is a hash-bound prefix, not the whole worker. |
| Callback map-placement handler | `$0B:$8327-$8360` | `0x016337` | `0x39` | `e3ed67bcd4a760f0f8324b4d46ca08100ef6d1b578af495da8475b7e66096853` | Loads the map operand and prior `$05CD` placement, calls `$8525`, then toggles placement. |

The `$8327/$8525/$85C2` map expansion, selector tables, tile records, and
placement calculations are detailed in
[`first_command_field_background_producers_20261027.md`](first_command_field_background_producers_20261027.md).
The source record for scenario `$1E` event `$45` (map `$36`) is separately
mapped in [`first_command_scenario_event_continuation_audit_20261028.md`](first_command_scenario_event_continuation_audit_20261028.md).

## Trace correlation and limit

[`fresh_field_ppu_trace_20261029.md`](fresh_field_ppu_trace_20261029.md)
reports 2,528 writes in `$2800-$2BFF` from frames 8595-8734, with all 1,024
addresses covered by frame 8619. Its ordered event file is
`reference/diagnostics/first_command_field_ppu_trace_20261029/field_pass2_ordered_events.csv.gz`
(SHA-256
`89f4f8ddfb6c318d1099296bb615b4b064f4ba19da3495745cce8e4913187e9c`). It
retains PPU bus events and post-store PC `$C97B`, but not the source queue
bytes or their CPU write PCs.

The separate
`reference/diagnostics/first_command_task_boundary_20261028_070655_utc/task_events.csv`
records callback/map-worker events in that interval, including `$8525` calls
at frames 8593, 8607, 8624, 8667, and 8718. Its metadata lists hooks for
`$814C/$81A7/$81BC/$8327/$8525`, but not `$85C2` or writes to `$04A5-$0514`.
Thus it supplies map ID and placement context, while the PPU trace supplies
committed PPU addresses and values; the two artifacts do not carry the packet
identity needed to join a specific `$85C2` output to a `$C97B` write. Also, the
`$45` map-`$36` callback at frame 8789 and `$70` map-`$56` callback at frame
8893 occur after the bulk write interval and cannot explain its earlier
packets. Earlier scenario callbacks and map-worker calls are temporally
consistent with part of that interval.

## Exact next capture needed

Use the signature-checked frame-8399 checkpoint and the same recorded route
input sequence, preserving its frame/cycle input phase. In the **same field-
reaching run**, retain:

- every CPU write to `$04A5-$0514`, with cycle, PC, mapped PRG bank, old/new
  byte, A/X/Y/P/SP, current task slot, callback selector/pointer/index, map
  ID, `$05CD/$05CE`, and mapper state;
- entry to `$85C2`, `$C951`, and each `$C97B` store, plus a full `$04A5-$0514`
  snapshot immediately before `$C951` consumes it;
- the existing ordered `$2006/$2007` event stream and route input latch/cycle.

This will join the callback-created packet bytes to the normal-NMI queue
consumer and its ordered PPU writes. The existing field trace's first replay
missed Start while its second reached field setup, so frame-only input replay
is insufficient; preserve and report the controller latch/sub-frame phase.

## Runtime consumer contract

The Godot path may accept only packets generated from live ROM-derived callback
and `$85C2` state, with their `$04A5` ordering, `$0498/$0515` gates, and normal
NMI consumption modeled. The consumer should return ordered PPU address/data
operations for the renderer; it must not seed the renderer from the captured
`$2800-$2BFF` endpoint bytes. The verified map writer supports bounded map
patches, but the complete field producer and the exact packet-to-trace mapping
remain unresolved until the combined queue/PPU capture is available.
