# Cutscene cleanup helpers

This package preserves the supplied ROM's bank-$00 source spans for the shared
`$9BA0` cleanup called after a title cutscene returns. The manifest records the
ROM identity, CPU addresses, iNES file offsets, lengths, and SHA-256 hashes.

| CPU span | File offset | Runtime effect represented |
| --- | ---: | --- |
| `$9BA0-$9BA8` | `0x001BB0` | Call `$99F0`, call `$98A0`, then jump to `$9B7F` |
| `$98A0-$98DB` | `0x0018B0` | Temporarily mask rendering, clear `$2000-$27FF` through `$2007`, restore `$0020/$0021` masks, return |
| `$9B7F-$9B9F` | `0x001B8F` | Fill `$0468-$0567` and `$0200-$02FF` with `$F8`, clear four motion-record bytes, return |

`RomCutsceneCleanupClearTask` verifies the preserved bytes and applies the
decoded PPU and OAM effects to the presentation. It records the four RAM
effects in the route's bounded cleanup shadow. The Godot renderer does not yet
own PPUCTRL/PPUMASK shadows, so `$0020/$0021` register-mask restoration is
reported but not claimed as live register emulation.

## Validation

A muted, two-pass FCEUX replay from the signature-checked frame-4692 anonymous
checkpoint reaches frame 7258 twice with identical full PPU and RAM snapshots.
At that frame, `$2000-$27FF` is zero, the 32 palette bytes are `$0F`, OAM shadow
and DMA image are `$F8`, and `$0568/$0588/$05A8/$05C8` are zero. The trace runner
also verifies every staged ID-1 `$99F0` palette packet at frames 7243–7257.
After the helper returns to `$82E2`, the checked caller tail writes zero to
`$0044/$0045/$007A/$007B` and returns to `$80F1`; those four frame-7258 RAM bytes
also match the same-input FCEUX snapshot.

These frame-end observations validate the selected input route. They do not
establish CPU-cycle or PPU-dot timing. Captured PPU/RAM data remain comparison
evidence and are not runtime assets.
