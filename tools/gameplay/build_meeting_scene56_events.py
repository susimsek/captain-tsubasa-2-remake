#!/usr/bin/env python3
"""Build the ROM-indexed scene $56 branch and its shared scene-$58 tail."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

from build_kickoff_cutscene_events import EXPECTED_ROM_SHA256, decode


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
DATA_DIR = ROOT / "reference/rom_extract/gameplay/meeting_menu"
OUTPUT_DIR = ROOT / "assets/gameplay/rom_logic"

MENU_CALLER_FILE = 0x0026D4  # Bank 1 CPU $A6C4.
KICKOFF_TABLE_FILE = 0x00342B  # Bank 1 CPU $B41B.
SCENE_POINTER_TABLE_FILE = 0x00A058  # Bank 5 CPU $A048, scene $44 base.
ENTRY_CPU = 0xBFBA
ENTRY_FILE = 0x00BFCA
ENTRY_LENGTH = 10
TAIL_CPU = 0xBFD5
TAIL_FILE = 0x00BFE5
TAIL_LENGTH = 0x1F


def sha256(data: bytes) -> str:
	return hashlib.sha256(data).hexdigest()


def main() -> None:
	rom = ROM_PATH.read_bytes()
	if sha256(rom) != EXPECTED_ROM_SHA256:
		raise SystemExit("Supplied ROM SHA-256 mismatch.")

	# $A6C4: LDX $26; LDA $B41B,X; JSR $8464.
	if rom[MENU_CALLER_FILE:MENU_CALLER_FILE + 8] != bytes.fromhex("a6 26 bd 1b b4 20 64 84"):
		raise SystemExit("The menu no longer directly dispatches tbl_B41B[match].")
	if rom[KICKOFF_TABLE_FILE] != 0x56:
		raise SystemExit("Fresh-match tbl_B41B[0] is not scene $56 in this ROM.")

	entry_pointer_file = SCENE_POINTER_TABLE_FILE + (0x56 - 0x44) * 2
	tail_pointer_file = SCENE_POINTER_TABLE_FILE + (0x58 - 0x44) * 2
	if int.from_bytes(rom[entry_pointer_file:entry_pointer_file + 2], "little") != ENTRY_CPU:
		raise SystemExit("Bank-$05 scene-$56 pointer no longer resolves to $BFBA.")
	if int.from_bytes(rom[tail_pointer_file:tail_pointer_file + 2], "little") != 0xBFCE:
		raise SystemExit("Bank-$05 scene-$58 pointer no longer resolves to $BFCE.")

	entry = rom[ENTRY_FILE:ENTRY_FILE + ENTRY_LENGTH]
	tail = rom[TAIL_FILE:TAIL_FILE + TAIL_LENGTH]
	if entry != bytes.fromhex("f1 02 fa 0f fb 01 0c fe d5 bf"):
		raise SystemExit("Scene-$56 command prefix differs from the supplied ROM.")
	if tail[:2] != bytes.fromhex("ed 31") or tail[-4:] != bytes.fromhex("ed 01 ea ff"):
		raise SystemExit("Scene-$56 shared tail does not preserve its live queue/exit commands.")
	if int.from_bytes(entry[-2:], "little") != TAIL_CPU:
		raise SystemExit("Scene-$56 FE branch does not point to the preserved shared tail.")

	execution_stream = entry + tail
	events = decode(execution_stream, ENTRY_CPU, ENTRY_FILE)
	for event in events:
		offset = int(event["script_offset"])
		if offset >= ENTRY_LENGTH:
			segment_offset = offset - ENTRY_LENGTH
			event["cpu_address"] = TAIL_CPU + segment_offset
			event["file_offset"] = TAIL_FILE + segment_offset
			event["source_segment_index"] = 1
		else:
			event["source_segment_index"] = 0

	entry_resource = DATA_DIR / "bank5_meeting_start_scene_56_entry.bin"
	tail_resource = DATA_DIR / "bank5_scene_58_shared_tail_BFD5_BFF4.bin"
	execution_resource = DATA_DIR / "scene_56_execution.bin"
	entry_resource.write_bytes(entry)
	tail_resource.write_bytes(tail)
	execution_resource.write_bytes(execution_stream)
	root_manifest_path = DATA_DIR / "manifest.json"
	root_manifest = json.loads(root_manifest_path.read_text(encoding="utf-8"))
	new_source_files = [
		{
			"file": entry_resource.name,
			"description": "Scene $56 entry bytes through its FE jump operands.",
			"prg_bank": 5,
			"cpu_range_inclusive_start_exclusive_end": ["$BFBA", "$BFC4"],
			"rom_file_range_inclusive_start_exclusive_end": ["0x00BFCA", "0x00BFD4"],
			"length_bytes": len(entry),
			"sha256": sha256(entry),
		},
		{
			"file": tail_resource.name,
			"description": "Scene $58 bytes reached by scene $56's FE jump to $BFD5, through FF.",
			"prg_bank": 5,
			"cpu_range_inclusive_start_exclusive_end": ["$BFD5", "$BFF4"],
			"rom_file_range_inclusive_start_exclusive_end": ["0x00BFE5", "0x00C004"],
			"length_bytes": len(tail),
			"sha256": sha256(tail),
		},
	]
	manifest_files = root_manifest.get("files")
	if not isinstance(manifest_files, list):
		raise SystemExit("Meeting-menu source manifest has no files array.")
	files_by_name = {item.get("file"): item for item in manifest_files if isinstance(item, dict)}
	for source_file in new_source_files:
		files_by_name[source_file["file"]] = source_file
	root_manifest["files"] = list(files_by_name.values())
	limitations = root_manifest.get("limitations", [])
	new_limit = "Scene $56 command bytes are extracted; rendering and source return/task timing are not yet integrated."
	if new_limit not in limitations:
		limitations.append(new_limit)
	root_manifest["limitations"] = limitations
	root_manifest_path.write_text(json.dumps(root_manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

	segments = [
		{
			"execution_stream_offset_range": [0, ENTRY_LENGTH],
			"source_resource": "reference/rom_extract/gameplay/meeting_menu/bank5_meeting_start_scene_56_entry.bin",
			"cpu_start": f"0x{ENTRY_CPU:04X}",
			"file_start": f"0x{ENTRY_FILE:06X}",
			"length_bytes": len(entry),
			"sha256": sha256(entry),
		},
		{
			"execution_stream_offset_range": [ENTRY_LENGTH, len(execution_stream)],
			"source_resource": "reference/rom_extract/gameplay/meeting_menu/bank5_scene_58_shared_tail_BFD5_BFF4.bin",
			"cpu_start": f"0x{TAIL_CPU:04X}",
			"file_start": f"0x{TAIL_FILE:06X}",
			"length_bytes": len(tail),
			"sha256": sha256(tail),
		},
	]
	stream_hash = sha256(execution_stream)
	span_manifest = {
		"name": "supplied_turkish_rom_scene_56_execution_spans",
		"source_rom": ROM_PATH.name,
		"source_rom_sha256": EXPECTED_ROM_SHA256,
		"execution_stream_sha256": stream_hash,
		"runtime_stream_resource": "reference/rom_extract/gameplay/meeting_menu/scene_56_execution.bin",
		"runtime_stream_is_flattened": True,
		"segments": segments,
		"note": "Scene $56 at $BFBA branches with FE to $BFD5, inside scene $58's $BFCE-$BFF4 pointer span; the flattened stream preserves those two reachable ROM segments without the skipped bytes.",
	}
	(DATA_DIR / "scene_56_execution_spans.json").write_text(
		json.dumps(span_manifest, indent=2) + "\n", encoding="utf-8"
	)

	manifest = {
		"schema": 1,
		"name": "kickoff_meeting_scene_56",
		"source_rom_sha256": EXPECTED_ROM_SHA256,
		"source_execution_stream_sha256": stream_hash,
		"source_resource": "reference/rom_extract/gameplay/meeting_menu/scene_56_execution.bin",
		"execution_stream_cpu_range": [f"0x{ENTRY_CPU:04X}", f"0x{TAIL_CPU + TAIL_LENGTH - 1:04X}"],
		"execution_stream_file_range": [f"0x{ENTRY_FILE:06X}", f"0x{TAIL_FILE + TAIL_LENGTH:06X}"],
		"execution_stream_length_bytes": len(execution_stream),
		"execution_segments": segments,
		"event_count": len(events),
		"event_boundaries_byte_verified": True,
		"frame_timing_decoded": False,
		"asset_producers_decoded": False,
		"events": events,
	}
	output_path = OUTPUT_DIR / "kickoff_meeting_scene_56_events.json"
	OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
	output_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
	print(f"{output_path.relative_to(ROOT)}: {len(events)} ROM-indexed events, {len(execution_stream)} bytes")
	print(f"scene $56 reachable stream SHA-256: {stream_hash}")


if __name__ == "__main__":
	main()
