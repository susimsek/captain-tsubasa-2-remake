# Active Implementation Plan

GOALS.md owns the outcome and completion criteria. This file contains only the active work package, its next transitions, and the stop conditions.

## Current work package

Reach the first match command menu from the title's selected KICK OFF route by closing the source-owned setup handoff and connecting the field/menu path. Stop with no soccer action selected.

### Current boundary

The focused recorded-input integration check reaches $893B at frame 7266 after the Select cleanup and the measured selector write timeline. The production route does not execute its interrupt handlers, read/release $78, or return through $895C->$8117. The visible field and command menu remain unreachable in Godot. The exact evidence and limitations are in the source-clock and post-wait reports linked from GOALS.md.

## Next sequence

1. **Restore source-owned state continuity at the caller.** Carry only state produced by the ROM path from the title's KICK OFF branch into $8114->$8920: CPU/status/stack, internal RAM, mapper, PPU, MMC3, and required APU state. Do not seed values from the candidate schedule or FCEUX snapshots.
2. **Execute the $893B wait from source events.** Derive the relevant wait-byte producers from the live route; execute the ROM NMI, sound-driver, and raster-IRQ paths with their RAM/MMIO/stack effects and return state. Produce the receipt consumed by the existing $893F-$895C caller component, then return to $8117. Do not use an elapsed-frame shortcut.
3. **Continue fresh-match setup.** Execute $8117-$811F and source-selected tasks from the returned state. Reconcile the scenario-$35 and slot-$11 timing/state differences against the same-input trace.
4. **Build and connect the visible field.** Establish ROM-derived CHR, palette, nametable, scroll, raster, and actor state. Feed ordered NMI PPU writes into the existing renderer from their live producers.
5. **Reach and operate the first command menu.** Follow the live menu request and player state into the existing panel/input components. Verify the unselected initial cursor and keyboard/controller navigation; stop before confirmation.
6. **Close route audio and standalone verification.** Generate route audio from ROM driver/data, compare the same-input route, and verify a packaged copy without ROM/emulator/capture files. Record residual gaps.

## Execution contract

- Each work cycle answers one source transition: input state, ROM byte span, writes/return, production consumer, observable event, and focused acceptance evidence.
- Reuse a signature-checked muted FCEUX checkpoint for repeated traces. Keep one emulator owner and capture only the missing event. Do not repeat already matched snapshots.
- Prefer integrating a verified component into the live route over building an isolated decoder. Read external sources only for a named unresolved routine/data mapping and verify any lead against this ROM.
- Keep raw traces and exact source-byte provenance in focused reference reports; keep this file as a short work queue. Do not read future scope unless the active goal changes.

## Deferred scope

The complete match command loop, opponent AI, match lifecycle/campaign, Continue/save flow, and unrelated visual/audio paths are outside this milestone. Begin them only after the active goal is completed or the user changes scope.

## Key implementation reports

- $893B interrupt/wait gap: reference/rom_extract/gameplay/fresh_kickoff_8920_source_clock_runtime_gap_20261029.md
- Post-wait caller: reference/rom_extract/gameplay/fresh_match_postwait_caller_20261031.md
- Field PPU producer: reference/rom_extract/gameplay/field_ppu_baseline_transition_20261029.md
- Route audio: reference/rom_extract/gameplay/first_match_audio_integration_boundary_20261028.md
