#!/usr/bin/env python3
"""Compare ROM-only A160 visual-event predictions with opcode $CE set to six cycles.

The controller route is the only external input to ROM execution. The existing
event JSON is read after prediction solely as a comparison baseline; captured
PPU state, screenshots, WAV, and PCM are not opened.
"""

from __future__ import annotations

import hashlib
import importlib.util
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PREDICTOR = ROOT / "tools/diagnostics/predict_a160_ppu_dots_irq_return_poc_20261026.py"
BASELINE = ROOT / "reference/rom_extract/intro/rom_source_a160_ppu_write_timeline.json"
OUT_DIR = ROOT / "reference/diagnostics/audio/rom_stepper_opcode_ce6_full_4692_20261026"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
EXPECTED_INPUT_SHA256 = "195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3"
LAST_FRAME = 3649


def load_predictor():
    spec = importlib.util.spec_from_file_location("ce6_a160_predictor", PREDICTOR)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load predictor: {PREDICTOR}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def pack_events(rows: list[dict]) -> list[dict]:
    frames: dict[int, dict[str, dict]] = {}
    for row in rows:
        pc = str(row["instruction_pc"])
        if pc not in ("$A175", "$A178"):
            continue
        frame = int(row["source_frame"])
        frames.setdefault(frame, {})[pc] = {
            "cpu_cycle": int(row["cpu_cycle"]),
            "scanline": int(row["predicted_scanline"]),
            "dot": int(row["predicted_dot"]),
            "value": int(row["value"]),
        }
    packed = []
    for frame, writes in sorted(frames.items()):
        if set(writes) != {"$A175", "$A178"}:
            raise RuntimeError(f"incomplete event pair in frame {frame}: {writes}")
        packed.append({"source_frame": frame, "writes": [writes["$A175"], writes["$A178"]]})
    return packed


def main() -> None:
    model = load_predictor()
    rom = model.base.ROM_PATH.read_bytes()
    input_path = model.base.INPUT_PATH
    input_bytes = input_path.read_bytes()
    if sha256(rom) != EXPECTED_ROM_SHA256:
        raise SystemExit("supplied ROM hash differs from audited revision")
    if sha256(input_bytes) != EXPECTED_INPUT_SHA256:
        raise SystemExit("same-input route hash differs from audited route")
    inputs = model.base.stepper.load_input_timeline(input_path)

    class CE6IRQReturnMachine(model.IRQReturnMachine):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, **kwargs)
            base_cycles = int(self.cpu.cycletime[0xCE])
            if base_cycles != 3:
                raise RuntimeError(f"expected Py65 $CE base=3, got {base_cycles}")
            self.cpu.cycletime[0xCE] = 6

        def _irq_clock(self, _source_ppu_line=None, _source_ppu_dot=None) -> None:
            # The shared stepper now supplies the source PPU coordinates;
            # preserve the predictor's pinned NewPPU slot-2 behavior while
            # accepting the newer hook signature.
            super()._irq_clock()

    machine = CE6IRQReturnMachine(rom, inputs)
    machine.run(LAST_FRAME)
    candidate_events = pack_events(machine.store_rows)
    baseline = json.loads(BASELINE.read_text(encoding="utf-8"))
    baseline_events = baseline["events"]
    by_frame_base = {int(row["source_frame"]): row for row in baseline_events}
    by_frame_candidate = {int(row["source_frame"]): row for row in candidate_events}
    frame_ids = sorted(set(by_frame_base) | set(by_frame_candidate))
    differences = []
    for frame in frame_ids:
        old = by_frame_base.get(frame)
        new = by_frame_candidate.get(frame)
        if old != new:
            differences.append({"source_frame": frame, "baseline": old, "ce6": new})

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    candidate_path = OUT_DIR / "a160_visual_events_ce6_candidate.json"
    candidate_doc = {
        "purpose": "diagnostics-only ROM-source A160 $2006 visual-event candidate under pinned FCEUX $CE timing",
        "rom_sha256": EXPECTED_ROM_SHA256,
        "input_timeline_sha256": EXPECTED_INPUT_SHA256,
        "source_model": "same ROM-only NewPPU/IRQ-return predictor as baseline; only Py65 absolute DEC ($CE) changed from 3 to 6 cycles",
        "source_frame_range": [min(by_frame_candidate), max(by_frame_candidate)] if candidate_events else None,
        "frame_count": len(candidate_events),
        "write_count": sum(len(event["writes"]) for event in candidate_events),
        "captured_ppu_trace_used_as_execution_input": False,
        "events": candidate_events,
    }
    candidate_path.write_text(json.dumps(candidate_doc, indent=2) + "\n", encoding="utf-8")

    report = {
        "purpose": "post-run comparison of ROM-derived A160 visual-event timeline under the $CE=6 candidate",
        "rom_sha256": EXPECTED_ROM_SHA256,
        "input_timeline_sha256": EXPECTED_INPUT_SHA256,
        "baseline_sha256": sha256(BASELINE.read_bytes()),
        "candidate_sha256": sha256(candidate_path.read_bytes()),
        "candidate_path": candidate_path.relative_to(ROOT).as_posix(),
        "baseline_frame_count": len(baseline_events),
        "candidate_frame_count": len(candidate_events),
        "frames_compared": len(frame_ids),
        "changed_frame_count": len(differences),
        "changed_write_count": sum(
            sum(a != b for a, b in zip((d["baseline"] or {}).get("writes", []), (d["ce6"] or {}).get("writes", [])))
            for d in differences
        ),
        "first_changed_frames": differences[:20],
        "interpretation": "A prediction-timeline delta requires visual-event schedule/resource review and targeted rendering parity recapture before any runtime promotion; it does not establish pixel parity by itself.",
    }
    report_path = OUT_DIR / "a160_visual_events_ce6_comparison.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({k: v for k, v in report.items() if k != "first_changed_frames"}, indent=2))
    print(f"comparison={report_path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
