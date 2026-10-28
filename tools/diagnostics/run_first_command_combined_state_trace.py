#!/usr/bin/env python3
"""Run and validate the combined muted FCEUX scheduler/scenario/actor trace."""

from __future__ import annotations

import csv
import hashlib
import json
import os
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
LUA = ROOT / "tools/diagnostics/trace_first_command_combined_state_from_8399.lua"
OPENING = ROOT / "reference/opening_reference_capture/input_timeline.csv"
ROUTE = ROOT / "reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
FCEUX = Path("/opt/homebrew/bin/fceux")
EXPECTED = {
    ROM: "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
    OPENING: "195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3",
    ROUTE: "87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e",
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def normalized_digest(path: Path) -> tuple[str, int]:
    with path.open(newline="", encoding="utf-8") as stream:
        rows = list(csv.reader(stream))
    if not rows or "pass" not in rows[0]:
        raise SystemExit(f"Missing pass column in {path}")
    pass_column = rows[0].index("pass")
    for row in rows[1:]:
        del row[pass_column]
    payload = "\n".join(",".join(row) for row in rows).encode()
    return hashlib.sha256(payload).hexdigest(), len(rows) - 1


def main() -> None:
    for path, expected in EXPECTED.items():
        if not path.is_file() or sha256(path) != expected:
            raise SystemExit(f"Missing or changed hashed trace input: {path.name}")
    if not LUA.is_file() or not FCEUX.is_file():
        raise SystemExit("The combined trace script or FCEUX executable is unavailable")

    run_id = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_utc")
    out = ROOT / "reference/diagnostics" / f"first_command_combined_state_{run_id}"
    out.mkdir(parents=True, exist_ok=False)
    env = os.environ.copy()
    env.update({
        "SDL_AUDIODRIVER": "dummy",
        "CT2_PROJECT_ROOT": str(ROOT),
        "CT2_COMBINED_TRACE_OUTPUT_DIR": str(out),
    })
    command = [
        str(FCEUX), "--sound", "0", "--volume", "0", "--no-config", "1",
        "--newppu", "1", "--loadlua", str(LUA), str(ROM),
    ]
    started = time.monotonic()
    last_progress, last_progress_at = None, started
    with (out / "fceux_stdout.txt").open("w", encoding="utf-8") as stdout, \
            (out / "fceux_stderr.txt").open("w", encoding="utf-8") as stderr:
        process = subprocess.Popen(command, env=env, stdout=stdout, stderr=stderr)
        while process.poll() is None:
            progress_path = out / "progress.txt"
            if progress_path.is_file():
                progress = progress_path.read_text(encoding="ascii").strip()
                if progress and progress != last_progress:
                    print(f"Muted combined FCEUX trace: {progress}", flush=True)
                    last_progress, last_progress_at = progress, time.monotonic()
            now = time.monotonic()
            if now - started > 300 or now - last_progress_at > 60:
                process.kill()
                process.wait()
                raise SystemExit(f"Trace timed out at {last_progress}; diagnostics: {out}")

    elapsed = time.monotonic() - started
    metadata_path = out / "metadata.txt"
    metadata = metadata_path.read_text(encoding="utf-8") if metadata_path.is_file() else ""
    with metadata_path.open("a", encoding="utf-8") as stream:
        for path, expected in EXPECTED.items():
            stream.write(f"sha256_{path.name}={expected}\n")
        stream.write(f"fceux_executable={FCEUX}\n")
        stream.write("fceux_command=" + " ".join(command) + "\n")
        stream.write(f"fceux_exit_code={process.returncode}\nelapsed_seconds={elapsed:.3f}\n")

    if "complete=true" not in metadata or process.returncode not in (0, -11):
        raise SystemExit(f"Trace did not complete cleanly (exit {process.returncode}); diagnostics: {out}")
    events_a, events_b = out / "combined_events.csv", out / "combined_events_repeat.csv"
    writes_a, writes_b = out / "combined_writes.csv", out / "combined_writes_repeat.csv"
    if not all(path.is_file() for path in (events_a, events_b, writes_a, writes_b)):
        raise SystemExit(f"One or more replay CSVs are missing; diagnostics: {out}")
    event_hash_a, event_count_a = normalized_digest(events_a)
    event_hash_b, event_count_b = normalized_digest(events_b)
    write_hash_a, write_count_a = normalized_digest(writes_a)
    write_hash_b, write_count_b = normalized_digest(writes_b)
    if event_hash_a != event_hash_b or event_count_a != event_count_b:
        raise SystemExit(f"Normalized event replays differ; diagnostics: {out}")
    if write_hash_a != write_hash_b or write_count_a != write_count_b:
        raise SystemExit(f"Normalized write replays differ; diagnostics: {out}")

    result = {
        "checkpoint_frame": 8399,
        "replay_frames": [8400, 8953],
        "replays": 2,
        "normalized_event_sha256": event_hash_a,
        "normalized_event_rows_per_pass": event_count_a,
        "normalized_write_sha256": write_hash_a,
        "normalized_write_rows_per_pass": write_count_a,
        "fceux_exit_code": process.returncode,
        "elapsed_seconds": round(elapsed, 3),
        "diagnostics_only": True,
    }
    (out / "validation.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(f"PASS: checkpointed event/write replay hashes match in {elapsed:.2f}s; output={out}")
    if process.returncode == -11:
        print("NOTE: FCEUX returned -11 after writing complete, byte-identical trace outputs.")


if __name__ == "__main__":
    main()
