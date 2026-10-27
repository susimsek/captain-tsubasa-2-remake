#!/usr/bin/env python3
"""Slot-by-slot validation of BG08 source OAM, DMA culling, and Godot output."""
from __future__ import annotations
import csv
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
RAM_FILE = ROOT / "reference/opening_timing_capture_20261024_125148/ram_states/ram_01087.bin"
REPORT_FILE = ROOT / "reference/diagnostics/bg08_oam_frame1088_oam_audit/runtime_oam.json"
ROM_FILE = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
TIMING_FILE = ROOT / "reference/rom_extract/intro/animation_timing_entry.json"
FRAMES_FILE = ROOT / "reference/rom_extract/intro/sprite_frames_entry.json"
OUT_DIR = REPORT_FILE.parent


def tuple_at(data: bytes, start: int, slot: int) -> tuple[int, int, int, int]:
    return tuple(data[start + slot * 4:start + slot * 4 + 4])  # type: ignore[return-value]


def signed16_pair(record: bytes) -> tuple[int, int]:
    y = record[4] | (record[5] << 8)
    x = record[6] | (record[7] << 8)
    return (y - 0x10000 if y & 0x8000 else y,
            x - 0x10000 if x & 0x8000 else x)


def main() -> None:
    rom_hash = hashlib.sha256(ROM_FILE.read_bytes()).hexdigest()
    if rom_hash != EXPECTED_ROM_SHA256:
        raise SystemExit(f"ROM identity mismatch: {rom_hash}")
    report = json.loads(REPORT_FILE.read_text())
    checkpoint = report["checkpoints"][0]
    oam_doc = checkpoint["oam"]
    godot = bytes.fromhex(oam_doc["shared_oam_bytes_hex"])
    ram = RAM_FILE.read_bytes()
    shadow_start, dma_start = 0x468, 0x200
    timing = json.loads(TIMING_FILE.read_text())
    frames_doc = json.loads(FRAMES_FILE.read_text())
    frame_by_address = {f["cpu_address"].lower(): f for f in frames_doc["frames"]}
    tracks = oam_doc["tracks"]
    coords: dict[int, tuple[int, int, str]] = {}
    for track in tracks:
        frame = frame_by_address.get(str(track["frame_address"]).lower())
        if not frame:
            continue
        record = bytes.fromhex(track["record_bytes_hex"])
        y_raw, x_raw = signed16_pair(record)
        origin_y, origin_x = y_raw // 128, x_raw // 128
        for sprite_index, sprite in enumerate(frame["sprites"]):
            slot = (int(track["oam_start_slot"]) + sprite_index) % 64
            coords[slot] = (
                origin_x + int(sprite["x_offset_from_animation"]),
                origin_y + int(sprite["y_offset_from_animation"]),
                str(track["animation_id"]),
            )
    owners = oam_doc["slot_owners"]
    rows = []
    for slot in range(64):
        gt = tuple_at(godot, 0, slot)
        sh = tuple_at(ram, shadow_start, slot)
        dma = tuple_at(ram, dma_start, slot)
        marker = sh[2] & 0x0C
        expected_dma = (0xF8 if marker else sh[0], sh[1], sh[2], sh[3])
        godot_marker = gt[2] & 0x0C
        godot_dma = (0xF8 if godot_marker else gt[0], gt[1], gt[2], gt[3])
        x_calc, y_calc, animation_id = coords.get(slot, (-999, -999, ""))
        predicted_marker = (0x04 if x_calc < 0 or x_calc > 255 else 0) | (0x08 if y_calc < 0 or y_calc > 255 else 0)
        rows.append({
            "slot": slot,
            "owner": owners[slot] if slot < len(owners) else "",
            "animation_id": animation_id,
            "godot_y_tile_attr_x": " ".join(f"{v:02X}" for v in gt),
            "rom_shadow_y_tile_attr_x": " ".join(f"{v:02X}" for v in sh),
            "rom_dma_source_y_tile_attr_x": " ".join(f"{v:02X}" for v in dma),
            "predicted_pre_wrap_x": x_calc,
            "predicted_pre_wrap_y": y_calc,
            "expected_overflow_marker": f"{predicted_marker:02X}",
            "observed_shadow_overflow_marker": f"{marker:02X}",
            "godot_equals_shadow": gt == sh,
            "shadow_to_dma_copy_matches_A8CE_rule": dma == expected_dma,
            "godot_dma_copy_matches_A8CE_rule": godot_dma == dma,
        })
    out_csv = OUT_DIR / "slot_comparison.csv"
    with out_csv.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=rows[0].keys())
        writer.writeheader(); writer.writerows(rows)
    summary = {
        "rom_sha256": rom_hash,
        "display_frame": 1088,
        "fceux_oam_state_frame": 1087,
        "rom_cpu_oam_shadow_address": "$0468-$0567",
        "rom_dma_source_page": "$0200-$02FF",
        "godot_exact_slots_vs_shadow": sum(bool(r["godot_equals_shadow"]) for r in rows),
        "godot_exact_slots_vs_dma_source": sum(bool(r["godot_dma_copy_matches_A8CE_rule"]) for r in rows),
        "shadow_to_dma_matches_A8CE_rule": sum(bool(r["shadow_to_dma_copy_matches_A8CE_rule"]) for r in rows),
        "overflow_markers_match_coordinate_prediction": sum(
            r["expected_overflow_marker"] == r["observed_shadow_overflow_marker"] for r in rows
        ),
        "slots_with_overflow_markers": [r["slot"] for r in rows if r["observed_shadow_overflow_marker"] != "00"],
        "godot_mismatch_slots_vs_dma": [r["slot"] for r in rows if not r["godot_dma_copy_matches_A8CE_rule"]],
        "rom_file_offsets_checked_separately": ["0x001551", "0x0048DE", "0x004225"],
        "csv": str(out_csv.relative_to(ROOT)),
    }
    (OUT_DIR / "slot_comparison_summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
