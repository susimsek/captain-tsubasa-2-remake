#!/usr/bin/env python3
"""Extract the ROM source spans at the PASS-confirmation return and holder commit."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUT_DIR = ROOT / "reference/rom_extract/gameplay/pass_receiver_holder_transfer"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

# This Turkish ROM is an iNES image with a 16-byte header, mapper 4, and
# 8-KiB PRG bank slots. All offsets below include the header.
PRG_BASE = 0x10
PRG_BANK_SIZE = 0x2000

SPANS: list[dict[str, object]] = [
    {
        "name": "pass_confirmation_wait_return_D70C_D717",
        "file": "pass_confirmation_wait_return_D70C_D717.bin",
        "bank": 0x1E,
        "window_start": 0xC000,
        "cpu_start": 0xD70C,
        "cpu_end_exclusive": 0xD717,
        "role": "PASS confirmation's shared task wait, cleanup flag clear, caller-stack unwind, and RTS.",
        "bytes_hex": "20 46 cc a9 00 8d 2d 06 68 68 60",
    },
    {
        "name": "pass_holder_commit_and_scenario_handoff_DE6C_DE96",
        "file": "pass_holder_commit_and_scenario_handoff_DE6C_DE96.bin",
        "bank": 0x1E,
        "window_start": 0xC000,
        "cpu_start": 0xDE6C,
        "cpu_end_exclusive": 0xDE96,
        "role": "Commits selected slot $05FC into holder $0441, copies holder coordinates, maps $1A/$1B, runs vector $801E, enqueues scenario $1C, resets SP, and jumps to $E0DF. The branch target at $DE96 is included.",
        "bytes_hex": "ad fc 05 c9 ff f0 23 8d 41 04 20 ec e6 48 a5 22 a9 1a 85 24 a9 1b 85 25 20 2d ce 68 20 1e 80 a9 1c 20 b0 cb a2 50 9a 4c df e0",
    },
    {
        "name": "bank1A_field_event_vector_801E_8021",
        "file": "bank1a_field_event_vector_801E_8021.bin",
        "bank": 0x1A,
        "window_start": 0x8000,
        "cpu_start": 0x801E,
        "cpu_end_exclusive": 0x8021,
        "role": "Vector selected after $DE88 maps bank $1A; JMPs to bank-$1A routine $8B4A.",
        "bytes_hex": "4c 4a 8b",
    },
    {
        "name": "bank1A_field_event_prefix_8B4A_8B69",
        "file": "bank1a_field_event_prefix_8B4A_8B69.bin",
        "bank": 0x1A,
        "window_start": 0x8000,
        "cpu_start": 0x8B4A,
        "cpu_end_exclusive": 0x8B69,
        "role": "Initial vector target instructions; calls $8B9C and $C624. This prefix does not claim the full event routine or its return.",
        "bytes_hex": "20 9c 8b b0 01 60 20 24 c6 a9 00 8d 00 06 8a a2 02 4d fb 05 f0 02 a2 01 8e 21 06 a9 ff 8d 1a",
    },
]

EXISTING_DEPENDENCIES = [
    {
        "cpu": "$CC46-$CCD1",
        "path": "reference/rom_extract/gameplay/field_entry_renderer_wrapper/fixed_shared_waiter_CC46_CCD2.bin",
        "sha256": "21a4cd33eb56fe3d4da516e0eff910ff375a8d7c3ff42bfa46dfb691a846d5cc",
        "role": "Called at $D70C; its cooperative wait/yield path must finish before execution resumes at $D70F.",
    },
    {
        "cpu": "$E6EC-$E708",
        "path": "reference/rom_extract/gameplay/first_command_field/holder_coordinates/bank_1f_e6ec_holder_coordinate_copy.bin",
        "sha256": "3bf0cf8593e6eccf77d32044c666a39713134e8120a2e3e7deba3541bb6fbf8c",
        "role": "Called at $DE76; resolves the live $0441 player record and writes its destination tile to $05FE.",
    },
    {
        "cpu": "$CD7C-$CD88",
        "path": "reference/rom_extract/gameplay/fresh_bank18_worker_prefix/fixed_record_pointer_resolver_CD7C_CD89.bin",
        "sha256": "8d7d8153252420175055aa5ef041e0e9dd85f99bb9dae8e24200e9549487ed24",
        "role": "Called by $E6EC; resolves the live holder slot into a player-record pointer.",
    },
    {
        "cpu": "$CDE2-$CE07",
        "path": "reference/rom_extract/gameplay/first_command_field/holder_coordinates/bank_1f_cde2_coordinate_index_helper.bin",
        "sha256": "e5f6dcb9f5d2451ba1770add2906daa504befaf7800e3bfe2e1b163708e58a83",
        "role": "Called by $E6EC; converts the copied X/Y position into a field-tile index.",
    },
    {
        "cpu": "$CE2D-$CE49",
        "path": "reference/rom_extract/gameplay/fresh_bank18_worker_prefix/fixed_stamina_bank_switch_CE2D_CE4A.bin",
        "sha256": "6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c",
        "role": "Maps PRG banks selected by the caller's $24/$25 shadows before the $801E call.",
    },
    {
        "cpu": "$CBB0-$CBC1",
        "path": "reference/rom_extract/gameplay/scenario_task_runtime/fixed_scenario_queue_CBB0_CBC1.bin",
        "sha256": "bda16c7ced2834027dd6039a6c079a701dc8abd9c89179ba2d3c568aa0a16a32",
        "role": "Called with A=$1C at $DE8D; stores scenario ID and requests the normal scheduler handoff.",
    },
    {
        "cpu": "$E0DF-$E0E3",
        "path": "reference/rom_extract/gameplay/field_entry_renderer_wrapper/fixed_field_entry_first_wrapper_E0DF_E0E4.bin",
        "sha256": "8988952df5477e6c5bf86bfe4bd64d0116b2ff652bbf50d9d4298708cbdb0d12",
        "role": "Direct jump target at $DE93; selects descriptor $00 and enters the field renderer wrapper.",
    },
]


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def bank_offset(bank: int, window_start: int, cpu_address: int) -> int:
    if not (window_start <= cpu_address < window_start + PRG_BANK_SIZE):
        raise ValueError(f"CPU address ${cpu_address:04X} is outside bank window")
    return PRG_BASE + bank * PRG_BANK_SIZE + cpu_address - window_start


def main() -> int:
    if not ROM_PATH.is_file():
        raise SystemExit(f"Supplied ROM not found: {ROM_PATH.name}")
    rom = ROM_PATH.read_bytes()
    if sha256(rom) != ROM_SHA256:
        raise SystemExit("Supplied ROM SHA-256 does not match the pinned Turkish revision")
    if rom[:4] != b"NES\x1a" or len(rom) != 393_232:
        raise SystemExit("Unexpected iNES header or ROM length")
    mapper = (rom[6] >> 4) | (rom[7] & 0xF0)
    if mapper != 4 or rom[4] != 16:
        raise SystemExit(f"Expected mapper 4 with 16 PRG 16-KiB units, got mapper={mapper}, PRG={rom[4]}")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    emitted: list[dict[str, object]] = []
    for source in SPANS:
        start = int(source["cpu_start"])
        end = int(source["cpu_end_exclusive"])
        offset = bank_offset(int(source["bank"]), int(source["window_start"]), start)
        payload = rom[offset : offset + end - start]
        expected = bytes.fromhex(str(source["bytes_hex"]))
        if payload != expected or len(payload) != end - start:
            raise SystemExit(f"ROM bytes differ from the pinned instruction span: {source['name']}")
        target = OUT_DIR / str(source["file"])
        target.write_bytes(payload)
        entry = {
            **source,
            "bank": f"0x{int(source['bank']):02X}",
            "window_start": f"0x{int(source['window_start']):04X}",
            "cpu_start": f"0x{start:04X}",
            "cpu_end_exclusive": f"0x{end:04X}",
            "file_offset": f"0x{offset:06X}",
            "length_bytes": len(payload),
            "sha256": sha256(payload),
            "bytes_hex": payload.hex(" "),
        }
        emitted.append(entry)

    # Validate referenced shared sources instead of silently documenting stale paths.
    dependency_results: list[dict[str, object]] = []
    for dependency in EXISTING_DEPENDENCIES:
        row = dict(dependency)
        path = ROOT / str(row["path"])
        row["exists"] = path.is_file()
        if path.is_file() and path.suffix == ".bin":
            actual = sha256(path.read_bytes())
            if row["sha256"] and actual != row["sha256"]:
                raise SystemExit(f"Existing source dependency hash changed: {row['path']}")
            row["actual_sha256"] = actual
        elif not bool(row["exists"]):
            raise SystemExit(f"Referenced source dependency is missing: {row['path']}")
        dependency_results.append(row)

    manifest = {
        "schema": "ct2-pass-receiver-holder-transfer-source-v1",
        "source_rom": {
            "name": ROM_PATH.name,
            "sha256": ROM_SHA256,
            "size_bytes": len(rom),
            "format": "iNES",
            "mapper": mapper,
            "prg_16k_units": rom[4],
            "prg_8k_bank_count": rom[4] * 2,
        },
        "bank_mapping": {
            "prg_bank_size_bytes": PRG_BANK_SIZE,
            "header_bytes": PRG_BASE,
            "file_offset_formula": "0x10 + (8-KiB PRG bank * 0x2000) + (CPU address - window start)",
            "bank_1e_window": "$C000-$DFFF; switchable MMC3 PRG bank $1E in the observed route",
            "bank_1a_window": "$8000-$9FFF; switchable MMC3 PRG bank $1A after $CE2D",
        },
        "scope": "Preserves the ROM-byte PASS waiter return and post-confirm holder-commit caller, plus the initial bank-$1A vector target. This package does not execute the task waiter, intervening field movement, full $8B4A event routine, scenario $1C, renderer, or PPU/NMI cadence.",
        "spans": emitted,
        "existing_dependencies": dependency_results,
        "trace_reference": {
            "report": "reference/rom_extract/gameplay/first_pass_action_trace_20261110.md",
            "temporary_logs": [
                "/tmp/ct2_first_pass_action_next_menu/events.csv",
                "/tmp/ct2_first_pass_action_next_menu/writes.csv",
            ],
            "emulator": "FCEUX 2.7.0; NTSC; NewPPU; muted",
            "interpretation": "Frame labels are emulator frame advances, not hardware beam/cycle timing.",
        },
    }
    (OUT_DIR / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    for span in emitted:
        print(f"{span['name']}: ${span['cpu_start'][2:]}-${span['cpu_end_exclusive'][2:]} "
              f"offset={span['file_offset']} sha256={span['sha256']}")
    print(f"Verified dependencies: {sum(bool(item['exists']) for item in dependency_results)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
