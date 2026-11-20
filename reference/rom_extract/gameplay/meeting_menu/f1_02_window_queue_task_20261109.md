# Scene `$56` F1 `$02` window queue task

## ROM source and data

The source ROM is the supplied Turkish revision, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`. Scene
`$56` begins at bank-5 `$BFBA` with `F1 02`. The bank-0 `$864A` handler indexes
the bank-6 pointer table at `$BB40` by `2 * operand`; entry `$BB44` contains
`E8 BB`, selecting the four-record PPU stream at `$BBE8` (file offset
`0x00DBF8`). The extracted 90 bytes are preserved unchanged in
[`f1_02_window.bin`](f1_02_window.bin), with record offsets and hashes in
[`f1_02_window.json`](f1_02_window.json). Runtime reads its packaged copy at
`assets/gameplay/rom_logic/f1_02_window.bin`; it does not open the `.nes` file.

The byte parser in `tools/diagnostics/extract_f1_02_window.py` independently
checks the ROM hash, pointer entry, four records, and final-record bit before
copying bytes. Each record has a three-byte header/address followed by
`header & $3F` payload bytes. Header bit 7 selects PPU increment 32; bit 6
marks the final record. `$BBE8` contains two 30-byte rows at `$2221` and
`$2361`, then two 9-byte increment-32 records at `$2241` and `$225E`.

## Buffered source behavior

`$864A` first requests the ROM-defined 11-row × 30-byte zero fill at `$2221`,
then `$97B6` reads the selected table records. The source `$97B6` path checks
`$4A | $4B`: zero selects its direct PPU writer; nonzero stages packets through
`$9B28`. In the recorded KICK OFF route, the frame-7993 RAM sample has
`$4A/$4B=$0F/$0F` and `$0628=$23`, so the expected source branch is buffered.
The retained frame-end samples later show `$0628=$39` at frame 8023 and `$3F`
at 8027. These are sampled snapshots, not per-instruction queue observations.

The queue producer tests whether `$0628 + payload_size >= $3D`; on capacity
pressure it yields through `$9FA8(A=1)` and retries after the queue drain. The
`$05E8` PPU queue is consumed by the bank-2 `$A000` NMI path, which clears
`$0628` when its zero terminator is reached. Source code and NMI queue behavior
are documented in
[`cold_start_palette_nmi_commit_trace.md`](../../intro/cold_start_palette_nmi_commit_trace.md)
and
[`f9_task_timing_trace.md`](../../intro/f9_task_timing_trace.md).

The task derives 13 F1 capacity batches from the exact 11 clear rows, the four
ROM records, the live entry cursor, and the `$3D` comparison. With the recorded
entry cursor `$23`, the first 30-byte row waits for an inherited-queue drain;
that drain is tagged with the unowned receipt sentinel `{event_id: "",
batch_index: -1}`. Each F1 batch then requires a matching `$A000` NMI receipt
before the next batch can be staged. The final three source records fit in one
batch with queue cursor 57, so the command returns when that final batch is
queued; it does not wait for the final NMI commit.

## Runtime and verification boundary

`scripts/gameplay/rom_f1_dialog_window_task.gd` validates the event as scene
`$56`, `$BFBA`, opcode `F1 02`; validates the packaged stream and manifest;
constructs clear-row and ROM-record packets; and rejects a queue-release
receipt unless event ID, batch, cursor, byte counts, source frame, and NMI
consumer PC `$A000` match. `tools/diagnostics/verify_rom_f1_dialog_window_task.gd`
passes the data checks, 13-batch calculation, initial inherited drain, normal
batch release sequence, final marker, and wrong-receipt rejection.

The route must still provide the live `$4A/$4B` counters, live `$0628` cursor,
and actual presenter-produced NMI receipts. The retained same-input capture
does not hook `$97B6`, `$9B28`, or `$A000` during this scene, so this focused
task verifier does not establish that the F1 task is integrated into the live
route or that the observed 29/30-frame sound onset difference is fully closed.
Cycle/subframe timing and visible first-pixel timing remain separate limits.
