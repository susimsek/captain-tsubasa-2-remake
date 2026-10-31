# `$E6EC` holder copy in the live route

## Source and implementation

The supplied Turkish ROM is identified by SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
The fixed-bank `$DAF5` receiver caller reads `$00E2`, indexes `$DC82`, writes
the receiver slot to `$05FC`, and calls `$E6EC`. Godot now executes that
receiver path from the slot-$05 task boundary, then passes the returned live
boundary to `scripts/gameplay/rom_fresh_e6ec_holder_copy_executor.gd`.

The executor verifies and interprets ROM bytes for `$E6EC`, `$CD7C`, `$CD89`,
and `$CDE2`. It copies the selected holder's record coordinates from offsets
`+$06/+8` to `$0635/$0637`, executes the small tile-index helper, and returns
through the caller's stack frame. The `$CDE2` callsite inside `$E6EC` is
`$E702`; its return PC is `$E705`. The routine returns to `$DB0E`, before the
scenario-`$36` caller begins.

## Focused verification

`tools/diagnostics/verify_rom_fresh_e6ec_holder_copy_executor.gd` passes from
a constructed live-source boundary. For holder slot 8, it checks record
pointer `$0360`, coordinates `$7C/$7C`, tile index `$71`, return PC `$DB0E`,
and the expected stack pointer. This proves the bounded helper behavior for
that input boundary.

The recorded-route verifier reaches `$DB0E` after its frame-8593 A press, then
executes the scenario-$36 caller through `$CB0F` and the scheduler's slot-$09
selection. The route boundary is documented in
[`scenario36_queue_live_route_20261030.md`](../scenario36_queue_live_route_20261030.md).
It confirms the 22 initial player positions against the same-input FCEUX RAM
oracle. The route now consumes the source-derived, input-hash-bound RNG replay;
the frame-8593 state selects slot 6 in both routes. This does not generalize
RNG behavior to different input histories.

No screenshot, WAV, or captured RAM is used as a runtime asset or an input to
the holder executor. Source bytes and hashes are maintained under
`reference/rom_extract/gameplay/first_command_field/holder_coordinates/`.

## Remaining boundary

The route stops before dispatching the selected slot `$09` scenario consumer.
It has not produced the first command menu. The route remains software-frame-
driven; this work does not establish instruction-cycle, PPU-dot, or physical
NES timing equivalence.
