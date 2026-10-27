#!/usr/bin/env python3
"""Build an isolated ROM/NSF WaveHi candidate with instruction-hook DMC timing.

All synthesis inputs come from an explicit ROM-derived seed-1 NSF, its libgme
CPU/APU execution, the supplied ROM's bank-$1E DPCM bytes, and the pinned
WaveHi renderer. FCEUX PCM is opened only after the candidate WAV is complete.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
import tarfile
from pathlib import Path

import trace_rom_driver_apu as base_trace
from compare_fceux_apu_wavehi_prototype import (
	DEFAULT_REFERENCE, SAMPLE_RATE, WINDOWS, frame_envelope, load_wav, pearson,
)
from prototype_fceux_filter_pipeline import FCEUX_REVISION, ROOT, SOURCE_SHA256, fetch_coeffs
from render_source_nsf_wavehi_rom_dmc import RENDERER, ROM_PATH, ROM_SHA256, source_blocks

TRACE_DIR = ROOT / "reference/diagnostics/audio/source_phase_seed1_candidate_20261025/apu_trace"
NSF_PATH = ROOT / "reference/diagnostics/audio/source_phase_seed1_candidate_20261025/opening_timeline_seed1.nsf"
OUTPUT_DIR = ROOT / "reference/diagnostics/audio/source_phase_seed1_instruction_dmc_20261026"
EXPECTED_CPU_SHA256 = "fd8c98788f86a42ac75d2ad2fc2de07913e715e7bff87763cbe6166617e72542"
INSTRUCTION_HOOKS_CPP = r'''#include "trace_hooks.hpp"

#include <cstdio>
#include <cstdint>
#include <cstdlib>

namespace {
FILE* event_file = nullptr;
uint64_t cycle_base = 0;
uint32_t sequence = 0;
uint8_t dmc_format = 0;
uint8_t dmc_address_latch = 0;
uint8_t dmc_size_latch = 0;
uint32_t dmc_address = 0;
uint32_t dmc_size = 0;
int dmc_acc = 1;
int dmc_period = 1;
uint8_t dmc_bit_count = 0;
bool dmc_have_dma = false;
constexpr int periods[16] = {428,380,340,320,286,254,226,214,190,160,142,128,106,84,72,54};

void prep_sample() {
	dmc_address = 0x4000u + (static_cast<uint32_t>(dmc_address_latch) << 6);
	dmc_size = (static_cast<uint32_t>(dmc_size_latch) << 4) + 1;
}
} // namespace

void ct2_trace_instruction_dmc_open(const char* path) {
	if (event_file != nullptr) std::fclose(event_file);
	event_file = std::fopen(path, "wb");
	if (event_file == nullptr) {
		std::fprintf(stderr, "Unable to open instruction-hook DMC output\n");
		std::exit(2);
	}
	std::fputs("sequence,absolute_cpu_cycle,local_cpu_cycle,cpu_address,value,hook_pc,opcode,opcode_cycles,stall_cycles,dmcacc_at_hook,bitcount_at_hook,dmcsize_at_hook,dmcperiod_at_hook\n", event_file);
}

void ct2_trace_instruction_dmc_reset() {
	cycle_base = 0;
	sequence = 0;
	dmc_format = 0;
	dmc_address_latch = 0;
	dmc_size_latch = 0;
	dmc_address = 0;
	dmc_size = 0;
	dmc_acc = 1;
	dmc_period = 1;
	dmc_bit_count = 0;
	dmc_have_dma = false;
}

void ct2_trace_instruction_dmc_apu_write(int32_t local_cycle, uint16_t address, int value, uint8_t origin) {
	const uint8_t data = static_cast<uint8_t>(value);
	if (origin != 0 && address == 0x4015) { dmc_size = 0; return; }
	switch (address) {
	case 0x4010:
		dmc_format = data;
		dmc_period = periods[data & 0x0F];
		break;
	case 0x4012: dmc_address_latch = data; break;
	case 0x4013: dmc_size_latch = data; break;
	case 0x4015:
		if (!(data & 0x10)) dmc_size = 0;
		else if (!dmc_size) prep_sample();
		break;
	default: break;
	}
	(void)local_cycle;
}

int ct2_trace_instruction_dmc_hook(int32_t local_cycle, uint16_t pc, uint8_t opcode, int opcode_cycles) {
	const int acc_before = dmc_acc;
	const uint8_t bitcount_before = dmc_bit_count;
	int stall = 0;
	if (dmc_size && !dmc_have_dma) {
		// Pinned FCEUX calls DMCDMA once per instruction hook and performs four
		// X6502_DMR reads. This candidate records the fourth-read edge and carries
		// those four cycles into subsequent NSF CPU/APU execution.
		stall = 4;
		const uint16_t cpu_address = static_cast<uint16_t>(0x8000u + dmc_address);
		const int32_t fetch_local = local_cycle + stall;
		const uint64_t fetch_absolute = cycle_base + static_cast<uint32_t>(fetch_local);
		if (event_file != nullptr) {
			std::fprintf(event_file, "%u,%llu,%d,$%04X,$00,$%04X,$%02X,%d,%d,%d,%u,%u,%d\n",
				sequence++, static_cast<unsigned long long>(fetch_absolute), fetch_local,
				cpu_address, pc, opcode, opcode_cycles, stall, acc_before,
				static_cast<unsigned>(bitcount_before), dmc_size, dmc_period);
		}
		dmc_have_dma = true;
		dmc_address = (dmc_address + 1) & 0x7FFF;
		--dmc_size;
		if (!dmc_size && (dmc_format & 0x40)) prep_sample();
	}

	// FCEUX advances DMCacc by the opcode's cycles in the hook; the four DMR
	// cycles advance CPU/audio timestamps but are not added to this decrement.
	dmc_acc -= opcode_cycles;
	while (dmc_acc <= 0) {
		dmc_acc += dmc_period;
		if (dmc_bit_count == 0 && dmc_have_dma) dmc_have_dma = false;
		dmc_bit_count = static_cast<uint8_t>((dmc_bit_count + 1) & 7);
	}
	return stall;
}

void ct2_trace_instruction_dmc_end_frame(int32_t local_cycles) {
	cycle_base += static_cast<uint32_t>(local_cycles);
}

void ct2_trace_instruction_dmc_close() {
	if (event_file != nullptr) {
		std::fclose(event_file);
		event_file = nullptr;
	}
}
'''


def sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def write_adapter(source: Path, output: Path) -> int:
	with source.open(newline="", encoding="ascii") as inp, output.open("w", newline="", encoding="ascii") as out:
		reader = csv.DictReader(inp)
		writer = csv.writer(out, lineterminator="\n")
		writer.writerow(["sequence", "unused_frame", "unused_hook", "absolute_cpu_cycle", "local_cpu_cycle", "address", "value"])
		for row in reader:
			writer.writerow([row["sequence"], "", "", row["absolute_cpu_cycle"], row["local_cpu_cycle"], row["address"], row["value"]])
		return sum(1 for _ in source.open(newline="", encoding="ascii"))


def patch_cpu_source(source: Path) -> str:
	path = source / "gme/Nes_Cpu.cpp"
	original = path.read_bytes()
	actual_hash = hashlib.sha256(original).hexdigest()
	if actual_hash != EXPECTED_CPU_SHA256:
		raise ValueError(f"Pinned Nes_Cpu.cpp hash mismatch: {actual_hash}")
	text = original.decode("utf-8")
	include_anchor = '#include "nes_cpu_io.h"\n'
	if text.count(include_anchor) != 1:
		raise ValueError("Expected a unique Nes_Cpu.cpp hook include anchor")
	text = text.replace(include_anchor, include_anchor + '#include "ct2_trace_hooks.hpp"\nextern int ct2_trace_instruction_dmc_hook(int32_t local_cycle, uint16_t pc, uint8_t opcode, int opcode_cycles);\n', 1)
	anchor = "almost_out_of_time:\n\n\tdata = *instr;"
	replacement = (
		"almost_out_of_time:\n"
		"\t\ts_time += ct2_trace_instruction_dmc_hook( TIME, pc - 1, opcode, data );\n\n"
		"\tdata = *instr;"
	)
	if text.count(anchor) != 1:
		raise ValueError("Expected a unique per-instruction boundary in Nes_Cpu.cpp")
	text = text.replace(anchor, replacement, 1)
	path.write_text(text, encoding="utf-8", newline="")
	return actual_hash


def patch_trace_project(project: Path) -> None:
	header = project / "trace_hooks.hpp"
	with header.open("a", encoding="utf-8", newline="") as stream:
		stream.write("\nvoid ct2_trace_instruction_dmc_open(const char* path);\nvoid ct2_trace_instruction_dmc_reset();\nvoid ct2_trace_instruction_dmc_apu_write(int32_t local_cycle, uint16_t address, int value, uint8_t origin);\nint ct2_trace_instruction_dmc_hook(int32_t local_cycle, uint16_t pc, uint8_t opcode, int opcode_cycles);\nvoid ct2_trace_instruction_dmc_end_frame(int32_t local_cycles);\nvoid ct2_trace_instruction_dmc_close();\n")
	cpp = project / "trace_hooks.cpp"
	text = cpp.read_text(encoding="utf-8")
	text = text.replace("\tcycle_base = 0;\n\twrite_sequence = 0;", "\tcycle_base = 0;\n\tct2_trace_instruction_dmc_reset();\n\tct2_trace_instruction_dmc_apu_write(0, 0x4015, 0x0F, 1);\n\twrite_sequence = 0;", 1)
	text = text.replace("void ct2_trace_apu_write(int32_t local_cycle, uint16_t address, int value, uint8_t origin) {\n\tif (apu_file == nullptr)", "void ct2_trace_apu_write(int32_t local_cycle, uint16_t address, int value, uint8_t origin) {\n\tct2_trace_instruction_dmc_apu_write(local_cycle, address, value, origin);\n\tif (apu_file == nullptr)", 1)
	text = text.replace("void ct2_trace_end_frame(int32_t local_cycles) {\n\tcycle_base += static_cast<uint32_t>(local_cycles);", "void ct2_trace_end_frame(int32_t local_cycles) {\n\tcycle_base += static_cast<uint32_t>(local_cycles);\n\tct2_trace_instruction_dmc_end_frame(local_cycles);", 1)
	cpp.write_text(text, encoding="utf-8", newline="")
	(project / "instruction_dmc.cpp").write_text(INSTRUCTION_HOOKS_CPP, encoding="utf-8", newline="")
	cmake = project / "CMakeLists.txt"
	text = cmake.read_text(encoding="utf-8")
	text = text.replace("\ttrace_hooks.cpp\n)", "\ttrace_hooks.cpp\n\tinstruction_dmc.cpp\n)", 1)
	cmake.write_text(text, encoding="utf-8", newline="")
	main = project / "trace_main.cpp"
	text = main.read_text(encoding="utf-8")
	text = text.replace("if (argc != 6)", "if (argc != 7)", 1)
	text = text.replace("usage: %s input.nsf apu_writes.csv play_calls.csv dmc_fetches.csv cpu_cycles\\n", "usage: %s input.nsf apu_writes.csv play_calls.csv dmc_fetches.csv instruction_dmc.csv cpu_cycles\\n", 1)
	text = text.replace("std::strtol(argv[5], nullptr, 10)", "std::strtol(argv[6], nullptr, 10)", 1)
	text = text.replace("ct2_trace_open(argv[2], argv[3], argv[4]);", "ct2_trace_open(argv[2], argv[3], argv[4]);\n\tct2_trace_instruction_dmc_open(argv[5]);", 1)
	text = text.replace("ct2_trace_close();\n\t\treturn 1;", "ct2_trace_close();\n\t\tct2_trace_instruction_dmc_close();\n\t\treturn 1;", 1)
	text = text.replace("ct2_trace_close();\n\treturn result;", "ct2_trace_close();\n\tct2_trace_instruction_dmc_close();\n\treturn result;", 1)
	main.write_text(text, encoding="utf-8", newline="")


def map_rom_values(trace_path: Path, rom_path: Path, output: Path) -> int:
	rom = rom_path.read_bytes()
	if hashlib.sha256(rom).hexdigest() != ROM_SHA256:
		raise ValueError("supplied ROM SHA-256 mismatch")
	if rom[:4] != b"NES\x1a":
		raise ValueError("supplied reference is not iNES")
	bank_start = 16 + (512 if (rom[6] & 0x04) else 0) + 0x1E * 0x2000
	bank = rom[bank_start:bank_start + 0x2000]
	count = 0
	with trace_path.open(newline="", encoding="ascii") as inp, output.open("w", newline="", encoding="ascii") as out:
		reader = csv.DictReader(inp)
		fields = ["sequence", "absolute_cpu_cycle", "local_cpu_cycle", "cpu_address", "value", "hook_pc", "opcode", "opcode_cycles", "stall_cycles", "dmcacc_at_hook", "bitcount_at_hook", "dmcsize_at_hook", "dmcperiod_at_hook"]
		writer = csv.DictWriter(out, fieldnames=fields, lineterminator="\n")
		writer.writeheader()
		for row in reader:
			address = int(row["cpu_address"].replace("$", ""), 16)
			if not 0xC000 <= address < 0xE000:
				raise ValueError(f"DMC source address escaped bank-$1E window: ${address:04X}")
			offset = address - 0xC000
			mapped = dict(row)
			mapped["value"] = f"${bank[offset]:02X}"
			writer.writerow(mapped)
			count += 1
	return count


def trace_source_nsf(output: Path, nsf: Path, cycles: int) -> dict:
	output.mkdir(parents=True, exist_ok=True)
	if sha256(nsf) != json.loads(nsf.with_suffix(".json").read_text(encoding="utf-8"))["nsf_sha256"]:
		raise ValueError("explicit NSF sidecar hash mismatch")
	if json.loads(nsf.with_suffix(".json").read_text(encoding="utf-8")).get("source_rom_sha256") != ROM_SHA256:
		raise ValueError("explicit NSF sidecar does not identify the supplied reference ROM")
	with tempfile.TemporaryDirectory(prefix="ct2_instruction_dmc_") as temp_dir:
		work = Path(temp_dir)
		upstream, archive_hash = base_trace.download_source(work, None)
		base_trace.apply_instrumentation(upstream)
		cpu_original_hash = patch_cpu_source(upstream)
		shutil.copy2(base_trace.TRACE_PROJECT / "trace_hooks.hpp", upstream / "gme/ct2_trace_hooks.hpp")
		project = work / "trace_project"
		shutil.copytree(base_trace.TRACE_PROJECT, project)
		patch_trace_project(project)
		build = work / "build"
		subprocess.run(["cmake", "-S", str(project), "-B", str(build), f"-DCT2_GME_SOURCE={upstream}", "-DCMAKE_BUILD_TYPE=Release"], check=True)
		subprocess.run(["cmake", "--build", str(build), "--target", "ct2_libgme_apu_trace", "--parallel"], check=True)
		exe = build / "ct2_libgme_apu_trace"
		runs = []
		for index in range(2):
			prefix = work / f"run_{index}"
			paths = {key: prefix.with_name(prefix.name + f"_{key}.csv") for key in ("apu", "play", "callback", "hook")}
			subprocess.run([str(exe), str(nsf), str(paths["apu"]), str(paths["play"]), str(paths["callback"]), str(paths["hook"]), str(cycles)], check=True)
			runs.append(paths)
		for key in runs[0]:
			if runs[0][key].read_bytes() != runs[1][key].read_bytes():
				raise RuntimeError(f"instruction-DMC trace is nondeterministic: {key}")
		copied = {}
		for key, target_name in (("apu", "apu_writes.csv"), ("play", "play_calls.csv"), ("callback", "libgme_callbacks_validation_only.csv"), ("hook", "instruction_dmc_raw.csv")):
			target = output / target_name
			shutil.copy2(runs[0][key], target)
			copied[key] = {"path": target_name, "sha256": sha256(target), "bytes": target.stat().st_size}
		rom_verified = output / "instruction_dmc_fetches.csv"
		fetch_count = map_rom_values(copied_path(output, copied["hook"]["path"]), ROM_PATH, rom_verified)
		return {"archive_sha256": archive_hash, "original_cpu_source_sha256": cpu_original_hash, "outputs": copied, "rom_verified_dmc_fetches": {"path": rom_verified.name, "sha256": sha256(rom_verified), "rows": fetch_count}}


def copied_path(folder: Path, name: str) -> Path:
	return folder / name


def validate_pcm_after_render(candidate: Path, output: Path) -> dict:
	# This function is intentionally invoked only after the candidate exists.
	reference = load_wav(DEFAULT_REFERENCE)
	pcm = load_wav(candidate)
	shared_frames = min(len(frame_envelope(reference)), len(frame_envelope(pcm)))
	ref_env = frame_envelope(reference)[:shared_frames]
	candidate_env = frame_envelope(pcm)[:shared_frames]
	windows = {}
	for name, (lo, hi) in WINDOWS.items():
		end = min(hi, shared_frames)
		if end <= lo:
			continue
		lo_sample = round(lo * SAMPLE_RATE / 60.0988)
		end_sample = min(len(reference), len(pcm), round(end * SAMPLE_RATE / 60.0988))
		ref = reference[lo_sample:end_sample]
		cand = pcm[lo_sample:end_sample]
		ref_values = list(ref)
		cand_values = list(cand)
		ref_rms = (sum(float(x) * x for x in ref_values) / max(1, len(ref_values))) ** 0.5
		rmse = (sum((float(a) - float(b)) ** 2 for a, b in zip(ref_values, cand_values)) / max(1, len(ref_values))) ** 0.5
		windows[name] = {"frames": [lo, end], "envelope_correlation": pearson(ref_env[lo:end], candidate_env[lo:end]), "same_index_sample_correlation": pearson(ref_values, cand_values), "normalized_rmse": rmse / ref_rms if ref_rms else None, "sample_count": len(ref_values)}
	result = {
		"purpose": "Post-render validation only. Captured FCEUX PCM is read after the source-only candidate WAV has been written; it was not a synthesis input.",
		"candidate": {"path": candidate.relative_to(ROOT).as_posix(), "sha256": sha256(candidate), "samples": len(pcm)},
		"reference": {"path": DEFAULT_REFERENCE.relative_to(ROOT).as_posix(), "sha256": sha256(DEFAULT_REFERENCE), "samples": len(reference)},
		"shared_frame_count": shared_frames,
		"windows": windows,
		"limitations": ["This NSF cue schedule still carries previously documented presenter timing anchors; the experiment isolates DMC instruction-hook scheduling.", "Hook cycle placement is derived from libgme's 6502 loop, not a physical 2A03 bus arbiter. The four-cycle stall model follows pinned FCEUX's instruction hook.", "The candidate compares an instruction-hook DMC schedule with captured FCEUX PCM, but does not prove arbitrary-input runtime audio exactness."],
	}
	path = output / "post_render_fceux_pcm_validation.json"
	path.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
	return result


def render_candidate(trace: dict, output: Path, horizon: int) -> dict:
	trace_dir = output
	blocks_path = output / "source_play_blocks.csv"
	blocks = source_blocks(trace_dir / "play_calls.csv", horizon, blocks_path)
	adapter = output / "wavehi_apu_writes.csv"
	write_adapter(trace_dir / "apu_writes.csv", adapter)
	ignored = output / "unused_fceux_dmc_trace.csv"
	ignored.write_text("instruction-boundary source DMC mode: captured FCEUX timing not loaded\n", encoding="ascii")
	candidate = output / "seed1_instruction_boundary_wavehi.wav"
	rendered_fetches = output / "renderer_rom_verified_fetches.csv"
	with tempfile.TemporaryDirectory(prefix="ct2_instruction_dmc_wavehi_") as temp:
		work = Path(temp)
		fetch_coeffs(work)
		binary = work / "apu_wavehi_renderer"
		subprocess.run(["clang++", "-std=c++17", "-O3", "-DNDEBUG", "-Wall", "-Wextra", "-Wno-unused-function", "-I", str(work), str(RENDERER), "-o", str(binary)], check=True)
		result = subprocess.run([str(binary), str(adapter), str(blocks_path), str(ignored), str(ROM_PATH), str(candidate), "--source-frame-sequencer", "--source-dmc-callbacks", str(trace_dir / "instruction_dmc_fetches.csv"), "--source-dmc-fetches", str(rendered_fetches)], capture_output=True, text=True)
		if result.returncode:
			raise RuntimeError(f"instruction-boundary WaveHi renderer failed: {result.stderr.strip()}")
	return {"path": candidate.relative_to(ROOT).as_posix(), "sha256": sha256(candidate), "samples": (candidate.stat().st_size - 44) // 2, "renderer_stdout": result.stdout.strip(), "fetch_rows": sum(1 for _ in csv.DictReader(rendered_fetches.open(newline="", encoding="ascii"))), "rendered_fetch_sha256": sha256(rendered_fetches), "source_play_block_count": len(blocks)}


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--output-dir", type=Path, default=OUTPUT_DIR)
	parser.add_argument("--input-nsf", type=Path, default=NSF_PATH)
	parser.add_argument("--cpu-cycles", type=int, default=140_000_000)
	args = parser.parse_args()
	output = args.output_dir.resolve()
	output.mkdir(parents=True, exist_ok=True)
	trace_meta = trace_source_nsf(output, args.input_nsf.resolve(), args.cpu_cycles)
	(output / "trace_manifest.json").write_text(json.dumps(trace_meta, indent=2) + "\n", encoding="utf-8")
	render = render_candidate(trace_meta, output, args.cpu_cycles)
	validation = validate_pcm_after_render(ROOT / render["path"], output)
	manifest = {"source_nsf": args.input_nsf.resolve().relative_to(ROOT).as_posix(), "source_nsf_sha256": sha256(args.input_nsf.resolve()), "source_rom_sha256": ROM_SHA256, "cpu_cycles": args.cpu_cycles, "trace": trace_meta, "render": render, "validation": validation, "synthesis_inputs": {"captured_fceux_pcm": False, "captured_fceux_apu_writes_or_timestamps": False, "captured_fceux_dmc_timestamps": False, "captured_fceux_frame_cycles": False, "source_inputs": ["explicit ROM-derived seed-1 NSF CPU/APU execution", "original ROM physical PRG bank $1E", "ROM-derived NSF PLAY-call blocks", "pinned WaveHi/mixer/filter implementation"]}}
	(output / "candidate_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
	print(output)


if __name__ == "__main__":
	main()
