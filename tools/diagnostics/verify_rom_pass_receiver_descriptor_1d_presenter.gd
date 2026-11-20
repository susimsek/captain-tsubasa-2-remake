extends SceneTree
## Focused source-only verification of descriptor-$1D's first packet batch.
## The fixture is assembled from ROM-derived match state plus synthetic input
## coordinates; it is not an emulator or FCEUX capture.

const RECEIVER_EXECUTOR := preload("res://scripts/gameplay/rom_pass_receiver_input_executor.gd")
const PRESENTER := preload("res://scripts/gameplay/rom_pass_receiver_descriptor_1d_presenter.gd")
const RNG_REPLAY := preload("res://scripts/gameplay/rom_kickoff_rng_source_replay.gd")
const PLAYER_PROVIDER := preload("res://scripts/gameplay/rom_fresh_kickoff_match_state_provider.gd")
const RNG_SCHEDULE := "res://assets/gameplay/rom_logic/kickoff_rng_source_schedule.json"
const INPUT_HASH := "6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc"
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var rng := RNG_REPLAY.new() as RomKickoffRngSourceReplay
	if not rng.configure(RNG_SCHEDULE, INPUT_HASH) \
			or not rng.advance_to_source_frame(rng.receiver_source_frame):
		_fail("Could not prepare the pinned ROM-only roster fixture: " + rng.error_message)
		return
	var provider := PLAYER_PROVIDER.new() as RomFreshKickoffMatchStateProvider
	if not provider.configure_from_receiver_replay(rng):
		_fail("Could not derive fresh-start player records from ROM tables: " + provider.error_message)
		return
	var receiver_record: Dictionary = provider.get_player_record(10)
	if receiver_record.is_empty() or int(receiver_record.get("player_id", -1)) != 0x0B \
			or int(receiver_record.get("record_address", -1)) != 0x0378 \
			or int(receiver_record.get("level", -1)) != 0:
		_fail("Match-zero ROM roster/provider did not produce slot-$0A's normal player record.")
		return

	var executor := RECEIVER_EXECUTOR.new() as RomPassReceiverInputExecutor
	if not executor.configure_from_project_sources():
		_fail("Could not configure the receiver scan source executor: " + executor.error_message)
		return
	var boundary := _make_live_poll_fixture(receiver_record)
	var down_result: Dictionary = executor.execute_after_input_poll(boundary)
	if not bool(down_result.get("ok", false)) \
			or String(down_result.get("status", "")) != "receiver_down_scan_stopped_at_renderer_call":
		_fail("Down input did not return the pending source renderer request: " + str(down_result))
		return
	var requests: Array = down_result.get("renderer_requests", [])
	if requests.size() != 1 or int(requests[0].get("source_pc", -1)) != 0xD96C \
			or int(requests[0].get("entry_pc", -1)) != 0xEF7F \
			or int(requests[0].get("descriptor_id", -1)) != 0x1D:
		_fail("Receiver executor did not expose the exact pending `$D96C->$EF7F` descriptor-$1D call.")
		return

	var presenter = PRESENTER.new()
	if not presenter.configure_from_project_sources():
		_fail("Could not configure ROM descriptor/token sources: " + presenter.error_message)
		return
	var presentation: Dictionary = presenter.present_first_queue_batch(down_result)
	if not bool(presentation.get("ok", false)) \
			or String(presentation.get("status", "")) != "descriptor_1d_first_packet_batch_derived":
		_fail("Presenter did not derive the first packet batch: " + str(presentation))
		return
	var batch: Array = presentation.get("first_queue_batch_candidates", [])
	if batch.size() != 2 or int(presentation.get("descriptor_progress_packet_count", -1)) != 11:
		_fail("Descriptor progress sequence did not expose only the first two of its 11 source packets.")
		return
	var blank: Dictionary = batch[0]
	var top: Dictionary = batch[1]
	if int(blank.get("progress", -1)) != 0 or int(blank.get("ppu_address", -1)) != 0x2232 \
			or (blank.get("packet", PackedByteArray()) as PackedByteArray).size() != 15 \
			or int(top.get("progress", -1)) != 1 or int(top.get("ppu_address", -1)) != 0x2252 \
			or (top.get("packet", PackedByteArray()) as PackedByteArray).size() != 15 \
			or not bool(blank.get("complete", false)) or not bool(top.get("complete", false)):
		_fail("First batch candidate packets do not match descriptor progress 0/1 and ROM width 12.")
		return
	var tiles: PackedByteArray = top.get("tiles", PackedByteArray())
	var source_record_bytes := (presentation["live_player_record"]["record_bytes"] as PackedByteArray)
	if int(presentation["live_player_record"].get("slot", -1)) != 0x0A \
			or source_record_bytes != boundary["ram_image"].slice(0x0378, 0x037C) \
			or tiles.size() != 12 or tiles[0] != 0x9C or tiles[1] != 0xA8 or tiles[11] != 0x9D:
		_fail("Top-border packet does not preserve the ROM frame and the live slot-$0A record source.")
		return
	if bool(presentation.get("ppu_effects_applied", true)) \
			or bool(presentation.get("renderer_worker_executed", true)) \
			or bool(presentation.get("scheduler_continuation_executed", true)) \
			or bool(presentation.get("nmi_or_ppu_transfer_executed", true)) \
			or bool(presentation.get("trace_state_used", true)) \
			or bool(presentation.get("emulator_data_used", true)):
		_fail("Packet derivation must stop before renderer worker, scheduler, or PPU transfer.")
		return

	var bad_descriptor := down_result.duplicate(true)
	(bad_descriptor["renderer_requests"] as Array)[0]["descriptor_id"] = 0x0F
	if bool(presenter.present_first_queue_batch(bad_descriptor).get("ok", true)):
		_fail("Presenter accepted the wrong descriptor at the pending call entry.")
		return
	var trace_seeded := down_result.duplicate(true)
	trace_seeded["trace_state_used"] = true
	if bool(presenter.present_first_queue_batch(trace_seeded).get("ok", true)):
		_fail("Presenter accepted an emulator/trace-seeded source receipt.")
		return
	var unknown_player := down_result.duplicate(true)
	var unknown_ram: PackedByteArray = unknown_player["next_boundary_snapshot"]["ram_image"].duplicate()
	unknown_ram[0x0378] = 0
	unknown_player["next_boundary_snapshot"]["ram_image"] = unknown_ram
	var unresolved: Dictionary = presenter.present_first_queue_batch(unknown_player)
	if bool(unresolved.get("ok", true)):
		_fail("Presenter claimed a complete dynamic first row without a resolvable live player ID.")
		return

	print("PASS: ROM-only Down source execution reaches `$D96C->$EF7F` descriptor `$1D`; presenter derives progress-0/1 packet candidates and resolves E2 from live `$05FC`/record `$0378`.")
	print("VALIDATION CANDIDATE (progress 1): " + (top["packet"] as PackedByteArray).hex_encode())
	print("LIMIT: packet derivation is not EF7F/$800C 6502 execution, a `$04A5` queue wait, `$C515` continuation, scheduler/NMI, or actual PPU transfer; no FCEUX parity is asserted.")
	quit(0)


func _make_live_poll_fixture(receiver: Dictionary) -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(0x800)
	ram.fill(0)
	var stack := PackedByteArray()
	stack.resize(0x100)
	stack.fill(0)
	stack[0x41] = 0x34
	stack[0x42] = 0xD6
	for i in stack.size():
		ram[0x0100 + i] = stack[i]
	ram[0x001C] = 0x04
	ram[0x001E] = 0
	ram[0x0024] = 0x1A
	ram[0x0025] = 0x1B
	ram[0x0441] = 0x06
	ram[0x0624] = 0x77
	var receiver_slot := int(receiver["player_slot_index"])
	var receiver_address := int(receiver["record_address"])
	if receiver_slot != 10 or receiver_address != 0x0378:
		return {}
	ram[receiver_address] = int(receiver["player_id"])
	ram[receiver_address + 1] = int(receiver["current_energy"]) & 0xFF
	ram[receiver_address + 2] = (int(receiver["current_energy"]) >> 8) & 0xFF
	ram[receiver_address + 3] = int(receiver["level"])
	# The D8F7 coordinate scan observes this receiver at field tile $78.
	ram[receiver_address + 6] = 0x80
	ram[receiver_address + 8] = 0x50
	ram[0x0300 + 0x15 * 0x0C + 8] = 0x67
	return {
		"rom_sha256": ROM_SHA256,
		"slot_base": 0x05,
		"active_task_slot": 0x05,
		"phase": 2,
		"pc": 0xD80F,
		"sp": 0x40,
		"a": 0,
		"x": 0,
		"y": 0,
		"p": 0x30,
		"p_known_mask": 0xFF,
		"executing_cpu_bank": 0x1E,
		"mapper": {
			"cpu_c000_bank": 0x1E,
			"cpu_e000_bank": 0x1F,
			"bank_registers": {6: int(ram[0x0024]), 7: int(ram[0x0025])},
		},
		"ram_image": ram,
		"stack_page": stack,
		"polled_controller": {"direction_mask": 0x04, "button_mask": 0},
		"trace_state_used": false,
		"emulator_data_used": false,
	}


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
