# Live cleanup-fade palette packet bridge — 1 November 2026

## Scope and source path

This report covers one bounded production-route bridge. It does not claim that
the surrounding NMI, controller scan, sound driver, or interrupt timing runs.

1. `RomCutsceneCleanupFadeTask` derives a 35-byte palette packet from the
   checked ROM cleanup-fade path (`$99F0->$9A71`). The packet starts with
   `20 00 3F` and contains the 32 palette bytes.
2. The route holds the produced packet until the next modeled source tick,
   preserving the existing one-tick palette-presentation delay.
3. `RomFreshMatchSpecialNmiExecutor.execute_cleanup_fade_palette_packet()`
   validates and executes the ROM `$A00A-$A05A` queue consumer against that
   producer packet. It verifies one 35-byte record, 32 `$2007` writes at
   `$3F00-$3F1F` from source PC `$A039`, and the `$0628=0` clear at `$A04A`.
4. The route rebuilds the packet from those 32 returned `$2007` values,
   requires byte equality with the producer output, and gives that reconstructed
   packet to the existing palette presenter. The `$A04A` write is merged into
   the sparse source-RAM ledger under a packet-specific event ID.

The executor constructs only the bounded packet queue from the ROM-produced
fade packet. It does not copy trace RAM, emulator state, or the isolated frame-
7258 NMI snapshot into the production route.

## Verification

The focused recorded-input verifier passed on 1 November 2026:

```sh
godot --headless --path . --script tools/diagnostics/verify_kickoff_recorded_input_path.gd
```

It reaches the projected frame-7266 `$893B` boundary. At the earlier `$A15B`
candidate checkpoint it reports 16/25 known selected-NMI read-set bytes,
including `$0628=$00`; the ledger attributes that value to the packet-specific
consumer event at source PC `$A04A`. The projected `$893B` ledger knows
13/25 selected bytes and 577/2,048 internal-RAM bytes. The other nine candidate
read-set bytes remain unknown, and 12 selected bytes remain unknown in the
later `$893B` projection.

## Limits and next step

This bridge proves the bounded packet consumer and carries its source-produced
palette bytes into the production presenter. It does not execute the full NMI
or IRQ, generate the candidate CPU status and full stack state, release the
`$0078` wait, or continue through `$8117`. It also does not prove sub-frame
PPU timing, displayed-pixel parity, audio parity, first command-menu behavior,
or packaged-runtime independence. The route still stops at the projected
`$893B` setup boundary. Continue by producing complete NMI/IRQ entry state from
live ROM-derived events; keep emulator captures as validation evidence only.
