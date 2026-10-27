#!/usr/bin/env python3
"""Validate live ROM-presenter nametable reads against FCEUX evidence."""

from __future__ import annotations

import csv
import json
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "reference/diagnostics/shared_sprite_fetch_override_20261026"
LIVE_PATH = OUT_DIR / "live_nametable_pixel_candidates.json"
TRACE_DIR = ROOT / "reference/diagnostics/oam_all_residual_trace_20261026"
PPU_SNAPSHOT_DIR = ROOT / "reference/opening_timing_capture_20261024_125300/ppu_states"
GODOT_DIR = ROOT / "reference/diagnostics/opening_runtime_full_20261026_packed_rows"
FCEUX_INDEX = ROOT / "reference/opening_full_frame_capture_20261025_101014/screen_index.csv"
RGB_PALETTE_PATH = ROOT / "reference/palettes/FCEUX_internal_default_2.7.0_rgb.pal"

sys.path.insert(0, str(ROOT / "tools"))
from compare_rom_intro_frames import gd_rgb, png_rgb  # noqa: E402


def read_csv(path: Path) -> list[dict[str, str]]:
	with path.open(newline="", encoding="utf-8") as stream:
		return list(csv.DictReader(stream))


def hex_byte(value: str) -> int:
	return int(value.replace("$", "").replace("0x", ""), 16)


def screen_path(frame: int) -> Path:
	for row in read_csv(FCEUX_INDEX):
		if int(row["source_frame"]) != frame:
			continue
		path = FCEUX_INDEX.parent / row["raw_screen_file"]
		if not path.is_file():
			path = FCEUX_INDEX.parent / "unique_screens" / row["raw_screen_file"]
		return path
	raise FileNotFoundError(f"No FCEUX screen index row for frame {frame}")


def rgb_at(data: bytes, x: int, y: int) -> tuple[int, int, int]:
	start = (y * 256 + x) * 3
	return tuple(data[start:start + 3])


def nes_rgb(palette: bytes, color: int) -> tuple[int, int, int]:
	start = (color & 0x3F) * 3
	return tuple(palette[start:start + 3])


def main() -> None:
	live = json.loads(LIVE_PATH.read_text(encoding="utf-8"))
	causal_rows = read_csv(TRACE_DIR / "residual_pixel_causal_attribution.csv")
	write_rows = read_csv(TRACE_DIR / "ppu2006_writes.csv")
	plane_rows = read_csv(TRACE_DIR / "sprite_plane_reads.csv")
	final_rows = read_csv(TRACE_DIR / "final_pixels.csv")
	write_by_frame: dict[int, list[dict[str, str]]] = {}
	for row in write_rows:
		write_by_frame.setdefault(int(row["movie_frame"]), []).append(row)
	final_by_point = {
		(int(row["movie_frame"]), int(row["output_x"]), int(row["output_y"])): row
		for row in final_rows
	}
	causal_by_point = {
		(int(row["frame"]), int(row["x"]), int(row["y"])): row
		for row in causal_rows
	}
	palette = RGB_PALETTE_PATH.read_bytes()
	plane1_snapshot_matches = 0
	plane1_trace_matches = 0
	plane1_masked_address_matches = 0
	full_event_matches = 0
	pattern_index_changes = 0
	pattern_after_counts: Counter[int] = Counter()
	selected_sprite_match = 0
	transparent_fallback_match = 0
	selected_sprite_rgb_match = 0
	current_rgb_counts: Counter[tuple[int, int, int]] = Counter()
	expected_rgb_counts: Counter[tuple[int, int, int]] = Counter()
	pairs: Counter[tuple[tuple[int, int, int], tuple[int, int, int]]] = Counter()
	rows_out: list[dict] = []

	for frame_record in live["frames"]:
		frame = int(frame_record["source_frame"])
		address = hex_byte(frame_record["plane1_full_address_after_plus_8"])
		live_byte = hex_byte(frame_record["live_source_nametable_byte"])
		assert 0x2000 <= address < 0x3000, (frame, address)
		assert frame_record["temp_addr_after_low_write"] in ("0x2200", "0x21C0")

		frame_writes = write_by_frame[frame]
		low_pred = next(item for item in frame_record["rom_only_writes"] if item["pc"] == "$A178")
		low_trace = [row for row in frame_writes
			if int(row["scanline"]) == int(low_pred["scanline"])
			and int(row["dot"]) == int(low_pred["dot"])
			and hex_byte(row["value"]) == hex_byte(low_pred["value"])
			and row["writer_pc_assuming_sta_abs"] == "$A178"]
		if len(low_trace) != 1:
			raise AssertionError(f"Source-only low store failed FCEUX validation: frame {frame}")
		full_event_matches += 1
		trace_low = low_trace[0]
		if ((hex_byte(trace_low["refresh_after"]) + 8) & 0x3FFF) != address:
			raise AssertionError(f"Full address mismatch at frame {frame}")

		ppu_snapshot = (PPU_SNAPSHOT_DIR / f"ppu_{frame:05d}.bin").read_bytes()
		if len(ppu_snapshot) != 0x4000:
			raise AssertionError(f"Unexpected PPU snapshot size for frame {frame}: {len(ppu_snapshot)}")
		snapshot_byte = ppu_snapshot[address]
		if snapshot_byte != live_byte:
			raise AssertionError(f"Live source PPU memory differs from snapshot at frame {frame}, ${address:04X}: {live_byte:02X}!={snapshot_byte:02X}")

		for pixel in frame_record["pixels"]:
			x, y = map(int, pixel["screen_position"])
			target = causal_by_point[(frame, x, y)]
			slot = int(pixel["oam_slot"])
			read_matches = [row for row in plane_rows
				if int(row["movie_frame"]) == frame
				and int(row["output_y"]) == y - 1
				and int(row["oam_index"]) == slot
				and int(row["plane"]) == 1
				and int(row["dot"]) == int(low_pred["dot"])]
			if len(read_matches) != 1:
				raise AssertionError(f"Missing unique FCEUX plane-1 read for {(frame,x,y,slot)}")
			plane1 = read_matches[0]
			if hex_byte(plane1["ppu_data"]) != snapshot_byte:
				raise AssertionError(f"PPU snapshot byte differs from returned FCEUX bus data at {(frame,x,y)}")
			plane1_snapshot_matches += 1
			plane1_trace_matches += 1
			if hex_byte(plane1["ppu_addr"]) != (address & 0x1FFF):
				raise AssertionError(f"Instrumented low 13-bit address mismatch at {(frame,x,y)}")
			plane1_masked_address_matches += 1

			final = final_by_point[(frame, x, y)]
			before_index, after_index = map(int, pixel["pattern_pixel_index_before_after"])
			if before_index != after_index:
				pattern_index_changes += 1
			pattern_after_counts[after_index] += 1
			selected_slot = int(final["selected_oam_index"])
			selected_pixel = int(final["selected_spixel"])
			if after_index == 0:
				if selected_slot == slot:
					raise AssertionError(f"Transparent source prediction still selected slot {slot} at {(frame,x,y)}")
				transparent_fallback_match += 1
				composition_status = "affected sprite becomes transparent; another sprite/background is exposed"
			else:
				if selected_slot != slot or selected_pixel != after_index:
					raise AssertionError(f"Source pixel prediction differs from selected FCEUX sprite at {(frame,x,y)}")
				selected_sprite_match += 1
				composition_status = "affected sprite remains selected with predicted index"

			current_image = png_rgb(GODOT_DIR / f"frame_{frame:06d}.png")
			reference_image = gd_rgb(screen_path(frame))
			current_rgb = rgb_at(current_image, x, y)
			expected_rgb = rgb_at(reference_image, x, y)
			current_rgb_counts[current_rgb] += 1
			expected_rgb_counts[expected_rgb] += 1
			pairs[(expected_rgb, current_rgb)] += 1
			final_palette_rgb = nes_rgb(palette, hex_byte(final["pixelcolor_before_adjust"]))
			if final_palette_rgb != expected_rgb:
				raise AssertionError(f"FCEUX final palette byte does not map to screenshot at {(frame,x,y)}")
			candidate_sprite_rgb = pixel["replacement_sprite_rgb"]
			if after_index > 0:
				candidate_rgb_tuple = tuple(candidate_sprite_rgb)
				if candidate_rgb_tuple != expected_rgb:
					raise AssertionError(f"ROM-derived source palette differs from expected visible pixel at {(frame,x,y)}")
				selected_sprite_rgb_match += 1

			rows_out.append({
				"frame": frame,
				"screen_x": x,
				"screen_y": y,
				"full_ppu_fetch_address": f"0x{address:04X}",
				"live_ppu_memory_byte": f"0x{live_byte:02X}",
				"snapshot_byte": f"0x{snapshot_byte:02X}",
				"trace_returned_byte": plane1["ppu_data"],
				"trace_masked_address": plane1["ppu_addr"],
				"trace_chr_bank_offset_labels_valid": False,
				"sprite_oam_slot": slot,
				"pattern_index_before": before_index,
				"pattern_index_after": after_index,
				"composition_validation": composition_status,
				"expected_fceux_rgb": list(expected_rgb),
				"current_godot_rgb": list(current_rgb),
				"source_palette_sprite_rgb": candidate_sprite_rgb,
			})

	if len(rows_out) != 45:
		raise AssertionError(f"Expected 45 validation pixels, found {len(rows_out)}")
	OUT_DIR.mkdir(parents=True, exist_ok=True)
	with (OUT_DIR / "pixel_nametable_override_validation.csv").open("w", newline="", encoding="utf-8") as stream:
		writer = csv.DictWriter(stream, fieldnames=list(rows_out[0]))
		writer.writeheader()
		writer.writerows(rows_out)

	def color_counts(counts: Counter[tuple[int, int, int]]) -> list[dict]:
		return [{"rgb": list(color), "count": count} for color, count in sorted(counts.items())]

	result = {
		"source_schedule_and_event_validation": {
			"source_only_low_store_events_compared": full_event_matches,
			"source_live_nametable_byte_matches_16k_ppu_snapshot": plane1_snapshot_matches,
			"snapshot_byte_matches_fceux_returned_bus_data": plane1_trace_matches,
			"masked_trace_address_matches_full_address_low_13_bits": plane1_masked_address_matches,
			"full_address_region": "all `$2208` or `$21C8` (nametable space, not CHR)",
			"live_memory_explicit_keys": sum(1 for frame in live["frames"] if frame["live_ppu_memory_has_explicit_key"]),
			"live_memory_zero_default_frames": sum(1 for frame in live["frames"] if not frame["live_ppu_memory_has_explicit_key"]),
			"live_memory_zero_default_pixels": sum(1 for frame in live["frames"] if not frame["live_ppu_memory_has_explicit_key"] for _pixel in frame["pixels"]),
			"live_lookup_equals_snapshot_for_every_pixel": True,
		},
		"pixel_model_validation": {
			"pixels": len(rows_out),
			"pattern_index_changed": pattern_index_changes,
			"pattern_index_after_counts": {str(index): count for index, count in sorted(pattern_after_counts.items())},
			"same_sprite_selected_with_expected_index": selected_sprite_match,
			"transparent_fallback_composition_matches": transparent_fallback_match,
			"same_sprite_candidate_rgb_matches_fceux": selected_sprite_rgb_match,
			"current_pixels_differ_from_fceux": sum(count for (expected, current), count in pairs.items() if expected != current),
			"expected_fceux_rgb_counts": color_counts(expected_rgb_counts),
			"current_godot_rgb_counts": color_counts(current_rgb_counts),
		},
		"chr_trace_labels": {
			"interpretation": "The instrumentation calls CALL_PPUREAD with full RefreshAddr, then masks the logged address to $1FFF before computing CHR offset/bank. Since the full addresses are >=$2000, returned data comes from vnapage/nametable memory and the logged CHR bank/offset labels are invalid for these reads.",
			"unresolved_chr_label_rows": 45,
			"specific_raw_chr_offset_mismatches": 5,
		},
		"standalone_pixel_comparison_path": "pixel_nametable_override_validation.csv",
		"full_frame_candidate_generated": False,
		"preservation_of_4675_exact_visible_frames_verified": False,
		"runtime_code_modified": False,
	}
	(OUT_DIR / "nametable_override_validation_summary.json").write_text(
		json.dumps(result, indent=2) + "\n", encoding="utf-8")
	print(json.dumps(result, indent=2))


if __name__ == "__main__":
	main()
