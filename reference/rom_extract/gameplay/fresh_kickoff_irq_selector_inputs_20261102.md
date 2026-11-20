# Fresh KICK OFF IRQ Selector Inputs

## Finding

The bank-$02 raster IRQ handler at `$A160` uses the wait-event index in `$0078` to select the event tuple in `$007C-$007E`. Its terminal helper at `$A1CB` restores the CHR register pair from `$0090/$0091`. The ROM-only candidate run at the `$893B` wait boundary reports `$007C-$007E = $80,$00,$22` and `$0090/$0091 = $00,$02`; the last source writers for the latter pair are `$8081` and `$8085` in bank `$00`.

The exact initializer at CPU `$807F-$8086` is `LDA #$00; STA $90; LDA #$02; STA $91`. Its bytes are extracted from file offset `0x00008F` and pinned in [the match-setup source manifest](fresh_kickoff_match_setup/manifest.json). Godot validates those bytes, executes this bounded instruction sequence when it accepts the title handoff, and merges the two source-PC write receipts into the sparse RAM ledger. If the live opening presenter supplies `$0090/$0091`, the handoff checks that pair against the ROM result; it does not use emulator state.

## Verification

`godot --headless --path . --script tools/diagnostics/verify_kickoff_recorded_input_path.gd` passed on 2 November 2026. At the projected frame-7266 `$893B` boundary, the ledger reports 610 of 2,048 RAM bytes known, including `$0090=$00` from `$8081` and `$0091=$02` from `$8085`. The IRQ's four table inputs are now represented in the production ledger.

## Limit

This closes IRQ input data only. The production route still stops at `$893B`; it does not yet schedule and execute the raster IRQ, run `$A160->$A1C3`, clear `$0078`, or return through `$8117`. The receipt does not establish physical NES subframe timing or complete MMC3/PPU state. The route verifier's projected boundary is not the interrupt-serviced FCEUX wait state.
