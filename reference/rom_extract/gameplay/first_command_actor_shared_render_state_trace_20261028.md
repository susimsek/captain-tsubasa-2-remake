# First-command actor shared render-state trace — 2026-10-28

## Scope and provenance

This report summarizes a muted FCEUX replay of the supplied Turkish ROM into
the first in-match command panel. The source ROM SHA-256 is
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`. The
opening input timeline SHA-256 is
`195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3`, and the
post-title route timeline SHA-256 is
`87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e`.

FCEUX 2.7.0 ran NTSC with NewPPU and audio disabled (`--sound 0 --volume 0`,
`SDL_AUDIODRIVER=dummy`). The trace warms from power-on through source frame
8399, saves an anonymous in-memory checkpoint, and replays frames 8400–8953
twice in the same Lua process. It uses no numbered save slots. After each
checkpoint load, the script verifies frame and cycle counters, all 2 KiB CPU
RAM, all 16 KiB PPU memory, MMC3 registers, mapped PRG banks, and representative
mapped PRG bytes. Both loads matched at frame 8399, cycle `250126423`, MMC3
select `$07`, PRG banks `$00/$02/$1E/$1F`.

The trace artifacts are under
`reference/diagnostics/first_command_actor_shared_state_20261028_094239_utc/`:

- `shared_state_writes.csv` and `shared_state_writes_repeat.csv` contain the
  ordered writes with source frame, emulator frame, cycle within frame, total
  cycle, PC, mapped PRG bank, A/X/Y/P/S, MMC3 mapping, and related RAM state.
- `frame_state.csv` and `frame_state_repeat.csv` record the four shared values
  and their route context before each frame, plus the frame-8953 endpoint.
- `validation.json` records hashes, write counts, and replay checks.
- `metadata.txt` records ROM/input hashes, emulator invocation, and checkpoint
  details.

FCEUX documents write callbacks as `(address, size, value)`. A first capture
mistook the callback's `size` argument for the old byte. Its raw files are kept
as `shared_state_writes_raw_hook_args.csv` and
`shared_state_writes_repeat_raw_hook_args.csv`. The reported `old_value` in the
final CSVs is reconstructed from the source-frame-8400 RAM snapshot, applying
the ordered post-write RAM readback for each event. For each replay, all 554
frame-to-frame and endpoint transitions of `$0517/$0538/$0540/$0541` match the
recorded frame-state rows. The corrected write CSVs and frame-state CSVs are
byte-identical between passes.

## Observed writes

There are 584 writes per replay. PC values below are FCEUX's PC at the write
hook (the instruction immediately after the store); banks are the mapped
16-KiB PRG bank for that PC.

| RAM field | Writes | Observed writer PCs / mapped banks | Route observation |
| --- | ---: | --- | --- |
| `$0517` mirror | 13 | `$9B86` / bank `$00` (2), `$AA10` / `$02` (1), `$CF34` / `$1E` (1), `$ED12` / `$1F` (8), `$E114` / `$1F` (1) | The `$ED12` writes include `$00` copies at frames 8480, 8606, and 8623; `$40` is copied at frame 8656 and remains `$40` through later copies at 8707, 8758, 8821, and 8906. At frame 8656, `$052A=$40`. `$E114` writes `$40` unchanged at frame 8842 while `$052A=$00`. Endpoint frame 8953 has `$0517=$40`, `$052A=$00`. |
| `$0538` horizontal actor scroll | 547 | `$9B86` / `$00` (2), `$AA10` / `$02` (1), `$CF34` / `$1E` (1), `$EC4A` / `$1F` (50), `$8814` / `$18` (493) | Startup/fill writes at `$9B86/$AA10/$CF34` leave `$00` by frame 8460. The `$8814` write occurs once in every source frame 8461–8953 and writes `$00`; it is the post-store PC for the bank-$18 `STA $0538` at `$8811`. Fifty fixed-bank writes at `$EC4A` are the post-store PC for the `$EC47` `$0538` store and also write `$00`. Endpoint frame 8953 has `$0538=$00`, `$004A=$00`, `$004B=$74`. |
| `$0540` clip minimum | 12 | `$9B86` / `$00` (2), `$AA10` / `$02` (1), `$CF34` / `$1E` (1), `$8053` / `$14` (8) | Bank-$14 writes at PC `$8053` write `$00` in frames 8481, 8607, 8624, 8657, 8708, 8759, 8822, and 8907. `$8053` is the post-store PC for `STA $0540` at `$8050`. |
| `$0541` clip maximum | 12 | `$9B86` / `$00` (2), `$AA10` / `$02` (1), `$CF34` / `$1E` (1), `$8058` / `$14` (8) | Bank-$14 writes at PC `$8058` write `$FF` in the same eight frames; `$8058` is the post-store PC for `STA $0541` at `$8055`. Endpoint frame 8953 has `$0540=$00`, `$0541=$FF`. |

These observations confirm the actual writer cadence and values for this
specific input route. They also correct the former assumption that `$0538` had
no intervening route-time writes: it is written at the actor-loop cadence,
with the observed value remaining zero through this endpoint.

## What this establishes and what remains open

The trace gives a repeatable same-input validation target for the actor
presenter's mirror, scroll, and clip inputs. It identifies the observed write
sites and their source-frame/cycle context, and confirms that the sampled
frame-8953 values are produced through route execution rather than being
constant assumptions.

The trace is diagnostic evidence, not a runtime input or a Godot route model.
`KickoffRouteRuntime` still does not execute the source task/callback chain
that produces these transitions. In particular, `$0517` depends on the live
scenario/holder/player state and `$052A` copy path; `$0538` writer calls are not
connected to a decoded route worker; and `$0540/$0541` actor-engine setup is
not invoked from the source-timed actor task in Godot. Do not feed the captured
RAM values into runtime or replace the missing source events with frame-count
defaults. A production resolver still needs the route's decoded state and
source event sequence.
