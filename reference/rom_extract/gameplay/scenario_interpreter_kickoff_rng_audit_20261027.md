# KICK OFF scenario interpreter and receiver-state audit — 2026-10-27

## Scope and ROM identity

This is a static-byte trace of the supplied Turkish ROM, from cutscene 2's
return through the first in-match command panel. No emulator was controlled
for this audit. PPU/RAM captures are cited only as independent checks, not as
runtime data or as a source for the receiver value.

- ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- PRG bank `$10` occupies file range `0x020010–0x023FFF`; CPU `$8000` maps to
  `0x020010`. This places the scenario pointer table and streams in the
  `$8000–$BFFF` window.
- The cutscene-2 return and match-start context are summarized in
  [`fresh_start_to_first_command_menu.md`](fresh_start_to_first_command_menu.md).

## Route after cutscene 2

The bank-0 caller at `$8157` dispatches ID 2; `$815A` waits through the same
`$82B5` A/Select helper used by ID 1. On return, `$815D–$8163` applies the
new-game flag mask and jumps to `$8017`, which enters bank-$02 startup at
`$A203` (file `0x004213`). That path reaches `$A2AF` and fixed-bank kickoff
setup `$DAAA` (file `0x03DABA`). On the fresh match-index-zero path, the
kickoff initializer:

1. selects the left/home side (`$05FB=0` when opponent `$002B=3`);
2. writes scenario ID `$35` through `$CBB0`;
3. waits for held A or B (`$001C & $C0`); and
4. chooses the receiver, writes scenario ID `$36` through `$CBB0`, stores the
   chosen player in `$0441`, and enters field setup at `$E0DF`.

The source bytes at `$DAAA` / file `0x03DABA` include the call sites for
`$CBB0`, `$C50F`, and the A/B poll. `$CBB0` (file `0x03CBC0`) is a small
scenario-start helper:
it stores A to `$0518`, writes `$80` to `$0516`, clears `$0005`, and calls
`$C50F`. Thus `$35` and `$36` are scenario IDs in `$0518`; neither is an audio
queue write.

## Bank-$10 scenario reader

The target-ROM reader begins at bank-$10 `$8000` (file `0x020010`):

- `$8000` jumps to `$8006`; `$8003` is the other bank entry.
- `$8006–$8020` reads `$0518`, doubles it, and loads a pointer from table base
  `$89BF` (file `0x0209CF`). Scenario `$35`'s word is `$B7CD` at file
  `0x020A39`; `$36` is `$B7E4` at `0x020A3B`; `$44` is `$B7D5` at
  `0x020A57`.
- `$8021–$803E` initializes per-run state, including `$052A/$052B/$052C/$052D`,
  `$0530`, and the byte index `$3A`.
- `$803F–$80A8` reads a record. If its first byte is below `$F0`, it consumes
  exactly four bytes: field 1 → `$0523`, field 2 → `$0524`, field 3 → `$0528`,
  field 4 → `$0529`. Each of the latter three fields has its own inline
  `$F0+` transformer at `$8991`, `$899C`, or `$89A7`. After the four fields,
  the reader advances its source pointer and prepares its worker using X=`$15`,
  `$0016=$F0`, `$0017=$0B`, A=`$80`, Y=`$08`, then calls `$C50F`.
- `$C50F` is a jump-table trampoline to `$CAE7`. It seeds the task's initial
  stack return address and marks the requested slot ready; the scheduler maps
  bank `$0B` and resumes at `$8009 → $814C`, the event-selector callback. The
  fixed-bank slot scan, mapper/stack restore, NMI-ready latch, and the separate
  per-frame actor loop are documented in
  [`first_command_scenario_worker_lifecycle_20261027.md`](first_command_scenario_worker_lifecycle_20261027.md).
- If the first byte is `$F0–$FF`, `$803F` calls the opcode dispatcher at `$80A9`.
  The table follows its `$C509` call at `$80BF` (file `0x0200CF`):

| Opcode | Handler | Byte-backed effect relevant to the reader |
|---|---:|---|
| `$F0` | `$80CF` | Clears `$052A`, applies the `$0516` flag transition, calls `$C51B`, clears `$0522`, and masks `$21`. |
| `$F1` | `$80D4` | Shared `$0516`/`$C51B` transition without the `$052A` clear. |
| `$F2` | `$80F4` | Replaces `$5D:$5E` with the following pointer word and resets `$3A`. |
| `$F3` | `$8105` | Conditional/relative stream control through `$816E`; full meaning not needed by the documented initial `$35/$36` prefixes. |
| `$F4/$F5/$F6` | `$87E0/$87E6/$87EC` | `$F4` writes `$40` to `$052A`; `$F5` writes `$00`; `$F6` XORs `$40` with the existing `$052A` value. Target-ROM handler bytes are at files `0x0207F0`, `0x0207F6`, and `0x0207FC` respectively; `$F5` is an immediate zero write, not a bit-clear operation. |
| `$F7/$F8` | `$87F5/$87FF` | Read one following byte into `$052B` / `$052C`. |
| `$F9` | `$8809` | Read a following word into `$0530/$0531`. |
| `$FA/$FB` | `$881A/$8837` | Push the continuation address to `$051A` using `$0522`, then pop/restore it. `$FB` jumps to `$80CF` if the stack is exhausted. |
| `$FC` | `$8853` | Read one following byte into `$052D`. |
| `$FD` | `$885D` | Read one following byte, pass it through `$886A`, and store the result to `$052A`. |
| `$FE/$FF` | `$88E3/$88ED` | Dispatch condition handlers and test the current ball-holder/player state; not required to explain the shown `$44` packet. |

The event's first field `$0523` becomes the wait counter `$0519` at fixed-bank
`$EC94` (`0x03ECA4–0x03ECA7`). The countdown is `DEX; STX $0519` at
`$ED5B–$ED5E` (`0x03ED6B–0x03ED6E`). This establishes the source wait handoff
and decrement, but not its exact gameplay release phase or wall-clock frame
timing; see the worker-lifecycle audit above.

## Initial scenario stream prefixes

The following boundaries follow the target handlers above. These are byte
sequences and handler assignments, not a claim that all visual side effects
are implemented:

- Scenario `$35`, `$B7CD` / file `0x0237DD` begins:
  `F9 EB 44 | 02 3A 8F 73 | FB`. The former longer `$35` prefix shown here
  was stale and mixed bytes from later route scenarios. The separate `$44`
  stream starts at `$B7D5` / file `0x0237E5`; `$1E` starts at `$B7DA` / file
  `0x0237EA`; `$36` starts at `$B7E4` / file `0x0237F4`. Their pointer-bounded
  byte spans and hashes are preserved in
  [`first_command_scenarios/manifest.json`](first_command_scenarios/manifest.json).
- Scenario `$36`, `$B7E4` / file `0x0237F4` begins:
  `F5 | F9 02 7F | 10 3A 8F F0 | F9 02 66 | 20 0C 4E 74 | FD 00 |
  F9 09 2B | 32 72 66 F0 | F7 02 | 32 1F 4C F0 | F9 1D 2C |
  3E 01 E6 75 | FB | 01 71 00 00 | F7 1F ...`
- Scenario `$44`, `$B7D5` / file `0x0237E5` begins:
  `02 70 5C F0 | FB | FD ...`.

The `$44` four-byte record sets `$0523=$02`, `$0524=$70`, `$0528=$5C`, and
`$0529=$FF` after the inline `$F0` parameter handler. The bank-$10 reader
therefore selects event/animation `$70` with sequence parameter `$5C`; the
ROM path that resolves `$70` to CHR pair `$3C/$2E` is separately documented in
[`first_command_field_background_producers_20261027.md`](first_command_field_background_producers_20261027.md).

## B-to-command-panel transition

After `$E0DF` enters the fresh left-possession field loop, `$E349` checks the
new/held B input on the home-team branch. It clears the defender count/flag,
starts scenario `$44` through `$CBB0`, switches to banks `$1A/$1B`, and jumps
to bank-$1A `$803C` (`0x03404C`). That handler sets `$044E=0` and `$0621=0`,
then calls `$D575->$D5C3` to draw descriptors `$02` (action prompt) and `$03`
(player/status). The exact code and initial unselected input state are in
[`first_action_menu_input_rom_trace_20261027.md`](first_action_menu_input_rom_trace_20261027.md).

The scenario stream is not an audio command list. Its parser writes its
parameters to `$0523–$0529` and schedules event work; the parser and `$CBB0`
helper contain no direct `$0700` store. Actual route audio writes are enumerated separately in
[`first_match_audio_source.md`](first_match_audio_source.md). Do not interpret
scenario ID `$35`, `$36`, or `$44` as a sound request because those values also
exist in the sound pointer table.

## `$E2` seed, update path, and receiver calculation

The reset vector at file `0x04000C` points to `$FFF0`; the reset stub at
`$FFF0` jumps through fixed-bank `$C503->$C64E`. `$C64E` clears CPU RAM
`$0000–$07FF` with a page loop (`$00/$01` pointer, Y over 0–255, eight pages).
Thus the source initializes `$E1/$E2/$E3` to zero; this conclusion does not
depend on a captured RAM value.

On the bank-$02 controller-read path, after the two eight-bit controller loops,
the RNG entry executes `CLC` at `$A116`; `$A117–$A127` then updates the
three-byte state:

```text
$E1 = $E1 + $83
$E2 = $E2 + $0D + carry_from_E1
$E3 = $E3 + $11 + carry_from_E2
```

The NMI vector `$C500->$C76E` branches to the banked frame path at `$C421` when
bit 6 of `$001B` is set. `$C421` selects bank `$02` and calls `$A000`; that
routine performs the controller reads and reaches the `$A116` entry once after
its read loops (`$A117` begins with `LDA $E1`). This gives a source-driven update rule, not a simple “one increment per
elapsed frame” rule: the count depends on how often the mode-gated bank-$02
path runs. The byte-checked NMI branch at file `0x03C77E` is
`24 1B 50 03 4C 21 C4` (`BIT $001B; BVC +3; JMP $C421`): bit 6 set chooses
the special bank-$02/controller path; bit 6 clear falls through to the normal
body at `$C775`. That normal body calls `$C9C5` at `$C7E4`, then `$C982`, and
sets the scheduler-ready bit 7 of `$001B` at `$C7EE`. Thus these are alternative
NMI routes selected by a source mode flag, not two increments that can be
applied on every rendered frame.

The fixed-bank `$C9C5` routine (file `0x03C9D5`) updates `$E2` through two
`ROL $E2` operations and an `ADC $E2`/`STA $E2`, then updates `$E3` and
increments `$E1`. Its indexed operands are `$0300,X`, `$0700,X`, and `$0780,X`
with `X=$E1`. It has no entry `CLC`/`SEC`; the first `ADC` consumes carry from
its normal-NMI caller path. A generic runtime calculation therefore needs the
current contents of those arrays and carry state, as well as the NMI mode/call
sequence. The ROM-only stepper has that state because it executes the route;
the current Godot helper instead replays per-call results from one input-hash
schedule.

At kickoff, fixed-bank `$DAEF–$DB19` computes the receiver from the current
`$E2` byte: `i = $E2 & 7`; if `i >= 5`, subtract 5; then use `$DC82[i]` and add
`$05FB`. For match zero, `$05FB=0` and `$DC82` is `05 06 07 09 0A`. `$05FC`
holds the selected slot; after helper `$E6EC`, the code starts scenario `$36`,
copies `$05FC` to `$0441`, and enters gameplay.

The existing frame-end capture validates one example: at frame 8782 it has
`$E2=$11` and `$0441=$06`, consistent with index 1 and `$DC82[1]=$06`. The
earlier cold-start snapshots also show the first `$0D` update after the
zeroed state. These samples validate the formula, but are not used as seeds or
defaults.

**Cold-start-through-receiver source-model result:** the ROM-only source CPU/PPU
stepper was rerun from reset with the recorded route input timeline merged from
`reference/diagnostics/kickoff_select_test_20261027/opening_replay.csv` and
`reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv`
(SHA-256 `6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc`). The
timeline supplies input only; no captured RAM value was used to seed or steer
the run. The instrumented run reached the receiver store at `$DB08` on source
frame 8593, cycle 255894821, with `$E2=$BE`; the ROM calculation selected
`$05FC=$06` (`$BE & 7 = 6`, subtract 5, then `$DC82[1]=$06`).

The run executed `$A117` 8446 times, from frame 9 through frame 8458, while
the `$001B` mode gate routed NMI through `$C76E->$C421->$A000`. It then executed
the separate `$C9C5` helper 133 times by receiver selection, from frame 8461
through frame 8593; each invocation writes `$E2` at `$C9CE/$C9D3/$C9D9`.
The source-derived schedule is packaged at
`assets/gameplay/rom_logic/kickoff_rng_source_schedule.json`, and
`scripts/gameplay/rom_kickoff_rng_source_replay.gd` consumes it from a cold zero
state. `tools/gameplay/build_kickoff_rng_source_schedule.py` reconstructs the
input timeline from the two retained input logs; the timeline hash is checked
before generation. The helper requires the caller to provide the observed
input-timeline hash and rejects any other route identity.

**Post-run validation:** target FCEUX RAM dumps are not inputs to the schedule
builder or the Godot helper. The helper was compared against all 3901 available
route RAM dumps through frame 8593; `$E1/$E2/$E3` matched in every dump. At the
selection frame, both helper and target dump have `$E1/$E2/$E3=$7F/$BE/$3C`
and `$05FC=$06`. A separate source-stepper run continued through frame 8782;
its `$E2` matched all 4090 available dumps through that frame, including the
captured `$E2=$11` and `$0441=$06`. This establishes reproducibility in the
existing ROM-only source-clock model for this exact recorded input route. It
does not establish physical NES oscillator/input-sampling timing or make the
stepper a complete runtime CPU. A new input sequence can change task/mode call
counts; the schedule therefore carries a strict route/timeline identity and
must not be reused as a general random-number implementation. A general
dynamic `$C9C5` interpreter still needs the ROM-derived runtime values at
`$0300/$0700/$0780` for arbitrary routes. Do not hardcode `$06` or captured
`$E2` values into gameplay state.

## Safest Godot connection and remaining gaps

The safe Godot-facing contract (proposed; not currently implemented) is
`set_scenario_id(id)` → ROM-table pointer → a source-byte reader that
distinguishes four-byte events from `$F0–$FF` control opcodes, exposes the
event fields and wait byte, and emits typed events to presentation.
Keep `$35`'s held A/B gate in the kickoff state machine; then derive receiver
from the modeled `$E2` state; start `$36`; on the first left-team B input edge,
start `$44` and open context-0 command UI. The scenario ID must remain separate
from the audio cue API.

Do not use a capture-timeline substitute or ship a partial VM as the original
scenario executor. The current trace does not fully reconstruct `$C50F` task
resumption, every event producer/consumer, mapping restoration, NMI phase, or
all `$E2` update call sites. Those are the remaining requirements before a
runtime VM can claim route-level source equivalence.
