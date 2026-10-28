# FC opcode audit for KICK OFF cutscenes 1 and 2

## Result

`$FC` is a one-byte cutscene command in the supplied Turkish ROM's shared
interpreter. It does **not** take a following byte as a payload length. The
`tools/extract_kickoff_cutscenes.py` and
`tools/gameplay/build_kickoff_cutscene_events.py` outputs that skip a counted
`$FC` payload are therefore not valid execution parses and must not be used to
drive Godot. The raw ROM pointer-span binaries remain valid byte-preserving
exports.

This correction is strongly supported by the dispatcher vector, local handler
bytes, a direct live PC/pointer trace for entry 0, and sampled script-pointer
states on the KICK OFF route. The route capture does not hook the `$8837` PC
inside IDs 1 and 2, so it is not a per-dispatch instruction trace for those
two entries.

## ROM identity and handler mapping

- Supplied ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- The bank-0 command-vector table starts at CPU `$8545`, file `0x000555`.
- `$FC`'s table word is `$8836` at CPU `$856D`, file `0x00057D`; dispatch is
  RTS-based, so execution enters at `$8837` (file `0x000847`).
- Local ROM bytes at `$8837` are:

  ```text
  20 9A 89 A9 04 20 A8 9F A5 51 18 69 40 85 51
  A5 52 69 00 85 52 E6 4D D0 02 E6 4E 4C E3 84
  ```

The handler calls `$899A`, yields with `$9FA8(A=$04)`, adds `$0040` to
`$51:$52`, increments the script pointer `$4D:$4E` by exactly one, and resumes
at `$84E3`. It never reads a length operand after `$FC`. The live entry-0
trace confirms the behavior: at source frame 479, `$84E7` dispatches `$FC` at
`$A054`; the next hook reaches `$8837` with the same pointer; the next
interpreter dispatch has pointer `$A055`. During that direct trace, MMC3 select
is `$06`, R6 is `$00`, and R7 is `$03`, so the handler is executing in the
bank-0 `$8000–$9FFF` window while the script is read from `$A000–$BFFF`.
Source: `../intro/fc_counted_block_trace.md` and its referenced
`reference/diagnostics/audio_command_context_20261024_145219/dispatch_context.csv`.

## KICK OFF route corroboration

The muted route observation at
`reference/diagnostics/kickoff_select_test_20261027/state_index.csv` stores
end-of-frame `$4D/$4E` plus the raw MMC3 register values. It contains these
script-pointer transitions:

| Entry | `$FC` address → next pointer | Sampled frame | Evidence |
|---|---|---:|---|
| ID 1 | `$A2BA → $A2BB` | 5008 | RAM `$4D/$4E`; raw R6=`$00`, R7=`$02` |
| ID 1 | `$A2C4 → $A2C5` | 5083 | RAM `$4D/$4E`; raw R6=`$00`, R7=`$02` |
| ID 1 | `$A2D5 → $A2D6` | 5218 | RAM `$4D/$4E`; raw R6=`$00`, R7=`$02` |
| ID 1 | `$A30B → $A30C` | 5878 | RAM `$4D/$4E`; raw R6=`$00`, R7=`$02` |
| ID 2 | `$A64B → $A64C` | 8338 | RAM `$4D/$4E`; raw R6=`$00`, R7=`$02` |

These sampled states align with one-byte `$FC` advancement and the shared
bank-0 handler. They are frame-edge snapshots, not direct `$8837` PC hooks;
the route capture's bank register values are preserved as raw mapper state and
are not relabelled as logical bank numbers here.

## Correct linear parses for entries 1 and 2

Using the locally verified command widths (including `$FC`=1, `$FB`=`2+count`,
`$F0`=3, and `$F3 $FF`=4), both streams reach `$FF` exactly at their next
pointer-table boundary:

| Entry | Start | Terminal `$FF` | Bytes | Events | Important command counts |
|---|---:|---:|---:|---:|---|
| ID 1 | `$A2A1` | `$A625` | 901 | 222 | 42 `$FC`, 12 `$EB`, 15 `$FB`, 9 background changes (`$F9/$FA`), 8 `$ED` |
| ID 2 | `$A626` | `$A6B3` | 142 | 45 | 6 `$FC`, 1 `$EB`, 2 `$FB`, 2 `$F9`, 3 `$ED` |

Verified data at the start of ID 1 is `E8 01 F9 5C FB 01 6D DD E9 ED 55`;
ID 2 starts `E8 01 F9 02 FB 01 15 DE E9 ED 53`. Compact waits use the ROM
table at bank-0 CPU `$88E6` / file `0x000AF6`: `D8..DF` request
`1,10,20,40,60,80,120,240` cooperative scheduler ticks respectively. These
are scheduler delays, not independently verified absolute video-frame or
pixel times for entries 1 and 2.

The current route observations show `$FC` pointers advancing as above, but do
not provide a cycle-stamped command trace for every byte. The full `$EB`
input-wait cadence, animation descriptor/frame execution, PPU packet producers,
and per-command audio onset still require route-specific tracing. `$ED` writes
an ID to the sound-command queue; it does not itself write APU registers.

## Required extraction correction

1. Change the KICK OFF event builder's `$FC` width to one byte and parse the
   following glyph bytes as ordinary `00..D7` text tiles until the next
   control value.
2. Regenerate the event manifests from the pointer spans. For the current ROM
   and verified opcode widths, ID 1 is 222 records through `$A625`; ID 2 is 45
   records through `$A6B3`.
3. Do not preserve the erroneous counted-payload execution streams as
   authoritative data. If retained for history, label them as withdrawn parse
   candidates and keep them out of Godot's runtime resource tree.
4. Before claiming exact route timing, add a muted trace hooking `$84E7`,
   `$8837`, `$4D/$4E` writes, and mapper state through entries 1 and 2.
