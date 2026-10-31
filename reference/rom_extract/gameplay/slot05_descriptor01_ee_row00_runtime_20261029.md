# Slot-$05 Descriptor-$01 `$EE 00 FC` Runtime Boundary

## Result

The live source worker consumed descriptor row `$BD9C: EE 00 FC`, entered the ROM `$EE` handler at `$8B2F`, took the zero-value early return in the formatter at `$8C55`, and returned through the inline `$FC` handler at `$8C52`. It then reached the real `$C515` worker-yield boundary. No later descriptor row bytes were read.

The worker's live text pointer remained `$BD9C` at `$C515`. The ROM descriptor tail at `$B475-$B47D` contains `$BBE3` as the following row address, but this invocation did not load `$BBE3` into the live text pointer. Treat `$BBE3` as the descriptor's next-row entry, not as a runtime-confirmed pointer transition.

## Provenance

- ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`
- Worker source manifest SHA-256: `afb902c0a8b3780f546ee61b2838e378b272ade79cb4023ac40d3419c165c4dc`
- Row source: `field_entry_window_01/descriptor_01_row_01.bin`, CPU `$BD9C-$BD9F`, bytes `EE 00 FC`, SHA-256 `57363e3984f12148feb77f14c81048d8aaeb1a754576bea2cd507d4fb7250e92`.
- `$EE` handler source: `field_entry_window_01/ee_numeric_handler_8B2F_8B48.bin`, CPU `$8B2F-$8B48`, SHA-256 `ae8a2a4125cb75968151ad77665a895dc7718501a0203a198dc68eb283fc2c48`.
- Decimal formatter source: CPU `$8C55-$8C85`, included in the worker manifest as `bank18_f0_decimal_formatter_8C55_8C85.bin`.
- Descriptor tail: `field_entry_window_01/descriptor_01.bin` bytes `$B475-$B47D` are `03 01 E3 BB 03 05 9F BD`; the row-2 address is encoded at `$B477-$B478` as `$BBE3`.

## Live input and output

The scheduler supplied the current adopted slot-$05 boundary; the continuation did not seed a return receipt or replace its RAM/stack state.

| State | Input at `$89A0->$BD9C` | Output at `$C515` |
| --- | --- | --- |
| A, X, Y | `$00, $03, $00` | `$01, $0F, $03` |
| P, known mask | `$20, $E3` | `$20` |
| SP, PC | `$46, $89A0` | `$48, $C515` |
| Mapper low/high/select | `$18, $19, $07` | `$18, $19, $07` |
| `$0028` | `$00` | `$00` |
| `$003C` | `$01` | `$01` |
| `$003E/$003F` live text pointer | `$BD9C` | `$BD9C` |
| `$0515` | `$01` | `$80` |
| `$05C5` | `$00` | `$02` |

The source-produced `$05C5=$02` and `$0515=$80` are preserved in the adopted scheduler RAM. The live descriptor row pointer did not advance during this worker invocation.

## Executed return path

1. The `$BD9C` row bytes select `$EE`, operand `$00`, then `$FC`.
2. The handler at `$8B2F` reads the live indexed selector `$0028`; the current source state is zero, so the selected value is zero.
3. `$8B2F` jumps to formatter `$8C55`. With `$003C=$01`, `LDY $3C; DEY` makes Y zero and the branch at `$8C58` reaches `$8C84`, the formatter's `RTS`.
4. The inline `$FC` return at `$8C52-$8C54` pops its return words and resumes at `$896C`.
5. The worker reaches `$C515` and is left there without executing the trampoline, scanning another task, generating an NMI, or reading later row bytes.

## Verification and limits

Focused verifier: `tools/diagnostics/verify_rom_slot05_descriptor01_ee_row00.gd`.

It passes under Godot 4.7.2 and checks the same source route through the adopted `$BD9C` boundary, live selector/progress inputs, `$8B2F->$8C55` execution, branch `$8C58->$8C84`, `$FC` return `$8C54->$896C`, output RAM/stack adoption, and stop at `$C515`.

The worker does not reach or load the following `$BBE3` pointer in this slice. The next required ROM transition is the task/scheduler continuation after `$C515`; no cadence or row-2 execution is claimed here.
