#!/usr/bin/env python3
"""Extract the pointer-bounded ROM source for pass-action scenario $18."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUT_DIR = ROOT / "reference/rom_extract/gameplay/pass_scenario_18"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
ROM_SIZE = 393_232
TABLE_OFFSET = 0x0209CF
TABLE_CPU = 0x89BF
WINDOW_BASE = 0x020010
SCENARIO_ID = 0x18
BRANCH_AF51 = {
	"cpu_address": 0xAF51,
	"file_name": "scenario_18_branch_af51.bin",
	"length": 8,
	"bytes_hex": "F9 05 2B 3C 72 66 47 FB",
	"sha256": "162fe60677bbd4a6f06415055195215d0a39860746a52816598badfc7571cb8a",
}
SLOT05_POST_QUEUE_CALLER = {
	"cpu_address": 0x8188,
	"file_name": "slot05_scenario18_post_queue_caller_8188_819b.bin",
	"length": 20,
	"bytes_hex": "AD 44 04 29 03 8D 4E 04 20 24 C6 AD 17 06 09 80 8D 17 06 60",
	"sha256": "fea79dbe1bb2ce4aa401d7b4df6c6cfd4574aa0ee0bf0fac643005b42f428245",
}


def sha256(data: bytes) -> str:
	return hashlib.sha256(data).hexdigest()


def main() -> None:
	rom = ROM_PATH.read_bytes()
	if len(rom) != ROM_SIZE or sha256(rom) != ROM_SHA256:
		raise SystemExit("The supplied ROM does not match the expected size and SHA-256.")
	entry_offset = TABLE_OFFSET + SCENARIO_ID * 2
	pointer_bytes = rom[entry_offset:entry_offset + 2]
	pointer = int.from_bytes(pointer_bytes, "little")
	valid_pointers: list[tuple[int, int]] = []
	for scenario_id in range(0x100):
		offset = TABLE_OFFSET + scenario_id * 2
		candidate = int.from_bytes(rom[offset:offset + 2], "little")
		if 0x8000 <= candidate < 0xC000:
			valid_pointers.append((candidate, scenario_id))
	boundaries = [(value, scenario_id) for value, scenario_id in valid_pointers if value > pointer]
	if not boundaries:
		raise SystemExit("No greater valid scenario pointer bounds scenario $18.")
	end_pointer = min(value for value, _scenario_id in boundaries)
	boundary_ids = [scenario_id for value, scenario_id in boundaries if value == end_pointer]
	stream_offset = WINDOW_BASE + pointer - 0x8000
	end_offset = WINDOW_BASE + end_pointer - 0x8000
	stream = rom[stream_offset:end_offset]
	if pointer != 0x9E3E or end_pointer != 0x9E57 or boundary_ids != [0x32] \
			or stream != bytes.fromhex("FD 00 F3 B4 03 02 0B F3 1E 51 AF 59 AF 90 AF AA AF F9 15 2B 3F 2A 19 47 FB"):
		raise SystemExit("Scenario $18 pointer, exclusive bound, or source bytes changed.")
	branch = BRANCH_AF51
	branch_offset = WINDOW_BASE + int(branch["cpu_address"]) - 0x8000
	branch_bytes = rom[branch_offset:branch_offset + int(branch["length"])]
	if branch_bytes != bytes.fromhex(str(branch["bytes_hex"])) \
			or sha256(branch_bytes) != branch["sha256"]:
		raise SystemExit("Scenario $18 live `$F3 $1E` target `$AF51` bytes changed.")
	caller = SLOT05_POST_QUEUE_CALLER
	caller_offset = 0x034010 + int(caller["cpu_address"]) - 0x8000
	caller_bytes = rom[caller_offset:caller_offset + int(caller["length"])]
	if caller_bytes != bytes.fromhex(str(caller["bytes_hex"])) \
			or sha256(caller_bytes) != caller["sha256"]:
		raise SystemExit("The slot-$05 scenario-$18 `$8188-$819B` caller bytes changed.")

	OUT_DIR.mkdir(parents=True, exist_ok=True)
	pointer_name = "scenario_pointer_18.bin"
	stream_name = "scenario_18.bin"
	branch_name = str(branch["file_name"])
	caller_name = str(caller["file_name"])
	(OUT_DIR / pointer_name).write_bytes(pointer_bytes)
	(OUT_DIR / stream_name).write_bytes(stream)
	(OUT_DIR / branch_name).write_bytes(branch_bytes)
	(OUT_DIR / caller_name).write_bytes(caller_bytes)
	manifest = {
		"schema": "ct2-pass-scenario-18-source-v1",
		"source_rom_filename": ROM_PATH.name,
		"source_rom_sha256": ROM_SHA256,
		"source_rom_size_bytes": ROM_SIZE,
		"runtime_rom_dependency": False,
		"capture_or_screenshot_bytes_included": False,
		"pointer_table": {
			"cpu_address": f"0x{TABLE_CPU:04X}",
			"file_offset": f"0x{TABLE_OFFSET:06X}",
			"prg_bank": "$10",
			"entry_width_bytes": 2,
			"scanned_entry_count": 256,
			"boundary_rule": "End at the smallest greater valid CPU pointer among all 256 entries; end is exclusive.",
		},
		"scenario_id": "$18",
		"start_cpu_address": f"0x{pointer:04X}",
		"pointer_entry_cpu_address": f"0x{TABLE_CPU + SCENARIO_ID * 2:04X}",
		"pointer_entry_file_offset": f"0x{entry_offset:06X}",
		"pointer_entry_bytes_hex": pointer_bytes.hex(" ").upper(),
		"pointer_entry_sha256": sha256(pointer_bytes),
		"end_boundary_pointer_entry_id": "$32",
		"end_cpu_address_exclusive": f"0x{end_pointer:04X}",
		"file_offset": f"0x{stream_offset:06X}",
		"end_file_offset_exclusive": f"0x{end_offset:06X}",
		"length_bytes": len(stream),
		"sha256": sha256(stream),
		"bytes_hex": stream.hex(" ").upper(),
		"source_spans": [
			{"file": pointer_name, "cpu_start": f"0x{TABLE_CPU + SCENARIO_ID * 2:04X}",
				"file_offset": f"0x{entry_offset:06X}", "length": len(pointer_bytes),
				"sha256": sha256(pointer_bytes)},
			{"file": stream_name, "cpu_start": f"0x{pointer:04X}",
				"file_offset": f"0x{stream_offset:06X}", "length": len(stream),
				"sha256": sha256(stream)},
			{"name": "slot05_post_queue_caller", "file": caller_name,
				"bank": "0x1A", "cpu_start": f"0x{int(caller['cpu_address']):04X}",
				"file_offset": f"0x{caller_offset:06X}",
				"length_bytes": int(caller["length"]),
				"sha256": str(caller["sha256"])},
		],
		"initial_control_flow": [
			{"offset": 0, "bytes_hex": "FD 00", "status": "Source handler and live context are required."},
			{"offset": 2, "bytes_hex": "F3 B4 03 02 0B", "status": "Selector and branch are determined by live RAM $044E."},
		],
		"external_branches": [
			{"selector": 0, "table_entry_offset": 9, "target_cpu_address": "0xAF51",
				"file_offset": f"0x{branch_offset:06X}", "file": branch_name,
				"length_bytes": int(branch["length"]), "sha256": str(branch["sha256"]),
				"bytes_hex": branch_bytes.hex(" ").upper(),
				"terminator": "local `$FB`; scenario root continuation remains caller-owned"},
		],
		"slot05_post_queue_caller": {
			"role": "After the scenario-$18 `$CBC1 RTS` pops `$8187`, execute this caller through its final RTS; the `$C624` vector and `$DCDF` target are pinned in pass_scenario_1c/manifest.json.",
			"cpu_address": f"0x{int(caller['cpu_address']):04X}",
			"file_offset": f"0x{caller_offset:06X}",
			"length_bytes": int(caller["length"]),
			"file": caller_name,
			"sha256": str(caller["sha256"]),
			"bytes_hex": caller_bytes.hex(" ").upper(),
			"entry": "`$8188`, returned from `$CBC1 RTS` using stack word `$8187`",
			"exit": "`$8112`, after `$819B RTS` consumes the caller-owned `$8111` word; `$E944` remains separate scheduler metadata",
		},
	}
	(OUT_DIR / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
	print(f"Extracted scenario $18: $%04X-$%04X, {len(stream)} bytes, sha256 {sha256(stream)}" % (pointer, end_pointer))


if __name__ == "__main__":
	main()
