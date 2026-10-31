# Fresh KICK OFF `$A006` entry — 31 Oct 2026

## Scope and source identity

This increment establishes only the source transfer from the fresh caller's
`$811C JSR $A006` into the target body. It does not execute the body or return
to `$811F`.

- Supplied ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- iNES header: 16 bytes; 16 × 16 KiB PRG units (32 × 8 KiB MMC3 banks);
  mapper `$04` (MMC3).
- PRG bank `$01` selected in MMC3 register 7 maps CPU `$A000-$BFFF` to file
  offset `0x002010 + (CPU - $A000)`.
- `$A006-$A008` is preserved at file offset `0x002016`, length 3, SHA-256
  `d823d82f6c345fe92558a284727617cdea76ce9d9c6b32bdd01e44a18bfd8af3`.
- Target body `$A4EB-$A610` is preserved at file offset `0x0024FB`, length
  294, SHA-256
  `1897387554b3047615392719f5a00c32f4ceb24e56645c64fe7d8a11a3ed3587`.
- Exact extraction is reproducible with
  `tools/gameplay/extract_fresh_prematch_a006_sources.py`.

The vector bytes are `4C EB A4`, so the three-cycle instruction is
`JMP $A4EB`. The preserved target body ends at `$A610 RTS`. Its early code
clears and loads pre-match state, copies ROM table data into `$0468-$049B`,
uses several bank-$02 helpers, and enters a `$9FA8` yield/input loop before
later branches. The helper and task effects, later control path, and return
state have not been implemented here.

## Runtime executor contract

`RomFreshPrematchA006Entry.execute_source_call()` consumes:

- A source event for exactly `$811C->$A006->$811F`.
- CPU PC/SP and a full stack page containing the caller's actual JSR return
  word `$811E`.
- The source-owned mapper state showing PRG bank `$01` in `$A000-$BFFF` and
  RAM `$0025=$01` from the preceding mapper selection.

It verifies the caller instruction and bank-$01 vector, executes only the
`JMP`, advances PC to `$A4EB`, and preserves registers, stack, RAM, and mapper
state. Its output is a **transfer receipt**, not an RTS receipt. It does not
accept FCEUX register, stack, RAM, PPU, or cycle data as runtime input and does
not claim source-frame timing.

The component is not yet connected to `KickoffRouteRuntime`; the caller chain
still needs a live mapper event and entry state, and this transition does not
advance the visible scene by itself.

## Focused verification

Godot 4.7.2 ran
`tools/diagnostics/verify_rom_fresh_prematch_a006_entry.gd` successfully. The
verifier checks the packaged source hashes, source JSR/stack contract, three
cycle JMP result, unchanged pass-through state, and refusal of a wrong bank,
target, or missing stack. Its caller event and stack page are explicit test
fixtures, not a live route replay.

The `$A4EB` body, the `$811F` return, caller-to-route integration, field output,
and audio are still unverified by this component.
