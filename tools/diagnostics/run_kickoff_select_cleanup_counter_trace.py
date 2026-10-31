#!/usr/bin/env python3
"""Capture the ID-1 Select cleanup counters with muted, checkpointed FCEUX."""

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
LUA = ROOT / "tools/diagnostics/trace_kickoff_select_cleanup_counters.lua"
OPENING = ROOT / "reference/opening_reference_capture/input_timeline.csv"
ROUTE = ROOT / "reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
FCEUX = Path("/opt/homebrew/bin/fceux")
EXPECTED = {
	ROM: "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
	OPENING: "195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3",
	ROUTE: "87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e",
}


def digest(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def normalized_hash(path: Path) -> str:
	with path.open(newline="", encoding="utf-8") as stream:
		rows = list(csv.reader(stream))
	if not rows or "pass" not in rows[0]:
		raise SystemExit(f"Missing pass column in {path}")
	pass_index = rows[0].index("pass")
	for row in rows[1:]:
		del row[pass_index]
	return hashlib.sha256("\n".join(",".join(row) for row in rows).encode()).hexdigest()


def check_snapshot(path: Path) -> None:
	with path.open(newline="", encoding="utf-8") as stream:
		rows = {int(row["source_frame"]): row for row in csv.DictReader(stream)}
	for frame in range(7242, 7258):
		if frame not in rows:
			raise SystemExit(f"Missing frame-end counter snapshot {frame} in {path.name}")
		expected = f"${15 - (frame - 7242):02X}"
		for address in ("ram_004a", "ram_004b"):
			if rows[frame][address] != expected:
				raise SystemExit(f"{path.name} frame {frame} {address}={rows[frame][address]}, expected {expected}")


def check_cleanup_clear_snapshots(output: Path) -> tuple[str, str]:
	ppu_hashes, ram_hashes = [], []
	for pass_number in (1, 2):
		ppu_path = output / f"frame_7258_ppu_pass{pass_number}.bin"
		ram_path = output / f"frame_7258_ram_pass{pass_number}.bin"
		ppu, ram = ppu_path.read_bytes(), ram_path.read_bytes()
		if len(ppu) != 0x4000 or len(ram) != 0x800:
			raise SystemExit(f"Frame-7258 PPU/RAM snapshot has the wrong size in pass {pass_number}")
		if set(ppu[0x2000:0x2800]) != {0}:
			raise SystemExit(f"Frame-7258 pass {pass_number} did not clear PPU $2000-$27FF")
		if ppu[0x3F00:0x3F20] != bytes([0x0F]) * 0x20:
			raise SystemExit(f"Frame-7258 pass {pass_number} palette is not the completed zero-level palette")
		if ram[0x0200:0x0300] != bytes([0xF8]) * 0x100:
			raise SystemExit(f"Frame-7258 pass {pass_number} did not fill the OAM DMA image with $F8")
		if ram[0x0468:0x0568] != bytes([0xF8]) * 0x100:
			raise SystemExit(f"Frame-7258 pass {pass_number} did not fill the OAM shadow with $F8")
		if any(ram[address] != 0 for address in (0x0568, 0x0588, 0x05A8, 0x05C8)):
			raise SystemExit(f"Frame-7258 pass {pass_number} did not clear all four OAM motion records")
		ppu_hashes.append(hashlib.sha256(ppu).hexdigest())
		ram_hashes.append(hashlib.sha256(ram).hexdigest())
	if ppu_hashes[0] != ppu_hashes[1] or ram_hashes[0] != ram_hashes[1]:
		raise SystemExit("Frame-7258 full PPU/RAM snapshots differ between replay passes")
	return ppu_hashes[0], ram_hashes[0]


def check_selector_copy_snapshots(output: Path) -> tuple[int, str]:
	rom_bytes = ROM.read_bytes()
	copy_start = 0x10 + 2 * 0x2000 + (0xACB0 - 0xA000)
	expected = rom_bytes[copy_start:copy_start + 0x1350]
	if len(expected) != 0x1350:
		raise SystemExit("ROM bank-$02 selector copy source is truncated")
	copy_hashes = []
	for pass_number in (1, 2):
		copy_path = output / f"selector_copy_frame_{pass_number}.bin"
		ram_path = output / f"selector_ram_frame_{pass_number}.bin"
		if not copy_path.is_file() or not ram_path.is_file():
			raise SystemExit("FCEUX did not reach the selector return in both passes")
		copy_image, ram_image = copy_path.read_bytes(), ram_path.read_bytes()
		if len(copy_image) != 0x1350 or len(ram_image) != 0x800:
			raise SystemExit(f"Selector return snapshot has the wrong size in pass {pass_number}")
		if copy_image != expected:
			for index, (actual, source) in enumerate(zip(copy_image, expected)):
				if actual != source:
					raise SystemExit(f"Selector ROM-to-RAM copy differs at ${0x6000 + index:04X}: {actual:02X}!={source:02X}")
		copy_hashes.append(hashlib.sha256(copy_image).hexdigest())
	if copy_hashes[0] != copy_hashes[1]:
		raise SystemExit("Selector copied-RAM snapshots differ between replay passes")
	return 0x1350, copy_hashes[0]


def main() -> None:
	for path, expected in EXPECTED.items():
		if not path.is_file() or digest(path) != expected:
			raise SystemExit(f"Missing or changed trace input: {path.name}")
	if not LUA.is_file() or not FCEUX.is_file():
		raise SystemExit("FCEUX or the cleanup-counter Lua trace is unavailable")

	run_id = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_utc")
	output = ROOT / "reference/diagnostics" / f"kickoff_select_cleanup_counters_{run_id}"
	output.mkdir(parents=True, exist_ok=False)
	env = os.environ.copy()
	env.update({"SDL_AUDIODRIVER": "dummy", "CT2_PROJECT_ROOT": str(ROOT),
		"CT2_SELECT_CLEANUP_TRACE_OUTPUT_DIR": str(output)})
	command = [str(FCEUX), "--sound", "0", "--volume", "0", "--no-config", "1",
		"--newppu", "1", "--loadlua", str(LUA), str(ROM)]
	started = time.monotonic()
	last_progress, last_progress_at = None, started
	with (output / "fceux_stdout.txt").open("w", encoding="utf-8") as stdout, \
			(output / "fceux_stderr.txt").open("w", encoding="utf-8") as stderr:
		process = subprocess.Popen(command, env=env, stdout=stdout, stderr=stderr)
		while process.poll() is None:
			progress_path = output / "progress.txt"
			if progress_path.is_file():
				progress = progress_path.read_text(encoding="ascii").strip()
				if progress and progress != last_progress:
					print(f"Muted ID-1 cleanup-counter trace: {progress}", flush=True)
					last_progress, last_progress_at = progress, time.monotonic()
			if time.monotonic() - started > 300 or time.monotonic() - last_progress_at > 60:
				process.kill()
				process.wait()
				raise SystemExit(f"Trace timed out; last progress={last_progress}; output={output}")
			time.sleep(0.25)

	metadata = output / "metadata.txt"
	metadata_text = metadata.read_text(encoding="utf-8") if metadata.is_file() else ""
	metadata_values = dict(line.split("=", 1) for line in metadata_text.splitlines() if "=" in line)
	complete = "complete=true" in metadata_text
	with metadata.open("a", encoding="utf-8") as stream:
		stream.write("fceux_version=2.7.0\n")
		stream.write(f"fceux_exit_code={process.returncode}\nelapsed_seconds={time.monotonic() - started:.3f}\n")
	if process.returncode not in (0, -11) or not complete:
		raise SystemExit(f"Trace incomplete (exit {process.returncode}); output={output}")

	for suffix in ("", "_repeat"):
		check_snapshot(output / f"frame_snapshots{suffix}.csv")
	startup_mapper_path = output / "mapper_shadow_writes_startup.csv"
	mapper_pass_paths = [output / f"mapper_shadow_writes_pass{number}.csv" for number in (1, 2)]
	if not startup_mapper_path.is_file() or not all(path.is_file() for path in mapper_pass_paths):
		raise SystemExit(f"FCEUX did not produce the $0022 mapper-shadow write trace; output={output}")
	mapper_hashes = [normalized_hash(path) for path in mapper_pass_paths]
	if mapper_hashes[0] != mapper_hashes[1]:
		raise SystemExit(f"$0022 mapper-shadow writer passes differ; output={output}")
	with startup_mapper_path.open(newline="", encoding="utf-8") as stream:
		startup_mapper_rows = list(csv.DictReader(stream))
	with mapper_pass_paths[0].open(newline="", encoding="utf-8") as stream:
		mapper_route_rows = list(csv.DictReader(stream))
	mapper_last_route_write = mapper_route_rows[-1] if mapper_route_rows else None
	clear_ppu_hash, clear_ram_hash = check_cleanup_clear_snapshots(output)
	event_hash = normalized_hash(output / "counter_writes.csv")
	if event_hash != normalized_hash(output / "counter_writes_repeat.csv"):
		raise SystemExit(f"Counter-writer passes differ; output={output}")
	caller_hook_hash = normalized_hash(output / "caller_hooks.csv")
	if caller_hook_hash != normalized_hash(output / "caller_hooks_repeat.csv"):
		raise SystemExit(f"Caller instruction-hook passes differ; output={output}")
	sound_queue_path = output / "sound_queue_writes.csv"
	sound_queue_repeat_path = output / "sound_queue_writes_repeat.csv"
	sound_queue_hash = normalized_hash(sound_queue_path)
	if sound_queue_hash != normalized_hash(sound_queue_repeat_path):
		raise SystemExit(f"Sound queue and bank-write passes differ; output={output}")
	with sound_queue_path.open(newline="", encoding="utf-8") as stream:
		sound_queue_rows = list(csv.DictReader(stream))
	if not sound_queue_rows:
		raise SystemExit(f"FCEUX did not capture any sound-queue/bank-state writes; output={output}")
	stream_buffer_path = output / "stream_buffer_writes.csv"
	stream_buffer_repeat_path = output / "stream_buffer_writes_repeat.csv"
	stream_buffer_hash = normalized_hash(stream_buffer_path)
	if stream_buffer_hash != normalized_hash(stream_buffer_repeat_path):
		raise SystemExit(f"`$05B0-$05BF` state-write passes differ; output={output}")
	with stream_buffer_path.open(newline="", encoding="utf-8") as stream:
		stream_buffer_rows = list(csv.DictReader(stream))
	with (output / "stream_buffer_writes_startup.csv").open(newline="", encoding="utf-8") as stream:
		stream_buffer_startup_rows = list(csv.DictReader(stream))
	word_wait_path = output / "word_wait_writes.csv"
	word_wait_repeat_path = output / "word_wait_writes_repeat.csv"
	word_wait_hash = normalized_hash(word_wait_path)
	if word_wait_hash != normalized_hash(word_wait_repeat_path):
		raise SystemExit(f"$0078 wait-counter writer passes differ; output={output}")
	with word_wait_path.open(newline="", encoding="utf-8") as stream:
		word_wait_rows = list(csv.DictReader(stream))
	if not word_wait_rows:
		raise SystemExit(f"FCEUX did not capture any writes to the $0078 wait byte; output={output}")
	with (output / "caller_hooks.csv").open(newline="", encoding="utf-8") as stream:
		caller_rows = list(csv.DictReader(stream))
	startup_queue_path = output / "sound_queue_writes_startup.csv"
	with startup_queue_path.open(newline="", encoding="utf-8") as stream:
		startup_queue_rows = list(csv.DictReader(stream))
	first_saved_bank_0f = next((row for row in startup_queue_rows
		if row["address"] == "$07FC" and row["new_value"] == "$0F"), None)
	if not first_saved_bank_0f:
		raise SystemExit(f"The cold-start trace did not capture a ROM write establishing `$07FC=$0F`; output={output}")
	caller_pcs = {row["pc"] for row in caller_rows}
	stream_hooks = [row for row in caller_rows if row["pc"] in {"$A4EB", "$A500", "$A503", "$A50B", "$A526", "$A539", "$A56C", "$A571", "$A57D", "$A580", "$A58B", "$A59A", "$A5A3", "$A5A9", "$A5B1", "$A5BD", "$A5C6", "$A5E0", "$A5E8", "$A5F1", "$A5FC", "$A603", "$A60A", "$A610", "$B0C0", "$B0C6", "$B0F7", "$B1BA", "$97B6", "$9889", "$C572", "$8122", "$8124", "$812C", "$812F", "$813F", "$8142", "$8145", "$814F", "$8157", "$815A", "$8163", "$A009", "$A203", "$A2AF", "$AA06", "$C557", "$C6BE", "$DB62", "$DB9D"}]
	dispatch_rows = [row for row in caller_rows if row["pc"] == "$B0C6"]
	expected_dispatch = [("$B305", "$0D"), ("$B306", "$05"), ("$B30B", "$05"),
		("$B310", "$05"), ("$B315", "$04"), ("$B31A", "$04"),
		("$B31F", "$04"), ("$B324", "$00"), ("$B327", "$0F")]
	observed_dispatch = [(row["dispatch_ptr"], row["dispatch_byte"]) for row in dispatch_rows[:len(expected_dispatch)]]
	if observed_dispatch != expected_dispatch:
		raise SystemExit(f"A4EB `$B0C0` ROM command stream mismatch: {observed_dispatch}; output={output}")
	first_dispatch = dispatch_rows[0] if dispatch_rows else None
	required_caller_pcs = {"$82E2", "$82EC", "$80F1", "$80F3", "$80F5", "$80F7",
		"$A20F", "$A86E", "$A138", "$A14A", "$A1E4", "$A8BB", "$A8CD", "$A8A3", "$A8B6", "$80FD",
		"$8114", "$893B", "$8117", "$811C", "$A006"}
	missing_caller_pcs = sorted(required_caller_pcs - caller_pcs)
	if missing_caller_pcs:
		raise SystemExit(f"Caller trace missed required ROM PCs {missing_caller_pcs}; output={output}")
	zero_writer = next((row for row in word_wait_rows if row["source_frame"] == "7266"
		and row["pc"] == "$A1C5" and row["new_value"] == "$00"), None)
	loop_exit = next((row for row in caller_rows if row["source_frame"] == "7266"
		and row["pc"] == "$893B" and row["ram_0078"] == "$00"), None)
	zero_cycle = int(zero_writer["cycle"]) if zero_writer else -1
	post_wait = next((row for row in caller_rows if row["pc"] == "$8117"
		and row["source_frame"] == "7266" and row["sp"] == "$28" and row["ram_0078"] == "$00"
		and int(row["cycle"]) >= zero_cycle), None)
	a006_call = next((row for row in caller_rows if row["pc"] == "$A006"
		and row["source_frame"] == "7266" and int(row["cycle"]) >= zero_cycle), None)
	target_nmi = next((row for row in caller_rows if row["pc"] == "$C421" and row["source_frame"] == "7266"), None)
	target_sound_call = next((row for row in caller_rows if row["pc"] == "$C449" and row["source_frame"] == "7266"), None)
	if not zero_writer or not loop_exit or not post_wait or not a006_call or not target_nmi or not target_sound_call:
		raise SystemExit(f"FCEUX did not capture the `$A1C5` `$78=0` write and `$893B->$8117->$A006` return chain; output={output}")
	nmi_snapshot_hashes: dict[str, str] = {}
	target_ram_bytes: dict[str, dict[str, int]] = {}
	for label in ("C421", "C449"):
		for component, expected_size in (("ram", 0x800), ("ppu", 0x4000)):
			pass_paths = [output / f"frame_7266_{label}_{component}_pass{number}.bin" for number in (1, 2)]
			if not all(path.is_file() and path.stat().st_size == expected_size for path in pass_paths):
				raise SystemExit(f"FCEUX did not capture matching frame-7266 {label} {component} snapshots; output={output}")
			payloads = [path.read_bytes() for path in pass_paths]
			hashes = [hashlib.sha256(payload).hexdigest() for payload in payloads]
			if hashes[0] != hashes[1]:
				raise SystemExit(f"Frame-7266 {label} {component} snapshots differ between checkpoint replays; output={output}")
			nmi_snapshot_hashes[f"{label}_{component}"] = hashes[0]
			if component == "ram":
				target_ram_bytes[label] = {
					"003b": payloads[0][0x003B], "003c": payloads[0][0x003C],
					"003d": payloads[0][0x003D], "003e": payloads[0][0x003E],
					"0078": payloads[0][0x0078], "0079": payloads[0][0x0079],
					"0628": payloads[0][0x0628], "0629": payloads[0][0x0629],
					"0700": payloads[0][0x0700], "0701": payloads[0][0x0701],
					"0702": payloads[0][0x0702], "0703": payloads[0][0x0703],
					"0704": payloads[0][0x0704], "0705": payloads[0][0x0705],
					"07fc": payloads[0][0x07FC],
				}
	if not (int(zero_writer["cycle"]) <= int(loop_exit["cycle"]) <= int(post_wait["cycle"]) <= int(a006_call["cycle"])):
		raise SystemExit(f"The `$78` wait exit does not precede the caller's `$A006` call; output={output}")
	selector_copy_length, selector_copy_hash = check_selector_copy_snapshots(output)
	snapshot_hash = normalized_hash(output / "frame_snapshots.csv")
	if snapshot_hash != normalized_hash(output / "frame_snapshots_repeat.csv"):
		raise SystemExit(f"Frame-end snapshot passes differ; output={output}")
	validation = {
		"rom_sha256": digest(ROM), "checkpoint_source_frame": 4692,
		"checkpoint_sound_queue_bytes": metadata_values.get("checkpoint_sound_queue_bytes", ""),
		"checkpoint_saved_bank_07fc": metadata_values.get("checkpoint_saved_bank_07fc", ""),
		"trace_frames": [4693, 9042], "replays": 2,
		"counter_writer_sha256": event_hash, "frame_snapshot_sha256": snapshot_hash,
		"caller_hook_sha256": caller_hook_hash, "caller_hook_events": len(caller_rows),
		"caller_hook_required_pcs": sorted(required_caller_pcs),
		"sound_queue_write_sha256": sound_queue_hash, "sound_queue_write_events": len(sound_queue_rows),
		"stream_buffer_write_sha256": stream_buffer_hash, "stream_buffer_write_events": len(stream_buffer_rows),
		"stream_buffer_startup_write_events": len(stream_buffer_startup_rows),
		"a4eb_dispatch_hooks": [{key: row[key] for key in ("source_frame", "cycle", "pc", "bank", "a", "x", "y", "p", "sp", "ram_00ec", "ram_00ed", "dispatch_ptr", "dispatch_byte", "mapper_select", "mapper_r6", "mapper_r7")} for row in stream_hooks],
		"a4eb_dispatch_rows_match_rom_b305_b327": observed_dispatch == expected_dispatch,
		"first_b0c6_dispatch_state": ({key: first_dispatch[key] for key in ("source_frame", "cycle", "pc", "bank", "a", "x", "y", "p", "sp", "ram_00ec", "ram_00ed", "dispatch_ptr", "dispatch_byte", "mapper_select", "mapper_r6", "mapper_r7")} if first_dispatch else None),
		"sound_queue_cold_start_events_through_frame_4692": len(startup_queue_rows),
		"first_saved_bank_0f_write": {key: first_saved_bank_0f[key] for key in ("source_frame", "cycle", "pc", "bank", "address", "old_value", "new_value", "ram_0700", "ram_0701", "ram_0702", "ram_0703", "ram_0704", "ram_0705", "ram_07fc", "mapper_select", "mapper_r6", "mapper_r7")},
		"target_nmi_state": {key: target_nmi[key] for key in ("source_frame", "cycle", "sp", "ram_0700", "ram_0701", "ram_0702", "ram_0703", "ram_0704", "ram_0705", "ram_07fc", "mapper_select", "mapper_r6", "mapper_r7")},
		"target_sound_call_state": {key: target_sound_call[key] for key in ("source_frame", "cycle", "sp", "ram_0700", "ram_0701", "ram_0702", "ram_0703", "ram_0704", "ram_0705", "ram_07fc", "mapper_select", "mapper_r6", "mapper_r7")},
		"target_nmi_ram_bytes": target_ram_bytes,
		"target_nmi_snapshot_sha256": nmi_snapshot_hashes,
		"word_wait_write_sha256": word_wait_hash, "word_wait_write_events": len(word_wait_rows),
		"mapper_shadow_0022": {
			"startup_write_events": len(startup_mapper_rows),
			"post_checkpoint_write_events": len(mapper_route_rows),
			"post_checkpoint_pass_sha256": mapper_hashes[0],
			"post_checkpoint_passes_match": True,
			"last_post_checkpoint_write": mapper_last_route_write,
			"trace_is_observation_only": True,
		},
		"wait_clear": {"pc": "$A1C5", "value": "$00", "source_frame": int(zero_writer["source_frame"]), "cycle": int(zero_writer["cycle"])},
		"wait_loop_exit": {"pc": "$893B", "ram_0078": "$00", "source_frame": int(loop_exit["source_frame"]), "cycle": int(loop_exit["cycle"])},
		"caller_resumed_at_8117": {"source_frame": int(post_wait["source_frame"]), "cycle": int(post_wait["cycle"])},
		"a006_entered": {"source_frame": int(a006_call["source_frame"]), "cycle": int(a006_call["cycle"])},
		"selector_ram_copy_length": selector_copy_length,
		"selector_ram_copy_sha256": selector_copy_hash,
		"signature_checked_after_both_checkpoint_loads": True,
		"frame_7258_full_ppu_sha256": clear_ppu_hash,
		"frame_7258_full_ram_sha256": clear_ram_hash,
		"fceux_exit_code": process.returncode,
		"elapsed_seconds": round(time.monotonic() - started, 3),
		"audio_muted": True, "diagnostics_only": True,
	}
	(output / "validation.json").write_text(json.dumps(validation, indent=2) + "\n", encoding="utf-8")
	print(f"PASS: identical muted FCEUX counter, caller-hook, sound-queue, NMI RAM/PPU, `$0078`, and `$0022`-writer replays; `$893B->$8117->$A006` confirmed; {validation['elapsed_seconds']:.2f}s; output={output}")


if __name__ == "__main__":
	main()
