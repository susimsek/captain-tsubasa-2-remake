#!/usr/bin/env python3
"""Run a muted same-input FCEUX trace for first-command palette/mirror state."""

from __future__ import annotations

import hashlib
import os
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
LUA = ROOT / "tools/diagnostics/trace_first_command_actor_palette_mirror.lua"
FCEUX = Path("/opt/homebrew/bin/fceux")
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


def sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
	if not ROM.is_file() or not LUA.is_file() or not FCEUX.is_file():
		raise SystemExit("The supplied ROM, Lua trace, or FCEUX executable is missing.")
	if sha256(ROM) != EXPECTED_ROM_SHA256:
		raise SystemExit("The supplied ROM SHA-256 differs from the audited target.")
	run_id = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_utc")
	output = ROOT / "reference/diagnostics" / f"first_command_palette_mirror_{run_id}"
	output.mkdir(parents=True, exist_ok=False)
	env = os.environ.copy()
	env["SDL_AUDIODRIVER"] = "dummy"
	env["CT2_ACTOR_TRACE_OUTPUT_DIR"] = str(output)
	command = [
		str(FCEUX), "--sound", "0", "--volume", "0", "--no-config", "1",
		"--newppu", "1", "--loadlua", str(LUA), str(ROM),
	]
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
					print(f"Muted FCEUX palette/mirror trace: source frame {progress}", flush=True)
					last_progress = progress
			if time.monotonic() - started > 720:
				process.kill()
				process.wait()
				raise SystemExit(f"Trace exceeded 12 minutes; last frame={last_progress}; output={output}")
			time.sleep(0.5)
	metadata = output / "metadata.txt"
	with metadata.open("a", encoding="utf-8") as stream:
		stream.write(f"source_rom_sha256={sha256(ROM)}\n")
		stream.write(f"fceux_executable={FCEUX}\n")
		stream.write(f"fceux_command={' '.join(command)}\n")
		stream.write(f"exit_code={process.returncode}\n")
		stream.write(f"elapsed_seconds={time.monotonic() - started:.3f}\n")
	if process.returncode != 0:
		raise SystemExit(f"FCEUX trace exited with {process.returncode}; output={output}")
	print(output)


if __name__ == "__main__":
	main()
