extends RefCounted
class_name RomGameplaySchedulerScanModel
## Diagnostic-only model of the fixed-bank scheduler's six-slot ready scan.
## It is not referenced by gameplay runtime and does not emulate CPU/NMI timing.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_PATH := "res://reference/rom_extract/gameplay/task_context/fixed_task_scheduler_CA97_CAE6.bin"
const SOURCE_OFFSET := 0x03CAA7
const SOURCE_LENGTH := 80
const SOURCE_SHA256 := "3768ab8ac0aaeace9d3d53cf92cb8fea9363c400d6b8d4a40b77619c9900c6d8"
const SCAN_PREFIX_LENGTH := 34
const READY_SENTINEL := 0xFF
const NMI_READY_MASK := 0x80
const NMI_CLEAR_MASK := 0x7F
const SLOT_BASES := [0x01, 0x05, 0x09, 0x0D, 0x11, 0x15]

enum Decision {
	INITIAL_DISPATCH,
	YIELDED_RESUME,
	WAIT_FOR_NMI_READY,
	CLEAR_NMI_AND_RESCAN,
}

var error_message := ""
var _configured := false


static func source_span_spec() -> Dictionary:
	return {
		"path": SOURCE_PATH,
		"offset": SOURCE_OFFSET,
		"length": SOURCE_LENGTH,
		"sha256": SOURCE_SHA256,
	}


static func slot_bases() -> Array[int]:
	var result: Array[int] = []
	for base: int in SLOT_BASES:
		result.append(base)
	return result


## The preserved 80-byte span is hash-checked, then its scheduler instructions
## are checked against the supplied ROM's scan/gate control-flow signature.
func configure(source_bytes: PackedByteArray) -> bool:
	error_message = ""
	_configured = false
	if source_bytes.size() != SOURCE_LENGTH:
		return _fail("Preserved scheduler ROM span has an unexpected size.")
	if _sha256(source_bytes) != SOURCE_SHA256:
		return _fail("Preserved scheduler ROM span failed its source hash check.")
	if source_bytes.size() < SCAN_PREFIX_LENGTH:
		return _fail("Preserved scheduler span omits the scan/gate code.")
	var scan_bytes := source_bytes.slice(0, SCAN_PREFIX_LENGTH)
	if scan_bytes != _expected_scan_bytes():
		return _fail("Scheduler scan/gate opcodes differ from the audited source sequence.")
	if not _verify_relative_branch_targets(scan_bytes):
		return false
	_configured = true
	return true


## Runs one bounded scheduler pass over six ready/delay bytes. The returned
## copy shows only mutations made by the ROM scan; caller input is unchanged.
## `$001B.7` is consulted only after all six records were examined.
func scan_once(ready_delays: PackedByteArray, ready_latch_001b: int) -> Dictionary:
	if not _configured:
		_fail("Configure the hash-checked scheduler source before scanning.")
		return {}
	if ready_delays.size() != SLOT_BASES.size():
		_fail("A scheduler scan requires one ready/delay byte for each of six slots.")
		return {}
	if ready_latch_001b < 0 or ready_latch_001b > 0xFF:
		_fail("The `$001B` latch input must fit one byte.")
		return {}
	for value: int in ready_delays:
		if value < 0 or value > 0xFF:
			_fail("Task ready/delay values must fit one byte.")
			return {}

	var after := ready_delays.duplicate()
	var checked_slots: Array[int] = []
	for slot_index in range(SLOT_BASES.size()):
		var slot_base: int = SLOT_BASES[slot_index]
		checked_slots.append(slot_base)
		var value: int = after[slot_index]
		if value == 0:
			continue
		if value == READY_SENTINEL:
			return _result(Decision.INITIAL_DISPATCH, slot_base, after,
				ready_latch_001b, checked_slots)
		after[slot_index] = value - 1
		if after[slot_index] == 0:
			return _result(Decision.YIELDED_RESUME, slot_base, after,
				ready_latch_001b, checked_slots)

	if (ready_latch_001b & NMI_READY_MASK) == 0:
		return _result(Decision.WAIT_FOR_NMI_READY, -1, after,
			ready_latch_001b, checked_slots)
	return _result(Decision.CLEAR_NMI_AND_RESCAN, -1, after,
		ready_latch_001b & NMI_CLEAR_MASK, checked_slots)


func get_source_status() -> Dictionary:
	return {
		"rom_sha256": ROM_SHA256,
		"scheduler_source_sha256": SOURCE_SHA256,
		"scan_slot_bases": slot_bases(),
		"scan_prefix_bytes": SCAN_PREFIX_LENGTH,
		"ready_sentinel": READY_SENTINEL,
		"nmi_ready_mask": NMI_READY_MASK,
		"nmi_clear_mask": NMI_CLEAR_MASK,
		"configured": _configured,
	}


func _result(decision: int, selected_slot_base: int, ready_after: PackedByteArray,
		latch_after: int, checked_slots: Array[int]) -> Dictionary:
	return {
		"decision": decision,
		"selected_slot_base": selected_slot_base,
		"ready_delays_after": ready_after,
		"ready_latch_after": latch_after,
		"checked_slots": checked_slots.duplicate(),
	}


func _verify_relative_branch_targets(scan_bytes: PackedByteArray) -> bool:
	# Source addresses: BEQ `$CA9B→$CAA5`, BEQ `$CA9F→$CAD4`,
	# BEQ `$CAA3→$CAB9`, BNE `$CAAC→$CA99`, and BPL `$CAB0→$CAAE`.
	var branches := [
		[0xCA9B, 0xF0, 0xCAA5],
		[0xCA9F, 0xF0, 0xCAD4],
		[0xCAA3, 0xF0, 0xCAB9],
		[0xCAAC, 0xD0, 0xCA99],
		[0xCAB0, 0x10, 0xCAAE],
	]
	for branch: Array in branches:
		var address: int = branch[0]
		var opcode_index: int = address - 0xCA97
		if scan_bytes[opcode_index] != int(branch[1]):
			return _fail("Scheduler branch opcode mismatch at $%04X." % address)
		var target := _relative_target(address + 2, scan_bytes[opcode_index + 1])
		if target != int(branch[2]):
			return _fail("Scheduler branch target mismatch at $%04X." % address)
	return true


func _relative_target(pc_after_operand: int, offset_byte: int) -> int:
	var signed_offset := offset_byte if offset_byte < 0x80 else offset_byte - 0x100
	return (pc_after_operand + signed_offset) & 0xFFFF


func _expected_scan_bytes() -> PackedByteArray:
	return PackedByteArray([
		0xA2, 0x01, 0xB5, 0x00, 0xF0, 0x08, 0xC9, 0xFF, 0xF0, 0x33,
		0xD6, 0x00, 0xF0, 0x14, 0x8A, 0x18, 0x69, 0x04, 0xAA, 0xE0,
		0x19, 0xD0, 0xEB, 0xA5, 0x1B, 0x10, 0xFC, 0x29, 0x7F, 0x85,
		0x1B, 0x4C, 0x97, 0xCA,
	])


func _fail(message: String) -> bool:
	error_message = message
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()
