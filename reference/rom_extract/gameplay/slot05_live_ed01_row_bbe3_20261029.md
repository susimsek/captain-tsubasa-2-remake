# Live Slot-$05 Descriptor Row $BBE3 — 2026-10-29

## Result

The live route dispatched slot $05 from record 00 46 18 19 at $8889 and
executed the previously unmanifested descriptor row at bank $19:$BBE3:

    ED 01 FC

The worker entered the ROM $ED handler at $8AE7 and reached the $FC return
routine at $8C52. Its source accesses include the existing hash-checked
team-$00 name stream at $F776; live team identifiers were $002A=$00 and
$002B=$00. The worker produced 139 ordered RAM writes over its private copy.

It then stopped at the first source read missing from the worker package:
PC $89A0 requested bank $19:$BD9F. Its partial RAM result was not adopted by
the scheduler. Live $0629 remained $00 and no scenario-$35 enqueue ran. This
pass did not execute the continuation at $BD9F.

## Live input and worker state

| Value | Before dispatch | At worker stop |
| --- | --- | --- |
| Slot-$05 record | 00 46 18 19 | unchanged live scheduler record |
| PC | $8889 | $89A0 |
| A / X / Y / SP | $0F / $0F / $03 / $4A | $00 / $03 / $00 / $46 |
| Mapper banks | $18 / $19 | $18 / $19 |
| Stack page $0140-$014F | 00 81 8C B9 52 A8 89 03 0F 88 88 98 EF 1D 1C D0 | worker-local stack |
| $002A / $002B | $00 / $00 | unchanged |
| $003E-$003F | 9C BD | 9F BD |
| $003C | $B0 | $01 |
| $0629 | $00 | $00 |

Selected worker-local output bytes at $04A5-$04AE were:

    07 01 23 AA 00 00 00 00 00 AB

These are RAM observations from the source worker, not visible PPU output.
Scheduler RAM remained byte-identical to the live input boundary.

## Source provenance

- ROM SHA-256: 4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097
- Worker manifest: reference/rom_extract/gameplay/fresh_bank18_worker_prefix/manifest.json
- Worker manifest SHA-256: 5f04b487771024d41a69c2093e3d201f51c2d3fd568bcf448b11aa9f019b36fe
- New worker span: field_entry_window_01/descriptor_01_row_02.bin
- Row source SHA-256: ff4579caac8640e812546cc7649a99a939843eb1f972ccb5c5b715278c5dbd47
- Row bank/CPU/file offset: bank $19, $BBE3-$BBE5, file offset 0x033BF3
- Parent field-entry manifest SHA-256:
  9e675240b8994f5956ca0939202b7841e2b833568103dbfc6567d5a21980beb1
- Existing team-$00 stream: $F776-$F77B, hash-checked in the worker manifest.

The GDScript source map loads the row bytes from the existing extracted
resource and validates them against both manifests. Worker and scheduler
manifest-hash guards were updated to the new worker-manifest hash.

## Verification and limits

Focused verifier:
tools/diagnostics/verify_rom_slot05_live_ed01_row_bbe3.gd

Command:

    godot --headless --path . --script res://tools/diagnostics/verify_rom_slot05_live_ed01_row_bbe3.gd

Result: PASS on Godot 4.7.2. The verifier rebuilds the existing route through
the slot-$01 return, dispatches the real pending slot-$05 scheduler record,
checks row and team-stream provenance, confirms the $8AE7/$8C52 path, and stops
at the first unmanifested read $BD9F. It confirms no partial worker state was
adopted.

This does not establish physical NMI cadence, PPU application, visible output,
or later row behavior. No FCEUX trace or emulator-derived runtime state was
used.
