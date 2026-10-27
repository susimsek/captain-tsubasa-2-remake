#!/usr/bin/env python3
"""Export the source-only A160 $2006 writes as a compact Godot runtime resource.

The event rows are produced by executing the supplied ROM in the project's
diagnostic 6502/MMC3/PPU stepper. FCEUX traces are not opened by this exporter;
the same-input controller file is provenance for the deterministic ROM run,
not event timing or PPU-state input.
"""

from __future__ import annotations

import hashlib
import importlib.util
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "reference/rom_extract/intro/rom_source_a160_ppu_write_timeline.json"
SOURCE_PREDICTOR = ROOT / "tools/diagnostics/predict_a160_ppu_dots_irq_return_poc_20261026.py"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
EXPECTED_INPUT_SHA256 = "195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3"
LAST_SOURCE_FRAME = 3649


def sha256(data: bytes) -> str:
	return hashlib.sha256(data).hexdigest()


def load_predictor():
	spec = importlib.util.spec_from_file_location("ct2_a160_irq_return_export", SOURCE_PREDICTOR)
	if spec is None or spec.loader is None:
		raise RuntimeError(f"Cannot load ROM-only predictor: {SOURCE_PREDICTOR}")
	module = importlib.util.module_from_spec(spec)
	sys.modules[spec.name] = module
	spec.loader.exec_module(module)
	return module


def main() -> None:
	model = load_predictor()
	rom = model.base.ROM_PATH.read_bytes()
	if sha256(rom) != EXPECTED_ROM_SHA256:
		raise SystemExit("Supplied ROM SHA-256 does not match the verified source revision.")
	input_path = model.base.INPUT_PATH
	input_bytes = input_path.read_bytes()
	if sha256(input_bytes) != EXPECTED_INPUT_SHA256:
		raise SystemExit("Controller timeline SHA-256 changed; inspect before regenerating.")
	inputs = model.base.stepper.load_input_timeline(input_path)
	machine = model.IRQReturnMachine(rom, inputs)
	machine.run(LAST_SOURCE_FRAME)

	frames: dict[int, dict[str, dict]] = {}
	for row in machine.store_rows:
		pc = str(row["instruction_pc"])
		if pc not in ("$A175", "$A178"):
			continue
		frame = int(row["source_frame"])
		frames.setdefault(frame, {})[pc] = {
			"cpu_cycle": int(row["cpu_cycle"]),
			"scanline": int(row["predicted_scanline"]),
			"dot": int(row["predicted_dot"]),
			"value": int(row["value"]),
		}

	packed_frames = []
	for frame in sorted(frames):
		writes = frames[frame]
		if set(writes) != {"$A175", "$A178"}:
			raise SystemExit(f"Frame {frame} has an incomplete $2006 pair: {writes}")
		if int(writes["$A175"]["cpu_cycle"]) >= int(writes["$A178"]["cpu_cycle"]):
			raise SystemExit(f"Frame {frame} has reversed $2006 store order.")
		packed_frames.append({"source_frame": frame, "writes": [writes["$A175"], writes["$A178"]]})

	result = {
		"schema": 1,
		"rom_sha256": EXPECTED_ROM_SHA256,
		"source_model": "ROM-only 6502/MMC3/PPU stepper with pinned NewPPU call subdivision and IRQ-return semantics",
		"source_predictor": SOURCE_PREDICTOR.relative_to(ROOT).as_posix(),
		"source_stepper": model.base.STEPPER_PATH.relative_to(ROOT).as_posix(),
		"controller_timeline_sha256": EXPECTED_INPUT_SHA256,
		"controller_timeline_role": "captured input route drives ROM execution only; it is not PPU timing or memory-state input",
		"input_route_scope": "deterministic captured intro route, not a general arbitrary-input CPU emulator",
		"fceux_ppu_trace_or_visual_capture_used_for_generation": False,
		"fceux_validation_scope": "196 direct-trace stores across 98 frames; other exported events remain source-model output pending independent validation",
		"source_frame_range": [min(frames), max(frames)],
		"frame_count": len(packed_frames),
		"write_count": sum(len(item["writes"]) for item in packed_frames),
		"events": packed_frames,
	}
	OUTPUT.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
	print(json.dumps({key: value for key, value in result.items() if key != "events"}, indent=2))
	print(f"output={OUTPUT.relative_to(ROOT)} bytes={OUTPUT.stat().st_size}")


if __name__ == "__main__":
	main()
