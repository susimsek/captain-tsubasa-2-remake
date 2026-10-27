# Opening command `F1 01` ROM graphics path trace

## Scope and ROM identity

This trace follows the four opening invocations of `F1 01` at `$A02D`,
`$A0D2`, `$A14C`, and `$A1B6` in the supplied Turkish ROM. Its SHA-256 is
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
The script bytes are in PRG bank 3; the live dispatcher trace records the
source pointer and frame. The selected drawing list is in bank 6 at CPU
`$BB9A`, file offset `0x00DBAA` (including the 16-byte iNES header).

This document corrects the earlier interpretation that the zero-brightness
branch returned without drawing. That branch lands at `$9819`, immediately
after the RTS at `$9818`, and `$9819` is the direct PPU drawing path.

## Handler branch and packet format

`$864A` sets the clear destination to `$2221`, calls `$98E8`, selects the
table pointer from `$BB40/$BB41`, then calls `$97B6`. In the supplied ROM,
`$97B6` starts at file offset `0x0017C6` with:

```text
A9 00 85 E9 A5 4A 05 4B F0 59
```

The `BEQ` is at CPU `$97BE`; its branch base is `$97C0`, so displacement
`+$59` lands at `$9819`. `$9818` is the RTS, while `$9819` starts
`LDA $20; AND #$7F; STA $2000 ...` and proceeds to write the selected records
directly through `$2006/$2007`. Thus `$4A|$4B == 0` selects the direct PPU
path; it is not a skip. With nonzero counters, `$97B6` stages row packets and
waits through the queue path. The captures show their later transfer from
the NMI PPU writer at `$A03C`.

The `$BB9A` stream is a sequence of records:

```text
header, PPU address low, PPU address high, payload[header & 0x3F]
```

Observed header bits: bit 7 sets PPU increment-by-32 (`PPUCTRL` bit 2); bit 6
marks the final record. The final marker is checked by the `$97B6` loop after
the PPU write. The listed destination addresses are the effective 14-bit PPU
addresses.

## Byte-verified `$BB9A` record list

The helper `tools/diagnostics/decode_f1_bb9a_table.py` verifies the ROM hash
and decodes these same bytes directly from the supplied ROM. ROM file offsets
include the iNES header; CPU pointers use the active bank-6 mapping.
The byte-identical stream is preserved at
`reference/rom_extract/intro/f1_01_graphics.bin` and packaged for runtime at
`assets/opening/rom_logic/f1_01_graphics.bin`; its adjacent JSON manifest
records the source range and hashes. The standalone Godot loader is
`scripts/opening/rom_f1_graphics_packet_loader.gd`; `build_packets()` validates
the extracted bytes and returns packet dictionaries without reading the ROM.

| # | File range | CPU pointer | Header / count | PPU destination / increment | Payload bytes | Record SHA-256 |
|---:|---|---:|---|---|---|---|
| 0 | `0x00DBAA–0x00DBC4` | `$BB9A` | `18` / 24 | `$2227` / +1 | `9B A2 A2 A9 A2 A9 A2 A9 A2 A9 A2 A9 A2 A9 A2 A9 A2 A9 A2 A9 A2 A9 A2 9A` | `b7e289c5d97fd4fd9cf0bfb194eb64e8f50e37f2baa47d8b02a19ea7ff5a6d48` |
| 1 | `0x00DBC5–0x00DBDF` | `$BBB5` | `18` / 24 | `$2367` / +1 | `99 A0 A8 A0 A8 A0 A8 A0 A8 A0 A8 A0 A8 A0 A8 A0 A8 A0 A8 A0 A8 A0 A0 98` | `ae4bf591cb249e4ecc7844e44fd219f861dca90359e269dc77bb569e85364996` |
| 2 | `0x00DBE0–0x00DBEB` | `$BBD0` | `89` / 9 | `$2247` / +32 | `A1 AB A1 AB A1 AB A1 AB A1` | `b8d9e1c4ed3113ff4961b62ce54144071286fc74ed223c4dbee879ce799f34cf` |
| 3 | `0x00DBEC–0x00DBF7` | `$BBDC` | `C9` / 9, final | `$225E` / +32 | `A3 AA A3 AA A3 AA A3 AA A3` | `2573459ebabfbf540b69cc0e9313ecd537d46c8fc1ff60cfe39fdef2ba1debec` |

The full 78-byte stream is `0x00DBAA–0x00DBF7`, SHA-256
`6f2b7603e57aec97c109eef96eeab562963e7f097a1a000da99c3eda89532d92`.
The four raw records concatenate to:

```text
18 27 22 9B A2 A2 A9 A2 A9 A2 A9 A2 A9 A2 A9 A2 A9 A2 A9 A2 A9 A2 A9 A2 9A
18 67 23 99 A0 A8 A0 A8 A0 A8 A0 A8 A0 A8 A0 A8 A0 A8 A0 A8 A0 A8 A0 A0 98
89 47 22 A1 AB A1 AB A1 AB A1 AB A1
C9 5E 22 A3 AA A3 AA A3 AA A3
```

## Observed invocation paths

All frames below are `source_frame` values from
`reference/opening_timing_capture_20261024_125300`; its frame mapping is
documented in that capture's `metadata.txt`. PPU bus events identify the
executing writer PC, effective address is reconstructed from `$2006` writes
and the active `$2000` increment mode, and payload bytes are compared against
the ROM table above.

| Script invocation | Frame-end `$4A/$4B` | Observed path and timing |
|---|---|---|
| `$A02D`, frame 342 | `00/00` | Direct path. `$9953` writes the 11×30 zero fill to `$2221,$2241,…,$2361`; `$9860` then writes all four ROM records to `$2227`, `$2367`, `$2247` (+32), and `$225E` (+32), in source frame 342. |
| `$A0D2`, frame 1108 | `0F/0F` | Buffered path. NMI writer `$A03C` commits the 11 zero-fill rows over source frames 1109–1119, then records 0–3 over frames 1119–1120. The final record has its writes in source frame 1120, after the dispatcher has already advanced from `$A0D2` to `$A0D4` in frame 1119; this is queued transfer, not another `F1` invocation. |
| `$A14C`, frame 1760 | `00/00` at frame end | Direct path. In source frame 1760, `$9953` writes the target zero-fill rows and `$9860` writes all four matching `$BB9A` records. The end-of-frame snapshot is not an entry-cycle sample; do not infer a zero-path skip from that snapshot. Separate `$2000` clear writes in that frame are consistent with the earlier `EA` work and are not attributed to the `$BB9A` table. |
| `$A1B6`, frame 2340 | `00/00` at frame end | Direct path is corroborated by same-frame `$9953` zero-fill writes and `$9860` writes of the four `$BB9A` ROM records. As with `$A14C`, the frame-end `$4A/$4B` values are snapshot context, not the exact values read at the `$97BE` branch. |

For `$A0D2`, the four ROM packets are visible in the captured writes as:

- source frame 1119, `$2227`, 24 bytes, `$A03C`, cycles 1156–1524;
- source frame 1120, `$2367`, 24 bytes, `$A03C`, cycles 649–997;
- source frame 1120, `$2247`, 9 bytes at +32, `$A03C`, cycles 1063–1191;
- source frame 1120, `$225E`, 9 bytes at +32, `$A03C`, cycles 1257–1385.

For `$A14C`, the corresponding four data payloads are written by `$9860` in
source frame 1760, at cycles 8479–8851 (`$2227`), 8957–9329 (`$2367`),
9436–9568 (`$2247`, +32), and 9675–9803 (`$225E`, +32). These are direct
ROM-table writes. The capture does not provide a RAM read at the exact `$97B6`
branch instruction; its frame-end `$4A/$4B=00/00` is therefore recorded as
snapshot context, not as the branch input.

## Evidence and limits

- `reference/rom_extract/intro/cold_start_observed_dispatch.json`: live script
  dispatch entries and source frames for `$A02D`, `$A0D2`, `$A14C`, and `$A1B6`.
- `reference/opening_timing_capture_20261024_125300/bus_events.csv`: PPU
  writer PCs, register values, cycle offsets, and scanline/dot observations.
- `reference/opening_timing_capture_20261024_125300/ram_states/`: frame-end
  RAM snapshots; these do not sample `$4A/$4B` at `$97BE`.
- ROM bytes at bank-0 `$864A`, `$97B6`, `$9818–$9819`, and `$98E8`, plus bank-6
  table bytes at `$BB9A` / file `0x00DBAA`.

This establishes the `$F1 01` table decoder and its two observed presentation
paths across four opening calls. It does not establish sub-dot PPU visibility for every row or prove
that unrelated PPU traffic elsewhere in the frame belongs to this command.
