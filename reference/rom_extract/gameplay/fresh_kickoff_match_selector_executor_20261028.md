# Fresh KICK OFF match-selector execution boundary — 28 Oct 2026

## Source identity and bounded path

`RomFreshMatchSelectorExecutor` executes the supplied Turkish ROM's fresh
match-index-zero path through its real outer RTS. It reads packaged ROM spans,
not the `.nes` at runtime, FCEUX state, screenshots, or a frame schedule.
The focused manifest identifies ROM SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`, checks
the caller/trampoline/selector/roster spans, and preserves the ROM bytes copied
by the nested helper. `tools/gameplay/extract_fresh_kickoff_match_selector_sources.py`
creates that source package from the supplied ROM and validates the ROM hash.

The checked source path is:

```text
$80FA JSR $A20F
$A20F JMP $A86E
$A86E LDA $26 / CMP #$06 / BCC $A87C       ; fresh $26=0
$A87C LDX #$00 / JSR $A8B7
$A8B7 JMP $A138                             ; Turkish ROM bytes
$A138 copies $ACB0-$BFFF to $6000-$734F
$A1E4 LDA #$0B / STA $ED / JMP $A8BB
$A8BB-$A8CD copies 11 roster IDs to $0300+12*n
$A8CD RTS -> $A881
$A8A3-$A8B6 derives $2C/$2A/$2B; RTS -> $80FD
```

`$A8B7` is a three-byte tail-jump in this ROM, not the loop described at that
address by the navigation disassembly. Its `$A138` target has no further JSR
callout on this path: it copies 4,944 bytes of ROM data to PRG RAM, then jumps
to the shared `$A8BB` roster-copy body. This check prevents accidentally
executing the disassembly's differing `$A8B7` bytes or treating the following
bytes as code at the wrong PC.

The executor emulates the executed source instructions and records writes,
register/flag state, stack contents, branch/return PCs, and a no-interrupt
instruction-cycle total. NMI service and elapsed route timing are outside this
component.

## Explicit caller preconditions

The helper does not create its call event. A caller must supply:

- An identified `$80FA->$A20F` source event, return PC `$80FD`, pre-JSR SP, and
  the full 256-byte post-JSR stack page with the correct stacked word `$80FC`.
- Explicit A/X/Y/P/SP/PC at `$A20F`, after the preceding `$80F7->$C4B9` mapper
  call. The helper verifies `X=$02`, `$25=$02`, `$23=($22 | $07)`, A equals
  `$23`, and N/Z flags match A.
- Caller-owned RAM `$22/$23/$25/$26`, with fresh match index `$26=$00`.
- Explicit `Y=$00`. `$A138` uses `(pointer),Y` while copying from `$ACB0` to
  `$BFFF`; the executor refuses other Y values rather than assuming their
  page-cross and destination behavior.

No production caller currently supplies this full state contract. This is an
isolated executable component, not evidence that `KickoffRouteRuntime` now
reaches the selector or that the return is source-clock aligned in the live
route.

## Verification and next boundary

Focused Godot 4.7.2 verifier:

```sh
godot --headless --audio-driver Dummy --path . --script tools/diagnostics/verify_rom_fresh_match_selector_executor.gd --quit-after 5
```

It passes the match-zero branch, all 4,944 ROM-to-PRG-RAM bytes, the eleven
roster writes, `$ED/$2A/$2B/$2C`, both RTS targets, preserved outer stack word,
and returned A/X/Y/P/SP. It also rejects nonzero match index, nonzero Y, and a
malformed caller stack. The test's call ID is labelled as a verifier fixture;
it is not a captured or production caller receipt.

The fresh KICK OFF caller resumes at `$80FD`, clears `$28/$29/$27`, queues the
stop request, and then reaches the next unresolved synchronous call `$810F
JSR $A20C` (return `$8112`). Its bank-$02 target/normalization routine still
needs a source-executing return contract. Do not route around that call by
seeding selector outputs or by accepting trace RAM as runtime state.
