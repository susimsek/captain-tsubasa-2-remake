# PASS Waiter Field Caller at `$E081`

The pinned ROM (`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`) maps the fixed-bank caller `$E081-$E0DE` to PRG bank `$1F`, file offset `$03E091`. Its 94-byte source span and hash are recorded in `manifest.json`.

The ROM bytes start with `LDA #$00; PHA; LDA #$01; JSR $CB0F`. The caller later branches through a counted loop and contains `$E0AB: JSR $8000`; that call is conditional on live flags/RAM and the selected MMC3 bank. The isolated executor performs local instructions and yields explicit contracts at JSRs. It does not run `$CB0F`, mapper helpers, the `$8000` handoff, or the target field worker.

The muted FCEUX 2.7.0 record in `../../../diagnostics/pass_receiver_waiter_boundaries_20261116_063055_utc/` reports `$E709` at frame 9086/cycle 270567918 with SP `$4C`; its validated RTS word `$E080` returns to `$E081`. At `$E709`, RAM `$062A=$0F`. It reports `$A103` at frame 9088/cycle 270618865 with A/X/Y/P=`$01/$00/$07/$20`, SP `$4A`, mapper `$1A/$1B/$1E/$1F`, and RAM `$062A=$8C`. This A103 state is consistent with a JSR through `$8000`, which would push SP `$4C` to `$4A`, but the trace has no direct PC hook at `$E081` or `$E0AB` and therefore does not prove that exact caller path.

The focused verifier passed using a trace-shaped entry and synthetic external-call returns. It changes `$062A` only in a fixture to exercise the negative-bit branch, then verifies local ROM instructions through the `$CE2D` call and `$E0AB` handoff contract. This does not prove that the live game took that branch. Route integration, observed `$E081/$E0AB` execution, helper-call results, hardware timing, and visible field output remain unresolved.
