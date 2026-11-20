extends SceneTree
## Verifies the ROM-derived PASS scenario-$38 callback/$2D source chain.
## This is a bounded source-data check; it does not simulate FCEUX timing,
## field movement, queue packets, or PPU rendering.

const CALLBACK_DISPATCHER := preload("res://scripts/gameplay/rom_slot15_callback_dispatcher_executor.gd")
const MAP_HANDLER_PREFIX := preload("res://scripts/gameplay/rom_slot15_map_handler_prefix_executor.gd")
const MAP_WORKER_PREFIX := preload("res://scripts/gameplay/rom_slot15_map_worker_8525_prefix_executor.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ram := PackedByteArray()
	ram.resize(0x800)
	ram[0x0000] = 0x15
	ram[0x0518] = 0x38
	ram[0x0524] = 0x34
	var stack := PackedByteArray()
	stack.resize(0x100)
	var source_entry := {
		"ok": true,
		"status": "reached_callback_dispatcher_entry",
		"rom_sha256": ROM_SHA256,
		"exit_pc": 0x814C,
		"dispatcher_dispatch": {
			"pc": 0x814C,
			"a": 0xF0,
			"x": 0xF0,
			"y": 0,
			"sp": 0xF2,
			"p": 0x20,
			"p_known_mask": 0,
			"slot_base": 0x15,
			"bank_low": 0x0B,
			"bank_high": 0x0C,
		},
		"ram_image": ram,
		"stack_page": stack,
	}
	var dispatcher = CALLBACK_DISPATCHER.new()
	var callback_result: Dictionary = dispatcher.execute_fresh_callback(source_entry)
	if not bool(callback_result.get("ok", false)):
		_fail("PASS scenario-$38 callback dispatch failed: " + str(callback_result.get("error", "unknown")))
		return
	if int(callback_result.get("scenario", -1)) != 0x38 \
			or int(callback_result.get("callback_id", -1)) != 0x34 \
			or int(callback_result.get("handler_pc", -1)) != 0x8327 \
			or callback_result.get("callback_bytes", PackedByteArray()) != PackedByteArray([0x02, 0x00, 0x2D]):
		_fail("Scenario-$38 did not resolve the checked callback-$34 map-$2D record: " + str(callback_result))
		return
	var map_handler = MAP_HANDLER_PREFIX.new()
	var map_result: Dictionary = map_handler.execute_from_handler_boundary(callback_result)
	if not bool(map_result.get("ok", false)):
		_fail("PASS callback-$34 map-handler prefix failed: " + str(map_result.get("error", "unknown")))
		return
	var first_batch: Dictionary = map_result.get("map_2d_first_batch_source", {})
	if int(map_result.get("map_selector", -1)) != 0x2D \
			or int(map_result.get("registers", {}).get("pc", -1)) != 0x8525 \
			or int(map_result.get("ram_image", PackedByteArray())[0x05CC]) != 0x2D \
			or not bool(first_batch.get("ok", false)) \
			or int(first_batch.get("map_selector", -1)) != 0x02 \
			or first_batch.get("chr_pair", PackedByteArray()) != PackedByteArray([0x00, 0x02]) \
			or first_batch.get("first_batch_cell_ids", PackedByteArray()) != PackedByteArray([0x00, 0x71, 0x72]) \
			or bool(first_batch.get("worker_execution_or_queue_packet_emitted", true)):
		_fail("ROM map-$2D first-batch resolution differs from the source manifest: " + str(first_batch))
		return
	var map_worker = MAP_WORKER_PREFIX.new()
	var setup_result: Dictionary = map_worker.execute_map_to_first_yield_callsite(map_result)
	if not bool(setup_result.get("ok", false)) \
			or int(setup_result.get("entry_pc", -1)) != 0x8525 \
			or int(setup_result.get("exit_pc", -1)) != 0x856F \
			or int(setup_result.get("map_data_pointer", -1)) != 0x9104 \
			or int(setup_result.get("map_selector", -1)) != 0x02 \
			or setup_result.get("chr_pair", PackedByteArray()) != PackedByteArray([0x00, 0x02]) \
			or setup_result.get("staged_chr_pair", PackedByteArray()) != PackedByteArray([0x80, 0x02]) \
			or int(setup_result.get("yield_callsite", -1)) != 0x856F \
			or bool(setup_result.get("trace_state_used", true)):
		_fail("ROM map-$2D `$8525->$856F` setup failed: " + str(setup_result.get("error", "source contract mismatch")))
		return
	print("PASS: scenario-$38 resolves callback `$34` to map `$2D` from packaged ROM bytes.")
	print("PASS: map `$2D` `$8525->$856F` setup derives selector `$02`, CHR `$00/$02`, and map pointer `$9104`.")
	print("PASS: first cell IDs `$00/$71/$72` validate; worker row expansion, scheduler continuation, PPU packets, movement, and timing remain unmodeled.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
