# First-command field packet descriptor `$063D`

Status: ROM-only source audit; no emulator was run and no production runtime
code was changed.

Target ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
Offsets below include the 16-byte iNES header. Fixed bank `$1F` is mapped at
CPU `$E000` from file base `0x03E010`; bank `$1A` at `$8000` uses file base
`0x034010`.

## Selector routine

The selector is in fixed bank `$1F`, CPU `$EFF6–$F00E`, file
`0x03F006–0x03F01E`. Its exact bytes are:

```text
AE 21 06       LDX $0621
BD 0F F0       LDA $F00F,X
8D 3D 06       STA $063D       ; instruction at $EFFC
8A             TXA
D0 11          BNE $F013
AD 00 06       LDA $0600
D0 0C          BNE $F013
A9 02          LDA #$02
8D 3D 06       STA $063D       ; instruction at $F009
4C 13 F0       JMP $F013
```

The four lookup bytes at `$F00F–$F012` are `00 00 01 00`. `$063D` is first
loaded from the context-indexed table. For context `$0621=0`, that temporary
value is `$00`; if `$0600` is also zero, the routine replaces it with `$02`.
If either condition fails, the initial table value remains. `$063D` selects
the field-packet stream used by `$F015/$F114`; this is distinct from the
action-window UI descriptor also numbered `$02` in the `$D5C3` menu path.

## Fresh first-command route inputs

The target-ROM path supplies both selector inputs without needing endpoint
RAM as runtime state:

1. Fixed-bank `$E349` checks `$05FB`; on the fresh home-possession route,
   `$05FB=0`. With B held (`$001C & $40`), the branch at `$E360` reaches
   `$E382` (file `0x03E392`). The bytes there start `A9 00 8D 00 06`: the
   source explicitly clears defender count `$0600` at `$E384`, then clears
   `$0615`, queues scenario `$44`, and switches to bank `$1A`.
2. Bank `$1A` `$803C` (file `0x03404C`) starts `A9 00 8D 4E 04 8D 21 06`.
   The `STA $0621` at `$8041` sets the fresh action-menu context to zero
   before it calls the shared menu setup.
3. Thus, when the field-packet selector executes for this fresh B/menu path,
   its ROM-derived inputs are `$0621=0` and `$0600=0`, which compute
   `$063D=2` by the selector above. This result is consistent with the
   existing route trace: the RAM-write log reports `$063D: 00→00` at PC
   `$EFFF`, then `$00→02` at PC `$F00C` on frame 8908. Those trace files are
   validation evidence only; the runtime result follows from ROM code and
   route state, not from those captured values.

The endpoint `$063D=$02` is therefore not an unexplained fixture for this
route. `RomFirstCommandFieldDescriptorResolver` implements the pure
branch/table rule from explicit caller-owned `menu_context_0621` and
`defender_count_0600` values. It hash-checks the byte-preserved ROM instruction
and lookup spans under
`reference/rom_extract/gameplay/first_command_field/descriptor_selector/`;
it does not read endpoint RAM or select `$02` from a route/input hash.

The focused verifier
`tools/diagnostics/verify_first_command_field_descriptor_resolver.gd` passed
with Godot 4.7.2: `(context=0, defenders=0) -> $02`, `(context=1,
defenders=0) -> $00` from lookup byte `$F010`, and `(context=0, defenders=1) ->
$00` from lookup byte `$F00F`. It also confirms that contexts outside the
preserved four-byte lookup range fail explicitly. These checks establish the
helper's source contract, not route integration or generic lifecycle.

The current `KickoffRouteRuntime` models the B/menu stage but does not retain
the two selector inputs as source-owned state. Production wiring still needs
an explicit menu-entry state/event; keep the UI window IDs and field-packet
descriptor ID as separate concepts. `$05CE` placement and holder-coordinate
route state remain independent unresolved inputs to the packet presenter.
