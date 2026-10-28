# Scene `$44`: animation `$3B` dialog branch

## Source identity and evidence

The target is the supplied Turkish ROM, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
All addresses and bytes below were checked against that ROM. The pinned English
disassembly at commit
[`ec03cf06e6bdae0bcd232e3a423e9d259757dc64`, `bank_80.asm`](https://raw.githubusercontent.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/bank_80.asm)
was used as a navigation/label lead, not as the runtime source.

## The two branches

The scene `$44` script issues `FB 01 3B`; animation `$3B` is in PRG bank `$09`.
Its pointer-table entry is at file offset `0x012086`, and the selected record
starts at CPU `$A476`, file offset `0x012486`. The ROM bytes are:

```text
0A F1 30 44 FA 10 B3 8A AD FF
```

`$F1 $30 $44` supplies the animation origin bytes Y=`$30`, X=`$44`. `$FA` is
the dialog-state opcode at `$A47A` / file `0x01248A`; its four operand bytes are
two little-endian frame pointers:

| `$99` state bit 0 | Pointer bytes | Selected bank-$09 frame | File offset |
|---:|---|---:|---:|
| 0 | `10 B3` | `$B310` | `0x013320` |
| 1 | `8A AD` | `$AD8A` | `0x012D9A` |

The target bytes at bank-0 `$9442–$947F` (file `0x001452–0x00148F`) establish
the selection logic: `$FA` sets animation-record flag bit 1, initializes the
shared dialog byte `$0099` to `$C0`, saves the script pointer, then reads either
the word at operand offsets 1–2 or 3–4. The selector is computed from `$0099`
bit 0. `$99` bit 6 is the update gate; when clear, the animation record gets a
one-tick timer and returns without loading a new frame. When set, the selected
pointer is passed to the shared sprite-frame byte reader at `$94D8` (file
`0x0014E8` onward). This matches the disassembly's description of `$FA` as a
two-way speaking/non-speaking animation branch. Do not collapse it to one fixed
frame.

The bank-0 cutscene handlers explain how that state is driven. `$8618` (file
`0x000628`) waits two scheduler ticks, toggles `$99` bit 7, and sets bit 6 so
the sprite worker refreshes. `$895D` (file `0x00096D`) toggles `$99` bits 0 and
6 when bit 7 is set, as part of the text-speed path. Thus the branch choice
comes from live dialogue state and text presentation, not from an independent
animation timer. The exact scene-specific call cadence still needs a live
trace; these handlers alone do not justify a guessed number of displayed
frames per mouth state.

## Frame data decoded from ROM

Both branch targets are ROM sprite-frame programs, not single image files.
The existing ROM frame decoder (`tools/decode_intro_sprite_frames.py`, which
follows the target parser at `$94D8–$96F1`) resolves each to 42 sprite
descriptors, beginning with the same four CHR selectors `78 79 7A 7B`. The
first frame's command stream jumps from `$B325` / file `0x013335` to shared
tail `$B88D`; the second jumps from `$AD9F` / file `0x012DAF` to that same
tail. Both terminate at `$B8DB` / file `0x0138EB` with `$FF`.

The source-data exporter now includes both `$FA` pointer targets in
`animations/kickoff/sprite_frames.json` and preserves their exact decoded ROM
command spans under `animations/kickoff/frame_sources/`. For `$AD8A`, the
frame's own bytes are bank `$09`, CPU `$AD8A–$ADA1`, file offset `0x012D9A`,
24 bytes, SHA-256
`f062f481553f78bd875db8fd85b8e3fcfc6f1c0f6392f5bddb4b1528ceacc524`.
Its shared tail is CPU `$B88D–$B8DB`, file offset `0x01389D`, 79 bytes, SHA-256
`38152016f0d3d9d3a55c4613c45701e45f05a5277904df1f1d6e76a61838fa55`.
The `$B310` frame span is at file offset `0x013320`, 24 bytes, SHA-256
`f8f3d4d149752fbd2c2928d0c02d035fe382039c9c3f27ef75b46eeb5908f684`; it
references the same tail. These binaries are generated from the verified ROM
using the existing frame parser; no capture OAM or rendered pixels are copied.

The parsed descriptor lists differ at sprite index 4: state 0 uses tile `$6F`
with palette low bits 0; state 1 uses tile `$71` with palette low bits 3. The
other 41 descriptors are identical after source addresses are ignored. The
upstream source labels these as the silent/speaking alternatives, but the
target-byte audit establishes the exact state-bit-to-pointer mapping above;
it does not independently label which mouth picture is open. The renderer
must also use ROM CHR bytes, the live animation origin, the selected sprite
palette, OAM ordering/clipping, and the bank-9 sprite CHR selectors. Captured
PPU/OAM state is validation evidence only.

## What this closes and what remains

The `$FA` branch semantics, both ROM frame pointers, and both source-derived
frame programs are now recorded. The existing `animation_timing.json` decoder
still stops at `$FA`. Production playback therefore still needs an
animation-state implementation that consumes `$99`-equivalent dialogue state,
selects the indexed branch frame, and follows the scene/text scheduler events.
Exact frame-by-frame toggle cadence, full palette selection, PPU upload timing,
OAM update phase, and same-input scene `$44` visual comparison remain
unverified. No screenshot or captured audio is part of this decoding.
