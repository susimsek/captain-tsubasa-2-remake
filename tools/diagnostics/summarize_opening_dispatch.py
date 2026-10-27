#!/usr/bin/env python3
"""Join FCEUX dispatch/handler hooks into per-script-opcode execution rows."""
import csv
import sys
from collections import Counter
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit("usage: summarize_opening_dispatch.py <capture-directory>")
root = Path(sys.argv[1])
rows = list(csv.DictReader((root / "dispatch.csv").open(newline="")))
by_seq = {}
for row in rows:
    by_seq.setdefault(row["seq"], []).append(row)

out_path = root / "opcode_flow.csv"
header = [
    "seq", "source_frame", "emulator_frame", "script_ptr", "opcode", "arg",
    "handler_class", "expected_handler_pc", "observed_handler_pc",
    "mmc3_select", "prg_8000", "prg_a000", "prg_c000", "prg_e000",
    "r0", "r1", "r2", "r3", "r4", "r5", "r6", "r7",
    "next_ptr", "next_opcode", "next_frame", "handler_entry_observed",
]
coverage = Counter()
flow_rows = []
with out_path.open("w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=header)
    w.writeheader()
    for row in rows:
        if row["event"] != "interpreter":
            continue
        seq = row["seq"]
        group = by_seq[seq]
        opcode = int(row["opcode"][1:], 16)
        entry_pc = row["expected_handler_pc"]
        inline_event = "inline_D8_DF" if 0xD8 <= opcode <= 0xDF else "inline_E0_E7" if 0xE0 <= opcode <= 0xE7 else None
        handler = next((x for x in group if x["event"] == "handler"
                        and x["pc"] == entry_pc and x["script_ptr"] == row["script_ptr"]), None) if entry_pc else None
        if inline_event:
            inline_pc = "$8508" if opcode <= 0xDF else "$8520"
            entry_pc = inline_pc
            handler = next((x for x in group if x["event"] == inline_event
                            and x["pc"] == inline_pc and x["script_ptr"] == row["script_ptr"]), None)
        continuation = next((x for x in group if x["event"] in ("continuation", "endpoint_no_next_dispatch")), None)
        if opcode >= 0xE8:
            handler_class = "vector"
            coverage[(row["opcode"], bool(handler))] += 1
        elif inline_event:
            handler_class = "inline"
            coverage[(row["opcode"], bool(handler))] += 1
        elif opcode >= 0xD8:
            handler_class = "control/inline-unmapped"
        else:
            handler_class = "text/data path"
        output = {key: row.get(key, "") for key in header}
        output.update({
            "handler_class": handler_class,
            "expected_handler_pc": entry_pc,
            "observed_handler_pc": handler["pc"] if handler else "",
            "next_ptr": continuation["next_ptr"] if continuation else "",
            "next_opcode": continuation["next_opcode"] if continuation else "",
            "next_frame": continuation["next_frame"] if continuation else "",
            "handler_entry_observed": "yes" if handler else ("no" if entry_pc else "n/a"),
        })
        w.writerow(output)
        flow_rows.append(output)

with (root / "opcode_flow_summary.txt").open("w") as f:
    f.write(f"source={root}\n")
    f.write(f"dispatch_rows={sum(1 for r in rows if r['event']=='interpreter')}\n")
    f.write("Per-opcode handler entry coverage (opcode, count, hits, missing):\n")
    counts = Counter()
    hits = Counter()
    for r in flow_rows:
        op = int(r["opcode"][1:], 16)
        if op >= 0xD8:
            counts[r["opcode"]] += 1
            if r["handler_entry_observed"] == "yes":
                hits[r["opcode"]] += 1
    for op in sorted(counts, key=lambda value: int(value[1:], 16)):
        f.write(f"{op},{counts[op]},{hits[op]},{counts[op]-hits[op]}\n")
print(out_path)
