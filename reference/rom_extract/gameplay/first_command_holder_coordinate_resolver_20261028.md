# First-command holder coordinates: ROM copy path and route-state boundary

## ROM identity and scope

This note follows the values copied to `$0635/$0637` before the bank-$1F
`$F0B5` holder-tile writer. The supplied Turkish ROM SHA-256 is
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
The preserved code spans and source hashes are in
`first_command_field/holder_coordinates/manifest.json`. The Godot helper
`scripts/gameplay/rom_first_command_holder_coordinate_resolver.gd` consumes
only those ROM bytes and the existing ROM-derived match-position initializer.

## Byte-verified coordinate-copy path

Fixed-bank `$1F:$E0F6` (file `0x03E106`) calls `$E6EC` with bytes `20 EC E6`.
The `$E6EC–$E708` span (file `0x03E6FC`, 29 bytes) decodes as:

```text
AD 41 04       LDA $0441       ; current ball-holder slot
20 7C CD       JSR $CD7C       ; resolve its $0300-record pointer
A0 06          LDY #$06
B1 34          LDA ($34),Y     ; record X
8D 35 06       STA $0635
AA             TAX
A0 08          LDY #$08
B1 34          LDA ($34),Y     ; record Y
8D 37 06       STA $0637
A8             TAY
20 E2 CD       JSR $CDE2
8D FE 05       STA $05FE
60             RTS
```

The existing position-source audit preserves `$CD7C` code at file
`0x03CD8C` and the 22-entry pointer table `$CD89` at `0x03CD99`. `$CD7C`
doubles the supplied holder slot and stores the corresponding pointer in
`$0034/$0035`; the table maps slot `n` to `$0300 + 12*n`. The match-zero
position initializer already derives every record's initial X/Y fields from
ROM formation tables and `$CDC9`, writing those values to offsets `+$06/+$08`.
The verified fresh route context is match 0, formations `$002C=$002E=0`, and
home possession `$05FB=0`.

Thus the coordinate transformation itself is complete for an explicitly
provided holder slot: the helper resolves the matching initial record and
returns its source-derived `+$06/+$08` values as `$0635/$0637`. It does not
choose the slot or update positions after movement.

## Diagnostic cross-check, not runtime input

The muted two-pass trace under
`reference/diagnostics/first_command_field_producer_input_trace_20261028_053644_utc/`
records the source path entering from `$E0F8` (the return address after the
`$E0F6` call). At source frames 8842 and 8855, the trace sees
`$0441=$06`, `$0034/$0035=$48/$03` (record `$0348`), and the coordinate reads
produce `$0635=$7C`, `$0637=$AC`. The later `$F0B5` entry at frame 8915 still
observes `$7C/$AC`. These trace values validate the byte interpretation only;
the resolver and verifier do not load the trace or endpoint RAM/PPU files.

The focused verifier
`tools/diagnostics/verify_first_command_holder_coordinate_resolver.gd`
checks both preserved instruction spans and the existing position-source
resource hashes, tests all 22 slot-to-record mappings from ROM logic, and
checks slot 6 as an explicitly supplied unit input. That unit case returning
`$7C/$AC` does not establish that production route logic selects slot 6.

## Remaining producer state

The missing value is the live `$0441` holder slot. Fixed-bank `$DAEF–$DB19`
computes it from `$00E2 & 7`, folds values 5–7 by subtracting 5, indexes ROM
table `$DC82 = 05 06 07 09 0A`, adds the home side, and stores the result to
`$0441`. The first-command trace's `$0441=$06` is one observed result. The
current RNG arithmetic helper does not produce the mode-gated `$A117/$C9C5`
call sequence, `$00E2` at the kickoff selection point, or `$C9C5` operands and
carry from the live scheduler. It is therefore not sufficient to select the
trace's slot as a runtime constant.

The resolver also uses initial formation coordinates. If the route changes the
selected record's coordinates before `$F0B5`, the movement/state writer must
be modeled and supplied instead. Separately, the `$05CD/$05CE` placement and
the event that reaches `$F0B5` remain caller-owned callback/task state. The
helper does not close any of those paths and is not wired into
`KickoffRouteRuntime` or the field presenter.

**Evidence boundary:** ROM bytes prove how an explicit `$0441` slot selects a
record and copies its initial coordinates to `$0635/$0637`. The muted trace
confirms one route instance. Live holder selection, post-initialization
movement, and callback invocation/state are not yet source-produced by Godot;
the `$F0B5` packet remains withheld from production presentation.

**Current update — 30 October 2026:** the later route now executes `$DAF5`
receiver selection and `$E6EC->$CDE2` from live source state after applying
the ROM-derived RNG replay for the recorded input hash. The frame-8593 route
resolves receiver slot 6 and passes the copied coordinates/tile index through
`$DB0E`. Arbitrary-input RNG, the callback/task state for `$F0B5`, and the
production field packet remain unresolved. See the route follow-up report at
`first_command_field/e6ec_holder_copy_live_route_20261030.md`.

## Route execution follow-up — 30 October 2026

`scripts/gameplay/rom_fresh_e6ec_holder_copy_executor.gd` now executes
hash-checked `$E6EC` and `$CDE2` bytes from the live slot-$05 boundary. The
`$E6EC` call to `$CDE2` is at `$E702`; it returns to `$E705`, and the holder
routine returns to `$DB0E`. The existing source-span decoder covers the ROM
`$CD7C` record-pointer lookup and `$CD89` table. For holder slot 8, the copied
record is `$0360`, coordinates are `$7C/$7C`, and `$CDE2` returns tile index
`$71`. The focused verifier passes from a constructed source boundary.

The recorded route validation reaches `$DB0E` but still fails RNG parity:
expected slot 6, current Godot slot 5. These holder values are therefore
verified for the supplied live Godot state, not the ROM's same-input route
endpoint. See `first_command_field/e6ec_holder_copy_live_route_20261030.md`.
