# FC dispatch correction: opening path is not a counted block

## Corrected finding

The earlier counted-payload interpretation is withdrawn for the cold-start
entry-0 replay. It confused the address stored in the dispatch table with the
6502 address reached after the interpreter's `RTS` dispatch, and it then
attributed an adjacent byte sequence to the command handler.

The 24 October 2026 live replay records the first FC at script CPU `$A054`:

- Frame 479: interpreter PC `$84E7`, script pointer `$A054`, opcode `$FC`.
- Next hook: PC `$8837`, same pointer `$A054` (`fc_target`).
- At that sample MMC3 select is `$06`, R6 is `$00` (bank 0 in `$8000–$9FFF`),
  and R7 is `$03` (bank 3 in `$A000–$BFFF`). Thus the handler bytes are from
  the same bank-0 mapping as the dispatcher, while the script is in bank 3.
- The next recorded interpreter dispatch is at frame 483 with pointer `$A055`.

Trace source: `reference/diagnostics/audio_command_context_20261024_145219/dispatch_context.csv`;
run metadata is in the adjacent `metadata.txt`.

The interpreter uses an RTS-based vector. For `$FC`, its table word is the
RTS return address `$8836`; `RTS` increments that word, so execution starts at
`$8837`. In the active bank-0 mapping, `$8837` begins `20 9A 89` (`JSR $899A`),
not a call to `$9085`. The byte sequence `20 85 90 4C E7 84` is physically
present at `$8831`, five bytes before the reached PC; it is not this FC vector
handler. `$9085`'s counted loop may exist elsewhere in the ROM, but it has not
been shown to handle this cold-start FC.

The FC handler's source bytes at `$8837` are `20 9A 89 A9 04 20 A8 9F A5 51
18 69 40 85 51 A5 52 69 00 85 52 E6 4D D0 02 E6 4E 4C E3 84`. This establishes
these direct effects:

- `$899A` transforms RAM `$99` as `($99 & $80) | $40`.
- `$9FA8` is called with A=`$04`; its complete purpose is still being traced.
- `$51:$52` is incremented by `$0040`.
- The script pointer `$4D:$4E` increments by one before execution resumes at
  `$84E3`.

The next interpreter dispatch is at pointer `$A055`; the following byte `$4F`
is dispatched as a normal text byte. The same one-byte progression is observed
at the next FC, `$A069` to `$A06A`. Do not parse the following bytes as FC
payload. The state update's complete visual meaning and `$9FA8` effects remain
unresolved. The source-addressed first-pass handler table is in
`cold_start_vector_handler_semantics.md`.

## PPU writes retained as independent observations

The cycle-stamped capture still records, on frames 837–845, pairs of `$2007`
writes at `$2249–$2251` and `$2269–$2271`. `$2000=$84` means PPUDATA increments
by 32 after each write. End-of-frame RAM pointer samples are later than those
bus writes and show the pointer one byte past the corresponding sampled text
source byte. These address facts remain valid, but the old claim that the
source bytes are an FC payload is false. The trace is not proof of final
rendered coordinates or raster visibility. See
`fc_first_payload_ppu_trace.md` for the corrected scope.

## Consequences for extraction

The prior FC-aware scan, its claimed `$A020–$A6DB` reachable boundary, and its
62-event stream depend on treating FC as a counted block. They are therefore
not verified execution evidence and must not drive runtime behavior or source
boundaries. The 641-byte pointer span remains a lexical ROM extraction only;
its status as a complete execution stream is also unproven. A new handler-aware
parse requires the traced `$8837` behavior and any later bank/context changes.
