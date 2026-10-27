# Opening post-stop audio tail: source trace (25 Oct 2026)

## Finding

The opening's final sequence is stopped by ROM command `$01`; there is no later
ROM cue. However, the stop does **not** make the APU-to-WaveHi input zero. It
sets pulse/noise volume to zero, disables further DMC fetches, and leaves the
triangle enabled while its remaining counters expire. After that, the triangle
DAC holds its last level; the DMC DAC latch is already held. Those TND inputs
continue feeding FCEUX's mixer while the resampler/filter state also persists.
FCEUX output decays through frame 4679. The production libgme render has a different
upstream mixer/resampler history, so adding only FCEUX's last filter stage to
it cannot recreate the tail. No runtime file was changed.

## ROM stop path

The target ROM SHA-256 is
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
At bank 0, file offset `$0058` contains `A9 01 8D 00 07`:
`LDA #$01; STA $0700`. The same-input trace observes this stop request on
source frame 4661. This dispatch location and frame are also recorded in
[`opening_audio_command_provenance.md`](opening_audio_command_provenance.md).

The sound-ID pointer at bank `$0C`, CPU `$8BDA` (file offset `$18BEA`) is
`42 8E`, pointing to CPU `$8E42` (file offset `$18E52`). That stream routes
all eight entries to `$8E5A`; `$8E5A` is `$FF`, the stream terminator. These
bytes match the stop-all interpretation in the local bank `$0C` disassembly.
The disassembly labels are navigation aids; the bytes above are from the
supplied ROM.

## APU writes and what they mean

The pinned FCEUX APU-write trace
`reference/diagnostics/audio/fceux_dmc_hook_trace_20261025_051007_utc/apu_writes.csv`
records the stop handler's writes at source frame 4662. Its `pc` column is the
post-write callback PC:

| Callback PC | Register/value | Source instruction bytes | Effect |
| --- | --- | --- | --- |
| `$8369` | `$4015 = $0F` | bank `$0C`, file `$18376`: `8E 15 40` (`STX $4015`) | Clears bit 4 to stop DMC fetches, while leaving pulse, triangle, and noise enabled. It does not reset the DMC DAC latch at `$4011`. |
| `$866D` | `$4000/$4004/$4008/$400C = $30` | bank `$0C`, file `$18678`: `A9 30 9D 00 40` (`LDA #$30; STA $4000,X`) | `$4000/$4004/$400C` set pulse/noise volume to zero. `$4008` clears the triangle linear-counter control bit; it is not a triangle volume or DAC-zero write. |

The writes occur twice in the trace for each register; the first pass is enough
to establish the stop state. In this FCEUX model, the triangle continues briefly
while its remaining counters expire; afterwards the held triangle and DMC DAC
levels contribute to the nonlinear TND mixer.

### Held APU levels at stop

The same-input APU write trace
`reference/diagnostics/audio/fceux_dmc_pcm_sync_20261025_seg1/apu_writes.csv`
records the final triangle note at frame 4650: `$4008=$8F`, `$400A=$93`,
`$400B=$19`. The pinned `sound.cpp` length table maps
`($19 >> 3) & $1F = 3` to length 2. While `$4008` bit 7 is set, the length
counter is halted. After the first stop write `$4008=$30` at cycle 138,811,483,
frame updates expire the remaining length by cycle 138,836,411 (about 0.84
NTSC video frame later). Applying the pinned counter logic to this write trace and
`reference/diagnostics/audio/fceux_dmc_hook_trace_pcm_sync_sequence_ordered_merged_20261025/dmc_hook_trace.csv`
predicts that the triangle DAC then holds step 21 (output level 15).
`RDoTriangle()` adds that held step even when its length or linear counter is
zero. The live trace does not serialize `tristep`; step 21 is a source-code
reconstruction result, not a directly sampled emulator state.

The final DMC bit edge in that trace is at source cycle 138,535,899 with
`RawDALatch=$60`. No `$4011` write follows it before `$4015=$0F` at cycle
138,810,624. `RDoPCM()` adds the raw DAC latch to WaveHi without checking DMC
enable or sample activity, so `$60` remains a constant mixer input after DMC
fetches stop. With pulse/noise volume zero, the resulting TND table index is
triangle 15 + DMC 96 = 111. This is the source input to the output chain; the
tail is not caused by filter memory alone.

## Why output continues

For the captured FCEUX profile (`soundq=2`, NTSC, 44.1 kHz, low-pass off),
`FlushEmulateSound()` sends the nonlinear `WaveHi` mix through the 1,024-tap
FIR/resampler and then the persistent `SexyFilter` recurrence. The FIR retains
input history and interpolation phase; `SexyFilter` carries `acc1` and `acc2`
across flushes. Muting the source channels does not clear either state. The
pinned FCEUX revision, source file hashes, and call paths are listed in
[`fceux_wavehi_implementation_map_20261024.md`](fceux_wavehi_implementation_map_20261024.md).

Existing diagnostic measurements quantify the gap: FCEUX remains above
1 LSB through frame 4679, while the current ROM-driver/libgme render does so
only through frame 4664. Applying the exact final `SexyFilter` recurrence to
the libgme output decays much sooner; its input does not contain FCEUX's
WaveHi/FIR history. See
[`start_tail_audit_20261024.json`](../../diagnostics/audio/start_tail_audit_20261024.json).

The later ChannelBC-aware WaveHi prototype reproduces the measured stop tail
with same-index correlation `0.99426`, but it replays FCEUX-measured
frame/DMC timing events, has about 3.8% higher RMS over the stop window, and
does not execute the game's 6502/DMC timing loop. Its manifest marks it
diagnostic-only and `runtime_asset: false`:
[`source_dmc_channelbc_wavehi.json`](../../diagnostics/audio/rom_source_wavehi_channelbc_replay_20261025/source_dmc_channelbc_wavehi.json),
[`validation_comparison.json`](../../diagnostics/audio/rom_source_wavehi_channelbc_replay_20261025/validation_comparison.json).

### Tail-window detail from the ChannelBC render

The same-index `4655–4684` comparison window has candidate/reference RMS ratio
`1.03774`, best linear gain `0.95810`, and normalized RMSE `0.11548`. Looking
only after the ROM mute edge, the candidate follows the measured decay shape
very closely but is consistently louder: frames 4662–4664 have correlation
`0.999840` and RMS ratio `1.17829`; 4665–4669 are `0.999983` / `1.18080`; and
4670–4679 are `0.999194` / `1.17602`. These are same-index calculations from
the source-generated candidate and comparison-only FCEUX PCM, using the
captured sample boundaries. FCEUX peak amplitude falls from 592 at frame 4662
to 2 at frame 4679, then at most 1 LSB in later capture frames.

The source model includes the held triangle/DMC levels and the broad tail shape,
but its post-stop RMS remains about 18% above the reference. The remaining
amplitude difference cannot be assigned to one filter parameter: the output
depends on the exact pre-stop WaveHi sequence, the held DAC transition, FIR
phase/history, and both persistent final-filter accumulators. In the pinned
soundq=2 path, `SexyFilter` keeps two
fixed-point accumulators across frame flushes; per output sample it updates
`acc1 += ((ino - acc1) * ((94 << 16) / 44100)) >> 16` and
`acc2 += ((ino - acc1 - acc2) * ((24 << 16) / 44100)) >> 16`, then emits
`(acc1 - ino + acc2) >> 16`. The 1,024-tap FIR also retains its 1,025-sample
overlap and phase. After the triangle length expires, the WaveHi source still
contains the held TND level; the audible decay is the response to that source
state plus the exact pre-stop WaveHi/FIR/filter history, not a missing sound
cue. The ChannelBC renderer ports the pinned filter equations, but its APU
writes, instruction-hook frame updates, DMC edges and PCM-sync timing come from
an instrumented FCEUX replay rather than execution of the ROM's 6502/DMC
opportunity loop. A fresh internal-state comparison at the exact end of source
frame 4661 is recorded in
[`rom_source_wavehi_checkpoint_compare_20261025/README.md`](../../diagnostics/audio/rom_source_wavehi_checkpoint_compare_20261025/README.md).
The first comparison was wrong in two ways: it used channel volume 256 instead
of the observed FCEUX 255/256 integer scaling, and compared the FCEUX retained
history against the candidate frame prefix rather than the aligned final
window `[28755,29780)`. With the corrected source arithmetic and sample window,
all five channel arrays and all 1,025 mixed WaveHi values match; FIR phase and
both `SexyFilter` accumulators match too. The DMC hook recurrence also reaches
the exact checkpoint state (`acc=12`, `bit_count=2`, DAC `$60`). The prior
0/1,025 result, pulse/noise mismatch attribution, and filter-state mismatch are
superseded by this corrected comparison. Candidate `fhcnt` is still 16,032
higher than FCEUX at the endpoint, so the APU frame-sequencer phase remains an
open issue for later frames. Do not treat one exact internal checkpoint as
full-opening audio proof or as grounds to replace the shipped runtime WAV.

## Runtime decision and remaining work

There is no source-backed runtime patch justified by this one endpoint. The
filter profile is pinned: NTSC, `soundq=2`, 44.1 kHz, `SoundVolume=256`, the
observed 255 per-channel multipliers, low-pass disabled, symmetric
`SQ2C44100NTSC` 1,024-tap FIR, and the `SexyFilter` recurrences shown above.
The corrected frame-4661 internal checkpoint now matches, but the complete
opening still needs a ROM-driven APU/DMC execution with its frame-sequencer
phase corrected, and more checkpoints against the original across the opening.
The ChannelBC tail candidate still consumes measured FCEUX APU/frame/DMC timing
events; it is not an independent runtime renderer. Do not extend the current
WAV with captured samples or guessed silence; keep captured output as
validation-only reference.
