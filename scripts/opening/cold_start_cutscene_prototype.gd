extends RefCounted
class_name ColdStartCutscenePrototype
## Isolated semantic prototype for the first ROM cutscene segment.
##
## Command bytes and addresses come from the byte-verified extracted cutscene
## manifest. No ROM or emulator is opened at runtime. This class models command
## state only; it is not wired to the playable scene and does not render pixels.

const SEQUENCE_PATH := "res://assets/opening/rom_logic/tecmotheater_logo_sequence.json"

enum CommandKind {
	VISUAL_PRESET,
	BACKGROUND_LOAD,
	ANIMATIONS_LOAD,
	SCREEN_ON,
	WAIT_FRAMES,
	SCREEN_OFF_CLEAR,
}

const KIND_BY_NAME: Dictionary = {
	"visual_preset": CommandKind.VISUAL_PRESET,
	"background_load": CommandKind.BACKGROUND_LOAD,
	"animations_load": CommandKind.ANIMATIONS_LOAD,
	"screen_on": CommandKind.SCREEN_ON,
	"wait_frames": CommandKind.WAIT_FRAMES,
	"screen_off_clear": CommandKind.SCREEN_OFF_CLEAR,
}


class RomCommand extends RefCounted:
	var kind: int = CommandKind.WAIT_FRAMES
	var opcode: int = 0
	var argument_bytes: PackedByteArray = PackedByteArray()
	var source_file_offset: String = ""
	var source_cpu_address: String = ""
	var raw_hex: String = ""
	var preset_id: int = -1
	var background_id: int = -1
	var background_variant: int = -1
	var animation_ids: Array[int] = []
	var wait_ticks: int = 0


class VmState extends RefCounted:
	## A script tick counter, not a guaranteed physical NES frame count.
	var script_ticks_elapsed: int = 0
	var command_index: int = 0
	var wait_ticks_remaining: int = 0
	var visual_preset_id: int = -1
	var background_id: int = -1
	var background_variant: int = -1
	var animation_ids: Array[int] = []
	var screen_enabled: bool = false
	var clear_requested: bool = false
	var sequence_complete: bool = false


var commands: Array[RomCommand] = []
var state: VmState = VmState.new()
var source_rom_sha256: String = ""
var source_script_sha256: String = ""


static func from_project_data() -> ColdStartCutscenePrototype:
	var file := FileAccess.open(SEQUENCE_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not open ROM cutscene prototype data: %s" % SEQUENCE_PATH)
		return null

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		push_error("ROM cutscene prototype data must be a JSON object.")
		return null
	return from_dictionary(parsed)


static func from_dictionary(data: Dictionary) -> ColdStartCutscenePrototype:
	var prototype := ColdStartCutscenePrototype.new()
	prototype.source_rom_sha256 = str(data.get("rom_sha256", ""))
	var cutscene_source: Variant = data.get("source_cutscene", {})
	if cutscene_source is Dictionary:
		prototype.source_script_sha256 = str(cutscene_source.get("script_sha256", ""))

	var raw_commands: Variant = data.get("commands", [])
	if not (raw_commands is Array):
		push_error("ROM cutscene prototype commands must be an array.")
		return null

	for raw_command: Variant in raw_commands:
		if not (raw_command is Dictionary):
			push_error("Each ROM cutscene command must be an object.")
			return null
		var command := _parse_command(raw_command)
		if command == null:
			return null
		prototype.commands.append(command)
	return prototype


static func _parse_command(raw: Dictionary) -> RomCommand:
	var kind_name := str(raw.get("kind", ""))
	if not KIND_BY_NAME.has(kind_name):
		push_error("Unsupported ROM cutscene prototype command: %s" % kind_name)
		return null

	var command := RomCommand.new()
	command.kind = KIND_BY_NAME[kind_name]
	command.opcode = int(raw.get("opcode", 0))
	command.source_file_offset = str(raw.get("source_file_offset", ""))
	command.source_cpu_address = str(raw.get("source_cpu_address", ""))
	command.raw_hex = str(raw.get("raw_hex", ""))
	var raw_arguments: Variant = raw.get("argument_bytes", [])
	if not (raw_arguments is Array):
		push_error("ROM command argument_bytes must be an array.")
		return null
	for argument: Variant in raw_arguments:
		command.argument_bytes.append(int(argument) & 0xFF)

	command.preset_id = int(raw.get("preset_id", -1))
	command.background_id = int(raw.get("background_id", -1))
	command.background_variant = int(raw.get("background_variant", -1))
	command.wait_ticks = int(raw.get("wait_ticks", 0))
	var raw_animation_ids: Variant = raw.get("animation_ids", [])
	if raw_animation_ids is Array:
		for animation_id: Variant in raw_animation_ids:
			command.animation_ids.append(int(animation_id))
	return command


func begin() -> VmState:
	state = VmState.new()
	_consume_until_wait_or_end()
	return state


func advance_one_frame() -> VmState:
	if state.sequence_complete:
		return state

	if state.wait_ticks_remaining > 0:
		state.script_ticks_elapsed += 1
		state.wait_ticks_remaining -= 1
		if state.wait_ticks_remaining == 0:
			_consume_until_wait_or_end()
	return state


func _consume_until_wait_or_end() -> void:
	while state.command_index < commands.size():
		var command := commands[state.command_index]
		state.command_index += 1
		match command.kind:
			CommandKind.VISUAL_PRESET:
				state.visual_preset_id = command.preset_id
			CommandKind.BACKGROUND_LOAD:
				state.background_id = command.background_id
				state.background_variant = command.background_variant
			CommandKind.ANIMATIONS_LOAD:
				state.animation_ids = command.animation_ids.duplicate()
			CommandKind.SCREEN_ON:
				state.screen_enabled = true
				state.clear_requested = false
			CommandKind.WAIT_FRAMES:
				state.wait_ticks_remaining = command.wait_ticks
				return
			CommandKind.SCREEN_OFF_CLEAR:
				state.screen_enabled = false
				state.clear_requested = true
				state.sequence_complete = true
				return
	state.sequence_complete = true
