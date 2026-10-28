extends RefCounted
class_name RomGameplayRootTaskBootstrapModel
## Diagnostic-only model of the fresh-game scheduler bootstrap and NMI-ready
## latch write. It is not referenced by the production route and does not
## execute the task bodies or simulate PPU/NMI timing.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const READY_SENTINEL := 0xFF
const NMI_ENABLE_MASK := 0x80
const NMI_READY_MASK := 0x80
const NMI_MODE_MASK := 0x40
const INITIAL_RAM_SIZE := 0x800
const ROOT_TASK_SEED_OFFSET := 0x3D # $C725 relative to the $C6E8 span.
const ROOT_TASK_SEED_LENGTH := 17
const ROOT_TASK_SLOTS := [0x01, 0x05, 0x09]

const SOURCE_SPANS := {
	"ram_zero_fill": {
		"path": "res://reference/rom_extract/gameplay/task_context/fixed_ram_zero_fill_C650_C679.bin",
		"offset": 0x03C660, "length": 42,
		"sha256": "076731fdd07d2c05fcc4c27d65cf0ed29193b97ac79a02501b7f2051082705d9",
	},
	"task_slot_clear": {
		"path": "res://reference/rom_extract/gameplay/task_context/fixed_task_slot_clear_C6BE_C6E7.bin",
		"offset": 0x03C6CE, "length": 42,
		"sha256": "4e62f14d490b37ece22e2cec5f55846ddbb6235efa54100634602c20cb29f73e",
	},
	"gameplay_bootstrap": {
		"path": "res://reference/rom_extract/gameplay/task_context/fixed_task_gameplay_bootstrap_C6E8_C765.bin",
		"offset": 0x03C6F8, "length": 126,
		"sha256": "dfb460088ed63655a5627ebc5c06f111061b00f0a6d48af562dc995bb67c1160",
	},
	"nmi_gate_and_normal_ready": {
		"path": "res://reference/rom_extract/gameplay/task_context/fixed_task_nmi_gate_and_ready_C76E_C7EF.bin",
		"offset": 0x03C77E, "length": 130,
		"sha256": "a8c2e5e208b5e45900e2fbca7cb75eda18f46231edc989200c723968aa091315",
	},
	"nmi_special_dispatch": {
		"path": "res://reference/rom_extract/gameplay/task_context/fixed_task_nmi_special_dispatch_C421_C43C.bin",
		"offset": 0x03C431, "length": 28,
		"sha256": "6389b19db8e0a662875a3dba68c5bd642fb75a0dfd2fc80fcfd4ef8344cd0bb2",
	},
	"nmi_special_ready_path": {
		"path": "res://reference/rom_extract/gameplay/task_context/bank02_nmi_ready_path_A000_A137.bin",
		"offset": 0x004010, "length": 312,
		"sha256": "4f938bdaec443590eca1a814afef66fb2be987abafc5c2bba677f8c415a81412",
	},
	"nmi_vectors": {
		"path": "res://reference/rom_extract/gameplay/task_context/fixed_nmi_vectors_FFFA_FFFF.bin",
		"offset": 0x04000A, "length": 6,
		"sha256": "72925dda7194399d7eb27eb4a7d41a2b4d4b8be47b049bc1fd06f95f6627edec",
	},
	"nmi_vector_entry": {
		"path": "res://reference/rom_extract/gameplay/task_context/fixed_nmi_vector_entry_C500.bin",
		"offset": 0x03C510, "length": 3,
		"sha256": "a8d9fc1dc189a985f762edb564889dbab0a9bc7b4dcced5b1ef17c6933ecf0b5",
	},
	"nmi_return_enable": {
		"path": "res://reference/rom_extract/gameplay/task_context/fixed_nmi_return_enable_C810_C820.bin",
		"offset": 0x03C820, "length": 17,
		"sha256": "1ddfe0a969927fb72713998c3454eae9c61053616ba747d6b6318f9a7cd3df75",
	},
	"task_seed": {
		"path": "res://reference/rom_extract/gameplay/task_context/fixed_task_seed_CAE7.bin",
		"offset": 0x03CAF7, "length": 16,
		"sha256": "139a8a1b3241ae60cebf1057463d3947c20f219b728ab98e2429ee2a0f3e3a55",
	},
}

const EXPECTED_RAM_ZERO_FILL := [
	0xA9, 0x00, 0x85, 0x00, 0x85, 0x01, 0xA8, 0xA2, 0x08,
	0x91, 0x00, 0xC8, 0xD0, 0xFB, 0xE6, 0x01, 0xCA, 0xD0, 0xF6,
]
const EXPECTED_TASK_SLOT_CLEAR := [
	0xA2, 0xE0, 0x9A,
	0xA9, 0x00, 0x85, 0x01, 0x85, 0x02,
	0xA9, 0x00, 0x85, 0x05, 0x85, 0x06,
	0xA9, 0x00, 0x85, 0x09, 0x85, 0x0A,
	0xA9, 0x00, 0x85, 0x0D, 0x85, 0x0E,
	0xA9, 0x00, 0x85, 0x11, 0x85, 0x12,
	0xA9, 0x00, 0x85, 0x15, 0x85, 0x16,
	0x20, 0x1F, 0xCF,
]
const EXPECTED_NMI_GATE := [0x24, 0x1B, 0x50, 0x03, 0x4C, 0x21, 0xC4]
const EXPECTED_NMI_READY_SET := [0xA5, 0x1B, 0x09, 0x80, 0x85, 0x1B]
const EXPECTED_NMI_SPECIAL_MAP_CALL := [0xA9, 0x02, 0x8D, 0x01, 0x80, 0x20, 0x00, 0xA0]

var error_message := ""
var _configured := false
var _sources: Dictionary = {}


static func source_span_specs() -> Dictionary:
	return SOURCE_SPANS.duplicate(true)


func configure(source_spans: Dictionary) -> bool:
	error_message = ""
	_configured = false
	_sources.clear()
	for key: String in SOURCE_SPANS:
		var spec: Dictionary = SOURCE_SPANS[key]
		var value: Variant = source_spans.get(key, PackedByteArray())
		if not value is PackedByteArray:
			return _fail("Missing preserved ROM source bytes for %s." % key)
		var bytes: PackedByteArray = value
		if bytes.size() != int(spec["length"]):
			return _fail("Source span %s has an unexpected length." % key)
		if _sha256(bytes) != String(spec["sha256"]):
			return _fail("Source span %s failed its SHA-256 check." % key)
		_sources[key] = bytes.duplicate()
	if not _verify_signatures():
		return false
	_configured = true
	return true


## Replays the source's cold-RAM-zero precondition, fresh-game task-byte clear,
## three literal root-task seeds, $CAE7 stack writes, $001B reset, and NMI enable.
## This is a bounded source model, not a complete title-to-gameplay RAM replay.
func derive_bootstrap() -> Dictionary:
	if not _configured:
		_fail("Configure the hash-checked ROM spans before deriving task state.")
		return {}
	var ram := PackedByteArray()
	ram.resize(INITIAL_RAM_SIZE)
	ram.fill(0)
	var stack_page := PackedByteArray()
	stack_page.resize(0x100)
	stack_page.fill(0)

	# C6BE resets the ready/SP bytes for all six slots; the zero-fill precondition
	# supplies bank bytes not rewritten by this path, including +3 for $01/$05/$09.
	for base: int in [0x01, 0x05, 0x09, 0x0D, 0x11, 0x15]:
		ram[base] = 0
		ram[base + 1] = 0

	var bootstrap: PackedByteArray = _sources["gameplay_bootstrap"]
	if bootstrap.slice(0, 4) != PackedByteArray([0xA9, 0x00, 0x85, 0x1B]):
		_fail("$C6E8 no longer clears the scheduler mode/ready latch.")
		return {}
	var latch_001b := 0
	var ppu_ctrl_shadow := 0
	var ppu_ctrl_init := bootstrap.slice(7, 11)
	if ppu_ctrl_init != PackedByteArray([0xA9, 0x08, 0x85, 0x20]):
		_fail("Gameplay bootstrap no longer initializes the $2000 shadow to $08.")
		return {}
	ppu_ctrl_shadow = 0x08

	var root_tasks: Array[Dictionary] = []
	for task_index in range(ROOT_TASK_SLOTS.size()):
		var seed_offset := ROOT_TASK_SEED_OFFSET + task_index * ROOT_TASK_SEED_LENGTH
		var seed_bytes := bootstrap.slice(seed_offset, seed_offset + ROOT_TASK_SEED_LENGTH)
		var decoded := _decode_root_seed(seed_bytes)
		if decoded.is_empty():
			_fail("ROM root-task seed %d does not match the source instruction pattern." % task_index)
			return {}
		var slot: int = int(decoded["slot"])
		var saved_sp: int = int(decoded["saved_sp"])
		var bank_low: int = int(decoded["bank_low"])
		var return_low: int = int(decoded["return_low"])
		var return_high: int = int(decoded["return_high"])
		var return_pc := (return_high << 8) | return_low
		if slot != int(ROOT_TASK_SLOTS[task_index]):
			_fail("ROM root-task order no longer matches slots $01/$05/$09.")
			return {}
		if slot + 3 >= ram.size():
			_fail("Decoded root-task slot falls outside internal RAM.")
			return {}

		# Caller stores saved SP and bank +2; $CAE7 seeds +0=$FF and the RTS word.
		ram[slot + 1] = saved_sp
		ram[slot + 2] = bank_low
		ram[slot] = READY_SENTINEL
		var low_stack_index := (saved_sp + 1) & 0xFF
		var high_stack_index := (saved_sp + 2) & 0xFF
		stack_page[low_stack_index] = return_low
		stack_page[high_stack_index] = return_high
		root_tasks.append({
			"slot": slot,
			"record": PackedByteArray([ram[slot], ram[slot + 1], ram[slot + 2], ram[slot + 3]]),
			"saved_sp": saved_sp,
			"bank_low": bank_low,
			"bank_high": int(ram[slot + 3]),
			"return_pc": return_pc,
			"stack_low_index": low_stack_index,
			"stack_high_index": high_stack_index,
		})

	var nmi_enable_bytes := bootstrap.slice(0x70, 0x7E)
	var expected_enable := PackedByteArray([
		0xA5, 0x20, 0x09, 0x80, 0x85, 0x20, 0x85, 0x19,
		0x8D, 0x00, 0x20, 0x4C, 0x97, 0xCA,
	])
	if nmi_enable_bytes != expected_enable:
		_fail("$C758 no longer enables PPU NMI and jumps to $CA97.")
		return {}
	ppu_ctrl_shadow |= NMI_ENABLE_MASK
	var scheduler_gate: PackedByteArray = _sources["nmi_gate_and_normal_ready"].slice(0, 7)
	var normal_ready_bytes: PackedByteArray = _sources["nmi_gate_and_normal_ready"].slice(0x7C, 0x82)
	if scheduler_gate != PackedByteArray(EXPECTED_NMI_GATE) or normal_ready_bytes != PackedByteArray(EXPECTED_NMI_READY_SET):
		_fail("NMI gate or normal-mode $001B.7 setter changed from the audited bytes.")
		return {}
	if ppu_ctrl_shadow != 0x88:
		_fail("Bootstrap did not derive the expected NMI-enabled $2000 shadow.")
		return {}

	return {
		"ok": true,
		"ram_zero_fill_size": INITIAL_RAM_SIZE,
		"root_tasks": root_tasks,
		"stack_page": stack_page,
		"latch_001b": latch_001b,
		"ppu_ctrl_shadow": ppu_ctrl_shadow,
		"ppu_nmi_enabled": (ppu_ctrl_shadow & NMI_ENABLE_MASK) != 0,
		"scheduler_entry_pc": 0xCA97,
		"nmi_gate_mode_mask": NMI_MODE_MASK,
		"nmi_ready_mask": NMI_READY_MASK,
	}


## Applies the source-owned ready-bit write for one externally supplied NMI
## edge. It intentionally does not predict NMI cadence or execute other handlers.
func apply_nmi_ready_edge(bootstrap_state: Dictionary, latch_001b: int) -> Dictionary:
	if not _configured:
		_fail("Configure verified source spans before modeling an NMI edge.")
		return {}
	if not bool(bootstrap_state.get("ppu_nmi_enabled", false)):
		return {"ok": true, "serviced": false, "path": "nmi_disabled", "latch_after": latch_001b}
	if latch_001b < 0 or latch_001b > 0xFF:
		_fail("$001B must fit in one byte.")
		return {}
	var special_mode := (latch_001b & NMI_MODE_MASK) != 0
	var path_name := "bank02_mode6" if special_mode else "fixed_normal"
	if special_mode:
		var dispatch: PackedByteArray = _sources["nmi_special_dispatch"]
		var bank2_path: PackedByteArray = _sources["nmi_special_ready_path"]
		if dispatch.slice(0x14, 0x1C) != PackedByteArray(EXPECTED_NMI_SPECIAL_MAP_CALL):
			_fail("Bit-6 path no longer maps bank $02 at $A000.")
			return {}
		if bank2_path.slice(0x12F, 0x135) != PackedByteArray(EXPECTED_NMI_READY_SET):
			_fail("Bank-$02 NMI path no longer sets $001B.7 at $A12F.")
			return {}
	else:
		var normal_path: PackedByteArray = _sources["nmi_gate_and_normal_ready"]
		if normal_path.slice(0x7C, 0x82) != PackedByteArray(EXPECTED_NMI_READY_SET):
			_fail("Normal NMI path no longer sets $001B.7 at $C7EA.")
			return {}
	return {
		"ok": true,
		"serviced": true,
		"path": path_name,
		"latch_before": latch_001b,
		"latch_after": latch_001b | NMI_READY_MASK,
		"writer_pc": 0xA135 if special_mode else 0xC7F0,
	}


## Resolves a source-clock NMI service after an external PPU model has supplied
## one NMI delivery event. It maps the ROM vector/gate/mode to the ready writer;
## it deliberately does not create the PPU event or predict its cycle.
func resolve_source_nmi_service(source_frame: int, ppu_ctrl_shadow: int,
		latch_001b: int, nmi_delivered: bool) -> Dictionary:
	if not _configured:
		_fail("Configure verified source spans before resolving an NMI service.")
		return {}
	if source_frame < 0 or source_frame > 0x7FFFFFFF:
		_fail("Source frame index must be a nonnegative 32-bit integer.")
		return {}
	if ppu_ctrl_shadow < 0 or ppu_ctrl_shadow > 0xFF or latch_001b < 0 or latch_001b > 0xFF:
		_fail("PPUCTRL and $001B must fit in one byte.")
		return {}
	if not nmi_delivered:
		return {"ok": true, "serviced": false, "source_frame": source_frame, "reason": "no_external_nmi_event"}
	if (ppu_ctrl_shadow & NMI_ENABLE_MASK) == 0:
		_fail("A delivered PPU NMI event conflicts with source $2000.7=0.")
		return {}
	var result := apply_nmi_ready_edge({"ppu_nmi_enabled": true}, latch_001b)
	if not bool(result.get("ok", false)):
		return result
	result["source_frame"] = source_frame
	result["edge_source"] = "externally supplied PPU NMI delivery"
	result["models_nmi_cycle"] = false
	return result


func get_source_status() -> Dictionary:
	return {
		"rom_sha256": ROM_SHA256,
		"source_spans": SOURCE_SPANS.duplicate(true),
		"root_task_slots": ROOT_TASK_SLOTS.duplicate(),
		"configured": _configured,
		"diagnostic_only": true,
		"models_nmi_service_mapping": true,
		"models_nmi_timing": false,
		"models_frame_cadence": false,
		"models_task_body_execution": false,
	}


func _decode_root_seed(bytes: PackedByteArray) -> Dictionary:
	if bytes.size() != ROOT_TASK_SEED_LENGTH:
		return {}
	if bytes[0] != 0xA2 or bytes[2] != 0xA9 or bytes[4] != 0x95 or bytes[5] != 0x01 \
			or bytes[6] != 0xA9 or bytes[8] != 0x95 or bytes[9] != 0x02 \
			or bytes[10] != 0xA9 or bytes[12] != 0xA0 or bytes[14] != 0x20 \
			or bytes[15] != 0xE7 or bytes[16] != 0xCA:
		return {}
	return {
		"slot": int(bytes[1]),
		"saved_sp": int(bytes[3]),
		"bank_low": int(bytes[7]),
		"return_high": int(bytes[11]),
		"return_low": int(bytes[13]),
	}


func _verify_signatures() -> bool:
	var ram_clear: PackedByteArray = _sources["ram_zero_fill"]
	if ram_clear.size() != 42 or ram_clear.slice(23, 42) != PackedByteArray(EXPECTED_RAM_ZERO_FILL):
		return _fail("Cold-start RAM zero-fill loop no longer covers eight 256-byte pages.")
	if _sources["task_slot_clear"] != PackedByteArray(EXPECTED_TASK_SLOT_CLEAR):
		return _fail("Fresh-game task slot clearing bytes changed.")
	var bootstrap: PackedByteArray = _sources["gameplay_bootstrap"]
	if bootstrap.size() != 126:
		return _fail("Fresh-game bootstrap span has an unexpected length.")
	if bootstrap.slice(ROOT_TASK_SEED_OFFSET, ROOT_TASK_SEED_OFFSET + 51).size() != 51:
		return _fail("Fresh-game bootstrap omits one or more root task seed callsites.")
	var seed_helper: PackedByteArray = _sources["task_seed"]
	var expected_seed_helper := PackedByteArray([
		0x48, 0x98, 0xB4, 0x01, 0x99, 0x01, 0x01, 0x68,
		0x99, 0x02, 0x01, 0xA9, 0xFF, 0x95, 0x00, 0x60,
	])
	if seed_helper != expected_seed_helper:
		return _fail("$CAE7 source no longer writes $FF ready state and RTS stack bytes.")
	var gate_span: PackedByteArray = _sources["nmi_gate_and_normal_ready"]
	if gate_span.slice(0, 7) != PackedByteArray(EXPECTED_NMI_GATE):
		return _fail("$C76E mode gate bytes changed.")
	var dispatch: PackedByteArray = _sources["nmi_special_dispatch"]
	if dispatch.size() != 28 or dispatch.slice(0x14, 0x1C) != PackedByteArray(EXPECTED_NMI_SPECIAL_MAP_CALL):
		return _fail("$C421 mode-6 dispatcher does not map bank $02 and call $A000.")
	var special_path: PackedByteArray = _sources["nmi_special_ready_path"]
	if special_path.size() != 312 or special_path.slice(0x12F, 0x135) != PackedByteArray(EXPECTED_NMI_READY_SET):
		return _fail("Bank-$02 NMI path does not contain the source ready-latch setter.")
	var vectors: PackedByteArray = _sources["nmi_vectors"]
	if vectors != PackedByteArray([0x00, 0xC5, 0xF0, 0xFF, 0x06, 0xC5]):
		return _fail("NMI vector no longer points to $C500.")
	var vector_entry: PackedByteArray = _sources["nmi_vector_entry"]
	if vector_entry != PackedByteArray([0x4C, 0x6E, 0xC7]):
		return _fail("$C500 NMI trampoline no longer jumps to $C76E.")
	var handler_head := gate_span.slice(0x0C, 0x15)
	if handler_head != PackedByteArray([0xA5, 0x20, 0x29, 0x7F, 0x8D, 0x00, 0x20, 0x85, 0x20]):
		return _fail("Normal NMI handler no longer disables $2000.7 at entry.")
	if gate_span.slice(0x2E, 0x31) != PackedByteArray([0x2C, 0x02, 0x20]):
		return _fail("Normal NMI handler no longer reads $2002 to clear vblank.")
	var handler_return: PackedByteArray = _sources["nmi_return_enable"]
	if handler_return != PackedByteArray([
		0xA5, 0x20, 0x09, 0x80, 0x85, 0x20, 0x85, 0x19, 0x8D,
		0x00, 0x20, 0x68, 0xA8, 0x68, 0xAA, 0x68, 0x40,
	]):
		return _fail("Normal NMI return path no longer re-enables PPU NMI before RTI.")
	return true


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
