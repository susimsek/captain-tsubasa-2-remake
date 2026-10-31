# Animation `$8F` setup and actor-seed boundary — 2026-10-30

## Finding and evidence limits

The supplied ROM is SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`
(iNES 1.0, mapper 4). This audit follows animation `$8F` from `$F5` through
the five `$F1` record constructors and the real `$F0` return to fixed-bank
`$EEB1`. Exact ROM spans and hashes are in [manifest.json](manifest.json).
The muted FCEUX trace is validation only; no trace row or RAM snapshot is a
runtime input. No emulator state or Godot runtime file was changed.

The bounded audit follows the source through the first actor's renderer return
at `$EF38`. The trace validates packet/record state but does not hook the
`$EF11`, `$EF23`, `$EF35`, or `$EF38` PCs; those call-site results below are
static control-flow conclusions, not direct trace observations. The production
Godot route now executes the `$F5/$F4/five $F1/$F0` prefix, walks the five
active records through the ROM-derived appearance, motion, and OAM code, then
returns to `$CA55` and runs the caller's `$E3CA` no-direction path. It reaches
the next slot-$09 `$ED5B` source gap; the full route and visible renderer remain
incomplete.

## Source path and byte advances

The pointer-bounded animation stream is bank `$14`, CPU `$9885–$98AA`
inclusive, file `0x029895–0x0298BA`; its first `$F1` is at stream offset 7 and
its `$F0` is at offset 37:

```text
F5 0A | F4 2C 0B 05 07 |
F1 00 91 00 D3 01 | F1 70 92 28 C3 05 |
F1 70 92 00 C3 08 | F1 71 93 B8 B3 0C |
F1 71 93 00 B3 10 | F0
```

Bank `$14` maps the `$8000–$BFFF` window from file base `0x028010`.
The fixed actor loop is in bank `$1F` at `$EE9F` / file `0x03EEAF`; the
post-render `$EF38` continuation is file `0x03EF48`.

The handler bytes relevant to the two stream advances are:

```text
$8142: A0 01 B1 4C 99 93 04 C8 C0 05 D0 F6 A9 05 4C CF 83
$8153: A0 01 B1 4C 10 06 20 BA 81 4C 64 81
$815F: A2 10 20 30 C5 20 33 C5 00 6C 04 A9 02 4C CF 83
```

| Source command | ROM handler and effect | Stream advance |
| --- | --- | ---: |
| `$F5 $0A` | `$8153` loads operand `$0A`; `BPL` at `$8157` takes the positive path to `$815F`. That path calls `$C530` then `$C533`; its tail supplies `$02` to `$83CF`. `$83CF` returns to the `$806D` parser. | `+2` |
| `$F4 $2C $0B $05 $07` | `$8142` copies the four operands to `$0494–$0497`, then supplies `$05` to `$83CF`. The parser next reads the first `$F1`. | `+5` |
| Five `$F1` packets | `$80AA–$8127` clears and constructs the selected 21-byte records; each command advances by its six source bytes. | `+6` each |
| `$F0` | Dispatch-table entry at `$808A` targets `$80A2`. `68 68 A9 00 8D 3A 05 60` drops the two nested dispatch/worker return frames, clears `$053A`, then returns to the fixed-bank caller at `$EEB1`. | `+0` |

The positive `$F5` branch is operand-sign controlled. `$0A` takes `$815F`; the
negative `$80` form takes the separate `$81BA` branch. The handler does not
test `$0542`; the checked `$CC02` and `$CCD2` helpers contain no direct
`$0542`, `$4E`, or `$4F` gate either. This is limited to this handler path and
its checked callees, not a global claim about every ROM routine. `$C533`
reaches `$CCD2`, whose source calls `$CB0F`; the same-frame trace confirms the
route proceeds into `$F4` and `$F1` parsing after the helper sequence. The
trace does not expose every intermediate stack/interrupt instruction.

The resulting five packet records are the source-selected entries already
documented by the [actor-constructor audit](../actor_packet_constructor/f1_actor_record_constructor_slice_20261028.md):
`$0547/$055C/$0571/$0586/$059B`, with flags `$81/$81/$80/$80/$80`.
The F1 record constructor and script roots are source data, not captured actor
state.

## FCEUX validation

The two-pass trace is FCEUX 2.7.0, NTSC, NewPPU enabled, audio muted; both
passes replay the same input from the verified in-memory frame-8399 checkpoint.
Use mapped bank as well as PC when reading its hooks. In source frame 8481:

- `$EE9F` is entered at cycle 2053; bank `$14:$800F` starts the `$8F` worker
  at cycle 2133.
- Bank `$14:$814C` records the four `$F4` bytes in A at cycles 3254, 3271,
  3288, and 3305: `$2C,$0B,$05,$07`.
- Bank `$14:$80AA` records five constructor entries at cycles 3412, 3999,
  4588, 5177, and 5766. Same-address hits in bank `$16` are unrelated and are
  excluded.
- The watched write at `$80A9` clears `$053A` from `$01` to `$00` at cycle
  6367, matching the `$F0` handler's store. The trace did not install a PC hook
  at `$EEB1`; that return target is established by the ROM stack/control flow.

The supplemental frame-8481 RAM snapshot is also validation only. It records
`$004C/$004D=$98AA`, `$0494–$0497=2C 0B 05 07`,
`$053A–$053D=00 00 8F 00`, `$0542=00`, and the five active flags above.
`$053D=0` is not the number of active records.

## First active actor and stop boundary

At `$EEB1` the fixed-bank code resets `$003A/$0048`, loads `$053D`, and takes
the zero branch to `$EEDA`. The first packed order byte `$0543=$01` resolves
the first record pointer at `$EF73` to `$0547`; its source `$F1` flag is `$81`,
so `$EEFB BPL $EF38` falls through into actor processing. The supplemental
frame-8481 snapshot has `$0615=0`, so the `$EF00 BVS $EF14` appearance-skip
branch is not taken. The ROM call sequence is:

1. `$EF11 JSR $8006` with bank `$14` mapped at `$8000` (appearance `$83D9`).
2. `$EF23 JSR $8003` with bank `$14` mapped (motion `$84DC`).
3. `$EF35 JSR $8000` with bank `$16` mapped (sprite/OAM engine).

After that renderer returns, `$EF38` is `INC $003A`; `$EF3A` loads the new
ordinal and `$EF3C/$EF3E` compare it with six and branch back to `$EEDA` for the
next record. Therefore `$EF38` is an **intra-loop continuation**, not a yield
or caller return. The audit stops immediately before its increment, after the
first actor's source appearance, motion, and renderer calls. It does not infer
later actors or later ticks from the endpoint snapshot.

## Existing Godot components to reuse

| Component | Reusable behavior | Still missing for the live route |
| --- | --- | --- |
| [`RomActorAnimationStreamDecoder`](../../../../scripts/gameplay/rom_actor_animation_stream_decoder.gd) | Hash-checks and decodes animation `$8F` commands at source-relative offsets. | It does not schedule or apply the live scenario/task handoff. |
| [`RomF1ActorRecordConstructor`](../../../../scripts/gameplay/rom_f1_actor_record_constructor.gd) | Builds the five `$8F` 21-byte records from the live `$F1` packets and ROM pointer tables. | Later scenario records and actor seeds still need live route inputs. |
| [`RomActorStateInterpreter`](../../../../scripts/gameplay/rom_actor_state_interpreter.gd) | The production route invokes the audited appearance/motion interpreters for all five active records and follows the loop back to its source caller. | Later animation states, source-frame cadence, and the real PPU sprite presentation remain open. |
| [`GameplayRomActorOamBuilder`](../../../../scripts/gameplay/gameplay_rom_actor_oam_builder.gd) and [`GameplayRomOamSpriteLayer`](../../../../scripts/gameplay/rom_oam_sprite_layer.gd) | The route builds a 256-byte OAM shadow with 34 sprites. The independent early-OAM verifier matches 34/34 frame-8481 tuples and all five actor cursor boundaries; the existing endpoint check matches 164/164 bytes. | Route-produced OAM is not yet applied to the visible renderer. The actor output was checked against the muted frame-8481 trace while Godot labels the boundary frame 8464, so source-frame timing and pixel parity are not established. |
| [`FirstCommandActorSourcePresenter`](../../../../scripts/gameplay/first_command_actor_source_presenter.gd) | Presents a frozen scenario `$44` / animation `$5C` endpoint lineup from ROM resources. | It is endpoint-only and does not reproduce this earlier `$8F` route timing. |

This closes the first live `$EE9F` actor-call route segment and its scheduler
return. It does not establish frame-matched pixels, full field composition,
later scenario/actor timing, PPU/APU parity, or arrival at the first command
menu.
