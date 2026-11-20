#!/usr/bin/env python3
"""Preserve the target ROM bytes required by the gameplay actor OAM decoder."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUTPUT_DIR = ROOT / "reference/rom_extract/gameplay/actor_oam"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
BANK16_FILE_BASE = 0x02C010  # Bank $16 CPU $8000.

SEGMENTS = [
    {
        "name": "sprite_engine_8000_8185",
        "filename": "bank16_sprite_engine_8000_8185.bin",
        "cpu_start": 0x8000,
        "length": 0x186,
        "purpose": "actor transform, compact stream interpreter, and descriptor dispatch",
    },
    {
        "name": "sprite_offsets_81d2_8239",
        "filename": "bank16_sprite_offsets_81d2_8239.bin",
        "cpu_start": 0x81D2,
        "length": 0x68,
        "purpose": "40-byte Y offset table followed by 64-byte X offset table",
    },
    {
        "name": "sprite_descriptor_pointers_8280_842b",
        "filename": "bank16_sprite_descriptor_pointers_8280_842b.bin",
        "cpu_start": 0x8280,
        "length": 0x1AC,
        "purpose": "ROM OAM descriptor pointer table for descriptor IDs $00-$D5, including live E6 actors using descriptor $CA",
    },
    {
        "name": "live_e6_descriptor_ca_terminator_bd45",
        "filename": "bank16_live_e6_descriptor_CA_terminator_BD45.bin",
        "cpu_start": 0xBD45,
        "length": 0x01,
        "purpose": "Descriptor $CA stream's ROM end marker; the OAM interpreter terminates on this byte",
    },
    {
        "name": "live_e6_descriptor_ca_stream_bdd5_bde1",
        "filename": "bank16_live_e6_descriptor_CA_stream_BDD5_BDE1.bin",
        "cpu_start": 0xBDD5,
        "length": 0x0D,
        "purpose": "Descriptor $CA compact OAM runs for the two live E6 actors and their terminal opcode",
    },
    {
        "name": "animation66_descriptor_pointer_9e_83bc_83bd",
        "filename": "bank16_descriptor_pointer_9E_83BC_83BD.bin",
        "cpu_start": 0x83BC,
        "length": 0x02,
        "purpose": "ROM descriptor-$9E pointer entry resolving animation-$66 actors to the $B21E sprite stream",
    },
    {
        "name": "animation66_descriptor_pointer_9f_83be_83bf",
        "filename": "bank16_descriptor_pointer_9F_83BE_83BF.bin",
        "cpu_start": 0x83BE,
        "length": 0x02,
        "purpose": "ROM descriptor-$9F pointer entry resolving animation-$66 actors to the $B2CC sprite stream",
    },
    {
        "name": "first_command_sprite_streams_842c_8979",
        "filename": "bank16_first_command_sprite_streams_842c_8979.bin",
        "cpu_start": 0x842C,
        "length": 0x54E,
        "purpose": "descriptor $00/$04/$0A stream roots, selector tables, jump targets, and compact OAM runs",
    },
    {
        "name": "descriptor_0b_0e_streams_897a_89bb",
        "filename": "bank16_descriptor_0B_0E_streams_897A_89BB.bin",
        "cpu_start": 0x897A,
        "length": 0x42,
        "purpose": "descriptor $0B-$0E source streams and their jumps to shared selector streams",
    },
    {
        "name": "slot11_actor_descriptors_0f_12_streams_89bc_8b73",
        "filename": "bank16_slot11_actor_descriptors_0F_12_streams_89BC_8B73.bin",
        "cpu_start": 0x89BC,
        "length": 0x1B8,
        "purpose": "ROM selector tables and compact-OAM streams for slot-$11 descriptors $0F-$12, with all twelve selector branches checked for each descriptor",
    },
    {
        "name": "route_actor_descriptor_14_stream_8b81_8d0b",
        "filename": "bank16_route_actor_descriptor_14_stream_8B81_8D0B.bin",
        "cpu_start": 0x8B81,
        "length": 0x18B,
        "purpose": "ROM descriptor-$14 selector table, twelve branch roots, shared compact OAM paths, and terminal opcode before descriptor $15",
    },
    {
        "name": "route_actor_descriptor_18_stream_8d45_8d51",
        "filename": "bank16_route_actor_descriptor_18_stream_8D45_8D51.bin",
        "cpu_start": 0x8D45,
        "length": 0x0D,
        "purpose": "ROM descriptor-$18 compact OAM runs and terminal opcode before descriptor $19",
    },
    {
        "name": "route_actor_descriptor_15_stream_8d0c_8d1a",
        "filename": "bank16_route_actor_descriptor_15_stream_8D0C_8D1A.bin",
        "cpu_start": 0x8D0C,
        "length": 0x0F,
        "purpose": "ROM descriptor-$15 compact OAM runs and bounded jump to shared descriptor-$14 selector paths",
    },
    {
        "name": "route_actor_descriptor_16_stream_8d1b_8d2f",
        "filename": "bank16_route_actor_descriptor_16_stream_8D1B_8D2F.bin",
        "cpu_start": 0x8D1B,
        "length": 0x15,
        "purpose": "ROM descriptor-$16 compact OAM runs, selector branch, and jump to shared descriptor-$14 paths",
    },
    {
        "name": "route_actor_descriptor_1d_stream_8f56_8f62",
        "filename": "bank16_route_actor_descriptor_1D_stream_8F56_8F62.bin",
        "cpu_start": 0x8F56,
        "length": 0x0D,
        "purpose": "ROM descriptor-$1D compact OAM runs and terminal opcode at its own pointer-bounded source address",
    },
    {
        "name": "animation66_descriptor9e_prefix_b21e_b231",
        "filename": "bank16_animation66_descriptor9E_prefix_B21E_B231.bin",
        "cpu_start": 0xB21E,
        "length": 0x13,
        "purpose": "Animation-$66 descriptor-$9E leading OAM runs and selector table shared by descriptors $9E/$9F",
    },
    {
        "name": "animation66_descriptor9e_selector08_pointer_b23b_b23c",
        "filename": "bank16_animation66_descriptor9E_selector08_pointer_B23B_B23C.bin",
        "cpu_start": 0xB23B,
        "length": 0x02,
        "purpose": "Live actor selector-$08 pointer resolves the animation-$66 descriptor-$9E stream to $B287",
    },
    {
        "name": "animation66_descriptor9e_selector02_b287_b292",
        "filename": "bank16_animation66_descriptor9E_selector02_B287_B292.bin",
        "cpu_start": 0xB287,
        "length": 0x0B,
        "purpose": "Animation-$66 descriptor-$9E selector-$02 runs and jump from $B287 to $B24B",
    },
    {
        "name": "animation66_descriptor9e_jump_b24b_b276",
        "filename": "bank16_animation66_descriptor9E_jump_B24B_B276.bin",
        "cpu_start": 0xB24B,
        "length": 0x2B,
        "purpose": "Animation-$66 descriptor-$9E jump target at $B24B through its source $01 terminator at $B275",
    },
    {
        "name": "animation66_descriptor9f_prefix_b2cc_b2d8",
        "filename": "bank16_animation66_descriptor9F_prefix_B2CC_B2D8.bin",
        "cpu_start": 0xB2CC,
        "length": 0x0D,
        "purpose": "Animation-$66 descriptor-$9F initial compact OAM runs and jump to the shared selector table at $B22A",
    },
    {
        "name": "early_actor_descriptor_pointer_b7_83ee_83ef",
        "filename": "bank16_early_actor_descriptor_pointer_B7_83EE_83EF.bin",
        "cpu_start": 0x83EE,
        "length": 0x02,
        "purpose": "descriptor $B7 source pointer resolving to the bank-$16 OAM run stream at $BAE0",
    },
    {
        "name": "early_actor_descriptor_pointers_83f0_83f5",
        "filename": "bank16_early_actor_descriptor_pointers_83f0_83f5.bin",
        "cpu_start": 0x83F0,
        "length": 0x06,
        "purpose": "descriptor $B8/$B9/$BA source pointers resolving to $BB21/$BB62/$BB6D",
    },
    {
        "name": "early_actor_descriptor_b7_bae0_bb20",
        "filename": "bank16_early_actor_descriptor_B7_BAE0_BB20.bin",
        "cpu_start": 0xBAE0,
        "length": 0x41,
        "purpose": "descriptor $B7 compact OAM runs and terminal opcode for the initial scenario-$36 animation-$4E actor",
    },
    {
        "name": "early_actor_descriptor_b8_bb21_bb61",
        "filename": "bank16_early_actor_descriptor_B8_BB21_BB61.bin",
        "cpu_start": 0xBB21,
        "length": 0x41,
        "purpose": "descriptor $B8 compact OAM runs and terminal opcode",
    },
    {
        "name": "early_actor_descriptor_b9_bb62_bb6c",
        "filename": "bank16_early_actor_descriptor_B9_BB62_BB6C.bin",
        "cpu_start": 0xBB62,
        "length": 0x0B,
        "purpose": "descriptor $B9 compact OAM run and terminal opcode",
    },
    {
        "name": "early_actor_descriptor_ba_bb6d_bb7b",
        "filename": "bank16_early_actor_descriptor_BA_BB6D_BB7B.bin",
        "cpu_start": 0xBB6D,
        "length": 0x0F,
        "purpose": "descriptor $BA compact OAM runs and terminal opcode",
    },
    {
        "name": "descriptor_pointer_7d_837a_837b",
        "filename": "bank16_descriptor_pointer_7D_837A_837B.bin",
        "cpu_start": 0x837A,
        "length": 0x02,
        "purpose": "descriptor $7D pointer resolves to the bank-$16 compact sprite stream at $AA83",
    },
    {
        "name": "descriptor_pointer_table_73_7b_8366_8377",
        "filename": "bank16_descriptor_pointer_table_73_7B_8366_8377.bin",
        "cpu_start": 0x8366,
        "length": 0x12,
        "purpose": "ROM pointers for field actor descriptors $73-$7B",
    },
    {
        "name": "descriptor_pointer_72_8364_8365",
        "filename": "bank16_descriptor_pointer_72_8364_8365.bin",
        "cpu_start": 0x8364,
        "length": 0x02,
        "purpose": "ROM descriptor-$72 pointer entry resolving the first scenario-$36 actor pose to $A9B2",
    },
    {
        "name": "descriptor_pointer_71_8362_8363",
        "filename": "bank16_descriptor_pointer_71_8362_8363.bin",
        "cpu_start": 0x8362,
        "length": 0x02,
        "purpose": "ROM descriptor-$71 pointer entry resolving the next scenario-$36 actor pose to $A96F",
    },
    {
        "name": "descriptor_71_stream_a96f_a9b1",
        "filename": "bank16_descriptor_71_stream_A96F_A9B1.bin",
        "cpu_start": 0xA96F,
        "length": 0x43,
        "purpose": "ROM descriptor-$71 compact OAM runs and terminator for the next scenario-$36 field actor pose",
    },
    {
        "name": "descriptor_72_stream_a9b2_a9e0",
        "filename": "bank16_descriptor_72_stream_A9B2_A9E0.bin",
        "cpu_start": 0xA9B2,
        "length": 0x2F,
        "purpose": "ROM descriptor-$72 compact OAM runs and terminator for the first scenario-$36 field actor",
    },
    {
        "name": "descriptor_streams_73_79_a9e1_aa6b",
        "filename": "bank16_descriptor_streams_73_79_A9E1_AA6B.bin",
        "cpu_start": 0xA9E1,
        "length": 0x8B,
        "purpose": "ROM compact OAM streams for the first field actor's descriptor sequence $73-$79",
    },
    {
        "name": "descriptor_7a_stream_aa6c_aa78",
        "filename": "bank16_descriptor_7A_stream_AA6C_AA78.bin",
        "cpu_start": 0xAA6C,
        "length": 0x0D,
        "purpose": "descriptor $7A compact OAM runs and terminal opcode used by the first field actor",
    },
    {
        "name": "descriptor_7b_stream_aa79_aa7d",
        "filename": "bank16_descriptor_7B_stream_AA79_AA7D.bin",
        "cpu_start": 0xAA79,
        "length": 0x05,
        "purpose": "descriptor $7B compact OAM run and terminal opcode for the first field actor",
    },
    {
        "name": "descriptor_pointer_7c_8378_8379",
        "filename": "bank16_descriptor_pointer_7C_8378_8379.bin",
        "cpu_start": 0x8378,
        "length": 0x02,
        "purpose": "descriptor $7C source pointer resolves to the bank-$16 compact sprite stream at $AA7E",
    },
    {
        "name": "descriptor_7c_stream_aa7e_aa82",
        "filename": "bank16_descriptor_7C_stream_AA7E_AA82.bin",
        "cpu_start": 0xAA7E,
        "length": 0x05,
        "purpose": "descriptor $7C compact OAM run and terminal opcode for the first callback-$1F map actor pose",
    },
    {
        "name": "descriptor_7d_stream_aa83_aa87",
        "filename": "bank16_descriptor_7D_stream_AA83_AA87.bin",
        "cpu_start": 0xAA83,
        "length": 0x05,
        "purpose": "descriptor $7D single compact OAM run and terminal opcode for the frame-8663 actor",
    },
    {
        "name": "descriptor_cf_streams_be2d_bed5",
        "filename": "bank16_descriptor_CF_streams_BE2D_BED5.bin",
        "cpu_start": 0xBE2D,
        "length": 0xA9,
        "purpose": "descriptor $CF compact OAM selector table, all twelve branches, and shared jump paths through the terminator at $BE80; descriptor $D0 begins at $BED6",
    },
]


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    rom = ROM_PATH.read_bytes()
    rom_sha256 = sha256(rom)
    if rom_sha256 != EXPECTED_ROM_SHA256:
        raise SystemExit(f"Target ROM SHA-256 mismatch: {rom_sha256}")
    if len(rom) != 393232:
        raise SystemExit(f"Unexpected target ROM size: {len(rom)}")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    entries = []
    for segment in SEGMENTS:
        cpu_start = int(segment["cpu_start"])
        offset = BANK16_FILE_BASE + cpu_start - 0x8000
        length = int(segment["length"])
        data = rom[offset : offset + length]
        if len(data) != length:
            raise SystemExit(f"Truncated bank-$16 resource at CPU ${cpu_start:04X}")
        output_path = OUTPUT_DIR / str(segment["filename"])
        output_path.write_bytes(data)
        entries.append({
            "name": segment["name"],
            "path": str(output_path.relative_to(ROOT)),
            "bank": "0x16",
            "cpu_start": f"0x{cpu_start:04X}",
            "file_offset": f"0x{offset:06X}",
            "length_bytes": length,
            "sha256": sha256(data),
            "purpose": segment["purpose"],
        })

    manifest = {
        "resource_kind": "preserved ROM source bytes for the gameplay actor OAM decoder",
        "source_rom_filename": ROM_PATH.name,
        "source_rom_sha256": rom_sha256,
        "bank_window_file_base": f"0x{BANK16_FILE_BASE:06X}",
        "runtime_rom_dependency": False,
        "capture_or_screenshot_bytes_included": False,
        "segments": entries,
    }
    (OUTPUT_DIR / "manifest.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print(f"Preserved {len(entries)} target-ROM bank-$16 source spans under {OUTPUT_DIR.relative_to(ROOT)}")
    for entry in entries:
        print(f"${entry['cpu_start'][2:]}: {entry['length_bytes']} bytes sha256 {entry['sha256']}")


if __name__ == "__main__":
    main()
