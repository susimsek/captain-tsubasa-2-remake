extends RefCounted
class_name RomGameplayTaskScheduler
## Bounded runtime model of the game's verified task-record/scheduler boundary.
## This is not a 6502 emulator: it does not execute task bodies, synthesize NMI
## cadence, or choose when callers create callbacks. A source runner must supply
## decoded call-site state and externally observed PPU NMI deliveries.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const TASK_CONTEXT_ROOT := "res://reference/rom_extract/gameplay/task_context/"
const MANIFEST_PATH := TASK_CONTEXT_ROOT + "manifest.json"
const RAM_SIZE := 0x800
const STACK_PAGE_SIZE := 0x100
const READY_SENTINEL := 0xFF
const NMI_ENABLE_MASK := 0x80
const NMI_READY_MASK := 0x80
const NMI_MODE_MASK := 0x40
const SLOT_BASES: Array[int] = [0x01, 0x05, 0x09, 0x0D, 0x11, 0x15]

const SOURCE_SPANS := {
	"ram_zero_fill": {
		"file": "fixed_ram_zero_fill_C650_C679.bin", "offset": 0x03C660,
		"length": 42, "sha256": "076731fdd07d2c05fcc4c27d65cf0ed29193b97ac79a02501b7f2051082705d9",
	},
	"task_slot_clear": {
		"file": "fixed_task_slot_clear_C6BE_C6E7.bin", "offset": 0x03C6CE,
		"length": 42, "sha256": "4e62f14d490b37ece22e2cec5f55846ddbb6235efa54100634602c20cb29f73e",
	},
	"gameplay_bootstrap": {
		"file": "fixed_task_gameplay_bootstrap_C6E8_C765.bin", "offset": 0x03C6F8,
		"length": 126, "sha256": "dfb460088ed63655a5627ebc5c06f111061b00f0a6d48af562dc995bb67c1160",
	},
	"nmi_gate_and_normal_ready": {
		"file": "fixed_task_nmi_gate_and_ready_C76E_C7EF.bin", "offset": 0x03C77E,
		"length": 130, "sha256": "a8c2e5e208b5e45900e2fbca7cb75eda18f46231edc989200c723968aa091315",
	},
	"nmi_special_dispatch": {
		"file": "fixed_task_nmi_special_dispatch_C421_C43C.bin", "offset": 0x03C431,
		"length": 28, "sha256": "6389b19db8e0a662875a3dba68c5bd642fb75a0dfd2fc80fcfd4ef8344cd0bb2",
	},
	"nmi_special_ready_path": {
		"file": "bank02_nmi_ready_path_A000_A137.bin", "offset": 0x004010,
		"length": 312, "sha256": "4f938bdaec443590eca1a814afef66fb2be987abafc5c2bba677f8c415a81412",
	},
	"nmi_vectors": {
		"file": "fixed_nmi_vectors_FFFA_FFFF.bin", "offset": 0x04000A,
		"length": 6, "sha256": "72925dda7194399d7eb27eb4a7d41a2b4d4b8be47b049bc1fd06f95f6627edec",
	},
	"nmi_vector_entry": {
		"file": "fixed_nmi_vector_entry_C500.bin", "offset": 0x03C510,
		"length": 3, "sha256": "a8d9fc1dc189a985f762edb564889dbab0a9bc7b4dcced5b1ef17c6933ecf0b5",
	},
	"nmi_return_enable": {
		"file": "fixed_nmi_return_enable_C810_C820.bin", "offset": 0x03C820,
		"length": 17, "sha256": "1ddfe0a969927fb72713998c3454eae9c61053616ba747d6b6318f9a7cd3df75",
	},
	"scenario_setup": {
		"file": "bank10_callback_task_setup_8097_80a8.bin", "offset": 0x0200A7,
		"length": 18, "sha256": "2d69d726177fe1eb737aab04622108e5860b03d4fd95a5182538c4bae7d982db",
	},
	"callback_entry": {
		"file": "bank0b_callback_entry_8009.bin", "offset": 0x016019,
		"length": 3, "sha256": "5813c87d4f453cff4b6738bc2af1b54149488222527a69155072092c9f971fdb",
	},
	"yield_callsite": {
		"file": "bank0b_yield_callsite_856f.bin", "offset": 0x01657F,
		"length": 3, "sha256": "59653ff81dfe5c01f141d4ee69bb4832290c727091c41b92a71a6b0e2400a837",
	},
	"bank18_worker_yield_callsite": {
		"file": "bank18_worker_yield_callsite_8886.bin", "offset": 0x030896,
		"length": 3, "sha256": "59653ff81dfe5c01f141d4ee69bb4832290c727091c41b92a71a6b0e2400a837",
	},
	"task_create": {
		"file": "fixed_task_create_C50F.bin", "offset": 0x03C51F,
		"length": 3, "sha256": "0ea4efd43ee0e2e3d1b9528351bc433e11207744845df22bfaa7bf0e335f08d0",
	},
	"yield_trampoline": {
		"file": "fixed_task_yield_trampoline_C515.bin", "offset": 0x03C525,
		"length": 3, "sha256": "86545169e2c9775f9eb73d63e59343ec9fff70a55fb97b17b22b39ab2fcd1d1e",
	},
	"scheduler": {
		"file": "fixed_task_scheduler_CA97_CAE6.bin", "offset": 0x03CAA7,
		"length": 80, "sha256": "3768ab8ac0aaeace9d3d53cf92cb8fea9363c400d6b8d4a40b77619c9900c6d8",
	},
	"task_seed": {
		"file": "fixed_task_seed_CAE7.bin", "offset": 0x03CAF7,
		"length": 16, "sha256": "139a8a1b3241ae60cebf1057463d3947c20f219b728ab98e2429ee2a0f3e3a55",
	},
	"task_finish": {
		"file": "fixed_task_finish_CAF7.bin", "offset": 0x03CB07,
		"length": 11, "sha256": "4caa4c1a5da0ac2ac961105268a2fc0a73babbc20efbf55707a5b63b99320770",
	},
	"task_yield": {
		"file": "fixed_task_yield_save_CB0F.bin", "offset": 0x03CB1F,
		"length": 30, "sha256": "b6377644890b9cd6671e4e63f48da4dfe1bd4975870bb531cb684ee7aeda07fc",
	},
	"root_slot01_startup": {
		"file": "fixed_root_slot01_startup_CA22_CA51.bin", "offset": 0x03CA32,
		"length": 48, "sha256": "a2e9aa1047c184ff21854c6e30733f68f17bc7a4df68ff98e8622571d5c90476",
	},
}

enum ScanDecision {
	INITIAL_DISPATCH,
	YIELDED_RESUME,
	WAIT_FOR_NMI_READY,
	CLEAR_NMI_AND_RESCAN,
}

enum ContextPhase { EMPTY, SEEDED, RUNNING, YIELDED, FINISHED }
enum ResumeKind { NONE, INITIAL_TASK, YIELDED_TASK }


class TaskContext extends RefCounted:
	var slot_base: int = -1
	var ready_delay: int = 0
	var phase: int = ContextPhase.EMPTY
	var pending_resume: int = ResumeKind.NONE
	var program_counter: int = 0
	var stack_pointer: int = 0
	var accumulator: int = 0
	var x_register: int = 0
	var y_register: int = 0
	var bank_low: int = 0
	var bank_high: int = 0
	var source_return_word: int = 0
	var source_label: String = ""


var error_message := ""
var _configured := false
var _initialized := false
var _sources: Dictionary = {}
var _ram := PackedByteArray()
var _stack_page := PackedByteArray()
var _contexts: Dictionary = {}
var _merged_source_write_prefixes: Dictionary = {}
var _active_task_slot := -1
var _ppu_ctrl_shadow := 0
var _scheduler_y_register := 0
var _scheduler_scan_cursor := 0x01


static func source_span_specs() -> Dictionary:
	return SOURCE_SPANS.duplicate(true)


## Loads only preserved project-owned ROM-derived bytes. It never opens the
## supplied `.nes` file or emulator output. The manifest links each span back
## to the audited ROM hash, offset, and length.
func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_sources.clear()
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return _fail("Packaged task-context source manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		return _fail("Packaged task-context source manifest is malformed.")
	var manifest: Dictionary = parsed
	if String(manifest.get("rom_sha256", "")) != ROM_SHA256:
		return _fail("Packaged task-context manifest targets a different ROM revision.")
	var entries_by_file: Dictionary = {}
	for entry_variant in manifest.get("spans", []):
		if entry_variant is Dictionary:
			var entry: Dictionary = entry_variant
			entries_by_file[String(entry.get("file", ""))] = entry
	for key: String in SOURCE_SPANS:
		var spec: Dictionary = SOURCE_SPANS[key]
		var file_name := String(spec["file"])
		if not entries_by_file.has(file_name):
			return _fail("Source manifest omits %s." % file_name)
		var manifest_entry: Dictionary = entries_by_file[file_name]
		if int(manifest_entry.get("length", -1)) != int(spec["length"]) \
				or String(manifest_entry.get("file_offset", "")) != "0x%06X" % int(spec["offset"]) \
				or String(manifest_entry.get("sha256", "")) != String(spec["sha256"]):
			return _fail("Manifest offset/length/hash differs for %s." % file_name)
		var path := TASK_CONTEXT_ROOT + file_name
		var bytes := FileAccess.get_file_as_bytes(path)
		if bytes.size() != int(spec["length"]) or _sha256(bytes) != String(spec["sha256"]):
			return _fail("Preserved source span failed its size/hash check: %s." % file_name)
		_sources[key] = bytes
	if not _verify_source_recipes():
		return false
	_configured = true
	return true


## Replays the verified cold-RAM precondition and `$C6BE–$C765` fresh-game
## task bootstrap. This is bounded initialization state, not a full startup CPU.
func initialize_fresh_game_bootstrap() -> Dictionary:
	if not _configured:
		_fail("Configure packaged source spans before deriving gameplay state.")
		return {}
	_initialized = false
	_active_task_slot = -1
	_merged_source_write_prefixes.clear()
	_scheduler_y_register = 0
	_scheduler_scan_cursor = 0x01
	_contexts.clear()
	_ram.resize(RAM_SIZE)
	_ram.fill(0)
	_stack_page.resize(STACK_PAGE_SIZE)
	_stack_page.fill(0)
	for slot_base: int in SLOT_BASES:
		_ram[slot_base] = 0
		_ram[slot_base + 1] = 0

	var bootstrap: PackedByteArray = _sources["gameplay_bootstrap"]
	var root_slots: Array[int] = [0x01, 0x05, 0x09]
	for task_index in range(root_slots.size()):
		var seed_offset := 0x3D + task_index * 17
		var seed := bootstrap.slice(seed_offset, seed_offset + 17)
		var decoded := _decode_root_seed(seed)
		if decoded.is_empty() or int(decoded["slot"]) != root_slots[task_index]:
			_fail("Root task %d does not match the source seed sequence." % task_index)
			return {}
		var context := TaskContext.new()
		context.slot_base = int(decoded["slot"])
		context.ready_delay = READY_SENTINEL
		context.phase = ContextPhase.SEEDED
		context.stack_pointer = int(decoded["saved_sp"])
		context.accumulator = READY_SENTINEL
		context.x_register = context.slot_base
		context.y_register = context.stack_pointer
		context.bank_low = int(decoded["bank_low"])
		context.bank_high = int(decoded["bank_high"])
		context.source_return_word = int(decoded["return_word"])
		context.source_label = "fixed bootstrap root task at $%04X" % int(decoded["return_word"])
		_scheduler_y_register = int(decoded["saved_sp"])
		_ram[context.slot_base] = READY_SENTINEL
		_ram[context.slot_base + 1] = context.stack_pointer
		_ram[context.slot_base + 2] = context.bank_low
		_ram[context.slot_base + 3] = context.bank_high
		_write_stack_byte(context.stack_pointer + 1, int(decoded["return_low"]))
		_write_stack_byte(context.stack_pointer + 2, int(decoded["return_high"]))
		_contexts[context.slot_base] = context

	_ppu_ctrl_shadow = 0x88
	# `$C6E8` executes `LDA #$1E; STA $21` before it seeds the root tasks.
	_ram[0x0021] = 0x1E
	_ram[0x001B] = 0
	_initialized = true
	return {
		"ok": true,
		"rom_sha256": ROM_SHA256,
		"root_slots": root_slots,
		"root_task_return_words": _root_return_words(),
		"task_record_snapshot": _task_record_snapshot(),
		"stack_pointer_words": _root_stack_pointers(),
		"scheduler_entry_pc": 0xCA97,
		"ppu_ctrl_shadow": _ppu_ctrl_shadow,
		"scheduler_ready_latch_001b": _ram[0x001B],
	}


## Applies one externally supplied PPU NMI delivery. No frame cadence is
## generated here: the caller owns whether/when an NMI was delivered.
func apply_external_nmi_delivery(source_frame: int, ppu_ctrl_shadow: int,
		nmi_delivered: bool) -> Dictionary:
	if not _require_initialized():
		return {}
	if source_frame < 0 or source_frame > 0x7FFFFFFF:
		_fail("Source frame must be a nonnegative 32-bit value.")
		return {}
	if ppu_ctrl_shadow < 0 or ppu_ctrl_shadow > 0xFF:
		_fail("PPUCTRL shadow must fit one byte.")
		return {}
	if not nmi_delivered:
		return {
			"ok": true, "serviced": false, "source_frame": source_frame,
			"reason": "no_external_nmi_delivery", "latch_after": int(_ram[0x001B]),
			"models_nmi_cycle": false,
		}
	if (ppu_ctrl_shadow & NMI_ENABLE_MASK) == 0:
		_fail("External NMI delivery conflicts with source PPUCTRL.7 being clear.")
		return {}
	var special_mode := (int(_ram[0x001B]) & NMI_MODE_MASK) != 0
	var writer_pc := 0xA135 if special_mode else 0xC7F0
	_ram[0x001B] = int(_ram[0x001B]) | NMI_READY_MASK
	return {
		"ok": true,
		"serviced": true,
		"source_frame": source_frame,
		"path": "bank02_mode6" if special_mode else "fixed_normal",
		"writer_pc": writer_pc,
		"latch_after": int(_ram[0x001B]),
		"edge_source": "caller-supplied PPU NMI delivery",
		"models_nmi_cycle": false,
	}


## Continues the ROM-ordered task scan from its current `$CAA5` cursor. A task
## yield advances to the next slot; only consuming the NMI-ready latch restarts
## at `$CA97` / slot `$01`. The owner still executes returned task bodies.
func scan_ready_tasks_once() -> Dictionary:
	if not _require_initialized():
		return {}
	if _active_task_slot >= 0:
		_fail("A task body is active; the scheduler cannot scan until that task yields or finishes.")
		return {}
	var checked_slots: Array[int] = []
	for slot_base: int in SLOT_BASES:
		if slot_base < _scheduler_scan_cursor:
			continue
		_scheduler_scan_cursor = slot_base
		checked_slots.append(slot_base)
		var value := int(_ram[slot_base])
		if value == 0:
			continue
		var context: TaskContext = _contexts.get(slot_base)
		if value == READY_SENTINEL:
			if context == null or context.phase not in [ContextPhase.SEEDED, ContextPhase.YIELDED]:
				return _scan_failure("Ready slot $%02X has no supported saved task context." % slot_base, checked_slots)
			context.pending_resume = ResumeKind.INITIAL_TASK if context.phase == ContextPhase.SEEDED else ResumeKind.YIELDED_TASK
			_scheduler_scan_cursor = slot_base
			return _scan_result(ScanDecision.INITIAL_DISPATCH if context.phase == ContextPhase.SEEDED else ScanDecision.YIELDED_RESUME,
				slot_base, checked_slots)
		_ram[slot_base] = value - 1
		if context != null:
			context.ready_delay = value - 1
		if int(_ram[slot_base]) == 0:
			if context == null or context.phase != ContextPhase.YIELDED:
				return _scan_failure("Finite-delay slot $%02X reached zero without a yielded task context." % slot_base, checked_slots)
			context.pending_resume = ResumeKind.YIELDED_TASK
			_scheduler_scan_cursor = slot_base
			return _scan_result(ScanDecision.YIELDED_RESUME, slot_base, checked_slots)

	_scheduler_scan_cursor = 0x19
	if (int(_ram[0x001B]) & NMI_READY_MASK) == 0:
		return _scan_result(ScanDecision.WAIT_FOR_NMI_READY, -1, checked_slots)
	_ram[0x001B] = int(_ram[0x001B]) & 0x7F
	_scheduler_scan_cursor = 0x01
	return _scan_result(ScanDecision.CLEAR_NMI_AND_RESCAN, -1, checked_slots)


## Restores the saved bank pair/6502 stack from the exact ROM task-record shape.
## The owner must separately execute the task body at the returned PC.
func dispatch_pending_task(slot_base: int) -> Dictionary:
	if not _require_initialized():
		return {}
	if _active_task_slot >= 0:
		_fail("Cannot dispatch while another task body is active.")
		return {}
	var context: TaskContext = _contexts.get(slot_base)
	if context == null or context.pending_resume == ResumeKind.NONE:
		_fail("No ROM-sourced dispatch decision is pending for slot $%02X." % slot_base)
		return {}
	var ready := int(_ram[slot_base])
	if context.pending_resume == ResumeKind.INITIAL_TASK:
		if ready != READY_SENTINEL or context.phase != ContextPhase.SEEDED:
			_fail("Initial task dispatch no longer matches its seeded record.")
			return {}
		var saved_sp := int(_ram[slot_base + 1])
		context.bank_low = int(_ram[slot_base + 2])
		context.bank_high = (context.bank_low + 1) & 0xFF
		context.stack_pointer = saved_sp
		var low := int(_stack_page[(saved_sp + 1) & 0xFF])
		var high := int(_stack_page[(saved_sp + 2) & 0xFF])
		context.program_counter = (((high << 8) | low) + 1) & 0xFFFF
		context.stack_pointer = (saved_sp + 2) & 0xFF
		# `$CAD4` loads the saved SP into A, transfers it to X, then TXS/RTS.
		# Y is preserved from the current scheduler continuation: `$78` at the
		# initial dispatch, then the last yielding slot base after `$CB0F`.
		context.accumulator = saved_sp
		context.x_register = saved_sp
		context.y_register = _scheduler_y_register
		context.pending_resume = ResumeKind.NONE
		context.phase = ContextPhase.RUNNING
		_ram[0x0000] = slot_base
		_active_task_slot = slot_base
		return _dispatch_result(context, "initial_rts")
	if context.pending_resume == ResumeKind.YIELDED_TASK:
		if ready != 0 or context.phase != ContextPhase.YIELDED:
			_fail("Yielded resume no longer matches a zero-delay task record.")
			return {}
		context.bank_low = int(_ram[slot_base + 2])
		context.bank_high = int(_ram[slot_base + 3])
		context.stack_pointer = int(_ram[slot_base + 1])
		context.y_register = _stack_pop(context)
		context.x_register = _stack_pop(context)
		var low := _stack_pop(context)
		var high := _stack_pop(context)
		context.program_counter = (((high << 8) | low) + 1) & 0xFFFF
		context.accumulator = context.x_register
		context.pending_resume = ResumeKind.NONE
		context.phase = ContextPhase.RUNNING
		_ram[0x0000] = slot_base
		_active_task_slot = slot_base
		return _dispatch_result(context, "yielded_rts")
	_fail("Unsupported pending task resume kind.")
	return {}


## Runs the byte-bounded fixed root slot `$01` setup from `$CA22` through its
## first `$CB0F` yield. Only the exact verified opcodes in the packaged source
## span are accepted; this is not a general 6502 interpreter or route runner.
func execute_root_slot01_startup_to_first_yield() -> Dictionary:
	if not _require_initialized():
		return {}
	var context: TaskContext = _contexts.get(0x01)
	if _active_task_slot != 0x01 or context == null \
			or context.phase != ContextPhase.RUNNING or context.program_counter != 0xCA22:
		_fail("Root slot `$01` startup requires its ROM-dispatched `$CA22` context.")
		return {}
	var source: PackedByteArray = _sources["root_slot01_startup"]
	var pc := 0xCA22
	var a := context.accumulator
	var writes: Array[Dictionary] = []
	while pc < 0xCA4F:
		var offset := pc - 0xCA22
		var opcode := int(source[offset])
		match opcode:
			0xA5: # LDA zero page
				var address := int(source[offset + 1])
				a = int(_ram[address])
				pc += 2
			0x09: # ORA immediate
				a = (a | int(source[offset + 1])) & 0xFF
				pc += 2
			0xA9: # LDA immediate
				a = int(source[offset + 1])
				pc += 2
			0x85: # STA zero page
				var zp_address := int(source[offset + 1])
				_ram[zp_address] = a
				writes.append({"address": zp_address, "value": a, "pc": pc})
				pc += 2
			0x8D: # STA absolute internal RAM
				var absolute_address := int(source[offset + 1]) | (int(source[offset + 2]) << 8)
				if absolute_address >= RAM_SIZE:
					_fail("Root startup touched an unsupported hardware address `$%04X`." % absolute_address)
					return {}
				_ram[absolute_address] = a
				writes.append({"address": absolute_address, "value": a, "pc": pc})
				pc += 3
			_:
				_fail("Unsupported root-startup opcode `$%02X` at `$%04X`." % [opcode, pc])
				return {}
	if pc != 0xCA4F or source.slice(0x2D, 0x30) != PackedByteArray([0x20, 0x0F, 0xCB]):
		_fail("Root startup no longer reaches its exact `$CA4F JSR $CB0F` yield.")
		return {}
	context.accumulator = a
	context.program_counter = pc
	if not yield_at_verified_callsite(0x01, pc, a, context.stack_pointer,
			context.x_register, context.y_register, context.bank_low, context.bank_high):
		return {}
	return {
		"ok": true,
		"slot_base": 0x01,
		"source_start_pc": 0xCA22,
		"yield_callsite_pc": pc,
		"resume_pc": pc + 3,
		"writes": writes,
		"task_record": _record_bytes(0x01),
		"a": context.accumulator,
		"x": context.x_register,
		"y": context.y_register,
		"saved_sp": context.stack_pointer,
		"bank_low": context.bank_low,
		"bank_high": context.bank_high,
	}


## Replays the known bank-$10 `$8097` caller plus `$C50F → $CAE7` seed.
## This method is an explicit source-caller operation; it does not decide when
## the route reaches `$8097` or schedule the resulting task.
func seed_scenario_callback_task(source_caller_pc: int) -> Dictionary:
	if not _require_initialized():
		return {}
	if source_caller_pc != 0x8097:
		_fail("Scenario callback seed requires a decoded bank-$10 caller PC of $8097.")
		return {}
	var source: PackedByteArray = _sources["scenario_setup"]
	if source != PackedByteArray([
		0xA2, 0x15, 0xA9, 0xF0, 0x95, 0x01, 0xA9, 0x0B, 0x95,
		0x02, 0xA9, 0x80, 0xA0, 0x08, 0x20, 0x0F, 0xC5, 0x60,
	]):
		_fail("Bank-$10 scenario setup no longer matches the verified callback task seed.")
		return {}
	var slot_base := int(source[1])
	var context: TaskContext = _contexts.get(slot_base)
	if context != null and context.phase not in [ContextPhase.EMPTY, ContextPhase.FINISHED]:
		_fail("Scenario callback slot $%02X is already occupied." % slot_base)
		return {}
	context = TaskContext.new()
	context.slot_base = slot_base
	context.phase = ContextPhase.SEEDED
	context.ready_delay = READY_SENTINEL
	context.stack_pointer = int(source[3])
	context.accumulator = int(source[11])
	context.x_register = slot_base
	context.y_register = int(source[13])
	context.bank_low = int(source[7])
	context.bank_high = 0
	context.source_return_word = (int(source[11]) << 8) | int(source[13])
	context.source_label = "bank-$10 callback caller $8097"
	_ram[slot_base] = READY_SENTINEL
	_ram[slot_base + 1] = context.stack_pointer
	_ram[slot_base + 2] = context.bank_low
	_ram[slot_base + 3] = context.bank_high
	_write_stack_byte(context.stack_pointer + 1, int(source[13]))
	_write_stack_byte(context.stack_pointer + 2, int(source[11]))
	_contexts[slot_base] = context
	var callback_entry: PackedByteArray = _sources["callback_entry"]
	var callback_reader_pc := int(callback_entry[1]) | (int(callback_entry[2]) << 8)
	return {
		"ok": true,
		"slot_base": slot_base,
		"record": _record_bytes(slot_base),
		"source_return_word": context.source_return_word,
		"initial_rts_pc": (context.source_return_word + 1) & 0xFFFF,
		"callback_entry_pc": (context.source_return_word + 1) & 0xFFFF,
		"callback_reader_pc": callback_reader_pc,
		"scheduled": false,
	}


## Applies the verified `$CB0F` save routine at a packaged caller site. The
## caller's SP is the pre-JSR stack pointer; caller state must come from a
## decoded task-body continuation.
func yield_at_verified_callsite(slot_base: int, source_pc: int, delay_in_a: int,
		caller_stack_pointer: int, saved_x: int, saved_y: int,
		current_bank_low: int, current_bank_high: int) -> bool:
	if not _require_initialized():
		return false
	var context: TaskContext = _contexts.get(slot_base)
	if _active_task_slot != slot_base or context == null or context.phase != ContextPhase.RUNNING:
		return _fail("Yield requires the currently running source task context.")
	var worker_jsr_already_executed := source_pc == 0x8886
	var expected_context_pc := 0xC515 if worker_jsr_already_executed else source_pc
	if context.program_counter != expected_context_pc or not _supported_yield_callsite(source_pc) or not _byte_arguments([
		delay_in_a, caller_stack_pointer, saved_x, saved_y, current_bank_low, current_bank_high,
	]):
		return _fail("Yield requires a packaged ROM-verified callsite and byte-valued CPU/task inputs.")
	if not _callsite_matches_source(source_pc):
		return false
	var sp := caller_stack_pointer
	if worker_jsr_already_executed:
		# `$8886` has already executed inside RomFreshBank18WorkerPrefix. The
		# resulting `$C515` state has the JSR return word on the real task stack;
		# validate it instead of pushing that same call frame a second time.
		if sp != context.stack_pointer or _stack_page[(sp + 1) & 0xFF] != ((source_pc + 2) & 0xFF) \
				or _stack_page[(sp + 2) & 0xFF] != (((source_pc + 2) >> 8) & 0xFF):
			return _fail("The `$8886` worker boundary does not carry its exact `$C515` JSR return word.")
	else:
		var return_minus_one := source_pc + 2
		_write_stack_byte(sp, (return_minus_one >> 8) & 0xFF)
		sp = (sp - 1) & 0xFF
		_write_stack_byte(sp, return_minus_one & 0xFF)
		sp = (sp - 1) & 0xFF
	_ram[0x007F] = delay_in_a # `$CB0F: STA $7F` before saving X/Y and task state.
	_write_stack_byte(sp, saved_x)
	sp = (sp - 1) & 0xFF
	_write_stack_byte(sp, saved_y)
	sp = (sp - 1) & 0xFF
	_ram[slot_base] = delay_in_a
	_ram[slot_base + 1] = sp
	_ram[slot_base + 2] = current_bank_low
	_ram[slot_base + 3] = current_bank_high
	context.ready_delay = delay_in_a
	context.accumulator = delay_in_a
	context.x_register = saved_x
	context.y_register = saved_y
	context.stack_pointer = sp
	context.bank_low = current_bank_low
	context.bank_high = current_bank_high
	context.program_counter = 0xCB0F
	context.pending_resume = ResumeKind.NONE
	context.phase = ContextPhase.YIELDED
	# `$CB0F` leaves Y as the current slot base, then `$CAA5` advances X by 4.
	_scheduler_y_register = slot_base
	_scheduler_scan_cursor = slot_base + 4
	_active_task_slot = -1
	return true


## Bridges the already-dispatched slot-$05 context to the verified ROM-byte
## worker result at `$C515`. Only its active stack window and CPU/mapper state
## are adopted; the worker's partial RAM image never overwrites scheduler or
## other task records.
func adopt_bank18_worker_prefix_state(slot_base: int, worker_state: Dictionary) -> bool:
	if not _require_initialized():
		return false
	var context: TaskContext = _contexts.get(slot_base)
	if slot_base != 0x05 or _active_task_slot != slot_base or context == null \
			or context.phase != ContextPhase.RUNNING or context.program_counter != 0xD11E:
		return _fail("Bank-$18 worker adoption requires the active ROM-dispatched slot-$05 `$D11E` task.")
	if String(worker_state.get("rom_sha256", "")) != ROM_SHA256 \
			or String(worker_state.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/manifest.json" \
			or int(worker_state.get("entry_pc", -1)) != 0x800C \
			or int(worker_state.get("entry_bank", -1)) != 0x18 \
			or int(worker_state.get("exit_pc", -1)) != 0xC515 \
			or int(worker_state.get("exit_bank", -1)) != 0x1E:
		return _fail("Worker state is not the packaged ROM-byte `$800C->$8886->$C515` result.")
	var registers_variant: Variant = worker_state.get("registers", {})
	var mapper_variant: Variant = worker_state.get("mapper", {})
	var ram_variant: Variant = worker_state.get("ram_image", PackedByteArray())
	var stack_variant: Variant = worker_state.get("stack_page", PackedByteArray())
	var calls_variant: Variant = worker_state.get("calls", [])
	if not registers_variant is Dictionary or not mapper_variant is Dictionary \
			or not ram_variant is PackedByteArray or not stack_variant is PackedByteArray \
			or not calls_variant is Array:
		return _fail("Worker state omits the source-derived CPU, mapper, RAM, stack, or call contract.")
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var ram_image: PackedByteArray = ram_variant
	var worker_stack: PackedByteArray = stack_variant
	var calls: Array = calls_variant
	if ram_image.size() != RAM_SIZE or worker_stack.size() != STACK_PAGE_SIZE \
			or int(registers.get("a", -1)) != 0x01 or int(registers.get("x", -1)) != 0xFF \
			or int(registers.get("y", -1)) != 0x00 or int(registers.get("p", -1)) != 0x20 \
			or int(registers.get("sp", -1)) != 0x48 or int(registers.get("pc", -1)) != 0xC515 \
			or int(mapper.get("bank_low", -1)) != 0x18 or int(mapper.get("bank_high", -1)) != 0x19 \
			or int(mapper.get("select", -1)) != 0x07:
		return _fail("Worker output does not carry the byte-verified `$C515` register/mapper state.")
	if _record_bytes(slot_base) != PackedByteArray([0xFF, 0x50, 0x00, 0x00]) \
			or context.source_return_word != 0xD11D:
		return _fail("Live slot-$05 scheduler record/RTS continuation is not the ROM-seeded `$D11E` task.")
	if calls.size() != 1 or not calls[0] is Dictionary \
			or int(calls[0].get("callsite", -1)) != 0x8886 \
			or int(calls[0].get("target", -1)) != 0xC515 \
			or int(calls[0].get("sp_after_push", -1)) != 0x48:
		return _fail("Worker output does not prove the real `$8886 JSR $C515` stack contract.")
	if worker_stack.slice(0x49, 0x51).hex_encode() != "888898ef1d1ccbda":
		return _fail("Worker stack continuation above `$C515` differs from the source wrapper chain.")
	for stack_address in range(0x49, 0x51):
		_stack_page[stack_address] = worker_stack[stack_address]
	context.accumulator = int(registers["a"])
	context.x_register = int(registers["x"])
	context.y_register = int(registers["y"])
	context.stack_pointer = int(registers["sp"])
	context.program_counter = int(registers["pc"])
	context.bank_low = int(mapper["bank_low"])
	context.bank_high = int(mapper["bank_high"])
	context.source_label = "ROM-byte fresh bank-$18 worker through `$8886->$C515`"
	return true


## Applies `$CAF7` only when the source runner reports execution at that handler.
## It clears record +0/+1 and preserves the stored bank bytes/stack page.
func finish_task_at_handler(slot_base: int, source_pc: int) -> bool:
	if not _require_initialized():
		return false
	var context: TaskContext = _contexts.get(slot_base)
	if _active_task_slot != slot_base or context == null or context.phase != ContextPhase.RUNNING:
		return _fail("Task finish requires the currently running source context.")
	if source_pc != 0xCAF7 or context.program_counter != source_pc or not _finish_handler_matches_source():
		return _fail("Task finish requires the verified source handler at $CAF7.")
	_ram[slot_base] = 0
	_ram[slot_base + 1] = 0
	context.ready_delay = 0
	context.phase = ContextPhase.FINISHED
	context.pending_resume = ResumeKind.NONE
	_scheduler_y_register = context.y_register
	_scheduler_scan_cursor = slot_base + 4
	_active_task_slot = -1
	return true


func get_task_context(slot_base: int) -> TaskContext:
	return _contexts.get(slot_base)


## Applies only the ordered writes produced by the current slot-$05 ROM-byte
## components. The component RAM images are validation references, never
## copied over scheduler-owned slots, the active-slot pointer, or NMI latch.
func merge_source_ordered_worker_writes(slot_base: int, period_result: Dictionary,
		continuation_result: Dictionary, worker_result: Dictionary) -> Dictionary:
	if not _require_initialized():
		return {}
	var context: TaskContext = _contexts.get(slot_base)
	if slot_base != 0x05 or _active_task_slot != slot_base or context == null \
			or context.phase != ContextPhase.RUNNING or context.program_counter != 0xD11E \
			or int(_ram[0x0000]) != slot_base:
		_fail("Source RAM merge requires the currently dispatched slot-$05 `$D11E` task.")
		return {}
	if _merged_source_write_prefixes.has(slot_base):
		_fail("This slot-$05 source write prefix was already merged.")
		return {}
	if not _validate_source_write_chain(period_result, continuation_result, worker_result):
		return {}
	var merged_writes: Array[Dictionary] = []
	var unique_addresses: Dictionary = {}
	var stream_results: Array[Dictionary] = [period_result, continuation_result, worker_result]
	for source_result: Dictionary in stream_results:
		var writes: Array = source_result.get("writes", [])
		for write_variant in writes:
			if not write_variant is Dictionary:
				_fail("A ROM-source write stream contains a malformed entry.")
				return {}
			var write: Dictionary = write_variant
			var address := int(write.get("address", -1))
			var value := int(write.get("value", -1))
			if address < 0 or address >= RAM_SIZE or value < 0 or value > 0xFF \
					or not write.has("pc") or _is_scheduler_owned_ram_address(address):
				_fail("ROM-source write at PC `$%04X` conflicts with scheduler-owned RAM or is invalid." % int(write.get("pc", -1)))
				return {}
			merged_writes.append(write.duplicate(true))
			unique_addresses[address] = true
	for write: Dictionary in merged_writes:
		var address := int(write["address"])
		var value := int(write["value"])
		_ram[address] = value
		if address >= 0x0100 and address < 0x0200:
			_stack_page[address & 0xFF] = value
	_merged_source_write_prefixes[slot_base] = true
	return {
		"ok": true,
		"slot_base": slot_base,
		"source_order": ["fresh_period_D11E_DAAA", "fresh_continuation_DAAA_800C", "bank18_worker_800C_C515"],
		"write_count": merged_writes.size(),
		"unique_address_count": unique_addresses.size(),
		"reserved_address_write_count": 0,
		"scheduler_task_records_after": _task_record_snapshot(),
		"active_slot_pointer_0000": int(_ram[0x0000]),
		"nmi_ready_latch_001b": int(_ram[0x001B]),
		"full_ram_image_copied": false,
		"next_boundary": "CB0F save; NMI/task scheduling is not included",
	}


func get_status() -> Dictionary:
	return {
		"configured": _configured,
		"initialized": _initialized,
		"error": error_message,
		"rom_sha256": ROM_SHA256,
		"task_slots": _task_record_snapshot() if _initialized else [],
		"scheduler_ready_latch_001b": int(_ram[0x001B]) if _initialized else -1,
		"ppu_ctrl_shadow": _ppu_ctrl_shadow,
		"active_task_slot": _active_task_slot,
		"scheduler_y_register": _scheduler_y_register,
		"scheduler_scan_cursor": _scheduler_scan_cursor,
		"does_execute_6502": false,
		"does_synthesize_nmi_cadence": false,
		"does_execute_full_task_bodies": false,
		"does_execute_bounded_root_slot01_startup": true,
	}


## Returns the bounded source-task fields needed to review a yield boundary.
func get_task_boundary_snapshot(slot_base: int) -> Dictionary:
	var context: TaskContext = _contexts.get(slot_base)
	if not _initialized or context == null:
		return {}
	return {
		"slot_base": context.slot_base,
		"phase": context.phase,
		"ready_delay": context.ready_delay,
		"pending_resume": context.pending_resume,
		"pc": context.program_counter,
		"sp": context.stack_pointer,
		"a": context.accumulator,
		"x": context.x_register,
		"y": context.y_register,
		"bank_low": context.bank_low,
		"bank_high": context.bank_high,
		"record": _record_bytes(slot_base),
		"ram_007F": int(_ram[0x007F]),
		"ram_image": _ram.duplicate(),
		"stack_page": _stack_page.duplicate(),
		"active_task_slot": _active_task_slot,
		"scheduler_y_register": _scheduler_y_register,
		"scheduler_scan_cursor": _scheduler_scan_cursor,
	}


func _validate_source_write_chain(period_result: Dictionary, continuation_result: Dictionary,
		worker_result: Dictionary) -> bool:
	if String(period_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(period_result.get("source_code_sha256", "")) != "28895a5c3512a45e1b1a59c4324654ec03bb5f2ea413445e32333aa3bd6b87cc" \
			or int(period_result.get("exit_pc", -1)) != 0xDAAA:
		return _fail("Period write stream is not the hash-checked `$D11E->$DAAA` ROM result.")
	var period_entry: Dictionary = period_result.get("entry", {})
	var period_dispatch: Dictionary = period_result.get("scheduler_dispatch", {})
	if int(period_entry.get("slot_base", -1)) != 0x05 or int(period_entry.get("pc", -1)) != 0xD11E \
			or int(period_entry.get("sp", -1)) != 0x52 \
			or int(period_dispatch.get("slot_base", -1)) != 0x05 \
			or int(period_dispatch.get("pc", -1)) != 0xD11E \
			or int(period_dispatch.get("source_return_word", -1)) != 0xD11D:
		return _fail("Period write stream has no source-derived slot-$05 scheduler dispatch.")
	if String(continuation_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(continuation_result.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/fresh_daaa_continuation/manifest.json" \
			or int(continuation_result.get("entry_pc", -1)) != 0xDAAA \
			or int(continuation_result.get("exit_pc", -1)) != 0x800C:
		return _fail("Continuation write stream is not the packaged `$DAAA->$800C` ROM result.")
	if String(worker_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(worker_result.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/manifest.json" \
			or int(worker_result.get("entry_pc", -1)) != 0x800C \
			or int(worker_result.get("exit_pc", -1)) != 0xC515:
		return _fail("Worker write stream is not the packaged `$800C->$C515` ROM result.")
	for source_result: Dictionary in [period_result, continuation_result, worker_result]:
		var writes_variant: Variant = source_result.get("writes", [])
		if not writes_variant is Array or writes_variant.is_empty():
			return _fail("A ROM-source write stream is missing or empty.")
	return true


func _is_scheduler_owned_ram_address(address: int) -> bool:
	if address == 0x0000 or address == 0x001B:
		return true
	for slot_base: int in SLOT_BASES:
		if address >= slot_base and address < slot_base + 4:
			return true
	return false


func _write_stack_byte(stack_pointer: int, value: int) -> void:
	var address := stack_pointer & 0xFF
	var byte_value := value & 0xFF
	_stack_page[address] = byte_value
	_ram[0x0100 | address] = byte_value


func _verify_source_recipes() -> bool:
	var zero_fill: PackedByteArray = _sources["ram_zero_fill"]
	var expected_zero_fill := PackedByteArray([
		0xA9, 0x00, 0x85, 0x00, 0x85, 0x01, 0xA8, 0xA2, 0x08,
		0x91, 0x00, 0xC8, 0xD0, 0xFB, 0xE6, 0x01, 0xCA, 0xD0, 0xF6,
	])
	if zero_fill.slice(23, 42) != expected_zero_fill:
		return _fail("Cold-RAM zero-fill instruction recipe differs from the checked ROM bytes.")
	var clear := PackedByteArray([
		0xA2, 0xE0, 0x9A, 0xA9, 0x00, 0x85, 0x01, 0x85, 0x02,
		0xA9, 0x00, 0x85, 0x05, 0x85, 0x06, 0xA9, 0x00, 0x85, 0x09,
		0x85, 0x0A, 0xA9, 0x00, 0x85, 0x0D, 0x85, 0x0E, 0xA9, 0x00,
		0x85, 0x11, 0x85, 0x12, 0xA9, 0x00, 0x85, 0x15, 0x85, 0x16,
		0x20, 0x1F, 0xCF,
	])
	if _sources["task_slot_clear"] != clear:
		return _fail("Fresh-game task-slot clear sequence differs from the checked ROM bytes.")
	var bootstrap: PackedByteArray = _sources["gameplay_bootstrap"]
	if bootstrap.slice(0, 4) != PackedByteArray([0xA9, 0x00, 0x85, 0x1B]) \
			or bootstrap.slice(7, 11) != PackedByteArray([0xA9, 0x08, 0x85, 0x20]) \
			or bootstrap.slice(0x70, 0x7E) != PackedByteArray([
				0xA5, 0x20, 0x09, 0x80, 0x85, 0x20, 0x85, 0x19,
				0x8D, 0x00, 0x20, 0x4C, 0x97, 0xCA,
			]):
		return _fail("Fresh-game bootstrap latch, PPUCTRL, or scheduler-entry bytes changed.")
	var root_startup: PackedByteArray = _sources["root_slot01_startup"]
	if root_startup != PackedByteArray([
		0xA5, 0x21, 0x09, 0x1E, 0x85, 0x21, 0xA9, 0x00, 0x8D, 0x90, 0x04,
		0xA9, 0x02, 0x8D, 0x91, 0x04, 0x8D, 0x87, 0x00, 0xA9, 0x00, 0x85,
		0x8E, 0xA9, 0x01, 0x8D, 0x69, 0x04, 0xA9, 0x01, 0x8D, 0x43, 0x05,
		0xA9, 0x23, 0x8D, 0x44, 0x05, 0xA9, 0x45, 0x8D, 0x45, 0x05, 0xA9,
		0x01, 0x20, 0x0F, 0xCB,
	]):
		return _fail("Root slot `$01` startup span `$CA22–$CA51` differs from the checked ROM bytes.")
	var scheduler: PackedByteArray = _sources["scheduler"]
	var scheduler_prefix := PackedByteArray([
		0xA2, 0x01, 0xB5, 0x00, 0xF0, 0x08, 0xC9, 0xFF, 0xF0, 0x33,
		0xD6, 0x00, 0xF0, 0x14, 0x8A, 0x18, 0x69, 0x04, 0xAA, 0xE0,
		0x19, 0xD0, 0xEB, 0xA5, 0x1B, 0x10, 0xFC, 0x29, 0x7F, 0x85,
		0x1B, 0x4C, 0x97, 0xCA,
	])
	if scheduler.slice(0, scheduler_prefix.size()) != scheduler_prefix:
		return _fail("Six-slot scheduler scan and NMI latch instructions changed.")
	var setup: PackedByteArray = _sources["scenario_setup"]
	if setup != PackedByteArray([
		0xA2, 0x15, 0xA9, 0xF0, 0x95, 0x01, 0xA9, 0x0B, 0x95,
		0x02, 0xA9, 0x80, 0xA0, 0x08, 0x20, 0x0F, 0xC5, 0x60,
	]):
		return _fail("Bank-$10 callback task setup differs from the checked ROM sequence.")
	if _sources["task_create"] != PackedByteArray([0x4C, 0xE7, 0xCA]) \
			or _sources["task_seed"] != PackedByteArray([
				0x48, 0x98, 0xB4, 0x01, 0x99, 0x01, 0x01, 0x68,
				0x99, 0x02, 0x01, 0xA9, 0xFF, 0x95, 0x00, 0x60,
			]):
		return _fail("$C50F/$CAE7 task creation instructions changed.")
	if _sources["yield_callsite"] != PackedByteArray([0x20, 0x15, 0xC5]) \
			or _sources["yield_trampoline"] != PackedByteArray([0x4C, 0x0F, 0xCB]):
		return _fail("Verified `$856F→$C515→$CB0F` yield path changed.")
	if _sources["callback_entry"][0] != 0x4C:
		return _fail("Bank-$0B callback entry no longer uses its verified absolute jump.")
	if not _callsite_matches_source(0x856F) or not _callsite_matches_source(0x8886) \
			or not _callsite_matches_source(0xCA4F) \
			or not _finish_handler_matches_source():
		return false
	var nmi_vectors: PackedByteArray = _sources["nmi_vectors"]
	if nmi_vectors[0] != 0x00 or nmi_vectors[1] != 0xC5 \
			or _sources["nmi_vector_entry"] != PackedByteArray([0x4C, 0x6E, 0xC7]):
		return _fail("Fixed NMI vector/entry no longer resolve to `$C500→$C76E`.")
	return true


func _decode_root_seed(seed: PackedByteArray) -> Dictionary:
	if seed.size() != 17 or seed[0] != 0xA2 or seed[2] != 0xA9 \
			or seed[4] != 0x95 or seed[5] != 0x01 or seed[6] != 0xA9 \
			or seed[8] != 0x95 or seed[9] != 0x02 or seed[10] != 0xA9 \
			or seed[12] != 0xA0 or seed[14] != 0x20 or seed[15] != 0xE7 or seed[16] != 0xCA:
		return {}
	return {
		"slot": int(seed[1]),
		"saved_sp": int(seed[3]),
		"bank_low": int(seed[7]),
		"bank_high": 0,
		"return_high": int(seed[11]),
		"return_low": int(seed[13]),
		"return_word": (int(seed[11]) << 8) | int(seed[13]),
	}


func _callsite_matches_source(source_pc: int) -> bool:
	if source_pc == 0xCA4F:
		var root_code: PackedByteArray = _sources.get("root_slot01_startup", PackedByteArray())
		return root_code.size() == 48 and root_code.slice(0x2D, 0x30) == PackedByteArray([0x20, 0x0F, 0xCB])
	if source_pc == 0x8886:
		var worker_call: PackedByteArray = _sources.get("bank18_worker_yield_callsite", PackedByteArray())
		var trampoline: PackedByteArray = _sources.get("yield_trampoline", PackedByteArray())
		return worker_call == PackedByteArray([0x20, 0x15, 0xC5]) \
				and trampoline == PackedByteArray([0x4C, 0x0F, 0xCB])
	if source_pc != 0x856F:
		return _fail("No preserved yield-callsite source span exists for `$%04X`." % source_pc)
	var yield_code: PackedByteArray = _sources.get("task_yield", PackedByteArray())
	var expected := PackedByteArray([
		0x85, 0x7F, 0x8A, 0x48, 0x98, 0x48, 0xA6, 0x00, 0xA5, 0x24,
		0x95, 0x02, 0xA5, 0x25, 0x95, 0x03, 0xA5, 0x7F, 0x95, 0x00,
		0x8A, 0xA8, 0xBA, 0x96, 0x01, 0xA6, 0x00, 0x4C, 0xA5, 0xCA,
	])
	if yield_code != expected:
		return _fail("`$CB0F` task-yield save instructions changed.")
	return true


func _supported_yield_callsite(source_pc: int) -> bool:
	return source_pc == 0x856F or source_pc == 0x8886 or source_pc == 0xCA4F


func _finish_handler_matches_source() -> bool:
	var finish_code: PackedByteArray = _sources.get("task_finish", PackedByteArray())
	var expected := PackedByteArray([
		0xA9, 0x00, 0xA6, 0x00, 0x95, 0x00, 0x95, 0x01, 0x4C, 0xA5, 0xCA,
	])
	if finish_code != expected:
		return _fail("`$CAF7` task-finish instructions changed.")
	return true


func _require_initialized() -> bool:
	if not _configured:
		return _fail("Configure packaged ROM-derived spans before using the scheduler.")
	if not _initialized:
		return _fail("Initialize fresh-game bootstrap state before using the scheduler.")
	return true


func _scan_result(decision: int, slot_base: int, checked_slots: Array[int]) -> Dictionary:
	return {
		"ok": true,
		"decision": decision,
		"selected_slot_base": slot_base,
		"ready_delays_after": _ready_delay_snapshot(),
		"ready_latch_after": int(_ram[0x001B]),
		"checked_slots": checked_slots.duplicate(),
		"scheduler_y_register": _scheduler_y_register,
		"scheduler_scan_cursor": _scheduler_scan_cursor,
	}


func _scan_failure(message: String, checked_slots: Array[int]) -> Dictionary:
	_fail(message)
	return {"ok": false, "error": error_message, "checked_slots": checked_slots.duplicate()}


func _dispatch_result(context: TaskContext, path: String) -> Dictionary:
	return {
		"ok": true,
		"slot_base": context.slot_base,
		"resume_path": path,
		"pc": context.program_counter,
		"sp": context.stack_pointer,
		"a": context.accumulator,
		"x": context.x_register,
		"y": context.y_register,
		"bank_low": context.bank_low,
		"bank_high": context.bank_high,
		"source_return_word": context.source_return_word,
		"source_return_bytes": [context.source_return_word & 0xFF, (context.source_return_word >> 8) & 0xFF],
		"phase": context.phase,
	}


func _task_record_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot_base: int in SLOT_BASES:
		result.append({"slot_base": slot_base, "bytes": _record_bytes(slot_base)})
	return result


func _root_return_words() -> Array[int]:
	var result: Array[int] = []
	for slot_base: int in [0x01, 0x05, 0x09]:
		var context: TaskContext = _contexts[slot_base]
		result.append(context.source_return_word)
	return result


func _root_stack_pointers() -> Array[int]:
	var result: Array[int] = []
	for slot_base: int in [0x01, 0x05, 0x09]:
		var context: TaskContext = _contexts[slot_base]
		result.append(context.stack_pointer)
	return result


func _record_bytes(slot_base: int) -> PackedByteArray:
	return PackedByteArray([
		int(_ram[slot_base]), int(_ram[slot_base + 1]),
		int(_ram[slot_base + 2]), int(_ram[slot_base + 3]),
	])


func _ready_delay_snapshot() -> PackedByteArray:
	var result := PackedByteArray()
	for slot_base: int in SLOT_BASES:
		result.append(int(_ram[slot_base]))
	return result


func _stack_pop(context: TaskContext) -> int:
	context.stack_pointer = (context.stack_pointer + 1) & 0xFF
	return int(_stack_page[context.stack_pointer])


func _byte_arguments(values: Array[int]) -> bool:
	for value: int in values:
		if value < 0 or value > 0xFF:
			return false
	return true


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()


func _fail(message: String) -> bool:
	error_message = message
	return false
