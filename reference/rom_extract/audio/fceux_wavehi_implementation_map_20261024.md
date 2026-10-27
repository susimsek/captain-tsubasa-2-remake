# FCEUX `WaveHi` output implementation map (24 Oct 2026)

This note maps the pinned FCEUX 2.7.0 `soundq=2`, NTSC, 44.1 kHz output path
to the ROM-derived APU-write trace. It is an implementation plan and evidence
map, not a claim that the Godot audio currently matches FCEUX.

## Already available in the project

- `tools/audio/build_opening_timeline_nsf.py` copies the supplied ROM's sound
  driver/data into an offline NSF wrapper after checking the ROM hash. The
  runtime WAV is rendered from that ROM-derived NSF by libgme; captured PCM is
  not used as a source asset.
- `tools/audio/trace_rom_driver_apu.py` advances the instrumented NSF to the
  same-input capture's exact 139,730,109 CPU-cycle horizon without emitting
  PCM. It records ordered CPU-cycle APU writes and PLAY calls. Its trace does
  not include `WaveHi`, the DMC DMA/read time, or the CPU PC.
- The source-DPCM bytes are preserved in
  `reference/rom_extract/audio/dpcm_sample_blob.bin`; the NSF maps the ROM's
  PRG bank `$1E` into `$C000–$DFFF`.
- An isolated NSF schedule with cue offset +2 matches the same-input FCEUX
  APU stream's 45,450 address/value/order writes, including 903 DMC register
  writes. A single rational clock scale and phase fit leave −50…+1,236 CPU
  cycles residual (RMS 307; maximum 0.691 ms). This is strong sequence
  evidence, not cycle-exact timing or waveform equivalence. See
  `reference/diagnostics/audio/apu_write_timing_comparison_20261024.json`.

## Reference output path and source locations

The checked local FCEUX source is commit
`a6d03e7968bd77a8156a7c9b628a673753f2f4c6`; `sound.cpp`, `filter.cpp`, and
`wave.cpp` hashes are recorded in
`reference/diagnostics/audio/start_tail_audit_20261024.json`. The source files
are also linked at the exact commit in
`reference/rom_extract/audio/offline_renderer_next_step.md`.

1. **Cycle clock and write boundaries.** In `src/x6502.cpp:38–45`, each CPU
   instruction adds its cycle count to `soundtimestamp`. `sound.h:62` defines
   `SOUNDTS = soundtimestamp + soundtsoffs`. Each register handler in
   `sound.cpp:222–307` calls the affected channel's `Do*()` routine before it
   changes the register state, so the old channel state is rendered up to the
   write boundary and the new value applies after it. `FlushEmulateSound()`
   flushes channels to the current endpoint at `sound.cpp:1037–1077`.
2. **Channel and nonlinear mix.** High-quality channel renderers append
   integer/fixed-point contributions to `WaveHi`: pulse at
   `sound.cpp:594–652`, triangle at `762–802`, noise at `948–1011`, and DMC
   DAC at `585–592`. At `sound.cpp:1063–1067`, FCEUX maps the pulse sum through
   `wlookup1`, the combined triangle/noise/DMC term through `wlookup2`, and
   retains the low 16-bit expansion remainder. These tables are initialized
   at `sound.cpp:1223–1236` using the NES nonlinear mixer curves. The selected
   capture profile is NTSC, `soundq=2`, 44,100 Hz, master `--volume 256`,
   per-channel volume defaults 256, and low-pass disabled.
3. **DMC reads and DAC.** `sound.cpp:108–112` provides the NTSC DMC bit periods
   (428 down to 54 CPU cycles). `$4012/$4013` become address `$C000 +
   ($4012 * 64)` and length `($4013 * 16) + 1` bytes at
   `sound.cpp:165–172`. `DMCDMA()` fetches the next source byte and advances
   address/length at `520–544`; `FCEU_SoundCPUHook()` advances the DMC period,
   shifts its eight bits, and applies ±2 DAC steps at `546–583`. `RDoPCM()`
   turns the current seven-bit DAC latch into the `WaveHi` TND input at
   `585–592`. In the opening trace, implement reads from the verified
   `$1E`-to-`$C000–$DFFF` ROM mapping; the current libgme trace has register
   writes but no timestamped DMA reads.
4. **FIR/resampler.** `filter.cpp:168–198` selects the symmetric 1,024-tap
   `SQ2C44100NTSC` table for this profile; the taps are sourced through
   `src/fcoeffs.h:1–6` and `src/fir/c44100ntsc.h`. `MakeFilters()` also sets a
   16.16 CPU-cycle/sample step and primes `mrindex` with the filter history.
   `NeoFilterSound()` at `filter.cpp:96–166` computes the two neighboring FIR
   convolutions, linearly interpolates at the fractional phase, carries
   `mrindex`, and asks the caller to retain 1,025 input samples. FCEUX keeps
   this phase/history across frame flushes (`sound.cpp:1069–1074`).
5. **Final filter and PCM encoding.** `SexyFilter()` at `filter.cpp:51–82`
   scales the resampled signal by the configured master volume, runs two
   persistent fixed-point recurrences (`acc1`, `acc2`), clamps to signed
   16-bit, and overwrites the input buffer. `NeoFilterSound()` always applies
   this for `soundq>=1` (`filter.cpp:159–165`). The optional `SexyFilter2`
   low-pass follows only when enabled; it was disabled in this reference
   capture. `FlushEmulateSound()` hands the result to `FCEU_WriteWaveData()` at
   `sound.cpp:1107–1109`.

## Sample and frame boundaries

For the selected capture, CPU-cycle input is preferable to a fixed sample
count per video frame. Rows 1–4692 cover 139,730,109 elapsed CPU cycles; at
44.1 kHz and the pinned NTSC CPU clock, that corresponds to 3,442,949.88576
unprimed sample intervals. The recorded 3,442,925 samples are explained by
the 1,025-clock FIR startup phase (25.256 samples), after integer rounding.
Use the saved precise alignment record at
`reference/diagnostics/audio/precise_pcm_sample_alignment_20261024.json`.
Frame-number × nominal-735-sample alignment will drift because actual frame
cycle counts vary.

## Filter prototype and original next-step plan (24 Oct 2026)

The downstream filter stage is now implemented as a build-only diagnostic in
`tools/audio/prototype_fceux_filter_pipeline.py` and
`tools/audio/fceux_filter_prototype/filter_pipeline.cpp`. It checks the pinned
FCEUX source/coefficient hashes and ports `NeoFilterSound`'s 16.16 phase,
1,024-tap FIR, 1,025-sample overlap, plus persistent `SexyFilter` state. It
processes the measured per-frame CPU-cycle blocks and emits the expected
3,442,925 samples. Its input is a sample-held libgme PCM signal rendered from
the ROM-derived NSF, explicitly not FCEUX WaveHi and not captured PCM. The
filtered surrogate has overall envelope correlation 0.90665 at offset 0; its
stop-frame-4662 RMS is 8,488 versus FCEUX's 252. This shows that the surrogate
does not validate the true APU output; the filter port is not a runtime asset
or replacement for the current WAV. Metadata and diagnostic WAV are under
`reference/diagnostics/audio/rom_driver_apu_trace_cue_offset_plus2_20261024/`.

The original next stage was a deterministic source-cycle module that consumes
ordered APU writes, reset and `$4017` frame-sequencer state, NTSC clock,
channel volume profile, and ROM-derived DPCM reads. The ROM-source WaveHi
renderer below implements channel mixing, DMC byte reads and DAC state, the
pinned filter port, and (in the 25 Oct follow-up) `ChannelBC`-aware lazy flush
boundaries. FCEUX PCM remains a comparison-only input to the separate
validation script. The remaining timing question is how to replace captured
FCEUX frame-update/DMC hook timestamps with execution of the original 6502
instruction and DMA opportunity loop. Runtime audio has not changed.

## ROM-trace APU/`WaveHi` prototype (24 Oct 2026)

The first upstream prototype is now in
`tools/audio/fceux_apu_wavehi_prototype/apu_wavehi_renderer.cpp`, driven by
`tools/audio/render_fceux_apu_wavehi_prototype.py`. It consumes the FCEUX
cycle-stamped APU write trace and per-frame CPU-cycle totals, renders pulse 1,
pulse 2, triangle, and noise through the pinned nonlinear mixer, then calls
the filter port above. It processes 139,730,109 measured cycles and emits
3,442,925 samples. It does not use captured PCM as input and is not a runtime
asset.

The DMC-free source-time interval 207,663–268,568 maps to PCM frame bins
283–366, ending at the first DMC enable. In that interval the source-synthesized
output has sample correlation 0.99723 at zero-sample offset, normalized RMSE
7.88%, and candidate/reference RMS ratio 1.02329 (least-squares gain 0.97454).
Frame-envelope correlation is 0.98564 with RMS ratio 1.02243. These results
support the ported non-DMC channels/mixer over this interval. The frame-clock
hook is still resolved per CPU cycle rather than at exact CPU instruction
boundaries (at most 7 cycles of placement uncertainty).

The diagnostic renderer now also models DMC address/length/rate registers,
bank-`$1E` sample reads, its sample buffer, shift register, and 7-bit DAC.
The 301 programmed starts and two ROM sample windows are described in
`reference/diagnostics/audio/dmc_playback_path_audit_20261024.md`. The renderer
advances `DMCDMA` opportunities once per modeled CPU cycle; FCEUX actually
calls its sound hook at instruction boundaries and advances four cycles per
same-address DMR sequence, while the trace lacks those hook/read events. The
frame-sequencer hook is likewise cycle-quantized by up to seven cycles. Thus
the DMC model is ROM-source-driven but not DMA-phase exact.

The complete diagnostic render is
`reference/diagnostics/audio/fceux_apu_wavehi_prototype_20261024/apu_wavehi_model.wav`.
It emits the expected 3,442,925 samples. Validation-only sample correlations
are 0.99723 in the DMC-free first cue, 0.98165–0.99628 in three post-DMC
windows, 0.93508 in the late `$58` loop, 0.87599 in the final `$68` cue, and
0.77007 over the stop/filter tail. These are not sample identity guarantees.
The detailed window metrics are in
`reference/diagnostics/audio/fceux_apu_wavehi_prototype_20261024/validation_comparison.json`.
No production WAV or Godot runtime code changed.

## 25 Oct 2026 follow-up: DMC hook and PCM synchronization

The instruction-hook gap described above is now narrowed for the captured
opening input. A private pinned-FCEUX replay records 104,106 DMC byte fetches,
836,081 DMC bit-state edges, 832,848 `PCM_SYNC_IN` records, and 18,736 frame
updates. All fetched bytes are checked against supplied-ROM physical bank
`$1E`. Compact merge output preserves original event order where multiple
edges share a CPU-hook timestamp. The renderer uses `PCM_SYNC_IN.detail_extra`
(`fudge`) to schedule the new DAC value at the adjusted WaveHi coordinate
`absolute_cycle - fudge`, matching `DoPCM()`/`RDoPCM()`'s exclusive end at
`SOUNDTS`. The measured adjustment range is 0–515 cycles.

The PCM-sync-only comparison from this stage has been superseded by the
ChannelBC follow-up below. See `reference/diagnostics/audio/dmc_playback_path_audit_20261024.md`
and the PCM-sync trace metadata for capture provenance.

## 25 Oct 2026 follow-up: ChannelBC lazy flush boundaries

The renderer now ports the pinned `sound.cpp` lazy per-channel fill semantics.
At an APU write, `Write_PSG` invokes the corresponding `DoSQ1`, `DoSQ2`,
`DoTriangle`, or `DoNoise` **before** changing that register's state;
`$4008/$4009` only store the byte and do not flush a channel. `$4010/$4011`
flush DMC PCM before changing period/DAC state, while `$4012/$4013` only update
latches. `StatusWrite` flushes pulse 1, pulse 2, triangle, noise, and PCM before
changing channel enables or lengths. `FrameSoundStuff` flushes pulse 1, pulse
2, noise, then triangle before changing envelope, sweep, length, and linear
counter state; it does not flush PCM. `PCM_SYNC_IN` subtracts its measured
`fudge` from `soundtsoffs`, flushes PCM at that corrected exclusive
`SOUNDTS`, then the hook changes the DMC DAC. At frame end, `FlushEmulateSound`
flushes all five channels before nonlinear mixing and filtering.

The diagnostic maps `ChannelBC` into frame-local coordinates: FCEUX carries
the 1,025-sample soundq=2 overlap in its WaveHi buffer, and the existing filter
port prepends that same retained history. Captured PCM is used only by the
separate comparison script. The ROM-source renderer and WAV are
`tools/audio/fceux_apu_wavehi_prototype/apu_wavehi_renderer.cpp` and
`reference/diagnostics/audio/rom_source_wavehi_channelbc_replay_20261025/`.
This is a source-ported boundary model fed with the captured write/frame/DMC
event timeline; it does not run the original 6502/DMC instruction-hook loop.

Against the same FCEUX PCM file and identical sample indices, the new
diagnostic yields correlations of 0.99759 before DMC, 0.99615 for the first
DMC cue, 0.99696 in the later `$28` sequence, 0.99604 for `$02`, 0.99565 in
the late `$58` loop, 0.99663 for the final `$68` cue, and 0.99426 over the
stop/filter tail. The candidate has 3,442,925 samples like the reference and
is about 2–4% higher in RMS across these windows; normalized RMSE is 7.3–11.5%.
This materially improves the earlier late-cue/tail results, but differing
WAV hashes, remaining level/error, trace-anchored timing, and the unexecuted
CPU/DMC hook mean it is **not declared sample-exact**. It remains
diagnostic-only; the Godot runtime WAV/assets were not changed (the existing
`assets/opening/audio/opening_timeline_rom_driver.wav` still hashes to
`325fa7947fcba0874a6b5261a03b8314d302df318a58f887eb0ee4daab8cbf4a`).
