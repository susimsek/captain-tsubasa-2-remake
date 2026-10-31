# Slot-$09 bank-$18 worker `$8779` live zero-branch audit — 2026-10-29

## Finding

The source-route result from the preceding `$86F8->$8722 RTS` reaches the
fixed-bank caller at `$EBB3` with `$0534=$00`. The caller reselects the
`$18/$19` PRG pair and invokes `$8006->$8779`. The worker reads `$0534`, takes
the `$87A3 RTS` branch, and returns to `$EBC5`. A focused source-specific
executor and verifier now model that route result. The executor stops at
`$EBC5`; it does not read or execute the next root-loop body or the following
`$8009->$87E6` worker.

## Evidence classes

### ROM-derived

The supplied ROM is SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`, iNES
1.0, mapper 4, with a 16-byte header and no trainer. The hash-checked bytes and
bank/file mapping for this audit are listed in
[`slot09_8779_worker/manifest.json`](slot09_8779_worker/manifest.json).

| CPU span | Bank | File offset | Length | SHA-256 | Role |
| --- | ---: | ---: | ---: | --- | --- |
| `$EBB3-$EBC4` | `$1F` fixed | `0x03EBC3` | 18 | `5b1a5142b268e834aafe619d51b6c51a80e71c99ec269641ecb61cc6c0d50883` | Caller continuation through `JSR $8006` |
| `$8006-$8008` | `$18` | `0x030016` | 3 | `ec20595812bf088382eaa136f2bbf5cf9429467653f948041a7684a34e1b4fab` | `JMP $8779` vector |
| `$8779-$87A3` | `$18` | `0x030789` | 43 | `407f2feb4cedb61c07aab10b9b39e7775d9891b04afeaa16b43ad459aeeab511` | Worker entry, branch, supported RTS, and bounded adjacent source bytes |
| `$CE2D-$CE49` | `$1E` fixed | `0x03CE3D` | 29 | `6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c` | MMC3 register-pair helper called by the root |

The source sequence is:

1. `$EBB3 PHA`; load `$18` and `$19` into `$0024/$0025`.
2. `$EBBE JSR $CE2D`; the helper selects MMC3 registers 6 and 7, writes the
   pair values, and returns to `$EBC1`.
3. Restore A and call `$8006`; the bank-$18 vector jumps to `$8779`.
4. `$8779 LDA $0534; BEQ $87A3`; when the byte is zero, execute `RTS` at
   `$87A3` and return to `$EBC5`.

The next fixed-bank loop body begins at `$EBC5`. The already extracted full
root-loop span in [`task_context/manifest.json`](task_context/manifest.json)
shows the repeated caller sequence there and `$EBD4: JSR $8009`. The
bank-$18 vector at `$8009` is `JMP $87E6` (see
[`slot09_87e6_worker/manifest.json`](slot09_87e6_worker/manifest.json)).
Those later bytes establish the next source boundary, but this executor stops
before fetching `$EBC5` or entering that call.

### Source-route state exercised by the verifier

`verify_rom_slot09_8779_zero_branch_executor.gd` builds the fresh route with
the existing source context and runner, then passes their actual
`slot09_86f8_worker_result` into the new executor. It does not seed worker
state from a trace fixture. The exercised input has:

- CPU at `$EBB3`: A=`$00`, X=`$00`, Y=`$05`, SP=`$7A`, P=`$02` (Z set, N clear);
- internal RAM: `$0022=$00`, `$0023=$07`, `$0024=$18`, `$0025=$19`,
  `$0534=$00`;
- MMC3: selected register 7, R6=`$18`, R7=`$19`;
- pending caller return bytes at stack `$0179-$017A`: `$B2,$EB` from the
  preceding worker's return.

The executor checks the caller's stack operations and mapper writes. At the
`$8779` entry it checks A=`$00`, X=`$00`, Y=`$05`, SP=`$78`, with the same
`$18/$19` mapping. The zero branch reads `$0534` from the passed RAM image,
returns with SP=`$7A` at `$EBC5`, and leaves RAM, stack, and mapper effects
consistent with the source instructions. It records no PPU bus events or APU
register writes on this branch.

### Inference and scope limits

For the exercised source-route input, the zero path is a valid bounded
increment. This result does not establish behavior for nonzero `$0534`, nor
that the worker renders a visible field. No PPU/APU output is modeled. The
executor does not use trace state, emulator screenshots, or captured audio.

Nonzero `$0534` is rejected at `$877E`, before following its unimplemented
script/data path. The next production increment must start from the returned
state at `$EBC5`, carry out the repeated root caller and its mapper setup, and
stop at `$EBD4` before `JSR $8009`; the separate `$87E6` audit documents its
own source contract but is not executed here.

## Runtime consumer and verification

The standalone executor is
[`rom_slot09_8779_zero_branch_executor.gd`](../../../scripts/gameplay/rom_slot09_8779_zero_branch_executor.gd).
The focused verifier is
[`verify_rom_slot09_8779_zero_branch_executor.gd`](../../../tools/diagnostics/verify_rom_slot09_8779_zero_branch_executor.gd).
It checks ROM-source hashes, input CPU/RAM/stack/MMC3 state, expected writes,
branch target, return stack, and the `$EBC5` stop boundary. It also changes a
copy of the source-route RAM image to `$0534=$01` to confirm that the
unsupported branch is rejected at `$877E`; this mutation is only a negative
verifier case and is not fed into the production route.

Command run:

```text
godot --headless --path . --script res://tools/diagnostics/verify_rom_slot09_8779_zero_branch_executor.gd
```

Result: both verifier checks passed. No FCEUX session, emulator screenshot, or
captured WAV was used for this audit.
