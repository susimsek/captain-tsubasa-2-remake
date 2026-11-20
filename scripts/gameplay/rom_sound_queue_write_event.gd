extends RefCounted
class_name RomSoundQueueWriteEvent
## Typed provenance for a ROM sound-queue write requested by a decoded source
## event. A route VM tick is not an NES CPU timestamp; unresolved cycle and
## absolute-ROM-frame values stay explicitly unknown.

const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const CUTSCENE_SOUND_HANDLER_PC := 0x85EC
const CUTSCENE_SOUND_QUEUE_STORE_PC := 0x85FC
const CUTSCENE_SOUND_POST_STORE_PC := 0x85FF
const CBF1_QUEUE_STORE_PC := 0xCBFE
const CBF1_QUEUE_POST_STORE_PC := 0xCC01
const CBF1_QUEUE_START := 0x0700
const CBF1_QUEUE_SIZE := 5
const STOP_QUEUE_ID := 0x01
const CBF1_HELPER_SOURCE_SHA256 := "fc6689183aa19a053b44b44571a373ebb48b3bf940f299fb10623c61da4791ce"
const CBF1_SOURCE_MANIFEST_SHA256 := "01b60a8cf91bfde2c6ff02098f50fe4851aca50aea5d43fffb792516dc53e0ea"
const CBF1_DEPENDENCY_MANIFEST_SHA256 := "28ce64890bfd3b4f0d6c3ab60d9b189c15adcb3a732881f93e2ff2927f399c2f"
const FRESH_DAAA_SOURCE_MANIFEST_SHA256 := "01b60a8cf91bfde2c6ff02098f50fe4851aca50aea5d43fffb792516dc53e0ea"
const FRESH_DAAA_QUEUE_SOURCE_SHA256 := "fc6689183aa19a053b44b44571a373ebb48b3bf940f299fb10623c61da4791ce"

var event_identity := ""
var event_origin := ""
var source_rom_sha256 := SOURCE_ROM_SHA256
var queue_id := -1
var cutscene_id := -1
var script_event_index := -1
var script_offset := -1
var script_cpu_address := -1
var script_raw_bytes := PackedByteArray()
var handler_entry_pc := -1
var queue_store_instruction_pc := -1
var post_store_pc := -1
var queue_slot := -1
var queue_address := -1
var source_caller_pc := -1
var source_frame := -1
var source_frame_domain := ""
var source_helper_span_sha256 := ""
var source_manifest_sha256 := ""
var dependency_manifest_sha256 := ""
var root_input_ram_052e := -1
var root_input_ram_052f := -1
var root_output_ram_052e := -1
var root_source_ram_0530 := -1
var root_source_ram_0531 := -1
var root_source_ram_063f := -1
var root_scenario_id := -1
var route_frame := -1
var route_frame_domain := ""
var absolute_rom_frame := -1
var cpu_cycle := -1
var timing_verified := false


## Construct an event from a byte-verified cutscene VM `$ED nn` record.
## The event identifies the ROM queue-store instruction reached by the ROM's
## `$85EB→$85EC` handler. `route_frame` is the Godot model's tick counter only.
func populate_from_cutscene_ed_command(cutscene_id: int, source_event: Dictionary,
		route_frame: int) -> bool:
	if str(source_event.get("kind", "")) != "sound_command" \
			or int(source_event.get("opcode", -1)) != 0xED:
		return false
	var raw_value: Variant = source_event.get("raw_bytes", [])
	if not raw_value is Array or raw_value.size() != 2 \
			or int(raw_value[0]) != 0xED:
		return false
	var raw := PackedByteArray([int(raw_value[0]), int(raw_value[1])])
	var queue_id := int(source_event.get("id", -1))
	if queue_id < 0 or queue_id > 0xFF or int(raw[1]) != queue_id:
		return false
	var event_index := int(source_event.get("event_index", -1))
	var script_offset := int(source_event.get("script_offset", -1))
	var script_cpu_address := int(source_event.get("cpu_address", -1))
	if cutscene_id <= 0 or event_index < 0 or script_offset < 0 \
			or script_cpu_address < 0 or route_frame < 0:
		return false

	event_identity = "ed:%02X:%04X:%04X:%d" % [cutscene_id,
		script_cpu_address, script_offset, event_index]
	event_origin = "rom_cutscene_script_ed_command"
	self.queue_id = queue_id
	self.cutscene_id = cutscene_id
	script_event_index = event_index
	self.script_offset = script_offset
	self.script_cpu_address = script_cpu_address
	script_raw_bytes = raw
	handler_entry_pc = CUTSCENE_SOUND_HANDLER_PC
	queue_store_instruction_pc = CUTSCENE_SOUND_QUEUE_STORE_PC
	post_store_pc = CUTSCENE_SOUND_POST_STORE_PC
	self.route_frame = route_frame
	route_frame_domain = "godot_route_vm_tick"
	# This command VM preserves the ROM command and dispatch meaning but does
	# not emulate CPU execution or cycle/NMI interleaving.
	absolute_rom_frame = -1
	cpu_cycle = -1
	timing_verified = false
	return true


## Construct a typed event from the live bank-$00 `$812C` direct queue store.
## The model tick is recorded separately from unknown ROM frame/cycle timing.
func populate_from_rom_direct_queue_store(source_event: Dictionary,
		route_frame: int) -> bool:
	if String(source_event.get("event_origin", "")) != "rom_direct_queue_store" \
			or String(source_event.get("source_rom_sha256", "")) != SOURCE_ROM_SHA256 \
			or int(source_event.get("queue_address", -1)) != 0x0700 \
			or int(source_event.get("queue_store_instruction_pc", -1)) != 0x812C \
			or int(source_event.get("post_store_pc", -1)) != 0x812F \
			or int(source_event.get("queue_id", -1)) not in [0x55, 0x4C] \
			or route_frame < 0 or int(source_event.get("route_frame", -1)) != route_frame:
		return false
	event_identity = String(source_event.get("event_id", ""))
	if event_identity.is_empty():
		return false
	event_origin = "rom_direct_queue_store"
	queue_id = int(source_event.get("queue_id", -1))
	queue_store_instruction_pc = 0x812C
	post_store_pc = 0x812F
	self.route_frame = route_frame
	route_frame_domain = "godot_route_model_tick"
	absolute_rom_frame = -1
	cpu_cycle = -1
	timing_verified = false
	return true


## Construct an event from a verified `$CBF1` helper result whose `$CBFE`
## `STA $0700,X` inserted one request. The caller supplies the source-route
## frame; this value is frame-level metadata and does not claim subframe timing.
func populate_from_cbf1_queue_insert(helper_result: Dictionary,
		source_frame: int) -> bool:
	if not bool(helper_result.get("ok", false)) \
			or String(helper_result.get("status", "")) != "queued_sound_request" \
			or String(helper_result.get("source_call_status", "")) != "source_cbf1_call_entry" \
			or String(helper_result.get("rom_sha256", "")) != SOURCE_ROM_SHA256 \
			or String(helper_result.get("source_span_sha256", "")) != CBF1_HELPER_SOURCE_SHA256 \
			or String(helper_result.get("source_manifest_sha256", "")) != CBF1_SOURCE_MANIFEST_SHA256 \
			or String(helper_result.get("dependency_manifest_sha256", "")) != CBF1_DEPENDENCY_MANIFEST_SHA256 \
			or int(helper_result.get("entry_pc", -1)) != 0xCBF1 \
			or int(helper_result.get("rts_pc", -1)) != CBF1_QUEUE_POST_STORE_PC \
			or bool(helper_result.get("queue_full", true)) \
			or source_frame < 0:
		return false
	var queue_slot := int(helper_result.get("queue_index", -1))
	var queue_id := int(helper_result.get("sound_request_value", -1))
	var writes_value: Variant = helper_result.get("memory_writes", [])
	var entry_registers_value: Variant = helper_result.get("entry_registers", {})
	var output_queue_value: Variant = helper_result.get("output_queue", PackedByteArray())
	if queue_slot < 0 or queue_slot >= CBF1_QUEUE_SIZE \
			or queue_id <= 0 or queue_id > 0xFF \
			or not writes_value is Array or writes_value.size() != 1 \
			or not entry_registers_value is Dictionary \
			or not output_queue_value is PackedByteArray \
			or output_queue_value.size() != CBF1_QUEUE_SIZE \
			or int(entry_registers_value.get("a", -1)) != queue_id:
		return false
	var output_queue: PackedByteArray = output_queue_value
	if int(output_queue[queue_slot]) != queue_id:
		return false
	var write_value: Variant = writes_value[0]
	if not write_value is Dictionary:
		return false
	var write: Dictionary = write_value
	var queue_address := CBF1_QUEUE_START + queue_slot
	if int(write.get("pc", -1)) != CBF1_QUEUE_STORE_PC \
			or int(write.get("address", -1)) != queue_address \
			or int(write.get("value", -1)) != queue_id \
			or String(write.get("kind", "")) != "queue_write":
		return false
	var caller_pc := int(helper_result.get("caller_pc", -1))
	if caller_pc < 0 or caller_pc > 0xFFFF:
		return false

	event_identity = "cbf1:%04X:%04X:%d:%d:%02X" % [caller_pc,
		CBF1_QUEUE_STORE_PC, source_frame, queue_slot, queue_id]
	event_origin = "rom_cbf1_queue_insert"
	source_rom_sha256 = SOURCE_ROM_SHA256
	self.queue_id = queue_id
	queue_store_instruction_pc = CBF1_QUEUE_STORE_PC
	post_store_pc = CBF1_QUEUE_POST_STORE_PC
	self.queue_slot = queue_slot
	self.queue_address = queue_address
	source_caller_pc = caller_pc
	root_input_ram_052e = int(helper_result.get("root_input_ram_052e", -1))
	root_input_ram_052f = int(helper_result.get("root_input_ram_052f", -1))
	root_output_ram_052e = int(helper_result.get("root_output_ram_052e", -1))
	root_source_ram_0530 = int(helper_result.get("root_source_ram_0530", -1))
	root_source_ram_0531 = int(helper_result.get("root_source_ram_0531", -1))
	root_source_ram_063f = int(helper_result.get("root_source_ram_063f", -1))
	root_scenario_id = int(helper_result.get("root_scenario_id", -1))
	self.source_frame = source_frame
	source_frame_domain = "godot_source_route_frame"
	source_helper_span_sha256 = CBF1_HELPER_SOURCE_SHA256
	source_manifest_sha256 = CBF1_SOURCE_MANIFEST_SHA256
	dependency_manifest_sha256 = CBF1_DEPENDENCY_MANIFEST_SHA256
	route_frame = -1
	route_frame_domain = ""
	absolute_rom_frame = -1
	cpu_cycle = -1
	timing_verified = false
	return true


## Construct an event from the initial fresh-match continuation's executed
## `$DAAA->$CBF1->$CC01` queue write. The supplied continuation result is the
## bounded ROM-byte execution result, not a trace row or endpoint RAM sample.
func populate_from_fresh_daaa_queue_insert(continuation_result: Dictionary,
		source_frame: int) -> bool:
	if not bool(continuation_result.get("ok", false)) \
			or String(continuation_result.get("rom_sha256", "")) != SOURCE_ROM_SHA256 \
			or String(continuation_result.get("source_manifest", "")) \
			!= "res://reference/rom_extract/gameplay/fresh_daaa_continuation/manifest.json" \
			or int(continuation_result.get("entry_pc", -1)) != 0xDAAA \
			or int(continuation_result.get("exit_pc", -1)) != 0x800C \
			or source_frame < 0:
		return false
	var calls_variant: Variant = continuation_result.get("calls", [])
	var instructions_variant: Variant = continuation_result.get("instructions", [])
	var writes_variant: Variant = continuation_result.get("writes", [])
	var ram_variant: Variant = continuation_result.get("ram_image", PackedByteArray())
	if not calls_variant is Array or not instructions_variant is Array \
			or not writes_variant is Array or not ram_variant is PackedByteArray \
			or (ram_variant as PackedByteArray).size() != 0x800:
		return false
	var saw_daaa_call := false
	for call_variant in calls_variant:
		if not call_variant is Dictionary:
			continue
		var call: Dictionary = call_variant
		if int(call.get("callsite", -1)) == 0xDAAC \
				and int(call.get("target", -1)) == 0xCBF1 \
				and int(call.get("bank", -1)) == 0x1E:
			saw_daaa_call = true
	var saw_store_instruction := false
	for instruction_variant in instructions_variant:
		if not instruction_variant is Dictionary:
			continue
		var instruction: Dictionary = instruction_variant
		if int(instruction.get("pc", -1)) == 0xCBFE \
				and int(instruction.get("bank", -1)) == 0x1E \
				and int(instruction.get("opcode", -1)) == 0x9D \
				and int(instruction.get("next_pc", -1)) == 0xCC01:
			saw_store_instruction = true
	var queue_writes: Array[Dictionary] = []
	for write_variant in writes_variant:
		if not write_variant is Dictionary:
			continue
		var write: Dictionary = write_variant
		if int(write.get("address", -1)) >= CBF1_QUEUE_START \
				and int(write.get("address", -1)) < CBF1_QUEUE_START + CBF1_QUEUE_SIZE:
			queue_writes.append(write)
	if not saw_daaa_call or not saw_store_instruction or queue_writes.size() != 1:
		return false
	var queue_write := queue_writes[0]
	var queue_slot := int(queue_write.get("address", -1)) - CBF1_QUEUE_START
	var queue_id := int(queue_write.get("value", -1))
	var output_ram: PackedByteArray = ram_variant
	if queue_slot != 0 or queue_id != STOP_QUEUE_ID \
			or int(queue_write.get("pc", -1)) != CBF1_QUEUE_STORE_PC \
			or int(queue_write.get("trace_pc", -1)) != CBF1_QUEUE_POST_STORE_PC \
			or int(queue_write.get("bank", -1)) != 0x1E \
			or int(output_ram[CBF1_QUEUE_START]) != queue_id \
			or output_ram.slice(CBF1_QUEUE_START, CBF1_QUEUE_START + CBF1_QUEUE_SIZE) \
			!= PackedByteArray([STOP_QUEUE_ID, 0, 0, 0, 0]):
		return false
	event_identity = "daaa-cbf1:%04X:%04X:%d:%02X" % [
		0xDAAC, CBF1_QUEUE_POST_STORE_PC, source_frame, queue_slot]
	event_origin = "rom_daaa_cbf1_queue_insert"
	source_rom_sha256 = SOURCE_ROM_SHA256
	self.queue_id = queue_id
	queue_store_instruction_pc = CBF1_QUEUE_STORE_PC
	post_store_pc = CBF1_QUEUE_POST_STORE_PC
	self.queue_slot = queue_slot
	queue_address = CBF1_QUEUE_START + queue_slot
	source_caller_pc = 0xDAAC
	self.source_frame = source_frame
	source_frame_domain = "godot_source_route_frame"
	source_helper_span_sha256 = FRESH_DAAA_QUEUE_SOURCE_SHA256
	source_manifest_sha256 = FRESH_DAAA_SOURCE_MANIFEST_SHA256
	dependency_manifest_sha256 = ""
	route_frame = -1
	route_frame_domain = ""
	absolute_rom_frame = -1
	cpu_cycle = -1
	timing_verified = false
	return true


func is_valid_fresh_daaa_queue_insert() -> bool:
	return event_identity.begins_with("daaa-cbf1:") \
			and event_origin == "rom_daaa_cbf1_queue_insert" \
			and source_rom_sha256 == SOURCE_ROM_SHA256 \
			and queue_id == STOP_QUEUE_ID \
			and queue_slot == 0 and queue_address == CBF1_QUEUE_START \
			and source_caller_pc == 0xDAAC \
			and queue_store_instruction_pc == CBF1_QUEUE_STORE_PC \
			and post_store_pc == CBF1_QUEUE_POST_STORE_PC \
			and source_frame >= 0 \
			and source_frame_domain == "godot_source_route_frame" \
			and source_helper_span_sha256 == FRESH_DAAA_QUEUE_SOURCE_SHA256 \
			and source_manifest_sha256 == FRESH_DAAA_SOURCE_MANIFEST_SHA256 \
			and dependency_manifest_sha256.is_empty() \
			and absolute_rom_frame == -1 and cpu_cycle == -1 and not timing_verified


func is_valid_cbf1_queue_insert() -> bool:
	return event_identity.begins_with("cbf1:") \
			and event_origin == "rom_cbf1_queue_insert" \
			and source_rom_sha256 == SOURCE_ROM_SHA256 \
			and queue_id > 0 and queue_id <= 0xFF \
			and queue_slot >= 0 and queue_slot < CBF1_QUEUE_SIZE \
			and queue_address == CBF1_QUEUE_START + queue_slot \
			and queue_store_instruction_pc == CBF1_QUEUE_STORE_PC \
			and post_store_pc == CBF1_QUEUE_POST_STORE_PC \
			and source_caller_pc >= 0 and source_caller_pc <= 0xFFFF \
			and source_frame >= 0 \
			and source_frame_domain == "godot_source_route_frame" \
			and source_helper_span_sha256 == CBF1_HELPER_SOURCE_SHA256 \
			and source_manifest_sha256 == CBF1_SOURCE_MANIFEST_SHA256 \
			and dependency_manifest_sha256 == CBF1_DEPENDENCY_MANIFEST_SHA256 \
			and absolute_rom_frame == -1 and cpu_cycle == -1 and not timing_verified


func to_dictionary() -> Dictionary:
	return {
		"event_identity": event_identity,
		"event_origin": event_origin,
		"source_rom_sha256": source_rom_sha256,
		"queue_id": queue_id,
		"cutscene_id": cutscene_id,
		"script_event_index": script_event_index,
		"script_offset": script_offset,
		"script_cpu_address": script_cpu_address,
		"script_raw_bytes": script_raw_bytes.duplicate(),
		"handler_entry_pc": handler_entry_pc,
		"queue_store_instruction_pc": queue_store_instruction_pc,
		"post_store_pc": post_store_pc,
		"queue_slot": queue_slot,
		"queue_address": queue_address,
		"source_caller_pc": source_caller_pc,
		"source_frame": source_frame,
		"source_frame_domain": source_frame_domain,
		"source_helper_span_sha256": source_helper_span_sha256,
		"source_manifest_sha256": source_manifest_sha256,
		"dependency_manifest_sha256": dependency_manifest_sha256,
		"root_input_ram_052e": root_input_ram_052e,
		"root_input_ram_052f": root_input_ram_052f,
		"root_output_ram_052e": root_output_ram_052e,
		"root_source_ram_0530": root_source_ram_0530,
		"root_source_ram_0531": root_source_ram_0531,
		"root_source_ram_063f": root_source_ram_063f,
		"root_scenario_id": root_scenario_id,
		"route_frame": route_frame,
		"route_frame_domain": route_frame_domain,
		"absolute_rom_frame": absolute_rom_frame,
		"cpu_cycle": cpu_cycle,
		"timing_verified": timing_verified,
	}
