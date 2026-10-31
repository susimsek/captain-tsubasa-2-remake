# Select-to-fresh-match route gap — 31 Oct 2026

## Question

Why does the recorded KICK OFF route stop before reaching the fresh-match
handoff and first command menu?

## Finding

Cutscene IDs 1 and 2 now run a source-byte-checked model of caller `$82B5`
alongside the event VM. It polls once per Godot source tick, tests the VM
running state as a proxy for the ROM script pointer, and accepts a fresh
`$001E & $20` Select edge. The recorded-input route reaches ID-1 Select at
frame 7243; ID 2's 43 one-tick wait calls are exercised separately. The waiter
source span and loop prefix are size/hash/byte checked in
[`rom_cutscene_select_wait_task.gd`](../../../scripts/gameplay/rom_cutscene_select_wait_task.gd).

On either return, production records the shared task cleanup and applies the
ROM `$82DC` `$0700=$01` stop through the cue presenter. For ID 1, it runs the
`$99F0->$9A71->$9FA8` fade, applies the `$98A0` PPU clear and `$9B7F`
OAM/motion-record clears, and matches the frame-7258 same-input FCEUX PPU/RAM
snapshots. It also executes the checked `$82E2-$82EC` caller stores/RTS and
the ROM `$80F1-$80F7` prefix, including `$00E0=$C0`, then pauses at the
`$80F7->$C4B9` mapper call. It still does not execute the waiter's
actual CPU stack/task state. Its script-pointer input is a VM-state proxy, and
its per-tick calls do not claim CPU/NMI timing. Match setup and later automatic
ID-2 dispatch are not yet integrated.

## Source and trace evidence

- ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- The Select-aware caller and return path are byte-mapped in
  [`fresh_kickoff_caller_continuation_20261028.md`](fresh_kickoff_caller_continuation_20261028.md).
- `$9BA0` starts with `20 F0 99 20 A0 98 4C 7F 9B`: call `$99F0`, call `$98A0`,
  then jump to `$9B7F`.
- The `$99F0` loop bytes at bank `$00:$99F0` are
  `A5 4A 05 4B F0 16 AA F0 02 C6 4A A5 4B F0 02 C6 4B 20 71 9A A9 01 20 A8 9F
  4C F0 99 60`. It returns when both `$004A` and `$004B` are zero. Otherwise it
  decrements each nonzero counter, calls `$9A71` to stage the current palette
  packet in `$05E8`, yields through `$9FA8`, and repeats. The 15 yields after
  Select are these return-cleanup loop iterations; they are not extra
  `$82B5` wait-loop ticks.
- The signature-checked, muted two-pass trace in
  [`first_command_task_wait_call_trace_20261028.md`](first_command_task_wait_call_trace_20261028.md)
  records 15 bank-$00 `$9FA8` yields at `$9A06` on frames 8443–8457. The call
  site bytes at `$9A04` are `A9 01 20 A8 9F`; the task is `$0001`. The second
  call-site series ends before `$A2AF` is entered at frame 8458.
- Same-input frame-end RAM files in
  `reference/diagnostics/kickoff_select_test_20261027/ram/` show `$004A/$004B`
  as `$0F/$0F` at frame 8442, decrementing together on frames 8443–8457 to
  `$00/$00`. This older capture used the same input route but does not share a
  recorded checkpoint signature with the 2026-10-28 instruction-hook trace;
  treat it as corroboration, not the same trace pass.
- The same RAM series shows the earlier ID-1 cleanup countdown: `$004A/$004B`
  are `$0F/$0F` at frame 7242, then `$0E/$0E` at frame 7243 and decrement
  together to `$00/$00` at frame 7257. The frame-7258 snapshot has both at
  zero. These are frame-end observations, not instruction-phase proof.
- A later, focused muted two-pass trace pins the producer: ID-1 event 52 at
  `$A38B` is ROM `$E9`; task base `$05` runs `$998C` and increments both counters
  from zero to `$0F` over frames 7121–7135. No more counter writes occur before
  the caller's Select at frame 7243. The trace also records the 35-byte `$05E8`
  packet (three-byte `$3F00` header plus 32 palette bytes): every payload matches
  `$062A-$0649` converted by `$9EA2` at the decremented counters, and PPU palette
  state matches the preceding staged packet at frame ends from 7244–7257. See
  the [ID-1 cleanup palette trace](id1_select_cleanup_palette_trace_20261031.md).
- A two-pass trace identifies the count-up routine at bank `$00:$998C-$99AD`
  (file offsets `0x00199C-0x0019BD`). The routine increments `$004A` at `$9992`
  and `$004B` at `$999A`, caps each at `$0F`, and exits when their sum reaches
  `$1E`. From `$00/$00` at the signature-checked frame-8249 checkpoint, it writes
  each counter once per frame from 8256 through 8270. Exact bytes and trace
  provenance are in
  [`source_report.md`](../../diagnostics/first_command_004A_countdown_20261030_2311_utc/source_report.md).
  Static ROM mapping resolves its immediate call chain: `$8582` loads `$02` and
  calls the cooperative-yield helper at `$9FA8`; after resumption `$8585` calls
  `$997E`, whose setup reaches `$998C`. The outer task/callback that enters
  `$8582`, its live task context, and its production Godot connection remain
  unresolved. Do not treat the immediate call chain as a recovered route entry.
- A separate signature-checked handoff trace records `$A2AF` at frame 8458,
  `$AA06` at 8459, `$C557->$C6BE` at 8460, and the ROM scenario-$35 writes at
  `$CBB3/$CBB8` on frame 8467. See
  [`fresh_match_scheduler_handoff_trace_20261028.md`](fresh_match_scheduler_handoff_trace_20261028.md).

## Godot divergence

The focused same-input route verifier already showed `$0516-$0519` as
`$00000000` in Godot and `$01AC0000` in FCEUX at frame 8443. Godot has
scenario-$35 fields by frame 8450; FCEUX's frame-end RAM does not show them
until frame 8467. Godot's first slot-$11 yield is frame 8463, while the
independent FCEUX actor-worker hook first observes its `$8047->$CB0F` yield at
frame 8480. Those hook and frame-end observations have different sampling
boundaries, so they do not alone establish the exact seed/write cycle.

The verifier's diagnostic keys now name the raw RAM slices (`ram_0011_0014`,
`ram_0015_0018`, and `ram_001D_0020`) instead of implying that each slice maps
to a logical scheduler slot. Actual slot bases are `$01/$05/$09/$0D/$11/$15`.

## Godot `$E9/$EA` presentation model — 31 Oct 2026

`KickoffCutsceneCommandVm` now validates `$E9` and `$EA` event opcodes from the
ROM-derived cutscene streams. `$E9` runs its two-tick pre-wait, then advances
the modeled palette level toward `$0F`, yielding one source scheduler tick per
level. `$EA` runs its one-tick pre-wait, decrements the modeled level to zero
with one tick per level, then applies the source-confirmed zero-fill addresses
from `$2000` (16 rows) and `$2400` (32 rows). The visible renderer derives the
unfaded background and actor palettes from ROM-derived profiles/records and
uses the existing `$9EA2` fade lookup table.

Focused diagnostics passed:

- `godot --headless --path . --script res://tools/diagnostics/verify_kickoff_cutscene_command_vm.gd`
  — cutscenes `$01` and `$02` complete; source byte boundaries, event order,
  text cadence, E9/EA fade levels, waits, and `$FF` termination pass.
- `godot --headless --path . --script res://tools/diagnostics/verify_kickoff_fade_palette_presentation.gd`
  — selected E9/EA levels produce the expected ROM palette bytes and EA
  zero-fill addresses reach the presentation PPU memory.

This does not recover the outer task/callback or its live CPU/RAM/stack state.
The VM's aggregate fade level remains a source-event model rather than live
`$004A/$004B` RAM. The runtime uses that state to execute the byte-checked
`$99F0` loop and builds the `$05E8` packets from ROM-derived background and
sprite palettes; the 15 packets match same-input FCEUX frame-end snapshots. Its
next-tick presenter agrees with the observed one-frame palette commit, but it
does not execute the game's NMI consumer or establish CPU/PPU phase. The
byte-checked `$98A0/$9B7F` helpers now apply the verified frame-end PPU/OAM
effects; see the [cleanup helper spans](cutscene_cleanup_helpers/README.md).
The checked `$82E2-$82EC` caller block returns to `$80F1`. The route then
executes `$80F1-$80F7`: `LDA #$C0`, `STA $E0`, and `LDX #$02`, and stops at the
`$80F7 JSR $C4B9` boundary. Its contract records A=`$C0`, X=`$02`, Y=`$00`, and
known N/Z=`$00`; other status bits and absolute SP remain unspecified. The
caller’s `$0022` mapper shadow and logical stack have not been produced by live
source execution, so the mapper helper is not invoked.

## ROM caller Select integration — 31 Oct 2026

The ID-1 caller calls `$82B5` at `$80EE`; it does not proceed to ID 2 until
`$82B5` cleanup returns to `$80F1`. `KickoffRouteRuntime` now starts the same
source-byte-checked waiter for IDs 1 and 2. Replaying
`post_title_inputs.csv` from frame 4693 reaches the Select edge at frame 7243,
stops the event VM without converting Select to an A edge, and records the
shared cleanup plan at `$82DF`. The next caller PC recorded for ID 1 is
`$80F1`; ID 2's is `$815D`.

At `$82DC`, the route applies `$0700=$01` through
`GameplayRomCueAudioPresenter.apply_rom_sound_command` and records the source
PC, address, value, and frame. The ID-1 `$99F0` cleanup fade executes all 15
source-selected yields and matches each staged palette packet against FCEUX.
At frame 7258, `$98A0/$9B7F` effects match the same-input PPU/RAM snapshots; the
route then verifies the caller's `$82E2-$82EC` source block: `LDA #$00`, stores
to `$0044/$0045/$007A/$007B` at their ROM PCs, and `RTS`. The frame-7258 FCEUX
RAM image has the four cleanup bytes at zero and `$00E0=$C0`. Godot follows the
checked ID-1 JSR return to `$80F1`, executes the three supported caller
instructions, and pauses at `$80F7` before the mapper helper or automatic ID-2
dispatch.

Focused checks passed:

- `godot --headless --path . --script res://tools/diagnostics/verify_kickoff_cutscene_select_wait_integration.gd`
  — same-input ID-1 Select at frame 7243, `$82DC` audio stop, all 15 `$99F0`
  packet comparisons against FCEUX frames 7243–7257, `$98A0/$9B7F` PPU/RAM
  parity, the `$82E2-$82EC` cleanup and `$80F1-$80F7` caller prefix at frame
  7258, and ID-2's 43-poll wait.
- `godot --headless --path . --script res://tools/diagnostics/verify_kickoff_recorded_input_path.gd`
  — recorded route reaches the explicit ID-1 cleanup boundary at frame 7243.

## Required next work

1. Continue the source-owned caller at `$80F7` through match selection,
   normalization, pre-match setup and automatic cutscene-ID-2 dispatch. The
   required helper returns and caller state must be produced by source-backed
   components, not handoff receipts. Replace the VM-running Select proxy with
   the live `$4D/$4E` task pointer when its owner is identified.
2. Trace ID-2's natural completion and Select wait through cleanup and its
   caller handoff. Continue the live path through
   `$A203->$A2AF->$AA06->$C557->$C6BE`.
3. Re-run focused same-input checks through the frame-8467 scenario writer
   before using slot-$11 animation counters to guide further work; then close
   the live field presentation, command menu, and route audio gaps.

## Production integration boundary

`KickoffCutsceneCommandVm` is a presentation/event VM; it does not own CPU,
RAM, stack, or task state for the Select-aware ROM waiter. The route's gameplay
scheduler seeds its RAM only after the fresh-match handoff and cannot provide
the earlier slot-`$01` context or the return frame at `$9A06`. A live upstream
source transition must produce that context. The runtime needs to preserve the
slot-`$01` CPU/task/stack state, current mapper and PPU state, plus held and
newly-pressed controller masks as the Select waiter returns.

The `$99F0` loop now advances from VM-modeled counters and source-derived base
palette data. Each resumption with a nonzero counter decrements it, stages the
`$9A71` palette packet, and models the `$9FA8` yield at `$9A06`. ID-1 packets
match FCEUX through frame 7257; the later handoff reaches zero at frame 8457.
The 2026-10-28
instruction-hook trace confirms the later loop stages and yields on its last
decrement, then returns on the following slot-`$01` resume so the caller
reaches `$A2AF` at frame 8458. The `$A2AF` copy of `$99F0` then sees zero
counters and yields no additional tick.

The palette packet has a Godot presentation consumer with the observed next-
tick frame-end result; the game's live NMI queue consumer and exact PPU phase
remain unimplemented. `$0700=$01` reaches the audio presenter from the
source-identified `$82DC` store. `$98A0/$9B7F` now update the live presentation
and bounded RAM-write shadow, but Godot does not yet model the ROM's PPUCTRL/
PPUMASK register-shadow writes. Existing intro palette helpers or the handoff
planner's named receipts are not proof of these gameplay helper effects.

`RomFreshMatchHandoffExecutor` remains a write-plan projection. Its synthetic
helper receipts do not execute the ROM helpers, apply effects to live state, or
close this gap. A return-only component can stop at `$A2AF` entry; the planned
fresh-match bootstrap continues through the zero-counter `$99F0` helper calls,
`$98A0/$9B7F`, `$AA06` zero-fill, and `$C557`, then stops at `$C6BE` before its
task-slot stores.
