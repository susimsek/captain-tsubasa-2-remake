#!/usr/bin/env python3
"""Render a ROM/NSF-only APU-to-WaveHi candidate with a cycle-clocked DMC model.

Synthesis inputs are the instrumented ROM-derived NSF APU writes, NSF PLAY
calls used only as output-block boundaries, the supplied ROM's physical PRG
bank $1E, and the pinned FCEUX WaveHi/mixer/filter port. The NSF's DMC refill
callbacks are compared after rendering by address/value order only; callback
timestamps are never loaded by the renderer. Captured FCEUX writes, DMC timing,
frame-cycle rows, and PCM are not synthesis inputs.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import subprocess
import tempfile
from pathlib import Path

from prototype_fceux_filter_pipeline import FCEUX_REVISION, ROOT, SOURCE_SHA256, fetch_coeffs

ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
TRACE_DIR = ROOT / "reference/diagnostics/audio/nsf_presenter_source_event_trace_20261025"
OUTPUT_DIR = ROOT / "reference/diagnostics/audio/source_nsf_wavehi_rom_dmc_20261026"
RENDERER = ROOT / "tools/audio/fceux_apu_wavehi_prototype/apu_wavehi_renderer.cpp"
DPCM_EXTRACT = ROOT / "reference/rom_extract/audio/dpcm_sample_blob.bin"


def sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def source_blocks(play_calls: Path, horizon: int, output: Path) -> list[dict]:
	calls: list[int] = []
	with play_calls.open(newline="", encoding="ascii") as stream:
		for row in csv.DictReader(stream):
			cycle = int(row["absolute_cpu_cycle"])
			if 0 < cycle <= horizon:
				calls.append(cycle)
	if any(a >= b for a, b in zip(calls, calls[1:])):
		raise ValueError("NSF PLAY-call clock is not strictly increasing")
	rows: list[dict] = []
	start = 0
	for index, end in enumerate(calls):
		if end <= start:
			continue
		rows.append({"source_block": len(rows), "nsf_play_index": index, "cycle_start": start,
			"cycle_end": end, "cycle_delta": end - start})
		start = end
	if start < horizon:
		rows.append({"source_block": len(rows), "nsf_play_index": "tail", "cycle_start": start,
			"cycle_end": horizon, "cycle_delta": horizon - start})
	with output.open("w", newline="", encoding="ascii") as stream:
		writer = csv.writer(stream, lineterminator="\n")
		writer.writerow(["source_frame", "emulator_frame_after", "cycle_start", "cycle_end", "cycle_delta"])
		for row in rows:
			writer.writerow([row["source_block"], row["nsf_play_index"], row["cycle_start"], row["cycle_end"], row["cycle_delta"]])
	return rows


def compare_dmc_fetch_order(model_path: Path, callback_path: Path) -> dict:
	model_rows = list(csv.DictReader(model_path.open(newline="", encoding="ascii")))
	callback_rows = list(csv.DictReader(callback_path.open(newline="", encoding="ascii")))
	# Accept both renderer `$0D` and libgme `0x0d`/`$D` spellings.
	def byte_pair(row: dict) -> tuple[int, int]:
		return tuple(int(row[key].replace("$", "").replace("0x", ""), 16) for key in ("cpu_address", "value"))
	model = [byte_pair(r) for r in model_rows]
	callbacks = [byte_pair(r) for r in callback_rows]
	common = min(len(model), len(callbacks))
	first_mismatch = next((i for i in range(common) if model[i] != callbacks[i]), None)
	return {
		"role": "post-render ROM/NSF byte-order validation only; callback cycle columns are ignored",
		"model_fetch_count": len(model),
		"nsf_callback_count": len(callbacks),
		"common_prefix_count": first_mismatch if first_mismatch is not None else common,
		"first_order_or_byte_mismatch": ({
			"sequence": first_mismatch,
			"model": {"cpu_address": f"${model[first_mismatch][0]:04X}", "value": f"${model[first_mismatch][1]:02X}"},
			"nsf_callback": {"cpu_address": f"${callbacks[first_mismatch][0]:04X}", "value": f"${callbacks[first_mismatch][1]:02X}"},
		} if first_mismatch is not None else None),
		"sequence_exact": model == callbacks,
	}


def render(trace_dir: Path, output_dir: Path) -> dict:
	trace_dir = trace_dir.resolve()
	output_dir = output_dir.resolve()
	output_dir.mkdir(parents=True, exist_ok=True)
	rom_bytes = ROM_PATH.read_bytes()
	if hashlib.sha256(rom_bytes).hexdigest() != ROM_SHA256:
		raise ValueError("supplied ROM SHA-256 does not match the pinned ROM")
	trace_meta = json.loads((trace_dir / "trace_meta.json").read_text(encoding="utf-8"))
	if trace_meta.get("source_rom_sha256") != ROM_SHA256:
		raise ValueError("NSF trace sidecar does not identify the supplied ROM")
	if trace_meta.get("input_mode") != "explicit_candidate_nsf_no_builder_or_capture_event_read":
		raise ValueError("source-only renderer requires an explicitly supplied NSF trace, not capture-built default input")
	for name, key in (("apu_writes.csv", "apu_writes_sha256"), ("play_calls.csv", "play_calls_sha256"),
			("dmc_fetches.csv", "dmc_fetches_sha256")):
		if sha256(trace_dir / name) != trace_meta["outputs"][key]:
			raise ValueError(f"NSF trace output hash mismatch: {name}")
	bank_start = 16 + (512 if rom_bytes[6] & 0x04 else 0) + 0x1E * 0x2000
	bank_1e = rom_bytes[bank_start:bank_start + 0x2000]
	if not bank_1e.startswith(DPCM_EXTRACT.read_bytes()):
		raise ValueError("physical PRG bank $1E differs from preserved ROM DPCM extract")

	adapter = trace_dir / "wavehi_apu_writes_source_only.csv"
	if sha256(adapter) != trace_meta["outputs"]["wavehi_apu_adapter"]["sha256"]:
		raise ValueError("source-only WaveHi APU adapter hash mismatch")
	horizon = int(trace_meta["nsf_replay"]["cpu_cycles_advanced"])
	blocks_path = output_dir / "nsf_play_blocks.csv"
	blocks = source_blocks(trace_dir / "play_calls.csv", horizon, blocks_path)
	# The C++ renderer skips the trace argument in source-DMC mode. Keep a
	# deliberately empty placeholder so no captured event file can be loaded.
	ignored_trace = output_dir / "unused_dmc_trace.csv"
	ignored_trace.write_text("source-only mode: DMC trace not loaded\n", encoding="ascii")
	candidate = output_dir / "source_nsf_wavehi.wav"
	model_fetches = output_dir / "source_dmc_rom_fetches.csv"

	with tempfile.TemporaryDirectory(prefix="ct2_nsf_wavehi_rom_dmc_") as temporary:
		work = Path(temporary)
		filter_hashes = fetch_coeffs(work)
		binary = work / "apu_wavehi_renderer"
		subprocess.run([
			"clang++", "-std=c++17", "-O3", "-DNDEBUG", "-Wall", "-Wextra", "-Wno-unused-function",
			"-I", str(work), str(RENDERER), "-o", str(binary),
		], check=True)
		completed = subprocess.run([
			str(binary), str(adapter), str(blocks_path), str(ignored_trace), str(ROM_PATH), str(candidate),
			"--source-frame-sequencer", "--source-dmc-engine", "--source-dmc-fetches", str(model_fetches),
		], check=False, capture_output=True, text=True)
		if completed.returncode:
			raise RuntimeError(f"source-only WaveHi renderer failed: {completed.stderr.strip()}")

	# This comparison is deliberately after rendering. It reads the NSF callback
	# address/value order, but never its timestamps, to check ROM-byte traversal.
	dmc_order = compare_dmc_fetch_order(model_fetches, trace_dir / "dmc_fetches.csv")
	with candidate.open("rb") as stream:
		candidate_hash = hashlib.sha256(stream.read()).hexdigest()
	manifest = {
		"purpose": "ROM/NSF-only diagnostic WaveHi render; not a runtime asset.",
		"source_inputs": {
			"rom_sha256": ROM_SHA256,
			"nsf_trace_dir": trace_dir.relative_to(ROOT).as_posix(),
			"source_nsf_sha256": trace_meta["source_nsf_sha256"],
			"apu_write_trace": {"path": (trace_dir / "apu_writes.csv").relative_to(ROOT).as_posix(),
				"sha256": trace_meta["outputs"]["apu_writes_sha256"], "rows": trace_meta["outputs"]["apu_write_count"],
				"timestamp_semantics": "ROM-derived NSF CPU-bus write cycle"},
			"apu_adapter": {"path": adapter.relative_to(ROOT).as_posix(), "sha256": sha256(adapter)},
			"nsf_play_call_blocks": {"path": blocks_path.relative_to(ROOT).as_posix(), "sha256": sha256(blocks_path),
				"rows": len(blocks), "use": "source NSF PLAY-call output boundaries; not FCEUX frame-cycle rows",
				"cpu_cycle_horizon": horizon},
			"dpcm_rom": {"path": DPCM_EXTRACT.relative_to(ROOT).as_posix(), "sha256": sha256(DPCM_EXTRACT),
				"bank": "$1E", "bank_bytes_verified": len(DPCM_EXTRACT.read_bytes())},
			"nsf_dmc_callbacks": {"path": (trace_dir / "dmc_fetches.csv").relative_to(ROOT).as_posix(),
				"sha256": trace_meta["outputs"]["dmc_fetches_sha256"], "rows": trace_meta["outputs"]["dmc_fetch_count"],
				"use": "post-render address/value-order validation only; callback cycle timestamps are not synthesized"},
		},
		"renderer": {
			"source": RENDERER.relative_to(ROOT).as_posix(),
			"source_sha256": sha256(RENDERER),
			"fceux_revision": FCEUX_REVISION,
			"pinned_filter_source_sha256": SOURCE_SHA256,
			"mixer": "pinned FCEUX nonlinear pulse/TND lookup and soundq=2 FIR/NeoFilterSound/SexyFilter port",
			"frame_clock": "source NSF $4017 writes and pinned FCEUX NTSC fixed-point frame-sequencer countdown; per-CPU-cycle check",
			"dmc_model": "source $4010-$4015 writes, physical ROM bank $1E bytes, 54-cycle DMC bit period table, sample buffer, shift register, output DAC, loop/length state",
			"captured_pcm_used_as_input": False,
			"captured_fceux_apu_writes_used_as_input": False,
			"captured_fceux_dmc_timestamps_used_as_input": False,
			"captured_fceux_frame_cycles_used_as_input": False,
			"nsf_dmc_callback_timestamps_used_as_input": False,
			"nsf_callback_address_value_validation": dmc_order,
		},
		"render": {"path": candidate.relative_to(ROOT).as_posix(), "sha256": candidate_hash,
			"samples": (candidate.stat().st_size - 44) // 2, "stdout": completed.stdout.strip(), "runtime_asset": False},
		"limits": [
			"The NSF PLAY-call trace is the block clock; the NSF candidate's absolute opening cue frames retain the documented startup/scheduler anchors.",
			"The DMC engine advances once per modeled CPU cycle and requests a ROM byte as soon as its buffer is empty. It does not execute the NSF's 6502 instruction-boundary loop or inject FCEUX's four X6502_DMR stall cycles, so exact DMA and post-DMA CPU-write timing are unresolved.",
			"The frame-sequencer threshold is checked per CPU cycle; pinned FCEUX checks it at instruction-hook boundaries.",
			"No captured APU timing, DMC timing, frame-cycle schedule, or PCM contributes to synthesis. FCEUX PCM is only for the separate validation report.",
		],
	}
	manifest_path = candidate.with_suffix(".json")
	manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
	return manifest


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--trace-dir", type=Path, default=TRACE_DIR)
	parser.add_argument("--output-dir", type=Path, default=OUTPUT_DIR)
	args = parser.parse_args()
	manifest = render(args.trace_dir, args.output_dir)
	print(manifest["render"]["path"])


if __name__ == "__main__":
	main()
