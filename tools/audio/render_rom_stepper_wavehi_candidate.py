#!/usr/bin/env python3
"""Build a diagnostics-only WaveHi candidate from ROM-stepper APU/DMC events."""

from __future__ import annotations

import argparse
import csv
import gzip
import hashlib
import json
import subprocess
import tempfile
from pathlib import Path

from prototype_fceux_filter_pipeline import ROOT, fetch_coeffs


ROM_HASH = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
STEPPER_DIR = ROOT / "reference/diagnostics/audio/rom_only_source_cpu_ppu_dmc_full_start_4662_20261026"
INPUT_TIMELINE = ROOT / "reference/opening_reference_capture/input_timeline.csv"
RENDERER = ROOT / "tools/audio/fceux_apu_wavehi_prototype/apu_wavehi_renderer.cpp"
DEFAULT_ROM = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
DEFAULT_OUTPUT_DIR = ROOT / "reference/diagnostics/audio/rom_stepper_wavehi_source_only_candidate_20261026"
DEFAULT_EDGE_OUTPUT_DIR = ROOT / "reference/diagnostics/audio/rom_stepper_wavehi_source_edge_candidate_20261026"
OUTPUT_HASHES = {
	"source_apu_writes.csv": "ab2a3974887c6d9deec651547d79da0e85522f932fad84b1bd1b776656a06d81",
	"source_dmc_dma_reads.csv": "51eb73856d9e82b71777e5d2444ae0d99514fe962895520a3b90711b0989ad1a",
	"source_frame_cycles.csv": "46669a60de4bffca1cd4bea9ffdbbeae08239dd09a2eee7a41b5f1866457a6fc",
}


def sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def load_stepper_manifest(rom_path: Path, stepper_dir: Path = STEPPER_DIR) -> dict:
	manifest_path = stepper_dir / "source_stepper_report.json"
	manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
	if manifest.get("source_rom_sha256") != ROM_HASH or sha256(rom_path) != ROM_HASH:
		raise ValueError("ROM or stepper manifest hash does not match the supplied ROM")
	if "no FCEUX trace used as scheduler input" not in manifest.get("purpose", ""):
		raise ValueError("stepper report does not identify a source-only scheduler")
	for name, default_expected in OUTPUT_HASHES.items():
		path = stepper_dir / name
		expected = default_expected if stepper_dir.resolve() == STEPPER_DIR.resolve() else manifest.get("outputs", {}).get(name)
		if not expected:
			raise ValueError(f"stepper report is missing output hash: {name}")
		if sha256(path) != expected or manifest.get("outputs", {}).get(name) != expected:
			raise ValueError(f"stepper source output hash changed: {name}")
	input_path = ROOT / manifest["input_timeline_path"]
	if sha256(input_path) != manifest["input_timeline_sha256"]:
		raise ValueError("explicit input timeline changed since the source-stepper run")
	return manifest


def adapt_apu_writes(source_path: Path, destination: Path, max_source_frame: int | None = None) -> int:
	count = 0
	previous_cycle = -1
	with source_path.open(newline="", encoding="utf-8") as source, destination.open("w", newline="", encoding="utf-8") as output:
		reader = csv.DictReader(source)
		if reader.fieldnames != ["source_frame", "cycle", "frame_cycle", "pc", "address", "value"]:
			raise ValueError("unexpected source APU write schema")
			
		writer = csv.writer(output)
		writer.writerow(["frame", "hook", "frame_cycle", "cycle", "pc", "address", "value"])
		for row in reader:
			if max_source_frame is not None and int(row["source_frame"]) > max_source_frame:
				continue
			cycle = int(row["cycle"])
			if cycle < previous_cycle:
				raise ValueError("source APU write cycles are not monotonic")
			previous_cycle = cycle
			writer.writerow([row["source_frame"], "0", row["frame_cycle"], cycle, row["pc"], row["address"], row["value"]])
			count += 1
	return count


def adapt_frame_cycles(source_path: Path, destination: Path, max_source_frame: int | None = None) -> tuple[int, int, int]:
	count = 0
	first_cycle = 0
	last_cycle = 0
	with source_path.open(newline="", encoding="utf-8") as source, destination.open("w", newline="", encoding="utf-8") as output:
		reader = csv.DictReader(source)
		if reader.fieldnames != ["source_frame", "cycle_start", "cycle_end", "cycle_delta"]:
			raise ValueError("unexpected source frame-cycle schema")
		writer = csv.writer(output)
		writer.writerow(["frame", "reserved", "cycle_start", "cycle_end", "cycle_delta"])
		for row in reader:
			frame = int(row["source_frame"])
			if max_source_frame is not None and frame > max_source_frame:
				break
			start = int(row["cycle_start"])
			end = int(row["cycle_end"])
			delta = int(row["cycle_delta"])
			if end - start != delta or (count and start != last_cycle) or frame != count + 1:
				raise ValueError(f"inconsistent or non-contiguous source frame range at frame {frame}")
			if count == 0:
				first_cycle = start
			last_cycle = start
			writer.writerow([frame, "0", start, end, delta])
			count += 1
			last_cycle = end
	return count, first_cycle, last_cycle


def adapt_source_frame_updates(source_path: Path, destination: Path, max_source_frame: int | None = None) -> int:
	count = 0
	previous_cycle = -1
	with source_path.open(newline="", encoding="utf-8") as source, destination.open("w", newline="", encoding="utf-8") as output:
		reader = csv.DictReader(source)
		required = {"sequence", "source_frame", "cycle", "hook_cycles", "frame_mode"}
		if not reader.fieldnames or not required.issubset(reader.fieldnames):
			raise ValueError("source frame-update export is missing its hook-boundary fields")
		writer = csv.writer(output)
		writer.writerow(["sequence", "source_frame", "cycle"])
		for row in reader:
			frame = int(row["source_frame"])
			if max_source_frame is not None and frame > max_source_frame:
				break
			cycle = int(row["cycle"])
			if cycle <= previous_cycle:
				raise ValueError("source frame-update events are not strictly cycle ordered")
			if int(row["hook_cycles"]) <= 0 or int(row["frame_mode"]) not in (0, 1, 2, 3):
				raise ValueError(f"invalid source frame-update state at sequence {row['sequence']}")
			writer.writerow([row["sequence"], frame, cycle])
			previous_cycle = cycle
			count += 1
	if not count:
		raise ValueError("source frame-update export contains no events in the requested range")
	return count


def append_filter_tail_frames(path: Path, source_frames: int, tail_frames: int) -> dict | None:
	"""Append empty diagnostic frame intervals so the output filter can decay after ROM Stop."""
	if tail_frames <= 0:
		return None
	with path.open(newline="", encoding="utf-8") as source:
		rows = list(csv.DictReader(source))
	if len(rows) != source_frames or int(rows[-1]["frame"]) != source_frames:
		raise ValueError("cannot append filter tail to an unexpected source frame-cycle table")
	frame_delta = int(rows[-1]["cycle_delta"])
	cycle_end = int(rows[-1]["cycle_end"])
	if frame_delta <= 0 or int(rows[-1]["cycle_start"]) + frame_delta != cycle_end:
		raise ValueError("last source frame-cycle row is invalid")
	with path.open("a", newline="", encoding="utf-8") as output:
		writer = csv.writer(output)
		for index in range(1, tail_frames + 1):
			start = cycle_end
			cycle_end += frame_delta
			writer.writerow([source_frames + index, 0, start, cycle_end, frame_delta])
	return {
		"frames": tail_frames,
		"frame_delta_cycles": frame_delta,
		"cycle_range_inclusive_start_exclusive_end": [int(rows[-1]["cycle_end"]), cycle_end],
		"apu_writes_added": 0,
		"timing_basis": "repeats the final source frame-cycle delta after the frame-4662 source table; diagnostic filter decay only, not ROM-executed frame timing",
	}


def adapt_source_dmc_reads(source_path: Path, destination: Path, max_source_frame: int | None = None) -> tuple[int, int]:
	count = 0
	rows = 0
	fields = ("source_frame", "cycle", "address", "value", "index")
	with source_path.open(newline="", encoding="utf-8") as source, destination.open("w", newline="", encoding="utf-8") as output:
		reader = csv.DictReader(source)
		if not reader.fieldnames or not set(fields).issubset(reader.fieldnames):
			raise ValueError("unexpected source DMC DMA read schema")
		writer = csv.writer(output)
		writer.writerow(fields)
		for row in reader:
			if max_source_frame is not None and int(row["source_frame"]) > max_source_frame:
				break
			rows += 1
			if int(row["index"]) % 4 == 3:
				count += 1
			writer.writerow([row[key] for key in fields])
	return rows, count


def adapt_source_dmc_dac_edges(source_path: Path, destination: Path) -> tuple[int, int]:
	rows = 0
	edges = 0
	previous_cycle = -1
	with gzip.open(source_path, "rt", newline="", encoding="utf-8") as source, destination.open("w", newline="", encoding="utf-8") as output:
		reader = csv.DictReader(source)
		required = {"event", "source_frame", "edge_cycle", "raw_dac_before", "raw_dac", "dac_changed"}
		if not reader.fieldnames or not required.issubset(reader.fieldnames):
			raise ValueError("source DMC edge export is missing its bit-edge/DAC fields")
		writer = csv.writer(output)
		writer.writerow(["source_frame", "cycle", "raw_dac_before", "raw_dac"])
		for row in reader:
			if row["event"] != "DMC_BIT_EDGE":
				continue
			rows += 1
			if row["dac_changed"] != "1":
				continue
			cycle = int(row["edge_cycle"])
			before = int(row["raw_dac_before"])
			after = int(row["raw_dac"])
			if cycle <= previous_cycle:
				raise ValueError("source DMC DAC edge cycles are not strictly increasing")
			if before == after or not 0 <= before <= 127 or not 0 <= after <= 127:
				raise ValueError(f"invalid source DMC DAC edge at cycle {cycle}")
			writer.writerow([row["source_frame"], cycle, before, after])
			previous_cycle = cycle
			edges += 1
	if edges == 0:
		raise ValueError("source DMC event export contains no DAC-changing bit edges")
	return rows, edges


def adapt_source_dmc_state_events(source_path: Path, destination: Path) -> tuple[int, int]:
	retained = 0
	types = 0
	previous_sequence = -1
	previous_cycle = -1
	with gzip.open(source_path, "rt", newline="", encoding="utf-8") as source, destination.open("w", newline="", encoding="utf-8") as output:
		reader = csv.DictReader(source)
		required = {"sequence", "event", "source_frame", "cycle", "dmc_period", "dmc_acc", "dmc_bit_count", "dmc_addr", "dmc_size", "dmc_shift", "dmc_have_dma", "dmc_have_sample", "dmc_dma_buf", "raw_dac"}
		if not reader.fieldnames or not required.issubset(reader.fieldnames):
			raise ValueError("source DMC state export is missing its state fields")
		writer = csv.writer(output)
		writer.writerow(["sequence", "source_frame", "cycle", "accumulator", "period", "bit_count", "address", "size", "shift", "have_dma", "have_sample", "dma_buffer", "raw_dac"])
		for row in reader:
			if row["event"] not in {"DMC_BIT_EDGE", "DMC_BUFFER_LOAD"}:
				continue
			sequence = int(row["sequence"])
			cycle = int(row["cycle"])
			if sequence <= previous_sequence or cycle < previous_cycle:
				raise ValueError("source DMC state events are not in source event order")
			previous_sequence = sequence
			previous_cycle = cycle
			writer.writerow([
				sequence, row["source_frame"], cycle, row["dmc_acc"], row["dmc_period"],
				row["dmc_bit_count"], row["dmc_addr"], row["dmc_size"], row["dmc_shift"],
				row["dmc_have_dma"], row["dmc_have_sample"], row["dmc_dma_buf"], row["raw_dac"],
			])
			retained += 1
			types += row["event"] == "DMC_BIT_EDGE"
	if not retained:
		raise ValueError("source DMC state export contains no bit-edge or buffer-load events")
	return retained, types


def run(rom_path: Path, output_dir: Path, source_dmc_dac_events: Path | None = None,
		source_dmc_state_events: Path | None = None, max_source_frame: int | None = None,
		append_tail_frames: int = 0, stepper_dir: Path = STEPPER_DIR,
		source_frame_update_events: Path | None = None, channel_wavehi_raw: Path | None = None,
		channel_cycle_start: int | None = None, channel_cycle_end: int | None = None,
		triangle_state_trace: Path | None = None, triangle_cycle_start: int | None = None,
		triangle_cycle_end: int | None = None) -> dict:
	output_dir.mkdir(parents=True, exist_ok=True)
	stepper_dir = stepper_dir.resolve()
	manifest = load_stepper_manifest(rom_path, stepper_dir)
	if source_frame_update_events is not None:
		frame_export = manifest.get("source_frame_updates_export", {})
		if frame_export.get("used_fceux_timestamps_or_pcm_as_scheduler_input") is not False:
			raise ValueError("stepper report does not establish source-only frame-update event provenance")
		if frame_export.get("sha256") != sha256(source_frame_update_events.resolve()):
			raise ValueError("source frame-update events do not match the stepper report hash")
	if channel_wavehi_raw is None and (channel_cycle_start is not None or channel_cycle_end is not None):
		raise ValueError("source channel WaveHi cycle boundaries require an output path")
	if channel_wavehi_raw is not None and (channel_cycle_start is None or channel_cycle_end is None):
		raise ValueError("source channel WaveHi output requires both cycle boundaries")
	if channel_wavehi_raw is not None:
		if channel_cycle_end <= channel_cycle_start:
			raise ValueError("source channel WaveHi cycle window must be nonempty")
		channel_wavehi_raw = channel_wavehi_raw.resolve()
		channel_wavehi_raw.parent.mkdir(parents=True, exist_ok=True)
	if triangle_state_trace is None and (triangle_cycle_start is not None or triangle_cycle_end is not None):
		raise ValueError("source triangle state cycle boundaries require an output path")
	if triangle_state_trace is not None and (triangle_cycle_start is None or triangle_cycle_end is None):
		raise ValueError("source triangle state trace output requires both cycle boundaries")
	if triangle_state_trace is not None:
		if triangle_cycle_end <= triangle_cycle_start:
			raise ValueError("source triangle state trace cycle window must be nonempty")
		triangle_state_trace = triangle_state_trace.resolve()
		triangle_state_trace.parent.mkdir(parents=True, exist_ok=True)
	apu_adapter = output_dir / "renderer_apu_writes.csv"
	frame_adapter = output_dir / "renderer_frame_cycles.csv"
	dmc_output = output_dir / "rendered_dmc_fetches.csv"
	dac_edge_adapter = output_dir / "renderer_source_dmc_dac_edges.csv"
	state_event_adapter = output_dir / "renderer_source_dmc_state_events.csv"
	frame_update_adapter = output_dir / "renderer_source_frame_updates.csv"
	dmc_read_adapter = output_dir / "renderer_source_dmc_dma_reads.csv"
	wav_path = output_dir / "rom_stepper_wavehi_candidate.wav"
	apus = adapt_apu_writes(stepper_dir / "source_apu_writes.csv", apu_adapter, max_source_frame)
	frames, first_cycle, last_cycle = adapt_frame_cycles(stepper_dir / "source_frame_cycles.csv", frame_adapter, max_source_frame)
	tail = append_filter_tail_frames(frame_adapter, frames, append_tail_frames)
	dmc_rows, accepted_dmc_bytes = adapt_source_dmc_reads(stepper_dir / "source_dmc_dma_reads.csv", dmc_read_adapter, max_source_frame)
	stepper_bit_edges = None
	stepper_dac_edges = None
	if source_dmc_dac_events is not None:
		stepper_bit_edges, stepper_dac_edges = adapt_source_dmc_dac_edges(source_dmc_dac_events, dac_edge_adapter)
	state_event_count = None
	state_bit_edge_count = None
	if source_dmc_state_events is not None:
		state_event_count, state_bit_edge_count = adapt_source_dmc_state_events(source_dmc_state_events, state_event_adapter)
	frame_update_count = None
	if source_frame_update_events is not None:
		frame_update_count = adapt_source_frame_updates(source_frame_update_events, frame_update_adapter, max_source_frame)
	expected_frames = int(manifest.get("source_frames_advanced", 4662)) if max_source_frame is None else max_source_frame
	if frames != expected_frames:
		raise ValueError(f"source frame count differs from requested {expected_frames}-frame render")
	if max_source_frame is None and accepted_dmc_bytes != manifest.get("dmc_dma_output_bytes"):
		raise ValueError("accepted source DMC read count differs from the stepper report")
	if first_cycle != 0 or (max_source_frame is None and last_cycle != manifest.get("source_cpu_cycles")):
		raise ValueError("source frame-cycle coverage does not span the requested source run")
	stop = manifest.get("title_stop_markers", [])
	if len(stop) != 1 or stop[0].get("source_frame") != 4661 or stop[0].get("pc") != "$8048":
		raise ValueError("source run does not contain the expected title-stop marker")

	with tempfile.TemporaryDirectory(prefix="ct2_rom_stepper_wavehi_") as temporary:
		work = Path(temporary)
		_, fetched_hashes = fetch_coeffs(work)
		binary = work / "apu_wavehi_renderer"
		subprocess.run([
			"clang++", "-std=c++17", "-O3", "-DNDEBUG", "-Wall", "-Wextra", "-Wno-unused-function",
			"-I", str(work), str(RENDERER), "-o", str(binary),
		], check=True)
		command = [
			str(binary), str(apu_adapter), str(frame_adapter), "-", str(rom_path), str(wav_path),
			"--source-dmc-read-replay", str(dmc_read_adapter.resolve()),
			"--source-dmc-fetches", str(dmc_output),
		]
		if source_frame_update_events is None:
			command.append("--source-frame-sequencer")
		else:
			command.extend(["--source-frame-update-events", str(frame_update_adapter)])
		if channel_wavehi_raw is not None:
			command.extend([
				"--channel-wavehi-raw", str(channel_wavehi_raw),
				"--channel-cycle-start", str(channel_cycle_start),
				"--channel-cycle-end", str(channel_cycle_end),
			])
		if triangle_state_trace is not None:
			command.extend([
				"--triangle-state-trace", str(triangle_state_trace),
				"--triangle-cycle-start", str(triangle_cycle_start),
				"--triangle-cycle-end", str(triangle_cycle_end),
			])
		if source_dmc_dac_events is not None:
			command.extend(["--source-dmc-dac-edges", str(dac_edge_adapter)])
		if source_dmc_state_events is not None:
			command.extend(["--source-dmc-state-events", str(state_event_adapter)])
		completed = subprocess.run(command, check=False, capture_output=True, text=True)
		if completed.returncode != 0:
			raise RuntimeError(f"WaveHi candidate renderer failed ({completed.returncode}): {completed.stderr.strip()}")
	stdout_fields = dict(line.split("=", 1) for line in completed.stdout.splitlines() if "=" in line)
	overrun_cycles = [int(value) for value in stdout_fields.get("source_dmc_buffer_overrun_cycles", "").split(",") if value]

	report = {
		"purpose": "Diagnostic-only source-ROM/CPU-stepper to WaveHi PCM candidate; not a runtime asset and not claimed to match NES/FCEUX audio.",
		"source": {
			"rom_sha256": ROM_HASH,
			"stepper_report": (stepper_dir / "source_stepper_report.json").relative_to(ROOT).as_posix(),
			"stepper_output_sha256": {name: sha256(stepper_dir / name) for name in OUTPUT_HASHES},
			"explicit_controller_input_timeline": {
				"path": manifest["input_timeline_path"],
				"sha256": manifest["input_timeline_sha256"],
				"role": "input to source CPU execution only; not audio event timing or PCM",
			},
			"fceux_trace_used_for_scheduling": False,
			"captured_pcm_or_wav_used_as_synthesis_input": False,
		},
		"source_events": {
			"apu_writes": apus,
			"dmc_raw_four_cycle_read_rows": dmc_rows,
			"accepted_dmc_sample_bytes": accepted_dmc_bytes,
			"frame_rows": frames,
			"rendered_through_source_frame": frames,
			"cycle_range_inclusive_start_exclusive_end": [first_cycle, last_cycle],
			"post_stop_filter_tail": tail,
			"source_channel_wavehi_raw": None if channel_wavehi_raw is None else {
				"path": channel_wavehi_raw.relative_to(ROOT).as_posix(),
				"sha256": sha256(channel_wavehi_raw),
				"rows": int(stdout_fields.get("source_channel_wavehi_rows", "0")),
				"cycle_range_inclusive_start_exclusive_end": [channel_cycle_start, channel_cycle_end],
				"binary_record_format": "little-endian uint64 absolute CPU cycle; int32 raw contributions pulse1,pulse2,triangle,noise,DMC; uint32 pre-mixer WaveHi; 32 bytes per record",
				"used_fceux_trace_or_pcm_as_synthesis_input": False,
			},
			"source_triangle_state_trace": None if triangle_state_trace is None else {
				"path": triangle_state_trace.relative_to(ROOT).as_posix(),
				"sha256": sha256(triangle_state_trace),
				"rows": sum(1 for _ in triangle_state_trace.open(encoding="utf-8")) - 1,
				"cycle_range_inclusive_start_exclusive_end": [triangle_cycle_start, triangle_cycle_end],
				"fields": ["ROM-stepper triangle step/timer/length/linear-counter/register state at flushes and timer expirations"],
				"used_fceux_trace_or_pcm_as_synthesis_input": False,
			},
			"source_frame_update_events": None if source_frame_update_events is None else {
				"path": source_frame_update_events.resolve().relative_to(ROOT).as_posix(),
				"sha256": sha256(source_frame_update_events.resolve()),
				"hook_boundary_events_replayed": frame_update_count,
				"adapter_sha256": sha256(frame_update_adapter),
				"timing_field_used": "cycle from the ROM-only CPU instruction-hook stepper",
			},
			"title_stop_source_frame": stop[0]["source_frame"],
			"source_dmc_dac_edge_export": None if source_dmc_dac_events is None else {
				"path": source_dmc_dac_events.resolve().relative_to(ROOT).as_posix(),
				"sha256": sha256(source_dmc_dac_events.resolve()),
				"bit_edges_in_export": stepper_bit_edges,
				"dac_changing_edges_replayed": stepper_dac_edges,
				"cycle_field_used": "edge_cycle",
				"adapter_sha256": sha256(dac_edge_adapter),
			},
			"source_dmc_state_corrections": None if source_dmc_state_events is None else {
				"path": source_dmc_state_events.resolve().relative_to(ROOT).as_posix(),
				"sha256": sha256(source_dmc_state_events.resolve()),
				"retained_bit_edge_and_buffer_load_rows": state_event_count,
				"bit_edge_rows": state_bit_edge_count,
				"timestamp_field_used": "cycle (source hook cycle; same-input FCEUX match validated through frame 380)",
				"adapter_sha256": sha256(state_event_adapter),
			},
			"renderer_dmc_buffer_phase_conflicts": {
				"count": int(stdout_fields.get("source_dmc_buffer_overruns", "0")),
				"cycles": overrun_cycles,
				"meaning": "at these ROM-stepper reads, the independently modeled WaveHi DMC bit phase still marked its prior byte buffered; the renderer accepted the source byte and recorded the conflict",
			},
		},
		"renderer": {
			"source": RENDERER.relative_to(ROOT).as_posix(),
			"source_sha256": sha256(RENDERER),
			"pinned_filter_coefficients_sha256": fetched_hashes,
			"command": [arg if arg != str(rom_path) else "<supplied ROM>" for arg in command],
			"stdout": completed.stdout.strip(),
			"modeled_channels": ["pulse 1", "pulse 2", "triangle", "noise", "DMC"],
			"frame_sequencer": ("ROM $4017 register writes plus ROM-stepper instruction-hook frame-update events" if source_frame_update_events is not None else "ROM $4017 register writes plus fixed-point per-CPU-cycle countdown"),
			"dmc_fetch_input": "accepted byte reads (index 3 of each source-stepper four-cycle read group), address/value checked against ROM PRG bank $1E and APU DMC registers",
			"dmc_bit_timer_and_dac": "ROM-stepper DMC bit-edge state corrections at supplied source hook cycles when --source-dmc-state-events is supplied; otherwise renderer per-CPU-cycle model",
			"filter": "pinned FCEUX WaveHi and SexyFilter implementation, used as an offline output transform",
		},
		"candidate": {
			"path": wav_path.relative_to(ROOT).as_posix(),
			"sha256": sha256(wav_path),
			"samples_44100_hz": (wav_path.stat().st_size - 44) // 2,
			"runtime_asset": False,
		},
		"limitations": [
			"The DMC read addresses, bytes and CPU cycles are generated by the ROM-only stepper, but its DMA arbitration/CPU-cycle semantics are still diagnostics-only.",
			("DMC bit-timer/DAC state is corrected at the exported source event cycles; source-hook timing has been directly checked against FCEUX only through frame 380, and DMA arbitration remains diagnostic." if source_dmc_state_events is not None else "The WaveHi renderer's DMC bit timer and DAC phase are modeled each CPU cycle with assumed initial phase; they are not derived from a complete 2A03 execution trace."),
			(f"In this {frames}-frame run, {len(overrun_cycles)} source DMC read buffer-phase conflicts remained after applying the supplied state corrections; cycles are listed in `source_events.renderer_dmc_buffer_phase_conflicts`." if source_dmc_state_events is not None else f"At {len(overrun_cycles)} source DMC reads, the renderer's modeled sample-buffer phase disagreed with the source-stepper read schedule; those bytes were retained and the cycles are listed in `source_events.renderer_dmc_buffer_phase_conflicts`."),
			("Frame-sequencer updates use ROM-stepper hook-boundary cycle events; FCEUX comparison is validation only and does not supply the synthesis schedule." if source_frame_update_events is not None else "The frame-sequencer fixed-point threshold is checked per modeled CPU cycle, not at the original instruction hook boundary."),
			("An optional post-Stop filter tail was appended as empty APU frame intervals; its duration repeats the last source frame-cycle delta and is a diagnostic extrapolation, not ROM-executed timing." if tail is not None else "The final stop/tail length comes from the modeled source frame range; no FCEUX stop tail or captured audio samples are injected."),
			"No waveform parity is established. This candidate must not replace the shipped production WAV.",
		],
	}
	(output_dir / "candidate_report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
	(output_dir / "README.md").write_text(
		"# ROM-stepper WaveHi candidate\n\n"
		"This offline diagnostic WAV is synthesized from the supplied ROM, the ROM CPU/PPU/DMC stepper's APU writes, frame-cycle ranges, and DMC byte-read events. It does not read FCEUX APU/DMC timestamps, emulator screenshots, or captured PCM/WAV data. The explicit controller timeline is used only to drive the source CPU execution.\n\n"
		"The renderer verifies every accepted DMC byte against bank `$1E` and the DMC address/length state reconstructed from source APU writes. DMC bit timer/DAC and frame-sequencer timing are diagnostic models or source-stepper event replays as recorded in `candidate_report.json`; PCM comparison is validation only. This is not a verified audio match or runtime asset. The existing production WAV and manifest are unchanged.\n",
		encoding="utf-8",
	)
	return report


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--rom", type=Path, default=DEFAULT_ROM)
	parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
	parser.add_argument("--source-dmc-dac-events", type=Path, default=None,
		help="gzip-compressed ROM-stepper event CSV; replay its DMC_BIT_EDGE DAC changes at edge_cycle")
	parser.add_argument("--source-dmc-state-events", type=Path, default=None,
		help="gzip-compressed ROM-stepper event CSV; apply DMC_BIT_EDGE and DMC_BUFFER_LOAD state corrections at source hook cycles")
	parser.add_argument("--source-frame-update-events", type=Path, default=None,
		help="ROM-only CPU-stepper CSV; replay frame-sequencer updates at source instruction-hook cycles")
	parser.add_argument("--channel-wavehi-raw", type=Path, default=None,
		help="optional diagnostics-only binary export of ROM-renderer per-channel WaveHi contributions")
	parser.add_argument("--channel-cycle-start", type=int, default=None,
		help="inclusive absolute source CPU-cycle start for the per-channel WaveHi export")
	parser.add_argument("--channel-cycle-end", type=int, default=None,
		help="exclusive absolute source CPU-cycle end for the per-channel WaveHi export")
	parser.add_argument("--triangle-state-trace", type=Path, default=None,
		help="optional diagnostic CSV of source triangle phase/timer/length state at flushes and timer expirations")
	parser.add_argument("--triangle-cycle-start", type=int, default=None,
		help="inclusive absolute source CPU-cycle start for the triangle state export")
	parser.add_argument("--triangle-cycle-end", type=int, default=None,
		help="exclusive absolute source CPU-cycle end for the triangle state export")
	parser.add_argument("--max-source-frame", type=int, default=None,
		help="render only source frames 1..N from the full stepper outputs (diagnostic window work)")
	parser.add_argument("--append-filter-tail-frames", type=int, default=0,
		help="append empty diagnostic APU frame intervals after source Stop so the WaveHi filter can decay")
	parser.add_argument("--stepper-dir", type=Path, default=STEPPER_DIR,
		help="source CPU-stepper output folder; defaults to the retained 4662-frame run")
	args = parser.parse_args()
	if args.append_filter_tail_frames < 0:
		parser.error("--append-filter-tail-frames must be nonnegative")
	if args.source_dmc_dac_events is not None and args.output_dir == DEFAULT_OUTPUT_DIR:
		args.output_dir = DEFAULT_EDGE_OUTPUT_DIR
	report = run(args.rom.resolve(), args.output_dir.resolve(), args.source_dmc_dac_events,
		args.source_dmc_state_events, args.max_source_frame, args.append_filter_tail_frames, args.stepper_dir,
		args.source_frame_update_events, args.channel_wavehi_raw,
		args.channel_cycle_start, args.channel_cycle_end, args.triangle_state_trace,
		args.triangle_cycle_start, args.triangle_cycle_end)
	print(report["candidate"]["path"])


if __name__ == "__main__":
	main()
