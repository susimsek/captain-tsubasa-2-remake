#!/usr/bin/env python3
"""Preserve the three ROM bytes for bank-$18:$8886's yield JSR."""

import argparse
import hashlib
import json
from pathlib import Path


ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
ROM_OFFSET = 0x030896
SPAN_FILE = "bank18_worker_yield_callsite_8886.bin"
EXPECTED_BYTES = bytes.fromhex("20 15 C5")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "rom",
        nargs="?",
        default="Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes",
        type=Path,
    )
    args = parser.parse_args()

    rom = args.rom.read_bytes()
    rom_hash = hashlib.sha256(rom).hexdigest()
    if rom_hash != ROM_SHA256:
        raise SystemExit(f"ROM hash mismatch: {rom_hash}")
    span = rom[ROM_OFFSET:ROM_OFFSET + len(EXPECTED_BYTES)]
    if span != EXPECTED_BYTES:
        raise SystemExit(f"Unexpected source bytes at 0x{ROM_OFFSET:06X}: {span.hex()}")

    output_dir = Path("reference/rom_extract/gameplay/task_context")
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / SPAN_FILE).write_bytes(span)
    manifest_path = output_dir / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    mapping_note = " Bank $18 CPU $8000-$9FFF maps to file 0x030010+."
    if mapping_note.strip() not in manifest["mapping"]:
        manifest["mapping"] += mapping_note
    spans = manifest.setdefault("spans", [])
    spans[:] = [entry for entry in spans if entry.get("file") != SPAN_FILE]
    spans.append({
        "file": SPAN_FILE,
        "cpu_address": "0x8886",
        "file_offset": f"0x{ROM_OFFSET:06X}",
        "length": len(span),
        "sha256": hashlib.sha256(span).hexdigest(),
        "description": "Bank-$18 worker JSR $C515 callsite, verified against the fresh match-zero worker span.",
        "bytes": span.hex(" "),
    })
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {SPAN_FILE}: {span.hex()} sha256={hashlib.sha256(span).hexdigest()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
