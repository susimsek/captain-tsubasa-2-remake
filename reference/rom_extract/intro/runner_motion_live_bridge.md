# Runner F7 live bridge and per-tick integrator

## Scope and ROM identity

This trace closes the previously open handoff from the opening runner's F7
commands to its live RAM object, then identifies the ROM routine that updates
its velocity and position. The supplied Turkish ROM's full-file SHA-256 is
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`; FCEUX
reports MD5 `eaf2b3745263efa4b1afd2b400f68dae`, which matches the ROM payload
after removing the 16-byte iNES header. The execution PC, writes, and object
bytes below come from a quiet FCEUX 2.7.0 replay of the existing
`reference/opening_reference_capture/input_timeline.csv`, frames 0–810. Sound
was disabled (`--sound 0 --volume 0`, SDL dummy output). No screenshot or WAV
was used or produced as a runtime asset. FCEUX revision was
`a6d03e7968bd77a8156a7c9b628a673753f2f4c6`; the replayed input CSV SHA-256 is
`195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3`.

The source-frame convention is the existing capture convention:
`source_frame = emulator_frame_after`; source frame 0 supplies the first
`frameadvance()`. A silent MMC3 trace records `$R6=$00` during runner execution,
so CPU `$8000–$9FFF` is bank 0. For that bank, the file mapping is
`0x0010 + (CPU address - $8000)`.

## F7 destination is the runner record

At source frame 378, the animation VM dispatches F7 with script pointer
`$92/$93=$A0CA`. At the F7 handler entry `$93A7` (`0x0013B7`), the live data
pointer `$94/$95` is `$0568`. The same pointer is present at each watched
F7 store. The writes land in the runner object at `$0568`, proving the
handler-to-object bridge directly rather than by end-of-frame correlation.

| Source frame | Script pointer | Handler state at `$93A7` | F7 result in `$0568` |
| ---: | --- | --- | --- |
| 378 | `$A0CA` (`F7 05 00 00`) | `$94/$95=$0568` | `+$08..+$0B = 00 00 00 00`; `+$0C..+$0F = 80 02 00 00`; flag `+$00` gets bit `$20`. |
| 394 | `$A0E0` (`F7 00 00 02`) | `$94/$95=$0568` | `+$08..+$0B = 00 00 00 00`; `+$0C..+$0F = 00 00 02 00`; flag `+$00` retains/sets bit `$20`. |
| 418 | `$A0E0` loop iteration | `$94/$95=$0568` | Repeats the horizontal reset: velocity `+$0C/+0D=0000`, increment `+$0E=02`. |

The first command therefore initializes the horizontal Q8.8 velocity to
`$0280` and increment to zero; the second stops that velocity and sets the
one-byte increment to `$02`. The vertical fields remain zero for this runner.
The handler's source bytes and individual operand decoding are documented in
[`runner_motion_trace.md`](runner_motion_trace.md); the new live PC/RAM trace
confirms the destination for those writes.

At F7 store callbacks, the trace records these exact object destinations:

| F7 command | CPU store PCs | Object bytes written |
| --- | --- | --- |
| `F7 05 00 00`, frame 378 | `$93B2`, `$93BA`, `$93C2`; `$93E7`, `$93EF`, `$93F7`; `$9417`, `$941B`, `$9423` | `$0571=$00`, `$0570=$00`, `$0572=$00`; `$0575=$02`, `$0574=$80`, `$0576=$00`; `$0573=$00`, `$0577=$00`, `$0568=$A1` (sets flag bit `$20`). |
| `F7 00 00 02`, frame 394 | same normal-path stores | `$0571/$0570/$0572=$00`; `$0575/$0574=$00`; `$0576=$02`; `$0573/$0577=$00`; `$0568` has flag bit `$20`. |

For this table, FCEUX's memory-write callback reports the PC immediately after
the two-byte `STA (zp),Y`, so, for example, callback PC `$93E9` is the store
instruction at `$93E7`. `$94/$95=$0568` was read at the F7 entry and remained
the base used by the indirect stores.

## Per-tick integration routine

The animation interpreter checks the object flag and calls the ROM helper
`$975B` for each axis:

| Caller | CPU / file offset | Inputs | Meaning of the helper call |
| --- | --- | --- | --- |
| `$9179` | `0x001189` | `X=$04`, `Y=$0A` | Update vertical velocity at `+$08/+09` and position at `+$04/+05`. |
| `$9190` | `0x0011A0` | `X=$06`, `Y=$0E` | Update horizontal velocity at `+$0C/+0D` and position at `+$06/+07`. |
| `sub_975B` | `$975B`, file `0x00176B` | X = position-pair offset; Y = one-byte acceleration offset | Add acceleration to velocity, then add the new velocity to position. |

ROM bytes at `$975B` are:

```text
86 ED B1 94 2A 2A 29 01 49 FF 18 69 01 AA B1 94 88 88 18 71 94 91 94
85 EC C8 8A 71 94 91 94 AA A4 ED A5 EC 18 71 94 91 94 8A C8 71 94 91 94 60
```

In the horizontal call, this routine writes the velocity pair with the
`STA (ram_0094_t02_data),Y` at `$9770` and `$9778` (file `0x001780` and
`0x001788`); it writes the X-position pair at `$9782` and `$9788` (file
`0x001792` and `0x001798`). The equivalent vertical call uses the same
instruction addresses with offsets `$08/$09` and `$04/$05`. The routine
sign-extends the one-byte acceleration according to its high bit, adds it to
the 16-bit Q8.8 velocity, then adds the updated velocity to the 16-bit Q8.8
position. The ROM-level recurrence is therefore:

```text
velocity[n+1] = velocity[n] + sign_extend_8(acceleration)
position[n+1] = position[n] + velocity[n+1]
```

For this specific animation, the captured inputs are nonnegative, so the
observed case reduces to `v += a; x += v`. The bytes `$0576/$0577` should not
be described as a 16-bit acceleration pair for this routine: F7 initializes
both bytes, but `$975B` reads the single byte at `+$0E` and clears/ignores the
adjacent `+$0F` byte in this path.

## Live write evidence

The same-input live write trace reports CPU write PCs after each store. For
the horizontal call, `$9772` is immediately after the store at `$9770`,
`$977A` after `$9778`, `$9784` after `$9782`, and `$978A` after `$9788`.
The callback rows show the target addresses and values:

| Source frame | Write sequence | Resulting motion state |
| ---: | --- | --- |
| 378 | F7 writes to `$0574..$0577` while `$94=$0568` | Start state: X=`$F6.00`, V=`$0280`, A=`$00`. |
| 379 | `$9770/72`: `$0574=$80`; `$9778/7A`: `$0575=$02`; `$9782/84`: `$056E=$80`; `$9788/8A`: `$056F=$F8` | X=`$F8.80`, V=`$0280`, A=`$00`. |
| 380 | same four stores: X fraction `$00`, integer `$FB`; velocity `$0280` | X=`$FB.00`. |
| 394 | Integrator first writes X=`$1E.00`, V=`$0280`; F7 then writes V=`$0000`, A=`$02` | The command change occurs after this frame's movement update. |
| 395 | `$0574=$02`, `$0575=$00`, then `$056E=$02`, `$056F=$1E` | X=`$1E.02`, V=`$0002`, A=`$02`. |
| 396 | `$0574=$04`, then X fraction `$06` | X=`$1E.06`, V=`$0004`, A=`$02`. |
| 418 | Integrator writes V=`$0030` and X=`$20.58`; then looped F7 resets V=`$0000` | Confirms the F7 setting is applied after this frame's movement update. |
| 419 | Integrator writes V=`$0002`, then X=`$20.5A` | The next frame uses the new `$02` acceleration. |

The instruction-level write order and post-command state confirm both the
record layout and the observed recurrence. The address `$056E/$056F` is the
X Q8.8 position (fraction byte first, signed integer byte second); the OAM
origin applies the already documented 2× coordinate scale.

## Godot implementation status

`scripts/opening/rom_runner_motion_record.gd` now reads the preserved `$6E`
animation bytes and ROM-derived tick table, checks the verified F1/F7 offsets
and loop boundary, builds the 16-byte record, and runs `$975B`'s update order.
The cold-start presenter uses its `screen_x()` projection instead of the old
capture-derived position formula. F7 frames 0/16 and the 24-tick repetition
are read from the extracted timing metadata; the live trace anchors tick zero
to source frame 378.

The source rule is now in Godot code, but its output is not yet validated
against a same-input Godot run. Compare record bytes, sprite OAM origin and
field-background raster output at frames 378–803. This implementation does
not resolve the field CHR split's subscanline pixel edge or claim exact final
displayed pixels.
