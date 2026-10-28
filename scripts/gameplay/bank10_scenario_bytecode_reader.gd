extends RefCounted
class_name Bank10ScenarioBytecodeReader
## Reads the preserved fresh-route bank-$10 scenario streams. It applies only
## byte-verified inline record transforms and route opcodes; it does not run
## worker scheduling or infer frame timing.
##
## Primary source: reference/rom_extract/gameplay/scenario_interpreter_kickoff_rng_audit_20261027.md
## Transform source: reference/rom_extract/gameplay/first_command_actor_fd_mirror_transform_audit_20261027.md
## ROM SHA-256: 4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097
## Scenario reader entry $803F is at file 0x02004F. Inline record handlers are
## $8991/$899C/$89A7 at file 0x0209A1/0x0209AC/0x0209B7. FD dispatch is $886A
## at file 0x02087A; its route handler $88B5 is at file 0x0208C5.

enum ParseStatus {
	PARSED_TO_SPAN_END,
	EXTERNAL_CONTINUATION_REQUIRED,
	UNSUPPORTED_HANDLER,
	UNSUPPORTED_TRANSFORM,
	TRUNCATED_INPUT,
	INVALID_SCENARIO_ID,
	RESOURCE_UNAVAILABLE,
	CONTEXT_REQUIRED,
	SOURCE_TERMINATED,
}

const SOURCE_PATHS: Dictionary = {
	0x1E: "res://reference/rom_extract/gameplay/first_command_scenarios/scenario_1E.bin",
	0x35: "res://reference/rom_extract/gameplay/first_command_scenarios/scenario_35.bin",
	0x36: "res://reference/rom_extract/gameplay/first_command_scenarios/scenario_36.bin",
	0x44: "res://reference/rom_extract/gameplay/first_command_scenarios/scenario_44.bin",
}

const VERIFIED_ROOT_STREAMS: Dictionary = {
	0x1E: {"size": 10, "sha256": "383f2248d753ef12b325c98238ee1c0eaa96c693ca427a5885536e1c16f1a496"},
	0x35: {"size": 8, "sha256": "02848b8b324fe6c120e6eb26bca5d0c08cab23baa91cf7820db454a3f78544df"},
	0x36: {"size": 38, "sha256": "948f05adfcd95e7fe76759534449f31f4194aed3521389934ee793e8f22e367f"},
	0x44: {"size": 5, "sha256": "22c0290ec8b82bd06eb69bd51a8d8617181cf2c5bbf52b790ea62102e0c71e0f"},
}

const RECORD_FIELD_DESTINATIONS: Array[String] = ["$0523", "$0524", "$0528", "$0529"]
const RECORD_TRANSFORMERS: Dictionary = {
	1: {"cpu_address": 0x8991, "file_offset": 0x0209A1, "table_file_offset": 0x0209A7, "table_bytes": [0x99, 0x89], "index_zero_target": 0x8999, "target_file_offset": 0x0209A9, "target_bytes": [0xA9, 0xFF, 0x60]},
	2: {"cpu_address": 0x899C, "file_offset": 0x0209AC, "table_file_offset": 0x0209B2, "table_bytes": [0xA4, 0x89], "index_zero_target": 0x89A4, "target_file_offset": 0x0209B4, "target_bytes": [0xA9, 0xFF, 0x60]},
	3: {"cpu_address": 0x89A7, "file_offset": 0x0209B7, "table_file_offset": 0x0209BD, "table_bytes": [0xB1, 0x89], "index_zero_target": 0x89B1, "target_file_offset": 0x0209C1, "target_bytes": [0xA9, 0xFF, 0x60]},
}

const FD_HANDLER_TARGETS: Dictionary = {
	0x00: {"cpu_address": 0x8877, "file_offset": 0x020887},
	0x02: {"cpu_address": 0x88B5, "file_offset": 0x0208C5},
}


static func read_project_scenario(scenario_id: int, context: Dictionary = {}) -> Dictionary:
	if not SOURCE_PATHS.has(scenario_id):
		return _result(ParseStatus.INVALID_SCENARIO_ID, ParseStatus.INVALID_SCENARIO_ID,
			scenario_id, [], 0, "No preserved bank-$10 source stream is registered for this ID.")
	var source_path: String = SOURCE_PATHS[scenario_id]
	var file := FileAccess.open(source_path, FileAccess.READ)
	if file == null:
		return _result(ParseStatus.RESOURCE_UNAVAILABLE, ParseStatus.RESOURCE_UNAVAILABLE,
			scenario_id, [], 0, "Could not open preserved scenario source: %s" % source_path)
	var bytes := file.get_buffer(file.get_length())
	return parse_bytes(scenario_id, bytes, source_path, context)


static func parse_bytes(scenario_id: int, source: PackedByteArray,
		source_path: String = "", context: Dictionary = {}) -> Dictionary:
	if not SOURCE_PATHS.has(scenario_id):
		return _result(ParseStatus.INVALID_SCENARIO_ID, ParseStatus.INVALID_SCENARIO_ID,
			scenario_id, [], 0, "Scenario ID is outside the preserved fresh-route set.", source_path)

	var tokens: Array[Dictionary] = []
	var context_requirements: Array[String] = []
	var ram_state: Dictionary = {}
	for key in ["ram_052A", "ram_052B", "ram_0530", "ram_0531", "ram_05FB"]:
		if context.has(key):
			ram_state[key] = int(context[key]) & 0xFF

	var offset := 0
	while offset < source.size():
		var opcode_or_first_field := int(source[offset])
		if opcode_or_first_field < 0xF0:
			if source.size() - offset < 4:
				return _result(ParseStatus.TRUNCATED_INPUT, ParseStatus.TRUNCATED_INPUT,
					scenario_id, tokens, offset,
					"A record beginning below $F0 needs exactly four source bytes.", source_path,
					context_requirements, ram_state)
			var raw_record := PackedByteArray([
				source[offset], source[offset + 1], source[offset + 2], source[offset + 3]
			])
			var resolved_values: Array[int] = [
				int(raw_record[0]), int(raw_record[1]), int(raw_record[2]), int(raw_record[3])
			]
			var transformations: Array[Dictionary] = []
			for field_index in range(1, 4):
				var transform := _transform_record_field(field_index, int(raw_record[field_index]))
				transform["field_index_zero_based"] = field_index
				transform["destination"] = RECORD_FIELD_DESTINATIONS[field_index]
				transformations.append(transform)
				if str(transform["status"]) == "unsupported_transform":
					tokens.append(_make_record_token(offset, raw_record, resolved_values, transformations))
					return _result(ParseStatus.UNSUPPORTED_TRANSFORM, ParseStatus.UNSUPPORTED_TRANSFORM,
						scenario_id, tokens, offset + 4,
						"A route field uses an inline transformer index not verified for this reader.",
						source_path, context_requirements, ram_state)
				if str(transform["status"]) == "transformed":
					resolved_values[field_index] = int(transform["value"])

			var record_token := _make_record_token(offset, raw_record, resolved_values, transformations)
			tokens.append(record_token)
			for field_index in range(4):
				ram_state["ram_%s" % RECORD_FIELD_DESTINATIONS[field_index].trim_prefix("$")] = resolved_values[field_index]
			offset += 4
			continue

		var opcode := opcode_or_first_field
		match opcode:
			0xF4:
				ram_state["ram_052A"] = 0x40
				tokens.append({
					"kind": "opcode",
					"opcode": opcode,
					"byte_offset": offset,
					"length_bytes": 1,
					"ram_write": {"$052A": 0x40},
					"handler_cpu_address": 0x87E0,
					"handler_file_offset": 0x0207F0,
					"handler_bytes": [0xA9, 0x40, 0x8D, 0x2A, 0x05, 0x60],
					"effect_status": "ROM $87E0 writes immediate $40 to $052A",
				})
				offset += 1
			0xF5:
				ram_state["ram_052A"] = 0x00
				tokens.append({
					"kind": "opcode",
					"opcode": opcode,
				"byte_offset": offset,
				"length_bytes": 1,
				"ram_write": {"$052A": 0x00},
					"handler_cpu_address": 0x87E6,
					"handler_file_offset": 0x0207F6,
					"handler_bytes": [0xA9, 0x00, 0x8D, 0x2A, 0x05, 0x60],
				"effect_status": "ROM $87E6 writes immediate zero to $052A; file 0x0207F6 contains A9 00 8D 2A 05 60",
				})
				offset += 1
			0xF6:
				var flag_effect := {"operation": "xor", "mask": 0x40}
				if ram_state.has("ram_052A"):
					var toggled := int(ram_state["ram_052A"]) ^ 0x40
					ram_state["ram_052A"] = toggled
					flag_effect["result"] = toggled
				else:
					_add_context_requirement(context_requirements,
						"$F6 at +0x%04X needs the incoming value of RAM $052A to report its XOR-$40 result." % offset)
				tokens.append({
					"kind": "opcode",
					"opcode": opcode,
					"byte_offset": offset,
					"length_bytes": 1,
					"ram_effect": flag_effect,
					"handler_cpu_address": 0x87EC,
					"handler_file_offset": 0x0207FC,
					"handler_bytes": [0xA9, 0x40, 0x4D, 0x2A, 0x05, 0x8D, 0x2A, 0x05, 0x60],
					"effect_status": "ROM $87EC applies EOR #$40 to $052A; file 0x0207FC contains A9 40 4D 2A 05 8D 2A 05 60",
				})
				offset += 1
			0xF7:
				if source.size() - offset < 2:
					return _result(ParseStatus.TRUNCATED_INPUT, ParseStatus.TRUNCATED_INPUT,
						scenario_id, tokens, offset, "$F7 requires its one-byte operand.",
						source_path, context_requirements, ram_state)
				var byte_operand := int(source[offset + 1])
				ram_state["ram_052B"] = byte_operand
				tokens.append({
					"kind": "opcode",
					"opcode": opcode,
					"byte_offset": offset,
					"length_bytes": 2,
					"operand": byte_operand,
					"ram_write": {"$052B": byte_operand},
					"handler_cpu_address": 0x87F5,
					"handler_file_offset": 0x020805,
					"handler_bytes": [0xA4, 0x3A, 0xE6, 0x3A, 0xB1, 0x5D, 0x8D, 0x2B, 0x05, 0x60],
					"effect_status": "ROM $87F5 reads the next stream byte to $052B; file 0x020805 contains A4 3A E6 3A B1 5D 8D 2B 05 60",
				})
				offset += 2
			0xF9:
				if source.size() - offset < 3:
					return _result(ParseStatus.TRUNCATED_INPUT, ParseStatus.TRUNCATED_INPUT,
						scenario_id, tokens, offset, "$F9 requires its two-byte word operand.",
						source_path, context_requirements, ram_state)
				var low_byte := int(source[offset + 1])
				var high_byte := int(source[offset + 2])
				var word_value := low_byte | (high_byte << 8)
				ram_state["ram_0530"] = low_byte
				ram_state["ram_0531"] = high_byte
				tokens.append({
					"kind": "opcode",
					"opcode": opcode,
					"byte_offset": offset,
					"length_bytes": 3,
					"operand_bytes": [low_byte, high_byte],
					"operand_word_little_endian": word_value,
					"ram_write": {"$0530": low_byte, "$0531": high_byte},
					"handler_cpu_address": 0x8809,
					"handler_file_offset": 0x020819,
					"handler_bytes": [0xA4, 0x3A, 0xB1, 0x5D, 0x8D, 0x30, 0x05, 0xC8, 0xB1, 0x5D, 0x8D, 0x31, 0x05],
					"effect_status": "ROM $8809 reads stream bytes to $0530/$0531; file 0x020819 contains A4 3A B1 5D 8D 30 05 C8 B1 5D 8D 31 05",
				})
				offset += 3
			0xFD:
				if source.size() - offset < 2:
					return _result(ParseStatus.TRUNCATED_INPUT, ParseStatus.TRUNCATED_INPUT,
						scenario_id, tokens, offset, "$FD requires its one-byte operand.",
						source_path, context_requirements, ram_state)
				var fd_operand := int(source[offset + 1])
				var fd_result := _transform_fd_operand(fd_operand, ram_state, context_requirements, offset)
				if str(fd_result["status"]) == "unsupported_handler":
					tokens.append(fd_result)
					return _result(ParseStatus.UNSUPPORTED_HANDLER, ParseStatus.UNSUPPORTED_HANDLER,
						scenario_id, tokens, offset + 2,
						"This route-specific FD handler has not been byte-decoded.", source_path,
						context_requirements, ram_state, fd_operand)
				if bool(fd_result["has_result"]):
					ram_state["ram_052A"] = int(fd_result["result"])
				else:
					ram_state.erase("ram_052A")
				tokens.append(fd_result)
				offset += 2
			0xFB:
				var source_stream_validated := _is_verified_root_stream(scenario_id, source)
				var continuation_depth_supplied := context.has("continuation_depth")
				var continuation_depth := int(context.get("continuation_depth", -1))
				var root_terminated := source_stream_validated and continuation_depth_supplied and continuation_depth == 0
				tokens.append({
					"kind": "control_flow",
					"opcode": opcode,
					"byte_offset": offset,
					"length_bytes": 1,
					"verified_effect": "decrement $0522; restore the saved $051A pointer, or jump to $80CF if the stack is empty",
					"source_bytes": "$8837/file 0x020847: AE 22 05 CA CA 8E 22 05 10 03 4C CF 80 BD 1A 05 85 5D BD 1B 05 85 5E",
					"source_span_validated": source_stream_validated,
					"continuation_depth": continuation_depth if continuation_depth_supplied else -1,
					"effect_status": "exact route root stream and caller-supplied depth zero take the $80CF terminator" if root_terminated else "return control flow remains external because the stream or caller-owned continuation depth is not a validated root state",
				})
				offset += 1
				if root_terminated:
					return _result(ParseStatus.SOURCE_TERMINATED,
						ParseStatus.SOURCE_TERMINATED, scenario_id, tokens, offset,
						"Validated route source ends at $FB with caller-supplied continuation depth zero.",
						source_path, context_requirements, ram_state)
				return _result(ParseStatus.EXTERNAL_CONTINUATION_REQUIRED,
					ParseStatus.EXTERNAL_CONTINUATION_REQUIRED, scenario_id, tokens, offset,
					"Stopped at $FB because a non-root continuation or validated root-depth input was not supplied.",
					source_path, context_requirements, ram_state)
			_:
				return _result(ParseStatus.UNSUPPORTED_HANDLER, ParseStatus.UNSUPPORTED_HANDLER,
					scenario_id, tokens, offset,
					"Opcode $%02X has no route handler implemented from verified target-ROM bytes." % opcode,
					source_path, context_requirements, ram_state, opcode)

	return _result(ParseStatus.PARSED_TO_SPAN_END, ParseStatus.PARSED_TO_SPAN_END,
		scenario_id, tokens, offset, "Recognized source bytes ended at the preserved span boundary.",
		source_path, context_requirements, ram_state)


static func _make_record_token(byte_offset: int, raw_record: PackedByteArray,
		resolved_values: Array[int], transformations: Array[Dictionary]) -> Dictionary:
	var assignments: Dictionary = {}
	for field_index in range(4):
		assignments[RECORD_FIELD_DESTINATIONS[field_index]] = resolved_values[field_index]
	return {
		"kind": "event_record",
		"byte_offset": byte_offset,
		"raw_bytes": raw_record,
		"ram_assignments_before_inline_transformers": {
			"$0523": int(raw_record[0]),
			"$0524": int(raw_record[1]),
			"$0528": int(raw_record[2]),
			"$0529": int(raw_record[3]),
		},
		"ram_assignments": assignments,
		"transformations": transformations,
		"effect_status": "four-byte record fields and inline transforms are decoded; cooperative worker effects are not executed",
	}


static func _transform_record_field(field_index: int, raw_operand: int) -> Dictionary:
	if raw_operand < 0xF0:
		return {"status": "direct", "raw_operand": raw_operand, "value": raw_operand}
	var info: Dictionary = RECORD_TRANSFORMERS[field_index]
	var result := {
		"raw_operand": raw_operand,
		"transformer_cpu_address": int(info["cpu_address"]),
		"transformer_file_offset": int(info["file_offset"]),
		"dispatch_index": raw_operand - 0xF0,
		"inline_table_file_offset": int(info["table_file_offset"]),
		"inline_table_bytes": info["table_bytes"],
	}
	if raw_operand != 0xF0:
		result["status"] = "unsupported_transform"
		result["reason"] = "Only dispatch index zero is present in the preserved route records; no other table target is assumed."
		return result
	result["status"] = "transformed"
	result["dispatch_target_cpu_address"] = int(info["index_zero_target"])
	result["dispatch_target_file_offset"] = int(info["target_file_offset"])
	result["dispatch_target_bytes"] = info["target_bytes"]
	result["value"] = 0xFF
	result["evidence"] = "C509 index-zero inline pointer resolves to LDA #$FF; RTS in the target ROM."
	return result


static func _transform_fd_operand(operand: int, ram_state: Dictionary,
		context_requirements: Array[String], byte_offset: int) -> Dictionary:
	if not FD_HANDLER_TARGETS.has(operand):
		return {
			"kind": "opcode",
			"opcode": 0xFD,
			"byte_offset": byte_offset,
			"length_bytes": 2,
			"operand": operand,
			"status": "unsupported_handler",
			"handler_target_known": false,
		}
	var handler: Dictionary = FD_HANDLER_TARGETS[operand]
	var token := {
		"kind": "opcode",
		"opcode": 0xFD,
		"byte_offset": byte_offset,
		"length_bytes": 2,
		"operand": operand,
		"transform_dispatch_cpu_address": 0x886A,
		"transform_dispatch_file_offset": 0x02087A,
		"dispatch_table_file_offset": 0x02087D,
		"dispatch_table_entry_bytes": [0x77, 0x88] if operand == 0x00 else [0xB5, 0x88],
		"handler_target_cpu_address": int(handler["cpu_address"]),
		"handler_target_file_offset": int(handler["file_offset"]),
		"fd_handler_cpu_address": 0x885D,
		"fd_handler_file_offset": 0x02086D,
		"fd_handler_bytes": [0xA4, 0x3A, 0xE6, 0x3A, 0xB1, 0x5D, 0x20, 0x6A, 0x88, 0x8E, 0x2A, 0x05, 0x60],
		"destination": "$052A",
		"has_result": false,
	}
	if operand == 0x02:
		token["status"] = "context_required"
		token["handler_bytes"] = [0xA2, 0x00, 0xAD, 0xFB, 0x05, 0xF0, 0x02, 0xA2, 0x40, 0x60]
		token["verified_effect"] = "return X=$00 when $05FB=$00, otherwise X=$40; caller stores X into $052A"
		if ram_state.has("ram_05FB"):
			var result := 0x00 if int(ram_state["ram_05FB"]) == 0 else 0x40
			token["has_result"] = true
			token["result"] = result
			token["status"] = "transformed"
			token["effect_status"] = "applied using caller-supplied $05FB context"
		else:
			_add_context_requirement(context_requirements,
				"$FD $02 at +0x%04X needs incoming RAM $05FB; ROM handler $88B5 branches directly on it." % byte_offset)
			token["effect_status"] = "raw operand and handler are known; output requires caller-supplied RAM $05FB"
		return token

	# Operand $00 routes through $8877, which reads the ball holder and its
	# player record, then compares values involving $0638. That context is not
	# represented by this byte-only reader, so preserve the operand and stop short
	# of manufacturing the mirror result.
	token["handler_bytes_prefix"] = [0xA9, 0x00, 0x85, 0x3B, 0xAD, 0x41, 0x04, 0x20, 0x0C, 0xC5, 0xAD, 0x38, 0x06, 0x20, 0x36, 0xC5]
	token["status"] = "context_required"
	token["verified_effect"] = "handler reads RAM $0441, resolves its player record through $C50C, and uses RAM $0638 through $C536 before returning X"
	token["required_context"] = ["RAM $0441", "resolved player-record fields", "RAM $0638"]
	token["effect_status"] = "context_required; raw operand retained and result not guessed"
	_add_context_requirement(context_requirements,
		"$FD $00 at +0x%04X requires RAM $0441, the player record resolved through $C50C, and RAM $0638 used via $C536." % byte_offset)
	return token


static func _add_context_requirement(requirements: Array[String], message: String) -> void:
	if not requirements.has(message):
		requirements.append(message)


static func status_name(status: int) -> String:
	match status:
		ParseStatus.PARSED_TO_SPAN_END:
			return "parsed_to_span_end"
		ParseStatus.EXTERNAL_CONTINUATION_REQUIRED:
			return "external_continuation_required"
		ParseStatus.UNSUPPORTED_HANDLER:
			return "unsupported_handler"
		ParseStatus.UNSUPPORTED_TRANSFORM:
			return "unsupported_transform"
		ParseStatus.TRUNCATED_INPUT:
			return "truncated_input"
		ParseStatus.INVALID_SCENARIO_ID:
			return "invalid_scenario_id"
		ParseStatus.RESOURCE_UNAVAILABLE:
			return "resource_unavailable"
		ParseStatus.CONTEXT_REQUIRED:
			return "context_required"
		ParseStatus.SOURCE_TERMINATED:
			return "source_terminated"
	return "unknown_status"


static func _is_verified_root_stream(scenario_id: int, source: PackedByteArray) -> bool:
	if not VERIFIED_ROOT_STREAMS.has(scenario_id):
		return false
	var expected: Dictionary = VERIFIED_ROOT_STREAMS[scenario_id]
	if source.size() != int(expected["size"]):
		return false
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(source) != OK:
		return false
	return context.finish().hex_encode() == str(expected["sha256"])


static func _result(status: int, terminal_status: int, scenario_id: int,
		tokens: Array[Dictionary], byte_offset: int, message: String,
		source_path: String = "", context_requirements: Array[String] = [],
		ram_state: Dictionary = {}, unsupported_opcode: int = -1) -> Dictionary:
	var public_status := status
	if not context_requirements.is_empty() and status in [
		ParseStatus.PARSED_TO_SPAN_END,
		ParseStatus.EXTERNAL_CONTINUATION_REQUIRED,
		ParseStatus.SOURCE_TERMINATED,
	]:
		public_status = ParseStatus.CONTEXT_REQUIRED
	return {
		"status": public_status,
		"status_name": status_name(public_status),
		"terminal_status": terminal_status,
		"terminal_status_name": status_name(terminal_status),
		"scenario_id": scenario_id,
		"source_path": source_path,
		"tokens": tokens,
		"next_byte_offset": byte_offset,
		"unsupported_opcode": unsupported_opcode,
		"context_required": not context_requirements.is_empty(),
		"context_requirements": context_requirements.duplicate(),
		"ram_state": ram_state.duplicate(true),
		"message": message,
	}
