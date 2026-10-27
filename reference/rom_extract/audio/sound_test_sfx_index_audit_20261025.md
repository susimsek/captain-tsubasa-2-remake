# SOUND 40–99 SFX pointer and opening-cue audit

Checked against the supplied Turkish ROM; emulator audio is not an input.

ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`

## ROM-derived table map

The driver lookup at bank `$0C` uses runtime queue ID minus one to index
the little-endian pointer table beginning at file `0x18BEA` (CPU `$8BDA`).
For each row below, the Turkish community post's candidate test ordinal,
table-word location, and target offset are checked against the actual ROM
bytes. The table location also yields the runtime queue ID shown here.

Japanese catalog labels are not used for SFX: the Japanese catalog only
labels BGM ordinals 00–39. SOUND 40–99 are treated here as ordinal IDs,
not as names or sound categories embedded in the ROM.

| SOUND ordinal | Runtime ID | Pointer word at file offset | Bytes → CPU pointer | Resolved sequence file offset | Channel route (channel → CPU stream pointer / file offset) |
|---:|---:|---:|---|---:|---|
| 40 | 0x03 | `0x18BEE` | `688E` → `$8E68` | `0x18E78` | 0 → $8E71 / 0x18E81; 1 → $8E71 / 0x18E81; 3 → $8E72 / 0x18E82 |
| 41 | 0x04 | `0x18BF0` | `898E` → `$8E89` | `0x18E99` | 0 → $8E92 / 0x18EA2; 1 → $8E92 / 0x18EA2; 3 → $8E93 / 0x18EA3 |
| 42 | 0x05 | `0x18BF2` | `CF8E` → `$8ECF` | `0x18EDF` | 0 → $8ED8 / 0x18EE8; 1 → $8ED8 / 0x18EE8; 3 → $8ED9 / 0x18EE9 |
| 43 | 0x06 | `0x18BF4` | `AD8F` → `$8FAD` | `0x18FBD` | 0 → $8FB6 / 0x18FC6; 1 → $8FB6 / 0x18FC6; 3 → $8FB7 / 0x18FC7 |
| 44 | 0x07 | `0x18BF6` | `148F` → `$8F14` | `0x18F24` | 0 → $8F1D / 0x18F2D; 1 → $8F47 / 0x18F57; 3 → $8F1E / 0x18F2E |
| 45 | 0x08 | `0x18BF8` | `A490` → `$90A4` | `0x190B4` | 0 → $90AD / 0x190BD; 1 → $90DD / 0x190ED; 3 → $90AE / 0x190BE |
| 46 | 0x09 | `0x18BFA` | `3592` → `$9235` | `0x19245` | 0 → $923E / 0x1924E; 1 → $923F / 0x1924F; 3 → $92DC / 0x192EC |
| 47 | 0x0A | `0x18BFC` | `CC96` → `$96CC` | `0x196DC` | 0 → $96D5 / 0x196E5; 1 → $96D6 / 0x196E6; 3 → $9721 / 0x19731 |
| 48 | 0x0B | `0x18BFE` | `4997` → `$9749` | `0x19759` | 0 → $9752 / 0x19762; 1 → $9752 / 0x19762; 3 → $9753 / 0x19763 |
| 49 | 0x0C | `0x18C00` | `8191` → `$9181` | `0x19191` | 0 → $918A / 0x1919A; 1 → $918B / 0x1919B; 3 → $91A4 / 0x191B4 |
| 50 | 0x0D | `0x18C02` | `EA91` → `$91EA` | `0x191FA` | 0 → $91F4 / 0x19204; 1 → $9230 / 0x19240; 3 → $91F3 / 0x19203 |
| 51 | 0x0E | `0x18C04` | `1D91` → `$911D` | `0x1912D` | 0 → $9126 / 0x19136; 1 → $9127 / 0x19137; 3 → $9157 / 0x19167 |
| 52 | 0x0F | `0x18C06` | `7990` → `$9079` | `0x19089` | 0 → $9082 / 0x19092; 1 → $9082 / 0x19092; 3 → $9083 / 0x19093 |
| 53 | 0x10 | `0x18C08` | `5A8F` → `$8F5A` | `0x18F6A` | 0 → $8FA4 / 0x18FB4; 1 → $8F89 / 0x18F99; 3 → $8F64 / 0x18F74 |
| 54 | 0x11 | `0x18C0A` | `BB8F` → `$8FBB` | `0x18FCB` | 0 → $8FC5 / 0x18FD5; 1 → $9041 / 0x19051; 3 → $9046 / 0x19056 |
| 55 | 0x12 | `0x18C0C` | `2D94` → `$942D` | `0x1943D` | 0 → $9436 / 0x19446; 1 → $9437 / 0x19447; 3 → $9444 / 0x19454 |
| 56 | 0x13 | `0x18C0E` | `6294` → `$9462` | `0x19472` | 0 → $946B / 0x1947B; 1 → $946C / 0x1947C; 3 → $9491 / 0x194A1 |
| 57 | 0x14 | `0x18C10` | `C694` → `$94C6` | `0x194D6` | 0 → $94CF / 0x194DF; 1 → $94D0 / 0x194E0; 3 → $94F9 / 0x19509 |
| 58 | 0x15 | `0x18C12` | `E49D` → `$9DE4` | `0x19DF4` | 0 → $9DED / 0x19DFD; 1 → $9DED / 0x19DFD; 3 → $9DEE / 0x19DFE |
| 59 | 0x16 | `0x18C14` | `FD9D` → `$9DFD` | `0x19E0D` | 0 → $9E06 / 0x19E16; 1 → $9E06 / 0x19E16; 3 → $9E07 / 0x19E17 |
| 60 | 0x17 | `0x18C16` | `5993` → `$9359` | `0x19369` | 0 → $9363 / 0x19373; 1 → $93A7 / 0x193B7; 3 → $93EB / 0x193FB |
| 61 | 0x18 | `0x18C18` | `5396` → `$9653` | `0x19663` | 0 → $96A2 / 0x196B2; 1 → $9678 / 0x19688; 3 → $965D / 0x1966D |
| 62 | 0x19 | `0x18C1A` | `7F9E` → `$9E7F` | `0x19E8F` | 0 → $9E88 / 0x19E98; 1 → $9E88 / 0x19E98; 3 → $9E89 / 0x19E99 |
| 63 | 0x1A | `0x18C1C` | `7797` → `$9777` | `0x19787` | 0 → $9780 / 0x19790; 1 → $9781 / 0x19791; 3 → $978F / 0x1979F |
| 64 | 0x1B | `0x18C1E` | `1E9B` → `$9B1E` | `0x19B2E` | 0 → $9B27 / 0x19B37; 1 → $9B28 / 0x19B38; 3 → $9B46 / 0x19B56 |
| 65 | 0x1C | `0x18C20` | `D39E` → `$9ED3` | `0x19EE3` | 0 → $9EDC / 0x19EEC; 1 → $9EE9 / 0x19EF9; 3 → $9EDD / 0x19EED |
| 66 | 0x1D | `0x18C22` | `CD9A` → `$9ACD` | `0x19ADD` | 0 → $9AD7 / 0x19AE7; 1 → $9AFB / 0x19B0B; 3 → $9B04 / 0x19B14 |
| 67 | 0x1E | `0x18C24` | `509B` → `$9B50` | `0x19B60` | 0 → $9B5A / 0x19B6A; 1 → $9B7A / 0x19B8A; 3 → $9B59 / 0x19B69 |
| 68 | 0x1F | `0x18C26` | `9D9B` → `$9B9D` | `0x19BAD` | 0 → $9BA6 / 0x19BB6; 1 → $9BA7 / 0x19BB7; 3 → $9BA6 / 0x19BB6 |
| 69 | 0x22 | `0x18C2C` | `F79E` → `$9EF7` | `0x19F07` | 0 → $9F00 / 0x19F10; 1 → $9F00 / 0x19F10; 3 → $9F01 / 0x19F11 |
| 70 | 0x23 | `0x18C2E` | `2D95` → `$952D` | `0x1953D` | 0 → $9536 / 0x19546; 1 → $9537 / 0x19547; 3 → $9548 / 0x19558 |
| 71 | 0x24 | `0x18C30` | `5795` → `$9557` | `0x19567` | 0 → $9561 / 0x19571; 1 → $95A7 / 0x195B7; 3 → $95AE / 0x195BE |
| 72 | 0x25 | `0x18C32` | `EE9C` → `$9CEE` | `0x19CFE` | 0 → $9CF7 / 0x19D07; 1 → $9CF7 / 0x19D07; 3 → $9CF8 / 0x19D08 |
| 73 | 0x26 | `0x18C34` | `589D` → `$9D58` | `0x19D68` | 0 → $9D61 / 0x19D71; 1 → $9D61 / 0x19D71; 3 → $9D62 / 0x19D72 |
| 74 | 0x27 | `0x18C36` | `739D` → `$9D73` | `0x19D83` | 0 → $9D7D / 0x19D8D; 1 → $9DA8 / 0x19DB8; 3 → $9DD3 / 0x19DE3 |
| 75 | 0x28 | `0x18C38` | `559A` → `$9A55` | `0x19A65` | 0 → $9A5E / 0x19A6E; 1 → $9A5E / 0x19A6E; 3 → $9A5F / 0x19A6F |
| 76 | 0x29 | `0x18C3A` | `D697` → `$97D6` | `0x197E6` | 0 → $97DF / 0x197EF; 1 → $97E0 / 0x197F0; 3 → $97F7 / 0x19807 |
| 77 | 0x2A | `0x18C3C` | `779A` → `$9A77` | `0x19A87` | 0 → $9A80 / 0x19A90; 1 → $9A81 / 0x19A91; 3 → $9A8F / 0x19A9F |
| 78 | 0x2B | `0x18C3E` | `5394` → `$9453` | `0x19463` | 0 → $945C / 0x1946C; 1 → $9437 / 0x19447; 3 → $945D / 0x1946D |
| 79 | 0x2C | `0x18C40` | `0398` → `$9803` | `0x19813` | 0 → $980C / 0x1981C; 1 → $980C / 0x1981C; 3 → $980D / 0x1981D |
| 80 | 0x2D | `0x18C42` | `9A9A` → `$9A9A` | `0x19AAA` | 0 → $9AA4 / 0x19AB4; 1 → $9AB2 / 0x19AC2; 3 → $9AC0 / 0x19AD0 |
| 81 | 0x2E | `0x18C44` | `9D97` → `$979D` | `0x197AD` | 0 → $97A7 / 0x197B7; 1 → $97B7 / 0x197C7; 3 → $97C7 / 0x197D7 |
| 82 | 0x2F | `0x18C46` | `1B98` → `$981B` | `0x1982B` | 0 → $9825 / 0x19835; 1 → $9839 / 0x19849; 3 → $9840 / 0x19850 |
| 83 | 0x30 | `0x18C48` | `139C` → `$9C13` | `0x19C23` | 0 → $9C1C / 0x19C2C; 1 → $9C1C / 0x19C2C; 3 → $9C1D / 0x19C2D |
| 84 | 0x5F | `0x18CA6` | `469F` → `$9F46` | `0x19F56` | 0 → $9F4F / 0x19F5F; 1 → $9F4F / 0x19F5F; 3 → $9F50 / 0x19F60 |
| 85 | 0x60 | `0x18CA8` | `7E98` → `$987E` | `0x1988E` | 0 → $9893 / 0x198A3; 1 → $9894 / 0x198A4; 3 → $989D / 0x198AD; 4 → $9893 / 0x198A3; 5 → $9893 / 0x198A3; 6 → $9893 / 0x198A3; 7 → $9893 / 0x198A3 |
| 86 | 0x61 | `0x18CAA` | `BD98` → `$98BD` | `0x198CD` | 0 → $98D2 / 0x198E2; 1 → $993B / 0x1994B; 3 → $98D3 / 0x198E3; 4 → $98D2 / 0x198E2; 5 → $98D2 / 0x198E2; 6 → $98D2 / 0x198E2; 7 → $98D2 / 0x198E2 |
| 87 | 0x62 | `0x18CAC` | `4499` → `$9944` | `0x19954` | 0 → $994D / 0x1995D; 1 → $994D / 0x1995D; 3 → $994E / 0x1995E |
| 88 | 0x63 | `0x18CAE` | `8E99` → `$998E` | `0x1999E` | 0 → $9998 / 0x199A8; 1 → $99A6 / 0x199B6; 3 → $9997 / 0x199A7 |
| 89 | 0x64 | `0x18CB0` | `CB9C` → `$9CCB` | `0x19CDB` | 0 → $9CD4 / 0x19CE4; 1 → $9CD5 / 0x19CE5; 3 → $9CD4 / 0x19CE4 |
| 90 | 0x65 | `0x18CB2` | `B499` → `$99B4` | `0x199C4` | 0 → $99BD / 0x199CD; 1 → $99BE / 0x199CE; 3 → $99D5 / 0x199E5 |
| 91 | 0x66 | `0x18CB4` | `FC99` → `$99FC` | `0x19A0C` | 0 → $9A05 / 0x19A15; 1 → $9A06 / 0x19A16; 3 → $9A05 / 0x19A15 |
| 92 | 0x68 | `0x18CB8` | `E799` → `$99E7` | `0x199F7` | 0 → $99F0 / 0x19A00; 1 → $99F0 / 0x19A00; 3 → $99F1 / 0x19A01 |
| 93 | 0x69 | `0x18CBA` | `9C9F` → `$9F9C` | `0x19FAC` | 0 → $9FA5 / 0x19FB5; 1 → $9FA5 / 0x19FB5; 3 → $9FA6 / 0x19FB6 |
| 94 | 0x6A | `0x18CBC` | `359C` → `$9C35` | `0x19C45` | 4 → $9C42 / 0x19C52; 5 → $9C60 / 0x19C70; 6 → $9C41 / 0x19C51; 7 → $9C67 / 0x19C77 |
| 95 | 0x6B | `0x18CBE` | `CA9F` → `$9FCA` | `0x19FDA` | 0 → $9FD3 / 0x19FE3; 1 → $9FD3 / 0x19FE3; 3 → $9FD4 / 0x19FE4 |
| 96 | 0x30 | `0x18C48` | `139C` → `$9C13` | `0x19C23` | 0 → $9C1C / 0x19C2C; 1 → $9C1C / 0x19C2C; 3 → $9C1D / 0x19C2D |
| 97 | 0x6D | `0x18CC2` | `089D` → `$9D08` | `0x19D18` | 0 → $9D11 / 0x19D21; 1 → $9D12 / 0x19D22; 3 → $9D36 / 0x19D46 |
| 98 | 0x6E | `0x18CC4` | `5D9E` → `$9E5D` | `0x19E6D` | 0 → $9E67 / 0x19E77; 1 → $9E72 / 0x19E82; 3 → $9E66 / 0x19E76 |
| 99 | 0x6F | `0x18CC6` | `219E` → `$9E21` | `0x19E31` | 0 → $9E2B / 0x19E3B; 1 → $9E37 / 0x19E47; 3 → $9E2A / 0x19E3A |

Verified 60/60 pointer words and 189 channel-pointer destinations. Each target header was parsed through its `$FF` terminator; raw header and
stream-prefix bytes are preserved in the adjacent JSON audit.

## SOUND IDs queued during the same-input opening trace

These are runtime queue IDs read from the existing source-frame capture,
not sound-test ordinals. The output route is independently resolved through
the target ROM's `$8BDA` table. Repeated frames are listed individually.

| Source frame | Runtime ID | Test ordinal, if mapped | Queue origin evidence | Sequence route |
|---:|---:|---|---|---|
| 282 | 0x58 | BGM 00 | rom command verified frame capture anchored | `0x1F7BD` (`$B7AD`) |
| 379 | 0x68 | SFX 92 | rom command verified frame capture anchored | `0x199F7` (`$99E7`) |
| 1048 | 0x28 | SFX 75 | capture observed unmapped | `0x19A65` (`$9A55`) |
| 1068 | 0x28 | SFX 75 | capture observed unmapped | `0x19A65` (`$9A55`) |
| 1088 | 0x28 | SFX 75 | capture observed unmapped | `0x19A65` (`$9A55`) |
| 1108 | 0x0E | SFX 51 | capture observed unmapped | `0x1912D` (`$911D`) |
| 1510 | 0x02 | empty sequence | capture observed unmapped | `0x18E6B` (`$8E5B`) |
| 1779 | 0x0E | SFX 51 | capture observed unmapped | `0x1912D` (`$911D`) |
| 1839 | 0x09 | SFX 46 | capture observed unmapped | `0x19245` (`$9235`) |
| 2368 | 0x07 | SFX 44 | capture observed unmapped | `0x18F24` (`$8F14`) |
| 4481 | 0x58 | BGM 00 | rom command verified frame capture anchored | `0x1F7BD` (`$B7AD`) |
| 4578 | 0x68 | SFX 92 | rom command verified frame capture anchored | `0x199F7` (`$99E7`) |
| 4661 | 0x01 | stop-all control | rom store verified frame capture anchored | `0x18E52` (`$8E42`) |

Runtime `$02` resolves to a header whose four channel pointers all land on
`$FF` terminators, so it is a queued empty/silent sequence; no sound-test
ordinal is listed for it. Runtime `$01` resolves to the driver's stop-all
sentinel; it is a control route, not an SFX entry. Other queue writes remain
capture-observed where the source command producer has not yet been mapped.

## Evidence and limits

- External pointer/target index: [TsubasaTR, CT2 music-system post](https://tsubasatr.net/konu-ct2-muzik-sistemi-nasil-calisir.html).
- The ROM checksum, pointer bytes, address translation, header records, and channel-stream pointer prefixes are checked locally by `tools/audio/audit_sound_test_sfx_index.py`.
- The opening frame/ID list comes from `reference/diagnostics/audio/opening_timeline_rom_driver_pre_start_tail_4661f.json`; it does not establish all queue producers as cutscene commands.
- This is pointer/route metadata, not a full SFX command decoder, PCM dump, or runtime audio asset. It does not add Japanese track names to the ROM-derived data.
