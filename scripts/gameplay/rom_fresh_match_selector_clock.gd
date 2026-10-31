extends RefCounted
class_name RomFreshMatchSelectorClock
## Validates a compact ROM-only candidate clock for the `$A20F` selector call.
## This is a cycle-budget/event-time source, not a CPU, IRQ handler, or PPU model.

const ASSET_PATH := "res://assets/gameplay/rom_logic/fresh_match_selector_runtime_clock.json"
const SCHEMA := "ct2-fresh-match-selector-runtime-clock-v1"
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const INPUT_SHA256 := "6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc"
const MODEL_SHA256 := "b0f528dfd73f79cf7148a5a2f6a9f0683cde22a03c1705deb8e5215864d888db"
const EXPECTED_ENTRY_PC := "$A20F"
const EXPECTED_RETURN_INSTRUCTION_PC := "$A8B6"
const EXPECTED_CALLER_RETURN := "$80FC"
const FIRST_SOURCE_FRAME_PROVENANCE := 7258
const LAST_SOURCE_FRAME_PROVENANCE := 7266
const EXPECTED_ELAPSED_CYCLES := 223242
const EXPECTED_INTERRUPT_CYCLES := 19909
const EXPECTED_MAINLINE_CYCLES := 203333
const I_FLAG_MASK := 0x04
const CANDIDATE_ENTRY_P := 0x30

var error_message := ""
var _configured := false
var _status: Dictionary = {}
var _segments_by_offset: Dictionary = {}
var _interrupt_events: Array[Dictionary] = []
var _entry_status_contract: Dictionary = {}


## Loads only the project-owned JSON asset. ROM and emulator files are not read.
func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_status.clear()
	_segments_by_offset.clear()
	_interrupt_events.clear()
	_entry_status_contract.clear()
	if not FileAccess.file_exists(ASSET_PATH):
		return _fail("Fresh selector runtime clock asset is missing.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ASSET_PATH))
	if not parsed is Dictionary:
		return _fail("Fresh selector runtime clock asset is malformed JSON.")
	return _configure_document(parsed)


## Returns one zero-based selector frame segment. `mainline_cycle_end` is
## cumulative from `$A20F` and excludes every overlapping NMI/IRQ span.
func get_frame_segment(frame_offset: int) -> Dictionary:
	if not _configured:
		if not configure_from_project_sources():
			return {"ok": false, "error": error_message}
	if not _segments_by_offset.has(frame_offset):
		return {
			"ok": false,
			"error": "Frame offset is outside the selector call (expected 0..8).",
		}
	var segment: Dictionary = _segments_by_offset[frame_offset]
	var result: Dictionary = segment.duplicate(true)
	result["ok"] = true
	return result


## Returns ordered interrupt acceptance/return cycle offsets separately from
## the mainline budgets. No handler writes or return receipts are synthesized.
func get_interrupt_events() -> Array[Dictionary]:
	if not _configured and not configure_from_project_sources():
		return []
	return _interrupt_events.duplicate(true)


## Returns only the ROM-model-derived I-bit fact. This is not a full P byte or
## proof of physical hardware timing.
func get_candidate_entry_status_evidence() -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return {"ok": false, "error": error_message}
	return _entry_status_contract.duplicate(true)


func get_status() -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return {"ok": false, "error": error_message}
	return _status.duplicate(true)


func _configure_document(document: Variant) -> bool:
	error_message = ""
	_configured = false
	_status.clear()
	_segments_by_offset.clear()
	_interrupt_events.clear()
	_entry_status_contract.clear()
	if not document is Dictionary:
		return _fail("Runtime clock document must be a JSON object.")
	var source: Dictionary = document
	if String(source.get("schema", "")) != SCHEMA:
		return _fail("Runtime clock schema is unsupported.")
	if String(source.get("source_rom_sha256", "")) != ROM_SHA256:
		return _fail("Runtime clock targets a different ROM revision.")
	if String(source.get("input_route_sha256", "")) != INPUT_SHA256 \
			or String(source.get("source_model_sha256", "")) != MODEL_SHA256:
		return _fail("Runtime clock provenance does not match the reviewed input/model.")
	var limits: Variant = source.get("source_limits", {})
	if not limits is Dictionary \
			or bool(limits.get("fceux_trace_used_as_input", true)) \
			or bool(limits.get("complete_ppu_fetch_parity", true)) \
			or bool(limits.get("physical_nes_timing_proven", true)) \
			or bool(limits.get("handler_writes_applied", true)) \
			or bool(limits.get("return_receipts_applied", true)) \
			or bool(limits.get("runtime_rom_dependency", true)) \
			or bool(limits.get("runtime_emulator_dependency", true)):
		return _fail("Runtime clock source-limit flags must remain explicitly bounded.")
	if not _validate_call_contract(source.get("call_contract", {})):
		return false
	if not _validate_entry_status_contract(source.get("entry_status_contract", {})):
		return false
	var totals: Variant = source.get("cycle_totals", {})
	if not totals is Dictionary \
			or int(totals.get("elapsed", -1)) != EXPECTED_ELAPSED_CYCLES \
			or int(totals.get("interrupt", -1)) != EXPECTED_INTERRUPT_CYCLES \
			or int(totals.get("mainline", -1)) != EXPECTED_MAINLINE_CYCLES:
		return _fail("Runtime clock totals differ from the reviewed cycle budget.")
	var intervals: Variant = source.get("frame_intervals", [])
	var events: Variant = source.get("interrupt_events", [])
	if not intervals is Array or intervals.size() != 9:
		return _fail("Runtime clock must contain frame offsets 0 through 8.")
	if not events is Array:
		return _fail("Runtime clock interrupt event list is malformed.")
	if not _derive_segments(intervals, events):
		return false
	_configured = true
	_status = {
		"ok": true,
		"schema": SCHEMA,
		"source_rom_sha256": ROM_SHA256,
		"input_route_sha256": INPUT_SHA256,
		"entry_pc": EXPECTED_ENTRY_PC,
		"entry_prg_bank_8k": 2,
		"entry_source_frame_provenance": FIRST_SOURCE_FRAME_PROVENANCE,
		"return_instruction_pc": EXPECTED_RETURN_INSTRUCTION_PC,
		"return_source_frame_provenance": LAST_SOURCE_FRAME_PROVENANCE,
		"frame_offset_min": 0,
		"frame_offset_max": 8,
		"elapsed_cycles": EXPECTED_ELAPSED_CYCLES,
		"interrupt_cycles": EXPECTED_INTERRUPT_CYCLES,
		"mainline_cycles": EXPECTED_MAINLINE_CYCLES,
		"interrupt_event_count": _interrupt_events.size(),
		"candidate_entry_i_flag_known": true,
		"candidate_entry_i_flag_clear": true,
		"candidate_entry_i_flag_basis": "ROM-only hash-bound source CPU candidate; not live route status propagation",
		"candidate_status_is_runtime_input": false,
		"runtime_rom_dependency": false,
		"runtime_emulator_dependency": false,
		"handler_writes_applied": false,
		"return_receipts_applied": false,
		"complete_ppu_fetch_parity": false,
		"physical_nes_timing_proven": false,
		"asset_path": ASSET_PATH,
	}
	return true


func _validate_call_contract(contract_variant: Variant) -> bool:
	if not contract_variant is Dictionary:
		return _fail("Runtime clock call contract is malformed.")
	var contract: Dictionary = contract_variant
	if String(contract.get("entry_pc", "")) != EXPECTED_ENTRY_PC \
			or int(contract.get("entry_prg_bank_8k", -1)) != 2 \
			or int(contract.get("entry_source_frame_provenance", -1)) != FIRST_SOURCE_FRAME_PROVENANCE \
			or int(contract.get("entry_source_cycle_provenance", -1)) != 216143875 \
			or String(contract.get("caller_return_word", "")) != EXPECTED_CALLER_RETURN:
		return _fail("Runtime clock `$A20F` entry boundary differs from the reviewed call.")
	if String(contract.get("return_instruction_pc", "")) != EXPECTED_RETURN_INSTRUCTION_PC \
			or int(contract.get("return_prg_bank_8k", -1)) != 2 \
			or int(contract.get("return_source_frame_provenance", -1)) != LAST_SOURCE_FRAME_PROVENANCE \
			or int(contract.get("return_source_cycle_provenance", -1)) != 216367117 \
			or String(contract.get("return_pc", "")) != "$80FD" \
			or String(contract.get("consumed_caller_return_word", "")) != EXPECTED_CALLER_RETURN:
		return _fail("Runtime clock `$A8B6` return boundary differs from the reviewed call.")
	return true


func _validate_entry_status_contract(contract_variant: Variant) -> bool:
	if not contract_variant is Dictionary:
		return _fail("Runtime clock I-flag contract is malformed.")
	var contract: Dictionary = contract_variant
	if String(contract.get("flag", "")) != "I" \
			or int(contract.get("known_mask", -1)) != I_FLAG_MASK \
			or int(contract.get("known_value", -1)) != 0 \
			or int(contract.get("candidate_p_byte", -1)) != CANDIDATE_ENTRY_P \
			or String(contract.get("source_model_sha256", "")) != MODEL_SHA256 \
			or String(contract.get("input_route_sha256", "")) != INPUT_SHA256 \
			or bool(contract.get("physical_nes_timing_proven", true)):
		return _fail("Runtime clock must prove only ROM-model I=clear for the reviewed canonical route.")
	_entry_status_contract = {
		"ok": true,
		"flag": "I",
		"p_known_mask": I_FLAG_MASK,
		"p_known_value": 0,
		"candidate_p_byte": CANDIDATE_ENTRY_P,
		"source_model_sha256": MODEL_SHA256,
		"input_route_sha256": INPUT_SHA256,
		"physical_nes_timing_proven": false,
		"runtime_rom_dependency": false,
		"runtime_emulator_dependency": false,
	}
	return true


func _derive_segments(intervals: Array, events: Array) -> bool:
	var parsed_intervals: Array[Dictionary] = []
	var previous_end := 0
	for offset in range(intervals.size()):
		var interval_variant: Variant = intervals[offset]
		if not interval_variant is Dictionary:
			return _fail("Runtime clock frame interval %d is malformed." % offset)
		var interval: Dictionary = interval_variant
		var frame_offset := int(interval.get("frame_offset", -1))
		var start := int(interval.get("elapsed_cycle_start", -1))
		var end := int(interval.get("elapsed_cycle_end", -1))
		if frame_offset != offset or int(interval.get("source_frame", -1)) != FIRST_SOURCE_FRAME_PROVENANCE + offset:
			return _fail("Runtime clock frame offsets/provenance are not contiguous.")
		if start != previous_end or end <= start:
			return _fail("Runtime clock frame cycle intervals contain a gap, overlap, or empty span.")
		parsed_intervals.append({
			"frame_offset": frame_offset,
			"source_frame_provenance": int(interval["source_frame"]),
			"elapsed_cycle_start": start,
			"elapsed_cycle_end": end,
		})
		previous_end = end
	if parsed_intervals[0]["elapsed_cycle_start"] != 0 \
			or parsed_intervals[-1]["elapsed_cycle_end"] != EXPECTED_ELAPSED_CYCLES:
		return _fail("Runtime clock frame intervals do not span the complete selector call.")

	var parsed_events: Array[Dictionary] = []
	var prior_accept := -1
	var prior_return := -1
	var interrupt_total := 0
	var nmi_count := 0
	var irq_count := 0
	for event_variant in events:
		if not event_variant is Dictionary:
			return _fail("Runtime clock contains a malformed interrupt event.")
		var event: Dictionary = event_variant
		var kind := String(event.get("kind", ""))
		var frame_offset := int(event.get("frame_offset", -1))
		var accept := int(event.get("elapsed_cycle", -1))
		var returned := int(event.get("return_cycle", -1))
		if kind != "NMI" and kind != "IRQ":
			return _fail("Runtime clock contains an unsupported interrupt kind.")
		if frame_offset < 0 or frame_offset >= parsed_intervals.size() \
				or accept < 0 or returned <= accept or accept <= prior_accept or accept < prior_return:
			return _fail("Runtime interrupt events are not ordered, bounded, and non-overlapping.")
		var interval: Dictionary = parsed_intervals[frame_offset]
		if accept < int(interval["elapsed_cycle_start"]) \
				or accept >= int(interval["elapsed_cycle_end"]) \
				or int(event.get("frame_offset", -1)) != frame_offset:
			return _fail("Runtime interrupt acceptance does not belong to its frame offset.")
		var expected_vector := "$C500" if kind == "NMI" else "$C506"
		if String(event.get("vector_pc", "")) != expected_vector \
				or String(event.get("pc_before", "")) != String(event.get("return_pc", "")):
			return _fail("Runtime interrupt vector/return contract is malformed.")
		parsed_events.append({
			"kind": kind,
			"frame_offset": frame_offset,
			"elapsed_cycle": accept,
			"return_cycle": returned,
			"pc_before": String(event["pc_before"]),
			"vector_pc": expected_vector,
			"return_pc": String(event["return_pc"]),
		})
		interrupt_total += returned - accept
		if kind == "NMI":
			nmi_count += 1
		else:
			irq_count += 1
		prior_accept = accept
		prior_return = returned
	if nmi_count != 8 or irq_count != 7 or interrupt_total != EXPECTED_INTERRUPT_CYCLES:
		return _fail("Runtime interrupt event counts or total duration are incorrect.")

	var cumulative_mainline := 0
	for interval in parsed_intervals:
		var start := int(interval["elapsed_cycle_start"])
		var end := int(interval["elapsed_cycle_end"])
		var overlapped_interrupt_cycles := 0
		var segment_events: Array[Dictionary] = []
		for event in parsed_events:
			var event_start := int(event["elapsed_cycle"])
			var event_end := int(event["return_cycle"])
			var overlap_start := maxi(start, event_start)
			var overlap_end := mini(end, event_end)
			if overlap_end > overlap_start:
				overlapped_interrupt_cycles += overlap_end - overlap_start
			if int(event["frame_offset"]) == int(interval["frame_offset"]):
				var event_copy: Dictionary = event.duplicate(true)
				var prior_interrupt_cycles := 0
				for previous_event in parsed_events:
					if int(previous_event["return_cycle"]) <= event_start:
						prior_interrupt_cycles += int(previous_event["return_cycle"]) - int(previous_event["elapsed_cycle"])
				event_copy["mainline_cycle_at_accept"] = event_start - prior_interrupt_cycles
				event_copy["mainline_cycle_at_return"] = event_end - prior_interrupt_cycles \
						- (event_end - event_start)
				segment_events.append(event_copy)
		var budget := (end - start) - overlapped_interrupt_cycles
		if budget < 0:
			return _fail("Interrupt spans exceed their frame's selector interval.")
		var segment := {
			"frame_offset": int(interval["frame_offset"]),
			"source_frame_provenance": int(interval["source_frame_provenance"]),
			"elapsed_cycle_start": start,
			"elapsed_cycle_end": end,
			"mainline_cycle_start": cumulative_mainline,
			"mainline_cycle_budget": budget,
			"mainline_cycle_end": cumulative_mainline + budget,
			"interrupt_overlap_cycles": overlapped_interrupt_cycles,
			"interrupt_events": segment_events,
		}
		_segments_by_offset[int(interval["frame_offset"])] = segment
		cumulative_mainline += budget
	if cumulative_mainline != EXPECTED_MAINLINE_CYCLES:
		return _fail("Frame-derived mainline budget is not exactly 203,333 cycles.")
	for event in parsed_events:
		var previous_interrupt_cycles := 0
		for prior_event in parsed_events:
			if int(prior_event["return_cycle"]) <= int(event["elapsed_cycle"]):
				previous_interrupt_cycles += int(prior_event["return_cycle"]) - int(prior_event["elapsed_cycle"])
		var event_copy: Dictionary = event.duplicate(true)
		var mainline_at_accept := int(event["elapsed_cycle"]) - previous_interrupt_cycles
		event_copy["mainline_cycle_at_accept"] = mainline_at_accept
		event_copy["mainline_cycle_at_return"] = mainline_at_accept
		_interrupt_events.append(event_copy)
	if parsed_intervals[-1]["elapsed_cycle_end"] - parsed_intervals[0]["elapsed_cycle_start"] \
			!= EXPECTED_ELAPSED_CYCLES:
		return _fail("Elapsed selector interval total changed.")
	return true


func _fail(message: String) -> bool:
	error_message = message
	_configured = false
	return false
