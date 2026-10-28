extends RefCounted
class_name RomSoundQueueWriteEvent
## Typed provenance for a ROM sound-queue write requested by a decoded source
## event. A route VM tick is not an NES CPU timestamp; unresolved cycle and
## absolute-ROM-frame values stay explicitly unknown.

const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const CUTSCENE_SOUND_HANDLER_PC := 0x85EC
const CUTSCENE_SOUND_QUEUE_STORE_PC := 0x85FC
const CUTSCENE_SOUND_POST_STORE_PC := 0x85FF

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
		"route_frame": route_frame,
		"route_frame_domain": route_frame_domain,
		"absolute_rom_frame": absolute_rom_frame,
		"cpu_cycle": cpu_cycle,
		"timing_verified": timing_verified,
	}
