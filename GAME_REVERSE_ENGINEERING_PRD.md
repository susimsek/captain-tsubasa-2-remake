# Full Game Reverse-Engineering PRD and Issue Backlog

## Product Goal

Recreate the supplied Turkish *Captain Tsubasa 2: Super Striker* ROM as a standalone Godot 4.7.2 game. Decode the ROM's presentation and game logic, then implement the resulting screens, data, rules, audio, and progression in the project. The playable build must not require the ROM, FCEUX, or validation captures at runtime.

The intended product scope is the complete playable game: boot and title flow, team and player selection, story scenes, match setup, both sides of match decisions, action results, goals, match periods and results, tournament/campaign progression, and save/continue flow.

ROM-derived resources and decoded logic are runtime inputs. Emulator screenshots, captured video/WAV, memory snapshots, and save states are validation evidence only. Do not claim a screen or mechanic is exact until matching input, visible output, timing, and audio have been checked. State software/emulator timing evidence separately from physical NES hardware evidence.

## Developer Tooling Goal (Not Player-Facing)

Provide a local Godot development menu that shortens investigation of scenes,
music/SFX, matches, teams, and players. It is a development tool, not part of
the playable release. It must remain unavailable in release builds and must not
change the ordinary player route.

The tool should make partial decoding useful: list known ROM-derived content,
show unsupported or unresolved entries as such, and expose evidence/provenance
where available. It must not invent missing data or treat a debug-selected
state as proof of a normal-input ROM route.

## Current Repository Baseline

- `README.md` describes the current release as the opening sequence and title screen; match and story flows are not part of that release.
- `GOALS.md` and `PLANS.md` currently track the first confirmed match action. The title-to-first-command-menu slice is documented as the completed baseline; the PASS route and its full-route acceptance still have open work.
- The current first-action work is not a full-game implementation. `GOALS.md` explicitly leaves the full match loop, opponent AI, campaign, save/continue, and later story routes out of scope for that milestone.
- ROM extraction and trace evidence is extensive under `reference/rom_extract/` and `reference/diagnostics/`. Existing reports and runtime components must be reused before creating duplicate decoders.
- BGM and SFX index files cover sound-test IDs 00–39 and 40–99. ROM-derived runtime audio assets exist for a subset; a complete driver/asset/cue route is still work.
- First-action menu evidence includes selected player-name, position, and stat tables. This does not establish a complete packaged team/roster/formation database.
- There is no in-game developer menu. [`KickoffRouteRuntime.get_route_status()`](scripts/gameplay/kickoff_route_runtime.gd) already exposes route stage/source frame, cutscene/task state, active background, first-action menu, player context, and presentation gaps; it is a candidate read-only inspector source. Existing audio playback supports only a verified subset, and the cutscene event catalog does not cover the full story.
- The project has many offline diagnostics under `tools/diagnostics/`, but they are command-line/editor tools, not a content-complete in-game browser. Reuse their source reports and runtime APIs; do not call every verifier from the game UI.
- All three current export presets use `all_resources`; their exclusion filters do not yet name developer-menu resources. Keep the new tooling in a dedicated location and explicitly prove its exclusion from release packages in RE-107.
- Commit `576ee95` contains a `$5C` dialogue CHR raster hookup that was not verified before commit. Treat its scanline/bank timing as an open fidelity issue; do not regard the change as proven.

`GOALS.md` remains authoritative for the active milestone and its acceptance criteria. This backlog describes the larger product scope; it does not silently expand the current milestone. The Codex conversation goal may be paused while repository `GOALS.md` still says `ACTIVE`; reconcile that state before starting implementation chats.

## How to Use This Backlog

Start a separate ChatGPT Project chat for one issue and refer to it by ID, for example: **“Work on RE-011 only.”** Read-only audit issues can run in parallel. Implementation issues should use separate branches/worktrees or non-overlapping file ownership. Keep one integration owner for `GOALS.md`, `PLANS.md`, shared route code, and the shared FCEUX instance.

Each issue is complete only when it records the relevant ROM hash, PRG/CHR bank and source address/file offset, evidence and input context, production Godot consumer, a focused acceptance check, and unresolved gaps. If the source does not establish an answer, report the gap instead of guessing. Update the focused evidence report and concise `GOALS.md`/`PLANS.md` status when the active milestone changes.

Do not commit, push, publish, or merge unless separately requested. Keep repository Markdown in English.

External Japanese, Chinese, Turkish, and English sources are indexed in
[`reference/rom_extract/gameplay/full_game_external_research.md`](reference/rom_extract/gameplay/full_game_external_research.md).
Use the linked issue for each source lead; do not copy its values into runtime
until the target-ROM bytes and, where behavior is involved, same-ROM execution
support the claim.

The local developer menu is a separate tooling epic below. It supports the
active milestone but does not extend or replace the player-facing endpoint in
`GOALS.md`.

## Issue Template

Use this shape when splitting a task further:

```markdown
### RE-XXX — Short title
- Status: OPEN
- Type: Audit | Data | Runtime | Verification
- Depends on: RE-YYY (or None)
- Scope: One ROM table, one source transition, or one visible result.
- Deliverable: Named report/resource/consumer.
- Acceptance: Observable, source-backed result and a focused verifier.
- Not included: The next transition or unrelated subsystem.
```

## Epic 0 — Project Map and Current Milestone

### RE-000 — Create the Full-Game Evidence Coverage Matrix
- Status: OPEN
- Type: Audit
- Depends on: None
- Scope: Audit existing reports, ROM-derived resources, production consumers, and verifiers for each major game system. Do not repeat already verified extraction work.
- Deliverable: A compact matrix with columns for system, source evidence, runtime consumer, verification, known gap, and next issue ID.
- Acceptance: Opening/title, scenes/text, audio, teams/players, match state/actions, AI, campaign, and persistence each have an evidence-backed status or are explicitly marked unknown.

### RE-001 — Reconcile the Full-Game Roadmap
- Status: OPEN
- Type: Planning
- Depends on: RE-000
- Scope: Compare `README.md`, `GOALS.md`, `PLANS.md`, current runtime entry points, and this backlog. Define the game-wide goal and milestone sequence without deleting the evidence for the current PASS milestone.
- Deliverable: Updated goal/plan wording or a short decision record showing the full-game parent goal, current milestone, and the next milestone.
- Acceptance: A new chat can identify the active endpoint, its acceptance criteria, and its out-of-scope boundary without relying on conversation history.

### RE-010 — Verify the Live `$044E/$00E2` PASS Branch
- Status: OPEN
- Type: Audit / Runtime
- Depends on: None
- Scope: Compare the current ordinary-input Godot route with the same-input frame-9191 trace. Derive the current `$044E/$00E2` branch from the live source route; do not force selector 2 or `$B4B6`.
- Deliverable: Focused source report and, only if justified, the smallest production consumer/verifier change.
- Acceptance: The route derives the same selector and ROM record from source-owned writes; the verifier rejects a trace-seeded or hard-coded endpoint.

### RE-011 — Resume the Frame-9496 Actor Packet Wait
- Status: OPEN
- Type: Runtime
- Depends on: RE-010
- Scope: Resume the actor-$6D index-02 `$A21A` stream through the `$82F2->$C515` packet-wait boundary on the normal input route.
- Deliverable: Production route integration and focused verifier for the wait/release conditions.
- Acceptance: The route reaches the observed wait using its own state, validates the next source event, and does not seed FCEUX RAM.

### RE-012 — Reach the Next PASS Decision Wait
- Status: OPEN
- Type: Runtime / Verification
- Depends on: RE-011
- Scope: Continue the ordinary-input PASS route to the ROM-polled `$D5EA` wait and confirm holder `$0A`.
- Deliverable: Route checkpoint and focused decision-wait report.
- Acceptance: Same-input route reaches frame 9600's decision boundary; report whether a command menu is actually redrawn. Do not confirm a second action.

### RE-013 — Close the First-Action Slice Acceptance
- Status: OPEN
- Type: Verification
- Depends on: RE-012
- Scope: Compare same-input visible output, event timing, and ROM-derived audio through the first result; verify a fresh exported package without ROM/emulator/capture runtime files.
- Deliverable: Acceptance report and any narrowly scoped verifier updates.
- Acceptance: Each stated pass/failure is reproducible and unresolved visual, timing, and audio gaps are explicit.

## Epic 1 — ROM Content Catalogs

These are evidence-first tasks. Their outputs should prevent repeated searches and identify the exact decoder/integration issues still open.

### RE-020 — Build the Team and Tournament Pointer Map
- Status: OPEN
- Type: Audit
- Depends on: RE-001
- Scope: Locate ROM tables and bank switches for team IDs, tournament/cup groups, and opponent order. Document pointers and record boundaries only.
- Deliverable: Hash-bound table map under `reference/rom_extract/gameplay/`.
- Acceptance: Every mapped entry has a checked ROM span and unknown entries are marked; no inferred team order is presented as fact.

### RE-021 — Decode One Team's Roster Records
- Status: OPEN
- Type: Data
- Depends on: RE-020
- Scope: Decode one explicitly named team or one bounded contiguous record range: player IDs, name encoding/pointers, goalkeeper marker, and record lengths.
- Deliverable: Reproducible extractor plus a ROM-derived data file and provenance manifest.
- Acceptance: Extractor output matches the source bytes and an independent ROM span check. Repeat this issue by team/range until the roster table is covered.

### RE-022 — Decode Player Stats and Position Values
- Status: OPEN
- Type: Data
- Depends on: RE-021
- Scope: Map one player-stat/position record family, including units, scaling, and references to existing first-menu tables.
- Deliverable: Data schema, extractor, and source report.
- Acceptance: All fields have ROM-backed meanings or are explicitly labeled unknown; existing menu data is reused where its provenance matches.

### RE-023 — Map Special-Move IDs and Parameters
- Status: OPEN
- Type: Audit / Data
- Depends on: RE-020
- Scope: Decode one bounded move table or move family: ID, eligibility, command selection, energy cost, and linked result handler.
- Deliverable: Move-family source map and a machine-readable index.
- Acceptance: Every included move resolves to source bytes and a handler path; display names are not treated as complete rules.

### RE-024 — Map Formation and Lineup Data
- Status: OPEN
- Type: Data
- Depends on: RE-021, RE-022
- Scope: Decode the source formation, player-slot, starting-position, and selection constraints for one team group.
- Deliverable: Formation schema/resource with provenance.
- Acceptance: A verifier reconstructs the expected lineup and starting positions from ROM data.

### RE-025 — Map Campaign and Story Route Records
- Status: OPEN
- Type: Audit
- Depends on: RE-020
- Scope: Identify campaign order, unlock/branch conditions, post-match events, and scene IDs for one bounded route segment.
- Deliverable: Route graph with source pointers and conditional edges.
- Acceptance: Each edge is supported by ROM data or an observed trace; unknown branches remain marked.

### RE-026 — Verify Community Player and Roster Indexes
- Status: OPEN
- Type: Audit / Data
- Depends on: RE-020
- Scope: Cross-check the Turkish player-ID/name/lineup notes and the Chinese editor's roster-related catalogs against one bounded team in the supplied ROM. Treat the Turkish discussion about exceeding 21 national-team players as a ROM-hacking question, not proof of original-game capacity.
- Deliverable: A target-ROM player-ID, roster-slot, pointer, and revision cross-reference under `reference/rom_extract/gameplay/`.
- Acceptance: Every accepted ID and record boundary has a checked ROM span; editor-only or hack-only capacity is separated from original behavior. Link useful results to RE-021 and RE-024.

## Epic 2 — Graphics, Text, and Cutscenes

### RE-030 — Audit One Background's PPU/CHR Profile
- Status: OPEN
- Type: Audit / Runtime
- Depends on: RE-001
- Scope: Resolve one background ID from ROM record through nametable, attributes, palette, active CHR banks, and any IRQ/raster changes.
- Deliverable: One focused report, production renderer hookup if proven, and a same-input visible-frame verifier.
- Acceptance: Runtime mapping comes from ROM/source logic; first affected pixel timing is either measured or explicitly left open. Use this issue for the unverified `$5C` dialogue profile.
- Repeat: Create a separate issue for each background/profile family not covered by an established shared decoder.

### RE-031 — Decode One Cutscene Command Segment
- Status: OPEN
- Type: Audit / Runtime
- Depends on: RE-030
- Scope: Decode one bounded scene segment from script pointer through background/text/animation commands to its next source wait or scene transition.
- Deliverable: Event data, production VM consumer, and a focused route verifier.
- Acceptance: Ordinary input advances the decoded events to the observed endpoint; no fixed frame delay or injected route state substitutes for the ROM command.

### RE-032 — Resolve One Dialogue Glyph/Palette Path
- Status: OPEN
- Type: Audit / Runtime
- Depends on: RE-030, RE-031
- Scope: Trace one text line from source string bytes through glyph IDs, PPU queue writes, active CHR/palette, and visible pixels.
- Deliverable: Source mapping and one same-input line comparison.
- Acceptance: Text bytes and visible glyph pixels agree at a pinned source frame, or the precise scanline/fetch uncertainty is documented.

### RE-033 — Decode One Actor Animation Family
- Status: OPEN
- Type: Data / Runtime
- Depends on: RE-030
- Scope: Follow one actor's descriptor, OAM composition, animation index, frame selection, and timing source.
- Deliverable: ROM-derived animation data and production presenter integration.
- Acceptance: One complete animation sequence advances from ordinary route state and matches pinned emulator observations; captured OAM/screens are not runtime art.

### RE-034 — Verify One Scene Transition's Fade and Timing
- Status: OPEN
- Type: Runtime / Verification
- Depends on: RE-031
- Scope: Trace one scene fade/clear/wait/next-background transition.
- Deliverable: A transition-specific state trace and verifier.
- Acceptance: Palette and screen-state changes follow decoded source events; timing gaps are listed separately from visual content gaps.

### RE-035 — Close the Reachable Scene Coverage Matrix
- Status: OPEN
- Type: Integration / Verification
- Depends on: RE-030 through RE-034
- Scope: Inventory all reachable scene/background/text/actor families and link each to a completed issue or a bounded follow-up issue.
- Deliverable: Scene coverage matrix and representative route checks.
- Acceptance: Every reachable scene family has a ROM-derived runtime path and a verification status; uncovered IDs are listed rather than silently omitted.

### RE-036 — Verify External Scene, Effect, Background, and Portrait Indexes
- Status: OPEN
- Type: Audit / Data
- Depends on: RE-030
- Scope: Audit the pinned Chinese editor catalogs for RAM-field labels (`$0523/$0524/$0528/$052B`), background/portrait IDs, and scene-effect examples. Resolve one selected scene or move effect from the local ROM data through its live source writes to the production consumer.
- Deliverable: A conflict-aware field/ID map with target-ROM bytes, bank/file offsets, trace context, and links to RE-030, RE-033, and RE-050.
- Acceptance: Conflicting catalog labels remain marked until target-ROM evidence resolves them; no editor value or screenshot is used as runtime state or art.

## Epic 3 — Music and Sound Effects

### RE-040 — Map the ROM Audio Driver and Sound-Test Dispatch
- Status: OPEN
- Type: Audit
- Depends on: RE-001
- Scope: Map one driver entry, sound-test index dispatch, bank selection, channel setup, and stop/loop behavior.
- Deliverable: Driver call graph and address-index map.
- Acceptance: Track/SFX ID, source bank, entry address, and termination behavior are independently checked against ROM bytes.

### RE-041 — Render One BGM Track from ROM Data
- Status: OPEN
- Type: Data / Runtime
- Depends on: RE-040
- Scope: Reproduce one indexed BGM using the ROM sequence/driver or a documented ROM-derived offline renderer.
- Deliverable: Source manifest, generated runtime resource, and playback integration.
- Acceptance: Resource has ROM provenance and is compared to same-input FCEUX audio; captured WAV is not used as the runtime source.
- Repeat: Batch only a small contiguous set of tracks after the shared renderer is verified.

### RE-042 — Render One SFX/DPCM Family from ROM Data
- Status: OPEN
- Type: Data / Runtime
- Depends on: RE-040
- Scope: Decode one indexed SFX family, including DPCM samples where applicable.
- Deliverable: Runtime resource and sound-event mapping.
- Acceptance: Trigger, duration, channel/sample source, and same-input comparison are documented.

### RE-043 — Connect One Route's Audio Cues
- Status: OPEN
- Type: Runtime / Verification
- Depends on: RE-041 or RE-042 and the owning scene/action issue
- Scope: Connect decoded source events to the cue presenter for one route interval.
- Deliverable: Event-to-cue mapping and audio-route verifier.
- Acceptance: No duplicate, missing, or invented cue is introduced; same-input timing and PCM limits are reported.

### RE-044 — Account for the Complete Sound-Test Catalog
- Status: OPEN
- Type: Integration / Verification
- Depends on: RE-041, RE-042
- Scope: Reconcile every BGM ID 00–39 and SFX ID 40–99 with a ROM-derived runtime resource or a documented unresolved reason.
- Deliverable: Updated catalog coverage report.
- Acceptance: No catalog entry is counted complete solely because its label/index is known; source mapping, generated asset, and verification status are tracked separately.

### RE-045 — Map Scene Music Cues and Scene-Length Boundaries
- Status: OPEN
- Type: Audit / Runtime
- Depends on: RE-040, RE-043
- Scope: Use external music indexes and the production interview only as leads; map one bounded cutscene's ROM music command to its driver entry, sequence, start/stop/loop behavior, and scene transition.
- Deliverable: A scene-to-track event map and an updated ROM-backed audio report.
- Acceptance: Track identity and cue boundaries are verified from the supplied ROM and same-ROM trace. Historical statements that a song was composed to fit a scene do not substitute for sequence or APU evidence.

## Epic 4 — Match State and Player Decisions

### RE-050 — Establish One Match-State Record Family
- Status: OPEN
- Type: Audit / Runtime
- Depends on: RE-022, RE-024
- Scope: Decode one source state record family for ball holder, player positions, energy/stamina, score, or clock; keep each field's writer and units explicit.
- Deliverable: Typed Godot state model plus a ROM-backed state producer.
- Acceptance: State is produced by the ordinary route and is not seeded from a FCEUX snapshot.

### RE-051 — Decode the Shared Action Result Inputs
- Status: OPEN
- Type: Audit / Runtime
- Depends on: RE-023, RE-050
- Scope: Trace one shared calculation path for stats, energy costs, RNG inputs, and action branching.
- Deliverable: Deterministic source model and verifier for one chosen branch.
- Acceptance: Arithmetic, input bytes, and branches are pinned to ROM code/data; unmodeled randomness is not replaced by a guessed result.

### RE-052 — Complete the PASS Action Route
- Status: OPEN
- Type: Runtime
- Depends on: RE-013, RE-050, RE-051
- Scope: Use ordinary command selection/input to complete one pass, receiver choice, possession transfer, result presentation, and next decision wait.
- Deliverable: Production route integration and same-input verifier.
- Acceptance: One action only; holder/result and visible/audio response match the trace; no second command is confirmed.

### RE-053 — Complete the Dribble Action Route
- Status: OPEN
- Type: Runtime
- Depends on: RE-050, RE-051
- Scope: Decode and implement one normal dribble branch through its first decision result.
- Deliverable: A single source-backed dribble route.
- Acceptance: Entry conditions, cost, success/failure branch, state changes, result scene, and next wait are verified.

### RE-054 — Complete a Normal Shot Route
- Status: OPEN
- Type: Runtime
- Depends on: RE-050, RE-051
- Scope: Decode one normal shot through the keeper/result branch and first resulting player decision.
- Deliverable: One source-backed shot route.
- Acceptance: Shot command, ball/result state, visual/text/audio response, and next wait match same-input evidence.

### RE-055 — Implement One Special Shot Family
- Status: OPEN
- Type: Runtime
- Depends on: RE-023, RE-054
- Scope: Add one special-shot family, one move ID at a time, including eligibility and energy checks.
- Deliverable: Move data consumer and route verifier.
- Acceptance: A valid and an invalid prerequisite case follow distinct ROM-backed branches.

### RE-056 — Complete One Defensive Command Route
- Status: OPEN
- Type: Runtime
- Depends on: RE-050, RE-051
- Scope: Implement one defensive command family: tackle/steal, block/intercept, or marking. Keep each family as a separate issue if it uses a different handler.
- Deliverable: One handler and its first result transition.
- Acceptance: Input, opponent/player selection, calculation, possession outcome, and next wait are checked.

### RE-057 — Complete One Goalkeeper Response Route
- Status: OPEN
- Type: Runtime
- Depends on: RE-054
- Scope: Decode one keeper response branch (catch, punch, or miss) from shot entry to its outcome.
- Deliverable: One goalkeeper result branch and verifier.
- Acceptance: Keeper state and goal/no-goal result come from the ROM's branch logic and recorded inputs.

### RE-058 — Implement Goal, Score, and Kickoff Restart
- Status: OPEN
- Type: Runtime
- Depends on: RE-057
- Scope: Carry one goal result into score update, scene/result presentation, and next kickoff state.
- Deliverable: One goal-to-restart route.
- Acceptance: Score writes and next possession/start state match source evidence.

### RE-059 — Implement Match Clock, Halftime, and Full-Time Boundaries
- Status: OPEN
- Type: Runtime
- Depends on: RE-050, RE-058
- Scope: Decode one clock transition at a time: normal tick, halftime, or full time.
- Deliverable: Source-owned clock/period transition and verifier.
- Acceptance: Period, clock, score display, and next phase transition are checked against the ROM.

### RE-060 — Decode One Opponent AI Decision Family
- Status: OPEN
- Type: Audit / Runtime
- Depends on: RE-050, RE-051
- Scope: Trace one CPU-controlled decision family for a pinned match context.
- Deliverable: Decision inputs, branch model, and production consumer.
- Acceptance: AI choice is generated by decoded source state/rules; it is not hard-coded from one observed route.

## Epic 5 — Selection, Campaign, and Persistence

### RE-070 — Implement Team Selection to Match Setup
- Status: OPEN
- Type: Runtime
- Depends on: RE-020, RE-021, RE-024
- Scope: Implement one team-selection route and its transition to the ROM-derived lineup/match setup.
- Deliverable: Selection UI, selected-team state, and route verifier.
- Acceptance: Keyboard/controller selection and chosen team state match the source route.

### RE-071 — Implement One Tournament Progression Segment
- Status: OPEN
- Type: Runtime
- Depends on: RE-025, RE-070
- Scope: Implement one tournament segment from match result to next opponent/scene.
- Deliverable: One progression transition and verifier.
- Acceptance: The next opponent and story event derive from ROM progression data.

### RE-072 — Implement One Between-Match Story Segment
- Status: OPEN
- Type: Runtime
- Depends on: RE-025, RE-031, RE-071
- Scope: Implement one post-match dialogue/event segment and its next route edge.
- Deliverable: One scene chain with ROM-derived text and presentation.
- Acceptance: Input-driven progression and event branching reach the expected next source state.

### RE-073 — Decode Continue/Save Data
- Status: OPEN
- Type: Audit / Data
- Depends on: RE-020, RE-025
- Scope: Map one save/continue representation, validation, and resume path.
- Deliverable: Save schema and resume-state source report.
- Acceptance: Every persisted field is tied to a ROM writer/reader; do not infer a save format from one endpoint snapshot.

### RE-074 — Implement Continue and Resume
- Status: OPEN
- Type: Runtime
- Depends on: RE-073, RE-050, RE-071
- Scope: Implement validated save/continue selection and one resume path.
- Deliverable: Continue flow and save/load verifier.
- Acceptance: A saved ROM-derived state resumes at the correct campaign/match boundary without requiring the ROM or emulator at runtime.

### RE-075 — Implement One Player-Progression Update
- Status: OPEN
- Type: Runtime
- Depends on: RE-022, RE-023, RE-071
- Scope: Decode one post-match player-growth, experience, or move-learning update that is confirmed in this ROM revision. Japanese guide tables are hypotheses to check, including the reported experience-sharing rules and low-award bug after the France match.
- Deliverable: One state update path and a focused verifier.
- Acceptance: The before/after player record is produced by decoded source rules; unknown growth rules are not filled with genre assumptions.

### RE-076 — Verify Japanese Match-Rule Tables Against One ROM Path
- Status: OPEN
- Type: Audit / Runtime
- Depends on: RE-023, RE-051
- Scope: Cross-check one bounded Japanese community table claim about special-move eligibility, move strength, or Guts cost against the supplied ROM's data and the live action handler. Repeat as small follow-ups for other move families.
- Deliverable: A source-to-rule comparison linked to the move-family report and production action consumer.
- Acceptance: The chosen claim is confirmed, corrected, or rejected with exact target-ROM bytes and trace evidence; the external table is not copied as runtime data.

### RE-077 — Build a Manual-Driven Match Flow Acceptance Matrix
- Status: OPEN
- Type: Audit
- Depends on: RE-050, RE-070
- Scope: Convert the Japanese manual's screen and control descriptions into a checklist for team management, substitutions/tactics, set plays, penalties, and offense/defense command states. Use the Chinese gameplay guide only to nominate trace questions.
- Deliverable: A compact flow matrix mapping each user-visible case to the relevant ROM route and a follow-up issue, including RE-052 through RE-061 and RE-070.
- Acceptance: Every listed flow is marked ROM-confirmed, manual-only, contradicted, or not yet traced; no guide prose is treated as executable logic.

## Epic 6 — Whole-Game Integration and Release

### RE-080 — Complete One Full Match End to End
- Status: OPEN
- Type: Integration / Verification
- Depends on: RE-052 through RE-060
- Scope: Exercise a full match using ordinary inputs and decoded opponent decisions.
- Deliverable: Repeatable route definition, visible/audio parity report, and focused regression checks.
- Acceptance: Both halves, score changes, goals, restart, and final result reach the ROM-defined endpoint; fidelity gaps remain explicit.

### RE-081 — Complete One Campaign Route
- Status: OPEN
- Type: Integration / Verification
- Depends on: RE-070 through RE-074 and RE-080
- Scope: Play one full tournament/campaign route through its result and persistence transitions.
- Deliverable: Input route, state progression report, and regression verifier.
- Acceptance: Team, match, story, result, and resume transitions use ROM-derived data without endpoint injection.

### RE-082 — Verify the Standalone Full-Game Package
- Status: OPEN
- Type: Release / Verification
- Depends on: RE-081
- Scope: Build a fresh package and inspect its runtime dependencies/content.
- Deliverable: Export inventory and clean-environment launch/route result.
- Acceptance: The packaged game runs without the `.nes` file, FCEUX, screenshots, WAV captures, or reference diagnostics. Only necessary project-owned ROM-derived runtime resources are packaged.

### RE-083 — Run Full-Game Regression from Cold Start
- Status: OPEN
- Type: Integration / Verification
- Depends on: RE-081, RE-082
- Scope: Re-run the previously verified opening/title/first-menu behavior and the selected campaign route from a clean launch.
- Deliverable: One reproducible input route and combined regression report.
- Acceptance: Existing opening-to-menu parity is preserved, the full campaign route reaches its declared endpoint, and the package has no ROM/emulator runtime dependency.

## Epic 7 — External Reference Audits

These issues turn useful online material into bounded research questions. They
do not expand the current milestone by themselves. The source register is
maintained in
[`full_game_external_research.md`](reference/rom_extract/gameplay/full_game_external_research.md).

### RE-090 — Maintain the Version-Scoped External Source Register
- Status: COMPLETE
- Type: Documentation
- Depends on: None
- Scope: Record the Japanese, Chinese, Turkish, and English sources found for CT2, what kind of evidence each provides, its revision limits, and the relevant follow-up issue.
- Deliverable: `reference/rom_extract/gameplay/full_game_external_research.md`.
- Acceptance: Direct links, pinned GitHub revisions where available, source classifications, known conflicts, and issue mappings are recorded; the target Turkish ROM hash is stated.

### RE-091 — Cross-Check Japanese Experience and Level Tables
- Status: OPEN
- Type: Audit / Data
- Depends on: RE-075
- Scope: Compare one reported Japanese experience award, level threshold, or player-sharing rule with the target ROM's data and progression handler. Explicitly investigate the guide's claim of very low experience after the France match.
- Deliverable: A table of confirmed/corrected/rejected claims with ROM spans and trace links.
- Acceptance: Each selected progression claim is confirmed, corrected, or rejected with target-ROM evidence; guide values and bug reports are not copied as implementation facts.

### RE-092 — Audit Chinese Editor State and Effect Catalogs
- Status: OPEN
- Type: Audit / Data
- Depends on: RE-036, RE-050, RE-051
- Scope: Inspect pinned text/catalog files only for the editor's `$0523/$0524/$0528/$052B` field meanings and one documented special-shot/effect example. Do not run the Windows editor or rely on its modified-ROM behavior.
- Deliverable: Field writer/reader map and one end-to-end effect trace, linked to RE-023 and RE-036.
- Acceptance: Each accepted field is tied to a local ROM routine and same-ROM state transition; conflicting or unsupported labels remain hypotheses.

### RE-093 — Resolve Chinese Background and Portrait Catalog Conflicts
- Status: OPEN
- Type: Audit / Data
- Depends on: RE-030, RE-033, RE-036
- Scope: Compare the editor's `$0524` background list with its collated `$0524/$0528` notes and resolve one selected background/portrait/effect ID on the target ROM.
- Deliverable: A conflict table with banked source mapping and one renderer/actor consumer link.
- Acceptance: The chosen entry maps to ROM-derived tiles, palette, nametable/OAM rules, and an observed route event; mismatched community labels are retained as conflicts.

### RE-094 — Validate External Glyph and Cutscene-Animation Indexes
- Status: OPEN
- Type: Audit / Data
- Depends on: RE-031, RE-032, RE-033
- Scope: Validate one Chinese `CT2_J` character mapping and one cutscene animation-ID description against the Turkish ROM's bytecode, CHR, actor descriptor, and visible result.
- Deliverable: One text-code mapping and one animation mapping added to the focused scene evidence.
- Acceptance: The mappings are confirmed from ROM bytes and production consumers; external names do not stand in for palette, frame order, or timing.

### RE-095 — Derive Match-Flow Cases from the Japanese Manual
- Status: OPEN
- Type: Audit
- Depends on: RE-077
- Scope: Prioritize one manual-described flow at a time from substitution/tactical changes, set plays, penalties, and defense/keeper commands; identify its ROM entry, input wait, state writes, and result route.
- Deliverable: A trace question and follow-up implementation issue for each verified flow family.
- Acceptance: Manual-described controls are tied to the matching target-ROM handler or labeled as manual-only/unknown; one route is not generalized to all cases.

### RE-096 — Compare Chinese Music-Tool Indexes with the ROM Driver
- Status: OPEN
- Type: Audit / Data
- Depends on: RE-040, RE-044, RE-045
- Scope: Check the editor's music extraction/index conversion notes, including E8/E9 handling, against one track's target-ROM sequence and driver execution.
- Deliverable: A command/index compatibility note linked to the audio driver and scene-cue reports.
- Acceptance: The command behavior and track mapping are confirmed from ROM bytes and same-ROM APU/driver evidence; no captured WAV or editor output becomes a runtime asset.

### RE-097 — Byte-Check Public Disassembly Labels for the Next Route
- Status: OPEN
- Type: Audit
- Depends on: RE-000
- Scope: Select the next gameplay or story bank needed by an open issue and compare the pinned public assembly annotations with the supplied Turkish ROM, including mapper-bank and file-offset mapping.
- Deliverable: A byte-coverage report for that bank/routine with matching and missing ranges and the linked consumer issue.
- Acceptance: Every reused label is byte-matched over its annotated range; skipped bytes, mismatches, and non-matching revision assumptions remain explicit. Do not repeat already covered ranges without a specific reason.

## Epic 8 — Local Developer Debug Menu

This is a local development aid only. Use Godot's built-in debugger for general
breakpoints, script evaluation, and performance profiling; the game-specific
menu should focus on ROM route state and decoded content. Godot 4.7 documents
`debug`, `release`, and `editor` feature tags for gating local tools
([feature tags](https://docs.godotengine.org/en/4.7/tutorials/export/feature_tags.html),
[debugger panel](https://docs.godotengine.org/en/4.7/tutorials/scripting/debug/debugger_panel.html)).

Global requirements for RE-100 through RE-107:

- Open only in a local editor/debug development run, through a non-conflicting
  developer action or dev-only launcher. Keep it closed in normal gameplay.
- Do not instantiate, expose, or package the menu and its scenario launchers in
  release builds. Verify the release export inventory and normal startup.
- The menu reads project-owned resources and runtime state only. It must not
  load the supplied `.nes`, FCEUX, emulator states, screenshots, or captured WAVs.
- Read-only inspection is the default. Any forced/synthetic state must be a
  named test fixture, visibly labeled as synthetic, resettable, and excluded
  from parity or route-acceptance evidence.
- Resume/jump tools may start only from named, verified Godot checkpoints
  generated by ordinary source-route execution. Never seed from FCEUX RAM or
  skip an unresolved transition to claim a route passes.
- Show `decoded`, `observed`, `external lead`, or `unknown` status and source
  provenance for content where that information exists. Never present missing
  fields as confirmed game data.

### RE-100 — Build the Local-Only Developer Menu Shell
- Status: OPEN
- Type: Tooling / Runtime
- Depends on: None
- Scope: Create a hidden, keyboard/controller-accessible debug overlay or dev-only launcher. Define non-conflicting open/close controls, tabs, a read-only status panel, and a strict local debug/editor gate.
- Deliverable: Small menu scene/controller and a documented input action in a development-only location.
- Acceptance: It can open and close during local development, does not consume or alter normal game input while closed, and cannot open in a release build. It reads existing route status rather than duplicating gameplay state.

### RE-101 — Add a Story Scene and Route Browser
- Status: OPEN
- Type: Tooling / Runtime
- Depends on: RE-100, RE-031
- Scope: List scene IDs and cutscene segments present in decoded project data; display text/animation/audio event coverage, source entry, known waits, and unresolved gaps. Allow replay from normal startup or a named verified Godot checkpoint.
- Deliverable: Searchable scene list, detail view, and safe launch/replay actions.
- Acceptance: Partial/unknown scenes remain visibly partial; launching a scene does not fabricate its endpoint or bypass an unresolved source-owned transition.

### RE-102 — Add a BGM and SFX Browser
- Status: OPEN
- Type: Tooling / Runtime
- Depends on: RE-100, RE-040
- Scope: Show BGM 00–39 and SFX 40–99 index status, runtime queue ID versus sound-test index where decoded, source mapping, and render/verification status. Preview only available ROM-derived runtime resources and provide stop/replay controls.
- Deliverable: Audio catalog panel backed by existing indexes/manifests and the production cue presenter.
- Acceptance: Unsupported entries are labeled, queue IDs are not confused with sound-test ordinals, and no captured WAV or emulator operation is used.

### RE-103 — Add a Team and Player Data Inspector
- Status: OPEN
- Type: Tooling / Runtime
- Depends on: RE-100, RE-021, RE-022
- Scope: Browse decoded teams, roster slots, player IDs, positions, stats, Guts, move eligibility, and data provenance. Show fields as unknown until their ROM meaning is established.
- Deliverable: Team/roster/player detail panels backed by ROM-derived project resources.
- Acceptance: Values match their resource manifests; no cheat RAM address is presented as a ROM ID or complete record, and viewing does not edit production data.

### RE-104 — Add a Match Scenario Lab
- Status: OPEN
- Type: Tooling / Runtime
- Depends on: RE-100, RE-050, RE-051
- Scope: Launch named, source-supported match-start or action test scenarios and inspect match phase, clock, score, ball holder, player positions/energy, selected command, and AI decision state as each field becomes available.
- Deliverable: A scenario picker plus read-only match-state panel; synthetic fixtures, if required, are kept separate from ordinary source-route scenarios.
- Acceptance: Scenario provenance is visible, synthetic state is explicitly labeled, and no scenario result can be reported as ordinary-input route parity.

### RE-105 — Add a Route, Input, and Checkpoint Inspector
- Status: OPEN
- Type: Tooling / Runtime
- Depends on: RE-100
- Scope: Display stage, source frame, cutscene/script/event cursor, scheduler task/wait, current decision boundary, recent events, and known fidelity gaps. Support pause, source-frame advance, input record/replay, and validated Godot checkpoint save/load.
- Deliverable: Read-only route telemetry and bounded reproduction controls connected to existing runtime status/events.
- Acceptance: Replaying the same input from a generated Godot checkpoint reaches the same observed source events; no FCEUX state or endpoint injection is accepted.

### RE-106 — Add a Visual and Source-Provenance Inspector
- Status: OPEN
- Type: Tooling / Runtime
- Depends on: RE-100, RE-030, RE-032, RE-033
- Scope: Where decoded data exists, show active scene/background, CHR/palette profile, text/glyph code, actor/animation ID, coordinates, and the source resource/report that drives it. Add pixel/frame stepping only at declared source or renderer boundaries.
- Deliverable: A compact overlay/details panel for visual source state and per-field provenance.
- Acceptance: Each displayed value comes from a production consumer or is explicitly an observation/hypothesis; screenshots and PPU/RAM dumps remain validation-only.

### RE-107 — Verify Developer-Tool Release Isolation
- Status: OPEN
- Type: Release / Verification
- Depends on: RE-100 through RE-106
- Scope: Inspect all release export presets (currently `all_resources`) and a fresh package for developer-menu scenes/scripts, test fixtures, debug input actions, and diagnostics that must remain local-only. Add explicit exclusion or another verified release gate where needed.
- Deliverable: Release export inventory and clean-start result linked to RE-082.
- Acceptance: No developer menu or launcher can be opened, and no debug-only test fixture/menu resource is present in the release package; the ordinary game starts without the supplied ROM or emulator.

## Chat Command

Use this exact request to start a task chat:

> Work on backlog issue **RE-XXX** from `GAME_REVERSE_ENGINEERING_PRD.md` only. Read `AGENTS.md`, the relevant part of `GOALS.md` and `PLANS.md`, and the applicable project skill. Check existing evidence before creating a decoder. Respect the issue's dependencies and acceptance criteria. Report any mismatch between this backlog and the active project goal before changing scope. Do not claim unverified behavior or expand into the next issue.

## Completion Policy

The complete-game goal is done only when RE-035, RE-044, RE-080 through RE-083 pass and all earlier required issues are closed or explicitly resolved as unnecessary with evidence. External audits RE-091 through RE-097 must be completed or explicitly marked not applicable before claiming the affected system is fully verified. RE-100 through RE-107 are local development tooling; they are not a player-facing feature and do not change the full-game content endpoint.

The 65 numbered RE issues are work-package templates, not a promise that one
instance of every issue covers every game variant. Expand repeatable work into
bounded follow-up issues until the coverage matrix accounts for every
source-reachable team/roster/formation, scene/text/animation family, sound-test
entry, match command/result handler, progression rule, and campaign/continue
transition in the shipped scope. A family may be marked unnecessary only with
ROM-backed evidence that it is unreachable or duplicates an already covered
handler. RE-080 and RE-081 are end-to-end integration gates; one successful
match and campaign replay alone do not replace this coverage review.

“Complete” means the declared game scope is playable from a standalone build
without the ROM or emulator, and remaining fidelity gaps are reported. It does
not mean physical NES timing or pixel/sample exactness has been proven when the
corresponding evidence is still open. The current `GOALS.md` remains the active
implementation milestone; this full-game backlog does not silently activate
all of its issues.

A total of 65 numbered RE items currently exist: RE-090 is complete, 64 are
open. Eight of them (RE-100–RE-107) cover the local-only developer menu and are
not required for the player-facing game to be considered content-complete.
A decoded table or isolated screen is not, by itself, a completed playable
route.
