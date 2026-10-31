extends RefCounted
class_name RomGameplayTaskScheduler
## Bounded runtime model of the game's verified task-record/scheduler boundary.
## This is not a 6502 emulator: it does not execute task bodies, synthesize NMI
## cadence, or choose when callers create callbacks. A source runner must supply
## decoded call-site state and externally observed PPU NMI deliveries.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const TASK_CONTEXT_ROOT := "res://reference/rom_extract/gameplay/task_context/"
const SLOT11_RESUME_MANIFEST := "res://reference/rom_extract/gameplay/slot11_actor_worker_resume_wait/manifest.json"
const SLOT11_RESUME_WAITER_PATH := "res://reference/rom_extract/gameplay/slot11_actor_worker_resume_wait/fixed_task_yield_waiter_cc46_cc5d.bin"
const SLOT11_RESUME_WAITER_SHA256 := "dce4d011f0e612ea074e546e43c28c5395220f2af924a49aee4b35c2491775e3"
const SLOT11_RESUME_SOURCE_HASHES := {
	"bank18_actor_worker_resume_804a_80fd.bin": "9c07722c85a0670f8986a7e7a680bc205a587881383fd84276e520806f465c6e",
	"bank18_actor_stream_f4_f5_9f42_9f53.bin": "907c3653f2e64fa9d27a0a14a7dd38e404f0f1c05a97c0367be24e587f5ebadf",
	"bank18_match_index_pointer_resolver_8122_8138.bin": "f4acc27853404adda00ba3dcee5f5f4ecdb2939a5d026a6d8f459261497d35b0",
	"bank18_actor_stream_command_f5_81fd_8200.bin": "9ae06ade354ced65b80ae98704cd748b28b3fb80829dae0172ce09859fa37405",
	"fixed_c52d_jump_to_cc46.bin": "eb93189d38ebaea8201970900e5b276a27c54c6fa2001a705945cb1d5172f371",
	"fixed_task_yield_waiter_cc46_cc5d.bin": SLOT11_RESUME_WAITER_SHA256,
	"inline_dispatch": "3b507ee4745afd5b11dda219b523c39c7e9a8881d856592d8908bf535fd63441",
	"trampoline": "1f8058f9fd70aeec319a32433feb0c102c72e0f5131571a0da8bf89ef84a2d54",
}
const MAP42_WORKER_SOURCE_PATH := "res://reference/rom_extract/gameplay/first_command_field/map_worker_8525/bank_0b_8572_85c2.bin"
const MAP42_WORKER_SOURCE_SHA256 := "098a354cae578918bf54407b972e69b520327d030eb391ed3c2d476c4d337502"
const MANIFEST_PATH := TASK_CONTEXT_ROOT + "manifest.json"
const RAM_SIZE := 0x800
const STACK_PAGE_SIZE := 0x100
const READY_SENTINEL := 0xFF
const NMI_ENABLE_MASK := 0x80
const NMI_READY_MASK := 0x80
const NMI_MODE_MASK := 0x40
const NORMAL_NMI_QUEUE_CONSUMER_SCRIPT := preload("res://scripts/gameplay/rom_normal_nmi_ppu_queue_consumer.gd")
const CBF1_SOUND_QUEUE_EXECUTOR_SCRIPT := preload("res://scripts/gameplay/rom_slot09_cbf1_sound_queue_executor.gd")
const NORMAL_NMI_ENTRY_PROOF_SCHEMA := "rom-normal-nmi-c8fb-entry-proof-v1"
const NORMAL_NMI_CALL_PC := 0xC799
const NORMAL_NMI_QUEUE_ENTRY_PC := 0xC8FB
const POSITION_INITIALIZER_MANIFEST_PATH := "res://reference/rom_extract/gameplay/first_command_field/player_record_positions/manifest.json"
const POSITION_INITIALIZER_MANIFEST_SHA256 := "5a12a34630b7c38a13812c3280eef00c2fcbd74615ccac7f21a31d3d8a9eff2d"
const DAF5_RECEIVER_MANIFEST_PATH := "res://reference/rom_extract/gameplay/fresh_daf5_receiver_setup/manifest.json"
const DAF5_RECEIVER_MANIFEST_SHA256 := "41725f1115032b26c9499409a3e496aeffac9119ab651b2139003f5d07d285bf"
const HOLDER_COPY_MANIFEST_PATH := "res://reference/rom_extract/gameplay/first_command_field/holder_coordinates/manifest.json"
const HOLDER_COPY_MANIFEST_SHA256 := "aa951660b645d51a2c8fbfa6fbbc44026c478daea8bd8068b8afedf1a08b2bf3"
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
	"task_finish_trampoline": {
		"file": "fixed_task_finish_trampoline_C512.bin", "offset": 0x03C522,
		"length": 3, "sha256": "bc85dc6c05fac84b9063f3cb28a3acbe16e2591ab2dff53b935530aa2a35940f",
	},
	"scenario_queue": {
		"file": "fixed_scenario_queue_CBB0_CBC1.bin", "path": "res://reference/rom_extract/gameplay/scenario_task_runtime/fixed_scenario_queue_CBB0_CBC1.bin",
		"offset": 0x03CBC0, "length": 18, "sha256": "bda16c7ced2834027dd6039a6c079a701dc8abd9c89179ba2d3c568aa0a16a32",
	},
	"root_slot01_startup": {
		"file": "fixed_root_slot01_startup_CA22_CA51.bin", "offset": 0x03CA32,
		"length": 48, "sha256": "a2e9aa1047c184ff21854c6e30733f68f17bc7a4df68ff98e8622571d5c90476",
	},
	"root_slot09_loop": {
		"file": "fixed_root_slot09_loop_EB86_EC07.bin", "offset": 0x03EB96,
		"length": 130, "sha256": "91ee3ddc0110b7575a472103de8f5e4d1391a60efebe557b4f4238940d74f917",
	},
	"scenario_actor_worker_seed": {
		"file": "fixed_scenario_actor_worker_seed_ED15_ED2C.bin", "offset": 0x03ED25,
		"length": 24, "sha256": "61ef48dd58901f95f2c20f7f4a8bc1bb850221cb403f6bfbd52a65a12e33f551",
	},
	"slot11_actor_worker_prefix": {
		"file": "bank18_actor_worker_entry_8000_804A.bin", "offset": 0x030010,
		"length": 74, "sha256": "2187af6881ea2f4e7eb16c0c5550bb24ead076be918d429d8ab63564ed8fd46c",
	},
	"slot11_actor_parameter_73_pointer": {
		"file": "bank18_actor_parameter_73_pointer_9306.bin", "offset": 0x031316,
		"length": 2, "sha256": "03f3c4278cc253614b622fa856993e8b325eb061a29e54685038771778377938",
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
	var status_register: int = 0
	var status_known_mask: int = 0
	var bank_low: int = 0
	var bank_high: int = 0
	var mapper_state: Dictionary = {}
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
var _last_controller_sample := {"previous": 0, "current": 0, "newly_pressed": 0}
var _normal_nmi_queue_consumer: RefCounted
var _root_slot09_yield_in_progress := false
var _slot11_actor_worker_yield_in_progress := false
var _slot11_actor_resume_yield_in_progress := false
var _slot11_f5_animation_yield_in_progress := false
var _kickoff_rng_replay_last_applied_frame := -1
var _last_slot09_cb0f_save_result: Dictionary = {}
var _slot09_actor_seed_request: Dictionary = {}


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
		var path := String(spec.get("path", TASK_CONTEXT_ROOT + file_name))
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
	_kickoff_rng_replay_last_applied_frame = -1
	_initialized = false
	_active_task_slot = -1
	_root_slot09_yield_in_progress = false
	_merged_source_write_prefixes.clear()
	_scheduler_y_register = 0
	_scheduler_scan_cursor = 0x01
	_contexts.clear()
	_last_slot09_cb0f_save_result.clear()
	_slot11_actor_worker_yield_in_progress = false
	_slot11_actor_resume_yield_in_progress = false
	_slot11_f5_animation_yield_in_progress = false
	_slot09_actor_seed_request.clear()
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
	# The verified bootstrap tail leaves PPUCTRL enabled in both its shadow and
	# the NMI return byte used by `$CAB9/$CACD`.
	_ram[0x0020] = _ppu_ctrl_shadow
	_ram[0x0019] = _ppu_ctrl_shadow
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
## generated here: the caller owns whether/when an NMI was delivered. The
## normal path also executes the verified PPU-queue source component before
## setting the scheduler-ready latch.
func apply_external_nmi_delivery(source_frame: int, ppu_ctrl_shadow: int,
		nmi_delivered: bool) -> Dictionary:
	return service_external_nmi_delivery(source_frame, ppu_ctrl_shadow, nmi_delivered)


## Services an externally supplied NMI using only scheduler-owned RAM and the
## ROM-verified normal NMI call path. The `$C799->$C8FB` proof is constructed
## internally after validating the external edge and `$001B.6` mode gate.
func service_external_nmi_delivery(source_frame: int, ppu_ctrl_shadow: int,
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
	var normal_nmi_return_shadow := 0
	if not special_mode:
		var nmi_disabled_shadow := int(_ram[0x0020]) & 0x7F
		normal_nmi_return_shadow = nmi_disabled_shadow | NMI_ENABLE_MASK
		if normal_nmi_return_shadow != ppu_ctrl_shadow:
			_fail("Normal NMI PPUCTRL shadow mismatch: RAM[$0020]=$%02X implies enabled $%02X, caller supplied $%02X." % [int(_ram[0x0020]), normal_nmi_return_shadow, ppu_ctrl_shadow])
			return {}
		_ram[0x0020] = nmi_disabled_shadow
	var writer_pc := 0xA135 if special_mode else 0xC7F0
	var source_events: Array[Dictionary] = []
	var secondary_queue := {
		"status": "bypassed" if special_mode else "not_attempted",
		"branch": "special_mode_bypass" if special_mode else "unresolved",
		"transfer_performed": false,
		"primary_transfer_modeled": false,
	}
	var ppu_bus_events: Array[Dictionary] = []
	if special_mode:
		source_events.append({
			"sequence": source_events.size(), "event": "special_nmi_dispatch",
			"source_pc": 0xC76E, "target_pc": 0xC421,
		})
	else:
		var ram_001b_at_dispatch := int(_ram[0x001B])
		var proof := _build_normal_nmi_queue_entry_proof(ram_001b_at_dispatch)
		source_events.append({
			"sequence": source_events.size(), "event": "normal_nmi_dispatch",
			"source_pc": 0xC76E, "ram_001b": ram_001b_at_dispatch,
		})
		source_events.append({
			"sequence": source_events.size(), "event": "normal_nmi_queue_call",
			"source_pc": NORMAL_NMI_CALL_PC,
			"target_pc": NORMAL_NMI_QUEUE_ENTRY_PC,
		})
		if _normal_nmi_queue_consumer == null:
			_normal_nmi_queue_consumer = NORMAL_NMI_QUEUE_CONSUMER_SCRIPT.new()
		var consume_result: Dictionary = _normal_nmi_queue_consumer.call(
			"consume", _ram, {}, proof)
		var consume_status := String(consume_result.get("status", ""))
		if consume_status == "primary_queue_not_empty":
			secondary_queue = {
				"status": "skipped",
				"branch": "primary_queue_selected",
				"source_pc": NORMAL_NMI_QUEUE_ENTRY_PC,
				"primary_count": int(_ram[0x0498]),
				"transfer_performed": false,
				"primary_transfer_modeled": false,
			}
			source_events.append({
				"sequence": source_events.size(), "event": "primary_queue_selected",
				"source_pc": NORMAL_NMI_QUEUE_ENTRY_PC,
				"primary_count": int(_ram[0x0498]),
				"secondary_transfer_performed": false,
			})
		elif consume_status == "secondary_queue_not_ready":
			secondary_queue = {
				"status": "skipped",
				"branch": "secondary_queue_not_ready",
				"source_pc": 0xC951,
				"ready_flag_before": int(_ram[0x0515]),
				"transfer_performed": false,
				"primary_transfer_modeled": false,
			}
			source_events.append({
				"sequence": source_events.size(), "event": "secondary_queue_not_ready",
				"source_pc": 0xC951,
				"ready_flag": int(_ram[0x0515]),
				"secondary_transfer_performed": false,
			})
		elif bool(consume_result.get("ok", false)):
			if String(consume_result.get("source_rom_sha256", "")) != ROM_SHA256 \
					or int(consume_result.get("source_nmi_call_pc", -1)) != NORMAL_NMI_CALL_PC \
					or int(consume_result.get("source_entry_pc", -1)) != NORMAL_NMI_QUEUE_ENTRY_PC:
				_fail("Normal-NMI queue consumer returned a mismatched source boundary.")
				return {}
			var updated_ram: PackedByteArray = consume_result.get("updated_ram", PackedByteArray())
			if updated_ram.size() != RAM_SIZE:
				_fail("Normal-NMI queue consumer returned an invalid RAM image.")
				return {}
			_ram = updated_ram.duplicate()
			ppu_bus_events = consume_result.get("bus_events", [])
			var packets: Array = consume_result.get("packets", [])
			var queue_kind := String(consume_result.get("queue_kind", "secondary"))
			var transfer_performed := not ppu_bus_events.is_empty()
			var queue_branch := "primary_queue_consumed" if queue_kind == "primary" \
				and transfer_performed else "primary_queue_empty" if queue_kind == "primary" \
				else "secondary_queue_consumed" if transfer_performed else "secondary_queue_empty"
			var queue_source_pc := 0xC900 if queue_kind == "primary" else 0xC958
			secondary_queue = {
				"status": "transferred" if transfer_performed else "consumed_empty",
				"branch": queue_branch,
				"queue_kind": queue_kind,
				"source_pc": queue_source_pc,
				"ready_flag_before": int(consume_result.get("source_ready_flag_before", -1)),
				"ready_flag_after": int(_ram[0x0515]),
				"packet_count": packets.size(),
				"transfer_performed": transfer_performed,
				"primary_count_before": int(consume_result.get("primary_queue_count_before", -1)),
				"primary_count_after": int(consume_result.get("primary_queue_count_after", -1)),
				"primary_transfer_modeled": queue_kind == "primary",
			}
			source_events.append({
				"sequence": source_events.size(), "event": queue_branch,
				"source_pc": queue_source_pc,
				"ready_flag_after": int(_ram[0x0515]),
				"packet_count": packets.size(),
				"ppu_bus_event_count": ppu_bus_events.size(),
			})
		else:
			_fail("Normal-NMI queue consumer could not establish a safe source transfer: %s" % consume_status)
			return {}

	var latch_before := int(_ram[0x001B])
	_ram[0x001B] = int(_ram[0x001B]) | NMI_READY_MASK
	source_events.append({
		"sequence": source_events.size(), "event": "scheduler_ready_latch_set",
		"source_pc": writer_pc, "old": latch_before,
		"new": int(_ram[0x001B]),
	})
	if not special_mode:
		# `$C810-$C820` restores bit 7 to `$20`, copies the enabled shadow to
		# `$19`, writes `$2000`, then returns with RTI.
		_ram[0x0020] = normal_nmi_return_shadow
		_ram[0x0019] = normal_nmi_return_shadow
		source_events.append({
			"sequence": source_events.size(), "event": "normal_nmi_return_shadow_restored",
			"source_pc": 0xC816, "ram_0020": normal_nmi_return_shadow,
			"ram_0019": normal_nmi_return_shadow,
		})
	return {
		"ok": true,
		"serviced": true,
		"source_frame": source_frame,
		"path": "bank02_mode6" if special_mode else "fixed_normal",
		"writer_pc": writer_pc,
		"latch_after": int(_ram[0x001B]),
		"edge_source": "caller-supplied PPU NMI delivery",
		"models_nmi_cycle": false,
		"secondary_queue": secondary_queue,
		"ppu_bus_events": ppu_bus_events,
		"source_events": source_events,
	}


func _build_normal_nmi_queue_entry_proof(ram_001b_at_dispatch: int) -> Dictionary:
	return {
		"schema": NORMAL_NMI_ENTRY_PROOF_SCHEMA,
		"rom_sha256": ROM_SHA256,
		"nmi_kind": "normal",
		"call_site_pc": NORMAL_NMI_CALL_PC,
		"entry_pc": NORMAL_NMI_QUEUE_ENTRY_PC,
		"ram_001b_at_dispatch": ram_001b_at_dispatch,
		"source_dispatch_observed": (ram_001b_at_dispatch & NMI_MODE_MASK) == 0,
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
		_ram[0x0024] = context.bank_low
		_ram[0x0025] = context.bank_high
		_ram[0x0000] = slot_base
		_active_task_slot = slot_base
		return _dispatch_result(context, "initial_rts")
	if context.pending_resume == ResumeKind.YIELDED_TASK:
		if ready != 0 or context.phase != ContextPhase.YIELDED:
			_fail("Yielded resume no longer matches a zero-delay task record.")
			return {}
		# `$CAB9` shifts the scheduler return bit before bank restoration;
		# `$CACD` reconstructs it with SEC/ROR. PLA/TAY/PLA/TAX then leave
		# N/Z from the saved X byte. P is not part of a yielded task record.
		_ram[0x0019] = int(_ram[0x0019]) >> 1
		var resumed_carry := int(_ram[0x0019]) & 0x01
		_ram[0x0019] = 0x80 | (int(_ram[0x0019]) >> 1)
		context.bank_low = int(_ram[slot_base + 2])
		context.bank_high = int(_ram[slot_base + 3])
		context.stack_pointer = int(_ram[slot_base + 1])
		context.y_register = _stack_pop(context)
		context.x_register = _stack_pop(context)
		var low := _stack_pop(context)
		var high := _stack_pop(context)
		context.program_counter = (((high << 8) | low) + 1) & 0xFFFF
		context.accumulator = context.x_register
		context.status_register = 0x20 | resumed_carry
		if (context.x_register & 0x80) != 0:
			context.status_register |= 0x80
		if context.x_register == 0:
			context.status_register |= 0x02
		context.status_known_mask = 0x83
		context.pending_resume = ResumeKind.NONE
		context.phase = ContextPhase.RUNNING
		_ram[0x0024] = context.bank_low
		_ram[0x0025] = context.bank_high
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


## Executes only the source-verified `$EB86: LDA #$01; JSR $CB0F` prefix after
## the scheduler has dispatched the bootstrap-seeded slot `$09`. The full
## packaged loop is hash-checked, but later loop instructions are not run.
func execute_root_slot09_first_yield() -> Dictionary:
	if not _require_initialized():
		return {}
	var context: TaskContext = _contexts.get(0x09)
	if _active_task_slot != 0x09 or context == null \
			or context.phase != ContextPhase.RUNNING or context.program_counter != 0xEB86 \
			or context.source_return_word != 0xEB85 or context.accumulator != 0x78 \
			or context.x_register != 0x78 or context.stack_pointer != 0x7A \
			or context.bank_low != 0x00 or context.bank_high != 0x01 \
			or _record_bytes(0x09) != PackedByteArray([0xFF, 0x78, 0x00, 0x00]):
		_fail("Root slot `$09` first yield requires the source-dispatched `$EB86` bootstrap context.")
		return {}
	var source: PackedByteArray = _sources.get("root_slot09_loop", PackedByteArray())
	var prefix := PackedByteArray([0xA9, 0x01, 0x20, 0x0F, 0xCB])
	if source.size() != 130 or source.slice(0, prefix.size()) != prefix:
		_fail("Root slot `$09` `$EB86-$EB8A` yield prefix differs from the checked ROM bytes.")
		return {}
	# Execute exactly LDA #$01. The following source JSR is modeled by the
	# scheduler's shared CB0F save routine, which pushes its own return word.
	context.accumulator = int(source[1])
	context.program_counter = 0xEB88
	_root_slot09_yield_in_progress = true
	var yielded := yield_at_verified_callsite(0x09, 0xEB88, context.accumulator,
		context.stack_pointer, context.x_register, context.y_register,
		context.bank_low, context.bank_high)
	_root_slot09_yield_in_progress = false
	if not yielded:
		return {}
	var saved_sp := int(_ram[0x09 + 1])
	var return_low := int(_stack_page[(saved_sp + 3) & 0xFF])
	var return_high := int(_stack_page[(saved_sp + 4) & 0xFF])
	return {
		"ok": true,
		"slot_base": 0x09,
		"source_start_pc": 0xEB86,
		"yield_callsite_pc": 0xEB88,
		"yield_target_pc": 0xCB0F,
		"resume_pc": (((return_high << 8) | return_low) + 1) & 0xFFFF,
		"task_record": _record_bytes(0x09),
		"saved_stack_pointer": saved_sp,
		"saved_y": int(_stack_page[(saved_sp + 1) & 0xFF]),
		"saved_x": int(_stack_page[(saved_sp + 2) & 0xFF]),
		"scheduler_y_register": _scheduler_y_register,
		"scheduler_scan_cursor": _scheduler_scan_cursor,
		"active_task_slot": _active_task_slot,
		"source_span_sha256": String(SOURCE_SPANS["root_slot09_loop"]["sha256"]),
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
	# `$8097` writes the ready marker, stack pointer, and low bank only. Keep
	# the live high-bank byte at `$0018`; this source path does not clear it.
	context.bank_high = int(_ram[slot_base + 3])
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


## Adopts the source-produced slot-$09 prefix ending at the `$ED15` actor-seed
## caller. The result must start at the scheduler's live `$EB8B` boundary; its
## ordered RAM/stack/mapper effects are replayed over that boundary.
func adopt_slot09_actor_seed_caller_prefix(source_result: Dictionary) -> bool:
	if not _require_initialized():
		return false
	var context: TaskContext = _contexts.get(0x09)
	if _active_task_slot != 0x09 or int(_ram[0x0000]) != 0x09 \
			or context == null or context.phase != ContextPhase.RUNNING \
			or context.program_counter != 0xEB8B:
		return _fail("Actor-seed prefix adoption requires the live active slot-$09 `$EB8B` boundary.")
	if String(source_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(source_result.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/slot09_eb8b_continuation/manifest.json" \
			or String(source_result.get("status", "")) != "slot09_actor_worker_seed_ready_before_cae7" \
			or int(source_result.get("entry_pc", -1)) != 0xEB8B \
			or int(source_result.get("exit_pc", -1)) != 0xED15 \
			or int(source_result.get("active_slot", -1)) != 0x09 \
			or bool(source_result.get("trace_state_used", true)) \
			or bool(source_result.get("fixture_only", true)) \
			or bool(source_result.get("worker_body_executed", true)) \
			or bool(source_result.get("worker_body_bytes_read", true)):
		return _fail("Actor-seed prefix is not the ROM-derived slot-$09 `$EB8B->$ED15` result.")
	var entry_variant: Variant = source_result.get("entry_registers", {})
	var registers_variant: Variant = source_result.get("registers", {})
	var mapper_variant: Variant = source_result.get("mapper", {})
	var ram_variant: Variant = source_result.get("ram_image", PackedByteArray())
	var stack_variant: Variant = source_result.get("stack_page", PackedByteArray())
	var writes_variant: Variant = source_result.get("writes", [])
	var stack_writes_variant: Variant = source_result.get("stack_writes", [])
	var mapper_writes_variant: Variant = source_result.get("mapper_writes", [])
	var span_hashes_variant: Variant = source_result.get("source_span_hashes", {})
	var seed_request_variant: Variant = source_result.get("actor_worker_seed_request", {})
	if not entry_variant is Dictionary or not registers_variant is Dictionary \
			or not mapper_variant is Dictionary or not ram_variant is PackedByteArray \
			or not stack_variant is PackedByteArray or not writes_variant is Array \
			or not stack_writes_variant is Array or not mapper_writes_variant is Array \
			or not span_hashes_variant is Dictionary or not seed_request_variant is Dictionary:
		return _fail("Actor-seed prefix result omits its source CPU, mapper, memory, writes, or seed request.")
	var entry: Dictionary = entry_variant
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var result_ram: PackedByteArray = ram_variant
	var result_stack: PackedByteArray = stack_variant
	var span_hashes: Dictionary = span_hashes_variant
	var seed_request: Dictionary = seed_request_variant
	if not _slot09_registers_match_context(entry, context, 0xEB8B) \
			or result_ram.size() != RAM_SIZE or result_stack.size() != STACK_PAGE_SIZE \
			or int(registers.get("pc", -1)) != 0xED15 \
			or int(mapper.get("bank_low", -1)) < 0 or int(mapper.get("bank_low", -1)) > 0xFF \
			or int(mapper.get("bank_high", -1)) < 0 or int(mapper.get("bank_high", -1)) > 0xFF \
			or int(result_ram[0x0000]) != 0x09 \
			or int(result_ram[0x001B]) != int(_ram[0x001B]) \
			or int(result_ram[0x0529]) != 0x73 \
			or int(registers.get("a", -1)) != 0x73 \
			or int(seed_request.get("source_pc", -1)) != 0xED15 \
			or int(seed_request.get("call_pc", -1)) != 0xED2A \
			or int(seed_request.get("return_pc", -1)) != 0xED2D \
			or int(seed_request.get("active_slot", -1)) != 0x09 \
			or int(seed_request.get("actor_parameter", -1)) != 0x73 \
			or int(seed_request.get("a", -1)) != 0x73 \
			or bool(seed_request.get("trace_state_used", true)) \
			or bool(seed_request.get("fixture_only", true)):
		return _fail("Actor-seed prefix entry/exit state or `$ED15` request does not match the live source contract.")
	if not _validate_slot09_source_manifest_hashes(
			String(source_result["source_manifest"]), span_hashes):
		return false
	var request_hashes_variant: Variant = seed_request.get("source_span_hashes", {})
	var seed_entry_registers_variant: Variant = seed_request.get("entry_registers", {})
	var seed_mapper_variant: Variant = seed_request.get("mapper", {})
	var seed_ram_variant: Variant = seed_request.get("ram_image", PackedByteArray())
	var seed_stack_variant: Variant = seed_request.get("stack_page", PackedByteArray())
	if String(seed_request.get("source_manifest", "")) != String(source_result["source_manifest"]) \
			or request_hashes_variant != span_hashes \
			or String(seed_request.get("rom_sha256", "")) != ROM_SHA256 \
			or String(seed_request.get("schema", "")) != "rom-slot11-actor-seed-request-v1" \
			or String(seed_request.get("source_sha256", "")) != String(SOURCE_SPANS["scenario_actor_worker_seed"]["sha256"]) \
			or String(seed_request.get("helper_sha256", "")) != String(SOURCE_SPANS["task_seed"]["sha256"]) \
			or not seed_entry_registers_variant is Dictionary \
			or not seed_mapper_variant is Dictionary \
			or not seed_ram_variant is PackedByteArray \
			or not seed_stack_variant is PackedByteArray:
		return _fail("Actor-seed request provenance differs from its enclosing ROM-source result.")
	var seed_entry_registers: Dictionary = seed_entry_registers_variant
	var seed_mapper: Dictionary = seed_mapper_variant
	var seed_ram: PackedByteArray = seed_ram_variant
	var seed_stack: PackedByteArray = seed_stack_variant
	if seed_entry_registers != registers or seed_mapper != mapper \
			or seed_ram != result_ram or seed_stack != result_stack:
		return _fail("Actor-seed request does not preserve the `$ED15` source-result boundary.")
	var expected_ram := _ram.duplicate()
	var expected_stack := _stack_page.duplicate()
	var replay := _replay_actor_source_writes(writes_variant, stack_writes_variant,
			expected_ram, expected_stack)
	if not bool(replay.get("ok", false)):
		return _fail(String(replay.get("reason", "Actor-seed prefix write replay failed.")))
	expected_ram = replay["ram_image"]
	expected_stack = replay["stack_page"]
	if expected_ram.is_empty() or expected_stack.is_empty():
		return _fail("Actor-seed prefix write replay returned empty memory images.")
	if expected_ram != result_ram or expected_stack != result_stack \
			or result_ram.slice(0x0100, 0x0200) != result_stack:
		return _fail("Actor-seed prefix RAM/stack differs from replaying its ordered source writes.")
	var mapper_result := _replay_actor_source_mapper_writes(mapper_writes_variant,
			context.bank_low, context.bank_high, mapper,
			int(context.mapper_state.get("select", -1)))
	if not bool(mapper_result.get("ok", false)):
		return _fail(String(mapper_result.get("reason", "Actor-seed prefix mapper replay failed.")))
	# Prove that scheduler-owned task records and the ready latch survived replay.
	for slot_base: int in SLOT_BASES:
		if result_ram.slice(slot_base, slot_base + 4) != _record_bytes(slot_base):
			return _fail("Actor-seed prefix changed scheduler-owned task record `$%02X` before `$ED15`." % slot_base)
	_ram = expected_ram
	_stack_page = expected_stack
	context.accumulator = int(registers.get("a", -1)) & 0xFF
	context.x_register = int(registers.get("x", -1)) & 0xFF
	context.y_register = int(registers.get("y", -1)) & 0xFF
	context.status_register = int(registers.get("p", context.status_register)) & 0xFF
	context.status_known_mask = int(registers.get("p_known_mask", context.status_known_mask)) & 0xFF
	context.stack_pointer = int(registers.get("sp", -1))
	context.program_counter = 0xED15
	context.bank_low = int(mapper["bank_low"])
	context.bank_high = int(mapper["bank_high"])
	context.mapper_state = mapper.duplicate(true)
	context.source_label = "ROM-byte slot-$09 prefix at actor seed caller `$ED15`"
	return true


## Executes the packaged `$ED15->$ED2D` caller and `$CAE7` task-seed helper
## only from a fresh, unchanged live slot-$09 `$ED15` boundary.
func seed_slot11_actor_worker_from_source_request(request: Dictionary) -> Dictionary:
	if not _require_initialized():
		return {}
	var caller: TaskContext = _contexts.get(0x09)
	if _active_task_slot != 0x09 or int(_ram[0x0000]) != 0x09 or caller == null \
			or caller.phase != ContextPhase.RUNNING or caller.program_counter != 0xED15:
		_fail("Slot-$11 seed requires the active slot-$09 caller at `$ED15`.")
		return {}
	var boundary := get_task_boundary_snapshot(0x09)
	var request_registers_variant: Variant = request.get("entry_registers", {})
	var request_mapper_variant: Variant = request.get("mapper", {})
	var request_ram_variant: Variant = request.get("ram_image", PackedByteArray())
	var request_stack_variant: Variant = request.get("stack_page", PackedByteArray())
	var request_hashes_variant: Variant = request.get("source_span_hashes", {})
	if String(request.get("schema", "")) != "rom-slot11-actor-seed-request-v1" \
			or String(request.get("rom_sha256", "")) != ROM_SHA256 \
			or String(request.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/slot09_eb8b_continuation/manifest.json" \
			or String(request.get("source_sha256", "")) != String(SOURCE_SPANS["scenario_actor_worker_seed"]["sha256"]) \
			or String(request.get("helper_sha256", "")) != String(SOURCE_SPANS["task_seed"]["sha256"]) \
			or int(request.get("source_pc", -1)) != 0xED15 \
			or int(request.get("call_pc", -1)) != 0xED2A \
			or int(request.get("return_pc", -1)) != 0xED2D \
			or int(request.get("active_slot", -1)) != 0x09 \
			or int(request.get("actor_parameter", -1)) != 0x73 \
			or int(request.get("a", -1)) != 0x73 \
			or bool(request.get("trace_state_used", true)) \
			or bool(request.get("fixture_only", true)) \
			or not request_registers_variant is Dictionary \
			or not request_mapper_variant is Dictionary \
			or not request_ram_variant is PackedByteArray \
			or not request_stack_variant is PackedByteArray \
			or not request_hashes_variant is Dictionary:
		_fail("Actor seed request is missing its source hash, live boundary, or non-fixture provenance.")
		return {}
	var request_registers: Dictionary = request_registers_variant
	var request_mapper: Dictionary = request_mapper_variant
	var request_ram: PackedByteArray = request_ram_variant
	var request_stack: PackedByteArray = request_stack_variant
	var boundary_ram: Variant = boundary.get("ram_image", PackedByteArray())
	var boundary_stack: Variant = boundary.get("stack_page", PackedByteArray())
	var boundary_mapper: Variant = boundary.get("mapper", {})
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("active_task_slot", -1)) != 0x09 \
			or not _slot09_registers_match_context(request_registers, caller, 0xED15) \
			or request_registers != _register_snapshot(caller) \
			or not boundary_ram is PackedByteArray or request_ram != boundary_ram \
			or not boundary_stack is PackedByteArray or request_stack != boundary_stack \
			or not boundary_mapper is Dictionary or request_mapper != boundary_mapper \
			or request_ram != _ram or request_stack != _stack_page \
			or request_mapper != caller.mapper_state \
			or int(request_mapper.get("bank_low", -1)) != int(boundary.get("bank_low", -1)) \
			or int(request_mapper.get("bank_high", -1)) != int(boundary.get("bank_high", -1)) \
			or request_hashes_variant.is_empty() \
			or not _validate_slot09_source_manifest_hashes(
				String(request["source_manifest"]), request_hashes_variant):
		_fail("Actor seed request RAM/stack/mapper/registers changed from the live `$ED15` boundary.")
		return {}
	if int(_ram[0x0529]) == 0xFF or int(_ram[0x0529]) != 0x73 \
			or caller.accumulator != int(_ram[0x0529]) \
			or int(request.get("actor_parameter", -1)) != int(_ram[0x0529]) \
			or not _seeded_slot11_is_available():
		_fail("Actor seed branch requires live `$0529=A=$73` and a fresh slot `$11`.")
		return {}
	var actor_source: PackedByteArray = _sources["scenario_actor_worker_seed"]
	var seed_helper: PackedByteArray = _sources["task_seed"]
	if actor_source.size() != 24 or seed_helper != PackedByteArray([
			0x48, 0x98, 0xB4, 0x01, 0x99, 0x01, 0x01, 0x68,
			0x99, 0x02, 0x01, 0xA9, 0xFF, 0x95, 0x00, 0x60,
		]):
		_fail("Packaged `$ED15` caller or `$CAE7` helper bytes changed after configuration.")
		return {}
	var source_ram := _ram.duplicate()
	var source_stack := _stack_page.duplicate()
	var ram_writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var instruction_pcs: Array[int] = []
	var a := caller.accumulator & 0xFF
	var x := caller.x_register & 0xFF
	var y := caller.y_register & 0xFF
	var p := caller.status_register & 0xFF
	var p_known := caller.status_known_mask & 0xFF
	var sp := caller.stack_pointer & 0xFF
	var pc := 0xED15

	# CMP #$FF; BEQ bypass. This bounded route only follows the non-FF arm.
	instruction_pcs.append(pc)
	var compare := (a - 0xFF) & 0xFF
	p = (p & 0x7C) | (1 if a >= 0xFF else 0)
	if (compare & 0x80) != 0: p |= 0x80
	if compare == 0: p |= 0x02
	p_known = (p_known & ~0x83) | 0x83
	pc = 0xED17
	instruction_pcs.append(pc)
	if a == 0xFF:
		_fail("The ROM `$ED15` BEQ bypass is not implemented for parameter `$FF`.")
		return {}
	# Store actor parameter, task SP/bank, then invoke the fixed-bank seed helper.
	if actor_source.slice(4, 7) != PackedByteArray([0x8D, 0xEA, 0x05]):
		_fail("`$ED19 STA $05EA` differs from the packaged caller bytes.")
		return {}
	instruction_pcs.append(0xED19)
	source_ram[0x05EA] = a
	ram_writes.append({"pc": 0xED19, "address": 0x05EA, "value": a, "kind": "STA"})
	instruction_pcs.append(0xED1C)
	x = 0x11
	p = _update_nz_flags(p, x)
	p_known |= 0x82
	instruction_pcs.append(0xED1E)
	a = 0xC8
	p = _update_nz_flags(p, a)
	instruction_pcs.append(0xED20)
	source_ram[0x0012] = a
	ram_writes.append({"pc": 0xED20, "address": 0x0012, "value": a, "kind": "STA_zp_x"})
	instruction_pcs.append(0xED22)
	a = 0x18
	p = _update_nz_flags(p, a)
	instruction_pcs.append(0xED24)
	source_ram[0x0013] = a
	ram_writes.append({"pc": 0xED24, "address": 0x0013, "value": a, "kind": "STA_zp_x"})
	instruction_pcs.append(0xED26)
	a = 0x7F
	p = _update_nz_flags(p, a)
	instruction_pcs.append(0xED28)
	y = 0xFF
	p = _update_nz_flags(p, y)
	pc = 0xED2A
	instruction_pcs.append(pc)
	# JSR $CAE7 pushes the caller return-minus-one word on slot-$09's live stack.
	var caller_sp := sp
	var return_minus_one := 0xED2C
	var push_result := _push_actor_seed_stack_byte(source_ram, source_stack,
		stack_writes, sp, (return_minus_one >> 8) & 0xFF, 0xED2A, "JSR_high")
	source_ram = push_result["ram_image"]
	source_stack = push_result["stack_page"]
	sp = int(push_result["sp"])
	push_result = _push_actor_seed_stack_byte(source_ram, source_stack,
		stack_writes, sp, return_minus_one & 0xFF, 0xED2A, "JSR_low")
	source_ram = push_result["ram_image"]
	source_stack = push_result["stack_page"]
	sp = int(push_result["sp"])
	pc = 0xCAE7
	instruction_pcs.append(pc)
	# PHA / TYA / LDY $01,X / STA $0101,Y.
	push_result = _push_actor_seed_stack_byte(source_ram, source_stack,
		stack_writes, sp, a, 0xCAE7, "PHA")
	source_ram = push_result["ram_image"]
	source_stack = push_result["stack_page"]
	sp = int(push_result["sp"])
	a = y
	p = _update_nz_flags(p, a)
	pc = 0xCAE9
	instruction_pcs.append(pc)
	y = int(source_ram[0x0012])
	p = _update_nz_flags(p, y)
	pc = 0xCAEB
	instruction_pcs.append(pc)
	var actor_stack_low := (0x0101 + y) & 0x07FF
	source_ram[actor_stack_low] = a
	source_stack[actor_stack_low & 0xFF] = a
	ram_writes.append({"pc": pc, "address": actor_stack_low, "value": a, "kind": "STA_abs_y"})
	# PLA restores A; the second indexed store writes the return high byte.
	sp = (sp + 1) & 0xFF
	a = int(source_stack[sp])
	p = _update_nz_flags(p, a)
	pc = 0xCAEE
	instruction_pcs.append(pc)
	pc = 0xCAEF
	instruction_pcs.append(pc)
	var actor_stack_high := (0x0102 + y) & 0x07FF
	source_ram[actor_stack_high] = a
	source_stack[actor_stack_high & 0xFF] = a
	ram_writes.append({"pc": pc, "address": actor_stack_high, "value": a, "kind": "STA_abs_y"})
	pc = 0xCAF2
	instruction_pcs.append(pc)
	a = 0xFF
	p = _update_nz_flags(p, a)
	pc = 0xCAF4
	instruction_pcs.append(pc)
	source_ram[0x0011] = a
	ram_writes.append({"pc": pc, "address": 0x0011, "value": a, "kind": "STA_zp_x"})
	# RTS consumes the exact ED2C return word and resumes the caller at ED2D.
	sp = (sp + 1) & 0xFF
	var return_low := int(source_stack[sp])
	sp = (sp + 1) & 0xFF
	var return_high := int(source_stack[sp])
	pc = (((return_high << 8) | return_low) + 1) & 0xFFFF
	instruction_pcs.append(0xCAF6)
	if pc != 0xED2D or sp != caller_sp or source_ram[0x0012] != 0xC8 \
			or source_ram[0x0013] != 0x18 or source_ram[0x0011] != 0xFF \
			or source_ram[0x01C9] != 0xFF or source_ram[0x01CA] != 0x7F:
		_fail("ROM `$CAE7` return did not leave the checked slot-$11 seed and `$ED2D` caller continuation.")
		return {}
	_ram = source_ram
	_stack_page = source_stack
	caller.accumulator = a
	caller.x_register = x
	caller.y_register = y
	caller.status_register = p
	caller.status_known_mask = p_known
	caller.stack_pointer = sp
	caller.program_counter = pc
	caller.source_label = "ROM-byte `$ED15->$CAE7->$ED2D` actor-task seed"
	var actor := TaskContext.new()
	actor.slot_base = 0x11
	actor.ready_delay = READY_SENTINEL
	actor.phase = ContextPhase.SEEDED
	actor.pending_resume = ResumeKind.NONE
	actor.stack_pointer = 0xC8
	actor.accumulator = 0x00
	actor.x_register = 0x11
	actor.y_register = 0x00
	actor.bank_low = 0x18
	actor.bank_high = 0x19
	# `$CAE7` installs the actor task's `$18/$19` bank pair in its task record;
	# the `$0B/$0C` caller mapping used for the parameter lookup is not the
	# mapping to restore when this task is dispatched later.
	actor.mapper_state = {"bank_low": 0x18, "bank_high": 0x19, "select": 0x07,
		"bank_registers": {6: 0x18, 7: 0x19}}
	actor.source_return_word = 0x7FFF
	actor.source_label = "ROM-byte scenario actor seed `$ED15->$CAE7`, parameter `$73`"
	_contexts[0x11] = actor
	_slot09_actor_seed_request = request.duplicate(true)
	var pending_dispatch := _slot11_initial_dispatch_candidate(actor)
	return {
		"ok": true,
		"status": "slot11_seeded_caller_returned_ed2d",
		"rom_sha256": ROM_SHA256,
		"source_manifest": TASK_CONTEXT_ROOT + "manifest.json",
		"source_span_sha256": String(SOURCE_SPANS["scenario_actor_worker_seed"]["sha256"]),
		"seed_helper_sha256": String(SOURCE_SPANS["task_seed"]["sha256"]),
		"slot09_post_return_boundary": get_task_boundary_snapshot(0x09),
		"slot11_seeded_boundary": get_task_boundary_snapshot(0x11),
		"pending_initial_dispatch_boundary": pending_dispatch,
		"ram_writes": ram_writes,
		"stack_writes": stack_writes,
		"instruction_pcs": instruction_pcs,
		"trace_state_used": false,
		"fixture_only": false,
	}


## Adopts the source continuation beginning at the post-seed caller `$ED2D`.
## Slot `$11` must remain freshly seeded while slot `$09` continues to `$86F8`.
func adopt_slot09_after_actor_seed_continuation(source_result: Dictionary) -> bool:
	if not _require_initialized():
		return false
	var context: TaskContext = _contexts.get(0x09)
	var actor: TaskContext = _contexts.get(0x11)
	if _active_task_slot != 0x09 or int(_ram[0x0000]) != 0x09 \
			or context == null or context.phase != ContextPhase.RUNNING \
			or context.program_counter != 0xED2D or actor == null \
			or actor.phase != ContextPhase.SEEDED \
			or _record_bytes(0x11) != PackedByteArray([0xFF, 0xC8, 0x18, 0x00]):
		return _fail("Post-seed continuation adoption requires live slot `$09` at `$ED2D` and seeded slot `$11`.")
	if String(source_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(source_result.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/slot09_eb8b_continuation/manifest.json" \
			or String(source_result.get("status", "")) != "slot09_actor_seed_continuation_to_worker_vector" \
			or int(source_result.get("entry_pc", -1)) != 0xED2D \
			or int(source_result.get("exit_pc", -1)) != 0x86F8 \
			or int(source_result.get("active_slot", -1)) != 0x09 \
			or bool(source_result.get("trace_state_used", true)) \
			or bool(source_result.get("fixture_only", true)) \
			or bool(source_result.get("worker_body_executed", true)) \
			or bool(source_result.get("worker_body_bytes_read", true)) \
			or source_result.get("source_actor_seed_request", {}) != _slot09_actor_seed_request:
		return _fail("Post-seed continuation is not the ROM-derived slot-$09 `$ED2D->$86F8` result.")
	var entry_variant: Variant = source_result.get("entry_registers", {})
	var registers_variant: Variant = source_result.get("registers", {})
	var mapper_variant: Variant = source_result.get("mapper", {})
	var ram_variant: Variant = source_result.get("ram_image", PackedByteArray())
	var stack_variant: Variant = source_result.get("stack_page", PackedByteArray())
	var writes_variant: Variant = source_result.get("writes", [])
	var stack_writes_variant: Variant = source_result.get("stack_writes", [])
	var mapper_writes_variant: Variant = source_result.get("mapper_writes", [])
	var hashes_variant: Variant = source_result.get("source_span_hashes", {})
	if not entry_variant is Dictionary or not registers_variant is Dictionary \
			or not mapper_variant is Dictionary or not ram_variant is PackedByteArray \
			or not stack_variant is PackedByteArray or not writes_variant is Array \
			or not stack_writes_variant is Array or not mapper_writes_variant is Array \
			or not hashes_variant is Dictionary:
		return _fail("Post-seed continuation result omits source CPU, mapper, memory, or writes.")
	var entry: Dictionary = entry_variant
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var result_ram: PackedByteArray = ram_variant
	var result_stack: PackedByteArray = stack_variant
	var hashes: Dictionary = hashes_variant
	if not _slot09_registers_match_context(entry, context, 0xED2D) \
			or int(registers.get("pc", -1)) != 0x86F8 \
			or result_ram.size() != RAM_SIZE or result_stack.size() != STACK_PAGE_SIZE \
			or int(result_ram[0x0000]) != 0x09 \
			or int(result_ram[0x001B]) != int(_ram[0x001B]) \
			or int(mapper.get("bank_low", -1)) < 0 or int(mapper.get("bank_low", -1)) > 0xFF \
			or int(mapper.get("bank_high", -1)) < 0 or int(mapper.get("bank_high", -1)) > 0xFF:
		return _fail("Post-seed continuation entry/exit does not preserve the live scheduler boundary.")
	if not _validate_slot09_source_manifest_hashes(
			String(source_result["source_manifest"]), hashes):
		return false
	var expected_ram := _ram.duplicate()
	var expected_stack := _stack_page.duplicate()
	var replay := _replay_actor_source_writes(writes_variant, stack_writes_variant,
			expected_ram, expected_stack)
	if not bool(replay.get("ok", false)):
		return _fail(String(replay.get("reason", "Post-seed continuation write replay failed.")))
	expected_ram = replay["ram_image"]
	expected_stack = replay["stack_page"]
	if expected_ram != result_ram or expected_stack != result_stack \
			or result_ram.slice(0x0100, 0x0200) != result_stack:
		return _fail("Post-seed continuation RAM/stack differs from replaying its ordered source writes.")
	var mapper_result := _replay_actor_source_mapper_writes(mapper_writes_variant,
			context.bank_low, context.bank_high, mapper,
			int(context.mapper_state.get("select", -1)))
	if not bool(mapper_result.get("ok", false)):
		return _fail(String(mapper_result.get("reason", "Post-seed continuation mapper replay failed.")))
	for slot_base: int in SLOT_BASES:
		if result_ram.slice(slot_base, slot_base + 4) != _record_bytes(slot_base):
			return _fail("Post-seed continuation changed scheduler-owned record `$%02X`." % slot_base)
	_ram = expected_ram
	_stack_page = expected_stack
	context.accumulator = int(registers.get("a", -1)) & 0xFF
	context.x_register = int(registers.get("x", -1)) & 0xFF
	context.y_register = int(registers.get("y", -1)) & 0xFF
	context.status_register = int(registers.get("p", context.status_register)) & 0xFF
	context.status_known_mask = int(registers.get("p_known_mask", context.status_known_mask)) & 0xFF
	context.stack_pointer = int(registers.get("sp", -1))
	context.program_counter = 0x86F8
	context.bank_low = int(mapper["bank_low"])
	context.bank_high = int(mapper["bank_high"])
	context.mapper_state = mapper.duplicate(true)
	context.source_label = "ROM-byte slot-$09 post-seed continuation `$ED2D->$86F8`"
	return true


## Replays the source-produced `$86F8->$EBD7` actor route on top of the live
## post-seed boundary, then adopts the caller entry before its `$CB0F` JSR.
## The following `apply_slot09_cb0f_from_root_route_result()` owns that call.
func adopt_slot09_actor_seeded_root_loop_entry_state(worker_results: Array,
		root_result: Dictionary) -> bool:
	if not _require_initialized():
		return false
	var context: TaskContext = _contexts.get(0x09)
	var actor: TaskContext = _contexts.get(0x11)
	if _active_task_slot != 0x09 or int(_ram[0x0000]) != 0x09 \
			or context == null or context.phase != ContextPhase.RUNNING \
			or context.program_counter != 0x86F8 or actor == null \
			or actor.phase != ContextPhase.SEEDED \
			or _record_bytes(0x11) != PackedByteArray([0xFF, 0xC8, 0x18, 0x00]) \
			or int(_stack_page[0xC9]) != 0xFF or int(_stack_page[0xCA]) != 0x7F:
		return _fail("Actor-seeded root adoption requires slot-$09 at `$86F8` and the untouched seeded slot-$11 stack/record.")
	if worker_results.size() != 3:
		return _fail("Actor-seeded root adoption requires the ordered `$86F8`, `$8779`, and `$87E6` source results.")
	var manifests := [
		"res://reference/rom_extract/gameplay/slot09_86f8_worker/manifest.json",
		"res://reference/rom_extract/gameplay/slot09_8779_worker/manifest.json",
		"res://reference/rom_extract/gameplay/slot09_87e6_worker/manifest.json",
	]
	var schemas := [
		"ct2-slot09-86f8-worker-source-v1",
		"ct2-slot09-8779-worker-source-v1",
		"ct2-slot09-87e6-worker-source-v1",
	]
	var statuses := [
		"returned_to_root_caller",
		"returned_before_next_worker_call",
		"returned_before_root_loop_check",
	]
	var entry_pcs: Array[int] = [0x86F8, 0xEBB3, 0xEBC5]
	var exit_pcs: Array[int] = [0xEBB3, 0xEBC5, 0xEBD7]
	var input_addresses: Array[int] = [0x0532, 0x0534, 0x0536]
	var expected_source_spans: Array[Dictionary] = [
		{"bank18_slot09_worker_86F8_8778.bin": "ae998967ec1bb0e39ffcc72c8670a393946cfe233ad6845dc524870bd3264d23"},
		{
			"fixed_root_slot09_after_86f8_EBB3_EBC5.bin": "5b1a5142b268e834aafe619d51b6c51a80e71c99ec269641ecb61cc6c0d50883",
			"bank18_slot09_worker_vector_8006_8009.bin": "ec20595812bf088382eaa136f2bbf5cf9429467653f948041a7684a34e1b4fab",
			"bank18_slot09_worker_8779_87A4.bin": "407f2feb4cedb61c07aab10b9b39e7775d9891b04afeaa16b43ad459aeeab511",
			"fixed_mapper_helper_CE2D_CE4A.bin": "6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c",
		},
		{
			"fixed_root_slot09_after_8779_EBC5_EBD7.bin": "75ff2ee06764439aecb4eae84c694e1f99b083d7b21a92c9ad5e41baa09b304e",
			"bank18_slot09_vector_8009_800B.bin": "ee600ed5f0ff7a46e0b9a1d41acb3615828d6c635eee42c16598839227a71e27",
			"bank18_slot09_worker_87E6_8850.bin": "879cfbc3684874aa7a857d9ee294755cbb773b616d5815335a2208d414799509",
			"bank19_slot09_worker_pointer_table_AD54_AD5D.bin": "8d1c08abdc6be570a1a0e8304738c995c09856b4081e0962f15db579cb95f7b5",
			"fixed_mapper_helper_CE2D_CE4A.bin": "6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c",
		},
	]
	var current_registers := _register_snapshot(context)
	var current_mapper: Dictionary = context.mapper_state.duplicate(true)
	if current_mapper.is_empty():
		return _fail("Actor-seeded worker chain has no preserved `$86F8` mapper boundary.")
	var current_ram := _ram.duplicate()
	var current_stack := _stack_page.duplicate()
	var scheduler_records := {}
	for slot_base: int in SLOT_BASES:
		scheduler_records[slot_base] = _record_bytes(slot_base)
	var ready_latch := int(_ram[0x001B])
	for index: int in worker_results.size():
		var result_variant: Variant = worker_results[index]
		if not result_variant is Dictionary:
			return _fail("Actor-seeded worker result %d is malformed." % index)
		var result: Dictionary = result_variant
		if String(result.get("rom_sha256", "")) != ROM_SHA256 \
				or String(result.get("source_manifest", "")) != String(manifests[index]) \
				or String(result.get("status", "")) != String(statuses[index]) \
				or int(result.get("entry_pc", -1)) != entry_pcs[index] \
				or int(result.get("exit_pc", -1)) != exit_pcs[index] \
				or (index == 1 and String(result.get("previous_worker_manifest", "")) != String(manifests[0])) \
				or (index == 2 and String(result.get("previous_worker_manifest", "")) != String(manifests[1])) \
				or bool(result.get("trace_state_used", true)) \
				or bool(result.get("nmi_cadence_generated", true)) \
				or bool(result.get("ppu_apu_effects_applied", true)):
			return _fail("Actor-seeded worker result %d has unsupported source, range, status, or trace provenance." % index)
		if not _validate_actor_chain_manifest(String(manifests[index]),
				String(schemas[index]), expected_source_spans[index]):
			return false
		var entry_variant: Variant = result.get("entry_registers", {})
		var registers_variant: Variant = result.get("registers", {})
		var mapper_variant: Variant = result.get("mapper", {})
		var ram_variant: Variant = result.get("ram_image", PackedByteArray())
		var stack_variant: Variant = result.get("stack_page", PackedByteArray())
		var stack_writes_variant: Variant = result.get("stack_writes", [])
		var mapper_writes_variant: Variant = result.get("mapper_writes", [])
		var writes_variant: Variant = result.get("memory_writes", result.get("ram_writes", []))
		if not entry_variant is Dictionary or not registers_variant is Dictionary \
				or not mapper_variant is Dictionary or not ram_variant is PackedByteArray \
				or not stack_variant is PackedByteArray or not stack_writes_variant is Array \
				or not mapper_writes_variant is Array or not writes_variant is Array:
			return _fail("Actor-seeded worker result %d omits CPU, mapper, memory, or ordered writes." % index)
		var entry_registers: Dictionary = entry_variant
		var registers: Dictionary = registers_variant
		var mapper: Dictionary = mapper_variant
		var result_ram: PackedByteArray = ram_variant
		var result_stack: PackedByteArray = stack_variant
		if entry_registers != current_registers or result_ram.size() != RAM_SIZE \
				or result_stack.size() != STACK_PAGE_SIZE \
				or int(registers.get("pc", -1)) != exit_pcs[index] \
				or int(result_ram[0x0000]) != 0x09 \
				or int(result_ram[input_addresses[index]]) != 0 \
				or int(result_ram[0x0529]) != 0x73 or int(result_ram[0x05EA]) != 0x73 \
				or int(result_ram[0x001B]) != ready_latch:
			return _fail("Actor-seeded worker result %d does not continue the live CPU/RAM/latch boundary." % index)
		if index > 0 and result.get("entry_mapper", {}) != current_mapper:
			return _fail("Actor-seeded worker result %d mapper entry differs from the preceding ROM result." % index)
		# The `$8779` and `$87E6` worker executors keep their `$0100-$01FF`
		# `ram_image` and `stack_page` snapshots separate: their CPU stack
		# operations are emitted only in `stack_writes`. Preserve that exact
		# executor contract while still replaying explicit RAM stores into RAM.
		var stack_writes_mirror_ram := index == 0
		var replay := _replay_actor_source_writes(writes_variant,
				stack_writes_variant, current_ram, current_stack,
				stack_writes_mirror_ram)
		if not bool(replay.get("ok", false)):
			return _fail(String(replay.get("reason", "Actor-seeded worker write replay failed.")))
		var expected_ram: PackedByteArray = replay["ram_image"]
		var expected_stack: PackedByteArray = replay["stack_page"]
		if expected_ram != result_ram or expected_stack != result_stack:
			var ram_mismatches: Array[Dictionary] = []
			for address in range(RAM_SIZE):
				if int(expected_ram[address]) == int(result_ram[address]):
					continue
				var address_ram_writes: Array[Dictionary] = []
				var address_stack_writes: Array[Dictionary] = []
				for write_variant in writes_variant:
					if write_variant is Dictionary and int((write_variant as Dictionary).get("address", -1)) == address:
						address_ram_writes.append(write_variant)
				for write_variant in stack_writes_variant:
					if write_variant is Dictionary and int((write_variant as Dictionary).get("address", -1)) == address:
						address_stack_writes.append(write_variant)
				ram_mismatches.append({"address": "0x%04X" % address,
					"replayed": int(expected_ram[address]), "source": int(result_ram[address]),
					"ram_writes": address_ram_writes, "stack_writes": address_stack_writes})
				if ram_mismatches.size() >= 16:
					break
			var stack_mismatches: Array[Dictionary] = []
			for stack_address in range(STACK_PAGE_SIZE):
				if int(expected_stack[stack_address]) == int(result_stack[stack_address]):
					continue
				stack_mismatches.append({"address": "0x%02X" % stack_address,
					"replayed": int(expected_stack[stack_address]), "source": int(result_stack[stack_address])})
				if stack_mismatches.size() >= 16:
					break
			return _fail("Actor-seeded worker result %d memory differs from ordered replay: RAM=%s stack=%s." % [
				index, JSON.stringify(ram_mismatches), JSON.stringify(stack_mismatches)])
		var mapper_replay := _replay_actor_source_mapper_writes(mapper_writes_variant,
				int(current_mapper.get("bank_low", -1)),
				int(current_mapper.get("bank_high", -1)), mapper,
				int(current_mapper.get("select", -1)))
		if not bool(mapper_replay.get("ok", false)):
			return _fail(String(mapper_replay.get("reason", "Actor-seeded worker mapper replay failed.")))
		for slot_base: int in SLOT_BASES:
			if result_ram.slice(slot_base, slot_base + 4) != scheduler_records[slot_base]:
				return _fail("Actor-seeded worker result %d changed scheduler-owned slot `$%02X`." % [index, slot_base])
		if result_ram[0x01C9] != 0xFF or result_ram[0x01CA] != 0x7F \
				or result_stack[0xC9] != 0xFF or result_stack[0xCA] != 0x7F:
			return _fail("Actor-seeded worker result %d changed slot `$11`'s saved RTS stack." % index)
		current_registers = registers.duplicate(true)
		current_mapper = mapper.duplicate(true)
		current_ram = result_ram.duplicate()
		current_stack = result_stack.duplicate()
	var root_proof := _validate_slot09_cb0f_root_result(root_result)
	if not bool(root_proof.get("ok", false)):
		return _fail(String(root_proof.get("reason", "Invalid actor-seeded `$EBD7` root-loop result.")))
	var root_entry: Dictionary = root_result.get("entry_registers", {})
	var root_mapper: Dictionary = root_result.get("mapper", {})
	var root_ram: Variant = root_result.get("ram_image", PackedByteArray())
	var root_stack: Variant = root_result.get("stack_page", PackedByteArray())
	var root_stack_writes: Variant = root_result.get("stack_writes", [])
	var root_input_counter := int(root_result.get("input_ram_052e", -1))
	var root_output_counter := int(root_proof.get("output_ram_052e", -1))
	if root_entry != current_registers or root_mapper != current_mapper \
			or root_input_counter != int(current_ram[0x052E]) \
			or not root_ram is PackedByteArray or root_ram.size() != RAM_SIZE \
			or int(root_ram[0x052E]) != root_output_counter \
			or not root_stack is PackedByteArray or not root_stack_writes is Array:
		return _fail("Actor-seeded `$EBD7` root result does not begin at the preceding `$87E6` output boundary.")
	var root_ram_without_counter: PackedByteArray = root_ram.duplicate()
	root_ram_without_counter[0x052E] = current_ram[0x052E]
	root_ram_without_counter[0x0024] = current_ram[0x0024]
	root_ram_without_counter[0x0025] = current_ram[0x0025]
	for stack_address in range(0x0100, 0x0200):
		root_ram_without_counter[stack_address] = current_ram[stack_address]
	if root_ram_without_counter != current_ram:
		return _fail("Actor-seeded `$EBD7` root result changed RAM outside its counter, mapper save, or verified stack page.")
	if int(root_ram[0x0024]) != int(root_mapper.get("bank_low", -1)) \
			or int(root_ram[0x0025]) != int(root_mapper.get("bank_high", -1)):
		return _fail("Actor-seeded `$EBD7` root result's mapper-save bytes differ from its live bank pair.")
	if not _validate_actor_chain_manifest(
			"res://reference/rom_extract/gameplay/slot09_ebd7_root_checks/manifest.json",
			"ct2-slot09-ebd7-root-checks-v1",
			{"fixed_root_slot09_loop_EB86_EC07.bin": "91ee3ddc0110b7575a472103de8f5e4d1391a60efebe557b4f4238940d74f917"}):
		return false
	var root_stack_replay := _replay_actor_source_writes([], root_stack_writes,
			current_ram, current_stack)
	if not bool(root_stack_replay.get("ok", false)) \
			or root_stack_replay["stack_page"] != root_stack:
		return _fail("Actor-seeded `$EBD7` JSR stack writes do not match the source result.")
	for slot_base: int in SLOT_BASES:
		if root_ram.slice(slot_base, slot_base + 4) != scheduler_records[slot_base]:
			return _fail("Actor-seeded `$EBD7` root result changed scheduler-owned slot `$%02X`." % slot_base)
	if int(root_ram[0x001B]) != ready_latch or int(root_ram[0x0000]) != 0x09:
		return _fail("Actor-seeded `$EBD7` root result changed the active-slot or NMI-ready latch.")
	_ram = current_ram
	_stack_page = current_stack
	context.accumulator = int(root_entry.get("a", -1))
	context.x_register = int(root_entry.get("x", -1))
	context.y_register = int(root_entry.get("y", -1))
	context.status_register = int(root_entry.get("p", -1))
	context.status_known_mask = int(root_entry.get("p_known_mask", -1))
	context.stack_pointer = int(root_entry.get("sp", -1))
	context.program_counter = 0xEBD7
	context.bank_low = int(current_mapper.get("bank_low", -1))
	context.bank_high = int(current_mapper.get("bank_high", -1))
	context.mapper_state = current_mapper.duplicate(true)
	context.source_label = "ROM-byte slot-$09 actor-seeded root return `$86F8->$EBD7`"
	return true


## Adopts the checked three-byte JMP at a scheduler-dispatched initial task
## entry, keeping the per-slot CPU boundary synchronized with its source run.
func adopt_initial_task_jmp_result(slot_base: int, jump_result: Dictionary) -> bool:
	if not _require_initialized():
		return false
	var context: TaskContext = _contexts.get(slot_base)
	if slot_base != 0x15 or _active_task_slot != slot_base or context == null \
			or context.phase != ContextPhase.RUNNING or context.program_counter != 0x8009:
		return _fail("Initial callback JMP adoption requires dispatched slot-$15 at `$8009`.")
	var entry_variant: Variant = jump_result.get("entry_dispatch", {})
	var output_variant: Variant = jump_result.get("dispatcher_dispatch", {})
	if not entry_variant is Dictionary or not output_variant is Dictionary:
		return _fail("Initial callback JMP result omits its source dispatch boundaries.")
	var entry: Dictionary = entry_variant
	var output: Dictionary = output_variant
	for key: String in ["slot_base", "resume_path", "sp", "a", "x", "y",
			"p", "p_known_mask", "bank_low", "bank_high",
			"source_return_word", "source_return_bytes", "phase"]:
		if entry.get(key) != output.get(key):
			return _fail("Initial callback JMP changed preserved dispatch field `%s`." % key)
	if String(jump_result.get("rom_sha256", "")) != "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097" \
			or String(jump_result.get("status", "")) != "reached_callback_dispatcher_entry" \
			or int(jump_result.get("entry_pc", -1)) != 0x8009 \
			or int(jump_result.get("exit_pc", -1)) != 0x814C \
			or int(entry.get("pc", -1)) != 0x8009 or int(output.get("pc", -1)) != 0x814C \
			or int(output.get("slot_base", -1)) != slot_base \
			or not bool(jump_result.get("source_bytes_executed", PackedByteArray()) == PackedByteArray([0x4C, 0x4C, 0x81])) \
			or bool(jump_result.get("trace_state_used", true)) \
			or bool(jump_result.get("ppu_apu_effects_applied", true)):
		return _fail("Initial callback JMP result differs from the source `$8009->$814C` transfer.")
	context.program_counter = 0x814C
	context.status_register = int(output.get("p", context.status_register))
	context.status_known_mask = int(output.get("p_known_mask", context.status_known_mask))
	context.source_label = "ROM-byte initial callback entry `$8009->$814C`"
	return true


## Replays the live slot-$15 callback-$3A dispatcher writes and stack traffic
## through its first indirect handler entry, `$8327`.
func adopt_slot15_callback_handler_boundary(handler_result: Dictionary) -> bool:
	if not _require_initialized():
		return false
	var context: TaskContext = _contexts.get(0x15)
	if _active_task_slot != 0x15 or context == null or context.phase != ContextPhase.RUNNING \
			or context.program_counter != 0x814C:
		return _fail("Callback adoption requires active slot-$15 at the source `$814C` entry.")
	var entry_variant: Variant = handler_result.get("entry_registers", {})
	var output_variant: Variant = handler_result.get("registers", {})
	var mapper_variant: Variant = handler_result.get("mapper", {})
	var ram_variant: Variant = handler_result.get("ram_image", PackedByteArray())
	var stack_variant: Variant = handler_result.get("stack_page", PackedByteArray())
	var writes_variant: Variant = handler_result.get("ram_writes", [])
	var stack_writes_variant: Variant = handler_result.get("stack_writes", [])
	if not entry_variant is Dictionary or not output_variant is Dictionary \
			or not mapper_variant is Dictionary or not ram_variant is PackedByteArray \
			or not stack_variant is PackedByteArray or not writes_variant is Array \
			or not stack_writes_variant is Array:
		return _fail("Callback-$3A result omits source CPU, mapper, memory, or ordered writes.")
	var entry: Dictionary = entry_variant
	var registers: Dictionary = output_variant
	var mapper: Dictionary = mapper_variant
	var source_ram: PackedByteArray = ram_variant
	var source_stack: PackedByteArray = stack_variant
	var scenario_id := int(_ram[0x0518])
	var expected_wait := 0x02 if scenario_id == 0x35 else 0x10
	var expected_actor_parameter := 0x73 if scenario_id == 0x35 else 0xFF
	var expected_bank_high := 0x0C
	var expected_ram := _ram.duplicate()
	var expected_stack := _stack_page.duplicate()
	if String(handler_result.get("rom_sha256", "")) != "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097" \
			or String(handler_result.get("status", "")) != "reached_first_callback_handler_8327" \
			or int(handler_result.get("entry_pc", -1)) != 0x814C \
			or int(handler_result.get("exit_pc", -1)) != 0x8327 \
			or scenario_id not in [0x35, 0x36] \
			or int(handler_result.get("scenario", -1)) != scenario_id \
			or int(handler_result.get("callback_id", -1)) != 0x3A \
			or handler_result.get("callback_bytes", PackedByteArray()) != PackedByteArray([0x02, 0x00, 0x42]) \
			or bool(handler_result.get("trace_state_used", true)) \
			or bool(handler_result.get("ppu_apu_effects_applied", true)) \
			or int(entry.get("pc", -1)) != 0x814C \
			or int(entry.get("a", -1)) != context.accumulator \
			or int(entry.get("x", -1)) != context.x_register \
			or int(entry.get("y", -1)) != context.y_register \
			or int(entry.get("sp", -1)) != context.stack_pointer \
			or int(registers.get("pc", -1)) != 0x8327 \
			or int(registers.get("sp", -1)) != 0xF0 \
			or int(mapper.get("bank_low", -1)) != 0x0B \
			or int(mapper.get("bank_high", -1)) != expected_bank_high \
			or source_ram.size() != RAM_SIZE or source_stack.size() != STACK_PAGE_SIZE:
		return _fail("Callback-$3A `$814C->$8327` CPU, mapper, ROM data, or provenance contract differs.")
	var allowed_ram := [0x0036, 0x0037, 0x003A, 0x0052, 0x0053, 0x0525, 0x05D1]
	for write_variant in writes_variant:
		if not write_variant is Dictionary:
			return _fail("Callback-$3A RAM write stream contains a malformed event.")
		var write: Dictionary = write_variant
		var address := int(write.get("address", -1))
		var value := int(write.get("value", -1))
		if address not in allowed_ram or value < 0 or value > 0xFF:
			return _fail("Callback-$3A attempted an unapproved RAM write at `$%04X`." % address)
		expected_ram[address] = value
	for write_variant in stack_writes_variant:
		if not write_variant is Dictionary:
			return _fail("Callback-$3A stack write stream contains a malformed event.")
		var write: Dictionary = write_variant
		var address := int(write.get("address", -1))
		var value := int(write.get("value", -1))
		if address < 0x0100 or address >= 0x0200 or value < 0 or value > 0xFF:
			return _fail("Callback-$3A stack write is outside the CPU stack page.")
		expected_stack[address & 0xFF] = value
	for stack_offset in STACK_PAGE_SIZE:
		expected_ram[0x0100 + stack_offset] = expected_stack[stack_offset]
	for address in RAM_SIZE:
		if expected_ram[address] != source_ram[address]:
			return _fail("Callback-$3A RAM replay differs at `$%04X`: replay=$%02X source=$%02X." % [address, expected_ram[address], source_ram[address]])
	for address in STACK_PAGE_SIZE:
		if expected_stack[address] != source_stack[address]:
			return _fail("Callback-$3A stack replay differs at `$%02X`: replay=$%02X source=$%02X." % [address, expected_stack[address], source_stack[address]])
	_ram = expected_ram
	_stack_page = expected_stack
	context.accumulator = int(registers.get("a", -1))
	context.x_register = int(registers.get("x", -1))
	context.y_register = int(registers.get("y", -1))
	context.stack_pointer = int(registers.get("sp", -1))
	context.program_counter = int(registers.get("pc", -1))
	context.status_register = int(registers.get("p", context.status_register))
	context.status_known_mask = int(registers.get("p_known_mask", context.status_known_mask))
	context.source_label = "ROM-byte callback `$3A` dispatcher through `$8327`"
	return true


## Replays the first ROM-owned `$8327` map-handler instructions through the
## `$8525` worker call. The worker body remains a separate source transition.
func adopt_slot15_map_worker_entry(map_worker_result: Dictionary) -> bool:
	if not _require_initialized():
		return false
	var context: TaskContext = _contexts.get(0x15)
	if _active_task_slot != 0x15 or context == null or context.phase != ContextPhase.RUNNING \
			or context.program_counter != 0x8327:
		return _fail("Map-worker adoption requires active slot-$15 at the source `$8327` entry.")
	var entry_variant: Variant = map_worker_result.get("entry_registers", {})
	var output_variant: Variant = map_worker_result.get("registers", {})
	var mapper_variant: Variant = map_worker_result.get("mapper", {})
	var source_ram_variant: Variant = map_worker_result.get("ram_image", PackedByteArray())
	var source_stack_variant: Variant = map_worker_result.get("stack_page", PackedByteArray())
	var writes_variant: Variant = map_worker_result.get("ram_writes", [])
	var stack_writes_variant: Variant = map_worker_result.get("stack_writes", [])
	if not entry_variant is Dictionary or not output_variant is Dictionary \
			or not mapper_variant is Dictionary or not source_ram_variant is PackedByteArray \
			or not source_stack_variant is PackedByteArray or not writes_variant is Array \
			or not stack_writes_variant is Array:
		return _fail("The `$8327->$8525` result omits CPU, mapper, memory, or write events.")
	var entry: Dictionary = entry_variant
	var registers: Dictionary = output_variant
	var mapper: Dictionary = mapper_variant
	var source_ram: PackedByteArray = source_ram_variant
	var source_stack: PackedByteArray = source_stack_variant
	var source_hashes_variant: Variant = map_worker_result.get("source_hashes", {})
	var source_hashes: Dictionary = source_hashes_variant if source_hashes_variant is Dictionary else {}
	var expected_hashes := {
		"handler_8327": "e3ed67bcd4a760f0f8324b4d46ca08100ef6d1b578af495da8475b7e66096853",
	}
	if String(map_worker_result.get("rom_sha256", "")) != "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097" \
			or String(map_worker_result.get("status", "")) != "entered_map_worker_8525" \
			or int(map_worker_result.get("entry_pc", -1)) != 0x8327 \
			or int(map_worker_result.get("exit_pc", -1)) != 0x8525 \
			or map_worker_result.get("source_hashes", {}) != expected_hashes \
			or map_worker_result.get("source_bytes_executed", PackedByteArray()) != PackedByteArray([
				0xA0, 0x02, 0xB1, 0x52, 0x8D, 0xCC, 0x05, 0xAC, 0xCD, 0x05, 0x20, 0x25, 0x85]) \
			or bool(map_worker_result.get("worker_body_executed", true)) \
			or bool(map_worker_result.get("trace_state_used", true)) \
			or not (map_worker_result.get("ppu_bus_events", []) as Array).is_empty() \
			or not (map_worker_result.get("apu_register_writes", []) as Array).is_empty() \
			or int(entry.get("pc", -1)) != 0x8327 or int(entry.get("a", -1)) != context.accumulator \
			or int(entry.get("x", -1)) != context.x_register or int(entry.get("y", -1)) != context.y_register \
			or int(entry.get("sp", -1)) != context.stack_pointer \
			or int(registers.get("pc", -1)) != 0x8525 or int(registers.get("a", -1)) != 0x42 \
			or int(registers.get("x", -1)) != 0xF3 or int(registers.get("y", -1)) != _ram[0x05CD] \
			or int(registers.get("sp", -1)) != 0xEE \
			or int(mapper.get("bank_low", -1)) != context.bank_low \
			or int(mapper.get("bank_high", -1)) != context.bank_high \
			or int(map_worker_result.get("map_selector", -1)) != 0x42 \
			or int(map_worker_result.get("placement_input", -1)) != _ram[0x05CD] \
			or source_ram.size() != RAM_SIZE or source_stack.size() != STACK_PAGE_SIZE:
		return _fail("ROM `$8327->$8525` prefix result differs from its byte, CPU, and provenance contract.")
	var expected_ram := _ram.duplicate()
	var expected_stack := _stack_page.duplicate()
	for write_variant in writes_variant:
		if not write_variant is Dictionary:
			return _fail("The `$8327` RAM stream contains a malformed write event.")
		var write: Dictionary = write_variant
		var address := int(write.get("address", -1))
		var value := int(write.get("value", -1))
		if address != 0x05CC or value != 0x42:
			return _fail("The `$8327` prefix wrote an unapproved RAM byte at `$%04X`." % address)
		expected_ram[address] = value
	for write_variant in stack_writes_variant:
		if not write_variant is Dictionary:
			return _fail("The `$8327` stack stream contains a malformed write event.")
		var write: Dictionary = write_variant
		var address := int(write.get("address", -1))
		var value := int(write.get("value", -1))
		if address not in [0x01F0, 0x01EF] or value < 0 or value > 0xFF:
			return _fail("The `$8525` JSR frame wrote an unapproved stack byte at `$%04X`." % address)
		expected_stack[address & 0xFF] = value
	for stack_offset in STACK_PAGE_SIZE:
		expected_ram[0x0100 + stack_offset] = expected_stack[stack_offset]
	for address in RAM_SIZE:
		if expected_ram[address] != source_ram[address]:
			return _fail("The `$8327` RAM replay differs at `$%04X`: replay=$%02X source=$%02X." % [address, expected_ram[address], source_ram[address]])
	for address in STACK_PAGE_SIZE:
		if expected_stack[address] != source_stack[address]:
			return _fail("The `$8525` stack replay differs at `$%02X`: replay=$%02X source=$%02X." % [address, expected_stack[address], source_stack[address]])
	_ram = expected_ram
	_stack_page = expected_stack
	context.accumulator = int(registers.get("a", -1))
	context.x_register = int(registers.get("x", -1))
	context.y_register = int(registers.get("y", -1))
	context.stack_pointer = int(registers.get("sp", -1))
	context.program_counter = int(registers.get("pc", -1))
	context.status_register = int(registers.get("p", context.status_register))
	context.status_known_mask = int(registers.get("p_known_mask", context.status_known_mask))
	context.source_label = "ROM-byte `$8327` map handler called worker `$8525`"
	return true


## Adopts the ROM-executed map-$42 setup through the `$856F` yield callsite.
func adopt_slot15_map_worker_yield_callsite(worker_result: Dictionary) -> bool:
	if not _require_initialized():
		return false
	var context: TaskContext = _contexts.get(0x15)
	if _active_task_slot != 0x15 or context == null or context.phase != ContextPhase.RUNNING \
			or context.program_counter != 0x8525:
		return _fail("Map-worker setup requires active slot-$15 at `$8525`.")
	var entry_variant: Variant = worker_result.get("entry_registers", {})
	var registers_variant: Variant = worker_result.get("registers", {})
	var mapper_variant: Variant = worker_result.get("mapper", {})
	var source_ram_variant: Variant = worker_result.get("ram_image", PackedByteArray())
	var source_stack_variant: Variant = worker_result.get("stack_page", PackedByteArray())
	var writes_variant: Variant = worker_result.get("ram_writes", [])
	var stack_writes_variant: Variant = worker_result.get("stack_writes", [])
	if not entry_variant is Dictionary or not registers_variant is Dictionary \
			or not mapper_variant is Dictionary or not source_ram_variant is PackedByteArray \
			or not source_stack_variant is PackedByteArray or not writes_variant is Array \
			or not stack_writes_variant is Array:
		return _fail("Map-worker `$856F` result omits source CPU, mapper, memory, or writes.")
	var entry: Dictionary = entry_variant
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var source_ram: PackedByteArray = source_ram_variant
	var source_stack: PackedByteArray = source_stack_variant
	var expected_hashes := {
		"worker_8525": "1b406e85c56269d2369ebe99eb26c662b48fe32aedfb55c40e654bf3bc4e0f8a",
		"selector_routine_86d3": "08c5584a0bae0feb953cd6f98c7a8dc792d1304c047872dd8f6b145ac7a555b7",
		"chr_pair_42": "50ccd3ef9e7c33fc6961800add05d3ed815ad357d03d7fbfcb74354a40986c46",
		"packed_selector_table": "2dac66189d5f3d9e733016f5005bb1b667822781cf5be50e27753f3b814c170e",
		"yield_callsite": "59653ff81dfe5c01f141d4ee69bb4832290c727091c41b92a71a6b0e2400a837",
	}
	if String(worker_result.get("rom_sha256", "")) != "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097" \
			or String(worker_result.get("status", "")) != "reached_first_map_worker_yield_callsite" \
			or int(worker_result.get("entry_pc", -1)) != 0x8525 \
			or int(worker_result.get("exit_pc", -1)) != 0x856F \
			or worker_result.get("source_hashes", {}) != expected_hashes \
			or int(worker_result.get("yield_callsite", -1)) != 0x856F \
			or bool(worker_result.get("trace_state_used", true)) \
			or not (worker_result.get("ppu_bus_events", []) as Array).is_empty() \
			or not (worker_result.get("apu_register_writes", []) as Array).is_empty() \
			or int(entry.get("pc", -1)) != 0x8525 or int(entry.get("a", -1)) != context.accumulator \
			or int(entry.get("x", -1)) != context.x_register or int(entry.get("y", -1)) != context.y_register \
			or int(entry.get("sp", -1)) != context.stack_pointer \
			or int(registers.get("pc", -1)) != 0x856F or int(registers.get("a", -1)) != 0x01 \
			or int(registers.get("x", -1)) != 0x08 or int(registers.get("y", -1)) != 0x10 \
			or int(registers.get("sp", -1)) != 0xED or int(registers.get("p", -1)) != 0x20 \
			or int(mapper.get("bank_low", -1)) != 0x0B or int(mapper.get("bank_high", -1)) != 0x0C \
			or int(worker_result.get("map_id", -1)) != 0x42 \
			or int(worker_result.get("map_selector", -1)) != 0x01 \
			or worker_result.get("chr_pair", PackedByteArray()) != PackedByteArray([0x3C, 0x2C]) \
			or worker_result.get("staged_chr_pair", PackedByteArray()) != PackedByteArray([0xBC, 0x2C]) \
			or int(worker_result.get("map_data_pointer", -1)) != 0x93A4 \
			or int(worker_result.get("placement", -1)) != _ram[0x05CD] \
			or int(worker_result.get("row_count", -1)) != 0x20 \
			or source_ram.size() != RAM_SIZE or source_stack.size() != STACK_PAGE_SIZE:
		return _fail("ROM map-$42 setup at `$856F` differs from its decoded source-data contract.")
	var expected_ram := _ram.duplicate()
	var expected_stack := _stack_page.duplicate()
	for write_variant in writes_variant:
		if not write_variant is Dictionary:
			return _fail("The `$8525` RAM stream contains a malformed write event.")
		var write: Dictionary = write_variant
		var address := int(write.get("address", -1))
		var value := int(write.get("value", -1))
		if address not in [0x0054, 0x0055, 0x0526, 0x0527, 0x05C8, 0x05C9, 0x05CA] \
				or value < 0 or value > 0xFF:
			return _fail("The `$8525` prefix wrote an unapproved RAM address `$%04X`." % address)
		expected_ram[address] = value
	for write_variant in stack_writes_variant:
		if not write_variant is Dictionary:
			return _fail("The `$8525` stack stream contains a malformed write event.")
		var write: Dictionary = write_variant
		var address := int(write.get("address", -1))
		var value := int(write.get("value", -1))
		if address not in [0x01EE, 0x01ED, 0x01EC] or value < 0 or value > 0xFF:
			return _fail("The `$8525` prefix wrote an unapproved stack address `$%04X`." % address)
		expected_stack[address & 0xFF] = value
	for stack_offset in STACK_PAGE_SIZE:
		expected_ram[0x0100 + stack_offset] = expected_stack[stack_offset]
	for address in RAM_SIZE:
		if expected_ram[address] != source_ram[address]:
			return _fail("The `$8525` RAM replay differs at `$%04X`: replay=$%02X source=$%02X." % [address, expected_ram[address], source_ram[address]])
	for address in STACK_PAGE_SIZE:
		if expected_stack[address] != source_stack[address]:
			return _fail("The `$8525` stack replay differs at `$%02X`: replay=$%02X source=$%02X." % [address, expected_stack[address], source_stack[address]])
	_ram = expected_ram
	_stack_page = expected_stack
	context.accumulator = int(registers.get("a", -1))
	context.x_register = int(registers.get("x", -1))
	context.y_register = int(registers.get("y", -1))
	context.stack_pointer = int(registers.get("sp", -1))
	context.program_counter = int(registers.get("pc", -1))
	context.status_register = int(registers.get("p", context.status_register))
	context.status_known_mask = int(registers.get("p_known_mask", context.status_known_mask))
	context.source_label = "ROM-byte map-$42 worker through `$856F` cooperative-yield callsite"
	return true


## Adopts the first three ROM-derived map-$42 packet groups after the selected
## slot-$15 task resumes from `$C515` at `$8572`.
func adopt_slot15_map42_batch_result(worker_result: Dictionary) -> bool:
	if not _require_initialized():
		return false
	var context: TaskContext = _contexts.get(0x15)
	if _active_task_slot != 0x15 or context == null \
			or context.phase != ContextPhase.RUNNING or context.program_counter != 0x8572:
		return _fail("Map-$42 batch adoption requires the resumed slot-$15 `$8572` context.")
	var entry_variant: Variant = worker_result.get("entry_registers", {})
	var registers_variant: Variant = worker_result.get("registers", {})
	var mapper_variant: Variant = worker_result.get("mapper", {})
	var entry_ram_variant: Variant = worker_result.get("entry_ram_image", PackedByteArray())
	var updated_ram_variant: Variant = worker_result.get("updated_ram", PackedByteArray())
	var entry_stack_variant: Variant = worker_result.get("entry_stack_page", PackedByteArray())
	var stack_variant: Variant = worker_result.get("stack_page", PackedByteArray())
	var writes_variant: Variant = worker_result.get("ram_writes", [])
	if not entry_variant is Dictionary or not registers_variant is Dictionary \
			or not mapper_variant is Dictionary or not entry_ram_variant is PackedByteArray \
			or not updated_ram_variant is PackedByteArray or not entry_stack_variant is PackedByteArray \
			or not stack_variant is PackedByteArray or not writes_variant is Array:
		return _fail("Map-$42 batch result omits CPU, mapper, RAM, stack, or write data.")
	var entry: Dictionary = entry_variant
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var entry_ram: PackedByteArray = entry_ram_variant
	var updated_ram: PackedByteArray = updated_ram_variant
	var entry_stack: PackedByteArray = entry_stack_variant
	var result_stack: PackedByteArray = stack_variant
	var expected_hashes := {
		"worker_8572_85c2": "098a354cae578918bf54407b972e69b520327d030eb391ed3c2d476c4d337502",
		"metatile_expand_85c2_86d3": "1aab318fd595b2cf9f82ed8176340dfe43d4fbdc792e9204ede31c2d21c79e15",
		"block_map_42": "0a9b49db69d34648c87f480c6eb6c5a015e4880e231f0f46b896391719f4b1ae",
		"metatile_14_tiles": "374708fff7719dd5979ec875d56cd2286f6d3cf7ec317a3b25632aab28ec37bb",
		"metatile_14_attribute": "6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d",
		"metatile_33_tiles": "c1b0c2097d76922820e5daf5ca095f8aa1ff51948ee1201dd5fed705fadb58fe",
		"metatile_33_attribute": "bceef655b5a034911f1c3718ce056531b45ef03b4c7b1f15629e867294011a7d",
		"metatile_15_tiles": "18b013f1362799dbb2a4ee3c0ba84ce6d236b7c82a89793899db4919d3dfab9f",
		"metatile_15_attribute": "aa7225e7d5b0a2552bbb58880b3ec00c286995b801a7aeb69281e76a8b4908de",
		"metatile_16_tiles": "f396045da5b50769278c8d36c46ec034d65d6776cec27d49d6b15581ea6a4050",
		"metatile_16_attribute": "aa7225e7d5b0a2552bbb58880b3ec00c286995b801a7aeb69281e76a8b4908de",
		"metatile_EA_tiles": "f053daa04e3c5a86cba482abca9fec2aaa68f6ef5048ed9730ea6c8d83ccfd23",
		"metatile_EA_attribute": "a8100ae6aa1940d0b663bb31cd466142ebbdbd5187131b92d93818987832eb89",
		"metatile_EB_tiles": "a2d2d606a7c02d92acce0f45be5610ef4163d77ac44ba18f33541aa074df431a",
		"metatile_EB_attribute": "a8100ae6aa1940d0b663bb31cd466142ebbdbd5187131b92d93818987832eb89",
	}
	var batch_start_map_index := int(worker_result.get("batch_start_map_index", -1))
	var batch_start_placement := int(worker_result.get("batch_start_placement", -1))
	var batch_cell_count := int(worker_result.get("batch_cell_count", -1))
	var expected_queue_size := 0
	var expected_output_y := 0x10
	for cell_offset in range(batch_cell_count):
		var cell_placement := (batch_start_placement + cell_offset) & 0xFF
		if (cell_placement & 0x3F) >= 0x38:
			expected_output_y = expected_queue_size + 0x05
			expected_queue_size += 0x12
		else:
			expected_output_y = 0x10
			expected_queue_size += 0x20
	var expected_output_c8 := (batch_start_placement + batch_cell_count) & 0xFF
	var expected_output_c9 := 0x20 - batch_start_map_index - batch_cell_count
	var expected_callsite_pc := 0x85BE if expected_output_c9 == 0 else 0x856F
	var expected_callsite_sp := 0xEE if expected_output_c9 == 0 else 0xED
	var supported_placement := (batch_start_map_index == 0 and batch_start_placement in [0, 0xA0]) \
			or (batch_start_map_index > 0 and batch_start_placement in [
				batch_start_map_index, 0xA0 + batch_start_map_index])
	if String(worker_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(worker_result.get("status", "")) != "map42_%d_metatiles_ready_at_yield" % batch_cell_count \
			or worker_result.get("source_hashes", {}) != expected_hashes \
			or int(worker_result.get("entry_pc", -1)) != 0x8572 \
			or int(worker_result.get("exit_pc", -1)) != expected_callsite_pc \
			or int(worker_result.get("callsite_pc", -1)) != expected_callsite_pc \
			or bool(worker_result.get("map_exhausted_branch", false)) != (expected_output_c9 == 0) \
			or bool(worker_result.get("trace_state_used", true)) \
			or bool(worker_result.get("source_cycle_timing_modeled", true)) \
			or bool(worker_result.get("temporary_stack_writes_modeled", true)) \
			or batch_start_map_index not in [0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30] \
			or not supported_placement \
			or int(entry.get("pc", -1)) != context.program_counter \
			or int(entry.get("a", -1)) != context.accumulator \
			or int(entry.get("x", -1)) != context.x_register \
			or int(entry.get("y", -1)) != context.y_register \
			or int(entry.get("sp", -1)) != context.stack_pointer \
			or int(registers.get("pc", -1)) != expected_callsite_pc \
			or int(registers.get("a", -1)) != 0x01 \
			or int(registers.get("x", -1)) != expected_queue_size \
			or int(registers.get("y", -1)) != expected_output_y \
			or int(registers.get("sp", -1)) != expected_callsite_sp \
			or int(mapper.get("bank_low", -1)) != 0x0B \
			or int(mapper.get("bank_high", -1)) != 0x12 \
			or entry_ram.size() != RAM_SIZE or updated_ram.size() != RAM_SIZE \
			or entry_stack.size() != STACK_PAGE_SIZE or result_stack.size() != STACK_PAGE_SIZE \
			or entry_ram != _ram or entry_stack != _stack_page \
			or result_stack != entry_stack \
			or batch_cell_count != mini(3, 0x20 - batch_start_map_index) \
			or int(worker_result.get("batch_queue_byte_count", -1)) != expected_queue_size \
			or int(worker_result.get("last_metatile_return_y", -1)) != expected_output_y \
			or expected_queue_size <= 0 or expected_queue_size > 0x60 \
			or worker_result.get("queue_bytes", PackedByteArray()).size() != expected_queue_size \
			or (worker_result.get("map_calls", []) as Array).size() != batch_cell_count:
		return _fail("Resumed map-$42 batch differs from its source-selected task boundary or ROM-sized batch contract.")
	var expected_ram := _ram.duplicate()
	for write_variant in writes_variant:
		if not write_variant is Dictionary:
			return _fail("Map-$42 batch contains a malformed RAM write.")
		var write: Dictionary = write_variant
		var address := int(write.get("address", -1))
		var value := int(write.get("value", -1))
		var allowed := address in [0x0023, 0x0025, 0x0515, 0x05C7, 0x05C8, 0x05C9, 0x05CA] \
				or (address >= 0x04A5 and address <= 0x0505)
		if not allowed or value < 0 or value > 0xFF:
			return _fail("Map-$42 batch wrote outside its row queue and worker state at `$%04X`." % address)
		expected_ram[address] = value
	if expected_ram != updated_ram:
		return _fail("Map-$42 worker write stream does not reproduce its returned RAM image.")
	if int(updated_ram[0x0515]) != 0x80 or int(updated_ram[0x05C7]) != expected_queue_size \
			or int(updated_ram[0x05C8]) != expected_output_c8 \
			or int(updated_ram[0x05C9]) != expected_output_c9:
		return _fail("Map-$42 batch output cursor differs from its source row count.")
	_ram = updated_ram.duplicate()
	_stack_page = result_stack.duplicate()
	for offset in STACK_PAGE_SIZE:
		_ram[0x0100 + offset] = _stack_page[offset]
	context.accumulator = int(registers["a"])
	context.x_register = int(registers["x"])
	context.y_register = int(registers["y"])
	context.stack_pointer = int(registers["sp"])
	context.program_counter = int(registers["pc"])
	context.status_register = int(registers.get("p", context.status_register))
	context.status_known_mask = int(registers.get("p_known_mask", context.status_known_mask))
	context.bank_low = int(mapper["bank_low"])
	context.bank_high = int(mapper["bank_high"])
	context.source_label = "ROM-derived map-$42 %d `$85C2` packet groups through `$%04X`" % [batch_cell_count, expected_callsite_pc]
	return true


## Adopts the ROM-byte callback/dispatcher return after map-$42 cell 31.
## The executor is limited to the observed zero-placement branch and returns
## at the verified fixed-bank `$CAF7` task-finish handler.
func adopt_slot15_map42_terminal_return_result(worker_result: Dictionary) -> bool:
	if not _require_initialized():
		return false
	var context: TaskContext = _contexts.get(0x15)
	if _active_task_slot != 0x15 or context == null \
			or context.phase != ContextPhase.RUNNING or context.program_counter != 0x85C1:
		return _fail("Map-$42 terminal-return adoption requires the running slot-$15 `$85C1 RTS` boundary.")
	var entry_variant: Variant = worker_result.get("entry_registers", {})
	var registers_variant: Variant = worker_result.get("registers", {})
	var entry_ram_variant: Variant = worker_result.get("entry_ram_image", PackedByteArray())
	var updated_ram_variant: Variant = worker_result.get("updated_ram", PackedByteArray())
	var entry_stack_variant: Variant = worker_result.get("entry_stack_page", PackedByteArray())
	var stack_variant: Variant = worker_result.get("stack_page", PackedByteArray())
	var writes_variant: Variant = worker_result.get("ram_writes", [])
	var hashes_variant: Variant = worker_result.get("source_hashes", {})
	if not entry_variant is Dictionary or not registers_variant is Dictionary \
			or not entry_ram_variant is PackedByteArray or not updated_ram_variant is PackedByteArray \
			or not entry_stack_variant is PackedByteArray or not stack_variant is PackedByteArray \
			or not writes_variant is Array or not hashes_variant is Dictionary:
		return _fail("Map-$42 terminal-return result omits its CPU, memory, writes, or source hashes.")
	var entry: Dictionary = entry_variant
	var registers: Dictionary = registers_variant
	var entry_ram: PackedByteArray = entry_ram_variant
	var updated_ram: PackedByteArray = updated_ram_variant
	var entry_stack: PackedByteArray = entry_stack_variant
	var result_stack: PackedByteArray = stack_variant
	var source_hashes: Dictionary = hashes_variant
	if String(worker_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(worker_result.get("status", "")) != "slot15_map42_terminal_return_reached_CAF7" \
			or int(worker_result.get("exit_pc", -1)) != 0xCAF7 \
			or bool(worker_result.get("trace_state_used", true)) \
			or bool(worker_result.get("source_cycle_timing_modeled", true)) \
			or String(source_hashes.get("worker", "")) != "098a354cae578918bf54407b972e69b520327d030eb391ed3c2d476c4d337502" \
			or String(source_hashes.get("placement", "")) != "e3ed67bcd4a760f0f8324b4d46ca08100ef6d1b578af495da8475b7e66096853" \
			or String(source_hashes.get("dispatcher", "")) != "c648a228e5e90247ce604220a2aff2bb4b1c58af30546e71b543fec874b28df6" \
			or String(source_hashes.get("finish_trampoline", "")) != "bc85dc6c05fac84b9063f3cb28a3acbe16e2591ab2dff53b935530aa2a35940f":
		return _fail("Map-$42 terminal-return source identity or exit contract differs.")
	if entry_ram.size() != RAM_SIZE or updated_ram.size() != RAM_SIZE \
			or entry_stack.size() != STACK_PAGE_SIZE or result_stack.size() != STACK_PAGE_SIZE \
			or entry_ram != _ram or entry_stack != _stack_page \
			or int(entry.get("pc", -1)) != 0x85C1 or int(entry.get("sp", -1)) != 0xEE \
			or int(entry.get("a", -1)) != context.accumulator \
			or int(entry.get("x", -1)) != context.x_register \
			or int(entry.get("y", -1)) != context.y_register:
		return _fail("Terminal-return entry image no longer matches the live slot-$15 context.")
	if result_stack != entry_stack or int(registers.get("pc", -1)) != 0xCAF7 \
			or int(registers.get("sp", -1)) != 0xF2 \
			or int(registers.get("x", -1)) != int(entry["x"]) \
			or int(registers.get("y", -1)) != int(entry["y"]) \
			or int(registers.get("a", -1)) != (int(entry_ram[0x0516]) | 0x10):
		return _fail("Terminal-return CPU registers do not match the source RTS/dispatcher/trampoline path.")
	var callback_placement := int(entry_ram[0x05CD])
	var expected_placement_page := 0
	var expected_next_placement := 0xA0
	if callback_placement != 0:
		expected_placement_page = (callback_placement & 0x20) | 0x80
		expected_next_placement = expected_placement_page ^ 0x20
	if int(entry_ram[0x05CC]) != 0x42 or int(entry_ram[0x05C9]) != 0 \
			or not ((int(entry_ram[0x05C7]) == 0x24 \
			and int(entry_ram[0x05C8]) == 0xC0 and callback_placement == 0xA0) \
			or (int(entry_ram[0x05C7]) == 0x40 \
			and int(entry_ram[0x05C8]) == 0x20 and callback_placement == 0)):
		return _fail("Terminal-return entry RAM is outside the two checked map-$42 callback branches.")
	var expected_write_contract := [
		{"address": 0x05CB, "value": 0x01, "pc_after_write": 0x8339},
		{"address": 0x05CE, "value": expected_placement_page, "pc_after_write": 0x8345},
		{"address": 0x05CD, "value": expected_next_placement, "pc_after_write": 0x834C},
		{"address": 0x05DB, "value": 0x00, "pc_after_write": 0x8351},
		{"address": 0x05DC, "value": 0x00, "pc_after_write": 0x8354},
		{"address": 0x05DD, "value": 0x00, "pc_after_write": 0x8357},
		{"address": 0x0516, "value": int(entry_ram[0x0516]) | 0x10, "pc_after_write": 0x81A4},
	]
	var writes: Array = writes_variant
	if writes.size() != expected_write_contract.size():
		return _fail("Terminal-return produced an unexpected number of source-ordered RAM writes.")
	var reconstructed_ram := entry_ram.duplicate()
	for write_index in range(expected_write_contract.size()):
		var write_variant: Variant = writes[write_index]
		if not write_variant is Dictionary:
			return _fail("Terminal-return RAM write %d is malformed." % write_index)
		var write: Dictionary = write_variant
		var expected: Dictionary = expected_write_contract[write_index]
		var address := int(expected["address"])
		if int(write.get("address", -1)) != address \
				or int(write.get("old", -1)) != int(reconstructed_ram[address]) \
				or int(write.get("value", -1)) != int(expected["value"]) \
				or int(write.get("pc_after_write", -1)) != int(expected["pc_after_write"]) \
				or _is_scheduler_owned_ram_address(address):
			return _fail("Terminal-return RAM write %d differs from the bounded ROM source contract." % write_index)
		reconstructed_ram[address] = int(write["value"])
	if reconstructed_ram != updated_ram:
		return _fail("Terminal-return RAM image contains writes outside its source-ordered instruction stream.")
	for write_variant in writes:
		var write: Dictionary = write_variant
		_ram[int(write["address"])] = int(write["value"])
	context.accumulator = int(registers["a"])
	context.x_register = int(registers["x"])
	context.y_register = int(registers["y"])
	context.stack_pointer = int(registers["sp"])
	context.program_counter = int(registers["pc"])
	context.status_register = int(registers.get("p", context.status_register))
	context.status_known_mask = int(registers.get("p_known_mask", 0x83))
	context.source_label = "ROM-byte map-$42 exhausted-row callback return through `$C512->$CAF7`"
	return true


## Applies the verified `$CB0F` save routine at a packaged caller site. The
## caller's SP is the pre-JSR stack pointer; caller state must come from a
## decoded task-body continuation.
func save_slot11_actor_worker_first_yield(worker_result: Dictionary) -> Dictionary:
	if not _require_initialized():
		return {}
	var context: TaskContext = _contexts.get(0x11)
	if _active_task_slot != 0x11 or int(_ram[0x0000]) != 0x11 or context == null \
			or context.phase != ContextPhase.RUNNING or context.program_counter != 0x8000 \
			or context.stack_pointer != 0xCA or context.bank_low != 0x18 \
			or context.bank_high != 0x19:
		_fail("Slot-$11 actor save requires its live initial `$8000` task context.")
		return {}
	if String(worker_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(worker_result.get("source_manifest", "")) != TASK_CONTEXT_ROOT + "manifest.json" \
			or String(worker_result.get("source_sha256", "")) != String(SOURCE_SPANS["slot11_actor_worker_prefix"]["sha256"]) \
			or String(worker_result.get("source_pointer_file", "")) != "bank18_actor_parameter_73_pointer_9306.bin" \
			or String(worker_result.get("source_pointer_sha256", "")) != String(SOURCE_SPANS["slot11_actor_parameter_73_pointer"]["sha256"]) \
			or int(worker_result.get("slot_base", -1)) != 0x11 \
			or int(worker_result.get("entry_pc", -1)) != 0x8000 \
			or int(worker_result.get("exit_pc", -1)) != 0x8047 \
			or int(worker_result.get("yield_callsite_pc", -1)) != 0x8047 \
			or int(worker_result.get("yield_target_pc", -1)) != 0xC515 \
			or int(worker_result.get("resolved_actor_stream_pointer", -1)) != 0x9F42 \
			or int(worker_result.get("resolved_parameter", -1)) != 0x73 \
			or bool(worker_result.get("trace_state_used", true)) \
			or bool(worker_result.get("ppu_apu_effects_applied", true)):
		_fail("Slot-$11 actor result is not the bounded, source-only `$8000->$8047` execution.")
		return {}
	var entry_record: Variant = worker_result.get("entry_record", PackedByteArray())
	var entry_ram: Variant = worker_result.get("entry_ram_image", PackedByteArray())
	var entry_stack: Variant = worker_result.get("entry_stack_page", PackedByteArray())
	var output_ram: Variant = worker_result.get("ram_image", PackedByteArray())
	var output_stack: Variant = worker_result.get("stack_page", PackedByteArray())
	var entry_registers: Variant = worker_result.get("entry_registers", {})
	var output_registers: Variant = worker_result.get("registers", {})
	var output_mapper: Variant = worker_result.get("mapper", {})
	var writes_variant: Variant = worker_result.get("memory_writes", [])
	if not entry_record is PackedByteArray or entry_record != _record_bytes(0x11) \
			or not entry_ram is PackedByteArray or entry_ram != _ram \
			or not entry_stack is PackedByteArray or entry_stack != _stack_page \
			or not output_ram is PackedByteArray or output_ram.size() != RAM_SIZE \
			or not output_stack is PackedByteArray or output_stack != _stack_page \
			or not entry_registers is Dictionary or not output_registers is Dictionary \
			or not output_mapper is Dictionary \
			or not writes_variant is Array:
		_fail("Slot-$11 actor result does not carry the live source-owned task, RAM, stack, or register input.")
		return {}
	var live_entry_registers := {
		"a": context.accumulator, "x": context.x_register, "y": context.y_register,
		"p": context.status_register, "p_known_mask": context.status_known_mask,
		"sp": context.stack_pointer, "pc": context.program_counter,
	}
	for key: String in live_entry_registers:
		if int(entry_registers.get(key, -1)) != int(live_entry_registers[key]):
			_fail("Slot-$11 actor prefix changed its live entry register `%s` before execution." % key)
			return {}
	var expected_registers := {
		"a": 0x01, "x": 0x42, "y": 0xE7, "sp": 0xCA, "pc": 0x8047,
	}
	for key: String in expected_registers:
		if int(output_registers.get(key, -1)) != int(expected_registers[key]):
			_fail("Slot-$11 actor prefix output `%s` differs from its source boundary." % key)
			return {}
	var entry_p := int(entry_registers.get("p", -1))
	var entry_p_known := int(entry_registers.get("p_known_mask", -1))
	var expected_p_known := entry_p_known | 0xC3
	var expected_p := (entry_p & ~0xC3) | (int(_ram[0x063F]) & 0x40)
	if entry_p < 0 or entry_p > 0xFF or entry_p_known < 0 or entry_p_known > 0xFF \
			or int(output_registers.get("p", -1)) != expected_p \
			or int(output_registers.get("p_known_mask", -1)) != expected_p_known \
			or int(output_mapper.get("bank_low", -1)) != 0x18 \
			or int(output_mapper.get("bank_high", -1)) != 0x19:
		_fail("Slot-$11 actor prefix flag or mapper output is not derived from its live inputs.")
		return {}
	var expected_instruction_pcs: Array[int] = [
		0x8000, 0x800F, 0x8012, 0x8017, 0x8019, 0x801B, 0x801D, 0x801F,
		0x8022, 0x8023, 0x8027, 0x8028, 0x802A, 0x802B, 0x802C, 0x802E,
		0x8030, 0x8032, 0x8034, 0x8037, 0x803A, 0x803D, 0x8040, 0x8042, 0x8045,
	]
	var instruction_pcs: Variant = worker_result.get("instruction_pcs", [])
	if not instruction_pcs is Array or instruction_pcs != expected_instruction_pcs:
		_fail("Slot-$11 actor prefix instruction path differs from the parameter-$73 branch.")
		return {}
	var expected_writes := [
		[0x8019, 0x005F, 0x20], [0x801D, 0x0060, 0x92],
		[0x802E, 0x0060, 0x9F], [0x8030, 0x005F, 0x42],
		[0x8034, 0x05E9, 0x00], [0x8037, 0x05E5, 0x00],
		[0x803A, 0x05E4, 0x00], [0x803D, 0x05F4, 0x00],
		[0x8042, 0x05E3, 0x01],
	]
	if writes_variant.size() != expected_writes.size():
		_fail("Slot-$11 actor prefix did not produce the expected nine source writes.")
		return {}
	var expected_ram := _ram.duplicate()
	for index: int in expected_writes.size():
		var write_variant: Variant = writes_variant[index]
		if not write_variant is Dictionary:
			_fail("Slot-$11 actor prefix write %d is malformed." % index)
			return {}
		var write: Dictionary = write_variant
		var expected: Array = expected_writes[index]
		if int(write.get("pc", -1)) != int(expected[0]) \
				or int(write.get("address", -1)) != int(expected[1]) \
				or int(write.get("value", -1)) != int(expected[2]):
			_fail("Slot-$11 actor prefix write %d differs from its ROM instruction." % index)
			return {}
		expected_ram[int(expected[1])] = int(expected[2])
	if output_ram != expected_ram:
		_fail("Slot-$11 actor prefix changed RAM outside the nine decoded source stores.")
		return {}
	for write_variant in writes_variant:
		var write: Dictionary = write_variant
		_ram[int(write["address"])] = int(write["value"])
	context.accumulator = int(output_registers["a"])
	context.x_register = int(output_registers["x"])
	context.y_register = int(output_registers["y"])
	context.status_register = int(output_registers.get("p", context.status_register))
	context.status_known_mask = int(output_registers.get("p_known_mask", context.status_known_mask))
	context.program_counter = 0x8047
	context.source_label = "ROM-byte slot-$11 actor setup `$8000->$8047`"
	_slot11_actor_worker_yield_in_progress = true
	var caller_sp := context.stack_pointer
	var saved := yield_at_verified_callsite(0x11, 0x8047,
		context.accumulator, caller_sp, context.x_register, context.y_register,
		context.bank_low, context.bank_high)
	_slot11_actor_worker_yield_in_progress = false
	if not saved:
		return {}
	var boundary := get_task_boundary_snapshot(0x11)
	return {
		"ok": true,
		"status": "slot11_actor_worker_yielded_at_cb0f",
		"rom_sha256": ROM_SHA256,
		"source_manifest": TASK_CONTEXT_ROOT + "manifest.json",
		"source_callsite_pc": 0x8047,
		"yield_target_pc": 0xCB0F,
		"cb0f_entry_registers": {
			"a": int(output_registers["a"]),
			"x": int(output_registers["x"]),
			"y": int(output_registers["y"]),
			"p": int(output_registers.get("p", -1)),
			"sp": (caller_sp - 2) & 0xFF,
			"pc": 0xCB0F,
		},
		"saved_boundary": boundary,
		"trace_state_used": false,
		"ppu_apu_effects_applied": false,
	}


## Replays the verified `$804A->$CC50` actor-stream continuation into the live
## slot-$11 context, then runs the existing `$CB0F` task-save contract. The
## worker has already pushed `$CC52` on its stack, so the save reuses that frame.
func _validate_slot11_actor_worker_resume_result(result: Dictionary) -> Dictionary:
	if String(result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(result.get("status", "")) != "slot11_actor_worker_at_cb0f_from_cc50" \
			or String(result.get("source_manifest", "")) != SLOT11_RESUME_MANIFEST \
			or int(result.get("slot_base", -1)) != 0x11 \
			or int(result.get("entry_pc", -1)) != 0x804A \
			or int(result.get("exit_pc", -1)) != 0xCB0F \
			or int(result.get("yield_callsite_pc", -1)) != 0xCC50 \
			or int(result.get("yield_target_pc", -1)) != 0xCB0F \
			or int(result.get("resume_pc_after_rts", -1)) != 0xCC53 \
			or int(result.get("resolved_f4_target", -1)) != 0x9F52 \
			or int(result.get("resolved_f5_handler", -1)) != 0x81FD \
			or not bool(result.get("call_frame_already_pushed", false)) \
			or bool(result.get("trace_state_used", true)) \
			or bool(result.get("ppu_apu_effects_applied", true)) \
			or bool(result.get("source_timing_modeled", true)):
		return {"ok": false, "reason": "Input is not the bounded ROM-byte slot-$11 `$CC50->$CB0F` result."}
	if result.get("source_span_hashes", {}) != SLOT11_RESUME_SOURCE_HASHES:
		return {"ok": false, "reason": "Slot-$11 resume source-span hashes differ from their verified manifest package."}
	var entry_record: Variant = result.get("entry_record", PackedByteArray())
	var entry_ram: Variant = result.get("entry_ram_image", PackedByteArray())
	var entry_stack: Variant = result.get("entry_stack_page", PackedByteArray())
	var entry_registers: Variant = result.get("entry_registers", {})
	var callsite_registers: Variant = result.get("yield_callsite_registers", {})
	var cb0f_registers: Variant = result.get("cb0f_entry_registers", {})
	var mapper: Variant = result.get("mapper", {})
	var save_contract: Variant = result.get("scheduler_save_contract", {})
	var source_reads: Variant = result.get("source_reads", [])
	var ram_writes: Variant = result.get("ram_writes", [])
	var stack_writes: Variant = result.get("stack_writes", [])
	var output_ram: Variant = result.get("ram_image", PackedByteArray())
	var output_stack: Variant = result.get("stack_page", PackedByteArray())
	var callsite_stack: Variant = result.get("yield_callsite_stack_page", PackedByteArray())
	var ppu_events: Variant = result.get("ppu_bus_events", [])
	var apu_writes: Variant = result.get("apu_register_writes", [])
	if not entry_record is PackedByteArray or entry_record != PackedByteArray([0x00, 0xC6, 0x18, 0x19]) \
			or not entry_ram is PackedByteArray or entry_ram.size() != RAM_SIZE \
			or not entry_stack is PackedByteArray or entry_stack.size() != STACK_PAGE_SIZE \
			or not entry_registers is Dictionary or not callsite_registers is Dictionary \
			or not cb0f_registers is Dictionary or not mapper is Dictionary \
			or not save_contract is Dictionary or not source_reads is Array \
			or not ram_writes is Array or not stack_writes is Array \
			or not output_ram is PackedByteArray or output_ram.size() != RAM_SIZE \
			or not output_stack is PackedByteArray or output_stack.size() != STACK_PAGE_SIZE \
			or not callsite_stack is PackedByteArray or callsite_stack.size() != STACK_PAGE_SIZE \
			or not ppu_events is Array or not ppu_events.is_empty() \
			or not apu_writes is Array or not apu_writes.is_empty():
		return {"ok": false, "reason": "Slot-$11 resume result omits its source boundary, writes, mapper, or side-effect fields."}
	var entry: Dictionary = entry_registers
	var callsite: Dictionary = callsite_registers
	var cb0f: Dictionary = cb0f_registers
	var source_mapper: Dictionary = mapper
	var save: Dictionary = save_contract
	if int(entry.get("pc", -1)) != 0x804A or int(entry.get("sp", -1)) != 0xCA \
			or int(entry.get("a", -1)) != 0x42 or int(entry.get("x", -1)) != 0x42 \
			or int(entry.get("y", -1)) != 0xE7 \
			or int(callsite.get("pc", -1)) != 0xCC50 or int(callsite.get("sp", -1)) != 0xC3 \
			or int(callsite.get("a", -1)) != 0x01 or int(callsite.get("x", -1)) != 0x52 \
			or int(callsite.get("y", -1)) != 0x0C \
			or int(cb0f.get("pc", -1)) != 0xCB0F or int(cb0f.get("sp", -1)) != 0xC1 \
			or int(cb0f.get("a", -1)) != 0x01 or int(cb0f.get("x", -1)) != 0x52 \
			or int(cb0f.get("y", -1)) != 0x0C \
			or int(callsite.get("p", -1)) != int(cb0f.get("p", -2)) \
			or int(callsite.get("p_known_mask", -1)) != int(cb0f.get("p_known_mask", -2)) \
			or int(source_mapper.get("bank_low", -1)) != 0x18 \
			or int(source_mapper.get("bank_high", -1)) != 0x19 \
			or int(save.get("slot_base", -1)) != 0x11 \
			or int(save.get("delay_in_a", -1)) != 0x01 \
			or int(save.get("callsite_pc", -1)) != 0xCC50 \
			or int(save.get("target_pc", -1)) != 0xCB0F \
			or int(save.get("resume_pc", -1)) != 0xCC53 \
			or not bool(save.get("call_frame_already_pushed", false)) \
			or int(save.get("pre_jsr_sp", -1)) != 0xC3 \
			or int(save.get("cb0f_entry_sp", -1)) != 0xC1 \
			or save.get("rom_cb0f_push_order", []) != ["X", "Y"] \
			or int(save.get("expected_saved_sp_after_cb0f_pushes", -1)) != 0xBF \
			or save.get("mapper_low_high", PackedByteArray()) != PackedByteArray([0x18, 0x19]):
		return {"ok": false, "reason": "Slot-$11 resume CPU/mapper/save contract differs: record=%s entry=%s callsite=%s cb0f=%s mapper=%s save=%s." % [
			entry_record.hex_encode(), str(entry), str(callsite), str(cb0f), str(source_mapper), str(save)]}
	for expected_read: Array in [
		[0x9F42, 0xF4, "actor_stream_command"],
		[0x9F43, 0x04, "F4_selector"],
		[0x9F44, 0x52, "F4_target_pointer_low"],
		[0x9F45, 0x9F, "F4_target_pointer_high"],
		[0x9F52, 0xF5, "actor_stream_command"],
	]:
		if not _slot11_source_read_present(source_reads, int(expected_read[0]),
				int(expected_read[1]), String(expected_read[2])):
			return {"ok": false, "reason": "The slot-$11 source read stream omits a byte in the audited F4/F5 path."}
	return {"ok": true}


func _validate_slot11_actor_waiter_resume_result(result: Dictionary) -> Dictionary:
	var expected_hashes := {
		"fixed_task_yield_waiter_cc46_cc5d.bin": "dce4d011f0e612ea074e546e43c28c5395220f2af924a49aee4b35c2491775e3",
		"fixed_wait_packet_builder_CC53_CC9E.bin": "681bf402c35efba946da16d63cb53787bf50ed5ba87261929c10d19906b66d0c",
		"fixed_wait_counter_tail_CC9E_CCD1.bin": "28ae864c35cf13601f8cb93f4bc13f0cadcd64b9d401fff6f0bef8e2b656bee0",
	}
	var callsite_pc := int(result.get("yield_callsite_pc", -1))
	var entry_pc := int(result.get("entry_pc", -1))
	var callsite_sp := 0xC3 if callsite_pc == 0xCC50 else 0xC4
	var entry_sp := 0xC3 if entry_pc == 0xCC53 else 0xC4
	var entry_saved_sp := 0xBF if entry_pc == 0xCC53 else 0xC0
	var resume_pc := 0xCC53 if callsite_pc == 0xCC50 else 0xCCA3 if callsite_pc == 0xCCA0 else 0xCCD1
	var expected_status := "slot11_actor_waiter_at_cb0f_from_cc53" \
		if callsite_pc == 0xCC50 else "slot11_actor_waiter_tail_at_cb0f_from_cca0" \
		if callsite_pc == 0xCCA0 else "slot11_actor_waiter_final_packet_at_cb0f_from_ccce"
	var callsite_valid := (callsite_pc == 0xCC50 and entry_pc == 0xCC53) \
		or (callsite_pc == 0xCCA0 and entry_pc in [0xCC53, 0xCCA3]) \
		or (callsite_pc == 0xCCCE and entry_pc == 0xCCA3)
	if String(result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(result.get("source_manifest", "")) != SLOT11_RESUME_MANIFEST \
			or String(result.get("status", "")) != expected_status \
			or int(result.get("slot_base", -1)) != 0x11 \
			or not callsite_valid \
			or int(result.get("exit_pc", -1)) != 0xCB0F \
			or callsite_pc not in [0xCC50, 0xCCA0, 0xCCCE] \
			or int(result.get("yield_target_pc", -1)) != 0xCB0F \
			or int(result.get("resume_pc_after_rts", -1)) != resume_pc \
			or not bool(result.get("call_frame_already_pushed", true)) \
			or bool(result.get("trace_state_used", true)) \
			or bool(result.get("ppu_apu_effects_applied", true)) \
			or bool(result.get("source_timing_modeled", true)) \
			or result.get("source_span_hashes", {}) != expected_hashes:
		return {"ok": false, "reason": "Input is not a hash-checked ROM-byte slot-$11 waiter/tail `$CB0F` result."}
	var record: Variant = result.get("entry_record", PackedByteArray())
	var entry_ram: Variant = result.get("entry_ram_image", PackedByteArray())
	var entry_stack: Variant = result.get("entry_stack_page", PackedByteArray())
	var entry: Variant = result.get("entry_registers", {})
	var callsite: Variant = result.get("yield_callsite_registers", {})
	var cb0f: Variant = result.get("cb0f_entry_registers", {})
	var mapper: Variant = result.get("mapper", {})
	var save: Variant = result.get("scheduler_save_contract", {})
	var ram_writes: Variant = result.get("ram_writes", [])
	var stack_writes: Variant = result.get("stack_writes", [])
	var source_reads: Variant = result.get("source_reads", [])
	var output_ram: Variant = result.get("ram_image", PackedByteArray())
	var output_stack: Variant = result.get("stack_page", PackedByteArray())
	var callsite_stack: Variant = result.get("yield_callsite_stack_page", PackedByteArray())
	if not record is PackedByteArray or record != PackedByteArray([0x00, entry_saved_sp, 0x18, 0x19]) \
			or not entry_ram is PackedByteArray or entry_ram.size() != RAM_SIZE \
			or not entry_stack is PackedByteArray or entry_stack.size() != STACK_PAGE_SIZE \
			or not entry is Dictionary or not callsite is Dictionary or not cb0f is Dictionary \
			or not mapper is Dictionary or not save is Dictionary \
			or not ram_writes is Array or not stack_writes is Array or not source_reads is Array \
			or not output_ram is PackedByteArray or output_ram.size() != RAM_SIZE \
			or not output_stack is PackedByteArray or output_stack.size() != STACK_PAGE_SIZE \
			or not callsite_stack is PackedByteArray or callsite_stack.size() != STACK_PAGE_SIZE \
			or not (result.get("ppu_bus_events", []) is Array) \
			or not (result.get("ppu_bus_events", []) as Array).is_empty() \
			or not (result.get("apu_register_writes", []) is Array) \
			or not (result.get("apu_register_writes", []) as Array).is_empty():
		return {"ok": false, "reason": "The waiter result omits its live RAM/stack, writes, source reads, or side-effect declaration."}
	var entry_xy_ok: bool = (int(entry.get("x", -1)) == 0x52 and int(entry.get("y", -1)) == 0x0C) \
		or (int(entry.get("x", -1)) == 0x4F and int(entry.get("y", -1)) == 0x00)
	if entry_pc == 0xCCA3:
		entry_xy_ok = int(entry.get("x", -1)) == 0x4F and int(entry.get("y", -1)) == 0x00
	var callsite_xy_ok: bool = (int(callsite.get("x", -1)) == 0x52 and int(callsite.get("y", -1)) == 0x0C) \
		or (int(callsite.get("x", -1)) == 0x4F and int(callsite.get("y", -1)) == 0x00)
	if callsite_pc == 0xCCA0:
		callsite_xy_ok = int(callsite.get("x", -1)) == 0x4F and int(callsite.get("y", -1)) == 0x00
	elif callsite_pc == 0xCCCE:
		callsite_xy_ok = int(callsite.get("x", -1)) == 0x21 and int(callsite.get("y", -1)) == 0x00
	var cb0f_sp := (callsite_sp - 2) & 0xFF
	var saved_sp := (callsite_sp - 4) & 0xFF
	if int(entry.get("pc", -1)) != entry_pc or int(entry.get("sp", -1)) != entry_sp \
			or not entry_xy_ok or not callsite_xy_ok \
			or int(cb0f.get("x", -1)) != int(callsite.get("x", -2)) \
			or int(cb0f.get("y", -1)) != int(callsite.get("y", -2)) \
			or int(callsite.get("pc", -1)) != callsite_pc \
			or int(callsite.get("sp", -1)) != callsite_sp \
			or int(callsite.get("a", -1)) != 0x01 \
			or int(cb0f.get("pc", -1)) != 0xCB0F or int(cb0f.get("sp", -1)) != cb0f_sp \
			or int(cb0f.get("a", -1)) != 0x01 \
			or int(callsite.get("p", -1)) != int(cb0f.get("p", -2)) \
			or int(callsite.get("p_known_mask", -1)) != int(cb0f.get("p_known_mask", -2)) \
			or int(mapper.get("bank_low", -1)) != 0x18 \
			or int(mapper.get("bank_high", -1)) != 0x19 \
			or int(save.get("slot_base", -1)) != 0x11 \
			or int(save.get("delay_in_a", -1)) != 0x01 \
			or int(save.get("callsite_pc", -1)) != callsite_pc \
			or int(save.get("target_pc", -1)) != 0xCB0F \
			or int(save.get("resume_pc", -1)) != resume_pc \
			or int(save.get("pre_jsr_sp", -1)) != callsite_sp \
			or int(save.get("cb0f_entry_sp", -1)) != cb0f_sp \
			or int(save.get("expected_saved_sp_after_cb0f_pushes", -1)) != saved_sp \
			or save.get("mapper_low_high", PackedByteArray()) != PackedByteArray([0x18, 0x19]):
		return {"ok": false, "reason": "The slot-$11 waiter source CPU/mapper/save contract is inconsistent: entry=%s callsite=%s cb0f=%s mapper=%s save=%s." % [
			str(entry), str(callsite), str(cb0f), str(mapper), str(save)]}
	var expected_read_pc := 0xCC53 if entry_pc == 0xCC53 else 0xCCA3
	var expected_read_kind := "ppu_queue_pending_flag" if entry_pc == 0xCC53 else "counter_tail_queue_flag"
	if source_reads.is_empty() or source_reads[0] != {
			"pc": expected_read_pc, "address": 0x0515,
			"value": int(entry_ram[0x0515]), "kind": expected_read_kind}:
		return {"ok": false, "reason": "The waiter result did not branch from its live `$0515` input."}
	return {"ok": true}


func apply_slot11_actor_worker_resume_result(worker_result: Dictionary) -> Dictionary:
	if not _require_initialized():
		return {}
	var proof := _validate_slot11_actor_worker_resume_result(worker_result)
	if not bool(proof.get("ok", false)):
		_fail(String(proof.get("reason", "Invalid slot-$11 resume result.")))
		return {}
	var context: TaskContext = _contexts.get(0x11)
	if context == null or _active_task_slot != 0x11 or context.phase != ContextPhase.RUNNING \
			or context.program_counter != 0x804A or context.stack_pointer != 0xCA \
			or int(_ram[0x0000]) != 0x11 or _record_bytes(0x11) != PackedByteArray([0x00, 0xC6, 0x18, 0x19]) \
			or context.bank_low != 0x18 or context.bank_high != 0x19:
		_fail("Slot-$11 resume adoption requires the live dispatched `$804A` scheduler boundary.")
		return {}
	var entry_record: Variant = worker_result.get("entry_record", PackedByteArray())
	var entry_ram: Variant = worker_result.get("entry_ram_image", PackedByteArray())
	var entry_stack: Variant = worker_result.get("entry_stack_page", PackedByteArray())
	var entry_registers: Variant = worker_result.get("entry_registers", {})
	var source_ram: Variant = worker_result.get("ram_image", PackedByteArray())
	var source_stack: Variant = worker_result.get("stack_page", PackedByteArray())
	var source_writes: Variant = worker_result.get("ram_writes", [])
	var source_stack_writes: Variant = worker_result.get("stack_writes", [])
	var callsite_stack: Variant = worker_result.get("yield_callsite_stack_page", PackedByteArray())
	if not entry_record is PackedByteArray or entry_record != _record_bytes(0x11) \
			or not entry_ram is PackedByteArray or entry_ram != _ram \
			or not entry_stack is PackedByteArray or entry_stack != _stack_page \
			or not entry_registers is Dictionary or entry_registers != _register_snapshot(context) \
			or not source_ram is PackedByteArray or not source_stack is PackedByteArray \
			or not source_writes is Array or not source_stack_writes is Array \
			or not callsite_stack is PackedByteArray:
		_fail("Slot-$11 resume result does not start from the current live task, RAM, stack, and registers.")
		return {}
	var callsite_registers: Dictionary = worker_result["yield_callsite_registers"]
	var cb0f_registers: Dictionary = worker_result["cb0f_entry_registers"]
	var mapper: Dictionary = worker_result["mapper"]
	var save_contract: Dictionary = worker_result["scheduler_save_contract"]
	if callsite_registers.get("pc", -1) != 0xCC50 \
			or callsite_registers.get("sp", -1) != 0xC3 \
			or callsite_registers.get("a", -1) != 0x01 \
			or callsite_registers.get("x", -1) != 0x52 \
			or callsite_registers.get("y", -1) != 0x0C \
			or cb0f_registers.get("pc", -1) != 0xCB0F \
			or cb0f_registers.get("sp", -1) != 0xC1 \
			or callsite_registers.get("p", -1) != cb0f_registers.get("p", -2) \
			or callsite_registers.get("p_known_mask", -1) != cb0f_registers.get("p_known_mask", -2) \
			or mapper != context.mapper_state \
			or int(mapper.get("bank_low", -1)) != 0x18 \
			or int(mapper.get("bank_high", -1)) != 0x19 \
			or int(save_contract.get("pre_jsr_sp", -1)) != 0xC3 \
			or int(save_contract.get("cb0f_entry_sp", -1)) != 0xC1 \
			or int(save_contract.get("expected_saved_sp_after_cb0f_pushes", -1)) != 0xBF:
		_fail("Slot-$11 resume callsite registers, mapper, or CB0F save contract differs from the live source path.")
		return {}
	var writes: Array = source_writes
	var stack_writes: Array = source_stack_writes
	var pre_call_stack_writes: Array[Dictionary] = []
	var cc50_frame_writes: Array[Dictionary] = []
	for write_variant in stack_writes:
		if not write_variant is Dictionary:
			_fail("Slot-$11 resume contains a malformed stack-write event.")
			return {}
		var write: Dictionary = write_variant
		if int(write.get("pc", -1)) == 0xCC50:
			cc50_frame_writes.append(write)
		else:
			pre_call_stack_writes.append(write)
	if cc50_frame_writes != [
			{"pc": 0xCC50, "address": 0x01C3, "value": 0xCC, "kind": "JSR_high"},
			{"pc": 0xCC50, "address": 0x01C2, "value": 0x52, "kind": "JSR_low"}]:
		_fail("The source result does not contain exactly one `$CC50->$CB0F` pre-pushed return frame.")
		return {}
	var replay := _replay_actor_source_writes(writes, stack_writes, _ram, _stack_page)
	var pre_call_replay := _replay_actor_source_writes(writes, pre_call_stack_writes, _ram, _stack_page)
	if not bool(replay.get("ok", false)) or not bool(pre_call_replay.get("ok", false)) \
			or replay.get("ram_image", PackedByteArray()) != source_ram \
			or replay.get("stack_page", PackedByteArray()) != source_stack \
			or pre_call_replay.get("stack_page", PackedByteArray()) != callsite_stack:
		_fail("Slot-$11 resume output RAM/stack does not equal the replayed ROM writes and JSR frame.")
		return {}
	# Adopt only ordered writes from the ROM executor; do not replace scheduler
	# state with its whole returned RAM image.
	for write_variant in writes:
		var write: Dictionary = write_variant
		_ram[int(write["address"])] = int(write["value"])
	for write_variant in stack_writes:
		var write: Dictionary = write_variant
		_write_stack_byte(int(write["address"]) & 0xFF, int(write["value"]))
	context.accumulator = int(callsite_registers["a"])
	context.x_register = int(callsite_registers["x"])
	context.y_register = int(callsite_registers["y"])
	context.status_register = int(callsite_registers["p"])
	context.status_known_mask = int(callsite_registers["p_known_mask"])
	context.program_counter = 0xCC50
	context.stack_pointer = 0xC3
	context.source_label = "ROM-byte slot-$11 actor stream `$804A->$CC50->$CB0F`"
	_slot11_actor_resume_yield_in_progress = true
	var saved := yield_at_verified_callsite(0x11, 0xCC50,
		context.accumulator, context.stack_pointer, context.x_register, context.y_register,
		context.bank_low, context.bank_high, true)
	_slot11_actor_resume_yield_in_progress = false
	if not saved:
		return {}
	var boundary := get_task_boundary_snapshot(0x11)
	return {
		"ok": true,
		"status": "slot11_actor_resume_saved_at_cb0f",
		"rom_sha256": ROM_SHA256,
		"source_manifest": SLOT11_RESUME_MANIFEST,
		"callsite_pc": 0xCC50,
		"handler_entry_pc": 0xCB0F,
		"resume_pc": 0xCC53,
		"task_record": _record_bytes(0x11),
		"saved_boundary": boundary,
		"scheduler_scan_cursor": _scheduler_scan_cursor,
		"scheduler_y_register": _scheduler_y_register,
		"active_task_slot": _active_task_slot,
		"preexisting_jsr_frame_reused": true,
		"source_ram_image_copied": false,
		"source_ram_write_count": writes.size(),
		"source_stack_write_count": stack_writes.size(),
	}


## Adopts the ROM-derived `$CC53` waiter continuation after scheduler dispatch.
## This is separate from the first `$804A` actor-stream resume because the
## second boundary has a different saved SP and stack-resident packet counter.
func apply_slot11_actor_waiter_resume_result(worker_result: Dictionary) -> Dictionary:
	if not _require_initialized():
		return {}
	var proof := _validate_slot11_actor_waiter_resume_result(worker_result)
	if not bool(proof.get("ok", false)):
		_fail(String(proof.get("reason", "Invalid slot-$11 waiter result.")))
		return {}
	var entry_pc := int(worker_result.get("entry_pc", -1))
	var callsite_pc := int(worker_result.get("yield_callsite_pc", -1))
	var entry_sp := 0xC3 if entry_pc == 0xCC53 else 0xC4
	var entry_saved_sp := 0xBF if entry_pc == 0xCC53 else 0xC0
	var callsite_sp := 0xC3 if callsite_pc == 0xCC50 else 0xC4
	var resume_pc := int(worker_result.get("resume_pc_after_rts", -1))
	var context: TaskContext = _contexts.get(0x11)
	if context == null or _active_task_slot != 0x11 \
			or context.phase != ContextPhase.RUNNING \
			or context.program_counter != entry_pc or context.stack_pointer != entry_sp \
			or int(_ram[0x0000]) != 0x11 \
			or _record_bytes(0x11) != PackedByteArray([0x00, entry_saved_sp, 0x18, 0x19]) \
			or context.bank_low != 0x18 or context.bank_high != 0x19:
		_fail("Slot-$11 waiter adoption requires the matching live dispatched waiter/tail boundary.")
		return {}
	var entry_record: Variant = worker_result.get("entry_record", PackedByteArray())
	var entry_ram: Variant = worker_result.get("entry_ram_image", PackedByteArray())
	var entry_stack: Variant = worker_result.get("entry_stack_page", PackedByteArray())
	var entry_registers: Variant = worker_result.get("entry_registers", {})
	var source_ram: Variant = worker_result.get("ram_image", PackedByteArray())
	var source_stack: Variant = worker_result.get("stack_page", PackedByteArray())
	var writes: Variant = worker_result.get("ram_writes", [])
	var stack_writes: Variant = worker_result.get("stack_writes", [])
	var callsite_stack: Variant = worker_result.get("yield_callsite_stack_page", PackedByteArray())
	var callsite_registers: Dictionary = worker_result["yield_callsite_registers"]
	var cb0f_registers: Dictionary = worker_result["cb0f_entry_registers"]
	var mapper: Dictionary = worker_result["mapper"]
	if not entry_record is PackedByteArray or entry_record != _record_bytes(0x11) \
			or not entry_ram is PackedByteArray or entry_ram != _ram \
			or not entry_stack is PackedByteArray or entry_stack != _stack_page \
			or not entry_registers is Dictionary or entry_registers != _register_snapshot(context) \
			or not source_ram is PackedByteArray or source_ram.size() != RAM_SIZE \
			or not source_stack is PackedByteArray or source_stack.size() != STACK_PAGE_SIZE \
			or not writes is Array or not stack_writes is Array \
			or not callsite_stack is PackedByteArray or callsite_stack.size() != STACK_PAGE_SIZE \
			or mapper != context.mapper_state:
		_fail("Slot-$11 waiter result does not start from the current live task, RAM, stack, registers, and mapper.")
		return {}
	var replay := _replay_actor_source_writes(writes, stack_writes, _ram, _stack_page)
	var pre_call_writes: Array[Dictionary] = []
	var callsite_frame_writes: Array[Dictionary] = []
	for write_variant in stack_writes:
		if not write_variant is Dictionary:
			_fail("Slot-$11 waiter result contains a malformed stack write.")
			return {}
		var write: Dictionary = write_variant
		if int(write.get("pc", -1)) == callsite_pc:
			callsite_frame_writes.append(write)
		else:
			pre_call_writes.append(write)
	var pre_call_replay := _replay_actor_source_writes(writes, pre_call_writes, _ram, _stack_page)
	var return_minus_one := (callsite_pc + 2) & 0xFFFF
	var callsite_frame_sp := (callsite_sp - 2) & 0xFF
	var expected_callsite_frame := [
		{"pc": callsite_pc, "address": 0x0100 + callsite_sp,
			"value": (return_minus_one >> 8) & 0xFF, "kind": "JSR_high"},
		{"pc": callsite_pc, "address": 0x0100 + ((callsite_sp - 1) & 0xFF),
			"value": return_minus_one & 0xFF, "kind": "JSR_low"},
	]
	if not bool(replay.get("ok", false)) or not bool(pre_call_replay.get("ok", false)) \
			or replay.get("ram_image", PackedByteArray()) != source_ram \
			or replay.get("stack_page", PackedByteArray()) != source_stack \
			or pre_call_replay.get("stack_page", PackedByteArray()) != callsite_stack \
			or callsite_frame_writes != expected_callsite_frame:
		_fail("Slot-$11 waiter result does not equal its ordered ROM writes and pre-pushed JSR frame.")
		return {}
	for write_variant in writes:
		var write: Dictionary = write_variant
		_ram[int(write["address"])] = int(write["value"])
	for write_variant in stack_writes:
		var write: Dictionary = write_variant
		_write_stack_byte(int(write["address"]) & 0xFF, int(write["value"]))
	context.accumulator = int(callsite_registers["a"])
	context.x_register = int(callsite_registers["x"])
	context.y_register = int(callsite_registers["y"])
	context.status_register = int(callsite_registers["p"])
	context.status_known_mask = int(callsite_registers["p_known_mask"])
	context.program_counter = callsite_pc
	context.stack_pointer = callsite_sp
	context.source_label = "ROM-byte slot-$11 waiter/tail `$%04X->$CB0F`" % callsite_pc
	_slot11_actor_resume_yield_in_progress = true
	var saved := yield_at_verified_callsite(0x11, callsite_pc,
		context.accumulator, context.stack_pointer, context.x_register, context.y_register,
		context.bank_low, context.bank_high, true)
	_slot11_actor_resume_yield_in_progress = false
	if not saved:
		return {}
	return {
		"ok": true,
		"status": "slot11_actor_waiter_resume_saved_at_cb0f",
		"rom_sha256": ROM_SHA256,
		"source_manifest": SLOT11_RESUME_MANIFEST,
		"callsite_pc": callsite_pc,
		"handler_entry_pc": 0xCB0F,
		"resume_pc": resume_pc,
		"task_record": _record_bytes(0x11),
		"saved_boundary": get_task_boundary_snapshot(0x11),
		"source_ram_image_copied": false,
		"source_ram_write_count": writes.size(),
		"source_stack_write_count": stack_writes.size(),
	}


## Adopts the ROM's final F5 return at `$CCD1->$8200->$804D` into the live
## slot-$11 context. This is an in-task continuation; it does not save/yield.
func apply_slot11_actor_f5_tail_return_result(worker_result: Dictionary) -> Dictionary:
	if not _require_initialized():
		return {}
	var expected_hashes := {
		"fixed_wait_counter_tail_CC9E_CCD1.bin": "28ae864c35cf13601f8cb93f4bc13f0cadcd64b9d401fff6f0bef8e2b656bee0",
		"bank18_actor_stream_f5_tail_8200_8217.bin": "f99ead3dbc9481250bab0c306693651ab2ac705bd5feeb82ea3975167c3663a0",
		"bank18_actor_stream_f4_f5_9f42_9f53.bin": "907c3653f2e64fa9d27a0a14a7dd38e404f0f1c05a97c0367be24e587f5ebadf",
	}
	if String(worker_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(worker_result.get("source_manifest", "")) != SLOT11_RESUME_MANIFEST \
			or String(worker_result.get("status", "")) != "slot11_actor_f5_tail_returned_to_804d" \
			or int(worker_result.get("slot_base", -1)) != 0x11 \
			or int(worker_result.get("entry_pc", -1)) != 0xCCD1 \
			or int(worker_result.get("exit_pc", -1)) != 0x804D \
			or worker_result.get("source_span_hashes", {}) != expected_hashes \
			or bool(worker_result.get("trace_state_used", true)) \
			or bool(worker_result.get("ppu_apu_effects_applied", true)) \
			or bool(worker_result.get("source_timing_modeled", true)):
		_fail("Input is not the hash-checked ROM-byte slot-$11 final F5-tail return.")
		return {}
	var context: TaskContext = _contexts.get(0x11)
	if context == null or _active_task_slot != 0x11 \
			or context.phase != ContextPhase.RUNNING \
			or context.program_counter != 0xCCD1 or context.stack_pointer != 0xC4 \
			or _record_bytes(0x11) != PackedByteArray([0x00, 0xC0, 0x18, 0x19]) \
			or context.bank_low != 0x18 or context.bank_high != 0x19:
		_fail("F5-tail adoption requires the live dispatched `$CCD1` slot-$11 boundary.")
		return {}
	var entry_record: Variant = worker_result.get("entry_record", PackedByteArray())
	var entry_ram: Variant = worker_result.get("entry_ram_image", PackedByteArray())
	var entry_stack: Variant = worker_result.get("entry_stack_page", PackedByteArray())
	var entry_registers: Variant = worker_result.get("entry_registers", {})
	var output_ram: Variant = worker_result.get("ram_image", PackedByteArray())
	var output_stack: Variant = worker_result.get("stack_page", PackedByteArray())
	var writes: Variant = worker_result.get("ram_writes", [])
	var stack_writes: Variant = worker_result.get("stack_writes", [])
	var stack_reads: Variant = worker_result.get("stack_reads", [])
	var reads: Variant = worker_result.get("source_reads", [])
	var exit_registers: Variant = worker_result.get("exit_registers", {})
	var mapper: Variant = worker_result.get("mapper", {})
	if not entry_record is PackedByteArray or entry_record != _record_bytes(0x11) \
			or not entry_ram is PackedByteArray or entry_ram != _ram \
			or not entry_stack is PackedByteArray or entry_stack != _stack_page \
			or not entry_registers is Dictionary or entry_registers != _register_snapshot(context) \
			or not output_ram is PackedByteArray or output_ram.size() != RAM_SIZE \
			or not output_stack is PackedByteArray or output_stack.size() != STACK_PAGE_SIZE \
			or not writes is Array or not stack_writes is Array or not stack_writes.is_empty() \
			or not stack_reads is Array or stack_reads.size() != 6 \
			or not reads is Array or not exit_registers is Dictionary \
			or not mapper is Dictionary or mapper != context.mapper_state \
			or not (worker_result.get("ppu_bus_events", []) is Array) \
			or not (worker_result.get("ppu_bus_events", []) as Array).is_empty() \
			or not (worker_result.get("apu_register_writes", []) is Array) \
			or not (worker_result.get("apu_register_writes", []) as Array).is_empty():
		_fail("F5-tail result does not start from the live RAM/stack/register/mapper state or has unexpected side effects.")
		return {}
	var replay := _replay_actor_source_writes(writes, stack_writes, _ram, _stack_page)
	if not bool(replay.get("ok", false)) \
			or replay.get("ram_image", PackedByteArray()) != output_ram.slice(0, RAM_SIZE) \
			or replay.get("stack_page", PackedByteArray()) != output_stack \
			or int(exit_registers.get("pc", -1)) != 0x804D \
			or int(exit_registers.get("sp", -1)) != 0xCA \
			or int(exit_registers.get("a", -1)) != 0x80 \
			or int(exit_registers.get("y", -1)) != 0x01 \
			or int(output_ram[0x05F3]) != 0x0D or int(output_ram[0x05F4]) != 0x80 \
			or int(output_ram[0x05E5]) != 0x02 or int(output_ram[0x05E9]) != 0x02:
		_fail("F5-tail result does not replay the source return and stream-parameter writes.")
		return {}
	for write_variant in writes:
		var write: Dictionary = write_variant
		_ram[int(write["address"])] = int(write["value"])
	context.accumulator = int(exit_registers["a"])
	context.x_register = int(exit_registers["x"])
	context.y_register = int(exit_registers["y"])
	context.status_register = int(exit_registers["p"])
	context.status_known_mask = int(exit_registers["p_known_mask"])
	context.program_counter = int(exit_registers["pc"])
	context.stack_pointer = int(exit_registers["sp"])
	context.source_label = "ROM-byte slot-$11 F5 tail `$CCD1->$8200->$804D`"
	return {
		"ok": true,
		"status": "slot11_actor_f5_tail_return_adopted_at_804d",
		"source_boundary_pc": context.program_counter,
		"source_reads": reads.duplicate(true),
		"source_ram_write_count": writes.size(),
		"task_boundary": get_task_boundary_snapshot(0x11),
		"source_ram_image_copied": false,
		"trace_state_used": false,
	}


## Adopts the ROM-byte actor-animation gate at `$A217->$C515->$CB0F`.
## The F5 handler's wait loop can continue after this task yield; this package
## only records the first verified gate and does not synthesize frame timing.
func apply_slot11_f5_animation_gate_result(worker_result: Dictionary) -> Dictionary:
	if not _require_initialized():
		return {}
	var expected_hashes := {
		"fixed_c560_bank1a_call_stub.bin": "170b3801f4df2a5789a9ef9fbdc6c389c58afdad9c58a94d3c7fad8e6563ccbc",
		"fixed_cf72_bank1a_call_and_restore.bin": "8ef4c31ce9f19ea12db252480ab5342a4429e37c3f81148bdde0286ad03b3c13",
		"bank1a_worker_entry_802a_802d.bin": "d8ec35aefd2671a7a810a2fa342db297bfb35011862ec3b907aa09fced64da90",
		"bank1b_actor_animation_gate_A1EB_A219.bin": "7cf2b10130708c5b0a722741eb60d27e732672730c7bbfb515dd1f9a17122618",
		"bank1b_actor_animation_index_0D_A2AC_A2AD.bin": "588eba1d324cbcd9381797960eb1a81d099ef8277be6a1f92b935389647e1ae2",
	}
	if String(worker_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(worker_result.get("source_manifest", "")) != SLOT11_RESUME_MANIFEST \
			or String(worker_result.get("status", "")) != "slot11_f5_animation_gate_at_cb0f_from_a217" \
			or int(worker_result.get("slot_base", -1)) != 0x11 \
			or int(worker_result.get("entry_pc", -1)) != 0x804D \
			or int(worker_result.get("exit_pc", -1)) != 0xCB0F \
			or int(worker_result.get("yield_callsite_pc", -1)) != 0xA217 \
			or int(worker_result.get("yield_target_pc", -1)) != 0xCB0F \
			or int(worker_result.get("resume_pc_after_rts", -1)) != 0xA21A \
			or not bool(worker_result.get("call_frame_already_pushed", false)) \
			or bool(worker_result.get("trace_state_used", true)) \
			or bool(worker_result.get("ppu_apu_effects_applied", true)) \
			or bool(worker_result.get("source_timing_modeled", true)):
		_fail("Input is not the bounded ROM-byte `$804D->$A217->$CB0F` actor-animation gate.")
		return {}
	var mapper_helper := FileAccess.get_file_as_bytes(
			"res://reference/rom_extract/gameplay/ee9f_empty_actor_call/fixed_mapper_helper_CE2D_CE49.bin")
	var reported_hashes: Dictionary = worker_result.get("source_span_hashes", {}).duplicate(true)
	var reported_helper_hash := String(reported_hashes.get("fixed_mapper_helper_CE2D_CE49.bin", ""))
	reported_hashes.erase("fixed_mapper_helper_CE2D_CE49.bin")
	if reported_hashes != expected_hashes \
			or reported_helper_hash \
			!= "6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c" \
			or mapper_helper.size() != 29 \
			or _sha256(mapper_helper) != "6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c" \
			or not _validate_slot09_source_manifest_hashes(SLOT11_RESUME_MANIFEST, expected_hashes):
		if error_message.is_empty():
			_fail("The F5 animation-gate source spans do not match their manifest hashes.")
		return {}
	var context: TaskContext = _contexts.get(0x11)
	if _active_task_slot != 0x11 or context == null \
			or context.phase != ContextPhase.RUNNING \
			or context.program_counter != 0x804D or context.stack_pointer != 0xCA \
			or _record_bytes(0x11) != PackedByteArray([0x00, 0xC0, 0x18, 0x19]) \
			or context.bank_low != 0x18 or context.bank_high != 0x19:
		_fail("The F5 animation gate requires the live `$804D` slot-$11 continuation.")
		return {}
	var entry_record: Variant = worker_result.get("entry_record", PackedByteArray())
	var entry_ram: Variant = worker_result.get("entry_ram_image", PackedByteArray())
	var entry_stack: Variant = worker_result.get("entry_stack_page", PackedByteArray())
	var entry_registers: Variant = worker_result.get("entry_registers", {})
	var callsite_registers: Variant = worker_result.get("yield_callsite_registers", {})
	var callsite_stack: Variant = worker_result.get("yield_callsite_stack_page", PackedByteArray())
	var cb0f_registers: Variant = worker_result.get("cb0f_entry_registers", {})
	var initial_mapper: Variant = worker_result.get("initial_mapper", {})
	var output_mapper: Variant = worker_result.get("mapper", {})
	var writes: Variant = worker_result.get("ram_writes", [])
	var stack_writes: Variant = worker_result.get("stack_writes", [])
	var mapper_writes: Variant = worker_result.get("mapper_writes", [])
	var source_reads: Variant = worker_result.get("source_reads", [])
	var output_ram: Variant = worker_result.get("ram_image", PackedByteArray())
	var output_stack: Variant = worker_result.get("stack_page", PackedByteArray())
	var ppu_events: Variant = worker_result.get("ppu_bus_events", [])
	var apu_writes: Variant = worker_result.get("apu_register_writes", [])
	if not entry_record is PackedByteArray or entry_record != _record_bytes(0x11) \
			or not entry_ram is PackedByteArray or entry_ram != _ram \
			or not entry_stack is PackedByteArray or entry_stack != _stack_page \
			or not entry_registers is Dictionary or entry_registers != _register_snapshot(context) \
			or not callsite_registers is Dictionary or not callsite_stack is PackedByteArray \
			or not cb0f_registers is Dictionary or not initial_mapper is Dictionary \
			or initial_mapper != context.mapper_state or not output_mapper is Dictionary \
			or not writes is Array or not stack_writes is Array or not mapper_writes is Array \
			or not source_reads is Array or not output_ram is PackedByteArray \
			or output_ram.size() != RAM_SIZE or not output_stack is PackedByteArray \
			or output_stack.size() != STACK_PAGE_SIZE \
			or not ppu_events is Array or not ppu_events.is_empty() \
			or not apu_writes is Array or not apu_writes.is_empty():
		_fail("The F5 animation-gate result omits its exact live entry, writes, mapper, or side-effect evidence.")
		return {}
	var callsite: Dictionary = callsite_registers
	var cb0f: Dictionary = cb0f_registers
	if int(callsite.get("pc", -1)) != 0xA217 or int(callsite.get("sp", -1)) != 0xC6 \
			or int(callsite.get("a", -1)) != 0x01 or int(callsite.get("x", -1)) != 0x1A \
			or int(callsite.get("y", -1)) != 0x01 \
			or int(cb0f.get("pc", -1)) != 0xCB0F or int(cb0f.get("sp", -1)) != 0xC4 \
			or int(cb0f.get("x", -1)) != 0x1A or int(cb0f.get("y", -1)) != 0x01 \
			or int(callsite.get("p", -1)) != int(cb0f.get("p", -2)) \
			or int(callsite.get("p_known_mask", -1)) != int(cb0f.get("p_known_mask", -2)) \
			or int(output_mapper.get("bank_low", -1)) != 0x1A \
			or int(output_mapper.get("bank_high", -1)) != 0x1B:
		_fail("F5 animation gate CPU state or MMC3 bank pair differs from the ROM callsite contract: callsite=%s cb0f=%s mapper=%s." % [str(callsite), str(cb0f), str(output_mapper)])
		return {}
	var replay := _replay_actor_source_writes(writes, stack_writes, _ram, _stack_page)
	var mapper_replay := _replay_actor_source_mapper_writes(mapper_writes,
		context.bank_low, context.bank_high, output_mapper,
		int(context.mapper_state.get("select", -1)))
	if not bool(replay.get("ok", false)) \
			or replay.get("ram_image", PackedByteArray()) != output_ram \
			or replay.get("stack_page", PackedByteArray()) != output_stack \
			or not bool(mapper_replay.get("ok", false)) \
			or not _slot11_source_read_present(source_reads, 0xC515, 0x4C, "task_yield_dispatch_opcode") \
			or int(output_stack[0xC5]) != 0x19 or int(output_stack[0xC6]) != 0xA2 \
			or int(output_ram[0x0024]) != 0x1A or int(output_ram[0x0025]) != 0x1B \
			or int(output_ram[0x0063]) != 0x25 or int(output_ram[0x0064]) != 0xA4 \
			or int(output_ram[0x05F4]) != 0x01 or int(output_ram[0x05F5]) != 0x00:
		_fail("F5 animation-gate writes do not replay to the checked actor pointer and yield call frame.")
		return {}
	for write_variant in writes:
		var write: Dictionary = write_variant
		_ram[int(write["address"])] = int(write["value"])
	for write_variant in stack_writes:
		var write: Dictionary = write_variant
		_write_stack_byte(int(write["address"]) & 0xFF, int(write["value"]))
	context.accumulator = int(callsite["a"])
	context.x_register = int(callsite["x"])
	context.y_register = int(callsite["y"])
	context.status_register = int(callsite["p"])
	context.status_known_mask = int(callsite["p_known_mask"])
	context.program_counter = 0xA217
	context.stack_pointer = 0xC6
	context.bank_low = 0x1A
	context.bank_high = 0x1B
	context.mapper_state = output_mapper.duplicate(true)
	context.source_label = "ROM-byte slot-$11 animation gate `$804D->$A217->$CB0F`"
	_slot11_f5_animation_yield_in_progress = true
	var saved := yield_at_verified_callsite(0x11, 0xA217,
		context.accumulator, context.stack_pointer, context.x_register, context.y_register,
		context.bank_low, context.bank_high, true)
	_slot11_f5_animation_yield_in_progress = false
	if not saved:
		return {}
	return {
		"ok": true,
		"status": "slot11_f5_animation_gate_saved_at_cb0f",
		"callsite_pc": 0xA217,
		"resume_pc": 0xA21A,
		"task_record": _record_bytes(0x11),
		"saved_boundary": get_task_boundary_snapshot(0x11),
		"source_ram_image_copied": false,
		"trace_state_used": false,
		"source_timing_modeled": false,
	}


## Applies the first ROM-built `$A21A` secondary PPU packet queue, then records
## the worker's next `$8047->$CB0F` yield. The packet queue is still consumed by
## the separate normal-NMI path; this does not render pixels or infer cadence.
func apply_slot11_f5_animation_queue_result(worker_result: Dictionary) -> Dictionary:
	if not _require_initialized():
		return {}
	var expected_hashes := {
		"bank1b_actor_animation_command_loop_A21A_A291.bin": "c315087f3f361a05abbbc63748d1c890aea1a2be7f40fb325150cb71688f1cfd",
		"bank1b_actor_animation_stream_0D_A425_A426.bin": "c80e57d27a62d8f8ae98f6976e64d0a1e4f9cebe78cf5b16e79ecd927b985da6",
		"bank1b_actor_animation_pointer_00_A42A_A42B.bin": "48dceebd8704067b3697888d1f847f69d77a5fbbcb8e57ac3a9a0b41205e47cf",
		"bank1b_actor_animation_ef_00_ppu_packets_A46A_A48E.bin": "4fd878c7cc59ffec84362bfc6f973474f72c83087d302687958b844682b2d678",
	}
	if String(worker_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(worker_result.get("source_manifest", "")) != SLOT11_RESUME_MANIFEST \
			or String(worker_result.get("status", "")) != "slot11_f5_animation_queue_at_8047" \
			or int(worker_result.get("slot_base", -1)) != 0x11 \
			or int(worker_result.get("entry_pc", -1)) != 0xA21A \
			or int(worker_result.get("exit_pc", -1)) != 0x8047 \
			or int(worker_result.get("yield_callsite_pc", -1)) != 0x8047 \
			or int(worker_result.get("yield_target_pc", -1)) != 0xCB0F \
			or int(worker_result.get("resume_pc_after_rts", -1)) != 0x804A \
			or bool(worker_result.get("call_frame_already_pushed", true)) \
			or bool(worker_result.get("trace_state_used", true)) \
			or bool(worker_result.get("ppu_apu_effects_applied", true)) \
			or bool(worker_result.get("source_timing_modeled", true)):
		_fail("Input is not the bounded ROM-byte `$A21A` packet builder through `$8047`.")
		return {}
	var reported_hashes: Dictionary = worker_result.get("source_span_hashes", {}).duplicate(true)
	var helper_hash := String(reported_hashes.get("fixed_mapper_helper_CE2D_CE49.bin", ""))
	var prefix_hash := String(reported_hashes.get("bank18_actor_worker_entry_8000_804A.bin", ""))
	reported_hashes.erase("fixed_mapper_helper_CE2D_CE49.bin")
	reported_hashes.erase("bank18_actor_worker_entry_8000_804A.bin")
	var helper := FileAccess.get_file_as_bytes(
			"res://reference/rom_extract/gameplay/ee9f_empty_actor_call/fixed_mapper_helper_CE2D_CE49.bin")
	var prefix := FileAccess.get_file_as_bytes(
			"res://reference/rom_extract/gameplay/task_context/bank18_actor_worker_entry_8000_804A.bin")
	if reported_hashes != expected_hashes \
			or helper_hash != "6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c" \
			or prefix_hash != "2187af6881ea2f4e7eb16c0c5550bb24ead076be918d429d8ab63564ed8fd46c" \
			or helper.size() != 29 or _sha256(helper) != helper_hash \
			or prefix.size() != 74 or _sha256(prefix) != prefix_hash \
			or not _validate_slot09_source_manifest_hashes(SLOT11_RESUME_MANIFEST, expected_hashes):
		if error_message.is_empty():
			_fail("The A21A source packet/code spans do not match their manifest hashes.")
		return {}
	var context: TaskContext = _contexts.get(0x11)
	if _active_task_slot != 0x11 or context == null \
			or context.phase != ContextPhase.RUNNING \
			or context.program_counter != 0xA21A or context.stack_pointer != 0xC6 \
			or _record_bytes(0x11) != PackedByteArray([0x00, 0xC2, 0x1A, 0x1B]) \
			or context.bank_low != 0x1A or context.bank_high != 0x1B:
		_fail("The animation packet builder requires the dispatched slot-$11 `$A21A` boundary.")
		return {}
	var entry_record: Variant = worker_result.get("entry_record", PackedByteArray())
	var entry_ram: Variant = worker_result.get("entry_ram_image", PackedByteArray())
	var entry_stack: Variant = worker_result.get("entry_stack_page", PackedByteArray())
	var entry_registers: Variant = worker_result.get("entry_registers", {})
	var callsite_registers: Variant = worker_result.get("yield_callsite_registers", {})
	var callsite_stack: Variant = worker_result.get("yield_callsite_stack_page", PackedByteArray())
	var initial_mapper: Variant = worker_result.get("initial_mapper", {})
	var output_mapper: Variant = worker_result.get("mapper", {})
	var writes: Variant = worker_result.get("ram_writes", [])
	var stack_writes: Variant = worker_result.get("stack_writes", [])
	var mapper_writes: Variant = worker_result.get("mapper_writes", [])
	var source_reads: Variant = worker_result.get("source_reads", [])
	var packets: Variant = worker_result.get("secondary_ppu_packets", [])
	var output_ram: Variant = worker_result.get("ram_image", PackedByteArray())
	var output_stack: Variant = worker_result.get("stack_page", PackedByteArray())
	if not entry_record is PackedByteArray or entry_record != _record_bytes(0x11) \
			or not entry_ram is PackedByteArray or entry_ram != _ram \
			or not entry_stack is PackedByteArray or entry_stack != _stack_page \
			or not entry_registers is Dictionary or entry_registers != _register_snapshot(context) \
			or not callsite_registers is Dictionary or not callsite_stack is PackedByteArray \
			or not initial_mapper is Dictionary or initial_mapper != context.mapper_state \
			or not output_mapper is Dictionary or not writes is Array \
			or not stack_writes is Array or not stack_writes.is_empty() \
			or not mapper_writes is Array or not source_reads is Array or not packets is Array \
			or not output_ram is PackedByteArray or output_ram.size() != RAM_SIZE \
			or not output_stack is PackedByteArray or output_stack.size() != STACK_PAGE_SIZE \
			or not (worker_result.get("ppu_bus_events", []) is Array) \
			or not (worker_result.get("ppu_bus_events", []) as Array).is_empty() \
			or not (worker_result.get("apu_register_writes", []) is Array) \
			or not (worker_result.get("apu_register_writes", []) as Array).is_empty():
		_fail("The A21A packet result omits its exact live entry, queue writes, or side-effect evidence.")
		return {}
	var callsite: Dictionary = callsite_registers
	if int(callsite.get("pc", -1)) != 0x8047 or int(callsite.get("sp", -1)) != 0xCA \
			or int(callsite.get("a", -1)) != 0x01 or int(callsite.get("x", -1)) != 0x24 \
			or int(callsite.get("y", -1)) != 0x24 \
			or int(output_ram[0x0515]) != 0x80 \
			or int(output_ram[0x05F5]) != 0xEF \
			or int(output_ram[0x003A]) != 0x6A or int(output_ram[0x003B]) != 0xA4 \
			or int(output_ram[0x003C]) != 0x00 \
			or int(output_ram[0x0063]) != 0x27 or int(output_ram[0x0064]) != 0xA4 \
			or output_ram.slice(0x04A5, 0x04CA) != PackedByteArray([
				0x04, 0xC8, 0x22, 0x00, 0xB4, 0xB5, 0xE0,
				0x04, 0xE8, 0x22, 0x00, 0xB6, 0xB7, 0xE2,
				0x04, 0x08, 0x23, 0x00, 0xBC, 0xBD, 0xE8,
				0x04, 0x28, 0x23, 0x00, 0xBE, 0xBF, 0xEA,
				0x01, 0xEA, 0x23, 0x50, 0x01, 0xF2, 0x23, 0x05, 0x00,
			]) \
			or int(output_mapper.get("bank_low", -1)) != 0x18 \
			or int(output_mapper.get("bank_high", -1)) != 0x19:
		_fail("The A21A output differs from the six ROM PPU packets, animation pointer, or bank restore.")
	var replay := _replay_actor_source_writes(writes, stack_writes, _ram, _stack_page)
	var mapper_replay := _replay_actor_source_mapper_writes(mapper_writes,
		context.bank_low, context.bank_high, output_mapper,
		int(context.mapper_state.get("select", -1)))
	if not bool(replay.get("ok", false)) \
			or replay.get("ram_image", PackedByteArray()) != output_ram \
			or replay.get("stack_page", PackedByteArray()) != output_stack \
			or not bool(mapper_replay.get("ok", false)) \
			or not _slot11_source_read_present(source_reads, 0xA425, 0xEF, "animation_command") \
			or not _slot11_source_read_present(source_reads, 0xA426, 0x00, "animation_event_index"):
		_fail("A21A packet writes do not replay to the checked PPU queue or ROM event bytes: ram=%s stack=%s mapper=%s cmd=%s index=%s." % [
			str(bool(replay.get("ok", false)) and replay.get("ram_image", PackedByteArray()) == output_ram),
			str(bool(replay.get("ok", false)) and replay.get("stack_page", PackedByteArray()) == output_stack),
			str(bool(mapper_replay.get("ok", false))),
			str(_slot11_source_read_present(source_reads, 0xA425, 0xEF, "animation_command")),
			str(_slot11_source_read_present(source_reads, 0xA426, 0x00, "animation_event_index")),
		])
		return {}
	for write_variant in writes:
		var write: Dictionary = write_variant
		_ram[int(write["address"])] = int(write["value"])
	for write_variant in stack_writes:
		var write: Dictionary = write_variant
		_write_stack_byte(int(write["address"]) & 0xFF, int(write["value"]))
	context.accumulator = int(callsite["a"])
	context.x_register = int(callsite["x"])
	context.y_register = int(callsite["y"])
	context.status_register = int(callsite["p"])
	context.status_known_mask = int(callsite["p_known_mask"])
	context.program_counter = 0x8047
	context.stack_pointer = 0xCA
	context.bank_low = 0x18
	context.bank_high = 0x19
	context.mapper_state = output_mapper.duplicate(true)
	context.source_label = "ROM-byte slot-$11 F5 queue `$A21A->$8047`"
	_slot11_actor_worker_yield_in_progress = true
	var saved := yield_at_verified_callsite(0x11, 0x8047,
		context.accumulator, context.stack_pointer, context.x_register, context.y_register,
		context.bank_low, context.bank_high)
	_slot11_actor_worker_yield_in_progress = false
	if not saved:
		return {}
	return {
		"ok": true,
		"status": "slot11_f5_animation_queue_saved_and_scanned",
		"callsite_pc": 0x8047,
		"resume_pc": 0x804A,
		"secondary_ppu_packet_count": packets.size(),
		"task_record": _record_bytes(0x11),
		"saved_boundary": get_task_boundary_snapshot(0x11),
		"source_ram_image_copied": false,
		"trace_state_used": false,
		"source_timing_modeled": false,
	}


## Adopts one source-driven `$05E9/$05F5` animation wait tick through the
## worker's next `$8047->$CB0F` yield.
func apply_slot11_f5_animation_countdown_result(worker_result: Dictionary) -> Dictionary:
	if not _require_initialized():
		return {}
	var expected_hashes := {
		"bank18_actor_worker_resume_804a_80fd.bin": "9c07722c85a0670f8986a7e7a680bc205a587881383fd84276e520806f465c6e",
		"bank18_actor_stream_dispatch_8218_822e.bin": "a46488bd47acb67282e03aa63e4111b7efc1677dc8f10dc52e90a2d80ae7aa5c",
		"bank18_actor_stream_short_event_decoder_81d1_81e4.bin": "7e59d0713a7eb14d55dcca569ff75b2e6fea37d394fa72531eabcfabe4c106be",
		"bank18_actor_stream_followup_9f54_9f7f.bin": "79be558cb1fe9bfbf950a23486ed0da89c1dc37e20daa52feed8f6a124225fe4",
		"bank19_actor_event_stream_a3c9_a43b.bin": "98eb047a4e32fafe77d2285722a236b891fb01441b845e2d1c1fc94dfeaae314",
		"fixed_c560_bank1a_call_stub.bin": "170b3801f4df2a5789a9ef9fbdc6c389c58afdad9c58a94d3c7fad8e6563ccbc",
		"fixed_cf72_bank1a_call_and_restore.bin": "8ef4c31ce9f19ea12db252480ab5342a4429e37c3f81148bdde0286ad03b3c13",
		"bank1a_worker_entry_802a_802d.bin": "d8ec35aefd2671a7a810a2fa342db297bfb35011862ec3b907aa09fced64da90",
		"bank1b_actor_animation_gate_A1EB_A219.bin": "7cf2b10130708c5b0a722741eb60d27e732672730c7bbfb515dd1f9a17122618",
	}
	if String(worker_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(worker_result.get("source_manifest", "")) != SLOT11_RESUME_MANIFEST \
			or String(worker_result.get("status", "")) != "slot11_f5_animation_countdown_at_8047" \
			or int(worker_result.get("slot_base", -1)) != 0x11 \
			or int(worker_result.get("entry_pc", -1)) != 0x804A \
			or int(worker_result.get("exit_pc", -1)) != 0x8047 \
			or int(worker_result.get("yield_callsite_pc", -1)) != 0x8047 \
			or int(worker_result.get("yield_target_pc", -1)) != 0xCB0F \
			or int(worker_result.get("resume_pc_after_rts", -1)) != 0x804A \
			or bool(worker_result.get("call_frame_already_pushed", true)) \
			or bool(worker_result.get("trace_state_used", true)) \
			or bool(worker_result.get("ppu_apu_effects_applied", true)) \
			or bool(worker_result.get("source_timing_modeled", true)):
		_fail("Input is not the bounded ROM-byte animation countdown through `$8047`.")
		return {}
	var reported_hashes: Dictionary = worker_result.get("source_span_hashes", {}).duplicate(true)
	var helper_hash := String(reported_hashes.get("fixed_mapper_helper_CE2D_CE49.bin", ""))
	reported_hashes.erase("fixed_mapper_helper_CE2D_CE49.bin")
	var helper := FileAccess.get_file_as_bytes(
			"res://reference/rom_extract/gameplay/ee9f_empty_actor_call/fixed_mapper_helper_CE2D_CE49.bin")
	if reported_hashes != expected_hashes \
			or helper_hash != "6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c" \
			or helper.size() != 29 or _sha256(helper) != helper_hash \
			or not _validate_slot09_source_manifest_hashes(SLOT11_RESUME_MANIFEST, expected_hashes):
		if error_message.is_empty():
			_fail("The animation-countdown source spans do not match their manifest hashes.")
		return {}
	var context: TaskContext = _contexts.get(0x11)
	if _active_task_slot != 0x11 or context == null \
			or context.phase != ContextPhase.RUNNING \
			or context.program_counter != 0x804A or context.stack_pointer != 0xCA \
			or _record_bytes(0x11) != PackedByteArray([0x00, 0xC6, 0x18, 0x19]) \
			or context.bank_low != 0x18 or context.bank_high != 0x19:
		_fail("The animation countdown requires the dispatched slot-$11 `$804A` continuation.")
		return {}
	var entry_ram: Variant = worker_result.get("entry_ram_image", PackedByteArray())
	var entry_stack: Variant = worker_result.get("entry_stack_page", PackedByteArray())
	var entry_registers: Variant = worker_result.get("entry_registers", {})
	var callsite: Variant = worker_result.get("yield_callsite_registers", {})
	var callsite_stack: Variant = worker_result.get("yield_callsite_stack_page", PackedByteArray())
	var initial_mapper: Variant = worker_result.get("initial_mapper", {})
	var output_mapper: Variant = worker_result.get("mapper", {})
	var writes: Variant = worker_result.get("ram_writes", [])
	var stack_writes: Variant = worker_result.get("stack_writes", [])
	var mapper_writes: Variant = worker_result.get("mapper_writes", [])
	var source_reads: Variant = worker_result.get("source_reads", [])
	var output_ram: Variant = worker_result.get("ram_image", PackedByteArray())
	var output_stack: Variant = worker_result.get("stack_page", PackedByteArray())
	if not entry_ram is PackedByteArray or entry_ram != _ram \
			or not entry_stack is PackedByteArray or entry_stack != _stack_page \
			or not entry_registers is Dictionary or entry_registers != _register_snapshot(context) \
			or not callsite is Dictionary or not callsite_stack is PackedByteArray \
			or not initial_mapper is Dictionary or initial_mapper != context.mapper_state \
			or not output_mapper is Dictionary or not writes is Array \
			or not stack_writes is Array or not mapper_writes is Array or not source_reads is Array \
			or not output_ram is PackedByteArray or output_ram.size() != RAM_SIZE \
			or not output_stack is PackedByteArray or output_stack.size() != STACK_PAGE_SIZE \
			or not (worker_result.get("ppu_bus_events", []) is Array) \
			or not (worker_result.get("ppu_bus_events", []) as Array).is_empty() \
			or not (worker_result.get("apu_register_writes", []) is Array) \
			or not (worker_result.get("apu_register_writes", []) as Array).is_empty():
		_fail("The animation-countdown result omitted its exact live entry, writes, or side-effect boundary.")
		return {}
	if int(callsite.get("pc", -1)) != 0x8047 or int(callsite.get("sp", -1)) != 0xCA \
			or int(callsite.get("a", -1)) != 0x01 or int(callsite.get("x", -1)) != 0x24 \
			or int(callsite.get("y", -1)) != (int(entry_ram[0x05E5]) if int(entry_ram[0x05E9]) == 0 else int(entry_registers["y"])) \
			or int(output_ram[0x05E9]) != (0xE8 if int(entry_ram[0x05E9]) == 0 else int(entry_ram[0x05E9]) - 1) \
			or int(output_ram[0x05F5]) != int(entry_ram[0x05F5]) - 1 \
			or int(output_ram[0x05E4]) != (int(entry_ram[0x05E4]) + (1 if int(entry_ram[0x05E9]) == 0 else 0)) \
			or int(output_ram[0x05E5]) != (int(entry_ram[0x05E5]) + (1 if int(entry_ram[0x05E9]) == 0 else 0)) \
			or int(output_ram[0x0515]) != 0 \
			or int(output_mapper.get("bank_low", -1)) != 0x18 \
			or int(output_mapper.get("bank_high", -1)) != 0x19:
		_fail("The animation countdown output differs from the source decrement or restored yield state: callsite=%s e9=%02X->%02X f5=%02X->%02X e4=%02X->%02X e5=%02X->%02X queue=%02X mapper=%s." % [
			str(callsite), int(entry_ram[0x05E9]), int(output_ram[0x05E9]),
			int(entry_ram[0x05F5]), int(output_ram[0x05F5]),
			int(entry_ram[0x05E4]), int(output_ram[0x05E4]),
			int(entry_ram[0x05E5]), int(output_ram[0x05E5]),
			int(output_ram[0x0515]), str(output_mapper),
		])
		return {}
	var replay := _replay_actor_source_writes(writes, stack_writes, _ram, _stack_page)
	var mapper_replay := _replay_actor_source_mapper_writes(mapper_writes,
		context.bank_low, context.bank_high, output_mapper,
		int(context.mapper_state.get("select", -1)))
	if not bool(replay.get("ok", false)) \
			or replay.get("ram_image", PackedByteArray()) != output_ram \
			or replay.get("stack_page", PackedByteArray()) != output_stack \
			or not bool(mapper_replay.get("ok", false)) \
			or (int(entry_ram[0x05E9]) > 0 \
				and not _slot11_source_read_present(source_reads, 0x05E9, int(entry_ram[0x05E9]), "actor_animation_delay")) \
			or (int(entry_ram[0x05E9]) == 0 \
				and not _slot11_source_read_present(source_reads, 0x9F54, 0xE8, "actor_stream_followup_delay")) \
			or not _slot11_source_read_present(source_reads, 0x05F5, int(entry_ram[0x05F5]), "animation_wait_counter"):
		_fail("The animation countdown writes do not replay to the live RAM/stack and mapper state.")
		return {}
	for write_variant: Variant in writes:
		var write: Dictionary = write_variant
		_ram[int(write["address"])] = int(write["value"])
	for write_variant: Variant in stack_writes:
		var write: Dictionary = write_variant
		_write_stack_byte(int(write["address"]) & 0xFF, int(write["value"]))
	context.accumulator = int(callsite["a"])
	context.x_register = int(callsite["x"])
	context.y_register = int(callsite["y"])
	context.status_register = int(callsite["p"])
	context.status_known_mask = int(callsite["p_known_mask"])
	context.program_counter = 0x8047
	context.stack_pointer = 0xCA
	context.bank_low = 0x18
	context.bank_high = 0x19
	context.mapper_state = output_mapper.duplicate(true)
	context.source_label = "ROM-byte slot-$11 animation countdown `$804A->$8047`"
	_slot11_actor_worker_yield_in_progress = true
	var saved := yield_at_verified_callsite(0x11, 0x8047,
		context.accumulator, context.stack_pointer, context.x_register, context.y_register,
		context.bank_low, context.bank_high)
	_slot11_actor_worker_yield_in_progress = false
	if not saved:
		return {}
	return {
		"ok": true,
		"status": "slot11_f5_animation_countdown_saved_at_cb0f",
		"callsite_pc": 0x8047,
		"resume_pc": 0x804A,
		"task_record": _record_bytes(0x11),
		"saved_boundary": get_task_boundary_snapshot(0x11),
		"source_ram_image_copied": false,
		"trace_state_used": false,
		"source_timing_modeled": false,
	}


func yield_at_verified_callsite(slot_base: int, source_pc: int, delay_in_a: int,
		caller_stack_pointer: int, saved_x: int, saved_y: int,
		current_bank_low: int, current_bank_high: int,
		call_frame_already_pushed: bool = false) -> bool:
	if not _require_initialized():
		return false
	var context: TaskContext = _contexts.get(slot_base)
	if _active_task_slot != slot_base or context == null or context.phase != ContextPhase.RUNNING:
		return _fail("Yield requires the currently running source task context.")
	if source_pc == 0x8047 and (not _slot11_actor_worker_yield_in_progress \
			or slot_base != 0x11 or context.program_counter != source_pc \
			or delay_in_a != context.accumulator or caller_stack_pointer != context.stack_pointer \
			or saved_x != context.x_register or saved_y != context.y_register \
			or current_bank_low != 0x18 or current_bank_high != 0x19):
		return _fail("Slot-$11 `$8047` yield must be reached through its bounded actor-worker source executor.")
	var is_slot11_resume_callsite := source_pc in [0xCC50, 0xCCA0, 0xCCCE, 0xA217]
	var expected_slot11_low := 0x1A if source_pc == 0xA217 else 0x18
	var expected_slot11_high := 0x1B if source_pc == 0xA217 else 0x19
	if is_slot11_resume_callsite and (not _slot11_actor_resume_yield_in_progress \
			and not (source_pc == 0xA217 and _slot11_f5_animation_yield_in_progress) \
			or slot_base != 0x11 or context.program_counter != source_pc \
			or delay_in_a != context.accumulator or caller_stack_pointer != context.stack_pointer \
			or saved_x != context.x_register or saved_y != context.y_register \
			or current_bank_low != expected_slot11_low or current_bank_high != expected_slot11_high \
			or not call_frame_already_pushed):
		return _fail("Slot-$11 continuation yield requires its bounded ROM consumer and pre-pushed JSR frame.")
	if source_pc == 0xEB88 and (not _root_slot09_yield_in_progress or slot_base != 0x09 \
			or delay_in_a != context.accumulator or caller_stack_pointer != context.stack_pointer \
			or saved_x != context.x_register or saved_y != context.y_register \
			or current_bank_low != context.bank_low or current_bank_high != context.bank_high):
		return _fail("Root slot `$09` yield must be reached through its bounded ROM-prefix executor.")
	var worker_jsr_already_executed := source_pc == 0x8886
	var scenario_jsr_already_executed := source_pc == 0xCBBE and slot_base == 0x05
	var slot11_resume_jsr_already_executed := source_pc in [0xCC50, 0xCCA0, 0xCCCE, 0xA217] and slot_base == 0x11
	if scenario_jsr_already_executed and (not call_frame_already_pushed \
			or delay_in_a != context.accumulator or saved_x != context.x_register \
			or saved_y != context.y_register or current_bank_low != context.bank_low \
			or current_bank_high != context.bank_high):
		return _fail("Slot-$05 `$CBBE` save inputs must match the adopted worker's post-JSR state.")
	var expected_context_pc := 0xC515 if worker_jsr_already_executed else (0xCB0F if scenario_jsr_already_executed else source_pc)
	if context.program_counter != expected_context_pc or not _supported_yield_callsite(source_pc) or not _byte_arguments([
		delay_in_a, caller_stack_pointer, saved_x, saved_y, current_bank_low, current_bank_high,
	]):
		return _fail("Yield requires a packaged ROM-verified callsite and byte-valued CPU/task inputs.")
	if not _callsite_matches_source(source_pc):
		return false
	var sp := caller_stack_pointer
	if worker_jsr_already_executed:
		if call_frame_already_pushed:
			return _fail("The `$8886` worker handoff uses its existing C515 frame contract.")
		if delay_in_a != context.accumulator or saved_x != context.x_register \
				or saved_y != context.y_register or current_bank_low != context.bank_low \
				or current_bank_high != context.bank_high:
			return _fail("The `$8886` save inputs must match the adopted worker's live A/X/Y and mapper state.")
		# `$8886` has already executed inside RomFreshBank18WorkerPrefix. The
		# resulting `$C515` state has the JSR return word on the real task stack;
		# validate it instead of pushing that same call frame a second time.
		if sp != context.stack_pointer or _stack_page[(sp + 1) & 0xFF] != ((source_pc + 2) & 0xFF) \
				or _stack_page[(sp + 2) & 0xFF] != (((source_pc + 2) >> 8) & 0xFF):
			return _fail("The `$8886` worker boundary does not carry its exact `$C515` JSR return word.")
	elif call_frame_already_pushed:
		if not ((source_pc == 0xEB88 and slot_base == 0x09) or scenario_jsr_already_executed \
				or slot11_resume_jsr_already_executed):
			return _fail("Pre-pushed `$CB0F` frames are limited to the source-proven root, scenario, and slot-$11 continuations.")
		var return_minus_one := (source_pc + 2) & 0xFFFF
		var frame_sp := (caller_stack_pointer - 2) & 0xFF
		if _stack_page[(frame_sp + 1) & 0xFF] != (return_minus_one & 0xFF) \
				or _stack_page[(frame_sp + 2) & 0xFF] != ((return_minus_one >> 8) & 0xFF):
			return _fail("Pre-pushed source call frame does not contain the exact return word.")
		if scenario_jsr_already_executed and caller_stack_pointer != ((context.stack_pointer + 2) & 0xFF):
			return _fail("The slot-$05 `$CBBE` frame does not match the worker's post-JSR stack pointer.")
		sp = frame_sp
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


## Consumes the actual ROM-byte `$EB88->$CB0F` route result and applies only
## the verified task-save handler. Source call-frame bytes are validated and
## adopted; the handler's JSR frame is not pushed a second time.
func apply_slot09_cb0f_from_root_route_result(handler_entry_result: Dictionary) -> Dictionary:
	if not _require_initialized():
		return {}
	var proof := _validate_slot09_cb0f_root_result(handler_entry_result)
	if not bool(proof.get("ok", false)):
		_fail(String(proof.get("reason", "Invalid slot-$09 `$CB0F` source result.")))
		return {}
	var context: TaskContext = _contexts.get(0x09)
	if _active_task_slot != 0x09 or context == null \
			or context.phase != ContextPhase.RUNNING \
			or context.program_counter not in [0xEB8B, 0xEBD7] \
			or context.stack_pointer != 0x7A \
			or int(_ram[0x0000]) != 0x09:
		_fail("`$CB0F` save requires slot-$09 `$EB8B`: active=$%02X phase=%s pc=$%04X sp=$%02X current=$%02X." % [
			_active_task_slot, str(context.phase) if context != null else "missing",
			context.program_counter if context != null else -1,
			context.stack_pointer if context != null else -1, int(_ram[0x0000])])
		return {}
	var request: Dictionary = handler_entry_result["source_yield_request"]
	var stack_writes: Array = handler_entry_result["stack_writes"]
	var source_stack: PackedByteArray = handler_entry_result["stack_page"]
	var source_ram: PackedByteArray = handler_entry_result["ram_image"]
	var expected_stack := _stack_page.duplicate()
	for write_variant in stack_writes:
		var write: Dictionary = write_variant
		var address := int(write.get("address", -1))
		var value := int(write.get("value", -1))
		if address < 0x0100 or address >= 0x0200 or value < 0 or value > 0xFF:
			_fail("`$CB0F` source JSR stack write is outside the live CPU stack page.")
			return {}
		expected_stack[address & 0xFF] = value
	if source_ram.size() != RAM_SIZE:
		_fail("`$CB0F` source result has an invalid RAM image.")
		return {}
	if int(_ram[0x052E]) != int(proof["input_ram_052e"]) \
			or int(source_ram[0x052E]) != int(proof["output_ram_052e"]):
		_fail("`$CB0F` counter proof differs from live input/output: live=$%02X proof-in=$%02X source-out=$%02X proof-out=$%02X." % [
			int(_ram[0x052E]), int(proof["input_ram_052e"]),
			int(source_ram[0x052E]), int(proof["output_ram_052e"])])
		return {}
	if source_stack.size() != STACK_PAGE_SIZE:
		_fail("`$CB0F` source result has an invalid stack-page image.")
		return {}
	var active_stack_mismatch := -1
	for stack_index in range(0x7B, STACK_PAGE_SIZE):
		if int(source_stack[stack_index]) != int(expected_stack[stack_index]):
			active_stack_mismatch = stack_index
			break
	if active_stack_mismatch >= 0:
		_fail("`$CB0F` source stack differs from live stack plus checked JSR writes in the active stack window at `$%02X`." % active_stack_mismatch)
		return {}
	for address in range(RAM_SIZE):
		if address != 0x052E and address != 0x0024 and address != 0x0025 \
				and (address < 0x0100 or address >= 0x0200) \
				and int(source_ram[address]) != int(_ram[address]):
			_fail("`$CB0F` source result changed live RAM outside `$052E` and mapper save at `$%04X`." % address)
			return {}
	if int(source_ram[0x0024]) != int(request.get("bank_low", -1)) \
			or int(source_ram[0x0025]) != int(request.get("bank_high", -1)):
		_fail("`$CB0F` source mapper save does not match the verified caller bank pair.")
		return {}
	# The route executor has already executed this JSR. Adopt only its two
	# checked return-address writes; do not copy its full trace-derived RAM image.
	for write_variant in stack_writes:
		var write: Dictionary = write_variant
		var address := int(write["address"])
		var value := int(write["value"])
		_write_stack_byte(address & 0xFF, value)
	if source_stack[0x79] != 0x8A or source_stack[0x7A] != 0xEB \
			or _stack_page[0x79] != 0x8A or _stack_page[0x7A] != 0xEB:
		_fail("The live `$EB88` caller stack does not carry its verified `$EB8A` JSR return word.")
		return {}
	# `$CB0F` reads this live bank pair to save the active task's mapping.
	_ram[0x052E] = int(proof["output_ram_052e"])
	_ram[0x0024] = int(request["bank_low"])
	_ram[0x0025] = int(request["bank_high"])
	context.program_counter = int(request["callsite_pc"])
	context.accumulator = int(request["delay_in_a"])
	context.x_register = int(request["x"])
	context.y_register = int(request["y"])
	context.stack_pointer = int(request["pre_jsr_sp"])
	context.bank_low = int(request["bank_low"])
	context.bank_high = int(request["bank_high"])
	context.source_label = "ROM-byte slot-$09 root loop `$EB88->$CB0F`"
	_root_slot09_yield_in_progress = true
	var saved := yield_at_verified_callsite(0x09, 0xEB88,
		int(request["delay_in_a"]), int(request["pre_jsr_sp"]),
		int(request["x"]), int(request["y"]),
		int(request["bank_low"]), int(request["bank_high"]), true)
	_root_slot09_yield_in_progress = false
	if not saved:
		return {}
	var save_result := {
		"ok": true,
		"status": "slot09_saved_at_cb0f",
		"rom_sha256": ROM_SHA256,
		"source_manifest": String(handler_entry_result["source_manifest"]),
		"slot_base": 0x09,
		"callsite_pc": 0xEB88,
		"handler_entry_pc": 0xCB0F,
		"resume_pc": 0xEB8B,
		"task_record": _record_bytes(0x09),
		"saved_stack_pointer": int(_ram[0x0A]),
		"saved_y": int(_stack_page[(int(_ram[0x0A]) + 1) & 0xFF]),
		"saved_x": int(_stack_page[(int(_ram[0x0A]) + 2) & 0xFF]),
		"return_low": int(_stack_page[(int(_ram[0x0A]) + 3) & 0xFF]),
		"return_high": int(_stack_page[(int(_ram[0x0A]) + 4) & 0xFF]),
		"scheduler_scan_cursor": _scheduler_scan_cursor,
		"scheduler_y_register": _scheduler_y_register,
		"nmi_ready_latch": int(_ram[0x001B]),
		"active_task_slot": _active_task_slot,
		"handler_source_hash": String(SOURCE_SPANS["task_yield"]["sha256"]),
		"full_source_ram_copied": false,
		"preexisting_jsr_frame_reused": true,
	}
	_last_slot09_cb0f_save_result = save_result.duplicate(true)
	return save_result


## Adopts the source CPU boundary after slot-$09's bounded nested workers
## return to the root loop. The ROM executes X/Y-preserving setup there, so
## the scenario-active values flow into `$CB0F` instead of being replaced by
## constants from the earlier zero-state route.
## Commits the checked scenario-$36 `$0516=$51` no-actor callback continuation
## before the slot-$09 worker prefix. This profile is restricted to the ROM
## branch whose `$0529=$FF` selector skips `$CAE7` and enters `$ED2D`.
func adopt_slot09_scenario36_post_callback_prefix_state(worker_state: Dictionary) -> bool:
	if not _require_initialized():
		return false
	var context: TaskContext = _contexts.get(0x09)
	if _active_task_slot != 0x09 or context == null \
			or context.phase != ContextPhase.RUNNING or context.program_counter != 0xEB8B:
		return _fail("Scenario-$36 post-callback adoption requires the live slot-$09 `$EB8B` task.")
	var entry_variant: Variant = worker_state.get("entry_registers", {})
	var registers_variant: Variant = worker_state.get("registers", {})
	var mapper_variant: Variant = worker_state.get("mapper", {})
	var ram_variant: Variant = worker_state.get("ram_image", PackedByteArray())
	var stack_variant: Variant = worker_state.get("stack_page", PackedByteArray())
	var writes_variant: Variant = worker_state.get("writes", [])
	var stack_writes_variant: Variant = worker_state.get("stack_writes", [])
	var mapper_writes_variant: Variant = worker_state.get("mapper_writes", [])
	var hashes_variant: Variant = worker_state.get("source_span_hashes", {})
	if not entry_variant is Dictionary or not registers_variant is Dictionary \
			or not mapper_variant is Dictionary or not ram_variant is PackedByteArray \
			or not stack_variant is PackedByteArray or not writes_variant is Array \
			or not stack_writes_variant is Array or not mapper_writes_variant is Array \
			or not hashes_variant is Dictionary:
		return _fail("Scenario-$36 post-callback result omits its CPU, mapper, memory, or ordered writes.")
	var entry: Dictionary = entry_variant
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var source_ram: PackedByteArray = ram_variant
	var source_stack: PackedByteArray = stack_variant
	var hashes: Dictionary = hashes_variant
	if String(worker_state.get("rom_sha256", "")) != ROM_SHA256 \
			or String(worker_state.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/slot09_eb8b_continuation/manifest.json" \
			or String(worker_state.get("status", "")) != "stopped_before_worker_body" \
			or not bool(worker_state.get("scenario36_post_callback_executed", false)) \
			or bool(worker_state.get("scenario_active", true)) \
			or int(worker_state.get("entry_pc", -1)) != 0xEB8B \
			or int(worker_state.get("exit_pc", -1)) != 0x86F8 \
			or not _slot09_registers_match_context(entry, context, 0xEB8B) \
			or source_ram.size() != RAM_SIZE or source_stack.size() != STACK_PAGE_SIZE \
			or int(source_ram[0x0000]) != 0x09 or int(source_ram[0x0516]) != 0x01 \
			or int(source_ram[0x0518]) != 0x36 or int(source_ram[0x0519]) != 0x10 \
			or int(source_ram[0x0529]) != 0xFF or int(source_ram[0x05CE]) != 0xA0 \
			or int(mapper.get("bank_low", -1)) != 0x18 \
			or int(mapper.get("bank_high", -1)) != 0x19 \
			or int(mapper.get("select", -1)) != 0x07:
		return _fail("Scenario-$36 post-callback output mismatch: status=%s post=%s route=%s active=%s entry/exit=$%04X/$%04X regs_match=%s RAM=$%02X/$%02X/$%02X/$%02X/$%02X/$%02X mapper=$%02X/$%02X/%02X." % [
			String(worker_state.get("status", "")), str(worker_state.get("scenario36_post_callback_executed", false)),
			str(worker_state.get("scenario_route_state_executed", false)), str(worker_state.get("scenario_active", true)),
			int(worker_state.get("entry_pc", -1)), int(worker_state.get("exit_pc", -1)),
			str(_slot09_registers_match_context(entry, context, 0xEB8B)), int(source_ram[0x0000]),
			int(source_ram[0x0516]), int(source_ram[0x0518]), int(source_ram[0x0519]),
			int(source_ram[0x0529]), int(source_ram[0x05CE]), int(mapper.get("bank_low", -1)),
			int(mapper.get("bank_high", -1)), int(mapper.get("select", -1))])
	if not _validate_slot09_source_manifest_hashes(
			String(worker_state["source_manifest"]), hashes):
		return false
	var expected_ram := _ram.duplicate()
	var expected_stack := _stack_page.duplicate()
	for write_variant: Variant in writes_variant:
		if not write_variant is Dictionary:
			return _fail("Scenario-$36 post-callback RAM write stream contains a malformed event.")
		var write: Dictionary = write_variant
		var address := int(write.get("address", -1))
		var value := int(write.get("value", -1))
		var allowed_source_slot13_clear := (address == 0x000D and value == 0 \
				and int(write.get("pc", -1)) == 0xED08) \
				or (address == 0x000E and value == 0 and int(write.get("pc", -1)) == 0xED0A)
		if address < 0 or address >= RAM_SIZE or value < 0 or value > 0xFF \
				or not write.has("pc") \
				or (_is_scheduler_owned_ram_address(address) and not allowed_source_slot13_clear):
			return _fail("Scenario-$36 post-callback source write conflicts with scheduler-owned RAM `$%04X`." % address)
		expected_ram[address] = value
		if address >= 0x0100 and address < 0x0200:
			expected_stack[address & 0xFF] = value
	for write_variant: Variant in stack_writes_variant:
		if not write_variant is Dictionary:
			return _fail("Scenario-$36 post-callback stack write stream contains a malformed event.")
		var write: Dictionary = write_variant
		var address := int(write.get("address", -1))
		var value := int(write.get("value", -1))
		if address < 0x0100 or address >= 0x0200 or value < 0 or value > 0xFF:
			return _fail("Scenario-$36 post-callback stack write is outside the CPU stack page.")
		expected_ram[address] = value
		expected_stack[address & 0xFF] = value
	if expected_ram != source_ram or expected_stack != source_stack:
		return _fail("Scenario-$36 post-callback RAM/stack differs from replaying its ordered ROM-source writes.")
	var mapper_result := _replay_actor_source_mapper_writes(mapper_writes_variant,
			context.bank_low, context.bank_high, mapper,
			int(context.mapper_state.get("select", -1)))
	if not bool(mapper_result.get("ok", false)):
		return _fail(String(mapper_result.get("reason", "Scenario-$36 post-callback mapper replay failed.")))
	_ram = expected_ram
	_stack_page = expected_stack
	context.accumulator = int(registers.get("a", -1)) & 0xFF
	context.x_register = int(registers.get("x", -1)) & 0xFF
	context.y_register = int(registers.get("y", -1)) & 0xFF
	context.status_register = int(registers.get("p", context.status_register)) & 0xFF
	context.status_known_mask = int(registers.get("p_known_mask", context.status_known_mask)) & 0xFF
	context.stack_pointer = int(registers.get("sp", -1))
	context.program_counter = int(registers.get("pc", -1))
	context.bank_low = int(mapper["bank_low"])
	context.bank_high = int(mapper["bank_high"])
	context.mapper_state = mapper.duplicate(true)
	context.source_label = "ROM-byte scenario-$36 `$ED2D` no-actor continuation"
	return true


## Replays the three checked zero-branch workers after the scenario-$36
## callback. Their `$0532` normalization must be committed before `$EBD7`.
func adopt_slot09_scenario36_worker_chain_state(worker_results: Array) -> bool:
	if not _require_initialized():
		return false
	var context: TaskContext = _contexts.get(0x09)
	if worker_results.size() != 3 or _active_task_slot != 0x09 \
			or int(_ram[0x0000]) != 0x09 or context == null \
			or context.phase != ContextPhase.RUNNING or context.program_counter != 0x86F8 \
			or int(_ram[0x0518]) != 0x36:
		return _fail("Scenario-$36 worker adoption requires its live slot-$09 `$86F8` context and three ordered worker results.")
	var manifests := [
		"res://reference/rom_extract/gameplay/slot09_86f8_worker/manifest.json",
		"res://reference/rom_extract/gameplay/slot09_8779_worker/manifest.json",
		"res://reference/rom_extract/gameplay/slot09_87e6_worker/manifest.json",
	]
	var schemas := ["ct2-slot09-86f8-worker-source-v1",
		"ct2-slot09-8779-worker-source-v1", "ct2-slot09-87e6-worker-source-v1"]
	var statuses := ["returned_to_root_caller", "returned_before_next_worker_call",
		"returned_before_root_loop_check"]
	var entry_pcs: Array[int] = [0x86F8, 0xEBB3, 0xEBC5]
	var exit_pcs: Array[int] = [0xEBB3, 0xEBC5, 0xEBD7]
	var source_spans: Array[Dictionary] = [
		{"bank18_slot09_worker_86F8_8778.bin": "ae998967ec1bb0e39ffcc72c8670a393946cfe233ad6845dc524870bd3264d23"},
		{"fixed_root_slot09_after_86f8_EBB3_EBC5.bin": "5b1a5142b268e834aafe619d51b6c51a80e71c99ec269641ecb61cc6c0d50883",
			"bank18_slot09_worker_vector_8006_8009.bin": "ec20595812bf088382eaa136f2bbf5cf9429467653f948041a7684a34e1b4fab",
			"bank18_slot09_worker_8779_87A4.bin": "407f2feb4cedb61c07aab10b9b39e7775d9891b04afeaa16b43ad459aeeab511",
			"fixed_mapper_helper_CE2D_CE4A.bin": "6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c"},
		{"fixed_root_slot09_after_8779_EBC5_EBD7.bin": "75ff2ee06764439aecb4eae84c694e1f99b083d7b21a92c9ad5e41baa09b304e",
			"bank18_slot09_vector_8009_800B.bin": "ee600ed5f0ff7a46e0b9a1d41acb3615828d6c635eee42c16598839227a71e27",
			"bank18_slot09_worker_87E6_8850.bin": "879cfbc3684874aa7a857d9ee294755cbb773b616d5815335a2208d414799509",
			"bank19_slot09_worker_pointer_table_AD54_AD5D.bin": "8d1c08abdc6be570a1a0e8304738c995c09856b4081e0962f15db579cb95f7b5",
			"fixed_mapper_helper_CE2D_CE4A.bin": "6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c"},
	]
	var current_registers := _register_snapshot(context)
	var current_mapper: Dictionary = context.mapper_state.duplicate(true)
	var current_ram := _ram.duplicate()
	var current_stack := _stack_page.duplicate()
	var scheduler_records := {}
	for slot_base: int in SLOT_BASES:
		scheduler_records[slot_base] = current_ram.slice(slot_base, slot_base + 4)
	for index in range(worker_results.size()):
		var result_variant: Variant = worker_results[index]
		if not result_variant is Dictionary:
			return _fail("Scenario-$36 worker result %d is malformed." % index)
		var result: Dictionary = result_variant
		if String(result.get("rom_sha256", "")) != ROM_SHA256 \
				or String(result.get("source_manifest", "")) != String(manifests[index]) \
				or String(result.get("status", "")) != String(statuses[index]) \
				or int(result.get("entry_pc", -1)) != entry_pcs[index] \
				or int(result.get("exit_pc", -1)) != exit_pcs[index] \
				or bool(result.get("trace_state_used", true)) \
				or bool(result.get("nmi_cadence_generated", true)) \
				or bool(result.get("ppu_apu_effects_applied", true)) \
				or (index == 1 and String(result.get("previous_worker_manifest", "")) != String(manifests[0])) \
				or (index == 2 and String(result.get("previous_worker_manifest", "")) != String(manifests[1])):
			return _fail("Scenario-$36 worker result %d has unsupported provenance or boundary." % index)
		if not _validate_actor_chain_manifest(String(manifests[index]),
				String(schemas[index]), source_spans[index]):
			return false
		var entry_variant: Variant = result.get("entry_registers", {})
		var registers_variant: Variant = result.get("registers", {})
		var mapper_variant: Variant = result.get("mapper", {})
		var ram_variant: Variant = result.get("ram_image", PackedByteArray())
		var stack_variant: Variant = result.get("stack_page", PackedByteArray())
		var writes_variant: Variant = result.get("memory_writes", result.get("ram_writes", []))
		var stack_writes_variant: Variant = result.get("stack_writes", [])
		var mapper_writes_variant: Variant = result.get("mapper_writes", [])
		if not entry_variant is Dictionary or not registers_variant is Dictionary \
				or not mapper_variant is Dictionary or not ram_variant is PackedByteArray \
				or not stack_variant is PackedByteArray or not writes_variant is Array \
				or not stack_writes_variant is Array or not mapper_writes_variant is Array:
			return _fail("Scenario-$36 worker result %d omits its CPU, mapper, memory, or writes." % index)
		var entry: Dictionary = entry_variant
		var registers: Dictionary = registers_variant
		var mapper: Dictionary = mapper_variant
		var source_ram: PackedByteArray = ram_variant
		var source_stack: PackedByteArray = stack_variant
		if entry != current_registers or source_ram.size() != RAM_SIZE \
				or source_stack.size() != STACK_PAGE_SIZE \
				or int(registers.get("pc", -1)) != exit_pcs[index] \
				or int(source_ram[0x0000]) != 0x09 \
				or (index > 0 and result.get("entry_mapper", {}) != current_mapper):
			return _fail("Scenario-$36 worker result %d does not continue the preceding CPU/RAM boundary." % index)
		var replay := _replay_actor_source_writes(writes_variant, stack_writes_variant,
				current_ram, current_stack, index == 0)
		if not bool(replay.get("ok", false)):
			return _fail(String(replay.get("reason", "Scenario-$36 worker write replay failed.")))
		var expected_ram: PackedByteArray = replay["ram_image"]
		var expected_stack: PackedByteArray = replay["stack_page"]
		if expected_ram != source_ram or expected_stack != source_stack:
			return _fail("Scenario-$36 worker result %d differs from ordered ROM-write replay." % index)
		for slot_base: int in SLOT_BASES:
			if source_ram.slice(slot_base, slot_base + 4) != scheduler_records[slot_base]:
				return _fail("Scenario-$36 worker result %d changed scheduler record `$%02X`." % [index, slot_base])
		var mapper_replay := _replay_actor_source_mapper_writes(mapper_writes_variant,
				int(current_mapper.get("bank_low", -1)),
				int(current_mapper.get("bank_high", -1)), mapper,
				int(current_mapper.get("select", -1)))
		if not bool(mapper_replay.get("ok", false)):
			return _fail(String(mapper_replay.get("reason", "Scenario-$36 worker mapper replay failed.")))
		current_registers = registers.duplicate(true)
		current_mapper = mapper.duplicate(true)
		current_ram = source_ram.duplicate()
		current_stack = source_stack.duplicate()
	_ram = current_ram
	_stack_page = current_stack
	context.accumulator = int(current_registers.get("a", -1)) & 0xFF
	context.x_register = int(current_registers.get("x", -1)) & 0xFF
	context.y_register = int(current_registers.get("y", -1)) & 0xFF
	context.status_register = int(current_registers.get("p", -1)) & 0xFF
	context.status_known_mask = int(current_registers.get("p_known_mask", -1)) & 0xFF
	context.stack_pointer = int(current_registers.get("sp", -1))
	context.program_counter = int(current_registers.get("pc", -1))
	context.bank_low = int(current_mapper.get("bank_low", -1))
	context.bank_high = int(current_mapper.get("bank_high", -1))
	context.mapper_state = current_mapper.duplicate(true)
	context.source_label = "ROM-byte scenario-$36 zero-branch worker chain through `$EBD7`"
	return true


func adopt_slot09_root_loop_entry_state(root_result: Dictionary) -> bool:
	if not _require_initialized():
		return false
	var proof := _validate_slot09_cb0f_root_result(root_result)
	if not bool(proof.get("ok", false)):
		return _fail(String(proof.get("reason", "Invalid slot-$09 root-loop result.")))
	var context: TaskContext = _contexts.get(0x09)
	var scenario36_worker_context := int(_ram[0x0518]) == 0x36 \
		and context != null and context.program_counter in [0x86F8, 0xEBD7]
	var expected_context_sp := 0x7A if context != null and context.program_counter == 0xEBD7 else 0x78
	if _active_task_slot != 0x09 or context == null \
			or context.phase != ContextPhase.RUNNING \
			or (context.program_counter != 0xEB8B and not scenario36_worker_context) \
			or context.stack_pointer != expected_context_sp:
		return _fail("Root-loop adoption requires slot-$09's live prefix boundary at `$86F8`.")
	var entry_variant: Variant = root_result.get("entry_registers", {})
	var exit_variant: Variant = root_result.get("registers", {})
	var mapper_variant: Variant = root_result.get("mapper", {})
	var request_variant: Variant = root_result.get("source_yield_request", {})
	var ram_variant: Variant = root_result.get("ram_image", PackedByteArray())
	var stack_variant: Variant = root_result.get("stack_page", PackedByteArray())
	if not entry_variant is Dictionary or not exit_variant is Dictionary \
			or not mapper_variant is Dictionary or not request_variant is Dictionary \
			or not ram_variant is PackedByteArray or not stack_variant is PackedByteArray:
		return _fail("Root-loop result omits its source CPU, mapper, memory, or yield request.")
	var entry: Dictionary = entry_variant
	var exit_state: Dictionary = exit_variant
	var mapper: Dictionary = mapper_variant
	var request: Dictionary = request_variant
	var source_ram: PackedByteArray = ram_variant
	var source_stack: PackedByteArray = stack_variant
	var input_counter := int(proof["input_ram_052e"])
	var output_counter := int(proof["output_ram_052e"])
	var helper_memory_writes: Array = proof.get("helper_memory_writes", [])
	var normalized_source_ram := source_ram.duplicate()
	if normalized_source_ram.size() == RAM_SIZE:
		normalized_source_ram[0x052E] = int(_ram[0x052E])
		normalized_source_ram[0x0024] = int(_ram[0x0024])
		normalized_source_ram[0x0025] = int(_ram[0x0025])
		for helper_write_variant in helper_memory_writes:
			if not helper_write_variant is Dictionary:
				return _fail("The `$CBF1` helper returned a malformed queue write.")
			var helper_write: Dictionary = helper_write_variant
			var helper_address := int(helper_write.get("address", -1))
			if helper_address < 0x0700 or helper_address >= 0x0705:
				return _fail("The `$CBF1` helper wrote outside its five-byte sound queue.")
			normalized_source_ram[helper_address] = int(_ram[helper_address])
	var first_normalized_ram_mismatch := -1
	if normalized_source_ram.size() == RAM_SIZE:
		for address in range(RAM_SIZE):
			if int(normalized_source_ram[address]) != int(_ram[address]):
				first_normalized_ram_mismatch = address
				break
	if String(root_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(root_result.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/slot09_ebd7_root_checks/manifest.json" \
			or String(root_result.get("status", "")) != "reached_scheduler_yield_handler_entry" \
			or int(root_result.get("entry_pc", -1)) != 0xEBD7 \
			or int(root_result.get("exit_pc", -1)) != 0xCB0F \
			or int(entry.get("pc", -1)) != 0xEBD7 or int(entry.get("sp", -1)) != 0x7A \
			or int(entry.get("x", -1)) != context.x_register \
			or int(entry.get("y", -1)) != context.y_register \
			or int(exit_state.get("pc", -1)) != 0xCB0F \
			or int(exit_state.get("sp", -1)) != 0x78 \
			or int(exit_state.get("x", -1)) != int(proof.get("output_x", -2)) \
			or int(exit_state.get("y", -1)) != int(proof.get("output_y", -2)) \
			or int(mapper.get("bank_low", -1)) != 0x18 \
			or int(mapper.get("bank_high", -1)) != 0x19 \
			or source_ram.size() != RAM_SIZE or source_stack.size() != STACK_PAGE_SIZE \
			or int(source_ram[0x0000]) != 0x09 \
			or input_counter != int(_ram[0x052E]) \
			or int(source_ram[0x052E]) != output_counter \
			or int(source_ram[0x0024]) != int(request.get("bank_low", -1)) \
			or int(source_ram[0x0025]) != int(request.get("bank_high", -1)) \
			or normalized_source_ram != _ram \
			or int(request.get("callsite_pc", -1)) != 0xEB88 \
			or int(request.get("x", -1)) != int(proof.get("output_x", -2)) \
			or int(request.get("y", -1)) != int(proof.get("output_y", -2)):
		return _fail("Root-loop `$EBD7` mismatch: slot/pc/sp=%02X/$%04X/%02X entry=$%04X/%02X/%02X counter=%02X>%02X live=%02X mapper=%02X/%02X request=%02X/%02X normalized_ram=$%04X live=%02X source=%02X." % [
			_active_task_slot, int(context.program_counter) if context != null else -1,
			int(context.stack_pointer) if context != null else -1,
			int(entry.get("pc", -1)), int(entry.get("x", -1)), int(entry.get("y", -1)),
			input_counter, output_counter, int(_ram[0x052E]),
			int(mapper.get("bank_low", -1)), int(mapper.get("bank_high", -1)),
			int(request.get("bank_low", -1)), int(request.get("bank_high", -1)),
			first_normalized_ram_mismatch,
			int(_ram[first_normalized_ram_mismatch]) if first_normalized_ram_mismatch >= 0 else -1,
			int(normalized_source_ram[first_normalized_ram_mismatch]) if first_normalized_ram_mismatch >= 0 else -1])
	for helper_write_variant in helper_memory_writes:
		var helper_write: Dictionary = helper_write_variant
		_ram[int(helper_write["address"])] = int(helper_write["value"])
	context.accumulator = int(entry.get("a", -1))
	context.x_register = int(entry.get("x", -1))
	context.y_register = int(entry.get("y", -1))
	context.stack_pointer = int(entry.get("sp", -1))
	context.program_counter = int(entry.get("pc", -1))
	context.bank_low = int(mapper.get("bank_low", -1))
	context.bank_high = int(mapper.get("bank_high", -1))
	context.mapper_state = mapper.duplicate(true)
	context.source_label = "ROM-byte slot-$09 root loop return from `$87E6`"
	return true


## Validates source provenance and the exact CPU/stack inputs before allowing
## the task-save transition. Kept public so focused verifiers can reject
## mutated source-result copies without running a second production route.
func validate_slot09_cb0f_root_result(handler_entry_result: Dictionary) -> Dictionary:
	return _validate_slot09_cb0f_root_result(handler_entry_result)


func _validate_slot09_cb0f_root_result(result: Dictionary) -> Dictionary:
	if String(result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(result.get("status", "")) != "reached_scheduler_yield_handler_entry" \
			or String(result.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/slot09_ebd7_root_checks/manifest.json" \
			or String(result.get("previous_result_manifest", "")) != "res://reference/rom_extract/gameplay/slot09_87e6_worker/manifest.json" \
			or int(result.get("entry_pc", -1)) != 0xEBD7 \
			or int(result.get("exit_pc", -1)) != 0xCB0F \
			or bool(result.get("yield_handler_executed", true)) \
			or bool(result.get("trace_state_used", true)) \
			or bool(result.get("nmi_cadence_generated", true)) \
			or bool(result.get("next_root_check_executed", true)) \
			or bool(result.get("later_root_checks_executed", true)):
		return {"ok": false, "reason": "Input is not the source-derived slot-$09 `$EB88->$CB0F` call result."}
	var request_variant: Variant = result.get("source_yield_request", {})
	var entry_variant: Variant = result.get("entry_registers", {})
	var registers_variant: Variant = result.get("registers", {})
	var mapper_variant: Variant = result.get("mapper", {})
	var ram_variant: Variant = result.get("ram_image", PackedByteArray())
	var stack_variant: Variant = result.get("stack_page", PackedByteArray())
	var writes_variant: Variant = result.get("stack_writes", [])
	if not request_variant is Dictionary or not entry_variant is Dictionary \
			or not registers_variant is Dictionary or not mapper_variant is Dictionary \
			or not ram_variant is PackedByteArray or not stack_variant is PackedByteArray \
			or not writes_variant is Array:
		return {"ok": false, "reason": "`$CB0F` result omits its source request, CPU/mapper, RAM, stack, or ordered JSR writes."}
	var request: Dictionary = request_variant
	var entry: Dictionary = entry_variant
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	var writes: Array = writes_variant
	var input_counter := int(result.get("input_ram_052e", -1))
	if input_counter < 0 or input_counter > 0xFF:
		return {"ok": false, "reason": "Root `$052E` counter is outside the byte range."}
	var counter_one_helper: Dictionary = {}
	if input_counter == 0x01:
		var call_variant: Variant = result.get("source_cbf1_call", {})
		var helper_variant: Variant = result.get("cbf1_helper_result", {})
		if not call_variant is Dictionary or not helper_variant is Dictionary:
			return {"ok": false, "reason": "The live `$052E=$01` root branch omits its source `$EC02->$CBF1` call and helper result."}
		var helper_entry_ram: Variant = call_variant.get("ram_image", PackedByteArray())
		if not helper_entry_ram is PackedByteArray or helper_entry_ram.size() != RAM_SIZE:
			return {"ok": false, "reason": "The nested `$CBF1` call omits its complete live RAM input."}
		var expected_helper_entry_ram := _ram.duplicate()
		expected_helper_entry_ram[0x052E] = 0x00
		var supplied_helper: Dictionary = helper_variant
		var helper_input_queue: Variant = supplied_helper.get("input_queue", PackedByteArray())
		if not helper_input_queue is PackedByteArray or helper_input_queue.size() != 5:
			return {"ok": false, "reason": "The `$CBF1` result omits its five source queue inputs."}
		for queue_index in 5:
			expected_helper_entry_ram[0x0700 + queue_index] = int(helper_input_queue[queue_index])
		if helper_entry_ram != expected_helper_entry_ram:
			return {"ok": false, "reason": "The nested `$CBF1` call does not carry the live root RAM after `$052E` decrements to zero."}
		var sound_queue_executor: RefCounted = CBF1_SOUND_QUEUE_EXECUTOR_SCRIPT.new()
		if not sound_queue_executor.configure_from_project_sources():
			return {"ok": false, "reason": "The `$CBF1` source consumer is unavailable: " + sound_queue_executor.error_message}
		var replayed_helper: Dictionary = sound_queue_executor.execute_from_root_cbf1_call(call_variant)
		if not bool(replayed_helper.get("ok", false)) or replayed_helper != helper_variant:
			return {"ok": false, "reason": "The nested `$CBF1` queue result differs from replaying the checked helper source."}
		counter_one_helper = helper_variant
	var expected_counter := input_counter - 1 if input_counter > 1 else 0
	var expected_instruction_pcs: Array[int] = [0xEBD7, 0xEBDA, 0xEC05, 0xEB86, 0xEB88]
	if input_counter > 1:
		expected_instruction_pcs = [0xEBD7, 0xEBDA, 0xEBDC, 0xEBDF, 0xEC05, 0xEB86, 0xEB88]
	elif input_counter == 0x01:
		expected_instruction_pcs = [0xEBD7, 0xEBDA, 0xEBDC, 0xEBDF,
			0xEBE1, 0xEBE4, 0xEBE6, 0xEBF9, 0xEBFC, 0xEC02, 0xEC05,
			0xEB86, 0xEB88]
	var entry_x := int(entry.get("x", -1))
	var entry_y := int(entry.get("y", -1))
	if entry_x < 0 or entry_x > 0xFF or entry_y < 0 or entry_y > 0xFF:
		return {"ok": false, "reason": "The root-loop entry omits its source-preserved X/Y registers."}
	var expected_exit_x := entry_x
	var expected_exit_y := entry_y
	if input_counter == 0x01:
		var helper_registers: Dictionary = counter_one_helper.get("registers", {})
		expected_exit_x = int(helper_registers.get("x", -1))
		expected_exit_y = int(helper_registers.get("y", -1))
		if expected_exit_x < 0 or expected_exit_x > 0xFF or expected_exit_y < 0 or expected_exit_y > 0xFF:
			return {"ok": false, "reason": "The `$CBF1` helper result omits its source-return X/Y values."}
	var expected_request := {
		"slot_base": 0x09, "callsite_pc": 0xEB88, "target_pc": 0xCB0F,
		"delay_in_a": 0x01, "pre_jsr_sp": 0x7A, "x": expected_exit_x, "y": expected_exit_y,
		"bank_low": 0x18, "bank_high": 0x19, "resume_pc": 0xEB8B,
	}
	var expected_writes: Array[Dictionary] = [
		{"pc": 0xEB88, "address": 0x017A, "value": 0xEB, "kind": "JSR_high"},
		{"pc": 0xEB88, "address": 0x0179, "value": 0x8A, "kind": "JSR_low"},
	]
	if input_counter == 0x01 \
			and ram != counter_one_helper.get("ram_image", PackedByteArray()):
		return {"ok": false, "reason": "The root `$052E=$01` continuation did not retain the exact `$CBF1` queue output RAM."}
	if request != expected_request \
			or int(entry.get("pc", -1)) != 0xEBD7 \
			or int(entry.get("a", -1)) != 0 \
			or int(entry.get("sp", -1)) != 0x7A \
			or int(registers.get("pc", -1)) != 0xCB0F \
			or int(registers.get("a", -1)) != 0x01 \
			or int(registers.get("x", -1)) != expected_exit_x \
			or int(registers.get("y", -1)) != expected_exit_y \
			or int(registers.get("sp", -1)) != 0x78 \
			or (int(registers.get("p", -1)) & 0x82) != 0 \
			or (int(registers.get("p_known_mask", -1)) & 0x82) != 0x82 \
			or int(mapper.get("bank_low", -1)) != 0x18 \
			or int(mapper.get("bank_high", -1)) != 0x19 \
			or ram.size() != RAM_SIZE or int(ram[0x0000]) != 0x09 \
			or int(ram[0x0024]) != 0x18 or int(ram[0x0025]) != 0x19 \
			or int(ram[0x052E]) != expected_counter \
			or stack.size() != STACK_PAGE_SIZE \
			or stack[0x79] != 0x8A or stack[0x7A] != 0xEB \
			or writes != expected_writes \
			or result.get("instruction_pcs", []) != expected_instruction_pcs \
			or result.get("ppu_bus_events", []) != [] \
			or result.get("apu_register_writes", []) != []:
		return {"ok": false, "reason": "`$EB88->$CB0F` CPU, mapper, live RAM, stack frame, or side-effect contract differs."}
	var helper_memory_writes: Array = counter_one_helper.get("memory_writes", [])
	return {"ok": true, "input_ram_052e": input_counter,
		"output_ram_052e": expected_counter, "output_x": expected_exit_x,
		"output_y": expected_exit_y, "helper_memory_writes": helper_memory_writes,
		"instruction_pcs": expected_instruction_pcs}


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
	var scenario_returned := context.source_label == "ROM-byte slot-$05 scenario return `$CBC1 RTS->$DADD`" \
		and context.program_counter == 0xDADD and context.stack_pointer == 0x50 \
		and context.bank_low == 0x1C and context.bank_high == 0x1D
	var initial_task_seed := _record_bytes(slot_base) == PackedByteArray([0xFF, 0x50, 0x00, 0x00])
	if (not scenario_returned and not initial_task_seed) or context.source_return_word != 0xD11D:
		return _fail("Live slot-$05 scheduler record/RTS continuation is not the ROM-seeded `$D11E` task.")
	if calls.size() != 1 or not calls[0] is Dictionary \
			or int(calls[0].get("callsite", -1)) != 0x8886 \
			or int(calls[0].get("target", -1)) != 0xC515 \
			or int(calls[0].get("sp_after_push", -1)) != 0x48:
		return _fail("Worker output does not prove the real `$8886 JSR $C515` stack contract.")
	if not scenario_returned and worker_stack.slice(0x49, 0x51).hex_encode() != "888898ef1d1ccbda":
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


## Replays the source writes from the live slot-$09 scenario-$35 path through
## `$8097->$C50F->$CAE7`, preserving other scheduler task records.
func adopt_slot09_scenario_active_prefix_state(worker_state: Dictionary) -> bool:
	if not _require_initialized():
		return false
	var context: TaskContext = _contexts.get(0x09)
	var scenario36_post_event_boundary := String(worker_state.get("status", "")) \
		== "scenario36_event_returned_to_worker_vector" \
		and int(worker_state.get("entry_pc", -1)) == 0xEB9E
	var expected_live_pc := 0xEB9E if scenario36_post_event_boundary else 0xEB8B
	if _active_task_slot != 0x09 or context == null \
			or context.phase != ContextPhase.RUNNING or context.program_counter != expected_live_pc:
		return _fail("Scenario-active adoption requires live slot-$09 at `$%04X` (active=$%02X, context=$%04X)." % [
			expected_live_pc, _active_task_slot, int(context.program_counter) if context != null else -1])
	var registers_variant: Variant = worker_state.get("registers", {})
	var mapper_variant: Variant = worker_state.get("mapper", {})
	var ram_variant: Variant = worker_state.get("ram_image", PackedByteArray())
	var stack_variant: Variant = worker_state.get("stack_page", PackedByteArray())
	var writes_variant: Variant = worker_state.get("writes", [])
	var stack_writes_variant: Variant = worker_state.get("stack_writes", [])
	var seed_variant: Variant = worker_state.get("scenario_seed_request", {})
	if not registers_variant is Dictionary or not mapper_variant is Dictionary \
			or not ram_variant is PackedByteArray or not stack_variant is PackedByteArray \
			or not writes_variant is Array or not stack_writes_variant is Array \
			or not seed_variant is Dictionary:
		return _fail("Scenario-active result omits its source CPU, mapper, memory, writes, or callback seed.")
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var source_ram: PackedByteArray = ram_variant
	var source_stack: PackedByteArray = stack_variant
	var seed: Dictionary = seed_variant
	var scenario_id := int(seed.get("scenario_id", -1))
	var expected_wait_value := 0x02 if scenario_id == 0x35 else 0x10
	var expected_actor_parameter := 0x73 if scenario_id == 0x35 else 0xFF
	var early_scenario36_return := scenario_id == 0x36 \
		and int(worker_state.get("exit_pc", -1)) == 0xEB9E \
		and int(mapper.get("bank_low", -1)) == 0x10 \
		and int(mapper.get("bank_high", -1)) == 0x11
	var scenario36_post_event_vector := scenario_id == 0x36 \
		and int(worker_state.get("entry_pc", -1)) == 0xEB9E \
		and int(worker_state.get("exit_pc", -1)) == 0x86F8 \
		and int(mapper.get("bank_low", -1)) == 0x18 \
		and int(mapper.get("bank_high", -1)) == 0x19
	var expected_entry_pc := 0xEB9E if scenario36_post_event_vector else 0xEB8B
	var complete_scenario35_prefix := scenario_id == 0x35 \
		and int(worker_state.get("exit_pc", -1)) == 0x86F8 \
		and int(mapper.get("bank_low", -1)) == 0x18 \
		and int(mapper.get("bank_high", -1)) == 0x19
	if String(worker_state.get("rom_sha256", "")) != ROM_SHA256 \
			or String(worker_state.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/slot09_eb8b_continuation/manifest.json" \
			or int(worker_state.get("entry_pc", -1)) != expected_entry_pc \
			or not (early_scenario36_return or scenario36_post_event_vector or complete_scenario35_prefix) \
			or int(mapper.get("select", -1)) != 7 \
			or source_ram.size() != RAM_SIZE or source_stack.size() != STACK_PAGE_SIZE \
			or not bool(worker_state.get("scenario_active", false)) \
			or scenario_id not in [0x35, 0x36] \
			or int(seed.get("event_selector_ram_0524", -1)) != 0x3A \
			or int(seed.get("wait_value_ram_0523", -1)) != expected_wait_value \
			or int(seed.get("actor_selector_ram_0528", -1)) != 0x8F \
			or int(seed.get("actor_parameter_ram_0529", -1)) != expected_actor_parameter \
			or int(seed.get("task_slot_base", -1)) != 0x15 \
			or int(source_ram[0x0516]) != 0x41 or int(source_ram[0x0518]) != scenario_id \
			or int(source_ram[0x0519]) != 0 \
			or int(source_ram[0x0523]) != expected_wait_value or int(source_ram[0x0524]) != 0x3A \
			or int(source_ram[0x0528]) != 0x8F or int(source_ram[0x0529]) != expected_actor_parameter \
			or source_ram.slice(0x0015, 0x0018) != PackedByteArray([0xFF, 0xF0, 0x0B]) \
			or int(source_ram[0x0018]) != int(_ram[0x0018]) \
			or source_stack[0xF1] != 0x08 or source_stack[0xF2] != 0x80:
		return _fail("Scenario active output mismatch: id=$%02X flag=$%02X wait=$%02X/$%02X actor=$%02X/$%02X task=%s stack=%s exit=$%04X mapper=$%02X/$%02X." % [
			scenario_id, int(source_ram[0x0516]), int(seed.get("wait_value_ram_0523", -1)),
			int(source_ram[0x0523]), int(seed.get("actor_parameter_ram_0529", -1)),
			int(source_ram[0x0529]), source_ram.slice(0x0015, 0x0019).hex_encode(),
			source_stack.slice(0xF1, 0xF3).hex_encode(), int(worker_state.get("exit_pc", -1)),
			int(mapper.get("bank_low", -1)), int(mapper.get("bank_high", -1))])
	var expected_ram := _ram.duplicate()
	var expected_stack := _stack_page.duplicate()
	for write_variant in writes_variant:
		if not write_variant is Dictionary:
			return _fail("Scenario-active write stream contains a malformed event.")
		var write: Dictionary = write_variant
		var address := int(write.get("address", -1))
		var value := int(write.get("value", -1))
		var allowed_slot15_store := (address == 0x0015 and value == 0xFF and int(write.get("pc", -1)) == 0xCAF4) \
				or (address == 0x0016 and value == 0xF0 and int(write.get("pc", -1)) == 0x809B) \
				or (address == 0x0017 and value == 0x0B and int(write.get("pc", -1)) == 0x809F)
		if address < 0 or address >= RAM_SIZE or value < 0 or value > 0xFF \
				or (_is_scheduler_owned_ram_address(address) and not allowed_slot15_store):
			return _fail("Scenario-active write conflicts with scheduler-owned RAM `$%04X`." % address)
		expected_ram[address] = value
		if address >= 0x0100 and address < 0x0200:
			expected_stack[address & 0xFF] = value
	for write_variant in stack_writes_variant:
		if not write_variant is Dictionary:
			return _fail("Scenario-active stack write stream contains a malformed event.")
		var write: Dictionary = write_variant
		var address := int(write.get("address", -1))
		var value := int(write.get("value", -1))
		if address < 0x0100 or address >= 0x0200 or value < 0 or value > 0xFF:
			return _fail("Scenario-active stack write is outside the CPU stack page.")
		expected_ram[address] = value
		expected_stack[address & 0xFF] = value
	if expected_ram != source_ram or expected_stack != source_stack:
		return _fail("Scenario-active RAM/stack differs from replaying its ordered ROM-source writes.")
	_ram = expected_ram
	_stack_page = expected_stack
	context.accumulator = int(registers.get("a", -1))
	context.x_register = int(registers.get("x", -1))
	context.y_register = int(registers.get("y", -1))
	context.stack_pointer = int(registers.get("sp", -1))
	if early_scenario36_return or scenario36_post_event_vector:
		context.program_counter = int(registers.get("pc", -1))
	context.bank_low = int(mapper.get("bank_low", -1))
	context.bank_high = int(mapper.get("bank_high", -1))
	context.source_label = "ROM-byte slot-$09 scenario-$%02X reader and slot-$15 seed" % scenario_id
	return true


## Replays the ROM-owned slot-$09 wait, scenario-root termination, and finish
## helper before the regular bank-$18 worker. The only scheduler-record write
## accepted here is `$CB0A` incrementing slot-$05's ready delay.
func adopt_slot09_scenario_wait_worker_state(worker_state: Dictionary) -> bool:
	if not _require_initialized():
		return false
	var context: TaskContext = _contexts.get(0x09)
	if _active_task_slot != 0x09 or context == null \
			or context.phase != ContextPhase.RUNNING or context.program_counter != 0xEB8B:
		return _fail("Scenario wait adoption requires the live dispatched slot-$09 `$EB8B` task.")
	var entry_variant: Variant = worker_state.get("entry_registers", {})
	var registers_variant: Variant = worker_state.get("registers", {})
	var mapper_variant: Variant = worker_state.get("mapper", {})
	var ram_variant: Variant = worker_state.get("ram_image", PackedByteArray())
	var stack_variant: Variant = worker_state.get("stack_page", PackedByteArray())
	var writes_variant: Variant = worker_state.get("writes", [])
	var stack_writes_variant: Variant = worker_state.get("stack_writes", [])
	var mapper_writes_variant: Variant = worker_state.get("mapper_writes", [])
	var hashes_variant: Variant = worker_state.get("source_span_hashes", {})
	if not entry_variant is Dictionary or not registers_variant is Dictionary \
			or not mapper_variant is Dictionary or not ram_variant is PackedByteArray \
			or not stack_variant is PackedByteArray or not writes_variant is Array \
			or not stack_writes_variant is Array or not mapper_writes_variant is Array \
			or not hashes_variant is Dictionary:
		return _fail("Scenario wait result omits source CPU, mapper, memory, or ordered writes.")
	var entry: Dictionary = entry_variant
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var source_ram: PackedByteArray = ram_variant
	var source_stack: PackedByteArray = stack_variant
	var hashes: Dictionary = hashes_variant
	var route_executed := bool(worker_state.get("scenario_route_state_executed", false))
	var wait_executed := bool(worker_state.get("scenario_wait_worker_executed", false))
	var entry_flag := int(_ram[0x0516])
	var entry_wait := int(_ram[0x0519])
	var first_root_termination := wait_executed and entry_flag == 0x01 and entry_wait == 0x02
	var continued_countdown := wait_executed and entry_flag == 0x29 and entry_wait == 0x01
	var terminal_idle := not wait_executed and entry_flag == 0x29 and entry_wait == 0x00
	var expected_scenario_cursor := int(_ram[0x003A]) \
		if continued_countdown or terminal_idle else 0x01
	if String(worker_state.get("rom_sha256", "")) != ROM_SHA256 \
			or String(worker_state.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/slot09_eb8b_continuation/manifest.json" \
			or String(worker_state.get("status", "")) != "stopped_before_worker_body" \
			or int(worker_state.get("entry_pc", -1)) != 0xEB8B \
			or int(worker_state.get("exit_pc", -1)) != 0x86F8 \
			or not route_executed or not (first_root_termination or continued_countdown or terminal_idle) \
			or bool(worker_state.get("scenario_active", true)) \
			or bool(worker_state.get("trace_state_used", true)) \
			or bool(worker_state.get("worker_body_executed", true)) \
			or source_ram.size() != RAM_SIZE or source_stack.size() != STACK_PAGE_SIZE \
			or int(entry.get("pc", -1)) != 0xEB8B or int(entry.get("sp", -1)) != 0x7A \
			or int(mapper.get("bank_low", -1)) != 0x18 \
			or int(mapper.get("bank_high", -1)) != 0x19 \
			or int(mapper.get("select", -1)) != 7 \
			or int(source_ram[0x0000]) != 0x09 \
			or int(source_ram[0x0516]) != 0x29 \
			or int(source_ram[0x0518]) != 0x35 \
			or int(source_ram[0x0519]) != maxi(0, entry_wait - 1) \
			or int(source_ram[0x0522]) != 0x00 \
			or (int(source_ram[0x005D]) | (int(source_ram[0x005E]) << 8)) != 0xB7D4 \
			or int(source_ram[0x003A]) != expected_scenario_cursor:
		return _fail("Scenario continuation output differs from the source wait/FB terminal phase selected by live RAM.")
	if terminal_idle and source_ram.slice(0x0532, 0x053A) != PackedByteArray([0, 0, 0, 0, 0, 0, 0, 0]):
		return _fail("The zero-count `$EC3C` terminal-phase path did not clear its source-owned scratch bytes.")
	if not _slot09_registers_match_context(entry, context, 0xEB8B) \
			or int(registers.get("pc", -1)) != 0x86F8 \
			or int(registers.get("sp", -1)) != 0x78:
		return _fail("Scenario wait entry/exit CPU state does not match the live slot-$09 route boundary.")
	if not _validate_slot09_source_manifest_hashes(
			String(worker_state["source_manifest"]), hashes):
		return false
	var expected_ram := _ram.duplicate()
	var expected_stack := _stack_page.duplicate()
	for write_variant in writes_variant:
		if not write_variant is Dictionary:
			return _fail("Scenario wait RAM write stream contains a malformed event.")
		var write: Dictionary = write_variant
		var address := int(write.get("address", -1))
		var value := int(write.get("value", -1))
		var source_slot05_delay := address == 0x0005 and value == ((int(expected_ram[0x0005]) + 1) & 0xFF) \
				and int(write.get("pc", -1)) == 0xCB0A
		if address < 0 or address >= RAM_SIZE or value < 0 or value > 0xFF \
				or (_is_scheduler_owned_ram_address(address) and not source_slot05_delay):
			return _fail("Scenario wait source write conflicts with scheduler-owned RAM `$%04X` at `$%04X`." % [address, int(write.get("pc", -1))])
		expected_ram[address] = value
		if address >= 0x0100 and address < 0x0200:
			expected_stack[address & 0xFF] = value
	for write_variant in stack_writes_variant:
		if not write_variant is Dictionary:
			return _fail("Scenario wait stack write stream contains a malformed event.")
		var write: Dictionary = write_variant
		var address := int(write.get("address", -1))
		var value := int(write.get("value", -1))
		if address < 0x0100 or address >= 0x0200 or value < 0 or value > 0xFF:
			return _fail("Scenario wait stack write is outside the CPU stack page.")
		expected_ram[address] = value
		expected_stack[address & 0xFF] = value
	if expected_ram != source_ram or expected_stack != source_stack:
		return _fail("Scenario wait RAM/stack differs from replaying the ordered ROM-source writes.")
	var mapper_result := _replay_actor_source_mapper_writes(mapper_writes_variant,
			context.bank_low, context.bank_high, mapper,
			int(context.mapper_state.get("select", -1)))
	if not bool(mapper_result.get("ok", false)):
		return _fail(String(mapper_result.get("reason", "Scenario wait mapper replay failed.")))
	for slot_base: int in SLOT_BASES:
		if slot_base != 0x05 and source_ram.slice(slot_base, slot_base + 4) != _record_bytes(slot_base):
			return _fail("Scenario wait source changed unrelated scheduler task record `$%02X`." % slot_base)
	if source_ram.slice(0x0006, 0x0009) != _record_bytes(0x05).slice(1, 4):
		return _fail("Scenario finish helper changed slot-$05 task fields beyond its source delay byte.")
	_ram = expected_ram
	_stack_page = expected_stack
	context.accumulator = int(registers.get("a", -1)) & 0xFF
	context.x_register = int(registers.get("x", -1)) & 0xFF
	context.y_register = int(registers.get("y", -1)) & 0xFF
	context.status_register = int(registers.get("p", context.status_register)) & 0xFF
	context.status_known_mask = int(registers.get("p_known_mask", context.status_known_mask)) & 0xFF
	context.stack_pointer = int(registers.get("sp", -1))
	context.bank_low = int(mapper["bank_low"])
	context.bank_high = int(mapper["bank_high"])
	context.mapper_state = mapper.duplicate(true)
	context.ready_delay = int(_ram[0x0009])
	var slot05: TaskContext = _contexts.get(0x05)
	if slot05 != null:
		slot05.ready_delay = int(_ram[0x0005])
	context.source_label = "ROM-byte slot-$09 wait and `$FB->$80CF` scenario termination"
	return true


## Adopts a bounded source executor's return from the two verified slot-$01
## callees. Replays its ordered RAM writes instead of trusting/copying a whole
## foreign RAM image, preserving scheduler-owned task records and latches.
func adopt_root_slot01_callee_return_state(source_pc: int, target_cpu_address: int,
		callee_result: Dictionary) -> bool:
	if not _require_initialized():
		return false
	var call_contracts := {
		0xCA52: {"target": 0xEE9F, "return_pc": 0xCA55},
		0xCA55: {"target": 0xE3CA, "return_pc": 0xCA58},
	}
	if not call_contracts.has(source_pc):
		return _fail("Root slot-$01 callee adoption was requested from an unsupported caller PC.")
	var contract: Dictionary = call_contracts[source_pc]
	var context: TaskContext = _contexts.get(0x01)
	if _active_task_slot != 0x01 or context == null or context.phase != ContextPhase.RUNNING \
			or context.program_counter != source_pc or target_cpu_address != int(contract["target"]):
		return _fail("Callee return must match the active source slot-$01 caller boundary.")
	if String(callee_result.get("rom_sha256", "")) != "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097" \
			or String(callee_result.get("status", "")) != "returned_to_source_caller" \
			or not bool(callee_result.get("returned_to_caller", false)):
		return _fail("Callee result is not a successful bounded return for this ROM.")
	var entry_variant: Variant = callee_result.get("entry", {})
	var registers_variant: Variant = callee_result.get("registers", {})
	var mapper_variant: Variant = callee_result.get("mapper", {})
	var ram_variant: Variant = callee_result.get("ram_image", PackedByteArray())
	var stack_variant: Variant = callee_result.get("stack_page", PackedByteArray())
	var writes_variant: Variant = callee_result.get("memory_writes", [])
	if not entry_variant is Dictionary or not registers_variant is Dictionary \
			or not mapper_variant is Dictionary or not ram_variant is PackedByteArray \
			or not stack_variant is PackedByteArray or not writes_variant is Array:
		return _fail("Callee result omits its source call, CPU, mapper, RAM, stack, or ordered writes.")
	var entry: Dictionary = entry_variant
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var result_ram: PackedByteArray = ram_variant
	var result_stack: PackedByteArray = stack_variant
	var writes: Array = writes_variant
	if int(entry.get("slot_base", -1)) != 0x01 \
			or int(entry.get("call_pc", -1)) != source_pc \
			or int(entry.get("target_pc", -1)) != target_cpu_address \
			or int(entry.get("expected_return_pc", -1)) != int(contract["return_pc"]) \
			or int(registers.get("pc", -1)) != int(contract["return_pc"]) \
			or result_ram.size() != RAM_SIZE or result_stack.size() != STACK_PAGE_SIZE \
			or int(mapper.get("task_bank_low", -1)) != int(registers.get("bank_low", -2)) \
			or int(mapper.get("task_bank_high", -1)) != int(registers.get("bank_high", -2)):
		return _fail("Callee return does not match the caller PC, task-bank pair, or byte-array sizes.")
	for name: String in ["a", "x", "y", "sp", "bank_low", "bank_high"]:
		var value := int(registers.get(name, -1))
		if value < 0 or value > 0xFF:
			return _fail("Callee return has an invalid 6502/task register `%s`." % name)
	if int(registers["sp"]) != context.stack_pointer:
		return _fail("Callee RTS did not restore the task's incoming stack pointer.")
	var expected_ram := _ram.duplicate()
	var expected_stack := _stack_page.duplicate()
	for write_variant in writes:
		if not write_variant is Dictionary:
			return _fail("Callee ordered write stream contains a malformed event.")
		var write: Dictionary = write_variant
		var space := String(write.get("space", ""))
		var address := int(write.get("address", -1))
		var value := int(write.get("value", -1))
		if value < 0 or value > 0xFF:
			return _fail("Callee ordered write stream contains a non-byte value.")
		if space == "cpu_ram":
			if address < 0 or address >= RAM_SIZE or _is_scheduler_owned_ram_address(address):
				return _fail("Callee write touches invalid or scheduler-owned RAM `$%04X`." % address)
			expected_ram[address] = value
			if address >= 0x0100 and address < 0x0200:
				expected_stack[address & 0xFF] = value
		elif space == "mmc3":
			if address != 0x8000 and address != 0x8001:
				return _fail("Callee mapper write is outside the verified MMC3 register window.")
		else:
			return _fail("Callee ordered write stream contains an unsupported address space.")
	if expected_ram != result_ram or expected_stack != result_stack:
		return _fail("Callee RAM/stack image does not equal replaying its ordered writes over live scheduler state.")
	for index in range(STACK_PAGE_SIZE):
		if result_ram[0x0100 + index] != result_stack[index]:
			return _fail("Callee returned RAM and stack mirrors disagree at `$%04X`." % (0x0100 + index))
	_ram = expected_ram
	_stack_page = expected_stack
	context.accumulator = int(registers["a"])
	context.x_register = int(registers["x"])
	context.y_register = int(registers["y"])
	context.stack_pointer = int(registers["sp"])
	context.program_counter = int(contract["return_pc"])
	context.bank_low = int(registers["bank_low"])
	context.bank_high = int(registers["bank_high"])
	context.source_label = "ROM-byte slot-$01 callee return `$%04X->$%04X`" % [source_pc, target_cpu_address]
	return true


## Adopts the real `$CBC1 RTS->$D11E` return from slot-$05's scenario-$35
## yield. It accepts no RAM writes and changes only the active CPU continuation.
func adopt_slot05_scenario35_return_state(dispatch: Dictionary, boundary: Dictionary,
		return_result: Dictionary) -> bool:
	if not _require_initialized():
		return false
	var context: TaskContext = _contexts.get(0x05)
	var entry: Dictionary = return_result.get("entry", {})
	var registers: Dictionary = return_result.get("registers", {})
	var mapper: Dictionary = return_result.get("mapper", {})
	var result_ram: Variant = return_result.get("ram_image", PackedByteArray())
	var result_stack: Variant = return_result.get("stack_page", PackedByteArray())
	var live_ram: Variant = boundary.get("ram_image", PackedByteArray())
	var live_stack: Variant = boundary.get("stack_page", PackedByteArray())
	if _active_task_slot != 0x05 or context == null \
			or context.phase != ContextPhase.RUNNING or context.program_counter != 0xCBC1 \
			or int(dispatch.get("slot_base", -1)) != 0x05 \
			or int(dispatch.get("pc", -1)) != 0xCBC1 \
			or int(dispatch.get("sp", -1)) != 0x4E \
			or int(boundary.get("active_task_slot", -1)) != 0x05 \
			or int(boundary.get("pc", -1)) != 0xCBC1 \
			or context.source_return_word != 0xD11D \
			or String(return_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(return_result.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/scenario_task_runtime/manifest.json" \
			or String(return_result.get("status", "")) != "returned_to_source_caller" \
			or not bool(return_result.get("returned_to_caller", false)) \
			or not entry is Dictionary or int(entry.get("call_pc", -1)) != 0xCBC1 \
			or int(entry.get("expected_return_pc", -1)) != 0xDADD \
			or not registers is Dictionary or int(registers.get("pc", -1)) != 0xDADD \
			or int(registers.get("sp", -1)) != 0x50 \
			or not mapper is Dictionary or int(mapper.get("bank_low", -1)) != 0x1C \
			or int(mapper.get("bank_high", -1)) != 0x1D \
			or not live_ram is PackedByteArray or live_ram.size() != RAM_SIZE \
			or not live_stack is PackedByteArray or live_stack.size() != STACK_PAGE_SIZE \
			or not result_ram is PackedByteArray or result_ram != live_ram \
			or not result_stack is PackedByteArray or result_stack != live_stack \
			or return_result.get("memory_writes", []) != []:
		return _fail("Slot-$05 scenario return does not match the live `$CBC1->$D11E` CPU/stack boundary.")
	context.accumulator = int(registers["a"]) & 0xFF
	context.x_register = int(registers["x"]) & 0xFF
	context.y_register = int(registers["y"]) & 0xFF
	context.status_register = int(registers.get("p", context.status_register)) & 0xFF
	context.status_known_mask = int(registers.get("p_known_mask", context.status_known_mask)) & 0xFF
	context.program_counter = 0xDADD
	context.stack_pointer = 0x50
	context.source_label = "ROM-byte slot-$05 scenario return `$CBC1 RTS->$DADD`"
	return true


## Adopts the ROM's `LDA #$01` before the scenario wait caller invokes `$CB0F`.
## The scheduler performs the JSR/save itself so its stack frame is written once.
func adopt_slot05_scenario35_wait_callsite_state(return_result: Dictionary,
		caller_result: Dictionary) -> bool:
	if not _require_initialized():
		return false
	var context: TaskContext = _contexts.get(0x05)
	var registers: Dictionary = caller_result.get("registers", {})
	var mapper: Dictionary = caller_result.get("mapper", {})
	var caller_ram: Variant = caller_result.get("ram_image", PackedByteArray())
	var caller_stack: Variant = caller_result.get("stack_page", PackedByteArray())
	var live_ram: Variant = return_result.get("ram_image", PackedByteArray())
	var live_stack: Variant = return_result.get("stack_page", PackedByteArray())
	var instructions: Array = caller_result.get("instructions", [])
	if _active_task_slot != 0x05 or context == null or context.phase != ContextPhase.RUNNING \
			or context.program_counter != 0xDADD \
			or context.source_label != "ROM-byte slot-$05 scenario return `$CBC1 RTS->$DADD`" \
			or not bool(caller_result.get("ok", false)) \
			or String(caller_result.get("status", "")) != "scenario35_wait_yield_callsite_ready" \
			or String(caller_result.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/fresh_daaa_continuation/manifest.json" \
			or int(caller_result.get("entry_pc", -1)) != 0xDADD \
			or int(caller_result.get("exit_pc", -1)) != 0xDADF \
			or int(caller_result.get("exit_sp", -1)) != context.stack_pointer \
			or int(registers.get("a", -1)) != 0x01 \
			or int(registers.get("pc", -1)) != 0xDADF \
			or int(registers.get("sp", -1)) != context.stack_pointer \
			or int(mapper.get("bank_low", -1)) != context.bank_low \
			or int(mapper.get("bank_high", -1)) != context.bank_high \
			or not caller_ram is PackedByteArray or caller_ram != live_ram \
			or not caller_stack is PackedByteArray or caller_stack != live_stack \
			or not live_ram is PackedByteArray or live_ram.size() != RAM_SIZE \
			or not live_stack is PackedByteArray or live_stack.size() != STACK_PAGE_SIZE \
			or caller_result.get("writes", []) != [] \
			or caller_result.get("mapper_writes", []) != [] \
			or instructions.size() != 1 or not instructions[0] is Dictionary \
			or int(instructions[0].get("pc", -1)) != 0xDADD \
			or int(instructions[0].get("opcode", -1)) != 0xA9 \
			or int(instructions[0].get("next_pc", -1)) != 0xDADF:
		return _fail("Slot-$05 wait callsite must be the source-executed `$DADD LDA #$01` over unchanged live RAM/stack.")
	context.accumulator = int(registers["a"]) & 0xFF
	context.x_register = int(registers.get("x", context.x_register)) & 0xFF
	context.y_register = int(registers.get("y", context.y_register)) & 0xFF
	context.status_register = int(registers.get("p", context.status_register)) & 0xFF
	context.status_known_mask = int(registers.get("p_known_mask", context.status_known_mask)) & 0xFF
	context.program_counter = 0xDADF
	context.source_label = "ROM-byte slot-$05 scenario wait `$DADD->$DADF`"
	return true


## Adopts the ROM-executed `$DAE2` status test when it branches back to the
## `$DADF` scheduler callsite. A set status bit is not accepted here.
func adopt_slot05_scenario35_wait_resume_state(dispatch: Dictionary,
		boundary: Dictionary, caller_result: Dictionary) -> bool:
	if not _require_initialized():
		return false
	var context: TaskContext = _contexts.get(0x05)
	var registers: Dictionary = caller_result.get("registers", {})
	var mapper: Dictionary = caller_result.get("mapper", {})
	var caller_ram: Variant = caller_result.get("ram_image", PackedByteArray())
	var caller_stack: Variant = caller_result.get("stack_page", PackedByteArray())
	var live_ram: Variant = boundary.get("ram_image", PackedByteArray())
	var live_stack: Variant = boundary.get("stack_page", PackedByteArray())
	var instructions: Array = caller_result.get("instructions", [])
	var expected_pcs := [0xDAE2, 0xDAE5, 0xDAE7, 0xDADD]
	var expected_opcodes := [0xAD, 0x29, 0xF0, 0xA9]
	var expected_next_pcs := [0xDAE5, 0xDAE7, 0xDADD, 0xDADF]
	var source_sequence_matches := instructions.size() == 4
	if source_sequence_matches:
		for index in range(4):
			if not instructions[index] is Dictionary \
					or int(instructions[index].get("pc", -1)) != expected_pcs[index] \
					or int(instructions[index].get("opcode", -1)) != expected_opcodes[index] \
					or int(instructions[index].get("next_pc", -1)) != expected_next_pcs[index]:
				source_sequence_matches = false
				break
	if _active_task_slot != 0x05 or context == null or context.phase != ContextPhase.RUNNING \
			or context.program_counter != 0xDAE2 \
			or int(dispatch.get("slot_base", -1)) != 0x05 \
			or int(dispatch.get("pc", -1)) != 0xDAE2 \
			or not bool(caller_result.get("ok", false)) \
			or String(caller_result.get("status", "")) != "scenario35_wait_yield_callsite_ready" \
			or int(caller_result.get("entry_pc", -1)) != 0xDAE2 \
			or int(caller_result.get("exit_pc", -1)) != 0xDADF \
			or int(caller_result.get("exit_sp", -1)) != context.stack_pointer \
			or int(caller_result.get("wait_flags", -1)) != 0 \
			or String(caller_result.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/fresh_daaa_continuation/manifest.json" \
			or int(registers.get("a", -1)) != 0x01 \
			or int(registers.get("pc", -1)) != 0xDADF \
			or int(registers.get("sp", -1)) != context.stack_pointer \
			or int(mapper.get("bank_low", -1)) != context.bank_low \
			or int(mapper.get("bank_high", -1)) != context.bank_high \
			or not caller_ram is PackedByteArray or caller_ram != live_ram \
			or not caller_stack is PackedByteArray or caller_stack != live_stack \
			or caller_result.get("writes", []) != [] \
			or caller_result.get("mapper_writes", []) != [] \
			or not source_sequence_matches:
		return _fail("Slot-$05 wait resume must source-test `$001C & $C0 == 0` and return to `$DADF` without changing RAM/stack.")
	context.accumulator = int(registers["a"]) & 0xFF
	context.x_register = int(registers.get("x", context.x_register)) & 0xFF
	context.y_register = int(registers.get("y", context.y_register)) & 0xFF
	context.status_register = int(registers.get("p", context.status_register)) & 0xFF
	context.status_known_mask = int(registers.get("p_known_mask", context.status_known_mask)) & 0xFF
	context.program_counter = 0xDADF
	context.source_label = "ROM-byte slot-$05 scenario wait `$DAE2->$DADF`"
	return true


## Adopts the source-executed A/B exit through `$DAEF STA $0441`, stopping at
## the caller's `$DAF2 JSR $DC07` boundary. The position initializer remains a
## separate ROM-owned callee.
func adopt_slot05_scenario35_input_call_state(dispatch: Dictionary,
		boundary: Dictionary, caller_result: Dictionary) -> bool:
	if not _require_initialized():
		return false
	var context: TaskContext = _contexts.get(0x05)
	var registers: Dictionary = caller_result.get("registers", {})
	var mapper: Dictionary = caller_result.get("mapper", {})
	var caller_ram: Variant = caller_result.get("ram_image", PackedByteArray())
	var caller_stack: Variant = caller_result.get("stack_page", PackedByteArray())
	var live_ram: Variant = boundary.get("ram_image", PackedByteArray())
	var live_stack: Variant = boundary.get("stack_page", PackedByteArray())
	var instructions: Array = caller_result.get("instructions", [])
	var call_request: Dictionary = caller_result.get("position_initializer_call_request", {})
	if not live_ram is PackedByteArray or live_ram.size() != RAM_SIZE:
		return _fail("The `$DAE2` input branch requires a full source-owned RAM boundary.")
	var holder_slot := (int(live_ram[0x05FB]) + 8) & 0xFF
	var expected_ram: PackedByteArray = live_ram.duplicate()
	expected_ram[0x0441] = holder_slot
	var source_sequence_matches := instructions.size() == 7
	var expected_pcs := [0xDAE2, 0xDAE5, 0xDAE7, 0xDAE9, 0xDAEC, 0xDAED, 0xDAEF]
	var expected_opcodes := [0xAD, 0x29, 0xF0, 0xAD, 0x18, 0x69, 0x8D]
	var expected_next_pcs := [0xDAE5, 0xDAE7, 0xDAE9, 0xDAEC, 0xDAED, 0xDAEF, 0xDAF2]
	if source_sequence_matches:
		for index in range(expected_pcs.size()):
			if not instructions[index] is Dictionary \
					or int(instructions[index].get("pc", -1)) != expected_pcs[index] \
					or int(instructions[index].get("opcode", -1)) != expected_opcodes[index] \
					or int(instructions[index].get("next_pc", -1)) != expected_next_pcs[index]:
				source_sequence_matches = false
				break
	var writes: Array = caller_result.get("writes", [])
	if _active_task_slot != 0x05 or context == null \
			or context.phase != ContextPhase.RUNNING or context.program_counter != 0xDAE2 \
			or int(dispatch.get("slot_base", -1)) != 0x05 \
			or int(dispatch.get("pc", -1)) != 0xDAE2 \
			or not bool(caller_result.get("ok", false)) \
			or String(caller_result.get("status", "")) != "scenario35_input_exit_dc07_callsite_ready" \
			or String(caller_result.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/fresh_daaa_continuation/manifest.json" \
			or int(caller_result.get("entry_pc", -1)) != 0xDAE2 \
			or int(caller_result.get("exit_pc", -1)) != 0xDAF2 \
			or int(registers.get("pc", -1)) != 0xDAF2 \
			or int(registers.get("sp", -1)) != context.stack_pointer \
			or int(mapper.get("bank_low", -1)) != context.bank_low \
			or int(mapper.get("bank_high", -1)) != context.bank_high \
			or int(caller_result.get("wait_flags", 0)) == 0 \
			or int(caller_result.get("ball_holder_slot_0441", -1)) != holder_slot \
			or not source_sequence_matches \
			or not caller_ram is PackedByteArray or caller_ram != expected_ram \
			or not live_stack is PackedByteArray or not caller_stack is PackedByteArray \
			or caller_stack != live_stack or caller_stack != caller_ram.slice(0x0100, 0x0200) \
			or writes.size() != 1 or not writes[0] is Dictionary \
			or int(writes[0].get("pc", -1)) != 0xDAEF \
			or int(writes[0].get("address", -1)) != 0x0441 \
			or int(writes[0].get("value", -1)) != holder_slot \
			or String(call_request.get("kind", "")) != "rom_jsr_request" \
			or int(call_request.get("source_pc", -1)) != 0xDAF2 \
			or int(call_request.get("target_pc", -1)) != 0xDC07 \
			or int(call_request.get("return_pc", -1)) != 0xDAF5 \
			or call_request.get("source_bytes", PackedByteArray()) != PackedByteArray([0x20, 0x07, 0xDC]):
		return _fail("Slot-$05 A/B input path did not reproduce the ROM `$DAE2->$DAF2->$DC07` call boundary.")
	_ram = caller_ram.duplicate()
	_stack_page = caller_stack.duplicate()
	context.accumulator = int(registers.get("a", context.accumulator)) & 0xFF
	context.x_register = int(registers.get("x", context.x_register)) & 0xFF
	context.y_register = int(registers.get("y", context.y_register)) & 0xFF
	context.status_register = int(registers.get("p", context.status_register)) & 0xFF
	context.status_known_mask = int(registers.get("p_known_mask", context.status_known_mask)) & 0xFF
	context.program_counter = 0xDAF2
	context.source_label = "ROM-byte slot-$05 A/B wait exit `$DAE2->$DAF2`"
	return true


## Adopts the source-derived `$DC07` player-position callee from its live
## `$DAF2` request and verifies ordered RAM/stack effects through `$DAF5`.
func adopt_slot05_dc07_position_initializer_result(boundary: Dictionary,
		initializer_result: Dictionary) -> bool:
	if not _require_initialized():
		return false
	var context: TaskContext = _contexts.get(0x05)
	var entry_variant: Variant = initializer_result.get("entry", {})
	var registers_variant: Variant = initializer_result.get("registers", {})
	var source_ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
	var source_stack_variant: Variant = boundary.get("stack_page", PackedByteArray())
	var result_ram_variant: Variant = initializer_result.get("ram_image", PackedByteArray())
	var result_stack_variant: Variant = initializer_result.get("stack_page", PackedByteArray())
	var writes_variant: Variant = initializer_result.get("memory_writes", [])
	var stack_writes_variant: Variant = initializer_result.get("stack_writes", [])
	var positions_variant: Variant = initializer_result.get("positions", [])
	if _active_task_slot != 0x05 or context == null \
			or context.phase != ContextPhase.RUNNING or context.program_counter != 0xDAF2 \
			or context.stack_pointer != 0x50 or context.bank_low != 0x1C or context.bank_high != 0x1D \
			or int(boundary.get("active_task_slot", -1)) != 0x05 \
			or int(boundary.get("pc", -1)) != 0xDAF2 or int(boundary.get("sp", -1)) != 0x50 \
			or String(initializer_result.get("status", "")) != "returned_to_slot05_caller_DAF5" \
			or String(initializer_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(initializer_result.get("source_manifest", "")) != POSITION_INITIALIZER_MANIFEST_PATH \
			or String(initializer_result.get("source_manifest_sha256", "")) != POSITION_INITIALIZER_MANIFEST_SHA256 \
			or not bool(initializer_result.get("ok", false)) \
			or not entry_variant is Dictionary or not registers_variant is Dictionary \
			or not source_ram_variant is PackedByteArray or source_ram_variant.size() != RAM_SIZE \
			or not source_stack_variant is PackedByteArray or source_stack_variant.size() != STACK_PAGE_SIZE \
			or not result_ram_variant is PackedByteArray or result_ram_variant.size() != RAM_SIZE \
			or not result_stack_variant is PackedByteArray or result_stack_variant.size() != STACK_PAGE_SIZE \
			or not writes_variant is Array or not stack_writes_variant is Array \
			or not positions_variant is Array or positions_variant.size() != 22 \
			or source_ram_variant != _ram or source_stack_variant != _stack_page \
			or int(entry_variant.get("pc", -1)) != 0xDAF2 \
			or int(entry_variant.get("sp", -1)) != 0x50 \
			or int(entry_variant.get("return_word", -1)) != 0xDAF4 \
			or int(registers_variant.get("pc", -1)) != 0xDAF5 \
			or int(registers_variant.get("sp", -1)) != 0x50 \
			or int(registers_variant.get("a", -1)) != 0x16 \
			or int(registers_variant.get("y", -1)) != 0x06:
		return _fail("The `$DC07` result does not match the live slot-$05 `$DAF2` call or `$DAF5` return contract.")
	var expected_ram: PackedByteArray = (source_ram_variant as PackedByteArray).duplicate()
	for write_variant in writes_variant:
		if not write_variant is Dictionary:
			return _fail("The `$DC07` result contains a malformed RAM write.")
		var write: Dictionary = write_variant
		var address := int(write.get("address", -1))
		var value := int(write.get("value", -1))
		var pc := int(write.get("pc", -1))
		if address < 0 or address >= RAM_SIZE or value < 0 or value > 0xFF \
				or pc not in [0xDC0F, 0xDC16, 0xDC20, 0xDC27, 0xDC31, 0xDC40,
					0xCD81, 0xCD86, 0xDC61, 0xDC66, 0xDC74]:
			return _fail("The `$DC07` result contains an unapproved RAM write at `$%04X` from `$%04X`." % [address, pc])
		expected_ram[address] = value
	var expected_stack: PackedByteArray = (source_stack_variant as PackedByteArray).duplicate()
	for write_variant in stack_writes_variant:
		if not write_variant is Dictionary:
			return _fail("The `$DC07` result contains a malformed stack write.")
		var write: Dictionary = write_variant
		var address := int(write.get("address", -1))
		var value := int(write.get("value", -1))
		var pc := int(write.get("pc", -1))
		if address < 0x0100 or address >= 0x0200 or value < 0 or value > 0xFF \
				or pc not in [0xDAF2, 0xDC0B, 0xDC1C, 0xDC2B, 0xDC2C, 0xDC34, 0xDC4C, 0xDC69]:
			return _fail("The `$DC07` result contains an unapproved stack write at `$%04X` from `$%04X`." % [address, pc])
		expected_stack[address & 0xFF] = value
		expected_ram[address] = value
	if expected_ram != result_ram_variant:
		for address in RAM_SIZE:
			if expected_ram[address] != (result_ram_variant as PackedByteArray)[address]:
				return _fail("The `$DC07` ordered RAM/stack writes differ at `$%04X`: replay `$%02X`, result `$%02X`." % [
					address, expected_ram[address], (result_ram_variant as PackedByteArray)[address]])
		return _fail("The `$DC07` ordered RAM write list does not reproduce its returned RAM image.")
	if expected_stack != result_stack_variant \
			or result_ram_variant.slice(0x0100, 0x0200) != result_stack_variant:
		return _fail("The `$DC07` ordered stack write list does not reproduce its returned stack page.")
	var last_position: Dictionary = positions_variant[21]
	if int(registers_variant.get("x", -1)) != int(last_position.get("x", -2)) \
			or int(result_ram_variant[0x0034]) | (int(result_ram_variant[0x0035]) << 8) != 0x03FC \
			or int(result_ram_variant[0x0100 + 0x4E]) != 21 \
			or int(result_stack_variant[0x4F]) != 0xF4 or int(result_stack_variant[0x50]) != 0xDA:
		return _fail("The `$DC07` final pointer, last player register, or JSR stack bytes are inconsistent.")
	_ram = (result_ram_variant as PackedByteArray).duplicate()
	_stack_page = (result_stack_variant as PackedByteArray).duplicate()
	context.accumulator = int(registers_variant.get("a", -1)) & 0xFF
	context.x_register = int(registers_variant.get("x", -1)) & 0xFF
	context.y_register = int(registers_variant.get("y", -1)) & 0xFF
	context.status_register = int(registers_variant.get("p", context.status_register)) & 0xFF
	context.status_known_mask = int(registers_variant.get("p_known_mask", context.status_known_mask)) & 0xFF
	context.program_counter = 0xDAF5
	context.stack_pointer = 0x50
	context.source_label = "ROM-derived slot-$05 `$DC07` position initializer returns `$DAF5`"
	return true


## Adopts the ROM-byte `$DAF5-$DB0E` receiver calculation after the live
## `$DC07` return and stops at the `$E6EC` call entry.
func adopt_slot05_daf5_receiver_caller_result(boundary: Dictionary,
		receiver_result: Dictionary) -> bool:
	if not _require_initialized():
		return false
	var context: TaskContext = _contexts.get(0x05)
	var registers_variant: Variant = receiver_result.get("registers", {})
	var source_ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
	var source_stack_variant: Variant = boundary.get("stack_page", PackedByteArray())
	var result_ram_variant: Variant = receiver_result.get("ram_image", PackedByteArray())
	var result_stack_variant: Variant = receiver_result.get("stack_page", PackedByteArray())
	var writes_variant: Variant = receiver_result.get("memory_writes", [])
	var stack_writes_variant: Variant = receiver_result.get("stack_writes", [])
	var calls_variant: Variant = receiver_result.get("calls", [])
	if _active_task_slot != 0x05 or context == null \
			or context.phase != ContextPhase.RUNNING or context.program_counter != 0xDAF5 \
			or context.stack_pointer != 0x50 or context.bank_low != 0x1C or context.bank_high != 0x1D \
			or int(boundary.get("active_task_slot", -1)) != 0x05 \
			or int(boundary.get("pc", -1)) != 0xDAF5 or int(boundary.get("sp", -1)) != 0x50 \
			or not bool(receiver_result.get("ok", false)) \
			or String(receiver_result.get("status", "")) != "stopped_at_slot05_e6ec_holder_call_boundary" \
			or String(receiver_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(receiver_result.get("source_manifest", "")) != DAF5_RECEIVER_MANIFEST_PATH \
			or String(receiver_result.get("source_manifest_sha256", "")) != DAF5_RECEIVER_MANIFEST_SHA256 \
			or not registers_variant is Dictionary \
			or not source_ram_variant is PackedByteArray or source_ram_variant.size() != RAM_SIZE \
			or not source_stack_variant is PackedByteArray or source_stack_variant.size() != STACK_PAGE_SIZE \
			or not result_ram_variant is PackedByteArray or result_ram_variant.size() != RAM_SIZE \
			or not result_stack_variant is PackedByteArray or result_stack_variant.size() != STACK_PAGE_SIZE \
			or not writes_variant is Array or writes_variant.size() != 1 \
			or not stack_writes_variant is Array or stack_writes_variant.size() != 2 \
			or not calls_variant is Array or calls_variant.size() != 1 \
			or source_ram_variant != _ram or source_stack_variant != _stack_page:
		return _fail("The receiver-caller result does not match the live slot-$05 `$DAF5` boundary.")
	var expected_ram: PackedByteArray = (source_ram_variant as PackedByteArray).duplicate()
	var write_variant: Variant = writes_variant[0]
	if not write_variant is Dictionary:
		return _fail("The receiver caller returned a malformed `$05FC` write.")
	var write: Dictionary = write_variant
	var receiver_slot := int(receiver_result.get("entry", {}).get("receiver_slot", -1))
	if int(write.get("pc", -1)) != 0xDB08 or int(write.get("address", -1)) != 0x05FC \
			or int(write.get("value", -1)) != receiver_slot or receiver_slot < 0 or receiver_slot > 0xFF:
		return _fail("The receiver caller did not perform its source `$DB08 STA $05FC` write.")
	expected_ram[0x05FC] = receiver_slot
	var expected_stack: PackedByteArray = (source_stack_variant as PackedByteArray).duplicate()
	for stack_write_variant in stack_writes_variant:
		if not stack_write_variant is Dictionary:
			return _fail("The receiver caller returned a malformed JSR stack write.")
		var stack_write: Dictionary = stack_write_variant
		var address := int(stack_write.get("address", -1))
		var value := int(stack_write.get("value", -1))
		if int(stack_write.get("pc", -1)) != 0xDB0B or address not in [0x014F, 0x0150] \
				or value < 0 or value > 0xFF:
			return _fail("The receiver caller returned an unapproved `$DB0B JSR $E6EC` stack write.")
		expected_stack[address & 0xFF] = value
		expected_ram[address] = value
	var call: Dictionary = calls_variant[0]
	if expected_ram != result_ram_variant or expected_stack != result_stack_variant \
			or result_ram_variant.slice(0x0100, 0x0200) != result_stack_variant \
			or int(call.get("callsite", -1)) != 0xDB0B or int(call.get("target", -1)) != 0xE6EC \
			or int(call.get("return_word", -1)) != 0xDB0D or int(call.get("return_pc", -1)) != 0xDB0E \
			or int(call.get("sp_after_push", -1)) != 0x4E \
			or int(result_ram_variant[0x0150]) != 0xDB or int(result_ram_variant[0x014F]) != 0x0D:
		return _fail("The receiver caller's ordered RAM/stack writes or `$DB0B->$E6EC` call frame are inconsistent.")
	var registers: Dictionary = registers_variant
	if int(registers.get("pc", -1)) != 0xE6EC or int(registers.get("sp", -1)) != 0x4E \
			or int(registers.get("a", -1)) != receiver_slot \
			or int(result_ram_variant[0x05FC]) != receiver_slot:
		return _fail("The receiver caller did not stop at `$E6EC` with the live receiver in A and `$05FC`.")
	_ram = (result_ram_variant as PackedByteArray).duplicate()
	_stack_page = (result_stack_variant as PackedByteArray).duplicate()
	context.accumulator = int(registers["a"]) & 0xFF
	context.x_register = int(registers.get("x", context.x_register)) & 0xFF
	context.y_register = int(registers.get("y", context.y_register)) & 0xFF
	context.status_register = int(registers.get("p", context.status_register)) & 0xFF
	context.status_known_mask = int(registers.get("p_known_mask", context.status_known_mask)) & 0xFF
	context.program_counter = 0xE6EC
	context.stack_pointer = 0x4E
	context.source_label = "ROM-byte slot-$05 receiver caller `$DAF5->$DB0B JSR $E6EC`"
	return true


## Adopts the ROM-byte $E6EC/$CD7C/$CDE2 holder copy and leaves slot-$05 at
## $DB0E, immediately before the scenario-$36 caller instruction.
func adopt_slot05_e6ec_holder_copy_result(boundary: Dictionary,
		holder_result: Dictionary) -> bool:
	if not _require_initialized():
		return false
	var context: TaskContext = _contexts.get(0x05)
	var source_ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
	var source_stack_variant: Variant = boundary.get("stack_page", PackedByteArray())
	var result_ram_variant: Variant = holder_result.get("ram_image", PackedByteArray())
	var result_stack_variant: Variant = holder_result.get("stack_page", PackedByteArray())
	var registers_variant: Variant = holder_result.get("registers", {})
	var writes_variant: Variant = holder_result.get("memory_writes", [])
	var stack_writes_variant: Variant = holder_result.get("stack_writes", [])
	var calls_variant: Variant = holder_result.get("calls", [])
	if _active_task_slot != 0x05 or context == null \
			or context.phase != ContextPhase.RUNNING or context.program_counter != 0xE6EC \
			or context.stack_pointer != 0x4E or context.bank_low != 0x1C or context.bank_high != 0x1D \
			or int(boundary.get("active_task_slot", -1)) != 0x05 \
			or int(boundary.get("pc", -1)) != 0xE6EC or int(boundary.get("sp", -1)) != 0x4E \
			or not bool(holder_result.get("ok", false)) \
			or String(holder_result.get("status", "")) != "returned_to_slot05_db0e_before_scenario36" \
			or String(holder_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(holder_result.get("source_manifest", "")) != HOLDER_COPY_MANIFEST_PATH \
			or String(holder_result.get("source_manifest_sha256", "")) != HOLDER_COPY_MANIFEST_SHA256 \
			or not source_ram_variant is PackedByteArray or source_ram_variant.size() != RAM_SIZE \
			or not source_stack_variant is PackedByteArray or source_stack_variant.size() != STACK_PAGE_SIZE \
			or not result_ram_variant is PackedByteArray or result_ram_variant.size() != RAM_SIZE \
			or not result_stack_variant is PackedByteArray or result_stack_variant.size() != STACK_PAGE_SIZE \
			or not registers_variant is Dictionary \
			or not writes_variant is Array or writes_variant.size() != 5 \
			or not stack_writes_variant is Array or stack_writes_variant.size() != 4 \
			or not calls_variant is Array or calls_variant.size() != 2 \
			or source_ram_variant != _ram or source_stack_variant != _stack_page:
		return _fail("The $E6EC result does not match the live slot-$05 callee boundary.")
	var expected_ram: PackedByteArray = (source_ram_variant as PackedByteArray).duplicate()
	var expected_stack: PackedByteArray = (source_stack_variant as PackedByteArray).duplicate()
	var expected_write_pcs: Array[int] = [0xCD81, 0xCD86, 0xE6F6, 0xE6FE, 0xE705]
	var expected_write_addresses: Array[int] = [0x0034, 0x0035, 0x0635, 0x0637, 0x05FE]
	for index in range(writes_variant.size()):
		var write_variant: Variant = writes_variant[index]
		if not write_variant is Dictionary:
			return _fail("The $E6EC routine returned a malformed RAM write.")
		var write: Dictionary = write_variant
		var address := int(write.get("address", -1))
		var value := int(write.get("value", -1))
		if int(write.get("pc", -1)) != expected_write_pcs[index] \
				or address != expected_write_addresses[index] or value < 0 or value > 0xFF:
			return _fail("The $CD7C/$E6EC source-ordered RAM write list is inconsistent.")
		expected_ram[address] = value
	for stack_write_variant in stack_writes_variant:
		if not stack_write_variant is Dictionary:
			return _fail("The $E6EC routine returned a malformed nested JSR stack write.")
		var stack_write: Dictionary = stack_write_variant
		var address := int(stack_write.get("address", -1))
		var value := int(stack_write.get("value", -1))
		var pc := int(stack_write.get("pc", -1))
		if address not in [0x014D, 0x014E] or value < 0 or value > 0xFF \
				or pc not in [0xE6EF, 0xE702]:
			return _fail("The $E6EC nested calls returned an unapproved stack write.")
		expected_stack[address & 0xFF] = value
		expected_ram[address] = value
	var calls: Array = calls_variant
	if int(calls[0].get("callsite", -1)) != 0xE6EF \
			or int(calls[0].get("target", -1)) != 0xCD7C \
			or int(calls[0].get("return_word", -1)) != 0xE6F1 \
			or int(calls[0].get("return_pc", -1)) != 0xE6F2 \
			or int(calls[1].get("callsite", -1)) != 0xE702 \
			or int(calls[1].get("target", -1)) != 0xCDE2 \
			or int(calls[1].get("return_word", -1)) != 0xE704 \
			or int(calls[1].get("return_pc", -1)) != 0xE705 \
			or expected_ram != result_ram_variant or expected_stack != result_stack_variant \
			or result_ram_variant.slice(0x0100, 0x0200) != result_stack_variant:
		return _fail("The holder-copy RAM, stack, or nested ROM-call order is inconsistent.")
	var registers: Dictionary = registers_variant
	var holder: Dictionary = holder_result.get("holder_copy", {})
	if int(registers.get("pc", -1)) != 0xDB0E or int(registers.get("sp", -1)) != 0x50 \
			or int(result_ram_variant[0x05FE]) != int(holder.get("tile_index_05fe", -1)) \
			or int(result_ram_variant[0x0635]) != int(holder.get("x_0635", -1)) \
			or int(result_ram_variant[0x0637]) != int(holder.get("y_0637", -1)):
		return _fail("The holder-copy executor did not return to the pre-scenario-$36 caller boundary.")
	_ram = (result_ram_variant as PackedByteArray).duplicate()
	_stack_page = (result_stack_variant as PackedByteArray).duplicate()
	context.accumulator = int(registers.get("a", -1)) & 0xFF
	context.x_register = int(registers.get("x", -1)) & 0xFF
	context.y_register = int(registers.get("y", -1)) & 0xFF
	context.status_register = int(registers.get("p", context.status_register)) & 0xFF
	context.status_known_mask = int(registers.get("p_known_mask", context.status_known_mask)) & 0xFF
	context.program_counter = 0xDB0E
	context.stack_pointer = 0x50
	context.source_label = "ROM-byte slot-$05 $E6EC/$CD7C/$CDE2 holder copy returns before scenario $36"
	return true


## Adopts the source-executed fresh scenario-$36 caller and saves its existing
## `$CBBE->$CB0F` JSR frame through the scheduler's verified task-save handler.
func adopt_slot05_scenario36_queue_result(boundary: Dictionary,
		queue_result: Dictionary) -> bool:
	if not _require_initialized():
		return false
	var context: TaskContext = _contexts.get(0x05)
	var entry_ram: Variant = queue_result.get("entry_ram_image", PackedByteArray())
	var entry_stack: Variant = queue_result.get("entry_stack_page", PackedByteArray())
	var result_ram: Variant = queue_result.get("ram_image", PackedByteArray())
	var result_stack: Variant = queue_result.get("stack_page", PackedByteArray())
	var entry_registers: Variant = queue_result.get("entry_registers", {})
	var registers: Variant = queue_result.get("registers", {})
	var writes: Variant = queue_result.get("memory_writes", [])
	var stack_writes: Variant = queue_result.get("stack_writes", [])
	var instructions: Variant = queue_result.get("instructions", [])
	if _active_task_slot != 0x05 or context == null \
			or context.phase != ContextPhase.RUNNING or context.program_counter != 0xDB0E \
			or context.stack_pointer != 0x50 or context.bank_low != 0x1C or context.bank_high != 0x1D \
			or int(boundary.get("active_task_slot", -1)) != 0x05 \
			or int(boundary.get("pc", -1)) != 0xDB0E or int(boundary.get("sp", -1)) != 0x50 \
			or not bool(queue_result.get("ok", false)) \
			or String(queue_result.get("status", "")) != "scenario36_queue_at_cb0f_entry" \
			or String(queue_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(queue_result.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/first_command_scenarios/manifest.json" \
			or String(queue_result.get("caller_source_sha256", "")) != "e5d260e080d1d429cc5e76b4685426857a78b3bc6739f9b923cc5cb3e538ed94" \
			or String(queue_result.get("queue_source_sha256", "")) != String(SOURCE_SPANS["scenario_queue"]["sha256"]) \
			or bool(queue_result.get("trace_state_used", true)) \
			or bool(queue_result.get("captured_ram_input_used", true)) \
			or bool(queue_result.get("ppu_apu_effects_applied", true)) \
			or not entry_ram is PackedByteArray or entry_ram != _ram \
			or not entry_stack is PackedByteArray or entry_stack != _stack_page \
			or not result_ram is PackedByteArray or result_ram.size() != RAM_SIZE \
			or not result_stack is PackedByteArray or result_stack.size() != STACK_PAGE_SIZE \
			or not entry_registers is Dictionary or entry_registers != _register_snapshot(context) \
			or not registers is Dictionary or not writes is Array or writes.size() != 3 \
			or not stack_writes is Array or stack_writes.size() != 4 \
			or not instructions is Array or instructions.size() != 9:
		return _fail("Scenario-$36 queue result does not match the live slot-$05 `$DB0E` caller boundary.")
	var expected_ram: PackedByteArray = (entry_ram as PackedByteArray).duplicate()
	var expected_stack: PackedByteArray = (entry_stack as PackedByteArray).duplicate()
	var expected_writes := [[0xCBB0, 0x0518, 0x36], [0xCBB5, 0x0516, 0x80], [0xCBBA, 0x0005, 0x00]]
	for index in range(expected_writes.size()):
		if not writes[index] is Dictionary:
			return _fail("Scenario-$36 CBB0 queue write %d is malformed." % index)
		var write: Dictionary = writes[index]
		var expected: Array = expected_writes[index]
		if int(write.get("pc", -1)) != expected[0] \
				or int(write.get("address", -1)) != expected[1] \
				or int(write.get("value", -1)) != expected[2]:
			return _fail("Scenario-$36 CBB0 write %d differs from the packaged instruction bytes." % index)
		expected_ram[int(expected[1])] = int(expected[2])
	var expected_stack_writes := [[0xDB10, 0x0150, 0xDB], [0xDB10, 0x014F, 0x12],
		[0xCBBE, 0x014E, 0xCB], [0xCBBE, 0x014D, 0xC0]]
	for index in range(expected_stack_writes.size()):
		if not stack_writes[index] is Dictionary:
			return _fail("Scenario-$36 JSR stack write %d is malformed." % index)
		var write: Dictionary = stack_writes[index]
		var expected: Array = expected_stack_writes[index]
		if int(write.get("pc", -1)) != expected[0] \
				or int(write.get("address", -1)) != expected[1] \
				or int(write.get("value", -1)) != expected[2]:
			return _fail("Scenario-$36 JSR stack write %d has the wrong return word." % index)
		expected_stack[int(expected[1]) & 0xFF] = int(expected[2])
		expected_ram[int(expected[1])] = int(expected[2])
	if expected_ram.slice(0x0100, 0x0200) != expected_stack \
			or expected_ram != result_ram or expected_stack != result_stack:
		return _fail("Scenario-$36 caller output differs from the three RAM writes and two source JSR frames.")
	var expected_pc_sequence: Array[int] = [0xDB0E, 0xDB10, 0xCBB0, 0xCBB3, 0xCBB5, 0xCBB8, 0xCBBA, 0xCBBC, 0xCBBE]
	for index in range(instructions.size()):
		if not instructions[index] is Dictionary \
				or int(instructions[index].get("pc", -1)) != expected_pc_sequence[index]:
			return _fail("Scenario-$36 queue instruction path diverged at instruction %d." % index)
	var expected_p := _update_nz_flags(context.status_register, 0)
	var expected_p_known := context.status_known_mask | 0x82
	if int(registers.get("pc", -1)) != 0xCB0F or int(registers.get("sp", -1)) != 0x4C \
			or int(registers.get("a", -1)) != 0 or int(registers.get("x", -1)) != context.x_register \
			or int(registers.get("y", -1)) != context.y_register \
			or int(registers.get("p", -1)) != expected_p \
			or int(registers.get("p_known_mask", -1)) != expected_p_known \
			or int(result_ram[0x0518]) != 0x36 or int(result_ram[0x0516]) != 0x80 \
			or int(result_ram[0x0005]) != 0:
		return _fail("Scenario-$36 caller did not reach `$CB0F` with the ROM-derived queue state.")
	_ram = (result_ram as PackedByteArray).duplicate()
	_stack_page = (result_stack as PackedByteArray).duplicate()
	context.accumulator = 0
	context.status_register = expected_p
	context.status_known_mask = expected_p_known
	context.program_counter = 0xCB0F
	context.stack_pointer = 0x4C
	context.source_label = "ROM-byte fresh scenario-$36 caller `$DB0E->$CBB0->$CB0F`"
	if not yield_at_verified_callsite(0x05, 0xCBBE, context.accumulator, 0x4E,
			context.x_register, context.y_register, context.bank_low, context.bank_high, true):
		return false
	return true


## Applies the caller loop's decoded `$CA4F JSR $CB0F` inputs after its last
## source callee returns. The yield routine itself remains the scheduler's
## existing source-verified implementation.
func adopt_root_slot01_loop_yield_call_state(yield_request: Dictionary) -> bool:
	if not _require_initialized():
		return false
	var context: TaskContext = _contexts.get(0x01)
	if _active_task_slot != 0x01 or context == null or context.phase != ContextPhase.RUNNING \
			or context.program_counter != 0xCA58 \
			or not bool(yield_request.get("ok", false)) \
			or String(yield_request.get("status", "")) != "yield_requested" \
			or int(yield_request.get("slot_base", -1)) != 0x01 \
			or int(yield_request.get("callsite_pc", -1)) != 0xCA4F \
			or int(yield_request.get("target_cpu_address", -1)) != 0xCB0F \
			or int(yield_request.get("resume_pc", -1)) != 0xCA52 \
			or int(yield_request.get("delay_in_a", -1)) != 0x01:
		return _fail("Root slot-$01 caller did not decode the source `$CA4F->$CB0F` yield contract.")
	for name: String in ["delay_in_a", "x", "y", "sp", "bank_low", "bank_high"]:
		var value := int(yield_request.get(name, -1))
		if value < 0 or value > 0xFF:
			return _fail("Root slot-$01 yield request has an invalid byte register `%s`." % name)
	context.program_counter = 0xCA4F
	context.accumulator = int(yield_request["delay_in_a"])
	context.x_register = int(yield_request["x"])
	context.y_register = int(yield_request["y"])
	context.stack_pointer = int(yield_request["sp"])
	context.bank_low = int(yield_request["bank_low"])
	context.bank_high = int(yield_request["bank_high"])
	context.source_label = "ROM-byte slot-$01 continuation through `$CA4F` yield request"
	return true


## Adopts the bounded slot-$05 `$8889` worker continuation. It accepts the
## source yield at `$C515`, the first unresolved fixed-bank read at `$C509`,
## the validated descriptor `$F0` input boundary, or the source-verified F0
## divider stop at `$CD52` after its `$CD46` ROL. Only ordered worker writes
## are committed over live RAM.
func adopt_root_slot05_worker_resume_state(dispatch: Dictionary, boundary: Dictionary,
		worker_result: Dictionary, descriptor_contract: Dictionary = {},
		worker_descriptor_contract: Dictionary = {}) -> bool:
	if not _require_initialized():
		return false
	var context: TaskContext = _contexts.get(0x05)
	if _active_task_slot != 0x05 or context == null or context.phase != ContextPhase.RUNNING \
			or context.program_counter != 0x8889 or int(dispatch.get("slot_base", -1)) != 0x05 \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch.get("pc", -1)) != 0x8889 \
			or int(dispatch.get("bank_low", -1)) != 0x18 \
			or int(dispatch.get("bank_high", -1)) != 0x19 \
			or int(boundary.get("slot_base", -1)) != 0x05 \
			or int(boundary.get("active_task_slot", -1)) != 0x05 \
			or int(boundary.get("pc", -1)) != 0x8889:
		return _fail("Worker resume adoption requires the live yielded slot-$05 `$8889` dispatch.")
	var accepted_c509_boundary := not bool(worker_result.get("ok", false)) \
			and String(worker_result.get("exit_kind", "")) == "unresolved_source_span" \
			and int(worker_result.get("exit_pc", -1)) == 0xC509
	var blocked_read_variant: Variant = worker_result.get("blocked_read", {})
	var blocked_read: Dictionary = blocked_read_variant if blocked_read_variant is Dictionary else {}
	var contract_values_variant: Variant = descriptor_contract.get("source_inputs", {})
	var contract_values: Dictionary = contract_values_variant if contract_values_variant is Dictionary else {}
	var worker_tokens_variant: Variant = worker_descriptor_contract.get("descriptor_tokens_expected", [])
	var worker_tokens: Array = worker_tokens_variant if worker_tokens_variant is Array else []
	var unresolved_descriptor_tokens_variant: Variant = descriptor_contract.get("unresolved_source_tokens", [])
	var unresolved_descriptor_tokens: Array = unresolved_descriptor_tokens_variant \
			if unresolved_descriptor_tokens_variant is Array else []
	var accepted_f0_token_boundary := not bool(worker_result.get("ok", false)) \
			and String(worker_result.get("exit_kind", "")) == "unresolved_source_span" \
			and int(worker_result.get("exit_pc", -1)) == 0x89A0 \
			and int(blocked_read.get("instruction_pc", -1)) == 0x89A0 \
			and int(blocked_read.get("requested_address", -1)) == 0xBBDE \
			and int(blocked_read.get("bank", -1)) == 0x19 \
			and bool(descriptor_contract.get("ok", false)) \
			and bool(descriptor_contract.get("packet_data_complete", false)) \
			and bool(descriptor_contract.get("source_inputs_ready", false)) \
			and unresolved_descriptor_tokens.is_empty() \
			and bool(worker_descriptor_contract.get("ok", false)) \
			and String(worker_descriptor_contract.get("status", "")) == "descriptor_source_validated_for_live_worker" \
			and int(worker_descriptor_contract.get("descriptor_text_pointer_cpu", -1)) == 0xBBDC \
			and worker_tokens == [0xEF, 0xFC] \
			and int(contract_values.get("$0027", -1)) == 0x00 \
			and int(contract_values.get("$05F7", -1)) == 0xB4 \
			and int(contract_values.get("$05F8", -1)) == 0x00 \
			and not bool(worker_descriptor_contract.get("next_descriptor_row_executed", true))
	var accepted_c515_yield := bool(worker_result.get("ok", false)) \
			and String(worker_result.get("exit_kind", "")) == "yield_at_c515" \
			and int(worker_result.get("exit_pc", -1)) == 0xC515
	var accepted_ed_row00_boundary := _slot05_ed_row00_boundary_matches(
		worker_result, worker_descriptor_contract)
	var accepted_f0_division_opcode_boundary := _slot05_f0_division_opcode_boundary_matches(
		worker_result, descriptor_contract, worker_descriptor_contract)
	var accepted_scenario35_boundary := validate_slot05_scenario35_enqueue_worker_result(worker_result)
	if not accepted_c509_boundary and not accepted_c515_yield \
			and not accepted_f0_token_boundary and not accepted_f0_division_opcode_boundary \
			and not accepted_ed_row00_boundary and not accepted_scenario35_boundary:
		return _fail("Worker resume boundary rejected: kind=%s pc=$%04X blocked=%s descriptor=%s worker_descriptor=%s tokens=%s values=%s." % [
			String(worker_result.get("exit_kind", "")), int(worker_result.get("exit_pc", -1)),
			str(blocked_read), str(descriptor_contract.get("descriptor_id", "")),
			String(worker_descriptor_contract.get("status", "")), str(worker_tokens), str(contract_values)])
	if String(worker_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(worker_result.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/manifest.json":
		return _fail("Worker resume result is not from the packaged ROM-derived source spans.")
	var proof_variant: Variant = worker_result.get("source_dispatch", {})
	var registers_variant: Variant = worker_result.get("registers", {})
	var mapper_variant: Variant = worker_result.get("mapper", {})
	var ram_variant: Variant = worker_result.get("ram_image", PackedByteArray())
	var stack_variant: Variant = worker_result.get("stack_page", PackedByteArray())
	var writes_variant: Variant = worker_result.get("writes", [])
	var mapper_writes_variant: Variant = worker_result.get("mapper_writes", [])
	if not proof_variant is Dictionary or not registers_variant is Dictionary \
			or not mapper_variant is Dictionary or not ram_variant is PackedByteArray \
			or not stack_variant is PackedByteArray or not writes_variant is Array \
			or not mapper_writes_variant is Array:
		return _fail("Worker result omits its dispatch proof, CPU/mapper state, RAM/stack, or writes.")
	var proof: Dictionary = proof_variant
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var result_ram: PackedByteArray = ram_variant
	var result_stack: PackedByteArray = stack_variant
	var writes: Array = writes_variant
	var mapper_writes: Array = mapper_writes_variant
	if String(proof.get("rom_sha256", "")) != ROM_SHA256 \
			or int(proof.get("slot_base", -1)) != 0x05 \
			or String(proof.get("resume_path", "")) != "yielded_rts" \
			or int(proof.get("pc", -1)) != 0x8889 \
			or int(proof.get("bank", -1)) != 0x18 \
			or not bool(proof.get("source_dispatch_observed", false)) \
			or int(registers.get("pc", -1)) != int(worker_result.get("exit_pc", -2)) \
			or int(registers.get("sp", -1)) < 0 or int(registers.get("sp", -1)) > 0xFF \
			or result_ram.size() != RAM_SIZE or result_stack.size() != STACK_PAGE_SIZE:
		return _fail("Worker result does not match the live slot-$05 dispatch and bounded exit state.")
	var expected_ram: PackedByteArray = boundary.get("ram_image", PackedByteArray())
	var expected_stack: PackedByteArray = boundary.get("stack_page", PackedByteArray())
	if expected_ram.size() != RAM_SIZE or expected_stack.size() != STACK_PAGE_SIZE:
		return _fail("Live slot-$05 boundary omits its RAM or stack page.")
	expected_ram = expected_ram.duplicate()
	expected_stack = expected_stack.duplicate()
	for write_variant in writes:
		if not write_variant is Dictionary:
			return _fail("Worker RAM write stream contains a malformed event.")
		var write: Dictionary = write_variant
		var address := int(write.get("address", -1))
		var value := int(write.get("value", -1))
		var source_slot_ready_clear := accepted_scenario35_boundary \
				and address == 0x0005 and value == 0 \
				and int(write.get("pc", -1)) == 0xCBBA
		if address < 0 or address >= RAM_SIZE or value < 0 or value > 0xFF \
				or (_is_scheduler_owned_ram_address(address) and not source_slot_ready_clear):
			return _fail("Worker write touches invalid or scheduler-owned RAM `$%04X`." % address)
		expected_ram[address] = value
		if address >= 0x0100 and address < 0x0200:
			expected_stack[address & 0xFF] = value
	if result_ram != expected_ram or result_stack != expected_stack:
		return _fail("Worker RAM/stack output differs from replaying its source writes over live scheduler state.")
	for write_variant in mapper_writes:
		if not write_variant is Dictionary:
			return _fail("Worker mapper write stream contains a malformed event.")
		var write: Dictionary = write_variant
		if int(write.get("address", -1)) not in [0x8000, 0x8001] \
				or int(write.get("value", -1)) < 0 or int(write.get("value", -1)) > 0xFF:
			return _fail("Worker mapper write is outside the MMC3 register contract.")
	for index in range(STACK_PAGE_SIZE):
		if result_ram[0x0100 + index] != result_stack[index]:
			return _fail("Worker result RAM and stack mirrors disagree at `$%04X`." % (0x0100 + index))
	var expected_worker_bank_low := 0x1C if accepted_scenario35_boundary else 0x18
	var expected_worker_bank_high := 0x1D if accepted_scenario35_boundary else 0x19
	if int(mapper.get("bank_low", -1)) != expected_worker_bank_low \
			or int(mapper.get("bank_high", -1)) != expected_worker_bank_high:
		return _fail("Worker resume returned outside the slot-$05 `$18/$19` bank pair.")
	_ram = expected_ram
	_stack_page = expected_stack
	context.accumulator = int(registers.get("a", 0)) & 0xFF
	context.x_register = int(registers.get("x", 0)) & 0xFF
	context.y_register = int(registers.get("y", 0)) & 0xFF
	context.status_register = int(registers.get("p", 0)) & 0xFF
	context.status_known_mask = int(registers.get("p_known_mask", 0)) & 0xFF
	context.stack_pointer = int(registers["sp"])
	context.program_counter = int(registers["pc"])
	context.bank_low = int(mapper["bank_low"])
	context.bank_high = int(mapper["bank_high"])
	context.source_label = "ROM-byte resumed slot-$05 worker to `$%04X`" % context.program_counter
	return true


## Adopts one source-worker continuation from the active slot-$05 `$BD9C`
## boundary. This method cannot dispatch, resume another slot, or alter the
## scheduler-owned task record / ready latch.
func adopt_active_slot05_worker_continuation_state(live_boundary: Dictionary,
		previous_worker_result: Dictionary, worker_result: Dictionary) -> bool:
	if not _require_initialized():
		return false
	var context: TaskContext = _contexts.get(0x05)
	var previous_blocked: Dictionary = previous_worker_result.get("blocked_read", {})
	var source_continuation: Dictionary = worker_result.get("source_continuation", {})
	var registers: Dictionary = worker_result.get("registers", {})
	var mapper: Dictionary = worker_result.get("mapper", {})
	var blocked: Dictionary = worker_result.get("blocked_read", {})
	var result_ram: PackedByteArray = worker_result.get("ram_image", PackedByteArray())
	var result_stack: PackedByteArray = worker_result.get("stack_page", PackedByteArray())
	var writes: Array = worker_result.get("writes", [])
	var mapper_writes: Array = worker_result.get("mapper_writes", [])
	var live_ram: PackedByteArray = live_boundary.get("ram_image", PackedByteArray())
	var live_stack: PackedByteArray = live_boundary.get("stack_page", PackedByteArray())
	if _active_task_slot != 0x05 or context == null or context.phase != ContextPhase.RUNNING \
			or context.program_counter != 0x89A0 \
			or int(live_boundary.get("slot_base", -1)) != 0x05 \
			or int(live_boundary.get("active_task_slot", -1)) != 0x05 \
			or int(live_boundary.get("pc", -1)) != 0x89A0 \
			or int(previous_blocked.get("requested_address", -1)) != 0xBD9C \
			or int(source_continuation.get("entry_pc", -1)) != 0x89A0 \
			or int(source_continuation.get("source_pointer", -1)) != 0xBD9C \
			or String(worker_result.get("exit_kind", "")) != "yield_at_c515" \
			or int(worker_result.get("exit_pc", -1)) != 0xC515 \
			or not blocked.is_empty() \
			or String(worker_result.get("rom_sha256", "")) != ROM_SHA256 \
			or live_ram.size() != RAM_SIZE or live_stack.size() != STACK_PAGE_SIZE \
			or result_ram.size() != RAM_SIZE or result_stack.size() != STACK_PAGE_SIZE \
			or _ram != live_ram or _stack_page != live_stack:
		return _fail("Slot-$05 worker adoption requires the unchanged active `$BD9C` boundary and a stop before `$BBE3`.")
	var previous_ram: PackedByteArray = previous_worker_result.get("ram_image", PackedByteArray())
	var previous_stack: PackedByteArray = previous_worker_result.get("stack_page", PackedByteArray())
	if previous_ram != live_ram or previous_stack != live_stack \
			or int(live_boundary.get("bank_low", -1)) != 0x18 \
			or int(live_boundary.get("bank_high", -1)) != 0x19 \
			or int(mapper.get("bank_low", -1)) != 0x18 \
			or int(mapper.get("bank_high", -1)) != 0x19 \
			or int(registers.get("pc", -1)) != 0xC515:
		return _fail("Slot-$05 continuation changed the live input snapshot or returned outside its bank pair.")
	var expected_ram := live_ram.duplicate()
	var expected_stack := live_stack.duplicate()
	for write_variant in writes:
		if not write_variant is Dictionary:
			return _fail("Slot-$05 continuation write stream contains a malformed event.")
		var write: Dictionary = write_variant
		var address := int(write.get("address", -1))
		var value := int(write.get("value", -1))
		if address < 0 or address >= RAM_SIZE or value < 0 or value > 0xFF \
				or _is_scheduler_owned_ram_address(address):
			return _fail("Slot-$05 continuation writes invalid or scheduler-owned RAM `$%04X`." % address)
		expected_ram[address] = value
		if address >= 0x0100 and address < 0x0200:
			expected_stack[address & 0xFF] = value
	for mapper_write_variant in mapper_writes:
		if not mapper_write_variant is Dictionary:
			return _fail("Slot-$05 continuation mapper write stream is malformed.")
		var mapper_write: Dictionary = mapper_write_variant
		if int(mapper_write.get("address", -1)) not in [0x8000, 0x8001] \
				or int(mapper_write.get("value", -1)) < 0 or int(mapper_write.get("value", -1)) > 0xFF:
			return _fail("Slot-$05 continuation mapper write is outside the MMC3 register contract.")
	if result_ram != expected_ram or result_stack != expected_stack \
			or result_ram.slice(0x0100, 0x0200) != result_stack:
		return _fail("Slot-$05 continuation output differs from ordered writes over live RAM/stack state.")
	_ram = expected_ram
	_stack_page = expected_stack
	context.accumulator = int(registers.get("a", 0)) & 0xFF
	context.x_register = int(registers.get("x", 0)) & 0xFF
	context.y_register = int(registers.get("y", 0)) & 0xFF
	context.status_register = int(registers.get("p", 0)) & 0xFF
	context.status_known_mask = int(registers.get("p_known_mask", 0)) & 0xFF
	context.stack_pointer = int(registers.get("sp", -1))
	context.program_counter = 0xC515
	context.bank_low = int(mapper["bank_low"])
	context.bank_high = int(mapper["bank_high"])
	context.source_label = "ROM-byte slot-$05 descriptor `$EE` continuation yielded at `$C515`"
	return true


func _slot05_ed_row00_boundary_matches(worker_result: Dictionary,
		worker_descriptor_contract: Dictionary) -> bool:
	var blocked_variant: Variant = worker_result.get("blocked_read", {})
	var registers_variant: Variant = worker_result.get("registers", {})
	var mapper_variant: Variant = worker_result.get("mapper", {})
	var ram_variant: Variant = worker_result.get("ram_image", PackedByteArray())
	var stack_variant: Variant = worker_result.get("stack_page", PackedByteArray())
	if not blocked_variant is Dictionary or not registers_variant is Dictionary \
			or not mapper_variant is Dictionary or not ram_variant is PackedByteArray \
			or not stack_variant is PackedByteArray:
		return false
	var blocked: Dictionary = blocked_variant
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	var source_stop_variant: Variant = worker_result.get("source_boundary_stop", {})
	if not source_stop_variant is Dictionary:
		return false
	var source_stop: Dictionary = source_stop_variant
	if bool(worker_result.get("ok", true)) \
			or String(worker_result.get("exit_kind", "")) != "source_read_boundary" \
			or int(source_stop.get("address", -1)) != 0xBD9C \
			or not bool(source_stop.get("source_bytes_available", false)) \
			or String(worker_result.get("source_manifest_sha256", "")) != "d3f5ba788ea93fb02c6678f88efff9fe19aa303d19440b89c88ad81907a539ad" \
			or String(worker_descriptor_contract.get("status", "")) != "descriptor_source_validated_for_live_worker" \
			or int(worker_descriptor_contract.get("second_descriptor_pointer_cpu", -1)) != 0xB464 \
			or int(worker_descriptor_contract.get("descriptor01_text_pointer_cpu", -1)) != 0xBBE0 \
			or String(worker_descriptor_contract.get("descriptor01_row00_hex", "")) != "ed00fc" \
			or int(worker_descriptor_contract.get("descriptor01_next_row_pointer_cpu", -1)) != 0xBD9C \
			or bool(worker_descriptor_contract.get("descriptor01_next_row_executed", true)) \
			or int(worker_result.get("exit_pc", -1)) != 0x89A0 \
			or int(blocked.get("instruction_pc", -1)) != 0x89A0 \
			or int(blocked.get("requested_address", -1)) != 0xBD9C \
			or int(blocked.get("bank", -1)) != 0x19 \
			or int(registers.get("pc", -1)) != 0x89A0 \
			or int(mapper.get("bank_low", -1)) != 0x18 or int(mapper.get("bank_high", -1)) != 0x19 \
			or ram.size() != RAM_SIZE or stack.size() != STACK_PAGE_SIZE \
			or int(ram[0x003E]) != 0x9C or int(ram[0x003F]) != 0xBD \
			or int(ram[0x002A]) != 0 or int(ram[0x003C]) != 1 \
			or int(ram[0x0515]) != 1 or int(ram[0x05C5]) != 0:
		return false
	var required_spans := {
		"bank19_resumed_worker_descriptor01_row00_BBE0_BBE3.bin": false,
		"bank18_ed_team_handler_8AE7_8B0A.bin": false,
		"bank18_ed_text_loop_8A56_8A86.bin": false,
		"fixed_team_00_name_stream_F776_F77C.bin": false,
	}
	var spans_variant: Variant = worker_result.get("executed_source_spans", [])
	if not spans_variant is Array:
		return false
	for span_variant in spans_variant:
		if span_variant is Dictionary:
			var name := String((span_variant as Dictionary).get("file", ""))
			if required_spans.has(name):
				required_spans[name] = true
	for name in required_spans:
		if not bool(required_spans[name]):
			return false
	var row_clear_seen := false
	var row_increment_seen := false
	var writes_variant: Variant = worker_result.get("writes", [])
	if not writes_variant is Array:
		return false
	for write_variant in writes_variant:
		if write_variant is Dictionary:
			var write: Dictionary = write_variant
			if int(write.get("address", -1)) == 0x003C and int(write.get("pc", -1)) == 0x8954 \
					and int(write.get("value", -1)) == 0:
				row_clear_seen = true
			if int(write.get("address", -1)) == 0x003C and int(write.get("pc", -1)) == 0x8960 \
					and int(write.get("value", -1)) == 1:
				row_increment_seen = true
	return row_clear_seen and row_increment_seen


## Accepts only the live source-worker result that followed `$DAD1->$DAD8->$DADA->$CBB0`
## and reached the already-executed `$CBBE->$CB0F` call with scenario `$35` queued.
func validate_slot05_scenario35_enqueue_worker_result(worker_result: Dictionary) -> bool:
	var blocked: Dictionary = worker_result.get("blocked_read", {})
	var registers: Dictionary = worker_result.get("registers", {})
	var mapper: Dictionary = worker_result.get("mapper", {})
	var source_dispatch: Dictionary = worker_result.get("source_dispatch", {})
	var ram: PackedByteArray = worker_result.get("ram_image", PackedByteArray())
	var stack: PackedByteArray = worker_result.get("stack_page", PackedByteArray())
	if bool(worker_result.get("ok", true)) \
			or String(worker_result.get("exit_kind", "")) != "unresolved_source_span" \
			or int(worker_result.get("exit_pc", -1)) != 0xCB0F \
			or String(worker_result.get("source_manifest_sha256", "")) != "d3f5ba788ea93fb02c6678f88efff9fe19aa303d19440b89c88ad81907a539ad" \
			or int(blocked.get("instruction_pc", -1)) != 0xCB0F \
			or int(blocked.get("requested_address", -1)) != 0xCB0F \
			or int(blocked.get("bank", -1)) != 0x1E \
			or int(registers.get("pc", -1)) != 0xCB0F \
			or int(mapper.get("bank_low", -1)) != 0x1C or int(mapper.get("bank_high", -1)) != 0x1D \
			or String(worker_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(worker_result.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/manifest.json" \
			or int(source_dispatch.get("slot_base", -1)) != 0x05 \
			or String(source_dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(source_dispatch.get("pc", -1)) != 0x8889 \
			or not bool(source_dispatch.get("source_dispatch_observed", false)) \
			or ram.size() != RAM_SIZE or stack.size() != STACK_PAGE_SIZE \
			or ram.slice(0x0100, 0x0200) != stack \
			or ram.slice(0x0515, 0x0519) != PackedByteArray([0x80, 0x80, 0x00, 0x35]) \
			or int(ram[0x0005]) != 0 or int(ram[0x0629]) != 0:
		return false
	var required_spans := {
		"fixed_kickoff_caller_DAD1_DAD8.bin": "8577a4922b07af947dc28746b106cc81365aa68d16d2c4bc7497618cf1db6311",
		"fixed_kickoff_scenario35_caller_DAD8_DADC.bin": "334e25e61f3fa69e4c51961948c06c802993d03dbf9dc2c77b1cb471d857afd5",
		"fixed_scenario_queue_CBB0_CBC1.bin": "bda16c7ced2834027dd6039a6c079a701dc8abd9c89179ba2d3c568aa0a16a32",
	}
	var spans_variant: Variant = worker_result.get("executed_source_spans", [])
	if not spans_variant is Array:
		return false
	for span_variant in spans_variant:
		if span_variant is Dictionary:
			var span: Dictionary = span_variant
			var file_name := String(span.get("file", ""))
			if required_spans.has(file_name):
				if String(span.get("sha256", "")) != String(required_spans[file_name]):
					return false
				required_spans.erase(file_name)
	if not required_spans.is_empty():
		return false
	var expected_opcodes := {0xDAD1: 0xAD, 0xDAD4: 0xC9, 0xDAD6: 0xF0,
		0xDAD8: 0xA9, 0xDADA: 0x20, 0xCBB0: 0x8D, 0xCBBE: 0x20}
	var seen_instructions: Dictionary = {}
	var branch_skipped_to_dad8 := false
	var instructions_variant: Variant = worker_result.get("instructions", [])
	if not instructions_variant is Array:
		return false
	for instruction_variant in instructions_variant:
		if instruction_variant is Dictionary:
			var instruction: Dictionary = instruction_variant
			var pc := int(instruction.get("pc", -1))
			if expected_opcodes.has(pc):
				if int(instruction.get("opcode", -1)) != int(expected_opcodes[pc]):
					return false
				seen_instructions[pc] = true
			if pc == 0xDAD6 and int(instruction.get("next_pc", -1)) == 0xDAD8:
				branch_skipped_to_dad8 = true
	if not branch_skipped_to_dad8:
		return false
	for pc in expected_opcodes:
		if not seen_instructions.has(pc):
			return false
	var scenario_call_seen := false
	var save_call_seen := false
	var calls_variant: Variant = worker_result.get("calls", [])
	if not calls_variant is Array:
		return false
	for call_variant in calls_variant:
		if call_variant is Dictionary:
			var call: Dictionary = call_variant
			if int(call.get("callsite", -1)) == 0xDADA \
					and int(call.get("target", -1)) == 0xCBB0:
				scenario_call_seen = true
			if int(call.get("callsite", -1)) == 0xCBBE \
					and int(call.get("target", -1)) == 0xCB0F \
					and int(call.get("sp_after_push", -1)) == int(registers.get("sp", -2)):
				save_call_seen = true
	var source_queue_writes := {
		"$CBB0:$0518=$35": false,
		"$CBB5:$0516=$80": false,
		"$CBBA:$0005=$00": false,
	}
	var writes_variant: Variant = worker_result.get("writes", [])
	if not writes_variant is Array:
		return false
	for write_variant in writes_variant:
		if write_variant is Dictionary:
			var write: Dictionary = write_variant
			var signature := "$%04X:$%04X=$%02X" % [int(write.get("pc", -1)),
				int(write.get("address", -1)), int(write.get("value", -1))]
			if source_queue_writes.has(signature):
				source_queue_writes[signature] = true
	for signature in source_queue_writes:
		if not bool(source_queue_writes[signature]):
			return false
	return scenario_call_seen and save_call_seen


func _slot05_f0_division_opcode_boundary_matches(worker_result: Dictionary,
		descriptor_contract: Dictionary, worker_descriptor_contract: Dictionary) -> bool:
	var unsupported_variant: Variant = worker_result.get("unsupported_opcode", {})
	var unsupported: Dictionary = unsupported_variant if unsupported_variant is Dictionary else {}
	var blocked_variant: Variant = worker_result.get("blocked_read", {})
	var blocked: Dictionary = blocked_variant if blocked_variant is Dictionary else {}
	var values_variant: Variant = descriptor_contract.get("source_inputs", {})
	var values: Dictionary = values_variant if values_variant is Dictionary else {}
	var unresolved_variant: Variant = descriptor_contract.get("unresolved_source_tokens", [])
	var unresolved: Array = unresolved_variant if unresolved_variant is Array else []
	var tokens_variant: Variant = worker_descriptor_contract.get("descriptor_tokens_expected", [])
	var tokens: Array = tokens_variant if tokens_variant is Array else []
	var mapper_variant: Variant = worker_result.get("mapper", {})
	var mapper: Dictionary = mapper_variant if mapper_variant is Dictionary else {}
	var mapper_writes_variant: Variant = worker_result.get("mapper_writes", [])
	var mapper_writes: Array = mapper_writes_variant if mapper_writes_variant is Array else []
	if bool(worker_result.get("ok", true)) \
			or String(worker_result.get("exit_kind", "")) != "unsupported_source_opcode" \
			or int(worker_result.get("exit_pc", -1)) != 0xCD52 \
			or int(worker_result.get("exit_bank", -1)) != 0x1E \
			or int(unsupported.get("pc", -1)) != 0xCD52 \
			or int(unsupported.get("bank", -1)) != 0x1E \
			or int(unsupported.get("opcode", -1)) != 0xC5 \
			or not blocked.is_empty() \
			or String(worker_result.get("source_manifest_sha256", "")) != "d3f5ba788ea93fb02c6678f88efff9fe19aa303d19440b89c88ad81907a539ad" \
			or String(worker_descriptor_contract.get("status", "")) != "descriptor_source_validated_for_live_worker" \
			or int(worker_descriptor_contract.get("descriptor_text_pointer_cpu", -1)) != 0xBBDC \
			or tokens != [0xEF, 0xFC] \
			or not bool(descriptor_contract.get("ok", false)) \
			or not bool(descriptor_contract.get("packet_data_complete", false)) \
			or not bool(descriptor_contract.get("source_inputs_ready", false)) \
			or not unresolved.is_empty() \
			or int(values.get("$0027", -1)) != 0x00 \
			or int(values.get("$05F7", -1)) != 0xB4 \
			or int(values.get("$05F8", -1)) != 0x00 \
			or int(mapper.get("select", -1)) != 0x07 \
			or not mapper_writes.is_empty():
		return false
	var expected_span_files := {
		"bank19_resumed_worker_text_row01_BBDE_BBE0.bin": true,
		"bank18_resumed_worker_vector_tail_89D7_89DC.bin": true,
		"bank18_f0_match_clock_handler_8B8B_8BD5.bin": true,
		"bank18_f0_decimal_formatter_8C55_8C85.bin": true,
		"fixed_division_dispatch_C51E_C521.bin": true,
		"fixed_division_16bit_CD3C_CD77.bin": true,
	}
	var span_files: Dictionary = {}
	for span_variant in worker_result.get("executed_source_spans", []):
		if span_variant is Dictionary:
			span_files[String((span_variant as Dictionary).get("file", ""))] = true
	for file_name: String in expected_span_files:
		if not span_files.has(file_name):
			return false
	var instruction_pcs: Dictionary = {}
	var rol_completed := false
	for instruction_variant in worker_result.get("instructions", []):
		if instruction_variant is Dictionary:
			var instruction: Dictionary = instruction_variant
			var pc := int(instruction.get("pc", -1))
			instruction_pcs[pc] = true
			if pc == 0xCD46 and int(instruction.get("opcode", -1)) == 0x26 \
					and int(instruction.get("next_pc", -1)) == 0xCD48:
				rol_completed = true
	for pc in [0x89A0, 0x8B8B, 0x8C55, 0xCD3C, 0xCD46]:
		if not instruction_pcs.has(pc):
			return false
	if not rol_completed:
		return false
	var call_targets: Dictionary = {}
	for call_variant in worker_result.get("calls", []):
		if call_variant is Dictionary:
			call_targets[int((call_variant as Dictionary).get("target", -1))] = true
	for target in [0xC509, 0x8C85, 0xC51E]:
		if not call_targets.has(target):
			return false
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
	var period_context: Dictionary = period_result.get("source_context", {})
	var resumed_from_scenario := String(period_context.get("source_event", "")) \
		== "ROM-byte slot-$05 `$CBC1 RTS->$D11E` live continuation"
	if _merged_source_write_prefixes.has(slot_base) and not resumed_from_scenario:
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


## Replays the live scenario-$35 `$CBC1->$DADD->$800C` continuation and its
## worker writes over the scheduler RAM already produced by the running task.
func merge_slot05_scenario35_worker_writes(return_result: Dictionary,
		continuation_result: Dictionary, worker_result: Dictionary) -> Dictionary:
	if not _require_initialized():
		return {}
	var context: TaskContext = _contexts.get(0x05)
	var return_ram: Variant = return_result.get("ram_image", PackedByteArray())
	var return_stack: Variant = return_result.get("stack_page", PackedByteArray())
	var continuation_ram: Variant = continuation_result.get("ram_image", PackedByteArray())
	var worker_ram: Variant = worker_result.get("ram_image", PackedByteArray())
	var worker_stack: Variant = worker_result.get("stack_page", PackedByteArray())
	if _active_task_slot != 0x05 or context == null or context.phase != ContextPhase.RUNNING \
			or context.program_counter != 0xDADD \
			or context.source_label != "ROM-byte slot-$05 scenario return `$CBC1 RTS->$DADD`" \
			or String(return_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(return_result.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/scenario_task_runtime/manifest.json" \
			or not bool(return_result.get("returned_to_caller", false)) \
			or String(continuation_result.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/fresh_daaa_continuation/manifest.json" \
			or int(continuation_result.get("entry_pc", -1)) != 0xDADD \
			or int(continuation_result.get("exit_pc", -1)) != 0x800C \
			or String(worker_result.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/manifest.json" \
			or int(worker_result.get("entry_pc", -1)) != 0x800C \
			or int(worker_result.get("exit_pc", -1)) != 0xC515 \
			or not return_ram is PackedByteArray or return_ram.size() != RAM_SIZE \
			or not return_stack is PackedByteArray or return_stack.size() != STACK_PAGE_SIZE \
			or not continuation_ram is PackedByteArray or continuation_ram.size() != RAM_SIZE \
			or not worker_ram is PackedByteArray or worker_ram.size() != RAM_SIZE \
			or not worker_stack is PackedByteArray or worker_stack.size() != STACK_PAGE_SIZE \
			or _ram != return_ram or _stack_page != return_stack:
		_fail("Scenario-$35 write replay requires the unchanged live `$DADD` RAM/stack boundary and source-derived worker results.")
		return {}
	var expected_ram: PackedByteArray = return_ram.duplicate()
	var expected_stack: PackedByteArray = return_stack.duplicate()
	var merged_writes: Array[Dictionary] = []
	for source_result: Dictionary in [continuation_result, worker_result]:
		var writes_variant: Variant = source_result.get("writes", [])
		if not writes_variant is Array:
			_fail("Scenario-$35 continuation omitted its ordered source write stream.")
			return {}
		for write_variant in writes_variant:
			if not write_variant is Dictionary:
				_fail("Scenario-$35 continuation write stream contains a malformed event.")
				return {}
			var write: Dictionary = write_variant
			var address := int(write.get("address", -1))
			var value := int(write.get("value", -1))
			if address < 0 or address >= RAM_SIZE or value < 0 or value > 0xFF \
					or not write.has("pc") or _is_scheduler_owned_ram_address(address):
				_fail("Scenario-$35 source write conflicts with scheduler-owned RAM at `$%04X`." % address)
				return {}
			merged_writes.append(write.duplicate(true))
			expected_ram[address] = value
			if address >= 0x0100 and address < 0x0200:
				expected_stack[address & 0xFF] = value
	if expected_ram != worker_ram or expected_stack != worker_stack \
			or continuation_result.get("ram_image", PackedByteArray()) != continuation_ram:
		_fail("Replaying `$DADD` and worker writes did not reproduce their live RAM/stack outputs.")
		return {}
	for slot_base: int in SLOT_BASES:
		if expected_ram.slice(slot_base, slot_base + 4) != _record_bytes(slot_base):
			_fail("Scenario-$35 ROM continuation changed scheduler-owned task record `$%02X`." % slot_base)
	_ram = expected_ram
	_stack_page = expected_stack
	_merged_source_write_prefixes[0x05] = true
	return {"ok": true, "slot_base": 0x05,
		"source_order": ["live_CBC1_RTS_DADD", "fixed_DADD_EF7F_wrapper", "bank18_worker_C515"],
		"write_count": merged_writes.size(), "full_ram_image_copied": false,
		"active_slot_pointer_0000": int(_ram[0x0000]),
		"nmi_ready_latch_001b": int(_ram[0x001B]),
		"scheduler_task_records_after": _task_record_snapshot()}


func get_status() -> Dictionary:
	return {
		"configured": _configured,
		"initialized": _initialized,
		"error": error_message,
		"rom_sha256": ROM_SHA256,
		"task_slots": _task_record_snapshot() if _initialized else [],
		"scheduler_ready_latch_001b": int(_ram[0x001B]) if _initialized else -1,
		"ppu_ctrl_shadow": _ppu_ctrl_shadow,
		"live_ppu_ctrl_shadow": int(_ram[0x0020]) if _initialized else -1,
		"active_task_slot": _active_task_slot,
		"slot09_cb0f_scheduler_save": _last_slot09_cb0f_save_result.duplicate(true),
		"scheduler_y_register": _scheduler_y_register,
		"scheduler_scan_cursor": _scheduler_scan_cursor,
		"does_execute_6502": false,
		"does_synthesize_nmi_cadence": false,
		"does_execute_full_task_bodies": false,
		"does_execute_bounded_root_slot01_startup": true,
		"does_execute_bounded_root_slot09_first_yield": true,
		"controller_sample": _last_controller_sample.duplicate(true),
	}


## Applies one source-frame controller sample at a stable task boundary. `$001C`
## is the held-button mask; `$001E` is the ROM's newly-pressed mask:
## `($previous ^ current) & current`. Callers provide actual pad state, never
## captured RAM values.
func sample_controller_input(button_state: int) -> Dictionary:
	if not _require_initialized():
		return {"ok": false, "error": error_message}
	if _active_task_slot != -1:
		return {"ok": false, "error": "Controller input can only be sampled between source-task executions."}
	if button_state < 0 or button_state > 0xFF:
		return {"ok": false, "error": "Controller state must be an 8-bit NES pad mask."}
	var previous := int(_ram[0x001C])
	var current := button_state & 0xFF
	var newly_pressed := (previous ^ current) & current
	_ram[0x001C] = current
	_ram[0x001E] = newly_pressed
	_last_controller_sample = {
		"previous": previous,
		"current": current,
		"newly_pressed": newly_pressed,
		"held_ram_001c": int(_ram[0x001C]),
		"edge_ram_001e": int(_ram[0x001E]),
	}
	return {"ok": true, "sample": _last_controller_sample.duplicate(true)}


## Returns the bounded source-task fields needed to review a yield boundary.
func get_task_boundary_snapshot(slot_base: int) -> Dictionary:
	var context: TaskContext = _contexts.get(slot_base)
	if not _initialized or context == null:
		return {}
	return {
		"rom_sha256": ROM_SHA256,
		"slot_base": context.slot_base,
		"phase": context.phase,
		"ready_delay": context.ready_delay,
		"pending_resume": context.pending_resume,
		"pc": context.program_counter,
		"sp": context.stack_pointer,
		"a": context.accumulator,
		"x": context.x_register,
		"y": context.y_register,
		"p": context.status_register,
		"p_known_mask": context.status_known_mask,
		"bank_low": context.bank_low,
		"bank_high": context.bank_high,
			"mapper": context.mapper_state.duplicate(true),
		"record": _record_bytes(slot_base),
		"ram_007F": int(_ram[0x007F]),
		"ram_image": _ram.duplicate(),
		"stack_page": _stack_page.duplicate(),
		"active_task_slot": _active_task_slot,
		"scheduler_y_register": _scheduler_y_register,
		"scheduler_scan_cursor": _scheduler_scan_cursor,
	}


## Returns a read-only snapshot of source-owned inputs used by the normal NMI
## secondary-queue consumer. The route uses it only to ensure that a pending
## queue was not altered between its producer boundary and the caller's NMI.
func get_live_nmi_secondary_queue_state() -> Dictionary:
	if not _require_initialized():
		return {}
	return {
		"rom_sha256": ROM_SHA256,
		"ram_001b": int(_ram[0x001B]),
		"primary_count_0498": int(_ram[0x0498]),
		"primary_queue_records": _ram.slice(0x0499, 0x04A5),
		"primary_transfer_buffer": _ram.slice(0x046C, 0x0498),
		"ready_flag_0515": int(_ram[0x0515]),
		"packet_buffer": _ram.slice(0x04A5, 0x05A5),
	}


func _validate_source_write_chain(period_result: Dictionary, continuation_result: Dictionary,
		worker_result: Dictionary) -> bool:
	if String(period_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(period_result.get("source_code_sha256", "")) != "28895a5c3512a45e1b1a59c4324654ec03bb5f2ea413445e32333aa3bd6b87cc" \
			or int(period_result.get("exit_pc", -1)) != 0xDAAA:
		return _fail("Period write stream is not the hash-checked `$D11E->$DAAA` ROM result.")
	var period_entry: Dictionary = period_result.get("entry", {})
	var period_dispatch: Dictionary = period_result.get("scheduler_dispatch", {})
	var period_context: Dictionary = period_result.get("source_context", {})
	var resumed_period := String(period_context.get("source_event", "")) \
		== "ROM-byte slot-$05 `$CBC1 RTS->$D11E` live continuation"
	var period_entry_sp := 0x50 if resumed_period else 0x52
	if int(period_entry.get("slot_base", -1)) != 0x05 or int(period_entry.get("pc", -1)) != 0xD11E \
			or int(period_entry.get("sp", -1)) != period_entry_sp \
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


func _register_snapshot(context: TaskContext) -> Dictionary:
	return {
		"a": context.accumulator, "x": context.x_register, "y": context.y_register,
		"p": context.status_register, "p_known_mask": context.status_known_mask,
		"sp": context.stack_pointer, "pc": context.program_counter,
	}


func _slot11_source_read_present(reads: Array, address: int, value: int,
		kind: String) -> bool:
	for read_variant in reads:
		if read_variant is Dictionary:
			var read: Dictionary = read_variant
			if int(read.get("address", -1)) == address \
					and int(read.get("value", -1)) == value \
					and String(read.get("kind", "")) == kind:
				return true
	return false


func _slot09_registers_match_context(registers: Dictionary, context: TaskContext,
		expected_pc: int) -> bool:
	return int(registers.get("a", -1)) == context.accumulator \
			and int(registers.get("x", -1)) == context.x_register \
			and int(registers.get("y", -1)) == context.y_register \
			and int(registers.get("p", -1)) == context.status_register \
			and int(registers.get("p_known_mask", -1)) == context.status_known_mask \
			and int(registers.get("sp", -1)) == context.stack_pointer \
			and int(registers.get("pc", -1)) == expected_pc


func _seeded_slot11_is_available() -> bool:
	var existing: TaskContext = _contexts.get(0x11)
	return int(_ram[0x11]) == 0 and _record_bytes(0x11) == PackedByteArray([0, 0, 0, 0]) \
			and (existing == null or existing.phase in [ContextPhase.EMPTY, ContextPhase.FINISHED])


func _slot11_initial_dispatch_candidate(context: TaskContext) -> Dictionary:
	var saved_sp := int(_ram[0x12])
	var return_low := int(_stack_page[(saved_sp + 1) & 0xFF])
	var return_high := int(_stack_page[(saved_sp + 2) & 0xFF])
	var return_word := (return_high << 8) | return_low
	return {
		"slot_base": 0x11,
		"phase": ContextPhase.SEEDED,
		"pending_resume": ResumeKind.NONE,
		"task_record": _record_bytes(0x11),
		"source_return_word": return_word,
		"rts_target_pc": (return_word + 1) & 0xFFFF,
		"saved_sp_before_rts": saved_sp,
		"sp_after_rts": (saved_sp + 2) & 0xFF,
		"bank_low": int(_ram[0x13]),
		"bank_high_after_dispatch": (int(_ram[0x13]) + 1) & 0xFF,
		"dispatch_required": true,
		"dispatch_performed": false,
		"active_task_slot": _active_task_slot,
	}


func _push_actor_seed_stack_byte(ram: PackedByteArray, stack: PackedByteArray,
		writes: Array[Dictionary], sp_before: int, value: int, pc: int,
		kind: String) -> Dictionary:
	var result_ram := ram.duplicate()
	var result_stack := stack.duplicate()
	var stack_offset := sp_before & 0xFF
	var byte_value := value & 0xFF
	result_stack[stack_offset] = byte_value
	result_ram[0x0100 | stack_offset] = byte_value
	writes.append({"pc": pc, "address": 0x0100 | stack_offset,
		"value": byte_value, "kind": kind})
	return {
		"ram_image": result_ram,
		"stack_page": result_stack,
		"sp": (stack_offset - 1) & 0xFF,
	}


func _replay_actor_source_writes(writes_variant: Variant, stack_writes_variant: Variant,
		initial_ram: PackedByteArray, initial_stack: PackedByteArray,
		stack_writes_mirror_ram: bool = true) -> Dictionary:
	if not writes_variant is Array or not stack_writes_variant is Array:
		return {"ok": false, "reason": "Actor source write streams are malformed."}
	var result_ram := initial_ram.duplicate()
	var result_stack := initial_stack.duplicate()
	for write_variant: Variant in writes_variant:
		if not write_variant is Dictionary:
			return {"ok": false, "reason": "Actor source RAM write is malformed."}
		var write: Dictionary = write_variant
		var address := int(write.get("address", -1))
		var value := int(write.get("value", -1))
		var write_pc := int(write.get("pc", -1))
		var allowed_source_clear := (write_pc == 0xED08 and address == 0x000D and value == 0) \
				or (write_pc == 0xED0A and address == 0x000E and value == 0)
		if address < 0 or address >= RAM_SIZE or value < 0 or value > 0xFF \
				or not write.has("pc") \
				or (_is_scheduler_owned_ram_address(address) and not allowed_source_clear) \
				or (allowed_source_clear and int(result_ram[address]) != value):
			return {"ok": false, "reason": "Actor source write is invalid or touches scheduler-owned RAM `$%04X`." % address}
		result_ram[address] = value
		if address >= 0x0100 and address < 0x0200:
			result_stack[address & 0xFF] = value
	for write_variant: Variant in stack_writes_variant:
		if not write_variant is Dictionary:
			return {"ok": false, "reason": "Actor source stack write is malformed."}
		var write: Dictionary = write_variant
		var address := int(write.get("address", -1))
		var value := int(write.get("value", -1))
		if address < 0x0100 or address >= 0x0200 or value < 0 or value > 0xFF \
				or not write.has("pc"):
			return {"ok": false, "reason": "Actor source stack write is outside the CPU stack page."}
		result_stack[address & 0xFF] = value
		if stack_writes_mirror_ram:
			result_ram[address] = value
	return {"ok": true, "ram_image": result_ram, "stack_page": result_stack}


func _replay_actor_source_mapper_writes(mapper_writes_variant: Variant,
		initial_bank_low: int, initial_bank_high: int, output_mapper: Dictionary,
		initial_select: int = -1) -> Dictionary:
	if not mapper_writes_variant is Array:
		return {"ok": false, "reason": "Actor source mapper write stream is malformed."}
	var registers := {6: initial_bank_low & 0xFF, 7: initial_bank_high & 0xFF}
	var selected := initial_select
	for write_variant: Variant in mapper_writes_variant:
		if not write_variant is Dictionary:
			return {"ok": false, "reason": "Actor source mapper write is malformed."}
		var write: Dictionary = write_variant
		var address := int(write.get("address", -1))
		var value := int(write.get("value", -1))
		if value < 0 or value > 0xFF or address not in [0x8000, 0x8001] \
				or not write.has("pc"):
			return {"ok": false, "reason": "Actor source mapper write is outside the MMC3 register contract."}
		if address == 0x8000:
			selected = value & 0x07
			if selected not in [6, 7] or int(write.get("select", selected)) != selected:
				return {"ok": false, "reason": "Actor source selected an unsupported MMC3 bank register."}
		else:
			var write_select := int(write.get("select", selected))
			if write_select not in [6, 7] or (selected >= 0 and write_select != selected):
				return {"ok": false, "reason": "Actor source MMC3 data write does not match its selected bank register."}
			selected = write_select
			registers[selected] = value
	var expected_low := int(registers[6])
	var expected_high := int(registers[7])
	if int(output_mapper.get("bank_low", -1)) != expected_low \
			or int(output_mapper.get("bank_high", -1)) != expected_high:
		return {"ok": false, "reason": "Actor source mapper output differs from replayed MMC3 bank writes."}
	var output_registers_variant: Variant = output_mapper.get("bank_registers", {})
	if output_registers_variant is Dictionary:
		var output_registers: Dictionary = output_registers_variant
		if int(output_registers.get(6, output_registers.get("6", -1))) != expected_low \
				or int(output_registers.get(7, output_registers.get("7", -1))) != expected_high:
			return {"ok": false, "reason": "Actor source mapper register image differs from replayed writes."}
	if selected >= 0 and int(output_mapper.get("select", selected)) != selected:
		return {"ok": false, "reason": "Actor source mapper select register differs from its ordered writes."}
	return {"ok": true, "bank_low": expected_low, "bank_high": expected_high}


func _validate_slot09_source_manifest_hashes(manifest_path: String,
		hashes: Dictionary) -> bool:
	if not manifest_path.begins_with("res://reference/rom_extract/gameplay/") \
			or hashes.is_empty():
		return _fail("Slot-$09 source result lacks a packaged ROM-source manifest/hash set.")
	var manifest_file := FileAccess.open(manifest_path, FileAccess.READ)
	if manifest_file == null:
		return _fail("Slot-$09 source manifest is unavailable: %s." % manifest_path)
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		return _fail("Slot-$09 source manifest is malformed.")
	var manifest: Dictionary = parsed
	var rom_variant: Variant = manifest.get("rom", {})
	var manifest_rom_sha := String(manifest.get("rom_sha256", ""))
	if rom_variant is Dictionary:
		manifest_rom_sha = String(rom_variant.get("sha256", manifest_rom_sha))
	if manifest_rom_sha != ROM_SHA256 or bool(manifest.get("trace_state_included", true)) \
			or bool(manifest.get("runtime_rom_dependency", true)):
		return _fail("Slot-$09 source manifest targets another ROM or includes trace/runtime dependencies.")
	var spans_variant: Variant = manifest.get("spans", [])
	if not spans_variant is Array:
		return _fail("Slot-$09 source manifest omits its span list.")
	var base_path := manifest_path.get_base_dir()
	for filename_variant: Variant in hashes:
		var filename := String(filename_variant)
		var expected_hash := String(hashes[filename_variant]).to_lower()
		var found: Dictionary = {}
		for span_variant: Variant in spans_variant:
			if span_variant is Dictionary and String(span_variant.get("file", "")) == filename:
				found = span_variant
				break
		if found.is_empty() or String(found.get("sha256", "")).to_lower() != expected_hash:
			return _fail("Slot-$09 source hash `%s` is not listed by its manifest." % filename)
		var source_bytes := FileAccess.get_file_as_bytes(base_path.path_join(filename))
		if source_bytes.size() != int(found.get("length", -1)) \
				or _sha256(source_bytes) != expected_hash \
				or String(found.get("bytes", "")).replace(" ", "").to_lower() != source_bytes.hex_encode():
			return _fail("Slot-$09 source span failed its manifest-byte/hash check: %s." % filename)
	return true


func _validate_actor_chain_manifest(manifest_path: String, expected_schema: String,
		expected_spans: Dictionary) -> bool:
	var manifest_file := FileAccess.open(manifest_path, FileAccess.READ)
	if manifest_file == null:
		return _fail("Actor-seeded worker manifest is unavailable: %s." % manifest_path)
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		return _fail("Actor-seeded worker manifest is malformed: %s." % manifest_path)
	var manifest: Dictionary = parsed
	var rom_variant: Variant = manifest.get("rom", {})
	var spans_variant: Variant = manifest.get("spans", [])
	if String(manifest.get("schema", "")) != expected_schema \
			or not rom_variant is Dictionary \
			or String(rom_variant.get("sha256", "")) != ROM_SHA256 \
			or bool(manifest.get("trace_state_included", true)) \
			or bool(manifest.get("runtime_rom_dependency", true)) \
			or not spans_variant is Array:
		return _fail("Actor-seeded worker manifest targets unsupported ROM/source state: %s." % manifest_path)
	var base_path := manifest_path.get_base_dir()
	for filename_variant: Variant in expected_spans:
		var filename := String(filename_variant)
		var expected_hash := String(expected_spans[filename_variant]).to_lower()
		var found: Dictionary = {}
		for span_variant: Variant in spans_variant:
			if span_variant is Dictionary and String(span_variant.get("file", "")) == filename:
				found = span_variant
				break
		if found.is_empty() or String(found.get("sha256", "")).to_lower() != expected_hash:
			return _fail("Actor-seeded worker span `%s` is absent or has a different hash." % filename)
		var source_bytes := FileAccess.get_file_as_bytes(base_path.path_join(filename))
		if source_bytes.size() != int(found.get("length", -1)) \
				or _sha256(source_bytes) != expected_hash \
				or String(found.get("bytes", "")).replace(" ", "").to_lower() != source_bytes.hex_encode():
			return _fail("Actor-seeded worker bytes failed manifest/hash validation: %s." % filename)
	return true


func _update_nz_flags(status: int, value: int) -> int:
	var result := status & 0x7D
	if (value & 0x80) != 0:
		result |= 0x80
	if (value & 0xFF) == 0:
		result |= 0x02
	return result


## Adopts one monotonic state from the ROM-only, fixed-input KICK OFF source
## replay. This is an explicit route-bound replay contract, not a generic RNG
## producer; arbitrary input histories require live source-event execution.
func adopt_kickoff_rng_source_replay_state(rng_state: Dictionary) -> bool:
	if not _require_initialized():
		return false
	var frame := int(rng_state.get("last_source_frame", -1))
	var e1 := int(rng_state.get("e1", -1))
	var e2 := int(rng_state.get("e2", -1))
	var e3 := int(rng_state.get("e3", -1))
	if not bool(rng_state.get("configured", false)) \
			or not bool(rng_state.get("input_identity_bound", false)) \
			or String(rng_state.get("route_identity", "")) != "turkish-fresh-kickoff-capture-20261027" \
			or String(rng_state.get("input_timeline_sha256", "")) != "6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc" \
			or frame <= _kickoff_rng_replay_last_applied_frame \
			or frame > 8593 \
			or not _byte_arguments([e1, e2, e3]):
		return _fail("KICK OFF RNG replay state is not from the monotonic, hash-bound recorded route.")
	_ram[0x00E1] = e1
	_ram[0x00E2] = e2
	_ram[0x00E3] = e3
	_kickoff_rng_replay_last_applied_frame = frame
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
	var root_slot09: PackedByteArray = _sources["root_slot09_loop"]
	if root_slot09.slice(0, 5) != PackedByteArray([0xA9, 0x01, 0x20, 0x0F, 0xCB]) \
			or root_slot09.slice(root_slot09.size() - 3, root_slot09.size()) \
			!= PackedByteArray([0x4C, 0x86, 0xEB]):
		return _fail("Root slot `$09` loop no longer starts with its `$CB0F` yield or returns to `$EB86`.")
	var scheduler: PackedByteArray = _sources["scheduler"]
	var scheduler_prefix := PackedByteArray([
		0xA2, 0x01, 0xB5, 0x00, 0xF0, 0x08, 0xC9, 0xFF, 0xF0, 0x33,
		0xD6, 0x00, 0xF0, 0x14, 0x8A, 0x18, 0x69, 0x04, 0xAA, 0xE0,
		0x19, 0xD0, 0xEB, 0xA5, 0x1B, 0x10, 0xFC, 0x29, 0x7F, 0x85,
		0x1B, 0x4C, 0x97, 0xCA,
	])
	if scheduler.slice(0, scheduler_prefix.size()) != scheduler_prefix:
		return _fail("Six-slot scheduler scan and NMI latch instructions changed.")
	var nmi_return_expected := PackedByteArray([
		0xA5, 0x20, 0x09, 0x80, 0x85, 0x20, 0x85, 0x19, 0x8D,
		0x00, 0x20, 0x68, 0xA8, 0x68, 0xAA, 0x68, 0x40,
	])
	if _sources["nmi_return_enable"] != nmi_return_expected:
		return _fail("Normal NMI's `$C810->$C820` PPUCTRL-shadow restore bytes changed.")
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
	if _sources["scenario_actor_worker_seed"] != PackedByteArray([
			0xC9, 0xFF, 0xF0, 0x14, 0x8D, 0xEA, 0x05, 0xA2, 0x11, 0xA9,
			0xC8, 0x95, 0x01, 0xA9, 0x18, 0x95, 0x02, 0xA9, 0x7F, 0xA0,
			0xFF, 0x20, 0xE7, 0xCA,
		]) \
			or _sources["slot11_actor_worker_prefix"].size() != 74 \
			or _sources["slot11_actor_worker_prefix"].slice(0, 3) != PackedByteArray([0x4C, 0x0F, 0x80]) \
			or _sources["slot11_actor_worker_prefix"].slice(0x47, 0x4A) != PackedByteArray([0x20, 0x15, 0xC5]) \
			or _sources["slot11_actor_parameter_73_pointer"] != PackedByteArray([0x42, 0x9F]):
		return _fail("Scenario actor seed, bank-$18 setup/callsite, or parameter-$73 pointer bytes changed.")
	if _sources["yield_callsite"] != PackedByteArray([0x20, 0x15, 0xC5]) \
			or _sources["yield_trampoline"] != PackedByteArray([0x4C, 0x0F, 0xCB]):
		return _fail("Verified `$856F→$C515→$CB0F` yield path changed.")
	if _sources["callback_entry"][0] != 0x4C:
		return _fail("Bank-$0B callback entry no longer uses its verified absolute jump.")
	if not _callsite_matches_source(0x856F) or not _callsite_matches_source(0x8886) \
			or not _callsite_matches_source(0xCA4F) \
			or not _callsite_matches_source(0xEB88) \
			or not _callsite_matches_source(0xCBBE) \
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
	if source_pc == 0x8047:
		var actor_worker: PackedByteArray = _sources.get("slot11_actor_worker_prefix", PackedByteArray())
		return actor_worker.size() == 74 \
				and _sha256(actor_worker) == String(SOURCE_SPANS["slot11_actor_worker_prefix"]["sha256"]) \
				and actor_worker.slice(0x47, 0x4A) == PackedByteArray([0x20, 0x15, 0xC5]) \
				and _sources.get("yield_trampoline", PackedByteArray()) == PackedByteArray([0x4C, 0x0F, 0xCB])
	if source_pc == 0xCBBE:
		var scenario_code: PackedByteArray = _sources.get("scenario_queue", PackedByteArray())
		return scenario_code == PackedByteArray([0x8D, 0x18, 0x05, 0xA9, 0x80, 0x8D, 0x16, 0x05,
				0xA9, 0x00, 0x85, 0x05, 0xA9, 0x00, 0x20, 0x0F, 0xCB, 0x60]) \
				and scenario_code.slice(14, 17) == PackedByteArray([0x20, 0x0F, 0xCB])
	if source_pc == 0xEB88:
		var root_code: PackedByteArray = _sources.get("root_slot09_loop", PackedByteArray())
		return root_code.size() == 130 \
				and root_code.slice(0, 5) == PackedByteArray([0xA9, 0x01, 0x20, 0x0F, 0xCB])
	if source_pc == 0xDADF:
		var scenario_wait := FileAccess.get_file_as_bytes(
				"res://reference/rom_extract/gameplay/fresh_daaa_continuation/fixed_scenario_wait_DADD_DAE9.bin")
		return scenario_wait == PackedByteArray([
			0xA9, 0x01, 0x20, 0x0F, 0xCB, 0xAD, 0x1C, 0x00, 0x29, 0xC0, 0xF0, 0xF4]) \
				and scenario_wait.slice(2, 5) == PackedByteArray([0x20, 0x0F, 0xCB])
	if source_pc == 0xCA4F:
		var root_code: PackedByteArray = _sources.get("root_slot01_startup", PackedByteArray())
		return root_code.size() == 48 and root_code.slice(0x2D, 0x30) == PackedByteArray([0x20, 0x0F, 0xCB])
	if source_pc == 0x8886:
		var worker_call: PackedByteArray = _sources.get("bank18_worker_yield_callsite", PackedByteArray())
		var trampoline: PackedByteArray = _sources.get("yield_trampoline", PackedByteArray())
		return worker_call == PackedByteArray([0x20, 0x15, 0xC5]) \
				and trampoline == PackedByteArray([0x4C, 0x0F, 0xCB])
	if source_pc == 0xCC50:
		var waiter := FileAccess.get_file_as_bytes(SLOT11_RESUME_WAITER_PATH)
		return waiter.size() == 23 and _sha256(waiter) == SLOT11_RESUME_WAITER_SHA256 \
				and waiter.slice(10, 13) == PackedByteArray([0x20, 0x0F, 0xCB])
	if source_pc in [0xCCA0, 0xCCCE]:
		var tail := FileAccess.get_file_as_bytes(
				"res://reference/rom_extract/gameplay/slot11_actor_worker_resume_wait/fixed_wait_counter_tail_CC9E_CCD1.bin")
		var offset := source_pc - 0xCC9E
		return tail.size() == 52 \
				and _sha256(tail) == "28ae864c35cf13601f8cb93f4bc13f0cadcd64b9d401fff6f0bef8e2b656bee0" \
				and offset >= 0 and offset + 3 <= tail.size() \
				and tail.slice(offset, offset + 3) == PackedByteArray([0x20, 0x0F, 0xCB])
	if source_pc == 0xA217:
		var animation_gate := FileAccess.get_file_as_bytes(
				"res://reference/rom_extract/gameplay/slot11_actor_worker_resume_wait/bank1b_actor_animation_gate_A1EB_A219.bin")
		return animation_gate.size() == 47 \
				and _sha256(animation_gate) == "7cf2b10130708c5b0a722741eb60d27e732672730c7bbfb515dd1f9a17122618" \
				and animation_gate.slice(0x2C, 0x2F) == PackedByteArray([0x20, 0x15, 0xC5]) \
				and _sources.get("yield_trampoline", PackedByteArray()) == PackedByteArray([0x4C, 0x0F, 0xCB])
	if source_pc == 0x85BE:
		var map_worker := FileAccess.get_file_as_bytes(MAP42_WORKER_SOURCE_PATH)
		return map_worker.size() == 0x50 and _sha256(map_worker) == MAP42_WORKER_SOURCE_SHA256 \
				and map_worker.slice(0x4C, 0x50) == PackedByteArray([0x20, 0x15, 0xC5, 0x60])
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
	return source_pc == 0x8047 or source_pc == 0x856F or source_pc == 0x85BE or source_pc == 0x8886 or source_pc in [0xCC50, 0xCCA0, 0xCCCE, 0xA217] or source_pc == 0xCA4F \
			or source_pc == 0xEB88 or source_pc == 0xCBBE or source_pc == 0xDADF


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
