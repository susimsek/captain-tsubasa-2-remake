# First-command RNG state before frame 8400: static source audit

## Scope and identity

Static ROM-byte audit of the supplied Turkish ROM, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
File offsets include the 16-byte iNES header. No FCEUX session was run for
this note; emulator captures and the prior post-frame-8399 trace are not used
as runtime state.

## `$001B.6`: known readers, writers, and unresolved producer

- Reset vector `$FFF0 -> $C503 -> $C64E` clears physical RAM `$0000-$07FF`
  with the page loop at fixed-bank `$C64E-$C678` (file `0x03C65E`). Startup
  then clears `$001B` again at `$C6E8-$C6EB` (file `0x03C6F8`). The same
  instruction address is reused by the route transition observed at frame
  8460, so the bytes establish the clear operation but not a unique caller or
  startup-only role. They do not identify when the route first enables bit 6.
- The NMI gate at `$C76E` (file `0x03C77E`) tests `$001B.6`: set jumps to
  `$C421`, clear falls through to `$C775` and its normal `$C7E4 -> $C9C5`
  call. `$C421` selects bank `$02` and calls `$A000` at `$C43A` (file
  `0x03C44A`); that controller-read path reaches the `$A116` RNG entry (`$A117`
  begins with its first arithmetic load). A separate bank-$02
  dispatcher at `$A200` has a vector to `$A21B`; this is not the NMI path.
- That separate `$A21B` body contains `LDA $001B; ORA #$40; STA $001B` at
  `$A224-$A228` (file `0x004234-0x004238`). The write preserves/reasserts bit
  6, but its route caller is not established here and it does not identify the
  original mode transition.
- Bank-$02 `$A5C0-$A5CD` selects mapper register value 0 and clears bit 6;
  `$A5CE-$A5DB` selects value 1 and sets bit 6. Their bit operations are at
  `$A5C5-$A5C9` and `$A5D3-$A5D7` respectively (file `0x0045D5-0x0045D9`
  and `0x0045E3-0x0045E7`). Their indirect caller is now byte-mapped: bank-$02
  `$A484-$A490` (`0x004494-0x0044A0`) reads `$00ED`, doubles it, then pushes
  the selected pointer from `$A491` and returns through it. Table entries 8
  and 9 at `$A4A1/$A4A3` (`0x0044B1/0x0044B3`) contain `$A5BF/$A5CD`; the
  RTS dispatch therefore enters `$A5C0/$A5CE`. The target bytes match the
  entry layout in the external [bank-$82 disassembly](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/blob/master/bank_82.asm),
  whose comments mark indices 8/9 unused. That is a useful label lead, not
  route evidence: the three hash-checked decoded kickoff streams
  (`kickoff_cutscene_01`, `kickoff_cutscene_02`, and `kickoff_meeting_scene_44`)
  contain zero `$F8` event opcodes, and no capture establishes `$00ED=8/9`
  during this route. The `$A5C0/$A5CE` path is therefore a known possible
  producer, not the demonstrated fresh-KICKOFF mode transition.
- Address-only references to `$A484` are ambiguous across banks. The
  bank-$09 dialog-animation routine at `$A484` is a different function (file
  `0x012494`, as listed in the ROM-derived kickoff frame-source manifest); it
  must not be confused with bank-$02 F8 dispatch at file `0x004494`.
- A second candidate setter is bank-$02 `$A21B`: `$A200` begins with
  `JMP $A21B`, and `$A21B` ORs `$40` into `$001B`. Fixed-bank `$C41E`
  (`0x03C42E`) jumps to `$A200`, so the local instruction path is
  `$C41E -> $A200 -> $A21B` when entered at `$C41E`. A raw absolute JSR/JMP
  scan found no direct target `$C410/$C411`; the entry/caller state for this
  setup path is still not established, and no source-frame trace ties it to
  the fresh-KICKOFF route.
- `$A133` sets bit 7, `$C7EE` sets bit 7, and `$CAB4` clears bit 7; bank-0
  `$9F0A` also clears bit 7. These are scheduler-ready latch operations,
  distinct from the mode bit 6.

The current ROM-only route model establishes a specific recorded path: the
bank-$02 `$A117` phase runs through frame 8458, and the mode clear is recorded
at frame 8460. That is not a static proof of the earlier mode producer or a
generic cadence for other inputs.

## Operand pages: initialization and known executable writers

`$C64E` clears all three regions at reset. They are mutable RAM, not ROM RNG
tables. `$C9C5` reads them with `X=$E1`; for `$0780,X`, CPU addresses above
`$07FF` mirror to zero page.

| Region | Source-backed path before the first command menu | Still unresolved statically |
|---|---|---|
| `$0300-$03FF` | Match-zero setup selects roster data at bank-$02 `$A86E` (file `0x00487E`); the roster IDs are written to the separate `$0400`-series slots. Record fields are initialized later through record pointers: fresh-match bank-0 `$811F -> $C572 -> $DB62` initializes home-record energy via `$CE08` and indirect stores at `$DB90/$DB95`; `$DC07` writes formation positions through the same record-pointer mechanism. Opponent setup at fixed `$DB34` maps banks `$1C/$1D`, calls bank-$1C `$8003`, and its trampoline jumps to `$8B22`; `$8B22` initializes opponent record fields through `($34),Y`. | A complete inventory of all earlier indirect record writes and their route-dependent target addresses. The ROM provides no single contiguous `$0300` table initializer. |
| `$0700-$07FF` | `$0700` begins as zero. The first-match queue writer is bank-0 `$812C` (`STA $0700`, file `0x000132`); cutscene queue commands also pass through the `$ED` handler. The bank-$0C sound driver both consumes the queue and mutates working state, e.g. `$834D` `STA $0700,X` and watched-cell updates around `$80D2/$80D9/$80E3`. | The complete pre-frame-8400 cell-by-cell sound-driver/route write history. The queue occupies the first bytes; the rest of the page is live driver/working RAM and must not be modeled as a static command list. |
| `$0780-$07FF` plus mirror | `$C64E` clears the RAM page. The address range is ordinary upper internal RAM; `$0800-$087F` aliases `$0000-$007F`. | No source-only audit has yet traced the complete route-specific writes to the cells later consumed by `$C9C5`, including aliases. Existing post-checkpoint writer rows do not cover the pre-8400 initialization history. |

The post-frame-8399 trace identifies later examples only: `$0300` stores at
opponent/fixed-bank record paths, `$0700+X` sound-driver mutations, and
`$0780,X` mirrored scratch writes. Those rows cannot identify who wrote the
checkpoint's earlier bytes. See
[`first_command_rng_operand_writer_source_map_20261027.md`](first_command_rng_operand_writer_source_map_20261027.md)
for the repeated window and its exact limits.

## Godot production-binding boundary

The current `RomKickoffRngSourceReplay` consumes an A117 frame-range table and
per-frame C9C5 post-state rows from `kickoff_rng_source_schedule.json`. Its
configuration requires the recorded input-timeline SHA-256. The player-state
provider in turn requires that configured replay and the same route identity.
`KickoffRouteRuntime` exposes provider bind/install/eligible-loop methods, but
the production route does not call them. Current callers are focused
diagnostics only; the route's stage transitions and pending menu boundary do
not emit ROM call or field-loop events.

Consequently, the ROM roster/stat/stamina tables can be reused, but receiver
and stamina state cannot yet be safely wired into production. The smallest
source-owned interface needs to provide (1) the polled controller state and
the mode-selected `$A117`/`$C9C5` calls, with live operand RAM and carry for
`$C9C5`; (2) a receiver-selection event from the `$DB08/$DB13` path; and (3) a
field-loop event only when `$E349` returns to `$E14D`. Until a route source
model emits those events, keep the provider/replay diagnostic-only. Do not
remove the hash guard or use the recorded receiver/RAM endpoint as a default.

## Bounded next trace

After the emulator is available, use muted FCEUX 2.7.0/NewPPU and the supplied
ROM hash above. Avoid a full RAM-write callback from reset, which stalled in
the prior attempts. Split the trace into two narrow passes:

1. From cold start, hook only writes to `$001B` and PC entries/returns in
   `$C76E`, `$C421`, bank-$02 `$A000-$A117`, `$A200-$A22B`, `$A5C0-$A5DB`,
   and `$C6E8`. Stop after source frame 32 or after the first `$A117` call
   following the first bit-6-changing write. This identifies the earliest
   mode producer and its call/dispatch path.
2. Make an anonymous in-memory save state at the verified source frame just
   before fresh-match setup begins (record ROM hash, source frame/cycle, full
   RAM/PPU signature, CPU registers, and MMC3 banks). Add only indexed-store
   hooks for `$0300-$03FF`, `$0700-$07FF`, `$0780-$07FF` and mirrored
   `$0000-$007F`; replay through the first `$C9C5` calls. For each relevant
   writer log source frame/cycle, executing bank and PC, effective CPU/physical
   RAM address, old/new byte, `$E1-$E3`, carry, and the caller stack. Reload
   that in-memory state for one same-input repeat and compare normalized rows.

If the first indexed `$C9C5` call precedes the planned state boundary, move the
checkpoint earlier; never infer a missing write from checkpoint contents.
Keep the emulator state and trace diagnostic-only. This bounded work should
close the exact mode dispatch and the operand writers on the recorded route;
generic behavior still requires modeling the identified code paths rather
than replaying captured RAM or a frame/input hash.
