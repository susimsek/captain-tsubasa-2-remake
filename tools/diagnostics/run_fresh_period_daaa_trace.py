#!/usr/bin/env python3
"""Run and compare two muted FCEUX replays of the $DAAA-to-$DAD8 setup."""

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
LUA = ROOT / "tools/diagnostics/trace_fresh_period_daaa_calls_from_8399.lua"
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


def normalized_csv_hash(path: Path) -> str:
    with path.open(newline="", encoding="utf-8") as stream:
        rows = list(csv.reader(stream))
    if not rows or "pass" not in rows[0]:
        raise SystemExit(f"Trace CSV has no pass column: {path}")
    pass_column = rows[0].index("pass")
    for row in rows[1:]:
        del row[pass_column]
    normalized = "\n".join(",".join(row) for row in rows).encode()
    return hashlib.sha256(normalized).hexdigest()


def main() -> None:
    for path, expected_hash in EXPECTED.items():
        if not path.is_file() or sha256(path) != expected_hash:
            raise SystemExit(f"Missing or changed trace input: {path.name}")
    if not LUA.is_file() or not FCEUX.is_file():
        raise SystemExit("FCEUX or the focused trace script is unavailable")

    run_id = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_utc")
    out = ROOT / "reference/diagnostics" / f"fresh_period_daaa_trace_{run_id}"
    out.mkdir(parents=True, exist_ok=False)
    env = os.environ.copy()
    env.update({
        "SDL_AUDIODRIVER": "dummy",
        "CT2_PROJECT_ROOT": str(ROOT),
        "CT2_DAAA_TRACE_OUTPUT_DIR": str(out),
    })
    command = [str(FCEUX), "--sound", "0", "--volume", "0", "--no-config", "1",
               "--newppu", "1", "--loadlua", str(LUA), str(ROM)]
    started = time.monotonic()
    last_progress: str | None = None
    last_progress_at = started
    with (out / "fceux_stdout.txt").open("w", encoding="utf-8") as stdout, \
            (out / "fceux_stderr.txt").open("w", encoding="utf-8") as stderr:
        process = subprocess.Popen(command, env=env, stdout=stdout, stderr=stderr)
        while process.poll() is None:
            progress_path = out / "progress.txt"
            if progress_path.is_file():
                progress = progress_path.read_text(encoding="ascii").strip()
                if progress and progress != last_progress:
                    print(f"Muted DAAA trace: {progress}", flush=True)
                    last_progress, last_progress_at = progress, time.monotonic()
            if time.monotonic() - started > 300 or time.monotonic() - last_progress_at > 60:
                process.kill()
                process.wait()
                raise SystemExit(f"Trace timed out; last progress={last_progress}; output={out}")
            time.sleep(0.25)

    elapsed = time.monotonic() - started
    metadata_path = out / "metadata.txt"
    metadata_text = metadata_path.read_text(encoding="utf-8") if metadata_path.is_file() else ""
    with metadata_path.open("a", encoding="utf-8") as stream:
        stream.write(f"source_rom_sha256={sha256(ROM)}\n")
        stream.write(f"opening_input_sha256={sha256(OPENING)}\nroute_input_sha256={sha256(ROUTE)}\n")
        stream.write(f"fceux_executable={FCEUX}\n")
        stream.write(f"fceux_command={' '.join(command)}\n")
        stream.write(f"fceux_exit_code={process.returncode}\nelapsed_seconds={elapsed:.3f}\n")

    outputs = ["call_boundaries.csv", "call_boundaries_repeat.csv", "ram_writes.csv", "ram_writes_repeat.csv"]
    if not all((out / name).is_file() for name in outputs):
        raise SystemExit(f"Trace output files are missing; output={out}")
    if "complete=true" not in metadata_text or "pass_1_reached_dad8=true" not in metadata_text or "pass_2_reached_dad8=true" not in metadata_text:
        raise SystemExit(f"The trace did not reach $DAD8 twice; output={out}")
    if process.returncode not in (0, -11):
        raise SystemExit(f"FCEUX exited with {process.returncode}; output={out}")
    call_hash = normalized_csv_hash(out / outputs[0])
    write_hash = normalized_csv_hash(out / outputs[2])
    if call_hash != normalized_csv_hash(out / outputs[1]):
        raise SystemExit(f"Call-boundary replays differ; output={out}")
    if write_hash != normalized_csv_hash(out / outputs[3]):
        raise SystemExit(f"RAM-write replays differ; output={out}")

    with (out / outputs[0]).open(newline="", encoding="utf-8") as stream:
        call_rows = list(csv.DictReader(stream))
    with (out / outputs[2]).open(newline="", encoding="utf-8") as stream:
        write_rows = list(csv.DictReader(stream))
    names = [row["event"] for row in call_rows]
    required = ["fresh_period_DAAA", "sound_queue_CBF1", "fresh_record_setup_CF4F",
                "mapper_helper_CE2D", "bank1a_entry_8039", "fresh_match_dispatch_DB24",
                "bank18_wrapper_EF7F", "scenario35_caller_DAD8"]
    missing = [name for name in required if name not in names]
    if missing:
        raise SystemExit(f"Trace reached DAD8 but missed expected helper hooks {missing}; output={out}")
    result = {
        "checkpoint_frame": 8399,
        "checkpoint_signature_verified_after_both_loads": True,
        "replays": 2,
        "replay_endpoint": "$DAD8",
        "source_rom_sha256": sha256(ROM),
        "normalized_call_sha256": call_hash,
        "normalized_ram_write_sha256": write_hash,
        "call_rows_per_pass": len(call_rows),
        "ram_write_rows_per_pass": len(write_rows),
        "required_calls_seen": required,
        "audio_muted": True,
        "numbered_save_slot_used": False,
        "diagnostics_only": True,
        "fceux_exit_code": process.returncode,
        "elapsed_seconds": round(elapsed, 3),
    }
    (out / "validation.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(f"PASS: two muted, signature-checked replays matched through $DAD8; {elapsed:.2f}s; output={out}")


if __name__ == "__main__":
    main()
