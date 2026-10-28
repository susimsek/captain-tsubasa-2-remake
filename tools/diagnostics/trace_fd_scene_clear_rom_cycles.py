#!/usr/bin/env python3
"""Trace FD-clear instruction and PPU-write cycles from ROM only, then compare retained FCEUX evidence.

The ROM/input replay creates the source trace. The FCEUX bus and PC-hook files
are read only after execution, solely for validation. This script never uses
captured pixels or audio and does not modify the Godot runtime.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import importlib.util
import json
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[2]
ROM = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
INPUT = ROOT / "reference/opening_reference_capture/input_timeline.csv"
FCEUX_BUS = ROOT / "reference/opening_timing_capture_20261024_125300/bus_events.csv"
FCEUX_EXEC = ROOT / "reference/diagnostics/text_cursor_reset_ram_writes_20261025_144029/cursor_setup_exec.csv"
STEPPER = ROOT / "tools/diagnostics/step_rom_source_cpu_ppu_dmc.py"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
INPUT_SHA256 = "195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3"
FD_FRAMES = (810, 1025, 1525, 1756, 2117, 2336, 2685, 2904, 3469)
NMI_FRAMES = (3470, 3471, 3472, 3473)
FD_RESUME_FRAMES = (3476,)
TARGET_FRAMES = set(FD_FRAMES + NMI_FRAMES + FD_RESUME_FRAMES)
PC_LABELS = {
    0x8855: "fd_handler",
    0x88B1: "fd_fill_parameter_helper",
    0x885A: "fd_wait_call",
    0x9FA8: "cooperative_yield",
    0x885D: "fd_wait_resume",
    0x8887: "fd_script_advance",
    0x98E8: "fill_dispatch_entry",
    0x98EC: "fade_gate_test",
    0x992C: "direct_fill_entry",
    0x993C: "rendering_off",
    0x9949: "row_address_high",
    0x994E: "row_address_low",
    0x9953: "direct_fill_data_bus_pc",
    0x996E: "rendering_restore",
    0x9B28: "queued_row_reserve",
    0x9B5E: "queued_fill_commit",
    0xA03C: "nmi_queue_consumer",
}
REG_EVENTS = {
    0x2000: "PPUCTRL_write",
    0x2001: "PPUMASK_write",
    0x2006: "PPUADDR_write",
    0x2007: "PPUDATA_write",
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_stepper():
    spec = importlib.util.spec_from_file_location("ct2_source_stepper", STEPPER)
    if spec is None or spec.loader is None:
        raise RuntimeError("could not import the pinned ROM-only source stepper")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def read_rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as stream:
        return list(csv.DictReader(stream))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out-dir", type=Path, required=True)
    args = parser.parse_args()
    out_dir = args.out_dir.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    if sha256(ROM) != ROM_SHA256 or sha256(INPUT) != INPUT_SHA256:
        raise SystemExit("ROM or same-input timeline hash mismatch")
    if not FCEUX_BUS.is_file() or not FCEUX_EXEC.is_file():
        raise SystemExit("retained FCEUX validation traces are missing")

    module = load_stepper()
    rom = ROM.read_bytes()
    inputs = module.load_input_timeline(INPUT)
    module_pc_events: list[dict] = []
    module_ppu_events: list[dict] = []
    machine_type = module.Machine
    original_step = machine_type._cpu_instruction
    original_store = machine_type.__setitem__

    def traced_step(machine):
        frame = machine.source_frame
        pc = machine.cpu.pc & 0xFFFF
        if frame in TARGET_FRAMES and pc in PC_LABELS:
            module_pc_events.append({
                "source_frame": frame,
                "cycle_absolute": machine.cpu_cycles,
                "cycle_from_frame_start": machine.cpu_cycles - machine.frame_cycle_start,
                "event": PC_LABELS[pc],
                "pc": f"${pc:04X}",
                "opcode": f"${machine[pc]:02X}",
                "prg_bank_8k": machine._prg_bank(pc),
                "script_pointer": machine.ram[0x04D] | (machine.ram[0x04E] << 8),
                "fade_state": [machine.ram[x] for x in (0x4A, 0x4B)],
                "fill_state": [machine.ram[x] for x in (0x4F, 0x50, 0x54)],
                "queue_count": machine.ram[0x0628],
            })
        return original_step(machine)

    def traced_store(machine, addr: int, value: int) -> None:
        canonical = 0x2000 | (addr & 7) if 0x2000 <= addr < 0x4000 else -1
        if machine.source_frame in TARGET_FRAMES and canonical in REG_EVENTS:
            pc = machine.current_instruction_pc & 0xFFFF
            module_ppu_events.append({
                "source_frame": machine.source_frame,
                "cycle_absolute": machine.cpu_cycles,
                "cycle_from_frame_start": machine.cpu_cycles - machine.frame_cycle_start,
                "event": REG_EVENTS[canonical],
                "address": f"${canonical:04X}",
                "value": f"${value & 0xFF:02X}",
                "pc": f"${pc:04X}",
            })
        original_store(machine, addr, value)

    machine_type._cpu_instruction = traced_step
    machine_type.__setitem__ = traced_store
    machine = machine_type(rom, inputs)
    try:
        machine.run(max(TARGET_FRAMES))
    finally:
        machine_type._cpu_instruction = original_step
        machine_type.__setitem__ = original_store

    with (out_dir / "rom_source_pc_events.csv").open("w", newline="", encoding="utf-8") as stream:
        fields = ("source_frame", "cycle_absolute", "cycle_from_frame_start", "event", "pc", "opcode",
                  "prg_bank_8k", "script_pointer", "fade_state", "fill_state", "queue_count")
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        for row in module_pc_events:
            writer.writerow({**row, "fade_state": " ".join(f"${v:02X}" for v in row["fade_state"]),
                             "fill_state": " ".join(f"${v:02X}" for v in row["fill_state"])})
    with (out_dir / "rom_source_ppu_writes.csv").open("w", newline="", encoding="utf-8") as stream:
        fields = ("source_frame", "cycle_absolute", "cycle_from_frame_start", "event", "address", "value", "pc")
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        writer.writerows(module_ppu_events)

    fceux_bus = []
    with FCEUX_BUS.open(newline="", encoding="utf-8") as stream:
        for row in csv.DictReader(stream):
            if int(row["source_frame"]) in TARGET_FRAMES and row["event"] in REG_EVENTS.values():
                fceux_bus.append(row)
    source_bus = [{"source_frame": str(row["source_frame"]),
                   "cycle_from_frame_start": str(row["cycle_from_frame_start"]),
                   "event": row["event"], "address": row["address"], "value": row["value"],
                   "cpu_pc": row["cpu_pc"]} for row in fceux_bus]
    model_bus = [{"source_frame": str(row["source_frame"]),
                  "cycle_from_frame_start": str(row["cycle_from_frame_start"]),
                  "event": row["event"], "address": row["address"], "value": row["value"],
                  "cpu_pc": row["pc"]} for row in module_ppu_events]

    def key(row: dict[str, str]) -> tuple:
        return (row["source_frame"], row["cycle_from_frame_start"], row["event"], row["address"], row["value"])

    fceux_by_frame: dict[str, list[dict[str, str]]] = {}
    model_by_frame: dict[str, list[dict[str, str]]] = {}
    for row in source_bus:
        fceux_by_frame.setdefault(row["source_frame"], []).append(row)
    for row in model_bus:
        model_by_frame.setdefault(row["source_frame"], []).append(row)
    ppu_comparison = {}
    for frame in sorted(TARGET_FRAMES):
        f = fceux_by_frame.get(str(frame), [])
        m = model_by_frame.get(str(frame), [])
        f_keys = [key(row) for row in f]
        m_keys = [key(row) for row in m]
        f_data = [(row["event"], row["address"], row["value"]) for row in f]
        m_data = [(row["event"], row["address"], row["value"]) for row in m]
        cycle_deltas = [int(model_row["cycle_from_frame_start"]) - int(fceux_row["cycle_from_frame_start"])
                        for fceux_row, model_row in zip(f, m)
                        if (fceux_row["event"], fceux_row["address"], fceux_row["value"])
                        == (model_row["event"], model_row["address"], model_row["value"])]
        delta_histogram: dict[str, int] = {}
        for delta in cycle_deltas:
            delta_histogram[str(delta)] = delta_histogram.get(str(delta), 0) + 1
        ppu_comparison[str(frame)] = {
            "fceux_event_count": len(f),
            "rom_stepper_event_count": len(m),
            "ordered_register_values_match": f_data == m_data,
            "exact_ordered_bus_match": f_keys == m_keys,
            "cycle_delta_histogram_rom_minus_fceux": delta_histogram,
            "first_data_mismatch": None,
            "first_cycle_mismatch": None,
        }
        if f_data != m_data:
            first = next((i for i, pair in enumerate(zip(f_data, m_data)) if pair[0] != pair[1]), min(len(f_data), len(m_data)))
            ppu_comparison[str(frame)]["first_data_mismatch"] = {
                "index": first,
                "fceux": f[first] if first < len(f) else None,
                "rom_stepper": m[first] if first < len(m) else None,
            }
        if f_keys != m_keys:
            first = next((i for i, pair in enumerate(zip(f_keys, m_keys)) if pair[0] != pair[1]), min(len(f_keys), len(m_keys)))
            ppu_comparison[str(frame)]["first_cycle_mismatch"] = {
                "index": first,
                "fceux": f[first] if first < len(f) else None,
                "rom_stepper": m[first] if first < len(m) else None,
            }

    fceux_exec_rows = [row for row in read_rows(FCEUX_EXEC) if row["source_frame"] == "2904"
                       and row["event"] in ("FD_handler_8855", "FD_fill_helper_88B1", "FD_wait_jsr_885A")]
    fceux_wait_cycle = next(int(row["cycle_from_frame_start"]) for row in fceux_exec_rows
                            if row["event"] == "FD_wait_jsr_885A")
    fceux_yield = next(row for row in read_rows(FCEUX_EXEC)
                       if row["source_frame"] == "2904" and row["event"] == "cooperative_yield_9FA8"
                       and int(row["cycle_from_frame_start"]) > fceux_wait_cycle
                       and row["scheduler_slot_0000"] == "$05")
    fceux_exec_rows.append(fceux_yield)
    stepper_base = [row for row in module_pc_events if row["source_frame"] == 2904
                    and row["pc"] in ("$8855", "$88B1", "$885A")]
    stepper_wait_cycle = next(row["cycle_from_frame_start"] for row in stepper_base if row["pc"] == "$885A")
    stepper_yield = next(row for row in module_pc_events if row["source_frame"] == 2904
                         and row["pc"] == "$9FA8" and row["cycle_from_frame_start"] > stepper_wait_cycle)
    stepper_2904 = stepper_base + [stepper_yield]
    fceux_exec = [{"source_frame": int(row["source_frame"]), "pc": row["cpu_pc"],
                   "cycle_from_frame_start": int(row["cycle_from_frame_start"]), "event": row["event"]}
                  for row in fceux_exec_rows]
    stepper_exec = [{"source_frame": row["source_frame"], "pc": row["pc"],
                     "cycle_from_frame_start": row["cycle_from_frame_start"], "event": row["event"]}
                    for row in stepper_2904]
    fceux_exec_map = {row["pc"]: row["cycle_from_frame_start"] for row in fceux_exec}
    stepper_exec_map = {row["pc"]: row["cycle_from_frame_start"] for row in stepper_exec}

    report = {
        "result": "PASS" if all(v["exact_ordered_bus_match"] for v in ppu_comparison.values()) else "DIAGNOSTIC_MISMATCH",
        "rom_sha256": ROM_SHA256,
        "input_timeline_sha256": INPUT_SHA256,
        "stepper": "ROM-only reset execution with pinned Py65 model; FCEUX data is read only after execution for comparison",
        "target_fd_dispatch_frames": list(FD_FRAMES),
        "queued_nmi_drain_frames": list(NMI_FRAMES),
        "target_fd_resume_frames": list(FD_RESUME_FRAMES),
        "rom_source_pc_event_count": len(module_pc_events),
        "rom_source_ppu_write_count": len(module_ppu_events),
        "fceux_vs_rom_source_ppu_bus": ppu_comparison,
        "direct_fceux_pc_cycle_crosscheck_frame_2904": {
            "source": "reference/diagnostics/text_cursor_reset_ram_writes_20261025_144029/cursor_setup_exec.csv",
            "fceux": fceux_exec,
            "rom_stepper": stepper_exec,
            "exact_pc_cycle_match": fceux_exec_map == stepper_exec_map,
            "cycle_residuals": {pc: stepper_exec_map.get(pc) - cycle for pc, cycle in fceux_exec_map.items()
                                 if pc in stepper_exec_map},
        },
        "limitations": [
            "The retained FCEUX instruction-hook trace directly covers only the frame-2904 FD call. The prepared muted same-input FCEUX trace is needed to directly stamp all nine handler PCs.",
            "The source stepper models DMC reads but omits physical 2A03 halt/get-put DMA arbitration; its post-frame-367 instruction-cycle labels are not hardware-validated.",
            "Any PPU bus equality is an emulator-model comparison against the retained FCEUX NewPPU bus log, not physical NES timing.",
        ],
    }
    (out_dir / "fd_rom_source_cycle_comparison.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"result": report["result"], "report": str(out_dir / "fd_rom_source_cycle_comparison.json"),
                      "ppu_frames_cycle_exact": [frame for frame, value in ppu_comparison.items() if value["exact_ordered_bus_match"]],
                      "ppu_frames_values_exact": [frame for frame, value in ppu_comparison.items() if value["ordered_register_values_match"]],
                      "direct_pc_cycle_match_2904": report["direct_fceux_pc_cycle_crosscheck_frame_2904"]["exact_pc_cycle_match"]}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
