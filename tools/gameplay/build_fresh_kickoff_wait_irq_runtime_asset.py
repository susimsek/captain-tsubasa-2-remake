#!/usr/bin/env python3
"""Build the small runtime input for the fresh-match preset raster IRQ.

Only hash-checked ROM instruction spans and the ROM-only candidate IRQ edge
are copied into the Godot resource. The candidate audit snapshot and FCEUX
trace fields are deliberately excluded.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
INPUT_SHA256 = "6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc"
SOURCE_MANIFEST = ROOT / "reference/rom_extract/gameplay/fresh_kickoff_0078_wait_20261029/manifest.json"
EDGE_SCHEDULE = ROOT / "reference/rom_extract/gameplay/fresh_kickoff_893b_irq_candidate_schedule_20261031.json"
OUTPUT = ROOT / "assets/gameplay/rom_logic/fresh_kickoff_preset_wait_irq_runtime.json"
SCHEMA = "ct2-fresh-kickoff-preset-wait-irq-runtime-v1"
REQUIRED_SPANS = {
    "vector_trampolines": "fixed_vector_trampolines_C500_C508.bin",
    "irq_dispatch": "fixed_irq_dispatch_C821_C827.bin",
    "irq_service": "fixed_raster_irq_service_C478_C4AD.bin",
    "interrupt_vectors": "fixed_nmi_irq_vectors_FFFA_FFFF.bin",
    "bank2_irq_consumer": "bank02_irq_event_consumer_A160_A1E1.bin",
    "bank2_irq_consumer_tail": "bank02_mapper_pair_tail_A1E2_A1E4.bin",
}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def read_document(path: Path) -> dict:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise SystemExit(f"Expected a JSON object in {path.relative_to(ROOT)}")
    return value


def main() -> None:
    manifest = read_document(SOURCE_MANIFEST)
    if manifest.get("schema") != "ct2-fresh-kickoff-0078-wait-source-v1" \
            or manifest.get("rom", {}).get("sha256") != ROM_SHA256:
        raise SystemExit("The wait/IRQ manifest targets a different ROM or schema.")
    entries = {Path(span["file"]).name: span for span in manifest.get("spans", [])}
    spans: dict[str, dict] = {}
    for span_id, filename in REQUIRED_SPANS.items():
        entry = entries.get(filename)
        if not isinstance(entry, dict):
            raise SystemExit(f"The source manifest omits {filename}.")
        raw = bytes.fromhex(str(entry.get("bytes", "")))
        if len(raw) != int(entry.get("length", -1)) \
                or sha256(raw) != str(entry.get("sha256", "")):
            raise SystemExit(f"The ROM span {filename} failed its manifest hash.")
        spans[span_id] = {
            "cpu_start": entry["cpu_start"],
            "cpu_end_exclusive": entry["cpu_end_exclusive"],
            "length": len(raw),
            "sha256": sha256(raw),
            "bytes_hex": raw.hex(),
        }

    schedule = read_document(EDGE_SCHEDULE)
    if schedule.get("schema") != "ct2-kickoff-preset-irq-source-schedule-v1" \
            or schedule.get("source_rom_sha256") != ROM_SHA256 \
            or schedule.get("input_route", {}).get("sha256") != INPUT_SHA256:
        raise SystemExit("The candidate edge schedule has unsupported ROM/route provenance.")
    irq_release = schedule.get("irq_wait_release", {})
    edge = irq_release.get("irq_edge", {})
    if irq_release.get("runtime_must_execute_rom_irq_handlers") is not True \
            or edge.get("source_frame") != 7266 \
            or edge.get("source_cycle") != 216372246 \
            or edge.get("ppu_line") != 128 or edge.get("ppu_dot") != 274:
        raise SystemExit("The candidate IRQ edge differs from the reviewed frame-7266 event.")

    document = {
        "schema": SCHEMA,
        "source_rom_sha256": ROM_SHA256,
        "input_route_sha256": INPUT_SHA256,
        "source_manifest_sha256": sha256(SOURCE_MANIFEST.read_bytes()),
        "candidate_schedule_sha256": sha256(EDGE_SCHEDULE.read_bytes()),
        "source_event_id": irq_release["source_event_id"],
        "irq_edge": {
            "source_frame": int(edge["source_frame"]),
            "source_cycle": int(edge["source_cycle"]),
            "ppu_line": int(edge["ppu_line"]),
            "ppu_dot": int(edge["ppu_dot"]),
            "counter_before": int(edge["counter_before"]),
            "counter_after": int(edge["counter_after"]),
            "latch": int(edge["latch"]),
            "irq_enabled": int(edge["irq_enabled"]),
        },
        "source_spans": spans,
        "limits": {
            "candidate_irq_edge_only": True,
            "runtime_executes_rom_handler": True,
            "fceux_trace_used_as_runtime_input": False,
            "candidate_endpoint_state_used": False,
            "physical_nes_timing_proven": False,
            "complete_ppu_fetch_parity": False,
        },
    }
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(document, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({
        "output": OUTPUT.relative_to(ROOT).as_posix(),
        "source_spans": {key: value["sha256"] for key, value in spans.items()},
        "irq_edge": document["irq_edge"],
        "source_rom_sha256": ROM_SHA256,
        "input_route_sha256": INPUT_SHA256,
    }, indent=2))


if __name__ == "__main__":
    main()
