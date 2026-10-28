#!/usr/bin/env python3
"""Run and validate the muted two-pass fresh-KICK-OFF entry-context trace."""

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
LUA = ROOT / "tools/diagnostics/trace_fresh_kickoff_entry_context.lua"
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
    pass_index = rows[0].index("pass")
    for row in rows[1:]:
        del row[pass_index]
    payload = "\n".join(",".join(row) for row in rows).encode()
    return hashlib.sha256(payload).hexdigest()


def main() -> None:
    for path, expected in EXPECTED.items():
        if not path.is_file() or sha(path) != expected:
            raise SystemExit(f"Missing or changed trace input: {path.name}")
    if not LUA.is_file() or not FCEUX.is_file():
        raise SystemExit("FCEUX or fresh-entry Lua trace is unavailable")

    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_utc")
    output = ROOT / "reference/diagnostics" / f"fresh_kickoff_entry_context_{timestamp}"
    output.mkdir(parents=True, exist_ok=False)
    environment = os.environ.copy()
    environment.update({
        "SDL_AUDIODRIVER": "dummy",
        "CT2_PROJECT_ROOT": str(ROOT),
        "CT2_FRESH_ENTRY_TRACE_OUTPUT_DIR": str(output),
    })
    command = [str(FCEUX), "--sound", "0", "--volume", "0", "--no-config", "1",
               "--newppu", "1", "--loadlua", str(LUA), str(ROM)]
    started = time.monotonic()
    last_progress, last_progress_at = None, started
    with (output / "fceux_stdout.txt").open("w") as stdout, (output / "fceux_stderr.txt").open("w") as stderr:
        process = subprocess.Popen(command, env=environment, stdout=stdout, stderr=stderr)
        while process.poll() is None:
            progress_file = output / "progress.txt"
            if progress_file.exists():
                progress = progress_file.read_text().strip()
                if progress != last_progress:
                    print(f"Muted fresh-entry replay: {progress}", flush=True)
                    last_progress, last_progress_at = progress, time.monotonic()
            if time.monotonic() - started > 300 or time.monotonic() - last_progress_at > 60:
                process.kill()
                process.wait()
                raise SystemExit(f"Fresh-entry trace timed out; last={last_progress}; output={output}")
            time.sleep(0.25)

    elapsed = time.monotonic() - started
    metadata = output / "metadata.txt"
    with metadata.open("a", encoding="utf-8") as stream:
        stream.write(f"source_rom_sha256={sha(ROM)}\n")
        stream.write(f"opening_input_sha256={sha(OPENING)}\nroute_input_sha256={sha(ROUTE)}\n")
        stream.write(f"fceux_exit_code={process.returncode}\nelapsed_seconds={elapsed:.3f}\n")
    expected_files = ["events.csv", "events_repeat.csv", "accesses.csv", "accesses_repeat.csv"]
    if process.returncode not in (0, -11) or "complete=true" not in metadata.read_text(encoding="utf-8"):
        raise SystemExit(f"Fresh-entry trace incomplete (exit {process.returncode}); output={output}")
    if not all((output / name).is_file() for name in expected_files):
        raise SystemExit(f"Trace output is missing; output={output}")

    hashes = {name: normalized_hash(output / name) for name in ("events.csv", "accesses.csv")}
    for first, second in (("events.csv", "events_repeat.csv"), ("accesses.csv", "accesses_repeat.csv")):
        if normalized_hash(output / first) != normalized_hash(output / second):
            raise SystemExit(f"Two source replays differ: {first}/{second}; output={output}")
    with (output / "events.csv").open(newline="", encoding="utf-8") as stream:
        events = list(csv.DictReader(stream))
    with (output / "accesses.csv").open(newline="", encoding="utf-8") as stream:
        accesses = list(csv.DictReader(stream))
    match_index_write_counts: dict[str, int] = {}
    for pass_name, event_path, access_path in (("1", "events.csv", "accesses.csv"),
                                                ("2", "events_repeat.csv", "accesses_repeat.csv")):
        with (output / event_path).open(newline="", encoding="utf-8") as stream:
            pass_events = list(csv.DictReader(stream))
        with (output / access_path).open(newline="", encoding="utf-8") as stream:
            pass_accesses = list(csv.DictReader(stream))
        expected_kinds = {row["kind"] for row in pass_events}
        required = {"match_selector_A86E_entry", "opponent_formula_A8AF", "slot05_entry_D11E"}
        if not required.issubset(expected_kinds):
            raise SystemExit(f"Pass {pass_name} missed required source events {required - expected_kinds}; output={output}")
        a86e = next(row for row in pass_events if row["kind"] == "match_selector_A86E_entry")
        d11e = next(row for row in pass_events if row["kind"] == "slot05_entry_D11E")
        if a86e["ram_0026"] != "$00" or d11e["ram_0026"] != "$00":
            raise SystemExit(f"Pass {pass_name} did not retain match index zero; output={output}")
        if d11e["ram_0027"] != "$00" or d11e["ram_002b"] != "$03":
            raise SystemExit(f"Pass {pass_name} has unexpected period/opponent at $D11E; output={output}")
        if d11e["sp"] != "$52" or d11e["current_task_base"] != "$05":
            raise SystemExit(f"Pass {pass_name} has unexpected slot-$05 entry stack/task; output={output}")
        match_index_writes = [row for row in pass_accesses
                              if row["kind"] == "write" and row["address"] == "$0026"]
        match_index_write_counts[pass_name] = len(match_index_writes)
        if match_index_writes:
            summary = ", ".join(f"{row['pc']}={row['value']}@{row['source_frame']}" for row in match_index_writes)
            raise SystemExit(f"Pass {pass_name} rewrote `$0026` inside the captured interval: {summary}; output={output}")
    if not any(row["kind"] == "read" and row["address"] == "$0026" for row in accesses):
        raise SystemExit(f"No `$0026` read hook was captured; output={output}")
    if not any(row["kind"] == "write" and row["address"] == "$002B" and row["value"] == "$03" for row in accesses):
        raise SystemExit(f"No `$002B=$03` source writer was captured; output={output}")
    if not any(row["kind"] == "write" and row["address"] == "$0027" and row["value"] == "$00" for row in accesses):
        raise SystemExit(f"No `$0027=$00` source writer was captured; output={output}")

    result = {
        "checkpoint_frame": 4692,
        "replay_from_frame": 4693,
        "replays": 2,
        "normalized_event_sha256": hashes["events.csv"],
        "normalized_access_sha256": hashes["accesses.csv"],
        "signature_verified_after_both_loads": "checkpoint_signature=frame/cycle, RAM2KiB, PPU16KiB, MMC3 registers and mapped PRG bytes" in metadata.read_text(encoding="utf-8"),
        "observed": {
            "match_index_0026": 0,
            "period_0027_at_D11E": 0,
            "opponent_002B_at_D11E": 3,
            "slot05_entry_pc": "$D11E",
            "slot05_entry_sp": "$52",
        },
        "match_index_write_counts_by_pass": match_index_write_counts,
        "match_index_unchanged_within_captured_interval": all(count == 0 for count in match_index_write_counts.values()),
        "fceux_exit_code": process.returncode,
        "elapsed_seconds": round(elapsed, 3),
        "diagnostics_only": True,
        "trace_or_capture_ram_used_as_runtime_input": False,
        "numbered_slots_used": False,
    }
    (output / "validation.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(f"PASS: two source replays match through `$A86E` and slot-$05 `$D11E`; {elapsed:.2f}s; output={output}")


if __name__ == "__main__":
    main()
