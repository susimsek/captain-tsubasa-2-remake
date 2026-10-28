# First-command route: `$05CE` ROM cross-reference

Status: ROM-byte cross-reference plus muted two-pass route trace. The
bank-$10 byte reader now preserves and parses the scenario-$44 source record;
the live route still does not execute its continuation or callback workers.
See [`first_command_scenario_44_runtime_boundary_20261028.md`](first_command_scenario_44_runtime_boundary_20261028.md).

ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
PRG bank numbers below use the project's 16 KiB bank mapping. File offsets are
within the supplied iNES image.

## Direct absolute references

The ROM contains these direct absolute references to `$05CE`:

| Kind | Bank / CPU PC | File offset | Instruction/context |
|---|---|---:|---|
| write | `$0B:$8342` | `0x016352` | `STA $05CE`, in placement callback routine `$8327` |
| write | `$0B:$83A3` | `0x0163B3` | `STY $05CE`, callback/table path beginning at `$8377`; `$83A1` loads `Y=0` |
| write | `$0B:$8438` | `0x016448` | `STA $05CE`, preceded by `LDA #$40` |
| write | `$1A:$970F` | `0x03571F` | `STA $05CE`, clear path |
| read | `$18:$88EC` | `0x0308FC` | `LDA $05CE` |
| read | `$1F:$ECD8` | `0x03ECE8` | `LDA $05CE` |
| read | `$1F:$F049` | `0x03F059` | `LDA $05CE`, within `$F015` producer block |
| read | `$1F:$F054` | `0x03F064` | `LDA $05CE`, within `$F015` producer block |
| read | `$1F:$F0FB` | `0x03F10B` | `LDA $05CE`, within `$F0B5` producer block |
| read | `$1F:$F134` | `0x03F144` | `LDA $05CE`, within `$F0B5` producer block |

No direct absolute `$06CE` code references were found in this scan. This is an
instruction-operand cross-reference, not a complete proof against indirect
addressing or aliases.

## Confirmed code path and route evidence

Bank `$0B` callback dispatcher `$814C` selects callback records through `$87F6`.
The callback records at `$8A2A` (selector `$45`) and `$8B38` (selector `$70`)
have a zero handler-table index; handler-table entry zero points to `$8327`.
That routine reads its third record byte as the map ID and updates placement
state. Its relevant bytes decode as:

```text
$8327: LDY #$02
$8329: LDA ($52),Y
$832B: STA $05CC
$832E: LDY $05CD
$8331: JSR $8525
$8334: LDA #$01 / STA $05CB
$8339: LDA $05CD
$833C: BEQ $8342
$833E: AND #$20
$8340: ORA #$80
$8342: STA $05CE
$8345: ORA #$80
$8347: EOR #$20
$8349: STA $05CD
```

The muted two-pass trace at
[`first_command_field_producer_input_trace_20261028_053644_utc/`](../../diagnostics/first_command_field_producer_input_trace_20261028_053644_utc/README.md)
closes the route-specific writer question. It starts from an anonymous,
signature-checked in-memory state at source frame 8399, and logs `$05CD`,
`$05CE`, and `$063D` writers from cold start through frame 8953. Both replays
match after normalizing only the pass-label column.

The route's `$05CE` writes by the `$8327` handler are at source frames 8479,
8605, 8619, 8647, 8681, 8734, 8803, and 8905. The final write before `$F015`
is frame 8905, cycle offset 22035: trace PC-after `$8345` is the `$STA $05CE`
at `$8342`, bank `$0B`, storing `$A0`. At cycle offset 22043, the following
`$STA $05CD` at `$8349` (trace PC-after `$834C`) stores `$80`. No later `$05CE`
write occurs before either producer. This follows the bytes above: `$8327`
stores the placement derived from the previous `$05CD`, then toggles `$05CD`.
The other direct writers `$83A3`, `$8438`, and `$970F` do not execute on this
captured route interval.

## Minimal route integration point

The concrete source event is scenario `$44` at ROM file offset `0x0237E5`,
bytes `02 70 5C F0 FB`: two-tick delay, background event `$70`, actor
animation `$5C`, inline `$F0` parameter transform to `$FF`, then `$FB` return
through caller-owned continuation state. The same-input scheduler trace records the bank-$0B
`$814C` dispatch of `$44/$70/$5C` at frame 8893. Background record `$70` is
bank `$0B:$8B38` / file `0x016B48`, beginning `06 00 56 02 00`; its decoded
map opcode reaches the common `$8327` placement handler. The corrected input
trace records that handler's final `$05CE` write at frame 8905; the first
`$F015` packet iteration enters at frame 8908. The production integration
point is a ROM background-animation record executor: when it dispatches this
`$70` record's map opcode, call the source-byte-checked
`advance_map_placement_state(previous_05cd)` transition and pass its result to
the packet producer. The bank-$10 reader now exposes the `$70/$5C` record and
classifies its exact depth-zero root `$FB` as termination; the bounded parser
is not the live callback executor. Do not
substitute a frame-8905 event or a literal `$A0`; the callback/task interpreter
must supply the timing and previous `$05CD` state.

At frame 8908, bank `$1F` writes `$063D=$00` at `$EFFC` (trace PC-after
`$EFFF`), then `$063D=$02` at `$F009` (trace PC-after `$F00C`, cycle offset
23729). `$F015` enters at cycle offset 23741 with `$063D=$02`, `$05CE=$A0`,
`$05CD=$80`; its six calls span frames 8908–8913 with `A=$00…$05`. `$F0B5`
enters at frame 8915 with the same three values. The selector's inputs are
ROM-derived for the fresh B/menu route: `$0621=0` and `$0600=0`, as detailed in
[`first_command_field_descriptor_063d_source_audit_20261028.md`](first_command_field_descriptor_063d_source_audit_20261028.md).

This proves the source writer and input values for the packet routines. The
ROM-byte transition for `$8327` is now implemented in
`FirstCommandFieldPacketProducer.advance_map_placement_state()` and the narrow
Godot verifier checks all eight traced transitions on both replay passes.
However, `KickoffRouteRuntime` still needs to call that transition when the
decoded map-animation record dispatches opcode `$00`; it must also feed the
source-owned `$05CD` state into that call rather than supply `$A0` directly.
The descriptor selector helper separately evaluates fresh-route `$0621/$0600`
to obtain `$063D=$02`, but the route must pass those owned inputs through its
menu-entry state. `$F0B5` still needs the active record/holder selection that
produces `$0635/$0637=$7C/$AC` through the `$0034`-selected record path. Those
route integrations remain open. The earlier trace that watched `$06CE` was
incorrect and is superseded by the corrected trace above.
