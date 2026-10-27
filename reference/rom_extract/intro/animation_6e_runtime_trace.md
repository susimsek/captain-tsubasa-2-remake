# Animation `$6E` runtime trace

## Evidence and scope

This report traces the opening's runner animation in the supplied Turkish ROM
(`Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`). It uses
the ROM bytes, the pinned CT2 disassembly where its byte audit applies, and the
existing per-source-frame CPU-RAM/PPU captures. Captured pixels are not used as
assets. The Chinese animation catalog's “Tsubasa running with the ball” label
is useful context, but the behavior below is derived locally rather than from
that label.

The cold-start dispatch trace shows `FB 01 6E` at script file offset
`0x006043` (CPU `$A033`) on source frame 378. ID `$6E` resolves to bank 10,
CPU `$A0C6`, file `0x0140D6`. The extracted bytes in
[`animation_6E.bin`](animation_6E.bin) are byte-for-byte the corresponding
42-byte ROM span. The timing decoder identifies the animation VM range as
CPU `$9154–$94D7` in bank 0; the opening disassembly audit records bank 80's
annotated bytes as matching the ROM. Bank 10's animation and frame data are
read directly from this Turkish ROM; symbolic table comments for banks
`$88–$8A` were not included in the prior annotated-byte comparison.

The timing capture maps `source_frame = emulator_frame_after` and captures
CPU RAM once per source frame. Its CPU-RAM snapshots include the OAM shadow at
`$0200–$02FF`. “Visible pose” below means the ROM-derived frame descriptors
match that OAM shadow; it does not claim to model the 2C02's full scanline
fetch pipeline or OAM DMA edge.

## Byte-decoded animation program

The first byte at `$A0C6` is palette index `$00`; the animation commands begin
at `$A0C7`:

| ROM address / bytes | Decoded effect |
| --- | --- |
| `$A0C6: 00` | Sprite palette index 0 (entry prefix). |
| `$A0C7: F1 1E F6` | Set animation origin Y=`$1E`, X=`$F6`. The captured object stores X as signed Q8.8 and the OAM geometry confirms a 2× origin scale. |
| `$A0CA: F7 05 00 00` | Set animation motion fields. Live trace proves `$94/$95=$0568`; operands initialize horizontal velocity `$0280` and acceleration `$00`. See `runner_motion_live_bridge.md`. |
| `$A0CE: E2` | Repeat the enclosed block twice. |
| `$A0CF: F5` | Enable horizontal mirroring. |
| `$A0D0: 88 37`, `$A0D2: 01` | Select sprite frame `$A837`; wait 2 animation ticks. |
| `$A0D3: 88 6F`, `$A0D5: 01` | Select `$A86F`; wait 2 ticks. |
| `$A0D6: 88 BA`, `$A0D8: 01` | Select `$A8BA`; wait 2 ticks. |
| `$A0D9: 89 08`, `$A0DB: 01` | Select `$A908`; wait 2 ticks. |
| `$A0DC: F0` | End repeat; first pass branches to `$A0CF`, second falls through. |
| `$A0DD: F5; 88 37; F7 00 00 02; 03` | Keep mirroring enabled; select `$A837`; F7 resets horizontal velocity to `$0000` and sets signed acceleration `$02`; wait 6 animation ticks. |
| `$A0F5: 88 6F; 03`; `$A0F8: 88 BA; 03`; `$A0FB: 89 08; 03` | Select each remaining pose in order, waiting 6 ticks per pose. |
| `$A0FE: A0 DD` | Jump back to `$A0DD`; this four-pose section loops indefinitely. |

Thus the animation has a finite two-pass fast section (8 ticks per pass),
followed by an infinite 24-tick cycle. The repeated poses stay in the same
order; only their hold changes from 2 to 6 ticks. All four frame records use
sprite CHR selectors `08 09 0A 0B`:

| Sprite frame | ROM file offset | ROM-derived sprite count |
| --- | ---: | ---: |
| `$A837` | `0x014847` | 42 |
| `$A86F` | `0x01487F` | 42 |
| `$A8BA` | `0x0148CA` | 41 |
| `$A908` | `0x014918` | 43 |

## Capture-confirmed pose timing

In the synchronized capture, the command dispatch is on source frame 378. The
first complete OAM-shadow match to `$A837` is on source frame 379; frame 378 is
the activation edge and does not yet match one of the four complete runner
descriptors. From frame 380 onward, the selected poses and hold lengths align
with the decoded waits:

| Source frames | ROM sprite frame | Hold / phase |
| ---: | --- | --- |
| 379 (initial visible edge) | `$A837` | Initial 2-tick beat; frame 378 is the activation edge. |
| 380–381 | `$A86F` | 2 ticks |
| 382–383 | `$A8BA` | 2 ticks |
| 384–385 | `$A908` | 2 ticks |
| 386–387 | `$A837` | Second `E2` pass |
| 388–389 | `$A86F` | 2 ticks |
| 390–391 | `$A8BA` | 2 ticks |
| 392–393 | `$A908` | 2 ticks |
| 394–399 | `$A837` | First 6-tick beat of the infinite section |
| 400–405 | `$A86F` | 6 ticks |
| 406–411 | `$A8BA` | 6 ticks |
| 412–417 | `$A908` | 6 ticks |
| 418–423 | `$A837` | First observed repeat of the 24-tick loop |

The sequence then repeats every 24 source-frame intervals: `$A837` for six,
`$A86F` for six, `$A8BA` for six, `$A908` for six. Comparing the OAM shadow
against all four ROM descriptor sets with the documented origin, mirror, and
left-clipping rules gives an exact match for 431 of 432 snapshots from source
frames 378–809; the only unmatched snapshot is the source-frame-378 activation
edge. This supports the descriptor selection and frame cadence over the
captured interval, while leaving that one-frame display boundary unresolved.

The sampled PPU states at source frames 380 and 803 independently map sprite
pattern slots `$1000–$1FFF` to the four ROM CHR banks selected by the frame
records (`08 09 0A 0B`). This confirms the sprite graphics source for those
samples, not exact visible-pixel timing at every scanline.

## Capture-confirmed movement; operand mapping still open

The live runner record begins at RAM `$0568`. Its X position is the signed
Q8.8 pair `$056E` (fraction) / `$056F` (integer); the observed velocity pair
is `$0574/$0575`, and the acceleration pair is `$0576/$0577`. These names and
the recurrence are inferred from the captured values and their exact
frame-to-frame changes, rather than asserted from a fully traced variable
handoff. The sampled states follow `v[n+1] = v[n] + a` and
`x[n+1] = x[n] + v[n+1]` (for example, source frame 394→395 changes velocity
from 0 to 2 and position by 2). This is a capture-derived recurrence, not a
claim about instruction order inside the update routine:

| Source frame | X Q8.8 | Velocity | Acceleration | OAM origin X |
| ---: | ---: | ---: | ---: | ---: |
| 378 | `$F6.00` | `$0280` | `$0000` | −20 px (origin state; complete runner OAM is not yet matched) |
| 379 | `$F8.80` | `$0280` | `$0000` | −15 px |
| 380 | `$FB.00` | `$0280` | `$0000` | −10 px |
| 393 | `$1B.80` | `$0280` | `$0000` | 55 px |
| 394 | `$1E.00` | `$0000` | `$0002` | 60 px |
| 395 | `$1E.02` | `$0002` | `$0002` | 60 px after integer-pixel conversion |
| 396 | `$1E.06` | `$0004` | `$0002` | 60 px after integer-pixel conversion |
| 417 | `$20.28` | `$002E` | `$0002` | 64 px |
| 418 | `$20.58` | `$0000` | `$0002` | 64 px; the next loop applies the `$A0E0` physics command |
| 442 | `$22.B0` | `$0000` | `$0002` | 69 px |
| 803 | `$45.DA` | `$0002` | `$0002` | 139 px |

The initial segment advances by `$0280` Q8.8 position units per source-frame
interval, equivalent to 2.5 coordinate units or 5 OAM pixels per interval.
From source frame 394 to 418, the per-frame increments 2, 4, …, 48 sum to
`$0258` Q8.8 units. That is 2.34375 coordinate units, or 4.6875 OAM pixels
per 24-interval cycle. At the loop boundary, the final `$0030` velocity step
advances the position to `$20.58` at source frame 418; the loop's physics
command then resets velocity to zero while acceleration remains `$0002`.
This matches the live record at source frames 394 and 418. The F7 bytecode
operands, live `$0568` destination, and `$975B` integrator are now traced in
`runner_motion_live_bridge.md`. The Godot motion record consumes those source
bytes and timing metadata; same-input output comparison is still needed.

## Unknowns / limits

- The first activation edge at source frame 378 has active runner state but no
  exact match to a complete four-pose OAM descriptor. The exact visible/OAM
  commit boundary there remains open.
- The animation frames are verified against CPU-RAM OAM shadow and two PPU CHR
  snapshots; this does not reconstruct the PPU sprite evaluation/fetch path,
  raster clipping, or prove every final displayed pixel.
- Superseding live PC/RAM evidence now proves the F7 `$94/$95=$0568` destination
  and locates the `$975B` per-tick integrator; see
  `runner_motion_live_bridge.md`. Godot executes that typed object state now;
  same-input OAM projection and raster visibility remain unverified.
- The four-pose loop is shown continuing through source frame 809. Later
  scene commands replace it; this report does not trace the runner's eventual
  exit from the field scene or the cutscene's separate top-level replay.

### Local evidence used

- `reference/rom_extract/intro/animation_6E.bin` and `cutscene_00.json`:
  original entry bytes, pointer, bank and source file offsets.
- `reference/rom_extract/intro/animation_timing_entry.json`:
  decoded repeat/jump path and tick schedule; interpreter range `$9154–$94D7`.
- `reference/rom_extract/intro/sprite_frames_entry.json`:
  four frame descriptor programs, their CHR selectors and sprite counts.
- `reference/rom_extract/intro/cold_start_observed_dispatch.json`:
  `FB 01 6E` dispatch at source frame 378 and its later replay.
- `reference/opening_timing_capture_20261024_125148/metadata.txt` and
  `ram_states/ram_00378.bin` onward: frame mapping, runner state, and OAM
  shadow.
- `reference/diagnostics/intro_sprite_oam_matches.json` and
  `reference/opening_reference_capture/ppu_states/ppu_000380.bin`,
  `ppu_000803.bin`: independent selected-frame geometry/CHR checks.
- `reference/rom_extract/intro/runner_motion_trace.md`:
  earlier record-layout and F7-handler audit; this report narrows its
  animation schedule to per-source-frame OAM matches.
