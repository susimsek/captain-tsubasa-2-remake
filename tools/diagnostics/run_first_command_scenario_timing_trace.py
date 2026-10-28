#!/usr/bin/env python3
"""Run a muted same-input FCEUX trace of scenario task/wait scheduling."""

from __future__ import annotations

import csv
import hashlib
import os
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
LUA = ROOT / "tools/diagnostics/trace_first_command_scenario_timing.lua"
OPENING = ROOT / "reference/opening_reference_capture/input_timeline.csv"
ROUTE = ROOT / "reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
FCEUX = Path("/opt/homebrew/bin/fceux")
EXPECTED = {
    ROM: "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
    OPENING: "195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3",
    ROUTE: "87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e",
}
LAST_FRAME = 8953


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def normalized(path: Path) -> str:
    with path.open(newline="", encoding="utf-8") as f:
        rows = list(csv.reader(f))
    if not rows or "pass" not in rows[0]:
        raise SystemExit(f"Missing pass column in {path}")
    index = rows[0].index("pass")
    for row in rows[1:]:
        if index < len(row):
            del row[index]
    return hashlib.sha256("\n".join(",".join(row) for row in rows).encode()).hexdigest()


def validate_inputs() -> None:
    for path, expected in EXPECTED.items():
        if not path.is_file() or sha(path) != expected:
            raise SystemExit(f"Missing or changed input: {path}")
    if not LUA.is_file() or not FCEUX.is_file():
        raise SystemExit("FCEUX or Lua trace script is missing")


def main() -> None:
    validate_inputs()
    stamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_utc")
    out = ROOT / "reference/diagnostics" / f"first_command_scenario_timing_{stamp}"
    out.mkdir(parents=True, exist_ok=False)
    env = os.environ.copy()
    env.update({"SDL_AUDIODRIVER": "dummy", "CT2_PROJECT_ROOT": str(ROOT),
                "CT2_SCENARIO_TIMING_OUTPUT_DIR": str(out)})
    cmd = [str(FCEUX), "--sound", "0", "--volume", "0", "--no-config", "1",
           "--newppu", "1", "--loadlua", str(LUA), str(ROM)]
    started = time.monotonic()
    last, last_at = None, started
    with (out / "fceux_stdout.txt").open("w") as stdout, (out / "fceux_stderr.txt").open("w") as stderr:
        proc = subprocess.Popen(cmd, env=env, stdout=stdout, stderr=stderr)
        while proc.poll() is None:
            progress_file = out / "progress.txt"
            if progress_file.exists():
                current = progress_file.read_text().strip()
                if current != last:
                    print(f"Muted scenario trace: {current}", flush=True)
                    last, last_at = current, time.monotonic()
            if time.monotonic() - started > 300 or time.monotonic() - last_at > 60:
                proc.kill(); proc.wait()
                raise SystemExit(f"Scenario trace timed out; last={last}; output={out}")
            time.sleep(0.25)
    elapsed = time.monotonic() - started
    with (out / "metadata.txt").open("a") as f:
        f.write(f"source_rom_sha256={sha(ROM)}\nopening_input_sha256={sha(OPENING)}\nroute_input_sha256={sha(ROUTE)}\n")
        f.write(f"fceux_executable={FCEUX}\nfceux_command={' '.join(cmd)}\nexit_code={proc.returncode}\nelapsed_seconds={elapsed:.3f}\n")
    expected_files = ["scheduler_events.csv", "scheduler_events_repeat.csv", "scheduler_writes.csv", "scheduler_writes_repeat.csv"]
    if proc.returncode not in (0, -11) or "complete=true" not in (out / "metadata.txt").read_text():
        raise SystemExit(f"Trace incomplete (exit {proc.returncode}); output={out}")
    if not all((out / file).is_file() for file in expected_files):
        raise SystemExit(f"Trace outputs missing; output={out}")
    if normalized(out / expected_files[0]) != normalized(out / expected_files[1]) or normalized(out / expected_files[2]) != normalized(out / expected_files[3]):
        raise SystemExit(f"Repeated checkpoint passes differ; output={out}")
    print(f"PASS: two checkpointed traces match; {elapsed:.2f}s; FCEUX exit {proc.returncode}; output={out}")


if __name__ == "__main__":
    main()
