#!/usr/bin/env python3
"""Byte-check SOUND 40-99 pointer/header routes against the supplied ROM.

The Turkish community index supplies candidate sound-test ordinals and file
offsets. This audit verifies each table word and each sequence-header channel
pointer in the named Turkish ROM revision; it does not synthesize audio.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
BANK_C_FILE_BASE = 0x18010
POINTER_TABLE_FILE_BASE = 0x18BEA
MAX_BANK_C_CPU_ADDRESS = 0xA000

# Turkish community post: SOUND ordinal -> sequence file offset, pointer-word
# file offset. These are hypotheses until the ROM-byte checks below pass.
SFX_INDEX = [
    (40, 0x18E78, 0x18BEE), (41, 0x18E99, 0x18BF0),
    (42, 0x18EDF, 0x18BF2), (43, 0x18FBD, 0x18BF4),
    (44, 0x18F24, 0x18BF6), (45, 0x190B4, 0x18BF8),
    (46, 0x19245, 0x18BFA), (47, 0x196DC, 0x18BFC),
    (48, 0x19759, 0x18BFE), (49, 0x19191, 0x18C00),
    (50, 0x191FA, 0x18C02), (51, 0x1912D, 0x18C04),
    (52, 0x19089, 0x18C06), (53, 0x18F6A, 0x18C08),
    (54, 0x18FCB, 0x18C0A), (55, 0x1943D, 0x18C0C),
    (56, 0x19472, 0x18C0E), (57, 0x194D6, 0x18C10),
    (58, 0x19DF4, 0x18C12), (59, 0x19E0D, 0x18C14),
    (60, 0x19369, 0x18C16), (61, 0x19663, 0x18C18),
    (62, 0x19E8F, 0x18C1A), (63, 0x19787, 0x18C1C),
    (64, 0x19B2E, 0x18C1E), (65, 0x19EE3, 0x18C20),
    (66, 0x19ADD, 0x18C22), (67, 0x19B60, 0x18C24),
    (68, 0x19BAD, 0x18C26), (69, 0x19F07, 0x18C2C),
    (70, 0x1953D, 0x18C2E), (71, 0x19567, 0x18C30),
    (72, 0x19CFE, 0x18C32), (73, 0x19D68, 0x18C34),
    (74, 0x19D83, 0x18C36), (75, 0x19A65, 0x18C38),
    (76, 0x197E6, 0x18C3A), (77, 0x19A87, 0x18C3C),
    (78, 0x19463, 0x18C3E), (79, 0x19813, 0x18C40),
    (80, 0x19AAA, 0x18C42), (81, 0x197AD, 0x18C44),
    (82, 0x1982B, 0x18C46), (83, 0x19C23, 0x18C48),
    (84, 0x19F56, 0x18CA6), (85, 0x1988E, 0x18CA8),
    (86, 0x198CD, 0x18CAA), (87, 0x19954, 0x18CAC),
    (88, 0x1999E, 0x18CAE), (89, 0x19CDB, 0x18CB0),
    (90, 0x199C4, 0x18CB2), (91, 0x19A0C, 0x18CB4),
    (92, 0x199F7, 0x18CB8), (93, 0x19FAC, 0x18CBA),
    (94, 0x19C45, 0x18CBC), (95, 0x19FDA, 0x18CBE),
    (96, 0x19C23, 0x18C48), (97, 0x19D18, 0x18CC2),
    (98, 0x19E6D, 0x18CC4), (99, 0x19E31, 0x18CC6),
]

TRACE_PATH = ROOT / "reference/diagnostics/audio/opening_timeline_rom_driver_pre_start_tail_4661f.json"
BGM_INDEX_PATH = ROOT / "reference/rom_extract/audio/sound_test_bgm_index_00_39.json"
JSON_OUTPUT = ROOT / "reference/rom_extract/audio/sound_test_sfx_index_40_99.json"
MD_OUTPUT = ROOT / "reference/rom_extract/audio/sound_test_sfx_index_audit_20261025.md"


def cpu_to_file(cpu_address: int) -> int:
    if not 0x8000 <= cpu_address < MAX_BANK_C_CPU_ADDRESS:
        raise ValueError(f"bank-$0C pointer outside its fixed window: ${cpu_address:04X}")
    return BANK_C_FILE_BASE + cpu_address - 0x8000


def cpu_to_file_in_window(cpu_address: int, file_base: int, cpu_base: int) -> int:
    if not cpu_base <= cpu_address < cpu_base + 0x2000:
        raise ValueError(f"pointer outside selected 8 KiB bank window: ${cpu_address:04X}")
    return file_base + cpu_address - cpu_base


def event_bank_mapper(runtime_id: int):
    if 0x51 <= runtime_id <= 0x5B:
        # The bank-0C driver selects PRG bank 0F at $A000-$BFFF for these IDs.
        return lambda cpu: cpu_to_file_in_window(cpu, 0x1E010, 0xA000), "0x0F/$A000"
    # The opening trace enters this path with bank 0C in the fixed $8000 window;
    # IDs $5C+ restore the saved R7 bank, which is $0C in this replay.
    return cpu_to_file, "0x0C/$8000"


def check_stream_header(rom: bytes, target_file: int, mapper=cpu_to_file) -> dict:
    cursor = target_file
    channels = []
    while cursor < len(rom):
        channel_id = rom[cursor]
        if channel_id == 0xFF:
            terminator_offset = cursor
            break
        if len(channels) >= 8:
            raise ValueError(f"header at 0x{target_file:X} exceeds 8 channels")
        if cursor + 2 >= len(rom):
            raise ValueError(f"truncated channel record at 0x{cursor:X}")
        if channel_id > 0x07:
            raise ValueError(
                f"unexpected channel id ${channel_id:02X} at 0x{cursor:X}"
            )
        pointer = rom[cursor + 1] | (rom[cursor + 2] << 8)
        stream_file = mapper(pointer)
        channels.append({
            "channel_id": channel_id,
            "record_file_offset": f"0x{cursor:05X}",
            "pointer_le_hex": rom[cursor + 1:cursor + 3].hex().upper(),
            "stream_cpu_address": f"${pointer:04X}",
            "stream_file_offset": f"0x{stream_file:05X}",
            "stream_prefix_hex": rom[stream_file:stream_file + 16].hex(" ").upper(),
            "stream_starts_at_terminator": rom[stream_file] == 0xFF,
        })
        cursor += 3
    else:
        raise ValueError(f"header at 0x{target_file:X} has no $FF terminator")

    header_bytes = rom[target_file:terminator_offset + 1]
    return {
        "header_file_offset": f"0x{target_file:05X}",
        "header_bytes_hex": header_bytes.hex(" ").upper(),
        "header_terminator_file_offset": f"0x{terminator_offset:05X}",
        "header_terminator_verified": True,
        "channels": channels,
        "all_channels_start_at_terminator": bool(channels)
            and all(channel["stream_starts_at_terminator"] for channel in channels),
    }


def load_sound_test_maps() -> tuple[dict[int, int], dict[int, list[int]]]:
    bgm_data = json.loads(BGM_INDEX_PATH.read_text(encoding="utf-8"))
    bgm_by_runtime_id = {}
    for track in bgm_data["tracks"]:
        pointer_offset = int(track["pointer_table_file_offset"], 16)
        runtime_id = (pointer_offset - POINTER_TABLE_FILE_BASE) // 2 + 1
        bgm_by_runtime_id[runtime_id] = track["sound_test_ordinal"]
    sfx_by_runtime_id: dict[int, list[int]] = {}
    for ordinal, _, pointer_offset in SFX_INDEX:
        runtime_id = (pointer_offset - POINTER_TABLE_FILE_BASE) // 2 + 1
        sfx_by_runtime_id.setdefault(runtime_id, []).append(ordinal)
    return bgm_by_runtime_id, sfx_by_runtime_id


def main() -> None:
    rom = ROM_PATH.read_bytes()
    rom_sha = hashlib.sha256(rom).hexdigest()
    if rom_sha != ROM_SHA256:
        raise SystemExit(f"wrong ROM revision: {rom_sha}")

    bgm_by_runtime_id, sfx_by_runtime_id = load_sound_test_maps()
    records = []
    by_runtime_id = {}
    for ordinal, expected_target, pointer_file in SFX_INDEX:
        if (pointer_file - POINTER_TABLE_FILE_BASE) & 1:
            raise SystemExit(f"odd pointer-table displacement at 0x{pointer_file:X}")
        pointer_bytes = rom[pointer_file:pointer_file + 2]
        if len(pointer_bytes) != 2:
            raise SystemExit(f"truncated pointer word at 0x{pointer_file:X}")
        cpu_pointer = pointer_bytes[0] | (pointer_bytes[1] << 8)
        actual_target = cpu_to_file(cpu_pointer)
        if actual_target != expected_target:
            raise SystemExit(
                f"SOUND {ordinal} target mismatch: 0x{actual_target:X} != 0x{expected_target:X}"
            )
        runtime_id = (pointer_file - POINTER_TABLE_FILE_BASE) // 2 + 1
        record = {
            "sound_test_ordinal": ordinal,
            "category": "SFX",
            "pointer_table_file_offset": f"0x{pointer_file:05X}",
            "runtime_queue_id_from_driver_index": f"0x{runtime_id:02X}",
            "pointer_word_le_hex": pointer_bytes.hex().upper(),
            "resolved_cpu_address": f"${cpu_pointer:04X}",
            "sequence_file_offset": f"0x{actual_target:05X}",
            "sequence_header": check_stream_header(rom, actual_target),
            "rom_pointer_target_verified": True,
        }
        records.append(record)
        by_runtime_id.setdefault(runtime_id, []).append(record)

    trace = json.loads(TRACE_PATH.read_text(encoding="utf-8"))
    trigger_records = []
    for cue in trace["source_command_frames"]:
        runtime_id = int(cue["sound_id"], 16)
        pointer_file = POINTER_TABLE_FILE_BASE + 2 * (runtime_id - 1)
        pointer_bytes = rom[pointer_file:pointer_file + 2]
        cpu_pointer = pointer_bytes[0] | (pointer_bytes[1] << 8)
        map_cpu, bank_route = event_bank_mapper(runtime_id)
        target_file = map_cpu(cpu_pointer)
        provenance = next((
            item for item in trace["source_event_provenance"]
            if item["frame"] == cue["frame"] and item["sound_id"] == runtime_id
        ), {})
        test_matches = []
        if runtime_id in bgm_by_runtime_id:
            test_matches.append({"ordinal": bgm_by_runtime_id[runtime_id], "category": "BGM"})
        for ordinal in sorted(set(sfx_by_runtime_id.get(runtime_id, []))):
            test_matches.append({"ordinal": ordinal, "category": "SFX"})
        trigger_records.append({
            "source_frame": cue["frame"],
            "runtime_queue_id": f"0x{runtime_id:02X}",
            "queue_origin_status": provenance.get("source_status", "capture_observed"),
            "queue_source": provenance.get("command_source", "capture queue trace"),
            "sound_test_matches": test_matches,
            "pointer_table_file_offset": f"0x{pointer_file:05X}",
            "pointer_word_le_hex": pointer_bytes.hex().upper(),
            "resolved_cpu_address": f"${cpu_pointer:04X}",
            "resolved_file_offset": f"0x{target_file:05X}",
            "active_prg_route_for_trace": bank_route,
            "sequence_header": check_stream_header(rom, target_file, map_cpu),
        })

    output = {
        "title": "Captain Tsubasa II: Super Striker (Turkish ROM)",
        "target_rom_sha256": rom_sha,
        "scope": "Byte audit of community-indexed SOUND 40-99 SFX sequence pointers and their channel-header routes; opening queue IDs are mapped separately.",
        "external_index_source": "https://tsubasatr.net/konu-ct2-muzik-sistemi-nasil-calisir.html",
        "bank_mapping": {
            "fixed_bank": "0x0C",
            "file_range": "0x18010-0x1A00F",
            "cpu_window": "$8000-$9FFF",
            "pointer_table_file_base": "0x18BEA",
            "runtime_lookup_formula": "table_file = 0x18BEA + 2*(runtime_queue_id-1)",
            "cpu_pointer_to_file_formula": "0x18010 + (cpu_pointer - 0x8000)",
        },
        "validation": {
            "entries_checked": len(records),
            "pointer_words_matching_external_target_offsets": sum(
                record["rom_pointer_target_verified"] for record in records
            ),
            "sequence_headers_with_verified_ff_terminator": sum(
                record["sequence_header"]["header_terminator_verified"] for record in records
            ),
            "channel_pointer_targets_checked": sum(
                len(record["sequence_header"]["channels"]) for record in records
            ),
            "external_track_labels_used_as_rom_evidence": False,
        },
        "effects": records,
        "opening_same_input_trace": {
            "source_trace": "reference/diagnostics/audio/opening_timeline_rom_driver_pre_start_tail_4661f.json",
            "events": trigger_records,
        },
        "limits": [
            "The SFX ordinal/target candidate table comes from the Turkish community post; every listed pointer word and mapped target was independently checked against this target ROM hash.",
            "Channel headers and stream pointer prefixes are byte-checked; this audit does not decode every SFX command, establish sound design names, or prove sample-level audio.",
            "The same-input queue trace records the IDs and frames. Only ROM-command entries marked rom_command_verified_frame_capture_anchored have a fully verified cutscene command origin; other queue writes remain capture-observed with producer context unresolved.",
        ],
    }

    JSON_OUTPUT.write_text(json.dumps(output, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    write_markdown(output)
    print(json.dumps(output["validation"], indent=2))
    print(f"Wrote {JSON_OUTPUT.relative_to(ROOT)}")
    print(f"Wrote {MD_OUTPUT.relative_to(ROOT)}")


def write_markdown(audit: dict) -> None:
    lines = [
        "# SOUND 40–99 SFX pointer and opening-cue audit",
        "",
        "Checked against the supplied Turkish ROM; emulator audio is not an input.",
        "",
        f"ROM SHA-256: `{audit['target_rom_sha256']}`",
        "",
        "## ROM-derived table map",
        "",
        "The driver lookup at bank `$0C` uses runtime queue ID minus one to index",
        "the little-endian pointer table beginning at file `0x18BEA` (CPU `$8BDA`).",
        "For each row below, the Turkish community post's candidate test ordinal,",
        "table-word location, and target offset are checked against the actual ROM",
        "bytes. The table location also yields the runtime queue ID shown here.",
        "",
        "Japanese catalog labels are not used for SFX: the Japanese catalog only",
        "labels BGM ordinals 00–39. SOUND 40–99 are treated here as ordinal IDs,",
        "not as names or sound categories embedded in the ROM.",
        "",
        "| SOUND ordinal | Runtime ID | Pointer word at file offset | Bytes → CPU pointer | Resolved sequence file offset | Channel route (channel → CPU stream pointer / file offset) |",
        "|---:|---:|---:|---|---:|---|",
    ]
    for effect in audit["effects"]:
        route = "; ".join(
            f"{channel['channel_id']} → {channel['stream_cpu_address']} / {channel['stream_file_offset']}"
            for channel in effect["sequence_header"]["channels"]
        )
        lines.append(
            f"| {effect['sound_test_ordinal']:02d} | {effect['runtime_queue_id_from_driver_index']} "
            f"| `{effect['pointer_table_file_offset']}` | `{effect['pointer_word_le_hex']}` → "
            f"`{effect['resolved_cpu_address']}` | `{effect['sequence_file_offset']}` | {route} |"
        )
    lines += [
        "",
        f"Verified {audit['validation']['entries_checked']}/60 pointer words and "
        f"{audit['validation']['channel_pointer_targets_checked']} channel-pointer destinations. "
        "Each target header was parsed through its `$FF` terminator; raw header and",
        "stream-prefix bytes are preserved in the adjacent JSON audit.",
        "",
        "## SOUND IDs queued during the same-input opening trace",
        "",
        "These are runtime queue IDs read from the existing source-frame capture,",
        "not sound-test ordinals. The output route is independently resolved through",
        "the target ROM's `$8BDA` table. Repeated frames are listed individually.",
        "",
        "| Source frame | Runtime ID | Test ordinal, if mapped | Queue origin evidence | Sequence route |",
        "|---:|---:|---|---|---|",
    ]
    for event in audit["opening_same_input_trace"]["events"]:
        matches = ", ".join(
            f"{match['category']} {match['ordinal']:02d}"
            for match in event["sound_test_matches"]
        )
        if not matches:
            runtime_id = int(event["runtime_queue_id"], 16)
            matches = "empty sequence" if runtime_id == 0x02 else (
                "stop-all control" if runtime_id == 0x01 else "no test-index mapping"
            )
        origin = event["queue_origin_status"].replace("_", " ")
        lines.append(
            f"| {event['source_frame']} | {event['runtime_queue_id']} | {matches} | "
            f"{origin} | `{event['resolved_file_offset']}` (`{event['resolved_cpu_address']}`) |"
        )
    lines += [
        "",
        "Runtime `$02` resolves to a header whose four channel pointers all land on",
        "`$FF` terminators, so it is a queued empty/silent sequence; no sound-test",
        "ordinal is listed for it. Runtime `$01` resolves to the driver's stop-all",
        "sentinel; it is a control route, not an SFX entry. Other queue writes remain",
        "capture-observed where the source command producer has not yet been mapped.",
        "",
        "## Evidence and limits",
        "",
        f"- External pointer/target index: [TsubasaTR, CT2 music-system post]({audit['external_index_source']}).",
        "- The ROM checksum, pointer bytes, address translation, header records, and channel-stream pointer prefixes are checked locally by `tools/audio/audit_sound_test_sfx_index.py`.",
        "- The opening frame/ID list comes from `reference/diagnostics/audio/opening_timeline_rom_driver_pre_start_tail_4661f.json`; it does not establish all queue producers as cutscene commands.",
        "- This is pointer/route metadata, not a full SFX command decoder, PCM dump, or runtime audio asset. It does not add Japanese track names to the ROM-derived data.",
        "",
    ]
    MD_OUTPUT.write_text("\n".join(lines), encoding="utf-8")


if __name__ == "__main__":
    main()
