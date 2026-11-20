#!/usr/bin/env python3
"""Extract and verify ROM-only source spans for the post-PASS scenario-$1C route."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUT_DIR = ROOT / "reference/rom_extract/gameplay/pass_scenario_1c"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
ROM_SIZE = 393_232
HEADER_BYTES = 0x10
PRG_BANK_SIZE = 0x2000
SCENARIO_TABLE_CPU = 0x89BF
SCENARIO_TABLE_OFFSET = 0x0209CF


def _span(name: str, filename: str, bank: int, window: int, start: int,
          length: int, role: str, boundary: str) -> dict[str, object]:
	return {
		"name": name,
		"file": filename,
		"bank": bank,
		"window_start": window,
		"cpu_start": start,
		"length_bytes": length,
		"role": role,
		"boundary_status": boundary,
	}


# Code prefixes are labeled as such when a function boundary is not established.
# Fixed-bank references in the manifest are validated against their existing
# project-owned source files rather than copied into this package.
SPAN_SPECS: list[dict[str, object]] = [
	_span("scenario_1C_pointer_entry", "scenario_1C_pointer_entry.bin", 0x10, 0x8000,
		0x89F7, 2, "Little-endian bank-$10 pointer-table entry for scenario ID $1C.",
		"Exact two-byte table entry."),
	_span("scenario_24_exclusive_boundary_pointer", "scenario_24_boundary_pointer.bin", 0x10, 0x8000,
		0x8A07, 2, "Pointer-table entry ID $24; its target $9BF2 is the first greater valid pointer after scenario $1C.",
		"Exact two-byte table entry."),
	_span("scenario_1C_root_stream", "scenario_1C.bin", 0x10, 0x8000,
		0x9BE3, 15, "Scenario-$1C root bytes, bounded by the next greater valid pointer in the full 256-entry table.",
		"Pointer-bounded; end is exclusive at CPU $9BF2."),
	_span("scenario_1C_FA_target_context", "bank10_FA_target_context_9F3E_9F7E.bin", 0x10, 0x8000,
		0x9F3E, 0x40, "ROM context at the nested target selected by root opcode FA $3E $9F.",
		"64-byte context prefix only; not claimed as a complete nested script."),
	_span("scenario_1C_FA_dispatch_wrapper_9F3E_9F54", "bank10_FA_dispatch_wrapper_9F3E_9F54.bin", 0x10, 0x8000,
		0x9F3E, 0x16, "Two exact F3 selector tables: $F3 $10 indexes five targets using $043B; when it selects $9F4A, $F3 $1E indexes four branch targets using $043C&$7F.",
		"Exact wrapper and inline pointer-table bytes through the next byte at $9F54; selected target streams are external/dynamic."),
	_span("scenario_1C_FA_branch_BB4B_BB50", "bank10_FA_branch_BB4B_BB50.bin", 0x10, 0x8000,
		0xBB4B, 5, "Exact selected nested branch: one event record ($30 $1F $4C $00) followed by local $FB return to scenario-$1C root.",
		"Exact five-byte nested stream including local FB; this bounds the nested call only, not the later field worker or visible result."),
	_span("scenario_1C_F2_target_B49E_context", "bank10_F2_target_context_B49E.bin", 0x10, 0x8000,
		0xB49E, 0x30, "Context prefix at the first little-endian F2 pointer target $B49E.",
		"48-byte context prefix only; not claimed as a complete script."),
	_span("scenario_1C_F2_target_B4B6_context", "bank10_F2_target_context_B4B6.bin", 0x10, 0x8000,
		0xB4B6, 0x30, "Context prefix at the second little-endian F2 pointer target $B4B6.",
		"48-byte context prefix only; not claimed as a complete script."),
	_span("bank10_scenario_opcode_dispatch", "bank10_scenario_opcode_dispatch_80A9_80CF.bin", 0x10, 0x8000,
		0x80A9, 0x26, "Opcode dispatcher and inline F0-FF handler pointer table. Resolves F2->$80F4, F3->$8105, FA->$881A, and FD->$885D.",
		"Exact dispatcher/table span through the first handler at $80CF."),
	_span("bank10_F2_pointer_replacement_handler", "bank10_F2_handler_80F4_8105.bin", 0x10, 0x8000,
		0x80F4, 0x11, "F2 handler reads a little-endian stream pointer into $5D/$5E, clears stream offset $3A, then returns.",
		"Exact instruction span ending before F3 handler $8105."),
	_span("bank10_F3_handler_context", "bank10_F3_handler_context_8105_8138.bin", 0x10, 0x8000,
		0x8105, 0x33, "F3 handler body and its branch to $80F6; its full route-specific result/continuation semantics are not decoded here.",
		"Bounded instruction context; includes the handler return/jump paths but not all dispatch targets."),
	_span("bank10_F3_dispatch_targets_816E_81F9", "bank10_F3_dispatch_table_816E_81F9.bin", 0x10, 0x8000,
		0x816E, 0x8B, "F3 operand dispatch helper and inline pointer table entries 0 through $42; covers selector values seen in the extracted $9F3E context.",
		"Exact prefix through table entry $42; higher selector entries are not included."),
	_span("bank10_F3_selector04_helper_8259_8260", "bank10_F3_selector04_helper_8259_8260.bin", 0x10, 0x8000,
		0x8259, 7, "F3 selector $04 returns X=$044E when zero, or X=$044E-1 when nonzero.",
		"Exact helper through RTS."),
	_span("bank10_F3_selector10_helper_836E_837C", "bank10_F3_selector10_helper_836E_837C.bin", 0x10, 0x8000,
		0x836E, 14, "Complete F3 selector $10 helper: initializes X=0, compares $043B with 1, conditionally calls $8677 and increments X, then returns.",
		"Exact helper through RTS at $837B."),
	_span("bank10_F3_selector1E_helper_8401_840A", "bank10_F3_selector1E_helper_8401_840A.bin", 0x10, 0x8000,
		0x8401, 9, "F3 selector $1E loads X=$043C&$7F, then jumps to $8211.",
		"Exact helper through the JMP instruction."),
	_span("bank10_F3_selector1E_flag_helper_8211_821C", "bank10_F3_selector1E_flag_helper_8211_821C.bin", 0x10, 0x8000,
		0x8211, 0x0B, "When selector input is nonzero, sets bit $04 in RAM $0516; returns to the F3 handler.",
		"Exact helper through RTS."),
	_span("bank10_F3_root_F2_target_B49E_B4A6", "bank10_F3_root_target_B49E_B4A6.bin", 0x10, 0x8000,
		0xB49E, 8, "First root F3-$84 branch target selected when helper X=0: one F9 operand, one four-byte record, and FB.",
		"Exact eight-byte stream prefix through its FB byte."),
	_span("bank10_F3_root_F2_target_B4B6_B4BE", "bank10_F3_root_target_B4B6_B4BE.bin", 0x10, 0x8000,
		0xB4B6, 8, "Second root F3-$84 branch target selected when helper X=1: one F9 operand, one four-byte record, and FB.",
		"Exact eight-byte stream prefix through its FB byte."),
	_span("bank10_FD_handler_dispatch_885D_8877", "bank10_FD_dispatch_885D_8877.bin", 0x10, 0x8000,
		0x885D, 0x1A, "FD operand dispatch and its first table target; operand $00 resolves to $8877.",
		"Exact handler/table prefix through target entry $8877."),
	_span("bank10_FD00_handler_context_8877_88A8", "bank10_FD00_handler_context_8877_88A8.bin", 0x10, 0x8000,
		0x8877, 0x31, "FD $00 handler reads holder $0441, resolves its player record, and compares source fields involving $0638.",
		"Bounded handler context; dependent record resolver/compare helpers are referenced separately."),
	_span("bank1A_field_event_setup_8B4A_8B9C", "bank1A_field_event_setup_8B4A_8B9C.bin", 0x1A, 0x8000,
		0x8B4A, 0x52, "Entry target of bank-$1A vector $801E. Calls the coordinate gate, dispatches fixed-bank $C624, initializes fields, then branches to $8298 or $8978.",
		"Exact setup block through the next routine entry at $8B9C."),
	_span("bank1A_field_event_coordinate_gate_8B9C_8BBA", "bank1A_coordinate_gate_8B9C_8BBA.bin", 0x1A, 0x8000,
		0x8B9C, 0x1E, "Returns carry set only when Y=$0637 is in [$60,$A0) and X=$0635 is outside [$50,$B0); otherwise clears carry.",
		"Exact branch-and-return helper through RTS at $8BB9."),
	_span("fixed_C624_dispatch_vectors_C624_C64E", "fixed_C624_dispatch_vectors_C624_C64E.bin", 0x1E, 0xC000,
		0xC624, 0x2A, "Fourteen fixed-bank JMP vectors; the direct JSR $C624 reaches vector 0 at $DCDF.",
		"Exact 14-entry vector table; next byte at $C64E starts another routine."),
	_span("fixed_C624_vector0_target_DCDF_DCF0", "fixed_C624_vector0_target_DCDF_DCF0.bin", 0x1E, 0xC000,
		0xDCDF, 0x11, "If $044E is zero, initializes it to 1+(($00E2)&1); otherwise returns without changing it.",
		"Exact instruction span through RTS at $DCEF."),
	_span("fixed_C609_vector0_C609_C60C", "fixed_C609_vector0_C609_C60C.bin", 0x1E, 0xC000,
		0xC609, 3, "First vector reached by the $8B73 JSR $C609 call; JMP target is bank-$1F $E4D7.",
		"Exact three-byte vector."),
	_span("fixed_C609_vector0_target_E4D7_context", "fixed_C609_vector0_target_E4D7_context.bin", 0x1F, 0xE000,
		0xE4D7, 0x20, "Context for the $8B73 LDA #$0A / JSR $C609 call: vector 0 enters bank-$1F $E4D7 with A=$0A.",
		"32-byte context prefix; full routine boundary and path are not claimed."),
	_span("fixed_C54E_vector0_C54E_C551", "fixed_C54E_vector0_C54E_C551.bin", 0x1E, 0xC000,
		0xC54E, 3, "First vector reached by $8B84 LDA #$2F / JSR $C54E; it jumps to $CBB0 and enqueues scenario $2F.",
		"Exact three-byte vector."),
	_span("fixed_C600_vector0_C600_C603", "fixed_C600_vector0_C600_C603.bin", 0x1E, 0xC000,
		0xC600, 3, "First vector reached by the $8B8C JSR $C600 call; JMP target is $D565.",
		"Exact three-byte vector."),
	_span("fixed_C600_vector0_target_D565_context", "fixed_C600_vector0_target_D565_context.bin", 0x1E, 0xC000,
		0xD565, 0x20, "Context for $C600 vector 0; begins a helper call, selects bank shadows $1A/$1B, then maps them through $CE2D.",
		"32-byte context prefix; full routine boundary and path are not claimed."),
	_span("bank1A_post_C624_helper_87E1_context", "bank1A_post_C624_helper_87E1_context.bin", 0x1A, 0x8000,
		0x87E1, 0x20, "Context for direct JSR $87E1 in $8B4A; begins by using $05FB and resolving a player record through $C50C.",
		"32-byte context prefix; full routine boundary and path are not claimed."),
	_span("bank1A_post_C624_helper_848F_context", "bank1A_post_C624_helper_848F_context.bin", 0x1A, 0x8000,
		0x848F, 0x20, "Context for the conditional JSR $848F in $8B4A when $0621 is not $02.",
		"32-byte context prefix; full routine boundary and path are not claimed."),
	_span("bank1A_post_C624_helper_8E86_context", "bank1A_post_C624_helper_8E86_context.bin", 0x1A, 0x8000,
		0x8E86, 0x20, "Context for the direct JSR $8E86 in $8B4A after fixed vector $C54E enqueues scenario $2F.",
		"32-byte context prefix; full routine boundary and path are not claimed."),
	_span("bank1A_event_branch_8298_context", "bank1A_event_branch_8298_context.bin", 0x1A, 0x8000,
		0x8298, 0x20, "Context at one branch destination selected by $0621=$01 in $8B4A.",
		"32-byte context prefix; full event path is not claimed."),
	_span("bank1A_event_branch_8978_context", "bank1A_event_branch_8978_context.bin", 0x1A, 0x8000,
		0x8978, 0x20, "Context at one branch destination selected by $0621!=$01 in $8B4A.",
		"32-byte context prefix; full event path is not claimed."),
]


DEPENDENCIES: list[dict[str, str]] = [
	{
		"cpu": "$DE6C-$DE95",
		"path": "reference/rom_extract/gameplay/pass_receiver_holder_transfer/pass_holder_commit_and_scenario_handoff_DE6C_DE96.bin",
		"sha256": "d6ab96667636645baf440cfa35b81c05279f471ee3de570af7adbea241867cfa",
		"role": "Confirmed post-PASS caller: holder commit, $E6EC, bank mapping via $CE2D, $801E call, scenario-$1C enqueue through $CBB0, then jump to $E0DF.",
	},
	{
		"cpu": "$E6EC-$E708",
		"path": "reference/rom_extract/gameplay/first_command_field/holder_coordinates/bank_1f_e6ec_holder_coordinate_copy.bin",
		"sha256": "3bf0cf8593e6eccf77d32044c666a39713134e8120a2e3e7deba3541bb6fbf8c",
		"role": "Holder record lookup and holder-coordinate copy called by $DE76.",
	},
	{
		"cpu": "$CE2D-$CE49",
		"path": "reference/rom_extract/gameplay/fresh_bank18_worker_prefix/fixed_stamina_bank_switch_CE2D_CE4A.bin",
		"sha256": "6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c",
		"role": "Maps bank shadows $24/$25 before calling the bank-$1A vector at $801E.",
	},
	{
		"cpu": "$CBB0-$CBC1",
		"path": "reference/rom_extract/gameplay/scenario_task_runtime/fixed_scenario_queue_CBB0_CBC1.bin",
		"sha256": "bda16c7ced2834027dd6039a6c079a701dc8abd9c89179ba2d3c568aa0a16a32",
		"role": "Stores scenario ID $1C into $0518, enables scenario mode, and yields to the task scheduler.",
	},
	{
		"cpu": "$EC08-$EC33",
		"path": "reference/rom_extract/gameplay/scenario_continuation/fixed_scenario_start_ec08_ec33.bin",
		"sha256": "c5283a9bd23ff473de0b43cfa8d98d8d5f3b78255fa75d5b66d649174218c21f",
		"role": "Scenario start maps bank $10 and calls its $8000 reader entry.",
	},
	{
		"cpu": "$8000-$803E",
		"path": "reference/rom_extract/gameplay/scenario_task_runtime/bank10_reader_entry_8000_803E.bin",
		"sha256": "8f7bdba702bda2bc20e19776e2496f96f7c1c8fad07f424e555726fb4ccc3ca5",
		"role": "Resolves $0518 through pointer table $89BF and initializes the source reader at $803F.",
	},
	{
		"cpu": "$881A-$8836",
		"path": "reference/rom_extract/gameplay/scenario_continuation/bank10_fa_handler_881a_8836.bin",
		"sha256": "25c007a559b5f85da1cd991874f85c2c9fa77d68a3b0647cfc347bc0f147aa68",
		"role": "FA nested-call handler saves the caller stream pointer before entering the target loader.",
	},
	{
		"cpu": "$80F6-$8104",
		"path": "reference/rom_extract/gameplay/scenario_continuation/bank10_fa_target_loader_80f6_8104.bin",
		"sha256": "6b735a94e9738de7eebcad8d843c80f5149dac71a2fd846060adbebcd9dea089",
		"role": "Loads FA target pointer $9F3E and resets stream offset $3A.",
	},
	{
		"cpu": "$8837-$8852",
		"path": "reference/rom_extract/gameplay/scenario_continuation/bank10_fb_handler_8837_8852.bin",
		"sha256": "34e0466b33439d4de66876bdb757e2fb8600498f1cc3cf0968d612266af02866",
		"role": "FB restores the saved caller pointer or branches to the scenario terminator on underflow.",
	},
	{
		"cpu": "$C509-$C50B and $CB99-$CBAF",
		"path": "reference/rom_extract/gameplay/scenario_continuation/fixed_scenario_opcode_dispatch_vector_C509_C50B.bin",
		"sha256": "3b507ee4745afd5b11dda219b523c39c7e9a8881d856592d8908bf535fd63441",
		"role": "Fixed opcode trampoline used by the bank-$10 F3 operand table. The matching CB99 inline dispatcher is listed in this package's report.",
	},
	{
		"cpu": "$CB99-$CBAF",
		"path": "reference/rom_extract/gameplay/scenario_continuation/fixed_scenario_opcode_table_dispatch_CB99_CBAF.bin",
		"sha256": "1f8058f9fd70aeec319a32433feb0c102c72e0f5131571a0da8bf89ef84a2d54",
		"role": "Reads an inline selector table after the C509 callsite and transfers control to the selected F3 operation target.",
	},
	{
		"cpu": "$C50C-$C50E and $CD7C-$CD88",
		"path": "reference/rom_extract/gameplay/scenario36_fd00_mirror/fixed_record_pointer_vector_C50C_C50F.bin",
		"sha256": "71f4bb6ccdc5573bcfceef2422fe8636bc1dd1068675da3d860282d577e78b44",
		"role": "FD $00 handler uses vector $C50C to resolve holder $0441; the matching $CD7C resolver is listed in the adjacent manifest.",
	},
	{
		"cpu": "$CD7C-$CD88",
		"path": "reference/rom_extract/gameplay/scenario36_fd00_mirror/fixed_record_pointer_helper_CD7C_CD89.bin",
		"sha256": "8d7d8153252420175055aa5ef041e0e9dd85f99bb9dae8e24200e9549487ed24",
		"role": "Resolves the holder slot to its player-record pointer for FD $00.",
	},
	{
		"cpu": "$C536-$C538 and $CDC9-$CDE1",
		"path": "reference/rom_extract/gameplay/scenario36_fd00_mirror/fixed_value_div12_vector_C536_C539.bin",
		"sha256": "45c5f5dc3181044f55e152be9dd6ec1c7f9664fb4a87340dc5ac758ccc0bc775",
		"role": "FD $00 handler uses vector $C536 for a divide-by-12 helper; the matching $CDC9 helper is listed in the adjacent manifest.",
	},
	{
		"cpu": "$CDC9-$CDE1",
		"path": "reference/rom_extract/gameplay/scenario36_fd00_mirror/fixed_value_div12_helper_CDC9_CDE2.bin",
		"sha256": "45eb9e048e38d5655178886e5c61d4245720493c9044e2acc2f180f8c76eba7c",
		"role": "ROM helper reached by FD $00's $C536 vector.",
	},
	{
		"cpu": "$8097-$80A8",
		"path": "reference/rom_extract/gameplay/task_context/bank10_callback_task_setup_8097_80a8.bin",
		"sha256": "2d69d726177fe1eb737aab04622108e5860b03d4fd95a5182538c4bae7d982db",
		"role": "Existing scenario record consumer/task setup reference; its detailed callback target and worker remain a separate source-tracing step.",
	},
]


def sha256(data: bytes) -> str:
	return hashlib.sha256(data).hexdigest()


def bank_offset(bank: int, window: int, cpu: int) -> int:
	# The scenario reader maps the 16-KiB bank-$10 window at $8000-$BFFF;
	# field code spans use individual 8-KiB MMC3 windows.
	window_size = 0x4000 if bank == 0x10 and window == 0x8000 else PRG_BANK_SIZE
	if not window <= cpu < window + window_size:
		raise ValueError(f"CPU ${cpu:04X} is outside bank window ${window:04X}-${window + window_size - 1:04X}")
	return HEADER_BYTES + bank * PRG_BANK_SIZE + cpu - window


def pointer_entries(rom: bytes) -> list[tuple[int, int]]:
	rows: list[tuple[int, int]] = []
	for scenario_id in range(0x100):
		offset = SCENARIO_TABLE_OFFSET + scenario_id * 2
		pointer = int.from_bytes(rom[offset:offset + 2], "little")
		if 0x8000 <= pointer < 0xC000:
			rows.append((pointer, scenario_id))
	return rows


def build_manifest(rom: bytes) -> dict[str, object]:
	actual_sha = sha256(rom)
	if actual_sha != ROM_SHA256:
		raise SystemExit(f"Supplied ROM SHA-256 mismatch: {actual_sha}")
	if len(rom) != ROM_SIZE or rom[:4] != b"NES\x1a":
		raise SystemExit("Unexpected iNES header or ROM length")
	mapper = (rom[6] >> 4) | (rom[7] & 0xF0)
	if mapper != 4 or rom[4] != 16:
		raise SystemExit(f"Expected mapper 4 / 16 PRG 16-KiB units; got mapper={mapper}, PRG={rom[4]}")

	rows = pointer_entries(rom)
	root_offset = SCENARIO_TABLE_OFFSET + 0x1C * 2
	root_pointer = int.from_bytes(rom[root_offset:root_offset + 2], "little")
	if root_pointer != 0x9BE3:
		raise SystemExit(f"Scenario-$1C pointer changed: expected $9BE3, got ${root_pointer:04X}")
	greater = sorted((pointer, sid) for pointer, sid in rows if pointer > root_pointer)
	if not greater:
		raise SystemExit("Scenario-$1C has no greater valid pointer boundary")
	boundary_pointer, boundary_id = greater[0]
	if (boundary_pointer, boundary_id) != (0x9BF2, 0x24):
		raise SystemExit(f"Scenario-$1C boundary changed: expected ID $24->$9BF2, got ID ${boundary_id:02X}->${boundary_pointer:04X}")
	root_file = bank_offset(0x10, 0x8000, root_pointer)
	boundary_file = bank_offset(0x10, 0x8000, boundary_pointer)
	root_bytes = rom[root_file:boundary_file]
	if root_bytes != bytes.fromhex("FD 00 FA 3E 9F F3 84 02 04 F2 9E B4 F2 B6 B4"):
		raise SystemExit("Scenario-$1C pointer-bounded stream bytes differ from the pinned source")
	fa_child_offset = bank_offset(0x10, 0x8000, 0xBB4B)
	fa_child_bytes = rom[fa_child_offset:fa_child_offset + 5]
	if fa_child_bytes != bytes.fromhex("30 1F 4C 00 FB"):
		raise SystemExit("Scenario-$1C selected $BB4B nested child bytes differ from the pinned source")

	spans: list[dict[str, object]] = []
	for spec in SPAN_SPECS:
		bank = int(spec["bank"])
		window = int(spec["window_start"])
		start = int(spec["cpu_start"])
		length = int(spec["length_bytes"])
		offset = bank_offset(bank, window, start)
		payload = rom[offset:offset + length]
		if len(payload) != length:
			raise SystemExit(f"Truncated source span: {spec['name']}")
		filename = str(spec["file"])
		spans.append({
			**spec,
			"bank": f"0x{bank:02X}",
			"window_start": f"0x{window:04X}",
			"cpu_start": f"0x{start:04X}",
			"cpu_end_exclusive": f"0x{start + length:04X}",
			"file_offset": f"0x{offset:06X}",
			"length_bytes": length,
			"sha256": sha256(payload),
			"bytes_hex": payload.hex(" ").upper(),
		})
		if not ARGS.check:
			(OUT_DIR / filename).write_bytes(payload)
		else:
			path = OUT_DIR / filename
			if not path.is_file() or path.read_bytes() != payload:
				raise SystemExit(f"Extracted source span differs from ROM: {filename}")

	dependencies: list[dict[str, object]] = []
	for dependency in DEPENDENCIES:
		row: dict[str, object] = dict(dependency)
		path = ROOT / dependency["path"]
		if not path.is_file():
			raise SystemExit(f"Existing source dependency is missing: {dependency['path']}")
		payload = path.read_bytes()
		actual = sha256(payload)
		if dependency["sha256"] and actual != dependency["sha256"]:
			raise SystemExit(f"Existing source dependency hash changed: {dependency['path']}")
		row["exists"] = True
		row["actual_sha256"] = actual
		dependencies.append(row)

	manifest: dict[str, object] = {
		"schema": "ct2-pass-scenario-1c-source-v1",
		"source_rom": {
			"name": ROM_PATH.name,
			"sha256": actual_sha,
			"size_bytes": len(rom),
			"format": "iNES",
			"mapper": mapper,
			"mapper_name": "MMC3",
			"prg_16k_units": rom[4],
			"prg_8k_bank_count": rom[4] * 2,
		},
		"bank_mapping": {
			"prg_bank_size_bytes": PRG_BANK_SIZE,
			"header_bytes": HEADER_BYTES,
			"formula": "0x10 + (8-KiB PRG bank * 0x2000) + (CPU address - CPU window start)",
			"bank_10_scenario_window": "$8000-$BFFF",
			"bank_1A_vector_window": "$8000-$9FFF; mapped by the $DE76 caller through $CE2D",
			"bank_1E_fixed_window": "$C000-$DFFF",
		},
		"scenario_1C": {
			"pointer_table_cpu_address": f"0x{SCENARIO_TABLE_CPU:04X}",
			"pointer_table_file_offset": f"0x{SCENARIO_TABLE_OFFSET:06X}",
			"pointer_entry_id": "$1C",
			"pointer_entry_cpu_address": "0x89F7",
			"pointer_entry_file_offset": f"0x{root_offset:06X}",
			"pointer_entry_bytes": rom[root_offset:root_offset + 2].hex(" ").upper(),
			"stream_cpu_address": f"0x{root_pointer:04X}",
			"stream_file_offset": f"0x{root_file:06X}",
			"boundary_rule": "Smallest greater pointer among all valid entries in the 256-entry table; stream end exclusive.",
			"boundary_pointer_entry_id": f"${boundary_id:02X}",
			"boundary_cpu_address_exclusive": f"0x{boundary_pointer:04X}",
			"boundary_pointer_entry_file_offset": f"0x{SCENARIO_TABLE_OFFSET + boundary_id * 2:06X}",
			"length_bytes": len(root_bytes),
			"bytes_hex": root_bytes.hex(" ").upper(),
			"sha256": sha256(root_bytes),
			"decoded_from_handler_bytes": [
				"$FD $00 dispatches through bank-$10 $886A to $8877; the result depends on holder/record/$0638 state.",
				"$FA $3E $9F enters nested bank-$10 target $9F3E through existing handler $881A and loader $80F6.",
				"$F3 $84 dispatches selector $04 to $8259, which returns X=0 when $044E is 0/1 and X=1 when $044E is 2. Because $84 takes the high-bit handler path, X selects the inline skip byte: $02 resumes at $9BEC ($F2 $9E $B4), while $04 resumes at $9BEF ($F2 $B6 $B4).",
				"The preceding $C624->$DCDF call initializes a zero $044E to 1+($00E2&1); a pre-existing nonzero value is preserved. Therefore the $B49E/$B4B6 branch is established for fresh zero-initialized $044E, while other incoming values remain context-dependent.",
				"Each $F2 consumes its following little-endian pointer and replaces the active source address through handler $80F4. The selected B49E/B4B6 streams each contain one F9, one four-byte record, and FB.",
			],
		},
		"nested_fa_dispatch": {
			"target_cpu_address": "0x9F3E",
			"dispatch_wrapper_cpu_span": "$9F3E-$9F53 (end exclusive $9F54)",
			"f3_10": {
				"handler_target": "$836E",
				"helper_source_span": "bank10_F3_selector10_helper_836E_837C.bin",
				"helper_sha256": sha256(rom[bank_offset(0x10, 0x8000, 0x836E):bank_offset(0x10, 0x8000, 0x836E) + 14]),
				"helper_behavior": "Starts with X=0; if $043B==$01 it returns X=0; otherwise it calls $8677, increments X, and returns, so other selectors require that helper's result.",
				"inline_pointer_table": ["$9F4A", "$BB4B", "$BB4B", "$BB4B", "$BB4B"],
				"table_cpu_span": "$9F40-$9F49",
			},
			"f3_1e_if_selected_at_9F4A": {
				"handler_target": "$8401",
				"return_value": "X=$043C&$7F; nonzero also sets bit $04 in $0516 via $8211",
				"inline_pointer_table": ["$BB4B", "$B502", "$B54F", "$BB50"],
				"table_cpu_span": "$9F4C-$9F53",
			},
			"selected_branch_BB4B": {
				"selection_condition": "$043B==$01 selects index 0 -> $9F4A, then $043C&$7F==0 selects index 0 -> $BB4B; the outer table's indexes 1-4 also target $BB4B.",
				"bytes_hex": fa_child_bytes.hex(" ").upper(),
				"sha256": sha256(fa_child_bytes),
				"return": "$BB4F $FB restores the saved FA caller stream at $9BE8 when this child is entered from root $9F3E.",
			},
			"interpretation_limit": "The $BB4B child is exact and bounded here. The other selected targets $B502/$B54F/$BB50 and their return behavior are not followed in this package.",
		},
		"handoff": {
			"caller_source": "Existing extracted $DE6C-$DE96 bytes show $DE76->$E6EC, bank mapping helper $CE2D, then $801E->$8B4A; at $DE8D the caller loads $1C and calls $CBB0.",
			"reader_source": "Existing $EC08 scenario start maps bank $10 and calls $8000; reader entry $8000 resolves $0518 through pointer table $89BF.",
			"route_observation_limit": "This package is a static source extraction; it does not claim FCEUX/Godot runtime execution or resolve the complete scenario worker/output path.",
		},
		"spans": spans,
		"existing_dependencies": dependencies,
		"unresolved": [
			"The nested $FA target $9F3E selector chain and the $BB4B child are source-decoded; this static package does not retain a same-input FCEUX RAM checkpoint at the $043B/$043C branch, and other targets $B502/$B54F/$BB50 remain unresolved.",
		"The root $F3 $84 skip calculation is byte-decoded; its normal two branches assume $044E is 1 or 2, which follows when $C624 sees zero but not when $044E was already nonzero.",
			"The full post-$8B4A branch path through $8298/$8978 and any resulting player/field presentation is outside this package.",
			"No scenario-$1C same-input visual, timing, or audio parity is established by these bytes.",
		],
		"runtime_rom_dependency": False,
	}
	manifest_path = OUT_DIR / "manifest.json"
	if ARGS.check:
		if not manifest_path.is_file() or json.loads(manifest_path.read_text()) != manifest:
			raise SystemExit("Generated manifest differs from the recorded source manifest")
	else:
		manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
	return manifest


def main() -> int:
	global ARGS
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--check", action="store_true", help="verify extracted bytes and manifest without rewriting")
	ARGS = parser.parse_args()
	if not ROM_PATH.is_file():
		raise SystemExit(f"Supplied ROM not found: {ROM_PATH.name}")
	if not ARGS.check:
		OUT_DIR.mkdir(parents=True, exist_ok=True)
	manifest = build_manifest(ROM_PATH.read_bytes())
	for span in manifest["spans"]:
		print(f"{span['name']}: {span['cpu_start']}+{span['length_bytes']} bytes; {span['file_offset']}; sha256={span['sha256']}")
	print(f"scenario $1C: $9BE3-$9BF1, 15 bytes, sha256={manifest['scenario_1C']['sha256']}")
	print(f"verified existing source dependencies: {len(manifest['existing_dependencies'])}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
