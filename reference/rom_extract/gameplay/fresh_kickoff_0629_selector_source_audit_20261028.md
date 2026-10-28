# Fresh KICK OFF `$0629` selector source audit — 2026-10-28

Status: static source audit against the supplied Turkish ROM; no emulator was
used and no production runtime code was changed.

Target ROM SHA-256:
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
File offsets include the 16-byte iNES header. The relevant mappings are bank
`$80` at `$8000` (`0x000010 + address - $8000`), bank `$82` at `$A000`
(`0x004010 + address - $A000`), and the fixed bank at `$C000`
(`0x03C010 + address - $C000`).

## Conclusion

The fresh-start route produces selector `$0629=0` through decoded source
logic after the opening. The opening does reuse `$0628/$0629` for PPU queue
state, so cold-reset values alone are insufficient. However, the post-opening
new-match setup clears `$0629` before gameplay setup, and the fresh-period
initializer then writes zero to `$0629` again immediately before entering the
kickoff dispatcher. Selector 0 can therefore be supplied by the route model
from ROM-derived logic; it is not a value that must remain caller-owned or be
copied from endpoint RAM.

## Byte-checked route and writer chain

| Source step | Supplied-ROM bytes / effect |
|---|---|
| KICK OFF | Bank `$80:$80E6`, file `0x0000F6`: `20 A0 9B A9 01 20 64 84 ...` calls screen cleanup and cutscene ID 1. After it returns, `$80FD` (file `0x00010D`) begins `A9 00 85 28 85 29 85 27`, explicitly setting period `$0027=0`. The pre-match scene ID 2 then returns through `$8163` (`4C 17 80`) to `$8017`. |
| New-match entry | `$8017` loads bank `$82` and jumps to `$A203`; local bytes at file `0x004213` are `4C AF A2`. `$A203` therefore jumps to `$A2AF` at file `0x0042BF`. |
| Post-opening RAM clear | `$A2AF` sets `$EC=$68`, A=`$98`, X=2, Y=4, and calls `$AA06` (`20 06 AA` at `$A2E2`). The target-ROM bytes at file `0x004A16` are `84 ED E8 A0 00 48 A9 00 91 EC E6 EC D0 02 E6 ED 68 38 E9 01 D0 EF CA D0 EC 60`. This is a zero-fill routine: it stores Y in `$ED`, increments X to 3, then writes 152 bytes on the first pass and 256 bytes on each of the next two passes. The latter passes wrap A from zero through a full byte because the loop does not reload it. Total: 664 bytes, `$0468..$06FF` inclusive, ending with pointer `$0700`; this clears `$0629` and `$05CD/$05CE`. `$A2AF` then jumps through `$C557`. |
| Gameplay scheduler setup | Fixed-bank `$C557`, file `0x03C567`, is `4C BE C6`, a jump to `$C6BE`. `$C6BE` seeds coroutine slot 5 with return address `$D11E-1` and enters the task scheduler at `$CA97`. |
| Fresh-period selector write | The scheduled `$D11E` routine reads `$0027`. For fresh start it is 0; the non-penalty branch reaches `$D14F`, whose local bytes include `8D 29 06` (`STA $0629`). It writes the period value, hence zero. `$D180` then jumps to `$DAAA`. |
| Dispatcher | `$DAAA` calls its setup helpers and then `$DB24`; `$DB24` at file `0x03DB34` begins `AD 29 06 20 99 CB`, reading `$0629` as the five-way selector. Zero selects table entry `$DB34`. |

The `$AA06` behavior above was decoded from the supplied bytes, including its
caller arguments and indirect-address loop. The pinned English-translation
disassembly labels the helper's range as `$0468-$06FF`, which agrees with the
range calculated from the supplied Turkish ROM bytes. The local ROM bytes and
their execution semantics are the implementation evidence here; the former
claim that the external routine's implementation/range differed from this ROM
was unsupported and is withdrawn.

## Related `$063D` selector inputs

The existing
[`first_command_field_descriptor_063d_source_audit_20261028.md`](first_command_field_descriptor_063d_source_audit_20261028.md)
already resolves these source-owned values:

- On the fresh left-possession B/menu path, fixed-bank `$E384` clears
  `$0600` before scenario `$44` and the bank `$1A` handler.
- Bank `$1A:$803C` writes zero to `$0621` at `$8041` before the shared menu
  setup.
- The fixed-bank `$EFF6` selector therefore evaluates `$0621=0` and
  `$0600=0`, producing `$063D=2` from its ROM table and branch.

These are separate later field-menu inputs. The current Godot route still needs
to emit the source-owned B/menu state/event to carry them into the field packet
producer; the RAM trace is validation evidence only.

## Documentation reconciliation / GOAL update plan

The conclusion in
[`fresh_start_to_first_command_menu.md`](fresh_start_to_first_command_menu.md)
that gameplay setup clears `$0629` and selects branch 0 is correct, but should
cite the concrete `$A2AF -> $AA06` clear and `$D11E -> $D14F` write above.
The earlier caveat in
[`fresh_kickoff_position_context/source_audit.md`](fresh_kickoff_position_context/source_audit.md)
that the opening-to-kickoff `$0629` transition is unresolved is superseded.
The `GOAL.md` status should remove `$0629` from caller-owned/unresolved route
inputs while retaining unresolved live callback history, `$05CD/$05CE`, RNG,
and gameplay field-loop integration. This audit resolves the selector
boundary only; it does not claim that the first command panel is production
integrated.
