#!/usr/bin/env python3
"""Prepare or run a one-pass, silent-output FCEUX PCM validation capture.

By default this prints the exact launch command without starting FCEUX. Pass
--execute to run it. The WAV and metadata are written under /tmp and are never
runtime assets. No checkpoint, second replay, or captured sound playback is
used.
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import shlex
import shutil
import struct
import subprocess
import sys
import tempfile
import wave
import re


ROOT = Path(__file__).resolve().parents[2]
ROM = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OPENING = ROOT / "reference/opening_reference_capture/input_timeline.csv"
POST_TITLE = ROOT / "reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
PASS_EDGES = ROOT / "reference/diagnostics/first_pass_action_input_edges_20261110.csv"
LUA = ROOT / "tools/diagnostics/capture_first_pass_fceux_pcm.lua"
EXPECTED_HASHES = {
    ROM: "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
    OPENING: "195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3",
    POST_TITLE: "87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e",
    PASS_EDGES: "3e522de6924b0fb9ad40ffdd2271a9e4ea62cbe1bf76cc27c6b414b7e87bb6d2",
}
SAMPLE_RATE = 44_100
CPU_CLOCK_HZ = 1_789_772.7272727273
SOUNDQ2_START_PHASE_SAMPLES = 25.256


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def confirmed_sdl_audio_drivers(log_paths: tuple[Path, ...]) -> list[str]:
    """Read SDL's FCEUX startup lines; a requested env var is not proof it stuck."""
    log_text = "\n".join(path.read_text(encoding="utf-8", errors="replace")
                          for path in log_paths if path.is_file())
    return [match.casefold() for match in re.findall(
        r"Loading SDL sound with ([a-z0-9_-]+) driver", log_text, flags=re.IGNORECASE
    )]


def inspect_finalized_wav(path: Path) -> dict:
    """Require a complete FCEUX-style 44-byte RIFF/WAVE PCM file and data chunk."""
    payload = path.read_bytes()
    if len(payload) < 44 or payload[:4] != b"RIFF" or payload[8:16] != b"WAVEfmt ":
        raise ValueError("WAV is missing or has an incomplete RIFF/WAVE header")
    if payload[36:40] != b"data":
        raise ValueError("WAV is missing the expected PCM data chunk")
    riff_size = struct.unpack_from("<I", payload, 4)[0]
    data_bytes = struct.unpack_from("<I", payload, 40)[0]
    if riff_size != len(payload) - 8 or data_bytes != len(payload) - 44:
        raise ValueError("WAV RIFF/data sizes do not match the finalized file length")
    with wave.open(str(path), "rb") as pcm:
        wav_info = {
            "channels": pcm.getnchannels(),
            "sample_width_bytes": pcm.getsampwidth(),
            "sample_rate_hz": pcm.getframerate(),
            "compression_type": pcm.getcomptype(),
            "sample_count": pcm.getnframes(),
        }
        samples = pcm.readframes(pcm.getnframes())
    if len(samples) != wav_info["sample_count"] * wav_info["channels"] * wav_info["sample_width_bytes"]:
        raise ValueError("WAV sample payload is shorter than its declared frame count")
    if data_bytes != len(samples):
        raise ValueError("WAV data chunk size does not match the decoded sample payload")
    wav_info["finalized"] = True
    wav_info["file_bytes"] = len(payload)
    wav_info["contains_nonzero_pcm"] = any(payload[44:])
    wav_info["sha256"] = hashlib.sha256(payload).hexdigest()
    return wav_info


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--execute", action="store_true", help="Launch FCEUX; default is command/preflight only.")
    parser.add_argument("--fceux", type=Path, default=Path(shutil.which("fceux") or "/opt/homebrew/bin/fceux"))
    parser.add_argument("--output-dir", type=Path, help="Optional new output directory; defaults to a unique /tmp path.")
    args = parser.parse_args()

    for path, expected in EXPECTED_HASHES.items():
        if not path.is_file() or sha256(path) != expected:
            raise SystemExit(f"Missing or changed fixed input: {path}")
    if not LUA.is_file() or not args.fceux.is_file():
        raise SystemExit("FCEUX or the one-pass Lua capture script is unavailable")

    if args.output_dir is None:
        stamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_utc")
        out = Path(tempfile.mkdtemp(prefix=f"ct2_first_pass_fceux_pcm_{stamp}_"))
    else:
        out = args.output_dir.expanduser().resolve()
        out.mkdir(parents=True, exist_ok=False)
    wav_path = out / "first_pass_to_frame9600.wav"
    command = [
        str(args.fceux), "--no-config", "1", "--sound", "1", "--volume", "256",
        "--soundrate", str(SAMPLE_RATE), "--soundq", "2", "--soundrecord", str(wav_path),
        "--newppu", "1", "--pal", "0", "--loadlua", str(LUA), str(ROM),
    ]
    env = os.environ.copy()
    env.update({"SDL_AUDIODRIVER": "dummy", "CT2_PROJECT_ROOT": str(ROOT),
                "CT2_FIRST_PASS_PCM_OUTPUT_DIR": str(out)})
    manifest = {
        "purpose": "Validation-only one-pass FCEUX PCM reference for source frames 0-9600.",
        "status": "prepared_only" if not args.execute else "running",
        "rom": str(ROM),
        "rom_sha256": EXPECTED_HASHES[ROM],
        "input_sha256": {
            "opening": EXPECTED_HASHES[OPENING],
            "post_title": EXPECTED_HASHES[POST_TITLE],
            "first_pass_edges": EXPECTED_HASHES[PASS_EDGES],
        },
        "output_dir": str(out),
        "wav_path": str(wav_path),
        "command": command,
        "environment": {"SDL_AUDIODRIVER": "dummy"},
        "audio_settings": {"sound_enabled": True, "volume": 256, "sample_rate_hz": SAMPLE_RATE,
                           "soundq": 2, "recording": "internal FCEUX WAV PCM output"},
        "route": {"from_cold_poweron": True, "first_source_frame": 0,
                  "last_source_frame_inclusive": 9600, "passes": 1,
                  "savestate_or_checkpoint": False},
        "sample_origin": {
            "cpu_clock_hz": CPU_CLOCK_HZ,
            "prior_soundq2_fir_start_phase_samples": SOUNDQ2_START_PHASE_SAMPLES,
            "policy": "Do not assume WAV sample zero is CPU cycle zero. Reconcile finalized WAV length against the Lua cycle trace before fixed-index comparison.",
        },
        "runtime_asset": False,
    }
    manifest_path = out / "capture_manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Output: {out}")
    print("Command: " + shlex.join(command))
    print("Requested SDL dummy output; emulated sound remains enabled for recording.")
    if not args.execute:
        print("Preflight only. Add --execute to launch FCEUX.")
        return 0

    with (out / "fceux_stdout.txt").open("w", encoding="utf-8") as stdout, \
            (out / "fceux_stderr.txt").open("w", encoding="utf-8") as stderr:
        result = subprocess.run(command, env=env, stdout=stdout, stderr=stderr, check=False)

    manifest["fceux_exit_code"] = result.returncode
    stdout_path, stderr_path = out / "fceux_stdout.txt", out / "fceux_stderr.txt"
    selected_drivers = confirmed_sdl_audio_drivers((stdout_path, stderr_path))
    manifest["sdl_audio_driver_lines"] = selected_drivers
    manifest["dummy_output_confirmed_by_fceux_log"] = bool(selected_drivers) and set(selected_drivers) == {"dummy"}
    trace_path = out / "fceux_trace.txt"
    frame_path = out / "frame_cycles.csv"
    manifest["lua_trace_present"] = trace_path.is_file()
    manifest["frame_cycle_trace_present"] = frame_path.is_file()
    if trace_path.is_file():
        manifest["lua_trace"] = trace_path.read_text(encoding="utf-8")
    if frame_path.is_file():
        import csv

        with frame_path.open(newline="", encoding="utf-8") as stream:
            rows = list(csv.DictReader(stream))
        mapping_mismatches = [row for row in rows if row["emulator_frame_after"] != row["source_frame"]]
        manifest["frame_trace_rows"] = len(rows)
        manifest["frame_mapping_mismatch_count"] = len(mapping_mismatches)
        if rows:
            start_cycle = int(rows[0]["cycle_start"])
            end_cycle = int(rows[-1]["cycle_end"])
            elapsed_cycles = end_cycle - start_cycle
            predicted = elapsed_cycles * SAMPLE_RATE / CPU_CLOCK_HZ - SOUNDQ2_START_PHASE_SAMPLES
            manifest["cycle_sample_accounting"] = {
                "first_cycle_start": start_cycle,
                "last_cycle_end": end_cycle,
                "elapsed_cycles": elapsed_cycles,
                "predicted_pcm_samples_using_prior_soundq2_phase": predicted,
            }
    try:
        wav_info = inspect_finalized_wav(wav_path)
        manifest["wav"] = wav_info
        manifest["observed_minus_predicted_samples"] = (
            wav_info["sample_count"] - manifest.get("cycle_sample_accounting", {}).get("predicted_pcm_samples_using_prior_soundq2_phase", 0)
        )
        manifest["sample_count_matches_cycle_prediction_within_one_sample"] = abs(
            manifest["observed_minus_predicted_samples"]
        ) <= 1.0
    except (wave.Error, OSError, ValueError) as error:
        manifest["wav_error"] = str(error)
    manifest["status"] = "captured" if (
        result.returncode == 0
        and manifest.get("dummy_output_confirmed_by_fceux_log")
        and manifest.get("lua_trace_present")
        and manifest.get("frame_trace_rows") == 9601
        and manifest.get("frame_mapping_mismatch_count") == 0
        and manifest.get("wav", {}).get("finalized") is True
        and manifest.get("wav", {}).get("channels") == 1
        and manifest.get("wav", {}).get("sample_width_bytes") == 2
        and manifest.get("wav", {}).get("sample_rate_hz") == SAMPLE_RATE
        and manifest.get("wav", {}).get("compression_type") == "NONE"
        and manifest.get("wav", {}).get("sample_count", 0) > 0
        and manifest.get("wav", {}).get("contains_nonzero_pcm")
        and manifest.get("lua_trace", "").find("complete=true") >= 0
    ) else "incomplete_or_unreconciled"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Capture status: {manifest['status']}; report: {manifest_path}")
    if not manifest.get("dummy_output_confirmed_by_fceux_log"):
        print("Capture rejected: FCEUX logs did not confirm the SDL dummy audio backend.")
    if not manifest.get("wav", {}).get("finalized"):
        print("Capture rejected: the expected WAV was missing, truncated, or not finalized.")
    print("PCM remains validation-only. The sample-count check is a start-origin diagnostic, not proof of waveform parity.")
    return 0 if manifest["status"] == "captured" else 2


if __name__ == "__main__":
    sys.exit(main())
