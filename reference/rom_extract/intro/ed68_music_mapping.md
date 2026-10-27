# Opening cue `$ED $68` mapping

## Result

In the supplied Turkish ROM, the cutscene command `ED 68` queues runtime
sound ID `$68`. The sound driver decrements that ID and indexes its pointer
table; it resolves to a short sequence header in driver bank `$0C`, not to a
sound-test entry called “Sound 68”. The header has two immediately terminated
channels and one active channel. That channel selects envelope/macro `$12`,
sets its volume parameter to `$00`, and ends without requesting DPCM playback.

Target ROM SHA-256:
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
Offsets below include the 16-byte iNES header.

## Cutscene command to sequence header

1. The opening script at file offset `0x604C` contains `ED 68`. In the live
   capture, bank 3 is mapped at CPU `$A000–$BFFF`; the cutscene `$ED` handler
   reads the argument byte at `(script_ptr),Y` with `Y=1` and stores `$68` in
   the sound queue at `$0700–$0704`.
2. The bank-0C sound engine starts at CPU `$8000`, file `0x18010`. Its `$5C+`
   ID-range branch at CPU `$8058–$805B` restores the saved PRG bank from
   `$07FC` to MMC3 register 7. The second pass accepts IDs below `$72` and
   calls the pointer lookup at CPU `$8349`, file `0x18359`.
3. The lookup decrements `$68` to `$67`, doubles it to `$CE`, and indexes the
   little-endian table at CPU `$8BDA`. This selects CPU `$8CA8`, which maps to
   file offset `0x18CB8` in bank `$0C`. The bytes there are `E7 99`, giving
   pointer `$99E7`.
4. `$99E7` lies in bank `$0C`'s CPU `$8000–$9FFF` window. It maps to file
   offset `0x199F7`, whose header bytes are:

   ```text
   00 F0 99   01 F0 99   03 F1 99   FF
   ```

   These are channel ID / little-endian sequence-pointer records, terminated
   by `$FF`.

## Channels, macro, volume, and DPCM

- Channel `$00` points to `$99F0` (file `0x19A00`), whose first byte is `$FF`.
- Channel `$01` points to the same `$99F0` terminator.
- Channel `$03` points to `$99F1` (file `0x19A01`). Its stream is:

  ```text
  E0 12 E3 00 ED 02 84 09 93 06 FF
  ```

- Driver code at CPU `$8544` (file `0x18554`) handles `$E0`: it uses the
  argument as a two-byte index into the macro-pointer table at CPU `$8754`,
  file `0x18764`. For `$12`, table entry CPU `$8778` (file `0x18788`) is
  `AC 8A`, pointer `$8AAC`; the macro data begins at file `0x18ABC`.
- Driver code at CPU `$855F` (file `0x1856F`) handles `$E3`. When the global
  volume-scaling state permits it, the handler preserves the high nibble of
  the channel control byte and combines the supplied low-nibble value. This
  stream supplies `$00`.
- The `$ED 02` here is a **sound-sequencer** command handled by the music
  driver; it is distinct from the cutscene `$ED` command that queues `$68`.
- No `$F9`, `$FA`, or `$FB` DPCM command occurs in the active channel before
  its `$FF` terminator, and the other two channels terminate immediately.
  Therefore this `$68` sequence itself does not request DPCM playback. This
  conclusion is limited to the byte-checked sequence header and streams.

The sequence pointer, channel records, macro pointer, and stream bytes above
are direct checks against the supplied ROM. The annotated community driver
listing is used only as a navigation aid; its relevant instruction bytes were
checked against this ROM. The external Turkish music-system list establishes
the separate `$58` → Sound 00 address correspondence; no external `$68`
sound-test label is asserted here.

## Timing and audio status

The command's observed queue frame (frame 379 in the first captured pass, and
4578 in the repeated pass) comes from FCEUX. Cue timing in the current offline
audio timeline is still capture-anchored rather than produced by a complete
cutscene interpreter and source sound-driver scheduler. The Godot runtime
audio is not sample-exact; this mapping alone does not verify its rendered
waveform, timbre, or mix.
