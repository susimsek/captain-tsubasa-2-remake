#!/usr/bin/env python3
"""Validate a captured actor-writer trace and replay its RAM write stream."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
from collections import Counter
from pathlib import Path


EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
EXPECTED_OPENING_SHA256 = "195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3"
EXPECTED_ROUTE_SHA256 = "87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e"
FIRST_FRAME = 8400
LAST_FRAME = 8953
ACTOR_FIRST = 0x0547
ACTOR_LAST = 0x05C4
ACTOR_STRIDE = 0x15
ROUTINE_PCS = {
	"appearance_update_83D9": 0x83D9,
	"motion_update_84DC": 0x84DC,
	"actor_draw_loop_EE9F": 0xEE9F,
}


def fail(message: str) -> None:
	raise SystemExit(f"Trace validation failed: {message}")


def metadata(path: Path) -> dict[str, str]:
	if not path.is_file():
		fail(f"missing {path.name}")
	result: dict[str, str] = {}
	for line in path.read_text(encoding="utf-8").splitlines():
		if "=" in line:
			key, value = line.split("=", 1)
			result[key] = value
	return result


def read_csv(path: Path) -> list[dict[str, str]]:
	if not path.is_file():
		fail(f"missing {path.name}")
	with path.open(newline="", encoding="utf-8") as stream:
		return list(csv.DictReader(stream))


def parse_hex(value: str, field: str) -> int:
	try:
		return int(value.removeprefix("$").removeprefix("0x"), 16)
	except (TypeError, ValueError):
		fail(f"invalid {field}: {value!r}")


def parse_int(value: str, field: str) -> int:
	try:
		return int(value)
	except (TypeError, ValueError):
		fail(f"invalid {field}: {value!r}")


def memory_addresses() -> list[int]:
	return list(range(ACTOR_FIRST, ACTOR_LAST + 1)) + list(range(0x053A, 0x053E))


def check_metadata(values: dict[str, str], capture_dir: Path) -> bool:
	checks = {
		"source_rom_sha256": EXPECTED_ROM_SHA256,
		"opening_input_sha256": EXPECTED_OPENING_SHA256,
		"route_input_sha256": EXPECTED_ROUTE_SHA256,
		"source_frames": "0-8953",
		"instrumented_source_frames": "8400-8953",
		"completed_source_frames": "8954",
		"target_hook_frame_count": "554",
	}
	for key, expected in checks.items():
		if values.get(key) != expected:
			fail(f"metadata {key} expected {expected!r}, got {values.get(key)!r}")
	exit_code = values.get("exit_code")
	clean_exit = exit_code == "0"
	if not clean_exit:
		completed_shutdown_crash = (
			exit_code == "-11"
			and (capture_dir / "progress.txt").is_file()
			and (capture_dir / "progress.txt").read_text(encoding="ascii").strip() == "2:8953"
			and values.get("completed_source_frames") == "8954"
			and values.get("replay_passes", "").startswith("2 from the same verified")
			and values.get("pass_1_checkpoint_verified") == "true"
			and values.get("pass_2_checkpoint_verified") == "true"
			and values.get("pass_1_actor_write_events") == values.get("pass_2_actor_write_events")
			and values.get("pass_1_routine_calls") == values.get("pass_2_routine_calls")
		)
		if not completed_shutdown_crash:
			fail(f"FCEUX exit code {exit_code!r} lacks a complete two-pass trace marker")
	if values.get("audio") is None or "disabled" not in values["audio"]:
		fail("audio was not explicitly disabled")
	if values.get("cycle_counter_available") != "true":
		fail("FCEUX did not expose debugger.getcyclescount()")
	return clean_exit


def check_repeated_outputs(capture_dir: Path) -> dict[str, dict[str, object]]:
	pairs = {
		"actor_memory_writes.csv": "actor_memory_writes_repeat.csv",
		"actor_routine_calls.csv": "actor_routine_calls_repeat.csv",
		"actor_start.bin": "actor_start_repeat.bin",
		"actor_end.bin": "actor_end_repeat.bin",
	}
	result: dict[str, dict[str, object]] = {}
	for first_name, repeat_name in pairs.items():
		first_path, repeat_path = capture_dir / first_name, capture_dir / repeat_name
		if not first_path.is_file() or not repeat_path.is_file():
			fail(f"missing repeated replay outputs {first_name}/{repeat_name}")
		first_bytes, repeat_bytes = first_path.read_bytes(), repeat_path.read_bytes()
		if first_bytes != repeat_bytes:
			fail(f"save-state replay differs between {first_name} and {repeat_name}")
		result[first_name] = {
			"repeat_file": repeat_name,
			"sha256": hashlib.sha256(first_bytes).hexdigest(),
			"byte_identical": True,
		}
	return result


def check_write_stream(rows: list[dict[str, str]], start: bytes, end: bytes) -> dict:
	addresses = memory_addresses()
	if len(start) != len(addresses) or len(end) != len(addresses):
		fail(f"snapshot size must be {len(addresses)} bytes; got {len(start)} and {len(end)}")
	state = bytearray(start)
	index_for_address = {address: i for i, address in enumerate(addresses)}
	by_kind: Counter[str] = Counter()
	by_record: Counter[str] = Counter()
	by_pc_bank: Counter[str] = Counter()
	by_frame: Counter[str] = Counter()
	unknown_old = 0
	last_sequence = -1
	last_absolute_cycle = -1
	last_source_frame = FIRST_FRAME

	for row in rows:
		sequence = parse_int(row["sequence"], "write sequence")
		if sequence != last_sequence + 1:
			fail(f"write sequence discontinuity at {sequence}")
		last_sequence = sequence
		frame = parse_int(row["source_frame"], "source frame")
		if not FIRST_FRAME <= frame <= LAST_FRAME:
			fail(f"write outside target frame range: {frame}")
		if frame < last_source_frame:
			fail(f"source frames are out of order at write {sequence}")
		last_source_frame = frame
		cycle = parse_int(row["cycle_absolute"], "absolute cycle")
		if cycle < 0:
			fail(f"absolute cycle is unavailable at write {sequence}")
		if cycle < last_absolute_cycle:
			fail(f"absolute cycle went backwards at write {sequence}")
		last_absolute_cycle = cycle
		address = parse_hex(row["address"], "write address")
		if address not in index_for_address:
			fail(f"unexpected write address {address:04X}")
		cell = index_for_address[address]
		current = state[cell]
		old_field = row["old_value"]
		if not old_field:
			unknown_old += 1
			fail(f"write {sequence} has no known old value at {address:04X}")
		old_value = parse_hex(old_field, "old value")
		if old_value != current:
			fail(f"write {sequence} old value at {address:04X}: log={old_value:02X}, reconstructed={current:02X}")
		new_value = parse_hex(row["new_value"], "new value")
		if not 0 <= new_value <= 0xFF:
			fail(f"write {sequence} new value is not a byte")
		state[cell] = new_value
		kind = row["event"]
		by_kind[kind] += 1
		by_pc_bank[row["pc_prg_bank"] or "unknown"] += 1
		by_frame[str(frame)] += 1
		if address >= ACTOR_FIRST:
			idx = (address - ACTOR_FIRST) // ACTOR_STRIDE
			base = ACTOR_FIRST + idx * ACTOR_STRIDE
			if row["actor_record_index"] != str(idx) or parse_hex(row["actor_record"], "actor record") != base:
				fail(f"actor index/base mismatch at write {sequence}")
			if parse_hex(row["record_offset"], "record offset") != address - base:
				fail(f"actor byte offset mismatch at write {sequence}")
			by_record[str(idx)] += 1
		else:
			if row["actor_record_index"] or row["actor_record"]:
				fail(f"global field write {sequence} has an actor index")

	if bytes(state) != end:
		mismatches = []
		for i, address in enumerate(addresses):
			if state[i] != end[i]:
				mismatches.append(f"${address:04X}: replay={state[i]:02X}, endpoint={end[i]:02X}")
				if len(mismatches) == 8:
					break
		fail("replayed writes do not produce endpoint RAM: " + "; ".join(mismatches))
	return {
		"write_count": len(rows),
		"write_kinds": dict(by_kind),
		"writes_by_actor_record_index": dict(by_record),
		"writes_by_pc_prg_bank": dict(by_pc_bank),
		"frames_with_writes": len(by_frame),
		"unknown_old_value_count": unknown_old,
		"all_writes_replay_to_endpoint": True,
	}


def check_routine_calls(rows: list[dict[str, str]]) -> dict:
	by_event: Counter[str] = Counter()
	by_frame: Counter[str] = Counter()
	last_sequence = -1
	last_cycle = -1
	for row in rows:
		sequence = parse_int(row["sequence"], "routine sequence")
		if sequence != last_sequence + 1:
			fail(f"routine sequence discontinuity at {sequence}")
		last_sequence = sequence
		frame = parse_int(row["source_frame"], "routine source frame")
		if not FIRST_FRAME <= frame <= LAST_FRAME:
			fail(f"routine call outside target frame range: {frame}")
		cycle = parse_int(row["cycle_absolute"], "routine absolute cycle")
		if cycle < 0:
			fail(f"routine absolute cycle is unavailable at call {sequence}")
		if cycle < last_cycle:
			fail(f"routine absolute cycle went backwards at call {sequence}")
		last_cycle = cycle
		event = row["event"]
		if event not in ROUTINE_PCS:
			fail(f"unexpected routine event {event!r}")
		if parse_hex(row["cpu_pc"], "routine PC") != ROUTINE_PCS[event]:
			fail(f"routine PC does not match hook {event} at call {sequence}")
		by_event[event] += 1
		by_frame[str(frame)] += 1
	for event in ROUTINE_PCS:
		if by_event[event] == 0:
			fail(f"no calls recorded for {event}")
	return {
		"routine_call_count": len(rows),
		"calls_by_routine": dict(by_event),
		"frames_with_calls": len(by_frame),
	}


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("capture_dir", type=Path, help="completed first_command_actor_writer_trace_* directory")
	args = parser.parse_args()
	root = args.capture_dir.resolve()
	meta = metadata(root / "metadata.txt")
	clean_exit = check_metadata(meta, root)
	repeated_outputs = check_repeated_outputs(root)
	write_summary = check_write_stream(
		read_csv(root / "actor_memory_writes.csv"),
		(root / "actor_start.bin").read_bytes(),
		(root / "actor_end.bin").read_bytes(),
	)
	routine_summary = check_routine_calls(read_csv(root / "actor_routine_calls.csv"))
	summary = {
		"status": "validated" if clean_exit else "validated_with_fceux_shutdown_crash",
		"fceux_process_exit_code": int(meta["exit_code"]),
		"fceux_exited_cleanly": clean_exit,
		"save_state_repeat_outputs": repeated_outputs,
		"capture_dir": str(root),
		"rom_sha256": EXPECTED_ROM_SHA256,
		"input_timeline_sha256": {
			"opening": EXPECTED_OPENING_SHA256,
			"post_title": EXPECTED_ROUTE_SHA256,
		},
		"source_frame_window": [FIRST_FRAME, LAST_FRAME],
		"write_stream": write_summary,
		"routine_calls": routine_summary,
		"runtime_asset_policy": "diagnostic write/call records only; no captured values are runtime assets",
	}
	output_path = root / "actor_writer_trace_validation.json"
	output_path.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
	print(f"Validated actor-writer trace: {output_path}")
	print(f"Writes: {write_summary['write_count']}; routines: {routine_summary['routine_call_count']}")


if __name__ == "__main__":
	main()
