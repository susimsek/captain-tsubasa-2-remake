# First command field: source path and current evidence boundary

## Scope and target ROM

This note consolidates the ROM-backed parts of the fresh KICK OFF field scene
and the live actor trace at the first command-menu endpoint. The supplied ROM
is SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
FCEUX files are used only to check addresses, RAM state, PPU output and OAM
composition; they are not shipped presentation assets.

## Confirmed background-animation producer

The first command path queues scenario `$44`. Its source event at ROM file
`0x0237E5` is `02 70 5C F0`: two-tick delay, animation `$70`, sequence `$5C`,
cloud parameter `$F0`. The bank-$10 scenario interpreter copies these values
to `$0524/$0528/$0529`. Bank-$0B routine `$814C` reads animation `$70` through
table `$87F6`; its pointer is `$8B38`, file `0x016B48`, where the record begins
`06 00 56 02 00`. Handler `$8327` selects block `$56`, and `$8525` reads pair
`$3C/$2E` from the `$86EE` table at file `0x0166FE` (pair bytes at
`0x0167AA`). Fixed-bank code stages and commits those CHR selectors to
`$0490/$0491`.

The source record expands to a 4-by-8 metatile region (32-by-16 NES tiles),
not the whole pitch. With the endpoint's `$05CD=$80`, its PPU destinations are
tile data at `$2800` and attributes at `$2BC0`. The exact record header,
block map, metatile tile bytes, and metatile attribute bytes are preserved in
`first_command_field/manifest.json`, with source offsets and hashes. This
small animated-background producer is suitable for a ROM-only Godot resource
path after its update cadence and PPU packet timing are modeled. Applying the
pair as a static profile is not yet equivalent to the live screen.

## Full pitch is not yet established

Background record `$01` at file `0x00E0EF` has header
`3C 3E 02 04 10 00`; its palette selector `$02` matches the captured
background palette at the command endpoint. Its decoded map is a strong
candidate, but it is not confirmed as the active complete field loader. The
previous coordinate alignment matched 412/512 tile IDs; the live background
animation pair also uses `$3C/$2E`, while record `$01` declares `$3C/$3E`.
There is no evidence in the retained run for the complete nametable loader,
its transform, attributes, and raster-time CHR-bank switches. Do not promote
record `$01` to an exact field screen without that route evidence.

The general minimap loader is separately confirmed at bank `$1C` `$82CA`
(global file `0x0382DA`), which reads tile rows from `$834A` (file
`0x03835A`). It fills a 12-by-24-tile lower-screen map and is not the pitch.
The normal field loop enters at fixed-bank `$E145` (file `0x03E155`), while
the first B-press action-menu path is `$E349`/`$E35B` (files
`0x03E359–0x03E370`) → bank `$1A` `$803C` (file `0x03404C`) → `$D575/$D5C3`.
That menu caller confirms descriptors `$02/$03`, but it does not identify the
full pitch-map producer.

At frame 8953, PPUCTRL shadow `$0020=$8A` selects nametable page 2, and the
fixed-bank NMI writes it to `$2000`; its `$2005` scroll is `$004A+$0538=$00`,
then `$004B=$74` (coarse Y 14, fine Y 4). Bank-$0B `$84A1` can establish this
page and scroll through caller `$8393–$8395` with input `$A0`, but the retained
route has no PC hook proving that caller ran. BG `$01` remains a ROM-derived
pitch candidate: its palette matches and its decoded field window matches
412/512 page-2 tile IDs, with all 100 mismatches in source rows 2–9. The active
complete pitch loader, map transform, attribute producer, and raster CHR
sequence therefore remain unresolved.

For animation `$70` / block `$56`, ROM code `$86D3` computes `$05CA=2`;
`$85C2` consequently reads metatile attributes from `$9DE4` / file
`0x017DF4` (page-2 selector), not `$9BE4` / file `0x017BF4`. The expanded
source attributes match PPU `$2BC0` 32/32, but the decoded block's tile rows
do not match the endpoint pitch at either candidate vertical placement. The
runtime candidate and manifest have now been corrected to use separately
preserved page-2 attribute resources; page-0 exports remain distinct. A narrow
Godot route verification now checks those 32 generated PPU bytes against the
retained endpoint snapshot. This fixes the isolated `$56` attribute source, not
the full pitch map or its live producer timing.

## ROM actor pipeline and endpoint evidence

The source actor renderer is fixed-bank `$EE9F` (file `0x03EEAF`). It iterates
six order nibbles in `$0543–$0545`; pointer table `$EF73` (file `0x03EF83`)
maps them to records `$0547,$055C,$0571,$0586,$059B,$05B0`. Bank `$14`
`$83D9/$84DC` advances actor animation state, then bank `$16` `$8000` (file
`0x02C010`) interprets the descriptor in record byte `+$12` and writes the
RAM OAM shadow `$0200–$02FF`. NMI copies that shadow to hardware OAM.

The muted same-input actor trace at frame 8953 establishes the actual
draw-time inputs, superseding static-only uncertainty about which descriptors
were active:

| Actor record | Descriptor `+$12` | `$0546` at draw | OAM slots written |
| --- | ---: | ---: | ---: |
| `$0547` | `$00` | `$08` | 0–5 (6 sprites) |
| `$055C` | `$04` | `$08` | 6–18 (13 sprites) |
| `$0586` | `$0A` | `$08` | 19–40 (22 sprites) |

The other actor records are inactive at that endpoint. The sprite-bank
selectors at each draw call are `$08,$09,$0A,$0B` in `$0494–$0497`; `$0493`
is not part of the four F4-written selectors and is `$00` at the endpoint. Thus the
ROM inputs needed for an endpoint renderer are now known, not just sampled at
end-of-frame. The trace reports the endpoint RAM and PPU images match the
previous retained capture byte-for-byte; those images remain validation
material only.

The descriptor pointer table at bank `$16` `$8280` (file `0x02C290`) resolves
`$00/$04/$0A` to streams `$842C/$87D9/$896B` (files
`0x02C43C/0x02C7E9/0x02C97B`). `$00` and `$04` branch by selector `$0546`;
the live `$08` paths are `$84DF` and `$87F2`. These stream pointers plus
actor position/flip and the run tables `$81D2/$81FA` are all ROM-decodable.
The three selected streams are now decoded into per-sprite OAM tuples by the
research-only tool
[`decode_first_command_actor_oam.py`](../../../tools/diagnostics/decode_first_command_actor_oam.py).
Its JSON report is
[`rom_generated_oam_decode.json`](../../diagnostics/first_command_actor_oam_20261027_113609_utc/rom_generated_oam_decode.json).
The tool reads instruction/data tables from the supplied ROM, consumes the
endpoint actor records as state inputs, and compares its generated tuples with
the endpoint OAM shadow only as a validation step. It does not write or produce
runtime assets.

### Reproducible ROM descriptor-to-OAM algorithm

The decoder checks the target ROM hash and hashes of bank-$16 code `$8000–$8185`,
the descriptor pointers `$8280–$82AF`, and the X/Y tables `$81D2/$81FA` before
interpreting a record. At the endpoint, it selects the stream pointer from the
descriptor table. Control opcode `$03` branches to `pointer + 1 + 2*selector`
(subtracting `$0C` once for selectors `>= $0C`); `$02` replaces the stream
pointer with its little-endian operand; `$01` ends the stream. A control byte
with low three bits `$00` starts a run: count is `((control & $38) >> 3) + 1`,
followed by one Y-offset index and that many two-byte sprite records. Each
sprite record's first byte uses `byte >> 2` to index `$81FA` for X offset and
`byte & 3` for the palette bits; the next byte is the CHR tile ID.

The actor transform follows the byte-checked `$8000–$807A` path: the actor flag
provides sign-extension bits, actor coordinate bytes are biased by `$80`, X is
adjusted by `$0538`, the `$0517` field mirror performs the source's
`$0100 - X` transform, and the sprite flag applies its 8-pixel X-origin
correction. Signed movement deltas at actor-record offsets `+$13` and `+$14`
are then added to X and Y; horizontal mirroring reverses the X delta when the
actor/mirror XOR bit is set. The Y origin uses the actor's Y sign bit and the
`$80/$88` base selected by the sprite flip flags. For each run,
`$81D2[y_index]` is added to the Y origin; X offsets are negated for horizontal
flip. Sprite attribute is `(x_attribute_code & 3) | sprite_flip`. The source clipping window is
`$0540 <= Y < $0541`; an off-range Y or out-of-range X causes the source to
write hidden OAM Y `$F8`.

### Godot source-only builder and focused parity check

The ROM spans needed by this decoder are preserved under
[`actor_oam/`](actor_oam/); `manifest.json` records the target ROM hash,
bank/CPU/file offsets, byte lengths, and hashes. The reproducible extraction
utility is
[`extract_first_command_actor_oam_resources.py`](../../../tools/gameplay/extract_first_command_actor_oam_resources.py).
The runtime component
[`gameplay_rom_actor_oam_builder.gd`](../../../scripts/gameplay/gameplay_rom_actor_oam_builder.gd)
loads and hash-checks those project-owned byte spans. Its `build_oam()` method
accepts live 21-byte actor records, selector, mirror mode, scroll, clip window,
and a caller-owned 256-byte OAM shadow; it decodes descriptor/run/jump/selector
opcodes and returns updated OAM bytes. It never reads the `.nes`, endpoint RAM,
captured OAM, or screenshots. Its output is directly compatible with the OAM
argument of `GameplayRomOamSpriteLayer.configure()`, but the first-command
field scene does not wire the builder into that renderer yet: the route-time
actor-state producer and complete field composition remain missing.

Focused verifier:
[`verify_first_command_actor_oam_builder.gd`](../../../tools/diagnostics/verify_first_command_actor_oam_builder.gd).
Run with `godot --headless --path . --script
tools/diagnostics/verify_first_command_actor_oam_builder.gd`. It supplies the
frame-8953 RAM actor records only as a diagnostic fixture, starts from an
independent OAM shadow, then compares generated bytes with the captured OAM
shadow. Result: **41 sprites, all 164/164 OAM bytes match** across slots 0–40.
This validates the source stream parser and transform for that one frozen
pose. It does not reproduce how the route creates actor records, descriptors,
positions, timers, or animation cadence, and the fixture is not a runtime
asset.

For the frame-8953 validation state, all three actors resolve to base X `$0078`,
base Y `$0043`, and flip `$40`. The source streams resolve to 6 + 13 + 22 = 41
sprites in slots 0–40. The first tuples are actor `$0547`: slot 0
`23 6D 40 80`, slot 1 `23 67 40 78`; actor `$055C`: slot 6
`27 04 41 90`; actor `$0586`: slot 19 `63 5C 43 98`. The generated tuple
comparison matches all 41/41 endpoint entries. This proves the descriptor
parser and endpoint transform for this frozen pose only; the RAM actor state
was the validation input and must itself be produced by the live game logic.

The same-input route trace now records actor-record bytes, script pointers,
timers, selector, and OAM range at every draw from frames 8481–8953. This
supersedes older descriptions that said only the final actor snapshot was
available. It still does not capture the writer PC/PRG bank for mutations to
actor RAM, so route initialization and stream handoffs are not yet a Godot
state producer. See
[`first_command_actor_state_producer_20261027.md`](first_command_actor_state_producer_20261027.md)
for the exact call chain, observed pointer transitions, and next trace hooks.

The draw trace also gives sprite CHR selectors `$08,$09,$0A,$0B` in
`$0494–$0497`; the bank-$16 parser supplies tile and palette attributes. A
runtime actor layer can therefore be built from source ROM streams and CHR
after the animation/field state path is wired. No captured OAM shadow should
be copied into a runtime resource.

## Palette source

The palette worker at fixed-bank `$9ADA` indexes the original ROM table at
file `0x00D310` by `16 * $49`, writes 16 source bytes to RAM `$063A–$0649`,
then uploads those values to sprite palette PPU `$3F10–$3F1F`. During the
MEETING scene `$49=$37` selects file offset `0x00D680`; when the meeting menu
is ready `$49=$0A` selects `0x00D3B0`. Both rows were checked against same-input
RAM/PPU captures. For runtime, use those ROM palette rows and the current
source palette selector, not the captured PPU bytes.

## What is implementable next, and what remains open

1. Add the actor script cadence that produces the endpoint descriptors and
   position from the fresh-start route. The pose timers are `$FF` at frame
   8953; the full path that sets those held descriptors and actor coordinates
   across the route is not yet reproduced. A single endpoint pose is not a
   substitute for the route's time-dependent actor updates. The source-only
   descriptor-to-OAM transform itself now has a Godot implementation with the
   41/41 endpoint parity result above.
2. Trace the full pitch loader and gameplay PPU/IRQ sequence from field entry
   through frame 8953: writes to `$2000/$2005/$2006/$2007`, `$8000/$8001`, and
   IRQ registers with frame/cycle/PC. This identifies the active tilemap,
   attribute producer, and line-dependent CHR selectors.
3. Run a same-input FCEUX compare after those ROM-only paths are in Godot. The
   retained B press at frame 8893 opens the menu; the first sampled complete
   panel is frame 8953, with its true reveal bounded to 45–60 frames. Use
   frame 8953 only as a validation endpoint, not as a hardcoded draw state.

Current status: source selection for the `$70/$56` animation, its CHR pair,
the palette-table addressing path, actor records, draw-time CHR selectors,
active OAM ranges, and the source descriptor-to-OAM tuple algorithm are
confirmed for the frame-8953 validation state. A complete pitch reconstruction
and actor animation/state runtime integration are still open; exact
frame-8953 field/menu composition cannot yet be claimed.
