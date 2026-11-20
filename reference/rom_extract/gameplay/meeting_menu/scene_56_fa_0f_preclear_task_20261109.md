# Scene $56 FA $0F preclear row task

## Scope and ROM source

This task models only the buffered 16-row clear entered through the shared
bank-0 `$9071` or `$9076` helper. It does not decode FA `$0F`'s 40 background
packets; those remain owned by
[`scene_56_fa_0f_queue_continuation_20261109.md`](scene_56_fa_0f_queue_continuation_20261109.md).

- ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- Scene `$56` event: bank 5, `$BFBC`, file `0x00BFCC`, bytes `FA 0F`.
- Background `$0F` descriptor: bank 7, `$A294`, file `0x00E2A4`, bytes
  `64 66 9A 02 04 12 57 58 59 52 5A 5B 5C 56 00 A0`.
- Checked byte spans and ROM provenance are preserved by
  [`fa_0f_preclear_sources.json`](fa_0f_preclear_sources.json) and
  [`fa_0f_preclear_sources.bin`](fa_0f_preclear_sources.bin). The matching
  Godot runtime copies are under `assets/gameplay/rom_logic/`.

The shared loader at bank 0 `$8AF7` obtains descriptor byte `$02` as `$5E` for
this record. At `$8B93`, it compares `$5E` with `$09`; `$02` takes the branch to
the `$5D & $04` test at `$8B9F`. If that bit is clear, `$8BA5` calls `$9071`;
if set, `$8BAB` calls `$9076`. The retained frame-8006 RAM snapshot has
`$5D=$25`, but the scene trace does not hook the branch instruction, so that
sample alone does not prove which helper entry was actually taken. The task
therefore requires the route to supply the live, source-derived helper entry
PC instead of guessing the destination.

`$9071` begins `A9 20 4C 78 90`: it leaves `$A=$20` and jumps over the `$9076`
immediate, setting `$E7:$E6=$20:$00` (PPU `$2000`). `$9076` begins `A9 24 85
E7`, selecting PPU `$2400`. Both paths then set `$E6=$00`, `$Y=$10` rows,
`$X=$20` bytes, and jump to `$98E8`. These two outputs are represented by the
task; the current trace does not identify the selected one for this event.

## Queue behavior and task API

The `$98E8` loop tests `$4A | $4B`; nonzero selects its buffered path. At
frame 8006 the retained scene trace samples `$4A=$0F`, `$4B=$0F`. The buffered
path copies 16 into `$E8` and 32 into `$E9`, calls `$9B28` once per row, writes
32 zero bytes, calls `$9B5E` to terminate the packet/update the cursor, advances
the PPU base by `$20`, and decrements the row count. For this 16-row count, the
loop's optional negative-row-count `$9FA8` call is not taken.

At `$9B28`, the source compares `$0628 + payload_size` against `$3D`; the
payload is `$20` (32) bytes. A successful packet adds a three-byte queue
header, so its serialized size is 35 bytes. This distinction means a cursor
of `$1C` passes the source compare (`$1C + $20 = $3C`) and can end at `$3F`,
while `$1D` reaches `$3D` and yields. The queue occupies `$05E8–$0627`; the
terminator may be at cursor `$3F`.

When the comparison is full, `$9B2E` loads `$01` and `$9B30` calls `$9FA8`.
The call's saved return word is `$9B32` and its resumed instruction is `$9B33`;
the caller at `$98FC` has saved return word `$98FE`. The buffered `$05E8`
queue's counted PPU data loop is `$A03C`; a release receipt must identify
`$A03C` exactly.

`RomCutsceneFa0fPreclearTask` accepts:

```gdscript
begin(event, 0x56, source_frame, helper_entry_pc,
      Vector2i(live_004A, live_004B), live_0628,
      "rom_derived_presenter_state")
```

`helper_entry_pc` is `$9071` or `$9076` from the decoded loader path. The
initial action requests an anonymous inherited-queue drain if
`$0628 + $20 >= $3D`; its receipt uses empty `event_id`, `batch_index=-1`,
the exact inherited cursor/byte counts, reset cursor zero, and consumer PC
`$A03C`. Otherwise it emits row 0 immediately. It then emits 16 one-row batches
in order, each with a 32-byte zero payload and a 35-byte serialized length.
Each of the first 15 row batches must be followed by a matching release receipt
before the next row is returned. The task returns after staging row 15; it
does not wait for that final row's NMI commit.

After the helper returns, both loader branches converge at `$8BAE`, which
starts a **separate** `$9FA8(A=$01)` wait. That wait is intentionally outside
this row task and must be represented by the outer loader/runtime.

## Retained trace evidence and timing limits

The verifier reads the existing raw RAM snapshots only as validation evidence:

- Frame 8006: `$0628=$39`, `$4A/$4B=$0F/$0F`; the stack contains saved return
  byte pairs for `$9B32` and `$98FE`.
- Frames 8007 and 8021 retain those nested return pairs, consistent with a
  suspended queue-capacity path in this interval.
- Frame 8022 no longer contains the pair, marking a frame-end state boundary.

The capture has no scene-$56 instruction hook at `$9B28`, `$9FA8`, or `$A03C`.
It therefore validates a suspended call context and a sampled queue cursor,
not the exact NMI drain frame, per-row release count in that replay, or
subframe release phase. The intro's
[`cold_start_palette_nmi_commit_trace.md`](../../intro/cold_start_palette_nmi_commit_trace.md)
identifies `$A03C` as the counted `$05E8` queue writer, but does not add a
scene-$56 NMI timing receipt.

Focused check:

```sh
godot --headless --audio-driver Dummy --path . --script tools/diagnostics/verify_rom_cutscene_fa0f_preclear_task.gd
```

Result: PASS on Godot 4.7.2. The verifier checks packaged bytes/hashes,
helper-derived `$2000`/`$2400` row addresses, the 16-row packet sequence,
threshold edges `$1C`/`$1D`, inherited and per-row receipt validation,
rejection of a wrong `$A000` consumer PC, and the retained frame-end stack
context. Synthetic increasing frame labels exercise receipt ordering only;
they do not assert NES frame duration or hardware cycle phase. The task is not
yet integrated into the production route, and the specific `$9071` versus
`$9076` choice remains unresolved from the retained scene trace.
