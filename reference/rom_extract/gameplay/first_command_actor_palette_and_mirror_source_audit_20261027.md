# First-command actor palette and mirror inputs: target-ROM audit

## Scope and ROM

This note independently checks the two shared inputs needed by the first-
command actor OAM renderer. It uses the supplied Turkish ROM
`Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
Offsets include the 16-byte iNES header. The 16 KiB bank-$14 window at CPU
`$8000` maps to file `0x028010`; bank-$10 at `$8000` maps to `0x020010`.
Captured RAM/PPU values cited below are validation evidence only.

## Palette index: `$08` selects index `$08`, not `$0A`

The normal-player palette path begins at bank-$14 CPU `$81E9` (file
`0x0281F9`). It resolves the selected player record, calls `$826A` to set the
graphic selector, reads the player ID from that record, and for a nonzero ID
calls `$8282` to select a palette index. The `$8282` bytes at file
`0x028292` are:

```text
A2 01 85 3B C9 01 F0 0C A2 00 C9 0F 90 06 C9 17 B0 02 A2 02 8A 20 09 C5
```

For player ID `$08`, the `$01` comparison fails, then `$08 < $0F` selects the
ordinary-player branch at `$82A0` (file `0x0282B0`): it returns the saved ID
unchanged. The palette base pointer table at CPU `$8264` / file `0x028274`
starts with `$B80C` (`0C B8`), the ordinary-player table.

The offset arithmetic at `$820D–$8232` (file `0x02821D–0x028242`) multiplies
the returned index by **five** before adding that table base. The relevant
sequence is `ASL; ROL $3B; ASL; ROL $3B; ADC $3A`, which forms `4*i + i`.
Thus player ID `$08` selects `B80C + 5×08 = $B834`, file `0x02B844`, whose
five-byte read window is:

```text
15 0F 30 30 30
```

The first byte is the shared slot-3 color; the following four bytes are the
slot-2 colors for the four sprite subpalettes. The ROM writer at
`$8241–$8263` (file `0x028251–0x028273`) writes `$0F` to slot 1 and leaves slot
0 untouched. For this endpoint, the resulting `$3F10–$3F1F` bytes match the
same-input PPU sample:

```text
0F 0F 0F 15  0F 0F 30 15  0F 0F 30 15  0F 0F 30 15
```

**Correction:** the earlier `$0A` label came from dividing the file-address
difference `$B834-$B80C=$28` by four. That is not the ROM's index arithmetic.
In particular, the statement in
[`first_match_asset_byte_map.md`](first_match_asset_byte_map.md) that the
ordinary table uses a four-byte stride and reads five bytes is superseded by
this direct instruction-level decode. The previous 4-byte-stride extraction
happened to address the same source bytes because `$0A×4 = $08×5`, so its
rendered row matched; it mislabeled the index and cannot be generalized. The
runtime calculation for this player is index `$08`, stride 5.

The general nonzero-ID selector is byte-backed in `$8282`: ID `$01` uses a
`$002A`-dependent special result; IDs `$0F–$16` use a `$002A`-dependent
alternate range; other IDs return themselves. The palette pointer table also
has alternate bases `$B6C7` and `$B767` for the player-ID-zero/special branch
at `$81FB–$820B`. Therefore a general implementation must port the actual
`$81E9/$8282` branch and pointer-base selection, not assume every player's
palette index is their ID. For the ordinary first-menu player, a source-only
function is straightforward once it receives the live selected player ID and
`$002A`.

### Which player-selection branch the first-command route uses

Animation `$5C` at file `0x029367` begins with `$F5 80`. The bank-$14 `$F5`
handler at CPU `$8153–$815E` (file `0x028163–0x02816E`) reads that operand and,
when its sign bit is set, calls `$81BA` at `$8159` (file `0x028169`). `$81BA`
masks with `$7F` and dispatches through its pointer list at `$81BF`; operand
`$80` becomes selector zero and enters handler `$81CF` (file `0x0281DF`). That
handler loads `$0441` and jumps to the shared palette setup at `$81EC`.
Therefore the actual `$5C` route uses the ball-holder slot, not `$0442`.

For the audited fresh-start input route, the ROM-derived receiver is slot
`$06`; the match-zero roster at file `0x004A57`, entry 6, gives ID `$08`. The
`$CD89` player-record pointer table (file `0x03CD99`) maps slot 6 to `$0348`,
whose player ID byte is `$08`. The current state provider reconstructs this
controlled-player record from the source replay and ROM tables, subject to its
documented input-hash restriction. The source-only chain is thus available
for this route: `$F5 80` → `$0441=$06` → player ID `$08` → palette index `$08`
→ `$B834`. An arbitrary interactive route still needs a generic ROM-derived
receiver/state producer.

The neighboring `$81E9` dispatch handler is a different selector: it loads
`$0442` and then uses the same record lookup. Fixed-bank field entry at
`$E0DF` (file `0x03E0EF`) executes `LDA #$00; STA $0442`, initializing the
selector before the fresh-start field route. The player-record pointer table
at `$CD89` (file `0x03CD99`) maps selector 0 to RAM `$0300`; match-zero roster
byte at `0x004A57`, entry 0, is ID `$02`. Thus, if `$81E9` is called after
that initialization and before another writer changes `$0442`, the
ROM-derived record is slot 0 / player ID `$02`. Same-input endpoint RAM
validates `$0442=0`, while `$0441=6`; that snapshot validates the route state,
not the assignment mechanism. Other selector writers exist for other game
contexts, so this zero-value resolution should not be generalized past the
fresh-start path without tracing those writers.

For the first-command animation, the source operand is `$F5 80`, which masks
to dispatch selector 0 and loads `$0441`; it does not call the `$81E9`/`$0442`
branch. The ROM-source path needed to derive the ID `$08` palette therefore
does not depend on `$0442` at all.

The shared palette writer leaves slot 0 untouched, so a renderer must receive
that color from the active background palette instead of deriving it from
this player row.

## Mirror: ROM transform is decoded; route state is not integrated

The sprite renderer consumes `$0517`. Scenario startup at bank-$10 CPU `$8021`
(file `0x020031`) copies the current `$0517` into scenario state `$052A`.
`$FD` at `$885D` (file `0x02086D`) reads its following byte, dispatches it
through `$886A` (file `0x02087A`), and stores the returned X value in `$052A`.
The inline vector table at file `0x02087D` maps operands `00,01,02,03,04` to
`$8877,$88AA,$88B5,$88BF,$88D9` respectively.

For `$FD 02`, handler `$88B5` (file `0x0208C5`) is `A2 00 AD FB 05 F0 02 A2
40 60`: it returns `$00` when `$05FB=0` and `$40` otherwise. This correction
replaces the earlier mistaken `$8895` address/context description; see
[`first_command_actor_fd_mirror_transform_audit_20261027.md`](first_command_actor_fd_mirror_transform_audit_20261027.md).
Scenario opcode `$F6` reaches `$87EC` (file `0x0207FC`), whose bytes
`A9 40 4D 2A 05 8D 2A 05 60` toggle bit `$40` in `$052A`.

The route has an earlier, distinct `$FD 00` in scenario `$36`, at CPU `$B7F3`
(file `0x023803`). Operand zero dispatches to `$8877`, which reads ball-holder
slot `$0441`, obtains its player record through `$C50C`, and uses `$0638` via
`$C536` to calculate its returned mirror flag. The source code defines this
calculation, but Godot does not yet execute it as part of the live route.
The fixed-bank bridge at CPU `$ED0C` (file `0x03ED1C`) copies `$052A` to
`$0517` when the ROM worker runs that bridge.

The **same-input muted FCEUX trace** is validation evidence, not a runtime
source: scenario `$36` starts at frame 8593; `$052A` becomes `$40` at the
`$885D` store on frame 8624; a frame-8640 RAM snapshot retains `$052A=$40`;
the bridge copies it into `$0517` on frame 8656. At frame 8953, `$0517=$40`
while `$052A=$00`, confirming that the scenario field is mutable and cannot
replace the committed renderer field. These observations agree with the ROM
paths but do not themselves establish a general Godot producer.

## Runtime conclusion and open work

- **Palette:** the actual first-command `$F5 80` command source-selects the
  current ball-holder via `$0441`; for the audited route, the source-derived
  slot/roster/record path gives ID `$08` → palette index `$08` → `$B834` / file
  `0x02B844`. The neighboring `$F5 81` branch selects `$0442`, whose fresh
  field-entry value 0 maps to slot 0 / player ID `$02`; it is not used by
  animation `$5C`.
- **Mirror:** `$FD 02` and `$F6` are byte-decoded, and `$FD 00`'s ROM handler,
  scenario input, and `$ED0C` copy are identified. The first-menu route still
  lacks a Godot producer that advances this scenario state and bridge in source
  order, including the prior actor/receiver history. Keep `$0517` as an explicit
  actor-presenter input until that route producer is integrated; do not infer it
  from the player ID or substitute the endpoint `$052A` value.
- **Do not claim:** a complete arbitrary-route palette/mirror producer, or
  that the frame-8953 captured values by themselves reveal the upstream state
  transition. Emulator captures validate the endpoint only.
