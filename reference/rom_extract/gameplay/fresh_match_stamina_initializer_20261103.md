# Fresh Match Stamina Initializer `$C572->$DB62`

## Result

The production recorded-input route follows the `$811F` call through the
fixed-bank `$C572` vector and `$DB62` initializer, processes all eleven fresh
match-00 home records, and returns to `$8122` on route frame 7410. The caller
then reads live `$0026=0`, selects BGM `$55`, stores it at `$0700` at `$812C`,
and holds at `$812F`. The stamina executor writes 22 bytes (low/high for each
record) to the live source RAM ledger. It is bounded to the observed fresh
match-00 state; it is not a general 6502/MMC3 emulator.

## ROM path and data

- Target ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- `$C572->$DB62` vector: 3 bytes at file offset `0x03C582`, SHA-256
  `0cbb606a0a220384a7b6f7e18c761576cad7371a02db168f0c63ef73ce8a860e`.
- `$DB62-$DB9D` loop: 60 bytes at file offset `0x03DB72`, SHA-256
  `430dd56ae794b1424df1b19834d68b81f7e498b7758337574bc59f2a724143c8`.
- `$CE08-$CE29` evaluator-bank helper: 34 bytes at `0x03CE18`; `$CE2D-$CE49`
  bank switch: 29 bytes at `0x03CE3D`.
- Bank `$1C` evaluator `$802D-$818D`: 353 bytes at `0x03803D`. The checked
  entry begins `JSR $803A`; `$813C` jumps to `$818B`, which unwinds the nested
  return frames.
- The home roster and record-pointer table resolve records at `$0300 + 12 ×
  slot`. The profile selector map is the existing ROM-derived
  `player_stat_profile_map_00_22.bin`.
- The shared profile curves `$AE86-$AFAE` are 296 bytes; maximum-energy words
  `$9F0E-$9FCD` are 192 bytes. The additional raw curve span
  `$9FCE-$A595` contains 37 40-byte player-profile rows, SHA-256
  `26397ef62ee1cff2a36d072746005beb5c7a71c1419c193eb2c299c632d50e2b`.
  It crosses the `$1C`/`$1D` PRG-bank boundary under the mapping established by
  `$CE08`.
- Resource provenance and hashes are recorded by
  [`first_match_player_state/manifest.json`](first_match_player_state/manifest.json)
  and reproduced by
  [`extract_first_match_player_state_resources.py`](../../../tools/gameplay/extract_first_match_player_state_resources.py).

For the fresh home route, `$DB62` iterates selectors 10 down to 0 and calls
`$CE08` with evaluator X=0. The bank-`$1C` evaluator uses the player's first
profile byte from `$95D6`. Its selector branches choose the shared `$AE86`
curve path for evaluator selectors 0, `$0B`, `$1E`, and `$1F`; ordinary home
selectors read the corresponding 40-byte row beginning at `$9FCE`. It adds
the current level, clamps the curve index at `$5F`, and reads a little-endian
word from `$9F0E`. `$DB90/$DB95` store the result at each player record's
`+1/+2`. Player ID `$20` is forced to zero only when `$044D` is nonzero.

The live executor refuses unknown or non-fresh inputs. It requires known
`$0026=0`, `$002A=0`, `$044D=0`, the source match-00 roster IDs, and zero level
bytes. It then merges source-PC write receipts into `RomSourceRamImage` and
returns the caller contract at `$8122`. Runtime does not read the ROM file,
emulator state, screenshot, or captured audio.

## Verification and limits

Command:

```sh
CT2_ROUTE_FINAL_FRAME=7410 godot --headless --audio-driver Dummy --path . --script tools/diagnostics/verify_kickoff_recorded_input_path.gd
```

Result: PASS on Godot 4.7.2. The verifier checks the route through `$A611`,
the `$811F->$C572->$DB62->$8122` handoff, all eleven ROM-table calculations,
22 live ledger writes, and the frame-7393 input edge, fade/clear, and level-loop
observations. FCEUX frame-7409 RAM confirms the input roster IDs and levels;
the available frame capture does not provide a post-call RAM checkpoint for
directly comparing all 22 stamina writes. Therefore the stamina outputs are
validated against decoded ROM tables and source bytes, not claimed as a
post-call same-input FCEUX RAM match. The earlier fade, clear, and level-loop
comparisons remain frame/RAM corroboration, not proof of exact CPU/PPU timing.

The stamina executor itself returns at `$8122`; the production route now runs
the following `$8122-$812F` caller branch/store. The `$812F-$815C` caller tail,
field and initial command-menu presentation, menu navigation, same-input route
audio, subframe timing, and ROM/emulator-free packaged run remain open. The
presenter accepts the `$55` event, but its absolute audio onset and PCM parity
are not verified.

## Live scheduler RAM handoff — 9 November 2026

`RomFreshKickoffEntryContext` now carries `stamina_initialization_receipt`.
`RomGameplayTaskScheduler.apply_rom_fresh_match_stamina_initialization()` checks
the `$811F->$C572->$DB62` source path, the `$8122` return contract, all eleven
fresh roster IDs and zero levels, and the exact 66-write source-semantic
sequence. It adopts only the 22 `$DB90/$DB95` energy-record writes; temporary
zero-page writes, full source RAM, task records, and stack are not copied. The
receipt is rejected if it is marked as trace/emulator-derived, incomplete, or
already applied.

The focused verifier executes the selector and stamina source components from
ROM-owned inputs, composes their write receipts, and checks the live scheduler
records. It passed:

```sh
godot --headless --path . --script tools/diagnostics/verify_rom_gameplay_task_scheduler_stamina_adoption.gd
```

The check confirms 22 adopted writes across eleven records and slot 6 as
`08 90 01 00`; it also confirms task/stack preservation and rejection without
partial writes for a trace-marked receipt. This verifies initialization RAM
handoff only.

## Later field-loop update — 10 November 2026

The preceding statement that the field-loop update still needs execution is
historical and superseded. The live production route now executes the
asynchronous `$D193->$E1F1->$E1F7->$E2BC` transition. At source frame 8863, all
eleven live four-byte player records match the same-input FCEUX RAM snapshot
exactly; holder player `$08` changes from 400 to 397. See the focused
[live-route parity report](first_match_stamina_live_route_parity_20261110.md).
