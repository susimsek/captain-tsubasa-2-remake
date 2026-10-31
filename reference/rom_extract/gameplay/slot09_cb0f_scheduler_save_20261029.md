# Slot-$09 `$CB0F` save and scheduler wait boundary — 2026-10-29

## Result

The live route now consumes the actual `$EBD7` executor result from the
`$87E6` zero branch, executes the source-proven `$EB88->$CB0F` task save, then
runs the bounded scheduler scan to `WAIT_FOR_NMI_READY`. The route stops there
and requires the caller to provide the next external NMI. It does not
synthesize a frame/NMI or execute later slot-$09 loop checks.

## Source and input contract

ROM SHA-256:
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
The root-loop source package is `slot09_ebd7_root_checks/manifest.json`:
fixed bank `$1F`, `$EB86-$EC07`, file offset `0x03EB96`, 130 bytes,
SHA-256 `91ee3ddc0110b7575a472103de8f5e4d1391a60efebe557b4f4238940d74f917`.
The handler is `task_context/manifest.json`, `$CB0F-$CB2C`, file offset
`0x03CB1F`, 30 bytes, SHA-256
`b6377644890b9cd6671e4e63f48da4dfe1bd4975870bb531cb684ee7aeda07fc`.

The save consumer accepts only the actual source executor result with the
matching ROM and manifests, `$052E=$00`, source-produced `$00=$09` and
`$24/$25=$18/$19`, A/X/Y=`$01/$00/$05`, SP `$78` after JSR, the exact ordered
`$EB88` stack writes, and `$EB8A` return word at `$0179-$017A`. It rejects
mutated RAM and results marked trace-derived. It adopts only those validated
JSR stack writes and the live bank pair; it never copies the executor's full
RAM image.

## Applied effects and next boundary

The checked `$CB0F` handler save yields slot record `[01,76,18,19]`, stores
saved Y/X=`$05/$00` at `$0177/$0178`, and preserves return `$EB8A` at
`$0179/$017A` (resume `$EB8B`). The scheduler cursor advances from slot `$09`
to `$0D`. Its next bounded scan checks empty slots `$0D,$11,$15`, keeps
`$001B` ready latch clear, and stops at `WAIT_FOR_NMI_READY` with cursor `$19`.
The live route result reports `awaiting_external_nmi=true` and
`nmi_cadence_generated=false`.

**Next required input:** a later externally observed NMI edge. This increment
stops before servicing that edge or resuming the saved `$EB8B` task. Later
nonzero `$052E` countdown and `$052F/$0027/$063F` helper branches remain outside
this route coverage.

## Changed files and focused verification

- `scripts/gameplay/rom_gameplay_task_scheduler.gd` — validates and applies the
  source `$CB0F` save using its pre-executed JSR frame.
- `scripts/gameplay/rom_fresh_kickoff_source_route_runner.gd` — feeds the live
  root result into the scheduler and returns the post-save wait boundary.
- `tools/diagnostics/verify_rom_slot09_cb0f_scheduler_save.gd` — checks the
  production route, save bytes, scan boundary, and rejection of altered inputs.

Ran only:

```text
godot --headless --path . --script tools/diagnostics/verify_rom_slot09_cb0f_scheduler_save.gd
```

Result: PASS on Godot 4.7.2. This establishes the modeled task-save and
scheduler wait transition only; it does not establish the next NMI's visible
PPU output or full match fidelity.
