# Slot-$01 second-NMI root cycle — 2026-10-29

## Result and evidence boundary

The live route now consumes a second caller-supplied NMI, dispatches the
source-selected slot `$01` continuation, executes its six-inactive-actor
`$EE9F` path, returns through `$CA55->$E3CA`, saves the next slot `$01` yield
at `$CB0F`, then scans to the next yielded-task boundary: slot `$05`, before
its task body. The source route reports six actor flags of `$00`; it did not
reach an active actor.

The tested ROM is `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`,
SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
Each listed production span was compared byte-for-byte with that supplied
file. The Godot executors load only hash-checked project-owned ROM extracts.
No FCEUX session, captured actor RAM, screenshot, or trace fixture supplied
runtime state. NMI labels 1 and 2 are caller inputs, not physical cadence
measurements.

## Live slot-$01 input and branch

After the normal `$C799->$C8FB` queue consumer returns 20 ordered PPU bus
events, which remain unapplied, the scheduler selects record
`[00,26,00,01]` and dispatches the yielded resume at `$CA52`. The live
pre-call state is:

| Input | Live value |
| --- | --- |
| A / X / Y / SP | `$00 / $00 / $00 / $2A` |
| Task banks | `$00 / $01` |
| Stack bytes `$0127-$012B` | `00 00 51 CA 00` |
| Active task byte `$0000` | `$01` |
| Worker gates `$053A / $053D` | `$00 / $00` |
| Actor order `$0543-$0545` | `01 23 45` |

The `$EE9F` worker uses that source-owned RAM and stack snapshot. Its packed
order bytes resolve to actor indices 0–5 and fixed-bank pointer-table entries
`$0547`, `$055C`, `$0571`, `$0586`, `$059B`, and `$05B0`. Each live `+$00` flag
is `$00`; therefore `$EEFB BPL $EF38` takes its inactive branch for each
record. The worker completes all six visits and returns to `$CA55`. The
executor does not infer an active actor from the later actor trace or create
one from a fixture.

The root caller's `$CA55->$E3CA` call then takes the supported fresh-match,
no-direction path: `$05FB == 0`, `$001C & $0F == 0`, and RTS returns to
`$CA58`. Its `$CA4F->$CB0F` request uses delay `$01`. The scheduler saves
slot `$01` with record `[01,26,00,01]` and PC `$CB0F`; the next source scan
selects slot `$05`. It stops there before dispatching or executing slot `$05`.

## Runtime consumer contract

The route may enter `$EE9F` only from the scheduler's actual yielded slot-$01
dispatch and the corresponding 2-KiB RAM / 256-byte stack snapshot. Dispatch,
boundary, and `$CA52->$EE9F` request must agree on A/X/Y/SP and task banks;
the active slot, PC, stack mirror, task record, active-task byte, and packed
actor order are checked. Unsupported worker gates, actor order, or source
opcodes stop with their source boundary. The executor applies only its
ordered, ROM-decoded writes through the scheduler's adoption method.

`$E3CA` accepts only the resulting `$EE9F` source return plus the continuation
runtime's `$CA55->$E3CA` request. The subsequent yield accepts only the same
continuation's `$CA4F->$CB0F` request. No actor state, PPU writes, or NMI
cadence is synthesized by these calls.

## ROM spans checked

| CPU span | File offset | Length | SHA-256 | Use |
| --- | ---: | ---: | --- | --- |
| `$CA4D-$CA5A` | `0x03CA5D` | 14 | `e57b4fe7ceb639050a5d21b6a8d4ea958c181137f63ded21388b9ad9715a094a` | Slot-$01 loop: `$CB0F`, `$EE9F`, `$E3CA` |
| `$EE9F-$EF80` | `0x03EEAF` | 226 | `f2bc95b5fc4ee2ad1c558e64c942be24f99ced8af4784f4bb0a51c423bb48bbd` | Actor loop and `$EF73` pointer table |
| `$8000-$8083` in PRG bank `$14` | `0x028010` | 132 | `bff58de8e06e64719aa1bab3af55e5e5348ede7ffe7812b6ec4f515ab0f787c9` | `$053A` zero gate and worker dispatch |
| `$CE2D-$CE49` | `0x03CE3D` | 29 | `6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c` | MMC3 pair switch helper |
| `$E3CA-$E3D5` | `0x03E3DA` | 12 | `7100463bf16eadd91886eeb73c7afadd11972c955be5a29b99fa79d5a1afc2b1` | Fresh-match and direction checks |
| `$E406` | `0x03E416` | 1 | `8d33f520a3c4cef80d2453aef81b612bfe1cb44c8b2025630ad38662763f13d3` | No-direction RTS |
| `$CB0F-$CB2C` | `0x03CB1F` | 30 | `b6377644890b9cd6671e4e63f48da4dfe1bd4975870bb531cb684ee7aeda07fc` | Task save and scheduler return |

The ROM's later actor producer path is also checked against the same file,
but was not executed by this route:

| Span / data | File offset | Length | SHA-256 | Bytes / meaning |
| --- | ---: | ---: | --- | --- |
| `$E233` scenario setup | `0x03E243` | 5 | `c555582aed5266d64dff580f1eba839b61b132d49e110feed0abf0c1babfdc74` | `A9 1E 20 B0 CB`: select scenario `$1E`, call `$CBB0` |
| Scenario `$1E` pointer-table entry | `0x020A0B` | 2 | `72ac1108e6817858f37ce9d95f78b8d0c5dfc6e01041261f2684e0d47c2ecd1f` | `DA B7` → `$B7DA` |
| Scenario `$1E` event `$45` | `0x0237EF` | 4 | `eb6f2b6f0d3963d494eeeca19310e30c63a75891aeee9c319c4e0c5f6cded99d` | `07 45 90 F0` |
| Animation `$90` table entry | `0x028A98` | 2 | `7ed30504f3cbcedaba7103e4afe999213bbab094e15ce4ba2fe44d409db0a4d1` | `AB 98` → `$98AB` |
| Animation `$90` `$F1` packets | `0x0298C2` | 18 | `8aecd54020a132cb7bbe68fbf1f235a1c6594c93f18815d064089626b7c6fdfc` | `F1 00 58 00 C3 09 / F1 00 4B 00 C3 01 / F1 00 4D 00 C3 05` |
| Bank-$14 `$F1` constructor `$80AA-$8127` | `0x0280BA` | 126 | `f63b07670fbfa8ad3c3579daee619f4ec55b0886f92a9d7ce75f0cfc1c89587f` | Clears records and writes pointers, coordinates, and active flag |

The route also retains the existing hash-bound normal-NMI queue evidence in
[`slot09_second_nmi_queue_delivery_20261029.md`](slot09_second_nmi_queue_delivery_20261029.md).

## Active-actor producer gap

No active actor is present at this live root boundary. The production runner
has not yet connected the scenario-to-animation producer that creates actor
records. The ROM-derived later producer is known: fixed-bank `$E233` starts
scenario `$1E`; its event `$45` record `07 45 90 F0` is at file offset
`0x0237EF`. Animation `$90` resolves to `$98AB`, whose `$F1` packets begin at
`0x0298C2`. Bank-$14 constructor `$80AA-$8127` (file offset `0x0280BA`)
uses `$88E4`, `$A1B4`, and `$AC47` to write the 21-byte actor records,
including the active flag. These packet, event, and constructor spans match
the supplied ROM and are detailed in
[`fresh_kickoff_actor_initialization_rom_audit_20261027.md`](fresh_kickoff_actor_initialization_rom_audit_20261027.md)
and [`f1_actor_record_constructor_slice_20261028.md`](actor_packet_constructor/f1_actor_record_constructor_slice_20261028.md).

The exact live scheduler/caller edge from the current second-NMI state to
that scenario event remains unresolved. The later packet bytes explain what
the missing producer would write, but are not inputs to this route:

| Packet at file offset | Record selected by `$88E4` | Resulting `+$00` flag |
| ---: | --- | ---: |
| `0x0298C2`: `F1 00 58 00 C3 09` | index 2, `$0571` | `$81` |
| `0x0298C8`: `F1 00 4B 00 C3 01` | index 0, `$0547` | `$81` |
| `0x0298CE`: `F1 00 4D 00 C3 05` | index 1, `$055C` | `$81` |

Do not treat these later packets as proof that they ran on this route, and do
not render an actor until their event producer is connected. PPU bus events
are not applied to a renderer; visible output, actor graphics, and PPU/APU
timing remain unverified.

## Focused verification

The bounded live-route check is
[`verify_rom_slot01_second_nmi_root_cycle.gd`](../../../tools/diagnostics/verify_rom_slot01_second_nmi_root_cycle.gd).
It passed on Godot 4.7.2:

```text
godot --headless --path . --script tools/diagnostics/verify_rom_slot01_second_nmi_root_cycle.gd
```

It verifies the actual second-NMI selection, six inactive source actor flags,
the `$EE9F` and `$E3CA` returns, `$CB0F` save, next slot-$05 selection, the
unapplied 20-event PPU queue, and rejection of a dispatch/caller mismatch. It
does not establish later scenario-event timing or visual/audio fidelity.
