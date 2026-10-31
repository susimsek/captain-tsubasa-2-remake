# Slot-$09 scenario-active `$EC10` source audit — 2026-10-29

## Finding and stop boundary

On the fresh route, `$CBB0` stores scenario ID `$35` at `$0518`, sets
`$0516=$80`, clears `$0005`, and yields through `$CB0F`. When the resumed
slot-$09 root reaches `$EB9B->$EC08`, `$EC08` masks `$0516` with `$81`; the
nonzero result takes `$EC0D->$EC10`. With live `$0519=$00`, that path selects
the scenario pointer, initializes the scenario reader, processes the first
`$F9 EB 44` opcode and record `02 3A 8F 73`, and seeds callback task slot
`$15`. It then returns through bank-$10 `$80A8 RTS` and fixed `$EC74 RTS` to
the slot-$09 caller at `$EB9E`.

The bounded source path therefore ends at `$EC74 RTS`; it does not execute the
new callback task. The immediate next CPU consumer is the slot-$09 caller at
`$EB9E`, which continues into `$ED85`; that caller continuation is outside
this audit. After slot `$09` reaches its source save and scheduler scan, the
newly seeded callback task's next consumer is the actual slot-$15 dispatch
(`$8009->$814C` in bank `$0B`), with the source-produced task record and stack.

This report uses the supplied Turkish ROM, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`, iNES
1.0, mapper 4, no trainer. File offsets below include the 16-byte iNES header.
They were compared directly with the supplied file. No emulator was used.

## Hash-bound source spans

| CPU range | ROM mapping | File offset | Length | SHA-256 | Role |
|---|---|---:|---:|---|---|
| `$EC08-$EC74` | fixed `$1F` | `0x03EC18` | 109 | `59d874d29579bc7c94c7b15bf51480c5608004787289236797b648454589e424` | Gate, scenario-active setup, first callback-task creation, return |
| `$CE2D-$CE49` | fixed `$1E` | `0x03CE3D` | 29 | `6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c` | MMC3 register 6/7 helper |
| `$8000-$80A8` | scenario reader pair `$10/$11`; code begins in `$10` | `0x020010` | 169 | `2dec09a271880aacb98e9cbb555f8dccf21479dacc47580c3bd871e01ef272de` | Pointer resolver, reader initialization, record decode, slot-$15 seed call |
| `$80A9-$80CE` | bank `$10` | `0x0200B9` | 38 | `b22a45b7a2f1c6edc80a9fd896bac16792341761384fe9cb56e8525738465cb3` | `$F0+` opcode dispatcher and inline target table |
| `$8809-$8819` | bank `$10` | `0x020819` | 17 | `d4de2a1e704812eb7f8a0e8d959fdf4aefe0decf5a8e6933bc9edec941d2dfcc` | `$F9` operand reader |
| `$8A29-$8A2A` | bank `$10` | `0x020A39` | 2 | `751bb4c1d1d35f0a3f3c86304dffe714c0c1a6483af6e233ecff031004a22bc3` | Scenario `$35` pointer-table entry, bytes `CD B7` |
| `$B7CD-$B7D4` | upper `$11` member of selected `$10/$11` pair | `0x0237DD` | 8 | `02848b8b324fe6c120e6eb26bca5d0c08cab23baa91cf7820db454a3f78544df` | Scenario `$35` stream: `F9 EB 44 02 3A 8F 73 FB` |
| `$C509-$C50B` | fixed `$1E` | `0x03C519` | 3 | `3b507ee4745afd5b11dda219b523c39c7e9a8881d856592d8908bf535fd63441` | Scenario-opcode trampoline to `$CB99` |
| `$CB99-$CBAF` | fixed `$1E` | `0x03CBA9` | 23 | `1f8058f9fd70aeec319a32433feb0c102c72e0f5131571a0da8bf89ef84a2d54` | Inline opcode-table dispatch |
| `$8097-$80A8` | bank `$10` | `0x0200A7` | 18 | `2d69d726177fe1eb737aab04622108e5860b03d4fd95a5182538c4bae7d982db` | Slot-$15 callback-task parameters and `$C50F` call |
| `$C50F-$C511` | fixed `$1E` | `0x03C51F` | 3 | `0ea4efd43ee0e2e3d1b9528351bc433e11207744845df22bfaa7bf0e335f08d0` | Task-create jump to `$CAE7` |
| `$CAE7-$CAF6` | fixed `$1E` | `0x03CAF7` | 16 | `139a8a1b3241ae60cebf1052683d3947c20f219b728ab98e2429ee2a0f3e3a55` | Source task-stack seed and ready-slot write |
| `$CBB0-$CBC1` | fixed `$1E` | `0x03CBC0` | 18 | `bda16c7ced2834027dd6039a6c079a701dc8abd9c89179ba2d3c568aa0a16a32` | Upstream scenario `$35` producer |

The scenario extraction package identifies `$B7CD` as part of logical bank
`$10`. For exact MMC3 8 KiB mapping, the reader pair selects `$10` at
`$8000-$9FFF` and `$11` at `$A000-$BFFF`; CPU `$B7CD` and file offset
`0x0237DD` are in that upper `$11` window. Keep the pair label and physical
8 KiB window distinct when consuming this stream.

## Branches and ordered effects

The following is the ROM's source order for the observed fresh state. RAM
values are required inputs or source outputs; the trace is corroboration, not
runtime state.

1. **Scenario gate.** `$EC08` loads `$0516`, masks `$81`, and branches at
   `$EC0D`. `$0516=$80` takes `$EC10`. At `$EC10`, `BIT $0516` sees N=1, so
   `BPL $EC34` is not taken. `$EC15-$EC19` writes `$01` to `$0516` and pushes
   A.
2. **Select the scenario pair and resolve its stream.** `$EC1B-$EC2B` sets
   `$24/$25=$10/$11`, calls `$CE2D`, restores A, and calls `$8000`. The
   bank-$10 vector jumps to `$8006`; it reads live `$0518`, doubles the ID,
   indexes table `$89BF`, and writes the resulting pointer to `$5D/$5E`.
   For source-produced `$0518=$35`, table entry `$8A29` is `CD B7`, so the
   resulting pointer is `$B7CD`. The code then writes `$0022=$00` and
   `$0539=$00`.
3. **Choose the first fresh wait branch.** `$EC34` loads `$0519`; zero takes
   `$EC3C` and clears `$0532/$0534/$0536/$0538/$0539`. Nonzero jumps to
   `$ED5B`, which this audit does not execute. The next `$0516` checks do not
   take `$EC75`, `$EC8C`, or `$EC74` early branches for the initial `$01`.
   `$EC62-$EC71` remaps `$10/$11` and calls `$8003`.
4. **Initialize and decode the scenario stream.** The `$8003` vector jumps to
   `$8021`. It copies `$0517` to `$052A`, clears bit `$04` of `$0516`, zeros
   `$052B/$052D/$052C/$0530/$3A`, then reads the stream through `$5D/$5E`.
   The first byte `$F9` dispatches through `$80A9`, `$C509`, and `$CB99` to
   `$8809`; that handler reads following bytes `$EB/$44` into `$0530/$0531`
   and advances `$3A` past its three-byte token.
5. **Read the event record and seed its callback task.** The four bytes at
   stream offset 3 are `$02 $3A $8F $73`. Since each is below `$F0`, the
   reader takes its direct-field paths: writes `$0523=$02`, changes
   `$0516` from `$01` to `$41` via `(value | $40) & $EF`, then writes
   `$0524=$3A`, `$0528=$8F`, and `$0529=$73`. It advances `$5D/$5E` to
   `$B7D4`, the following `$FB` byte, then reaches `$8097` before reading that
   terminator.
6. **Create the next task and return.** `$8097-$80A8` sets X=`$15`, writes
   `$0016=$F0`, `$0017=$0B`, loads A/Y=`$80/$08`, and calls `$C50F`.
   `$C50F->$CAE7` writes `$01F1=$08`, `$01F2=$80`, and `$0015=$FF`; the live
   stack/task record therefore requests a ready slot-$15 dispatch in bank
   `$0B`. `$CAE7 RTS` returns to `$80A8`; `$80A8 RTS` returns to `$EC74`; the
   audit stops at `$EC74 RTS`.

`$CE2D` writes MMC3 selector/data registers through CPU `$8000/$8001` to map
registers 6 and 7 as `$10/$11`; the helper updates `$23` from the live `$22`
shadow. It is called twice in the active path. No instruction in the bounded
path writes PPU registers `$2000-$2007` or APU registers `$4000-$4017`, and
the bank-$10 reader/task seed does not execute a PPU/APU producer. Any normal
NMI or later `$814C` callback effects are separate source paths and are not
included in this claim.

## Live producer inputs and remaining unknowns

- Required: the actual slot-$09 scheduler dispatch, its full RAM image, stack
  page, CPU registers, and MMC3 state; `$0516=$80`, `$0518=$35`, and
  `$0519=$00`; the current `$22` mapper shadow; and `$0517`, copied to
  `$052A`. The `$0516/$0518` values are produced by the source `$DAD8->$DADA`
  caller and `$CBB0`; the second-wrapper call must be integrated into the
  production route before this state can be claimed live.
- `$CBB0` does not write `$0519`, `$0517`, or `$22`. `$0519=$00` is the
  same-input trace value for the first scenario reader pass, not an output of
  `$CBB0`; the runtime consumer must use the live values and reject an
  unsupported nonzero `$0519` branch rather than injecting the trace value.
- Existing same-input observations record `$CBB0` with A=`$35`, followed by
  `$803F` and `$8097` scenario-reader/task-setup events on frame 8467. The
  existing task-boundary trace reports `$0516/$0518=$01/$35` at the reader
  and `$41/$35` at task setup. No hook in that trace claims instruction-by-
  instruction verification of `$EC10`; this report establishes that branch
  from ROM bytes and treats the trace as route corroboration only.
- The callback task is seeded but not dispatched here. Its later `$814C`
  script, PPU/background side effects, field rendering, and audio are not
  established by this boundary. `$0522` continuation payload semantics and
  the purpose of `$0530/$0531` for this F9 operand remain outside this slice.

## Runtime-consumer contract and acceptance boundary

The future production consumer should accept only the runner's actual
slot-$09 dispatch after the source `$CBB0` scenario producer. It must execute
the checked `$EC08->$EC74` and bank-$10 path from that live CPU/RAM/stack/
mapper context; require `$0516&$81 != 0`, derive `$0518` and pointer `$5D/$5E`
from ROM, and branch on live `$0519`. For the observed first route, it should
emit the ordered source writes above and a slot-$15 seed (`FF F0 0B` plus the
`$01F1/$01F2=$08/$80` stack bytes), then stop before the scheduler dispatches
slot `$15` or the slot-$09 caller continues past `$EC74`.

Focused acceptance should compare the source PCs, ordered RAM/mapper writes,
final PC `$EB9E` after the return, task record/stack seed, and absence of
PPU/APU writes. It must reject mutated source bytes, injected endpoint RAM,
and nonzero `$0519` until that branch is independently mapped. This boundary
does not establish visible field output or command-menu behavior.

## Related evidence

- [Slot-$09 post-slot-$05 live continuation](slot09_post_slot05_resume_20261029.md)
- [Same-input CBB0/scenario-$35 route trace](first_command_post_c515_to_scenario35_fceux_trace_20261029.md)
- [Full first-command task-boundary trace](first_command_task_boundary_trace_20261028.md)
- [Scenario reader/task source manifest](scenario_task_runtime/manifest.json)
- [Task seed and scheduler byte manifest](task_context/manifest.json)
- [Scenario record and callback ownership audit](first_command_scenario_event_continuation_audit_20261028.md)
