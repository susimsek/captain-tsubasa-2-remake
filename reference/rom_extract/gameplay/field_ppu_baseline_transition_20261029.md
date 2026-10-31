# KICK OFF field PPU baseline: earliest producer audit

## Finding

The earliest PPU-producing calls in the fresh field setup are the two shared
bank-$18 renderer calls at fixed-bank `$E0DF`: `LDA #$00; JSR $EF7F`, then
`LDA #$01; JSR $EF7F`. `$EF7F` forwards the descriptor ID to bank-$18 `$800C`,
which enters the renderer at `$8851/$8852`. Descriptor `$00` now has a bounded
ROM-backed packet source; its two control-token rows remain incomplete.
Descriptor `$01` is not implemented because its `$ED/$EE` callbacks and
operands are outside the supported contract. Neither descriptor is wired into
the production route or a normal NMI consumer.

The first identified pitch-map producer follows at `$E233`: it starts scenario
`$1E`, whose event at ROM file `0x0237EF` is `07 45 90 F0`. That selects
background animation `$45`; its bank-$0B record at `$8A2A` is `06 00 36`.
Opcode `$00` reaches handler `$8327`, then `$8525/$85C2` expands map `$36` and
its attributes. The map is an 8-by-4 metatile patch (32-by-16 NES tiles), not a
complete pitch. The packed selector table gives map `$36` selector `$01`; the
separate CHR-pair table entry is `$00/$3C`. The `$8327` placement is caller
state: it reads prior `$05CD` and writes `$05CE` before producing the patch.

No single currently established transition supplies the complete field
baseline. The full-pitch loader and attributes, active palette writes, initial
CHR raster schedule, and field-time `$2000/$2001/$2005/$2006` state are not
connected to this route. Background record `$01` and palette `$02` remain
candidate data, not proof of the active loader. The endpoint `$70/$56` candidate
uses a different map and CHR pair and belongs to the later first-command path.

## Existing Godot consumer and precise blocker

`RomPpuNametableScreenRenderer` already accepts nametable/attribute bytes with
`set_ppu_memory()`, a background/profile and palette through
`set_background_profile()` / `set_background_palette_bytes()`, CHR mapping via
`set_source_mmc3_chr_writes()`, and scroll/address events via
`set_source_raster_events()`. It has only a boolean rendering toggle for mask
behavior; it does not expose register-level `$2001` PPUMASK state.

`FirstMatchFieldCandidatePresenter` is the only existing gameplay presenter
that joins background `$01`, maps `$36/$56`, and the later `$3C/$2E` profile.
`KickoffCutsceneVisuals.present_first_match_field_candidate()` calls it only as
a fallback inside `present_first_action_menu()`; `KickoffRouteRuntime` reaches
that call when installing the first action menu. It is therefore a later
candidate consumer, not the `$E0DF` field-entry consumer. The separate
`FirstCommandFieldPacketProducer` decodes residual `$F015/$F114` packets but
also requires source callback inputs.

## Descriptor-$00 packet slice

The source pointer, descriptor, and two FC-terminated rows are preserved under
[`field_entry_window_00/`](field_entry_window_00/) with hashes and shared
renderer code ranges in its `manifest.json`. The offline extractor is
[`extract_field_entry_window_00.py`](../../../tools/gameplay/extract_field_entry_window_00.py).
The text parser at `$8986` routes `$E0+` tokens through `$89B4`; its `$C509`
inline dispatch reads the token vectors at `$89BA`. The ROM vectors point
`$EF->$8B48` and `$F0->$8B8B`. For `$EF`, `$8B48` reads period `$0027` and
scans the ROM callback row at `$8B72`; source period zero hits its first `$FF`
and emits no tiles. For `$F0`, `$8B8B` reads `$05F7/$05F8`, divides that
16-bit source value by six, emits the remainder's two ROM tile bytes and the
`$77` separator, then calls the ROM decimal formatter at `$8C55` for the
quotient. Its `$C51E->$CD3C` division helper and `$8C85` tile writer are also
hash-checked.

Those handler inputs are source-owned by the existing fresh-period task:
`$D11E` supplies `$0027=0`; for the supported fresh-match opponent `$03`, the
ROM table `$D183/$D184` supplies `$B4/$00` to `$05F7/$05F8`. The supported
`$F0` output is emitted right-to-left from descriptor column 5, yielding
left-to-right row tiles `36 33 77 33 33` at columns 1–5. This is the ROM's
source output for value `$00B4`, without using captured pixels.

`RomFieldEntryWindowPacketSource` verifies the expanded code/resource
manifest, reuses `FirstActionMenuRomLayout.build_packets()`, and applies the
two ROM handlers. It returns five `$04A5`-format records at `$2221`, `$2241`,
`$2261`, `$2281`, and `$22A1`. It requires a successful result from
`RomFreshPeriodTask.execute_fresh_match_zero()` with the hash-pinned ROM, slot
`$05` at `$D11E`, exit `$DAAA`, period zero, and clock `$00B4`. Without that
source result, or with mismatched source inputs, both dynamic rows stay
incomplete and queue submission is disabled. With the supported result, all
five packet records are complete and queueable. `$0515` remains caller-owned;
the component never writes it. Descriptor `$01` remains outside this slice.

The focused verifier
[`verify_rom_field_entry_window_00_packets.gd`](../../../tools/diagnostics/verify_rom_field_entry_window_00_packets.gd)
passed on Godot 4.7.2. It derives the handler inputs from the existing
hash-checked fresh-match source path, checks all five final packet bytes, and
proves missing or tampered period-task inputs fail closed. It uses no
screenshots, WAV, trace state, ROM file at runtime, or emulator.

The missing inputs at the earliest transition are not the descriptor IDs: ROM
code supplies literals `$00` and `$01`. They are the decoded bank-$18 renderer
transactions for those IDs, their ordered `$04A5` writes and `$0515` wait/NMI
handoff, followed by source-owned field state for scenario `$1E`: callback
cadence and prior `$05CD` at `$8327`. Without those, the renderer cannot receive
the field-entry nametable, and the later `$45/$36` patch cannot be placed from
live state. Palette, active full-field base map, PPUCTRL/PPUMASK, and raster
inputs remain separate unresolved route state.

## Remaining field-entry boundary

The descriptor-$00 handler boundary is closed for the supported fresh-match
source inputs. It is still not wired into the production route or an NMI
consumer, and no live queue handoff is claimed. Descriptor `$01` remains
unsupported because its `$ED/$EE` operand contract has not been decoded.
Scenario `$1E`'s `$45/$36` map still requires live `$05CD` placement. Palette,
mask, and raster state remain unconnected to this field-entry route.

This audit used the supplied ROM and hash-bound resources; it did not start
FCEUX or wire the component into the active route.
