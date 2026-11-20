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
	0x18: "res://reference/rom_extract/gameplay/pass_scenario_18/scenario_18.bin",
	0x1C: "res://reference/rom_extract/gameplay/pass_scenario_1c/scenario_1C.bin",
	0x1E: "res://reference/rom_extract/gameplay/first_command_scenarios/scenario_1E.bin",
	0x2E: "res://reference/rom_extract/gameplay/scenario_2e/scenario_2E.bin",
	0x35: "res://reference/rom_extract/gameplay/first_command_scenarios/scenario_35.bin",
	0x36: "res://reference/rom_extract/gameplay/first_command_scenarios/scenario_36.bin",
	0x38: "res://reference/rom_extract/gameplay/first_command_scenarios/scenario_38.bin",
	0x44: "res://reference/rom_extract/gameplay/first_command_scenarios/scenario_44.bin",
}

const VERIFIED_ROOT_STREAMS: Dictionary = {
	0x18: {"size": 25, "sha256": "8e79217a8131e753b6a194df0ca5eb8e916b11d1bd537c06a4541583161bb81b"},
	0x1C: {"size": 15, "sha256": "68d8512ef76afc90deee499c53952f8cf27d4c4473749a571ef1ed9deca132e2"},
	0x1E: {"size": 10, "sha256": "383f2248d753ef12b325c98238ee1c0eaa96c693ca427a5885536e1c16f1a496"},
	0x2E: {"size": 6, "sha256": "1a8acb72b1adf0fd4059eb2a0a8c27b0e93778b9a3a3a82886aa0818c5722630"},
	0x35: {"size": 8, "sha256": "02848b8b324fe6c120e6eb26bca5d0c08cab23baa91cf7820db454a3f78544df"},
	0x36: {"size": 38, "sha256": "948f05adfcd95e7fe76759534449f31f4194aed3521389934ee793e8f22e367f"},
	0x38: {"size": 7, "sha256": "63ad2f03483843a538c92e33da4917356fce555fb8b69875b042be85fa77bc76"},
	0x44: {"size": 5, "sha256": "22c0290ec8b82bd06eb69bd51a8d8617181cf2c5bbf52b790ea62102e0c71e0f"},
}
const VERIFIED_SCENARIO18_BRANCH := {"size": 8,
	"sha256": "162fe60677bbd4a6f06415055195215d0a39860746a52816598badfc7571cb8a"}

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

const SCENARIO_1C_NESTED_WRAPPER_PATH := \
	"res://reference/rom_extract/gameplay/pass_scenario_1c/bank10_FA_dispatch_wrapper_9F3E_9F54.bin"
const SCENARIO_1C_NESTED_WRAPPER_SHA256 := \
	"e5944e698c99067bb0a5921b8823e977dcd92bcb83c8dcb593bdc49651fd5275"
const SCENARIO_1C_NESTED_WRAPPER_BYTES := [
	0xF3, 0x10, 0x4A, 0x9F, 0x4B, 0xBB, 0x4B, 0xBB, 0x4B, 0xBB, 0x4B,
	0xBB, 0xF3, 0x1E, 0x4B, 0xBB, 0x02, 0xB5, 0x4F, 0xB5, 0x50, 0xBB,
]
const SCENARIO_1C_F2_TARGETS: Dictionary = {
	0xB49E: {"file_offset": 0x0234AE, "bytes": [0xF9, 0x1D, 0x2C, 0x3C, 0x01, 0x78, 0x58, 0xFB],
		"sha256": "1a650937b1815dc4ab5a30a1da70eb4e3c4bad7059005d1fbb585995936db5e2"},
	0xB4B6: {"file_offset": 0x0234C6, "bytes": [0xF9, 0x11, 0x2C, 0x38, 0x63, 0x7A, 0x58, 0xFB],
		"sha256": "c2b1fab616d39995a449dc04d7893b270cb637df53a52ba54954c96de5d42915"},
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
	for key in ["ram_052A", "ram_052B", "ram_0530", "ram_0531", "ram_05FB",
			"ram_0441", "ram_044E", "ram_043B", "ram_043C", "ram_0516", "ram_0638",
			"ram_fd00_mirror_flag"]:
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
			0xFA:
				if scenario_id != 0x1C or not _is_verified_root_stream(scenario_id, source) \
						or offset != 2 or source.size() - offset < 3:
					return _result(ParseStatus.UNSUPPORTED_HANDLER, ParseStatus.UNSUPPORTED_HANDLER,
						scenario_id, tokens, offset,
						"Only the hash-verified scenario-$1C FA $3E $9F nested call is decoded.",
						source_path, context_requirements, ram_state, opcode)
				var target_pointer := int(source[offset + 1]) | (int(source[offset + 2]) << 8)
				if target_pointer != 0x9F3E:
					return _result(ParseStatus.UNSUPPORTED_HANDLER, ParseStatus.UNSUPPORTED_HANDLER,
						scenario_id, tokens, offset,
						"Scenario-$1C FA target is outside the preserved nested dispatch wrapper.",
						source_path, context_requirements, ram_state, opcode)
				var fa_token := _scenario_1c_fa_token(offset, target_pointer,
					context, context_requirements, ram_state)
				tokens.append(fa_token)
				offset += 3
				if str(fa_token.get("status", "")) in [
						"unsupported_handler", "resource_unavailable", "source_integrity_failure"]:
					return _result(ParseStatus.UNSUPPORTED_HANDLER,
						ParseStatus.UNSUPPORTED_HANDLER, scenario_id, tokens, offset,
						str(fa_token.get("error", fa_token.get("reason",
							"Scenario-$1C FA nested dispatch is not supported for this context."))),
						source_path, context_requirements, ram_state, opcode)
			0xF2:
				if source.size() - offset < 3:
					return _result(ParseStatus.TRUNCATED_INPUT, ParseStatus.TRUNCATED_INPUT,
						scenario_id, tokens, offset, "$F2 requires its two-byte target pointer.",
						source_path, context_requirements, ram_state)
				var f2_pointer := int(source[offset + 1]) | (int(source[offset + 2]) << 8)
				var f2_token := {
					"kind": "control_flow",
					"opcode": opcode,
					"byte_offset": offset,
					"length_bytes": 3,
					"operand_bytes": [int(source[offset + 1]), int(source[offset + 2])],
					"target_cpu_address": f2_pointer,
					"handler_cpu_address": 0x80F4,
					"handler_file_offset": 0x020104,
					"handler_bytes": [0xA4, 0x3A, 0xB1, 0x5D, 0xAA, 0xC8, 0xB1, 0x5D,
						0x85, 0x5E, 0x86, 0x5D, 0xA9, 0x00, 0x85, 0x3A, 0x60],
					"verified_effect": "replace $5D/$5E with the little-endian target and clear stream offset $3A",
					"status": "external_continuation_required",
					"target_is_external_to_preserved_span": true,
				}
				if scenario_id == 0x1C and SCENARIO_1C_F2_TARGETS.has(f2_pointer):
					var f2_target: Dictionary = SCENARIO_1C_F2_TARGETS[f2_pointer]
					f2_token["target_file_offset"] = int(f2_target["file_offset"])
					f2_token["target_prefix_bytes"] = f2_target["bytes"]
					f2_token["target_prefix_sha256"] = str(f2_target["sha256"])
				tokens.append(f2_token)
				offset += 3
				return _result(ParseStatus.EXTERNAL_CONTINUATION_REQUIRED,
					ParseStatus.EXTERNAL_CONTINUATION_REQUIRED, scenario_id, tokens, offset,
					"Stopped at the source-proven F2 pointer replacement; target stream execution remains external.",
					source_path, context_requirements, ram_state)
			0xF3:
				if scenario_id == 0x18 and _is_verified_root_stream(scenario_id, source) \
						and offset == 2 and source.size() >= 7 and int(source[offset + 1]) == 0xB4:
					var f3_result := _scenario18_f3_b4_token(offset, source, ram_state, context_requirements)
					tokens.append(f3_result["token"])
					if str(f3_result["status"]) == "context_required":
						return _result(ParseStatus.CONTEXT_REQUIRED, ParseStatus.CONTEXT_REQUIRED,
							scenario_id, tokens, offset + 2,
							"Scenario-$18 `$F3 $B4` needs live RAM `$044E` to choose a source skip branch.",
							source_path, context_requirements, ram_state)
					if str(f3_result["status"]) != "selected":
						return _result(ParseStatus.UNSUPPORTED_HANDLER, ParseStatus.UNSUPPORTED_HANDLER,
							scenario_id, tokens, int(f3_result.get("resume_offset", offset + 2)),
							str(f3_result.get("message", "Unsupported scenario-$18 `$F3 $B4` selector.")),
							source_path, context_requirements, ram_state, opcode)
					offset = int(f3_result["resume_offset"])
					continue
				elif scenario_id == 0x18 and _is_verified_root_stream(scenario_id, source) \
						and offset == 7 and source.size() >= 17 and int(source[offset + 1]) == 0x1E:
					var f3_token := _scenario18_f3_1e_token(offset, source,
						ram_state, context_requirements)
					tokens.append(f3_token)
					if str(f3_token.get("status", "")) == "context_required":
						return _result(ParseStatus.CONTEXT_REQUIRED, ParseStatus.CONTEXT_REQUIRED,
							scenario_id, tokens, offset + 2,
							"Scenario-$18 `$F3 $1E` needs live RAM `$043C` to select its pointer branch.",
							source_path, context_requirements, ram_state)
					if String(f3_token.get("status", "")) == "unsupported_handler":
						return _result(ParseStatus.UNSUPPORTED_HANDLER, ParseStatus.UNSUPPORTED_HANDLER,
							scenario_id, tokens, offset + 2,
							String(f3_token.get("reason", "Unsupported scenario-$18 `$F3 $1E` branch.")),
							source_path, context_requirements, ram_state, opcode)
					return _result(ParseStatus.EXTERNAL_CONTINUATION_REQUIRED,
						ParseStatus.EXTERNAL_CONTINUATION_REQUIRED, scenario_id, tokens, offset + 2,
						"Scenario-$18 `$F3 $1E` selects an external bank-$10 branch target not yet executed.",
						source_path, context_requirements, ram_state)
				elif scenario_id != 0x1C or not _is_verified_root_stream(scenario_id, source) \
						or offset != 5 or source.size() - offset < 2 or int(source[offset + 1]) != 0x84:
					return _result(ParseStatus.UNSUPPORTED_HANDLER, ParseStatus.UNSUPPORTED_HANDLER,
						scenario_id, tokens, offset,
						"Only scenario-$1C root $F3 $84 and its verified branch bytes are decoded.",
						source_path, context_requirements, ram_state, opcode)
				var f3_result := _scenario_1c_f3_84_token(offset, source, ram_state,
					context_requirements)
				tokens.append(f3_result["token"])
				if str(f3_result["status"]) == "context_required":
					return _result(ParseStatus.EXTERNAL_CONTINUATION_REQUIRED,
						ParseStatus.EXTERNAL_CONTINUATION_REQUIRED, scenario_id, tokens,
						offset + 2,
						"F3 $84 alternatives are decoded, but the selected branch requires RAM $044E.",
						source_path, context_requirements, ram_state)
				if str(f3_result["status"]) != "selected":
					return _result(ParseStatus.UNSUPPORTED_HANDLER,
						ParseStatus.UNSUPPORTED_HANDLER, scenario_id, tokens, offset + 2,
						str(f3_result.get("message", "Unsupported scenario-$1C F3 selector result.")),
						source_path, context_requirements, ram_state, opcode)
				offset = int(f3_result["resume_offset"])
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
				var scenario18_branch_validated := scenario_id == 0x18 \
					and _is_verified_scenario18_branch(source)
				var continuation_depth_supplied := context.has("continuation_depth")
				var continuation_depth := int(context.get("continuation_depth", -1))
				var live_empty_scenario18_branch := scenario18_branch_validated \
					and bool(context.get("scenario18_live_terminal_cursor", false))
				var empty_continuation := (source_stream_validated or live_empty_scenario18_branch) \
					and continuation_depth_supplied and continuation_depth == 0
				tokens.append({
					"kind": "control_flow",
					"opcode": opcode,
					"byte_offset": offset,
					"length_bytes": 1,
					"verified_effect": "decrement $0522; restore the saved $051A pointer, or jump to $80CF if the stack is empty",
					"source_bytes": "$8837/file 0x020847: AE 22 05 CA CA 8E 22 05 10 03 4C CF 80 BD 1A 05 85 5D BD 1B 05 85 5E",
					"source_span_validated": source_stream_validated or scenario18_branch_validated,
					"continuation_depth": continuation_depth if continuation_depth_supplied else -1,
					"effect_status": "verified root stream or live scenario-$18 branch cursor with empty caller continuation takes the $80CF terminator" if empty_continuation else "local branch $FB returns through the caller-owned continuation unless a live empty-stack state is supplied",
				})
				offset += 1
				if empty_continuation:
					return _result(ParseStatus.SOURCE_TERMINATED,
						ParseStatus.SOURCE_TERMINATED, scenario_id, tokens, offset,
						"Verified root or live scenario-$18 branch cursor reaches $FB with caller-supplied continuation depth zero.",
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


static func _scenario_1c_fa_token(byte_offset: int, target_pointer: int,
		context: Dictionary, context_requirements: Array[String],
		ram_state: Dictionary) -> Dictionary:
	var token := {
		"kind": "control_flow",
		"opcode": 0xFA,
		"byte_offset": byte_offset,
		"length_bytes": 3,
		"operand_bytes": [0x3E, 0x9F],
		"target_cpu_address": target_pointer,
		"target_file_offset": 0x021F4E,
		"handler_cpu_address": 0x881A,
		"handler_file_offset": 0x02082A,
		"target_loader_cpu_address": 0x80F6,
		"target_loader_file_offset": 0x020106,
		"return_stream_byte_offset": byte_offset + 3,
		"nested_wrapper_path": SCENARIO_1C_NESTED_WRAPPER_PATH,
		"nested_wrapper_sha256": SCENARIO_1C_NESTED_WRAPPER_SHA256,
		"status": "external_continuation_required",
		"execution_status": "static dispatch decoded; nested worker stream is not executed",
	}
	var wrapper_file := FileAccess.open(SCENARIO_1C_NESTED_WRAPPER_PATH, FileAccess.READ)
	if wrapper_file == null:
		token["status"] = "resource_unavailable"
		token["error"] = "Could not open the pinned scenario-$1C nested wrapper resource."
		return token
	var wrapper := wrapper_file.get_buffer(wrapper_file.get_length())
	if wrapper != PackedByteArray(SCENARIO_1C_NESTED_WRAPPER_BYTES) \
			or _sha256_hex(wrapper) != SCENARIO_1C_NESTED_WRAPPER_SHA256:
		token["status"] = "source_integrity_failure"
		token["error"] = "Nested wrapper bytes or SHA-256 differ from the pinned ROM extraction."
		return token
	token["nested_wrapper_bytes"] = wrapper
	var nested_tokens := _scenario_1c_nested_f3_tokens(
		context, context_requirements, ram_state)
	token["f3_dispatch_tokens"] = nested_tokens
	for nested_token: Dictionary in nested_tokens:
		if str(nested_token.get("status", "")) == "unsupported_handler":
			token["status"] = "unsupported_handler"
			token["reason"] = str(nested_token.get("reason", "Unsupported nested F3 selector."))
			break
	return token


static func _scenario_1c_nested_f3_tokens(context: Dictionary,
		context_requirements: Array[String], ram_state: Dictionary) -> Array[Dictionary]:
	var f3_10 := {
		"kind": "control_flow",
		"source_role": "FA target $9F3E",
		"opcode": 0xF3,
		"byte_offset": 0,
		"length_bytes": 2,
		"operand": 0x10,
		"handler_cpu_address": 0x8105,
		"handler_file_offset": 0x020115,
		"selector_cpu_address": 0x816E,
		"selector_dispatch_target_cpu_address": 0x836E,
		"selector_dispatch_target_file_offset": 0x02037E,
		"selector_bytes": [0xA2, 0x00, 0xAD, 0x3B, 0x04, 0xC9, 0x01, 0xF0,
			0x04, 0x20, 0x77, 0x86, 0xE8, 0x60],
		"inline_pointer_table_offset": 2,
		"inline_pointer_targets": [0x9F4A, 0xBB4B, 0xBB4B, 0xBB4B, 0xBB4B],
		"required_context": ["RAM $043B"],
		"status": "context_required",
	}
	var f3_1e := {
		"kind": "control_flow",
		"source_role": "FA target $9F3E, conditional branch at $9F4A",
		"opcode": 0xF3,
		"byte_offset": 12,
		"length_bytes": 2,
		"operand": 0x1E,
		"handler_cpu_address": 0x8105,
		"handler_file_offset": 0x020115,
		"selector_cpu_address": 0x816E,
		"selector_dispatch_target_cpu_address": 0x8401,
		"selector_dispatch_target_file_offset": 0x020411,
		"selector_bytes": [0xAD, 0x3C, 0x04, 0x29, 0x7F, 0xAA, 0x4C, 0x11, 0x82],
		"selector_flag_helper_cpu_address": 0x8211,
		"selector_flag_helper_file_offset": 0x020221,
		"inline_pointer_table_offset": 14,
		"inline_pointer_targets": [0xBB4B, 0xB502, 0xB54F, 0xBB50],
		"required_context": ["RAM $043C"],
		"conditional_on": "F3 $10 returns X=0 from RAM $043B",
		"status": "conditional_context_required",
	}
	var tokens: Array[Dictionary] = [f3_10, f3_1e]
	if not context.has("ram_043B"):
		_add_context_requirement(context_requirements,
			"Scenario-$1C nested F3 $10 needs RAM $043B to select one of five preserved pointers.")
		_add_context_requirement(context_requirements,
			"Scenario-$1C nested F3 $1E needs RAM $043C only if RAM $043B selects the $9F4A branch.")
		f3_10["status"] = "context_required"
		return tokens

	var incoming_043b := int(context["ram_043B"]) & 0xFF
	# The pinned `$836E` helper returns X=0 for `$043B==$01`; otherwise it
	# calls `$8677`, whose selector mapping is not yet decoded for this route.
	# Do not substitute `$043B` itself for the helper's return value.
	if incoming_043b != 0x01:
		f3_10["status"] = "unsupported_handler"
		f3_10["incoming_ram_043B"] = incoming_043b
		f3_10["reason"] = "Only the source-decoded `$043B=$01 -> X=$00` helper path is supported; `$8677` is unresolved."
		return tokens
	var f3_10_index := 0
	var first_target: int = int(f3_10["inline_pointer_targets"][f3_10_index])
	f3_10["incoming_ram_043B"] = incoming_043b
	f3_10["selector_result"] = f3_10_index
	f3_10["selected_target_cpu_address"] = first_target
	f3_10["status"] = "external_continuation_required"
	if first_target != 0x9F4A:
		f3_10["external_branch_target_cpu_address"] = first_target
		return tokens

	if not context.has("ram_043C"):
		_add_context_requirement(context_requirements,
			"Scenario-$1C nested F3 $1E needs RAM $043C after F3 $10 selects $9F4A.")
		return tokens
	var f3_1e_index := int(context["ram_043C"]) & 0x7F
	if f3_1e_index > 3:
		f3_1e["status"] = "unsupported_handler"
		f3_1e["selector_result"] = f3_1e_index
		f3_1e["reason"] = "The pinned inline F3 $1E table has only four entries."
		return tokens
	var second_target: int = int(f3_1e["inline_pointer_targets"][f3_1e_index])
	f3_1e["selector_result"] = f3_1e_index
	f3_1e["selected_target_cpu_address"] = second_target
	f3_1e["status"] = "external_continuation_required"
	if f3_1e_index != 0:
		if context.has("ram_0516"):
			ram_state["ram_0516"] = int(context["ram_0516"]) | 0x04
			f3_1e["ram_effect"] = {"$0516": ram_state["ram_0516"]}
		else:
			_add_context_requirement(context_requirements,
				"Nested F3 $1E selector nonzero sets bit $04 in $0516; incoming RAM $0516 is required to report the resulting byte.")
			f3_1e["status"] = "context_required"
	f3_1e["external_branch_target_cpu_address"] = second_target
	return tokens


static func _scenario_1c_f3_84_token(byte_offset: int, source: PackedByteArray,
		ram_state: Dictionary, context_requirements: Array[String]) -> Dictionary:
	var token := {
		"kind": "control_flow",
		"opcode": 0xF3,
		"byte_offset": byte_offset,
		"operand": 0x84,
		"handler_cpu_address": 0x8105,
		"handler_file_offset": 0x020115,
		"selector_cpu_address": 0x816E,
		"selector_index": 0x04,
		"selector_dispatch_target_cpu_address": 0x8259,
		"selector_dispatch_target_file_offset": 0x020269,
		"selector_handler_bytes": [0xAE, 0x4E, 0x04, 0xF0, 0x01, 0xCA, 0x60],
		"selector_effect": "X=$044E when zero; otherwise X=$044E-1",
		"high_bit_path": true,
		"handler_branch_cpu_address": 0x8110,
		"possible_branch_alternatives": [
			{"ram_044E": [0, 1], "x": 0, "skip_byte_offset": 7,
				"skip_byte": 0x02, "resume_byte_offset": 9, "f2_target_cpu_address": 0xB49E},
			{"ram_044E": [2], "x": 1, "skip_byte_offset": 8,
				"skip_byte": 0x04, "resume_byte_offset": 12, "f2_target_cpu_address": 0xB4B6},
		],
		"required_context": ["RAM $044E"],
		"status": "context_required",
	}
	if not ram_state.has("ram_044E"):
		_add_context_requirement(context_requirements,
			"Scenario-$1C F3 $84 needs incoming RAM $044E to select skip byte $02 or $04; no branch is guessed.")
		return {"token": token, "status": "context_required"}

	var incoming_044e := int(ram_state["ram_044E"]) & 0xFF
	var selector_x := 0 if incoming_044e == 0 else incoming_044e - 1
	if selector_x not in [0, 1]:
		token["status"] = "unsupported_handler"
		token["ram_044E"] = incoming_044e
		token["selector_result_x"] = selector_x
		token["reason"] = "Only X=0/$02 and X=1/$04 branch bytes are inside the pinned scenario-$1C span."
		return {"token": token, "status": "unsupported", "message": str(token["reason"])}
	var skip_byte_offset := byte_offset + 2 + selector_x
	if skip_byte_offset >= source.size():
		token["status"] = "truncated_input"
		return {"token": token, "status": "unsupported", "message": "F3 $84 skip byte lies outside source span."}
	var skip_byte := int(source[skip_byte_offset])
	var resume_offset := skip_byte_offset + skip_byte
	if resume_offset + 3 > source.size() or int(source[resume_offset]) != 0xF2:
		token["status"] = "unsupported_handler"
		token["ram_044E"] = incoming_044e
		token["selector_result_x"] = selector_x
		token["skip_byte_offset"] = skip_byte_offset
		token["skip_byte"] = skip_byte
		token["resume_byte_offset"] = resume_offset
		token["reason"] = "Selected F3 $84 branch does not reach a preserved F2 pointer instruction."
		return {"token": token, "status": "unsupported", "message": str(token["reason"])}
	token["ram_044E"] = incoming_044e
	token["selector_result_x"] = selector_x
	token["skip_byte_offset"] = skip_byte_offset
	token["skip_byte"] = skip_byte
	token["resume_byte_offset"] = resume_offset
	token["selected_f2_pointer"] = int(source[resume_offset + 1]) | (int(source[resume_offset + 2]) << 8)
	token["status"] = "selected"
	return {"token": token, "status": "selected", "resume_offset": resume_offset}


static func _scenario18_f3_b4_token(byte_offset: int, source: PackedByteArray,
		ram_state: Dictionary, context_requirements: Array[String]) -> Dictionary:
	var token := {"kind": "control_flow", "opcode": 0xF3, "byte_offset": byte_offset,
		"length_bytes": 2, "operand": 0xB4, "handler_cpu_address": 0x8105,
		"handler_file_offset": 0x020115, "selector_cpu_address": 0x816E,
		"inline_skip_table_offset": byte_offset + 2,
		"inline_skip_bytes": [0x03, 0x02, 0x0B],
		"possible_branches": [{"ram_044E": 0, "skip_byte_offset": 4, "skip_byte": 0x03, "resume_byte_offset": 7},
			{"ram_044E": 1, "skip_byte_offset": 5, "skip_byte": 0x02, "resume_byte_offset": 7},
			{"ram_044E": 2, "skip_byte_offset": 6, "skip_byte": 0x0B, "resume_byte_offset": 17}],
		"required_context": ["RAM $044E"], "status": "context_required"}
	if not ram_state.has("ram_044E"):
		_add_context_requirement(context_requirements,
			"Scenario-$18 `$F3 $B4` requires live RAM `$044E` to select one of three source skip bytes.")
		return {"token": token, "status": "context_required"}
	var selector := int(ram_state["ram_044E"]) & 0xFF
	if selector not in [0, 1, 2]:
		token["status"] = "unsupported_handler"
		token["ram_044E"] = selector
		token["reason"] = "The pinned scenario-$18 `$F3 $B4` skip table has only three verified entries."
		return {"token": token, "status": "unsupported", "message": String(token["reason"])}
	var skip_offset := byte_offset + 2 + selector
	var skip_byte := int(source[skip_offset])
	var resume_offset := skip_offset + skip_byte
	if resume_offset not in [7, 17] or resume_offset >= source.size():
		token["status"] = "unsupported_handler"
		token["ram_044E"] = selector
		token["skip_byte_offset"] = skip_offset
		token["skip_byte"] = skip_byte
		token["resume_byte_offset"] = resume_offset
		token["reason"] = "Scenario-$18 `$F3 $B4` selected an unverified source cursor."
		return {"token": token, "status": "unsupported", "message": String(token["reason"])}
	token["ram_044E"] = selector
	token["skip_byte_offset"] = skip_offset
	token["skip_byte"] = skip_byte
	token["resume_byte_offset"] = resume_offset
	token["status"] = "selected"
	return {"token": token, "status": "selected", "resume_offset": resume_offset}


static func _scenario18_f3_1e_token(byte_offset: int, source: PackedByteArray,
		ram_state: Dictionary, context_requirements: Array[String]) -> Dictionary:
	var token := {"kind": "control_flow", "opcode": 0xF3, "byte_offset": byte_offset,
		"length_bytes": 2, "operand": 0x1E, "handler_cpu_address": 0x8105,
		"handler_file_offset": 0x020115, "selector_cpu_address": 0x8401,
		"selector_mask": 0x7F, "inline_pointer_table_offset": byte_offset + 2,
		"inline_pointer_targets": [0xAF51, 0xAF59, 0xAF90, 0xAFAA],
		"required_context": ["RAM $043C"], "status": "context_required"}
	if not ram_state.has("ram_043C"):
		_add_context_requirement(context_requirements,
			"Scenario-$18 `$F3 $1E` requires live RAM `$043C` for its four-entry branch table.")
		return token
	var selector := int(ram_state["ram_043C"]) & 0x7F
	if selector > 3:
		token["status"] = "unsupported_handler"
		token["selector_result"] = selector
		token["reason"] = "The pinned scenario-$18 `$F3 $1E` table has four source-verified entries."
		return token
	var target := int(token["inline_pointer_targets"][selector])
	token["selector_result"] = selector
	token["selected_target_cpu_address"] = target
	token["status"] = "external_continuation_required"
	token["external_branch_target_cpu_address"] = target
	if selector != 0:
		if ram_state.has("ram_0516"):
			ram_state["ram_0516"] = int(ram_state["ram_0516"]) | 0x04
			token["ram_effect"] = {"$0516": ram_state["ram_0516"]}
		else:
			_add_context_requirement(context_requirements,
				"Scenario-$18 `$F3 $1E` nonzero selection sets bit `$04` in RAM `$0516`.")
			token["status"] = "context_required"
	return token


static func _sha256_hex(bytes: PackedByteArray) -> String:
	var hashing := HashingContext.new()
	if hashing.start(HashingContext.HASH_SHA256) != OK or hashing.update(bytes) != OK:
		return ""
	return hashing.finish().hex_encode()


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
	if ram_state.has("ram_fd00_mirror_flag"):
		var resolved_flag := int(ram_state["ram_fd00_mirror_flag"]) & 0xFF
		if resolved_flag not in [0x00, 0x40]:
			token["status"] = "unsupported_handler"
			token["reason"] = "The caller-supplied source `$FD $00` result must be `$00` or `$40`."
			return token
		token["has_result"] = true
		token["result"] = resolved_flag
		token["ram_write"] = {"$052A": resolved_flag}
		token["status"] = "transformed"
		token["effect_status"] = "resolved by the caller's hash-checked ROM `$8877->$C50C->$C536` executor"
		return token
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
	# Scenario-$1C's `$B49E` F2 branch is a selected, hash-pinned terminal
	# prefix after the live `$BB4F` `$FB` return restores the zero-depth root
	# cursor. It is not the scenario pointer-table root at `$9BE3`.
	if scenario_id == 0x1C:
		var b49e: Dictionary = SCENARIO_1C_F2_TARGETS[0xB49E]
		if source.size() == 8 and _sha256_hex(source) == str(b49e["sha256"]):
			return true
	if not VERIFIED_ROOT_STREAMS.has(scenario_id):
		return false
	var expected: Dictionary = VERIFIED_ROOT_STREAMS[scenario_id]
	if source.size() != int(expected["size"]):
		return false
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(source) != OK:
		return false
	return context.finish().hex_encode() == str(expected["sha256"])


static func _is_verified_scenario18_branch(source: PackedByteArray) -> bool:
	if source.size() != int(VERIFIED_SCENARIO18_BRANCH["size"]):
		return false
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(source) != OK:
		return false
	return context.finish().hex_encode() == str(VERIFIED_SCENARIO18_BRANCH["sha256"])


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
