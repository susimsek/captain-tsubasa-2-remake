#!/usr/bin/env python3
"""Extract the fixed-bank text selected by the live parameter-$47 packet route."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUTPUT_DIR = ROOT / "reference/rom_extract/gameplay/slot11_actor_worker_resume_wait"
MANIFEST_PATH = OUTPUT_DIR / "manifest.json"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

SPANS = [
	{
		"file": "fixed_actor_text_pointer_entry_00_F329_F32B.bin",
		"cpu_address": 0xF329,
		"file_offset": 0x03F339,
		"length": 2,
		"sha256": "4e48ab6b84301af8b8fa92c04373b79b5d6f0f37d207c775c98fbce001ff67fe",
		"description": "Fixed-bank pointer-table entry selected by the parameter-$47 index-$01 route; resolves to live RAM $05EB, whose source-owned producer is traced separately.",
	},
]


def sha256(data: bytes) -> str:
	return hashlib.sha256(data).hexdigest()


def main() -> None:
	rom = ROM_PATH.read_bytes()
	if sha256(rom) != ROM_SHA256:
		raise SystemExit("Target ROM SHA-256 mismatch.")
	manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
	if manifest.get("rom_sha256") != ROM_SHA256:
		raise SystemExit("Slot-$11 source manifest targets another ROM revision.")
	entries = {item["file"]: item for item in manifest.get("spans", [])}
	for spec in SPANS:
		start = int(spec["file_offset"])
		length = int(spec["length"])
		data = rom[start : start + length]
		if len(data) != length or sha256(data) != spec["sha256"]:
			raise SystemExit(f"Unexpected ROM bytes at ${int(spec['cpu_address']):04X}.")
		(OUTPUT_DIR / str(spec["file"])).write_bytes(data)
		entry = dict(spec)
		entry["cpu_address"] = f"0x{int(spec['cpu_address']):04X}"
		entry["file_offset"] = f"0x{start:06X}"
		entry["bytes"] = data.hex(" ")
		entries[str(spec["file"])] = entry
	manifest["spans"] = list(entries.values())
	MANIFEST_PATH.write_text(
		json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
	)
	print("Extracted the ROM pointer entry for the parameter-$47 route's dynamic RAM text buffer.")


if __name__ == "__main__":
	main()
