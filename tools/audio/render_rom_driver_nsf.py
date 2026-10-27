#!/usr/bin/env python3
"""Render a ROM-driver NSF to a Godot-compatible WAV with libgme.

Input NSF must be produced by build_intro_nsf.py from the supplied ROM. The
output is synthesized by executing those source bytes, not a captured emulator
WAV. This is an offline build tool; Godot only loads the resulting WAV.
"""

from __future__ import annotations

import argparse
import ctypes
import json
import wave
from array import array
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_NSF = ROOT / "tools/audio/build/intro_track_58_driver.nsf"
DEFAULT_WAV = ROOT / "reference/diagnostics/audio/intro_track_58_rom_driver.wav"
LIBGME_PATH = "/opt/homebrew/lib/libgme.dylib"


def render(nsf: Path, wav: Path, seconds: int, sample_rate: int, preserve_initial_silence: bool = False) -> None:
    lib = ctypes.CDLL(LIBGME_PATH)
    lib.gme_open_data.argtypes = [ctypes.c_void_p, ctypes.c_long, ctypes.POINTER(ctypes.c_void_p), ctypes.c_int]
    lib.gme_open_data.restype = ctypes.c_char_p
    lib.gme_start_track.argtypes = [ctypes.c_void_p, ctypes.c_int]
    lib.gme_start_track.restype = ctypes.c_char_p
    lib.gme_play.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.POINTER(ctypes.c_int16)]
    lib.gme_play.restype = ctypes.c_char_p
    lib.gme_delete.argtypes = [ctypes.c_void_p]
    lib.gme_ignore_silence.argtypes = [ctypes.c_void_p, ctypes.c_int]

    source = nsf.read_bytes()
    if source[:5] != b"NESM\x1A":
        raise ValueError("Expected a ROM-driver NSF file")
    source_buf = ctypes.create_string_buffer(source)
    player = ctypes.c_void_p()
    err = lib.gme_open_data(source_buf, len(source), ctypes.byref(player), sample_rate)
    if err:
        raise RuntimeError(err.decode())
    try:
        if preserve_initial_silence:
            # libgme otherwise skips up to about two seconds of leading silence,
            # which would destroy cold-start frame alignment for this timeline.
            lib.gme_ignore_silence(player, 1)
        err = lib.gme_start_track(player, 0)
        if err:
            raise RuntimeError(err.decode())
        wav.parent.mkdir(parents=True, exist_ok=True)
        with wave.open(str(wav), "wb") as out:
            # The source NES APU is mono; libgme supplies identical L/R samples.
            out.setnchannels(1)
            out.setsampwidth(2)
            out.setframerate(sample_rate)
            frames_left = seconds * sample_rate
            while frames_left:
                frames = min(frames_left, 4096)
                sample_count = frames * 2
                samples = (ctypes.c_int16 * sample_count)()
                err = lib.gme_play(player, sample_count, samples)
                if err:
                    raise RuntimeError(err.decode())
                out.writeframesraw(array("h", samples[::2]).tobytes())
                frames_left -= frames
    finally:
        lib.gme_delete(player)


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--nsf", type=Path, default=DEFAULT_NSF)
    p.add_argument("--output", type=Path, default=DEFAULT_WAV)
    p.add_argument("--seconds", type=int, default=90)
    p.add_argument("--sample-rate", type=int, default=44100)
    p.add_argument("--preserve-initial-silence", action="store_true")
    args = p.parse_args()
    args.nsf = args.nsf.resolve()
    args.output = args.output.resolve()
    render(args.nsf, args.output, args.seconds, args.sample_rate, args.preserve_initial_silence)
    metadata = {
        "source_nsf": str(args.nsf.relative_to(ROOT)),
        "wav": str(args.output.relative_to(ROOT)),
        "sample_rate": args.sample_rate,
        "channels": 1,
        "seconds": args.seconds,
        "renderer": "libgme 0.6.5, offline NSF execution of supplied ROM sound driver and cue data",
        "capture_used": False,
        "preserve_initial_silence": args.preserve_initial_silence,
        "validation_status": "Audio has not yet been compared against reference timing or waveform.",
    }
    args.output.with_suffix(".json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    print(args.output)


if __name__ == "__main__":
    main()
