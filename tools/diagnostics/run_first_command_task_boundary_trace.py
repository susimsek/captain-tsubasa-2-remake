#!/usr/bin/env python3
"""Run and validate the muted first-command task-boundary trace."""

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
LUA = ROOT / "tools/diagnostics/trace_first_command_task_boundary_from_8399.lua"
OPENING = ROOT / "reference/opening_reference_capture/input_timeline.csv"
ROUTE = ROOT / "reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
FCEUX = Path("/opt/homebrew/bin/fceux")
EXPECTED = {
    ROM: "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
    OPENING: "195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3",
    ROUTE: "87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e",
}


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def normalized_hash(path: Path) -> str:
    with path.open(newline="", encoding="utf-8") as stream:
        rows = list(csv.reader(stream))
    if not rows or "pass" not in rows[0]:
        raise SystemExit(f"Missing pass column in {path}")
    index = rows[0].index("pass")
    for row in rows[1:]:
        del row[index]
    normalized = "\n".join(",".join(row) for row in rows).encode()
    return hashlib.sha256(normalized).hexdigest()


def main() -> None:
    for path, expected in EXPECTED.items():
        if not path.is_file() or sha(path) != expected:
            raise SystemExit(f"Missing or changed trace input: {path.name}")
    if not LUA.is_file() or not FCEUX.is_file():
        raise SystemExit("FCEUX or task-boundary Lua trace is unavailable")

    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_utc")
    out = ROOT / "reference/diagnostics" / f"first_command_task_boundary_{timestamp}"
    out.mkdir(parents=True, exist_ok=False)
    env = os.environ.copy()
    env.update({"SDL_AUDIODRIVER": "dummy", "CT2_PROJECT_ROOT": str(ROOT),
                "CT2_TASK_BOUNDARY_TRACE_OUTPUT_DIR": str(out)})
    command = [str(FCEUX), "--sound", "0", "--volume", "0", "--no-config", "1",
               "--newppu", "1", "--loadlua", str(LUA), str(ROM)]
    started = time.monotonic()
    last_progress, last_progress_at = None, started
    with (out / "fceux_stdout.txt").open("w") as stdout, (out / "fceux_stderr.txt").open("w") as stderr:
        proc = subprocess.Popen(command, env=env, stdout=stdout, stderr=stderr)
        while proc.poll() is None:
            progress_file = out / "progress.txt"
            if progress_file.exists():
                progress = progress_file.read_text().strip()
                if progress != last_progress:
                    print(f"Muted task-boundary replay: {progress}", flush=True)
                    last_progress, last_progress_at = progress, time.monotonic()
            if time.monotonic() - started > 300 or time.monotonic() - last_progress_at > 60:
                proc.kill()
                proc.wait()
                raise SystemExit(f"Task-boundary trace timed out; last={last_progress}; output={out}")
            time.sleep(0.25)

    elapsed = time.monotonic() - started
    metadata = out / "metadata.txt"
    with metadata.open("a", encoding="utf-8") as stream:
        stream.write(f"source_rom_sha256={sha(ROM)}\n")
        stream.write(f"opening_input_sha256={sha(OPENING)}\nroute_input_sha256={sha(ROUTE)}\n")
        stream.write(f"fceux_exit_code={proc.returncode}\nelapsed_seconds={elapsed:.3f}\n")
    expected_outputs = ["task_events.csv", "task_events_repeat.csv",
                        "task_writes.csv", "task_writes_repeat.csv"]
    if proc.returncode not in (0, -11) or "complete=true" not in metadata.read_text(encoding="utf-8"):
        raise SystemExit(f"Task-boundary trace incomplete (exit {proc.returncode}); output={out}")
    if not all((out / name).is_file() for name in expected_outputs):
        raise SystemExit(f"Trace outputs missing; output={out}")
    event_hash = normalized_hash(out / expected_outputs[0])
    write_hash = normalized_hash(out / expected_outputs[2])
    if event_hash != normalized_hash(out / expected_outputs[1]):
        raise SystemExit(f"Task event replays differ; output={out}")
    if write_hash != normalized_hash(out / expected_outputs[3]):
        raise SystemExit(f"Task writer replays differ; output={out}")
    metadata_text = metadata.read_text(encoding="utf-8")
    result = {
        "checkpoint_frame": 8399,
        "replay_frames": [8400, 8953],
        "replays": 2,
        "normalized_event_sha256": event_hash,
        "normalized_write_sha256": write_hash,
        "checkpoint_signature_verified_after_both_loads": "checkpoint_signature=frame/cycle, RAM2KiB, PPU16KiB, MMC3 registers and mapped PRG bytes" in metadata_text,
        "fceux_exit_code": proc.returncode,
        "elapsed_seconds": round(elapsed, 3),
        "diagnostics_only": True,
    }
    import json
    (out / "validation.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(f"PASS: checkpointed task-boundary replays match; {elapsed:.2f}s; output={out}")


if __name__ == "__main__":
    main()
