# Contributing

Thank you for helping improve this Godot reconstruction.

## Before you start

- Open an issue before a substantial feature or behavior change.
- Keep changes focused and explain the intended user-visible behavior in the pull request.
- Follow the ROM-fidelity guide in **AGENTS.md**: separate confirmed behavior from assumptions and keep unresolved timing or content gaps explicit.
- Do not commit the supplied ROM, emulator save states, observation captures, generated diagnostic dumps, credentials, or local export output.
- Do not add original-game material unless its source and distribution status are clear.

## Development setup

Use Godot 4.7.2. Open the project folder and run the main scene. GitHub Actions performs a clean headless import and a short main-scene launch for every branch push and pull request targeting **main**.

When changing visuals, timing, or audio, include the exact same-input comparison used and describe any differences. Do not describe a result as exact unless the image, timing, and audio comparison supports that statement.

## Commit messages

Use Conventional Commits with a short imperative subject. Scope is optional:

    feat(opening): preserve the source title handoff
    fix(audio): correct cue release timing
    docs(repo): explain the NTSC crop
    test(renderer): cover title palette loading
    ci: verify a clean Godot import
    chore: update project metadata

Keep commits small and logically grouped. Avoid WIP and noisy fixup commits.

## Pull requests

- Use the repository pull request template.
- State what changed, why it matches the milestone, the evidence used, and remaining assumptions.
- Include the verification commands actually run and the CI result.
- Update focused documentation when behavior, source data, or project setup changes.
- Do not include screenshots as runtime assets or imply that emulator captures drive the running game.

## Review

Reviewers look for focused diffs, source-backed behavior, clear asset provenance, passing CI, and honest reporting of unresolved fidelity gaps.
