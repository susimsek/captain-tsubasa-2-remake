# Live `$001B.6` persistence and `$0078` wait trace — 2026-10-29

## Result

A muted, two-pass FCEUX replay now covers the cold-start input prefix through
the first fresh-match BGM write. It resolves the live `$001B.6` and `$0078`
inputs at `$8114->$8920`, observes the real `$895C RTS->$8117` return, and
shows how the wait exits. The prior inference that this caller waited with
interrupts disabled was wrong for the live route: the trace enters `$8114`
with `P=$22` (`I=0`), so the maskable raster IRQ can run.

The cold-start prefix records 9,373 writes to `$001B` over frames 0–4692.
The first writes are `$00` at `$C672` on frame 4 and `$00->$40` at `$A22A` on
frame 6. There are no bit-6-clearing writes after the setter through frame
4692. The two-pass route log adds 5,420 `$001B` writes over frames 4693–7409;
every resulting value retains bit 6 (`$40` or `$C0`). The `$A135/$9F0C`
writers toggle bit 7 while preserving bit 6.

## Checkpoint and replay record

- ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`;
  FCEUX reported the matching ROM MD5 `eaf2b3745263efa4b1afd2b400f68dae`.
- Emulator: FCEUX 2.7.0, NTSC, NewPPU, audio disabled with `--sound 0`,
  `--volume 0`, and `SDL_AUDIODRIVER=dummy`. No startup movie was active.
- Opening-input SHA-256:
  `195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3`.
  Route-input SHA-256:
  `87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e`.
- The named frame-4692 checkpoint is retained as an ignored local diagnostic
  artifact under checkpoint ID `fresh_kickoff_1b6_persistence_20261029` (file
  basename `frame_004692_fullprefix_slot0.fc0`). It is 79,384 bytes, SHA-256
  `e5f88f9e3b284fd80f69a29bfafe6cd7aaf1c53f426448074bc541320c5e4d84`.
  FCEUX saved it through `savestate.create(1)`, which selects its UI slot 0,
  under a unique project ROM alias. All ten state filenames for that alias
  were checked absent before creation; the supplied ROM is a hard link source
  and was not copied or modified. The slot file was copied into the ignored
  project checkpoint directory.
- Checkpoint frame/cycle: `4692 / 139730109`. The saved CPU state is
  `PC=$9F04, A=$40, X=$19, Y=$00, P=$21, SP=$E0`; MMC3 selector `$07`, PRG
  banks `$00/$02/$1E/$1F`.
- Both route passes loaded this same named checkpoint. Each load passed
  byte-for-byte comparisons of the full 2 KiB CPU RAM and 16 KiB PPU memory,
  MMC3 selector/register state, mapped PRG bytes, CPU registers, frame, and
  cycle count. Both passes reached the first `$812F` post-store at source
  frame 7409, cycle 220630519, with `$0700=$55`.
- The two local trace passes each have 8,953 PC events and 21,223 watched RAM
  writes. After excluding the pass-number CSV column, the event logs and write
  logs compare identical. Per-log hashes are retained with the ignored local
  trace artifacts; no local-only paths are recorded here.

## Live caller and wait inputs

At source frame 7266, the actual caller enters `$8114 JSR $8920` at cycle
11,884 (absolute cycle 216,367,219), bank `$00`:

| Point | Cycle in frame | PC / bank | A, X, Y, P, SP | `$1B` | `$78` | `$79` | `$3B` |
| --- | ---: | --- | --- | --- | --- | --- | --- |
| Caller before JSR | 11,884 | `$8114` / `$00` | `$00,$00,$84,$22,$28` | `$C0` | `$04` | `$40` | `$55` |
| Callee entry | 11,886 | `$8920` / `$00` | `$00,$00,$84,$22,$26` | `$C0` | `$04` | `$40` | `$55` |

The `$8114` status has the interrupt-disable bit clear. The alternate NMI path
is selected by `$001B.6`; its bank-2 setup sees `$79=$40` and writes `$04` to
`$78` at reported post-write PC `$A0A8`, frame 7266 cycle 737. It does not take
the `$79=0` path at `$A0A9`, so this NMI write does not release the wait.

The mainline then loops at `$893B` while `$78=$04`. On the same frame, the
raster IRQ path enters bank `$02`; `$A1C3 STA $78` clears `$04->$00` at reported
post-write PC `$A1C5`, cycle 17,076 (absolute cycle 216,372,411). The write
context is `A=$00, X=$04, Y=$22, P=$67, SP=$21`, with `$1B=$C0`, `$79=$40`,
and `$3B=$AA`. The final observed `$893B` read at cycle 17,179 sees `$78=$00`;
the path then reaches `$893F` at cycle 17,183, `$895C RTS` at 17,547, and the
caller return `$8117` at 17,549. At `$8117`, SP has returned to `$28`, matching
the pre-JSR stack depth. The caller clears `$79` only after the wait has
exited.

## BGM command and component boundary

The same uninterrupted replay reaches the direct match-setup store at
`$812C` on frame 7409, cycle 220,630,517. At that hook `A=$00` is the live
`$26` value read by the preceding caller bytes, while `X=$55`; the
`$26<$20` branch therefore selects `$55`. The post-store hook at `$812F`
observes `$0700=$55` two CPU cycles later. This is the actual fresh-match
caller event, not a menu callback or a scheduled substitute.

The prior `$0078` uncertainty is resolved, but this trace is not a runtime
return receipt. `RomFreshKickoffCallerContinuation` remains a projection that
requires its earlier caller helper receipts; production still needs to model
the ROM-owned NMI/IRQ and source-clock transitions instead of injecting this
trace's state. No runtime files changed in this work. The source bytes needed
for the wait, NMI, IRQ, and continuation are already covered by the
hash-checked
[`fresh_kickoff_0078_wait_20261029/manifest.json`](fresh_kickoff_0078_wait_20261029/manifest.json);
no duplicate source spans were added.

This establishes behavior in FCEUX's NTSC software model. It does not establish
physical NES interrupt timing. No emulator screenshot or WAV was used as a
runtime asset.
