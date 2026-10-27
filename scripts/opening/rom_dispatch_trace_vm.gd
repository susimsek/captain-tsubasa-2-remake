extends RefCounted
class_name RomDispatchTraceVm
## Research-only stepper over verified FCEUX interpreter observations.
## It does not simulate NES frames, handler side effects, or presentation.

signal dispatch_observed(event: Dictionary, state_snapshot: Dictionary)
signal trace_finished(state_snapshot: Dictionary)

const DATA_PATH := "res://reference/rom_extract/intro/cold_start_observed_dispatch.json"

var events: Array[Dictionary] = []
var state: Dictionary = {}
var _index := 0
var _started := false


static func from_project_data() -> RomDispatchTraceVm:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not open observed ROM dispatch trace: %s" % DATA_PATH)
		return null
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		push_error("Observed ROM dispatch trace must be a JSON object.")
		return null
	return from_dictionary(parsed)


static func from_dictionary(data: Dictionary) -> RomDispatchTraceVm:
	if int(data.get("schema", 0)) != 1 or str(data.get("status", "")).find("verified live dispatcher trace") < 0:
		push_error("Refusing dispatch data without verified live-trace provenance.")
		return null
	var raw_events: Variant = data.get("events", [])
	if not (raw_events is Array) or raw_events.is_empty():
		push_error("Observed ROM dispatch trace has no events.")
		return null
	var vm = load("res://scripts/opening/rom_dispatch_trace_vm.gd").new()
	for raw_event: Variant in raw_events:
		if not (raw_event is Dictionary):
			push_error("Every observed ROM dispatch row must be an object.")
			return null
		vm.events.append(raw_event.duplicate(true))
	return vm


func begin() -> Dictionary:
	_index = 0
	_started = true
	state = {
		"observed_dispatches": 0,
		"source_frame": -1,
		"script_pointer": "",
		"last_class": "",
		"last_text_tile_id": -1,
		"last_wait_frames_from_rom_table": -1,
		"last_cursor_back_tiles": -1,
		"last_vector_handler_pc": "",
		"last_operand_bytes": [],
		"last_verified_ram_effects": [],
		"last_verified_ppu_effects": [],
		"text_speed_ram_55": -1,
		"sound_queue_requests": [],
		"background_mode_bit_04": -1,
		"palette_branch_operand": -1,
		"cutscene_pointer_target": "",
		"semantic_effect_status": "not_started",
		"unsupported_reason": "",
		"loop_count": 0,
		"title_handoff_observed": false,
	}
	return state.duplicate(true)


## Advances exactly one captured dispatch row. This is trace inspection, not a
## frame/tick scheduler: source_frame deltas include the NES main loop.
func advance_one_observed_dispatch() -> Dictionary:
	if not _started:
		push_error("Call begin() before stepping the observed trace.")
		return state.duplicate(true)
	if _index >= events.size():
		return state.duplicate(true)

	var event: Dictionary = events[_index]
	_index += 1
	var opcode := int(str(event.get("byte", "$00")).trim_prefix("$").hex_to_int())
	var event_class := str(event.get("class", "unknown"))
	var unsupported_reason := ""
	var effect_status := "observed_only"
	state["observed_dispatches"] = int(state["observed_dispatches"]) + 1
	state["source_frame"] = int(event.get("source_frame", -1))
	state["script_pointer"] = str(event.get("script_cpu", ""))
	state["last_class"] = event_class
	state["last_vector_handler_pc"] = str(event.get("handler_entry_pc", ""))
	var operands: Array = event.get("operand_bytes_array", [])
	state["last_operand_bytes"] = operands.duplicate()
	state["last_verified_ram_effects"] = []
	state["last_verified_ppu_effects"] = []
	state["last_text_tile_id"] = -1
	state["last_wait_frames_from_rom_table"] = -1
	state["last_cursor_back_tiles"] = -1

	match event_class:
		"text_byte":
			state["last_text_tile_id"] = int(event.get("text_tile_id", opcode))
			effect_status = "tile_id_verified; glyph drawing and raster visibility unsupported"
		"compact_pause":
			state["last_wait_frames_from_rom_table"] = int(event.get("wait_frames_from_rom_table", -1))
			effect_status = "ROM wait-table value verified; physical frame scheduling unsupported"
			unsupported_reason = "Dispatch frame deltas include main-loop waits and do not isolate this opcode's frame cost."
		"cursor_back":
			state["last_cursor_back_tiles"] = int(event.get("cursor_back_tiles", opcode - 0xE0))
			effect_status = "inline cursor-back amount verified; text-window side effects unsupported"
			unsupported_reason = "The cursor amount is known, but the complete RAM/PPU state mutation is not represented."
		"vector_command":
			var operand := int(str(operands[0]).trim_prefix("$").hex_to_int()) if not operands.is_empty() else -1
			match opcode:
				0xE8:
					effect_status = "handler reads one operand and calls $8920; source target and +2 continuation verified"
					unsupported_reason = "$8920 preset/CHR effects are not fully traced to a state transition."
				0xE9:
					effect_status = "zero-operand screen-enable handler path and +1 continuation verified"
					unsupported_reason = "Called $9FA8/$997E effects and the exact PPU mask/raster edge are unresolved."
				0xEA:
					state["last_verified_ram_effects"] = ["$4C <- $00", "$7B <- $00", "$0D <- $00", "$0E <- $00"]
					state["last_verified_ppu_effects"] = ["zero-fill 16 rows x 32 bytes at $2000", "zero-fill 16 rows x 32 bytes at $2400", "$98E8 clears PPUCTRL increment bit to use +1 per PPUDATA write"]
					effect_status = "zero-operand nametable clear path; both 16x32 fills and direct PPU register behavior are source-verified"
					unsupported_reason = "The exact visible frame and raster commit point are not represented."
				0xEC:
					if operand == 0xFF:
						state["last_verified_ram_effects"] = ["$0652 <- $00"]
						effect_status = "$FF operand branch writes $0652=$00; +2 continuation verified"
					else:
						state["last_verified_ram_effects"] = ["$0654:$0655 <- word from $BD00 + operand*2", "$0652 <- $80", "$0653 <- $01", "$90 <- $00", "$91 <- $02"]
						effect_status = "non-$FF operand selects $BD00 pointer and initializes $0652-$0655/$90-$91"
						unsupported_reason = "The downstream consumer of the selected pointer is not modeled."
				0xED:
					var requests: Array = state["sound_queue_requests"]
					requests.append({"sound_id": operand, "queue_ram": "$0700-$0704"})
					state["sound_queue_requests"] = requests
					effect_status = "one-byte sound ID queued in first empty slot of $0700-$0704; no direct APU write"
					unsupported_reason = "Queue slot choice and later audio-driver execution are outside this handler-state stepper."
				0xEE:
					state["last_verified_ppu_effects"] = ["zero-fill 11 rows x 30 bytes from PPU address $2221", "$98E8 uses +1 PPUDATA increment and adds $20 per row"]
					effect_status = "zero-operand PPU fill dimensions and address are source-verified"
					unsupported_reason = "The fill's purpose and exact visible frame are not established."
				0xF1:
					state["last_verified_ppu_effects"] = ["zero-fill 11 rows x 30 bytes from PPU address $2221", "$98E8 uses +1 PPUDATA increment and adds $20 per row"]
					effect_status = "one-operand window path fills PPU region at $2221 and indexes $BB40/$BB41"
					unsupported_reason = "The indexed window resource and $97B6 drawing effects are not fully decoded."
				0xF2:
					state["text_speed_ram_55"] = operand
					state["last_verified_ram_effects"] = ["$55 <- $%02X" % operand]
					effect_status = "one operand stored directly to RAM $55; +2 continuation verified"
				0xF3:
					state["palette_branch_operand"] = operand
					if operand == 0:
						state["last_verified_ram_effects"] = ["$4A <- $0F", "$4B <- $0F", "palette staging/queue path via $9A71"]
						effect_status = "operand $00 resets palette selectors and stages palette data through $062A/$05E8"
						unsupported_reason = "The NMI consumer and final palette PPU commit are not modeled."
					else:
						effect_status = "F3 operand branch observed; length and dispatch continuation recorded"
						unsupported_reason = "Nonzero F3 selection subroutine effects are not modeled by this trace stepper."
				0xF4:
					state["palette_branch_operand"] = operand
					if operand == 4 or operand == 5:
						effect_status = "operand selects verified palette handler branch and stages colors through $9A71"
						unsupported_reason = "Palette table values and their visible PPU commit frame are not modeled."
					else:
						effect_status = "F4 handler entry observed"
						unsupported_reason = "This operand's computed-jump branch has not been analyzed."
				0xF5:
					var value := 0 if operand == 0xFF else operand | 0x80
					state["last_verified_ram_effects"] = ["$4C <- $%02X" % value]
					effect_status = "operand transform stored to RAM $4C; +2 continuation verified"
					unsupported_reason = "The downstream interpretation of $4C is not modeled."
				0xF8:
					state["last_verified_ram_effects"] = ["$ED <- operand byte", "$EC <- unconsumed lookahead byte"]
					effect_status = "one operand consumed; handler also reads next byte as lookahead and +2 continuation is observed"
					unsupported_reason = "$A212 result and F8 state effect are not fully understood."
				0xF9, 0xFA:
					state["background_mode_bit_04"] = opcode == 0xFA
					state["last_verified_ram_effects"] = ["$5B bit $04 cleared" if opcode == 0xF9 else "$5B bit $04 set"]
					effect_status = "one operand passed to $8AF7; $5B mode-bit change is byte-verified"
					unsupported_reason = "Background resource selection and its PPU effects through $8AF7 are not fully modeled."
				0xFB:
					state["last_verified_ram_effects"] = ["clear $0468-$0566", "counted ID data processed by $9085 into working buffers"]
					effect_status = "counted ID list length and $9085 buffer initialization verified"
					unsupported_reason = "Full ID-to-descriptor expansion and animation timing are not modeled."
				0xFC:
					state["last_verified_ram_effects"] = ["$99 <- ($99 & $80) | $40", "$51:$52 += $0040", "script pointer += 1"]
					effect_status = "one-byte FC path; $99 flag transform, $51:$52 increment and next-byte continuation verified"
					unsupported_reason = "$9FA8 side effects and full visual meaning are unresolved; following bytes are not FC payload."
				0xFD:
					state["last_verified_ppu_effects"] = ["zero-fill through $98E8; address derived from RAM $4F/$50/$54; row count $08; width derived from $54"]
					effect_status = "zero-operand path derives PPU fill address and dimensions from RAM, then calls $98E8"
					unsupported_reason = "The captured runtime values and resulting visible screen operation are not modeled."
				0xFE:
					var next_pointer := str(event.get("next_dispatch_cpu", ""))
					if operands.size() >= 2:
						state["cutscene_pointer_target"] = "$%02X%02X" % [int(str(operands[1]).trim_prefix("$").hex_to_int()), operand]
					if next_pointer == "$A020" and state["cutscene_pointer_target"] == "$A020":
						state["loop_count"] = int(state["loop_count"]) + 1
						effect_status = "unconditional script jump to $A020 verified from handler bytes and live continuation"
					else:
						effect_status = "FE handler entry observed"
						unsupported_reason = "This FE row does not show the verified $A020 loop target."
				_:
					unsupported_reason = "Vector handler entry and continuation are observed; no complete handler effect is modeled."
		_:
			unsupported_reason = "Unknown dispatch class; no command effect is inferred."

	var handoff_now := str(event.get("next_dispatch_cpu", "")) == "$00E8"
	if handoff_now:
		state["title_handoff_observed"] = true

	state["semantic_effect_status"] = effect_status
	state["unsupported_reason"] = unsupported_reason
	var observed_event := event.duplicate(true)
	observed_event["title_handoff_observed_now"] = handoff_now
	observed_event["vm_effect_status"] = effect_status
	observed_event["unsupported_reason"] = unsupported_reason
	dispatch_observed.emit(observed_event, state.duplicate(true))
	if _index >= events.size():
		trace_finished.emit(state.duplicate(true))
	return state.duplicate(true)


func has_more_observed_dispatches() -> bool:
	return _started and _index < events.size()


func current_observed_index() -> int:
	return _index
