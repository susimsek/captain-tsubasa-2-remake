> **Evidence correction (24 Oct 2026):** The FC-counted interpretation used by the existing VM data is withdrawn for the cold-start replay. Live dispatch reaches bank-0 `$8837` for FC and returns at the next script byte; the table word `$8836` is an RTS return address (RTS adds one). The generated 62-event stream and its `$A6DB` boundary are not verified execution evidence. Do not use them to drive runtime behavior until the parser is rebuilt from corrected handler traces. See `reference/rom_extract/intro/fc_counted_block_trace.md`.

# Opening cutscene command VM

`scripts/opening/rom_cutscene_vm.gd` is an isolated command-state prototype.
It is not connected to the main scene. Its old VM JSON remains preserved as
withdrawn parser output. The new evidence file
`reference/rom_extract/intro/cold_start_observed_dispatch.json` contains the
live cold-start dispatches recorded by FCEUX, including the partial loop replay
and the title transition handoff. It is a bounded observation, not yet a
complete semantic VM specification.

`scripts/opening/rom_dispatch_trace_vm.gd` is the matching research stepper. It
advances one observed dispatch row at a time and reports unsupported effects;
it does not schedule frames or drive visuals. The legacy visual prototype now
refuses its withdrawn VM JSON when loaded from project data.

## Source and validation status

- Supplied ROM SHA-256:
  `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- The bank-3 table at CPU `$A000` points entry 0 to `$A020` and entry 1 to
  `$A2A1`. These are valid entry points; they do not establish execution
  boundaries between entries.
- The 641-byte pointer-span extract and 1,724-byte former expansion remain
  retained as byte-exact historical artifacts. Their hashes establish byte
  identity only. The expanded parse used a withdrawn FC count assumption.
- The generated `assets/opening/rom_logic/cutscene_00_vm.json` keeps the old
  events for comparison and is explicitly marked withdrawn. Do not use those
  events as authoritative playback data.
- The verified live stream has 585 dispatch rows: 551 in the first pass from
  `$A020` through the dispatched `$FE` at `$A29E`, followed by a jump back to
  `$A020`, then 34 replay dispatches through `$A050`. The trace ends when the
  outer Start/title path changes the shared pointer to `$00E8`.

## Confirmed interpreter observations

The bank-0 text loop at `$84E7` handles ordinary `$00–$D7` bytes through the
glyph upload helper `$88CA`; when `$55` is nonzero it also calls delay/update
helper `$895D`. The F2 handler at `$8677` stores its following value in `$55`.
Captured pointer intervals agree with one script byte per frame at speed 1 and
one byte per five frames at speed 5. These observations are documented in
`reference/rom_extract/intro/dialogue_timing_observations.json`; the exact
raster-visible edge can differ by a frame from end-of-frame RAM snapshots.

The live trace separates four classes: `$00–$D7` text tile bytes, `$D8–$DF`
inline waits, `$E0–$E7` inline cursor-back operations, and `$E8–$FF` vector
commands. The compact-pause table at CPU `$8AE6` maps `$D8–$DF` to
`1, 10, 20, 40, 60, 80, 120, 240`; the trace observed 20 such waits and one
cursor-back opcode (`$E3`). All vector handler entries and inline hooks
matched in the joined trace. A text byte's following byte is not automatically
an operand; it is independently dispatched on a later interpreter step.

The vector trace records each handler entry and post-handler script pointer,
but does not yet encode every handler's full side effects or variable operand
format. In particular, the confirmed `$FE` handler at `$8862` changes the
script pointer from `$A29E` to `$A020`, producing a replay. The title Start
handoff later changes the pointer to `$00E8`; that is the trace endpoint, not a
cutscene terminator.

## FC correction and remaining behavior

The bank-0 interpreter's vector word for `$FC` is `$8836`. Since dispatch uses
`RTS`, execution starts at `$8837`. In the captured cold-start path, FC at
`$A054` calls `$899A` (which writes `$99=($99&$80)|$40`), calls `$9FA8` with
A=`$04`, increments `$51:$52` by `$0040`, increments the script pointer once,
and resumes at `$84E3`. The next dispatch is `$A055`; `$4F` there is text. The
former `$9085` counted-payload attribution is false on this path. The `$9FA8`
effects and FC's complete visual meaning remain unresolved; see
`reference/rom_extract/intro/cold_start_vector_handler_semantics.md`.

The PPU capture independently records write pairs at `$2249–$2251` and
`$2269–$2271` on frames 837–845. At the writes `$2000=$84`, so PPUDATA
increments PPUADDR by 32 after each write. End-of-frame RAM pointers are one
byte past the associated in-frame source event. This confirms register writes
and address stepping only; it does not prove the final raster-visible
coordinates or the producing routine. See
`reference/rom_extract/intro/fc_first_payload_ppu_trace.md`.

The former claims that `$FE` at file `0x0062AE` was payload, that entry 0
reaches `$FF` at `$A6DB`, and that `$A1B0` consumes bytes through `$A2A5` are
withdrawn. The live trace confirms `$FE` is dispatched at `$A29E` and loops to
`$A020`. The minimum replacement VM should implement the observed interpreter
classes and exact ROM byte dispatch order, handler table targets, pointer
continuations, delays, and FE replay. It must then model vector side effects
from handler code and verify the Start-driven handoff with the same input
sequence before replacing the current presentation timeline.
