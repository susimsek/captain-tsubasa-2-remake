# First-command field packet producer: `$F015/$F114`

## Scope and ROM identity

This note documents a source-byte decoder for the residual field packets that
the first-command screen writes through the `$04A5` queue. The decoder reads
preserved ROM-derived resources; it does not read the `.nes` file, emulator
captures, or the diagnostic packet trace at runtime.

- Supplied ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- Preserved code, tables, route prefix, and hashes:
  [`packet_producer/manifest.json`](first_command_field/packet_producer/manifest.json).
- Decoder: `scripts/gameplay/first_command_field_packet_producer.gd`.
- Focused verifier: `tools/diagnostics/verify_first_command_field_packet_producer.gd`.

## ROM routine and packet format

Bank `$1F` routine `$F015` uses the descriptor in `$063D`. It loops input `A`
from 0 through 5, reads the six column offsets at `$F10E`, the descriptor
address row at `$F15A`, six initial tile IDs from `$F16A`, and a little-endian
stream pointer from `$F182`. The stream bytes begin at `$F18E`. `$F114` copies
each length/delta/payload record into the `$04A5` transfer buffer and ends the
batch at a zero length byte. The runtime decoder implements this packet
construction from the preserved bytes and exposes both source state values as
required caller inputs:

- `descriptor_id` is the live `$063D` value.
- `placement_05ce` is the live `$05CE` value read by the producer.

The instruction operands are `AD CE 05`, so these routines read `$05CE`, not
`$06CE`. The earlier two-pass producer-input trace watched the wrong address;
its `$06CE` column is not evidence for the value consumed here.

For descriptor `$02`, the six source streams yield 60 tile payload bytes and
six attribute writes. The tile payload addresses cover the same 10-by-6 PPU
rectangle isolated by the map comparison. `$F015` supplies the base field
fragment; the separate bank-`$1F` `$F0B5` routine writes tile `$A2` over one
cell after calculating its address from `$0635/$0637`, descriptor `$063D`,
and `$05CE`.

## Placement and route-state boundary

The packet builder does not assign `$05CE`. A muted two-pass source trace now
establishes the actual placement writer and producer-entry values for this
fresh-start route. Bank `$0B` `$8327` stores the prior `$05CD`-derived
placement at `$8342`, then toggles `$05CD` at `$8349`. The producer class now
ports this placement-state portion in `advance_map_placement_state()` after
checking the preserved writer bytes. The caller must still invoke it only when
the decoded ROM callback dispatches this handler; it does not synthesize a
callback schedule. The traced callback
sequence writes `$05CE` at frames 8479, 8605, 8619, 8647, 8681, 8734, 8803,
and 8905. Its final write before the packet routines is frame 8905, cycle
offset 22035: bank `$0B:$8342` (the write hook reports post-instruction PC
`$8345`) stores `$A0`; the following `$05CD` write sets `$80`. The source
routine, not an endpoint capture or runtime constant, explains the input.
No later `$05CE` writer occurs before `$F015` or `$F0B5` in this trace. Other
ROM references show possible global writers:

- Bank `$0B` `$8327` writes `$05CE` at `$8342` from prior `$05CD` state, then
  changes `$05CD` at `$8349`.
- Bank `$0B` `$83A3` stores `Y` to `$05CE`.
- Bank `$0B` `$8438` stores immediate `$40`.
- Bank `$1A` `$970F` stores immediate `$00`.

The corrected source trace and ROM cross-reference are in
[`first_command_field_05ce_source_xref_20261028.md`](first_command_field_05ce_source_xref_20261028.md).
It also confirms `$063D=$02`: bank `$1F` writes zero at `$EFFC`, then writes
`$02` at `$F009` in frame 8908. The fresh B/menu route sets `$0621=0` and
`$0600=0`; the selector's ROM formula therefore yields `$02`. Details and the
distinction from the UI window descriptor `$02` are in
[`first_command_field_descriptor_063d_source_audit_20261028.md`](first_command_field_descriptor_063d_source_audit_20261028.md).

The `$F0B5` coordinate formula is implemented separately and accepts source
coordinates explicitly. The trace confirms `$0635/$0637=$7C/$AC` at `$F0B5`;
the latest writes come through `$E6F2/$E6FA` from a dynamic record selected by
`$0034/$0035`. This still does not establish which active-player record and
caller state the Godot route must reproduce. See the `$CD7C`/`$DC29` source audit in
[`first_command_field_live_source_summary_20261027.md`](first_command_field_live_source_summary_20261027.md)
and the route-state limits in
[`first_command_live_player_opponent_state_audit_20261027.md`](first_command_live_player_opponent_state_audit_20261027.md).

## Runtime integration and verification

`FirstMatchFieldCandidatePresenter` now accepts source state at the callback
boundary: `$0621`, `$0600`, previous `$05CD`, and the caller's current callback
PC. It verifies that scenario `$44` resolves to `$8327`, derives `$063D` with
`RomFirstCommandFieldDescriptorResolver`, computes the `$8327` placement write
from the preserved instruction bytes, and applies all six `$F015/$F114`
batches to the ROM-built field candidate. It rejects pre-resolved
`descriptor_id`/`placement_05ce` constants and does not read endpoint RAM/PPU
files. If source state is absent, it keeps the field candidate and reports
that the residual packet layer was not applied. The production route still
does not supply a live decoded `$8327` callback state, so this is a connected
ROM-data path, not yet a live route integration.

The later `$F0B5` holder tile is applied only when the caller also supplies
source-derived `$0635/$0637` coordinates. The live actor state needed to derive
those values is still missing; no endpoint RAM/PPU values are used by the
runtime.

The narrow Godot verifier passed on Godot 4.7.2:

- The source-byte `$8327` transition matches all eight traced `$05CE/$05CD`
  callback updates on each of the two replay passes.
- All six generated `$F015` batches match the muted FCEUX buffer prefixes at
  frames 8909–8914 byte-for-byte.
- Applying the base batches matches 59/60 cells in the endpoint PPU rectangle;
  the sole difference is `$2AE6`, which is the later `$F0B5` holder write.
- All six `$F015` attribute bytes match the endpoint PPU bytes.
- With trace-only coordinates as verifier inputs, the `$F0B5` formula produces
  PPU address `$2AE6` and tile `$A2`, matching the endpoint oracle.
- `verify_first_command_field_source_context.gd` separately exercises the
  field presenter with source logic only: it derives `$063D=$02` from fresh
  `$0621/$0600`, advances the ROM `$8327` formula seven times from cleared
  `$05CD`, then derives the eighth callback's `$05CE=$A0` and applies 60 tile
  plus six attribute writes. It supplies no capture bytes to the presenter;
  the separate `$F0B5` write remains withheld until live holder coordinates
  exist. It also checks that an empty context or pre-resolved constants do not
  activate the packet layer.

Validation references only:

- Muted two-pass trace: `reference/diagnostics/first_command_field_producer_input_trace_20261028_053644_utc/`.
- Endpoint PPU oracle: `reference/diagnostics/kickoff_select_test_20261027/ppu/route_frame_008953.bin`.
- Re-run: `godot --headless --path . --script res://tools/diagnostics/verify_first_command_field_packet_producer.gd`.
- Source-only presenter path: `godot --headless --path . --script res://tools/diagnostics/verify_first_command_field_source_context.gd`.

The packet producer verifier checks the decoder against ROM-produced packet
buffers and endpoint bytes. The source-context verifier checks the actual
presenter path from ROM logic without passing captures to runtime code. The
diagnostic route trace establishes the concrete producer inputs for one replay,
but `KickoffRouteRuntime` does not yet produce the callback event or source
state and therefore still renders the field candidate without the packet layer.
The active record/holder coordinates for `$F0B5` are also not yet derived in the
route. Do not count either helper-level verification as same-input visual
parity for the first command screen.
