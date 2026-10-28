# Fresh KICK OFF match normalization return — 28 Oct 2026

## Bounded source path

`RomFreshMatchNormalizeExecutor` consumes the explicit successful result of
`RomFreshMatchSelectorExecutor`, carries its CPU/RAM/stack state through the
next caller instructions, executes the second fixed-bank mapper helper, then
follows the `$A20C` normalization path through its real RTS. It does not
source a new caller event, read emulator data, or connect to
`KickoffRouteRuntime`.

The ROM revision is SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`. Exact
spans are checked against the source manifest and file bytes:

| Span | File offset | SHA-256 |
|---|---:|---|
| Caller `$80DF-$815C`, including `$80FD-$8111` and `$810F JSR $A20C` | `0x0000EF` | `a4b5afda1800eb4b500c95748497e22cb6467d90d1e99c56d4578b98db996a7b` |
| `$A20C-$A20E` trampoline | `0x00421C` | `fd63c4efff31a65f750b91006a64e730ba7c8bb4e2a3ca1ab612762808d7b433` |
| `$A855-$A86D` compare, branch, and alternate path | `0x004865` | `f43346f767ca9308764322a418899da490fca7537eb40096fcac8529a7c917e3` |
| `$A86E-$A8CD` containing the `$A8A8-$A8B6` common tail | `0x00487E` | `f9b27195e6d6c9163d55ee6161fbf8d4d795537df2f2347d3e4c406765033123` |
| Match-zero team byte `$AA75` | `0x004A85` | `6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d` |
| Fixed mapper helper `$C4B9-$C4C7` and its four caller JSRs | `0x03C4C9` | `a87676276fdbfa7feeb8e1279d6e9cb220b436dd1edb788813801b2be1c48f12` |

Source order after the previous `$80FA->$A20F->$80FD` return:

```text
$80FD LDA #$00 / STA $28 / STA $29 / STA $27
$8105 LDA #$01 / STA $0700 / LDX #$02
$810C JSR $C4B9 -> $810F
$810F JSR $A20C -> $8112
$A20C JMP $A855
$A855 LDA $E4 / CMP $26 / BCS $A8A8
$A8A8 LDX $26 / LDA $AA75,X / STA $2A
$A8AF LDA $26 / CLC / ADC #$03 / STA $2B
$A8B6 RTS -> $8112
```

## Why `$E4` does not need an invented value

The selector result supplies `$26=0`, and the intervening source instructions
do not write `$E4`. The exact `$E4` value is therefore not claimed or inferred.
For unsigned 6502 `CMP`, every byte is greater than or equal to zero, so with
`$26=0` the carry flag is set for all 256 possible `$E4` values and `$A859 BCS`
always takes `$A8A8`. The common tail overwrites A/X and the relevant flags,
reads ROM table byte `$AA75[0]=$00`, and writes `$2A=$00/$2B=$03`. An exhaustive
byte-domain verifier confirms identical return P=`$24` for all candidates.

The preceding `$810C->$C4B9` call reselects bank `$02`; its source helper emits
the MMC3 `$8000=$87` and `$8001=$02` writes. At the `$A20C` entry the bounded
continuation has A/X/Y/P=`$87/$02/$84/$A4`, `$26=0`, and the JSR stack word for
`$8111`. The `$A8B6 RTS` restores the caller SP and reaches `$8112` with
A/X/Y/P=`$03/$00/$84/$24`; the final stack retains the `$810F` return word.
The modeled caller writes `$28/$29/$27=0` and `$0700=1` before the call.

## Verification and limits

Run the focused Godot 4.7.2 verifier:

```sh
godot --headless --audio-driver Dummy --path . --script tools/diagnostics/verify_rom_fresh_match_normalize_executor.gd --quit-after 5
```

It composes the existing A20F executor, runs the caller byte sequence and
hash-checked `$C4B9` helper, proves branch/output invariance for all 256 `$E4`
values, and checks the `$A20C` stack return, registers, RAM writes, mapper
writes, and 94 no-interrupt cycles from `$80FD`. The verifier's source-event ID
is explicitly a fixture. This result proves the bounded synchronous source
slice, not that the production route supplies its initial A20F state or that
the NMI/task scheduler resumes at the corresponding source time.

The following `$8114 JSR $8920` is partially executed by
[`fresh_kickoff_match_setup_prefix_20261028.md`](fresh_kickoff_match_setup_prefix_20261028.md).
That prefix reaches `$893B LDA $78 / BNE $893B`; the missing source-owned
`$78` value/resume event prevents claiming the `$8920 RTS->$8117` return.
