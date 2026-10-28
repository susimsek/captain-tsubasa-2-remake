# First-command scenario `$FA`/`$FB` stack source audit — 2026-10-28

## ROM identity and mapping

This audit uses the supplied Turkish ROM, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
Bank `$10` begins at file offset `0x020010` and maps to CPU `$8000`; therefore
CPU `$80F6` maps to file `0x020106`. This mapping was checked against the
target ROM bytes. The saved ranges and hashes are listed in
[`scenario_continuation/manifest.json`](scenario_continuation/manifest.json).

## What the fixed scenario-start caller initializes

The fixed-bank path `$EC08–$EC33` is file `0x03EC18–0x03EC43`. After calling
the bank-`$10` scenario reader at `$8000`, `$EC2C` loads `$00` and `$EC2E`
executes `STA $0522`. This clears the continuation depth. It does not clear
the eight payload bytes `$051A–$0521`.

The continuation payload is four two-byte return-pointer slots. The caller
must provide the current script pointer `$5D/$5E`, byte index `$3A`, depth
`$0522`, and those eight stack bytes if it wants to execute nested control
flow. Each stored pointer is little-endian.

## `$FA` pushes a script pointer

Bank `$10` `$881A–$8836` is file `0x02082A–0x020847`, 29 bytes. Its bytes
load `$0522` into X, compute `$5D + $3A + 2`, store that 16-bit return pointer
at `$051A,X`, increment X twice, store the new depth to `$0522`, and jump to
`$80F6`.

The target loader `$80F6–$8104` is file `0x020106–0x020114`, 15 bytes:
`B1 5D AA C8 B1 5D 85 5E 86 5D A9 00 85 3A 60`. It reads the two-byte target
operand at `($5D),Y`, installs it in `$5D/$5E`, clears `$3A`, and returns to
the scenario interpreter. The exact CPU-to-file mapping matters here: file
`0x0200F6` maps to CPU `$80E6` and is the tail of the terminal routine, not
the `$80F6` loader.

## `$FB` pops or ends a root stream

Bank `$10` `$8837–$8852` is file `0x020847–0x020862`, 28 bytes. It subtracts
two from `$0522`. If the resulting byte is negative (the root-depth
underflow, `$00 → $FE`), it jumps to `$80CF`. Otherwise it reads the saved
little-endian pointer from `$051A/$051B` plus the new depth, restores `$5D/$5E`,
sets `$3A=0`, and returns to the interpreter.

The `$80CF–$80F5` root terminal handler is file `0x0200DF–0x020105`, 39 bytes.
Among its cleanup it stores zero to `$0522`; it also changes other flags and
RAM and performs `PLA / PLA / RTS`. The helper reports only the source-backed
script-stack result. It does not model those cleanup writes or the outer
6502/task return path.

## Fresh-route consequence

The preserved bank-`$10` streams `$1E`, `$35`, `$36`, and `$44` are
pointer-bounded in
[`first_command_scenarios/manifest.json`](first_command_scenarios/manifest.json).
Each has no `$FA` byte and ends in `$FB`:

| Stream | CPU span | File span | Length | Root terminator |
|---|---:|---:|---:|---:|
| `$35` | `$B7CD–$B7D4` | `0x0237DD–0x0237E4` | 8 bytes | `+7` |
| `$44` | `$B7D5–$B7D9` | `0x0237E5–0x0237E9` | 5 bytes | `+4` |
| `$1E` | `$B7DA–$B7E3` | `0x0237EA–0x0237F3` | 10 bytes | `+9` |
| `$36` | `$B7E4–$B809` | `0x0237F4–0x023819` | 38 bytes | `+37` |

Given the fixed caller's `$0522=0`, each of these source `$FB` opcodes takes
the `$80CF` root-terminal path. In this route slice, `$051A–$0521` are stale
payload and are not read by `$FB`. That does not establish the scheduler's
scenario dispatch order, the origin of each scenario ID in a production
Godot route, or the outer CPU/task stack state.

## Bounded implementation and remaining integration inputs

[`bank10_scenario_continuation_stack.gd`](../../../scripts/gameplay/bank10_scenario_continuation_stack.gd)
checks the preserved source bytes against the manifest and models only these
ROM-backed pointer-stack effects. Its focused verifier is
[`verify_bank10_scenario_continuation_stack.gd`](../../../tools/diagnostics/verify_bank10_scenario_continuation_stack.gd).
`Bank10ScenarioBytecodeReader` separately reports `SOURCE_TERMINATED` for one
of these four exact hash-checked streams only when the caller supplies
`continuation_depth: 0`; missing depth, nested depth, and modified/non-route
bytes remain external continuations. The scenario-$44 callback byte API uses
that explicit depth-zero case. Neither helper is wired into
`KickoffRouteRuntime`, which still lacks the source-owned scenario pointer,
byte-index, and task/scheduler transitions needed to advance a live route.
The separate callback, worker, and actor paths remain outside scope; see
[`first_command_scenario_event_continuation_audit_20261028.md`](first_command_scenario_event_continuation_audit_20261028.md)
for their evidence boundary.
