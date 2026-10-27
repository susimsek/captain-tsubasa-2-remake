# FD scene-clear helper trace

## Source and entry

Target: supplied Turkish ROM, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
The relevant code is in PRG bank 0 mapped at `$8000–$9FFF` (file offset is
`0x10 + CPU_address - 0x8000`). Live dispatcher rows in
`reference/diagnostics/opening_dispatch_full_20261024_150016/opcode_flow.csv`
show nine FD executions, all reaching `$8855` with bank 0 selected. The handler
bytes at file `0x0865` are:

```text
20 B1 88 A9 04 20 A8 9F A9 01 4C 87 88
```

`$8855` calls `$88B1`, calls `$9FA8` with A=`$04`, then advances the script by
one. `$9FA8` is the already-traced cooperative-task delay helper; the following
dispatch frames below are observations, not a claim that the delay alone
accounts for every intervening frame.

## ROM-derived fill parameters

At `$88B1` (file `0x08C1`), bytes
`A5 54 49 FF 18 69 1F AA A0 08 A5 4F 29 E0 05 54 85 E6 A5 50 85 E7 4C E8 98`
perform these operations:

- `Y = 8` rows.
- `X = (~$54 + $1F) mod 256 = $1E - $54` bytes per row.
- `E6 = ($4F & $E0) | $54`; `E7 = $50`, giving the initial PPU address
  `$E7:$E6`.
- The fill value is zero (`$EB=0`). Each next row address adds `$20` to
  `$E6:$E7`.

`$98E8` (file `0x18F8`) tests `$4A | $4B`. If zero, its `BEQ` at `$98F0`
lands at `$992C`, the direct-fill routine. That path saves X/Y as `$E9/$E8`,
turns rendering off through `$2001`, writes `$E9` zero bytes per row through
`$2007`, steps the row base by `$20`, then restores the mask. If `$4A | $4B`
is nonzero, the other path queues one `$05E8` packet per row via `$9B28`, writes
zero payload bytes, and terminates the queue via `$9B5E`; the NMI consumer then
transfers those packets. This matches the separate queue/NMI source trace in
`cold_start_palette_nmi_commit_trace.md`.

## Observed cold-start occurrences

The RAM values below come from per-frame samples in
`reference/opening_timing_capture_20261024_125300/ram_states/`; they are not
instruction-cycle snapshots. PPU writes are from the same replay's
`bus_events.csv`, which tags the executing CPU PC and PPU scanline/dot. The
first FD is independently present in the same-core synchronized capture at
`reference/diagnostics/synchronized_cycle_order_20261024_134001/`.

| FD frame / script PC | sampled `$4F/$50/$54`, `$4A/$4B` | resolved rows | observed PPU action | next dispatch |
|---|---|---|---|---|
| 810 / `$A08A` | `$49/$22/$09`, `$00/$00` | 8 × 21, starts `$2249,$2269,$2289,$22A9,$22C9,$22E9,$2309,$2329` | Direct `$9953` writes, source-frame cycles 26733–28555 (PPU lines 215–231) | frame 814, `$A08B` |
| 1025 / `$A0BC` | `$49/$22/$09`, `$00/$00` | same 8 × 21 sequence | Direct writes, cycles 26887–28721 (lines 216–232) | 1029, `$A0BD` |
| 1525 / `$A11F` | `$49/$22/$09`, `$00/$00` | same 8 × 21 sequence | Direct writes, cycles 25980–27798 (lines 208–224) | 1529, `$A120` |
| 1756 / `$A14B` | `$49/$22/$09`, `$00/$00` | same 8 × 21 sequence | Direct writes, cycles 26141–27979 (lines 209–226) | 1760, `$A14C` |
| 2117 / `$A18F` | `$49/$22/$09`, `$00/$00` | same 8 × 21 sequence | Direct writes, cycles 26994–28832 (lines 217–233) | 2121, `$A190` |
| 2336 / `$A1B5` | `$49/$22/$09`, `$00/$00` | same 8 × 21 sequence | Direct writes, cycles 26444–28266 (lines 212–228) | 2340, `$A1B6` |
| 2685 / `$A1FA` | `$49/$22/$09`, `$00/$00` | same 8 × 21 sequence | Direct writes, cycles 26472–28290 (lines 212–228) | 2689, `$A1FB` |
| 2904 / `$A22E` | `$49/$22/$09`, `$00/$00` | same 8 × 21 sequence | Direct writes, cycles 26153–27991 (lines 210–226) | 2908, `$A22F` |
| 3469 / `$A29A` | `$49/$22/$06`, `$0F/$0F` | 8 × 24, starts `$2246,$2266,$2286,$22A6,$22C6,$22E6,$2306,$2326` | Queued; NMI sends two rows in each source frame 3470–3473 (details below) | 3476, `$A29B` |

For the first eight entries, the matched `$2006/$2007` sequence is the final
eight row groups in the source frame, and each group has exactly 21 zero
`$2007` writes at the formula-derived address. `$2001=$06` disables rendering
before this direct fill; `$2001=$1E` restores it afterward. The first FD's
matching sequence is also present in the synchronized 134001 capture. These
are mainline direct PPU writes in the same source frame, not deferred NMI
packets.

The final FD takes the queued branch. Its frame-3469 RAM sample has
`$0628=$36` and two complete 27-byte records at `$05E8`: count `$18`, address
`$2246`, 24 zero bytes; then count `$18`, address `$2266`, 24 zero bytes. The
rolling RAM samples advance two rows at a time, and `$0628` returns to zero in
frame 3473. The tagged `$A03C` NMI writes confirm the drain:

| NMI source frame | two row addresses / bytes | first–last `$2007` cycle (PPU line) | `$2001` off → restore |
|---:|---|---|---|
| 3470 | `$2246` / 24, `$2266` / 24 | 652–1431 (246–253) | cycle 611 / line 246 → 1483 / line 254 |
| 3471 | `$2286` / 24, `$22A6` / 24 | 649–1428 (246–253) | 608 / 246 → 1480 / 254 |
| 3472 | `$22C6` / 24, `$22E6` / 24 | 649–1428 (246–253) | 608 / 246 → 1480 / 254 |
| 3473 | `$2306` / 24, `$2326` / 24 | 649–1428 (246–253) | 608 / 246 → 1480 / 253 |

All these `$A03C` data values are zero. The transfer happens in the NMI/vblank
window and takes four successive NMIs after the FD dispatch sample.

## Confirmed and still open

Confirmed for this cold-start replay: all nine dispatches and handler entries;
the source formula for base, width, row count, and zero fill; direct versus
queued path selection from `$4A/$4B`; all eight direct address/count patterns;
and the final queued packet order and four-NMI drain. The per-frame RAM values
are corroborating snapshots rather than values sampled on the exact handler
instruction, but the calculated address/count patterns match the PC-tagged PPU
writes.

Still open: the corresponding screen-space rectangle after scroll/raster
state, why the first eight clears use the direct path while the final one is
buffered, and the complete behavior of other FD executions outside this
cold-start replay. No presenter/runtime code was changed by this trace.
