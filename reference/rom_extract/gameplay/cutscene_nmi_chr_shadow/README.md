# Cutscene CHR Selector Shadow

## Scope

This report covers only the `$F9 $5E` background's two selected 2 KiB CHR
selectors and the corresponding `$008E/$008F` RAM shadow written by the NMI
copy routine. It does not emulate the NMI handler or establish sub-frame NES
timing.

## ROM source

The source ROM is pinned by the SHA-256 in `manifest.json`. The `$5E` record is
at CPU `$AE37`, PRG file offset `0x00EE47`, in bank `$07` mapped at `$A000`.
Its first two raw bytes are `$3C,$3E`; the ROM-derived background layout
reports the same selector pair. The extracted record and code spans are kept
beside the manifest, with byte strings and SHA-256 values for validation.

At `$8B39-$8B46`, the ROM reads two consecutive bytes through the table pointer
and stores them at `$0075` and `$0076` (`STA $75` at `$8B3F`, `STA $76` at
`$8B44`). When the seven-group `$F9 $5E` loader task completes, the NMI copy
routine at `$8CA7-$8CAD` copies `$0075` to `$008E` and `$0076` to `$008F`.

## Godot integration and evidence

`RomCutsceneChrSelectorShadowProducer` checks the extracted code and record
against the manifest, verifies the active ROM-derived layout, and emits
provenance-carrying RAM-write receipts. `KickoffRouteRuntime` applies those
receipts at the start and completion edges of the production background task.
It does not read emulator RAM or screenshots, and the standalone producer
does not require the ROM or emulator at runtime.

The recorded-input verifier observes the ROM `$8B39` selector-table read and
the `$0075/$0076` stores at frame 7112, then the seventh packet-group return
at frame 7119, matching the same-input FCEUX script PCs `$A386` and `$A38B`.
The Godot dispatcher has already delivered `$F9 $5E` on frame 7111; it defers
the source-owned table read/store to the next scheduler pass. The verifier
checks the ROM-derived `$0075/$0076`
and `$008E/$008F` values in the production sparse RAM ledger and checks that
the `$008E/$008F` values reach the candidate `$A15B` NMI checkpoint. This
raised its selected-NMI read-set coverage from 16/25 to 18/25; the projected
`$893B` ledger coverage rose from 13/25 to 15/25. The later
[sprite-animation CHR-shadow report](../cutscene_animation_chr_shadow/README.md)
adds four more ROM-derived selector bytes, bringing current coverage to 22/25
and 19/25 respectively.

Run the focused checks with:

```sh
godot --headless --path . --script tools/diagnostics/verify_rom_cutscene_chr_selector_shadow_producer.gd
CT2_ROUTE_FINAL_FRAME=7400 godot --headless --path . --script tools/diagnostics/verify_kickoff_recorded_input_path.gd
```

These checks establish source-byte and frame-edge receipt consistency. The
production route still does not dispatch the physical NMI handler; it models
the checked selector shadow separately. The endpoint viewport now matches the
same-input FCEUX visible 256×224 image, and a fresh packaged route runs without
the ROM or emulator. Remaining limits include intermediate-frame and
source-cycle PPU timing, physical NMI/`$78`/`$8117` ordering, and PCM waveform
parity. These results do not establish physical NES CPU, PPU, or APU timing.
