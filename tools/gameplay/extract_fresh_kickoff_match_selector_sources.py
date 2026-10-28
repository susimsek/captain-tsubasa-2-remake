#!/usr/bin/env python3
"""Package the supplied ROM spans used by the match-zero selector executor."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
DESTINATION = ROOT / "reference/rom_extract/gameplay/fresh_kickoff_match_selector"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

SOURCES = [
    {
        "id": "title_caller",
        "path": "reference/rom_extract/gameplay/fresh_kickoff_caller/bank00_title_to_first_match_setup_80DF_815C.bin",
        "cpu_start": "$80DF",
        "cpu_end_exclusive": "$815D",
        "file_offset": "0x0000EF",
        "length": 126,
        "sha256": "a4b5afda1800eb4b500c95748497e22cb6467d90d1e99c56d4578b98db996a7b",
    },
    {
        "id": "selector_trampoline",
        "path": "reference/rom_extract/gameplay/fresh_kickoff_entry_context/match_selector_trampoline_A20F.bin",
        "cpu_start": "$A20F",
        "cpu_end_exclusive": "$A212",
        "file_offset": "0x00421F",
        "length": 3,
        "sha256": "51244f9af68e818db390d67b69d822597a021d99bb35339132f4ce2dfde5430d",
    },
    {
        "id": "selector_code",
        "path": "reference/rom_extract/gameplay/fresh_kickoff_entry_context/match_selector_A86E_A8CD.bin",
        "cpu_start": "$A86E",
        "cpu_end_exclusive": "$A8CE",
        "file_offset": "0x00487E",
        "length": 96,
        "sha256": "f9b27195e6d6c9163d55ee6161fbf8d4d795537df2f2347d3e4c406765033123",
    },
    {
        "id": "home_roster_match_00",
        "path": "reference/rom_extract/gameplay/fresh_kickoff_position_context/bank_02_match_00_home_roster_AA47.bin",
        "cpu_start": "$AA47",
        "cpu_end_exclusive": "$AA53",
        "file_offset": "0x004A57",
        "length": 12,
        "sha256": "dcb5f0103eaecbc9785e947085b02cd6b56f7d31e6671a699d82b22d80a3b123",
    },
    {
        "id": "home_team_match_table",
        "path": "reference/rom_extract/gameplay/fresh_kickoff_position_context/bank_02_match_00_home_team_id_AA75.bin",
        "cpu_start": "$AA75",
        "cpu_end_exclusive": "$AA76",
        "file_offset": "0x004A85",
        "length": 1,
        "sha256": "6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d",
    },
    {
        "id": "selector_copy_scan_code",
        "path": "reference/rom_extract/gameplay/fresh_kickoff_match_selector/selector_copy_scan_code_A138_A15D.bin",
        "cpu_start": "$A138",
        "cpu_end_exclusive": "$A15E",
        "file_offset": "0x004148",
        "length": 38,
        "rom_offset": 0x004148,
    },
    {
        "id": "selector_copy_finish_code",
        "path": "reference/rom_extract/gameplay/fresh_kickoff_match_selector/selector_copy_finish_code_A1E4_A1EA.bin",
        "cpu_start": "$A1E4",
        "cpu_end_exclusive": "$A1EB",
        "file_offset": "0x0041F4",
        "length": 7,
        "rom_offset": 0x0041F4,
    },
    {
        "id": "selector_copy_increment_code",
        "path": "reference/rom_extract/gameplay/fresh_kickoff_match_selector/selector_copy_increment_code_A1EB_A1F9.bin",
        "cpu_start": "$A1EB",
        "cpu_end_exclusive": "$A1FA",
        "file_offset": "0x0041FB",
        "length": 15,
        "rom_offset": 0x0041FB,
    },
    {
        "id": "selector_normalize_trampoline",
        "path": "reference/rom_extract/gameplay/fresh_kickoff_match_selector/selector_normalize_trampoline_A20C_A20E.bin",
        "cpu_start": "$A20C",
        "cpu_end_exclusive": "$A20F",
        "file_offset": "0x00421C",
        "length": 3,
        "rom_offset": 0x00421C,
    },
    {
        "id": "selector_normalize_branch",
        "path": "reference/rom_extract/gameplay/fresh_kickoff_match_selector/selector_normalize_branch_A855_A86D.bin",
        "cpu_start": "$A855",
        "cpu_end_exclusive": "$A86E",
        "file_offset": "0x004865",
        "length": 25,
        "rom_offset": 0x004865,
    },
]

COPY_SOURCE_START = 0xACB0
COPY_SOURCE_END_EXCLUSIVE = 0xC000
COPY_SOURCE_FILE_OFFSET = 0x004010 + (COPY_SOURCE_START - 0xA000)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> int:
    rom = ROM_PATH.read_bytes()
    if sha256(rom) != ROM_SHA256:
        raise SystemExit("The supplied ROM hash does not match the audited Turkish revision.")
    DESTINATION.mkdir(parents=True, exist_ok=True)
    packaged: list[dict[str, object]] = []
    for spec in SOURCES:
        if "rom_offset" in spec:
            source_bytes = rom[int(spec["rom_offset"]):int(spec["rom_offset"]) + int(spec["length"])]
            if len(source_bytes) != spec["length"]:
                raise SystemExit(f"ROM ended before source span: {spec['path']}")
            (ROOT / str(spec["path"])).write_bytes(source_bytes)
        else:
            source_bytes = (ROOT / str(spec["path"])).read_bytes()
            if len(source_bytes) != spec["length"] or sha256(source_bytes) != spec["sha256"]:
                raise SystemExit(f"Preserved source span failed validation: {spec['path']}")
        item = {key: value for key, value in spec.items() if key != "rom_offset"}
        item["sha256"] = sha256(source_bytes)
        packaged.append({**item, "bytes": source_bytes.hex()})

    copy_bytes = rom[COPY_SOURCE_FILE_OFFSET:COPY_SOURCE_FILE_OFFSET + COPY_SOURCE_END_EXCLUSIVE - COPY_SOURCE_START]
    if len(copy_bytes) != COPY_SOURCE_END_EXCLUSIVE - COPY_SOURCE_START:
        raise SystemExit("ROM ended before the selector's copy-source span.")
    copy_file = "selector_prg_ram_copy_source_ACB0_BFFF.bin"
    (DESTINATION / copy_file).write_bytes(copy_bytes)
    packaged.append({
        "id": "selector_copy_source",
        "path": f"reference/rom_extract/gameplay/fresh_kickoff_match_selector/{copy_file}",
        "cpu_start": "$ACB0",
        "cpu_end_exclusive": "$C000",
        "file_offset": f"0x{COPY_SOURCE_FILE_OFFSET:06X}",
        "length": len(copy_bytes),
        "sha256": sha256(copy_bytes),
        "bytes": copy_bytes.hex(),
    })

    manifest = {
        "schema": "ct2-fresh-kickoff-match-selector-executable-v1",
        "rom": {
            "name": ROM_PATH.name,
            "sha256": ROM_SHA256,
        },
        "mapping": "Bank $02 at CPU $A000 maps file 0x004010 + (CPU-$A000); offsets include the 16-byte iNES header.",
        "scope": "Hash-checked source spans for the fresh match-index-zero caller path, selector/normalization branches, ROM-to-PRG-RAM copy routine/data, and roster tables.",
        "spans": packaged,
        "selector_call_path": [
            "$80FA JSR $A20F",
            "$A20F JMP $A86E",
            "$A86E CMP #$06; match index zero takes BCC to $A87C",
            "$A87E JSR $A8B7; $A8B7 JMP $A138",
            "$A138 copies $ACB0-$BFFF to $6000-$734F, then $A1E4 JMP $A8BB",
            "$A8BB-$A8CD copies eleven roster IDs and reaches RTS $A8CD to $A881",
            "$A8A3-$A8B6 derives formation/team/opponent and reaches RTS $A8B6 to $80FD",
        ],
    }
    (DESTINATION / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"PASS: packaged selector source with ROM SHA-256 {ROM_SHA256}")
    print(f"      copy span ${COPY_SOURCE_START:04X}-${COPY_SOURCE_END_EXCLUSIVE - 1:04X}, "
          f"{len(copy_bytes)} bytes, SHA-256 {sha256(copy_bytes)}")
    print(f"      manifest: {DESTINATION / 'manifest.json'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
