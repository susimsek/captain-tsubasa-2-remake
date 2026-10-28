#!/usr/bin/env python3
"""Verify the slot-$0001 wait-call source and the retained two-pass trace."""

from __future__ import annotations

import csv
import hashlib
import json
import sys
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
DEFAULT_TRACE = ROOT / "reference/diagnostics/first_command_task_wait_calls_20261028_080139_utc"


def fail(message: str) -> None:
    raise SystemExit("FAIL: " + message)


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def normalized_csv_hash(path: Path) -> str:
    with path.open(newline="", encoding="utf-8") as stream:
        rows = list(csv.reader(stream))
    if not rows or "pass" not in rows[0]:
        fail(f"{path.name} has no pass column")
    pass_index = rows[0].index("pass")
    for row in rows[1:]:
        del row[pass_index]
    payload = "\n".join(",".join(row) for row in rows).encode()
    return hashlib.sha256(payload).hexdigest()


def parse_hex(value: str) -> int:
    return int(value.removeprefix("$").removeprefix("0x"), 16)


def trace_callsite(row: dict[str, str]) -> int:
    sp = parse_hex(row["sp"])
    stack_page = bytes.fromhex(row["stack_page_0100_01ff"])
    if len(stack_page) != 256:
        fail("a wait-call trace row does not contain the complete stack page")
    return_pc = stack_page[(sp + 1) & 0xFF] | (stack_page[(sp + 2) & 0xFF] << 8)
    return (return_pc - 2) & 0xFFFF


def main() -> None:
    trace_root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else DEFAULT_TRACE
    if len(sys.argv) > 2:
        fail("usage: verify_first_command_task_wait_calls_trace.py [trace-directory]")
    if not ROM.is_file() or digest(ROM) != EXPECTED_ROM_SHA256:
        fail("the supplied Turkish ROM is missing or has a different hash")

    rom = ROM.read_bytes()

    def bank0_bytes(cpu_address: int, count: int) -> bytes:
        offset = 16 + (cpu_address - 0x8000)
        return rom[offset : offset + count]

    if bank0_bytes(0x82B5, 5) != bytes.fromhex("A9 01 20 A8 9F"):
        fail("bank-$00 $82B5 one-tick wait call changed")
    if bank0_bytes(0x9A04, 5) != bytes.fromhex("A9 01 20 A8 9F"):
        fail("bank-$00 $9A04 one-tick wait call changed")
    if bank0_bytes(0x9FA8, 2) != bytes.fromhex("85 19"):
        fail("bank-$00 $9FA8 no longer stores the requested delay to $0019")
    if bank0_bytes(0x9EF7, 2) != bytes.fromhex("D6 00"):
        fail("bank-$00 scheduler countdown instruction changed")
    if bank0_bytes(0x9FE0, 5) != bytes.fromhex("95 00 4C FB 9E"):
        fail("bank-$00 task-delay store/scheduler return changed")

    validation_path = trace_root / "validation.json"
    if not validation_path.is_file():
        fail("trace validation.json is missing")
    validation = json.loads(validation_path.read_text(encoding="utf-8"))
    if validation.get("checkpoint_frame") != 8399 or validation.get("replays") != 2:
        fail("trace did not use the expected frame-8399 two-pass checkpoint")
    if validation.get("checkpoint_signature_verified_after_both_loads") is not True:
        fail("checkpoint signatures were not verified after both loads")

    event_paths = [trace_root / "task_events.csv", trace_root / "task_events_repeat.csv"]
    write_paths = [trace_root / "task_writes.csv", trace_root / "task_writes_repeat.csv"]
    if not all(path.is_file() for path in event_paths + write_paths):
        fail("one or more retained two-pass trace files are missing")
    event_hash = normalized_csv_hash(event_paths[0])
    write_hash = normalized_csv_hash(write_paths[0])
    if event_hash != normalized_csv_hash(event_paths[1]) or event_hash != validation.get("normalized_event_sha256"):
        fail("the two event passes or their recorded validation hash differ")
    if write_hash != normalized_csv_hash(write_paths[1]) or write_hash != validation.get("normalized_write_sha256"):
        fail("the two write passes or their recorded validation hash differ")

    expected_groups = {
        1: {0x82B7: (43, 8400, 8442), 0x9A06: (15, 8443, 8457)},
        2: {0x82B7: (43, 8400, 8442), 0x9A06: (15, 8443, 8457)},
    }
    for pass_number, path in enumerate(event_paths, 1):
        with path.open(newline="", encoding="utf-8") as stream:
            rows = list(csv.DictReader(stream))
        waits = [row for row in rows if row.get("kind") == "task_wait_helper_9FA8"]
        if len(waits) != 58:
            fail(f"pass {pass_number} has {len(waits)} slot-$0001 wait entries, expected 58")
        groups: dict[int, list[dict[str, str]]] = {}
        for row in waits:
            if parse_hex(row["current_task_base_0000"]) != 1 or parse_hex(row["a"]) != 1:
                fail(f"pass {pass_number} has an unexpected task slot or delay at $9FA8")
            groups.setdefault(trace_callsite(row), []).append(row)
        if set(groups) != set(expected_groups[pass_number]):
            fail(f"pass {pass_number} has unexpected wait-helper caller addresses")
        for callsite, (expected_count, first_frame, last_frame) in expected_groups[pass_number].items():
            entries = groups[callsite]
            frames = [int(row["frame"]) for row in entries]
            if len(entries) != expected_count or min(frames) != first_frame or max(frames) != last_frame:
                fail(f"pass {pass_number} caller ${callsite:04X} count/frame range differs")

    print("PASS: ROM wait-call bytes, both checkpointed trace passes, and all 58 slot-$0001 callsites match.")


if __name__ == "__main__":
    main()
