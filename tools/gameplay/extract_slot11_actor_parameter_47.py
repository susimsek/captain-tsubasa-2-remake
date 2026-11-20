#!/usr/bin/env python3
"""Extract the ROM pointer and bounded actor stream selected by parameter $47."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
BANK18_FILE_BASE = 0x030010
TABLE_BASE = 0x9220
PARAMETER = 0x47
EXPECTED_POINTER = 0x9917
EXPECTED_NEXT_POINTER = 0x9921
EXPECTED_STREAM = bytes.fromhex("F2 01 51 E4 FC 04 E2 20 FC F0")

TASK_CONTEXT = ROOT / "reference/rom_extract/gameplay/task_context"
TASK_CONTEXT_MANIFEST = TASK_CONTEXT / "manifest.json"
RESUME = ROOT / "reference/rom_extract/gameplay/slot11_actor_worker_resume_wait"
RESUME_MANIFEST = RESUME / "manifest.json"


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def save_source(directory: Path, filename: str, data: bytes) -> None:
    path = directory / filename
    if path.exists() and path.read_bytes() != data:
        raise SystemExit(f"Preserved source differs from the supplied ROM: {path}")
    path.write_bytes(data)


def add_span(manifest: dict[str, object], entry: dict[str, object]) -> None:
    spans = manifest.get("spans")
    if not isinstance(spans, list):
        raise SystemExit("Source manifest has no span list.")
    filename = str(entry["file"])
    for old in spans:
        if isinstance(old, dict) and old.get("file") == filename:
            if old != entry:
                raise SystemExit(f"Existing manifest span differs: {filename}")
            return
    spans.append(entry)


def main() -> None:
    rom = ROM_PATH.read_bytes()
    if sha256(rom) != ROM_SHA256 or len(rom) != 393232:
        raise SystemExit("The supplied ROM identity or size does not match the pinned revision.")

    table_cpu = TABLE_BASE + 2 * PARAMETER
    table_offset = BANK18_FILE_BASE + table_cpu - 0x8000
    pointer_bytes = rom[table_offset : table_offset + 2]
    next_pointer_bytes = rom[table_offset + 2 : table_offset + 4]
    pointer = int.from_bytes(pointer_bytes, "little")
    next_pointer = int.from_bytes(next_pointer_bytes, "little")
    if table_cpu != 0x92AE or pointer != EXPECTED_POINTER or next_pointer != EXPECTED_NEXT_POINTER:
        raise SystemExit("The actor-$47 pointer or adjacent end pointer changed.")
    stream_offset = BANK18_FILE_BASE + pointer - 0x8000
    stream = rom[stream_offset : stream_offset + next_pointer - pointer]
    if stream != EXPECTED_STREAM:
        raise SystemExit("The actor-$47 stream bytes differ from the reviewed source sequence.")

    TASK_CONTEXT.mkdir(parents=True, exist_ok=True)
    RESUME.mkdir(parents=True, exist_ok=True)
    pointer_name = "bank18_actor_parameter_47_pointer_92AE.bin"
    next_pointer_name = "bank18_actor_parameter_48_boundary_pointer_92B0.bin"
    stream_name = "bank18_actor_stream_parameter47_9917_9920.bin"
    save_source(TASK_CONTEXT, pointer_name, pointer_bytes)
    save_source(RESUME, next_pointer_name, next_pointer_bytes)
    save_source(RESUME, stream_name, stream)

    task_manifest = json.loads(TASK_CONTEXT_MANIFEST.read_text(encoding="utf-8"))
    if task_manifest.get("rom_sha256") != ROM_SHA256:
        raise SystemExit("Task-context manifest targets another ROM revision.")
    add_span(task_manifest, {
        "file": pointer_name,
        "cpu_address": "0x92AE",
        "file_offset": f"0x{table_offset:06X}",
        "length": len(pointer_bytes),
        "sha256": sha256(pointer_bytes),
        "description": "Bank-$18 actor parameter `$47` pointer-table entry; `$800F` computes `$9220 + 2*$47` and resolves it to stream `$9917`.",
        "bytes": pointer_bytes.hex(" "),
    })
    TASK_CONTEXT_MANIFEST.write_text(json.dumps(task_manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    resume_manifest = json.loads(RESUME_MANIFEST.read_text(encoding="utf-8"))
    if resume_manifest.get("rom_sha256") != ROM_SHA256:
        raise SystemExit("Slot-$11 resume manifest targets another ROM revision.")
    add_span(resume_manifest, {
        "file": next_pointer_name,
        "cpu_address": "0x92B0",
        "file_offset": f"0x{table_offset + 2:06X}",
        "length": len(next_pointer_bytes),
        "sha256": sha256(next_pointer_bytes),
        "description": "Adjacent bank-$18 parameter `$48` pointer used to bound the parameter-$47 stream at `$9921`.",
        "bytes": next_pointer_bytes.hex(" "),
    })
    add_span(resume_manifest, {
        "file": stream_name,
        "cpu_address": f"0x{pointer:04X}",
        "file_offset": f"0x{stream_offset:06X}",
        "length": len(stream),
        "sha256": sha256(stream),
        "description": "Bank-$18 actor stream selected by parameter `$47`, bounded by the next pointer at `$92B0`; begins with `$F2 $01 $51`, then `$E4 $FC $04 $E2 $20 $FC $F0`.",
        "bytes": stream.hex(" "),
    })
    RESUME_MANIFEST.write_text(json.dumps(resume_manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"PASS: parameter $47 pointer ${pointer:04X} and {len(stream)} ROM bytes were hash-pinned.")
    print(f"pointer sha256={sha256(pointer_bytes)} stream sha256={sha256(stream)}")


if __name__ == "__main__":
    main()
