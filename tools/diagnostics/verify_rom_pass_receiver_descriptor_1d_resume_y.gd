extends SceneTree
## Confirms a scheduler-restored descriptor-$1D worker may use its current Y
## register even when it differs from the earlier first-yield Y. Inputs are
## synthetic live-shaped data and do not prove the full recorded route.

const WORKER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_bank18_worker_prefix.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const WORKER_MANIFEST := "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/manifest.json"
const DESCRIPTOR_MANIFEST := "res://reference/rom_extract/gameplay/menus/pass_receiver_down_menu/manifest.json"


func _init() -> void:
	var worker = WORKER_SCRIPT.new()
	if not worker.configure_from_project_sources():
		push_error("Descriptor-$1D worker source setup failed: " + worker.error_message)
		quit(1)
		return
	var first_yield := _make_first_yield()
	var resumed_state := _make_resumed_state()
	var candidates := _make_candidates()
	var result: Dictionary = worker.call("_validate_pass_receiver_descriptor_1d_resume",
		first_yield, resumed_state, candidates)
	if not bool(result.get("ok", false)):
		push_error("Source-valid resumed Y=$03 was rejected against the older first-yield Y=$07: " \
			+ String(result.get("error", "unknown validation failure")))
		quit(1)
		return
	print("PASS: descriptor-$1D resume uses the live scheduler Y=$03 while retaining the `$EF98` frame.")
	print("LIMIT: the full ordinary-input route must still confirm this boundary and execute its PPU batches.")
	quit(0)


func _make_first_yield() -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(0x800)
	var stack := PackedByteArray()
	stack.resize(0x100)
	ram[0x0050] = 0xC7
	ram[0x0051] = 0xB6
	return {
		"status": "pass_receiver_descriptor_1d_first_yield",
		"rom_sha256": ROM_SHA256,
		"source_manifest": WORKER_MANIFEST,
		"descriptor_source_manifest": DESCRIPTOR_MANIFEST,
		"route_boundary_observed": true,
		"input_boundary_fixture": false,
		"trace_state_used": false,
		"entry_pc": 0xEF7F,
		"exit_pc": 0xC515,
		"descriptor_body_executed": false,
		"descriptor_text_rows_executed": false,
		"ram_image": ram,
		"stack_page": stack,
		"mapper": {"bank_low": 0x18, "bank_high": 0x19},
		"registers": {"pc": 0xC515, "sp": 0x40, "y": 0x07},
		"descriptor_source": {
			"descriptor_id": 0x1D,
			"pointer_table_entry": 0xB409,
			"descriptor_pointer": 0xB6C7,
			"pointer_bytes": [0xC7, 0xB6],
			"pointer_read_by_source": true,
			"descriptor_read_by_source": false,
			"text_rows_read_by_source": [],
		},
	}


func _make_resumed_state() -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(0x800)
	var stack := PackedByteArray()
	stack.resize(0x100)
	ram[0x0050] = 0xC7
	ram[0x0051] = 0xB6
	stack[0x43] = 0x98
	stack[0x44] = 0xEF
	ram[0x0100 + 0x43] = 0x98
	ram[0x0100 + 0x44] = 0xEF
	return {
		"test_fixture": false,
		"source_label": "synthetic descriptor-$1D scheduler restore boundary",
		"source_dispatch": {
			"rom_sha256": ROM_SHA256,
			"slot_base": 0x05,
			"resume_path": "yielded_rts",
			"pc": 0x8889,
			"bank": 0x18,
			"source_dispatch_observed": true,
		},
		"registers": {"a": 0, "x": 0, "y": 0x03, "sp": 0x42, "pc": 0x8889},
		"mapper": {"bank_low": 0x18, "bank_high": 0x19, "select": 0x07},
		"ram_image": ram,
		"stack_page": stack,
	}


func _make_candidates() -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for progress in range(11):
		var packet := PackedByteArray()
		packet.resize(15)
		candidates.append({"progress": progress,
			"ppu_address": 0x2232 + progress * 0x20,
			"complete": true, "packet": packet})
	return candidates
