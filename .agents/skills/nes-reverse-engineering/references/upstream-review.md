# Upstream skill review

Reviewed 2026-10-28. These repositories informed workflow selection; local ROM bytes and traces remain authoritative.

## `Yuki001/nes-skills`

Repository: <https://github.com/Yuki001/nes-skills>

Reviewed skill pages: [FCEUX Lua](https://github.com/Yuki001/nes-skills/blob/main/skills/fceux-lua/SKILL.md), [retrodisasm](https://github.com/Yuki001/nes-skills/blob/main/skills/retrodisasm/SKILL.md), [6502 assembly](https://github.com/Yuki001/nes-skills/blob/main/skills/6502-assembly/SKILL.md), and [NES format](https://github.com/Yuki001/nes-skills/blob/main/skills/nes-format/SKILL.md).

The pack combines four useful domains: FCEUX Lua automation, trace/CDL-assisted disassembly, general 6502 assembly, and NES/iNES format. This project consolidates the parts that work together into one ROM-analysis skill rather than installing four overlapping skills.

Compatibility decisions:

- Its FCEUX guide bundles FCEUX 2.6.6 for Windows; this project uses FCEUX 2.7.0. The Lua API and callback assumptions must be checked against the installed build.
- Its retrodisasm guide ships prebuilt binaries. This project does not copy or run those binaries automatically; disassembly and CDL results are optional leads and must be checked against the supplied ROM's bank map and bytes.
- Its 6502 guide covers multiple machines. Generic instruction guidance is not evidence for NES 2A03, mapper, PPU, APU, or physical timing behavior.
- Its NES-format guide is a useful header/format checklist, but the actual target header and mapper behavior must be read from the supplied ROM and current project tools.
- No upstream skill text, ROM data, emulator binary, or disassembler binary is vendored here; the local workflow is project-specific.

GitHub MCP repository search also surfaced [`vl4dt/godot-skills`](https://github.com/vl4dt/godot-skills), a modular Godot skill set. It was not imported: this project needs one focused Godot skill, and the retrieved metadata mixed a Godot 4.7 description with individual compatibility entries for 4.0/4.1. That is a reason to inspect a specific module and version before using it, not to assume it matches this project's 4.7.2 pin.

## Other NES repositories checked with GitHub MCP

- [`ianlintner/howard-nester`](https://github.com/ianlintner/howard-nester/blob/main/.github/skills/claude-nes-agentic-development/SKILL.md) is a broad NES homebrew/development guide. Its tooling directory and hardware topics are useful discovery leads, but its assembly-writing workflow does not replace this project's ROM-specific tracing and verification.
- [`davefmurray/AWESOME-NESDEV`](https://github.com/davefmurray/AWESOME-NESDEV/tree/main/skills) includes detailed Tecmo Super Bowl ROM-map and hacking skills. Those bank IDs, file offsets, symbols, and gameplay rules belong to a different ROM and must never be reused for Captain Tsubasa 2. The useful general practice is to bind every mapping to a specific ROM revision and byte range.
- A GitHub MCP search for a Captain Tsubasa 2 NES disassembly returned no repository matches for the exact query. This does not prove that no disassembly or regional-language notes exist under different names or search terms; keep the project's external research index as the continuing source list.

No external code, binary, skill prose, or game-specific map from these repositories was copied into the project.

## Godot skill foundation

The single project skill at `.agents/skills/godot/` was adapted from the workflow shape of Setcode's [`godot-gamedev`](https://github.com/setcodes/gamedev-skills/tree/main/skills/godot-gamedev) MIT-licensed skill and then specialized for this project's Godot 4.7.2 version, ROM-derived data provenance, pixel output, and current milestone. It keeps only one Godot skill instead of bringing in unrelated networking, 3D, or general engine modules.

The [MIT license](https://github.com/setcodes/gamedev-skills/blob/main/LICENSE) applies to the upstream skill. This project keeps the source attribution here; the project-specific instructions and evidence references are local additions.
