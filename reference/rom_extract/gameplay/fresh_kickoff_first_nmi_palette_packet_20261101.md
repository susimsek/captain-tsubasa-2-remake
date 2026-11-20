# First KICK OFF NMI palette packet — 1 November 2026

## Claim and source

The first nonempty special NMI on the recorded fresh-start KICK OFF route reaches the bank-$02 `$A000` PPU setup routine with a queued 32-byte background-palette packet. The bounded Godot diagnostic executor interprets this packet from ROM-produced RAM, applies its `$2007` writes, clears the queue marker, and restores the interrupted CPU context with RTI.

- Supplied ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- The routine is bank `$02`, CPU `$A000-$A13E`, file offset `0x004010`, length 319 bytes; span SHA-256 `89820a1c55e52fb9fcdb123eeed89945d187eaf4aaf5688d1869ffca612c5350`. The bank mapping and span are checked by `rom_fresh_match_special_nmi_executor.gd` against `fresh_kickoff_0078_wait_20261029/manifest.json`.
- ROM-only source execution reached the NMI at frame 7258, cycle `216117117`, entry `$C421`. The interrupted instruction state is PC `$9F04`, P=`$21`; CPU registers at NMI entry are A/X/Y/P/SP=`$40/$19/$00/$65/$DD`. The trace used the recorded route input hash `87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e` and did not load emulator state or data.
- The source RAM snapshot has `$0628=$23` queued bytes and `$0629=$20`. At `$05E8` the packet is `20 00 3F`, followed by 32 `$0F` palette bytes; `$0628` counts the three-byte header/address plus payload. The terminating zero record follows the 35 queued bytes.
- Source snapshot files are under `reference/diagnostics/kickoff_first_nmi_source_context_20261101/rom_source_c421_snapshot/`; their hashes are recorded in `context.json`. These diagnostics are locally ignored and are not runtime assets.

## Godot execution and comparison

`RomFreshMatchSpecialNmiExecutor` validates and executes the checked bank-$02 `$A000-$A13E` span. Its bounded `$A00A-$A05A` packet path emits 32 `$2007` writes at `$3F00-$3F1F` with values read from the source RAM packet, reports 35 source bytes consumed, and clears `$0628` at `$A04A`. The verifier applies those ROM-derived writes to the pre-NMI source PPU snapshot and compares the 32 canonical palette bytes against both muted FCEUX raw PPU captures for frame 7258. Both captures have SHA-256 `6741d2a36a89296e3d07a94e68bccdda617983bf272eb9db9a183c619ca231ee`; the palette ranges match byte-for-byte. The executor's continuation restores the interrupted PC/P/SP as `$9F04/$21/$E0` (the original `$DD` stack pointer plus three hardware interrupt bytes).

Run the focused verifier with:

```sh
godot --headless --path . --script tools/diagnostics/verify_rom_first_nmi_palette_packet.gd
```

It passed on 1 November 2026. It reads the ignored local source snapshot and two ignored FCEUX raw captures, then runs the ROM-derived Godot executor. No FCEUX process or audio playback is needed for this verifier.

## Limits and next step

This is an isolated diagnostic execution from a ROM-only source snapshot, not a live production-route NMI. It does not prove that the Godot route generates the frame-7258 entry CPU, full stack/RAM, PPU, mapper, or controller state through the preceding source writers. It verifies only this palette packet's PPU memory effect and the bounded return state. It does not establish displayed-pixel equality, full NMI/IRQ sequencing, exact cycle timing, sound equality, first command-menu reachability, or clean packaged-runtime independence. The current production route still projects `$893B` at frame 7266 without live NMI/IRQ execution; it does not reach the field or command menu.

Next, integrate the missing source-owned event/state producers into the route and feed their generated NMI context to the executor. Do not seed the frame-7258 snapshot into production.
