#!/usr/bin/env python3
"""Replay the ROM reset path through the first NMI and compare after the run.

ROM execution is source-only. FCEUX event files are opened only after the ROM
stepper has finished, for validation; they never drive its CPU/PPU schedule.
Requires the diagnostic-only Py65 1.2.0 environment used by
step_rom_source_cpu_ppu_dmc.py. No Godot runtime or shipped assets are touched.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))

from step_rom_source_cpu_ppu_dmc import (  # noqa: E402
    EXPECTED_ROM_SHA256,
    ROM_PATH,
    Machine,
    sha256,
)

DEFAULT_OUT = ROOT / "reference/diagnostics/rom_only_cold_start_stepper_20261026"
DEFAULT_FCEUX_TRACES = (
    ROOT / "reference/diagnostics/cold_start_reset_path_20261026_121525/events.csv",
    ROOT / "reference/diagnostics/cold_start_reset_path_20261026_121611/events.csv",
)
PPU_BUS_REGISTERS = {0x2000, 0x2001, 0x2005, 0x2006, 0x2007}


class StartupTraceMachine(Machine):
    """The same ROM-only machine with a bounded startup PPU-write log."""

    def __init__(self, *args, **kwargs):
        self.startup_ppu_bus_events: list[dict] = []
        super().__init__(*args, **kwargs)

    def __setitem__(self, addr: int, value: int) -> None:
        normalized = addr & 0xFFFF
        if 0x2000 <= normalized < 0x4000:
            register = 0x2000 | (normalized & 7)
            if register in PPU_BUS_REGISTERS and 1 <= self.source_frame <= 9:
                self.startup_ppu_bus_events.append({
                    "source_frame": self.source_frame,
                    "cpu_cycle": self.cpu_cycles,
                    "frame_cycle": self.cpu_cycles - self.frame_cycle_start,
                    "register": f"${register:04X}",
                    "value": format_byte(value),
                    # This callback PC follows the store, matching FCEUX's
                    # registerwrite hook convention in the retained reset logs.
                    "pc": f"${(self.current_instruction_pc + self.current_instruction_len) & 0xFFFF:04X}",
                    "ppu_address_before_write": f"${self.ppu_vram_addr & 0x3FFF:04X}" if register == 0x2007 else None,
                })
        super().__setitem__(addr, value)

# Mirror the focused reset trace's event PCs, while also retaining every
# startup-ROM instruction hook from $C500-$C700. This list filters output only;
# it does not affect source execution or event timing.
NAMED_PCS = {
    0xFFF0, 0xC503, 0xC64E, 0xC675, 0xC677,
    0x801F, 0x8024, 0x8464, 0x8494, 0x9F69, 0x84C6, 0x84E7,
    0x9EED, 0x9FA8, 0xC500, 0xC76E, 0xC421, 0xC775,
    0xA000, 0xA12F, 0xC7EE, 0xA133,
}
REGISTER_FIELDS = ("a", "x", "y", "s", "p")
MEMORY_FIELDS = (
    "ram_001b", "task_0001_0018", "script_ptr_004d_004e",
    "ram_0055", "ram_0700", "byte_a020",
)
COMPARE_FIELDS = ("a", "x", "y", "s", "p", *MEMORY_FIELDS)
EVENT_FIELDS = (
    "sequence", "source_frame", "cycle", "cpu_credit", "pc", "opcode",
    "prg_bank_8k", *REGISTER_FIELDS, "ppu_status", "vblank", "nmi_pending",
    *MEMORY_FIELDS,
)


def format_byte(value: int) -> str:
    return f"${value & 0xFF:02X}"


def task_bytes(machine: Machine) -> str:
    return " ".join(f"{value:02X}" for value in machine.ram[0x0001:0x0019])


def source_memory_snapshot(machine: Machine) -> dict[str, str]:
    pointer = machine.ram[0x004D] | (machine.ram[0x004E] << 8)
    return {
        "ram_001b": format_byte(machine.ram[0x001B]),
        "task_0001_0018": task_bytes(machine),
        "script_ptr_004d_004e": f"${pointer:04X}",
        "ram_0055": format_byte(machine.ram[0x0055]),
        "ram_0700": format_byte(machine.ram[0x0700]),
        "byte_a020": format_byte(machine[0xA020]),
    }


def collect_source_events(machine: Machine) -> list[dict]:
    events: list[dict] = []
    sequence = 0
    instruction_table = list(machine.cpu.instruct)

    for opcode, original in enumerate(instruction_table):
        def instrumented(cpu, _original=original):
            nonlocal sequence
            pc = int(machine.current_instruction_pc)
            if not (0xC500 <= pc <= 0xC700 or pc in NAMED_PCS):
                return _original(cpu)

            # The wrapped Py65 function is called after the pinned CPU/PPU
            # budget has accrued and immediately before opcode semantics. This
            # is the register/cycle boundary observed by FCEUX registerexec.
            row = {
                "sequence": sequence,
                "source_frame": machine.source_frame,
                "cycle": machine.cpu_cycles,
                "cpu_credit": machine.cpu_credit,
                "pc": f"${pc:04X}",
                "opcode": f"${machine.current_instruction_opcode:02X}",
                "prg_bank_8k": machine._prg_bank(pc),
                "a": format_byte(cpu.a),
                "x": format_byte(cpu.x),
                "y": format_byte(cpu.y),
                "s": format_byte(cpu.sp),
                "p": format_byte(cpu.p),
                "ppu_status": format_byte(machine.ppu_status),
                "vblank": int(machine.vblank),
                "nmi_pending": int(machine.nmi_pending),
                **source_memory_snapshot(machine),
            }
            events.append(row)
            sequence += 1
            return _original(cpu)

        machine.cpu.instruct[opcode] = instrumented

    # Keep the ROM-only end-of-frame palette RAM snapshots. This distinguishes
    # the first NMI entry from the first frame whose queued black palette has
    # actually reached PPU RAM $3F00-$3F1F.
    machine.startup_palette_snapshots = []
    for frame in range(1, 10):
        machine.run_frame(frame)
        palette = bytes(machine.ppu_ram[0x3F00:0x3F20])
        machine.startup_palette_snapshots.append({
            "source_frame": frame,
            "ppu_address": "$3F00",
            "bytes_hex": palette.hex().upper(),
        })
    return events


def compare_trace(source_events: list[dict], source_frame_stats: list[dict],
                  source_ppu_bus_events: list[dict], trace_path: Path) -> dict:
    source_by_key: dict[tuple[int, int, str], list[dict]] = {}
    for row in source_events:
        key = (int(row["source_frame"]), int(row["cycle"]), row["pc"])
        source_by_key.setdefault(key, []).append(row)

    fceux_events = []
    with trace_path.open(newline="", encoding="utf-8") as stream:
        for row in csv.DictReader(stream):
            if int(row["source_frame"]) <= 9:
                fceux_events.append(row)

    matched = 0
    missing = []
    mismatches = []
    synthetic_p_differences = []
    consumed: Counter[tuple[int, int, str]] = Counter()
    for row in fceux_events:
        key = (int(row["source_frame"]), int(row["cycle_absolute"]), row["pc"].upper())
        candidates = source_by_key.get(key, [])
        candidate_index = consumed[key]
        if candidate_index >= len(candidates):
            missing.append({"source_frame": key[0], "cycle": key[1], "pc": key[2], "event": row["event"]})
            continue
        source = candidates[candidate_index]
        consumed[key] += 1
        matched += 1
        field_differences = {}
        for field in COMPARE_FIELDS:
            fceux_value = row[field].upper()
            source_value = str(source[field]).upper()
            # The 6502 B ($10) and U ($20) bits are not live condition flags.
            # Py65's RTI representation forces both; FCEUX may expose U from its
            # emulated stack value and never exposes B as an internal flag.
            # Compare the six live flags N,V,D,I,Z,C exactly.
            if field == "p":
                raw_fceux_p = fceux_value
                raw_source_p = source_value
                fceux_value = f"${int(fceux_value[1:], 16) & ~0x30:02X}"
                source_value = f"${int(source_value[1:], 16) & ~0x30:02X}"
                if raw_fceux_p != raw_source_p and fceux_value == source_value:
                    synthetic_p_differences.append({
                        "source_frame": key[0], "cycle": key[1], "pc": key[2],
                        "fceux_raw_p": raw_fceux_p, "source_raw_p": raw_source_p,
                    })
            if fceux_value != source_value:
                field_differences[field] = {"fceux": fceux_value, "source": source_value}
        if field_differences:
            mismatches.append({
                "source_frame": key[0], "cycle": key[1], "pc": key[2],
                "event": row["event"], "differences": field_differences,
            })

    source_startup_rows = sum(
        1 for row in source_events
        if 0xC500 <= int(row["pc"].replace("$", ""), 16) <= 0xC700
    )
    fceux_startup_rows = sum(1 for row in fceux_events if row["event"] == "startup_rom_instruction")
    fceux_frames_path = trace_path.with_name("frames.csv")
    fceux_frames = {}
    with fceux_frames_path.open(newline="", encoding="utf-8") as stream:
        for row in csv.DictReader(stream):
            frame = int(row["source_frame"])
            if 1 <= frame <= 9:
                fceux_frames[frame] = row
    frame_differences = []
    for row in source_frame_stats:
        frame = int(row["source_frame"])
        reference = fceux_frames.get(frame)
        if reference is None:
            frame_differences.append({"source_frame": frame, "missing_fceux_frame": True})
            continue
        for field in ("cycle_start", "cycle_end", "cycle_delta"):
            if int(row[field]) != int(reference[field]):
                frame_differences.append({
                    "source_frame": frame, "field": field,
                    "source": int(row[field]), "fceux": int(reference[field]),
                })
    fceux_ppu_path = trace_path.with_name("ppu_bus.csv")
    source_ppu_frame9 = [row for row in source_ppu_bus_events if int(row["source_frame"]) == 9]
    ppu_register_labels = {f"${register:04X}" for register in PPU_BUS_REGISTERS}
    fceux_ppu_frame9 = []
    with fceux_ppu_path.open(newline="", encoding="utf-8") as stream:
        for row in csv.DictReader(stream):
            if row["source_frame"] != "9" or row["event"] != "ppu_write" \
                    or row["address"] not in ppu_register_labels:
                continue
            fceux_ppu_frame9.append({
                "source_frame": 9,
                "cpu_cycle": int(row["cycle_absolute"]),
                "frame_cycle": int(row["cycle_from_frame_start"]),
                "register": row["address"],
                "value": row["value"],
                "pc": row["cpu_pc"].upper(),
            })
    ppu_write_mismatches = []
    ppu_common = min(len(source_ppu_frame9), len(fceux_ppu_frame9))
    ppu_compare_fields = ("source_frame", "cpu_cycle", "frame_cycle", "register", "value", "pc")
    for index in range(ppu_common):
        source_row = source_ppu_frame9[index]
        reference_row = fceux_ppu_frame9[index]
        differences = {
            field: {"source": source_row[field], "fceux": reference_row[field]}
            for field in ppu_compare_fields if source_row[field] != reference_row[field]
        }
        if differences:
            ppu_write_mismatches.append({"index": index, "differences": differences})
            break
    if len(source_ppu_frame9) != len(fceux_ppu_frame9) and not ppu_write_mismatches:
        ppu_write_mismatches.append({
            "source_count": len(source_ppu_frame9),
            "fceux_count": len(fceux_ppu_frame9),
        })
    return {
        "trace": str(trace_path.relative_to(ROOT)),
        "fceux_event_rows_through_frame_9": len(fceux_events),
        "matched_pc_cycle_rows": matched,
        "missing_source_rows": missing,
        "register_and_ram_mismatch_count": len(mismatches),
        "register_and_ram_mismatches": mismatches,
        "synthetic_b_u_status_representation_difference_count": len(synthetic_p_differences),
        "synthetic_b_u_status_representation_difference_examples": synthetic_p_differences[:8],
        "fceux_startup_rom_instruction_rows": fceux_startup_rows,
        "source_c500_c700_instruction_rows": source_startup_rows,
        "fceux_frames_csv": str(fceux_frames_path.relative_to(ROOT)),
        "frame_cycle_rows_compared": len(source_frame_stats),
        "frame_cycle_mismatch_count": len(frame_differences),
        "frame_cycle_mismatches": frame_differences,
        "exact_pc_cycle_live_register_ram_match": not missing and not mismatches and matched == len(fceux_events),
        "exact_frame_cycle_match": not frame_differences and len(fceux_frames) == len(source_frame_stats),
        "fceux_ppu_bus_csv": str(fceux_ppu_path.relative_to(ROOT)),
        "source_frame_9_ppu_register_write_count": len(source_ppu_frame9),
        "fceux_frame_9_ppu_register_write_count": len(fceux_ppu_frame9),
        "frame_9_ppu_write_mismatches": ppu_write_mismatches,
        "exact_frame_9_ppu_write_cycle_value_pc_match": not ppu_write_mismatches,
    }


def find_event(source_events: list[dict], pc: str, source_frame: int | None = None) -> dict:
    return next((row for row in source_events
                 if row["pc"] == pc and (source_frame is None or row["source_frame"] == source_frame)), {})


def build_runtime_phase(machine: StartupTraceMachine, source_events: list[dict],
                        comparisons: list[dict]) -> dict:
    first_scan = find_event(source_events, "$9EED")
    cold_start_entry = find_event(source_events, "$801F")
    worker_install = find_event(source_events, "$8494")
    worker_ready = find_event(source_events, "$9F69", 8)
    main_yield = find_event(source_events, "$9FA8", 8)
    worker_resume = find_event(source_events, "$84C6", 8)
    first_nmi = next((row for row in machine.cpu_interrupt_events if row["kind"] == "NMI"), {})
    first_nmi_handler = find_event(source_events, "$C500")
    first_nmi_scheduler_latch = find_event(source_events, "$A133", 9)
    first_black_palette_snapshot = next((row for row in machine.startup_palette_snapshots
                                         if bytes.fromhex(row["bytes_hex"]) == bytes([0x0F]) * 32), {})
    startup_ppu_events = [row for row in machine.startup_ppu_bus_events
                          if int(row["source_frame"]) == 9]
    palette_writes = [row for row in startup_ppu_events if row["register"] == "$2007"]
    first_palette_write = palette_writes[0] if palette_writes else {}
    final_palette_write = palette_writes[-1] if palette_writes else {}
    palette_mask_restore = next((row for row in startup_ppu_events
                                 if row["register"] == "$2001" and row["value"] == "$1E"), {})
    required = {
        "first_literal_scheduler_scan": first_scan,
        "cold_start_entry": cold_start_entry,
        "worker_context_install": worker_install,
        "worker_ready_sentinel_install": worker_ready,
        "pre_nmi_main_task_yield": main_yield,
        "pre_nmi_worker_resume": worker_resume,
        "first_nmi_accept": first_nmi,
        "first_nmi_handler_entry": first_nmi_handler,
        "first_nmi_scheduler_latch": first_nmi_scheduler_latch,
        "first_black_palette_snapshot": first_black_palette_snapshot,
        "palette_write_sequence": palette_writes,
        "first_palette_write": first_palette_write,
        "final_palette_write": final_palette_write,
        "palette_mask_restore": palette_mask_restore,
    }
    missing = [name for name, event in required.items() if not event]
    if missing:
        raise SystemExit(f"cannot export runtime startup phase; missing milestones: {', '.join(missing)}")
    if not first_black_palette_snapshot:
        raise SystemExit("cannot export startup phase: ROM-only PPU RAM never reached the initial black palette")
    expected_palette_addresses = [f"${address:04X}" for address in range(0x3F00, 0x3F20)]
    if len(palette_writes) != 32 \
            or [row["ppu_address_before_write"] for row in palette_writes] != expected_palette_addresses \
            or [row["value"] for row in palette_writes] != ["$0F"] * 32:
        raise SystemExit("cannot export startup phase: palette packet is not 32 ordered $0F writes")
    if not first_palette_write or not final_palette_write or not palette_mask_restore:
        raise SystemExit("cannot export startup phase: first/final palette write or mask restore is missing")

    return {
        "schema_version": 1,
        "source_rom_sha256": EXPECTED_ROM_SHA256,
        "generator": "tools/diagnostics/trace_rom_only_cold_start_reset.py",
        "cpu_engine": "Py65 1.2.0 with ROM-only reset/startup execution",
        "source_execution": {
            "start": "CPU reset vector from the supplied ROM",
            "end_source_frame": 9,
            "p1_input": "all buttons released",
            "capture_or_fceux_used_to_schedule_events": False,
        },
        "event_timebase": "absolute 6502 CPU cycles since ROM power-on; frame_cycle is relative to the source-frame start",
        "events": {
            "first_literal_scheduler_scan": {
                "source_frame": int(first_scan["source_frame"]),
                "cpu_cycle": int(first_scan["cycle"]),
                "pc": first_scan["pc"],
            },
            "cold_start_entry": {
                "source_frame": int(cold_start_entry["source_frame"]),
                "cpu_cycle": int(cold_start_entry["cycle"]),
                "pc": cold_start_entry["pc"],
            },
            "worker_context_install": {
                "source_frame": int(worker_install["source_frame"]),
                "cpu_cycle": int(worker_install["cycle"]),
                "pc": worker_install["pc"],
                "script_pointer": worker_install["script_ptr_004d_004e"],
            },
            "worker_ready_sentinel_install": {
                "source_frame": int(worker_ready["source_frame"]),
                "cpu_cycle": int(worker_ready["cycle"]),
                "pc": worker_ready["pc"],
                "slot_offset": 5,
                "delay_byte": 255,
            },
            "initial_ready_scan_trigger": {
                "source_frame": int(main_yield["source_frame"]),
                "cpu_cycle": int(main_yield["cycle"]),
                "pc": main_yield["pc"],
                "first_worker_resume_pc": worker_resume["pc"],
                "first_worker_resume_cycle": int(worker_resume["cycle"]),
            },
            "first_nmi_accept": {
                "source_frame": int(first_nmi["source_frame"]),
                "cpu_cycle": int(first_nmi["cycle"]),
                "pc_before": first_nmi["pc_before"],
                "kind": first_nmi["kind"],
            },
            "first_nmi_handler_entry": {
                "source_frame": int(first_nmi_handler["source_frame"]),
                "cpu_cycle": int(first_nmi_handler["cycle"]),
                "pc": first_nmi_handler["pc"],
            },
            "first_black_palette_commit": {
                "source_frame": int(first_black_palette_snapshot["source_frame"]),
                "cpu_cycle": int(final_palette_write["cpu_cycle"]),
                "frame_cycle": int(final_palette_write["frame_cycle"]),
                "ppu_address": first_black_palette_snapshot["ppu_address"],
                "byte_count": 32,
                "bytes_hex": first_black_palette_snapshot["bytes_hex"],
                "final_write_address": final_palette_write["ppu_address_before_write"],
                "measurement": "Cycle of the 32nd source-driven $2007 write completing the 32-byte palette packet; frame-end PPU RAM independently contains 32 $0F bytes.",
            },
            "first_black_palette_write": {
                "source_frame": int(first_palette_write["source_frame"]),
                "cpu_cycle": int(first_palette_write["cpu_cycle"]),
                "frame_cycle": int(first_palette_write["frame_cycle"]),
                "register": first_palette_write["register"],
                "ppu_address": first_palette_write["ppu_address_before_write"],
                "value": first_palette_write["value"],
                "pc": first_palette_write["pc"],
            },
            "first_black_palette_mask_restore": {
                "source_frame": int(palette_mask_restore["source_frame"]),
                "cpu_cycle": int(palette_mask_restore["cpu_cycle"]),
                "frame_cycle": int(palette_mask_restore["frame_cycle"]),
                "register": palette_mask_restore["register"],
                "value": palette_mask_restore["value"],
                "pc": palette_mask_restore["pc"],
            },
            "first_nmi_scheduler_latch": {
                "source_frame": int(first_nmi_scheduler_latch["source_frame"]),
                "cpu_cycle": int(first_nmi_scheduler_latch["cycle"]),
                "pc": first_nmi_scheduler_latch["pc"],
            },
        },
        "runtime_phase_frames": {
            "first_literal_scheduler_scan": int(first_scan["source_frame"]),
            "worker_ready_sentinel_install": int(worker_ready["source_frame"]),
            "first_ready_worker_scan": int(main_yield["source_frame"]),
            "first_nmi_release": int(first_nmi_scheduler_latch["source_frame"]),
            "first_black_palette_commit": int(first_black_palette_snapshot["source_frame"]),
        },
        "source_frame_cycles": [
            {key: int(value) for key, value in row.items()}
            for row in machine.frame_stats
        ],
        "source_startup_ppu_palette_snapshots": machine.startup_palette_snapshots,
        "source_ppu_cycle_validation": {
            "rom_only_execution": True,
            "post_run_fceux_traces": [
                {
                    "trace": item["trace"],
                    "matched_frame_9_ppu_register_writes": item["source_frame_9_ppu_register_write_count"],
                    "exact_cycle_value_pc_match": item["exact_frame_9_ppu_write_cycle_value_pc_match"],
                }
                for item in comparisons
            ],
            "ppu_scanline_dot_measured": False,
            "rendered_subframe_edge_verified": False,
            "limitation": "FCEUX's capture API did not expose scanline/dot getters; these are CPU bus-cycle events, not pixel-output timestamps.",
        },
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out-dir", type=Path, default=DEFAULT_OUT)
    parser.add_argument("--fceux-trace", type=Path, action="append", default=None,
                        help="post-run FCEUX events.csv validation input (repeatable)")
    parser.add_argument("--no-compare", action="store_true",
                        help="run source-only trace without opening FCEUX reference files")
    parser.add_argument("--write-runtime-resource", action="store_true",
                        help="write the derived startup phase to assets/opening/rom_logic/cold_start_bootstrap_phase.json")
    args = parser.parse_args()

    rom = ROM_PATH.read_bytes()
    rom_hash = sha256(rom)
    if rom_hash != EXPECTED_ROM_SHA256:
        raise SystemExit(f"ROM identity mismatch: {rom_hash}")

    args.out_dir.mkdir(parents=True, exist_ok=True)
    machine = StartupTraceMachine(rom)
    source_events = collect_source_events(machine)

    event_path = args.out_dir / "source_reset_instruction_events.csv"
    with event_path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=EVENT_FIELDS)
        writer.writeheader()
        writer.writerows(source_events)

    frame_path = args.out_dir / "source_frame_cycles.csv"
    with frame_path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=("source_frame", "cycle_start", "cycle_end", "cycle_delta"))
        writer.writeheader()
        writer.writerows(machine.frame_stats)

    compare_paths = []
    if not args.no_compare:
        compare_paths = args.fceux_trace or list(DEFAULT_FCEUX_TRACES)
    comparisons = [compare_trace(source_events, machine.frame_stats, machine.startup_ppu_bus_events,
                                 path.resolve()) for path in compare_paths]
    report = {
        "purpose": "reproducible ROM-only reset/startup instruction trace through source frame 9; FCEUX is post-run validation only",
        "source_rom_sha256": rom_hash,
        "cpu_engine": "Py65 1.2.0 from step_rom_source_cpu_ppu_dmc.Machine",
        "source_input": "all P1 buttons released; no input or capture timeline read",
        "source_frames_advanced": machine.source_frame,
        "source_cpu_cycles": machine.cpu_cycles,
        "source_frame_cycles": machine.frame_stats,
        "source_cpu_interrupts": machine.cpu_interrupt_events,
        "source_instruction_event_count": len(source_events),
        "milestones": [
            row for row in source_events
            if row["pc"] in {"$FFF0", "$C503", "$C64E", "$9EED", "$801F", "$8024",
                             "$8464", "$8494", "$9F69", "$9FA8", "$84C6", "$84E7", "$C500"}
        ],
        "named_milestones": {
            "first_literal_9eed_scan": next((row for row in source_events if row["pc"] == "$9EED"), None),
            "cold_start_entry": next((row for row in source_events if row["pc"] == "$801F"), None),
            "worker_context_install": next((row for row in source_events if row["pc"] == "$8494"), None),
            "worker_ready_sentinel_install": next((row for row in source_events
                if row["pc"] == "$9F69" and row["source_frame"] == 8), None),
            "pre_nmi_main_task_yield": next((row for row in source_events
                if row["pc"] == "$9FA8" and row["source_frame"] == 8), None),
            "pre_nmi_worker_resume": next((row for row in source_events
                if row["pc"] == "$84C6" and row["source_frame"] == 8), None),
            "first_nmi_accept": next((row for row in machine.cpu_interrupt_events
                if row["kind"] == "NMI"), None),
            "first_nmi_handler_entry": next((row for row in source_events
                if row["pc"] == "$C500"), None),
        },
        "outputs": {
            "source_reset_instruction_events.csv": sha256(event_path.read_bytes()),
            "source_frame_cycles.csv": sha256(frame_path.read_bytes()),
        },
        "runtime_phase_resource": None,
        "fceux_post_run_comparisons": comparisons,
        "status_comparison_note": "Only 6502 P's synthetic B ($10) and U ($20) bits are masked when comparing register states; live N,V,D,I,Z,C flags, all A/X/Y/S registers, RAM snapshots, PCs and cycles are compared exactly. Raw P bytes remain in the CSV.",
        "limitations": [
            "This is a diagnostics-only ROM stepper; it is not connected to Godot runtime.",
            "Its simplified PPU scheduler follows pinned FCEUX NewPPU/frame semantics; the trace does not claim physical 2C02 timing.",
            "Frame-9 palette write CPU cycles are compared against the retained FCEUX PPU bus trace; scanline/dot and rendered subframe edges remain unavailable.",
            "It validates the earliest cold-start scheduler/NMI anchor only; later intro EC/F1/FD/F8 maps are outside scope.",
        ],
    }
    if args.write_runtime_resource:
        runtime_path = ROOT / "assets/opening/rom_logic/cold_start_bootstrap_phase.json"
        runtime_path.parent.mkdir(parents=True, exist_ok=True)
        runtime_bytes = (json.dumps(build_runtime_phase(machine, source_events, comparisons), indent=2) + "\n").encode("utf-8")
        runtime_path.write_bytes(runtime_bytes)
        report["runtime_phase_resource"] = {
            "path": runtime_path.relative_to(ROOT).as_posix(),
            "sha256": sha256(runtime_bytes),
            "derived_without_fceux_input": True,
        }
    report_path = args.out_dir / "source_reset_stepper_report.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({
        "source_frames_advanced": machine.source_frame,
        "source_cpu_cycles": machine.cpu_cycles,
        "source_instruction_event_count": len(source_events),
        "runtime_phase_resource": report["runtime_phase_resource"],
        "comparisons": [
            {"trace": item["trace"], "matched": item["matched_pc_cycle_rows"],
             "fceux_rows": item["fceux_event_rows_through_frame_9"],
             "mismatches": item["register_and_ram_mismatch_count"],
             "missing": len(item["missing_source_rows"]),
             "exact_live_state": item["exact_pc_cycle_live_register_ram_match"],
             "frame_cycle_rows": item["frame_cycle_rows_compared"],
             "frame_cycle_mismatches": item["frame_cycle_mismatch_count"],
             "exact_frame_cycles": item["exact_frame_cycle_match"]}
            for item in comparisons
        ],
    }, indent=2))
    print(report_path)


if __name__ == "__main__":
    main()
