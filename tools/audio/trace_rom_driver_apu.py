#!/usr/bin/env python3
"""Build a pinned instrumented libgme and trace ROM-derived NSF APU writes.

This build-only diagnostic emits CPU-cycle APU register writes and NSF PLAY
call boundaries. It never renders or writes PCM/WAV.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import shutil
import subprocess
import tarfile
import tempfile
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

GME_VERSION = "0.6.5"
GME_TAG_COMMIT = "9e23d10f9fd2a6a2f33b10912dd8dc7153258995"
GME_ARCHIVE_URL = "https://github.com/libgme/game-music-emu/archive/refs/tags/0.6.5.tar.gz"
GME_ARCHIVE_SHA256 = "8531678502451c2cf04248cda45c8b4645e19fcfb63e6a7ec2549641c47bb392"
SOURCE_FILE_HASHES = {
	"gme/Nsf_Emu.h": "26770c9acf216ccfa5e5f0b8f97ce71eec6ca79850031f0b0ca0c7d0260074f8",
    "gme/Nsf_Emu.cpp": "380857679b888e34a4ce17b2d47af0680de451fe7cbae51f9ee973be120a29a9",
    "gme/nes_cpu_io.h": "9b3156f00ce6651b744d09300f5f1061cf9d95fbdcaf4f35ed0f7ecba20f84f1",
	"gme/Nes_Oscs.cpp": "77d1695a02a30b52cbf015dc04df282b2e1c0c15a0b8f16bb26a2a796551363f",
	"gme/Nes_Oscs.h": "25c52ce9a5acfade5573a57de7e572553d6f993087c9aae18884c889c5e0a89d",
}
REFERENCE_TIMING = ROOT / "reference/diagnostics/audio/precise_pcm_sample_alignment_20261024.json"
OUTPUT_DIR = ROOT / "reference/diagnostics/audio/rom_driver_apu_trace_20261024"
TRACE_PROJECT = ROOT / "tools/audio/trace_libgme_apu"
NTSC_CPU_HZ = 1789772.7272727273
DEFAULT_CYCLE_HORIZON = "elapsed_cycles_rows_1_through_4692"
NSF_HEADER_SIZE = 0x80
NSF_WRAPPER_CPU_BASE = 0xE000


def sha256(data: bytes) -> str:
	return hashlib.sha256(data).hexdigest()


def patch_exact(path: Path, replacements: list[tuple[str, str]]) -> str:
	before = path.read_bytes()
	actual_hash = sha256(before)
	expected_hash = SOURCE_FILE_HASHES[str(path.relative_to(path.parents[1]))]
	if actual_hash != expected_hash:
		raise ValueError(f"Pinned libgme source hash mismatch for {path.name}: {actual_hash}")
	text = before.decode("utf-8")
	for old, new in replacements:
		count = text.count(old)
		if count != 1:
			raise ValueError(f"Expected one patch anchor in {path.name}, found {count}: {old!r}")
		text = text.replace(old, new, 1)
	path.write_text(text, encoding="utf-8", newline="")
	return actual_hash


def apply_instrumentation(source: Path) -> dict[str, str]:
	for relative, expected in SOURCE_FILE_HASHES.items():
		actual = sha256((source / relative).read_bytes())
		if actual != expected:
			raise ValueError(f"Pinned libgme source mismatch for {relative}: {actual}")

	header = source / "gme/Nsf_Emu.h"
	header_hash = patch_exact(header, [
		(
			"\tNes_Apu* apu_() { return &apu; }\n",
			"\tNes_Apu* apu_() { return &apu; }\n"
			"\t// Temporary build-only access to CPU cycles for the external trace tool.\n"
			"\tblargg_err_t ct2_trace_advance_cycles( int cycles );\n",
		),
	])

	cpp = source / "gme/Nsf_Emu.cpp"
	cpp_hash = patch_exact(cpp, [
		('#include "Nsf_Emu.h"\n', '#include "Nsf_Emu.h"\n#include "ct2_trace_hooks.hpp"\n'),
		(
			"\tapu.reset( pal_only, (header_.speed_flags & 0x20) ? 0x3F : 0 );\n"
			"\tapu.write_register( 0, 0x4015, 0x0F );\n"
			"\tapu.write_register( 0, 0x4017, (header_.speed_flags & 0x10) ? 0x80 : 0 );",
			"\tapu.reset( pal_only, (header_.speed_flags & 0x20) ? 0x3F : 0 );\n"
			"\tct2_trace_reset();\n"
			"\tct2_trace_apu_write( 0, 0x4015, 0x0F, 1 );\n"
			"\tapu.write_register( 0, 0x4015, 0x0F );\n"
			"\tint ct2_frame_counter_mode = (header_.speed_flags & 0x10) ? 0x80 : 0;\n"
			"\tct2_trace_apu_write( 0, 0x4017, ct2_frame_counter_mode, 1 );\n"
			"\tapu.write_register( 0, 0x4017, ct2_frame_counter_mode );",
		),
		("\t\t\t\tGME_FRAME_HOOK( this );", "\t\t\t\tct2_trace_play_call( cpu::time() );\n\t\t\t\tGME_FRAME_HOOK( this );"),
		("\tduration = time();\n", "\tduration = time();\n\tct2_trace_end_frame( duration );\n"),
	])
	with cpp.open("a", encoding="utf-8", newline="") as stream:
		stream.write(
			"\n"
			"// Build-only entry point: advance exact 2A03 cycles without requesting audio samples.\n"
			"blargg_err_t Nsf_Emu::ct2_trace_advance_cycles( int cycles )\n"
			"{\n"
			"\tblip_time_t duration = cycles;\n"
			"\treturn run_clocks( duration, 0 );\n"
			"}\n"
			"\n"
			"extern \"C\" blargg_err_t ct2_gme_trace_advance_nsf( Music_Emu* emu, int cycles )\n"
			"{\n"
			"\treturn static_cast<Nsf_Emu*>( emu )->ct2_trace_advance_cycles( cycles );\n"
			"}\n"
		)

	io = source / "gme/nes_cpu_io.h"
	io_hash = patch_exact(io, [
		('#include "Nsf_Emu.h"\n', '#include "Nsf_Emu.h"\n#include "ct2_trace_hooks.hpp"\n'),
		(
			"\t\tGME_APU_HOOK( this, addr - Nes_Apu::start_addr, data );\n"
			"\t\tapu.write_register( cpu::time(), addr, data );",
			"\t\tGME_APU_HOOK( this, addr - Nes_Apu::start_addr, data );\n"
			"\t\tct2_trace_apu_write( cpu::time(), addr, data, 0 );\n"
			"\t\tapu.write_register( cpu::time(), addr, data );",
		),
	])
	dmc_header = source / "gme/Nes_Oscs.h"
	dmc_header_hash = patch_exact(dmc_header, [
		(
			"\tNes_Apu* apu;\n",
			"\tNes_Apu* apu;\n"
			"\t// Diagnostic-only timestamp supplied by the pinned APU DMC scheduler.\n"
			"\tnes_time_t ct2_trace_fetch_time;\n",
		),
	])
	dmc_cpp = source / "gme/Nes_Oscs.cpp"
	dmc_cpp_hash = patch_exact(dmc_cpp, [
		('#include "blargg_source.h"\n', '#include "blargg_source.h"\n#include "ct2_trace_hooks.hpp"\n'),
		(
			"\taddress = 0;\n\tdac = 0;\n",
			"\taddress = 0;\n\tct2_trace_fetch_time = 0;\n\tdac = 0;\n",
		),
		(
			"\tbuf = prg_reader( prg_reader_data, 0x8000u + address );\n",
			"\tbuf = prg_reader( prg_reader_data, 0x8000u + address );\n"
			"\tct2_trace_dmc_fetch( ct2_trace_fetch_time, 0x8000u + address, buf );\n",
		),
		(
			"void Nes_Dmc::start()\n{\n\treload_sample();\n\tfill_buffer();\n",
			"void Nes_Dmc::start()\n{\n\treload_sample();\n\tct2_trace_fetch_time = apu->last_dmc_time;\n\tfill_buffer();\n",
		),
		(
			"\t\t\t\t\t\tfill_buffer();\n",
			"\t\t\t\t\t\tct2_trace_fetch_time = time;\n"
			"\t\t\t\t\t\tfill_buffer();\n",
		),
	])
	return {
		"gme/Nsf_Emu.h": header_hash,
		"gme/Nsf_Emu.cpp": cpp_hash,
		"gme/nes_cpu_io.h": io_hash,
		"gme/Nes_Oscs.h": dmc_header_hash,
		"gme/Nes_Oscs.cpp": dmc_cpp_hash,
	}


def download_source(work: Path, source_dir: Path | None) -> tuple[Path, str]:
	if source_dir is not None:
		candidate = source_dir.resolve()
		if not (candidate / "gme/Nsf_Emu.cpp").is_file():
			raise ValueError(f"Not a libgme source tree: {candidate}")
		copied = work / "game-music-emu-0.6.5"
		shutil.copytree(candidate, copied)
		return copied, "provided_source_tree"

	archive_path = work / "libgme-0.6.5.tar.gz"
	with urllib.request.urlopen(GME_ARCHIVE_URL, timeout=30) as response:
		archive = response.read()
	if sha256(archive) != GME_ARCHIVE_SHA256:
		raise ValueError("Downloaded libgme 0.6.5 archive failed its pinned SHA-256 check")
	archive_path.write_bytes(archive)
	with tarfile.open(archive_path, "r:gz") as bundle:
		bundle.extractall(work, filter="data")
	source = work / "game-music-emu-0.6.5"
	if not (source / "gme/Nsf_Emu.cpp").is_file():
		raise ValueError("Unexpected directory layout in pinned libgme source archive")
	return source, sha256(archive)


def source_byte_digest(path: Path) -> str:
	return sha256(path.read_bytes())


def apply_cue_frame_offset(nsf_path: Path, nsf_info: dict, offset: int) -> dict:
	from build_opening_timeline_nsf import APU_SETUP_EVENT, EVENT_DETAILS, EVENT_TABLE, PRG_SIZE

	if offset == 0:
		return {"cue_frame_offset_ticks": 0, "cue_frame_patches": []}
	if offset < 0:
		raise ValueError("cue frame offset must be nonnegative")
	data = bytearray(nsf_path.read_bytes())
	wrapper_file_start = NSF_HEADER_SIZE + PRG_SIZE
	event_table_file_start = wrapper_file_start + EVENT_TABLE - NSF_WRAPPER_CPU_BASE
	setup_entry = bytes([APU_SETUP_EVENT[0] & 0xFF, APU_SETUP_EVENT[0] >> 8, APU_SETUP_EVENT[1]])
	if data[event_table_file_start:event_table_file_start + 3] != setup_entry:
		raise ValueError(f"NSF cold-start setup marker mismatch: {data[event_table_file_start:event_table_file_start + 3].hex()}")
	patches = []
	for index, event in enumerate(EVENT_DETAILS, start=1):
		entry_offset = event_table_file_start + index * 3
		old_frame = int(event["frame"])
		old_id = int(event["sound_id"])
		old_entry = bytes([old_frame & 0xFF, old_frame >> 8, old_id])
		if data[entry_offset:entry_offset + 3] != old_entry:
			raise ValueError(f"NSF event table mismatch at entry {index}: {data[entry_offset:entry_offset + 3].hex()}")
		new_frame = old_frame + offset
		if new_frame > 0xFFFE:
			raise ValueError(f"cue frame offset overflows NSF event counter at entry {index}")
		data[entry_offset:entry_offset + 2] = new_frame.to_bytes(2, "little")
		patches.append({
			"index": index,
			"rom_cue_frame": old_frame,
			"candidate_cue_frame": new_frame,
			"sound_id": old_id,
			"nsf_file_offset": f"0x{entry_offset:06X}",
		})
	nsf_path.write_bytes(data)
	info_path = nsf_path.with_suffix(".json")
	nsf_info = json.loads(info_path.read_text(encoding="utf-8"))
	nsf_info["nsf_sha256"] = sha256(data)
	nsf_info["cue_frame_offset_experiment"] = {
		"cue_frame_offset_ticks": offset,
		"patches": patches,
		"preserved_cold_start_marker": {"frame": APU_SETUP_EVENT[0], "id": f"0x{APU_SETUP_EVENT[1]:02X}", "note": "The NSF-only ROM-byte APU startup sequence is not part of the cue-frame offset experiment."},
		"note": "Diagnostic candidate only: source event frame entries are delayed without changing the ROM-byte APU startup marker, ROM driver bytes, NSF startup phase, or source event order.",
	}
	info_path.write_text(json.dumps(nsf_info, indent=2) + "\n", encoding="utf-8")
	return nsf_info["cue_frame_offset_experiment"]


def run_checked(args: list[str], *, cwd: Path | None = None) -> None:
	subprocess.run(args, cwd=cwd, check=True)


def _load_explicit_nsf(path: Path) -> tuple[Path, dict]:
	nsf_path = path.resolve()
	if not nsf_path.is_file():
		raise FileNotFoundError(f"Explicit NSF input does not exist: {nsf_path}")
	nsf_bytes = nsf_path.read_bytes()
	if len(nsf_bytes) < NSF_HEADER_SIZE or nsf_bytes[:5] != b"NESM\x1a":
		raise ValueError(f"Explicit input is not an NSF file: {nsf_path}")
	info_path = nsf_path.with_suffix(".json")
	if not info_path.is_file():
		raise FileNotFoundError(f"Explicit NSF sidecar metadata is required: {info_path}")
	info = json.loads(info_path.read_text(encoding="utf-8"))
	actual_nsf_hash = sha256(nsf_bytes)
	if info.get("nsf_sha256") != actual_nsf_hash:
		raise ValueError("Explicit NSF sidecar SHA-256 does not match the NSF bytes")
	if info.get("source_rom_sha256") != EXPECTED_ROM_SHA256:
		raise ValueError("Explicit NSF sidecar does not identify the supplied reference ROM")
	return nsf_path, info


def _write_renderer_apu_adapter(source_path: Path, output_path: Path) -> dict:
	"""Keep source CPU cycles while leaving the FCEUX-only columns explicitly blank."""
	with source_path.open("r", newline="", encoding="ascii") as source, output_path.open("w", newline="", encoding="ascii") as output:
		reader = csv.DictReader(source)
		writer = csv.writer(output, lineterminator="\n")
		writer.writerow(["sequence", "unused_frame", "unused_hook", "absolute_cpu_cycle", "local_cpu_cycle", "address", "value"])
		count = 0
		for row in reader:
			writer.writerow([
				row["sequence"], "", "", row["absolute_cpu_cycle"], row["local_cpu_cycle"],
				row["address"], row["value"],
			])
			count += 1
	return {"path": output_path.name, "rows": count, "sha256": sha256(output_path.read_bytes()),
		"note": "FCEUX-only frame/hook columns are blank; absolute and local CPU cycles are copied from libgme trace rows."}


def _write_reported_cycle_merge(apu_path: Path, dmc_path: Path, output_path: Path) -> dict:
	"""Interleave libgme's two event streams by their reported cycle without implying DMA accuracy."""
	events: list[dict] = []
	with apu_path.open("r", newline="", encoding="ascii") as stream:
		for row in csv.DictReader(stream):
			events.append({
				"reported_cycle": int(row["absolute_cpu_cycle"]),
				"local_cycle": row["local_cpu_cycle"],
				"event_type": "apu_write",
				"source_sequence": row["sequence"],
				"address": row["address"],
				"value": row["value"],
				"timestamp_semantics": "libgme CPU bus-write hook cycle",
				"origin": row["origin"],
			})
	with dmc_path.open("r", newline="", encoding="ascii") as stream:
		for row in csv.DictReader(stream):
			events.append({
				"reported_cycle": int(row["absolute_cpu_cycle"]),
				"local_cycle": row["local_cpu_cycle"],
				"event_type": "dmc_byte_refill_callback",
				"source_sequence": row["sequence"],
				"address": row["cpu_address"],
				"value": row["value"],
				"timestamp_semantics": "libgme internal DMC-buffer callback; not CPU DMA/bus-stall timing",
				"origin": "libgme Nes_Dmc::fill_buffer",
			})
	# Stable ties preserve each source stream's existing row order; cross-stream
	# same-cycle ordering is not emitted as a claim and is recorded in metadata.
	events.sort(key=lambda event: event["reported_cycle"])
	with output_path.open("w", newline="", encoding="utf-8") as stream:
		writer = csv.DictWriter(stream, fieldnames=[
			"reported_cycle", "event_type", "source_sequence", "local_cycle",
			"address", "value", "timestamp_semantics", "origin",
		], lineterminator="\n")
		writer.writeheader()
		writer.writerows(events)
	tie_cycles = sum(1 for first, second in zip(events, events[1:])
			if first["reported_cycle"] == second["reported_cycle"] and first["event_type"] != second["event_type"])
	return {
		"path": output_path.name,
		"rows": len(events),
		"sha256": sha256(output_path.read_bytes()),
		"ordering": "ascending libgme-reported cycle; source sequence retained per stream",
		"cross_stream_same_cycle_order_known": False,
		"cross_stream_same_cycle_adjacent_pairs": tie_cycles,
		"dmc_time_warning": "DMC cycles are internal libgme buffer-refill callback times, not CPU DMA/bus-stall timestamps; do not use as WaveHi DMC hook timing.",
	}


def build_and_trace(output_dir: Path, source_dir: Path | None, cpu_cycles: int, cue_frame_offset: int,
		input_nsf: Path | None = None) -> dict:
	if not (TRACE_PROJECT / "trace_hooks.hpp").is_file():
		raise ValueError("Missing trace tool sources")
	output_dir.mkdir(parents=True, exist_ok=True)
	if input_nsf is not None:
		if cue_frame_offset:
			raise ValueError("--cue-frame-offset cannot be used with --input-nsf; supply a separately built candidate instead")
		nsf_target, nsf_info = _load_explicit_nsf(input_nsf)
		cue_offset_info = {"cue_frame_offset_ticks": 0, "cue_frame_patches": [], "mode": "explicit_nsf_input_no_rebuild"}
		event_schedule = nsf_info.get("event_derivation", nsf_info.get("event_frame_basis", "metadata not provided"))
	else:
		from build_opening_timeline_nsf import build

		nsf_target = output_dir / "opening_timeline_rom_driver.nsf"
		nsf_info = build(nsf_target)
		cue_offset_info = apply_cue_frame_offset(nsf_target, nsf_info, cue_frame_offset)
		event_schedule = nsf_info.get("event_derivation", nsf_info.get("event_frame_basis", "default FCEUX RAM $0700 event list"))
	nsf_bytes = nsf_target.read_bytes()

	with tempfile.TemporaryDirectory(prefix="ct2_apu_trace_") as tmp_name:
		work = Path(tmp_name)
		upstream, source_archive_hash = download_source(work, source_dir)
		unmodified_hashes = apply_instrumentation(upstream)
		shutil.copy2(TRACE_PROJECT / "trace_hooks.hpp", upstream / "gme/ct2_trace_hooks.hpp")
		project_copy = work / "trace_project"
		project_copy.mkdir()
		shutil.copy2(TRACE_PROJECT / "CMakeLists.txt", project_copy / "CMakeLists.txt")
		shutil.copy2(TRACE_PROJECT / "trace_hooks.hpp", project_copy / "trace_hooks.hpp")
		shutil.copy2(TRACE_PROJECT / "trace_main.cpp", project_copy / "trace_main.cpp")
		shutil.copy2(TRACE_PROJECT / "trace_hooks.cpp", project_copy / "trace_hooks.cpp")
		build_dir = work / "build"
		run_checked([
			"cmake", "-S", str(project_copy), "-B", str(build_dir),
			f"-DCT2_GME_SOURCE={upstream}", "-DCMAKE_BUILD_TYPE=Release",
		])
		run_checked(["cmake", "--build", str(build_dir), "--target", "ct2_libgme_apu_trace", "--parallel"])
		executable = build_dir / "ct2_libgme_apu_trace"
		if not executable.is_file():
			raise FileNotFoundError(f"Trace executable was not produced: {executable}")

		first_writes = work / "first_apu_writes.csv"
		first_plays = work / "first_play_calls.csv"
		first_dmc = work / "first_dmc_fetches.csv"
		second_writes = work / "second_apu_writes.csv"
		second_plays = work / "second_play_calls.csv"
		second_dmc = work / "second_dmc_fetches.csv"
		cycles_arg = str(cpu_cycles)
		for writes_path, plays_path, dmc_path in (
			(first_writes, first_plays, first_dmc),
			(second_writes, second_plays, second_dmc),
		):
			run_checked([str(executable), str(nsf_target), str(writes_path), str(plays_path), str(dmc_path), cycles_arg])
		if first_writes.read_bytes() != second_writes.read_bytes():
			raise RuntimeError("Cycle-stamped APU write trace is not deterministic")
		if first_plays.read_bytes() != second_plays.read_bytes():
			raise RuntimeError("NSF PLAY-call trace is not deterministic")
		if first_dmc.read_bytes() != second_dmc.read_bytes():
			raise RuntimeError("DMC sample fetch trace is not deterministic")
		shutil.copy2(first_writes, output_dir / "apu_writes.csv")
		shutil.copy2(first_plays, output_dir / "play_calls.csv")
		shutil.copy2(first_dmc, output_dir / "dmc_fetches.csv")
	apu_adapter = _write_renderer_apu_adapter(output_dir / "apu_writes.csv", output_dir / "wavehi_apu_writes_source_only.csv")
	ordered_events = _write_reported_cycle_merge(
		output_dir / "apu_writes.csv", output_dir / "dmc_fetches.csv", output_dir / "apu_dmc_events_by_reported_cycle.csv")

	apu_data = (output_dir / "apu_writes.csv").read_bytes()
	play_data = (output_dir / "play_calls.csv").read_bytes()
	dmc_data = (output_dir / "dmc_fetches.csv").read_bytes()
	apu_rows = [line for line in apu_data.decode("ascii").splitlines()[1:] if line]
	play_rows = [line for line in play_data.decode("ascii").splitlines()[1:] if line]
	dmc_rows = [line for line in dmc_data.decode("ascii").splitlines()[1:] if line]
	apu_addresses: dict[str, int] = {}
	dmc_register_writes = []
	last_apu_cycle = 0
	last_play_cycle = 0
	for line in apu_rows:
		sequence, absolute_cycle, local_cycle, address, value, origin = line.split(",")
		last_apu_cycle = int(absolute_cycle)
		address_int = int(address[1:], 16)
		key = f"0x{address_int:04X}"
		apu_addresses[key] = apu_addresses.get(key, 0) + 1
		if 0x4010 <= address_int <= 0x4013:
			dmc_register_writes.append({"sequence": int(sequence), "cycle": int(absolute_cycle), "address": key, "value": value})
	for line in play_rows:
		play_index, absolute_cycle, local_cycle = line.split(",")
		last_play_cycle = int(absolute_cycle)
	validation_pcm_sha256 = None
	if input_nsf is None:
		validation_pcm_sha256 = json.loads(REFERENCE_TIMING.read_text(encoding="utf-8"))["audio_capture"]["sha256"]

	return {
		"schema_version": 1,
		"purpose": "Trace exact CPU-cycle APU writes and libgme DMC sample reads while an instrumented libgme 0.6.5 build executes the ROM-derived NSF; validation/tooling only, no PCM asset is emitted.",
		"source_rom_sha256": nsf_info["source_rom_sha256"],
		"source_nsf_path": nsf_target.relative_to(ROOT).as_posix() if nsf_target.is_relative_to(ROOT) else str(nsf_target),
		"source_nsf_sha256": sha256(nsf_bytes),
		"input_mode": "explicit_candidate_nsf_no_builder_or_capture_event_read" if input_nsf is not None else "default_builder_capture_event_schedule",
		"input_nsf_sidecar_event_source": event_schedule,
		"cue_frame_offset_experiment": cue_offset_info,
		"libgme": {
			"version": GME_VERSION,
			"tag_commit": GME_TAG_COMMIT,
			"official_source_archive_sha256": source_archive_hash if source_dir is None else None,
			"source_input": "downloaded official archive; SHA-256 pinned and checked" if source_dir is None else "provided source tree; patched files byte-verified against pinned official tag",
			"upstream_source_file_sha256_before_instrumentation": unmodified_hashes,
			"instrumented_files": ["gme/Nsf_Emu.h", "gme/Nsf_Emu.cpp", "gme/nes_cpu_io.h", "gme/Nes_Oscs.h", "gme/Nes_Oscs.cpp"],
			"build": "temporary CMake static build; NSF only; shared library, examples, tests and unrelated music formats disabled",
		},
		"cycle_clock": {
			"region": "NTSC",
			"cpu_hz": NTSC_CPU_HZ,
			"trace_unit": "absolute 2A03 CPU cycles",
			"origin": "Nsf_Emu::start_track_ APU reset; its host-injected $4015/$4017 setup writes are explicit cycle-zero records; the first CPU INIT cycle follows at cycle zero",
			"local_to_absolute": "Nsf_Emu::run_clocks local cycle times are accumulated by the exact returned duration; sequence columns preserve ordering for equal-cycle writes",
		},
		"nsf_replay": {
			"cpu_cycles_advanced": cpu_cycles,
			"advance_method": "temporary Nsf_Emu::run_clocks entry point, called directly to an exact CPU-cycle horizon",
			"all_gme_voices_muted": True,
			"pcm_generated": False,
			"pcm_persisted": False,
			"observed_play_calls": len(play_rows),
			"last_apu_write_cycle": last_apu_cycle,
			"last_play_call_cycle": last_play_cycle,
			"event_schedule": event_schedule,
			"rom_source_driver": "Original supplied ROM PRG driver/data copied into an NSF wrapper; only the five hash-checked MMC3 bank-write instructions are replaced by the documented NSF trampoline.",
		},
		"outputs": {
			"apu_writes_csv": "apu_writes.csv",
			"apu_writes_sha256": sha256(apu_data),
			"play_calls_csv": "play_calls.csv",
			"play_calls_sha256": sha256(play_data),
			"dmc_fetches_csv": "dmc_fetches.csv",
			"dmc_fetches_sha256": sha256(dmc_data),
			"wavehi_apu_adapter": apu_adapter,
			"apu_dmc_reported_cycle_merge": ordered_events,
			"apu_write_count": len(apu_rows),
			"dmc_fetch_count": len(dmc_rows),
			"dmc_fetches_first_32": dmc_rows[:32],
			"writes_by_address": apu_addresses,
			"dmc_register_write_count": len(dmc_register_writes),
			"dmc_register_writes_first_32": dmc_register_writes[:32],
		},
		"limitations": [
			"The trace is from the NSF driver path, not the complete game ROM scheduler; explicit NSF event IDs/frames are accepted as supplied, and their producer's timing limitations remain unchanged.",
			"DMC fetch records are libgme's own DMC-buffer refill callbacks from Nes_Dmc::fill_buffer. Their reported internal times are not CPU bus-stall cycles or hardware-accurate DMA records; the merged CSV preserves these values without extrapolating them.",
			"Cross-stream APU-write/DMC-callback ordering for equal reported cycles is unknown; the merged CSV sorts by reported cycle and does not claim same-cycle execution order.",
			"The trace does not output WaveHi or PCM. It records source-derived APU writes and libgme DMC buffer reads only.",
			"6502 PC is omitted because Nes_Cpu::r is not maintained during a CPU run; exact register, value, cycle, and same-cycle write order are recorded.",
			"Cycle-stamped writes plus the ROM-mapped DPCM bytes, APU reset profile, and NTSC cycle clock are sufficient inputs in principle for an independent 2A03 APU state/mixer; they are not yet a validated WaveHi renderer.",
		],
		"determinism_check": {
			"independent_replays": 2,
			"apu_trace_identical": True,
			"play_trace_identical": True,
			"dmc_fetch_trace_identical": True,
		},
		"validation_reference": {
			"same_input_pcm_path": "reference/diagnostics/audio/fceux_cold_start_silent_pcm_precise_20261024.wav",
			"same_input_pcm_sha256": validation_pcm_sha256,
			"pcm_role": "comparison only; not read by the trace builder and not emitted as runtime audio",
			"pcm_metadata_read": input_nsf is None,
		},
	}


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--output-dir", type=Path, default=OUTPUT_DIR)
	parser.add_argument("--source-dir", type=Path, default=None, help="Optional clean libgme 0.6.5 source tree; it is copied before patching")
	parser.add_argument("--cpu-cycles", type=int, default=None, help="Exact 2A03 CPU-cycle horizon; default is the verified FCEUX opening endpoint")
	parser.add_argument("--cue-frame-offset", type=int, default=0, help="Diagnostic-only delay applied to every NSF cue event frame; default preserves source frames")
	parser.add_argument("--input-nsf", type=Path, default=None,
		help="Trace an explicit ROM-derived NSF with a matching .json sidecar; skips the capture-based event builder. Requires explicit --cpu-cycles.")
	args = parser.parse_args()

	if args.input_nsf is not None and args.cpu_cycles is None:
		parser.error("--input-nsf requires an explicit --cpu-cycles horizon so no capture-derived horizon is loaded")
	if args.input_nsf is None and args.cpu_cycles is None:
		timing = json.loads(REFERENCE_TIMING.read_text(encoding="utf-8"))
		cpu_cycles = int(timing["capture_frames"][DEFAULT_CYCLE_HORIZON])
	else:
		cpu_cycles = args.cpu_cycles
	if cpu_cycles <= 0 or cpu_cycles > 2_000_000_000:
		parser.error("--cpu-cycles must be between 1 and 2,000,000,000")
	if args.cue_frame_offset < 0:
		parser.error("--cue-frame-offset must be nonnegative")

	meta = build_and_trace(args.output_dir.resolve(), args.source_dir, cpu_cycles, args.cue_frame_offset, args.input_nsf)
	(args.output_dir.resolve() / "trace_meta.json").write_text(json.dumps(meta, indent=2) + "\n", encoding="utf-8")
	print(args.output_dir.resolve())


if __name__ == "__main__":
	main()
