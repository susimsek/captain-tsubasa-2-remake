#!/usr/bin/env python3
"""Extract the target-ROM action-label renderer's scheduler-resume body."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
OUT_ROOT = ROOT / "reference/rom_extract/gameplay/menus/first_action_menu"
START_PC = 0xE945
END_PC = 0xE9D9
FIXED_BANK = 0x1E
FIXED_FILE_BASE = 0x03C010


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    rom = ROM_PATH.read_bytes()
    if sha256(rom) != ROM_SHA256:
        raise SystemExit("Supplied ROM hash does not match the pinned Turkish ROM.")
    file_offset = FIXED_FILE_BASE + START_PC - 0xC000
    source = rom[file_offset : file_offset + END_PC - START_PC + 1]
    if len(source) != END_PC - START_PC + 1:
        raise SystemExit("Renderer resume span is truncated in the supplied ROM.")

    code_path = OUT_ROOT / "action_menu_renderer_E945_E9D9.bin"
    manifest_path = OUT_ROOT / "action_menu_renderer_resume_source.json"
    code_path.write_bytes(source)
    manifest = {
        "schema": "ct2-first-action-renderer-resume-source-v1",
        "source_rom": ROM_PATH.name,
        "source_rom_sha256": ROM_SHA256,
        "source_code": {
            "cpu_start": f"${START_PC:04X}",
            "cpu_end_inclusive": f"${END_PC:04X}",
            "prg_bank": f"${FIXED_BANK:02X}",
            "file_offset": f"0x{file_offset:06X}",
            "length_bytes": len(source),
            "resource": code_path.name,
            "sha256": sha256(source),
        },
        "runtime_inputs": {
            "action_map": "action_id_to_render_variant_context_00.bin",
            "action_map_sha256": "9d154b311f10f5a25ae835854853e99223ec66f254251a5e1ff366fc334a740e",
            "render_variant_pointer_table": "action_render_variant_pointer_table_00_03.bin",
            "render_variant_pointer_table_sha256": "41f429b2ca2e143fb59e023bc886350b20135197e1bcfe7c5b837127fa662f42",
            "label_streams": "action_label_render_streams_EA1C_EA45.bin",
            "label_streams_sha256": "97ad1d49bafb4111180337fc8378ce31a3ac80bca6dccee238c08da423c34b11",
            "source_audit": "action_blink_source_audit.json",
            "source_audit_sha256": "72b7cac439df171fe3cad8098335037167f62a678f6edad3f31983b48f6fbf38",
        },
        "observed_algorithm": (
            "Resume after the $E93D prologue's CB0F yield. Poll $0515; a nonzero "
            "value branches to the $E940 JSR $CB0F and must be resumed again at $E945. "
            "When clear, reserve $0515, decode the saved render variant through "
            "$E9DA and the selected EA1C-EA45 stream, append row packets to $04A5, "
            "publish $0515=$80, and RTS to the caller."
        ),
        "packet_contract": {
            "buffer_start": "$04A5",
            "ready_flag": "$0515",
            "record": "payload width, PPU address low, PPU address high, payload tiles",
            "list_terminator": "one zero-width byte after the final row packet",
            "ppu_writes_are_not_applied_here": True,
        },
    }
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"ROM span ${START_PC:04X}-${END_PC:04X}: {len(source)} bytes, SHA-256 {sha256(source)}")
    print(f"Wrote {code_path.relative_to(ROOT)} and {manifest_path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
