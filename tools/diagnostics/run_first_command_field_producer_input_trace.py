#!/usr/bin/env python3
"""Run and validate the muted first-command field producer input/caller trace."""

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
LUA = ROOT / "tools/diagnostics/trace_first_command_field_producer_inputs_from_8399.lua"
OPENING_INPUT = ROOT / "reference/opening_reference_capture/input_timeline.csv"
ROUTE_INPUT = ROOT / "reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
FCEUX = Path("/opt/homebrew/bin/fceux")
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
EXPECTED_OPENING_SHA256 = "195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3"
EXPECTED_ROUTE_SHA256 = "87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e"
LAST_TRACE_FRAME = 8953
TOTAL_TIMEOUT_SECONDS = 300
NO_PROGRESS_TIMEOUT_SECONDS = 60


def sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def read_frames(path: Path, frame_column: str) -> list[int]:
	with path.open(newline="", encoding="utf-8") as stream:
		return [int(row[frame_column]) for row in csv.DictReader(stream)]


def normalized_csv_hash(path: Path, ignored_column: str) -> str:
	with path.open(newline="", encoding="utf-8") as stream:
		rows = list(csv.reader(stream))
	if not rows or ignored_column not in rows[0]:
		raise SystemExit(f"Trace CSV lacks required column {ignored_column}: {path}")
	index = rows[0].index(ignored_column)
	for row in rows[1:]:
		if index < len(row):
			del row[index]
	payload = "\n".join(",".join(row) for row in rows).encode("utf-8")
	return hashlib.sha256(payload).hexdigest()


def validate_inputs() -> tuple[str, str]:
	for path in (ROM, LUA, OPENING_INPUT, ROUTE_INPUT):
		if not path.is_file():
			raise SystemExit(f"Required trace input is missing: {path}")
	rom_hash, opening_hash, route_hash = sha256(ROM), sha256(OPENING_INPUT), sha256(ROUTE_INPUT)
	if rom_hash != EXPECTED_ROM_SHA256:
		raise SystemExit(f"Wrong target ROM: {rom_hash}")
	if opening_hash != EXPECTED_OPENING_SHA256:
		raise SystemExit(f"Opening input timeline changed: {opening_hash}")
	if route_hash != EXPECTED_ROUTE_SHA256:
		raise SystemExit(f"Post-title input timeline changed: {route_hash}")
	opening_frames = read_frames(OPENING_INPUT, "frame")
	route_frames = read_frames(ROUTE_INPUT, "source_frame")
	if opening_frames[:4693] != list(range(4693)):
		raise SystemExit("Opening timeline must contain source frames 0–4692.")
	if route_frames[: LAST_TRACE_FRAME - 4693 + 1] != list(range(4693, LAST_TRACE_FRAME + 1)):
		raise SystemExit("Post-title timeline must contain source frames 4693–8953.")
	return opening_hash, route_hash


def main() -> None:
	opening_hash, route_hash = validate_inputs()
	if not FCEUX.is_file():
		raise SystemExit(f"FCEUX is not installed at {FCEUX}")
	stamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_utc")
	output = ROOT / "reference/diagnostics" / f"first_command_field_producer_input_trace_{stamp}"
	output.mkdir(parents=True, exist_ok=False)
	env = os.environ.copy()
	env.update({
		"SDL_AUDIODRIVER": "dummy",
		"CT2_PROJECT_ROOT": str(ROOT),
		"CT2_FIELD_INPUT_TRACE_OUTPUT_DIR": str(output),
	})
	command = [str(FCEUX), "--sound", "0", "--volume", "0", "--no-config", "1",
		"--newppu", "1", "--loadlua", str(LUA), str(ROM)]
	started = time.monotonic()
	last_progress: str | None = None
	last_progress_at = started
	with (output / "fceux_stdout.txt").open("w", encoding="utf-8") as stdout, \
			(output / "fceux_stderr.txt").open("w", encoding="utf-8") as stderr:
		process = subprocess.Popen(command, env=env, stdout=stdout, stderr=stderr)
		while process.poll() is None:
			progress_path = output / "progress.txt"
			if progress_path.is_file():
				progress = progress_path.read_text(encoding="ascii").strip()
				if progress and progress != last_progress:
					print(f"Muted field producer input trace: {progress}", flush=True)
					last_progress = progress
					last_progress_at = time.monotonic()
			elapsed = time.monotonic() - started
			if elapsed > TOTAL_TIMEOUT_SECONDS:
				process.kill()
				process.wait()
				raise SystemExit(f"Trace exceeded 5 minutes; last progress={last_progress}; output={output}")
			if time.monotonic() - last_progress_at > NO_PROGRESS_TIMEOUT_SECONDS:
				process.kill()
				process.wait()
				raise SystemExit(f"Trace made no progress for 60 seconds; last progress={last_progress}; output={output}")
			time.sleep(0.25)

	elapsed = time.monotonic() - started
	metadata_path = output / "metadata.txt"
	with metadata_path.open("a", encoding="utf-8") as stream:
		stream.write(f"source_rom_sha256={sha256(ROM)}\n")
		stream.write(f"opening_input_sha256={opening_hash}\nroute_input_sha256={route_hash}\n")
		stream.write(f"fceux_executable={FCEUX}\nfceux_command={' '.join(command)}\n")
		stream.write(f"exit_code={process.returncode}\nelapsed_seconds={elapsed:.3f}\n")

	metadata_text = metadata_path.read_text(encoding="utf-8")
	if process.returncode not in (0, -11) or "complete=true" not in metadata_text:
		raise SystemExit(f"FCEUX trace incomplete (exit {process.returncode}); output={output}")
	paired = [
		("ppu_packet_ram_writes.csv", "ppu_packet_ram_writes_repeat.csv", "pass"),
		("ppu_packet_ready_events.csv", "ppu_packet_ready_events_repeat.csv", "pass"),
		("queue_consumer_entries.csv", "queue_consumer_entries_repeat.csv", "pass"),
		("field_producer_input_writes.csv", "field_producer_input_writes_repeat.csv", "pass"),
		("field_producer_entries.csv", "field_producer_entries_repeat.csv", "pass"),
		("coordinate_pointer_table_entries.csv", "coordinate_pointer_table_entries_repeat.csv", "pass"),
		("coordinate_pointer_codepath.csv", "coordinate_pointer_codepath_repeat.csv", "pass"),
	]
	for first, second, label in paired:
		paths = (output / first, output / second)
		if not all(path.is_file() for path in paths):
			raise SystemExit(f"Trace output is missing: {paths}; output={output}")
		if normalized_csv_hash(paths[0], label) != normalized_csv_hash(paths[1], label):
			raise SystemExit(f"The two save-state passes differ in {first}; output={output}")
	entries_path = output / "field_producer_entries.csv"
	with entries_path.open(newline="", encoding="utf-8") as stream:
		entries = list(csv.DictReader(stream))
	entry_labels = {row["entry_pc"] for row in entries}
	if not {"$E6F2", "$E6FA", "$E701", "$F015", "$F0B5"}.issubset(entry_labels):
		raise SystemExit(f"The trace did not enter all coordinate/packet producer paths: {entry_labels}; output={output}")
	for label in sorted(entry_labels):
		count = sum(row["entry_pc"] == label for row in entries)
		print(f"{label} entries/pass={count}", flush=True)
	for pass_index, path in ((1, entries_path), (2, output / "field_producer_entries_repeat.csv")):
		with path.open(newline="", encoding="utf-8") as stream:
			pass_entries = list(csv.DictReader(stream))
		f015 = [row for row in pass_entries if row["entry_pc"] == "$F015"]
		f0b5 = [row for row in pass_entries if row["entry_pc"] == "$F0B5"]
		if len(f015) != 6 or len(f0b5) != 1:
			raise SystemExit(f"Pass {pass_index}: expected six F015 and one F0B5 entry; output={output}")
		if [row["cpu_a"] for row in f015] != [f"${value:02X}" for value in range(6)]:
			raise SystemExit(f"Pass {pass_index}: F015 A sequence differs; output={output}")
		for row in f015 + f0b5:
			if (row["entry_prg_bank"], row["ram_05CD"], row["ram_05CE"], row["ram_063D"]) != ("$1F", "$80", "$A0", "$02"):
				raise SystemExit(f"Pass {pass_index}: producer input state differs at {row['entry_pc']}; output={output}")
		print(f"pass {pass_index}: F015/F0B5 entry inputs verified; $05CD=$80 $05CE=$A0 $063D=$02", flush=True)
	for pass_index, path in ((1, output / "field_producer_input_writes.csv"),
			(2, output / "field_producer_input_writes_repeat.csv")):
		with path.open(newline="", encoding="utf-8") as stream:
			state_writes = list(csv.DictReader(stream))
		for address, expected_frame, expected_pc, expected_value, expected_bank in (
			("$05CE", "8905", "$8345", "$A0", "11"),
			("$05CD", "8905", "$834C", "$80", "11"),
			("$063D", "8908", "$F00C", "$02", "31"),
		):
			writes_for_address = [row for row in state_writes if row["cpu_address"] == address]
			last_write = writes_for_address[-1] if writes_for_address else None
			if last_write is None or (last_write["source_frame"], last_write["cpu_pc_after_write"],
					last_write["new_value"], last_write["pc_prg_bank"]) != (
						expected_frame, expected_pc, expected_value, expected_bank):
				raise SystemExit(f"Pass {pass_index}: expected last {address} writer was not observed; output={output}")
		print(f"pass {pass_index}: last state writes before producers verified ($05CE/$05CD/$063D)", flush=True)
	with (output / "coordinate_pointer_table_entries.csv").open(newline="", encoding="utf-8") as stream:
		table_entries = list(csv.DictReader(stream))
	if not table_entries:
		raise SystemExit("The trace did not enter the $CD7C coordinate pointer-table loader.")
	print(f"$CD7C pointer-table reads/pass={len(table_entries)}", flush=True)
	with (output / "coordinate_pointer_codepath.csv").open(newline="", encoding="utf-8") as stream:
		codepath = list(csv.DictReader(stream))
	if not codepath:
		raise SystemExit("The trace did not execute the $CD74-$CD88 pointer code path.")
	print(f"$CD74-$CD88 instruction hooks/pass={len(codepath)}", flush=True)
	for address in ("$0034", "$0035", "$034E", "$0350", "$0366", "$0368", "$0441", "$05FB", "$05CD", "$05CE", "$063D", "$0635", "$0637"):
		count = 0
		with (output / "field_producer_input_writes.csv").open(newline="", encoding="utf-8") as stream:
			count = sum(row["cpu_address"] == address for row in csv.DictReader(stream))
		print(f"{address} writes/pass={count}", flush=True)
	for first, second in [
		("frame_edges.csv", "frame_edges_repeat.csv"),
		("buffer_start.bin", "buffer_start_repeat.bin"),
		("buffer_end.bin", "buffer_end_repeat.bin"),
	]:
		if sha256(output / first) != sha256(output / second):
			raise SystemExit(f"The two save-state passes differ in {first}; output={output}")
	print(f"PASS: two checkpointed source-input/caller traces match, including packet queue; elapsed={elapsed:.2f}s; exit={process.returncode}")
	if process.returncode == -11:
		print("NOTE: FCEUX crashed during shutdown after writing complete trace outputs.")
	print(output)


if __name__ == "__main__":
	main()
