#!/usr/bin/env python3
"""Preserve the byte-checked fresh-match $8920 prefix and $9DEE helper."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
OUT_DIR = ROOT / "reference/rom_extract/gameplay/fresh_kickoff_match_setup"
CALLER_DIR = ROOT / "reference/rom_extract/gameplay/fresh_kickoff_caller"

SPANS = [
    {
        "id": "preset_loader_prefix",
        "path": "reference/rom_extract/gameplay/fresh_kickoff_match_setup/preset_loader_prefix_A920_893E.bin",
        "cpu_start": "$8920",
        "cpu_end_exclusive": "$893F",
        "file_offset": "0x000930",
        "length": 31,
        "rom_offset": 0x930,
        "callsite": {"cpu": "$8938", "target": "$C4B9", "return": "$893B"},
    },
    {
        "id": "multiply_by_x_helper",
        "path": "reference/rom_extract/gameplay/fresh_kickoff_match_setup/multiply_by_x_helper_9DEE_9E0B.bin",
        "cpu_start": "$9DEE",
        "cpu_end_exclusive": "$9E0C",
        "file_offset": "0x001DFE",
        "length": 30,
        "rom_offset": 0x1DFE,
    },
]


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> int:
    if not ROM_PATH.is_file():
        raise SystemExit(f"ROM is missing: {ROM_PATH}")
    rom = ROM_PATH.read_bytes()
    if digest(rom) != ROM_SHA256:
        raise SystemExit("ROM SHA-256 differs from the supplied Turkish revision")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for span in SPANS:
        start = int(span["rom_offset"])
        data = rom[start : start + int(span["length"])]
        if len(data) != int(span["length"]):
            raise SystemExit(f"ROM span is truncated: {span['id']}")
        span["sha256"] = digest(data)
        span["bytes"] = data.hex()
        output = ROOT / str(span["path"])
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_bytes(data)

    package = {
        "schema": "ct2-fresh-kickoff-match-setup-sources-v1",
        "rom": {
            "name": ROM_PATH.name,
            "sha256": ROM_SHA256,
        },
        "mapping": "Bank $00 at CPU $8000 maps file 0x000010 + (CPU-$8000); offsets include the iNES header.",
        "scope": "Exact ROM spans for the fresh caller's $8920 preset-loader prefix and its $9DEE index arithmetic; the source stops at the unresolved $78 wait.",
        "spans": SPANS,
    }
    (OUT_DIR / "manifest.json").write_text(json.dumps(package, indent=2) + "\n")

    # The shared fixed-mapper executor validates every supported JSR site from
    # a packaged callsite span. Add the $8938 site to its existing source map.
    mapper_manifest_path = CALLER_DIR / "manifest.json"
    mapper_manifest = json.loads(mapper_manifest_path.read_text())
    callsite_path = CALLER_DIR / "bank00_match_setup_preset_8920_893F.bin"
    callsite_span = SPANS[0]
    callsite_bytes = rom[int(callsite_span["rom_offset"]) : int(callsite_span["rom_offset"]) + int(callsite_span["length"])]
    callsite_path.write_bytes(callsite_bytes)
    entry = {
        "file": callsite_path.name,
        "cpu_start": "$8920",
        "cpu_end_exclusive": "$893F",
        "file_offset": "0x000930",
        "length": len(callsite_bytes),
        "sha256": digest(callsite_bytes),
        "bank_mapping": "bank $00 at CPU $8000",
        "bytes": callsite_bytes.hex(" "),
    }
    spans = mapper_manifest.setdefault("spans", [])
    spans = [row for row in spans if row.get("file") != callsite_path.name]
    spans.append(entry)
    mapper_manifest["spans"] = spans
    mapper_manifest["scope"] += " Includes the fresh match setup `$8938->$C4B9` callsite."
    mapper_manifest_path.write_text(json.dumps(mapper_manifest, indent=2) + "\n")

    for span in SPANS:
        print(f"{span['id']}: {span['cpu_start']}-{span['cpu_end_exclusive']} sha256={span['sha256']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
