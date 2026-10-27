#!/usr/bin/env python3
"""Build a cold-start-aligned intro WAV entirely from the ROM sound driver.

The intermediate NSF executes original sound commands at observed $0700 frame
positions. libgme's NSF start routine adds a fixed three-frame output delay
relative to the captured APU cue onset. This script removes that delay and
retains the leading cold-start silence in the final Godot asset.
"""

from __future__ import annotations

import hashlib
import json
import wave
from pathlib import Path

from build_opening_timeline_nsf import EVENT_DETAILS, EVENTS, ROOT, build
from render_rom_driver_nsf import render

FPS = 60.0988
SAMPLE_RATE = 44100
FIRST_AUDIBLE_APU_FRAME = 283
ALIGNMENT_SHIFT_FRAMES = 3
TOTAL_FRAMES = 4662  # Cold power-on frames 0..4661, including the captured Start frame.


def main() -> None:
    nsf = ROOT / "tools/audio/build/opening_timeline_rom_driver.nsf"
    intermediate = ROOT / "tools/audio/build/opening_timeline_unaligned.wav"
    final = ROOT / "assets/opening/audio/opening_timeline_rom_driver.wav"
    nsf_info = build(nsf)
    render(nsf, intermediate, 79, SAMPLE_RATE, preserve_initial_silence=True)

    with wave.open(str(intermediate), "rb") as src:
        if (src.getnchannels(), src.getsampwidth(), src.getframerate()) != (1, 2, SAMPLE_RATE):
            raise ValueError("Unexpected offline NSF renderer format")
        raw = src.readframes(src.getnframes())

    # libgme's built-in NSF scheduling delays this wrapper's first audible cue
    # by three video frames: $58 queued at frame 282 would otherwise first
    # produce PCM in frame 286; the reference APU first activates in frame 283.
    shift_samples = round(ALIGNMENT_SHIFT_FRAMES * SAMPLE_RATE / FPS)
    output_samples = round(TOTAL_FRAMES * SAMPLE_RATE / FPS)
    pcm = raw[2 * shift_samples:2 * (shift_samples + output_samples)]
    if len(pcm) != 2 * output_samples:
        raise ValueError("Intermediate audio is too short for the intro timeline")

    final.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(final), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(SAMPLE_RATE)
        out.writeframes(pcm)

    meta = {
        "source_rom_sha256": nsf_info["source_rom_sha256"],
        "source_nsf": str(nsf.relative_to(ROOT)),
        "source_nsf_sha256": nsf_info["nsf_sha256"],
        "audio_path": str(final.relative_to(ROOT)),
        "audio_sha256": hashlib.sha256(final.read_bytes()).hexdigest(),
        "sample_rate_hz": SAMPLE_RATE,
        "channels": 1,
        "bits_per_sample": 16,
        "frame_rate_hz": FPS,
        "video_frames": TOTAL_FRAMES,
        "audio_samples": output_samples,
        "first_reference_apu_active_frame": FIRST_AUDIBLE_APU_FRAME,
        "libgme_alignment_shift_frames": ALIGNMENT_SHIFT_FRAMES,
        "source_command_frames": [{"frame": f, "sound_id": f"0x{v:02X}"} for f, v in EVENTS],
        "source_event_provenance": EVENT_DETAILS,
        "playback": "Play at cold-start frame 0. On visual loop at frame 4481, restart at frame 282/FPS. Stop on Start/title transition; ROM cues $01 at captured frame 4661.",
        "source_method": "Original supplied ROM PRG sound-driver/data bytes executed in offline NSF. All cue IDs and frames are scheduled from FCEUX RAM $0700 observations; all 12 ED cue origins are verified against live CPU dispatch, MMC3 mapping, and source ROM bytes, and the title-stop is verified against its bank-0 store. Rendered by libgme 0.6.5 with fixed output alignment correction.",
        "captured_pcm_used": False,
        "runtime_needs_rom_or_emulator": False,
        "fidelity_status": "Cue schedule and first tonal onset matched to FCEUX RAM/APU frame observations; sample-level timbre/mix and individual SFX waveforms have not been proven identical.",
    }
    final.with_suffix(".json").write_text(json.dumps(meta, indent=2) + "\n", encoding="utf-8")
    print(final)


if __name__ == "__main__":
    main()
