# First-command `$FD` mirror transform: target-ROM correction

## Scope and ROM

This audit corrects the address/semantics assigned to scenario opcode `$FD 02`
in [`first_command_actor_palette_and_mirror_source_audit_20261027.md`](first_command_actor_palette_and_mirror_source_audit_20261027.md).
It checks the supplied Turkish ROM SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`; offsets
include the iNES header. Runtime recommendations below are source-derived;
FCEUX values are validation only.

## `$FD 02` is decoded

Bank `$10` at CPU `$885D` (file `0x02086D`) reads the operand following `$FD`,
passes it to `$886A`, then stores the returned X value into `$052A`:

```text
A4 3A E6 3A B1 5D 20 6A 88 8E 2A 05 60
```

At `$886A` (file `0x02087A`), `$C509` dispatches the operand through the inline
five-entry vector table at file `0x02087D`:

```text
77 88 | AA 88 | B5 88 | BF 88 | D9 88
```

Thus operand `02` selects CPU `$88B5` (file `0x0208C5`), whose complete
handler is:

```text
A2 00 AD FB 05 F0 02 A2 40 60
```

It returns X=`$00` when `$05FB` is zero and X=`$40` when `$05FB` is nonzero.
The previous audit's `$8895` target was a mistaken address; `$8895` lies inside
the separate `$8877` handler. `$FD 02` does not consume a player record or
register context beyond the `$05FB` byte.

The following `$F6` scenario opcode dispatches to `$87EC` (file `0x0207FC`):

```text
A9 40 4D 2A 05 8D 2A 05 60
```

It toggles bit `$40` in `$052A`. Therefore, for the fresh-start left-side
branch where kickoff setup has set `$05FB=0`, the source sequence `$FD 02; $F6`
computes `$052A: 0 → 0 → $40`. The `$05FB=0` premise is conditional on the
match-zero opponent ID `$002B=3`; the kickoff-side branch and its byte evidence
are documented in
[`fresh_start_to_first_command_menu.md`](fresh_start_to_first_command_menu.md).

## The first actor layer also has an earlier `$FD 00`

The first-command route's preceding scenario `$36` contains `$FD 00` at CPU
`$B7F3` / file `0x023803` (`FD 00 F9 ...`). Operand zero selects `$8877`, not
the `$05FB` handler. That handler reads the current ball-holder `$0441`, obtains
its player record through `$C50C`, and compares record fields with a value
derived from `$0638` through `$C536`; it returns a mirror flag in X. The route
trace records `$052A=$40` being committed at the `$885D` store (PC `$8869`) on
frame 8624, after scenario `$36` began at frame 8593. At frame 8640 the saved
RAM has scenario `$36`, cursor `$B7FC`, `$052A=$40`, and `$05FB=0`. This is
consistent with `$FD 00` and is distinct from the later `$FD 02` command.

The fixed-bank bridge at CPU `$ED0C` / file `0x03ED1C` contains
`AD 2A 05 8D 17 05`, copying `$052A` to the renderer's `$0517`. The same-input
trace records this copy as `$0517:0→$40` at frame 8656. Later `$052A` is
scenario-worker state and may return to zero while `$0517` stays `$40`; the
first-menu endpoint frame 8953 has `$0517=$40,$052A=$00`. Do not use endpoint
`$052A` as a substitute for `$0517`.

## Runtime status

- The `$FD 02` transform is fully byte-decoded and can be implemented from the
  live `$05FB` flag. It is not an unresolved player-context calculation.
- The first actor layer's initial `$0517=$40` is established earlier by the
  scenario `$36` `$FD 00` result and the `$ED0C` copy. A runtime route model
  must execute that handler from current `$0441`/player-record/`$0638` state,
  preserve `$0517` across later scenario-state changes, and follow the ROM
  bridge timing. The retained Godot actor presenter still accepts mirror mode
  as an input; this audit does not wire that state producer into production.
- Validation material: muted trace directory
  `reference/diagnostics/first_command_palette_mirror_20261027_163639_utc/`.
  Captured bytes confirm route timing/state but are not runtime data.
