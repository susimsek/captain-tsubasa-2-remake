extends SceneTree

const EXECUTOR := preload("res://scripts/gameplay/rom_slot11_actor_worker_resume_executor.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_MANIFEST := "res://reference/rom_extract/gameplay/slot11_actor_worker_resume_wait/manifest.json"
const RAM_SIZE := 0x800
const STACK_SIZE := 0x100


func _initialize() -> void:
	var checkpoint_path := OS.get_environment("CT2_SLOT11_BOUNDARY_JSON").strip_edges()
	if checkpoint_path.is_empty():
		_fail("Set CT2_SLOT11_BOUNDARY_JSON to an ordinary-input Godot route boundary JSON file.")
		return
	if not FileAccess.file_exists(checkpoint_path):
		_fail("Boundary JSON does not exist: %s" % checkpoint_path)
		return
	var file := FileAccess.open(checkpoint_path, FileAccess.READ)
	if file == null:
		_fail("Could not read boundary JSON: %s" % checkpoint_path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		_fail("Boundary JSON must contain a top-level object.")
		return
	var checkpoint: Dictionary = parsed
	if String(checkpoint.get("source", "")) != "ordinary_input_godot_source_route":
		_fail("Refusing non-route-watcher data; expected source=ordinary_input_godot_source_route.")
		return
	var boundary_result := _build_boundary(checkpoint)
	if not bool(boundary_result.get("ok", false)):
		_fail(String(boundary_result.get("error", "Invalid route checkpoint.")))
		return
	var boundary: Dictionary = boundary_result["boundary"]
	var executor = EXECUTOR.new()
	if not executor.configure_from_project_sources():
		_fail("Executor source setup failed: %s" % executor.error_message)
		return
	var result: Dictionary = executor.execute_from_slot11_packet_wait_resume_boundary(boundary)
	if not bool(result.get("ok", false)):
		_fail("Worker rejected frame %d at $%04X: %s" % [
			int(checkpoint["source_frame"]), int(boundary["pc"]),
			String(result.get("error", "unsupported source path"))])
		return
	print("PASS: frame=%d slot=$%02X $%04X->$%04X status=%s yield=$%04X resume=$%04X steps=%d reads=%d writes=%d" % [
		int(checkpoint["source_frame"]), int(boundary["slot_base"]),
		int(result.get("entry_pc", -1)), int(result.get("exit_pc", -1)),
		String(result.get("status", "")), int(result.get("yield_callsite_pc", -1)),
		int(result.get("resume_pc_after_rts", -1)),
		(result.get("instruction_pcs", []) as Array).size(),
		(result.get("source_reads", []) as Array).size(),
		(result.get("ram_writes", []) as Array).size()])
	var decoded: Dictionary = result.get("decoded_packet", {})
	var output_ram: PackedByteArray = result.get("ram_image", PackedByteArray())
	var output_stack: PackedByteArray = result.get("stack_page", PackedByteArray())
	print("RESULT: pointer=$%04X E3:EA=%s F3:F5=%s queue=$%02X stack[C7:CB]=%s decoded=%s" % [
		int(output_ram[0x005F]) | (int(output_ram[0x0060]) << 8) if output_ram.size() == RAM_SIZE else -1,
		output_ram.slice(0x05E3, 0x05EB).hex_encode() if output_ram.size() == RAM_SIZE else "invalid",
		output_ram.slice(0x05F3, 0x05F6).hex_encode() if output_ram.size() == RAM_SIZE else "invalid",
		int(output_ram[0x0515]) if output_ram.size() == RAM_SIZE else -1,
		output_stack.slice(0xC7, 0xCC).hex_encode() if output_stack.size() == STACK_SIZE else "invalid",
		JSON.stringify(decoded)])
	var text_reads: Array[String] = []
	for read_variant: Variant in result.get("source_reads", []):
		if not read_variant is Dictionary:
			continue
		var read: Dictionary = read_variant
		if String(read.get("kind", "")) == "actor_packet_resume_rom_data" \
				and int(read.get("address", -1)) >= 0xF000:
			text_reads.append("$%04X:$%02X" % [int(read["address"]), int(read["value"])])
	print("TEXT_READS: %s" % ",".join(text_reads))
	if OS.get_environment("CT2_PACKET_RESUME_TRACE").strip_edges() == "1":
		var trace_reads: Array[String] = []
		var seen_reads: Dictionary = {}
		for read_variant: Variant in result.get("source_reads", []):
			if not read_variant is Dictionary:
				continue
			var read: Dictionary = read_variant
			if String(read.get("kind", "")) != "actor_packet_resume_rom_data":
				continue
			var address := int(read.get("address", -1))
			if not ((address >= 0x8360 and address <= 0x83A0) \
				or (address >= 0x86E8 and address <= 0x86ED) \
				or (address >= 0x9A60 and address <= 0x9A6F) \
				or (address >= 0xCD89 and address <= 0xCDA0) \
				or address >= 0xF000):
				continue
			var key := "$%04X=$%02X" % [address, int(read.get("value", -1))]
			if not seen_reads.has(key):
				seen_reads[key] = true
				trace_reads.append(key)
		print("ROM_READS: %s" % ",".join(trace_reads))
	print("YIELD: callsite=%s cb0f=%s output=%s" % [
		JSON.stringify(result.get("yield_callsite_registers", {})),
		JSON.stringify(result.get("cb0f_entry_registers", {})),
		JSON.stringify({
			"header": output_ram.slice(0x04A5, 0x04B9).hex_encode() if output_ram.size() == RAM_SIZE else "invalid",
			"text": output_ram.slice(0x04B9, 0x04BF).hex_encode() if output_ram.size() == RAM_SIZE else "invalid",
			"E3_EA": output_ram.slice(0x05E3, 0x05EB).hex_encode() if output_ram.size() == RAM_SIZE else "invalid",
			"F3_F5": output_ram.slice(0x05F3, 0x05F6).hex_encode() if output_ram.size() == RAM_SIZE else "invalid",
		})])
	quit(0)


func _build_boundary(checkpoint: Dictionary) -> Dictionary:
	var source_frame := _number_field(checkpoint, "source_frame")
	var slot_base := _number_field(checkpoint, "slot_base")
	var pc := _number_field(checkpoint, "pc")
	var sp := _number_field(checkpoint, "sp")
	var bank_low := _number_field(checkpoint, "bank_low")
	var bank_high := _number_field(checkpoint, "bank_high")
	for value: Dictionary in [source_frame, slot_base, pc, sp, bank_low, bank_high]:
		if not bool(value.get("ok", false)):
			return {"ok": false, "error": String(value.get("error", "Missing numeric checkpoint field."))}
	var registers_variant: Variant = checkpoint.get("registers", {})
	var mapper_variant: Variant = checkpoint.get("mapper", {})
	if not registers_variant is Dictionary or not mapper_variant is Dictionary:
		return {"ok": false, "error": "Checkpoint registers and mapper must be JSON objects."}
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant.duplicate(true)
	var register_values := {}
	for name: String in ["a", "x", "y", "p", "p_known_mask"]:
		var field := _number_field(registers, name)
		if not bool(field.get("ok", false)):
			return {"ok": false, "error": String(field.get("error", "Invalid register field."))}
		var value := int(field["value"])
		if value < 0 or value > 0xFF:
			return {"ok": false, "error": "Register %s is outside byte range: %d." % [name, value]}
		register_values[name] = value
	var record := _parse_hex(checkpoint.get("record_hex", ""), 4, "record_hex")
	var ram := _parse_hex(checkpoint.get("ram_hex", ""), RAM_SIZE, "ram_hex")
	var stack := _parse_hex(checkpoint.get("stack_hex", ""), STACK_SIZE, "stack_hex")
	for byte_field: Dictionary in [record, ram, stack]:
		if not bool(byte_field.get("ok", false)):
			return {"ok": false, "error": String(byte_field.get("error", "Invalid hex byte field."))}
	if int(slot_base["value"]) != 0x11:
		return {"ok": false, "error": "Expected slot_base=$11, got $%02X." % int(slot_base["value"])}
	var boundary := {
		"source_frame": int(source_frame["value"]),
		"rom_sha256": ROM_SHA256,
		"source_manifest": SOURCE_MANIFEST,
		"slot_base": int(slot_base["value"]),
		"phase": 2,
		"ready_delay": 0,
		"pending_resume": 0,
		"active_task_slot": 0x11,
		"pc": int(pc["value"]),
		"sp": int(sp["value"]),
		"a": int(register_values["a"]),
		"x": int(register_values["x"]),
		"y": int(register_values["y"]),
		"p": int(register_values["p"]),
		"p_known_mask": int(register_values["p_known_mask"]),
		"record": record["bytes"],
		"bank_low": int(bank_low["value"]),
		"bank_high": int(bank_high["value"]),
		"mapper": mapper,
		"ram_image": ram["bytes"],
		"stack_page": stack["bytes"],
	}
	return {"ok": true, "boundary": boundary}


func _number_field(source: Dictionary, name: String) -> Dictionary:
	if not source.has(name):
		return {"ok": false, "error": "Missing numeric field: %s." % name}
	var value: Variant = source[name]
	if value is int:
		return {"ok": true, "value": int(value)}
	if value is float:
		if float(value) == float(int(value)):
			return {"ok": true, "value": int(value)}
		return {"ok": false, "error": "Field %s must be an integer, not a fraction." % name}
	if value is String:
		var text_value := String(value).strip_edges().to_lower()
		if text_value.begins_with("0x"):
			var hex_number := _parse_hex(String(value), -1, name)
			if bool(hex_number.get("ok", false)):
				var bytes: PackedByteArray = hex_number["bytes"]
				var number := 0
				for byte_value: int in bytes:
					number = (number << 8) | byte_value
				return {"ok": true, "value": number}
			return hex_number
		if text_value.is_valid_int():
			return {"ok": true, "value": text_value.to_int()}
	return {"ok": false, "error": "Field %s is not an integer." % name}


func _parse_hex(value: Variant, expected_length: int, label: String) -> Dictionary:
	if not value is String:
		return {"ok": false, "error": "%s must be a hex string." % label}
	var text_value := String(value).strip_edges().to_lower()
	text_value = text_value.replace("0x", "").replace("$", "")
	for separator: String in [" ", "\t", "\n", "\r", ":", "-", "_"]:
		text_value = text_value.replace(separator, "")
	if text_value.length() % 2 != 0:
		return {"ok": false, "error": "%s has an odd number of hex digits." % label}
	var output := PackedByteArray()
	for offset: int in range(0, text_value.length(), 2):
		var high := _hex_nibble(text_value.substr(offset, 1))
		var low := _hex_nibble(text_value.substr(offset + 1, 1))
		if high < 0 or low < 0:
			return {"ok": false, "error": "%s contains a non-hex character near digit %d." % [label, offset]}
		output.append((high << 4) | low)
	if expected_length >= 0 and output.size() != expected_length:
		return {"ok": false, "error": "%s decoded to %d bytes; expected %d." % [label, output.size(), expected_length]}
	return {"ok": true, "bytes": output}


func _hex_nibble(value: String) -> int:
	return "0123456789abcdef".find(value.to_lower())


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
