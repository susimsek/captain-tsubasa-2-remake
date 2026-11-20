# Scenario `$44` Field-Entry Handoff

## Result

The same-input Godot route now executes scenario `$44`'s source caller after the `$CBC1 RTS`. At frame `8908`, the caller clears all 64 OAM Y bytes, selects MMC3 PRG banks `$1A/$1B`, resets the stack pointer to `$50`, and reaches `$8003`. The bank `$1A` vector at `$8000` and bank `$1B` field-update routine at `$A103` are the next unexecuted transition. The first command menu is not reached.

## ROM evidence

- ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- The live scenario `$44` return word is `$E38E`, so `$CBC1 RTS` returns to `$E38F` with SP `$4E`.
- `scenario44_post_cbc1_E38F_E3A3.bin` is bank `$1F`, CPU `$E38F-$E3A2`, ROM file offset `0x03E39F`, 20 bytes, SHA-256 `7dc4f685cc530388f709b0944a932a5fb2186f702625a3ef2e9fd1db117739a6`.
- Caller bytes: `20 8B CB A9 1A 85 24 A9 1B 85 25 20 2D CE A2 50 9A 4C 03 80`.
- `$CB8B` calls the fixed OAM helper, which writes `$F8` to `$0200,$0204,...,$02FC` (64 Y-byte stores).
- `$CE2D` selects MMC3 registers 6 and 7, writes `$1A` and `$1B`, then the caller executes `LDX #$50; TXS; JMP $8003`.
- The caller and helper spans are hash-checked by `scripts/gameplay/rom_scenario44_post_queue_return_executor.gd`; `scripts/gameplay/rom_gameplay_task_scheduler.gd` adopts only the validated OAM and mapper writes into the active task context.

## Verification

- The recorded-input route verifier passed its assertions and stopped at frame `8908` with phase `stopped_at_scenario44_field_entry_8003`.
- The focused executor smoke produced 64 OAM writes, four mapper writes, PC `$8003`, and SP `$50`.
- Godot `--check-only` passed for the new executor, source-route runner, scheduler, route runtime, and recorded-input verifier.
- The generated route image is diagnostic evidence only; it is not a runtime visual asset.

## Limits

This handoff does not execute or validate `$8003->$A103`, produce the field PPU composition or command menu, or establish visible pixel parity. PPU beam timing, APU effects, same-input PCM, and packaged runtime independence remain unverified.
