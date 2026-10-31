# Slot-$05 second descriptor at `$BBE0`: static source audit

## Runtime status update

The static observation below predates the live `$ED` integration. The current
route consumes `$BBE0: ED 00 FC` and stops before the next `$EE` row at `$BD9C`;
see [`slot05_descriptor01_ed_row00_runtime_20261029.md`](slot05_descriptor01_ed_row00_runtime_20261029.md).

## Finding

The second `$DACE->$EF7F->$800C` invocation selects descriptor `$01` at
bank-$19 `$B464`; its first text row is `$BBE0 = ED 00 FC`. At the time of
this static audit, the worker manifest covered descriptor `$00` at `$B453`,
text `$BBDC/$BBDE`, and `$EF/$F0` callbacks, so the live route stopped at the
unavailable `$BBE0` read. The live worker now consumes this first row as
documented in the runtime update above. A separate `RomFieldEntryWindow01PacketSource`
already decodes descriptor `$01` and its `$ED/$EE` substitutions, but it is a
packet candidate builder, not the slot-$05 CPU/stack/queue execution path. Its
`$EE` rows remain unresolved in that component because it does not execute the
descriptor-row progress loop. A follow-up source audit establishes that the
actual worker derives `$003C` itself; see
[`slot05_ee_003c_descriptor_progress_source_20261029.md`](slot05_ee_003c_descriptor_progress_source_20261029.md).

## ROM identity and selected data

Supplied ROM SHA-256:
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
Bank `$19` is mapped in the MMC3 high window `$A000-$BFFF`; file offset is
`0x032010 + (CPU - $A000)`.

| Source | File offset | Length | SHA-256 | ROM bytes / role |
| --- | ---: | ---: | --- | --- |
| `$B3D1` lookup entry | `0x0333E1` | 2 | `accbbfd498e294cb0ec1047d516f6d35959b8eb5489383366cb620e32143fa20` | `64 B4` → descriptor `$B464`. |
| Descriptor `$B464-$B47C` | `0x033474` | 25 | `f6812eef1a546a57f38689c72882108c959ac740e3ffea93288355cc6765bb82` | `C1 22 07 07 00 00 07 04 04 01 01 E0 BB 01 05 9C BD 03 01 E3 BB 03 05 9F BD`. The four row pointers are `$BBE0,$BD9C,$BBE3,$BD9F`. |
| Row 0 `$BBE0` | `0x033BF0` | 3 | `47e95b03911de543f1f251f12b38d11389dfca4b50b97065336b5b070e2ac5b7` | `ED 00 FC`. |
| Row 1 `$BD9C` | `0x033DAC` | 3 | `57363e3984f12148feb77f14c81048d8aaeb1a754576bea2cd507d4fb7250e92` | `EE 00 FC`. |
| Row 2 `$BBE3` | `0x033BF3` | 3 | `ff4579caac8640e812546cc7649a99a939843eb1f972ccb5c5b715278c5dbd47` | `ED 01 FC`. |
| Row 3 `$BD9F` | `0x033DAF` | 3 | `55535becc5335f960faf89b9118f0677f4a009dffd35466781512590f9f40291` | `EE 01 FC`. |

The lookup and full descriptor are also hash-listed in
[`slot05_second_wrapper_return_20261029/manifest.json`](slot05_second_wrapper_return_20261029/manifest.json)
and [`field_entry_window_01/manifest.json`](field_entry_window_01/manifest.json).
The latter preserves all four row resources above.

## ROM handler/data path

1. When the source-dispatched worker reaches the descriptor text pointer
   `$BBE0` in `$3E/$3F`, `$89A0` (`LDA ($3E),Y`) reads the row's first byte
   `$ED`. The focused runtime report records the preceding live route and
   pointer transition.
2. The bank-$18 parser/vector table `$89BA-$89DB` is file `0x0309CA`, length
   `0x22`, SHA-256
   `74f4bd039c15b503a6b4d4a71652c4c957a179f05cf105c142c04eb740759ebe`.
   Its `$ED` entry resolves to `$8AE7`. Handler bytes `$8AE7-$8B09` are file
   `0x030AF7`, length `0x23`, SHA-256
   `3d325dde06bcd128e916552a6ad5ceb1c29ee01b9d7a413cea018743e390a662`.
   Operand `00` selects `$002A`; with the source-derived fresh-match selector
   value `$002A=0`, the ROM lookup uses selector `$76`, resolves the team-name
   stream at `$F776`, and reads source bytes `53 41 4F` (`SAO`). Static
   converter mapping yields tile IDs `DF CD DB`; the live route verifies that
   the ROM lookup, converter, and emitter execute, but does not claim final
   tile output or PPU presentation. These source bytes are also recorded by
   [`field_entry_window_01/manifest.json`](field_entry_window_01/manifest.json).
3. The row's `$FC` terminator uses the worker's inline callback path to
   `$8C52`; its `68 68 60` sequence restores the callback return. The live
   `$8C54 RTS` returns to `$896C`, resumes the row loop, and reaches pointer
   `$BD9C`. The handler pointer and return bytes are already hash-bound
   in [`fresh_bank18_worker_prefix/manifest.json`](fresh_bank18_worker_prefix/manifest.json).
4. The remaining descriptor rows are not optional for completing the worker:
   `$BD9C` runs `$EE 00 FC`, `$BBE3` runs `$ED 01 FC`, and `$BD9F` runs
   `$EE 01 FC`. `$ED 01` selects `$002B`; the fresh-match selector supplies
   `$002B=3`, whose string stream at `$F785` begins `46 4C 55` and emits tiles
   `D2 D8 E1`. The `$EE` handler `$8B2F` branches through `$8C55` and consumes
   the `$0028/$0029` RAM aliases of `$0628/$0629`; the fresh setup/period
   sources establish both as zero for this route. The formatter also reads
   `$003C`, which the worker's descriptor-row progress loop derives from the
   row progress byte and `$05C5`. The live stop before `$BD9C` has `$003C=1`,
   produced by the worker loop; because `$EE 00` has not been entered, its
   handler input is not yet claimed as executed. The later `$EE 01` value
   `$003C=3` remains static source analysis.

The handler, parser, string tables, and formatter resource spans are recorded
with hashes in `field_entry_window_01/manifest.json`. This static mapping
identifies what the code reads; it does not supply the worker's dynamic CPU,
stack, or transfer-queue effects.

## Runtime boundary and remaining contract

The live worker now consumes `$BBE0: ED 00 FC`, executes the source team-name
lookup/converter/emitter and `$FC` return, adopts the resulting RAM/stack writes,
and stops at `$89A0` with the next text pointer `$BD9C`. Its boundary state has
`$003C=1`; the following `$EE` token read and handler have not executed.

The next bounded transition must resume from this adopted slot-$05 boundary,
execute the `$BD9C: EE 00 FC` path using live `$0028/$0029` and `$003C`, and stop
at the next unsupported ROM source read or source-controlled handoff. The later
`$ED 01`/`$EE 01` rows, `$DAD1` scenario branch, and `$CBB0` enqueue remain
outside this report. Do not seed a return PC, formatter state, or packet output.
