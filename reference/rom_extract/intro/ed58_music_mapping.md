# Opening cue `$ED $58` music mapping

## Result

In the supplied Turkish ROM, opening command `ED 58` queues runtime sound ID
`$58`. The sound driver does **not** treat `$58` as the community sound-test
label “Sound 58”: it decrements the runtime ID, indexes a pointer table, and
resolves the cue to the sequence header at ROM file offset `0x1F7BD`. The
Turkish music-system reference calls that pointer entry “Sound 00”; the
byte-verified disassembly labels the target as the intro/opening music. Thus
the opening cue maps to Sound 00 through a real table lookup.

## Byte and trace path

Target ROM: `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
Offsets below include the 16-byte iNES header.

1. The live cutscene dispatch trace records opcode `$ED`, argument `$58`,
   pointer `$A02A` at source frame 282. Bank 3 maps `$A000–$BFFF`; local file
   offset `0x603A` contains the same `ED 58` bytes. The handler at bank 0
   `$85EC–$85FF` reads the argument at `(script_ptr),Y` with `Y=1` and writes
   `$58` to the first free sound queue slot, `$0700–$0704`. In the saved queue
   trace, `$0700` is `$58` at frame 282.
2. The bank-0C sound-driver update begins at CPU `$8000`, file `0x18010`. Its
   local bytes compare each queued value against `$32`, `$44`, `$51`, and
   `$5C`; `$58` takes the `$51–$5B` branch, which selects bank `$0F` for MMC3
   register 7 (the PRG window `$A000–$BFFF`). The existing synchronized bus
   capture records register-7 writes of `$0F` during this driver pass.
3. The driver's second pass reaches `$8349` for a nonzero queued sound ID.
   Local bytes at file `0x18359` begin `86 F5 A9 00 9D 00 07 88 98 0A A8`:
   it saves X, clears that queue slot, then executes `DEY; TYA; ASL; TAY`.
   At `$8354` (`0x18364`) it reads the little-endian pointer from `$8BDA,Y`.
4. `$58 - 1 = $57`; doubled, the index is `$AE`. Therefore the selected
   pointer entry is `$8BDA + $AE = $8C88`. Bank 0C's `$8000` window maps to
   file offset `0x18010`, so CPU `$8C88` is file `0x18C98`. The local bytes
   there are `AD B7 59 AC ...`; the first word is `$B7AD`.
5. Bank `$0F` maps `$A000–$BFFF` from file base `0x1E010`. Thus `$B7AD` maps
   to `0x1E010 + ($B7AD-$A000) = 0x1F7BD`. Local bytes at that offset are
   `04 BA B7 05 BD BA 06 5E BD 07 3F BF FF`: a channel directory for IDs
   `$04–$07`, with the header terminator `$FF`.

The saved queue trace corroborates consumption: at frame 283, its queue-store
callback reports CPU PC `$8350` and `$0700=$00`; this is the instruction after
the driver's `$834D STA $0700,X`. The synchronized bus capture shows the
driver's register-7 selection/write for bank `$0F`. These are execution
observations from the existing silent replay. The bus log does not record ROM
read operands, so the final `$8BDA → $B7AD` read is established by the local
ROM code and data bytes rather than a captured CPU-read event.

## Why `$58` and “Sound 00” differ

The Turkish community list gives `Sound 00 → sequence 0x1F7BD, pointer entry
0x18C98`; both addresses and the pointer word `$B7AD` match this ROM. The
pointer table in driver bank 0C is indexed by the runtime queue ID minus one.
That explains why runtime `$58` uses file `0x18C98`, even though the community
music list calls it Sound 00. Do not pass `$58` to a separate sound-test
ordinal lookup without preserving this driver mapping.

The community list also has a row named “Sound 58” at a different table
address (`0x18C12`); that label is not the runtime queue byte `$58` in this
opening script. The two numbering systems are distinct. The Japanese music
catalog independently identifies the opening-demo BGM as “Opening,” often
called sound-test “SOUND 00,” and says it ends with the transition to the
title screen. These names corroborate the local mapping but do not replace the
ROM-derived lookup above.

The Chinese Hack CT2 release notes advertise Tecmo music extraction,
conversion, and music-index conversion. They support treating index
translation as a real part of the workflow, but publish no `$58 → Sound 00`
mapping; that relationship above is established from this ROM's code/data and
the Turkish address list.

## References

- Turkish CT2 music-system post: [pointer and sequence address list](https://tsubasatr.net/konu-ct2-muzik-sistemi-nasil-calisir.html).
- Japanese CT2 music catalog: [Opening (Captain Tsubasa II)](https://w.atwiki.jp/gamemusicbest100/pages/6979.html).
- Chinese Hack CT2 release notes: [music extraction/conversion and index-conversion features](https://daymoe.com/rom/Hack%20CT2.html).
- Annotated driver listing used as a navigation aid: [`bank_8C.asm`](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/blob/master/bank_8C.asm) and music labels in [`bank_8F.asm`](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/blob/master/bank_8F.asm). The relevant instructions and data were checked against the supplied Turkish ROM bytes above; the other ROM's labels alone are not treated as proof.
