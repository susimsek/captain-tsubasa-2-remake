# Entry-0 `EB` input wait trace

ROM: `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`  
SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`

This note traces the reachable entry-0 `EB` at CPU `$A326` through the
supplied ROM's bank-0 handler and fixed-bank controller reader. It uses ROM
bytes and existing RAM/input captures; it does not infer an EB activation
frame from the ordinary cold-start replay, which ends at the title screen.

## Dispatch and handler

The bank-0 command vector table starts at CPU `$8545` (ROM file `0x000555`).
The `EB` entry is the fourth little-endian vector, bytes `C3 85` at file
`0x00055B`, targeting CPU `$85C3` (file `0x0005D3`). The handler bytes are:

```text
88 20 9A 89 20 A3 89 20 B1 88 A9 01 4C 87 88
```

Decoded, it decrements Y, calls `$899A`, calls `$89A3`, calls `$88B1`, then
loads `A=1` and jumps to the interpreter's common return at `$8887`. The
input wait itself is in `$89A3`; `$899A` first sets `$99 = ($99 & $80) | $40`.
`$88B1` is reached only after the wait helper returns.

`$89A3` (file `0x0009B3`) begins by copying four bytes from the table at
`$88D2` into `$0564–$0567`. It then runs this loop:

```asm
$89B0  LDX #$F8
$89B2  LDY #$00
$89B4  LDA #$01
$89B6  JSR $9FA8       ; cooperative scheduler yield, one tick
$89B9  LDA $1E
$89BB  BMI $89CC       ; return when bit 7 is set
$89BD  INY
$89BE  CPY #$28
$89C0  BEQ $89A5       ; refresh the copied table, then restart counter
$89C2  CPY #$18
$89C4  BNE $89B2
$89C6  STX $0564       ; X is still $F8
$89C9  JMP $89B2
$89CC  RTS
```

Thus EB is an **indefinite input wait**: it checks after each one-tick
cooperative yield and returns when `$1E` has bit 7 set. The counter reaches
24 and writes `$F8` to `$0564`; at 40 it copies the remaining table bytes
through `$0567`, wraps Y, and restarts the 40-tick counter. No timeout branch
exists. The table refresh's final visible purpose is not established here.

## Which input does it wait for?

The bank-0 condition is exact: `LDA $1E; BMI`, equivalent to
`($1E & $80) != 0`. `$1E` is a newly-pressed edge mask, not a held-button
bitmap. In the fixed last PRG bank, the controller reader strobes `$4016`,
reads eight serial bits, and executes `LSR A` followed by `ROL $83` for each
bit. The first serial bit consequently lands in bit 7. It stores newly set
bits as `($001C ^ current) & current` at `$001E` (`$C9C4–$C9D0`). Under the
NES controller serial order, the first bit is **A**. So EB requires a fresh
A-button press edge; holding A from before that edge is not a substitute.

Evidence for the one-frame edge behavior is the existing title-menu Down
probe: the Down-only frame has `$1C=$04, $1E=$04`; the following no-input
frame has `$1C=$00, $1E=$00`. This confirms the newly-pressed representation
and active-high bit layout for a sampled direction. There is no existing
capture that presses A specifically while entry 0 is blocked at `$A326`.

Relevant source locations (file offsets include the 16-byte iNES header):

| Purpose | CPU address | ROM file offset |
|---|---:|---:|
| EB vector | `$854B` | `0x00055B` |
| EB handler | `$85C3` | `0x0005D3` |
| input-edge test / wait loop | `$89A3–$89CC` | `0x0009B3–0x0009DC` |
| controller edge construction | `$C980–$C9D3`, fixed bank | `0x03C990–0x03C9E3` |
| outer Start poll | `$8027–$8032` | `0x000037–0x000042` |
| scheduler yield routine | `$9FA8–$9FE0` | `0x001FB8–0x001FF0` |

## Relation to the outer Start poll

The reset routine's outer loop at `$8027` also yields once per tick via
`JSR $9FA8`, then checks `LDA $1E; AND #$10` and repeats while Start is not
newly pressed. A set Start edge falls through to the title-entry path, which
queues sound stop `$01` and loads the title setup. This is separate from EB:

- A (`$80`) releases the EB wait and allows the cutscene command stream to
  continue; by itself it does not satisfy the outer Start branch.
- Start (`$10`) satisfies the outer branch; by itself it does not satisfy
  EB's `$80` test.
- The handlers read `$1E` without clearing it, so the ROM code does not make
  the two masks mutually exclusive. A simultaneous A+Start edge satisfies
  both predicates in the byte-level logic. The exact same-frame task ordering
  and transition cleanup for that simultaneous case have not been captured.

The `$9FA8` scheduler saves task registers/state and dispatches cooperative
work. The EB helper yields through it on every poll, allowing other scheduled
work to run. The ordinary cold-start capture has no A press at `$A326`, and
there is no per-frame PC/task trace at that point; therefore the exact wall-
clock frame at which EB is first reached and the same-frame ordering against
Start remain unknown. The bytecode predicate, A/Start masks, and one-tick
polling loop are ROM-backed.
