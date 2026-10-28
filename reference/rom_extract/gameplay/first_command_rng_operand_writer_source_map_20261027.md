# First-command RNG operands and NMI mode: source map — 2026-10-27

## Identity and scope

This map combines target-ROM bytes with the retained, muted, repeated FCEUX
operand trace. It does not add a new emulator or source-stepper run. ROM SHA-256:
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`. File
offsets include the 16-byte iNES header; MMC3 PRG-bank numbers are 8 KiB banks.

## Which RNG update runs

The fixed-bank NMI entry at `$C76E` / bank `$1E` / file `0x03C77E` is
`BIT $001B; BVC +3; JMP $C421`. It selects one of two paths by `$001B.6`:

| `$001B.6` | Path | RNG work |
| --- | --- | --- |
| Set | `$C421` / bank `$1E` / file `0x03C431` selects bank `$02` and calls `$A000` | After its controller-read loops, the bank-$02 RNG entry is `$A116` / file `0x004126` (`CLC`); its arithmetic body begins at `$A117` / file `0x004127` and updates `$E1/$E2/$E3`: `E1 += $83`, `E2 += $0D + carry`, `E3 += $11 + carry`. |
| Clear | Normal NMI body at `$C775`; `$C7E4` / bank `$1E` / file `0x03C7F4` calls `$C9C5` / file `0x03C9D5` | `$C9C5` executes the indexed, operand-dependent transform below. Its first `ADC` uses caller carry; the normal caller reaches it with carry set, as detailed in `first_command_rng_source_execution_details_20261027.md`. |

The NMI mode bit is explicitly cleared by the route transition at `$C6E8–$C6EB`
(`LDA #$00; STA $001B`), bank `$1E`, file `0x03C6F8–0x03C6FB`. The retained
operand trace records that write at source frame 8460. Before it, the same
trace records the bank-$02 update path setting scheduler-ready bit 7 at
`$A133` (`STA $001B`; trace callback PC `$A135`) while preserving bit 6. After it, the source
replay and trace record `$C9C5` once per frame, frames 8461–8593: 133 calls.
This is the audited route's transition, not a general per-frame RNG rule.

Bit 7 is the cooperative scheduler-ready latch, separate from mode bit 6. The
normal NMI sets it at `$C7EE` (`ORA #$80; STA $001B`, file `0x03C7FC–0x03C7FF`;
write-hook return PC `$C7F0`); the worker clears it at `$CAB4` (`AND #$7F; STA
$001B`, file `0x03CAC4–0x03CAC5`; return PC `$CAB6`). On the bank-$02 path,
`$A117` sets bit 7 and the frame-loop code clears it at `$9F0A` (`STA $001B`,
bank `$00`, file `0x001F1A`; return PC `$9F0C`). These bit-7 writes do not
themselves decide whether `$A117` or `$C9C5` runs; `$001B.6` does.

## `$C9C5` reads mutable CPU RAM

The byte-checked bank-$1E routine at CPU `$C9C5` / file `0x03C9D5` is:

```text
LDX $00E1
LDA $0300,X
ADC $0700,X
ROL $00E2
EOR #$FF
ROL $00E2
ADC $00E2
STA $00E2
SBC $0780,X
ADC $00E1
STA $00E3
INC $00E1
RTS
```

Reset routine `$C64E` clears CPU RAM `$0000–$07FF`, including all three operand
regions. That establishes their reset value, zero. It does not establish the
values at later calls: these are ordinary, overlapping working RAM, not three
constant RNG tables.

| Operand | What the address range contains | Existing source/trace evidence |
| --- | --- | --- |
| `$0300,X` | Match/player record RAM. Match-zero fresh-start code initializes home records; opponent setup also writes record fields. | The post-checkpoint trace observes seven writer-PC/bank pairs for the watched cells, including opponent setup stores at bank `$1C` `$8B2C/$8B2F` (file `0x038B3C/0x038B3F`, trace return PCs `$8B2E/$8B31`) and fixed-bank record/field stores around `$CF59/$CF67`, `$DC61/$DC66/$DC74` (trace return PCs `$CF5B/$CF69/$DC63/$DC68/$DC76`). It does not cover the earlier initialization before frame 8400. |
| `$0700,X` | Sound-command queue and sound-driver working RAM; sound code also shares the page with other live route data. | The repeated trace sees 42 writer-PC/bank pairs for watched cells. Most are in sound-driver bank `$0C`; examples include `$80D2 STA $0707` (file `0x0180E2`, trace return PC `$80D5`), `$80D9 DEC $0707,X` (file `0x0180E9`, return PC `$80DC`), and `$80E3 DEC $0709,X` (file `0x0180F3`, return PC `$80E6`). Those writes depend on the driver's live state. |
| `$0780,X` | Upper internal RAM, with CPU mirroring: `$0780–$07FF` is physical RAM `$0780–$07FF`; `$0800–$087F` mirrors `$0000–$007F`. | The repeated trace sees 36 writer pairs in `$0780–$07FE` and five writer pairs to mirrored `$007A–$007F`. The common `$CB11` bank-`$1E` site (trace return PC; actual `$CB0F` write, file `0x03CB1F`) repeatedly writes zero-page `$007F`; other observed sites include bank `$02` `$A2D5` and fixed-bank `$CF4B`. Exact cells and old/new bytes are in the trace CSV. |

The CSV's `cpu_pc` comes from `memory.getregister("pc")` in FCEUX's memory-write
callback, so it is the PC after the write instruction. The examples above
subtract that instruction's byte length to identify the actual opcode address.
The trace watches only addresses read by the observed `$E1=$FA–$FF,$00–$7E`
calls plus selected route-control bytes; its writer counts are not a census of
every write to every RAM page.

## What the repeated trace establishes

The retained trace `reference/diagnostics/first_command_rng_operand_trace_20261027_172720_utc/`
loads an anonymous in-memory state at frame 8399, checks its RAM/PPU/frame and
seeded PRG-map signature, then replays frames 8400–8593 twice with the same inputs. Both runs
match byte-for-byte: 133 `$C9C5` calls and 5,653 watched writes per pass. At
every call, the three live values read at `$C9C8/$C9CB/$C9DC` match the RAM
mirror maintained by the write hooks. The mode trace shows `$001B.6` remaining
set through the `$A117` phase, cleared at frame 8460, and clear during the 133
`$C9C5` calls. This validates the exact recorded route window only.

Operand writers before frame 8400 are still unknown. The frame-8399 checkpoint
contains their resulting bytes but not their writer PCs or source semantics.
Two earlier FCEUX attempts stalled before producing rows; the retained notes
are `reference/diagnostics/first_command_rng_preinit_writer_trace_20261027_173304_utc/README.md`
and `..._174208_utc/README.md`. Do not treat checkpoint values as runtime
inputs.

## Generic Godot update: not yet source-supported

The `$A117` arithmetic itself is implementable once the actual mode-gated call
event is known. `$C9C5` arithmetic and its incoming carry are also byte/source
resolved. A generic Godot-side receiver update is still not justified because
the route model does not yet reproduce:

1. the live writer and timing of `$001B.6`, hence the exact choice/cadence of
   `$A117` versus `$C9C5` for arbitrary route inputs;
2. the pre-frame-8400 writes to the `$0300/$0700/$0780` operands; and
3. the relevant live game, sound-driver, scheduler and mirrored zero-page RAM
   writes whose values `$C9C5` consumes.

The current Godot schedule is therefore a hash-bound replay for one recorded
input timeline. Removing its input-hash guard or substituting endpoint RAM
would not make the update generic. Keep the production RNG unchanged until
these writers and call events are source-driven. The trace scripts, captures,
checkpoint and save states remain diagnostics only.

## Practical follow-up trace

The existing frame-8399 checkpoint is too late to identify operand writes made
before that frame. Reuse its successful anonymous in-memory save/load pattern,
but move the checkpoint to the first stable FCEUX frame after power-on has
cleared RAM and before the first route input. To avoid the reset-time stall seen
in the two failed frame-7393 attempts, start muted FCEUX 2.7.0/NewPPU without
Lua mapper or RAM-write callbacks, advance to that stable point, snapshot the
frame/cycle, full 2 KiB RAM, 16 KiB PPU, CPU registers and MMC3 mapping, then
create `savestate.create()` and save it in memory. Attach the hooks only after
loading the checkpoint; verify the entire signature after every load before
replaying the original input timeline.

Run the instrumented interval twice from that state and compare normalized
event rows. Record writes to `$001B`, `$0300–$03FF`, `$0700–$07FF`, `$0780–$07FF`
and mirrored `$0000–$007F`, with source frame/cycle, post-write PC, active PRG
banks, and old/new byte. At every `$C76E`, `$A117`, and `$C9C5` call, record
`$001B`, incoming carry, `$E1–$E3`, the three actual operand bytes, and the
resulting `$E1–$E3`; also record receiver writes at `$DB08/$05FC` and the
controller/input state at the NMI poll. This should identify which earlier
route routines initialize the mutable operands and when the `$001B.6` mode
switch occurs. The already successful frame-8399 checkpoint remains useful
for short repeated windows after that point, but cannot stand in for this
pre-checkpoint history. Do not use numbered FCEUX slots or promote trace values
to runtime constants.

For the separate stamina-state edge, use the same validated in-memory replay
method around field-loop PCs `$E349`, `$E14D`, `$E1F7`, and `$E2BC`; record each
input edge and whether `$E349` takes the B/menu exit before `$E14D`. This gives
the production route a source event for `report_eligible_field_loop_iteration()`
without advancing the provider from rendered frames or guessed delays. Existing
late-route captures can bound this work, but cannot supply runtime inputs.
