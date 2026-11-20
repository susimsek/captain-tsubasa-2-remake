# Fresh Kickoff A4EB Prefix

## Result

The production recorded-input route now applies the source-supported opening
of `$A4EB` and stops before its `$A500 JSR $B0C0` stream. The prefix stores the
source pointer pair, sets the pointer-enable bit, and runs the direct `$9B7F`
OAM/motion-record clear. The outer `$811F` return frame remains pending.

## ROM evidence

- ROM: `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`.
- SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- Bank `$01` body: CPU `$A4EB-$A610`, file offset `0x0024FB`, length 294,
  SHA-256 `1897387554b3047615392719f5a00c32f4ceb24e56645c64fe7d8a11a3ed3587`.
- Bank `$00` helper `$9B6F-$9B73`: file offset `0x001B7F`, five bytes,
  SHA-256 `23095e4aa356a47eac7312411861abb877a4ac6a0176553590cccbac1ba21701`.
- Bank `$00` helper `$9B74-$9B7E`: file offset `0x001B84`, eleven bytes,
  SHA-256 `0385f9c6291457e0b0bdf7dab7362e788fc2d270185fd3650f155feb1f129a5d`.
- The direct `$9B7F-$9B9F` helper reuses its existing checked 33-byte span in
  `cutscene_cleanup_helpers/manifest.json`; the new call path applies its RAM
  effects without the separate `$98A0` PPU clear.

`$A4EB` loads `$6A/$6B`, calls `$9B6F` to store `$009E/$009F`, loads `$7A/$7B`,
and calls `$9B74` to store `$00A0/$00A1` and set bit 7 in `$009E`. The next
call to `$9B7F` writes `$F8` across `$0468-$0567` and `$0200-$02FF`, then clears
`$0568/$0588/$05A8/$05C8`. `$A4FC/$A4FE` leave Y=`$05`, X=`$B3`, and the route
stops before calling `$B0C0` at `$A500`.

## Production verification

Command:

```text
CT2_ROUTE_FINAL_FRAME=7300 godot --headless --path . --script tools/diagnostics/verify_kickoff_recorded_input_path.gd
```

Godot 4.7.2 passes the recorded-input route verifier and stops at frame 7266,
PC `$A500`. It checks the returned A/X/Y values, the known N/Z flag bits,
521 explicit RAM writes, and the still-pending `$B0C0` call. This verifies the
new boundary only; it does not reach the field or first command menu.

## Same-input trace comparison and limits

The muted two-pass FCEUX trace
`diagnostics/kickoff_select_cleanup_counters_20261101_093929_utc/caller_hooks.csv`
records `$A4EB` at frame 7266/cycle `216372926` with A/X/Y/P=`$07/$01/$13/$20`,
then `$A500` at frame 7266/cycle `216378140` with A/X/Y/P=`$00/$B3/$05/$A0`.
The route model agrees on A/X/Y and the observed N/Z bits. The trace-hook cycle
delta is 5214 while the bounded instruction sum is 5210; this four-cycle gap
remains open and is not treated as physical NES timing evidence.

`$B0C0` and its `$B305-$B327` command stream, the rest of `$A4EB`, the
`$811F->$C572` return, later field/menu setup, route audio parity, and a clean
ROM/emulator-free package are still unverified. Fourteen earlier interrupt
effects and physical PPU/MMC3 subframe timing also remain unresolved.
