#!/usr/bin/env python3
"""Run the muted same-input FCEUX trace for scene-$44 speaker branch cadence."""

from __future__ import annotations

import hashlib
import os
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
LUA = ROOT / "tools/diagnostics/trace_meeting_speaker_branch.lua"
FCEUX = Path("/opt/homebrew/bin/fceux")


def main() -> None:
	if not ROM.is_file() or not LUA.is_file() or not FCEUX.is_file():
		raise SystemExit("Missing supplied ROM, trace script, or FCEUX executable.")

	run_id = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_utc")
	output = ROOT / "reference/diagnostics" / f"meeting_speaker_branch_{run_id}"
	output.mkdir(parents=True, exist_ok=False)
	env = os.environ.copy()
	env["SDL_AUDIODRIVER"] = "dummy"
	env["CT2_SPEAKER_TRACE_OUTPUT_DIR"] = str(output)
	command = [str(FCEUX), "--sound", "0", "--volume", "0", "--no-config", "1",
		"--newppu", "1", "--loadlua", str(LUA), str(ROM)]
	started = time.monotonic()
	with (output / "fceux_stdout.txt").open("w", encoding="utf-8") as stdout, \
			(output / "fceux_stderr.txt").open("w", encoding="utf-8") as stderr:
		process = subprocess.Popen(command, env=env, stdout=stdout, stderr=stderr)
		last_progress: str | None = None
		while process.poll() is None:
			progress_path = output / "progress.txt"
			if progress_path.is_file():
				progress = progress_path.read_text(encoding="ascii").strip()
				if progress and progress != last_progress:
					print(f"Muted FCEUX trace: source frame {progress}", flush=True)
					last_progress = progress
			if time.monotonic() - started > 720:
				process.kill()
				process.wait()
				raise SystemExit(f"Trace exceeded 12 minutes; output={output}")
	metadata = output / "metadata.txt"
	with metadata.open("a", encoding="utf-8") as stream:
		stream.write(f"source_rom_sha256={hashlib.sha256(ROM.read_bytes()).hexdigest()}\n")
		stream.write(f"source_rom_md5={hashlib.md5(ROM.read_bytes()).hexdigest()}\n")
		stream.write(f"fceux_executable={FCEUX}\n")
		stream.write(f"fceux_command={' '.join(command)}\n")
		stream.write(f"exit_code={process.returncode}\n")
		stream.write(f"elapsed_seconds={time.monotonic() - started:.3f}\n")
	if process.returncode != 0:
		raise SystemExit(f"FCEUX trace exited with {process.returncode}; output={output}")
	print(output)


if __name__ == "__main__":
	main()
