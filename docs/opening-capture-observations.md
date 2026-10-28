# Opening Capture: Observed Flow and Limitations

## Capture scope

- The source session in reference/opening_capture/capture.log contains 2,400 emulator frames (about 40 seconds). Screenshot comparison copies are under reference/opening_capture/frames_png/.
- The input_timeline.csv recording contains only A-button presses: frames 89, 239, 389, 539, 689, 839, 989, 1139, 1289, 1439, 1589, 1739, 1889, 2039, 2189, and 2339. Each press lasts one frame. There are no direction, B, Start, or Select presses.
- emulator_ppu/index.csv lists 759 changed PPU states. These are not frame-by-frame video; each raw file contains 8,192 bytes of pattern-table data and 4,128 bytes of nametable/palette data.

## Sparse PPU snapshot timestamps

reference/opening_reference_capture/ppu_index.csv indexes changed PPU byte
states. The capture script reads these bytes after every emulator frame and
writes a file only when the state differs from the previous reading.
Consequently, ppu_snapshot_frame for a frame identifies the last frame on which
the raw file changed. The absence of a new file on a later frame does not by
itself mean the bytes are missing or stale. The package metadata fields
ppu_byte_state_valid_from_frame, ppu_byte_state_valid_through_frame, and
ppu_byte_state_applicable_at_capture_frame identify the interval during which
that unchanged state applies.

This interval validates only the applicability of the sampled
pattern/nametable/palette bytes. It does not establish the raster timing of PPU
writes within a frame, CHR bank changes, the $2002 latch state, or when physical
OAM is copied for display. Until those are resolved, frame composition must not
be treated as pixel-accurate. The ppu_snapshot_timestamp_mismatches metric
counts records where the target-frame timestamp differs from the last PPU
file's timestamp; ppu_byte_state_inapplicable_frames counts sources that
cannot be assigned to a valid interval.

For OAM, the packaged source RAM frame is one frame earlier than the target
frame (ram_source_frame_offset: -1). The file provides OAM shadow-memory bytes;
oam_display_timing_verified_at_capture_frame: false explicitly records that
they have not been timing-aligned with the physical OAM used for display.

## Observed screens

Frame boundaries follow the changed screen samples listed in
screen_timeline.csv and PNG inspection. The screen may remain unchanged between
samples, or animation frames may be skipped by the sampling interval.

| Approximate frame range | Visible content | Evidence / note |
|---|---|---|
| 0–139 | Soccer-field animation and a dialogue box at the bottom; the text begins with “Kosuu...” on frame 0 | Frame 0 may be a stale image from before FCEU.poweron(); it is not evidence of a cold start. |
| 140–379 | Flashing TECMO THEATER logo on a black background | The FCEUX “Power on” on-screen message also appears on frame 140; it is not game graphics. |
| 380–809 | Field lines and a player dribbling/kicking the ball; dialogue text appears gradually in the lower box | Multiple dialogue lines are visible in the sample at frame 690. |
| 810–1025 | Black transition, followed by a blue portrait area and player information text | Around frame 880, “Oozora Tsubasa / Brazil / Sao Paulo FC MF” is readable. |
| 1026–1547 | Hyuga kicking animation, dialogue box, and gradually revealed text | Sample frames show a dialogue line about Hyuga-kun and a sudden Tiger Tackle. |
| 1548–1779 | Hyuga portrait and information card on a black background | “Hyuga Kojiro” and “Toho ... CF” are readable at frame 1610. |
| 1780–2117 | Shot animation, colored background transitions, and lower dialogue box | A dialogue line about the finishing Twin Shot appears progressively in the samples. |
| 2118–2399 | Transition to Taro Misaki's portrait/information card; the session ends here | “Taro Misaki / Nankatsu High School MF” is readable. The title or selection menu does not appear. |

## Conclusion

This capture shows the opening animation followed by character and dialogue
sequences. It does **not** capture the KICK OFF / CONTINUE title menu or a
team/selection screen. Because A is pressed automatically every 150 frames,
this recording cannot establish whether transitions depend on user input or
the game's own timing. The possible stale image on frame 0 and the FCEUX
on-screen display mean this is not a pixel-accurate clean-power-on reference.

To determine the exact flow for the Godot opening/title/target-selection
screens, make a new FCEUX recording that genuinely power-cycles the ROM, starts
capturing after reset, and records timestamped manual or controlled input. Do
not press A automatically before reaching the title menu. Existing PNGs are
observation material only; they must not replace original assets.

## OAM shadow-memory assessment

The ram_states/ram_NNNNN.bin samples cover CPU RAM $0000–$07FF. Their
$0200–$02FF region strongly resembles the NES OAM layout of 64 four-byte
entries (Y, tile, attribute, X): samples usually contain 39–64 visible entries,
tile/attribute values cluster like sprite data, and changing X/Y coordinates
match the animation in the image. Examples include field-player sprites around
frame 803, Tsubasa's portrait around frame 880, Hyuga's kick around frame 1290,
and character portraits around frames 1610 and 2190.

**Conclusion:** Reconstructing OAM shadow memory from emulator captures is
likely feasible. The per-frame $0200–$02FF dumps provide sprite order, position,
tile, and attribute fields. They have not yet been verified as direct dumps of
the PPU's physical OAM. For confirmation, compare the same frames with the
FCEUX OAM/Sprite Viewer or the emulator's OAM memory view, and use the mapped
CHR pattern data and palette as well. A raw RAM capture is not a complete
sprite image by itself.

This inspection covers 2,397 2 KiB records in ram_states/ram_*.bin (frames
0–2399); 318 distinct contents were observed in page $0200–$02FF. During this
inspection, the shared ram_state_index.csv had begun being regenerated by a
new capture and contained only its header. Frame mapping was therefore taken
from the NNNNN filenames. The previous capture's index file is not currently
available.

## Current intro-to-title observations

- Two clean power-cycle captures are available, and each uses its own frame
  origin. In the automated probe under reference/cold_start_title_input_probe/,
  Start is held on frames 4700–4711 and the title appears on frame 4731. In the
  capture under reference/opening_reference_capture/input_timeline.csv, Start
  is held on frames 4661–4667; the transition in the Godot manifest plays one
  intro frame followed by 30 black frames, then shows the menu on frame 4692.
  Do not treat frame numbers from these separate captures as interchangeable.
- The selection marker is beside KICK OFF when the title first appears.
  Twelve-frame A or B trials did not change the screen. About 15 frames after
  confirming with Start, the black transition begins and the next story flow
  follows.
- A long story/dialogue sequence begins after KICK OFF. This milestone ends at
  the title menu; neither KICK OFF nor CONTINUE is confirmed, and later screens
  are out of scope.
- The recording is useful for aligning PPU/RAM state and input on the title
  frame. PNG/GD/WAV files are not Godot runtime assets.

## Missing PPU register/mapper history

Current PPU snapshots contain end-of-frame memory, but not the timing of
in-frame PPUCTRL, PPUSCROLL, or MMC3 CHR-bank register writes. The
tools/capture_ppu_register_writes.lua tool was added to capture these writes in
a separate FCEUX CSV. Its cpu_cycles column helps resolve in-frame raster
effects, but it is not a complete PPU raster recording by itself.
