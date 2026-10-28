# Godot skill foundation

This project-local skill adapts the workflow shape of Setcode's [`godot-gamedev`](https://github.com/setcodes/gamedev-skills/tree/main/skills/godot-gamedev) skill. The upstream repository identifies the skill as MIT licensed; see its [license](https://github.com/setcodes/gamedev-skills/blob/main/LICENSE).

The Godot-specific workflow retained here is to inspect the project and pinned engine version first, trace behavior to the system that owns it, make a complete bounded change, and choose verification that actually exercises the affected behavior. Project additions specialize that workflow for Godot 4.7.2, the tactical command-driven game, source-clock timing, ROM-derived resources, and the ROM-free runtime requirement.

The existing project skill was used as the source for its game-specific fidelity rules. No separate "senior Godot developer" skill or unrelated generic game-development skill is kept. The Godot-specific source attribution is kept here; no upstream skill files or code were copied into the project.
