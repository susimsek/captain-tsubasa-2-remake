# FCEUX workflow for this project

Use the installed FCEUX 2.7.0 and the exact ROM revision recorded by the project. Keep audio muted unless doing a requested audio comparison.

## Before a trace

- Read the current source note and verifier; state the one missing event or mapping to measure.
- Record ROM SHA-256, FCEUX build, PPU mode, input prefix, and source frame/cycle convention.
- Specify each input edge by source frame and hold duration. For one-frame taps,
  confirm the game consumed the press at the expected controller poll; record
  controller-latch/poll phase when the build exposes it.
- For work that spans emulator sessions, save a named, project-dedicated checkpoint near the target event; use an anonymous in-memory checkpoint only for repeated passes within one session. Never overwrite a user's existing state slot.
- When creating or refreshing the named checkpoint, record its provenance and RAM/PPU/mapper signature. On every load, verify the ROM hash, source frame, input prefix, emulator/PPU/mute configuration, and signature before tracing. If the checkpoint is missing or mismatched, rebuild it once from the recorded input prefix, validate it, and save it for later passes.
- Do not restart from cold boot for each repeated pass.
- Record a small signature from RAM, PPU, and mapper state at checkpoint creation.

## For each pass

1. Load the checkpoint and verify the signature, source frame, and mapper/PPU mode.
2. Replay the same remaining input sequence.
3. Collect only necessary hooks: entry/return PCs, relevant memory writes, bank changes, and event timing. Keep Lua callbacks small and defer formatting/file I/O.
4. Repeat from the same state. Compare normalized event and write logs; reject
   runs with mismatched signatures, counts, or input timing. A matching RAM/PPU
   checkpoint alone is insufficient if a one-frame input edge was missed or
   consumed on a different poll.
5. Translate the observation into ROM-source evidence: identify the owning code/data bytes and the path that produced the state. A RAM value or screenshot alone is not the implementation rule.

## Checkpoint record

Keep the following together in the diagnostic artifact or its README:

- ROM identity and SHA-256.
- FCEUX version, PPU mode, mute state, source frame, and input-prefix hash/text.
- RAM/PPU/mapper signature used after every load.
- Hook addresses, timestamp convention, trace file hashes, pass counts, and any discarded pass.
- What the trace proves and what remains unobserved.

Anonymous Lua savestates are session-local. Store named project checkpoints in an ignored local path or FCEUX slot dedicated to this project, without replacing user data, and record the slot/path and its provenance. Do not commit emulator state files.
