# Fresh KICK OFF IRQ-to-A4EB Production Bridge

## Result

The recorded-input Godot route now continues through the candidate frame-7266
`$893B` wait IRQ. The route consumes its own ROM-derived sparse RAM image,
physical stack page, CPU registers, and PPU shadow state; executes the
hash-checked IRQ dispatch/wrapper and bank-$02 `$A160` handler; applies the
handler's PPU writes; releases `$0078` at `$A1C3`; returns through
`$893F-$895C->$8117`; and reaches `$A4EB`. The production route stops before
executing the `$A4EB` body.

## Source and scheduling evidence

- Source ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- Runtime source spans and their byte hashes are pinned in
  `assets/gameplay/rom_logic/fresh_kickoff_preset_wait_irq_runtime.json`.
- The route event context is formed by the live selector/prefix execution and
  sparse source-RAM ledger. The executor rejects trace RAM, emulator state, or
  a candidate endpoint snapshot.
- The schedule contributes only the candidate edge at frame 7266, cycle
  `216372246`, PPU line 128/dot 274. It does not supply handler state.
- The IRQ executor checks `$001B=$C0`, `$003B=$55`, `$0078=$04`, the `$007C-$007E`
  tuple, `$0090/$0091`, the caller stack, and the source PPU shadows before it
  starts the handler.

The bounded source path executes `$C506->$C821->$C478->$C491->$A160`, clears
`$0078` at `$A1C3`, restores the MMC3 banks and interrupted A/X/Y, returns at
`$C4AD`, then lets the mainline pass `$893B` and execute the preset tail. The
post-wait caller runs `$8117->$C4B9->$A006->$A4EB`. Frame-8 NMI PPU writes are
presented before the candidate IRQ's `$2006/$2000/$2005` writes.

## Verification

Command:

```text
CT2_ROUTE_FINAL_FRAME=7300 godot --headless --path . --script tools/diagnostics/verify_kickoff_recorded_input_path.gd
```

Result: PASS on Godot 4.7.2. The recorded route stopped at frame 7266 with
`fresh_match_a4eb_body` pending. The verifier checked the IRQ's `$78:04->$00`
write at `$A1C3`, balanced physical interrupt stack, return through the preset
tail to `$8117`, the `$A4EB` caller state, the no-action selection state, and
that Continue was not entered. Same-input cutscene frame-pointer mismatches at
6808 and 6943 remain in the report; the compared later boundaries at 6968,
7093, 7096, 7112, and 7119 still match.

## Limits and remaining work

- The scanline edge is a ROM-only scheduling candidate. The production model
  does not prove physical NES subframe timing, MMC3 A12 filtering, or full PPU
  fetch timing.
- This integration executes the candidate wait IRQ; it does not reconstruct
  the fourteen earlier NMI/IRQ effects or the complete interrupt timeline.
- `$A4EB`'s `$B305-$B327` stream and `$A503-$A610` body remain unexecuted, as do
  its helper effects and return to `$811F`; `$811F->$C572->$DB62` and later
  match setup are still pending.
- The first in-match command menu, same-input visible field/menu parity,
  route-audio parity, and a packaged ROM/emulator-free run are not verified.

This closes one source-owned wait-to-caller handoff. It is not completion of
the active goal and does not establish exactness.
