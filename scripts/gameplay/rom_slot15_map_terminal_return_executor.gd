extends RefCounted
class_name RomSlot15MapTerminalReturnExecutor
## Executes the source-confirmed return after a final slot-$15 map packet:
## worker RTS, callback placement tail, map-specific dispatcher tail, and the
## $C512 trampoline.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const WORKER_PATH := "res://reference/rom_extract/gameplay/first_command_field/map_worker_8525/bank_0b_8572_85c2.bin"
const PLACEMENT_PATH := "res://reference/rom_extract/gameplay/first_command_field/packet_producer/bank_0b_8327_8360_map_placement_writer.bin"
const DISPATCHER_PATH := "res://reference/rom_extract/gameplay/first_command_field/callback_dispatch/bank_0b_dispatcher_814c_81a6.bin"
const FINISH_TRAMPOLINE_PATH := "res://reference/rom_extract/gameplay/task_context/fixed_task_finish_trampoline_C512.bin"
const WORKER_SHA256 := "098a354cae578918bf54407b972e69b520327d030eb391ed3c2d476c4d337502"
const PLACEMENT_SHA256 := "e3ed67bcd4a760f0f8324b4d46ca08100ef6d1b578af495da8475b7e66096853"
const DISPATCHER_SHA256 := "c648a228e5e90247ce604220a2aff2bb4b1c58af30546e71b543fec874b28df6"
const FINISH_TRAMPOLINE_SHA256 := "bc85dc6c05fac84b9063f3cb28a3acbe16e2591ab2dff53b935530aa2a35940f"
const P_N := 0x80
const P_Z := 0x02
const P_NZ := P_N | P_Z

var error_message := ""
var _sources: Dictionary = {}


func execute_from_exhausted_map_worker(dispatch: Dictionary, boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _load_sources():
		return _failure(error_message)
	var registers_variant: Variant = boundary
	var ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
	var stack_variant: Variant = boundary.get("stack_page", PackedByteArray())
	if not registers_variant is Dictionary or not ram_variant is PackedByteArray \
			or not stack_variant is PackedByteArray:
		return _failure("The exhausted map-worker return omits CPU, RAM, or stack state.")
	var cpu: Dictionary = registers_variant.duplicate(true)
	var ram: PackedByteArray = ram_variant.duplicate()
	var stack: PackedByteArray = stack_variant.duplicate()
	var map_id := int(ram[0x05CC]) if ram.size() == 0x800 else -1
	var map42_placement_branch := ram.size() == 0x800 \
		and int(ram[0x05C7]) == 0x24 and int(ram[0x05C8]) == 0xC0 \
		and int(ram[0x05C9]) == 0x00 and int(ram[0x05CD]) == 0xA0
	var map42_zero_branch := ram.size() == 0x800 \
		and int(ram[0x05C7]) == 0x40 and int(ram[0x05C8]) == 0x20 \
		and int(ram[0x05C9]) == 0x00 and int(ram[0x05CD]) == 0x00
	var map43_placement_branch := ram.size() == 0x800 \
		and int(ram[0x05C7]) == 0x40 and int(ram[0x05C8]) == 0xA0 \
		and int(ram[0x05C9]) == 0x00 and int(ram[0x05CD]) == 0x80
	var map36_final_page_branch := map_id == 0x36 and ram.size() == 0x800 \
		and int(ram[0x05C7]) == 0x40 and int(ram[0x05C8]) == 0xA0 \
		and int(ram[0x05C9]) == 0x00 and int(ram[0x05CA]) == 0x01 \
		and int(ram[0x05CD]) == 0x80
	var map52_placement_branch := ram.size() == 0x800 \
		and int(ram[0x05C7]) == 0x40 and int(ram[0x05C8]) == 0xA0 \
		and int(ram[0x05C9]) == 0x00 and int(ram[0x05CD]) == 0x80
	var map52_final_page_branch := map_id == 0x52 and ram.size() == 0x800 \
		and int(ram[0x05C7]) == 0x24 and int(ram[0x05C8]) == 0xC0 \
		and int(ram[0x05C9]) == 0x00 and int(ram[0x05CD]) == 0xA0
	# Scenario-$1C callback-$63 map-$51 reaches this exhausted cursor after the
	# final page at frame 9202 in the repeated FCEUX trace. The callback and map
	# pointer keep this profile from accepting another map's coincidental cursor.
	var map51_final_page_branch := map_id == 0x51 and ram.size() == 0x800 \
		and int(ram[0x05C7]) == 0x24 and int(ram[0x05C8]) == 0xC0 \
		and int(ram[0x05C9]) == 0x00 and int(ram[0x05CA]) == 0x00 \
		and int(ram[0x05CD]) == 0xA0 and int(ram[0x05CE]) == 0x80 \
		and int(ram[0x0518]) == 0x1C and int(ram[0x0524]) == 0x63 \
		and int(ram[0x0054]) == 0x84 and int(ram[0x0055]) == 0x95
	var map56_final_page_branch := map_id == 0x56 and ram.size() == 0x800 \
		and int(ram[0x05C7]) == 0x24 and int(ram[0x05C8]) == 0xC0 \
		and int(ram[0x05C9]) == 0x00 and int(ram[0x05CA]) == 0x02 \
		and int(ram[0x05CD]) == 0xA0
	var map2d_final_page_branch := map_id == 0x2D and ram.size() == 0x800 \
		and int(ram[0x05C7]) == 0x40 and int(ram[0x05C8]) == 0xA0 \
		and int(ram[0x05C9]) == 0x00 and int(ram[0x05CA]) == 0x02 \
		and int(ram[0x05CD]) == 0x80
	var map2f_final_page_branch := map_id == 0x2F and ram.size() == 0x800 \
		and int(ram[0x05C7]) == 0x24 and int(ram[0x05C8]) == 0xC0 \
		and int(ram[0x05C9]) == 0x00 and int(ram[0x05CA]) == 0x01 \
		and int(ram[0x05CC]) == 0x2F and int(ram[0x05CD]) == 0xA0
	var map_f0_placement_branch := map_id in [0x00, 0x0E, 0x11, 0x12] and ram.size() == 0x800 \
		and int(ram[0x05C7]) == 0x24 and int(ram[0x05C8]) == 0xC0 \
		and int(ram[0x05C9]) == 0x00 and int(ram[0x05CA]) == 0x00 \
		and int(ram[0x05CD]) == 0xA0
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != 0x15 \
			or int(boundary.get("pc", -1)) != 0x85C1 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(dispatch.get("pc", -1)) != 0x85C1 \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch.get("sp", -1)) != 0xEE \
			or int(dispatch.get("a", -1)) != int(cpu.get("a", -2)) \
			or int(dispatch.get("x", -1)) != int(cpu.get("x", -2)) \
			or int(dispatch.get("y", -1)) != int(cpu.get("y", -2)) \
			or ram.size() != 0x800 or stack.size() != 0x100:
			return _failure("Input is not a source-selected exhausted slot-$15 map task at `$85C1 RTS`.")
	var supported_terminal_branch := map_f0_placement_branch \
		or (map_id == 0x42 and (map42_placement_branch or map42_zero_branch)) \
		or (map_id == 0x36 and map36_final_page_branch) \
		or (map_id == 0x43 and map43_placement_branch) \
		or map51_final_page_branch \
		or (map_id == 0x52 and (map52_placement_branch or map52_final_page_branch)) \
		or (map_id == 0x56 and map56_final_page_branch) \
		or (map_id == 0x2D and map2d_final_page_branch) \
		or (map_id == 0x2F and map2f_final_page_branch)
	var expected_selector := 0x02 if map_id in [0x2D, 0x56] else (0x00 if map_id in [0x00, 0x0E, 0x11, 0x12, 0x51, 0x52] else 0x01)
	var expected_bank_high := 0x13 if map_id in [0x2D, 0x56] else 0x12
	if map_id not in [0x00, 0x0E, 0x11, 0x12, 0x2D, 0x2F, 0x36, 0x42, 0x43, 0x51, 0x52, 0x56] \
			or int(ram[0x05CA]) != expected_selector \
			or (map_id == 0x51 and (int(boundary.get("bank_low", -1)) != 0x0B \
				or int(boundary.get("bank_high", -1)) != expected_bank_high \
				or boundary.get("record", PackedByteArray()) != PackedByteArray([0x00, 0xEA, 0x0B, 0x12]))) \
			or (map_id == 0x2D and (int(boundary.get("bank_low", -1)) != 0x0B \
				or int(boundary.get("bank_high", -1)) != expected_bank_high \
				or boundary.get("record", PackedByteArray()) != PackedByteArray([0x00, 0xEA, 0x0B, 0x13]))) \
			or (map_id == 0x2F and (int(boundary.get("bank_low", -1)) != 0x0B \
				or int(boundary.get("bank_high", -1)) != 0x12 \
				or boundary.get("record", PackedByteArray()) != PackedByteArray([0x00, 0xEA, 0x0B, 0x12]))) \
			or not supported_terminal_branch:
		return _failure("The exhausted map-$%02X row cursor does not match a source-verified callback branch." % map_id)
	var expected_callback_return := 0x7C if map_f0_placement_branch else 0x9B
	if int(stack[0xEF]) != 0x33 or int(stack[0xF0]) != 0x83 \
			or int(stack[0xF1]) != expected_callback_return or int(stack[0xF2]) != 0x81:
		return _failure("The `$85C1` RTS stack does not match the map-$%02X callback return path: SP=$%02X stack[$EF:$F3]=%s." % [map_id, int(cpu.get("sp", -1)), stack.slice(0xEF, 0xF3).hex_encode()])
	var source_worker: PackedByteArray = _sources["worker"]
	var source_placement: PackedByteArray = _sources["placement"]
	var source_dispatcher: PackedByteArray = _sources["dispatcher"]
	var source_finish: PackedByteArray = _sources["finish"]
	if int(source_worker[0x4F]) != 0x60 \
			or source_placement.slice(0x0D, 0x31) != PackedByteArray([
				0xA9, 0x01, 0x8D, 0xCB, 0x05, 0xAD, 0xCD, 0x05, 0xF0, 0x04,
				0x29, 0x20, 0x09, 0x80, 0x8D, 0xCE, 0x05, 0x09, 0x80, 0x49,
				0x20, 0x8D, 0xCD, 0x05, 0xA9, 0x00, 0x8D, 0xDB, 0x05, 0x8D,
				0xDC, 0x05, 0x8D, 0xDD, 0x05, 0x60]) \
			or source_dispatcher.slice(0x50, 0x5B) != PackedByteArray([
				0xAD, 0x16, 0x05, 0x09, 0x10, 0x8D, 0x16, 0x05, 0x4C, 0x12, 0xC5]) \
			or (map_f0_placement_branch and source_dispatcher.slice(0x31, 0x3C) != PackedByteArray([
				0xA9, 0x02, 0x8D, 0xD0, 0x05, 0x8D, 0x25, 0x05, 0x4C, 0x9C, 0x81])) \
			or source_finish != PackedByteArray([0x4C, 0xF7, 0xCA]):
		return _failure("A source opcode differs from the exhausted map-worker return path.")

	var entry_cpu := cpu.duplicate(true)
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var writes: Array[Dictionary] = []
	var instruction_pcs: Array[int] = [0x85C1, 0x8334, 0x8336, 0x8339, 0x833C]

	# RTS at $85C1 consumes the worker's JSR frame and resumes $8334.
	cpu["sp"] = 0xF0
	cpu["pc"] = 0x8334
	# Callback tail follows its source branch using the current `$05CD` value.
	_set_a(cpu, 0x01)
	_append_write(ram, writes, 0x05CB, 0x01, 0x8339, cpu)
	_set_a(cpu, int(ram[0x05CD]))
	if int(cpu["a"]) != 0:
		instruction_pcs.append(0x833E)
		_set_a(cpu, int(cpu["a"]) & 0x20)
		instruction_pcs.append(0x8340)
		_set_a(cpu, int(cpu["a"]) | 0x80)
	else:
		instruction_pcs.append(0x8342)
	_append_write(ram, writes, 0x05CE, int(cpu["a"]), 0x8345, cpu)
	_set_a(cpu, int(cpu["a"]) | 0x80)
	_set_a(cpu, int(cpu["a"]) ^ 0x20)
	_append_write(ram, writes, 0x05CD, int(cpu["a"]), 0x834C, cpu)
	_set_a(cpu, 0)
	_append_write(ram, writes, 0x05DB, 0, 0x8351, cpu)
	_append_write(ram, writes, 0x05DC, 0, 0x8354, cpu)
	_append_write(ram, writes, 0x05DD, 0, 0x8357, cpu)
	instruction_pcs.append_array([0x8345, 0x8347, 0x8349, 0x834C, 0x834E,
		0x8351, 0x8354, 0x8357])
	# The F0 callback returns to $817D, writes its route marker, then jumps to
	# $819C; ordinary table callbacks return directly to $819C.
	var callback_return_pc := 0x819C
	if map_f0_placement_branch:
		cpu["pc"] = 0x817D
		_set_a(cpu, 0x02)
		_append_write(ram, writes, 0x05D0, 0x02, 0x8182, cpu)
		_append_write(ram, writes, 0x0525, 0x02, 0x8185, cpu)
		callback_return_pc = 0x817D
		instruction_pcs.append_array([0x817D, 0x817F, 0x8182, 0x8185])
	# Dispatcher sets bit $10 then jumps through the checked fixed-bank
	# $C512 -> $CAF7 trampoline.
	cpu["sp"] = 0xF2
	cpu["pc"] = 0x819C
	_set_a(cpu, int(ram[0x0516]))
	_set_a(cpu, int(cpu["a"]) | 0x10)
	_append_write(ram, writes, 0x0516, int(cpu["a"]), 0x81A4, cpu)
	cpu["pc"] = 0xCAF7
	instruction_pcs.append_array([0x819C, 0x819F, 0x81A1, 0x81A4, 0xC512])
	return {
		"ok": true,
		"status": "slot15_map%02X_terminal_return_reached_CAF7" % map_id,
		"rom_sha256": ROM_SHA256,
		"source_hashes": {"worker": WORKER_SHA256, "placement": PLACEMENT_SHA256,
			"dispatcher": DISPATCHER_SHA256, "finish_trampoline": FINISH_TRAMPOLINE_SHA256},
		"entry_registers": entry_cpu,
		"registers": cpu,
		"entry_ram_image": entry_ram,
		"updated_ram": ram,
		"ram_writes": writes,
		"entry_stack_page": entry_stack,
		"stack_page": stack,
		"instruction_pcs": instruction_pcs,
		"exit_pc": 0xCAF7,
		"callback_return_pc": callback_return_pc,
		"map_id": map_id,
	"placement_branch": "placement_80" if map2d_final_page_branch else ("placement_A0" if (map_f0_placement_branch or map42_placement_branch or map36_final_page_branch or map43_placement_branch or map51_final_page_branch) else "zero"),
		"dispatcher_tail": "f0_marker_then_819c" if map_f0_placement_branch else "direct_819c",
		"source_cycle_timing_modeled": false,
		"trace_state_used": false,
	}


func _load_sources() -> bool:
	_sources.clear()
	var specs := {
		"worker": [WORKER_PATH, WORKER_SHA256],
		"placement": [PLACEMENT_PATH, PLACEMENT_SHA256],
		"dispatcher": [DISPATCHER_PATH, DISPATCHER_SHA256],
		"finish": [FINISH_TRAMPOLINE_PATH, FINISH_TRAMPOLINE_SHA256],
	}
	for key_variant in specs:
		var key := String(key_variant)
		var spec: Array = specs[key]
		var path := String(spec[0])
		var bytes := FileAccess.get_file_as_bytes(path)
		if bytes.is_empty() or _sha256(bytes) != String(spec[1]):
			error_message = "ROM-derived terminal-return bytes failed hash validation: %s." % path
			return false
		_sources[key] = bytes
	return true


func _append_write(ram: PackedByteArray, writes: Array[Dictionary], address: int,
		value: int, pc_after_write: int, cpu: Dictionary) -> void:
	var byte_value := value & 0xFF
	writes.append({"address": address, "old": int(ram[address]), "value": byte_value,
		"pc_after_write": pc_after_write, "a": int(cpu["a"]), "x": int(cpu["x"]),
		"y": int(cpu["y"]), "p": int(cpu["p"])})
	ram[address] = byte_value


func _set_a(cpu: Dictionary, value: int) -> void:
	var byte_value := value & 0xFF
	cpu["a"] = byte_value
	var p := int(cpu.get("p", 0x20)) & ~P_NZ
	if (byte_value & 0x80) != 0:
		p |= P_N
	if byte_value == 0:
		p |= P_Z
	cpu["p"] = p | 0x20


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()


func _failure(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "status": "rejected", "error": error_message}
