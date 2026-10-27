#!/usr/bin/env python3
"""Render a seed-1 ROM/NSF WaveHi candidate using NSF DMC refill callbacks.

This diagnostic uses cycle-ordered APU writes, NSF PLAY calls, and libgme DMC
refill callback events from the same explicitly supplied ROM-derived NSF. The
callback times are emulator refill times, not authoritative 2A03 bus cycles.
No captured FCEUX timing or PCM is loaded by this script.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import tempfile
import csv
from pathlib import Path

from prototype_fceux_filter_pipeline import FCEUX_REVISION, ROOT, SOURCE_SHA256, fetch_coeffs
from render_source_nsf_wavehi_rom_dmc import ROM_PATH, ROM_SHA256, RENDERER, source_blocks

TRACE_DIR = ROOT / "reference/diagnostics/audio/source_phase_seed1_candidate_20261025/apu_trace"
OUTPUT_DIR = ROOT / "reference/diagnostics/audio/source_phase_seed1_nsf_callback_wavehi_20261026"
DPCM_EXTRACT = ROOT / "reference/rom_extract/audio/dpcm_sample_blob.bin"


def sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def compare_callback_replay(source_path: Path, rendered_path: Path) -> dict:
	with source_path.open(newline="", encoding="ascii") as stream:
		source = list(csv.DictReader(stream))
	with rendered_path.open(newline="", encoding="ascii") as stream:
		rendered = list(csv.DictReader(stream))
	def hex_value(value: str) -> int:
		return int(value.replace("$", "").replace("0x", ""), 16)
	count = min(len(source), len(rendered))
	first_mismatch = None
	for index in range(count):
		left = (int(source[index]["absolute_cpu_cycle"]), hex_value(source[index]["cpu_address"]), hex_value(source[index]["value"]))
		right = (int(rendered[index]["source_cpu_cycle"]), hex_value(rendered[index]["cpu_address"]), hex_value(rendered[index]["value"]))
		if left != right:
			first_mismatch = {"sequence": index, "source_nsf": list(left), "rendered_rom_verified": list(right)}
			break
	return {"source_rows": len(source), "rendered_rows": len(rendered),
		"cycle_address_byte_order_exact": len(source) == len(rendered) and first_mismatch is None,
		"first_mismatch": first_mismatch,
		"role": "post-render confirmation that scheduled refill rows were consumed in order and each byte passed the renderer's ROM-bank check"}


def render(trace_dir: Path, output_dir: Path) -> dict:
	trace_dir = trace_dir.resolve()
	output_dir = output_dir.resolve()
	output_dir.mkdir(parents=True, exist_ok=True)
	rom_bytes = ROM_PATH.read_bytes()
	if hashlib.sha256(rom_bytes).hexdigest() != ROM_SHA256:
		raise ValueError("supplied ROM SHA-256 does not match the pinned ROM")
	trace_meta = json.loads((trace_dir / "trace_meta.json").read_text(encoding="utf-8"))
	if trace_meta.get("source_rom_sha256") != ROM_SHA256:
		raise ValueError("seed-1 NSF trace sidecar does not identify the supplied ROM")
	if trace_meta.get("input_mode") != "explicit_candidate_nsf_no_builder_or_capture_event_read":
		raise ValueError("requires an explicitly supplied NSF trace, not capture-built input")
	for name, key in (("apu_writes.csv", "apu_writes_sha256"), ("play_calls.csv", "play_calls_sha256"),
			("dmc_fetches.csv", "dmc_fetches_sha256")):
		if sha256(trace_dir / name) != trace_meta["outputs"][key]:
			raise ValueError(f"seed-1 NSF trace output hash mismatch: {name}")
	bank_start = 16 + (512 if rom_bytes[6] & 0x04 else 0) + 0x1E * 0x2000
	bank_1e = rom_bytes[bank_start:bank_start + 0x2000]
	if not bank_1e.startswith(DPCM_EXTRACT.read_bytes()):
		raise ValueError("physical PRG bank $1E differs from preserved ROM DPCM extract")

	adapter = trace_dir / "wavehi_apu_writes_source_only.csv"
	if sha256(adapter) != trace_meta["outputs"]["wavehi_apu_adapter"]["sha256"]:
		raise ValueError("seed-1 source-only WaveHi APU adapter hash mismatch")
	horizon = int(trace_meta["nsf_replay"]["cpu_cycles_advanced"])
	blocks_path = output_dir / "nsf_play_blocks.csv"
	blocks = source_blocks(trace_dir / "play_calls.csv", horizon, blocks_path)
	ignored_trace = output_dir / "unused_fceux_trace.csv"
	ignored_trace.write_text("source NSF callback mode: captured FCEUX trace not loaded\n", encoding="ascii")
	candidate = output_dir / "seed1_nsf_callback_wavehi.wav"
	fetches_path = output_dir / "rom_verified_callback_refills.csv"

	with tempfile.TemporaryDirectory(prefix="ct2_seed1_callback_wavehi_") as temporary:
		work = Path(temporary)
		fetch_coeffs(work)
		binary = work / "apu_wavehi_renderer"
		subprocess.run([
			"clang++", "-std=c++17", "-O3", "-DNDEBUG", "-Wall", "-Wextra", "-Wno-unused-function",
			"-I", str(work), str(RENDERER), "-o", str(binary),
		], check=True)
		completed = subprocess.run([
			str(binary), str(adapter), str(blocks_path), str(ignored_trace), str(ROM_PATH), str(candidate),
			"--source-frame-sequencer", "--source-dmc-callbacks", str(trace_dir / "dmc_fetches.csv"),
			"--source-dmc-fetches", str(fetches_path),
		], check=False, capture_output=True, text=True)
		if completed.returncode:
			raise RuntimeError(f"source NSF callback WaveHi renderer failed: {completed.stderr.strip()}")
	callback_validation = compare_callback_replay(trace_dir / "dmc_fetches.csv", fetches_path)

	manifest = {
		"purpose": "Diagnostics-only seed-1 WaveHi render using ROM-verified source NSF/libgme DMC refill callback cycles.",
		"source_inputs": {
			"rom_sha256": ROM_SHA256,
			"source_nsf_trace_dir": trace_dir.relative_to(ROOT).as_posix(),
			"source_nsf_sha256": trace_meta["source_nsf_sha256"],
			"apu_writes": {"path": (trace_dir / "apu_writes.csv").relative_to(ROOT).as_posix(),
				"sha256": trace_meta["outputs"]["apu_writes_sha256"], "rows": trace_meta["outputs"]["apu_write_count"],
				"timestamps": "ROM-derived NSF CPU-bus write cycles"},
			"apu_adapter": {"path": adapter.relative_to(ROOT).as_posix(), "sha256": sha256(adapter)},
			"nsf_play_call_blocks": {"path": blocks_path.relative_to(ROOT).as_posix(), "sha256": sha256(blocks_path),
				"rows": len(blocks), "horizon_cpu_cycles": horizon, "use": "source NSF PLAY-call output boundaries"},
			"dpcm_rom": {"path": DPCM_EXTRACT.relative_to(ROOT).as_posix(), "sha256": sha256(DPCM_EXTRACT),
				"physical_bank": "$1E", "verified_prefix_bytes": len(DPCM_EXTRACT.read_bytes())},
			"dmc_refill_callbacks": {"path": (trace_dir / "dmc_fetches.csv").relative_to(ROOT).as_posix(),
				"sha256": trace_meta["outputs"]["dmc_fetches_sha256"], "rows": trace_meta["outputs"]["dmc_fetch_count"],
				"timestamps": "libgme cycle-reported DMC buffer-refill callback; not authoritative 2A03 bus/DMA cycles",
				"values": "address and byte are checked against the supplied ROM's physical bank $1E"},
			"captured_fceux_apu_writes_used_as_input": False,
			"captured_fceux_dmc_timestamps_used_as_input": False,
			"captured_fceux_frame_cycles_used_as_input": False,
			"captured_fceux_pcm_used_as_input": False,
		},
		"renderer": {
			"source": RENDERER.relative_to(ROOT).as_posix(), "source_sha256": sha256(RENDERER),
			"fceux_revision": FCEUX_REVISION, "pinned_filter_source_sha256": SOURCE_SHA256,
			"mixer_filter": "pinned FCEUX nonlinear pulse/TND lookup and soundq=2 FIR/NeoFilterSound/SexyFilter port",
			"frame_clock": "source NSF $4017 writes and pinned FCEUX NTSC fixed-point countdown checked per CPU cycle",
			"dmc_model": "source DMC bit timer/DAC model; callback events fill the sample buffer at libgme-reported source NSF cycles; callback CPU addresses/ROM bytes verified against bank $1E",
			"same_cycle_order": "DMC refill callback is processed before a same-cycle APU bus write; source trace does not establish cross-stream order for ties",
			"callback_refills_used_as_synthesis_input": True,
			"callback_times_are_hardware_dma_cycles": False,
			"callback_replay_validation": callback_validation,
		},
		"render": {"path": candidate.relative_to(ROOT).as_posix(), "sha256": sha256(candidate),
			"samples": (candidate.stat().st_size - 44) // 2, "stdout": completed.stdout.strip(), "runtime_asset": False},
		"limits": [
			"The NSF event schedule uses the existing seed-1 ROM-presenter candidate; its startup/worker/stall/helper-return frames and title Stop still include documented anchors, and the synthetic $4010/$4017 setup remains at PLAY index 2.",
			"libgme callback cycles indicate emulator buffer refills, not instruction-hook DMA fetches. Using them as a diagnostic schedule does not establish exact hardware timing; same-cycle callback/APU ordering is not independently known.",
			"The DMC bit/shift/DAC and frame-sequencer remain the build-only cycle model; the callback input replaces only the per-cycle immediate-empty-buffer fetch scheduler.",
			"No captured FCEUX timing or PCM is used to synthesize this candidate. FCEUX PCM is compared only by a separate post-render validation tool.",
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
