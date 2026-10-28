# Title KICK OFF, Select skip, and automatic cutscene-2 dispatch

## Scope and ROM identity

This trace checks how the title's fresh `KICK OFF` branch enters cutscene 1,
how Select leaves a running story/cutscene, and how the ROM reaches cutscene 2.
It uses only the supplied ROM bytes and existing route captures; no emulator or
UI was opened for this audit.

- ROM: `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`
- SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`
- Bank-0 mapping: file offset `0x10 + (CPU address - $8000)`.
- Cutscene pointer table: bank 3 at file `0x006010`, CPU `$A000`.

## Title choice and cutscene-1 entry

The title input loop at `$80A2` masks newly pressed input with `$3C`, including
Select `$20`, Start `$10`, Up `$08`, and Down `$04`. Select on this screen is
the cursor-toggle path at `$80BC`; it does not skip the intro or start story
play. Start reaches the cursor test at `$80DF`:

```text
$80DF  24 ED       BIT $ED
$80E1  50 03       BVC $80E6
$80E3  4C 6A 82    JMP $826A       ; Continue branch
$80E6  20 A0 9B    JSR $9BA0
$80E9  A9 01       LDA #$01
$80EB  20 64 84    JSR $8464      ; install cutscene 1
$80EE  20 B5 82    JSR $82B5      ; wait for completion or Select skip
```

Here `BIT $ED` reads cursor-state bit 6: clear takes the KICK OFF path, while
set jumps to Continue. The KICK OFF branch loads cutscene ID `$01` and calls
the common dispatcher `$8464`. The target ROM's ID-1 pointer-table word is
`A1 A2` at file `0x006012`, resolving to `$A2A1` (ID 1 stream file
`0x0062B1`).

## What Select does in a running cutscene

The post-dispatch wait helper is at `$82B5` (file `0x0002C5`). Its loop and
shared completion cleanup are byte-checked in the ROM:

```text
$82B5  A9 01       LDA #$01
$82B7  20 A8 9F    JSR $9FA8      ; yield one cooperative tick
$82BA  A5 4D       LDA $4D
$82BC  05 4E       ORA $4E
$82BE  F0 06       BEQ $82C6      ; script pointer ended naturally
$82C0  A5 1E       LDA $1E       ; newly pressed buttons
$82C2  29 20       AND #$20      ; Select edge
$82C4  F0 EF       BEQ $82B5      ; otherwise keep waiting
$82C6  A9 00       LDA #$00      ; common cleanup, on either exit
$82C8  85 05       STA $0005
$82CA  85 06       STA $0006
$82CC  85 09       STA $0009
$82CE  85 0A       STA $000A
$82D0  85 11       STA $0011
$82D2  85 12       STA $0012
$82D4  85 0D       STA $000D
$82D6  85 0E       STA $000E
$82D8  85 4C       STA $004C
$82DA  A9 01       LDA #$01
$82DC  8D 00 07    STA $0700      ; stop/control audio request
$82DF  20 A0 9B    JSR $9BA0      ; clear/fade presentation state
$82E2  A9 00       LDA #$00
$82E4  85 44       STA $44
$82E6  85 45       STA $45
$82E8  85 7A       STA $7A
$82EA  85 7B       STA $7B
$82EC  60          RTS
```

Select does not write zero to `$4D/$4E` and does not jump to a separate story
script. It exits the caller's wait by clearing cooperative task state, queues
`$01`, runs `$9BA0`, and returns to the same caller. The common cleanup is also
used when the worker ends naturally. The live route capture is consistent:
at source frame 7243, `$001E=$20` while `$4D:$4E=$A39B`; at frame 7258 the
pointer is still `$A39B` but `$E0=$C0`, so the pointer bytes are stale after
the skip and must not be used as the completion flag. The route's `$82DF`
post-store PC hook at frame 7243 corroborates the stop-command cleanup path.

There is a separate unskippable wait helper at `$82A9`:

```text
$82A9  A9 01       LDA #$01
$82AB  20 A8 9F    JSR $9FA8
$82AE  A5 4D       LDA $4D
$82B0  05 4E       ORA $4E
$82B2  D0 F5       BNE $82A9
$82B4  60          RTS
```

It never reads input. The fresh-start title caller uses `$82B5`, so its
Select-aware behavior is directly relevant; do not apply it to every ROM
waiter or to the cutscene VM's separate `$EB` A-button wait.

## Automatic cutscene-2 selection

After the first `$82B5` returns, the KICK OFF caller continues at `$80F1` with
new-game initialization. It normalizes the team/match state, queues the setup
music, and calls the pre-match setup routine before the cutscene table check.
The table branch at `$8145–$815C` uses the fresh match index `$26`:

```text
$8145  24 E0       BIT $E0
$8147  30 06       BMI $814F
$8149  A5 E4       LDA $E4
$814B  C5 26       CMP $26
$814D  B0 14       BCS $8163
$814F  AE 26 00    LDX $26
$8152  BD DC 83    LDA $83DC,X
$8155  F0 0C       BEQ $8163
$8157  20 64 84    JSR $8464      ; dispatch table-selected cutscene
$815A  20 B5 82    JSR $82B5      ; same natural/Select completion wait
$815D  A5 E0       LDA $E0
$815F  29 7F       AND #$7F
$8161  85 E0       STA $E0
$8163  4C 17 80    JMP $8017
```

At `$83DC` the table byte for index `$26=0` is `$02` (bank-0 file
`0x0003EC`). The dispatcher therefore receives ID 2 without another title
input or an explicit narrative-choice step. The ID-2 pointer-table word is
`26 A6` at file `0x006014`, resolving to `$A626` (ID 2 stream file
`0x006636`). Its own `$82B5` wait also accepts Select, then returns to the
caller at `$815D` and onward to `$8017`.

Existing live route evidence matches the static result: the initial title
Start is at frame 4693; Select at 7243 reaches the helper cleanup; the source
trace hooks `$A626` at frame 7409; and `$26=$00` is present in the first-menu
RAM snapshot. These observations corroborate the automatic ID-2 route, though
the route capture did not hook every helper entry or byte of the wait loop.

## Route VM implications

- Keep title Select behavior as cursor movement; Start on the initial KICK OFF
  selection starts the fresh route.
- During each cutscene wait, a newly pressed Select cancels the active ROM task
  and applies the same `$01` audio stop/cleanup semantics. Do not model this as
  script-pointer zeroing or as an A-button press; A remains the `$EB` dialogue
  advance edge.
- After ID 1 reaches natural `$FF` or is Select-skipped, continue the same
  KICK OFF caller through setup, then auto-dispatch ID 2 when the table value
  for the current fresh match index is nonzero. Do not pause on a manual
  “between cutscenes” confirmation.
- After ID 2 completes or is skipped, return to the post-match-setup route
  caller; it is not yet the first field action menu.
- The ROM implements these transitions with task slots and banked helpers.
  A Godot VM can model their observed effects without pretending to execute
  the original 6502 instructions.

Related evidence: `fresh_start_to_first_command_menu.md`,
`kickoff_cutscene_timing_audit_20261027.md`,
`kickoff_first_command_menu_trace_20261027.md`, and the supplied-ROM bytes
listed above.
