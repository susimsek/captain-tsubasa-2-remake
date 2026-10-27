# Cold-start NMI → ROM audio driver: bus-cycle evidence

## Source identity and trace scope

The supplied Turkish ROM SHA-256 is
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
Bytes below were read from that file. Cycle events come from the retained quiet
FCEUX replay at
`reference/diagnostics/synchronized_cycle_order_20261024_154547/` (source frames
0–283), while APU writes are also retained in
`reference/diagnostics/audio/fceux_apu_write_trace_20261024_184641_utc/apu_writes.csv`.
The trace records CPU bus callbacks and frame-relative/absolute cycle counts;
callback `cpu_pc` points to the following instruction in several checked
stores, so it is not always the address of the store instruction itself.

## NMI and mapper path

Fixed-bank source bytes at CPU `$C421` / file offset `0x03C431` are
`24 3B 30 4D 38 66 3B`: `BIT $3B`, `BMI`, `SEC`, `ROR $3B`. At source frame 9,
the NMI handler maps PRG bank `$02` into `$A000` by selecting MMC3 R7 (`$8000=$07`
at cycle 238302, then `$8001=$02` at 238308). The handler's bank data write at
cycle 240174 has callback PC `$C449`; it selects bank `$0C` in MMC3 R6 for
`$8000`. This event occurs 1,910 CPU cycles after the trace's `$C500` NMI-entry
anchor at cycle 238264. Source bytes at `$C449` / file offset `0x03C459` are
`20 00 80`, `JSR $8000`; bank `$0C` begins at file offset `0x018010` and contains
the driver entry.

The bank event and bytes establish the mapped call route, but the `$8000` JSR
opcode entry/return cycles themselves are not directly timestamped in this
trace. The retained event is a bus write immediately before that call, not a
CPU instruction trace.

## `$3B` state

Frame-end RAM snapshots show `$003B=$00` through source frame 8, `$50` at frame
9, and `$55` from frame 10 onward. They do not sample `$003B` at the `$C421`
read or record its write cycles. The taken `$C449` path implies bit 7 was clear
when `BIT $3B` was tested; the complete pre-call byte and exact mutation cycles
remain unknown.

## APU setup and first status enable

Supplied-ROM bytes at `$C685` / file `0x03C695` are
`A9 00 8D 10 40 A9 40 8D 17 40`: the `$4010=$00` store is at `$C687`, and
`$4017=$40` is at `$C68C`. The frame-4 bus trace records them at absolute cycles
111988 and 111994, with callback PCs `$C68A` and `$C68F` respectively.

The same quiet replay records no `$4015` CPU write until source frame 283:
`$4015=$0F` at absolute cycle 8,400,582, callback PC `$8369` (store at `$8366`).
Later `$4015` writes are present in the CSV. These are register-write timings,
not audio sample times, and do not alone reproduce APU/DMC timing.

## Selected-PC and bus-hook rerun

The requested quiet FCEUX replay was run with the saved input timeline and
Lua hooks for `$C421`, `$C449`, mapped `$8000`, `$C44C`, `$C685`, `$C687`,
`$C68A`, `$C68C`, `$C68F`, `$8366`, RAM `$003B`, MMC3 `$8000/$8001`, and bus
writes `$4010–$4017`. The full run record and detailed event table are in
`reference/diagnostics/cold_start_audio_entry_trace_20261026/README.md`,
`run_20261026_105103/events.csv`, and `run_20261026_105103/metadata.txt`.

At frame 9, `$C421` is logged at cycle 238,275 with `$003B=$00`; the `$C428`
write makes it `$80` at 238,284. The MMC3 write sequence selects R6 and loads
bank `$0C` at cycles 240,168/240,174. `$C449` is logged at 240,180, mapped
driver `$8000` at 240,182, and the `$C44C` return site at 241,033. The cold
start sequence records `$C685` at 111,984, `$4010=$00` at 111,988, and
`$4017=$40` at 111,994. The first `$4015=$0F` is frame 283 / cycle 8,400,582,
with mapped-bank opcode `$8366` (`8E 15 40`, `STX $4015`).

The installed FCEUX 2.7.0 build is pinned as
`a6d03e7968bd77a8156a7c9b628a673753f2f4c6`. Its Lua hooks provide the needed
instruction labels, state and FCEUX callback cycle values. They do not expose
all 6502 internal bus phases or DMC DMA stalls. Thus the route and first
APU-register timestamps are now directly observed in FCEUX, but replacing the
remaining sub-instruction phase assumptions or deriving source-only DMC
sample edges still requires a core-level CPU/APU/DMA hook or equivalent model.

The separate NSF wrapper setup mismatch is now measured and corrected in the
builder: its original `$4010/$4017` writes at 110854/110860 were 1,134 cycles
early relative to the source callbacks at 111988/111994. A diagnostic candidate
with 567 two-cycle `$EA` NOPs before the copied ROM sequence matches both source
cycle values, while all other APU-write rows, PLAY calls, DMC refill callbacks,
and the 13-entry event list remain unchanged. See
`reference/diagnostics/audio/apu_setup_cycle_alignment_20261026.md`. This
resolves only the cold-start setup writes; it does not validate PCM or DMC audio
timing.

No runtime audio asset or playback code was changed by this audit. The retained
historical NSF hash is still missing; see the adjacent timeline render/source
lineage notes. A sample-exact Godot music match remains unverified.
