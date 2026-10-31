extends RefCounted
class_name RomSlot11ActorWorkerResumeExecutor
## Executes the source-backed slot-$11 resume from `$804A` through the first
## `$CC50->$CB0F` task-save entry. This is a narrow ROM-byte executor, not a
## general 6502 interpreter or a timing/PPU/APU emulator.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const MANIFEST_PATH := "res://reference/rom_extract/gameplay/slot11_actor_worker_resume_wait/manifest.json"
const ROOT := "res://reference/rom_extract/gameplay/slot11_actor_worker_resume_wait/"
const WORKER_FILE := "bank18_actor_worker_resume_804a_80fd.bin"
const STREAM_EVENT_DISPATCH_FILE := "bank18_actor_stream_dispatch_8218_822e.bin"
const STREAM_SHORT_EVENT_FILE := "bank18_actor_stream_short_event_decoder_81d1_81e4.bin"
const STREAM_FILE := "bank18_actor_stream_f4_f5_9f42_9f53.bin"
const STREAM_FOLLOWUP_FILE := "bank18_actor_stream_followup_9f54_9f7f.bin"
const ACTOR_EVENT_STREAM_FILE := "bank19_actor_event_stream_a3c9_a43b.bin"
const SELECTOR_FILE := "bank18_match_index_pointer_resolver_8122_8138.bin"
const F5_HANDLER_FILE := "bank18_actor_stream_command_f5_81fd_8200.bin"
const C52D_FILE := "fixed_c52d_jump_to_cc46.bin"
const WAITER_FILE := "fixed_task_yield_waiter_cc46_cc5d.bin"
const PACKET_BUILDER_FILE := "fixed_wait_packet_builder_CC53_CC9E.bin"
const COUNTER_TAIL_FILE := "fixed_wait_counter_tail_CC9E_CCD1.bin"
const F5_TAIL_FILE := "bank18_actor_stream_f5_tail_8200_8217.bin"
const C560_STUB_FILE := "fixed_c560_bank1a_call_stub.bin"
const CF72_WRAPPER_FILE := "fixed_cf72_bank1a_call_and_restore.bin"
const BANK1A_ENTRY_FILE := "bank1a_worker_entry_802a_802d.bin"
const ANIMATION_GATE_FILE := "bank1b_actor_animation_gate_A1EB_A219.bin"
const ANIMATION_INDEX_FILE := "bank1b_actor_animation_index_0D_A2AC_A2AD.bin"
const ANIMATION_COMMAND_LOOP_FILE := "bank1b_actor_animation_command_loop_A21A_A291.bin"
const ANIMATION_STREAM_FILE := "bank1b_actor_animation_stream_0D_A425_A426.bin"
const ANIMATION_POINTER_FILE := "bank1b_actor_animation_pointer_00_A42A_A42B.bin"
const ANIMATION_PPU_PACKETS_FILE := "bank1b_actor_animation_ef_00_ppu_packets_A46A_A48E.bin"
const MAPPER_HELPER_PATH := "res://reference/rom_extract/gameplay/ee9f_empty_actor_call/fixed_mapper_helper_CE2D_CE49.bin"
const WORKER_PREFIX_PATH := "res://reference/rom_extract/gameplay/task_context/bank18_actor_worker_entry_8000_804A.bin"
const INLINE_DISPATCH_FILE := "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/fixed_dispatch_C509_C50C.bin"
const INLINE_DISPATCH_SHA256 := "3b507ee4745afd5b11dda219b523c39c7e9a8881d856592d8908bf535fd63441"
const TRAMPOLINE_FILE := "res://reference/rom_extract/gameplay/fresh_daaa_continuation/fixed_branch_table_dispatch_CB99_CBAF.bin"
const TRAMPOLINE_SHA256 := "1f8058f9fd70aeec319a32433feb0c102c72e0f5131571a0da8bf89ef84a2d54"
const SLOT_11 := 0x11
const RAM_SIZE := 0x800
const STACK_SIZE := 0x100
const P_C := 0x01
const P_Z := 0x02
const P_V := 0x40
const P_N := 0x80

var error_message := ""
var _configured := false
var _sources: Dictionary = {}


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_sources.clear()
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return _fail("Slot-$11 resume source manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		return _fail("Slot-$11 resume source manifest is malformed.")
	var manifest: Dictionary = parsed
	if String(manifest.get("rom_sha256", "")) != ROM_SHA256:
		return _fail("Slot-$11 resume manifest targets another ROM revision.")
	var required := {
		WORKER_FILE: [0x804A, 0x03005A, 179, "9c07722c85a0670f8986a7e7a680bc205a587881383fd84276e520806f465c6e"],
		STREAM_EVENT_DISPATCH_FILE: [0x8218, 0x030228, 22, "a46488bd47acb67282e03aa63e4111b7efc1677dc8f10dc52e90a2d80ae7aa5c"],
		STREAM_SHORT_EVENT_FILE: [0x81D1, 0x0301E1, 19, "7e59d0713a7eb14d55dcca569ff75b2e6fea37d394fa72531eabcfabe4c106be"],
		STREAM_FILE: [0x9F42, 0x031F52, 18, "907c3653f2e64fa9d27a0a14a7dd38e404f0f1c05a97c0367be24e587f5ebadf"],
		STREAM_FOLLOWUP_FILE: [0x9F54, 0x031F64, 44, "79be558cb1fe9bfbf950a23486ed0da89c1dc37e20daa52feed8f6a124225fe4"],
		ACTOR_EVENT_STREAM_FILE: [0xA3C9, 0x0323D9, 114, "98eb047a4e32fafe77d2285722a236b891fb01441b845e2d1c1fc94dfeaae314"],
		SELECTOR_FILE: [0x8122, 0x030132, 22, "f4acc27853404adda00ba3dcee5f5f4ecdb2939a5d026a6d8f459261497d35b0"],
		F5_HANDLER_FILE: [0x81FD, 0x03020D, 3, "9ae06ade354ced65b80ae98704cd748b28b3fb80829dae0172ce09859fa37405"],
		C52D_FILE: [0xC52D, 0x03C53D, 3, "eb93189d38ebaea8201970900e5b276a27c54c6fa2001a705945cb1d5172f371"],
		WAITER_FILE: [0xCC46, 0x03CC56, 23, "dce4d011f0e612ea074e546e43c28c5395220f2af924a49aee4b35c2491775e3"],
		PACKET_BUILDER_FILE: [0xCC53, 0x03CC63, 75, "681bf402c35efba946da16d63cb53787bf50ed5ba87261929c10d19906b66d0c"],
		COUNTER_TAIL_FILE: [0xCC9E, 0x03CCAE, 52, "28ae864c35cf13601f8cb93f4bc13f0cadcd64b9d401fff6f0bef8e2b656bee0"],
		F5_TAIL_FILE: [0x8200, 0x030210, 24, "f99ead3dbc9481250bab0c306693651ab2ac705bd5feeb82ea3975167c3663a0"],
		C560_STUB_FILE: [0xC560, 0x03C570, 3, "170b3801f4df2a5789a9ef9fbdc6c389c58afdad9c58a94d3c7fad8e6563ccbc"],
		CF72_WRAPPER_FILE: [0xCF72, 0x03CF82, 29, "8ef4c31ce9f19ea12db252480ab5342a4429e37c3f81148bdde0286ad03b3c13"],
		BANK1A_ENTRY_FILE: [0x802A, 0x03403A, 3, "d8ec35aefd2671a7a810a2fa342db297bfb35011862ec3b907aa09fced64da90"],
		ANIMATION_GATE_FILE: [0xA1EB, 0x0361FB, 47, "7cf2b10130708c5b0a722741eb60d27e732672730c7bbfb515dd1f9a17122618"],
		ANIMATION_INDEX_FILE: [0xA2AC, 0x0362BC, 2, "588eba1d324cbcd9381797960eb1a81d099ef8277be6a1f92b935389647e1ae2"],
		ANIMATION_COMMAND_LOOP_FILE: [0xA21A, 0x03622A, 120, "c315087f3f361a05abbbc63748d1c890aea1a2be7f40fb325150cb71688f1cfd"],
		ANIMATION_STREAM_FILE: [0xA425, 0x036435, 2, "c80e57d27a62d8f8ae98f6976e64d0a1e4f9cebe78cf5b16e79ecd927b985da6"],
		ANIMATION_POINTER_FILE: [0xA42A, 0x03643A, 2, "48dceebd8704067b3697888d1f847f69d77a5fbbcb8e57ac3a9a0b41205e47cf"],
		ANIMATION_PPU_PACKETS_FILE: [0xA46A, 0x03647A, 37, "4fd878c7cc59ffec84362bfc6f973474f72c83087d302687958b844682b2d678"],
	}
	var entries_by_file: Dictionary = {}
	for entry_variant: Variant in manifest.get("spans", []):
		if entry_variant is Dictionary:
			var entry: Dictionary = entry_variant
			entries_by_file[String(entry.get("file", ""))] = entry
	for file_name_variant: Variant in required:
		var file_name := String(file_name_variant)
		var spec: Array = required[file_name]
		var entry: Dictionary = entries_by_file.get(file_name, {})
		var path := ROOT + file_name
		if entry.is_empty() or _manifest_hex(entry.get("cpu_address", "0x0")) != int(spec[0]) \
				or _manifest_hex(entry.get("file_offset", "0x0")) != int(spec[1]) \
				or int(entry.get("length", -1)) != int(spec[2]) \
				or String(entry.get("sha256", "")) != String(spec[3]) \
				or not FileAccess.file_exists(path):
			return _fail("Manifest mapping or source file differs for %s: expected=%s got cpu=$%04X offset=$%06X length=%d hash=%s exists=%s." % [
				file_name, str(spec), _manifest_hex(entry.get("cpu_address", "0x0")),
				_manifest_hex(entry.get("file_offset", "0x0")), int(entry.get("length", -1)),
				String(entry.get("sha256", "")), str(FileAccess.file_exists(path))])
		var source := FileAccess.get_file_as_bytes(path)
		if source.size() != int(spec[2]) or _sha256(source) != String(spec[3]) \
				or String(entry.get("bytes", "")).replace(" ", "").to_lower() != source.hex_encode():
			return _fail("Packaged ROM bytes failed validation for %s." % file_name)
		_sources[file_name] = source
	var mapper_helper := FileAccess.get_file_as_bytes(MAPPER_HELPER_PATH)
	if mapper_helper != PackedByteArray([
		0xA5, 0x22, 0x09, 0x06, 0x85, 0x23, 0x8D, 0x00, 0x80,
		0xA5, 0x24, 0x8D, 0x01, 0x80, 0xA5, 0x22, 0x09, 0x07,
		0x85, 0x23, 0x8D, 0x00, 0x80, 0xA5, 0x25, 0x8D, 0x01,
		0x80, 0x60]) \
			or _sha256(mapper_helper) != "6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c":
		return _fail("The shared `$CE2D->$CE49` MMC3 pair mapper source span failed validation.")
	_sources["mapper_helper"] = mapper_helper
	var worker_prefix := FileAccess.get_file_as_bytes(WORKER_PREFIX_PATH)
	if worker_prefix.size() != 74 \
			or _sha256(worker_prefix) != "2187af6881ea2f4e7eb16c0c5550bb24ead076be918d429d8ab63564ed8fd46c" \
			or worker_prefix.slice(0x45, 0x4A) != PackedByteArray([0xA9, 0x01, 0x20, 0x15, 0xC5]):
		return _fail("The shared bank-$18 `$8045->$8047` actor yield callsite failed validation.")
	_sources["worker_prefix"] = worker_prefix
	var inline_dispatch := PackedByteArray()
	var trampoline := PackedByteArray()
	if FileAccess.file_exists(INLINE_DISPATCH_FILE):
		inline_dispatch = FileAccess.get_file_as_bytes(INLINE_DISPATCH_FILE)
	if FileAccess.file_exists(TRAMPOLINE_FILE):
		trampoline = FileAccess.get_file_as_bytes(TRAMPOLINE_FILE)
	if inline_dispatch != PackedByteArray([0x4C, 0x99, 0xCB]) \
			or _sha256(inline_dispatch) != INLINE_DISPATCH_SHA256 \
			or trampoline != PackedByteArray([
			0x0A, 0xA8, 0x68, 0x85, 0x36, 0x68, 0x85, 0x37, 0xC8, 0xB1, 0x36,
			0x48, 0xC8, 0xB1, 0x36, 0x85, 0x37, 0x68, 0x85, 0x36, 0x6C, 0x36, 0x00]) \
			or _sha256(trampoline) != TRAMPOLINE_SHA256:
		return _fail("The shared `$C509->$CB99` inline-table trampoline differs from its verified ROM span.")
	_sources["inline_dispatch"] = inline_dispatch
	_sources["trampoline"] = trampoline
	if not _expect(WORKER_FILE, 0x804A, [0x20, 0x53, 0x80, 0x20, 0x60, 0xC5, 0x4C, 0x45, 0x80]) \
			or not _expect(WORKER_FILE, 0x8062, [0xAD, 0xE4, 0x05, 0x20, 0x09, 0xC5, 0x6E, 0x80]) \
			or not _expect(WORKER_FILE, 0x8068, [0x6E, 0x80, 0x18, 0x82]) \
			or not _expect(STREAM_EVENT_DISPATCH_FILE, 0x8218, [0xAC, 0xE5, 0x05, 0xB1, 0x5F, 0xC9, 0x90, 0xB0, 0x0D]) \
			or not _expect(STREAM_SHORT_EVENT_FILE, 0x81D1, [0x4A, 0xA2, 0x00, 0xC9, 0x01, 0x90, 0x0B, 0xE8, 0xC9, 0x05]) \
			or not _expect(WORKER_FILE, 0x8080, [0x8D, 0xE9, 0x05, 0xEE, 0xE4, 0x05, 0x60]) \
			or not _expect(WORKER_FILE, 0x806E, [0xAC, 0xE5, 0x05, 0xEE, 0xE5, 0x05, 0xB1, 0x5F, 0xC9, 0xF0]) \
			or not _expect(WORKER_FILE, 0x80CB, [0xAC, 0xE5, 0x05, 0xB1, 0x5F, 0x20, 0xEA, 0x80]) \
			or not _expect(WORKER_FILE, 0x80D3, [0x8A, 0x0A, 0x38, 0x6D, 0xE5, 0x05, 0xA8, 0xB1, 0x5F, 0xAA, 0xC8, 0xB1, 0x5F, 0x86, 0x5F, 0x85, 0x60, 0xA9, 0x00, 0x8D, 0xE5, 0x05, 0x60]) \
			or not _expect(WORKER_FILE, 0x8087, [0x29, 0x0F, 0x20, 0x09, 0xC5]) \
			or not _expect(WORKER_FILE, 0x80EA, [0x20, 0x09, 0xC5]) \
			or not _expect(SELECTOR_FILE, 0x8122, [0xA2, 0x00, 0xA5, 0x26, 0xDD, 0x31, 0x81]) \
			or not _expect(F5_HANDLER_FILE, 0x81FD, [0x20, 0x2D, 0xC5]) \
			or not _expect(C52D_FILE, 0xC52D, [0x4C, 0x46, 0xCC]) \
			or not _expect(WAITER_FILE, 0xCC46, [0xA9, 0x00, 0x8D, 0xF4, 0x05, 0xA9, 0x06, 0x48, 0xA9, 0x01, 0x20, 0x0F, 0xCB]) \
			or not _expect(PACKET_BUILDER_FILE, 0xCC53, [0xAD, 0x15, 0x05, 0xD0, 0xF6, 0xA9, 0x01, 0x8D, 0x15, 0x05]) \
			or not _expect(PACKET_BUILDER_FILE, 0xCC5D, [0xA0, 0x4F, 0xA2, 0x00, 0x8A, 0x9D, 0xA5, 0x04, 0xE8, 0x88, 0xD0, 0xF9]) \
			or not _expect(PACKET_BUILDER_FILE, 0xCC93, [0xA9, 0x80, 0x8D, 0x15, 0x05, 0x68, 0x38, 0xE9, 0x01, 0x10, 0xAF]) \
			or not _expect(COUNTER_TAIL_FILE, 0xCC9E, [0xA9, 0x01, 0x20, 0x0F, 0xCB, 0xAD, 0x15, 0x05, 0xD0, 0xF6]) \
			or not _expect(COUNTER_TAIL_FILE, 0xCCAF, [0x8D, 0xA5, 0x04, 0xA9, 0xE0, 0x8D, 0xA6, 0x04, 0xA9, 0x23, 0x8D, 0xA7, 0x04]) \
			or not _expect(COUNTER_TAIL_FILE, 0xCCBC, [0xA2, 0x00, 0x8A, 0x9D, 0xA8, 0x04, 0xE8, 0xE0, 0x21, 0xD0, 0xF8, 0xA9, 0x80, 0x8D, 0x15, 0x05, 0xA9, 0x01, 0x20, 0x0F, 0xCB, 0x60]) \
			or not _expect(F5_TAIL_FILE, 0x8200, [0xA9, 0x0D, 0x8D, 0xF3, 0x05, 0xA9, 0x80, 0x8D, 0xF4, 0x05]) \
			or not _expect(F5_TAIL_FILE, 0x820A, [0xAC, 0xE5, 0x05, 0xB1, 0x5F, 0x8D, 0xE9, 0x05, 0xEE, 0xE5, 0x05, 0x68, 0x68, 0x60]) \
			or not _expect(C560_STUB_FILE, 0xC560, [0x4C, 0x72, 0xCF]) \
			or not _expect(CF72_WRAPPER_FILE, 0xCF72, [0x48, 0xA5, 0x22, 0xA9, 0x1A, 0x85, 0x24, 0xA9, 0x1B, 0x85, 0x25, 0x20, 0x2D, 0xCE]) \
			or not _expect(BANK1A_ENTRY_FILE, 0x802A, [0x4C, 0xEB, 0xA1]) \
			or not _expect(ANIMATION_GATE_FILE, 0xA1EB, [0xAD, 0xF4, 0x05, 0xD0, 0x01, 0x60, 0x10, 0x19]) \
			or not _expect(ANIMATION_GATE_FILE, 0xA20C, [0xAD, 0xF5, 0x05, 0xF0, 0x04, 0xCE, 0xF5, 0x05, 0x60]) \
			or not _expect(CF72_WRAPPER_FILE, 0xCF84, [0xA9, 0x18, 0x85, 0x24, 0xA9, 0x19, 0x85, 0x25, 0x4C, 0x2D, 0xCE]) \
			or not _expect(ANIMATION_GATE_FILE, 0xA215, [0xA9, 0x01, 0x20, 0x15, 0xC5]) \
			or not _expect(ANIMATION_INDEX_FILE, 0xA2AC, [0x25, 0xA4]):
		return _fail("A source opcode in the `$804A->$CC50` bounded path changed.")
	if _sources[STREAM_FILE] != PackedByteArray([
		0xF4, 0x04, 0x52, 0x9F, 0xE1, 0x9F, 0x8B, 0xA0, 0x2A,
		0xA1, 0x25, 0xA2, 0x92, 0xA2, 0x02, 0xA3, 0xF5, 0x02]):
		return _fail("The packaged actor stream no longer contains the audited F4-to-F5 bytes.")
	_configured = true
	return true


## Consumes only a live yielded-task scheduler snapshot restored to `$804A`.
## Output PC is `$CB0F` after the actual `$CC50 JSR $CB0F` stack entry.
func execute_from_resumed_slot11_boundary(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		return _reject("Configure hash-checked slot-$11 ROM source spans first.")
	var valid := _validate_boundary(boundary)
	if not bool(valid.get("ok", false)):
		return _reject(String(valid.get("reason", "Unsupported scheduler boundary.")))
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	var cpu := {
		"pc": int(boundary["pc"]), "sp": int(boundary["sp"]),
		"a": int(boundary["a"]) & 0xFF, "x": int(boundary["x"]) & 0xFF,
		"y": int(boundary["y"]) & 0xFF, "p": int(boundary["p"]) & 0xFF,
		"p_known_mask": int(boundary["p_known_mask"]) & 0xFF,
	}
	var entry_cpu := cpu.duplicate(true)
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var mapper: Dictionary = boundary.get("mapper", {
		"bank_low": int(boundary["bank_low"]), "bank_high": int(boundary["bank_high"]),
	})
	mapper = mapper.duplicate(true)
	var ram_writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = []
	var callsite_registers: Dictionary = {}
	var callsite_stack := PackedByteArray()
	if int(ram[0x05E3]) != 1 or int(ram[0x05E9]) != 0 or int(ram[0x05E4]) != 0 \
			or int(ram[0x05E5]) != 0 or int(ram[0x005F]) != 0x42 \
			or int(ram[0x0060]) != 0x9F or int(ram[0x0026]) != 0:
		return _unsupported("Live worker state does not select the audited initial `$F4 04` match-zero stream branch.")

	# `$804A JSR $8053`; execute the ROM's `$05E3/$05E9/$05E4` guards.
	instruction_pcs.append(0x804A)
	_jsr(cpu, stack, stack_writes, 0x804A, 0x8053)
	instruction_pcs.append(0x8053)
	_set_a(cpu, int(ram[0x05E3]))
	_read_event(source_reads, 0x8053, 0x05E3, int(ram[0x05E3]), "worker_active_flag")
	if int(cpu["a"]) != 1:
		return _unsupported("The source `$8053` inactive-worker RTS branch is outside this route slice.")
	instruction_pcs.append(0x8056)
	instruction_pcs.append(0x8059)
	_set_a(cpu, int(ram[0x05E9]))
	_read_event(source_reads, 0x8059, 0x05E9, int(ram[0x05E9]), "worker_delay")
	instruction_pcs.append(0x805C)
	if int(cpu["a"]) != 0:
		return _unsupported("The live `$05E9` delay-countdown branch does not reach the audited F4/F5 dispatch.")
	instruction_pcs.append(0x8062)
	_set_a(cpu, int(ram[0x05E4]))
	_read_event(source_reads, 0x8062, 0x05E4, int(ram[0x05E4]), "actor_stream_dispatch_index")
	if int(cpu["a"]) != 0:
		return _unsupported("Only stream-dispatch index `$00` is packaged for this first resume.")
	instruction_pcs.append(0x8065)
	_jsr(cpu, stack, stack_writes, 0x8065, 0xC509)
	var first_handler := _inline_dispatch(cpu, ram, stack, ram_writes, stack_writes,
		stack_reads, source_reads, 0x8065, 0x8068, instruction_pcs)
	if first_handler != 0x806E:
		return _unsupported("Live `$05E4` resolves outside the packaged first stream handler.")

	# `$806E` parses the F4 command. Its selector `$04` reads the match-zero
	# pointer row at `$9F44/$9F45`, then the same source loop sees `$F5` at `$9F52`.
	while true:
		instruction_pcs.append(0x806E)
		_set_y(cpu, int(ram[0x05E5]))
		_read_event(source_reads, 0x806E, 0x05E5, int(ram[0x05E5]), "actor_stream_index")
		instruction_pcs.append(0x8071)
		_write_ram(ram, ram_writes, 0x05E5, (int(ram[0x05E5]) + 1) & 0xFF, 0x8071)
		_read_event(source_reads, 0x8074, 0x005F, int(ram[0x005F]), "actor_stream_pointer_low")
		_read_event(source_reads, 0x8074, 0x0060, int(ram[0x0060]), "actor_stream_pointer_high")
		var stream_address := ((int(ram[0x0060]) << 8) | int(ram[0x005F])) + int(cpu["y"])
		var stream_byte := _read_stream_byte(stream_address)
		if stream_byte < 0:
			return _unsupported("Actor stream pointer/index leaves the hash-checked `$9F42-$9F53` span.")
		_read_event(source_reads, 0x8074, stream_address, stream_byte, "actor_stream_command")
		_set_a(cpu, stream_byte)
		instruction_pcs.append(0x8076)
		_compare_a(cpu, 0xF0)
		instruction_pcs.append(0x8078)
		if stream_byte < 0xF0:
			return _unsupported("The source takes the timed `$05E9` payload branch; it is not the immediate F4/F5 yield.")
		instruction_pcs.append(0x807A)
		_jsr(cpu, stack, stack_writes, 0x807A, 0x8087)
		instruction_pcs.append(0x8087)
		_set_a(cpu, stream_byte & 0x0F)
		instruction_pcs.append(0x8089)
		_jsr(cpu, stack, stack_writes, 0x8089, 0xC509)
		var command_handler := _inline_dispatch(cpu, ram, stack, ram_writes,
			stack_writes, stack_reads, source_reads, 0x8089, 0x808C, instruction_pcs)
		if command_handler == 0x80CB:
			# `$80CB`: selector byte 04, table lookup at `$8122`, then pointer fetch.
			instruction_pcs.append(0x80CB)
			_set_y(cpu, int(ram[0x05E5]))
			_read_event(source_reads, 0x80CE, 0x005F, int(ram[0x005F]), "F4_stream_pointer_low")
			_read_event(source_reads, 0x80CE, 0x0060, int(ram[0x0060]), "F4_stream_pointer_high")
			var selector_address := ((int(ram[0x0060]) << 8) | int(ram[0x005F])) + int(cpu["y"])
			var selector := _read_stream_byte(selector_address)
			if selector != 0x04:
				return _unsupported("F4 selector byte differs from the supported `$04` pointer command.")
			_read_event(source_reads, 0x80CE, selector_address, selector, "F4_selector")
			_set_a(cpu, selector)
			instruction_pcs.append(0x80D0)
			_jsr(cpu, stack, stack_writes, 0x80D0, 0x80EA)
			instruction_pcs.append(0x80EA)
			_jsr(cpu, stack, stack_writes, 0x80EA, 0xC509)
			var row_handler := _inline_dispatch(cpu, ram, stack, ram_writes,
				stack_writes, stack_reads, source_reads, 0x80EA, 0x80ED, instruction_pcs)
			if row_handler != 0x8122:
				return _unsupported("F4 selector `$04` no longer resolves to its ROM row selector `$8122`.")
			var selected_row := _run_match_index_selector(cpu, ram, source_reads, instruction_pcs)
			if selected_row != 0:
				return _unsupported("The live `$0026` selector chooses a pointer row outside this match-zero stream slice.")
			_rts(cpu, stack, stack_reads, 0x8130)
			# Resume `$80CB` after JSR $80EA.
			instruction_pcs.append(0x80D3)
			_set_a(cpu, int(cpu["x"]))
			instruction_pcs.append(0x80D4)
			var doubled_row := (int(cpu["a"]) << 1) & 0xFF
			_set_flag(cpu, P_C, (int(cpu["a"]) & 0x80) != 0)
			_set_a(cpu, doubled_row)
			instruction_pcs.append(0x80D5)
			_set_flag(cpu, P_C, true)
			instruction_pcs.append(0x80D6)
			var adc_before := int(cpu["a"]) & 0xFF
			var adc_operand := int(ram[0x05E5])
			_read_event(source_reads, 0x80D6, 0x05E5, adc_operand, "F4_pointer_row_index")
			var adc_carry := 1 if (int(cpu["p"]) & P_C) != 0 else 0
			var adc_sum := adc_before + adc_operand + adc_carry
			var pointer_offset := adc_sum & 0xFF
			_set_flag(cpu, P_C, adc_sum > 0xFF)
			_set_flag(cpu, P_V, ((~(adc_before ^ adc_operand) & (adc_before ^ adc_sum)) & 0x80) != 0)
			_set_a(cpu, pointer_offset)
			instruction_pcs.append(0x80D9)
			_set_y(cpu, int(cpu["a"]))
			var low_address := ((int(ram[0x0060]) << 8) | int(ram[0x005F])) + pointer_offset
			var pointer_low := _read_stream_byte(low_address)
			var pointer_high := _read_stream_byte(low_address + 1)
			if pointer_low != 0x52 or pointer_high != 0x9F:
				return _unsupported("F4 pointer selection does not resolve to the verified match-zero target `$9F52`.")
			instruction_pcs.append(0x80DA)
			_read_event(source_reads, 0x80DA, low_address, pointer_low, "F4_target_pointer_low")
			_set_a(cpu, pointer_low)
			instruction_pcs.append(0x80DC)
			_set_x(cpu, int(cpu["a"]))
			instruction_pcs.append(0x80DD)
			_set_y(cpu, (int(cpu["y"]) + 1) & 0xFF)
			instruction_pcs.append(0x80DE)
			_read_event(source_reads, 0x80DE, low_address + 1, pointer_high, "F4_target_pointer_high")
			_set_a(cpu, pointer_high)
			instruction_pcs.append(0x80E0)
			_write_ram(ram, ram_writes, 0x005F, int(cpu["x"]), 0x80E0)
			instruction_pcs.append(0x80E2)
			_write_ram(ram, ram_writes, 0x0060, int(cpu["a"]), 0x80E2)
			instruction_pcs.append(0x80E4)
			_set_a(cpu, 0)
			instruction_pcs.append(0x80E6)
			_write_ram(ram, ram_writes, 0x05E5, 0, 0x80E6)
			instruction_pcs.append(0x80E9)
			_rts(cpu, stack, stack_reads, 0x80E9)
			# The handler RTS consumes the `$807A JSR $8087` return word and
			# resumes at `$807D`, whose ROM instruction jumps back to `$806E`.
			if int(cpu["pc"]) != 0x807D:
				return _unsupported("The F4 handler RTS did not restore the audited `$807D` parser continuation.")
			instruction_pcs.append(0x807D)
			continue
		if command_handler == 0x81FD:
			# `$81FD JSR $C52D`, `$C52D JMP $CC46`, then the verified waiter.
			instruction_pcs.append(0x81FD)
			_jsr(cpu, stack, stack_writes, 0x81FD, 0xC52D)
			instruction_pcs.append(0xC52D)
			cpu["pc"] = 0xCC46
			_set_a(cpu, 0)
			instruction_pcs.append(0xCC46)
			_write_ram(ram, ram_writes, 0x05F4, 0, 0xCC48)
			instruction_pcs.append(0xCC4B)
			_set_a(cpu, 6)
			instruction_pcs.append(0xCC4D)
			_push(cpu, stack, stack_writes, int(cpu["a"]), 0xCC4D, "PHA")
			instruction_pcs.append(0xCC4E)
			_set_a(cpu, 1)
			instruction_pcs.append(0xCC50)
			cpu["pc"] = 0xCC50
			callsite_registers = cpu.duplicate(true)
			callsite_stack = stack.duplicate()
			_jsr(cpu, stack, stack_writes, 0xCC50, 0xCB0F)
			instruction_pcs.append(0xCB0F)
			if int(cpu["pc"]) != 0xCB0F or int(cpu["sp"]) != 0xC1 \
					or int(cpu["a"]) != 0x01 or int(cpu["x"]) != 0x52 \
					or int(cpu["y"]) != 0x0C \
					or int(stack[0xC2]) != 0x52 or int(stack[0xC3]) != 0xCC \
					or int(stack[0xC4]) != 0x06 or int(stack[0xC5]) != 0xFF \
					or int(stack[0xC6]) != 0x81 or int(stack[0xC7]) != 0x7C \
					or int(stack[0xC8]) != 0x80:
				return _reject("Source-derived `$CC50->$CB0F` stack frame failed its boundary invariant.")
			return _result(boundary, entry_cpu, entry_ram, entry_stack, cpu, mapper,
				ram, stack, ram_writes, stack_writes, stack_reads, source_reads,
				instruction_pcs, callsite_registers, callsite_stack)


		return _unsupported("F4/F5 stream opcode resolves outside the packaged source rows.")

	return _unsupported("The actor-stream loop left the bounded F4/F5 command path.")

## Executes the live nested wait resumed by the scheduler at `$CC53`. It follows
## the `$0515` branch and, when the queue is clear, builds one ROM-owned packet
## from the loop counter already present on the 6502 stack before yielding again
## at `$CC50`. The zero-counter tail beyond `$CC9E` remains out of scope.
func execute_from_slot11_waiter_resume_boundary(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		return _reject("Configure hash-checked slot-$11 ROM source spans first.")
	var valid := _validate_waiter_boundary(boundary)
	if not bool(valid.get("ok", false)):
		return _reject(String(valid.get("reason", "Unsupported slot-$11 waiter boundary.")))
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	var cpu := {
		"pc": int(boundary["pc"]), "sp": int(boundary["sp"]),
		"a": int(boundary["a"]) & 0xFF, "x": int(boundary["x"]) & 0xFF,
		"y": int(boundary["y"]) & 0xFF, "p": int(boundary["p"]) & 0xFF,
		"p_known_mask": int(boundary["p_known_mask"]) & 0xFF,
	}
	var entry_cpu := cpu.duplicate(true)
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var mapper: Dictionary = boundary.get("mapper", {
		"bank_low": int(boundary["bank_low"]), "bank_high": int(boundary["bank_high"]),
	}).duplicate(true)
	var ram_writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = []
	var callsite_registers: Dictionary = {}
	var callsite_stack := PackedByteArray()

	# `$CC53 LDA $0515 / BNE $CC4E`: a pending packet repeats the exact
	# source yield without consuming the caller's stack-resident pass counter.
	instruction_pcs.append(0xCC53)
	var pending_queue := int(ram[0x0515])
	_read_event(source_reads, 0xCC53, 0x0515, pending_queue, "ppu_queue_pending_flag")
	_set_a(cpu, pending_queue)
	instruction_pcs.append(0xCC56)
	if pending_queue != 0:
		instruction_pcs.append(0xCC4E)
		_set_a(cpu, 0x01)
		instruction_pcs.append(0xCC50)
		cpu["pc"] = 0xCC50
		callsite_registers = cpu.duplicate(true)
		callsite_stack = stack.duplicate()
		_jsr(cpu, stack, stack_writes, 0xCC50, 0xCB0F)
		instruction_pcs.append(0xCB0F)
		return _waiter_yield_result(boundary, entry_cpu, entry_ram, entry_stack,
			cpu, mapper, ram, stack, ram_writes, stack_writes, stack_reads,
			source_reads, instruction_pcs, callsite_registers, callsite_stack)

	# The cleared-queue branch sets the poll flag to one, then starts the packet
	# builder at `$CC5D`. The loop writes X into `$04A5,X` for Y=$4F..$01.
	instruction_pcs.append(0xCC58)
	_set_a(cpu, 0x01)
	instruction_pcs.append(0xCC5A)
	_write_ram(ram, ram_writes, 0x0515, 0x01, 0xCC5A)
	instruction_pcs.append(0xCC5D)
	_set_y(cpu, 0x4F)
	instruction_pcs.append(0xCC5F)
	_set_x(cpu, 0x00)
	while int(cpu["y"]) != 0:
		instruction_pcs.append(0xCC61)
		_set_a(cpu, int(cpu["x"]))
		instruction_pcs.append(0xCC62)
		_write_ram(ram, ram_writes, 0x04A5 + int(cpu["x"]), int(cpu["a"]), 0xCC62)
		instruction_pcs.append(0xCC65)
		_set_x(cpu, int(cpu["x"]) + 1)
		instruction_pcs.append(0xCC66)
		_set_y(cpu, int(cpu["y"]) - 1)
		instruction_pcs.append(0xCC67)
	_set_a(cpu, 0x18)
	instruction_pcs.append(0xCC69)
	_write_ram(ram, ram_writes, 0x04A5, 0x18, 0xCC6B)
	_write_ram(ram, ram_writes, 0x04C0, 0x18, 0xCC6E)
	_set_a(cpu, 0x20)
	_write_ram(ram, ram_writes, 0x04A6, 0x20, 0xCC73)
	_write_ram(ram, ram_writes, 0x04C1, 0x20, 0xCC76)

	# The ROM rotates the pass count into the packet header, then emits its
	# source-owned queue-ready flag before deciding whether to repeat.
	var pass_count := _pop(cpu, stack, stack_reads, 0xCC76)
	_push(cpu, stack, stack_writes, pass_count, 0xCC77, "PHA")
	_set_a(cpu, int(cpu["a"]) | 0x08)
	var carry := int(cpu["a"]) & 0x01
	_set_flag(cpu, P_C, carry != 0)
	_set_a(cpu, int(cpu["a"]) >> 1)
	var mem_value := int(ram[0x04A6])
	var rotated := ((0x80 if (int(cpu["p"]) & P_C) != 0 else 0) | (mem_value >> 1)) & 0xFF
	_set_flag(cpu, P_C, (mem_value & 0x01) != 0)
	_set_nz(cpu, rotated)
	_write_ram(ram, ram_writes, 0x04A6, rotated, 0xCC7B)
	carry = int(cpu["a"]) & 0x01
	_set_flag(cpu, P_C, carry != 0)
	_set_a(cpu, int(cpu["a"]) >> 1)
	mem_value = int(ram[0x04A6])
	rotated = ((0x80 if (int(cpu["p"]) & P_C) != 0 else 0) | (mem_value >> 1)) & 0xFF
	_set_flag(cpu, P_C, (mem_value & 0x01) != 0)
	_set_nz(cpu, rotated)
	_write_ram(ram, ram_writes, 0x04A6, rotated, 0xCC7F)
	_set_a(cpu, int(cpu["a"]) | 0x20)
	_write_ram(ram, ram_writes, 0x04A7, int(cpu["a"]), 0xCC84)
	_write_ram(ram, ram_writes, 0x04C2, int(cpu["a"]), 0xCC87)
	_read_event(source_reads, 0xCC8A, 0x04A6, int(ram[0x04A6]), "packet_address_high")
	_set_a(cpu, int(ram[0x04A6]))
	_set_flag(cpu, P_C, false)
	var adc_sum := int(cpu["a"]) + 0x20
	var adc_result := adc_sum & 0xFF
	_set_flag(cpu, P_C, adc_sum > 0xFF)
	_set_flag(cpu, P_V, ((~(int(cpu["a"]) ^ 0x20) & (int(cpu["a"]) ^ adc_result)) & 0x80) != 0)
	_set_a(cpu, adc_result)
	_write_ram(ram, ram_writes, 0x04C1, int(cpu["a"]), 0xCC90)
	_set_a(cpu, 0x80)
	_write_ram(ram, ram_writes, 0x0515, 0x80, 0xCC95)
	var decremented_count := _pop(cpu, stack, stack_reads, 0xCC98)
	_set_flag(cpu, P_C, true)
	var subtraction := decremented_count - 1
	_set_flag(cpu, P_C, subtraction >= 0)
	var result_count := subtraction & 0xFF
	_set_flag(cpu, P_V, (((decremented_count ^ result_count) & (decremented_count ^ 1) & 0x80) != 0))
	_set_a(cpu, result_count)
	instruction_pcs.append(0xCC9C)
	if (int(cpu["p"]) & P_N) != 0:
		# `$CC9E LDA #$01 / JSR $CB0F` waits for the pending `$0515` packet;
		# RTS returns to `$CCA3`, which polls the flag before building the final
		# `$23E0` packet.
		instruction_pcs.append(0xCC9E)
		_set_a(cpu, 0x01)
		instruction_pcs.append(0xCCA0)
		cpu["pc"] = 0xCCA0
		callsite_registers = cpu.duplicate(true)
		callsite_stack = stack.duplicate()
		_jsr(cpu, stack, stack_writes, 0xCCA0, 0xCB0F)
		instruction_pcs.append(0xCB0F)
		return _waiter_yield_result(boundary, entry_cpu, entry_ram, entry_stack,
			cpu, mapper, ram, stack, ram_writes, stack_writes, stack_reads,
			source_reads, instruction_pcs, callsite_registers, callsite_stack,
			0xCCA0, 0xCCA3, "slot11_actor_waiter_tail_at_cb0f_from_cca0")
	# `$CC9C BPL $CC4D` retains the decremented counter and returns to the
	# wait/yield call. The next scheduler dispatch re-enters at `$CC53`.
	_push(cpu, stack, stack_writes, int(cpu["a"]), 0xCC4D, "PHA")
	_set_a(cpu, 0x01)
	instruction_pcs.append(0xCC4E)
	instruction_pcs.append(0xCC50)
	cpu["pc"] = 0xCC50
	callsite_registers = cpu.duplicate(true)
	callsite_stack = stack.duplicate()
	_jsr(cpu, stack, stack_writes, 0xCC50, 0xCB0F)
	instruction_pcs.append(0xCB0F)
	return _waiter_yield_result(boundary, entry_cpu, entry_ram, entry_stack,
		cpu, mapper, ram, stack, ram_writes, stack_writes, stack_reads,
		source_reads, instruction_pcs, callsite_registers, callsite_stack)


## Resumes the counter-tail wait at `$CCA3`. A nonzero `$0515` returns to the
## same `$CCA0->$CB0F` wait; zero builds the final `$23E0` packet and yields at
## `$CCCE`. The following `$CCD1 RTS` remains a separate continuation.
func execute_from_slot11_waiter_tail_poll_boundary(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		return _reject("Configure hash-checked slot-$11 ROM source spans first.")
	var valid := _validate_waiter_tail_boundary(boundary)
	if not bool(valid.get("ok", false)):
		return _reject(String(valid.get("reason", "Unsupported slot-$11 counter-tail boundary.")))
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	var cpu := {
		"pc": int(boundary["pc"]), "sp": int(boundary["sp"]),
		"a": int(boundary["a"]) & 0xFF, "x": int(boundary["x"]) & 0xFF,
		"y": int(boundary["y"]) & 0xFF, "p": int(boundary["p"]) & 0xFF,
		"p_known_mask": int(boundary["p_known_mask"]) & 0xFF,
	}
	var entry_cpu := cpu.duplicate(true)
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var mapper: Dictionary = boundary.get("mapper", {
		"bank_low": int(boundary["bank_low"]), "bank_high": int(boundary["bank_high"]),
	}).duplicate(true)
	var ram_writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = [0xCCA3, 0xCCA6]
	var callsite_registers: Dictionary = {}
	var callsite_stack := PackedByteArray()
	var ready_flag := int(ram[0x0515])
	_read_event(source_reads, 0xCCA3, 0x0515, ready_flag, "counter_tail_queue_flag")
	_set_a(cpu, ready_flag)
	if ready_flag != 0:
		# `$CCA6 BNE $CC9E`; yield again from `$CCA0` and resume at `$CCA3`.
		instruction_pcs.append(0xCC9E)
		_set_a(cpu, 0x01)
		instruction_pcs.append(0xCCA0)
		cpu["pc"] = 0xCCA0
		callsite_registers = cpu.duplicate(true)
		callsite_stack = stack.duplicate()
		_jsr(cpu, stack, stack_writes, 0xCCA0, 0xCB0F)
		instruction_pcs.append(0xCB0F)
		return _waiter_yield_result(boundary, entry_cpu, entry_ram, entry_stack,
			cpu, mapper, ram, stack, ram_writes, stack_writes, stack_reads,
			source_reads, instruction_pcs, callsite_registers, callsite_stack,
			0xCCA0, 0xCCA3, "slot11_actor_waiter_tail_at_cb0f_from_cca0")

	# `$CCA8-$CCBB`: raise the one-byte poll flag and define the final packet at
	# `$04A5` as length `$20`, destination `$23E0`.
	instruction_pcs.append(0xCCA8)
	_set_a(cpu, 0x01)
	instruction_pcs.append(0xCCAA)
	_write_ram(ram, ram_writes, 0x0515, 0x01, 0xCCAA)
	instruction_pcs.append(0xCCAD)
	_set_a(cpu, 0x20)
	instruction_pcs.append(0xCCAF)
	_write_ram(ram, ram_writes, 0x04A5, 0x20, 0xCCAF)
	instruction_pcs.append(0xCCB2)
	_set_a(cpu, 0xE0)
	instruction_pcs.append(0xCCB4)
	_write_ram(ram, ram_writes, 0x04A6, 0xE0, 0xCCB4)
	instruction_pcs.append(0xCCB7)
	_set_a(cpu, 0x23)
	instruction_pcs.append(0xCCB9)
	_write_ram(ram, ram_writes, 0x04A7, 0x23, 0xCCB9)
	instruction_pcs.append(0xCCBC)
	_set_x(cpu, 0x00)
	while int(cpu["x"]) != 0x21:
		instruction_pcs.append(0xCCBE)
		_set_a(cpu, int(cpu["x"]))
		instruction_pcs.append(0xCCBF)
		_write_ram(ram, ram_writes, 0x04A8 + int(cpu["x"]), int(cpu["a"]), 0xCCBF)
		instruction_pcs.append(0xCCC2)
		_set_x(cpu, int(cpu["x"]) + 1)
		instruction_pcs.append(0xCCC3)
		var compare_result := (int(cpu["x"]) - 0x21) & 0xFF
		_set_flag(cpu, P_C, int(cpu["x"]) >= 0x21)
		_set_flag(cpu, P_Z, int(cpu["x"]) == 0x21)
		_set_flag(cpu, P_N, (compare_result & 0x80) != 0)
		instruction_pcs.append(0xCCC5)
	instruction_pcs.append(0xCCC7)
	_set_a(cpu, 0x80)
	instruction_pcs.append(0xCCC9)
	_write_ram(ram, ram_writes, 0x0515, 0x80, 0xCCC9)
	instruction_pcs.append(0xCCCC)
	_set_a(cpu, 0x01)
	instruction_pcs.append(0xCCCE)
	cpu["pc"] = 0xCCCE
	callsite_registers = cpu.duplicate(true)
	callsite_stack = stack.duplicate()
	_jsr(cpu, stack, stack_writes, 0xCCCE, 0xCB0F)
	instruction_pcs.append(0xCB0F)
	return _waiter_yield_result(boundary, entry_cpu, entry_ram, entry_stack,
		cpu, mapper, ram, stack, ram_writes, stack_writes, stack_reads,
		source_reads, instruction_pcs, callsite_registers, callsite_stack,
		0xCCCE, 0xCCD1, "slot11_actor_waiter_final_packet_at_cb0f_from_ccce")


## Resumes the final `$CCD1 RTS`, executes the ROM's F5 post-wait handler, and
## returns to the live actor worker at `$804D`. The next `$C560` command dispatch
## remains a separate source transition.
func execute_from_slot11_final_packet_return_boundary(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		return _reject("Configure hash-checked slot-$11 ROM source spans first.")
	var valid := _validate_final_packet_return_boundary(boundary)
	if not bool(valid.get("ok", false)):
		return _reject(String(valid.get("reason", "Unsupported slot-$11 final-packet return boundary.")))
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	var cpu := {
		"pc": int(boundary["pc"]), "sp": int(boundary["sp"]),
		"a": int(boundary["a"]) & 0xFF, "x": int(boundary["x"]) & 0xFF,
		"y": int(boundary["y"]) & 0xFF, "p": int(boundary["p"]) & 0xFF,
		"p_known_mask": int(boundary["p_known_mask"]) & 0xFF,
	}
	var entry_cpu := cpu.duplicate(true)
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var mapper: Dictionary = boundary.get("mapper", {
		"bank_low": int(boundary["bank_low"]), "bank_high": int(boundary["bank_high"]),
	}).duplicate(true)
	var ram_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = []

	# `$CCD1 RTS` consumes the final `$CCCE JSR $CB0F` return word.
	instruction_pcs.append(0xCCD1)
	_rts(cpu, stack, stack_reads, 0xCCD1)
	if int(cpu["pc"]) != 0x8200 or int(cpu["sp"]) != 0xC6:
		return _unsupported("Final packet RTS did not resume the F5 handler at `$8200`.")

	# Hash-checked bank-$18 F5 tail: `$8200-$8217`.
	instruction_pcs.append(0x8200)
	_set_a(cpu, 0x0D)
	instruction_pcs.append(0x8202)
	_write_ram(ram, ram_writes, 0x05F3, 0x0D, 0x8202)
	instruction_pcs.append(0x8205)
	_set_a(cpu, 0x80)
	instruction_pcs.append(0x8207)
	_write_ram(ram, ram_writes, 0x05F4, 0x80, 0x8207)
	instruction_pcs.append(0x820A)
	var stream_index := int(ram[0x05E5])
	_read_event(source_reads, 0x820A, 0x05E5, stream_index, "F5_parameter_index")
	_set_y(cpu, stream_index)
	instruction_pcs.append(0x820D)
	var stream_pointer := int(ram[0x005F]) | (int(ram[0x0060]) << 8)
	_read_event(source_reads, 0x820D, 0x005F, int(ram[0x005F]), "actor_stream_pointer_low")
	_read_event(source_reads, 0x820D, 0x0060, int(ram[0x0060]), "actor_stream_pointer_high")
	var parameter_address := (stream_pointer + stream_index) & 0xFFFF
	var parameter := _read_stream_byte(parameter_address)
	if parameter < 0:
		return _unsupported("The F5 parameter read leaves the hash-checked actor-stream source span.")
	_read_event(source_reads, 0x820D, parameter_address, parameter, "F5_actor_stream_parameter")
	_set_a(cpu, parameter)
	instruction_pcs.append(0x820F)
	_write_ram(ram, ram_writes, 0x05E9, int(cpu["a"]), 0x820F)
	instruction_pcs.append(0x8212)
	var next_stream_index := (stream_index + 1) & 0xFF
	_write_ram(ram, ram_writes, 0x05E5, next_stream_index, 0x8212)
	_set_nz(cpu, next_stream_index)
	instruction_pcs.append(0x8215)
	_set_a(cpu, _pop(cpu, stack, stack_reads, 0x8215))
	instruction_pcs.append(0x8216)
	_set_a(cpu, _pop(cpu, stack, stack_reads, 0x8216))
	instruction_pcs.append(0x8217)
	_rts(cpu, stack, stack_reads, 0x8217)
	if int(cpu["pc"]) != 0x804D or int(cpu["sp"]) != 0xCA \
			or int(cpu["a"]) != 0x80 or int(cpu["x"]) != 0x21 \
			or int(cpu["y"]) != stream_index:
		return _unsupported("The F5 tail did not return through the live `$804D` actor-worker frame.")
	var output_ram := ram.duplicate()
	for stack_offset in STACK_SIZE:
		output_ram[0x0100 + stack_offset] = stack[stack_offset]
	return {
		"ok": true,
		"status": "slot11_actor_f5_tail_returned_to_804d",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_span_hashes": {
			COUNTER_TAIL_FILE: "28ae864c35cf13601f8cb93f4bc13f0cadcd64b9d401fff6f0bef8e2b656bee0",
			F5_TAIL_FILE: "f99ead3dbc9481250bab0c306693651ab2ac705bd5feeb82ea3975167c3663a0",
			STREAM_FILE: "907c3653f2e64fa9d27a0a14a7dd38e404f0f1c05a97c0367be24e587f5ebadf",
		},
		"slot_base": SLOT_11,
		"entry_pc": int(entry_cpu["pc"]),
		"exit_pc": int(cpu["pc"]),
		"entry_record": PackedByteArray(boundary["record"]),
		"entry_registers": entry_cpu,
		"entry_ram_image": entry_ram,
		"entry_stack_page": entry_stack,
		"mapper": mapper,
		"ram_image": output_ram,
		"stack_page": stack,
		"ram_writes": ram_writes,
		"stack_writes": [],
		"stack_reads": stack_reads,
		"source_reads": source_reads,
		"instruction_pcs": instruction_pcs,
		"exit_registers": cpu.duplicate(true),
		"ppu_bus_events": [],
		"apu_register_writes": [],
		"trace_state_used": false,
		"ppu_apu_effects_applied": false,
		"source_timing_modeled": false,
	}


## Executes the next source step after the F5 tail: `$804D->$C560->$CF72`,
## maps banks `$1A/$1B`, runs the `$A1EB` animation gate for index `$0D`, and
## returns the pre-pushed `$A217->$C515->$CB0F` yield contract.
func execute_from_slot11_f5_animation_gate_boundary(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		return _reject("Configure hash-checked slot-$11 ROM source spans first.")
	var valid := _validate_f5_animation_gate_boundary(boundary)
	if not bool(valid.get("ok", false)):
		return _reject(String(valid.get("reason", "Unsupported slot-$11 F5 animation gate boundary.")))
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	var cpu := {
		"pc": int(boundary["pc"]), "sp": int(boundary["sp"]),
		"a": int(boundary["a"]) & 0xFF, "x": int(boundary["x"]) & 0xFF,
		"y": int(boundary["y"]) & 0xFF, "p": int(boundary["p"]) & 0xFF,
		"p_known_mask": int(boundary["p_known_mask"]) & 0xFF,
	}

	var entry_cpu := cpu.duplicate(true)
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var mapper: Dictionary = boundary.get("mapper", {}).duplicate(true)
	var initial_mapper := mapper.duplicate(true)
	var ram_writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var mapper_writes: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = []

	# Worker `$804D JSR $C560`; the fixed-bank vector jumps to `$CF72`.
	instruction_pcs.append(0x804D)
	_jsr(cpu, stack, stack_writes, 0x804D, 0xC560)
	_read_event(source_reads, 0xC560, 0xC560, int(_sources[C560_STUB_FILE][0]), "fixed_call_stub_opcode")
	cpu["pc"] = 0xCF72
	# `$CF72` saves A, writes the pair to `$24/$25`, and calls `$CE2D`.
	instruction_pcs.append(0xCF72)
	_push(cpu, stack, stack_writes, int(cpu["a"]), 0xCF72, "PHA")
	instruction_pcs.append(0xCF73)
	_set_a(cpu, int(ram[0x0022]))
	_read_event(source_reads, 0xCF73, 0x0022, int(ram[0x0022]), "mapper_shadow")
	instruction_pcs.append(0xCF75)
	_set_a(cpu, 0x1A)
	instruction_pcs.append(0xCF77)
	_write_ram(ram, ram_writes, 0x0024, 0x1A, 0xCF77)
	instruction_pcs.append(0xCF79)
	_set_a(cpu, 0x1B)
	instruction_pcs.append(0xCF7B)
	_write_ram(ram, ram_writes, 0x0025, 0x1B, 0xCF7B)
	instruction_pcs.append(0xCF7D)
	_jsr(cpu, stack, stack_writes, 0xCF7D, 0xCE2D)
	var mapper_helper: PackedByteArray = _sources["mapper_helper"]
	if mapper_helper.size() != 29:
		return _unsupported("The shared `$CE2D` mapper helper span is unavailable.")
	var helper_offsets := [0, 2, 3, 6, 9, 11, 13, 14, 15, 17, 18, 21, 23, 24, 27, 28]
	for offset in helper_offsets:
		instruction_pcs.append(0xCE2D + offset)
	var selector_low := int(ram[0x0022]) | 0x06
	_write_ram(ram, ram_writes, 0x0023, selector_low, 0xCE31)
	_set_mapper_pair_register(mapper, mapper_writes, selector_low, 6, 0xCE33, true)
	_read_event(source_reads, 0xCE36, 0x0024, int(ram[0x0024]), "mapper_bank_6_value")
	_set_mapper_pair_register(mapper, mapper_writes, int(ram[0x0024]), 6, 0xCE38)
	var selector_high := int(ram[0x0022]) | 0x07
	_write_ram(ram, ram_writes, 0x0023, selector_high, 0xCE3F)
	_set_mapper_pair_register(mapper, mapper_writes, selector_high, 7, 0xCE41, true)
	_read_event(source_reads, 0xCE44, 0x0025, int(ram[0x0025]), "mapper_bank_7_value")
	_set_mapper_pair_register(mapper, mapper_writes, int(ram[0x0025]), 7, 0xCE46)
	if int(mapper.get("bank_low", -1)) != 0x1A or int(mapper.get("bank_high", -1)) != 0x1B \
			or int(mapper.get("select", -1)) != 7:
		return _unsupported("The ROM `$CE2D` mapper helper did not select the `$1A/$1B` pair.")
	_rts(cpu, stack, stack_reads, 0xCE49)
	if int(cpu["pc"]) != 0xCF80:
		return _unsupported("The mapper-helper RTS did not return to `$CF80`.")
	instruction_pcs.append(0xCF80)
	_set_a(cpu, _pop(cpu, stack, stack_reads, 0xCF80))
	instruction_pcs.append(0xCF81)
	_jsr(cpu, stack, stack_writes, 0xCF81, 0x802A)
	if int(mapper.get("bank_low", -1)) != 0x1A or int(mapper.get("bank_high", -1)) != 0x1B:
		return _unsupported("The bank-$1A `$802A` entry is not mapped at its source call.")
	instruction_pcs.append(0x802A)
	cpu["pc"] = 0xA1EB

	# Bank-$1B `$A1EB` starts animation 13 from the pointer row `$A2AC/$A2AD`.
	instruction_pcs.append(0xA1EB)
	_set_a(cpu, int(ram[0x05F4]))
	_read_event(source_reads, 0xA1EB, 0x05F4, int(ram[0x05F4]), "animation_gate_mode")
	if int(cpu["a"]) == 0:
		return _unsupported("The live `$05F4` actor-animation mode takes the unimplemented early RTS path.")
	instruction_pcs.append(0xA1EE)
	if (int(cpu["p"]) & P_N) != 0:
		# `$A1F1 BPL $A20C` is not taken for `$80`; execution falls into setup.
		instruction_pcs.append(0xA1F1)
	else:
		return _unsupported("The live `$05F4` mode takes `$A1F1 BPL $A20C`, outside the F5 setup branch.")
	instruction_pcs.append(0xA1F3)
	_set_a(cpu, 0x01)
	instruction_pcs.append(0xA1F5)
	_write_ram(ram, ram_writes, 0x05F4, 0x01, 0xA1F5)
	instruction_pcs.append(0xA1F8)
	_set_a(cpu, int(ram[0x05F3]))
	_read_event(source_reads, 0xA1F8, 0x05F3, int(ram[0x05F3]), "animation_index")
	if int(cpu["a"]) != 0x0D:
		return _unsupported("The live animation index is not the packaged `$0D` actor action.")
	instruction_pcs.append(0xA1FB)
	var doubled_animation_index := (int(cpu["a"]) << 1) & 0xFF
	_set_flag(cpu, P_C, (int(cpu["a"]) & 0x80) != 0)
	_set_a(cpu, doubled_animation_index)
	instruction_pcs.append(0xA1FC)
	_set_x(cpu, int(cpu["a"]))
	instruction_pcs.append(0xA1FD)
	var pointer_low := int(_sources[ANIMATION_INDEX_FILE][0])
	var pointer_high := int(_sources[ANIMATION_INDEX_FILE][1])
	_read_event(source_reads, 0xA1FD, 0xA2AC, pointer_low, "animation_0d_pointer_low")
	_set_a(cpu, pointer_low)
	instruction_pcs.append(0xA200)
	_write_ram(ram, ram_writes, 0x0063, pointer_low, 0xA200)
	instruction_pcs.append(0xA202)
	_read_event(source_reads, 0xA202, 0xA2AD, pointer_high, "animation_0d_pointer_high")
	_set_a(cpu, pointer_high)
	instruction_pcs.append(0xA205)
	_write_ram(ram, ram_writes, 0x0064, pointer_high, 0xA205)
	instruction_pcs.append(0xA207)
	_set_a(cpu, 0x00)
	instruction_pcs.append(0xA209)
	_write_ram(ram, ram_writes, 0x05F5, 0x00, 0xA209)
	instruction_pcs.append(0xA20C)
	_set_a(cpu, int(ram[0x05F5]))
	_read_event(source_reads, 0xA20C, 0x05F5, int(ram[0x05F5]), "animation_wait_counter")
	if int(cpu["a"]) != 0:
		return _unsupported("The first `$A20F BEQ $A215` animation-wait branch is not taken.")
	instruction_pcs.append(0xA20F)
	instruction_pcs.append(0xA215)
	_set_a(cpu, 0x01)
	cpu["pc"] = 0xA217
	instruction_pcs.append(0xA217)
	var callsite_registers := cpu.duplicate(true)
	var callsite_stack := stack.duplicate()
	_jsr(cpu, stack, stack_writes, 0xA217, 0xC515)
	instruction_pcs.append(0xC515)
	_read_event(source_reads, 0xC515, 0xC515, 0x4C, "task_yield_dispatch_opcode")
	cpu["pc"] = 0xCB0F # `$C515 JMP $CB0F`.
	instruction_pcs.append(0xCB0F)
	var cb0f_registers := cpu.duplicate(true)
	var output_ram := ram.duplicate()
	for stack_offset in STACK_SIZE:
		output_ram[0x0100 + stack_offset] = stack[stack_offset]
	return {
		"ok": true,
		"status": "slot11_f5_animation_gate_at_cb0f_from_a217",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_span_hashes": {
			C560_STUB_FILE: "170b3801f4df2a5789a9ef9fbdc6c389c58afdad9c58a94d3c7fad8e6563ccbc",
			CF72_WRAPPER_FILE: "8ef4c31ce9f19ea12db252480ab5342a4429e37c3f81148bdde0286ad03b3c13",
			BANK1A_ENTRY_FILE: "d8ec35aefd2671a7a810a2fa342db297bfb35011862ec3b907aa09fced64da90",
			ANIMATION_GATE_FILE: "7cf2b10130708c5b0a722741eb60d27e732672730c7bbfb515dd1f9a17122618",
			ANIMATION_INDEX_FILE: "588eba1d324cbcd9381797960eb1a81d099ef8277be6a1f92b935389647e1ae2",
			"fixed_mapper_helper_CE2D_CE49.bin": "6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c",
		},
		"slot_base": SLOT_11,
		"entry_pc": int(entry_cpu["pc"]),
		"exit_pc": int(cpu["pc"]),
		"yield_callsite_pc": 0xA217,
		"yield_target_pc": 0xCB0F,
		"resume_pc_after_rts": 0xA21A,
		"entry_record": PackedByteArray(boundary["record"]),
		"entry_registers": entry_cpu,
		"entry_ram_image": entry_ram,
		"entry_stack_page": entry_stack,
		"yield_callsite_registers": callsite_registers,
		"yield_callsite_stack_page": callsite_stack,
		"call_frame_already_pushed": true,
		"pre_jsr_sp": int(callsite_registers["sp"]),
		"cb0f_entry_registers": cb0f_registers,
		"mapper": mapper,
		"initial_mapper": initial_mapper,
		"ram_image": output_ram,
		"stack_page": stack,
		"ram_writes": ram_writes,
		"stack_writes": stack_writes,
		"stack_reads": stack_reads,
		"mapper_writes": mapper_writes,
		"source_reads": source_reads,
		"instruction_pcs": instruction_pcs,
		"ppu_bus_events": [],
		"apu_register_writes": [],
		"trace_state_used": false,
		"ppu_apu_effects_applied": false,
		"source_timing_modeled": false,
	}




## Executes the first `$A21A` animation command after the `$A217` task yield.
## It builds the ROM packet queue in RAM and stops at the next `$8047` yield
## callsite; NMI consumption and visible PPU rendering remain separate.
func execute_from_slot11_animation_after_a217_boundary(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		return _reject("Configure hash-checked slot-$11 ROM source spans first.")
	var valid := _validate_a21a_animation_boundary(boundary)
	if not bool(valid.get("ok", false)):
		return _reject(String(valid.get("reason", "Unsupported slot-$11 `$A21A` continuation.")))
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	var cpu := {
		"pc": int(boundary["pc"]), "sp": int(boundary["sp"]),
		"a": int(boundary["a"]) & 0xFF, "x": int(boundary["x"]) & 0xFF,
		"y": int(boundary["y"]) & 0xFF, "p": int(boundary["p"]) & 0xFF,
		"p_known_mask": int(boundary["p_known_mask"]) & 0xFF,
	}
	var entry_cpu := cpu.duplicate(true)
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var mapper: Dictionary = boundary.get("mapper", {}).duplicate(true)
	var initial_mapper := mapper.duplicate(true)
	var ram_writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var mapper_writes: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = []

	# `$A21A` waits for the previous secondary queue. This bounded pass only
	# accepts the trace-supported empty-queue branch that decodes event `$EF,00`.
	instruction_pcs.append(0xA21A)
	_set_a(cpu, int(ram[0x0515]))
	_read_event(source_reads, 0xA21A, 0x0515, int(ram[0x0515]), "animation_queue_ready")
	if int(cpu["a"]) != 0:
		return _unsupported("The `$A21A` continuation sees a pending `$0515` animation queue; its wait-only loop is not part of this packet builder.")
	instruction_pcs.append(0xA21F)
	_set_a(cpu, 0x01)
	instruction_pcs.append(0xA221)
	_write_ram(ram, ram_writes, 0x0515, 0x01, 0xA221)
	instruction_pcs.append(0xA224)
	_set_y(cpu, 0x00)
	instruction_pcs.append(0xA226)
	var animation_stream: PackedByteArray = _sources[ANIMATION_STREAM_FILE]
	var command := int(animation_stream[0])
	_set_a(cpu, command)
	_read_event(source_reads, 0xA226, 0xA425, command, "animation_command")
	if command != 0xEF:
		return _unsupported("The live `$A425` animation command is not the packaged `$EF` event.")
	instruction_pcs.append(0xA228)
	if command == 0xFF:
		return _unsupported("The `$A425==$FF` alternate animation-pointer branch is unsupported.")
	instruction_pcs.append(0xA242)
	_write_ram(ram, ram_writes, 0x05F5, command, 0xA242)
	instruction_pcs.append(0xA245)
	_set_y(cpu, 0x01)
	instruction_pcs.append(0xA246)
	var event_index := int(animation_stream[1])
	_set_a(cpu, event_index)
	_read_event(source_reads, 0xA246, 0xA426, event_index, "animation_event_index")
	if event_index != 0:
		return _unsupported("The `$EF` animation event index is not zero.")
	instruction_pcs.append(0xA248)
	_set_a(cpu, (event_index << 1) & 0xFF)
	instruction_pcs.append(0xA249)
	_set_x(cpu, int(cpu["a"]))
	instruction_pcs.append(0xA24A)
	var packet_pointer_low := int(_sources[ANIMATION_POINTER_FILE][0])
	_set_a(cpu, packet_pointer_low)
	_read_event(source_reads, 0xA24A, 0xA42A, packet_pointer_low, "animation_event_pointer_low")
	instruction_pcs.append(0xA24D)
	_write_ram(ram, ram_writes, 0x003A, packet_pointer_low, 0xA24D)
	instruction_pcs.append(0xA24F)
	var packet_pointer_high := int(_sources[ANIMATION_POINTER_FILE][1])
	_set_a(cpu, packet_pointer_high)
	_read_event(source_reads, 0xA24F, 0xA42B, packet_pointer_high, "animation_event_pointer_high")
	instruction_pcs.append(0xA252)
	_write_ram(ram, ram_writes, 0x003B, packet_pointer_high, 0xA252)
	_set_y(cpu, 0x00)
	_set_x(cpu, 0x00)
	var packet_bytes: PackedByteArray = _sources[ANIMATION_PPU_PACKETS_FILE]
	var stream_offset := 0
	var packet_offset := 0
	var packet_count := 0
	var parsed_packets: Array[Dictionary] = []
	while true:
		if stream_offset >= packet_bytes.size() or packet_count > 16:
			return _unsupported("The `$A46A` packet stream has no bounded zero-count terminator.")
		instruction_pcs.append(0xA258)
		var byte_count := int(packet_bytes[stream_offset])
		_set_y(cpu, stream_offset)
		_set_a(cpu, byte_count)
		_read_event(source_reads, 0xA258, 0xA46A + stream_offset, byte_count, "animation_packet_length")
		if byte_count == 0:
			instruction_pcs.append(0xA25A)
			break
		instruction_pcs.append(0xA25C)
		_write_ram(ram, ram_writes, 0x04A5 + packet_offset, byte_count, 0xA25C)
		_write_ram(ram, ram_writes, 0x003C, byte_count, 0xA25F)
		var destination_low := int(packet_bytes[stream_offset + 1])
		instruction_pcs.append(0xA262)
		_set_y(cpu, stream_offset + 1)
		_set_a(cpu, destination_low)
		_read_event(source_reads, 0xA262, 0xA46A + stream_offset + 1, destination_low, "animation_ppu_address_low")
		instruction_pcs.append(0xA264)
		_write_ram(ram, ram_writes, 0x04A6 + packet_offset, destination_low, 0xA264)
		var destination_high := int(packet_bytes[stream_offset + 2])
		instruction_pcs.append(0xA268)
		_set_y(cpu, stream_offset + 2)
		_set_a(cpu, destination_high)
		_read_event(source_reads, 0xA268, 0xA46A + stream_offset + 2, destination_high, "animation_ppu_address_high")
		instruction_pcs.append(0xA26A)
		_write_ram(ram, ram_writes, 0x04A7 + packet_offset, destination_high, 0xA26A)
		instruction_pcs.append(0xA26D)
		packet_offset += 3
		_set_x(cpu, packet_offset)
		var payload := PackedByteArray()
		for byte_index in byte_count:
			var payload_value := int(packet_bytes[stream_offset + 3 + byte_index])
			instruction_pcs.append(0xA271)
			_set_y(cpu, stream_offset + 3 + byte_index)
			_set_a(cpu, payload_value)
			_read_event(source_reads, 0xA271, 0xA46A + stream_offset + 3 + byte_index,
				payload_value, "animation_ppu_payload")
			_write_ram(ram, ram_writes, 0x04A5 + packet_offset, payload_value, 0xA273)
			payload.append(payload_value)
			packet_offset += 1
			_set_x(cpu, packet_offset)
		var left := byte_count
		while left > 0:
			left -= 1
			_write_ram(ram, ram_writes, 0x003C, left, 0xA278)
			_set_flag(cpu, P_N, (left & 0x80) != 0)
			_set_flag(cpu, P_Z, left == 0)
		instruction_pcs.append(0xA27C)
		stream_offset += 3 + byte_count
		packet_count += 1
		parsed_packets.append({
			"length": byte_count,
			"destination": (destination_high << 8) | destination_low,
			"payload": payload,
		})
	if stream_offset != packet_bytes.size() - 1 or packet_offset >= 0x70:
		return _unsupported("The first `$EF,00` PPU queue differs from the exact six-packet `$A46A->$A48E` span.")
	instruction_pcs.append(0xA27E)
	_write_ram(ram, ram_writes, 0x04A5 + packet_offset, 0x00, 0xA27E)
	instruction_pcs.append(0xA281)
	_set_a(cpu, 0x80)
	instruction_pcs.append(0xA283)
	_write_ram(ram, ram_writes, 0x0515, 0x80, 0xA283)
	instruction_pcs.append(0xA286)
	_set_a(cpu, int(ram[0x0063]))
	_read_event(source_reads, 0xA286, 0x0063, int(ram[0x0063]), "animation_stream_pointer_low")
	instruction_pcs.append(0xA288)
	_set_flag(cpu, P_C, false)
	instruction_pcs.append(0xA289)
	var next_pointer_low := (int(cpu["a"]) + 2) & 0xFF
	_set_flag(cpu, P_C, int(cpu["a"]) + 2 > 0xFF)
	_set_a(cpu, next_pointer_low)
	instruction_pcs.append(0xA28B)
	_write_ram(ram, ram_writes, 0x0063, next_pointer_low, 0xA28B)
	if (int(cpu["p"]) & P_C) != 0:
		instruction_pcs.append(0xA28D)
		_write_ram(ram, ram_writes, 0x0064, (int(ram[0x0064]) + 1) & 0xFF, 0xA28F)
	instruction_pcs.append(0xA291)
	_rts(cpu, stack, stack_reads, 0xA291)
	if int(cpu["pc"]) != 0xCF84:
		return _unsupported("The animation-list RTS did not return to mapper wrapper `$CF84`.")
	# `$CF84-$CF8E` restores the original bank pair before returning to `$8050`.
	instruction_pcs.append(0xCF84)
	_set_a(cpu, 0x18)
	instruction_pcs.append(0xCF86)
	_write_ram(ram, ram_writes, 0x0024, 0x18, 0xCF86)
	instruction_pcs.append(0xCF88)
	_set_a(cpu, 0x19)
	instruction_pcs.append(0xCF8A)
	_write_ram(ram, ram_writes, 0x0025, 0x19, 0xCF8A)
	var mapper_helper: PackedByteArray = _sources["mapper_helper"]
	for offset in [0, 2, 3, 6, 9, 11, 13, 14, 15, 17, 18, 21, 23, 24, 27, 28]:
		instruction_pcs.append(0xCE2D + offset)
	var selector_low := int(ram[0x0022]) | 0x06
	_write_ram(ram, ram_writes, 0x0023, selector_low, 0xCE31)
	_set_mapper_pair_register(mapper, mapper_writes, selector_low, 6, 0xCE33, true)
	_read_event(source_reads, 0xCE36, 0x0024, int(ram[0x0024]), "mapper_bank_6_value")
	_set_mapper_pair_register(mapper, mapper_writes, int(ram[0x0024]), 6, 0xCE38)
	var selector_high := int(ram[0x0022]) | 0x07
	_write_ram(ram, ram_writes, 0x0023, selector_high, 0xCE3F)
	_set_mapper_pair_register(mapper, mapper_writes, selector_high, 7, 0xCE41, true)
	_read_event(source_reads, 0xCE44, 0x0025, int(ram[0x0025]), "mapper_bank_7_value")
	_set_mapper_pair_register(mapper, mapper_writes, int(ram[0x0025]), 7, 0xCE46)
	_rts(cpu, stack, stack_reads, 0xCE49)
	if int(cpu["pc"]) != 0x8050 or int(cpu["sp"]) != 0xCA \
			or int(mapper.get("bank_low", -1)) != 0x18 \
			or int(mapper.get("bank_high", -1)) != 0x19:
		return _unsupported("The mapper helper did not restore banks `$18/$19` and return to `$8050`.")
	instruction_pcs.append(0x8050)
	cpu["pc"] = 0x8045
	instruction_pcs.append(0x8045)
	_set_a(cpu, 0x01)
	cpu["pc"] = 0x8047
	if _sources["worker_prefix"].slice(0x45, 0x4A) != PackedByteArray([0xA9, 0x01, 0x20, 0x15, 0xC5]):
		return _unsupported("The `$8050->$8045->$8047` source loop differs from the shared bank-$18 bytes.")
	instruction_pcs.append(0x8047)
	var output_ram := ram.duplicate()
	for offset in STACK_SIZE:
		output_ram[0x0100 + offset] = stack[offset]
	return {
		"ok": true,
		"status": "slot11_f5_animation_queue_at_8047",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_span_hashes": {
			ANIMATION_COMMAND_LOOP_FILE: "c315087f3f361a05abbbc63748d1c890aea1a2be7f40fb325150cb71688f1cfd",
			ANIMATION_STREAM_FILE: "c80e57d27a62d8f8ae98f6976e64d0a1e4f9cebe78cf5b16e79ecd927b985da6",
			ANIMATION_POINTER_FILE: "48dceebd8704067b3697888d1f847f69d77a5fbbcb8e57ac3a9a0b41205e47cf",
			ANIMATION_PPU_PACKETS_FILE: "4fd878c7cc59ffec84362bfc6f973474f72c83087d302687958b844682b2d678",
			"fixed_mapper_helper_CE2D_CE49.bin": "6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c",
			"bank18_actor_worker_entry_8000_804A.bin": "2187af6881ea2f4e7eb16c0c5550bb24ead076be918d429d8ab63564ed8fd46c",
		},
		"slot_base": SLOT_11,
		"entry_pc": int(entry_cpu["pc"]),
		"exit_pc": int(cpu["pc"]),
		"yield_callsite_pc": 0x8047,
		"yield_target_pc": 0xCB0F,
		"resume_pc_after_rts": 0x804A,
		"entry_record": PackedByteArray(boundary["record"]),
		"entry_registers": entry_cpu,
		"entry_ram_image": entry_ram,
		"entry_stack_page": entry_stack,
		"call_frame_already_pushed": false,
		"pre_jsr_sp": int(cpu["sp"]),
		"yield_callsite_registers": cpu.duplicate(true),
		"yield_callsite_stack_page": stack.duplicate(),
		"mapper": mapper,
		"initial_mapper": initial_mapper,
		"ram_image": output_ram,
		"stack_page": stack,
		"ram_writes": ram_writes,
		"stack_writes": stack_writes,
		"stack_reads": stack_reads,
		"mapper_writes": mapper_writes,
		"source_reads": source_reads,
		"instruction_pcs": instruction_pcs,
		"secondary_ppu_packets": parsed_packets,
		"ppu_bus_events": [],
		"apu_register_writes": [],
		"trace_state_used": false,
		"ppu_apu_effects_applied": false,
		"source_timing_modeled": false,
	}
## Executes one ROM-owned nonzero animation wait. `$8053` decrements `$05E9`,
## `$A20C` decrements `$05F5`, and the worker returns to its `$8047` yield.
func execute_from_slot11_animation_countdown_boundary(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		return _reject("Configure hash-checked slot-$11 ROM source spans first.")
	var valid := _validate_animation_countdown_boundary(boundary)
	if not bool(valid.get("ok", false)):
		return _reject(String(valid.get("reason", "Unsupported slot-$11 animation countdown boundary.")))
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	var cpu := {
		"pc": int(boundary["pc"]), "sp": int(boundary["sp"]),
		"a": int(boundary["a"]) & 0xFF, "x": int(boundary["x"]) & 0xFF,
		"y": int(boundary["y"]) & 0xFF, "p": int(boundary["p"]) & 0xFF,
		"p_known_mask": int(boundary["p_known_mask"]) & 0xFF,
	}
	var entry_cpu := cpu.duplicate(true)
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var mapper: Dictionary = boundary.get("mapper", {}).duplicate(true)
	var initial_mapper := mapper.duplicate(true)
	var ram_writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var mapper_writes: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = []

	# `$804A JSR $8053`; follow its active-worker, nonzero-delay path.
	instruction_pcs.append(0x804A)
	_jsr(cpu, stack, stack_writes, 0x804A, 0x8053)
	instruction_pcs.append(0x8053)
	_set_a(cpu, int(ram[0x05E3]))
	_read_event(source_reads, 0x8053, 0x05E3, int(ram[0x05E3]), "worker_active_flag")
	if int(cpu["a"]) != 1:
		return _unsupported("The animation countdown worker is not active at `$8053`.")
	instruction_pcs.append(0x8056)
	instruction_pcs.append(0x8059)
	_set_a(cpu, int(ram[0x05E9]))
	_read_event(source_reads, 0x8059, 0x05E9, int(ram[0x05E9]), "actor_animation_delay")
	instruction_pcs.append(0x805C)
	if int(cpu["a"]) == 0:
		# `$8062` dispatches the current actor-stream handler; this bounded case
		# accepts only its ROM byte below `$F0`, which becomes the next delay.
		instruction_pcs.append(0x8062)
		_set_a(cpu, int(ram[0x05E4]))
		_read_event(source_reads, 0x8062, 0x05E4, int(ram[0x05E4]), "actor_stream_dispatch_index")
		_jsr(cpu, stack, stack_writes, 0x8065, 0xC509)
		var handler := _inline_dispatch(cpu, ram, stack, ram_writes,
			stack_writes, stack_reads, source_reads, 0x8065, 0x8068, instruction_pcs)
		if handler == 0x806E:
			instruction_pcs.append(0x806E)
			var stream_index := int(ram[0x05E5])
			_set_y(cpu, stream_index)
			_read_event(source_reads, 0x806E, 0x05E5, stream_index, "actor_stream_index")
			_write_ram(ram, ram_writes, 0x05E5, (stream_index + 1) & 0xFF, 0x8071)
			_read_event(source_reads, 0x8074, 0x005F, int(ram[0x005F]), "actor_stream_pointer_low")
			_read_event(source_reads, 0x8074, 0x0060, int(ram[0x0060]), "actor_stream_pointer_high")
			var stream_address := ((int(ram[0x0060]) << 8) | int(ram[0x005F])) + stream_index
			var stream_byte := _read_stream_byte(stream_address)
			if stream_byte < 0:
				return _unsupported("The actor-stream delay byte is outside the hash-checked ROM spans.")
			_read_event(source_reads, 0x8074, stream_address, stream_byte, "actor_stream_followup_delay")
			_set_a(cpu, stream_byte)
			instruction_pcs.append(0x8076)
			_compare_a(cpu, 0xF0)
			if stream_byte >= 0xF0:
				return _unsupported("The live stream byte selects the `$F0+` handler table, outside this delay branch.")
			instruction_pcs.append(0x8078)
			instruction_pcs.append(0x8080)
			_write_ram(ram, ram_writes, 0x05E9, stream_byte, 0x8080)
			instruction_pcs.append(0x8083)
			_write_ram(ram, ram_writes, 0x05E4, (int(ram[0x05E4]) + 1) & 0xFF, 0x8083)
			_set_nz(cpu, int(ram[0x05E4]))
			instruction_pcs.append(0x8086)
			_rts(cpu, stack, stack_reads, 0x8086)
		elif handler == 0x8218:
			var stream_index := int(ram[0x05E5])
			_set_y(cpu, stream_index)
			_read_event(source_reads, 0x8218, 0x05E5, stream_index, "actor_event_stream_index")
			var stream_address := (int(ram[0x005F]) | (int(ram[0x0060]) << 8)) + stream_index
			var event_byte := _read_stream_byte(stream_address)
			if event_byte < 0:
				return _unsupported("The live `$8218` stream pointer is outside the verified source spans.")
			_read_event(source_reads, 0x8218, stream_address, event_byte, "actor_event_byte")
			_set_a(cpu, event_byte)
			instruction_pcs.append(0x8218)
			instruction_pcs.append(0x821B)
			instruction_pcs.append(0x821D)
			_compare_a(cpu, 0x90)
			instruction_pcs.append(0x821F)
			if (int(cpu["p"]) & P_C) != 0:
				return _unsupported("The `$821F` BCS path reaches `$822E->$C52D`; its live behavior is not integrated.")
			instruction_pcs.append(0x8221)
			_set_a(cpu, event_byte & 0x0F)
			_set_nz(cpu, int(cpu["a"]))
			instruction_pcs.append(0x8223)
			_write_ram(ram, ram_writes, 0x05F3, int(cpu["a"]), 0x8223)
			instruction_pcs.append(0x8226)
			_set_a(cpu, 0x80)
			instruction_pcs.append(0x8228)
			_write_ram(ram, ram_writes, 0x05F4, 0x80, 0x8228)
			instruction_pcs.append(0x8234)
			var matches_observed_event := (stream_address == 0xA3CA and event_byte == 0x20) \
					or (stream_address == 0xA43A and event_byte == 0x10)
			if not matches_observed_event:
				return _unsupported(
					"Godot reaches `$8218->$8234` with `$%02X` from `$%04X`; this " % [event_byte, stream_address]
					+ "does not match the muted FCEUX event reads `$20` at `$A3CA` "
					+ "or `$10` at `$A43A`. Resolve stream-pointer and tick alignment "
					+ "before advancing this route.")
			return _unsupported(
				"The `$8218->$8234` table-driven event matches the traced FCEUX "
				+ "stream byte. The `$86B8/$8DC2` payload selection and `$8266/$826C` "
				+ "queue wait are not integrated; stop before their PPU/text consumer.")
		else:
			return _unsupported("The live actor-stream dispatch selected unsupported handler `$%04X` for index `$%02X`." % [handler, int(ram[0x05E4])])
	else:
		instruction_pcs.append(0x805E)
		var next_delay := (int(ram[0x05E9]) - 1) & 0xFF
		_write_ram(ram, ram_writes, 0x05E9, next_delay, 0x805E)
		_set_nz(cpu, next_delay)
		instruction_pcs.append(0x8061)
		_rts(cpu, stack, stack_reads, 0x8061)
	if int(cpu["pc"]) != 0x804D or int(cpu["sp"]) != 0xCA:
		return _unsupported("The `$8053` countdown RTS did not return to `$804D`.")

	# `$804D->$C560->$CF72` selects `$1A/$1B`, then the ROM animation gate.
	instruction_pcs.append(0x804D)
	_jsr(cpu, stack, stack_writes, 0x804D, 0xC560)
	_read_event(source_reads, 0xC560, 0xC560, 0x4C, "fixed_call_stub_opcode")
	cpu["pc"] = 0xCF72
	instruction_pcs.append(0xCF72)
	_push(cpu, stack, stack_writes, int(cpu["a"]), 0xCF72, "PHA")
	instruction_pcs.append(0xCF73)
	_set_a(cpu, int(ram[0x0022]))
	_read_event(source_reads, 0xCF73, 0x0022, int(ram[0x0022]), "mapper_shadow")
	instruction_pcs.append(0xCF75)
	_set_a(cpu, 0x1A)
	instruction_pcs.append(0xCF77)
	_write_ram(ram, ram_writes, 0x0024, 0x1A, 0xCF77)
	instruction_pcs.append(0xCF79)
	_set_a(cpu, 0x1B)
	instruction_pcs.append(0xCF7B)
	_write_ram(ram, ram_writes, 0x0025, 0x1B, 0xCF7B)
	instruction_pcs.append(0xCF7D)
	_jsr(cpu, stack, stack_writes, 0xCF7D, 0xCE2D)
	_apply_animation_mapper_helper(ram, mapper, ram_writes, mapper_writes,
		source_reads, instruction_pcs)
	_rts(cpu, stack, stack_reads, 0xCE49)
	if int(cpu["pc"]) != 0xCF80:
		return _unsupported("The first `$CE2D` helper call did not return to `$CF80`.")
	instruction_pcs.append(0xCF80)
	_set_a(cpu, _pop(cpu, stack, stack_reads, 0xCF80))
	instruction_pcs.append(0xCF81)
	_jsr(cpu, stack, stack_writes, 0xCF81, 0x802A)
	instruction_pcs.append(0x802A)
	cpu["pc"] = 0xA1EB
	instruction_pcs.append(0xA1EB)
	_set_a(cpu, int(ram[0x05F4]))
	_read_event(source_reads, 0xA1EB, 0x05F4, int(ram[0x05F4]), "animation_gate_mode")
	if int(cpu["a"]) != 1:
		return _unsupported("The repeated animation gate is not in positive `$05F4` mode.")
	instruction_pcs.append(0xA1EE)
	instruction_pcs.append(0xA1F1)
	if (int(cpu["p"]) & P_N) != 0:
		return _unsupported("The animation gate takes the negative `$05F4` setup path.")
	instruction_pcs.append(0xA20C)
	_set_a(cpu, int(ram[0x05F5]))
	_read_event(source_reads, 0xA20C, 0x05F5, int(ram[0x05F5]), "animation_wait_counter")
	if int(cpu["a"]) == 0:
		return _unsupported("The animation counter reached the `$A215` yield branch.")
	instruction_pcs.append(0xA20F)
	instruction_pcs.append(0xA211)
	var next_animation_wait := (int(ram[0x05F5]) - 1) & 0xFF
	_write_ram(ram, ram_writes, 0x05F5, next_animation_wait, 0xA211)
	_set_nz(cpu, next_animation_wait)
	instruction_pcs.append(0xA214)
	_rts(cpu, stack, stack_reads, 0xA214)
	if int(cpu["pc"]) != 0xCF84:
		return _unsupported("The animation counter RTS did not return to `$CF84`.")

	# The wrapper restores `$18/$19` and its final mapper-helper RTS returns to `$804F`.
	instruction_pcs.append(0xCF84)
	_set_a(cpu, 0x18)
	instruction_pcs.append(0xCF86)
	_write_ram(ram, ram_writes, 0x0024, 0x18, 0xCF86)
	instruction_pcs.append(0xCF88)
	_set_a(cpu, 0x19)
	instruction_pcs.append(0xCF8A)
	_write_ram(ram, ram_writes, 0x0025, 0x19, 0xCF8A)
	_apply_animation_mapper_helper(ram, mapper, ram_writes, mapper_writes,
		source_reads, instruction_pcs)
	_rts(cpu, stack, stack_reads, 0xCE49)
	if int(cpu["pc"]) != 0x8050 or int(cpu["sp"]) != 0xCA \
			or int(mapper.get("bank_low", -1)) != 0x18 \
			or int(mapper.get("bank_high", -1)) != 0x19:
		return _unsupported("The wrapper did not restore `$18/$19` and return to `$8050`.")
	instruction_pcs.append(0x8050)
	cpu["pc"] = 0x8045
	instruction_pcs.append(0x8045)
	_set_a(cpu, 0x01)
	cpu["pc"] = 0x8047
	instruction_pcs.append(0x8047)
	var output_ram := ram.duplicate()
	for offset in STACK_SIZE:
		output_ram[0x0100 + offset] = stack[offset]
	return {
		"ok": true,
		"status": "slot11_f5_animation_countdown_at_8047",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_span_hashes": {
			WORKER_FILE: "9c07722c85a0670f8986a7e7a680bc205a587881383fd84276e520806f465c6e",
			STREAM_EVENT_DISPATCH_FILE: "a46488bd47acb67282e03aa63e4111b7efc1677dc8f10dc52e90a2d80ae7aa5c",
			STREAM_SHORT_EVENT_FILE: "7e59d0713a7eb14d55dcca569ff75b2e6fea37d394fa72531eabcfabe4c106be",
			STREAM_FOLLOWUP_FILE: "79be558cb1fe9bfbf950a23486ed0da89c1dc37e20daa52feed8f6a124225fe4",
			ACTOR_EVENT_STREAM_FILE: "98eb047a4e32fafe77d2285722a236b891fb01441b845e2d1c1fc94dfeaae314",
			C560_STUB_FILE: "170b3801f4df2a5789a9ef9fbdc6c389c58afdad9c58a94d3c7fad8e6563ccbc",
			CF72_WRAPPER_FILE: "8ef4c31ce9f19ea12db252480ab5342a4429e37c3f81148bdde0286ad03b3c13",
			BANK1A_ENTRY_FILE: "d8ec35aefd2671a7a810a2fa342db297bfb35011862ec3b907aa09fced64da90",
			ANIMATION_GATE_FILE: "7cf2b10130708c5b0a722741eb60d27e732672730c7bbfb515dd1f9a17122618",
			"fixed_mapper_helper_CE2D_CE49.bin": "6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c",
		},
		"slot_base": SLOT_11,
		"entry_pc": int(entry_cpu["pc"]),
		"exit_pc": int(cpu["pc"]),
		"yield_callsite_pc": 0x8047,
		"yield_target_pc": 0xCB0F,
		"resume_pc_after_rts": 0x804A,
		"entry_record": PackedByteArray(boundary["record"]),
		"entry_registers": entry_cpu,
		"entry_ram_image": entry_ram,
		"entry_stack_page": entry_stack,
		"call_frame_already_pushed": false,
		"pre_jsr_sp": int(cpu["sp"]),
		"yield_callsite_registers": cpu.duplicate(true),
		"yield_callsite_stack_page": stack.duplicate(),
		"mapper": mapper,
		"initial_mapper": initial_mapper,
		"ram_image": output_ram,
		"stack_page": stack,
		"ram_writes": ram_writes,
		"stack_writes": stack_writes,
		"stack_reads": stack_reads,
		"mapper_writes": mapper_writes,
		"source_reads": source_reads,
		"instruction_pcs": instruction_pcs,
		"ppu_bus_events": [],
		"apu_register_writes": [],
		"trace_state_used": false,
		"ppu_apu_effects_applied": false,
		"source_timing_modeled": false,
	}


func _run_match_index_selector(cpu: Dictionary, ram: PackedByteArray,
		source_reads: Array[Dictionary], instruction_pcs: Array[int]) -> int:
	# ROM `$8122-$8130`: X starts at zero and advances only while `$0026`
	# exceeds the indexed threshold byte. The match-zero trace uses the first row.
	instruction_pcs.append(0x8122)
	_set_x(cpu, 0)
	var match_index := int(ram[0x0026])
	instruction_pcs.append(0x8124)
	_read_event(source_reads, 0x8124, 0x0026, match_index, "match_index")
	_set_a(cpu, match_index)
	for row in 7:
		var threshold := int(_sources[SELECTOR_FILE][15 + row])
		instruction_pcs.append(0x8126)
		_read_event(source_reads, 0x8126, 0x8131 + row, threshold, "match_index_threshold")
		_compare_a(cpu, threshold)
		instruction_pcs.append(0x8129)
		if match_index < threshold:
			return int(cpu["x"])
		instruction_pcs.append(0x812B)
		if match_index == threshold:
			return int(cpu["x"])
		_set_x(cpu, (int(cpu["x"]) + 1) & 0xFF)
	return int(cpu["x"])


func _inline_dispatch(cpu: Dictionary, ram: PackedByteArray,
		stack: PackedByteArray, ram_writes: Array[Dictionary],
		stack_writes: Array[Dictionary], stack_reads: Array[Dictionary],
		source_reads: Array[Dictionary], call_pc: int, table_base: int,
		instruction_pcs: Array[int]) -> int:
	# The callsite's JSR $C509 has already pushed its return word.
	instruction_pcs.append(0xCB99)
	var prior_a := int(cpu["a"]) & 0xFF
	_set_flag(cpu, P_C, (prior_a & 0x80) != 0)
	_set_a(cpu, (prior_a << 1) & 0xFF)
	_set_y(cpu, int(cpu["a"]))
	var return_low := _pop(cpu, stack, stack_reads, 0xCB9B)
	_write_ram(ram, ram_writes, 0x0036, return_low, 0xCB9C)
	var return_high := _pop(cpu, stack, stack_reads, 0xCB9E)
	_write_ram(ram, ram_writes, 0x0037, return_high, 0xCBA0)
	_set_y(cpu, (int(cpu["y"]) + 1) & 0xFF)
	var vector_index := int(cpu["y"])
	var vector_low := _read_bank18(table_base + vector_index - 1)
	if vector_low < 0:
		return -1
	_read_event(source_reads, 0xCBA2, table_base + vector_index - 1, vector_low, "inline_vector_low")
	_set_a(cpu, vector_low)
	_push(cpu, stack, stack_writes, int(cpu["a"]), 0xCBA2, "PHA")
	_set_y(cpu, (int(cpu["y"]) + 1) & 0xFF)
	var vector_high := _read_bank18(table_base + int(cpu["y"]) - 1)
	if vector_high < 0:
		return -1
	_read_event(source_reads, 0xCBA6, table_base + int(cpu["y"]) - 1, vector_high, "inline_vector_high")
	_set_a(cpu, vector_high)
	_write_ram(ram, ram_writes, 0x0037, int(cpu["a"]), 0xCBA8)
	_set_a(cpu, _pop(cpu, stack, stack_reads, 0xCBAA))
	_write_ram(ram, ram_writes, 0x0036, int(cpu["a"]), 0xCBAB)
	var target := int(ram[0x0036]) | (int(ram[0x0037]) << 8)
	if target not in [0x806E, 0x80CB, 0x8122, 0x81FD, 0x8218]:
		return -1
	cpu["pc"] = target
	return target


func _validate_boundary(boundary: Dictionary) -> Dictionary:
	var record: Variant = boundary.get("record", PackedByteArray())
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != SLOT_11 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pending_resume", -1)) != 0 \
			or int(boundary.get("ready_delay", -1)) != 0 \
			or int(boundary.get("pc", -1)) != 0x804A \
			or int(boundary.get("sp", -1)) != 0xCA \
			or int(boundary.get("active_task_slot", -1)) != SLOT_11 \
			or int(boundary.get("bank_low", -1)) != 0x18 \
			or int(boundary.get("bank_high", -1)) != 0x19:
		return {"ok": false, "reason": "Input is not the live dispatched slot-$11 `$804A` continuation."}
	if not record is PackedByteArray or record != PackedByteArray([0x00, 0xC6, 0x18, 0x19]) \
			or not ram is PackedByteArray or ram.size() != RAM_SIZE \
			or not stack is PackedByteArray or stack.size() != STACK_SIZE \
			or int(ram[0x0000]) != SLOT_11 \
			or int(stack[0xC7]) != 0xE7 or int(stack[0xC8]) != 0x42 \
			or int(stack[0xC9]) != 0x49 or int(stack[0xCA]) != 0x80 \
			or int(boundary.get("a", -1)) != 0x42 or int(boundary.get("x", -1)) != 0x42 \
			or int(boundary.get("y", -1)) != 0xE7:
		return {"ok": false, "reason": "The live slot-$11 scheduler record, restored stack, or CPU registers are unsupported."}
	for stack_offset in STACK_SIZE:
		if int(ram[0x0100 + stack_offset]) != int(stack[stack_offset]):
			return {"ok": false, "reason": "The scheduler RAM image and stack-page snapshot disagree at `$%02X`." % stack_offset}
	if not boundary.has("p") or not boundary.has("p_known_mask") \
			or int(boundary.get("p", -1)) < 0 or int(boundary.get("p", -1)) > 0xFF \
			or int(boundary.get("p_known_mask", -1)) < 0 \
			or int(boundary.get("p_known_mask", -1)) > 0xFF:
		return {"ok": false, "reason": "The scheduler boundary omits a valid CPU status value and known-bit mask."}
	return {"ok": true}


func _validate_waiter_boundary(boundary: Dictionary) -> Dictionary:
	var record: Variant = boundary.get("record", PackedByteArray())
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != SLOT_11 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pending_resume", -1)) != 0 \
			or int(boundary.get("ready_delay", -1)) != 0 \
			or int(boundary.get("pc", -1)) != 0xCC53 \
			or int(boundary.get("sp", -1)) != 0xC3 \
			or int(boundary.get("active_task_slot", -1)) != SLOT_11 \
			or int(boundary.get("bank_low", -1)) != 0x18 \
			or int(boundary.get("bank_high", -1)) != 0x19:
		return {"ok": false, "reason": "Input is not a live scheduler-dispatched slot-$11 `$CC53` waiter continuation."}
	if not record is PackedByteArray or record != PackedByteArray([0x00, 0xBF, 0x18, 0x19]) \
			or not ram is PackedByteArray or ram.size() != RAM_SIZE \
			or not stack is PackedByteArray or stack.size() != STACK_SIZE \
			or int(ram[0x0000]) != SLOT_11 \
			or int(stack[0xC2]) != 0x52 or int(stack[0xC3]) != 0xCC \
			or int(stack[0xC4]) < 0 or int(stack[0xC4]) > 0x06 \
			or not ((int(boundary.get("x", -1)) == 0x52 and int(boundary.get("y", -1)) == 0x0C) \
				or (int(boundary.get("x", -1)) == 0x4F and int(boundary.get("y", -1)) == 0x00)):
		return {"ok": false, "reason": "The live slot-$11 `$CC53` record, return frame, or stack-resident packet count is unsupported."}
	for stack_offset in STACK_SIZE:
		if int(ram[0x0100 + stack_offset]) != int(stack[stack_offset]):
			return {"ok": false, "reason": "The `$CC53` RAM and stack snapshots disagree at `$%02X`." % stack_offset}
	if not boundary.has("p") or not boundary.has("p_known_mask") \
			or int(boundary.get("p", -1)) < 0 or int(boundary.get("p", -1)) > 0xFF \
			or int(boundary.get("p_known_mask", -1)) < 0 \
			or int(boundary.get("p_known_mask", -1)) > 0xFF:
		return {"ok": false, "reason": "The `$CC53` boundary omits a valid CPU status value and known-bit mask."}
	return {"ok": true}


func _validate_waiter_tail_boundary(boundary: Dictionary) -> Dictionary:
	var record: Variant = boundary.get("record", PackedByteArray())
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != SLOT_11 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pending_resume", -1)) != 0 \
			or int(boundary.get("ready_delay", -1)) != 0 \
			or int(boundary.get("pc", -1)) != 0xCCA3 \
			or int(boundary.get("sp", -1)) != 0xC4 \
			or int(boundary.get("active_task_slot", -1)) != SLOT_11 \
			or int(boundary.get("bank_low", -1)) != 0x18 \
			or int(boundary.get("bank_high", -1)) != 0x19:
		return {"ok": false, "reason": "Input is not a live scheduler-dispatched slot-$11 `$CCA3` counter-tail continuation."}
	if not record is PackedByteArray or record != PackedByteArray([0x00, 0xC0, 0x18, 0x19]) \
			or not ram is PackedByteArray or ram.size() != RAM_SIZE \
			or not stack is PackedByteArray or stack.size() != STACK_SIZE \
			or int(ram[0x0000]) != SLOT_11 \
			or int(stack[0xC3]) != 0xA2 or int(stack[0xC4]) != 0xCC \
			or int(stack[0xC5]) != 0xFF or int(stack[0xC6]) != 0x81 \
			or int(boundary.get("x", -1)) != 0x4F or int(boundary.get("y", -1)) != 0x00:
		return {"ok": false, "reason": "The live `$CCA3` record, outer actor return frame, or saved X/Y is unsupported."}
	for stack_offset in STACK_SIZE:
		if int(ram[0x0100 + stack_offset]) != int(stack[stack_offset]):
			return {"ok": false, "reason": "The `$CCA3` RAM and stack snapshots disagree at `$%02X`." % stack_offset}
	if not boundary.has("p") or not boundary.has("p_known_mask") \
			or int(boundary.get("p", -1)) < 0 or int(boundary.get("p", -1)) > 0xFF \
			or int(boundary.get("p_known_mask", -1)) < 0 \
			or int(boundary.get("p_known_mask", -1)) > 0xFF:
		return {"ok": false, "reason": "The `$CCA3` boundary omits valid CPU status and known-bit values."}
	return {"ok": true}


func _validate_final_packet_return_boundary(boundary: Dictionary) -> Dictionary:
	var record: Variant = boundary.get("record", PackedByteArray())
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != SLOT_11 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pending_resume", -1)) != 0 \
			or int(boundary.get("ready_delay", -1)) != 0 \
			or int(boundary.get("pc", -1)) != 0xCCD1 \
			or int(boundary.get("sp", -1)) != 0xC4 \
			or int(boundary.get("active_task_slot", -1)) != SLOT_11 \
			or int(boundary.get("bank_low", -1)) != 0x18 \
			or int(boundary.get("bank_high", -1)) != 0x19:
		return {"ok": false, "reason": "Input is not a live scheduler-dispatched slot-$11 `$CCD1` final-packet return."}
	if not record is PackedByteArray or record != PackedByteArray([0x00, 0xC0, 0x18, 0x19]) \
			or not ram is PackedByteArray or ram.size() != RAM_SIZE \
			or not stack is PackedByteArray or stack.size() != STACK_SIZE \
			or int(ram[0x0000]) != SLOT_11 \
			or int(stack[0xC3]) != 0xD0 or int(stack[0xC4]) != 0xCC \
			or int(stack[0xC5]) != 0xFF or int(stack[0xC6]) != 0x81 \
			or int(stack[0xC7]) != 0x7C or int(stack[0xC8]) != 0x80 \
			or int(stack[0xC9]) != 0x4C or int(stack[0xCA]) != 0x80 \
			or int(boundary.get("x", -1)) != 0x21 or int(boundary.get("y", -1)) != 0x00 \
			or int(ram[0x005F]) != 0x52 or int(ram[0x0060]) != 0x9F \
			or int(ram[0x05E3]) != 0x01 or int(ram[0x05E4]) != 0x00 \
			or int(ram[0x05E5]) != 0x01:
		return {"ok": false, "reason": "The live `$CCD1` record, nested RTS frames, F5 stream pointer, or index is unsupported."}
	for offset in STACK_SIZE:
		if int(ram[0x0100 + offset]) != int(stack[offset]):
			return {"ok": false, "reason": "The `$CCD1` RAM and stack snapshots disagree at `$%02X`." % offset}
	if not boundary.has("p") or not boundary.has("p_known_mask") \
			or int(boundary.get("p", -1)) < 0 or int(boundary.get("p", -1)) > 0xFF \
			or int(boundary.get("p_known_mask", -1)) < 0 \
			or int(boundary.get("p_known_mask", -1)) > 0xFF:
		return {"ok": false, "reason": "The `$CCD1` boundary omits valid CPU status and known-bit values."}
	return {"ok": true}


func _validate_f5_animation_gate_boundary(boundary: Dictionary) -> Dictionary:
	var record: Variant = boundary.get("record", PackedByteArray())
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	var mapper: Variant = boundary.get("mapper", {})
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != SLOT_11 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pending_resume", -1)) != 0 \
			or int(boundary.get("ready_delay", -1)) != 0 \
			or int(boundary.get("pc", -1)) != 0x804D \
			or int(boundary.get("sp", -1)) != 0xCA \
			or int(boundary.get("active_task_slot", -1)) != SLOT_11 \
			or int(boundary.get("bank_low", -1)) != 0x18 \
			or int(boundary.get("bank_high", -1)) != 0x19:
		return {"ok": false, "reason": "Input is not the live slot-$11 `$804D` F5 continuation."}
	if not record is PackedByteArray or record != PackedByteArray([0x00, 0xC0, 0x18, 0x19]) \
			or not ram is PackedByteArray or ram.size() != RAM_SIZE \
			or not stack is PackedByteArray or stack.size() != STACK_SIZE \
			or not mapper is Dictionary \
			or int(ram[0x0000]) != SLOT_11 \
			or int(stack[0xC7]) != 0x7C or int(stack[0xC8]) != 0x80 \
			or int(stack[0xC9]) != 0x4C or int(stack[0xCA]) != 0x80 \
			or int(boundary.get("a", -1)) != 0x80 \
			or int(boundary.get("x", -1)) != 0x21 \
			or int(boundary.get("y", -1)) != 0x01 \
			or int(ram[0x005F]) != 0x52 or int(ram[0x0060]) != 0x9F \
			or int(ram[0x05E3]) != 0x01 or int(ram[0x05E4]) != 0x00 \
			or int(ram[0x05E5]) != 0x02 or int(ram[0x05E9]) != 0x02 \
			or int(ram[0x05F3]) != 0x0D or int(ram[0x05F4]) != 0x80:
		return {"ok": false, "reason": "The live F5 stream, actor animation mode, return frames, or saved CPU state is unsupported."}
	var registers_variant: Variant = mapper.get("bank_registers", {})
	if not registers_variant is Dictionary \
			or int(registers_variant.get(6, registers_variant.get("6", -1))) != 0x18 \
			or int(registers_variant.get(7, registers_variant.get("7", -1))) != 0x19 \
			or int(mapper.get("select", -1)) not in [6, 7]:
		return {"ok": false, "reason": "The `$804D` mapper snapshot omits the current MMC3 registers 6/7."}
	for offset in STACK_SIZE:
		if int(ram[0x0100 + offset]) != int(stack[offset]):
			return {"ok": false, "reason": "The `$804D` RAM and stack snapshots disagree at `$%02X`." % offset}
	if not boundary.has("p") or not boundary.has("p_known_mask") \
			or int(boundary.get("p", -1)) < 0 or int(boundary.get("p", -1)) > 0xFF \
			or int(boundary.get("p_known_mask", -1)) < 0 \
			or int(boundary.get("p_known_mask", -1)) > 0xFF:
		return {"ok": false, "reason": "The `$804D` boundary omits valid CPU status and known-bit values."}
	return {"ok": true}


func _validate_a21a_animation_boundary(boundary: Dictionary) -> Dictionary:
	var record: Variant = boundary.get("record", PackedByteArray())
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	var mapper: Variant = boundary.get("mapper", {})
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != SLOT_11 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pending_resume", -1)) != 0 \
			or int(boundary.get("ready_delay", -1)) != 0 \
			or int(boundary.get("pc", -1)) != 0xA21A \
			or int(boundary.get("sp", -1)) != 0xC6 \
			or int(boundary.get("active_task_slot", -1)) != SLOT_11 \
			or int(boundary.get("bank_low", -1)) != 0x1A \
			or int(boundary.get("bank_high", -1)) != 0x1B:
		return {"ok": false, "reason": "Input is not the dispatched slot-$11 `$A21A` animation continuation."}
	if not record is PackedByteArray or record != PackedByteArray([0x00, 0xC2, 0x1A, 0x1B]) \
			or not ram is PackedByteArray or ram.size() != RAM_SIZE \
			or not stack is PackedByteArray or stack.size() != STACK_SIZE \
			or not mapper is Dictionary \
			or int(ram[0x0000]) != SLOT_11 \
			or int(stack[0xC7]) != 0x83 or int(stack[0xC8]) != 0xCF \
			or int(stack[0xC9]) != 0x4F or int(stack[0xCA]) != 0x80 \
			or int(boundary.get("a", -1)) != 0x1A \
			or int(boundary.get("x", -1)) != 0x1A \
			or int(boundary.get("y", -1)) != 0x01 \
			or int(ram[0x0063]) != 0x25 or int(ram[0x0064]) != 0xA4 \
			or int(ram[0x05F3]) != 0x0D or int(ram[0x05F4]) != 0x01 \
			or int(ram[0x05F5]) != 0x00 or int(ram[0x0515]) != 0x00 \
			or (int(ram[0x0022]) & 0xF8) != 0:
		return {"ok": false, "reason": "The `$A21A` event pointer, empty queue gate, mapper shadow, or saved stack is outside the trace-supported case: record=%s A/X/Y=%02X/%02X/%02X ptr=%02X%02X f3/f4/f5=%02X/%02X/%02X q=%02X mapper22=%02X stack=%s." % [
			record.hex_encode() if record is PackedByteArray else str(record),
			int(boundary.get("a", -1)), int(boundary.get("x", -1)), int(boundary.get("y", -1)),
			int(ram[0x0064]) if ram is PackedByteArray and ram.size() == RAM_SIZE else -1,
			int(ram[0x0063]) if ram is PackedByteArray and ram.size() == RAM_SIZE else -1,
			int(ram[0x05F3]) if ram is PackedByteArray and ram.size() == RAM_SIZE else -1,
			int(ram[0x05F4]) if ram is PackedByteArray and ram.size() == RAM_SIZE else -1,
			int(ram[0x05F5]) if ram is PackedByteArray and ram.size() == RAM_SIZE else -1,
			int(ram[0x0515]) if ram is PackedByteArray and ram.size() == RAM_SIZE else -1,
			int(ram[0x0022]) if ram is PackedByteArray and ram.size() == RAM_SIZE else -1,
			stack.slice(0xC2, 0xCB).hex_encode() if stack is PackedByteArray and stack.size() == STACK_SIZE else "invalid",
		]}
	var registers_variant: Variant = mapper.get("bank_registers", {})
	if not registers_variant is Dictionary \
			or int(registers_variant.get(6, registers_variant.get("6", -1))) != 0x1A \
			or int(registers_variant.get(7, registers_variant.get("7", -1))) != 0x1B \
			or int(mapper.get("select", -1)) not in [6, 7]:
		return {"ok": false, "reason": "The `$A21A` mapper snapshot omits the live MMC3 `$1A/$1B` pair."}
	for offset in STACK_SIZE:
		if int(ram[0x0100 + offset]) != int(stack[offset]):
			return {"ok": false, "reason": "The `$A21A` RAM and stack snapshots disagree at `$%02X`." % offset}
	if not boundary.has("p") or not boundary.has("p_known_mask") \
			or int(boundary.get("p", -1)) < 0 or int(boundary.get("p", -1)) > 0xFF \
			or int(boundary.get("p_known_mask", -1)) < 0 \
			or int(boundary.get("p_known_mask", -1)) > 0xFF:
		return {"ok": false, "reason": "The `$A21A` boundary omits valid CPU status values."}
	return {"ok": true}


func _validate_animation_countdown_boundary(boundary: Dictionary) -> Dictionary:
	var record: Variant = boundary.get("record", PackedByteArray())
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	var mapper: Variant = boundary.get("mapper", {})
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != SLOT_11 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pending_resume", -1)) != 0 \
			or int(boundary.get("ready_delay", -1)) != 0 \
			or int(boundary.get("pc", -1)) != 0x804A \
			or int(boundary.get("sp", -1)) != 0xCA \
			or int(boundary.get("active_task_slot", -1)) != SLOT_11 \
			or int(boundary.get("bank_low", -1)) != 0x18 \
			or int(boundary.get("bank_high", -1)) != 0x19:
		return {"ok": false, "reason": "Input is not the dispatched slot-$11 animation continuation at `$804A`."}
	if not record is PackedByteArray or record != PackedByteArray([0x00, 0xC6, 0x18, 0x19]) \
			or not ram is PackedByteArray or ram.size() != RAM_SIZE \
			or not stack is PackedByteArray or stack.size() != STACK_SIZE \
			or not mapper is Dictionary \
			or int(ram[0x0000]) != SLOT_11 \
			or int(stack[0xC7]) != (int(boundary.get("y", -1)) & 0xFF) or int(stack[0xC8]) != 0x24 \
			or int(stack[0xC9]) != 0x49 or int(stack[0xCA]) != 0x80 \
			or int(boundary.get("a", -1)) != 0x24 \
			or int(boundary.get("x", -1)) != 0x24 \
			or int(boundary.get("y", -1)) not in [0x24, 0x02, 0x03] \
			or int(ram[0x005F]) != 0x52 or int(ram[0x0060]) != 0x9F \
			or int(ram[0x0063]) != 0x27 or int(ram[0x0064]) != 0xA4 \
			or int(ram[0x05E3]) != 0x01 \
			or int(ram[0x05E4]) not in [0x00, 0x01] \
			or int(ram[0x05E5]) != (0x02 if int(ram[0x05E4]) == 0 else 0x03) \
			or int(ram[0x05F3]) != 0x0D or int(ram[0x05F4]) != 0x01 \
			or int(ram[0x05F5]) == 0 or int(ram[0x0515]) != 0 \
			or (int(ram[0x0022]) & 0xF8) != 0:
		return {"ok": false, "reason": "The `$804A` slot, animation counters, empty NMI queue, saved stack, or CPU registers are outside the live countdown case: record=%s A/X/Y=%02X/%02X/%02X RAM0=%02X ptr=%02X%02X active/delay=%02X/%02X anim=%02X/%02X/%02X queue=%02X map22=%02X stack=%s." % [
			record.hex_encode() if record is PackedByteArray else str(record),
			int(boundary.get("a", -1)), int(boundary.get("x", -1)), int(boundary.get("y", -1)),
			int(ram[0]) if ram is PackedByteArray and ram.size() == RAM_SIZE else -1,
			int(ram[0x0060]) if ram is PackedByteArray and ram.size() == RAM_SIZE else -1,
			int(ram[0x005F]) if ram is PackedByteArray and ram.size() == RAM_SIZE else -1,
			int(ram[0x05E3]) if ram is PackedByteArray and ram.size() == RAM_SIZE else -1,
			int(ram[0x05E9]) if ram is PackedByteArray and ram.size() == RAM_SIZE else -1,
			int(ram[0x05F3]) if ram is PackedByteArray and ram.size() == RAM_SIZE else -1,
			int(ram[0x05F4]) if ram is PackedByteArray and ram.size() == RAM_SIZE else -1,
			int(ram[0x05F5]) if ram is PackedByteArray and ram.size() == RAM_SIZE else -1,
			int(ram[0x0515]) if ram is PackedByteArray and ram.size() == RAM_SIZE else -1,
			int(ram[0x0022]) if ram is PackedByteArray and ram.size() == RAM_SIZE else -1,
			stack.slice(0xC7, 0xCB).hex_encode() if stack is PackedByteArray and stack.size() == STACK_SIZE else "invalid",
		]}
	var registers_variant: Variant = mapper.get("bank_registers", {})
	if not registers_variant is Dictionary \
			or int(registers_variant.get(6, registers_variant.get("6", -1))) != 0x18 \
			or int(registers_variant.get(7, registers_variant.get("7", -1))) != 0x19 \
			or int(mapper.get("select", -1)) not in [6, 7]:
		return {"ok": false, "reason": "The animation countdown boundary omits the live MMC3 `$18/$19` pair."}
	for offset in STACK_SIZE:
		if int(ram[0x0100 + offset]) != int(stack[offset]):
			return {"ok": false, "reason": "The `$804A` RAM and stack snapshots disagree at `$%02X`." % offset}
	if not boundary.has("p") or not boundary.has("p_known_mask") \
			or int(boundary.get("p", -1)) < 0 or int(boundary.get("p", -1)) > 0xFF \
			or int(boundary.get("p_known_mask", -1)) < 0 \
			or int(boundary.get("p_known_mask", -1)) > 0xFF:
		return {"ok": false, "reason": "The animation countdown boundary omits valid CPU status values."}
	return {"ok": true}


func _waiter_yield_result(boundary: Dictionary, entry_cpu: Dictionary,
		entry_ram: PackedByteArray, entry_stack: PackedByteArray, cpu: Dictionary,
		mapper: Dictionary, ram: PackedByteArray, stack: PackedByteArray,
		ram_writes: Array[Dictionary], stack_writes: Array[Dictionary],
		stack_reads: Array[Dictionary], source_reads: Array[Dictionary],
		instruction_pcs: Array[int], callsite_registers: Dictionary,
		callsite_stack: PackedByteArray, callsite_pc: int = 0xCC50,
		resume_pc: int = 0xCC53,
		result_status: String = "slot11_actor_waiter_at_cb0f_from_cc53") -> Dictionary:
	var output_ram := ram.duplicate()
	for stack_offset in STACK_SIZE:
		output_ram[0x0100 + stack_offset] = stack[stack_offset]
	return {
		"ok": true,
		"status": result_status,
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"slot_base": SLOT_11,
		"entry_pc": int(boundary["pc"]),
		"exit_pc": 0xCB0F,
		"yield_callsite_pc": callsite_pc,
		"yield_target_pc": 0xCB0F,
		"resume_pc_after_rts": resume_pc,
		"entry_record": PackedByteArray(boundary["record"]),
		"entry_registers": entry_cpu,
		"entry_ram_image": entry_ram,
		"entry_stack_page": entry_stack,
		"call_frame_already_pushed": true,
		"yield_callsite_registers": callsite_registers.duplicate(true),
		"yield_callsite_stack_page": callsite_stack.duplicate(),
		"cb0f_entry_registers": cpu.duplicate(true),
		"mapper": mapper.duplicate(true),
		"ram_image": output_ram,
		"stack_page": stack.duplicate(),
		"ram_writes": ram_writes,
		"stack_writes": stack_writes,
		"stack_reads": stack_reads,
		"source_reads": source_reads,
		"instruction_pcs": instruction_pcs,
		"source_span_hashes": {
			WAITER_FILE: "dce4d011f0e612ea074e546e43c28c5395220f2af924a49aee4b35c2491775e3",
			PACKET_BUILDER_FILE: "681bf402c35efba946da16d63cb53787bf50ed5ba87261929c10d19906b66d0c",
			COUNTER_TAIL_FILE: "28ae864c35cf13601f8cb93f4bc13f0cadcd64b9d401fff6f0bef8e2b656bee0",
		},
		"scheduler_save_contract": {
			"slot_base": SLOT_11, "delay_in_a": int(callsite_registers["a"]),
			"callsite_pc": callsite_pc, "target_pc": 0xCB0F,
			"resume_pc": resume_pc, "call_frame_already_pushed": true,
			"pre_jsr_sp": int(callsite_registers["sp"]),
			"cb0f_entry_sp": int(cpu["sp"]),
			"rom_cb0f_push_order": ["X", "Y"],
			"expected_saved_sp_after_cb0f_pushes": (int(callsite_registers["sp"]) - 4) & 0xFF,
			"mapper_low_high": PackedByteArray([0x18, 0x19]),
		},
		"ppu_bus_events": [],
		"apu_register_writes": [],
		"ppu_apu_effects_applied": false,
		"trace_state_used": false,
		"source_timing_modeled": false,
	}


func _result(boundary: Dictionary, entry_cpu: Dictionary, entry_ram: PackedByteArray,
		entry_stack: PackedByteArray, cpu: Dictionary, mapper: Dictionary,
		ram: PackedByteArray, stack: PackedByteArray, ram_writes: Array[Dictionary],
		stack_writes: Array[Dictionary], stack_reads: Array[Dictionary],
		source_reads: Array[Dictionary], instruction_pcs: Array[int],
		callsite_registers: Dictionary, callsite_stack: PackedByteArray) -> Dictionary:
	var output_ram := ram.duplicate()
	for stack_offset in STACK_SIZE:
		output_ram[0x0100 + stack_offset] = stack[stack_offset]
	return {
		"ok": true,
		"status": "slot11_actor_worker_at_cb0f_from_cc50",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"entry_pc": 0x804A,
		"exit_pc": 0xCB0F,
		"yield_callsite_pc": 0xCC50,
		"yield_target_pc": 0xCB0F,
		"resume_pc_after_rts": 0xCC53,
		"slot_base": SLOT_11,
		"entry_record": PackedByteArray(boundary["record"]),
		"source_span_hashes": {
			WORKER_FILE: "9c07722c85a0670f8986a7e7a680bc205a587881383fd84276e520806f465c6e",
			STREAM_FILE: "907c3653f2e64fa9d27a0a14a7dd38e404f0f1c05a97c0367be24e587f5ebadf",
			SELECTOR_FILE: "f4acc27853404adda00ba3dcee5f5f4ecdb2939a5d026a6d8f459261497d35b0",
			F5_HANDLER_FILE: "9ae06ade354ced65b80ae98704cd748b28b3fb80829dae0172ce09859fa37405",
			C52D_FILE: "eb93189d38ebaea8201970900e5b276a27c54c6fa2001a705945cb1d5172f371",
			WAITER_FILE: "dce4d011f0e612ea074e546e43c28c5395220f2af924a49aee4b35c2491775e3",
			"inline_dispatch": INLINE_DISPATCH_SHA256,
			"trampoline": TRAMPOLINE_SHA256,
		},
		"entry_registers": entry_cpu,
		"entry_ram_image": entry_ram,
		"entry_stack_page": entry_stack,
		"registers": cpu.duplicate(true),
		"yield_callsite_registers": callsite_registers.duplicate(true),
		"yield_callsite_stack_page": callsite_stack.duplicate(),
		"call_frame_already_pushed": true,
		"cb0f_entry_registers": cpu.duplicate(true),
		"mapper": mapper.duplicate(true),
		"ram_image": output_ram,
		"stack_page": stack,
		"ram_writes": ram_writes,
		"stack_writes": stack_writes,
		"stack_reads": stack_reads,
		"source_reads": source_reads,
		"instruction_pcs": instruction_pcs,
		"resolved_f4_target": 0x9F52,
		"resolved_f5_handler": 0x81FD,
		"scheduler_save_contract": {
			"slot_base": SLOT_11, "delay_in_a": 0x01,
			"callsite_pc": 0xCC50, "target_pc": 0xCB0F,
			"resume_pc": 0xCC53, "call_frame_already_pushed": true,
			"pre_jsr_sp": int(callsite_registers["sp"]),
			"cb0f_entry_sp": int(cpu["sp"]),
			"rom_cb0f_push_order": ["X", "Y"],
			"expected_saved_sp_after_cb0f_pushes": 0xBF,
			"mapper_low_high": PackedByteArray([0x18, 0x19]),
		},
		"ppu_bus_events": [],
		"apu_register_writes": [],
		"ppu_apu_effects_applied": false,
		"trace_state_used": false,
		"source_timing_modeled": false,
	}


func _expect(file_name: String, cpu_address: int, expected: Array[int]) -> bool:
	if not _sources.has(file_name):
		return false
	var base := _source_base(file_name)
	var source: PackedByteArray = _sources[file_name]
	var offset := cpu_address - base
	if offset < 0 or offset + expected.size() > source.size():
		return false
	for index: int in expected.size():
		if int(source[offset + index]) != expected[index]:
			return false
	return true


func _source_base(file_name: String) -> int:
	match file_name:
		WORKER_FILE: return 0x804A
		STREAM_EVENT_DISPATCH_FILE: return 0x8218
		STREAM_SHORT_EVENT_FILE: return 0x81D1
		STREAM_FILE: return 0x9F42
		STREAM_FOLLOWUP_FILE: return 0x9F54
		ACTOR_EVENT_STREAM_FILE: return 0xA3C9
		SELECTOR_FILE: return 0x8122
		F5_HANDLER_FILE: return 0x81FD
		C52D_FILE: return 0xC52D
		WAITER_FILE: return 0xCC46
		PACKET_BUILDER_FILE: return 0xCC53
		COUNTER_TAIL_FILE: return 0xCC9E
		F5_TAIL_FILE: return 0x8200
		C560_STUB_FILE: return 0xC560
		CF72_WRAPPER_FILE: return 0xCF72
		BANK1A_ENTRY_FILE: return 0x802A
		ANIMATION_GATE_FILE: return 0xA1EB
		ANIMATION_INDEX_FILE: return 0xA2AC
		ANIMATION_COMMAND_LOOP_FILE: return 0xA21A
		ANIMATION_STREAM_FILE: return 0xA425
		ANIMATION_POINTER_FILE: return 0xA42A
		ANIMATION_PPU_PACKETS_FILE: return 0xA46A
	return -1


func _read_bank18(address: int) -> int:
	if address >= 0x804A and address < 0x804A + _sources[WORKER_FILE].size():
		return int(_sources[WORKER_FILE][address - 0x804A])
	if address >= 0x8122 and address < 0x8122 + _sources[SELECTOR_FILE].size():
		return int(_sources[SELECTOR_FILE][address - 0x8122])
	if address >= 0x81FD and address < 0x81FD + _sources[F5_HANDLER_FILE].size():
		return int(_sources[F5_HANDLER_FILE][address - 0x81FD])
	return -1


func _read_stream_byte(address: int) -> int:
	var offset := address - 0x9F42
	var stream: PackedByteArray = _sources[STREAM_FILE]
	if offset >= 0 and offset < stream.size():
		return int(stream[offset])
	var followup_offset := address - 0x9F54
	var followup: PackedByteArray = _sources[STREAM_FOLLOWUP_FILE]
	if followup_offset >= 0 and followup_offset < followup.size():
		return int(followup[followup_offset])
	var actor_event_offset := address - 0xA3C9
	var actor_event: PackedByteArray = _sources[ACTOR_EVENT_STREAM_FILE]
	if actor_event_offset >= 0 and actor_event_offset < actor_event.size():
		return int(actor_event[actor_event_offset])
	return -1


func _jsr(cpu: Dictionary, stack: PackedByteArray,
		stack_writes: Array[Dictionary], pc: int, target: int) -> void:
	var return_word := (pc + 2) & 0xFFFF
	_push(cpu, stack, stack_writes, (return_word >> 8) & 0xFF, pc, "JSR_high")
	_push(cpu, stack, stack_writes, return_word & 0xFF, pc, "JSR_low")
	cpu["pc"] = target


func _rts(cpu: Dictionary, stack: PackedByteArray, stack_reads: Array[Dictionary], pc: int) -> void:
	var low := _stack_pop_raw(cpu, stack, stack_reads, pc)
	var high := _stack_pop_raw(cpu, stack, stack_reads, pc)
	cpu["pc"] = (((high << 8) | low) + 1) & 0xFFFF


func _push(cpu: Dictionary, stack: PackedByteArray,
		stack_writes: Array[Dictionary], value: int, pc: int, kind: String) -> void:
	var sp := int(cpu["sp"]) & 0xFF
	var byte_value := value & 0xFF
	stack[sp] = byte_value
	stack_writes.append({"pc": pc, "address": 0x0100 | sp, "value": byte_value, "kind": kind})
	cpu["sp"] = (sp - 1) & 0xFF


func _pop(cpu: Dictionary, stack: PackedByteArray, stack_reads: Array[Dictionary], pc: int) -> int:
	var value := _stack_pop_raw(cpu, stack, stack_reads, pc)
	_set_a(cpu, value)
	return value


func _stack_pop_raw(cpu: Dictionary, stack: PackedByteArray,
		stack_reads: Array[Dictionary], pc: int) -> int:
	var sp := (int(cpu["sp"]) + 1) & 0xFF
	cpu["sp"] = sp
	var value := int(stack[sp])
	stack_reads.append({"pc": pc, "address": 0x0100 | sp, "value": value})
	return value


func _write_ram(ram: PackedByteArray, writes: Array[Dictionary], address: int, value: int, pc: int) -> void:
	var byte_value := value & 0xFF
	ram[address] = byte_value
	writes.append({"pc": pc, "address": address, "value": byte_value})


func _set_mapper_pair_register(mapper: Dictionary, writes: Array[Dictionary],
		value: int, bank_register: int, pc: int, select_write: bool = false) -> void:
	var byte_value := value & 0xFF
	if select_write:
		mapper["select"] = bank_register
		writes.append({"pc": pc, "address": 0x8000, "value": byte_value,
			"select": bank_register})
		return
	var registers_variant: Variant = mapper.get("bank_registers", {})
	var registers: Dictionary = registers_variant.duplicate(true) if registers_variant is Dictionary else {}
	var selected := int(mapper.get("select", -1))
	if bank_register not in [6, 7] or selected != bank_register:
		return
	registers[bank_register] = byte_value
	mapper["bank_registers"] = registers
	mapper["bank_low"] = int(registers.get(6, registers.get("6", -1)))
	mapper["bank_high"] = int(registers.get(7, registers.get("7", -1)))
	writes.append({"pc": pc, "address": 0x8001, "value": byte_value,
		"select": bank_register})


func _read_event(events: Array[Dictionary], pc: int, address: int, value: int, kind: String) -> void:
	events.append({"pc": pc, "address": address, "value": value & 0xFF, "kind": kind})


func _apply_animation_mapper_helper(ram: PackedByteArray, mapper: Dictionary,
		ram_writes: Array[Dictionary], mapper_writes: Array[Dictionary],
		source_reads: Array[Dictionary], instruction_pcs: Array[int]) -> void:
	for offset in [0, 2, 3, 6, 9, 11, 13, 14, 15, 17, 18, 21, 23, 24, 27, 28]:
		instruction_pcs.append(0xCE2D + offset)
	var selector_low := int(ram[0x0022]) | 0x06
	_write_ram(ram, ram_writes, 0x0023, selector_low, 0xCE31)
	_set_mapper_pair_register(mapper, mapper_writes, selector_low, 6, 0xCE33, true)
	_read_event(source_reads, 0xCE36, 0x0024, int(ram[0x0024]), "mapper_bank_6_value")
	_set_mapper_pair_register(mapper, mapper_writes, int(ram[0x0024]), 6, 0xCE38)
	var selector_high := int(ram[0x0022]) | 0x07
	_write_ram(ram, ram_writes, 0x0023, selector_high, 0xCE3F)
	_set_mapper_pair_register(mapper, mapper_writes, selector_high, 7, 0xCE41, true)
	_read_event(source_reads, 0xCE44, 0x0025, int(ram[0x0025]), "mapper_bank_7_value")
	_set_mapper_pair_register(mapper, mapper_writes, int(ram[0x0025]), 7, 0xCE46)


func _set_a(cpu: Dictionary, value: int) -> void:
	cpu["a"] = value & 0xFF
	_set_nz(cpu, int(cpu["a"]))


func _set_x(cpu: Dictionary, value: int) -> void:
	cpu["x"] = value & 0xFF
	_set_nz(cpu, int(cpu["x"]))


func _set_y(cpu: Dictionary, value: int) -> void:
	cpu["y"] = value & 0xFF
	_set_nz(cpu, int(cpu["y"]))


func _set_nz(cpu: Dictionary, value: int) -> void:
	var p := int(cpu["p"]) & ~(P_N | P_Z)
	if (value & 0x80) != 0:
		p |= P_N
	if (value & 0xFF) == 0:
		p |= P_Z
	cpu["p"] = p
	cpu["p_known_mask"] = int(cpu["p_known_mask"]) | P_N | P_Z


func _set_flag(cpu: Dictionary, flag: int, enabled: bool) -> void:
	var p := int(cpu["p"])
	if enabled:
		p |= flag
	else:
		p &= ~flag
	cpu["p"] = p & 0xFF
	cpu["p_known_mask"] = int(cpu["p_known_mask"]) | flag


func _manifest_hex(value: Variant) -> int:
	var text := String(value).to_lower()
	if text.begins_with("0x"):
		text = text.substr(2)
	return text.hex_to_int()


func _compare_a(cpu: Dictionary, value: int) -> void:
	var before := int(cpu["a"]) & 0xFF
	var difference := (before - (value & 0xFF)) & 0xFF
	_set_flag(cpu, P_C, before >= (value & 0xFF))
	_set_nz(cpu, difference)


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()


func _reject(reason: String) -> Dictionary:
	error_message = reason
	return {"ok": false, "status": "rejected_boundary", "error": reason, "source_manifest": MANIFEST_PATH}


func _unsupported(reason: String) -> Dictionary:
	error_message = reason
	return {"ok": false, "status": "unsupported_live_branch", "error": reason, "source_manifest": MANIFEST_PATH}


func _fail(reason: String) -> bool:
	error_message = reason
	return false
