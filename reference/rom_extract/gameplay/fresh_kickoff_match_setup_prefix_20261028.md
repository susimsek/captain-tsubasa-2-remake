# Fresh-match preset-loader prefix — 28 Oct 2026

## Scope and source identity

`RomFreshMatchPresetLoaderPrefix` continues an explicit successful
`$810F->$A20C->$8112` result through the next caller instructions and executes
the `$8920` prefix to its first unresolved wait predicate. It does not read
FCEUX state, infer a frame delay, or claim an `$8920` return. The supplied ROM
SHA-256 is
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.

The extracted source package is
[`fresh_kickoff_match_setup/manifest.json`](fresh_kickoff_match_setup/manifest.json):

| Source span | File offset | SHA-256 |
|---|---:|---|
| `$8920-$893E` setup prefix through the `$78` branch | `0x000930` | `6f4f250519c608d82a9a58aa154e87070a7e6563341a4ec32ae78aa23ee51b12` |
| `$9DEE-$9E0B` multiply-by-X helper | `0x001DFE` | `274c1ff01f655cdaf900689a6b938df2f67d5d0c16713760e4d6074c5f684f79` |
| `$C4B9-$C4C7` fixed-bank mapper helper | `0x03C4C9` | `a87676276fdbfa7feeb8e1279d6e9cb220b436dd1edb788813801b2be1c48f12` |

The shared mapper-helper manifest also preserves the `$8938 JSR $C4B9` caller
bytes and validates this fifth callsite. Existing callsites remain checked.

## Executed fresh path

The verified `$A20C` result provides PC `$8112`, A/X/Y/P=`$03/$00/$84/$24`,
SP `$FD`, match index `$26=0`, current bank `$02`, and a complete stack page.
The caller executes `LDA #$00` and `JSR $8920`; `$8920` begins with `LDX #$13`
and calls `$9DEE`. Since caller A is zero, the hash-checked multiply routine
initializes `$EC/$ED` to zero and all eight shift/rotate iterations take its
`BCC` path. Its actual `$9E0B RTS` returns to `$8925` with A=0, X=`$13`, Y=0,
P=`$26`, and the nested stack balanced.

The rest of the verified prefix computes `$EC/$ED=$00/$BF`, saves prior bank
`$02` in `$EA`, then selects bank `$06` with `$8938->$C4B9`. That mapper helper
reaches its real RTS at `$C4C7` and returns to `$893B` with A/X/Y/P=`$87/$06/$00/$A4`.
The call also writes `$25=$06`, `$23=$87`, `$8000=$87`, and `$8001=$06`. The
source pointer is therefore `$BF00`; the code has not read the preset bytes yet.

## Exact stopping condition

The next ROM instructions are:

```text
$893B  LDA $78
$893D  BNE $893B
```

The preceding A20C result and `$8112-$8116` caller bytes do not establish
`$0078` or an event that clears it. The component stops before reading the
byte and reports both ROM successors: zero continues at `$893F`; nonzero loops
to `$893B`. It rejects an incoming `$78` value without source provenance, so
an emulator endpoint byte or assumed wait duration cannot silently unblock
the prefix. The remaining `$BF00` 19-byte copy, mapper restoration from `$EA`,
and the routine's `$8117` RTS are still open.

Focused Godot 4.7.2 verifier:

```sh
godot --headless --audio-driver Dummy --path . --script tools/diagnostics/verify_rom_fresh_match_preset_loader_prefix.gd --quit-after 5
```

It composes the A20F and A20C executors, verifies both nested real RTS returns,
checks CPU/RAM/stack/MMC3 effects, and stops at `$893B` after 232 no-interrupt
cycles from `$8112`. Its source-event ID is a verifier fixture. The result is a
bounded prefix only: it is not connected to `KickoffRouteRuntime`, does not
execute the `$78` resume, and does not complete the `$8920` call.
