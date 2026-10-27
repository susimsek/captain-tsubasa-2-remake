# Opening VM and audio bridge

## Current playback contract

`assets/opening/audio/opening_timeline_rom_driver.wav` is one pre-rendered,
mixed timeline, not a collection of independently playable sound-ID clips. It
contains the cold-start interval and the captured sequence of queued IDs.
`opening_source_runtime.gd` starts it at source frame 0; when playback ends and
the intro loops, the wrapper reads the first `$58` request frame from the audio
manifest and seeks there. The manifest currently places that captured cue at
frame 282. The audio metadata reports 4,662 frames (0 through
4,661), and the first visual pass is 4,481 frames. The captured replay queues
the ROM stop ID `$01` on Start frame 4661. In Godot, Start immediately stops
the mixed WAV when the transition begins; it does not run to a source-scheduler
edge for arbitrary press times. The fixed replay timing is therefore only an
anchor, not proof that dynamic Start timing is exact.

## Verified ROM cue provenance

The silent same-input FCEUX trace verifies all 12 opening sound-queue `ED`
commands against their live CPU dispatch, MMC3 bank mapping, source ROM bytes,
and `$0700` queue writes. Their absolute frame positions come from the captured
replay, not from a fully source-timed Godot VM scheduler. The source addresses,
ROM offsets, live handler evidence, and cue table are documented in
[`opening_audio_command_provenance.md`](../reference/rom_extract/audio/opening_audio_command_provenance.md).

The captured `ED` cue schedule is `$58` at frame 282, `$68` at 379, `$28` at
1048/1068/1088, `$0E` at 1108, `$02` at 1510, `$0E` at 1779, `$09` at 1839,
`$07` at 2368, then repeated `$58` and `$68` at 4481 and 4578. The separate
title-entry stop `$01` is not an `ED` cutscene command: bank-0 code at file
offset `$0058` / CPU `$8048` writes it to `$0700` when Start is observed. That
store occurs on captured frame 4661. Thus the captured queue has 12 verified
`ED` commands plus the separate title-stop event.

The old FC counted-payload interpretation and the VM export based on it are
superseded. The verified live trace resolves the apparent conflict: the later
captured queue writes are real `ED` commands with ROM-backed source addresses.
This does not make their absolute frames general scheduler rules; those remain
specific to the saved input replay.

## Bridge to the cutscene VM

1. Keep the mixed WAV as the only audio playback source for the current fixed
   cold-start replay. Do not also play a sound on `sound_requested`, which
   could double cues already present in the mix.
2. Keep one NES-frame clock at 60.0988 Hz. For this fixed replay, start the WAV
   at frame 0, seek to the first `$58` event recorded in audio metadata when
   the visual loop restarts, and stop on the Start/title transition. The WAV
   checksum, ROM hash, and standalone/capture-free metadata are checked before
   playback. The event's absolute frame remains capture-anchored.
3. Until VM event timing is connected to the shared source scheduler, use
   `RomCutsceneVm.sound_requested` for diagnostics only. Record the sound ID,
   event CPU address, VM script tick, and current NES frame. Do not use
   unanchored VM ticks to seek or retrigger the mixed WAV.
4. Dynamic Start timing and independently triggered sound effects are not
   represented by this fixed mixed timeline. A future ROM-driver-backed
   per-ID renderer or correctly segmented timeline must preserve the original
   source data and be checked against APU timing before replacing it.

## Clock and fidelity limits

The `$58` request is queued on captured frame 282; the first active FCEUX APU
tone appears on frame 283. The rendered WAV has its first audible frame at 283
after the documented three-frame libgme output-alignment correction. The
`$68` request is captured at frame 379. These anchors do not prove a one-to-one
mapping from every VM script tick to a physical NES frame: animation tasks,
PPU work, concurrent Start polling, and some command waits remain outside the
VM. Command identity and ROM origin are verified for the 12 `ED` events;
absolute cue timing remains capture-derived.

The title-stop command is queued on frame 4661, and the FCEUX APU channel
volumes are zero from frame 4662. However, FCEUX's filtered PCM remains above a
1-LSB peak through frame 4679. Its `WaveHi → NeoFilterSound → SexyFilter`
output chain retains state across frames and produces this post-stop filter
tail. The current Godot WAV contains frames 0–4661 and playback stops at frame
4662, so it omits that tail. The tail's source is understood, but a reliable,
frame-aligned offline render that reproduces it is still unresolved; no
captured WAV or guessed fade is used as a runtime asset. Applying only the
final `SexyFilter` recurrence to libgme output was also insufficient because
the upstream FCEUX mixer/resampler state differs; see
`reference/diagnostics/audio/start_tail_audit_20261024.json`.

## ROM-cue playback synchronization (2026-10-24)

`opening_source_runtime.gd` now listens to the source presenter's verified
`rom_sound_requested` signal and re-seeks the already mixed WAV only when the
`$58` music cue occurs at one of its manifest-backed source frames, 282 or
4481. The WAV itself already contains the cue and all other scheduled audio;
the callback does not add a second sound stream. This gives the long music
loop two source-command sync points instead of relying only on the audio
server's free-running clock. The cue frames remain anchored to the saved
FCEUX replay, and the rest of the mixed sequence still uses that fixed render.

`tools/diagnostics/verify_opening_audio_runtime.gd` instantiates
`scenes/main.tscn` under Dummy audio, confirms the WAV starts, checks the two
`$58` manifest anchors, emits the cue signal at frames 282 and 4481, confirms
`$68` does not restart the mixed stream, and exits cleanly. The 120-frame
forced-shutdown check (`godot --headless --audio-driver Dummy --path .
--quit-after 120 --verbose`) also exits without the previous
`AudioStreamPlaybackWAV`/`AudioStreamWAV` leak warnings. Cleanup is attached to
the audio-player child so it runs before parent scene teardown. It uses an
explicit playback-state flag updated by the runtime's play/stop/finished paths;
it does not query `AudioStreamPlayer.playing` after stop, which could ask for an
inactive stream playback during tree exit. It stops only when that tracked flag
is set, clears the stream, synchronizes with the audio driver, and waits up to
50 ms for the queued stop to drain. The focused harness now stops playback
before freeing the scene to exercise that title-handoff exit path.

These checks cover resource loading, cue re-anchoring, and clean scene
shutdown. They do not establish sample-identical mixing or dynamic Start
timing; the unresolved WaveHi/DMC and post-stop-tail gaps above remain.

## ROM-driver NSF timing experiment (2026-10-24)

Two build-only WaveHi renders were generated from the ROM-driver NSF's APU
write sequence after mapping its cycle stamps onto captured FCEUX frame-cycle
boundaries. The global affine map produced same-index sample correlation
`0.96197` in frames 283–366 before DMC, but `-0.05478` in frames 367–450
after DMC began. Per-frame interpolation was worse before DMC (`0.58799`) and
also negative after DMC (`-0.12550`). The capture-write-driven reference model
remains much closer in those windows (`0.99723` and `0.98165`). Neither NSF
candidate replaces the current runtime WAV. The experiment and exact mapping
formulas are recorded in
`reference/diagnostics/audio/rom_driver_wavehi_clock_mapping_candidates_20261024.md`;
the candidate manifests separately identify the raw NSF trace, mapped events,
and captured frame-cycle timing input after a metadata-label correction.

This leaves a specific timing gap: register write order is byte-for-byte
verified, but the mapped traces do not reproduce instruction-boundary DMC DMA
fetch phase or frame-sequencer edges. The next useful source trace needs those
instruction hooks and DMR reads; applying another global or per-frame clock
offset is not supported by the measured PCM.
