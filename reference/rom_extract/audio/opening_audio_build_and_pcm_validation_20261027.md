# Opening audio source build and PCM validation — 2026-10-27

## Source and build

The active Godot WAV, `assets/opening/audio/opening_timeline_rom_driver.wav`,
is an offline render of the supplied Turkish ROM, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
ROM-only CPU/APU/DMC stepper events and the pinned FCEUX 2.7.0 WaveHi,
FIR-resampler, and `SexyFilter` implementation drive synthesis. The explicit
controller timeline drives ROM execution only. Captured FCEUX timestamps, WAV,
and PCM are excluded from synthesis inputs; the PCM capture is read only by the
separate validation step.

The output uses the recorded FCEUX channel gain profile of 255/256 for each of
the five channels. This is an emulator output setting, not ROM data. The
historical full-capture metadata does not preserve its settings file, so the
comparison identifies a reproducible FCEUX output profile rather than a
physical NES analog level.

Rebuild and compare with:

```sh
python3 reference/diagnostics/audio/ce6_wavehi_channel_volume255_20261026/render_volume255_candidate.py --output-dir reference/diagnostics/audio/ce6_wavehi_channel_volume255_rebuild_audit_20261027
python3 reference/diagnostics/audio/ce6_wavehi_channel_volume255_20261026/validate_pcm_identity.py --candidate reference/diagnostics/audio/ce6_wavehi_channel_volume255_rebuild_audit_20261027/rom_stepper_wavehi_candidate.wav --output reference/diagnostics/audio/ce6_wavehi_channel_volume255_rebuild_audit_20261027/pcm_identity_validation.json
```

The independent candidate and the active runtime WAV have SHA-256
`445afa1fc9e35ffd05e4eded941626cd728f5d1034e859e9601aa7a9f472edc4`. Against
the retained same-input FCEUX reference, all 3,442,925 samples match: exact
fraction 1.0, maximum sample error 0, RMSE 0. The candidate, input hashes,
renderer/filter hashes, and comparison JSON are in
`reference/diagnostics/audio/ce6_wavehi_channel_volume255_rebuild_audit_20261027/`.

## Remaining DMC timestamp caveat

At zero-based accepted DMC byte 84,665 (`$C0C4=$F1`, source frame 3601), the
the ROM-only model timestamps its four DMR phases at cycles 107,214,611–614,
while a completed, muted same-input FCEUX trace timestamps them at
107,214,608–611 inside the same hook sequence 34,141,806 (`$C494`, three-cycle
opcode). The stepper records the phases after its instruction-cycle batch;
FCEUX records them from hook entry. This measured software event-order
difference accounts for the +3 label residual; it does not establish physical
NES DMC DMA timing. No one-off correction was applied. The production PCM
remains byte-identical and the runtime WAV/manifest remain unchanged. Full
audit and capture evidence:
`reference/diagnostics/audio/dmc_byte_84665_residual_audit_20261027.md` and
`reference/diagnostics/audio/dmc_byte_84665_dmr_hook_capture_20261027/`.

## Limits

The ROM-only stepper has one remaining DMC output-byte cycle-label difference:
index 84,665 (`$C0C4=$F1`, source frame 3601) is three CPU cycles later than the
retained FCEUX trace. The generated PCM is still byte-identical. The stepper is
a FCEUX-compatible software model, not a complete 2A03 bus-arbitration model,
and the result does not establish physical NES analog-output equivalence. The
Godot project loads the generated WAV without requiring the ROM or an emulator.
