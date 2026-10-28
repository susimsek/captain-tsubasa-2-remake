#!/usr/bin/env python3
"""Export ROM animation records used by the fresh-start KICK OFF cutscenes.

The raw animation records are copied byte-for-byte from the supplied Turkish
ROM. Timing and 8x8 sprite-frame descriptors are produced only by the existing
ROM bytecode decoders; no emulator screenshots, OAM captures, or captured audio
are inputs to these resources.
"""

from __future__ import annotations

import hashlib
import importlib.util
import json
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
MANIFESTS = [
    ROOT / "assets/gameplay/rom_logic/kickoff_cutscene_01_events.json",
    ROOT / "assets/gameplay/rom_logic/kickoff_cutscene_02_events.json",
]
OUT = ROOT / "reference/rom_extract/gameplay/animations/kickoff"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


def load_module(name: str, path: Path) -> Any:
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load decoder: {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


extractor = load_module("kickoff_intro_extractor", ROOT / "tools/extract_intro_cutscene.py")
timing_decoder = load_module("kickoff_animation_timing_decoder", ROOT / "tools/decode_intro_animation_timing.py")
frame_decoder = load_module("kickoff_sprite_frame_decoder", ROOT / "tools/decode_intro_sprite_frames.py")


def hex_value(value: int, width: int = 2) -> str:
    return f"0x{value:0{width}X}"


def read_u16(data: bytes, offset: int) -> int:
    return data[offset] | (data[offset + 1] << 8)


def cpu_address(bank: int, file_offset: int) -> int:
    """Map a file offset in a switchable 8 KiB PRG bank back to its CPU address."""
    bank_file_start = extractor.file_offset(bank, 0xA000)
    cpu = 0xA000 + file_offset - bank_file_start
    if not 0xA000 <= cpu < 0xC000:
        raise ValueError(f"File offset {file_offset:#08x} is outside PRG bank {bank}")
    return cpu


def parse_entry_from_bank_tail(rom: bytes, bank: int, start_cpu: int) -> tuple[dict, int]:
    """Decode an entry using bank tail as input, returning entry byte length.

    This is used only if the table's following word is not a mapped address.
    The entry parser stops at its first branch/jump/exit; that boundary is
    sufficient for the one encountered record (ID CB), whose entry exits.
    """
    start = extractor.file_offset(bank, start_cpu)
    tail = rom[start : extractor.file_offset(bank, 0xC000)]
    decoded = extractor.parse_animation_entry(tail, start)
    consumed = 1 + sum(len(bytes.fromhex(command["raw_hex"])) for command in decoded["entry_commands"])
    if not decoded["entry_commands"] or decoded["entry_commands"][-1]["kind"] != "exit":
        raise ValueError(
            f"Unbounded animation at bank {bank}, ${start_cpu:04X} does not have a linear FF exit; "
            "preserve its pointer-defined range and resolve the branch before bounding it"
        )
    return decoded, consumed


def collect_manifests() -> tuple[list[dict], dict[str, dict]]:
    invocations: list[dict] = []
    manifests: dict[str, dict] = {}
    for path in MANIFESTS:
        manifest = json.loads(path.read_text(encoding="utf-8"))
        if manifest.get("source_rom_sha256") != EXPECTED_ROM_SHA256:
            raise ValueError(f"ROM revision mismatch in {path}")
        if not manifest.get("event_boundaries_byte_verified"):
            raise ValueError(f"Event boundaries are not byte-verified in {path}")
        cutscene_id = path.stem.split("cutscene_", 1)[1].split("_", 1)[0]
        manifests[cutscene_id] = manifest
        for event in manifest["events"]:
            if event.get("kind") != "animations":
                continue
            ids = event["animation_ids"]
            invocations.append({
                "cutscene_id": int(cutscene_id),
                "event_index": event["event_index"],
                "script_offset": event["script_offset"],
                "cpu_address": hex_value(event["cpu_address"], 4),
                "file_offset": hex_value(event["file_offset"], 6),
                "requested_instance_count": event["arguments"][0],
                "animation_ids": [hex_value(value) for value in ids],
                "raw_hex": bytes(event["arguments"]).hex(" "),
            })
    return invocations, manifests


def get_animation_record(rom: bytes, animation_id: int) -> tuple[dict, bytes, int]:
    # Verified lookup rule from the original animation dispatch and the
    # cutscene-00 exporter: IDs $00-$6C index bank 9; IDs $6D+ index bank 10.
    bank = 9 if animation_id < 0x6D else 10
    index = animation_id if bank == 9 else animation_id - 0x6D
    table_offset = extractor.file_offset(bank, 0xA000)
    pointer_offset = table_offset + index * 2
    start_cpu = read_u16(rom, pointer_offset)
    next_cpu = read_u16(rom, pointer_offset + 2)
    if not 0xA000 <= start_cpu < 0xC000:
        raise ValueError(f"Animation ${animation_id:02X} has unmapped start pointer ${start_cpu:04X}")
    start_file = extractor.file_offset(bank, start_cpu)

    if 0xA000 <= next_cpu <= 0xC000 and next_cpu >= start_cpu:
        end_cpu = next_cpu
        span_method = "animation pointer table: current pointer to following pointer"
        raw = rom[start_file : extractor.file_offset(bank, end_cpu)]
        entry = extractor.parse_animation_entry(raw, start_file)
    else:
        # At the final used table slot ($CB), the next word is data outside the
        # mapped bank rather than an exclusive record pointer. Bound the
        # direct, terminating entry by the existing ROM-bytecode parser.
        entry, length = parse_entry_from_bank_tail(rom, bank, start_cpu)
        end_cpu = start_cpu + length
        if end_cpu > 0xC000:
            raise ValueError(f"Animation ${animation_id:02X} exits past its PRG bank")
        raw = rom[start_file : start_file + length]
        span_method = "linear entry parser through first FF; following table word is unmapped"

    if not raw:
        raise ValueError(f"Animation ${animation_id:02X} has an empty ROM record")
    # Both pointers are little-endian words embedded in the selected bank's
    # table. Keep the original pointer word even when it is a sentinel.
    record = {
        "id": hex_value(animation_id),
        "prg_bank": bank,
        "animation_pointer_table_file_offset": hex_value(pointer_offset, 6),
        "animation_pointer_table_index": index,
        "start_cpu_address": hex_value(start_cpu, 4),
        "start_file_offset": hex_value(start_file, 6),
        "following_table_word": hex_value(next_cpu, 4),
        "end_cpu_address_exclusive": hex_value(end_cpu, 4),
        "end_file_offset_exclusive": hex_value(extractor.file_offset(bank, end_cpu), 6),
        "source_span_method": span_method,
        "length_bytes": len(raw),
        "sha256": hashlib.sha256(raw).hexdigest(),
        "source_bin": f"animation_{animation_id:02X}.bin",
        "entry_decode": entry,
    }
    return record, raw, end_cpu


def get_dialog_branch_frames(rom: bytes, record: dict) -> list[dict]:
    """Resolve the two ROM frame pointers stored after a reachable `$FA`.

    `$FA` selection depends on the live dialog state, so the timing decoder
    deliberately stops there. We can still export both source frame programs
    and their state-to-pointer mapping from the byte operands.
    """
    branches: list[dict] = []
    bank = int(record["prg_bank"])
    for command in record["entry_decode"].get("entry_commands", []):
        if command.get("kind") != "dialog_branch":
            continue
        opcode_file_offset = int(command["file_offset"], 16)
        if rom[opcode_file_offset] != 0xFA:
            raise ValueError(f"Expected `$FA` at file offset {opcode_file_offset:#08x}")
        raw = rom[opcode_file_offset : opcode_file_offset + 5]
        if len(raw) != 5:
            raise ValueError(f"Truncated `$FA` pointer pair at file offset {opcode_file_offset:#08x}")
        targets = (read_u16(raw, 1), read_u16(raw, 3))
        choices = []
        for state_bit0, target_cpu in enumerate(targets):
            if not 0xA000 <= target_cpu < 0xC000:
                raise ValueError(
                    f"`$FA` state {state_bit0} in animation {record['id']} has invalid frame pointer ${target_cpu:04X}"
                )
            choices.append({
                "state_bit0": state_bit0,
                "frame_cpu_address": hex_value(target_cpu, 4),
                "frame_file_offset": hex_value(extractor.file_offset(bank, target_cpu), 6),
            })
        branches.append({
            "animation_id": record["id"],
            "prg_bank": bank,
            "opcode_cpu_address": hex_value(cpu_address(bank, opcode_file_offset), 4),
            "opcode_file_offset": hex_value(opcode_file_offset, 6),
            "raw_hex": raw.hex(" "),
            "selector": "dialog flag $0099 bit 0; the source handler loads offset 1/2 for 0 and 3/4 for 1",
            "choices": choices,
        })
    return branches


def source_spans_for_frame(rom: bytes, frame: dict) -> list[dict]:
    """Group a decoded frame's header and executed commands into exact ROM spans."""
    bank = int(frame["prg_bank"])
    start_cpu = int(frame["cpu_address"], 16)
    base_file_offset = int(frame["file_offset"], 16)
    source_offsets = set(range(base_file_offset, base_file_offset + 4))
    for command in frame["commands"]:
        command_offset = int(command["file_offset"], 16)
        command_bytes = bytes.fromhex(command["raw_hex"])
        if rom[command_offset : command_offset + len(command_bytes)] != command_bytes:
            raise ValueError(f"Decoded frame bytes disagree with ROM at {command_offset:#08x}")
        source_offsets.update(range(command_offset, command_offset + len(command_bytes)))

    spans: list[dict] = []
    sorted_offsets = sorted(source_offsets)
    if not sorted_offsets:
        raise ValueError(f"Frame ${start_cpu:04X} has no source bytes")
    group_start = previous = sorted_offsets[0]
    groups: list[tuple[int, int]] = []
    for offset in sorted_offsets[1:]:
        if offset != previous + 1:
            groups.append((group_start, previous + 1))
            group_start = offset
        previous = offset
    groups.append((group_start, previous + 1))

    bank_file_start = extractor.file_offset(bank, 0xA000)
    for span_start, span_end in groups:
        if span_start < bank_file_start or span_end > bank_file_start + 0x2000:
            raise ValueError(f"Frame ${start_cpu:04X} span leaves PRG bank ${bank:02X}")
        span_cpu = 0xA000 + span_start - bank_file_start
        span_bytes = rom[span_start:span_end]
        spans.append({
            "prg_bank": bank,
            "cpu_start_address": hex_value(span_cpu, 4),
            "cpu_end_address_exclusive": hex_value(span_cpu + len(span_bytes), 4),
            "file_offset": hex_value(span_start, 6),
            "length_bytes": len(span_bytes),
            "sha256": hashlib.sha256(span_bytes).hexdigest(),
            "source_bin": f"frame_sources/bank_{bank:02X}_{span_cpu:04X}.bin",
        })
    return spans


def main() -> None:
    rom = ROM_PATH.read_bytes()
    rom_sha256 = hashlib.sha256(rom).hexdigest()
    if rom_sha256 != EXPECTED_ROM_SHA256:
        raise ValueError(f"Supplied ROM SHA-256 changed: {rom_sha256}")
    invocations, manifests = collect_manifests()
    animation_ids = sorted({int(animation_id, 16) for item in invocations for animation_id in item["animation_ids"]})
    OUT.mkdir(parents=True, exist_ok=True)

    records: list[dict] = []
    timing_tracks: list[dict] = []
    frames_by_address: dict[tuple[int, int], dict] = {}
    dialog_branch_frames: list[dict] = []
    for animation_id in animation_ids:
        record, raw, _ = get_animation_record(rom, animation_id)
        destination = OUT / record["source_bin"]
        destination.write_bytes(raw)
        records.append(record)

        animation_info = {
            "id": record["id"],
            "prg_bank": record["prg_bank"],
            "cpu_address": record["start_cpu_address"],
            "entry_decode": record["entry_decode"],
        }
        track = timing_decoder.decode(rom, animation_info)
        track["source_record_sha256"] = record["sha256"]
        track["source_record_length_bytes"] = record["length_bytes"]
        timing_tracks.append(track)

        frame_addresses: set[int] = set()
        for command in record["entry_decode"]["entry_commands"]:
            if command["kind"] == "sprite_frame":
                frame_addresses.add(int(command["cpu_address"], 16))
        for command in track["commands"]:
            frame_address = command.get("frame_cpu_address")
            if frame_address:
                frame_addresses.add(int(frame_address, 16))
        animation_branches = get_dialog_branch_frames(rom, record)
        dialog_branch_frames.extend(animation_branches)
        for branch in animation_branches:
            for choice in branch["choices"]:
                cpu = int(choice["frame_cpu_address"], 16)
                frame_addresses.add(cpu)
        for cpu in frame_addresses:
            key = (record["prg_bank"], cpu)
            ref = frames_by_address.setdefault(key, {
                "prg_bank": record["prg_bank"],
                "cpu_address": hex_value(cpu, 4),
                "referenced_by_animation_ids": [],
                "referenced_by_invocations": [],
                "referenced_by_dialog_branches": [],
            })
            if record["id"] not in ref["referenced_by_animation_ids"]:
                ref["referenced_by_animation_ids"].append(record["id"])
            for branch in animation_branches:
                for choice in branch["choices"]:
                    if int(choice["frame_cpu_address"], 16) != cpu:
                        continue
                    reference = {
                        "animation_id": record["id"],
                        "opcode_cpu_address": branch["opcode_cpu_address"],
                        "opcode_file_offset": branch["opcode_file_offset"],
                        "state_bit0": choice["state_bit0"],
                    }
                    if reference not in ref["referenced_by_dialog_branches"]:
                        ref["referenced_by_dialog_branches"].append(reference)

    for invocation in invocations:
        for animation_id in invocation["animation_ids"]:
            for ref in frames_by_address.values():
                if animation_id in ref["referenced_by_animation_ids"]:
                    item = {k: invocation[k] for k in ("cutscene_id", "event_index", "cpu_address", "file_offset")}
                    if item not in ref["referenced_by_invocations"]:
                        ref["referenced_by_invocations"].append(item)

    frame_descriptors = []
    for key in sorted(frames_by_address):
        ref = frames_by_address[key]
        descriptor = frame_decoder.decode_frame(rom, key[0], key[1])
        descriptor["referenced_by_animation_ids"] = sorted(ref["referenced_by_animation_ids"])
        descriptor["referenced_by_invocations"] = sorted(
            ref["referenced_by_invocations"], key=lambda item: (item["cutscene_id"], item["event_index"])
        )
        descriptor["referenced_by_dialog_branches"] = sorted(
            ref["referenced_by_dialog_branches"],
            key=lambda item: (item["animation_id"], item["opcode_cpu_address"], item["state_bit0"]),
        )
        frame_descriptors.append(descriptor)

    # Preserve exact raw bytes for the frames selected by dialog branches.
    # Shared jump targets (such as $B88D) are emitted only once and referenced
    # by both frames in the generated manifest.
    source_span_by_key: dict[tuple[int, int, int], dict] = {}
    frame_source_entries: list[dict] = []
    for descriptor in frame_descriptors:
        if not descriptor.get("referenced_by_dialog_branches"):
            continue
        source_spans = source_spans_for_frame(rom, descriptor)
        descriptor["source_spans"] = source_spans
        frame_source_entries.append({
            "prg_bank": descriptor["prg_bank"],
            "frame_cpu_address": descriptor["cpu_address"],
            "frame_file_offset": descriptor["file_offset"],
            "referenced_by_dialog_branches": descriptor["referenced_by_dialog_branches"],
            "spans": source_spans,
        })
        for span in source_spans:
            key = (span["prg_bank"], int(span["file_offset"], 16), span["length_bytes"])
            source_span_by_key[key] = span

    source_root = OUT / "frame_sources"
    source_root.mkdir(parents=True, exist_ok=True)
    for (_, file_offset, length), span in sorted(source_span_by_key.items()):
        destination = OUT / span["source_bin"]
        source_bytes = rom[file_offset : file_offset + length]
        if hashlib.sha256(source_bytes).hexdigest() != span["sha256"]:
            raise ValueError(f"Frame source hash mismatch at {file_offset:#08x}")
        destination.write_bytes(source_bytes)
    frame_source_manifest = {
        "schema": 1,
        "rom_sha256": rom_sha256,
        "method": "Exact discontiguous source spans selected by the bank-0 sprite-frame parser; no OAM or pixels copied.",
        "frames": frame_source_entries,
    }
    (source_root / "manifest.json").write_text(
        json.dumps(frame_source_manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    index = {
        "schema": 1,
        "rom_file": ROM_PATH.name,
        "rom_sha256": rom_sha256,
        "source_manifests": [
            {"path": str(path.relative_to(ROOT)), "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
             "cutscene_id": int(path.stem.split("cutscene_", 1)[1].split("_", 1)[0]),
             "event_count": manifests[path.stem.split("cutscene_", 1)[1].split("_", 1)[0]]["event_count"]}
            for path in MANIFESTS
        ],
        "animation_id_lookup": {
            "bank_9_ids": "0x00-0x6C; pointer-table index equals ID",
            "bank_10_ids": "0x6D+; pointer-table index equals ID minus 0x6D",
            "pointer_table_cpu_address": "0xA000 in the selected PRG bank",
        },
        "animation_count": len(records),
        "invocations": invocations,
        "animations": records,
        "dialog_branch_frames": dialog_branch_frames,
        "output_files": {
            "timing": "animation_timing.json",
            "sprite_frames": "sprite_frames.json",
            "frame_source_manifest": "frame_sources/manifest.json",
        },
        "caution": (
            "This is source-byte extraction and static command decoding. It does not implement the cutscene "
            "scheduler, physical motion integration, palette effects, MMC3 CHR banking, OAM allocation/order, "
            "NES clipping, or rendered pixels."
        ),
    }
    (OUT / "animation_index.json").write_text(json.dumps(index, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    timing_doc = {
        "schema": 1,
        "rom_sha256": rom_sha256,
        "interpreter_cpu_range": "0x9154-0x94D7",
        "timing_semantics": "ROM animation-driver ticks from decoded wait opcodes; not scene-frame timing.",
        "animations": timing_tracks,
    }
    (OUT / "animation_timing.json").write_text(json.dumps(timing_doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    frame_doc = {
        "schema": 1,
        "rom_sha256": rom_sha256,
        "interpreter_cpu_range": "0x94D8-0x96F1",
        "interpreter_prg_bank": 0,
        "scope": "Sprite frame graphs selected by animation entry paths, decoded timing commands, and `$FA` dialog-branch operands.",
        "frame_count": len(frame_descriptors),
        "frames": frame_descriptors,
        "caution": (
            "Descriptors are decoded ROM frame geometry and CHR selectors, not rendered sprites. Runtime mirroring, "
            "motion, palette, bank state, clipping, priority, and OAM update order remain to be integrated."
        ),
    }
    (OUT / "sprite_frames.json").write_text(json.dumps(frame_doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    print(f"ROM {rom_sha256}; exported {len(records)} animation records and {len(frame_descriptors)} sprite frame descriptors")
    for record, track in zip(records, timing_tracks, strict=True):
        print(
            f"{record['id']}: bank {record['prg_bank']} ${record['start_cpu_address'][2:]} "
            f"{record['length_bytes']} bytes, {len(track['beats'])} waits, terminal {track['terminal']['kind']}"
        )


if __name__ == "__main__":
    main()
