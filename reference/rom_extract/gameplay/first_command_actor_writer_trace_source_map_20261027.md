# First-command actor writer trace: ROM source map — 2026-10-27

## Evidence boundary

This static follow-up maps the completed muted FCEUX writer trace to target-ROM
code and data. ROM SHA-256 is
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`. The trace
directory is
`reference/diagnostics/first_command_actor_writer_trace_20261027_170114_utc/`.
It saved an anonymous in-memory state at source frame 8399, checked a full
2-KiB RAM/16-KiB PPU/mapper/frame/cycle signature after loading it, and replayed
8400–8953 twice with sound disabled. Both runs produced 7,662 write rows and
3,371 interpreter/draw call rows. Primary and repeat CSVs and start/end snapshots
are byte-identical; their SHA-256 values are recorded below. FCEUX exited `-11`
during shutdown after writing the completed outputs; the post-shutdown exit
status is retained as a caveat. These files are diagnostic evidence, never
runtime data.

The byte-identical output hashes, in order `actor_memory_writes.csv`,
`actor_routine_calls.csv`, `actor_start.bin`, and `actor_end.bin`, are
`9db9a3718c4e16904a40c65163b19f433bb27788e70de641fca765dd4672a5a7`,
`bea33b2e6cc6c5118271910e11581fe5931df424dd42fcc4817c5fe017fbff21`,
`b226852a296fb1963077c60e2f0c2373ecf61636ad4b86eae211a05831a414ab`, and
`4ca9fefc99df54391ceef3f7d7abe5e89e254526bc80dd5fd5fcb4cea9bae372`.

FCEUX's write callback reports the PC immediately after the store instruction.
This is byte-checked, for example, by `$80BF STA ($3A),Y` followed by the
callback label `$80C1`, and `$80DF STA ($3A),Y` followed by `$80E1`.

## Writers mapped to source routines

| Trace callback PC / bank | Actor fields written | ROM interpretation |
| --- | --- | --- |
| `$9B86/$9B96/$9B99/$9B9C`, fixed bank `$00` | `$9B83 STA $0468,X` fills `$0468–$0567` with `$F8`; the watched actor range overlaps the tail. The other three stores initialize `$0568/$0588/$05A8`. | Scene-memory sentinel/field initialization, not a complete actor constructor. Bytes around `$9B78–$9B9C` confirm the indexed fill and fixed stores. |
| `$AA10`, PRG bank `$02` | Full 21-byte actor records, zero fill. | Generic zero-fill loop: target bytes at `$AA0C–$AA10` are `A9 00 91 EC E6 EC`; `STA ($EC),Y` stores zero and the callback sees the next PC `$AA10`. It runs across six records at frames 8459–8460. |
| `$CF34`, PRG bank `$1E` | Watched portions of actor records, zero fill. | Another bounded RAM clear: `$CF1F–$CF35` sets destination `$0468`, stores zero through `($3A),Y`, and advances the destination. This broad clear is not the route's actor-animation source. |
| `$80C1/$80E1/$80E5/$8100/$8104/$810C/$8114/$8125`, PRG bank `$14` | Record clear; motion pointer `+$02/+01`; appearance pointer `+$04/+03`; coordinate bytes `+$08/+0C`; active/sign byte `+$00`. | `$80AA–$8127` is the `$F1` actor-packet constructor. `$80BF` clears 21 bytes. `$A1B4` selects the motion pointer; `$AC47` selects the appearance pointer; packet bytes 3/4 initialize coordinate lanes; packet byte 5 selects record `(b & $1C)>>2` and active bits `$80 | (b & 3)`. The pointer tables are ROM data, not captured state. |
| `$83F1/$83F7/$83FA/$8423/$8428/$8430/$8437/$8456/$8465/$848C/$8490/$8495/$84C2/$84C6/$84CF`, PRG bank `$14` | Appearance flags, local offsets, descriptor `+$12`, timer `+$10`, and appearance pointer `+$03/+04`. | `$83D9` appearance interpreter. `$8430/$8437` advance or redirect the source stream pointer; `$8423/$8428` install descriptor/timer pairs; `$84C2/$84C6` and `$84CF` are control-command writes. The surrounding bytes at `$83D9–$84D8` match the existing opcode audit: timed pairs and `$F0–$F8` controls. |
| `$84EC/$85A6/$85EF`, PRG bank `$14` | Motion timer `+$11`. | `$84DC` secondary-motion interpreter and its command handlers. `$84EC` follows the `STA ($3C),Y` timer decrement at `$84EA`; the latter callbacks are timer assignments from motion commands. |
| `$803D/$83B8/$8517/$855C/$85E0`, PRG bank `$14` | Actor `+$00` flag bits. | Active/flip/high-coordinate or motion-command flags. `$855C` follows the flag recomposition store at `$855A`; it is within the `$84DC` motion path. The values still depend on the route-selected packet/command stream. |
| `$8523/$852A`, PRG bank `$14` | Motion pointer `+$01/+02`. | `$84DC` stores the advanced pointer after dispatching the command at `$857A`; the instruction bytes at `$851C–$852A` match those pointer stores. |
| `$85BB/$85C0/$85CF/$85D4/$85FA/$8606/$861C/$8623`, PRG bank `$14` | Motion/position lanes `+$05–+$0C`. | `$84DC` command handlers and fixed-point integrator. `$85FA/$8606` follow stores to lanes `+$06/+0A` and `+$08/+0C`; `$861C/$8623` follow accumulation stores to `+$05/+09` and `+$07/+0B`. They are source-executed updates, but require the correct motion stream and timers. |

The two broad initialization PCs `$AA10/$CF34` and fixed-bank `$9B86` explain
why some actor bytes already contain sentinels at the trace boundary. They
must not be mistaken for actor appearance decisions.

## Route roots and byte-checked table resolution

The constructor writes show when actor records are rebuilt. Target ROM's
appearance pointer table is CPU `$AC47`, file offset `0x02AC57`; motion table
`$A1B4` is file offset `0x02A1C4`. In the trace window the observed roots
resolve as follows:

| Source frame | New appearance-table index → root(s) | Interpretation and remaining gap |
| ---: | --- | --- |
| 8481 | `$91→$B30E`, `$92→$B310`, `$93→$B312` | Five opening field actors are constructed; motion indices `$00/$70/$71` resolve to `$A38A/$A723/$A72C`. Static audit links the packet set to scenario `$35`, event `$3A`, animation `$8F`; exact cooperative-worker release timing remains unmeasured. |
| 8624 | `$27→$AF5F` | Rebuild of `$0547`; static audit links the event to scenario `$36`, event `$0C`, animation `$4E`. The source wait/worker phase remains unmeasured. |
| 8663 | `$C4→$B537` | Rebuild of `$0547`; static audit links the event to scenario `$36`, event `$72`, animation `$66`. Appearance parsing advances to `$B539`. Motion index `$A9` resolves to `$A96E`, whose interpreter advances it to `$A974`. |
| 8708 | `$BA→$B43E` | Rebuild of `$0547`; static audit links the event to scenario `$36`, event `$1F`, animation `$4C`. Its script advances to `$B440`. Motion index `$7E→$A79B`, then the motion stream advances to `$A7A1`. |
| 8759 | `$49/$5C/$5D/$5E→$B01E/$B0B1/$B0B4/$B0B7` | Four actor records are rebuilt; static audit links their packet stream to scenario `$36`, event `$01`, animation `$E6→$78`. Appearance and motion interpreters then advance/jump within those scripts (for example `$B01E→$B020` and motion `$A6CE→$A6D4`). Exact task release/cadence remains unmeasured. |
| 8779–8781 | `$85→$B2EF`, then `$84→$B2E0` | `$055C` is rebuilt twice within scenario `$36`'s `$E6→$78` path; source command selection is mapped, but the subevent condition/release phase is not. |
| 8822 | `$4A/$4D/$58→$B026/$B040/$B09D` | Three lineup actors are rebuilt by fresh-match scenario `$1E`, event `$45`, animation `$90`. Next appearance pointers are `$B028/$B042/$B09F`. `$B026` ROM bytes `04 00 04 01 04 02 04 03 F3 26 B0` explain the first actor's four-descriptor loop. |
| 8907 | `$CA/$CB/$CD→$B5AC/$B5AE/$B5B2` | Fully source-linked final lineup below. |

Indices in this table were matched by reading the supplied ROM pointer table;
they are not inferred from names in a community editor or copied from the RAM
snapshot. The root changes at frames 8624, 8663, 8708, 8759, 8779, 8781, 8822,
and 8907 are directly observed as new `$F1` constructor writes. The ROM-byte
scenario-to-animation and `$F1` packet crosswalk is now documented in
[`first_command_actor_scenario_event_source_audit_20261027.md`](first_command_actor_scenario_event_source_audit_20261027.md).
This closes packet-group selection for the listed route events without using
actor RAM snapshots. The remaining route-time gap is the worker/NMI release
phase and the `$0519` wait counter, followed by executing selected appearance
and motion streams on the ROM actor-update cadence.

## Final lineup already source-decodable

The frame-8907 writers match the known ROM path: scenario `$44` source at file
`0x0237E5` contains `02 70 5C F0`, selecting animation `$5C`. The bank-$14
pointer table resolves `$5C` to CPU `$9357`, file `0x029367`. Its source packet
sequence contains:

```text
F1 00 CD 00 C3 0D
F1 00 CA 00 C3 01
F1 00 CB 00 C3 05
```

These packets select records `$0586/$0547/$055C`, motion pointer `$A38A`, and
appearance roots `$B5B2/$B5AC/$B5AE`; the source `$F7` commands set held
descriptors `$0A/$00/$04`. The writer trace corroborates the constructor
ordering and the existing ROM-stream audit; the packet/descriptor bytes, not
the captured actor rows, are suitable runtime inputs. The `$83D9/$84DC`
interpreters and OAM builder can render these once their producer is connected.

## Implementation decision

The `$F1` constructor, scenario-to-animation packet selection, and the two
per-actor interpreters now have byte-checked source paths. The muted
[`first-command scenario timing trace`](../../diagnostics/first_command_scenario_timing_20261028_045844_utc/README.md)
measures one `$EE9F`/`$800F` actor tick per source frame, the `$001B.7`
NMI-ready set/clear handshake, and one `$0519` decrement per source frame.
ROM-byte analysis also decodes `$800F` low-byte waits and the inline `$F6`
actor-removal operand. `RomActorAnimationStreamDecoder.decode_scenario_event_record`
bridges a decoded bank-$10 event record to that relative animation schedule.
This is a command/tick decoder, not a route-integrated actor presenter: the
scenario task/worker launch phase, `$F4/$F5` effects, route motion/appearance
table spans, `$83D9/$84DC` state mutations, and shared renderer state still
need source-backed runtime handling. Keep captured RAM and actor records as
validation only; do not wire the frozen `$44/$5C` endpoint pose into earlier
route frames.
