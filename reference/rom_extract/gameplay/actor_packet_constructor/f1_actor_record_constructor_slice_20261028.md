# Fresh-start `$F1` actor-record constructor slice

## Result

`RomF1ActorRecordConstructor` translates a decoded ROM `$F1` packet from
animation `$8F` into the 21-byte actor record built by bank `$14` code
`$80AA–$8127`. It uses hash-checked copies of the `$88E4`, `$A1B4`, and `$AC47`
pointer-table prefixes; it does not read the ROM, emulator state, actor RAM
snapshots, or a frame-number fixture at runtime.

The packet fields follow the byte-checked constructor path:

| Packet source | Actor record destination |
| --- | --- |
| packet byte 5 bits 2–4 | `$88E4` actor index / record base |
| packet byte 1 | `$A1B4` motion pointer → `+$01/+02` |
| packet byte 2 | `$AC47` appearance pointer → `+$03/+04` |
| packet byte 3 | `+$08` position lane |
| packet byte 4 | `+$0C` position lane |
| packet byte 5 low two bits | `$80 | (byte & 3)` at `+$00` |

Every other one of the 21 record bytes begins at zero, matching the source
constructor's clear loop. The records retain their decoder event's animation,
stream, and file offset as provenance.

## Verified animation `$8F` packet mapping

The source span is `0x029895–0x0298BA` (bank `$14`, CPU `$9885–$98AA`), selected
by the bank-$10 scenario `$35` event `02 3A 8F 73` at file offset `0x0237E0`.
The table slices are taken from ROM SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.

| Packet file offset | Record / base | Motion index → pointer | Appearance index → pointer | Active | packet positions |
| ---: | --- | --- | --- | ---: | --- |
| `0x02989C` | `$00` / `$0547` | `$00` → `$A38A` | `$91` → `$B30E` | `$81` | `$00,$D3` |
| `0x0298A2` | `$01` / `$055C` | `$70` → `$A723` | `$92` → `$B310` | `$81` | `$28,$C3` |
| `0x0298A8` | `$02` / `$0571` | `$70` → `$A723` | `$92` → `$B310` | `$80` | `$00,$C3` |
| `0x0298AE` | `$03` / `$0586` | `$71` → `$A72C` | `$93` → `$B312` | `$80` | `$B8,$B3` |
| `0x0298B4` | `$04` / `$059B` | `$71` → `$A72C` | `$93` → `$B312` | `$80` | `$00,$B3` |

All table entries were read locally from the supplied target ROM and are pinned
by the manifest hashes. The packet data and constructor mapping agree with
[`fresh_kickoff_actor_initialization_rom_audit_20261027.md`](../fresh_kickoff_actor_initialization_rom_audit_20261027.md)
and [`first_command_actor_writer_trace_source_map_20261027.md`](../first_command_actor_writer_trace_source_map_20261027.md).

## Boundary

This component closes only the source `$F1` packet → zeroed actor-record
initialization step. It does not install those records into the live route,
resolve scenario worker release/NMI timing, run `$EE9F` actor ticks, execute the
`$B30E/$B310/$B312` appearance or `$A723/$A72C` motion programs, resolve shared
mirror/scroll/clipping/CHR/palette state, or build OAM. The existing
`RomActorStateInterpreter` currently recognizes a narrow `$B026/$B5AC` and
`$A38A–$A390` slice, so these five early actors are not yet renderable by it.
Do not claim live route actor parity from this constructor alone.

Run the focused source check with:

```sh
godot --headless --path . --script tools/diagnostics/verify_rom_f1_actor_record_constructor.gd
```
