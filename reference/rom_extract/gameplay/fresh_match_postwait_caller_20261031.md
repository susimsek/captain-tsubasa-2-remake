# Fresh Match Post-Wait Caller Boundary

## Result

The source executor now consumes the successful return produced by `RomFreshMatchPresetLoaderPrefix.execute_after_wait_release()` and advances the fresh-match caller from `$8117` through the bank-$01 `$A006` vector transfer.

The checked caller bytes are:

| PC | ROM operation | Result |
| --- | --- | --- |
| `$8117` | `LDX #$01` | Executes; N/Z become known from X=`$01`. |
| `$8119` | `JSR $C4B9` | Executes the hash-checked mapper helper and returns to `$811C`. MMC3 register 7 is selected with bank `$01`, provided the source shadow leaves PRG mode 0. |
| `$811C` | `JSR $A006` | Executes the hash-checked `$A006: JMP $A4EB` vector transfer. The logical JSR frame remains pending at `$A4EB`. |
| `$811F` | `JSR $C572` | Present in the checked caller span but not executed. `$A4EB` has not been source-executed to its return at `$811F`. |

The bounded cycle count is 42 CPU cycles from `$8117` through the `$A006` JMP, excluding any interrupt or device timing. The executor preserves logical JSR frames and does not invent a physical stack pointer or stack page.

## Provenance and verification

The caller bytes come from the manifest- and SHA-checked `$80DF-$815C` ROM span. The mapper helper `$C4B9-$C4C7`, `$A006` vector, and `$A4EB-$A610` body source are validated by the existing source loaders. `RomFreshPrematchA006Entry.execute_logical_source_call()` applies the same checked vector transfer with the logical-frame contract used by the preset tail.

Focused verification:

```text
godot --headless --path . --script tools/diagnostics/verify_rom_fresh_kickoff_postwait_caller.gd
```

Result: PASS on Godot 4.7.2. The verifier checks the `$8117->$C4B9->$A006->$A4EB` source path, mapper register/bank selection, pending return frame, 42-cycle count, the explicit unexecuted `$C572` call, and rejection of unresolved or trace-backed tail inputs.

The verifier constructs a **test-only** IRQ wait-release receipt to exercise the existing preset-tail contract. It does not establish that runtime IRQ production is implemented or that this route is reachable during gameplay.

## Remaining boundary

There is no production producer for the `$893B` wait-release receipt, so this executor is not connected to the live route. The `$A4EB` body remains unexecuted; its helper calls, state mutations, wait conditions, and `$811F` return are still unresolved. Consequently `$811F->$C572`, match initialization, and the first command menu are not yet source-executed by this component.

## Correction: `$A4EB` dispatches a ROM stream at `$B305`

The earlier `$05B3` RAM-buffer analysis was wrong. At `$A4FC-$A500`, the ROM
executes `LDY #$05; LDX #$B3; JSR $B0C0`. `$B0C0` stores Y at zero-page `$EC`
(the pointer low byte) and X at `$ED` (the high byte). The indirect pointer is
therefore CPU address `$B305`, not RAM `$05B3`. The claims about an unproduced
`$05B3` buffer, its missing writer, and a conditional unowned handler must be
discarded. `$9B7F`'s fill range does not affect this ROM stream.

With MMC3 PRG mode 0 and R7=`$01`, `$B305` maps to PRG bank `$01`, file offset
`0x3315`. The 35-byte stream from `$B305` through `$B327` is pinned by SHA-256
`3907025e26e2b3f305a682282af798b2d04dafd2498ab061741d49d6e7c40790`:

| Stream address | Bytes | Dispatch result |
| --- | --- | --- |
| `$B305` | `0D` | Handler `$0D -> $B1A4`; calls `$98A0`, advances 1 byte. |
| `$B306` | `05 45 21 16 89` | Handler `$05 -> $B13B`; calls `$98EA`, advances 5 bytes. |
| `$B30B` | `05 A5 21 16 BA` | Handler `$05 -> $B13B`; advances 5 bytes. |
| `$B310` | `05 A5 22 16 89` | Handler `$05 -> $B13B`; advances 5 bytes. |
| `$B315` | `04 64 21 0A 8A` | Handler `$04 -> $B12F`; shared `$98EA` tail, advances 5 bytes. |
| `$B31A` | `04 7B 21 0A 8A` | Handler `$04 -> $B12F`; advances 5 bytes. |
| `$B31F` | `04 CF 21 07 BB` | Handler `$04 -> $B12F`; advances 5 bytes. |
| `$B324` | `00 28 B3` | Handler `$00 -> $B0F7`; calls `$97B6`, advances 3 bytes. |
| `$B327` | `0F` | Handler `$0F -> $B1BA RTS`; returns from `$B0C0` to `$A503`. |

The muted FCEUX two-pass trace directly records `$EC/$ED`, the computed
indirect address, and its mapped byte at each `$B0C6`: `$B305:0D`,
`$B306:05`, `$B30B:05`, `$B310:05`, `$B315:04`, `$B31A:04`, `$B31F:04`,
`$B324:00`, `$B327:0F`. The sequence matches the pinned ROM bytes in both
replays. At `$B324`, FCEUX enters `$B0F7`, calls `$97B6` with `A=$28, X=$B3,
Y=$28` (the operands at `$B325-$B326`), reaches `$9889`, then dispatches
`$B327:$0F`, returns through `$B1BA`, and enters `$A503`. This resolves the
first dispatcher input and terminator from ROM bytes; it does not by itself
prove all PPU side effects inside the called helpers.

The same muted trace observes `$A503` at frame 7267, `$A610 RTS` at frame
7409, then `$C572` at frame 7409. `$A610` returns to the pending `$811F` caller
return address; `$C572` is the caller's next `JSR` and vectors to `$DB62`.
The route then observes `$A203->$A2AF` at frame 8458, `$AA06` at frame 8459,
and `$C557->$C6BE` at frame 8460. The supplied route input continues through
frame 9042; the existing
[`first command menu capture`](kickoff_first_command_menu_trace_20261027.md)
records the full panel at frame 8953 and the stable endpoint at frame 9042.
These are FCEUX observations with the supplied input sequence, not Godot
execution or a physical-NES timing claim. The two-pass trace is at
`reference/diagnostics/kickoff_select_cleanup_counters_20261031_035608_utc/`.

## Godot boundary and next work

The receipt-gated Godot caller verifier stops at `$A4EB`; it has not executed
the `$B305` dispatcher or `$A503-$A610` body. The production route stops
earlier, at `$893B`, because its source-owned NMI/raster-IRQ bridge and wait
release are not connected. The FCEUX stream, registers, and RAM must not be
injected as runtime input. First produce the real `$893B->$8117` return from
ROM-backed interrupt state; then execute the `$B305-$B327` records and their
helper effects, followed by `$A503-$A610` from source-owned state. The live
route must then continue through `$811F->$C572` and the post-wait match setup
toward the field and first command-menu request. The current Godot route does
not yet reach that menu.
