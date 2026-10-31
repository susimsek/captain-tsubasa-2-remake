# Fresh KICK OFF next transition: `$80FD` through `$8920` — 31 Oct 2026

## Scope and ROM identity

This static audit follows the live route's new `$80FD` selector return through
the caller's roster-normalization call and identifies the next setup boundary
at `$8114->$8920`. It does not run FCEUX or alter production code.

- Supplied ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- The bank-$00 caller `$80DF-$815C` is packaged at file offset `0x0000EF` in
  [`fresh_kickoff_caller/manifest.json`](fresh_kickoff_caller/manifest.json).
  Thus `$80FD` is file offset `0x00010D`.
- Switchable bank `$02` maps `$A000-$BFFF`; `$A20C-$A20E` is at file
  offset `0x00421C` in
  [`fresh_kickoff_match_selector/manifest.json`](fresh_kickoff_match_selector/manifest.json).
- Fixed bank `$1E` maps `$C000-$DFFF`; `$C4B9-$C4C7` is at file offset
  `0x03C4C9`.

## Caller bytes and behavior

The source bytes at `$80FD-$811F` are:

```text
A9 00 85 28 85 29 85 27 A9 01 8D 00 07 A2 02
20 B9 C4 20 0C A2 A9 00 20 20 89 A2 01 20 B9 C4
20 06 A0 20 72 C5
```

Decoded control flow:

| Address | ROM operation | Effect / next boundary |
|---|---|---|
| `$80FD-$8104` | `LDA #$00; STA $28; STA $29; STA $27` | Clears match setup fields. |
| `$8105-$8109` | `LDA #$01; STA $0700` | Queues the source's audio-stop/control ID. |
| `$810A-$810E` | `LDX #$02; JSR $C4B9` | Selects MMC3 bank `$02`; returns at `$810F`. |
| `$810F-$8111` | `JSR $A20C` | Runs match normalization and returns at `$8112`. |
| `$8112-$8116` | `LDA #$00; JSR $8920` | Enters the preset-loader setup; its first nested wait is `$893B`. |
| `$8117-$811F` | `LDX #$01; JSR $C4B9; JSR $A006; JSR $C572` | Later setup stages after `$8920` returns. |

The fixed helper reads `$0022`, so `$810C` needs the current mapper shadow,
not just a guessed bank number. For the exact fresh route, the new source-state
builder derives `$0022=$00` from the ROM reset/initializer bytes. Its
same-input two-pass trace is validation only; it does not supply runtime RAM.
The existing bounded caller/selector route now executes through `$80FD` using
logical JSR frames. The `$810C` and `$810F` calls remain to be bound to those
live outputs.

## Reusable normalization component

[`rom_fresh_match_normalize_executor.gd`](../../../scripts/gameplay/rom_fresh_match_normalize_executor.gd)
packages the `$80FD-$8111` caller prefix, second `$C4B9` call, `$A20C`
trampoline/branch, and common `$A8A8-$A8B6` tail. Its logical-frame path reaches
`$8112`, derives `$002A=$00` and `$002B=$03`, and proves the `$A855` BCS branch
for all 256 `$E4` values because `$0026=0`. The live route supplies
ROM-derived `$0022=$00` / `$0023=$07`; it keeps absolute SP and stack-page bytes
unmodeled rather than adapting the older physical-stack fixture's
`$0022=$80` / `$0023=$87` values.

Relevant source spans and focused evidence:

- [`fresh_kickoff_match_selector_executor_20261028.md`](fresh_kickoff_match_selector_executor_20261028.md)
  documents `$80FA->$A20F->$80FD` and the fresh match-zero roster copy.
- [`fresh_kickoff_match_normalize_executor_20261028.md`](fresh_kickoff_match_normalize_executor_20261028.md)
  documents the bounded `$810C->$C4B9->$810F->$A20C->$8112` component and
  exhaustive `$E4` branch proof.
- [`fresh_kickoff_match_setup_prefix_20261028.md`](fresh_kickoff_match_setup_prefix_20261028.md)
  documents the following `$8112->$8920` preset-loader prefix through
  `$893B`.

## Next unresolved transition: `$8114->$8920`

The live muted replay reaches `$8114 JSR $8920` at source frame 7266. At the
caller, the observed A/X/Y/P/SP are `$00/$00/$84/$22/$28`; `$001B=$C0`,
`$0078=$04`, `$0079=$40`, `$003B=$55`. The callee entry SP is `$26`. `$8920`
multiplies the zero caller A value into `$EC/$ED`, derives preset pointer
`$BF00`, saves the current bank, selects bank `$06`, then polls `$78` at
`$893B`.

During that replay, an NMI retains `$78=$04`; the raster IRQ later clears it
to zero at `$A1C3 STA $78`. The loop exits, `$895C RTS` returns to `$8117`,
and the caller's SP is restored to `$28`. The exact route observation is in
[`fresh_kickoff_1b6_persistence_addendum_20261029.md`](fresh_kickoff_1b6_persistence_addendum_20261029.md).
This proves FCEUX behavior for the recorded route, not a production Godot
resume receipt. Runtime must source-execute the NMI/IRQ and `$78` transition;
do not inject the observed byte or use an elapsed-frame delay.

The remaining transition is the ROM-owned `$893B` NMI/raster-IRQ wait and
return. Then continue the caller at `$8117`: `$8119->$C4B9`, `$811C->$A006`, and
`$811F->$C572`. No physical NES interrupt timing is established by the cited
FCEUX cycle convention.

## Godot integration update — 31 Oct 2026

The live route now executes the logical-JSR caller and normalizer through
`$8112`, then runs the ROM-checked `$8112->$8920` prefix through its first wait
at `$893B`. The prefix derives `$EC/$ED=$00/$BF`, `$EA=$02`, and MMC3 bank `$06`
from the preceding source result. It stops before reading `$78`; no value is
copied from the FCEUX trace. The bounded prefix reports 232 no-interrupt cycles,
one pending logical outer call, and partial P mask `$C3`; absolute SP, PPU phase,
MMC3 A12/IRQ state, the wait, preset copy/restore, and `$895C RTS` remain
unmodeled. The focused prefix verifier and the recorded-input route integration
verifier pass. This is a software source-boundary check, not physical NES timing
or a visible field/menu result.

The logical selector, normalizer, and preset prefix now preserve any additional
processor-status bits that an upstream source contract explicitly marks known,
while recalculating the N/Z/C/V bits their instructions change. The prefix
verifier supplies a known I=0 fixture and confirms it remains known and clear at
`$893B`; its existing fixture confirms unknown I remains unknown. The live
selector route now receives only I=clear from a hash-bound ROM-only CPU
candidate contract, not from FCEUX. This does not prove that Godot executes the
cold-start `$C6B8 CLI` state through the title path. The CPU interrupt/RTI route
is still absent. The focused verifier passes.
