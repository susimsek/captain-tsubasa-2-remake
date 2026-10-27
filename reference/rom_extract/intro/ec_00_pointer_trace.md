# Opening command `EC 00` pointer trace

## Scope and source identity

This trace follows the opening command at script CPU `$A02F` in the supplied
Turkish ROM, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`. It
separates the handler's verified pointer selection and mapper effects from the
meaning of the selected data, which is not yet established.

## ROM path

- Script bytes at `$A02F` are `EC 00`; the live dispatch trace records the next
  command at `$A031` in the same source frame, 342.
- The bank-0 vector target is `$85D2` (PRG file offset `0x005E2`). It reads the
  operand; `$FF` takes a separate clear-state branch, while `$00` calls
  `$89D2`.
- `$89D2` (bank-0 PRG file offset `0x009E2`) begins
  `A8 A2 06 20 B9 C4 98 0A AA BD 00 BD 8D 54 06 BD 01 BD 8D 55 06 A9 80 8D 52 06 A9 01 8D 53 06 A9 00 85 90 A9 02 85 91 A6 56 20 B9 C4 60`.
- `$C4B9` temporarily maps PRG bank 6 into the `$A000` window. With operand 0,
  the handler reads pointer-table entry 0 at bank-6 CPU `$BD00/$BD01`; the local
  bytes there are `0C BD`, selecting pointer `$BD0C` (PRG file offset
  `0x00DD1C`). The handler writes `$0C,$BD` to `$0654,$0655`.
- The remaining direct state writes are `$0652=$80`, `$0653=$01`, `$0090=$00`,
  `$0091=$02`. `$C4B9` is called again with `$56` to restore the prior `$A000`
  PRG bank.

## Capture cross-check

The synchronized silent FCEUX capture at source frame 342 records
`$0652–$0655 = 80 01 0C BD`, `$0090–$0091 = 00 02`, and `$56=$03`; the values
remain stable in sampled frames 343, 378, and 379. The script-tagged MMC3 writes
at frame 342 show R7 selecting bank 6 and then restoring bank 3. The same
script-tagged trace shows the CHR registers R0–R5 remain `$7C,$7E,$FC,$71,$52,$53`
through this EC path. Other NMI/loader writes in that frame are not attributed
to EC.

## Open question

The bytes at selected pointer `$BD0C` begin
`05 0D 15 0D 15 1D 15 0D 15 1D 15 0D 05 FE 24 2C ...`. Do not label the
pointer as a CHR bank pair or infer a final image from its contents.

## `$8A0F` stream consumer: byte grammar and first group

Further byte tracing identifies the downstream reader at bank-0 `$8A0F` (file
offset `0x00A0F`). While `$0652` has bit 7 set and `$0653` is nonzero, the
reader holds its state. When it processes a regular stream byte `b`, it selects
the 12-byte payload at `$BD80 + 12*((b & $F8) >> 3)`, queues that payload as
three four-byte PPU-write packets, increments the stream index in `$0652`, and
loads a delay from the next stream byte's low three bits. `$FE` clears the low
six index bits and immediately restarts at stream byte zero; `$FF` clears the
active flag and restores the saved `$A000` PRG bank. The byte-level control
flow is established; the semantic label for the low-three-bit delay is not.

For the opening's first regular byte, the preserved 512-byte extract
`ec_bank6_bd00_beff.bin` contains:

- stream `$BD0C`: `05`; selected group index 0 at `$BD80`;
- lookahead `$BD0D`: `0D`; low-three-bit delay 5;
- payload at `$BD80`: `EB B6 BC BE EE B7 BD BF EF E2 E8 EA`.

The capture holds `$0652-$0655 = 80 01 0C BD` through frame 379. At frame
380, `$0652` becomes `$81`, `$0653` becomes `$05`, and the PPU queue contains
three records for addresses `$2302`, `$2303`, and `$2304`. Their queue bytes
begin `84 02 23`, `84 03 23`, and `84 04 23`, each followed by four ROM group
bytes. Frame 381 bus events and PPU memory confirm `$2000=$84` (increment by
32) and all twelve first-group bytes at the resulting nametable addresses.

### Frame-level consumer model

The routine bytes at bank-0 `$8A0F` (bank-relative PRG offset `0x00A0F`,
iNES file offset `0x00A1F`) calculate the payload address as
`$BD80 + 12 * ((b & $F8) >> 3)`. The arithmetic is `(b & $F8) + ((b & $F8) >> 1)`;
the resulting low/high bytes are added to base `$BD80`. The handler then loads the stream byte at index+1,
mask it with `$07`, and store that delay in `$0653`. The `$FE` path clears the
low six bits of `$0652` and jumps back to the read at `$8A14`; the `$FF` path
clears `$0652` and restores the saved PRG bank from `$56`. These are direct
ROM-code findings. The caller chain is `$84FC → $895D → $896D → $89FF`: a
nonzero `$55` text speed calls `$895D` after each glyph, and each `$9FA8(A=1)`
wait in its loop is followed by `$89FF`. `$89FF` checks `$0652`, decrements
`$0653`, and reaches `$8A0F` when the counter reaches zero. Static scanning of
all PRG banks found no other `$89FF` callsite or `$895D` caller.

The synchronized capture gives this entry-0 cadence:

| Source frame | `$0652` | `$0653` | Stream byte/group | PPU consequence |
|---:|---:|---:|---|---|
| 342–379 | `$80` | `$01` | Pointer remains `$BD0C` | Consumer does not advance in the sampled frames. |
| 380 | `$81` | `$05` | `$05` → group 0 at `$BD80` | Three four-byte packets are staged at `$2302–$2304`. |
| 381 | `$81` | `$04` | Delay countdown | NMI writes the twelve group-0 bytes with `$2000=$84`. |
| 382–384 | `$81` | `$03` to `$01` | Delay countdown | No new group is staged. |
| 385 | `$82` | `$05` | `$0D` → group 1 at `$BD8C` | Group 1 replaces the same three four-byte tile columns. |
| 386 | `$82` | `$04` | Delay countdown | NMI commits the staged group-1 packets. |
| 390 / 391 | `$83` / `$83` | `$05` / `$04` | `$15` → group 2 at `$BD98` | Same addresses; group-2 bytes commit one frame later. |

Across the reachable regular entries, `$0653` matches the next stream byte's
low three bits: the first groups update every 5 frames, some later groups use
3, 4, 6, or 7. `$FE` entries appear after these runs; when one is processed,
the same routine invocation resets to stream byte zero and stages the first
group again. Entry 0's trailing `$FF` follows the final `$FE`, so the live
loop prevents that trailing stop byte from being reached in the observed
continuous animation. The stop branch is ROM-confirmed, but not observed for
this entry.

`scripts/opening/rom_ec_stream_decoder.gd` validates and decodes the preserved
ROM segment. `scripts/opening/rom_ec_stream_player.gd` exposes three `$84`
packets and applies them at a caller-supplied next-NMI boundary. The presenter
advances it only at the decoded text-wait callsite; there is no capture-supplied
first-record frame or EC-specific pause gate. A focused diagnostic compared
RAM `$0652–$0655` for 1,377 frames across all four selected streams and their
transitions; all bytes match the synchronized FCEUX snapshots, including the
first groups and the `$02` pause. It does not model 6502 cycles or sub-frame
NMI/PPU ordering, nor prove the first colored pixel. This is not a full
EC/APU/PPU emulator.

Evidence: `reference/rom_extract/intro/cold_start_vector_handler_semantics.md`,
`reference/rom_extract/intro/cold_start_observed_dispatch.json`,
`reference/diagnostics/opening_dispatch_full_20261024_150016/mmc3_writes.csv`,
and synchronized frame RAM snapshots under
`reference/opening_timing_capture_20261024_125300/ram_states/`.
