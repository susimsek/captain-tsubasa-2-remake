# PPU prerequisites for the live KICK OFF field route

## Question and conclusion

Can the existing `RomPpuNametableWriteApplier` be connected now so the first
slot-$05 `$04A5` packets become visible in the live renderer? **Not safely as a
complete screen update.** The applier's register-to-nametable behavior is
focused-verified, but the current production route has not yet consumed these
packets in a later normal NMI, and it does not provide the source-derived field
nametable, active CHR mapping, palette, scroll, mask, or rendering-event state
needed to turn the writes into the correct visible field.

The applier can be used as a low-level nametable-memory transformer once its
caller owns that memory and PPU state. Wiring it to an empty or stale screen
model would show only a partial two-row patch and would not establish the NES
screen.

## Evidence classes

### ROM-derived route and writes

- The slot-$05 worker resumes at bank `$18:$8889`. With `$0515=0`, its checked
  source path executes `$C509->$CB99`, the `$EF->$8B48` callback, character
  conversion, `$FC->$8C52`, and the menu-window table read. It sets
  `$0515=$80`, advances `$05C5`, and emits these two packets at `$04A5`:

  ```text
  07 21 22 00 00 00 00 00 00 00
  07 41 22 9C A8 20 34 2E A8 9D
  ```

  These are packet-buffer bytes, not PPU writes or captured pixels. The source
  worker and provenance are recorded in
  [the worker continuation report](fresh_worker_resume_and_second_wrapper_source_20261029.md)
  and its [hash-bound manifest](fresh_bank18_worker_prefix/manifest.json).
- The normal-NMI consumer enters through `$C799->$C8FB`, takes the secondary
  queue only when `$0498=0`, checks `$0515.7`, clears `$0515`, and for each
  packet reads `$2002`, writes the address high and low bytes to `$2006`, then
  payload bytes to `$2007`. Its source spans and hashes are in the
  [consumer manifest](normal_nmi_ppu_queue_transfer/manifest.json).
- Therefore, with the bootstrap `$2000` shadow `$88` (PPUDATA increment 1),
  the packets would write seven zero bytes to `$2221-$2227` and the seven
  values `9C A8 20 34 2E A8 9D` to `$2241-$2247`. Each packet resets the
  shared write toggle by reading `$2002` and sets an explicit `$2006` address;
  the initial `v/t` address and write-toggle state do not determine these
  packet destinations. The current source applier models these operations,
  but the source route has not supplied this packet pair to a later NMI
  consumer.
- The fresh bootstrap source at fixed bank `$1E:$C6E8-$C765` seeds
  `$0020=$08`, then sets its NMI bit and copies `$88` to `$2000`. This is the
  bootstrap control shadow used by the current frame-level NMI adapter; it is
  not proof that `$88` remains the field's display configuration. The source
  bytes are already hash-bound in
  [`task_context/manifest.json`](task_context/manifest.json).
- The fixed-bank normal NMI path restores `$2000` from `$0020`, writes scroll
  values derived from `$004A+$0538` and `$004B` to `$2005`, and writes `$0021`
  to `$2001`. Current route composition does not derive the field-time values
  of all these registers or their exact event timing.

### Existing endpoint observations and ROM-derived candidates

- At the later first-command endpoint (frame 8953), retained trace evidence
  reports PPUCTRL `$8A`, scroll `$00,$74`, and MMC3 CHR registers
  `00 02 1F 2E 0A 0B 18 19`; this is a later sampled state, not the first
  `$04A5` packet's display profile. The IRQ trace also lacks scanline/dot
  position and first-output-pixel timing. See the
  [field evidence summary](first_command_field_live_source_summary_20261027.md)
  and [IRQ viewport trace](../../diagnostics/first_command_irq_viewport_20261027_164108_utc/README.md).
- ROM background record `$01` selects CHR banks `$3C/$3E` and palette record
  `$02`. Its decoded map is a candidate, not a confirmed complete field map;
  previous page-2 alignment matched 412/512 tile IDs. The endpoint background
  palette matches ROM record `$02`, but that does not establish its value at
  the initial packet event. The endpoint CHR banks differ from record `$01`'s
  static pair.
- Scenario `$44` animation `$70`/sequence `$5C` selects block `$56` and CHR
  pair `$3C/$2E`. Its decoded 4-by-8 metatile region supplies only 32-by-16
  NES tiles, with tiles at `$2800` and attributes at `$2BC0`; it is not the
  full pitch. These ROM resources are preserved in the
  [field-resource manifest](first_command_field/manifest.json).
- Later, a B input in the field loop reaches fixed-bank `$E349/$E35B`, then
  bank `$1A:$803C` and the `$D575/$D5C3` action-panel path. This confirms a
  later menu setup path, not that the early `$8889` window packets establish
  the full field background. The field loop is entered via `$DAAA` and
  `$E0DF/$E145`; its complete background loader, attribute producer, and
  raster-time CHR sequence remain unproven. See the
  [field source summary](first_command_field_live_source_summary_20261027.md).

### Current production-route observation

The present Godot route services one explicitly labeled normal-NMI abstraction
first. In [`RomFreshKickoffSourceRouteRunner.advance_on_external_nmi()`](../../../scripts/gameplay/rom_fresh_kickoff_source_route_runner.gd), that
consumer runs before root slot `$01` and slot `$05` are resumed. The slot-$05
worker then creates the two `$04A5` packets and leaves `$0515=$80`. The return
value's `ppu_bus_events` belongs to the earlier NMI consumer invocation; it
does not contain writes from the newly created packets. The route stops at the
slot-$09 `$86F8` boundary and does not synthesize another NMI edge. This order
is visible in the runner implementation and the worker/consumer source
contracts; it is not a captured frame-delay assumption.

## State required for a visible renderer

| State | Established for the first packet event? | Required before claiming visible parity |
| --- | --- | --- |
| Packet bytes and write addresses | Yes: source worker bytes and consumer format are hash-checked. | No additional packet inference; obtain them through the later live queue-consumer route. |
| `$2000` increment mode | Bootstrap shadow `$88` is available (`bit 2=0`, increment 1). | Carry the actual field-time shadow through subsequent PPUCTRL writes. |
| `$2002` latch / `$2006` destination | Per-packet source order resets the latch and writes both address bytes. | Model actual register side effects at the source event boundary. |
| Base nametable contents and mirroring | Not established by the two packets. | Derive a clean field nametable, attribute bytes, and mapper mirroring state from the live field loader. |
| Background and sprite CHR | Only partial animation and later endpoint selectors are known. | Derive active `$8000/$8001` mapping by source event/scanline and both pattern-table selections. |
| Palette | ROM palette candidate and later endpoint bytes exist. | Execute the route's palette producer and writes for the packet's actual display interval. |
| `$2000`, `$2001`, `$2005`, scroll, clipping | Bootstrap `$88` and later endpoint `$8A/$00,$74` are known at different points. | Derive field-time control/mask/scroll values and the IRQ transition's raster boundary. |
| OAM/sprites | Later actor pipeline is partly source-mapped. | Compose source-generated actor records, OAM, sprite palettes/CHR, and clipping for the active interval. |
| NMI/IRQ timing | The production route uses one frame-level abstraction; the later trace has CPU-cycle labels only. | Reach the packet's next NMI from source scheduling and identify scanline/dot/first visible pixel or document the remaining software-timing limit. |

## Smallest next transition and integration decision

The immediate missing event is **the next source-owned normal NMI after the
slot-$05 worker sets `$0515=$80`**, including its `$C799->$C8FB` queue delivery
and ordered bus events. Do not apply the current call's earlier NMI event list
to the later packet bytes. After that, the smallest screen-producing slice is
the source-owned field PPU baseline immediately before those writes: nametable
and attribute initialization, palette, active CHR mapping, `$2000/$2001`, and
scroll/IRQ setup. The existing `$DAAA->$E0DF/$E145` field path is the source
route to trace; later `$E349` menu setup is not a substitute for it.

Until those live inputs are available, keep the applier as an isolated
component or connect it only to a diagnostic/staging nametable. Do not call
`set_ppu_memory()` with an empty dictionary and present the resulting patch as
the ROM's visible screen. Existing source bytes and manifests are already
hash-checked; this report introduces no new ROM-byte extraction or runtime
asset.

## Route update after this audit — 2026-10-29

The production runner now executes the source-supported `$86F8` `$0532=0`
branch and returns at `$EBB3` before the next `$8779` worker. This does not
change the PPU conclusion: the current route still has only one frame-level
normal-NMI abstraction, and its `$04A5` packets are created after that NMI's
queue consumer ran. The later source-owned NMI and field PPU baseline remain
required before the packet writes can be rendered.
