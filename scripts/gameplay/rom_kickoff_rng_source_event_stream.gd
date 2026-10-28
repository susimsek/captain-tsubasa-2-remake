extends RefCounted
class_name RomKickoffRngSourceEventStream
## Consumes decoded live RNG call events for a fresh KICK OFF source runner.
## Unlike RomKickoffRngSourceReplay, this stream has no frame schedule or
## recorded input hash. The caller must invoke it at the corresponding ROM
## instruction boundaries and provide the current controller/RAM state.

const ARITHMETIC := preload("res://scripts/gameplay/rom_kickoff_rng_arithmetic.gd")
const A117_PATH := "res://reference/rom_extract/gameplay/rng_arithmetic/a117_rng_update.bin"
const C9C5_PATH := "res://reference/rom_extract/gameplay/rng_arithmetic/c9c5_rng_update.bin"
const RECEIVER_TABLE_PATH := "res://reference/rom_extract/gameplay/menus/first_action_menu/first_match_receiver_offsets_DC82.bin"
const A117_SHA256 := "96d2e722dfb21bf4b41493960cfee8035306d9de9f87a1516da655a2831c5fa9"
const C9C5_SHA256 := "7989c2867a7687a0a79daed64aa10950f5222678cdafa871a7aab8a374f07de0"
const RECEIVER_TABLE_SHA256 := "2784104ad143ec88dc701b76946cf13dfe9bbe799d90e5f4cb00bf97cf5abcb8"
const EXPECTED_A117_BYTES := [0x18, 0xA5, 0xE1, 0x69, 0x83, 0x85, 0xE1, 0xA5, 0xE2, 0x69, 0x0D, 0x85, 0xE2, 0xA5, 0xE3, 0x69, 0x11, 0x85, 0xE3]
const EXPECTED_C9C5_BYTES := [0xAE, 0xE1, 0x00, 0xBD, 0x00, 0x03, 0x7D, 0x00, 0x07, 0x2E, 0xE2, 0x00, 0x49, 0xFF, 0x2E, 0xE2, 0x00, 0x6D, 0xE2, 0x00, 0x8D, 0xE2, 0x00, 0xFD, 0x80, 0x07, 0x6D, 0xE1, 0x00, 0x8D, 0xE3, 0x00, 0xEE, 0xE1, 0x00, 0x60]
const RECEIVER_OFFSETS := [0x05, 0x06, 0x07, 0x09, 0x0A]
const INTERNAL_RAM_SIZE := 0x0800
const RAM_ADDRESS_MASK := 0x07FF

var error_message := ""
var e1 := 0
var e2 := 0
var e3 := 0
var a117_call_count := 0
var c9c5_call_count := 0
var source_event_count := 0
var last_controller_sample := -1
var last_c9c5_operands := Vector3i(-1, -1, -1)
var receiver_slot := -1
var receiver_base_05fb := -1

var _configured := false
var _reset_ready := false
var _receiver_offsets := PackedByteArray()


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_reset_ready = false
	var a117_bytes := _read_hashed_source(A117_PATH, A117_SHA256, 19)
	var c9c5_bytes := _read_hashed_source(C9C5_PATH, C9C5_SHA256, 36)
	var receiver_bytes := _read_hashed_source(RECEIVER_TABLE_PATH, RECEIVER_TABLE_SHA256, 5)
	if a117_bytes.is_empty() or c9c5_bytes.is_empty() or receiver_bytes.is_empty():
		return false
	if a117_bytes != PackedByteArray(EXPECTED_A117_BYTES) or c9c5_bytes != PackedByteArray(EXPECTED_C9C5_BYTES):
		return _fail("RNG source spans differ from the decoded target-ROM instruction sequences.")
	if receiver_bytes != PackedByteArray(RECEIVER_OFFSETS):
		return _fail("Receiver offsets at ROM $DC82 differ from the decoded five-byte table.")
	_receiver_offsets = receiver_bytes
	_configured = true
	return true


## Call only after the live route source runner has executed the ROM cold-reset
## RAM clear. This initializes the source-owned $E1-$E3 tuple; it does not read
## an emulator snapshot or accept a frame number.
func begin_after_rom_cold_reset() -> bool:
	error_message = ""
	if not _configured and not configure_from_project_sources():
		return false
	e1 = 0
	e2 = 0
	e3 = 0
	a117_call_count = 0
	c9c5_call_count = 0
	source_event_count = 0
	last_controller_sample = -1
	last_c9c5_operands = Vector3i(-1, -1, -1)
	receiver_slot = -1
	receiver_base_05fb = -1
	_reset_ready = true
	return true


## Feed one already-decoded bank-$02 controller/NMI path entry at $A117.
## `sampled_controller_state` is the byte sampled by that source input poll;
## the arithmetic does not consume it, but retaining it makes the event stream
## accountable to the caller's decoded input path.
func accept_a117_call(source_bank: int, source_pc: int, nmi_mode_bit_6: int,
		sampled_controller_state: int, pre_call_rng: Vector3i) -> bool:
	error_message = ""
	if not _require_reset_ready():
		return false
	if source_bank != 0x02 or source_pc != 0xA117:
		return _fail("A117 updates require the decoded bank-$02 $A117 instruction event.")
	if nmi_mode_bit_6 != 1:
		return _fail("A117 is valid only for the source NMI path with $001B.6 set.")
	if not _is_byte(sampled_controller_state):
		return _fail("The source controller poll must provide one byte in the range 0..255.")
	if not _pre_call_state_matches(pre_call_rng):
		return false
	var result: Vector4i = ARITHMETIC.step_a117(e1, e2, e3)
	e1 = result.x
	e2 = result.y
	e3 = result.z
	last_controller_sample = sampled_controller_state
	a117_call_count += 1
	source_event_count += 1
	return true


## Feed one normal bank-$1E NMI RNG call at $C9C5. The caller supplies the
## three byte reads made by the ROM at $C9C8 ($0300,X), $C9CB ($0700,X), and
## $C9DC ($0780,X), from its live source memory at this instruction boundary.
## X comes from the verified pre-call E1 state. The bridge does not accept a
## frame ID or bulk RAM image, and does not produce these reads itself. The
## verified normal caller is $C7E4 with carry set and mode bit 6 clear.
func accept_c9c5_call(source_bank: int, source_pc: int, caller_bank: int,
		caller_pc: int, nmi_mode_bit_6: int, incoming_carry: int,
		read_0300_x_at_c9c8: int, read_0700_x_at_c9cb: int,
		read_0780_x_at_c9dc: int, pre_call_rng: Vector3i) -> bool:
	error_message = ""
	if not _require_reset_ready():
		return false
	if source_bank != 0x1E or source_pc != 0xC9C5:
		return _fail("C9C5 updates require the fixed bank-$1E $C9C5 instruction event.")
	if caller_bank != 0x1E or caller_pc != 0xC7E4:
		return _fail("This fresh-route C9C5 path requires the decoded normal-NMI caller at $C7E4.")
	if nmi_mode_bit_6 != 0:
		return _fail("C9C5 is valid only for the normal NMI path with $001B.6 clear.")
	if incoming_carry != 1:
		return _fail("The verified $C7E4 normal-NMI caller enters C9C5 with carry set.")
	if not _pre_call_state_matches(pre_call_rng):
		return false
	if not _is_byte(read_0300_x_at_c9c8) or not _is_byte(read_0700_x_at_c9cb) or \
			not _is_byte(read_0780_x_at_c9dc):
		return _fail("Each decoded C9C5 indexed RAM read must provide one byte in the range 0..255.")
	last_c9c5_operands = Vector3i(read_0300_x_at_c9c8,
		read_0700_x_at_c9cb, read_0780_x_at_c9dc)
	var source_operand_ram := PackedByteArray()
	source_operand_ram.resize(INTERNAL_RAM_SIZE)
	source_operand_ram.fill(0)
	source_operand_ram[0x00E1] = e1
	source_operand_ram[0x00E2] = e2
	source_operand_ram[0x00E3] = e3
	var x := e1
	source_operand_ram[(0x0300 + x) & RAM_ADDRESS_MASK] = read_0300_x_at_c9c8
	source_operand_ram[(0x0700 + x) & RAM_ADDRESS_MASK] = read_0700_x_at_c9cb
	source_operand_ram[(0x0780 + x) & RAM_ADDRESS_MASK] = read_0780_x_at_c9dc
	var result: Vector4i = ARITHMETIC.step_c9c5(e1, e2, e3, incoming_carry, source_operand_ram)
	e1 = result.x
	e2 = result.y
	e3 = result.z
	c9c5_call_count += 1
	source_event_count += 1
	return true


## Execute the ROM receiver-selection formula when decoded execution reaches
## bank-$1E $DB05. The live $05FB byte is supplied by the caller's route state;
## a fresh match uses the source-derived zero base.
func resolve_receiver_at_db05(source_bank: int, source_pc: int,
		source_match_base_05fb: int, pre_call_rng: Vector3i) -> bool:
	error_message = ""
	if not _require_reset_ready():
		return false
	if source_bank != 0x1E or source_pc != 0xDB05:
		return _fail("Receiver selection requires the decoded fixed-bank $DB05 source event.")
	if receiver_slot >= 0:
		return _fail("The source receiver-selection event has already been consumed.")
	if not _is_byte(source_match_base_05fb):
		return _fail("The source match offset $05FB must be a ROM-state byte.")
	if not _pre_call_state_matches(pre_call_rng):
		return false
	var table_index := e2 & 0x07
	if table_index >= _receiver_offsets.size():
		table_index -= _receiver_offsets.size()
	var selected := source_match_base_05fb + int(_receiver_offsets[table_index])
	if selected > 0xFF:
		return _fail("The ROM receiver offset plus source $05FB wraps beyond a byte; this route path is unsupported.")
	receiver_slot = selected
	receiver_base_05fb = source_match_base_05fb
	source_event_count += 1
	return true


func get_receiver_selection() -> Dictionary:
	return {
		"ready": receiver_slot >= 0,
		"receiver_slot": receiver_slot,
		"receiver_base_05fb": receiver_base_05fb,
		"rng_state": Vector3i(e1, e2, e3),
		"a117_call_count": a117_call_count,
		"c9c5_call_count": c9c5_call_count,
		"source_event_count": source_event_count,
	}


func get_source_status() -> Dictionary:
	return {
		"configured": _configured,
		"reset_ready": _reset_ready,
		"source_mode": "caller_fed_decoded_instruction_events",
		"uses_frame_schedule": false,
		"uses_input_timeline_hash": false,
		"c9c5_operand_reads_produced_by_bridge": false,
		"c9c5_input_shape": ["$C9C8:$0300,X", "$C9CB:$0700,X", "$C9DC:$0780,X"],
		"e1": e1,
		"e2": e2,
		"e3": e3,
		"a117_call_count": a117_call_count,
		"c9c5_call_count": c9c5_call_count,
		"source_event_count": source_event_count,
		"last_controller_sample": last_controller_sample,
		"last_c9c5_operands": last_c9c5_operands,
		"receiver_selection": get_receiver_selection(),
		"error": error_message,
	}


func _pre_call_state_matches(pre_call_rng: Vector3i) -> bool:
	if pre_call_rng.x < 0 or pre_call_rng.x > 0xFF or \
			pre_call_rng.y < 0 or pre_call_rng.y > 0xFF or \
			pre_call_rng.z < 0 or pre_call_rng.z > 0xFF:
		return _fail("The decoded source event must provide byte-valued pre-call $E1-$E3.")
	if pre_call_rng != Vector3i(e1, e2, e3):
		return _fail("The caller's pre-call $E1-$E3 conflicts with the event stream; a source event may be missing or duplicated.")
	return true


func _require_reset_ready() -> bool:
	if not _configured and not configure_from_project_sources():
		return false
	if not _reset_ready:
		return _fail("Begin the event stream only after the decoded ROM cold-reset RAM clear.")
	return true


func _read_hashed_source(path: String, expected_hash: String, expected_size: int) -> PackedByteArray:
	if not FileAccess.file_exists(path):
		_fail("ROM-derived RNG source is missing: %s" % path)
		return PackedByteArray()
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.size() != expected_size or _sha256(bytes) != expected_hash:
		_fail("ROM-derived RNG source failed size/hash validation: %s" % path)
		return PackedByteArray()
	return bytes


func _is_byte(value: int) -> bool:
	return value >= 0 and value <= 0xFF


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK:
		return ""
	if context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()


func _fail(message: String) -> bool:
	error_message = message
	return false
