# Bank-$10 route scenario inline-transform audit — 2026-10-27

## Target ROM and scope

This audit checks the preserved fresh-start scenario streams `$1E`, `$35`, and
`$36` against the supplied Turkish ROM, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`. It
documents only the record transforms and top-level route opcodes consumed by
the isolated reader in
[`bank10_scenario_bytecode_reader.gd`](../../../scripts/gameplay/bank10_scenario_bytecode_reader.gd).
The reader does not execute worker timing or follow an external `$FB` stack
return.

## Four-byte record fields and `$F0` transforms

The record parser begins at bank-$10 CPU `$803F`, file `0x02004F`. Its code
reads four bytes into `$0523`, `$0524`, `$0528`, and `$0529`. For fields two,
three, and four, values below `$F0` are passed through; values at or above
`$F0` call the respective inline transformer:

| Field | Call bytes and file span | Index-zero table bytes → target | Return bytes and result |
|---|---|---|---|
| `$0524` | `$8991`, file `0x0209A1`: `38 E9 F0 20 09 C5 99 89 A9 FF 60` | `99 89` at `0x0209A7` → `$8999` | `A9 FF 60` at `0x0209A9` → `$FF` |
| `$0528` | `$899C`, file `0x0209AC`: `38 E9 F0 20 09 C5 A4 89 A9 FF 60` | `A4 89` at `0x0209B2` → `$89A4` | `A9 FF 60` at `0x0209B4` → `$FF` |
| `$0529` | `$89A7`, file `0x0209B7`: `38 E9 F0 20 09 C5 B1 89 A9 FF 60` | `B1 89` at `0x0209BD` → `$89B1` | `A9 FF 60` at `0x0209C1` → `$FF` |

Each routine subtracts `$F0` from the field value and calls `$C509`. The fixed
bank entry at `$C509` / file `0x03C519` is `4C 99 CB`; its `$CB99` inline
pointer trampoline reads the selected word after the call. For the route's
actual `$F0` operands, the dispatch index is zero and the three local targets
above return `$FF`. The reader implements this exact case. It does not infer
other `$F1+` table indices from adjacent code bytes.

The selected route records use the field-four `$F0` transform:

- Scenario `$1E`, stream byte `+5`, file `0x0237EF`: `07 45 90 F0` →
  `$0529=$FF` after the inline transform.
- Scenario `$36`, stream byte `+4`, file `0x0237F8`: `10 3A 8F F0` →
  `$0529=$FF`.
- Scenario `$36`, stream byte `+20`, file `0x023808`: `32 72 66 F0` →
  `$0529=$FF`.
- Scenario `$36`, stream byte `+26`, file `0x02380E`: `32 1F 4C F0` →
  `$0529=$FF`.

## `$FD` transform dispatch

The bank-$10 `$FD` handler at `$885D`, file `0x02086D`, reads one operand,
calls `$886A` at file `0x02087A`, then stores returned X in `$052A`. The
dispatch call is followed by five little-endian target words at file
`0x02087D`:

```text
77 88 | AA 88 | B5 88 | BF 88 | D9 88
```

Only operands `$00` and `$02` occur in the preserved route streams:

- Scenario `$36`, stream byte `+15`, file `0x023803`: `FD 00`. This selects
  `$8877` / file `0x020887`. The handler reads `$0441`, resolves the current
  player's record through `$C50C`, and uses `$0638` through `$C536` before
  returning X. This byte reader lacks that runtime state, so it preserves the
  operand and returns an explicit context-required result. It does not
  calculate a mirror flag.
- Scenario `$1E`, stream byte `+0`, file `0x0237EA`: `FD 02`. This selects
  `$88B5` / file `0x0208C5`, bytes `A2 00 AD FB 05 F0 02 A2 40 60`. It returns
  X=`$00` when `$05FB=$00` and X=`$40` otherwise. The reader applies this
  directly only when the caller supplies `ram_05FB`; absent that context, it
  retains the raw operand and reports context required.

## Route opcode effects checked for the reader

The exact handlers used before the first external `$FB` return are:

| Opcode | Handler/file | Target-ROM bytes | Reader behavior |
|---|---|---|---|
| `$F5` | `$87E6` / `0x0207F6` | `A9 00 8D 2A 05 60` | Writes `$00` to `$052A`. |
| `$F6` | `$87EC` / `0x0207FC` | `A9 40 4D 2A 05 8D 2A 05 60` | XORs `$40` with `$052A`; requires its incoming value to report a concrete result. |
| `$F7` | `$87F5` / `0x020805` | `A4 3A E6 3A B1 5D 8D 2B 05 60` | Reads one source byte into `$052B`. |
| `$F9` | `$8809` / `0x020819` | `A4 3A B1 5D 8D 30 05 C8 B1 5D 8D 31 05` | Reads a little-endian source word into `$0530/$0531`; the reader records the bytes and does not execute it as a pointer. |
| `$FB` | `$8837` / `0x020847` | `AE 22 05 CA CA 8E 22 05 10 03 4C CF 80 BD 1A 05 85 5D BD 1B 05 85 5E` | Restores the continuation from `$051A` via `$0522`, or jumps to `$80CF` when empty. Current reader reports a root-source termination only for the four exact hash-checked route streams when caller depth is zero; nested/missing-depth cases remain external. See the 2026-10-28 stack audit. |

The `$F4/$F5/$F6` summary in
[`scenario_interpreter_kickoff_rng_audit_20261027.md`](scenario_interpreter_kickoff_rng_audit_20261027.md)
was corrected to match the handler bytes: `$F4` writes `$40`, `$F5` writes
`$00`, and `$F6` XORs `$40` with `$052A`.

## Limits

The player-record lookup/compare inside `$FD 00`, all unlisted `$FD` dispatch
targets, nonzero inline field-transform indexes, scenario worker timing,
`$FB` return-stack contents, and downstream event-worker effects remain outside
this reader. No frames, delays, or worker lifecycle are inferred here.
