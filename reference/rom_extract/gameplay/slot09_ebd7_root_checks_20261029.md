# Slot-$09 root checks after `$EBD7` — 2026-10-29

## Finding

The live `$87E6` return supplies `$052E=$00`. The root loop reads that live
byte at `$EBD7`, takes `BEQ $EC05`, jumps back to `$EB86`, loads delay `$01`,
and calls `$CB0F`. A separate hash-checked executor now reaches the `$CB0F`
handler entry with the real source call frame and stops before executing the
task-save handler. It does not advance the scheduler or fabricate another
NMI.

This closes the first root-check iteration after the `$87E6` zero branch. It
does not establish the later countdown and state-check branches, scheduler
save effects, later PPU delivery, or visible output.

## ROM identity and source span

The supplied Turkish ROM is SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`, iNES
1.0, mapper 4, 16-byte header, no trainer. The complete checked source span is
fixed bank `$1F`, CPU `$EB86-$EC07`, ROM file offset `0x03EB96`, length 130,
SHA-256 `91ee3ddc0110b7575a472103de8f5e4d1391a60efebe557b4f4238940d74f917`.
The extracted bytes and source manifest are in
[`slot09_ebd7_root_checks/`](slot09_ebd7_root_checks/manifest.json). The span
was compared byte-for-byte with the supplied ROM at file offset `0x03EB96`;
all 130 bytes matched.

## Static root-check map

Addresses and relative branch targets below are derived from the complete
`$EB86-$EC07` span. Inputs are internal RAM values at the listed instruction;
the labels do not imply a higher-level meaning beyond the source operations.

| PC | Source operation | Branch condition / destination | Effect |
| --- | --- | --- | --- |
| `$EBD7` | `LDA $052E` | — | Sets A and N/Z from the current byte. |
| `$EBDA` | `BEQ $EC05` | `$052E == 0` | Skips all later root checks in this iteration. |
| `$EBDC` | `DEC $052E` | Executed only when initial `$052E != 0` | Decrements the live byte. |
| `$EBDF` | `BNE $EC05` | Decremented `$052E != 0` | Skips later checks. If it became zero, execution continues. |
| `$EBE1` | `LDA $052F`; `$EBE4 CMP #$7E` | `$052F < $7E`: `BCC $EBF9` | Selects the `$063F` flag check. |
| `$EBE8` | `CMP #$7F`; `$EBEA BEQ $EBF3` | `$052F == $7F` | Calls `$D093`. |
| `$EBEC` | `LDA $0027`; `$EBEF CMP #$04`; `$EBF1 BEQ $EC05` | `$0027 == $04` | Skips `$D093`; otherwise calls it. |
| `$EBF3` | `JSR $D093`; `$EBF6 JMP $EC05` | Reached by `$052F == $7F` or `$0027 != $04` | Calls the still-unmodeled helper, then returns to loopback. |
| `$EBF9` | `BIT $063F`; `$EBFC BPL $EC02` | `$063F` bit 7 clear | Calls `$CBF1`. |
| `$EBFE` | `CMP #$63`; `$EC00 BNE $EC05` | Carried A equals `$63` | Calls `$CBF1`; otherwise skips it. |
| `$EC02` | `JSR $CBF1` | Reached by the `$063F` / `$052F` checks | Calls the still-unmodeled helper. |
| `$EC05` | `JMP $EB86` | Common loopback | Starts the next iteration at the `$CB0F` yield call. |

Branch targets use the address after the two-byte branch instruction plus the
signed displacement. For example, `$EBDA F0 29` targets `$EC05`; `$EBDF D0 24`
also targets `$EC05`; `$EBE6 90 11` targets `$EBF9`; `$EBEA F0 07` targets
`$EBF3`; `$EBF1 F0 12` targets `$EC05`; `$EBFC 10 04` targets `$EC02`; and
`$EC00 D0 03` targets `$EC05`.

## Live route state and bounded execution

The verifier constructs the fresh route with
`RomFreshKickoffSourceRouteRunner`, then consumes its actual
`slot09_87e6_worker_result`. It does not insert or copy RAM from a trace. The
actual result is at `$EBD7`, has A/X/Y=`$00/$00/$05`, SP=`$7A`, banks
`$18/$19`, and RAM values `$052E=$00`, `$052F=$00`, `$0027=$00`, `$063F=$00`.
Only `$052E` is read on the supported path; the other three values are
recorded to make clear that they did not select the branch.

`RomSlot09Ebd7RootZeroCounterExecutor` validates the prior result's ROM,
source manifest, CPU, stack, RAM, and MMC3 context, then reads `$052E` from its
live RAM image. For the observed source value `$00`, it executes:

```text
$EBD7 LDA $052E
$EBDA BEQ $EC05       ; taken because the source-produced byte is zero
$EC05 JMP $EB86
$EB86 LDA #$01
$EB88 JSR $CB0F        ; stop at target entry, before the handler executes
```

The resulting consumer contract at `$CB0F` is:

| Input | Value |
| --- | ---: |
| Slot base | `$09` |
| Source callsite / target | `$EB88` / `$CB0F` |
| A (delay) | `$01` |
| X / Y | `$00` / `$05` |
| SP before JSR | `$7A` |
| SP at `$CB0F` entry | `$78` |
| JSR return word on stack | `$EB8A` at `$0179-$017A` |
| Mapper banks | `$18/$19` |
| Resume PC saved by the call | `$EB8B` |

The verifier checks the live path, CPU flags, register/mapper state, JSR stack
writes, byte-identical unchanged RAM, and exact stop PC. A negative contract
case changes a copy of live RAM to `$052E=$01`; the executor rejects at
`$EBDC` immediately after the `$EBDA` branch and before executing `DEC $052E`.
The nonzero countdown path is not supported by this increment.

## Files and verification

- Executor: [`rom_slot09_ebd7_root_zero_counter_executor.gd`](../../../scripts/gameplay/rom_slot09_ebd7_root_zero_counter_executor.gd)
- Focused verifier: [`verify_rom_slot09_ebd7_root_zero_counter_executor.gd`](../../../tools/diagnostics/verify_rom_slot09_ebd7_root_zero_counter_executor.gd)
- Source bytes and manifest: [`slot09_ebd7_root_checks/`](slot09_ebd7_root_checks/manifest.json)

Focused verification command:

```text
godot --headless --path . --script tools/diagnostics/verify_rom_slot09_ebd7_root_zero_counter_executor.gd
```

Result: all route-input, source-hash, live zero-branch, stack, mapper,
consumer-contract, and rejection checks passed on Godot 4.7.2. No FCEUX session,
screenshot, or WAV was used.

## Stop condition and remaining boundary

The executor stops at `$CB0F` entry; it does not run the handler bytes at
`$CB0F`, save the slot-$09 continuation, or perform the scheduler scan. The
next integration must pass the contract above into scheduler-owned slot-$09
state before applying the source `$CB0F` save operation. Once `$052E` becomes
nonzero, the earliest unsupported alternate path starts at `$EBDC`; when a
decrement reaches zero, the `$052F/$0027/$063F` predicates and calls to
`$D093/$CBF1` also need source-produced live values and bounded helper coverage.
No later loop or field/menu state is inferred here.
