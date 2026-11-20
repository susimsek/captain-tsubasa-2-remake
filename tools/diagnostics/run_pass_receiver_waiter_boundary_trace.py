#!/usr/bin/env python3
"""Capture the ROM's PASS confirmation waiter at bounded CPU boundaries."""

from __future__ import annotations

import csv
import hashlib
import json
import os
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OPENING = ROOT / "reference/opening_reference_capture/input_timeline.csv"
ROUTE = ROOT / "reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
ACTION_EDGES = ROOT / "reference/diagnostics/first_pass_action_input_edges_20261110.csv"
LUA = ROOT / "tools/diagnostics/trace_pass_receiver_waiter_boundaries.lua"
FCEUX = Path("/opt/homebrew/bin/fceux")
TRACE_LAST_FRAME = 9600

EXPECTED = {
    ROM: "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
    OPENING: "195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3",
    ROUTE: "87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e",
    ACTION_EDGES: "3e522de6924b0fb9ad40ffdd2271a9e4ea62cbe1bf76cc27c6b414b7e87bb6d2",
}
EXPECTED_EVENTS = {
    "D70C_action_cleanup": 9076,
    "D714_action_return": 9086,
    "D568_post_wait_return": 9086,
    "8047_field_bank_entry": 9086,
    "E07E_field_update_caller": 9086,
    "E709_field_update": 9086,
}
ALL_EVENTS = {
    "D70C_action_cleanup", "CC50_waiter_yield", "CC53_waiter_resume",
    "CCA0_waiter_yield", "CCA3_waiter_resume", "CCCE_waiter_yield",
    "CCD1_waiter_resume", "D70F_action_return", "D714_action_return",
    "D715_action_return", "D716_action_return", "D568_post_wait_return",
    "CE2D_post_wait_mapper", "8047_field_bank_entry", "A103_field_worker",
    "E07E_field_update_caller", "E709_field_update",
    "EB8B_scenario_root", "EB9E_scenario_return", "CBBE_scheduler_save",
    "CB0F_scheduler_save", "CAA5_scheduler_select", "8327_callback_handler",
    "8525_map_worker", "856F_map_worker_yield", "C515_nmi_wait",
    "A21A_actor_animation_gate",
    "bank10_8003_entry", "bank10_8021_reader", "bank10_803F_opcode",
    "bank10_FB_handler", "bank10_F0_terminal",
}


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def normalized_event_hash(path: Path) -> str:
    with path.open(newline="", encoding="utf-8") as stream:
        rows = list(csv.reader(stream))
    if not rows or "pass" not in rows[0]:
        raise SystemExit(f"Trace event file has no pass column: {path.name}")
    pass_index = rows[0].index("pass")
    for row in rows[1:]:
        del row[pass_index]
    return hashlib.sha256("\n".join(",".join(row) for row in rows).encode()).hexdigest()


def validate_events(path: Path, pass_number: int) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as stream:
        rows = list(csv.DictReader(stream))
    found = {row["event"] for row in rows}
    missing = sorted(ALL_EVENTS - found)
    if missing:
        raise SystemExit(f"Pass {pass_number} is missing boundary events: {', '.join(missing)}")
    for event, expected_frame in EXPECTED_EVENTS.items():
        matching = [row for row in rows if row["event"] == event]
        if not matching or int(matching[0]["source_frame"]) != expected_frame:
            actual = matching[0]["source_frame"] if matching else "missing"
            raise SystemExit(f"Pass {pass_number} {event} frame differs: {actual}, expected {expected_frame}")
    d714 = next(row for row in rows if row["event"] == "D714_action_return")
    d716 = next(row for row in rows if row["event"] == "D716_action_return")

    def first_after(event: str, previous: dict[str, str]) -> dict[str, str]:
        candidates = [row for row in rows if row["event"] == event
                      and int(row["cycle_absolute"]) > int(previous["cycle_absolute"])]
        if not candidates:
            raise SystemExit(f"Pass {pass_number} is missing ordered post-wait event {event}")
        return candidates[0]

    d568 = first_after("D568_post_wait_return", d716)
    ce2d = first_after("CE2D_post_wait_mapper", d568)
    field_entry = first_after("8047_field_bank_entry", ce2d)
    e07e = first_after("E07E_field_update_caller", field_entry)
    e709 = first_after("E709_field_update", e07e)
    if int(d714["source_frame"]) != int(e709["source_frame"]) \
            or int(d714["cycle_absolute"]) >= int(e709["cycle_absolute"]):
        raise SystemExit(f"Pass {pass_number} `$D714->$E709` event order differs")
    if not (int(d716["cycle_absolute"]) < int(d568["cycle_absolute"]) \
            < int(ce2d["cycle_absolute"]) < int(field_entry["cycle_absolute"]) \
            < int(e07e["cycle_absolute"]) \
            < int(e709["cycle_absolute"])):
        raise SystemExit(f"Pass {pass_number} post-wait ROM event order differs")
    for row in rows:
        ram_hex = row.get("ram_0000_07ff", "")
        if len(ram_hex) != 0x800 * 2:
            raise SystemExit(f"Pass {pass_number} {row['event']} lacks the complete 2 KiB RAM/stack image")
        if len(row.get("ppu_ram_hash_16k", "")) != 8:
            raise SystemExit(f"Pass {pass_number} {row['event']} lacks the 16 KiB PPU RAM signature")
    return rows


def validate_scenario2e_map2f(rows: list[dict[str, str]], pass_number: int) -> dict[str, object]:
    def ram(row: dict[str, str]) -> bytes:
        return bytes.fromhex(row["ram_0000_07ff"])

    def find(event: str, frame: int, predicate) -> dict[str, str]:
        matches = [row for row in rows if row["event"] == event
                   and int(row["source_frame"]) == frame and predicate(row, ram(row))]
        if not matches:
            raise SystemExit(f"Pass {pass_number} is missing {event} at frame {frame} for scenario-$2E/map-$2F")
        return matches[0]

    scenario_commit = find(
        "CBBE_scheduler_save", 9463,
        lambda row, image: row["task_slot_0000"] == "$05" and image[0x0518] == 0x2E,
    )
    callback_parameters = find(
        "8327_callback_handler", 9464,
        lambda row, image: row["task_slot_0000"] == "$15"
        and image[0x0518] == 0x2E
        and image[0x0523:0x052A] == bytes([0x78, 0x36, 0x02, 0xBC, 0x4A, 0x8B, 0x6D]),
    )
    worker_yield = find(
        "856F_map_worker_yield", 9463,
        lambda row, image: row["task_slot_0000"] == "$15",
    )
    nmi_wait = find(
        "C515_nmi_wait", 9463,
        lambda row, image: row["task_slot_0000"] == "$15",
    )
    map2f_live = find(
        "856F_map_worker_yield", 9464,
        lambda row, image: row["task_slot_0000"] == "$15" and image[0x05CC] == 0x2F,
    )
    map2f_resume = find(
        "8327_callback_handler", 9475,
        lambda row, image: row["task_slot_0000"] == "$15"
        and image[0x0518] == 0x2E and image[0x05CC] == 0x2F and image[0x05CD] == 0x80,
    )
    phase51 = find(
        "EB8B_scenario_root", 9476,
        lambda row, image: image[0x0516:0x051A] == bytes([0x51, 0x40, 0x2E, 0x00])
        and image[0x0523:0x052B] == bytes([0x78, 0x36, 0x02, 0xBC, 0x4A, 0x8B, 0x6D, 0x00]),
    )
    countdown_rows = [
        find("EB9E_scenario_return", frame,
             lambda row, image, expected=0x78 - (frame - 9476): image[0x0516:0x0519]
             == bytes([0x01, 0x00, 0x2E]) and image[0x0519] == expected
             and image[0x0523:0x052B] == bytes([0x78, 0x36, 0x02, 0x3C, 0x4A, 0x8B, 0x6D, 0x00]))
        for frame in range(9477, 9486)
    ]
    threshold_return = find(
        "EB9E_scenario_return", 9556,
        lambda row, image: image[0x0516:0x051A] == bytes([0x01, 0x00, 0x2E, 0x28]),
    )
    bank10_return = find(
        "EB9E_scenario_return", 9557,
        lambda row, image: image[0x0516:0x051A] == bytes([0x29, 0x00, 0x2E, 0x27]),
    )
    phase29_countdown_rows = [
        find("EB9E_scenario_return", frame,
             lambda row, image, expected=0x27 - (frame - 9557):
             image[0x0516:0x051A] == bytes([0x29, 0x00, 0x2E, expected]))
        for frame in range(9558, 9597)
    ]
    phase29_complete = find(
        "EB9E_scenario_return", 9597,
        lambda row, image: image[0x0516:0x051A] == bytes([0x00, 0x00, 0x2E, 0x00]),
    )
    if int(worker_yield["cycle_absolute"]) >= int(nmi_wait["cycle_absolute"]):
        raise SystemExit(f"Pass {pass_number} map-$2F worker/NMI wait event order differs")
    return {
        "scenario_commit_frame": int(scenario_commit["source_frame"]),
        "callback36_parameter_frame": int(callback_parameters["source_frame"]),
        "callback36_parameter_bytes_0523_0529": ram(callback_parameters)[0x0523:0x052A].hex(),
        "first_map2f_worker_nmi_wait_frame": int(nmi_wait["source_frame"]),
        "map_id_05cc_first_confirmed_frame": int(map2f_live["source_frame"]),
        "map_id_05cc": ram(map2f_live)[0x05CC],
        "map2f_worker_cursor_at_9475": ram(map2f_resume)[0x05C7:0x05CE].hex(),
        "map2f_phase51_post_callback_frame": int(phase51["source_frame"]),
        "map2f_phase01_countdown_frames": [int(row["source_frame"]) for row in countdown_rows],
        "map2f_countdown_9477_9485": [ram(row)[0x0519] for row in countdown_rows],
        "ed5b_threshold_return_frame": int(threshold_return["source_frame"]),
        "ed5b_threshold_ram_0516_0519": ram(threshold_return)[0x0516:0x051A].hex(),
        "bank10_scenario2e_return_frame": int(bank10_return["source_frame"]),
        "bank10_scenario2e_ram_0516_0519": ram(bank10_return)[0x0516:0x051A].hex(),
        "phase29_countdown_frames": len(phase29_countdown_rows),
        "phase29_countdown_first_last": [
            int(phase29_countdown_rows[0]["source_frame"]),
            int(phase29_countdown_rows[-1]["source_frame"]),
        ],
        "phase29_complete_frame": int(phase29_complete["source_frame"]),
        "ppu_ram_hash_frame_9464": map2f_live["ppu_ram_hash_16k"],
        "ppu_ram_hash_frame_9475": map2f_resume["ppu_ram_hash_16k"],
    }


def validate_scenario1e_map51_a21a(rows: list[dict[str, str]], pass_number: int) -> dict[str, object]:
    matches = [row for row in rows
               if row["event"] == "A21A_actor_animation_gate"
               and int(row["source_frame"]) == 9256
               and row["task_slot_0000"] == "$11"]
    if not matches:
        raise SystemExit(f"Pass {pass_number} lacks the scenario-$1E/map-$51 `$A21A` gate at frame 9256")
    row = matches[0]
    ram = bytes.fromhex(row["ram_0000_07ff"])
    expected_ram = {
        "slot11_record": (0x11, bytes.fromhex("00c21a1b")),
        "stream_context": (0x005D, bytes.fromhex("e3b7629a378eb0a2")),
        "animation_queue": (0x0515, bytes.fromhex("8061401e1fe89b00")),
        "callback": (0x0522, bytes.fromhex("000745023c4a90ff40")),
        "map": (0x05C7, bytes.fromhex("24c00000015180a000020000")),
        "actor": (0x05E3, bytes.fromhex("00000e0e02020058")),
        "gate": (0x05F3, bytes.fromhex("000100")),
        "stack": (0x01C7, bytes.fromhex("83cf4f80")),
    }
    mismatches = {name: {"actual": ram[offset:offset + len(expected)].hex(),
                         "expected": expected.hex()}
                  for name, (offset, expected) in expected_ram.items()
                  if ram[offset:offset + len(expected)] != expected}
    expected_registers = {"pc": "$A21A", "prg_bank": "27", "a": "$06", "x": "$06",
                          "y": "$02", "p": "$21", "sp": "$C6"}
    mismatches.update({name: {"actual": row.get(name), "expected": value}
                       for name, value in expected_registers.items()
                       if row.get(name) != value})
    if row.get("prg_map_8000_a000_c000_e000") != "1A/1B/1E/1F":
        mismatches["prg_map"] = {"actual": row.get("prg_map_8000_a000_c000_e000"),
                                 "expected": "1A/1B/1E/1F"}
    if mismatches:
        raise SystemExit(f"Pass {pass_number} scenario-$1E/map-$51 `$A21A` profile differs: "
                         f"{json.dumps(mismatches, sort_keys=True)}")
    return {"source_frame": 9256, "event": row["event"], "pc": row["pc"],
            "task_slot": row["task_slot_0000"], "registers": expected_registers,
            "record": ram[0x11:0x15].hex(),
            "stream_context": ram[0x005D:0x0065].hex(),
            "queue_animation": ram[0x0515:0x051D].hex(),
            "callback": ram[0x0522:0x052B].hex(),
            "map": ram[0x05C7:0x05D3].hex(),
            "actor": ram[0x05E3:0x05EB].hex(),
            "gate": ram[0x05F3:0x05F6].hex(),
            "stack_return_frame": ram[0x01C7:0x01CB].hex(),
            "prg_map": row["prg_map_8000_a000_c000_e000"]}


def validate_scenario1e_actor58_zero_mode_return(rows: list[dict[str, str]], pass_number: int) -> dict[str, object]:
    matches = [row for row in rows
               if row["event"] == "804A_slot11_actor_dispatch"
               and int(row["source_frame"]) == 9290
               and row["task_slot_0000"] == "$11"]
    if not matches:
        raise SystemExit(f"Pass {pass_number} lacks the scenario-$1E/$58 zero-mode `$804A` entry at frame 9290")
    row = matches[0]
    ram = bytes.fromhex(row["ram_0000_07ff"])
    expected_ram = {
        "task_and_callback": (0x0515, bytes.fromhex("0029401e05e89b00")),
        "stream": (0x005F, bytes.fromhex("629a")),
        "callback_parameters": (0x0523, bytes.fromhex("074506003c90ff")),
        "actor": (0x05E3, bytes.fromhex("00000e0e02020058")),
        "animation_mode_and_counter": (0x05F3, bytes.fromhex("000001")),
        "animation_pointer": (0x0063, bytes.fromhex("baa2")),
        "worker_return_frame": (0x01C7, bytes.fromhex("04044980")),
    }
    mismatches = {name: {"actual": ram[offset:offset + len(expected)].hex(),
                         "expected": expected.hex()}
                  for name, (offset, expected) in expected_ram.items()
                  if ram[offset:offset + len(expected)] != expected}
    expected_registers = {"pc": "$804A", "prg_bank": "24", "a": "$04", "x": "$04",
                          "y": "$04", "p": "$31", "sp": "$CA"}
    mismatches.update({name: {"actual": row.get(name), "expected": value}
                       for name, value in expected_registers.items()
                       if row.get(name) != value})
    if row.get("prg_map_8000_a000_c000_e000") != "18/19/1E/1F":
        mismatches["prg_map"] = {"actual": row.get("prg_map_8000_a000_c000_e000"),
                                 "expected": "18/19/1E/1F"}
    if ram[0x0022] != 0 or ram[0x0629] != 0:
        mismatches["idle_gates"] = {"mapper_shadow_0022": ram[0x0022],
                                     "queue_row_0629": ram[0x0629],
                                     "expected": "00/00"}
    if mismatches:
        raise SystemExit(f"Pass {pass_number} scenario-$1E/$58 zero-mode `$804A` profile differs: "
                         f"{json.dumps(mismatches, sort_keys=True)}")
    return {"source_frame": 9290, "event": row["event"], "pc": row["pc"],
            "task_slot": row["task_slot_0000"], "registers": expected_registers,
            "scenario": ram[0x0516:0x051A].hex(),
            "stream_pointer": ram[0x005F:0x0061].hex(),
            "actor": ram[0x05E3:0x05EB].hex(),
            "animation_mode_counter": ram[0x05F3:0x05F6].hex(),
            "animation_pointer": ram[0x0063:0x0065].hex(),
            "worker_return_frame": ram[0x01C7:0x01CB].hex(),
            "prg_map": row["prg_map_8000_a000_c000_e000"]}


def return_stack_contract(rows: list[dict[str, str]]) -> dict[str, object]:
    by_event = {row["event"]: row for row in rows}

    def reg(event: str, name: str) -> int:
        value = by_event[event][name]
        return int(value.removeprefix("$") or "0", 16)

    def ram_byte(event: str, address: int) -> int:
        ram = bytes.fromhex(by_event[event]["ram_0000_07ff"])
        return ram[address]

    d70f_sp = reg("D70F_action_return", "sp")
    d714_sp = reg("D714_action_return", "sp")
    d715_sp = reg("D715_action_return", "sp")
    d716_sp = reg("D716_action_return", "sp")
    e709_sp = reg("E709_field_update", "sp")
    d716_low = ram_byte("D716_action_return", 0x014D)
    d716_high = ram_byte("D716_action_return", 0x014E)
    d716_return_pc = (((d716_high << 8) | d716_low) + 1) & 0xFFFF
    e709_low = ram_byte("E709_field_update", 0x014D)
    e709_high = ram_byte("E709_field_update", 0x014E)
    e709_return_pc = (((e709_high << 8) | e709_low) + 1) & 0xFFFF
    return {
        "sp_at_D70F": d70f_sp,
        "sp_at_D714": d714_sp,
        "sp_at_D715": d715_sp,
        "sp_at_D716": d716_sp,
        "sp_at_E709": e709_sp,
        "D716_return_word": (d716_high << 8) | d716_low,
        "D716_natural_return_pc_from_stack": d716_return_pc,
        "sp_at_D568": reg("D568_post_wait_return", "sp"),
        "D716_rts_stack_delta_matches_6502":
            d714_sp == d70f_sp
            and d715_sp == ((d714_sp + 1) & 0xFF)
            and d716_sp == ((d715_sp + 1) & 0xFF)
            and reg("D568_post_wait_return", "sp") == ((d716_sp + 2) & 0xFF),
        "returns_to_D568": d716_return_pc == 0xD568,
        "sp_at_8047": reg("8047_field_bank_entry", "sp"),
        "A103_first_hook_frame": next(row for row in rows if row["event"] == "A103_field_worker")["source_frame"],
        "E709_return_word": (e709_high << 8) | e709_low,
        "E709_natural_return_pc_from_stack": e709_return_pc,
        "E709_return_word_targets_E081": e709_return_pc == 0xE081,
    }


def validate_wait_flag_writes(paths: list[Path]) -> dict[str, object]:
    replay_rows: list[list[dict[str, str]]] = []
    for pass_number, path in enumerate(paths, start=1):
        with path.open(newline="", encoding="utf-8") as stream:
            rows = list(csv.DictReader(stream))
        if not rows:
            raise SystemExit(f"Pass {pass_number} has no `$062D` write-hook events")
        cleanup = [row for row in rows
                   if int(row["source_frame"]) == 9086
                   and row["pc_after_write"] == "$D714"
                   and row["previous_value"] == "$81"
                   and row["write_size"] == "$01"
                   and row["new_value"] == "$00"]
        if not cleanup:
            raise SystemExit(f"Pass {pass_number} lacks the traced `$D711` `$062D:81->00` cleanup at frame 9086")
        replay_rows.append(rows)
    hashes = [normalized_event_hash(path) for path in paths]
    if hashes[0] != hashes[1]:
        raise SystemExit("Checkpointed `$062D` write-hook traces differ")
    later_reassertions = [row for row in replay_rows[0]
                          if int(row["source_frame"]) > 9086
                          and (int(row["new_value"].removeprefix("$"), 16) & 0x80) != 0]
    return {
        "write_hook": "FCEUX memory.registerwrite($062D)",
        "replay_write_counts": [len(rows) for rows in replay_rows],
        "normalized_sha256": hashes[0],
        "source_cleanup": {
            "source_frame": 9086,
            "pc_after_write": "$D714",
            "previous_value": "$81",
            "write_size": "$01",
            "new_value": "$00",
        },
        "post_cleanup_high_bit_writes": len(later_reassertions),
        "post_cleanup_high_bit_write_frames": [int(row["source_frame"]) for row in later_reassertions],
        "post_cleanup_high_bit_write_sites": [
            {"frame": int(row["source_frame"]), "pc_after_write": row["pc_after_write"],
             "new_value": row["new_value"], "slot": row["active_task_slot"],
             "scenario": row["scenario_0516_0519"]}
            for row in later_reassertions
        ],
    }


def main() -> None:
    for path, expected in EXPECTED.items():
        if not path.is_file() or sha(path) != expected:
            raise SystemExit(f"Missing or changed trace input: {path}")
    if not LUA.is_file() or not FCEUX.is_file():
        raise SystemExit("FCEUX 2.7.0 or PASS waiter Lua trace is unavailable")

    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_utc")
    out = ROOT / "reference/diagnostics" / f"pass_receiver_waiter_boundaries_{timestamp}"
    out.mkdir(parents=True, exist_ok=False)
    env = os.environ.copy()
    env.update({"SDL_AUDIODRIVER": "dummy", "CT2_PROJECT_ROOT": str(ROOT),
                "CT2_PASS_WAITER_TRACE_OUTPUT_DIR": str(out)})
    command = [str(FCEUX), "--sound", "0", "--volume", "0", "--no-config", "1",
               "--newppu", "1", "--loadlua", str(LUA), str(ROM)]
    started = time.monotonic()
    last_progress, last_progress_at = None, started
    with (out / "fceux_stdout.txt").open("w") as stdout, (out / "fceux_stderr.txt").open("w") as stderr:
        proc = subprocess.Popen(command, env=env, stdout=stdout, stderr=stderr)
        while proc.poll() is None:
            progress_file = out / "progress.txt"
            if progress_file.exists():
                progress = progress_file.read_text().strip()
                if progress != last_progress:
                    print(f"Muted PASS waiter replay: {progress}", flush=True)
                    last_progress, last_progress_at = progress, time.monotonic()
            if time.monotonic() - started > 300 or time.monotonic() - last_progress_at > 60:
                proc.kill()
                proc.wait()
                raise SystemExit(f"PASS waiter trace timed out; last={last_progress}; output={out}")
            time.sleep(0.25)

    elapsed = time.monotonic() - started
    metadata_path = out / "metadata.txt"
    if proc.returncode not in (0, -11) or not metadata_path.is_file() \
            or "complete=true" not in metadata_path.read_text(encoding="utf-8"):
        raise SystemExit(f"PASS waiter trace incomplete (exit {proc.returncode}); output={out}")
    with metadata_path.open("a", encoding="utf-8") as stream:
        stream.write(f"source_rom_sha256={sha(ROM)}\n")
        stream.write(f"opening_input_sha256={sha(OPENING)}\n")
        stream.write(f"route_input_sha256={sha(ROUTE)}\n")
        stream.write(f"action_edges_sha256={sha(ACTION_EDGES)}\n")
        stream.write(f"fceux_exit_code={proc.returncode}\nelapsed_seconds={elapsed:.3f}\n")
    checkpoint_ram = out / "checkpoint_ram.bin"
    checkpoint_ppu = out / "checkpoint_ppu.bin"
    if not checkpoint_ram.is_file() or checkpoint_ram.stat().st_size != 0x800 \
            or not checkpoint_ppu.is_file() or checkpoint_ppu.stat().st_size != 0x4000:
        raise SystemExit(f"PASS waiter checkpoint RAM/PPU dump is missing or has the wrong size; output={out}")
    event_paths = [out / "events.csv", out / "events_repeat.csv"]
    if not all(path.is_file() for path in event_paths):
        raise SystemExit(f"PASS waiter trace outputs are missing; output={out}")
    first_rows = validate_events(event_paths[0], 1)
    repeat_rows = validate_events(event_paths[1], 2)
    scenario2e_summary = validate_scenario2e_map2f(first_rows, 1)
    validate_scenario2e_map2f(repeat_rows, 2)
    scenario1e_a21a_summary = validate_scenario1e_map51_a21a(first_rows, 1)
    validate_scenario1e_map51_a21a(repeat_rows, 2)
    scenario1e_zero_mode_summary = validate_scenario1e_actor58_zero_mode_return(first_rows, 1)
    validate_scenario1e_actor58_zero_mode_return(repeat_rows, 2)
    waitflag_paths = [out / "waitflag_062d_writes.csv", out / "waitflag_062d_writes_repeat.csv"]
    if not all(path.is_file() for path in waitflag_paths):
        raise SystemExit(f"`$062D` write-hook outputs are missing; output={out}")
    waitflag_summary = validate_wait_flag_writes(waitflag_paths)
    event_hash = normalized_event_hash(event_paths[0])
    if event_hash != normalized_event_hash(event_paths[1]):
        raise SystemExit(f"Checkpointed PASS waiter traces differ; output={out}")

    result = {
        "checkpoint_frame": 9042,
        "checkpoint_cpu_registers": next(
            (line.split("=", 1)[1] for line in metadata_path.read_text(encoding="utf-8").splitlines()
             if line.startswith("checkpoint_cpu_registers=")), ""),
        "checkpoint_ram_file": checkpoint_ram.name,
        "checkpoint_ram_sha256": sha(checkpoint_ram),
        "checkpoint_ppu_file": checkpoint_ppu.name,
        "checkpoint_ppu_sha256": sha(checkpoint_ppu),
        "replay_frames": [9043, TRACE_LAST_FRAME],
        "replays": 2,
        "required_events": sorted(ALL_EVENTS),
        "first_pass_event_count": len(first_rows),
        "normalized_event_sha256": event_hash,
        "full_ram_and_stack_page_per_event": True,
        "cleanup_stack_contract": return_stack_contract(first_rows),
        "mapper_registers_and_mapped_prg_per_event": True,
        "ppu_ram_signature_and_queue_bytes_per_event": True,
        "scenario_2e_callback_36_map_2f": scenario2e_summary,
        "scenario_1e_map51_a21a_busy_queue": scenario1e_a21a_summary,
        "scenario_1e_actor58_zero_mode_return": scenario1e_zero_mode_summary,
        "waitflag_062d_write_trace": waitflag_summary,
        "muted_audio": True,
        "fceux_exit_code": proc.returncode,
        "elapsed_seconds": round(elapsed, 3),
        "diagnostics_only": True,
    }
    (out / "validation.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(f"PASS: full-register/stack/mapper/PPU PASS route replays match through frame {TRACE_LAST_FRAME}; {elapsed:.2f}s; output={out}")


if __name__ == "__main__":
    main()
