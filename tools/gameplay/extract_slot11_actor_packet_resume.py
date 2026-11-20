#!/usr/bin/env python3
"""Extract ROM spans needed to resume the slot-$11 actor packet builder."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUT = ROOT / "reference/rom_extract/gameplay/slot11_actor_worker_resume_wait"
MANIFEST = OUT / "manifest.json"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

# (name, CPU start, PRG file offset, length, description)
SPANS = [
    (
        "bank18_actor_packet_resume_82f7_8652.bin",
        0x82F7,
        0x030307,
        0x35C,
        "Bank-$18 row-2 packet resume, inline event-command table and text packet writers through $8652.",
    ),
    (
        "bank18_actor_packet_resume_continuation_8653_86e8.bin",
        0x8653,
        0x030663,
        0x95,
        "Bank-$18 ROM continuation reached by the type-$01 packet builder at $8653, bounded before the separate $86E8 row-address table.",
    ),
    (
        "fixed_record_pointer_table_CD89_CD97.bin",
        0xCD89,
        0x03CD99,
        14,
        "First seven fixed-bank record pointers used by the live $CD7C resolver; includes the source-selected Y=$0C entry at $CD95/$CD96.",
    ),
    (
        "bank18_actor_packet_row_address_86e8_86ed.bin",
        0x86E8,
        0x0306F8,
        6,
        "Bank-$18 PPU row-address entries selected by the live event rows $05E7=$00, $01, and $02.",
    ),
    (
        "fixed_text_pointer_lookup_F30F_F328.bin",
        0xF30F,
        0x03F31F,
        0x1A,
        "Fixed-bank text pointer lookup used by the ROM event handler for the live $76 text key.",
    ),
    (
        "fixed_text_pointer_entry_76_F415_F416.bin",
        0xF415,
        0x03F425,
        2,
        "Fixed-bank pointer-table entry $76 resolving the live actor text to $F776.",
    ),
    (
        "fixed_actor_text_76_F776_F77B.bin",
        0xF776,
        0x03F786,
        6,
        "ROM text bytes selected by the live row-$02 actor event, terminated by $FC.",
    ),
    (
        "fixed_player_name_pointer_08_F339_F33A.bin",
        0xF339,
        0x03F349,
        2,
        "Fixed-bank player-name pointer-table entry $08 selected by the live packet builder; resolves to $F52B.",
    ),
    (
        "fixed_player_name_stream_08_F52B_F530.bin",
        0xF52B,
        0x03F53B,
        5,
        "Player-name tile stream selected by pointer entry $08, including its $FC terminator.",
    ),
    (
        "fixed_text_pointer_table_F329_F528.bin",
        0xF329,
        0x03F339,
        0x200,
        "Fixed-bank 256-entry text-pointer table read by $F30F; the live $E6 lookup selects entry $F4F5 and resolves to $FAB0.",
    ),
    (
        "fixed_text_stream_E6_FAB0_FAB3.bin",
        0xFAB0,
        0x03FAC0,
        4,
        "ROM text stream selected by the $E6 pointer entry at $F4F5, through its first $FC terminator.",
    ),
    (
        "fixed_text_stream_F9A4_F9A7.bin",
        0xF9A4,
        0x03F9B4,
        4,
        "ROM text stream selected by the live $F30F pointer lookup during the slot-$11 packet resume, through its first $FC terminator.",
    ),
]


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    rom = ROM_PATH.read_bytes()
    if sha256(rom) != ROM_SHA256:
        raise SystemExit("Target ROM SHA-256 mismatch.")
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    if manifest.get("rom_sha256") != ROM_SHA256:
        raise SystemExit("Slot-$11 manifest targets another ROM revision.")

    entries = []
    names = {name for name, *_ in SPANS} | {
        "bank18_actor_packet_row_address_86e8_86e9.bin",
        "bank18_actor_packet_row_address_86e8_86eb.bin",
        "fixed_text_pointer_entry_E6_F4F5_F4F6.bin",
    }
    for name, cpu_address, file_offset, length, description in SPANS:
        data = rom[file_offset : file_offset + length]
        if len(data) != length:
            raise SystemExit(f"Truncated ROM span: {name}")
        (OUT / name).write_bytes(data)
        entries.append(
            {
                "file": name,
                "cpu_address": f"0x{cpu_address:04X}",
                "file_offset": f"0x{file_offset:06X}",
                "length": length,
                "sha256": sha256(data),
                "description": description,
                "bytes": data.hex(" "),
            }
        )

    old = [span for span in manifest.get("spans", []) if span.get("file") not in names]
    manifest["spans"] = old + entries
    dependencies = manifest.setdefault("external_dependencies", [])
    extra = [
        (
            "reference/rom_extract/gameplay/fresh_bank18_worker_prefix/fixed_text_helper_vector_C524_C527.bin",
            "Shared fixed-bank vector JMP from $C524 to the ROM text-token converter at $CBC2.",
        ),
        (
            "reference/rom_extract/gameplay/fresh_bank18_worker_prefix/fixed_text_token_converter_CBC2_CBF1.bin",
            "Shared fixed-bank text-token conversion routine used while building the actor's PPU text packet.",
        ),
        (
            "reference/rom_extract/gameplay/field_entry_window_01/fixed_team_name_dispatch_C53C_C53F.bin",
            "Shared fixed-bank vector JMP to the ROM's $F30F text pointer lookup.",
        ),
        (
            "reference/rom_extract/gameplay/first_match_player_state/fixed_record_pointer_vector_C50C_C50F.bin",
            "Shared fixed-bank vector JMP to the $CD7C player-record pointer resolver used by the packet builder.",
        ),
        (
            "reference/rom_extract/gameplay/first_match_player_state/fixed_record_pointer_resolver_CD7C_CD89.bin",
            "Shared fixed-bank player-record pointer resolver called from the actor packet builder.",
        ),
    ]
    known = {entry.get("path") for entry in dependencies}
    for relative, reason in extra:
        if relative in known:
            continue
        data = (ROOT / relative).read_bytes()
        dependencies.append({"path": relative, "sha256": sha256(data), "reason": reason})

    MANIFEST.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Extracted {len(entries)} ROM source spans for the slot-$11 packet resume.")


if __name__ == "__main__":
    main()
