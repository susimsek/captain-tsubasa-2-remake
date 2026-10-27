# Opening runner motion trace

ROM source: the supplied Turkish ROM, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
File offsets below include the 16-byte iNES header. RAM snapshots are
observation evidence; no captured image is used as a runtime asset.

## `F8 0A` is a reset command

The bank-0 cutscene vector table at CPU `$8545` (file `0x000555`) sends F8 to
`$87F7` (file `0x000807`). At that handler, the operand is read into `$ED`,
bank 2 is mapped, and `$A212` dispatches the subroutine number. Number `0A`
selects `$A602` (bank-2 file `0x004612`), whose bytes are:

```text
A9 00 85 0D 85 0E A9 02 60
```

It clears `$000D` and `$000E`, returns `02`, and the F8 handler advances the
cutscene stream by two bytes. In the opening script this is the command at
CPU `$A036` (file `0x006046`), immediately before F3. The traced effect is a
one-time state reset; it does not move the runner each frame.

## Animation `6E` and observed trajectory

Animation `6E` begins at CPU `$A0C6` (bank 10, file `0x0140D6`). Its command
sequence sets origin with `F1 1E F6` (`Y=30`, `X=246`), then issues `F7 05 00
00` at `$A0CA`. The later repeated segment begins at `$A0DD`; its `F7 00 00
02` at `$A0E0` accompanies the runner's accelerating movement. The animation
timing decode in `animation_timing_entry.json` gives the four sprite frames
two ticks each through tick 15, then six ticks each on a 24-tick cycle from
tick 16.

RAM `$056E` is the fractional byte and `$056F` the signed integer byte of the
runner's observed Q8.8 X origin. The OAM origin is twice that coordinate.
Consecutive snapshots show the initial segment advancing by `$0280` per
frame (2.5 Q8.8 coordinate units, or 5 screen pixels). After the second F7
settings point, the fractional increment rises by 2 each frame and wraps into
the integer byte. This matches an acceleration phase that restarts with the
24-tick animation cycle:

| Frame | `$056F.$056E` | Derived screen X | Evidence |
| ---: | ---: | ---: | --- |
| 378 | `F6.00` | −20 | Initial fixed-step segment |
| 379 | `F8.80` | −15 | +5 px |
| 380 | `FB.00` | −10 | +5 px; exact OAM match, 42/42 |
| 381 | `FD.80` | −5 | +5 px |
| 382 | `00.00` | 0 | +5 px |
| 394 | `1E.00` | 60 | Acceleration segment starts |
| 395 | `1E.02` | 60 | Fractional increment +2 |
| 396 | `1E.06` | 60 | Increment +4 |
| 397 | `1E.0C` | 60 | Increment +6 |
| 398 | `1E.14` | 60 | Increment +8 |
| 399 | `1E.1E` | 60 | Increment +10 |
| 400 | `1E.2A` | 60 | Next 24-tick phase begins |
| 418 | `20.58` | 64 | Exact decoded sprite OAM match |
| 442 | `22.B0` | 69 | Exact decoded sprite OAM match, 41/41 |
| 466 | `25.08` | 74 | Repeated cycle sample |
| 490 | `27.60` | 79 | Repeated cycle sample |
| 803 | `45.DA` | 139 | Exact decoded sprite OAM match, 42/42 |

Coordinates are signed Q8.8 values and screen X is `floor(2 × coordinate)`.
For the acceleration phase, adding increments 2, 4, …, 48 gives 600/256
coordinate units over 24 frames, or 4.6875 screen pixels. The OAM samples at
frames 380, 442, and 803 are independently checked against the ROM sprite
descriptors by `reference/diagnostics/intro_sprite_oam_matches.json`; the
decoded sprite frame and origin both match all listed entries. `intro-sprite-vm.md`
documents the descriptor formula and broader sample set.

The earlier frame-manifest controller did not encode the changing runner
positions. `scenes/main.tscn` now uses the source-command presenter and
ROM-derived animation frames, but its runner origin still comes from a
capture-derived formula. The new live bridge trace supplies the ROM record and
integrator needed to replace that formula; the Godot conversion and same-input
OAM/raster comparison remain work in progress.

## F7 command handler and motion state

The bank-0 dispatch code around CPU `$92D8` (file `0x0012E8`) reads the
F0–FF table at CPU `$92E5` (file `0x0012F5`). File offsets include the
16-byte iNES header, so in this bank `file = CPU - $8000 + $10`. The F7
return word at CPU `$92F3..$92F4` (file `0x001303..0x001304`) is `$93A6`.
The dispatch uses `RTS`, which enters at `$93A7` (file `0x0013B7`). The
handler bytes are:

```text
A0 01 B1 92 4A 4A 4A 4A 4A A0 09 91 94 29 04 D0 0F
6A 88 91 94 A0 02 B1 92 A0 0A 91 94 4C DE 93
B1 94 09 F8 91 94 A9 00 6A 88 91 94 A0 02 A9 00 38
F1 92 A0 0A 91 94 4C C1 94
```

The first F7 parser at `$93A7` reads operand 0 at `($92),Y` with `Y=1`, shifts
it right five times, and writes the result at `($94),$09`. If bit 2 of that
shifted value is clear, `AND #$04` leaves a masked accumulator; the handler
rotates that through carry into `+$08`, writes operand 1 to `+$0A`, and jumps
to `$93DE`. If that bit is set, its alternate path writes the packed/sign
form at `+$08..+$0A` and jumps to `$94C1`, skipping the motion-field parser
described next.

For the two observed runner commands (`F7 05 00 00` and `F7 00 00 02`), the
first parser takes the normal path. Its jump at `$93C4` goes to `$93DE`
(file `0x0013EE`), where `A0 01` starts the second parser. That code reads
operand 0 again at `$93E0`, masks its low nibble, shifts it right once, and
stores the result at record `+$0D` (`STA ($94),Y` at `$93E7`). If the
following bit-2 test is clear, it rotates the masked accumulator through
carry into `+$0C` (`STA ($94),Y` at `$93EF`). It then sets `Y=3` at `$93F1`
and reads operand 2 with `LDA ($92),Y` at `$93F3..$93F4` (file
`0x001403..0x001404`); after setting `Y=$0E`, `STA ($94),Y` at
`$93F7..$93F8` (file `0x001407..0x001408`) writes it to `+$0E`. The alternate
branch sign-extends `+$0D` with `$F8`, writes its carry-derived fractional
byte to `+$0C`, and stores `0 - operand[2]` at `+$0E` at `$9411`. The normal
path stores operand 2 at `+$0E` at `$93F7`. Both paths then reach `$9413`,
which clears `+$0B` and `+$0F`, sets flag bit `$20` at `+$00`, loads A with
`$04`, and jumps to `$94AE`.

This accounts for the observed motion fields directly. For `F7 05 00 00`,
operand 0's low nibble `$05` shifts to `$02` with carry set; `AND #$04` then
clears the accumulator, and `ROR` rotates the carry into bit 7. The handler
therefore writes `+$0D=$02`, `+$0C=$80`, and `+$0E=$00`, matching the
source-frame-378 record. For `F7 00 00 02`, it writes `+$0C=$00`,
`+$0D=$00`, and `+$0E=$02`, matching the source-frame-394 record.

The earlier end-of-frame snapshots alone did not prove the destination, since
`$94/$95` are reused afterward (for example, the frame-378 snapshot has
`$94/$95 = $E8/$05`). The subsequent live store trace resolves that gap:
F7-time `$94/$95` is `$0568`, and the next-frame integrator writes the motion
fields through `$975B`. See `runner_motion_live_bridge.md` for callback PCs,
destination bytes, and same-input frame states.

The RAM record at `$0568` supplies a separate, strongly constrained motion
model. In the captured runner record, `+06/+07` is the Q8.8 position,
`+0C/+0D` tracks velocity, and `+0E` is the one-byte signed acceleration read
by the ROM integrator. The live source trace in
[`runner_motion_live_bridge.md`](runner_motion_live_bridge.md) verifies the
record offsets and update order:

```text
v[n+1] = v[n] + a
x[n+1] = x[n] + v[n+1]
```

For example, at frame 394 the record has position `$1E00`, velocity `$0000`,
and increment `$0002`. Frame 395 has position `$1E02` and velocity `$0002`;
frame 396 has position `$1E06` and velocity `$0004`. During the earlier
constant-speed phase, frame 378 has position `$F600`, velocity `$0280`, and
acceleration `$00`; subsequent position changes are `$0280` per frame. F7
initializes the source-verified velocity/acceleration fields, and `$975B`
executes the signed-acceleration update before adding the new velocity to
position.

Therefore: the F7 dispatch, its live `$0568` destination, and `$975B` update
routine are source-verified. Godot still needs to replace its capture-derived
position projection with this record and compare the resulting sprite/OAM
placement at the sampled frames.

## Next integration step

The source-command presenter now uses `scripts/opening/rom_runner_motion_record.gd`
instead of the old capture-derived projection. It reads the verified `$6E`
F1/F7 byte stream and tick schedule, then applies the `$975B` state update.
Next compare record bytes and OAM origin at frames 378–803, followed by PPU
layer/raster timing, before treating the runner segment as source-faithful.
