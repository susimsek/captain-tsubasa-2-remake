# Fresh-start `$E3CA` no-direction input path — 28 Oct 2026

## ROM path

The supplied Turkish ROM has SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
Fixed-bank CPU `$E3CA` maps to file offset `0x03E3DA`. Its entry bytes are:

```text
$E3CA: AD FB 05       LDA $05FB
$E3CD: D0 07          BNE $E3D6
$E3CF: AD 1C 00       LDA $001C
$E3D2: 29 0F          AND #$0F
$E3D4: F0 30          BEQ $E406
...
$E406: 60             RTS
```

On the fresh match path (`$05FB=0`), this routine checks the low nibble of
`$001C`. If it is zero, it returns before the directional-movement arithmetic
and before the `$CE08` player-stat call. This is a source-byte branch, not a
frame-delay assumption.

## Same-input trace

`tools/diagnostics/run_first_command_e3ca_input_trace.py` replays the existing
opening and KICK OFF input files in muted FCEUX 2.7.0 / NTSC NewPPU. Within that
single emulator session it creates a signature-checked anonymous in-memory
checkpoint at source frame 8399, reuses it for two passes, and records only the
requested bounded trace outputs; it does not occupy numbered save slots or
produce screenshot/WAV runtime data. Inputs and ROM are hash-checked by the
runner. The trace is in
[`reference/diagnostics/first_command_e3ca_input_20261028_131759_utc/`](../../diagnostics/first_command_e3ca_input_20261028_131759_utc/).

Both passes record 493 `$E3CA` entries and 493 `$E406` returns per pass, one
entry/return per source frame from 8461 through 8953. Across those calls,
`$001C` is `$00`, `$20`, `$40`, or `$80`; every value satisfies
`$001C & $0F == 0`. The tested B press at frame 8893 has `$001C=$40`, so it also
takes the no-direction branch. At each return, A is zero and `$0642/$0643`
remain `$00/$00`. No write in the trace has a PC-after-write inside
`$E3CA–$E406`. The two normalized event/write replays match.

This closes only the no-direction branch for this recorded input route. It
does not implement directional movement, the alternate `$05FB` branch, the
field loop or task scheduler, or the later `$E349` B-to-command-menu path.
It establishes that a movement simulator is not needed to explain
`$E3CA`'s coordinate effect on the measured no-direction segment; it does not
make the live Godot route source-complete.
