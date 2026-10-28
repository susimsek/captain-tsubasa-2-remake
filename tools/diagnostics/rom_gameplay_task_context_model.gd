extends RefCounted
class_name RomGameplayTaskContextModel
## Diagnostic-only model for the ROM's one-slot task-context boundary.
## This file is not referenced by the game runtime. It is not a full 6502 or
## scheduler emulator and intentionally models no NMI cadence or task ordering.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const TASK_SLOT_STRIDE := 4
const READY_SENTINEL := 0xFF
const STACK_PAGE_SIZE := 0x100

const SOURCE_SPANS := {
	"scenario_setup": {
		"path": "res://reference/rom_extract/gameplay/task_context/bank10_callback_task_setup_8097_80a8.bin",
		"offset": 0x0200A7, "length": 18,
		"sha256": "2d69d726177fe1eb737aab04622108e5860b03d4fd95a5182538c4bae7d982db",
	},
	"callback_entry": {
		"path": "res://reference/rom_extract/gameplay/task_context/bank0b_callback_entry_8009.bin",
		"offset": 0x016019, "length": 3,
		"sha256": "5813c87d4f453cff4b6738bc2af1b54149488222527a69155072092c9f971fdb",
	},
	"yield_callsite": {
		"path": "res://reference/rom_extract/gameplay/task_context/bank0b_yield_callsite_856f.bin",
		"offset": 0x01657F, "length": 3,
		"sha256": "59653ff81dfe5c01f141d4ee69bb4832290c727091c41b92a71a6b0e2400a837",
	},
	"task_create": {
		"path": "res://reference/rom_extract/gameplay/task_context/fixed_task_create_C50F.bin",
		"offset": 0x03C51F, "length": 3,
		"sha256": "0ea4efd43ee0e2e3d1b9528351bc433e11207744845df22bfaa7bf0e335f08d0",
	},
	"yield_trampoline": {
		"path": "res://reference/rom_extract/gameplay/task_context/fixed_task_yield_trampoline_C515.bin",
		"offset": 0x03C525, "length": 3,
		"sha256": "86545169e2c9775f9eb73d63e59343ec9fff70a55fb97b17b22b39ab2fcd1d1e",
	},
	"scheduler": {
		"path": "res://reference/rom_extract/gameplay/task_context/fixed_task_scheduler_CA97_CAE6.bin",
		"offset": 0x03CAA7, "length": 80,
		"sha256": "3768ab8ac0aaeace9d3d53cf92cb8fea9363c400d6b8d4a40b77619c9900c6d8",
	},
	"task_seed": {
		"path": "res://reference/rom_extract/gameplay/task_context/fixed_task_seed_CAE7.bin",
		"offset": 0x03CAF7, "length": 16,
		"sha256": "139a8a1b3241ae60cebf1057463d3947c20f219b728ab98e2429ee2a0f3e3a55",
	},
	"task_finish": {
		"path": "res://reference/rom_extract/gameplay/task_context/fixed_task_finish_CAF7.bin",
		"offset": 0x03CB07, "length": 11,
		"sha256": "4caa4c1a5da0ac2ac961105268a2fc0a73babbc20efbf55707a5b63b99320770",
	},
	"task_yield": {
		"path": "res://reference/rom_extract/gameplay/task_context/fixed_task_yield_save_CB0F.bin",
		"offset": 0x03CB1F, "length": 30,
		"sha256": "b6377644890b9cd6671e4e63f48da4dfe1bd4975870bb531cb684ee7aeda07fc",
	},
}

const PHASE_EMPTY := 0
const PHASE_SEEDED := 1
const PHASE_RUNNING := 2
const PHASE_YIELDED := 3
const PHASE_FINISHED := 4

enum ResumeKind {
	NONE,
	INITIAL_TASK,
	YIELDED_TASK,
}


class TaskRecord extends RefCounted:
	var ready_delay: int = 0
	var saved_sp: int = 0
	var bank_low: int = 0
	var bank_high: int = 0

	func to_bytes() -> PackedByteArray:
		return PackedByteArray([ready_delay, saved_sp, bank_low, bank_high])

	func is_valid() -> bool:
		return _is_byte(ready_delay) and _is_byte(saved_sp) and _is_byte(bank_low) and _is_byte(bank_high)

	static func _is_byte(value: int) -> bool:
		return value >= 0 and value <= 0xFF


class TaskContext extends RefCounted:
	var slot_offset: int = -1
	var record: TaskRecord
	var stack_page: PackedByteArray = PackedByteArray()
	var phase: int = 0
	var pending_resume: int = 0
	var program_counter: int = 0
	var stack_pointer: int = 0
	var accumulator: int = 0
	var x_register: int = 0
	var y_register: int = 0
	var mapper_bank_low: int = 0
	var mapper_bank_high: int = 0

	func _init() -> void:
		record = TaskRecord.new()
		stack_page.resize(0x100)
		stack_page.fill(0)


var error_message := ""
var _configured := false
var _source_spans: Dictionary = {}
var _decoded_setup: Dictionary = {}
var _yield_return_minus_one := 0


static func source_span_specs() -> Dictionary:
	return SOURCE_SPANS.duplicate(true)


## The verifier supplies preserved spans only after comparing each one with the
## supplied ROM and its manifest. This model then checks the hashes and decodes
## the small instruction sequences it is allowed to represent.
func configure(source_spans: Dictionary) -> bool:
	error_message = ""
	_configured = false
	_source_spans.clear()
	for key: String in SOURCE_SPANS:
		var spec: Dictionary = SOURCE_SPANS[key]
		var source_value: Variant = source_spans.get(key, PackedByteArray())
		if not source_value is PackedByteArray:
			return _fail("Missing preserved ROM source bytes for %s." % key)
		var source_bytes: PackedByteArray = source_value
		if source_bytes.size() != int(spec["length"]):
			return _fail("Preserved ROM span has an unexpected size for %s." % key)
		if _sha256(source_bytes) != String(spec["sha256"]):
			return _fail("Preserved ROM span failed its source hash check for %s." % key)
		_source_spans[key] = source_bytes.duplicate()
	if not _decode_rom_recipes():
		return false
	_configured = true
	return true


## Replays the exact bank-$10 caller plus `$C50F → $CAE7` seed operation.
## The caller is the verified fresh-route callback task setup; no trace RAM is
## used to construct this state.
func seed_scenario_callback_task() -> TaskContext:
	if not _configured:
		_fail("Configure verified ROM source spans before creating a task context.")
		return null
	var context := TaskContext.new()
	context.slot_offset = int(_decoded_setup["slot_offset"])
	context.record.saved_sp = int(_decoded_setup["saved_sp"])
	context.record.bank_low = int(_decoded_setup["bank_base"])
	var return_high: int = int(_decoded_setup["return_high"])
	var return_low: int = int(_decoded_setup["return_low"])

	# `$CAE7`: TYA; LDY $01,X; STA $0101,Y; PLA; STA $0102,Y;
	# LDA #$FF; STA $00,X. Caller setup already supplied SP and bank base.
	var stack_low_index: int = (context.record.saved_sp + 1) & 0xFF
	var stack_high_index: int = (context.record.saved_sp + 2) & 0xFF
	context.stack_page[stack_low_index] = return_low
	context.stack_page[stack_high_index] = return_high
	context.record.ready_delay = READY_SENTINEL
	context.program_counter = int(_decoded_setup["seed_return_pc"])
	context.stack_pointer = context.record.saved_sp
	context.accumulator = READY_SENTINEL
	context.x_register = context.slot_offset
	context.y_register = context.record.saved_sp
	context.phase = PHASE_SEEDED
	return context


## Evaluates one task record during one scheduler scan. This is only the
## record-level eligibility rule; it does not model scan order, NMI timing, or
## the other five task slots.
func evaluate_single_slot_scan(context: TaskContext) -> bool:
	if not _require_context(context, [PHASE_SEEDED, PHASE_YIELDED]):
		return false
	if context.pending_resume != ResumeKind.NONE:
		return _fail("A task already has an unconsumed resume decision.")
	if context.record.ready_delay == READY_SENTINEL:
		context.pending_resume = ResumeKind.INITIAL_TASK
		return true
	if context.record.ready_delay == 0:
		return false
	context.record.ready_delay -= 1
	if context.record.ready_delay == 0:
		context.pending_resume = ResumeKind.YIELDED_TASK
		return true
	return false


## Applies the source-backed dispatcher return context for an initial `$FF`
## task or a yielded finite-delay task. The caller owns when a scan happens.
func dispatch_pending_task(context: TaskContext) -> bool:
	if not _configured:
		return _fail("Configure verified ROM source spans before dispatching a task.")
	if context == null or context.pending_resume == ResumeKind.NONE:
		return _fail("No eligible task context is pending dispatch.")
	if context.pending_resume == ResumeKind.INITIAL_TASK:
		return _dispatch_initial(context)
	if context.pending_resume == ResumeKind.YIELDED_TASK:
		return _dispatch_yielded(context)
	return _fail("Unsupported task resume kind.")


## Builds the one known bank-$0B `$856F JSR $C515` call frame, follows the
## `$C515 JMP $CB0F` trampoline, and applies the ROM yield-save instructions.
## `caller_stack_pointer` and current registers/banks are explicit inputs; the
## model does not invent the callback history that produced them.
func yield_at_verified_callsite(context: TaskContext, delay_in_a: int,
		caller_stack_pointer: int, saved_x: int, saved_y: int,
		current_bank_low: int, current_bank_high: int) -> bool:
	if not _require_context(context, [PHASE_RUNNING]):
		return false
	if not _byte_arguments([delay_in_a, caller_stack_pointer, saved_x, saved_y,
			current_bank_low, current_bank_high]):
		return _fail("Yield inputs must fit the 6502 register and stack byte ranges.")
	if context.slot_offset < 0 or context.slot_offset > 0xFC:
		return _fail("Task slot base is outside the zero-page four-byte range.")

	# The ROM call at $856F is JSR $C515. JSR pushes the address of its final
	# operand ($8571), high byte first, then low byte, before entering C515.
	var return_minus_one: int = _yield_return_minus_one
	var sp: int = caller_stack_pointer
	context.stack_page[sp] = (return_minus_one >> 8) & 0xFF
	sp = (sp - 1) & 0xFF
	context.stack_page[sp] = return_minus_one & 0xFF
	sp = (sp - 1) & 0xFF

	# `$CB0F` TXA/PHA; TYA/PHA; then writes bank pair, A delay, and TSX SP.
	context.stack_page[sp] = saved_x
	sp = (sp - 1) & 0xFF
	context.stack_page[sp] = saved_y
	sp = (sp - 1) & 0xFF
	context.record.ready_delay = delay_in_a
	context.record.saved_sp = sp
	context.record.bank_low = current_bank_low
	context.record.bank_high = current_bank_high
	context.stack_pointer = sp
	context.accumulator = delay_in_a
	context.x_register = saved_x
	context.y_register = saved_y
	context.mapper_bank_low = current_bank_low
	context.mapper_bank_high = current_bank_high
	context.program_counter = int(_decoded_setup["yield_trampoline_target"])
	context.pending_resume = ResumeKind.NONE
	context.phase = PHASE_YIELDED
	return true


## Applies `$CAF7`: clear record bytes +0/+1, leaving the bank bytes and
## stack-page contents untouched.
func finish_task(context: TaskContext) -> bool:
	if not _require_context(context, [PHASE_RUNNING]):
		return false
	context.record.ready_delay = 0
	context.record.saved_sp = 0
	context.pending_resume = ResumeKind.NONE
	context.phase = PHASE_FINISHED
	return true


func get_source_status() -> Dictionary:
	return {
		"configured": _configured,
		"error": error_message,
		"rom_sha256": ROM_SHA256,
		"scenario_callback_slot": _decoded_setup.get("slot_offset", -1),
		"initial_stack_pointer": _decoded_setup.get("saved_sp", -1),
		"initial_bank_base": _decoded_setup.get("bank_base", -1),
		"initial_entry_pc": _decoded_setup.get("entry_pc", -1),
		"seed_helper_return_pc": _decoded_setup.get("seed_return_pc", -1),
		"callback_reader_pc": _decoded_setup.get("callback_reader_pc", -1),
		"yield_callsite_pc": _decoded_setup.get("yield_callsite_pc", -1),
		"yield_return_pc": _yield_return_minus_one + 1,
	}


func _decode_rom_recipes() -> bool:
	var setup: PackedByteArray = _source_spans["scenario_setup"]
	if setup[0] != 0xA2 or setup[2] != 0xA9 or setup[4] != 0x95 or setup[5] != 0x01:
		return _fail("Scenario caller no longer matches the supported slot/SP setup sequence.")
	if setup[6] != 0xA9 or setup[8] != 0x95 or setup[9] != 0x02:
		return _fail("Scenario caller no longer matches the supported mapper-base setup.")
	if setup[10] != 0xA9 or setup[12] != 0xA0 or setup[14] != 0x20 or setup[17] != 0x60:
		return _fail("Scenario caller no longer matches the supported C50F call sequence.")
	var setup_jsr_target := _read_u16(setup, 15)
	var create: PackedByteArray = _source_spans["task_create"]
	if create != PackedByteArray([0x4C, 0xE7, 0xCA]):
		return _fail("$C50F no longer jumps directly to $CAE7.")
	var seed: PackedByteArray = _source_spans["task_seed"]
	if seed != PackedByteArray([0x48, 0x98, 0xB4, 0x01, 0x99, 0x01, 0x01,
			0x68, 0x99, 0x02, 0x01, 0xA9, 0xFF, 0x95, 0x00, 0x60]):
		return _fail("$CAE7 instruction sequence is outside this task-context model.")
	if setup_jsr_target != 0xC50F:
		return _fail("Scenario caller no longer calls $C50F.")

	var callback_entry: PackedByteArray = _source_spans["callback_entry"]
	if callback_entry[0] != 0x4C:
		return _fail("Bank-$0B $8009 is no longer an absolute JMP.")
	var callback_reader_pc := _read_u16(callback_entry, 1)
	if callback_reader_pc != 0x814C:
		return _fail("Bank-$0B $8009 no longer transfers to $814C.")

	var yield_callsite: PackedByteArray = _source_spans["yield_callsite"]
	if yield_callsite != PackedByteArray([0x20, 0x15, 0xC5]):
		return _fail("Bank-$0B $856F no longer calls $C515.")
	var yield_trampoline: PackedByteArray = _source_spans["yield_trampoline"]
	if yield_trampoline != PackedByteArray([0x4C, 0x0F, 0xCB]):
		return _fail("$C515 no longer jumps to $CB0F.")
	var yield_code: PackedByteArray = _source_spans["task_yield"]
	if yield_code != PackedByteArray([0x85, 0x7F, 0x8A, 0x48, 0x98, 0x48,
			0xA6, 0x00, 0xA5, 0x24, 0x95, 0x02, 0xA5, 0x25, 0x95, 0x03,
			0xA5, 0x7F, 0x95, 0x00, 0x8A, 0xA8, 0xBA, 0x96, 0x01,
			0xA6, 0x00, 0x4C, 0xA5, 0xCA]):
		return _fail("$CB0F instruction sequence is outside this task-context model.")
	var finish_code: PackedByteArray = _source_spans["task_finish"]
	if finish_code != PackedByteArray([0xA9, 0x00, 0xA6, 0x00, 0x95, 0x00,
			0x95, 0x01, 0x4C, 0xA5, 0xCA]):
		return _fail("$CAF7 instruction sequence is outside this task-context model.")

	var scheduler: PackedByteArray = _source_spans["scheduler"]
	var scan_prefix := PackedByteArray([
		0xA2, 0x01, 0xB5, 0x00, 0xF0, 0x08, 0xC9, 0xFF, 0xF0, 0x33,
		0xD6, 0x00, 0xF0, 0x14, 0x8A, 0x18, 0x69, 0x04, 0xAA, 0xE0,
		0x19, 0xD0, 0xEB, 0xA5, 0x1B, 0x10, 0xFC, 0x29, 0x7F, 0x85,
		0x1B, 0x4C, 0x97, 0xCA,
	])
	var yielded_resume := PackedByteArray([
		0x46, 0x19, 0x86, 0x00, 0xB5, 0x02, 0x85, 0x24, 0xB5, 0x03,
		0x85, 0x25, 0x20, 0x2D, 0xCE, 0xB5, 0x01, 0xAA, 0x9A, 0x38,
		0x66, 0x19, 0x68, 0xA8, 0x68, 0xAA, 0x60,
	])
	var initial_dispatch := PackedByteArray([
		0x86, 0x00, 0xB5, 0x02, 0x85, 0x24, 0x18, 0x69, 0x01, 0x85,
		0x25, 0x20, 0x2D, 0xCE, 0xB5, 0x01, 0xAA, 0x9A, 0x60,
	])
	if _slice(scheduler, 0, scan_prefix.size()) != scan_prefix:
		return _fail("$CA97 scan/sentinel/slot-stride bytes changed.")
	if _slice(scheduler, 34, yielded_resume.size()) != yielded_resume:
		return _fail("$CAB9 yielded-resume bytes changed.")
	if _slice(scheduler, 61, initial_dispatch.size()) != initial_dispatch:
		return _fail("$CAD4 initial-ready dispatch bytes changed.")

	var return_minus_one: int = 0x856F + 2
	var callback_entry_minus_one := (int(setup[11]) << 8) | int(setup[13])
	_decoded_setup = {
		"slot_offset": int(setup[1]),
		"saved_sp": int(setup[3]),
		"bank_base": int(setup[7]),
		"return_high": int(setup[11]),
		"return_low": int(setup[13]),
		"seed_return_pc": 0x80A8,
		"entry_pc": (callback_entry_minus_one + 1) & 0xFFFF,
		"callback_reader_pc": callback_reader_pc,
		"yield_callsite_pc": 0x856F,
		"yield_trampoline_target": _read_u16(yield_trampoline, 1),
	}
	_yield_return_minus_one = return_minus_one
	return true


func _dispatch_initial(context: TaskContext) -> bool:
	if context.phase != PHASE_SEEDED and context.phase != PHASE_YIELDED:
		return _fail("The immediate-ready dispatcher requires a seeded or yielded task.")
	var base: int = context.record.bank_low
	context.mapper_bank_low = base
	context.mapper_bank_high = (base + 1) & 0xFF
	context.stack_pointer = context.record.saved_sp
	context.accumulator = context.record.saved_sp
	context.x_register = context.record.saved_sp
	var rts_low := _stack_read(context, context.stack_pointer + 1)
	var rts_high := _stack_read(context, context.stack_pointer + 2)
	context.program_counter = (((rts_high << 8) | rts_low) + 1) & 0xFFFF
	context.stack_pointer = (context.stack_pointer + 2) & 0xFF
	context.pending_resume = ResumeKind.NONE
	context.phase = PHASE_RUNNING
	return true


func _dispatch_yielded(context: TaskContext) -> bool:
	if context.phase != PHASE_YIELDED:
		return _fail("The yielded-resume path requires a yielded task.")
	context.mapper_bank_low = context.record.bank_low
	context.mapper_bank_high = context.record.bank_high
	context.stack_pointer = context.record.saved_sp
	# `$CAB9`: restore TSX; PLA/TAY; PLA/TAX; RTS. `$19` flag math and
	# mapper-register side effects are not part of this per-task state model.
	context.y_register = _stack_pop(context)
	context.x_register = _stack_pop(context)
	context.accumulator = context.x_register
	var return_low := _stack_pop(context)
	var return_high := _stack_pop(context)
	context.program_counter = (((return_high << 8) | return_low) + 1) & 0xFFFF
	context.pending_resume = ResumeKind.NONE
	context.phase = PHASE_RUNNING
	return true


func _stack_read(context: TaskContext, page_offset: int) -> int:
	return int(context.stack_page[page_offset & 0xFF])


func _stack_pop(context: TaskContext) -> int:
	context.stack_pointer = (context.stack_pointer + 1) & 0xFF
	return int(context.stack_page[context.stack_pointer])


func _require_context(context: TaskContext, phases: Array[int]) -> bool:
	if not _configured:
		return _fail("Configure verified ROM source spans before operating on a task.")
	if context == null or not context.record.is_valid() or context.stack_page.size() != STACK_PAGE_SIZE:
		return _fail("Task context or its four-byte record/stack page is invalid.")
	if context.slot_offset < 0 or context.slot_offset > 0xFF or context.slot_offset % TASK_SLOT_STRIDE != 1:
		return _fail("Task context slot offset is not a ROM four-byte record base.")
	if not phases.has(context.phase):
		return _fail("Task operation is invalid for the context's current phase.")
	return true


func _byte_arguments(values: Array[int]) -> bool:
	for value: int in values:
		if value < 0 or value > 0xFF:
			return false
	return true


func _read_u16(bytes: PackedByteArray, offset: int) -> int:
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8)


func _slice(bytes: PackedByteArray, offset: int, length: int) -> PackedByteArray:
	var result := PackedByteArray()
	for index in range(length):
		result.append(bytes[offset + index])
	return result


func _sha256(bytes: PackedByteArray) -> String:
	var hash_context := HashingContext.new()
	if hash_context.start(HashingContext.HASH_SHA256) != OK:
		return ""
	if hash_context.update(bytes) != OK:
		return ""
	return hash_context.finish().hex_encode()


func _fail(message: String) -> bool:
	error_message = message
	return false
