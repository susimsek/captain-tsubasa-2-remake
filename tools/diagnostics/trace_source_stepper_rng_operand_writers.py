#!/usr/bin/env python3
"""Trace RNG operand RAM stores by executing the supplied ROM from reset.

This is diagnostic-only. It uses the recorded controller route as input, never
uses captured RAM to seed/steer the machine, and does not invoke FCEUX.
"""

from __future__ import annotations

import csv
import hashlib
import importlib.util
import json
import resource
import tempfile
import sys
import time
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
BUILDER_PATH = ROOT / "tools/gameplay/build_kickoff_rng_source_schedule.py"
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
SCHEDULE_PATH = ROOT / "assets/gameplay/rom_logic/kickoff_rng_source_schedule.json"
FCEUX_CALLS_PATH = ROOT / "reference/diagnostics/first_command_rng_operand_trace_20261027_172720_utc/c9c5_calls_window.csv"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
EXPECTED_ROUTE_SHA256 = "6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc"
LAST_FRAME = 9042
RUN_STARTED = time.monotonic()


def sha256(data: bytes) -> str:
	return hashlib.sha256(data).hexdigest()


def load_module(name: str, path: Path):
	spec = importlib.util.spec_from_file_location(name, path)
	if spec is None or spec.loader is None:
		raise RuntimeError(f"Could not load {path}")
	module = importlib.util.module_from_spec(spec)
	spec.loader.exec_module(module)
	return module


def physical_ram(address: int) -> int:
	return address & 0x7FF


class _DiscardAppend:
	"""Drop optional trace-only event rows; the stepper never reads these lists."""
	def append(self, _row: dict) -> None:
		return


def target_label(address: int, physical: int) -> str | None:
	if physical == 0x001B:
		return "mode_001b"
	if physical in (0x00E1, 0x00E2, 0x00E3):
		return f"rng_{physical:04x}"
	if physical == 0x0441:
		return "selected_actor_0441"
	if physical == 0x05FB:
		return "match_base_05fb"
	if physical == 0x05FC:
		return "receiver_slot_05fc"
	if 0x0300 <= physical <= 0x037E or 0x03FA <= physical <= 0x03FF:
		return "operand_0300"
	if 0x0700 <= physical <= 0x077E or 0x07FA <= physical <= 0x07FF:
		return "operand_0700"
	if 0x0780 <= physical <= 0x07FE:
		return "operand_0780"
	if 0x007A <= physical <= 0x007F:
		return "operand_0780_mirror"
	return None


def main() -> None:
	builder = load_module("ct2_rng_schedule_builder", BUILDER_PATH)
	stepper = builder._load_stepper()
	rom = ROM_PATH.read_bytes()
	rom_sha = sha256(rom)
	if rom_sha != EXPECTED_ROM_SHA256:
		raise SystemExit(f"Wrong ROM revision: {rom_sha}")
	input_rows, input_bytes = builder._read_route_inputs()
	route_sha = sha256(input_bytes)
	if route_sha != EXPECTED_ROUTE_SHA256:
		raise SystemExit(f"Route input changed: {route_sha}")
	with tempfile.NamedTemporaryFile("w", newline="", encoding="utf-8") as stream:
		stream.write(input_bytes.decode("utf-8"))
		stream.flush()
		input_timeline = stepper.load_input_timeline(Path(stream.name))

	# The RNG helper index addresses these operand cells on its observed route:
	# $FA-$FF, then $00-$7E. Include those arrays plus mode/selection context.
	eligible_x = tuple(range(0x00, 0x7F)) + tuple(range(0xFA, 0x100))
	read_addresses = {
		0x0300 + x for x in eligible_x
	} | {
		0x0700 + x for x in eligible_x
	} | {
		0x0780 + x for x in eligible_x
	}
	read_physical = {physical_ram(address) for address in read_addresses}
	context_physical = {0x001B, 0x00E1, 0x00E2, 0x00E3, 0x0441, 0x05FB, 0x05FC}
	watched_physical = read_physical | context_physical

	class WriterTraceMachine(stepper.Machine):
		def __init__(self, *args, **kwargs):
			self.writer_rows: list[dict] = []
			self.read_rows: list[dict] = []
			self.c9_calls: list[dict] = []
			self.current_rng_call: dict | None = None
			self.receiver_selection: dict | None = None
			super().__init__(*args, **kwargs)
			# These collections are append-only reporting sinks in the source stepper.
			# Their append sites do not feed CPU, PPU, MMC3, DMC, or controller state.
			# Replace them only in this diagnostic subclass to avoid retaining large,
			# unrelated APU/DMC/interrupt traces during the cold route execution.
			discard = _DiscardAppend()
			self.events = discard
			self.dmc_events = discard
			self.mmc3_irq_events = discard
			self.cpu_interrupt_events = discard

		def __getitem__(self, addr: int) -> int:
			requested = addr & 0xFFFF
			value = super().__getitem__(addr)
			pc = getattr(self, "current_instruction_pc", -1)
			if pc == 0xC9C5 and requested == 0xC9C5:
				self.current_rng_call = {
					"source_frame": self.source_frame,
					"source_cycle": self.cpu_cycles,
					"pc": pc,
					"pc_prg_bank_8k": self._prg_bank(pc),
					"p_incoming": self.cpu.p,
					"carry_in": self.cpu.p & 1,
					"mode_001b": self.ram[0x001B],
					"e1_before": self.ram[0x00E1],
					"e2_before": self.ram[0x00E2],
					"e3_before": self.ram[0x00E3],
					"reads": {},
				}
			for instruction_pc, base, name in (
				(0xC9C8, 0x0300, "$0300,X"),
				(0xC9CB, 0x0700, "$0700,X"),
				(0xC9DC, 0x0780, "$0780,X"),
			):
				if pc == instruction_pc and requested < 0x2000 and physical_ram(requested) in read_physical:
					call = self.current_rng_call
					if call is not None:
						call["reads"][name] = {
							"requested_cpu_address": requested,
							"physical_ram_address": physical_ram(requested),
							"value": value,
							"x": self.cpu.x,
					}
						self.read_rows.append({
							"source_frame": self.source_frame,
							"source_cycle": self.cpu_cycles,
							"instruction_pc": pc,
							"pc_prg_bank_8k": self._prg_bank(pc),
							"operand": name,
							"x": self.cpu.x,
							"requested_cpu_address": requested,
							"physical_ram_address": physical_ram(requested),
							"value": value,
						})
			return value

		def __setitem__(self, addr: int, value: int) -> None:
			requested = addr & 0xFFFF
			physical = physical_ram(requested)
			value &= 0xFF
			pc = getattr(self, "current_instruction_pc", -1)
			if requested < 0x2000 and physical in watched_physical:
				old = self.ram[physical]
				label = target_label(requested, physical)
				if label is None:
					label = target_label(physical, physical) or "alias"
				self.writer_rows.append({
					"source_frame": self.source_frame,
					"source_cycle": self.cpu_cycles,
					"instruction_pc": pc,
					"pc_after_instruction": (pc + self.current_instruction_len) & 0xFFFF,
					"pc_prg_bank_8k": self._prg_bank(pc) if pc >= 0x8000 else -1,
					"cpu_address": requested,
					"physical_ram_address": physical,
					"old_value": old,
					"new_value": value,
					"region": label,
					"mode_001b_before": self.ram[0x001B],
					"e1_before": self.ram[0x00E1],
					"e2_before": self.ram[0x00E2],
					"e3_before": self.ram[0x00E3],
				})
			super().__setitem__(addr, value)
			if (self.current_rng_call is not None and pc == 0xC9E5 and physical == 0x00E1):
				call = self.current_rng_call
				call["e1_after"] = self.ram[0x00E1]
				call["e2_after"] = self.ram[0x00E2]
				call["e3_after"] = self.ram[0x00E3]
				call["state_after"] = [self.source_frame, self.cpu_cycles,
					self.ram[0x00E1], self.ram[0x00E2], self.ram[0x00E3]]
				self.c9_calls.append(call)
				self.current_rng_call = None
			if requested < 0x2000 and physical == 0x05FC and pc == 0xDB08 and self._prg_bank(pc) == 30:
				self.receiver_selection = {
					"source_frame": self.source_frame,
					"source_cycle": self.cpu_cycles,
					"e1": self.ram[0x00E1], "e2": self.ram[0x00E2], "e3": self.ram[0x00E3],
					"slot": self.ram[0x05FC],
				}

	machine = WriterTraceMachine(rom, input_timeline)
	for source_frame in range(1, LAST_FRAME + 1):
		machine.run_frame(source_frame)
		if source_frame % 600 == 0:
			print(f"ROM-only RNG writer trace: frame {source_frame}", flush=True)
		if machine.receiver_selection is not None:
			break
	if machine.receiver_selection is None:
		raise SystemExit("ROM-only source stepper did not reach the receiver store by frame 8593.")
	if len(machine.c9_calls) != 133:
		raise SystemExit(f"Expected 133 C9C5 calls; observed {len(machine.c9_calls)}.")
	if (machine.receiver_selection["source_frame"], machine.receiver_selection["e2"], machine.receiver_selection["slot"]) != (8593, 0xBE, 0x06):
		raise SystemExit(f"Unexpected receiver result: {machine.receiver_selection}")

	schedule = json.loads(SCHEDULE_PATH.read_text(encoding="utf-8"))
	expected_calls = schedule["updates"]["c9c5"]["state_after_each_call"]
	actual_calls = [row["state_after"] for row in machine.c9_calls]
	if actual_calls != expected_calls:
		raise SystemExit("Intercepted C9C5 call state differs from the checked-in source schedule.")
	fceux_match = None
	if FCEUX_CALLS_PATH.is_file():
		with FCEUX_CALLS_PATH.open(newline="", encoding="utf-8") as stream:
			fceux = list(csv.DictReader(stream))
		matching = 0
		for call, reference in zip(machine.c9_calls, fceux, strict=True):
			if (call["source_frame"], call["e1_after"], call["e2_after"], call["e3_after"]) == (
				int(reference["source_frame"]), int(reference["e1_after"].replace("$", ""), 16),
				int(reference["e2_after"].replace("$", ""), 16), int(reference["e3_after"].replace("$", ""), 16),
			):
				matching += 1
		fceux_match = {"path": FCEUX_CALLS_PATH.relative_to(ROOT).as_posix(), "matched_calls": matching, "total_calls": len(fceux)}

	run_id = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_utc")
	out_dir = ROOT / "reference/diagnostics" / f"source_stepper_rng_operand_writers_{run_id}"
	out_dir.mkdir(parents=True, exist_ok=False)
	writer_fields = (
		"source_frame", "source_cycle", "instruction_pc", "pc_after_instruction", "pc_prg_bank_8k",
		"cpu_address", "physical_ram_address", "old_value", "new_value", "region",
		"mode_001b_before", "e1_before", "e2_before", "e3_before",
	)
	with (out_dir / "ram_writer_events.csv").open("w", newline="", encoding="utf-8") as stream:
		writer = csv.DictWriter(stream, fieldnames=writer_fields)
		writer.writeheader()
		writer.writerows(machine.writer_rows)
	read_fields = ("source_frame", "source_cycle", "instruction_pc", "pc_prg_bank_8k", "operand", "x", "requested_cpu_address", "physical_ram_address", "value")
	with (out_dir / "c9c5_operand_reads.csv").open("w", newline="", encoding="utf-8") as stream:
		writer = csv.DictWriter(stream, fieldnames=read_fields)
		writer.writeheader()
		writer.writerows(machine.read_rows)
	call_fields = (
		"source_frame", "source_cycle", "pc", "pc_prg_bank_8k", "p_incoming", "carry_in", "mode_001b",
		"e1_before", "e2_before", "e3_before", "e1_after", "e2_after", "e3_after", "state_after", "reads",
	)
	with (out_dir / "c9c5_calls.csv").open("w", newline="", encoding="utf-8") as stream:
		writer = csv.DictWriter(stream, fieldnames=call_fields)
		writer.writeheader()
		for row in machine.c9_calls:
			writer.writerow({**row, "pc": f"${row['pc']:04X}", "pc_prg_bank_8k": row["pc_prg_bank_8k"],
				"p_incoming": f"${row['p_incoming']:02X}", "mode_001b": f"${row['mode_001b']:02X}",
				"e1_before": f"${row['e1_before']:02X}", "e2_before": f"${row['e2_before']:02X}", "e3_before": f"${row['e3_before']:02X}",
				"e1_after": f"${row['e1_after']:02X}", "e2_after": f"${row['e2_after']:02X}", "e3_after": f"${row['e3_after']:02X}",
				"state_after": json.dumps(row["state_after"]), "reads": json.dumps(row["reads"], sort_keys=True)})

	region_counts = Counter(row["region"] for row in machine.writer_rows)
	writer_pc_counts = Counter((row["region"], row["instruction_pc"], row["pc_prg_bank_8k"]) for row in machine.writer_rows)
	metadata = {
		"purpose": "Trace pre-frame-8400 RNG operand and context RAM stores by ROM-only 6502 execution from reset.",
		"rom_sha256": rom_sha,
		"input_route_sha256": route_sha,
		"stepper_sha256": sha256(stepper.__file__ and Path(stepper.__file__).read_bytes()),
		"source_frames_executed": [1, machine.source_frame],
		"target_ram_dumps_used_as_inputs": False,
		"rom_only_execution": True,
		"c9c5_call_count": len(machine.c9_calls),
		"c9c5_source_frame_runs": [machine.c9_calls[0]["source_frame"], machine.c9_calls[-1]["source_frame"]],
		"receiver_selection": machine.receiver_selection,
		"writer_event_count": len(machine.writer_rows),
		"writer_event_counts_by_region": dict(region_counts),
		"unique_writer_pc_bank_pairs_by_region": {
			region: sorted({(pc, bank) for (label, pc, bank), _ in writer_pc_counts.items() if label == region})
			for region in sorted(region_counts)
		},
		"c9c5_reads": len(machine.read_rows),
		"c9c5_states_match_source_schedule": True,
		"fceux_call_state_crosscheck": fceux_match,
		"discarded_append_only_diagnostics": ["events", "dmc_events", "mmc3_irq_events", "cpu_interrupt_events"],
		"discard_sink_semantics": "These fields are append-only reports in Machine; source scan found no reads from them. Replacing append retains no state and does not alter CPU/PPU/DMC/controller decisions.",
		"runtime_seconds": round(time.monotonic() - RUN_STARTED, 3),
		"peak_rss": resource.getrusage(resource.RUSAGE_SELF).ru_maxrss,
		"peak_rss_units": "bytes" if sys.platform == "darwin" else "KiB",
		"limitations": [
			"Writer PCs and values are from the ROM-only stepper model, not a physical NES or live FCEUX execution.",
			"The route is the exact recorded input timeline; behavior for other input histories is not generalized.",
			"Source cycle labels follow this stepper's instruction/PPU/DMC scheduling and are not hardware oscillator measurements.",
		],
	}
	(out_dir / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
	print(f"Wrote {out_dir.relative_to(ROOT)}")
	print(f"ROM input SHA-256 {rom_sha}; route SHA-256 {route_sha}")
	print(f"RAM writer events {len(machine.writer_rows)}; C9C5 calls {len(machine.c9_calls)}; reads {len(machine.read_rows)}")
	print(f"Receiver frame {machine.receiver_selection['source_frame']} cycle {machine.receiver_selection['source_cycle']} E2=${machine.receiver_selection['e2']:02X} slot=${machine.receiver_selection['slot']:02X}")
	print(f"FCEUX C9C5 state cross-check {fceux_match}")
	print(f"Runtime {metadata['runtime_seconds']} s; peak RSS {metadata['peak_rss']} {metadata['peak_rss_units']}")


if __name__ == "__main__":
	main()
