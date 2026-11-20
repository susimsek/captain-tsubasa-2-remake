# Slot-$09 bank-$18 worker `$86F8` audit — 2026-10-29

## Finding

The first bank-$18 worker is a frame/task-driven stream interpreter. On the
retained first-match route, it takes a simpler source-supported path: its live
`$0532` state is zero, so the worker branches from `$86F8` to `$8722` and
returns without writing RAM or touching the PPU/APU. The source-route executor
can therefore model this call by reading `$0532` from its live dispatch image,
accepting zero, and returning to the caller's `$EBB3` continuation. It must
reject other states until the corresponding branches and producers are
implemented.

This is a match/field worker, not the command-panel renderer. The root
slot-`$09` loop calls the three banked workers in sequence; after this worker's
return, the next call is `$8006->$8779`. The visible first command panel is
separately attributed by existing trace notes to field-loop B handler
`$E349`.

## Source identity and spans

All offsets include the 16-byte iNES 1.0 header. The supplied ROM is mapper 4,
SHA-256 `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
The worker uses switchable low bank `$18` at `$8000-$9FFF` and switchable high
bank `$19` at `$A000-$BFFF`; helper code at `$C000-$DFFF` is fixed bank `$1E`.
The extracted source bytes and hashes are in
[`slot09_86f8_worker/manifest.json`](slot09_86f8_worker/manifest.json).

| CPU span | Bank | File offset | Length | SHA-256 | Purpose |
| --- | ---: | ---: | ---: | --- | --- |
| `$86F8-$8778` | `$18` | `0x030708` | 129 | `ae998967ec1bb0e39ffcc72c8670a393946cfe233ad6845dc524870bd3264d23` | Complete first worker body; `$8779` begins the next worker |
| `$AD6E-$AD6F` | `$19` | `0x032D7E` | 2 | `c8f33227c8180de1bf13f0f7aa7646a8b71d34414b68798f29adcd0121288dc8` | First script-pointer table entry, used only after a nonzero reset count |
| `$C533-$C535` | `$1E` | `0x03C543` | 3 | `447b2945aa7e5040be16cfa5135a9b4be42dac48166c962c6ae65c11fd443e74` | First inline-record helper vector: `JMP $CCD2` |
| `$CCD2-$CD0C` | `$1E` | `0x03CCE2` | 59 | `7c23b91502ce9ebf01c18cbf401030f35181dbdc359d245cc7d7d57dd2cbc37b` | `$C533` helper: copies three inline bytes into a `$0499` record and advances the caller return address |

## Entry contract and observed first-route state

The source caller at `$EBB0` has a pending `JSR $8003`; the bank-$18 vector at
`$8003` jumps to `$86F8`. At worker entry, the root continuation has mapper
banks `$18/$19`, SP `$78`, and a pending return word `$EBB2`. `RTS` at `$8722`
restores SP to `$7A` and resumes at `$EBB3`.

The retained muted FCEUX 2.7.0 NTSC/NewPPU trace was made in two matching
passes from a signature-checked frame-8399 checkpoint. It records `$0532`
initialization to `$F8` at `$9B86` on frame 8458, then `$F8->$00` at `$AA10` on
frame 8459. The later frame-8460 `$CF34` write preserves zero. The first
resumed slot-`$09` invocation is in the next traced frame, with no intervening
`$0532` write; the trace's task-write hooks show the next writes to `$0532`
only at frame 8467. Both normalized passes agree (event hash
`5bb43126def3352bbaeb44530ed712c16a8b112badbc300d76ef2ff33c8f9a4a`, write
hash `c639dfb47435a5706c92cf16a7316947445ac03d4887ee1b26dbbedbd1a8dd22`).
See `reference/diagnostics/first_command_task_boundary_20261028_070655_utc/`.

These observations support `$0532==0` for this first route pass; they are not
values to inject into Godot. The production consumer must branch on the RAM
image delivered by the source-owned route.

## Worker control flow

The `$86F8-$8778` body is hash-checked as one source span. Its relevant paths
are:

1. `$86F8` loads `$0532`; zero branches directly to `$8722 RTS`. This is the
first-match route path supported by the retained task trace.
2. If `$0532` is nonzero with bit 7 clear, the worker checks `$0533`; a nonzero
   value is decremented and returns. A zero value enters the stream parser.
3. If bit 7 is set, it masks `$0532` with `$7F`; a resulting zero returns. A
   nonzero count is decremented, doubled, and used as an index into the pointer
   table at `$AD6E,X`. The selected bank-$19 pointer is stored in `$79/$7A`,
   and `$0533` is cleared before parsing.
4. The stream control byte uses its high five bits as the `$0533` countdown
   and low three bits as a count/operation selector. For a nonzero countdown,
   the worker reads that many index/value pairs and writes them to
   `$046F + index`. It advances `$79/$7A`, calls `$C533` with three inline
   bytes, then returns to the root caller.
5. With zero countdown, low selector `0` clears `$0532` and returns. Selector
   `1` loads a new little-endian pointer into `$79/$7A` and loops to the stream
   reader. Other selector values advance the stream cursor and loop; their
   full data meaning is not established here.

The `$C533` vector jumps to `$CCD2`. That helper copies three inline bytes to
`$0499-$049B + 3 * $0498`, increments `$0498`, and adds three to the stacked
return PC so the worker resumes after the inline payload. On the shown worker
path, the inline payload is `00 6C 04`; the subsequent `$8764 RTS` returns to
the root caller. This establishes the byte-copy and stack effects, not the
consumer meaning of the `$0499` records.

## Safe stop boundary and limits at the original audit date

For the observed first route, the smallest executor is the `$0532==0` fast
path: execute `$86F8`'s `LDA $0532; BEQ`, then the source `RTS` at `$8722` and
stop at the returned caller PC `$EBB3`, before the next `$8006` worker call.
No event timer, pointer table, `$046F` writes, `$0499` record appends, PPU
effects, or APU effects occur on this path.

The nonzero `$0532` script path, its full pointer table/data, the later workers
at `$8779` and `$87E6`, and the meaning/consumer of `$0499` records remain
outside this audit. The report does not claim a rendered field or command
menu. No new emulator run, screenshot, or WAV capture was used.

## Initial production integration update — 2026-10-29

`RomSlot09Worker86F8ZeroBranchExecutor` now consumes the live
`slot09_resume_result` produced by `RomFreshKickoffSourceRouteRunner`. It
hash-checks this worker span, reads `$0532` only from that result's RAM image,
requires `$00`, executes `$86F8 LDA $0532; BEQ $8722; RTS`, verifies the live
`$EBB2` return word, and returns at `$EBB3`. The runner exposes this output and
stops before reading the next `$8006->$8779` worker. Nonzero `$0532` remains an
explicit unsupported branch.

## Recorded `$82` script branch — 2026-11-06

The later two-pass first-command-menu/stamina trace records a second live
`$86F8` state at source frame 8707. Its worker write rows agree between both
passes (10 selected transitions). At `$ED35`, scenario `$36` writes `$82` to
`$0532`; `$8704` masks that marker to `$02`; `$871A` clears `$0533`; the stream
reader then writes countdown `6` to `$0533` at `$873F`, and selector `3` to
`$003A` at `$8745`, decrementing `$003A` to zero at `$8752`.

The new extracted source rows are in
[`slot09_86f8_worker/manifest.json`](slot09_86f8_worker/manifest.json):

| Source | Bank / CPU range | File offset | Bytes | Meaning |
| --- | --- | ---: | --- | --- |
| Pointer selected by normalized `$0532=2` | `$19:$AD70-$AD71` | `0x032D80` | `FC AD` | Points to `$ADFC` |
| Stream consumed from that pointer | `$19:$ADFC-$AE03` | `0x032E0C` | `33 0D 1A 0E 1A 0F 3A 32` | Control `$33`, then pairs `$0D/$1A`, `$0E/$1A`, `$0F/$3A` |

The worker writes those three values to `$046F+$0D..$0F` (`$047C-$047E`),
advances its stream pointer to `$AE03`, and calls `$C533`. The checked inline
payload at `$8761-$8763` is `00 6C 04`; the existing hash-checked `$CCD2`
helper appends it at `$0499+3*$0498` and advances `$0498`. Godot now executes
this bounded branch from its live RAM/stack/mapper state and these ROM-derived
bytes, including both the helper's stack return to `$8764` and the worker RTS
to `$EBB3`. It does not apply a PPU/APU transfer here; the appended packet's
later consumer remains a separate transition.

The repeated FCEUX trace directly confirms the `$0532`, `$0533`, and `$003A`
changes and subsequent `$8779/$87E6` worker clears. The `$047C-$047E` data
values and `$0499` append are decoded from the ROM stream/helper; this trace's
selected write hooks do not independently record those bytes. The earlier
frame-8399-derived trace still documents a distinct zero-state invocation;
the source worker therefore retains both the `$00` and `$82` routes. The
remaining nonzero marker values, other stream selectors, and the field/menu
rendering are not covered by this bounded implementation.

## Countdown continuation replay confirmation — 2026-11-06

The retained muted FCEUX menu/stamina trace independently confirms the later
`$AE08` countdown tail used by the live route. Both normalized passes have the
same writes: at frame 8719, `$8722` leaves `$0533` at `$02` and decrements it
to `$01`; at frame 8720, `$8722` leaves `$01` and decrements it to `$00`; at
frame 8721, the `$8723` stream reader resumes from `$AE08`, writes `$06` to
`$0533`, sets the pair count at `$003A` to `$02`, then consumes both pairs.
Pass hashes and row counts are recorded in the diagnostic's
[`validation.json`](../../../../diagnostics/first_command_menu_stamina_20261028_064701_utc/validation.json).

The production executor now accepts the observed scenario-$36 `$02` marker
with `$AE08` and cursor `$06` at countdown `$01`. On the zero-count follow-up,
the cursor may still be `$06` or `$07`; the ROM stream instruction overwrites
it with the stream's pair count before consuming records. This bounded
continuation is based on the repeated trace and checked worker bytes, not a
synthetic timer or injected state.

The same two passes show `$0533=$06` at worker entry on frame 8722, then
`$8722` decrements it once per frame through `$00` at frame 8727. The next
worker event at frame 8728 reads the `$AE0D` selector tail from the extracted
stream (`01 FC AD`) and reaches the `$ADFC` batch, whose `$0533=$06` write is
observed at `$873F`. This supports the bounded `$AE0D` countdown and redirect
edge; the trace records the resulting write/event sequence, while the exact
pointer bytes are established by the ROM-derived stream manifest.

At frame 8729, the same trace shows the `$ADFC` batch's six-tick countdown
beginning at `$AE03`; `$8722` reduces it to zero by frame 8734. The next
`$8723` batch starts at `$AE03`'s `$32` control byte, and the extracted stream
then advances to `$AE08`. Both trace passes have matching writes for these
countdown transitions. The executor therefore recognizes the three stream
positions already present in the checked `$AE03-$AE0F` manifest and continues
through their source-defined count/redirect operations.
