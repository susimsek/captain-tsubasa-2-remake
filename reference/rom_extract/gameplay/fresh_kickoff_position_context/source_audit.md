# Fresh match-zero player-position inputs — ROM source audit

## Result and evidence boundary

The supplied Turkish ROM bytes derive the position initializer inputs for the
match-zero KICK OFF context as:

```text
$002C home formation       = $00
$002E away formation       = $00
$05FB possession side      = $00 (home/left)
```

This is a source-data result for decoded fresh-start route state
`match_index=0` and the ROM-produced kickoff selector `$0629=0`. The resolver in
`scripts/gameplay/rom_fresh_kickoff_position_context_resolver.gd` verifies the
preserved source spans and computes these values. It does not read emulator
RAM/PPU captures, infer state from an endpoint, or wire itself into the live
route/provider. The helper still accepts match index and selector as explicit
arguments; the new selector source audit proves how the route supplies zero.

ROM SHA-256:
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
The associated extracted source spans and their hashes are listed in
[`manifest.json`](manifest.json).

## Home formation `$002C`

Bank `$02`, file offset `0x00487E`, code `$A86E-$A8CD`, selects the home roster
using match index `$0026`. For `$26=0`, the selector takes `$A87C`, loads
`X=$00`, and calls the roster-copy path. The copy helper advances through the
eleven player IDs; after return, `$A8A3` reads the next byte from `$AA47,X` and
`$A8A6` stores that byte to `$002C`.

The match-zero home record at `$AA47`, file `0x004A57`, is:

```text
02 03 04 05 06 07 08 09 0A 01 0B 00
```

The first eleven bytes are roster IDs; byte 11 is the formation selector
`$00`. It is not a terminator. `$A8A8-$A8AD` reads team ID 0 from `$AA75` for
match zero. `$A8AF-$A8B4` computes opponent ID as `$26+3`, yielding 3.

## Away formation `$002E`

Bank `$1C`, file offset `0x038B49`, code `$8B39-$8B61`, computes the opponent
parameter index as `($002B-3)*2`, loads its pointer from bank `$1D` `$BAB2`,
then reads the pointed record's low nibble into `$002E` at `$8B4D-$8B51`.
With opponent ID 3, index 0 selects pointer `$BAF6` from bytes `F6 BA` at file
`0x03BAC2`. The source byte at `$BAF6`, file `0x03BB06`, is `$00`; its low
nibble is formation 0.

## Fresh kickoff side `$05FB`

The fixed-bank dispatcher reads `$0629` at `$DB24`, calls `$CB99`, and uses the
five-word target table beginning at `$DB2A`. Its selector-0 word is `$DB34`.
`$DB34` initializes X to 0, reads opponent `$002B`, and compares it with 3.
For opponent 3 the branch skips the random-side path and stores X=0 to `$044F`
and `$05FB` at `$DB5B-$DB60`. The branch therefore determines the left/home
side for this match-zero context without using a captured side value.

## Reset proof and live caller boundary

The fixed-bank reset vector at file `0x04000C` contains `F0 FF` and enters
`$FFF0`. The reset entry at `0x040000` jumps to `$C503`; `$C503` jumps to
`$C64E`. At `$C667-$C679`, `$C64E` points `$00/$01` at RAM zero, then writes
zero over eight pages `$0000-$07FF`. Thus `$0026` and `$0629` are both zero
immediately after cold reset.

The opening does reuse `$0628` and `$0629` as PPU queue cursor/request state
(see `../../intro/f9_task_timing_trace.md`,
`../../intro/cold_start_palette_nmi_commit_trace.md`, and
`../../intro/f8_00_sequence_trace.md`), so the cold-reset value alone is not
the proof for gameplay. A follow-up byte audit establishes the later
fresh-start transition: after cutscene ID 2, `$A203->$A2AF` calls the supplied
ROM's `$AA06` zero-fill routine. Its first pass writes 152 bytes and its next
two passes write 256 bytes each, clearing `$0468-$06FF`, including `$0629`;
the gameplay scheduler then runs `$D11E`,
which copies fresh period `$0027=0` into `$0629` at `$D14F` immediately before
`$D180->$DAAA->$DB24`. See
[`fresh_kickoff_0629_selector_source_audit_20261028.md`](../fresh_kickoff_0629_selector_source_audit_20261028.md).
Thus selector 0 is derived from the decoded fresh-start route and need not be
caller-owned or copied from endpoint RAM. The caller still supplies match
index from decoded new-game state; resolving that live value and wiring it
into the position provider remain separate work.

## Verification

Run the focused Godot check with:

```sh
godot --headless --path . --script tools/diagnostics/verify_fresh_kickoff_position_context_resolver.gd
```

It verifies preserved span hashes, resolves `(0,0,0)` when given the values
derived by the fresh-route source audits, and rejects unsupported matches,
selectors, and capture-derived contexts. It does not establish that the live
route currently passes those decoded values into the helper.
