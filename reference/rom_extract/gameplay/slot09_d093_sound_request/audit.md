# Slot-$09 `$D093` sound lookup audit

## Finding

The live route's `$CBF1` sound mismatch came from the `$D093` caller emulation,
not from the queue helper. The production `$D093` model had inverted the
`$D09D BEQ` outcome: when `$05FB` was zero, it incorrectly executed `LDX #$01`.
The ROM branches over that instruction, keeps X at zero, and selects `$002A`.

With the route's source-derived state `$063E=$00`, `$05FB=$00`, `$002A=$00`,
and `$002B=$03`, the correct path reads `$002A=$00`, then `$D0AC[0]=$3C`.
The corrected executor preserves `$002B=$03` as the away-team ID. It does not
rewrite route RAM or inject a sound ID.

## ROM evidence

The checked ROM is `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
The code span is fixed bank `$1E`, CPU `$D093-$D0AB`, file offset `0x03D0A3`,
SHA-256 `f40f3cd4e1dd98e081463a5b9e9e3651e65533b495f2b437a9fee4e2cbf311d8`.
The source bytes around the selection are:

```text
$D09A AE FB 05    LDX $05FB
$D09D F0 02       BEQ $D0A1
$D09F A2 01       LDX #$01
$D0A1 BD 2A 00    LDA $002A,X
$D0A4 AA          TAX
$D0A5 BD AC D0    LDA $D0AC,X
$D0A8 20 F1 CB    JSR $CBF1
```

Thus selector zero skips `$D09F`, while a nonzero selector executes it. The
hash-checked lookup table begins at `$D0AC`; its first byte is `$3C`, and its
fourth byte is `$35`.

The retained muted FCEUX trace independently records `$CBF1` entry A=`$3C` at
source frame 8607 and `$CC01` after the helper's store with `$0700=$3C`:
[`slot09_source_trace.csv`](../../../diagnostics/kickoff_select_cleanup_counters_20261109_050830_utc/slot09_source_trace.csv),
rows 1326–1328. The source-stepper audio table also lists `$3C` for that
frame in [`first_match_audio_source.md`](../first_match_audio_source.md).

The `$CBF1` helper itself is source-faithful: `$CBF1-$CBFC` scans queue slots,
`$CBFE` stores A to the first zero slot, and `$CC01` returns. The live Godot
route's earlier `$35` therefore exposed the caller's wrong X selection.

## Verification boundary

`tools/diagnostics/verify_rom_slot09_ebd7_root_zero_counter_executor.gd`
checks a branch-coverage copy based on live source-route RAM. It sets the root
counter and `$052F` branch selector, then supplies the ROM-established
match-zero away-team ID `$002B=03` while retaining `$002A=00`. It asserts the
ordered reads `$063E=0`, `$05FB=0`, `$002A=0`, the `$3C` table result, and the
unchanged `$CBF1` request and queue store. The scheduler's expected instruction
path likewise includes `$D09F` only for a nonzero `$05FB` selector. This
verifies the bounded executor path; it does not claim audible APU output or
hardware timing.

The recorded-input Godot route replay was also rerun with the corrected
executor. It now emits `$3C` at route frame 8607, matching the ROM-source queue
event. The overall audio-event comparison remains `MISMATCH` (7/10 matched)
for other existing events: `$55` starts at 4815 instead of 4816, its stop is at
8073 instead of 8108, and `$53` starts at 8221 instead of 8271. The replay
command was `godot --headless --path . --script
tools/diagnostics/audit_kickoff_route_audio_event_parity.gd`; its nonzero exit
reflects those three remaining event differences. It loaded no captured WAV or
PCM and did not use FCEUX.

Queue occupancy still differs at this event: the Godot provenance event is
`cbf1:D0A8:CBFE:8607:1:3C`, so the modeled helper writes `$0701` after a
pending `$0700=$01`. The retained FCEUX trace shows all five queue slots empty
at `$CBF1`, then `$0700=$3C` at `$CC01`. Thus this fix closes the sound-ID
lookup mismatch; it does not close source queue-consumption parity.
