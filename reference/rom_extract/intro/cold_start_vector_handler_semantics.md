# Cold-start vector handler semantics, first pass

The table is based on the supplied ROM SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
The CPU code `$8000–$9FFF` is PRG bank 0 during this trace; file offset is
`0x10 + (CPU address - 0x8000)`. The dispatch table begins at CPU `$8545`;
its stored word is an RTS return address, so the live handler starts at word+1.
All 145 vector entries in dispatch rows 1–551 matched the logged hook and
bank mapping. `opcode_flow.csv` is the live pointer/frame/mapper evidence.

The byte counts below are consumed script bytes, including opcode. Lengths are
shown by ROM handler control flow and checked against the next live dispatch
pointer. They are not derived from frame spacing. “Helper effects open” means
the handler calls the listed routine, but this table does not claim the
routine's full state changes unless stated.

| Opcode | First-pass count | Vector word → entry | Consumed bytes observed | Source-backed direct effects |
|---|---:|---|---|---|
| E8 | 2 | `$8574 → $8575` | 2: one operand | Reads operand at `($4D),Y`; calls `$8920`; then advances by 2. `$8920` configures state and calls `$9DEE`/`$C4B9`; its complete preset/CHR effects remain open. |
| E9 | 2 | `$857F → $8580` | 1 | Calls `$9FA8` with A=`$02`, then `$997E`, and advances by 1. Screen enable is the established command role; exact PPU mask/raster edge through the helpers remains open. |
| EA | 9 | `$858C → $858D` | 1 | Calls `$99F0` and `$9B7F`; prepares `$E7:$E6=$2000` with Y=`$10`, X=`$20`, then `$2400` with Y=`$20`, X=`$20`; calls `$98E8` for both zero fills; clears `$4C`, `$7B`, `$0D`, `$0E`; advances by 1. `$98E8` masks bit 7 of `$2000` before PPUDATA, so these fills use +1 per write: 16×32 at `$2000` and 32×32 at `$2400` (1,536 writes total), stepping `$20` between rows. |
| EC | 9 | `$85D1 → $85D2` | 2: one operand | Reads operand. `$FF` writes `$0652=0`; other values call `$89D2`, which indexes the bank-6 `$BD00` pointer table by `operand*2`, writes the selected 16-bit pointer to `$0654–$0655`, sets `$0652=$80`, `$0653=1`, `$90=0`, `$91=2`, then restores the `$A000` PRG bank from `$56`; advances by 2. For opening `EC 00`, the pointer is `$BD0C`; this trace does not yet decode the pointed-to data's consumer or visual effect. See `ec_00_pointer_trace.md`. |
| ED | 10 | `$85EB → $85EC` | 2: one sound ID | Finds the first empty slot in `$0700–$0704`; if none is empty it falls through to slot `$0705`. It writes the sound ID there and advances by 2. No direct APU register write in this handler; the later audio driver consumes the queue. |
| EE | 5 | `$8603 → $8604` | 1 | Sets `$E7:$E6=$2221`, uses Y=`$0B`, X=`$1E`, calls `$98E8`, advances by 1. Source code confirms an 11-row x 30-byte zero fill, +1 PPUDATA increment, and `$20` row steps. The fill's purpose and visible frame are not established. |
| F1 | 4 | `$8649 → $864A` | 2: one operand | Sets up the 11-row x 30-byte `$2221` fill through `$98E8`; uses the operand as a doubled table index around `$BB40/$BB41`, calls `$97B6`, then bank helper `$C4B9`; advances by 2. For `F1 01`, bank-6 entry 1 selects `$BB9A`. `$97B6`'s zero-counter `BEQ` at `$97BE` lands at `$9819` (after the RTS at `$9818`), selecting the direct PPU draw path; nonzero counters use the buffered path. Both paths apply the four `$BB9A` records in the captured opening. See `f1_01_graphics_gate_trace.md` for the bytes, addresses, and timing. |
| F2 | 9 | `$8677 → $8678` | 2: one operand | Writes operand directly to RAM `$55` (text delay/speed); advances by 2. |
| F3 | 8 | `$8681 → $8682` | 2 in this pass (operand `$00`) | `$00` calls `$9A35`; that rebuild path copies palette data into `$062A`, sets `$4A/$4B=$0F`, and calls `$9A71` to stage a 32-byte palette packet in the `$05E8` queue. The packet header, NMI consumer, and one-NMI observed transfer delay are traced in `cold_start_palette_nmi_commit_trace.md`. Other operand branches exist (`$FF` consumes four bytes total); their complete selection semantics are not needed to describe this observed first pass. |
| F4 | 9 | `$86B7 → $86B8` | 2: one operand | Operand indexes a handler jump table at `$86C6`. First-pass values `$04/$05` choose `$86F5/$8712`; each loop writes `$0631`, calls `$9A71` to stage palette data, and `$9FA8` with A=`$04`; advances by 2. The palette packet's PPU consumer is traced in `cold_start_palette_nmi_commit_trace.md`; the meaning of each selected palette variant remains open. |
| F5 | 3 | `$87B7 → $87B8` | 2: one operand | If operand is `$FF`, stores `$00` at `$4C`; otherwise stores `(operand OR $80)` at `$4C`; advances by 2. The opening runner's `F5 00` at frame 379 selects bank-6 effect stream 0 through `$EC/$ED=$2A/$B8`; the stream's `$0637–$0639` to `$3F0D–$3F0F` palette loop is traced in `f5_00_runner_palette_effect_trace.md`. Other F5 effect operands remain unmodeled unless separately traced. |
| F8 | 2 | `$87F7 → $87F8` | 2: one consumed operand in this pass | Reads operand at +1 to `$ED` and peeks at +2 to `$EC`; calls `$C4B9` and `$A212`; observed next dispatch is +2, so byte +2 is not consumed here. The helper result controls the actual advance; the F8 semantic effect remains open. |
| F9 | 5 | `$8813 → $8814` | 2: one operand | Clears bit `$04` in `$5B`, reads the operand and calls `$8AF7`; advances by 2. Resource selection/PPU results through `$8AF7` remain partly open. |
| FA | 4 | `$881A → $881B` | 2: one operand | Sets bit `$04` in `$5B`, reads operand and calls `$8AF7`; advances by 2. Resource selection/PPU results through `$8AF7` remain partly open. |
| FB | 10 | `$8830 → $8831` | `2 + count` (count plus that many IDs) | Calls `$9085`. The handler path reads the count, clears `$0468–$0566`, stores list data into animation-related working buffers, and advances by count+2. Observed count 1/2/3 entries consume 3/4/5 bytes respectively. Full descriptor meaning and display schedule remain open. |
| FC | 29 | `$8836 → $8837` | 1: no following payload | Calls `$899A` (sets `$99=($99&$80)|$40`), `$9FA8` with A=`$04`, adds `$40` to `$51:$52`, increments the script pointer by one, and resumes at `$84E3`. The next byte is independently dispatched. `$9FA8` task delay behavior and its limits are described in `cold_start_palette_nmi_commit_trace.md`; the visual meaning of FC's combined state remains open. |
| FD | 9 | `$8854 → $8855` | 1 | Calls `$88B1`, `$9FA8` with A=`$04`, then advances by 1 through `$8887` to `$84D7`. `$88B1` computes an 8-row zero fill from `$4F/$50/$54`; the direct and queued branches, row counts, addresses, and cold-start PPU/NMI timing are traced in `fd_scene_clear_trace.md`. The final screen-space rectangle after scroll/raster state remains open. `$9FA8` task delay behavior is described in `cold_start_palette_nmi_commit_trace.md`. |
| FE | 1 | `$8861 → $8862` | 3: 16-bit target | Reads the following little-endian target, stores it to `$4D:$4E`, and jumps to `$84E7`. At `$A29E`, bytes `$20 $A0` jump unconditionally to `$A020`; the replay begins in the same source frame. |

## Cutscene `$F7` handler versus animation `$F7`

The cutscene dispatcher vector word at ROM file `0x00573` is `$87D8`; because
the table stores an RTS return address, the cutscene handler entry is `$87D9`
(file `0x007E9`). Its bytes begin `A5 09 F0 08 A9 01 20 A8 9F 4C D9 87`:
while RAM `$09` is nonzero it requests a cooperative delay with `$9FA8` and
loops at `$87D9`. When `$09` is zero, it toggles `$7B`, clears `$7A/$44/$45`,
and continues through `$8879`. This handler does not read an `XX` effect
operand after `$F7`.

The cold-opening cutscene stream (`cutscene_00.bin`, 641 bytes) contains no
`$F7` byte, and the live cold-opening opcode trace records no `$F7` dispatch.
This is distinct from the animation VM: the opening runner program at bank-10
CPU `$A0CA` and `$A0E0` uses `F7 05 00 00` and `F7 00 00 02` to set motion
fields, as traced in `animation_6e_runtime_trace.md`. Do not apply generic
community cutscene F7/XX effect descriptions to this animation bytecode or
claim that such an effect command runs in the opening cutscene.

## F4 RTS-table correction and palette sweep

The F4 vector word is a return address, so execution starts one byte later.
At `$86B8` the handler doubles its operand and dispatches through the table at
`$86C6`; the first instruction for F4 04 is `$86F6`, and for F4 05 it is
`$8713`. F4 04 writes `$0631` in the sequence `0F,10,20,30`; F4 05 writes
`30,20,10,0F`. `$0631` is palette source byte `$062A+7`. Each of four passes
calls `$9A71` to stage a 32-byte palette packet and yields with `$9FA8(A=$04)`.
This corrects the earlier table-word interpretation that treated `$86F5` as the
instruction entry and attributed a call to `$9A1F`.

For the opening's F3 00 selection, the isolated source presenter models these
four slot-7 variants using the ROM palette LUT and one-NMI packet transfer. The
palette color change is source-derived; later PPU raster and visible-pixel
timing remain outside this bounded model.

## Trace and capture cross-checks

The first-pass counts and operands above come from dispatch rows 1–551 in
`reference/diagnostics/opening_dispatch_full_20261024_150016/opcode_flow.csv`.
Older RAM/PPU snapshots are only broad cross-checks and can include main-loop
or NMI work. The later cycle-stamped bus captures include the CPU PC for PPU
writes; the FD-specific address/count and path correlation is documented in
`fd_scene_clear_trace.md`. Do not infer per-command frame cost from
dispatch-frame deltas. Those intervals include main-loop work and concurrent
waits.

For ED, the audio queue capture independently confirms the `$0700–$0704`
request values and the later driver consumption. This handler itself does not
write `$4000–$4017`. For F3/F4, `$062A` holds source colors and `$05E8` begins
the staged palette packet. The packet consumer and observed frame-to-frame
transfer are documented in `cold_start_palette_nmi_commit_trace.md`; the first colored
pixel and full raster composition remain unverified.
