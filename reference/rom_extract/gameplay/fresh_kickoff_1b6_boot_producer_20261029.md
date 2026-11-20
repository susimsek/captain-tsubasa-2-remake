# Cold-start producer for NMI mode bit `$001B.6` — 2026-10-29

## Finding

The first verified `$001B.6` producer is the cold-start setup path, not an
unidentified title-route event. The reset routine enters fixed-bank `$CEFE`,
which jumps through `$C400->$A200->$A21B`; `$A21B` executes
`LDA $1B; ORA #$40; STA $1B`. A muted power-on write trace records the
corresponding `$001B` transition from `$00` to `$40` at post-write PC `$A22A`
on source frame 6. The `$001B` zero before it is also recorded during the
reset RAM-fill loop at `$C672`.

Thus the ROM does establish the mode bit during cold start before the title
and before the later KICK OFF route. The producer and its cold-start caller
are source-derived below. This does **not** yet prove that `$001B.6` remains
set at the later `$8114->$8920` wait: the retained KICK OFF trace begins at
frame 4693 and its hooks do not record `$001B` writes. Do not treat the
cold-start value as the live wait input until the intervening route writes
are source-executed or traced.

## Caller and write provenance

The reset-vector, reset-jump, early reset, `$C41E`, mapper-helper, and
`$A200-$A22A` spans are reused from existing hash-checked manifests. The new
non-overlapping byte spans are in
[`fresh_kickoff_1b6_boot_producer_20261029/manifest.json`](fresh_kickoff_1b6_boot_producer_20261029/manifest.json).

```text
$FFFC reset vector -> $C503 JMP $C64E
$C64E reset entry clears CPU RAM, including $001B=$00
  ... reset initialization and balanced helper calls ...
$C6B8 CLI
$C6B9 LDA #$00
$C6BB JMP $CEFE
$CEFE setup helper; PHA ... PLA; JMP $C400
$C400 TAY; mapper setup; LDX #$02; JSR $C4B9; TYA
$C41E JMP $A200
$A200 JMP $A21B
$A21B ... LDA $1B; ORA #$40; STA $1B ; write instruction at $A228
                                                ; post-write PC $A22A
```

At `$A21B` entry, A is `$00` from `$C6B9`, preserved through the balanced
push/pop in `$CEFE` and TAY/TYA in `$C400`. X is `$02` after the `$C418`
mapper-helper call, Y is `$00`, and fixed-bank `$C4B9` has selected physical
PRG bank `$02` at `$A000`. The reset RAM fill has set `$001B=$00`; the setter
preserves other bits and ORs in bit 6. The path uses JMP trampolines, not a
JSR return receipt; `$A21B` continues setup and does not return to `$C6BE`.

The existing muted boot trace provides a direct execution check:

| Source frame | Write | Post-write PC | Meaning |
| ---: | --- | --- | --- |
| 4 | `$001B <- $00` | `$C672` | Reset RAM-fill loop |
| 6 | `$001B <- $40` | `$A22A` | `$A21B` mode-bit setter |

The same two events are present in both retained power-on captures. Their
`writes.csv` files have SHA-256 values
`218f9c9df90a0e5d566a7aed449e46f573c89a1d1e27f77f564883c9da790ce2` and
`76d174e861f07df30e6abf695ba16fc1fbb3e9501c603c64c06b30881bb66032`;
metadata identifies the supplied ROM hash, power-on replay, frames 0–8, and
disabled audio. The trace is used only as independent
execution evidence; no screenshots, captured audio, or emulator state is
included in the source manifest.

## Godot source receipt

`scripts/gameplay/rom_fresh_kickoff_nmi_mode_producer.gd` now validates the
reset tail, `$CEFE->$C400` setup, `$C4B9` bank-$02 selection, `$C41E->$A200`
bridge, and `$A21B` setter against their source manifests and hashes. It
consumes the ROM reset-zero receipt for `$001B` and emits the ROM write at
`$A228` (`$001B=$40`, post-instruction PC `$A22A`). It also checks the
bank-$02 `$A133` OR-$80 writer and the fixed-bank `$9F0A` AND-$7F writer; both
preserve bits 0–6. The production route carries only known mask `$7F`, value
`$40`, into its sparse RAM ledger; bit 7 remains unknown.

The focused Godot verifier
[`verify_rom_fresh_kickoff_nmi_mode_producer.gd`](../../../tools/diagnostics/verify_rom_fresh_kickoff_nmi_mode_producer.gd)
passes its source-hash, reset-precondition, mode-writer invariant, partial-bit
ledger, and trace-rejection checks. The recorded-input route verifier also
passes and still stops at `$893B` on frame 7266: it knows `$001B & $7F=$40`,
while bit 7 and `$003B` remain unknown. The retained muted two-pass
FCEUX trace independently shows only the `$A135` and `$9F0C` `$001B` writers
in frames 4693–7409; trace state is not consumed by the runtime.

## Relation to the `$0078` wait

The prior [`$0078` wait audit](fresh_kickoff_0078_wait_20261029.md) shows that
the alternate NMI path can service the wait only when `$001B.6` is set and
`$003B.7` permits the service. The
[wait-input audit](fresh_kickoff_audio_wait_input_audit_20261029.md) listed
the setter caller as missing; this report resolves the cold-start caller. The
later `$C6E8` clear remains downstream of the wait on the mapped caller path.
The bit-level receipt plus the same-input writer census establish
`$001B & $7F=$40` at the `$893B` boundary, but not `$001B.7` or the live
`$003B` guard and interrupt context.

The next required transition is to produce the NMI/IRQ entry state and
`$003B` history from ROM-owned events, release the `$0078` wait, and execute
the `$895C->$8117` return. Do not infer those remaining inputs from the FCEUX
snapshot.

## Scope

This report uses the supplied ROM and existing muted trace records only. Its
Godot source receipt does not use emulator audio/screenshots or trace state as
a runtime input and does not claim a valid `$8920 RTS->$8117` return.
