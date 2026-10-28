# Fresh KICK OFF actor initialization: ROM-only path to the first menu lineup

## Scope and evidence boundary

This audit follows the source path that prepares the final three actors shown
at the first in-match command menu. It uses the supplied Turkish ROM as the
runtime-data source and the retained actor/RAM trace only to check the decoded
result. It does not use emulator images, OAM dumps, or captured audio as runtime
assets, and it does not change Godot runtime code.

- ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- Bank `$10` scenario `$44` source is `0x0237E5`; bank `$14`'s `$8000–$BFFF`
  source window begins at `0x028010`, so a CPU address `a` in that window maps
  to file offset `0x028010 + (a - $8000)`.
- The same-input frame-8953 RAM/actor snapshots are validation-only. See
  `reference/diagnostics/kickoff_select_test_20261027/ram/route_frame_008953.bin`
  and `reference/diagnostics/first_command_actor_oam_20261027_113609_utc/`.

## Source-proven setup: scenario `$44` selects actor animation `$5C`

The bank-$10 scenario pointer table at CPU `$89BF` / file `0x0209CF` points
scenario `$44` to CPU `$B7D5` / file `0x0237E5`. Its first record is:

```text
02 70 5C F0
```

The byte-checked scenario reader stores the four fields in `$0523`, `$0524`,
`$0528`, and `$0529`; the inline `$F0` transformer changes the final field to
`$FF`. Thus this record supplies animation selector `$5C` through `$0528`.
Fixed-bank code reads `$0528` at CPU `$ECF8` (file `0x03ED08`), stores it to
`$053C` at `$ECFB`, then writes `$80` to `$053A` at `$ED00`. `$053A` starts the
bank-$14 animation worker; it is not an actor record or a captured pose.

The bank-$14 worker at `$800F` / file `0x02801F` indexes its animation pointer
table at CPU `$8968` / file `0x028978`. Entry `$5C` is at
`0x028978 + 2×$5C = 0x028A30`, where the ROM bytes are `57 93`, a pointer to
CPU `$9357` / file `0x029367`.

## `$F1` packets create the three actor records

The source stream at `$9357` begins:

```text
F5 80 F4 08 09 0A 0B
F1 00 CD 00 C3 0D
F1 00 CA 00 C3 01
F1 00 CB 00 C3 05
F0
```

The `$F1` handler at `$80AA–$8127` is the source record constructor. It selects
an actor record using packet byte 5: `(value & $1C) >> 2` indexes the pointer
table at `$88E4` (file `0x0288F4`), and the low two bits form the record's
active flag after `$80` is ORed in. It clears all 21 bytes in that selected
record, then resolves packet byte 1 through pointer table `$A1B4` and packet
byte 2 through `$AC47`. It writes those two pointers at record offsets `+$01`
and `+$03`; packet coordinate bytes are written to the actor coordinate
fields. The following `$F0` ends this animation setup stream.

The exact table lookups from local ROM bytes are:

| `$F1` packet | Actor index / record | `$A1B4` motion entry | `$AC47` main-script entry | Active byte |
|---|---|---|---|---:|
| `00 CD 00 C3 0D` | index 3 / `$0586` | index `$00` → `$A38A` | index `$CD` → `$B5B2` | `$81` |
| `00 CA 00 C3 01` | index 0 / `$0547` | index `$00` → `$A38A` | index `$CA` → `$B5AC` | `$81` |
| `00 CB 00 C3 05` | index 1 / `$055C` | index `$00` → `$A38A` | index `$CB` → `$B5AE` | `$81` |

The pointer-table entries are directly byte-checked:

- `$A1B4[$00]`: file `0x02A1C4`, bytes `8A A3` → `$A38A`.
- `$AC47[$CA]`: file `0x02ADEB`, bytes `AC B5` → `$B5AC`.
- `$AC47[$CB]`: file `0x02ADED`, bytes `AE B5` → `$B5AE`.
- `$AC47[$CD]`: file `0x02ADF1`, bytes `B2 B5` → `$B5B2`.
- `$88E4[$00/$01/$03]`: file `0x0288F4`, entries `47 05 / 5C 05 / 86 05` →
  `$0547/$055C/$0586`.

The three main-script streams are also original ROM data. `$B5AC` at file
`0x02B5BC` begins `F7 00 F7 04 F7 06 F7 0A`; `$B5AE` begins at
`0x02B5BE` with `F7 04`; `$B5B2` begins at `0x02B5C2` with `F7 0A`. These
`$F7` commands set the descriptor byte and hold the selected pose. That
accounts for the source-selected first appearances `$00`, `$04`, and `$0A`.

## Validation against the retained endpoint

At the first command-menu endpoint, the retained frame-8953 RAM rows for
`$0547`, `$055C`, and `$0586` have active flag `$81`, main pointers `$B5AC`,
`$B5AE`, and `$B5B2`, coordinate inputs `X=$00/Y=$C3`, and descriptors
`$00/$04/$0A`. This agrees with the actor table selections and the three
ROM-owned `$F7` streams above. The snapshot is only a validation result; it was
not used to construct or package those rows.

The initial audit left the `$A38A → $A390` motion transition open. The ROM
command and timer path is now decoded below; this closes the actor's short
motion initialization at the final lineup, while leaving the earlier route
actor-state transitions separate.

## Follow-up: motion stop, held pose, and endpoint OAM

### Motion stream `$A38A → $A390 → hold`

The `$F1` packets set each final actor's secondary stream pointer to `$A38A`.
Bank-$14 `$84DC` / file `0x0284EC` reads the actor's `+$11` timer. When it is
zero, the routine loads the pointer at `+$01/+02`, dispatches the first stream
byte through `$857A` / file `0x02858A`, applies the command, and stores the
advanced stream pointer back into the actor record.

The target-ROM bytes at `$A38A` / file `0x02A39A` begin:

```text
01 01 00 00 00 00 00 01 ...
```

Opcode `$01` dispatches to `$85A9` / file `0x0285B9`. That handler reads the
duration byte `01` into `+$11`, then reads two 16-bit motion operands. All four
operand bytes are zero. The dispatcher consumes six bytes total, so the ROM
advances the cursor from `$A38A` to `$A390`; it also applies the zero deltas to
the actor's fixed-point motion lanes. The first command therefore leaves the
coordinates supplied by `$F1` unchanged.

The next source byte at `$A390` / file `0x02A3A0` is `$00`. On the next call,
`$84DC` decrements the one-tick timer to zero. On the following actor update,
opcode `$00` dispatches to `$85A0` / file `0x0285B0`, writes `$FF` to `+$11`,
and returns out of the interpreter without advancing the pointer. The route
trace's validation snapshots show exactly that progression for all three
actors: frame 8907 has pointer `$A390` and timer 1; frame 8908 has timer 0;
frame 8909 onward has pointer `$A390` and timer `$FF`. The matching endpoint
records keep the initial `$00/$C3` coordinate operands unchanged. In the
retained actor draw trace, each of the three records holds the same 21-byte
state at every draw from frame 8909 through 8953 (45 draws per actor). This
checks the source decode; it is not a runtime state source.

This is a complete ROM explanation of the final actors' motion state. It does
not decode how the earlier route actors transition through `$B539/$B440/$B020`
and related script cursors before animation `$5C` is queued.

### Appearance stream and descriptor-to-OAM mapping

The `$F1` packets set appearance streams `$B5B2/$B5AC/$B5AE`. At `$83D9` /
file `0x0283E9`, the first `$F7` command is dispatched to `$84C7` /
file `0x0284D7`: it copies the following byte into record `+$12`, then follows
the `$8450` exit at file `0x028460`, which sets the appearance timer `+$10` to
`$FF`. The ROM stream bytes and resulting held descriptors are:

| Actor record | Main stream | Stream prefix | Held descriptor |
|---|---|---|---:|
| `$0547` | `$B5AC`, file `0x02B5BC` | `F7 00` | `$00` |
| `$055C` | `$B5AE`, file `0x02B5BE` | `F7 04` | `$04` |
| `$0586` | `$B5B2`, file `0x02B5C2` | `F7 0A` | `$0A` |

The source then maps the held descriptor and selector `$08` through bank-$16
tables and streams. `$00` resolves through `$842C` and selector branch `$84DF`;
`$04` resolves through `$87D9` and branch `$87F2`; `$0A` resolves directly
through `$896B`. The bank-$16 run/jump parser, transform, and X/Y offset
tables are already implemented by
[`gameplay_rom_actor_oam_builder.gd`](../../../scripts/gameplay/gameplay_rom_actor_oam_builder.gd).
Its focused endpoint comparison previously generated all 41 actor sprites and
matched all 164 OAM bytes in slots 0–40; the procedure and exact tuple evidence
are recorded in
[`first_command_field_live_source_summary_20261027.md`](first_command_field_live_source_summary_20261027.md).
That comparison used endpoint actor records only as a diagnostic input; the
ROM stream bytes remain the runtime source.

The held script pointers at frame 8953 are also explained by the ROM handler.
The `$F7` branch at `$84C7` / file `0x0284D7` reads the inline operand into the
actor's `+$12` descriptor, then jumps to `$8450` / file `0x028460`, which sets
the `+$10` timer to `$FF` and exits. This direct-control path does not write an
advanced script pointer back to `+$03/+04`; therefore the rows remain at
`$B5AC/$B5AE/$B5B2` while their descriptors hold at `$00/$04/$0A`. These are
source-defined static endpoint poses, not a repeating `$F7` animation.

### Endpoint renderer inputs with ROM paths

For the first-menu actor layer, the needed source inputs now have direct paths:

- Active actor records, main script pointers, coordinates, and descriptor
  bytes come from scenario `$44` → animation `$5C` → `$F1` constructors.
- The animation prefix's `$F4 08 09 0A 0B` command is handled at `$8142` /
  file `0x028152` and writes the four sprite CHR selectors to `$0494–$0497`.
- Selector `$0546=$08` is the player graphic class selected by the live player
  data: endpoint ball-holder index `$0441=$06` resolves to player ID `$08`, and
  bank-$14 `$826A` uses table `$88F0` (file `0x028900`) to produce selector
  `$08`. The target-ROM lookup is also mapped in
  [`first_match_asset_byte_map.md`](first_match_asset_byte_map.md).
- Mirror mode `$0517` is the actor renderer's field-direction input. The fixed
  scenario bridge at `$ECF8–$ED03` (files `0x03ED08–0x03ED13`) copies animation
  selector `$0528` to `$053C` and starts the bank-$14 worker; a separate fixed
  copy at `$ED0C–$ED0F` moves the scenario mirror field `$052A` into `$0517`.
  Bank-$10 scenario start at `$8021–$8024` seeds `$052A` from `$0517`, and its
  `$F4/$F5/$F6` handlers control the mirror bit. The retained route state has
  `$0517=$40`; this corresponds to the 8-pixel horizontal reflection applied
  by the source renderer. The earlier scenario transition that first
  establishes that value is not part of the final `$5C` actor packet.
- Clip bounds `$0540/$0541` and order `$0543–$0545` are initialized by bank-$14
  `$800F` to `$00/$FF` and `01/23/45`; scroll `$0538` is zero in the endpoint
  state. These are renderer state, not sprite pixels.

### Player sprite palette versus the `$49` cutscene palette

The first-command player palette is the bank-$14 player-data path, not the
generic cutscene selector `$49`:

1. The `$F5 80` setup enters the bank-$14 command dispatcher at `$81BA`
   (file `0x0281CA`). Its command-zero function at `$81E9` resolves the
   selected player record, calls `$826A` to set graphic selector `$0546`, and
   builds the player colors in RAM `$047F–$048E`. The selected player record
   and `$88F0` lookup are documented above and in
   [`first_command_panel_rom_mapping.md`](first_command_panel_rom_mapping.md).
2. For endpoint player ID `$08`, the ordinary palette table base is `$B80C`
   (table pointer at `$8264`, file `0x028274`). The derived source window is
   `$B834`, file `0x02B844`, bytes `15 0F 30 30 30`. The writer at `$8241–$8263`
   distributes the first byte as slot 3 and the following four bytes as the
   four slot-2 colors; it writes `$0F` into slot 1 and leaves slot 0 alone.
   The result in `$047F–$048E` is
   `0F 0F 0F 15 / 0F 0F 30 15 / 0F 0F 30 15 / 0F 0F 30 15`, matching the
   endpoint PPU sprite palette bytes.
3. The fixed-bank palette queue consumer at `$C8FB` (file `0x03C90B`) reads
   queued packet pointers from `$0499…` and writes packet address/data bytes
   through `$2006/$2007`. The endpoint packet at `$046C` has header
   `20 00 3F` followed by the 32-byte `$046F–$048E` palette buffer; the PPU
   snapshot's `$3F00–$3F1F` bytes match that buffer, including the `$3F10`
   universal-color mirror. The queue is enqueued by `$CCD2` (file `0x03CCE2`)
   when a caller supplies inline pointer `$046C`.

This establishes the player palette's ROM source and the generic packet
consumer. The endpoint RAM/PPU equality validates the result, but the existing
route trace does not identify the exact enqueue/commit event that uploads the
post-`$81BA` player colors. Do not infer a frame or scanline for that transfer.
The separate bank-0 `$9ADA` routine indexes ROM table `$D310` by `$49` and
stages 16 cutscene colors at `$063A–$0649`; that path is not the first-command
player palette source. In particular, endpoint `$49=$40` must not be used to
select the field actor's colors.

### Integration recommendation and boundary

The final menu actors do not need a captured pose, OAM dump, or hand-authored
sprite sheet. Integrate the ROM animation `$5C` event and its `$F1`, motion,
and `$F7` command handlers into the route source runtime, then pass their live
21-byte actor rows plus the source-derived selector/mirror/clip state into the
existing OAM builder and ROM CHR layer. This source-only path provides enough
data to reproduce the three final actor sprites at frame 8953 once the route
supplies its source-defined shared state. Keep the builder's endpoint parity
check as a diagnostic guard, not as a runtime state provider.

The first-menu actor output is now source-reconstructible, but the milestone's
full route is not thereby closed: the actor writer/dispatcher chain for earlier
cursor states and their animation timing remain unresolved, and field/map
composition and gameplay PPU timing are separate open work. Do not use the
frame-8953 record or OAM snapshot to fill those route-state gaps.

The source-backed NMI scroll and scanline-IRQ split path, plus its unresolved
route timing evidence, are documented separately in
[`first_command_irq_viewport_split_audit_20261027.md`](first_command_irq_viewport_split_audit_20261027.md).

## What the other observed pointers mean, and what remains open

The live trace labels `$03/$04` as `script_ptr`; this is the mutable cursor
stored in each actor record at the draw call. It can point after a timed
descriptor pair, so it is not necessarily the stream's initial root. The ROM
bytes explain several observed cursor states:

- At `$B026`, bytes `04 00 04 01 04 02 04 03 F3 26 B0` advance through four
  descriptors and loop to `$B026`. After the first pair, the cursor is `$B028`
  with descriptor `$00`; after the next it is `$B02A` with descriptor `$01`.
- At `$B040`, `04 04` leaves cursor `$B042` with descriptor `$04`. The bank-$14
  script also contains explicit `F3 → $B028` and `F3 → $B042` branches at
  `$B0B1/$B0B4` (file `0x02B0C1/0x02B0C4`). These bytes account for the
  observed cursor values, but do not identify which route actor initializer
  first entered the surrounding script.
- At `$B537`, bytes `04 7D` leave cursor `$B539` with descriptor `$7D`.
  At `$B43E`, bytes `03 7D` leave cursor `$B440` with descriptor `$7D`. These
  pair boundaries fit the retained cursor/descriptor snapshots. The previous
  dispatcher or actor-record write that selects those sequence regions is not
  established by these local bytes alone.
- `$B020` begins `F2 01 CA F3 1E B0`; no bank-$14 literal `$F3 → $B020` was
  found. `$B09F` is likewise a recorded cursor, not a proven setup root.
  Do not treat either address as a separately decoded initializer.

The actor draw trace shows the route evolving through `$B539`, `$B440`,
`$B020` and related cursor states, then the lineup cursors `$B028/$B042/$B09F`,
before scenario `$44` installs the final `$B5AC/$B5AE/$B5B2` main-script
pointers. The failed actor-writer replay did not log the writes to
`$0547–$05C4` with their caller PC and PRG bank, so the earlier writer chain,
and the transition conditions among those earlier states remain unresolved.
The final `$A38A → $A390 → $FF` motion stop is decoded above and validated
against the retained draw-time rows; it is not part of the remaining gap. No
retry of the stalled writer replay was made for this audit.

The endpoint actor/OAM work can therefore promote the decoded `$F1` packet
schema and `$5C` setup data as source-only inputs. It cannot yet promote the
full route-time actor state producer or claim the actor animation timeline is
reproduced from KICK OFF. Keep captured RAM/OAM out of runtime resources.
