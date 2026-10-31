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

## Relation to the `$0078` wait

The prior [`$0078` wait audit](fresh_kickoff_0078_wait_20261029.md) shows that
the alternate NMI path can service the wait only when `$001B.6` is set and
`$003B.7` permits the service. The
[wait-input audit](fresh_kickoff_audio_wait_input_audit_20261029.md) listed
the setter caller as missing. This report resolves the cold-start producer
and caller, but the actual value at `$893B` is still unproven: the existing
KICK OFF trace does not have an `$001B` write hook over the intervening route,
and it does not source-execute that route through `$8114->$8920`. The later
`$C6E8` clear remains downstream of that wait on the mapped caller path; it
does not establish that no other earlier writer ran.

The next required transition is to carry `$001B` from the verified
cold-start setter through the title/cutscene caller to `$8114`, recording
every `$001B` write with its PC and the live `$78/$79/$3B` state at the wait.
Until then, the established fact is “cold-start sets bit 6,” not “the wait
receives bit 6 set.”

## Scope

This report uses the supplied ROM and existing muted trace records only. It
does not edit or add runtime behavior, does not use emulator audio/screenshots,
and does not claim a valid `$8920 RTS->$8117` return.
