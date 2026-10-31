# Live slot-$05 descriptor-$01 `$ED` row execution

## Result

The production route now consumes descriptor-$01 row `$BBE0` (`ED 00 FC`) from the live slot-$05 worker, executes its ROM `$ED` handler and inline `$FC` return, adopts the worker's ordered RAM/stack writes, and stops before the next row at `$BD9C`. The `$EE 00 FC` bytes at `$BD9C` are deliberately absent from this worker source package and are not executed.

This is ROM-byte execution from the supplied game image and source-dispatched task state. No emulator audio, WAV capture, screenshot, trace RAM snapshot, or packet-builder output is used as worker runtime state.

## Source identity and package

Supplied ROM SHA-256:

`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`

The expanded worker source manifest is
[`fresh_bank18_worker_prefix/manifest.json`](fresh_bank18_worker_prefix/manifest.json), SHA-256:

`774e00d8870eceb2df9759a78caa6ebf762b2f8062e1f42d061e257fd5d6eb87`

New runtime source mappings reuse existing hash-checked files from
[`field_entry_window_01/manifest.json`](field_entry_window_01/manifest.json): row `$BBE0`, the `$ED` handler and text loop, the team-name length/pointer data, the `$C53C/$F30F` lookup path, and the team-$00 name stream at `$F776`. The worker manifest references those existing byte files; it does not duplicate or regenerate them.

## Live entry state

The bounded route was advanced through its existing source transitions and four caller-supplied external NMI edges. The next selected task was the actual slot-$05 `yielded_rts` dispatch at `$8889`:

| Input | Value |
| --- | --- |
| CPU A/X/Y | `$FF/$FF/$00` |
| SP / PC | `$4A / $8889` |
| MMC3 low/high / selector | `$18 / $19 / $07` |
| Live `$002A` home-team ID | `$00` |
| Incoming `$003E/$003F` text pointer | `$BBDE` |
| Incoming `$003C` | `$B0` (not used as a seeded row value) |

P was not supplied by the scheduler boundary. The worker reports the status bits known from executed ROM instructions.

## Executed source path

The live worker source flow resolved the descriptor-$01 row pointer and consumed `$BBE0` as `ED 00 FC`:

1. The bank-$18 token vector at `$89BA` maps `$ED` to `$8AE7` (`E7 8A`). The live instruction stream enters the `$ED` handler at `$8AE7`.
2. Operand `$00` selects live `$002A=$00`. The handler calls the fixed-bank team-name lookup through `$8B03->$C53C->$F30F`, reads selector `$76` from `$F415`, and consumes the team-$00 stream at `$F776`, beginning `53 41 4F`.
3. ROM text conversion and emission execute through `$C524->$CBC2`, `$8A6F`, and `$8C9F->$8C85`. The worker consumed the hash-bound source spans for the handler, loop, converter, pointer, and name bytes.
4. The row's `$FC` callback executes `$8C52-$8C54`; the source RTS at `$8C54` returns to `$896C`. The descriptor loop resumes and reaches the next text pointer `$BD9C`.
5. The worker stops at `$89A0` when its indirect read requests `$BD9C` in bank `$19`. That row's first byte is not supplied to this runtime source package, so the `$EE` token handler is not entered.

The source-generated `$003C` value is also observed in this execution. The descriptor loop writes `$003C=0` at `$8954`, then writes `$003C=1` at `$8960` before the `$ED` handler runs. The character-buffer helper temporarily adjusts `$003C` while emitting characters and restores it; at the stop boundary `$003C=1`.

The byte executor gained the ROM's absolute `LDX` operation (`$AE`) because
the live `$ED` handler uses it to read `$002A`.

The stop is before the `$BD9C` token read, so `$003C=1` is reported as the
live next-row boundary value; this execution does not claim that the `$EE`
handler consumed that value.

## Adopted stop state

At the next-row boundary:

| Output | Value |
| --- | --- |
| CPU A/X/Y | `$00/$03/$00` |
| P / known-bit mask | `$20 / $E3` |
| SP / PC | `$46 / $89A0` |
| MMC3 low/high / selector | `$18 / $19 / $07` |
| `$002A` | `$00` |
| `$003C` | `$01`, produced by `$8954/$8960` and restored by the ROM helper |
| `$003E/$003F` | `$9C/$BD` → `$BD9C` |
| `$0515 / $05C5` | `$01 / $00` |
| blocked read | `$89A0` requests `$BD9C`, bank `$19` |

Stack RAM mirrors the returned stack page. The existing caller bytes `$D0/$DA` remain at `$014F/$0150`; this step does not execute the pending return to `$DAD1`.

## Verification

Focused verifier:

`godot --headless --path . --script res://tools/diagnostics/verify_rom_slot05_descriptor01_ed_row00.gd`

Result: passed. It checks the complete live route through the row, source PCs and spans, `$003C` writes, handler/return PC, final registers/mapper/RAM/stack, and the blocked read before `$BD9C`. It does not apply PPU bus events or advance another scheduler task or NMI.

## Remaining boundary

The next source step is the `$EE 00 FC` row beginning at `$BD9C`. Although `$003C=1` is now source-produced, its `$EE` handler and formatter have not been executed through the live worker. This report makes no claim about later descriptor rows, the `$DAD1` scenario enqueue, PPU presentation, audio, or physical NES timing.
