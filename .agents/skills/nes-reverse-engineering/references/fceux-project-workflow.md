# FCEUX workflow for this project

Use the installed FCEUX 2.7.0 and the exact ROM revision recorded by the project. Keep audio muted unless doing a requested audio comparison.

## Before a trace

- Read the current source note and verifier; state the one missing event or mapping to measure.
- Record ROM SHA-256, FCEUX build, PPU mode, input prefix, and source frame/cycle convention.
- Prefer a verified anonymous in-memory checkpoint close to the target event. Do not restart from cold boot for each repeated pass.
- Record a small signature from RAM, PPU, and mapper state at checkpoint creation.

## For each pass

1. Load the checkpoint and verify the signature, source frame, and mapper/PPU mode.
2. Replay the same remaining input sequence.
3. Collect only necessary hooks: entry/return PCs, relevant memory writes, bank changes, and event timing. Keep Lua callbacks small and defer formatting/file I/O.
4. Repeat from the same state. Compare normalized event and write logs; reject runs with mismatched signatures, counts, or input timing.
5. Translate the observation into ROM-source evidence: identify the owning code/data bytes and the path that produced the state. A RAM value or screenshot alone is not the implementation rule.

## Checkpoint record

Keep the following together in the diagnostic artifact or its README:

- ROM identity and SHA-256.
- FCEUX version, PPU mode, mute state, source frame, and input-prefix hash/text.
- RAM/PPU/mapper signature used after every load.
- Hook addresses, timestamp convention, trace file hashes, pass counts, and any discarded pass.
- What the trace proves and what remains unobserved.

Anonymous Lua savestates are session-local. If a state must survive emulator/script closure, use a clearly named temporary slot without replacing user data, and record the slot's provenance.
