# Fresh KICK OFF background-loader caller audit

## Scope and conclusion

This read-only audit checks whether the fresh KICK OFF path from `$DAAA` through
`$E0DF/$E145/$E233` identifies a full-field call to the shared `$8AF7`
background-record loader. It uses the supplied ROM and retained traces only;
no emulator was run. The ROM SHA-256 is
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.

**The current evidence does not prove a full-field `$8AF7` call after `$DAAA`,
nor a source-controlled full-field record ID on that route.** The direct
`$DAAA` setup calls `$EF7F` twice with renderer descriptors `$00` and `$01`.
The fixed-bank `$E0DF–$E349` and `$E233–$E267` source spans contain no direct
`JSR $8AF7`. Scenario `$1E` later selects animation `$45` and map `$36`, a
32-by-16-tile patch; this is not the full-pitch record loader. Indirect or
worker-mediated calls outside these source spans remain unproven.

## Distinguish the two `$F9` handlers

The same opcode byte has different meanings in the cutscene interpreter and
the bank-`$10` scenario interpreter:

- Before fresh gameplay setup, cutscene 2 starts with `E8 01 F9 02`. The
  cutscene `$F9` handler at bank `$00:$8814` reads operand `$02` and calls
  `$8AF7` at `$8824`. It selects background record `$02`.
- After `$DAAA`, scenario `$35` begins `F9 EB 44`; in the bank-`$10` scenario
  interpreter, `$F9` reads a little-endian word into `$0530/$0531`. Here the
  operand is `$44EB`; it does **not** call `$8AF7`. Scenario `$36` uses the
  same scenario opcode semantics for its `F9 02 7F`, `F9 02 66`, and later
  `F9` records.

Do not infer a gameplay background load from the scenario `$F9` bytes. The
handler distinction is documented in
[`scenario_interpreter_kickoff_rng_audit_20261027.md`](scenario_interpreter_kickoff_rng_audit_20261027.md)
and the earlier cutscene loader trace in
[`f9_task_timing_trace.md`](../intro/f9_task_timing_trace.md).

## Source path after `$DAAA`

The fresh `$DAAA` entry at fixed-bank file offset `0x03DABA` first calls
`$EF7F` with `$00`, then `$01`; it subsequently starts scenario `$35`. On
return from the match-start sequence, `$E0DF` at file offset `0x03E0EF`
initializes field state, calls `$E233`, and enters the loop at `$E145`.
`$E233` at `0x03E243` starts scenario `$1E` and switches to the field-running
setup. These source spans are hash-bound in
[`field_ppu_baseline_transition_20261029.manifest.json`](field_ppu_baseline_transition_20261029.manifest.json).
The checked `$E0DF–$E349` span is 618 bytes (SHA-256
`dc3cd54d809ec4a80dffc8959dd365ecfc994e926dafcfdd7b20d1afc6117523`); the
`$E233–$E267` span starts with `A9 1E 20 B0 CB`.

The first identified scenario-`$1E` field-map event is `07 45 90 F0` at ROM
file offset `0x0237EF` (bank `$10:$B7DF`). The event selects callback `$45`;
its bank-`$0B` record at `$8A2A`, file `0x016A3A`, is `06 00 36`. The callback
uses map `$36` at `$9224`, file `0x017234`, and selector `$01`; the corresponding
CHR-pair entry is `$00/$3C`. These resources and their hashes are listed in
[`first_command_field/page_correct_map_sources/manifest.json`](first_command_field/page_correct_map_sources/manifest.json).
The map expands to an 8-by-4 metatile patch, not a complete field nametable;
its placement still depends on prior `$05CD` state.

## The only identified `$8AF7` route call is earlier

For cutscene 2, operand `$02` selects the bank-`$07` record at CPU `$A127`,
file `0x00E137`. Its decoded header is `5C 5E 06 02 08 10 ...`: CHR selectors
`$5C/$5E`, palette index `$06`, a 2-by-8 metatile layout, and packed origin
`$10` / PPU `$2100`. The palette bytes are at file `0x00D070` and are preserved
as `background_palette_06.bin`. In the shared loader, record byte 2 is masked
and stored to `$0048` at `$8B4C` (file `0x000B5C`). The record/layout is
documented in
[`backgrounds/background_02_layout.json`](backgrounds/background_02_layout.json).

The retained route RAM snapshots bracket `$0048=$1A` at source frame 8100 and
`$0048=$06` by frame 8125; `$0049=$0E` is present by frame 8134. No retained
PC/write trace ties `$8B4C` to the frame-8125 change. These values show that
the cutscene loader is a plausible prior producer, but do not prove that its
nametable remains the fresh field baseline or that the `$8AF7` call runs again
after `$DAAA`.

At the later first-command endpoint, the retained PPU/RAM snapshot instead has
CHR selectors `$3C/$2E`; its background palette matches record `$01`'s palette
`$02`. The route report compares only 412/512 candidate tile IDs for record
`$01`, and no trace identifies a complete field-loader call, nametable packet
sequence, attribute producer, or raster-time CHR schedule. Endpoint state does
not identify when or how those values were produced.

## Trace boundary and next source transition

The existing same-input scenario trace confirms callback `$45` at source frame
8789 and later `$70` at frame 8893. The endpoint PPU capture is frame 8953.
The retained route did not record gameplay `$2006/$2007` writes, every
`$8000/$8001` CHR write, or a gameplay PC hook at `$8AF7`; the endpoint dump
cannot establish loader invocation or packet order. See
[`first_command_scenario_event_continuation_audit_20261028.md`](first_command_scenario_event_continuation_audit_20261028.md)
and [`first_command_field_background_producers_20261027.md`](first_command_field_background_producers_20261027.md).

The next unresolved transition is the field-entry state handoff from the
pre-match cutscene loader to the first visible field interval: determine which
source routine owns the full nametable/attribute initialization, and whether
it calls `$8AF7` or reuses prior background state. A source trace must tie the
caller and record ID to ordered PPU/mapper writes and palette/scroll state.
Until then, keep background `$01` as a candidate and `$02` as a proven earlier
cutscene record, not either one as the confirmed full-field producer.

## Runtime integration decision

No runtime component was added. The existing `RomBackgroundPacketLoader` can
decode packaged background records, and `RomPpuNametableScreenRenderer` can
consume source-owned nametable, palette, CHR, and raster state. The current
source contract does not identify the active full-field record, complete
attribute writes, or route-time PPU events, so wiring either candidate into
the live route would exceed the ROM evidence.
