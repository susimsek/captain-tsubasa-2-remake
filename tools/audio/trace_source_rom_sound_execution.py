#!/usr/bin/env python3
"""Run a muted, inputless ROM power-on and trace its NMI/APU/DMC execution."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
LUA = ROOT / "tools/diagnostics/trace_source_rom_sound_execution.lua"
EXPECTED_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
EXPECTED_PAYLOAD_MD5 = "eaf2b3745263efa4b1afd2b400f68dae"
PINNED_FCEUX_REVISION = "a6d03e7968bd77a8156a7c9b628a673753f2f4c6"
DEFAULT_OUTPUT = ROOT / "reference/diagnostics/audio"


def digest(path: Path, algorithm: str = "sha256") -> str:
	return hashlib.new(algorithm, path.read_bytes()).hexdigest()


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--fceux", required=True, help="separate pinned, DMC-trace-patched FCEUX executable")
	parser.add_argument("--frames", type=int, default=300, help="source frames to execute (1..5000)")
	parser.add_argument("--start-frame", type=int, default=-1, help="optional one-frame Start input; -1 keeps all buttons released")
	parser.add_argument("--output-dir", type=Path, default=None)
	args = parser.parse_args()
	if not 1 <= args.frames <= 5000:
		parser.error("--frames must be between 1 and 5000")
	if not -1 <= args.start_frame < args.frames:
		parser.error("--start-frame must be -1 or inside the requested frame range")
	if not ROM.is_file() or not LUA.is_file():
		parser.error("supplied ROM or diagnostic Lua script is missing")
	rom_sha = digest(ROM)
	if rom_sha != EXPECTED_SHA256:
		parser.error(f"ROM SHA-256 mismatch: got {rom_sha}")
	if not Path(args.fceux).is_file():
		parser.error("the separate FCEUX executable does not exist")

	run_id = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_utc")
	output_dir = (args.output_dir or DEFAULT_OUTPUT / f"rom_source_sound_execution_{run_id}").resolve()
	output_dir.mkdir(parents=True, exist_ok=False)
	dmc_trace = output_dir / "fceux_dmc_trace.csv"
	env = os.environ.copy()
	env.update({
		"SDL_AUDIODRIVER": "dummy",
		"CT2_FCEUX_NO_THROTTLE": "1",
		"CT2_FCEUX_SKIP_BLIT": "1",
		"CT2_SOURCE_SOUND_TRACE_OUTPUT_DIR": str(output_dir),
		"CT2_SOURCE_SOUND_TRACE_FRAMES": str(args.frames),
		"CT2_SOURCE_SOUND_TRACE_START_FRAME": str(args.start_frame),
		"FCEU_DMC_TRACE_PATH": str(dmc_trace),
		"FCEU_DMC_TRACE_START_CYCLE": "0",
		"FCEU_DMC_TRACE_END_CYCLE": str(args.frames * 29781 + 100000),
		"FCEU_DMC_TRACE_SOURCE_ONLY": "1",
	})
	command = [
		str(Path(args.fceux).resolve()), "--sound", "1", "--volume", "0",
		"--playmov", "", # Override FCEUX's saved last-movie setting; the Lua stop/assert remains a second guard.
		"--no-config", "1", "--savestate", "10", "--loadlua", str(LUA), str(ROM),
	]
	print(output_dir, flush=True)
	with (output_dir / "fceux_stdout.txt").open("w", encoding="utf-8") as stdout_file, \
			(output_dir / "fceux_stderr.txt").open("w", encoding="utf-8") as stderr_file:
		completed = subprocess.run(command, env=env, text=True, stdout=stdout_file, stderr=stderr_file)
	metadata_path = output_dir / "source_execution.txt"
	metadata_text = metadata_path.read_text(encoding="utf-8") if metadata_path.is_file() else ""
	completed_match = re.search(r"^completed_source_frames=(\d+)$", metadata_text, re.MULTILINE)
	completed_frames = int(completed_match.group(1)) if completed_match else 0
	required = ["rom_execution_events.csv", "apu_writes.csv", "sound_queue_writes.csv", "frame_cycles.csv", "progress.csv"]
	if completed_frames != args.frames or any(not (output_dir / name).is_file() for name in required):
		raise RuntimeError(f"FCEUX trace incomplete (exit={completed.returncode}); inspect {output_dir}")

	for name in required + ([dmc_trace.name] if dmc_trace.is_file() else []):
		path = output_dir / name
		metadata_text += f"{name}_sha256={digest(path)}\n{name}_bytes={path.stat().st_size}\n"
	metadata_text += f"source_rom_sha256={rom_sha}\n"
	metadata_text += f"fceux_pinned_revision={PINNED_FCEUX_REVISION}\n"
	metadata_text += f"fceux_executable={Path(args.fceux).resolve()}\n"
	metadata_text += f"fceux_executable_sha256={digest(Path(args.fceux))}\n"
	metadata_path.write_text(metadata_text, encoding="utf-8")
	manifest = {
		"purpose": "ROM-only source execution diagnostic; FCEUX model event traces are not runtime/synthesis inputs.",
		"source_rom": {"path": ROM.relative_to(ROOT).as_posix(), "sha256": rom_sha, "payload_md5": EXPECTED_PAYLOAD_MD5},
		"fceux": {"pinned_revision": PINNED_FCEUX_REVISION, "executable": str(Path(args.fceux).resolve()), "executable_sha256": digest(Path(args.fceux))},
		"execution": {"frames": args.frames, "input": f"all buttons released except one Start on source frame {args.start_frame}" if args.start_frame >= 0 else "all buttons explicitly released on every frame", "cold_poweron": True, "movie_input": "command-line empty --playmov override; Lua stop and inactive assertions", "event_rows": "buffered in Lua and written at process exit", "throttle": "disabled by CT2_FCEUX_NO_THROTTLE in isolated diagnostic build", "video_blit": "skipped by CT2_FCEUX_SKIP_BLIT; no screen capture is produced"},
		"startup_movie": {
			"auto_loaded_before_lua": metadata_value(metadata_text, "startup_movie_active"),
			"name": metadata_value(metadata_text, "startup_movie_name"),
			"mode": metadata_value(metadata_text, "startup_movie_mode"),
			"pre_power_active": metadata_value(metadata_text, "pre_power_movie_active"),
			"post_power_active": metadata_value(metadata_text, "post_power_movie_active"),
			"frame0_input_confirmed": metadata_value(metadata_text, "frame0_input_confirmed"),
		},
		"audio": {"sound_core_enabled": True, "master_volume": 0, "sdl_audio_driver": "dummy", "pcm_or_wav_written": False},
		"outputs": {name: {"sha256": digest(output_dir / name), "bytes": (output_dir / name).stat().st_size} for name in required + ([dmc_trace.name] if dmc_trace.is_file() else [])},
		"process": {"returncode": completed.returncode, "lua_completed_frames": completed_frames},
		"limitations": [
			"APU bus writes and DMC event cycles describe the pinned FCEUX execution model, not measured physical NES bus timing.",
			"The DMC hook trace reports FCEUX's CPU/audio-hook model; byte DMA ordering is diagnostic and does not alone provide exact WaveHi PCM.",
			"This experiment records no PCM and reads no emulator capture, WAV, or recorded input timeline.",
		],
	}
	(output_dir / "trace_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
	print(output_dir)
	if completed.returncode != 0:
		print(f"FCEUX returned {completed.returncode} after Lua completed {completed_frames} frames; inspect stderr.")


def metadata_value(text: str, key: str) -> str | None:
	match = re.search(rf"^{re.escape(key)}=(.*)$", text, re.MULTILINE)
	return match.group(1) if match else None


if __name__ == "__main__":
	main()
