# ROM Reverse Engineering and Godot Remake Plan

> This file is the implementation sequence, not a second status log. `GOAL.md`
> owns the current objective and progress; `AGENTS.md` and the project skills
> own durable workflow and evidence rules. Later phases do not expand the active
> endpoint by themselves.

## Current work package

**Resume the source-owned task after `$C515/$CB0F`, then trace the NMI-ready
release and task continuation through the second `$EF7F` call and `$DAD9`
scenario-`$35` enqueue.** `$DAD8` is the scenario operand; `$DAD9` is the enqueue
call boundary.

- Reuse the muted, signature-checked frame-8399 FCEUX checkpoint only when its
  ROM, input prefix, frame, and RAM/PPU/mapper signature match. Follow the
  reusable checkpoint procedure in
  `.agents/skills/nes-reverse-engineering/references/fceux-project-workflow.md`.
- Trace the ready event, restored stack/bank/SP context, and enqueue in source
  order. Do not replace missing source behavior with a frame delay or injected
  state.
- Integrate the resulting source-backed transition into the production route
  before starting an unrelated decoder. Keep exact source spans, traces, and
  comparisons in focused `reference/` reports.

**Acceptance:** two same-input trace passes agree; source bytes and ordered
state changes are recorded; the production route consumes the decoded
transition; no state is seeded from a trace. Stop at `$DAD9`, then update this
work package to the next unintegrated source event.

## Active milestone boundary

Start at the title screen's selected `KICK OFF` option and stop at the first
in-match command menu with no action selected. Do not confirm a soccer action or
enter `CONTINUE`. The completed cold-start opening/title slice and its measured
status are summarized in `GOAL.md`.

## Workflow references

Follow the ROM evidence, asset provenance, FCEUX checkpoint, and fidelity rules
in `AGENTS.md` and `.agents/skills/nes-reverse-engineering/SKILL.md`. Keep exact
bytes, traces, and comparison reports under `reference/`; link to those records
instead of copying their contents into this plan.

## Work plan

### 1. Close the active KICK OFF-to-first-menu slice — ACTIVE

- [ ] **Connect the fresh-start source route.** Compose the verified title
  branch, fresh-match bootstrap, fixed task scheduler, callback/task
  continuations, bank-$10 scenario workers, bank-$14 actor updates, and
  source-owned input/NMI events in execution order. Never start from copied
  frame snapshots.
- [ ] **Resolve live match state.** Produce formations, player records,
  possession, active holder/receiver, RNG operands, and route flags from their
  verified ROM writers and real call sites. Integrate existing isolated
  resolvers only when their inputs are supplied by the live route.
- [ ] **Produce the kickoff field.** Decode scenario-driven background,
  camera/scroll, CHR/palette, actor animation, OAM, IRQ/raster, and PPU queue
  work. Resolve the documented viewport/registration residual from source
  state; do not add an unverified pixel offset.
- [ ] **Reach the first command menu from normal play.** Install it only after
  the ROM-owned field loop and menu request/state are present. Preserve the
  observed initial “no action selected” state; map directional selection and
  confirmation to the observed inputs. Stop before action confirmation.
- [ ] **Make route audio source-driven.** Trigger and stop BGM/SFX from decoded
  ROM setup/scenario events. Investigate the documented cue-55 event-time and
  PCM differences; do not compensate with guessed frame delays or captured
  WAV input.
- [ ] **Compare same-input output.** Replay the same start/input sequence in
  FCEUX and Godot. Compare visible frames, cursor/menu state, source event order,
  frame/cycle timing, and audio samples. Add only focused comparisons for the
  current gap.
- [ ] **Prove standalone operation.** Launch a clean project copy without the
  `.nes` ROM, FCEUX, or diagnostic captures. Confirm the route still reaches
  the specified endpoint.

**Exit gate:** ordinary KICK OFF input reaches the first command menu without
test-only state injection; the menu is usable; same-input differences are
measured and documented; no soccer action or Continue flow is entered; runtime
has no ROM/emulator dependency.

### 2. Establish reusable ROM maps and decoders

- [ ] Maintain a bank map and byte-verified disassembly index for fixed and
  switchable PRG banks, RAM/WRAM, PPU registers/memory, mapper registers, and
  sound-driver entry points.
- [ ] Inventory tables and pointer formats for scene/script IDs, text, teams,
  players, formations, animations, backgrounds, palettes, sound tracks, and
  sound effects. Each entry should point to source bytes and name unresolved
  consumers.
- [ ] Build/reuse small decoders with explicit input/output contracts and
  hash-bound source spans. Keep parser/decoder verification separate from
  production-route integration.
- [ ] Maintain a behavior ledger: question, evidence class, ROM span, trace or
  external reference, implementation owner, current status, and next action.

### 3. Decode the complete match command loop — future scope

- [ ] Trace each menu and input branch from controller polling through
  precondition checks, resource costs, RNG calls, state writes, animations,
  audio cues, and return-to-field behavior.
- [ ] Decode movement and active-player selection, encounter/range rules,
  possession changes, passes, one-two passes, dribbles, tackles, blocks, shots,
  goalkeeper responses, and special moves.
- [ ] Reconstruct opponent decisions and randomness from ROM routines and
  source call order. Preserve deterministic seeds/inputs in replay evidence;
  do not substitute a guessed probability model where source behavior can be
  resolved.
- [ ] Represent authoritative match state separately from Godot presentation.
  Use explicit phases, action inputs/results, named costs/stats, and recoverable
  possession/transition handling as described by the gameplay skill.

### 4. Decode match lifecycle and campaign — future scope

- [ ] Trace kickoff, possession reset, goal/score updates, halftime, match end,
  win/loss/draw branches, and transitions to the next match.
- [ ] Decode story/cutscene scripts, text tables, character/scene identifiers,
  branch conditions, waits, animation commands, sound triggers, and script
  continuation rules.
- [ ] Map team/player databases, stats, levels, stamina/technique costs,
  formations, tournament schedule, save/continue records, and progression
  updates to their ROM readers/writers.
- [ ] Implement Continue/save/load only after the user expands the active scope
  beyond the current fresh-start first-menu endpoint.

### 5. Reconstruct all visual and audio paths — future scope

- [ ] Graphics: decode CHR tiles, palettes, nametable/tilemap/metatile
  compression, sprite descriptors/OAM, animation streams, scroll/camera,
  sprite priority, masking, IRQ/raster effects, and PPU update queues.
- [ ] Text/UI: decode tile-based text, glyph mapping, windows, menus, cursor
  movement, blinking, text speed, and input timing from original data/routines.
- [ ] Audio: map the ROM sound driver and track/SFX tables; decode command
  streams, channel state, tempo, envelopes, DMC state, trigger/stop ownership,
  and source-clock timing. Compare the selected renderer/mixer with FCEUX and
  report residuals rather than labeling unmatched PCM exact.
- [ ] Package extracted/converted project-owned resources with source manifests
  and checksums. Never bundle the full ROM or diagnostic-only captures.

### 6. Integrate, verify, and close each milestone

- [ ] For every milestone, retain one canonical input script and a verified
  emulator checkpoint near the target interval. Confirm checkpoint signatures
  after every load.
- [ ] Verify the smallest relevant slice: source bytes, decoder output, live
  state transitions, rendering/audio output, and clean runtime import/startup.
- [ ] Keep regression outputs under `reference/diagnostics/`; keep decoded
  source bytes/manifests under `reference/rom_extract/`; keep runtime-ready
  project assets under `assets/`.
- [ ] Update `GOAL.md`, source notes, and this plan together when evidence or
  implementation status changes. Do not duplicate long trace logs in this
  plan; link to their focused reports.
- [ ] Close a slice only when its exit gate is satisfied. Report measured
  mismatches and unmeasured hardware/desktop timing separately.

## External research already reviewed

The current source review is summarized in
`reference/rom_extract/gameplay/first_match_external_reverse_engineering_review_20261027.md`.
Japanese story/address references, Chinese editor/animation catalogs, Turkish
player/code lists, and a pinned English-translation disassembly provide useful
leads and some matching labels/bytes. They do **not** constitute a complete
disassembly or a fully decoded gameplay engine for this Turkish ROM. Continue
searching by specific unresolved table/routine questions, then verify each
candidate against the target ROM and local trace before adopting it.
