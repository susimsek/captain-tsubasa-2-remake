# Cutscene Sprite Animation CHR Shadow

## Scope

This source task covers the four MMC3 CHR register shadow bytes written when
cutscene 1 dispatches animation `$51` at `$A388`. It does not emulate the
interrupt handler or claim sub-frame NES timing.

## ROM source

The ROM identity and extracted raw spans are pinned in `manifest.json`. The
cutscene event bytes are `$FB $01 $51` at `$A388` (file offset `0x006398`). The
ROM animation record at bank `$09:$A54E` is `3F F1 30 46 93 64 FF`; its sprite
frame command resolves through the ROM frame source to `$B364`. The four-byte
CHR header at bank `$09:$B364` is `70 71 66 67` (file offset `0x013374`).

The fixed-bank writer at `$94D8-$94F0` reads these four bytes through `$E6`,
sets bit 7 on the first selector, and stores `$F0,$71,$66,$67` at `$009E-$00A1`.
The store instructions begin at `$94DE/$94E3/$94E9/$94EE`; their completion
PCs are `$94E0/$94E5/$94EB/$94F0`.

## Godot integration and evidence

`RomCutsceneAnimationChrShadowProducer` validates the cutscene event, ROM
animation record, raw `$B364` header, and `$94D8` instructions before producing
the four RAM-write receipts. `KickoffRouteRuntime` applies the receipt when the
decoded `$FB $01 $51` animation event is dispatched. It uses no FCEUX RAM,
screenshots, or captured audio.

The focused producer verifier passes. The recorded-route verifier passes its
documented projected `$893B` boundary at frame 7266 and now reports 22/25
candidate `$A15B` NMI read-set bytes and 19/25 bytes in the projected wait
ledger. The three candidate values still unknown are `$001B-$001D`. Same-input
FCEUX script pointers match at frame 7119 (`$A38B`); that frame-edge match does
not prove physical CPU/PPU timing or execute the NMI.

Run the checks with:

```sh
godot --headless --path . --script tools/diagnostics/verify_rom_cutscene_animation_chr_shadow_producer.gd
CT2_ROUTE_FINAL_FRAME=7400 godot --headless --path . --script tools/diagnostics/verify_kickoff_recorded_input_path.gd
```

The special NMI and raster IRQ, `$78` release, `$8117` return, field/menu
presentation, complete same-input audio parity, and ROM/emulator-free packaged
execution remain unverified. The earlier source-PC differences at frames 6808
and 6943 also remain.
