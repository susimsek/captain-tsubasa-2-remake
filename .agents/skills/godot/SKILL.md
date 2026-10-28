---
name: godot
description: Implement, debug, or review this Godot 4.7.2 project: GDScript, scenes, resources, UI, input, rendering, audio integration, gameplay state, and performance. Use for Godot engine and project changes; follow the current milestone and ROM-backed evidence.
---

# Godot

Use this project-local Godot skill for engine-specific implementation, debugging, and review. Ground changes in the existing project architecture and observable player behavior, then implement the smallest complete player-facing increment.

## Godot version and project conventions

- The project and CI pin Godot 4.7.2. Check the project metadata and configured tool before relying on an API; use version-matched official Godot documentation when behavior is uncertain.
- Preserve existing GDScript conventions, scene/resource UIDs, import settings, renderer choices, and project configuration. Do not upgrade the engine, plugins, or rendering path as a side effect.
- Keep core state typed and separate from presentation. Use scenes for composition, scripts for behavior, and Resources for reusable data when that matches the existing architecture.
- Use Godot 4 APIs (`await`, typed signals, `@export`, `FileAccess`, `TileMapLayer`, and current Tween patterns) only where they fit the project's actual version and existing code.
- Resolve dependencies through explicit node contracts, injected references, or signals. Avoid fragile scene-tree lookups, duplicate signal connections, and Autoloads without a real shared lifetime.
- Match update timing to the system: input, fixed physics, rendered frames, animation, audio, pause, and scene lifetime must not be conflated. Avoid frame-rate-dependent movement or guessed timers for source-driven behavior.

## Fidelity goal for this project

- The cold-boot opening through the title menu is already implemented. The current milestone is a fresh-start `KICK OFF` route through the first in-match command menu. Stop before confirming a soccer action and do not enter Continue.
- Use the user's supplied ROM as the canonical source for original graphics, palette indices, text, music, sound effects, and gameplay/cutscene data. Extract and decode original bytes into Godot-owned resources so the finished project does not need the `.nes` file or an emulator at runtime.
- Trace the original ROM's own drawing, cutscene, and audio routines/data where practical. If using a disassembly or source from another translation/revision, verify each relevant bank/offset against this ROM before treating it as authoritative.
- Emulator PPU/RAM/APU captures may identify active banks, nametable/OAM layout, input timing, and audio behavior. Emulator screenshots/video and captured WAV are comparison references only; never package them as final art or music.
- NES music is commonly sequenced data interpreted by a sound driver, not a ready-made audio file. Reproduce playback from the ROM's track bytes and driver, or render PCM offline from a byte-verified ROM-derived audio build. Document the source bytes and conversion method.
- Do not call a screen/audio “exact” while relevant mapping, PPU/APU state, frame timing, or input transitions remain unverified. State the specific evidence gap and continue investigating rather than silently substituting invented or capture-derived material.

## Before changing gameplay

1. Read the project `AGENTS.md` and inspect the relevant scenes, scripts, resources, and input mappings.
2. Identify the exact player-visible behavior being added or changed.
3. Check whether that behavior is documented as observed, assumed, or unknown. Do not turn an unknown into a claimed fact.
4. If a rule is missing, look for evidence in available user-provided reference material. Keep any temporary assumption small and easy to replace.
5. State the implementation approach briefly when the change affects core match state, save data, or architecture.

## Gameplay modeling

- Keep authoritative match state separate from scene presentation. The rules decide the result; animations, dialogue, and effects display it.
- Use explicit match phases and action results instead of loosely related booleans or long chains of UI conditionals.
- Define action inputs and outputs clearly. Validate prerequisites before applying costs or changing possession.
- Keep calculations deterministic where possible. Put randomness behind a seeded or injectable source so a replay can explain an outcome.
- Use data-driven player stats, teams, moves, costs, and difficulty values. Give each value a meaningful name and document units or ranges.
- Preserve tactical choices and command-driven pacing. Avoid real-time movement or simulation unless requested.
- Design for recoverable transitions: cancel/back, invalid actions, possession changes, goals, saves, match restart, and scene changes must leave the match in a valid state.

## Godot implementation

- Target the Godot 4 version already used by the project. Check official/current documentation when an API detail is uncertain or likely to have changed.
- Favor small scenes and scripts with one responsibility. Use signals or explicit interfaces for communication between UI, match rules, and presentation.
- Use typed GDScript for core state and action contracts. Prefer enums and named resources over magic numbers and stringly typed state.
- Define controls in the Input Map and let UI controls handle focus, cancel, and confirmation consistently.
- Keep low-resolution presentation pixel-crisp, with nearest filtering and integer-friendly scaling where the window permits it.
- Keep Turkish text UTF-8 and verify font coverage before choosing a font. Avoid embedding narrative copy in gameplay calculations.
- Do not add plugins, asset packs, or runtime dependencies without a concrete need and a short explanation.

## Reference and assets

- Use the supplied ROM as the reference for matching visuals, music, text, timing, and behavior.
- Recreate the game as native Godot scenes, scripts, data, and imported project resources. The finished project must run without the ROM; do not make the ROM an emulator/runtime dependency or bundle it into the playable build.
- Organize extracted or converted reference material as normal project assets with stable paths so the game can load it independently.
- Record observations and screenshots or notes in project documentation when they clarify a rule or regression.

## Delivery

- Keep changes focused and explain what changed, why, and which assumptions remain.
- Do not claim a mechanic matches the reference unless it was checked against observed behavior.
- Do not run tests or validation commands unless the user asks for verification. When asked, run the narrowest relevant checks and report exact results.
- Do not commit, publish, or distribute unless the user explicitly asks.

For the upstream foundation and project-specific additions, see [`references/upstream-foundation.md`](references/upstream-foundation.md). For desktop About/update UI and release workflow constraints, see [`references/desktop-ui-and-release.md`](references/desktop-ui-and-release.md).
