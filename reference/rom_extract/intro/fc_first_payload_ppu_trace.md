# PPU write observations around the first FC command

## Scope and corrected source interpretation

The supplied ROM SHA-256 is
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
The opening script has `$FC` at CPU `$A054`, followed by `$4F` at `$A055`.
A live dispatch trace reaches bank-0 PC `$8837` for this command and next
returns to the interpreter at script pointer `$A055`. The `$4F` byte is then
handled as a normal text byte. The old counted-block claim that `$A056–$A0A4`
were payload is withdrawn. See `fc_counted_block_trace.md` and
`reference/diagnostics/audio_command_context_20261024_145219/dispatch_context.csv`.

The bus writes below remain valid observations from
`reference/opening_reference_capture/ppu_register_writes.csv`; this note no
longer attributes them to an FC payload or claims a descriptor-table lookup.

## Cycle-stamped PPU register writes

| Source pointer sample | Observed PPU writes (zero, then value) |
|---:|---|
| `$A09B` | `$2249:$00`, `$2269:$4F` |
| `$A09C` | `$224A:$00`, `$226A:$6F` |
| `$A09D` | `$224B:$00`, `$226B:$7A` |
| `$A09E` | `$224C:$00`, `$226C:$6F` |
| `$A09F` | `$224D:$00`, `$226D:$0B` |
| `$A0A0` | `$224E:$00`, `$226E:$20` |
| `$A0A1` | `$224F:$00`, `$226F:$01` |
| `$A0A2` | `$2250:$00`, `$2270:$02` |
| `$A0A3` | `$2251:$00`, `$2271:$03` |

The cycle-stamped writes occur at frames 837–845. At each pair `$2000=$84`;
therefore PPUDATA increments PPUADDR by 32 after every write. The second
address is 32 bytes after the first. End-of-frame RAM samples show the source
pointer one byte later than the byte associated with the in-frame event; they
are a different sampling time, not the PPU-write timestamp.

## What this does and does not establish

Confirmed: the register values, write order, frame association, `$2000=$84`,
and the resulting +32 PPUADDR step. The live FC trace separately shows that
`$A054` is a one-byte command on this opening path; it does not own a counted
payload range. These observations do not by themselves map the writes to final
screen coordinates, identify the exact producing routine for every write, or
establish raster visibility timing. No screenshot or captured audio is used as
a runtime asset.
