extends Node2D
class_name KickoffCutsceneVisuals
## ROM-data-backed presenter for KICK OFF cutscene command streams.
## The VM supplies verified byte order and scheduler ticks; this node turns
## decoded background records, CHR/palette data, sprite descriptors, and text
## tile bytes into a Godot image. Unsupported palette/raster semantics remain
## explicit rather than being inferred from screenshots.

const SCREEN_SCRIPT := preload("res://scripts/opening/rom_ppu_nametable_screen_renderer.gd")
const BACKGROUND_PACKET_LOADER := preload("res://scripts/opening/rom_background_packet_loader.gd")
const SPRITE_SCRIPT := preload("res://scripts/opening/rom_sprite_animation_prototype.gd")
const INTRO_DATA_ROOT := "res://reference/rom_extract/intro"
const GAMEPLAY_DATA_ROOT := "res://reference/rom_extract/gameplay/backgrounds"
const GAMEPLAY_ANIMATION_TIMING := "res://reference/rom_extract/gameplay/animations/kickoff/animation_timing.json"
const GAMEPLAY_SPRITE_FRAMES := "res://reference/rom_extract/gameplay/animations/kickoff/sprite_frames.json"
const FIRST_ACTION_MENU_SCRIPT := preload("res://scripts/gameplay/first_action_menu_panel.gd")
const PASS_RECEIVER_MENU_SCRIPT := preload("res://scripts/gameplay/pass_receiver_menu_panel.gd")
const FIRST_MATCH_FIELD_SCRIPT := preload("res://scripts/gameplay/first_match_field_candidate_presenter.gd")
const FIRST_COMMAND_ACTOR_SCRIPT := preload("res://scripts/gameplay/first_command_actor_source_presenter.gd")
const MEETING_CURSOR_SCRIPT := preload("res://scripts/gameplay/rom_meeting_menu_cursor.gd")
const FADE_MODEL := preload("res://scripts/opening/prototypes/ea_fade/ea_palette_fade_reference.gd")
const VISIBLE_OUTPUT_FIRST_SCANLINE := 8
const TEXT_CURSOR_START := 0x2249
const TEXT_GLYPH_QUEUE_PAYLOAD_BYTES := 2
const TEXT_GLYPH_QUEUE_RECORD_BYTES := 5
const TEXT_GLYPH_QUEUE_CAPACITY_LIMIT := 0x3D
const NAMETABLE_END := 0x2800
const FIRST_KICKOFF_STORY_BACKGROUND_ID := 0x5C
const FIRST_KICKOFF_STORY_LOWER_CHR_SCANLINE := 130
const FIRST_KICKOFF_STORY_R0_DOT_CANDIDATE := 146
const FIRST_KICKOFF_STORY_R1_DOT_CANDIDATE := 197

@onready var screen: RomPpuNametableScreenRenderer = $Screen
@onready var sprite_layer: Node2D = $Sprites

var active_background_id := -1
var active_background_data_root := ""
var _active_palette_background_id := -1
var _active_palette_background_data_root := ""
var text_cursor_base := TEXT_CURSOR_START
var text_cursor_column := 0
var presentation_gaps: Array[String] = []
var action_menu_complete := false
var action_menu_missing_dynamic: Array[Dictionary] = []
var pass_receiver_menu_status: Dictionary = {"ok": false, "state": "not_presented"}
var first_match_field_status: Dictionary = {}
var first_command_actor_status: Dictionary = {"ok": false, "state": "not_presented"}

var _ppu_memory: Dictionary = {}
var _source_ppu_nametable_overlay: Dictionary = {}
var _source_ppu_background_palette_overlay: Dictionary = {}
var _source_ppu_address := 0
var _source_ppu_address_second_write := false
var _source_ppu_scroll_x := 0
var _source_ppu_scroll_y := 0
var _source_ppuctrl_shadow := 0
var _source_ppumask_shadow := 0
var _source_ppu_register_history: Array[Dictionary] = []
var _animations: Array[RomSpriteAnimationPrototype] = []
var _pending_glyph_writes: Array[Dictionary] = []
var _pending_source_zero_fill_rows: Array[Dictionary] = []
var _pending_source_nmi_packets: Array[Dictionary] = []
var _pending_source_nmi_batch_receipt: Dictionary = {}
var _shared_ppu_queue_cursor_0628 := 0
var _source_nmi_sequence := 0
var _source_zero_fill_batch_history: Array[Dictionary] = []
var _pending_source_background_loads: Dictionary = {}
var _source_background_tasks_managed := false
var _action_menu_panel: FirstActionMenuPanel
var _pass_receiver_menu_panel: Variant
var _first_command_actor_presenter: FirstCommandActorSourcePresenter
var _meeting_speaker: RomSpriteAnimationPrototype
var _meeting_cursor: Node2D
var _display_enabled := false
var _fade_base_event_index := -1
var _fade_base_background_palette := PackedByteArray()
var _fade_base_sprite_palettes: Array[Dictionary] = []
var _pending_fade_palette_commit: Dictionary = {}
var _fade_timing_gap_reported := false


func _ready() -> void:
	# The PPU presenter keeps a 256x240 raw image. The game viewport is 256x224
	# and the matching FCEUX validation crop is raw scanlines 8..231, so move
	# the whole route presentation together rather than clipping only the field.
	position.y = -VISIBLE_OUTPUT_FIRST_SCANLINE
	visible = false
	screen.visible = false


func bind_vm(vm: KickoffCutsceneCommandVm) -> void:
	vm.presenter_event.connect(_on_presenter_event)
	vm.text_glyph_requested.connect(_on_text_glyph_requested)
	vm.wait_completed.connect(_on_wait_completed)
	vm.screen_fade_palette_step_requested.connect(_on_screen_fade_palette_step_requested)
	vm.screen_off_clear_completed.connect(_on_screen_off_clear_completed)
	vm.set_text_glyph_queue_capacity_provider(Callable(self,
		"get_text_glyph_queue_capacity_status"))


## The production route runs F9/FA packet work through its cooperative source
## task. Standalone presenter users retain the immediate decoded-data path.
func set_source_background_tasks_managed(enabled: bool) -> void:
	_source_background_tasks_managed = enabled


## Source-owned dialog geometry for the common `$88B1` clear helper. The
## startup origin is ROM-derived (`$51/$52=$49/$22`); the helper's `$4F/$50/$54`
## fields remain a distinct fixed clear origin across the first two EB waits.
func get_eb_post_wait_clear_source_inputs() -> Dictionary:
	return {
		"clear_origin_address": TEXT_CURSOR_START,
		"source_queue_cursor_0628": _shared_ppu_queue_cursor_0628,
		"queue_cursor_source": "presenter-owned packet writes; captured RAM is not consumed",
		"geometry_source": "ROM startup dialog origin `$2249` and `$88B1` geometry routine",
	}


func get_source_nmi_queue_state() -> Dictionary:
	return {
		"queue_cursor_0628": _shared_ppu_queue_cursor_0628,
		"pending_release": not _pending_source_nmi_batch_receipt.is_empty(),
		"pending_task_kind": String(_pending_source_nmi_batch_receipt.get("task_kind", "")),
		"pending_event_id": String(_pending_source_nmi_batch_receipt.get("event_id", "")),
		"pending_event_index": int(_pending_source_nmi_batch_receipt.get("event_index", -1)),
		"pending_batch_index": int(_pending_source_nmi_batch_receipt.get("batch_index", -1)),
		"pending_queue_bytes": int(_pending_source_nmi_batch_receipt.get("serialized_queue_byte_count", -1)),
	}


## Mirrors `$9B28`'s `$0628 + payload >= $3D` capacity test. The VM may retry
## a blocked glyph only after this presenter's NMI queue sequence advances.
func get_text_glyph_queue_capacity_status() -> Dictionary:
	return {
		"can_accept": _shared_ppu_queue_cursor_0628 + TEXT_GLYPH_QUEUE_PAYLOAD_BYTES \
			< TEXT_GLYPH_QUEUE_CAPACITY_LIMIT,
		"queue_cursor_0628": _shared_ppu_queue_cursor_0628,
		"nmi_sequence": _source_nmi_sequence,
	}


## Stage ROM `$98E8` zero-fill packets for the next modeled NMI consumer tick.
func queue_source_eb_clear_batch(event_index: int, batch: Dictionary) -> bool:
	if event_index < 0 or not _pending_source_zero_fill_rows.is_empty():
		return false
	var rows_variant: Variant = batch.get("rows", null)
	if not rows_variant is Array or rows_variant.is_empty():
		return false
	var cursor_before := _shared_ppu_queue_cursor_0628
	for row_variant in rows_variant:
		if not row_variant is Dictionary:
			return false
		var row: Dictionary = row_variant
		var address := int(row.get("ppu_address", -1))
		var payload_size := int(row.get("payload_size", -1))
		if address < 0x2000 or address + payload_size > NAMETABLE_END \
				or payload_size <= 0 or int(row.get("value", -1)) != 0 \
				or int(row.get("source_pc", -1)) != 0x9901 \
				or int(row.get("packet_source_pc", -1)) != 0x9B57 \
				or int(row.get("terminator_source_pc", -1)) != 0x9B5E:
			return false
		_pending_source_zero_fill_rows.append(row.duplicate(true))
		_shared_ppu_queue_cursor_0628 += payload_size + 3
	var expected_cursor := int(batch.get("queue_cursor_bytes", -1))
	if _shared_ppu_queue_cursor_0628 - cursor_before != expected_cursor \
			or _shared_ppu_queue_cursor_0628 > 0x3F:
		_pending_source_zero_fill_rows.clear()
		_shared_ppu_queue_cursor_0628 = cursor_before
		return false
	_source_zero_fill_batch_history.append({
		"event_index": event_index,
		"batch_index": int(batch.get("batch_index", -1)),
		"source_rows": rows_variant.duplicate(true),
		"queue_cursor_before": cursor_before,
		"queue_cursor_after": _shared_ppu_queue_cursor_0628,
		"nmi_commit_pending": true,
	})
	return true


## Prepare a background command's ROM-derived packet groups without applying
## them all at once. The route owns when each scheduler release commits.
func prepare_source_background_load(event: Dictionary) -> Dictionary:
	var kind := String(event.get("kind", ""))
	var expected_opcode := 0xF9 if kind == "background_1" else 0xFA
	var background_id := int(event.get("id", -1))
	var event_index := int(event.get("event_index", -1))
	var arguments: Array = event.get("arguments", [])
	if kind not in ["background_1", "background_2"] \
			or int(event.get("opcode", -1)) != expected_opcode \
			or arguments.size() != 1 or int(arguments[0]) != background_id \
			or event_index < 0:
		return {"ok": false, "error": "Background load request is not a decoded cutscene F9/FA event."}
	if _pending_source_background_loads.has(event_index):
		return {"ok": false, "error": "A source background load already owns this event index."}
	var data_root := INTRO_DATA_ROOT if FileAccess.file_exists(
		INTRO_DATA_ROOT + "/background_%02X_layout.json" % background_id) else GAMEPLAY_DATA_ROOT
	if not FileAccess.file_exists(data_root + "/background_%02X_layout.json" % background_id):
		return {"ok": false, "error": "No ROM-derived layout for background $%02X." % background_id}
	var loader: RomBackgroundPacketLoader = BACKGROUND_PACKET_LOADER.new()
	if not loader.build_packets(background_id, data_root):
		return {"ok": false, "error": "Packet builder rejected background $%02X: %s" % [background_id, loader.last_error]}
	var batches: Array[Dictionary] = loader.build_capacity_batches()
	if batches.is_empty():
		return {"ok": false, "error": "Background $%02X has no source capacity batches." % background_id}
	var replace_primary := kind == "background_1"
	_active_palette_background_id = background_id
	_active_palette_background_data_root = data_root
	if replace_primary:
		active_background_id = background_id
		active_background_data_root = data_root
		_ppu_memory.clear()
		text_cursor_base = TEXT_CURSOR_START
		text_cursor_column = 0
		if not screen.set_background_profile(background_id, PackedByteArray(), data_root):
			return {"ok": false, "error": "Renderer rejected background $%02X." % background_id}
		if not _apply_kickoff_story_chr_raster(background_id):
			return {"ok": false, "error": "Renderer rejected the ROM-derived CHR raster for background $%02X." % background_id}
	_pending_source_background_loads[event_index] = {
		"background_id": background_id,
		"data_root": data_root,
		"replace_primary": replace_primary,
		"batches": batches,
	}
	return {
		"ok": true,
		"event_index": event_index,
		"background_id": background_id,
		"source_rom_sha256": String(loader.metadata.get("rom_sha256", "")),
		"record_cpu_address": _parse_source_address(String(loader.metadata.get("record_cpu_address", ""))),
		"record_file_offset": _parse_source_address(String(loader.metadata.get("record_file_offset", ""))),
		"record_bytes": _bytes_from_hex(String(loader.metadata.get("record_raw_hex", ""))),
		"packet_count": loader.packets.size(),
		"capacity_batch_count": batches.size(),
		"queue_cursor_limit": int(loader.metadata.get("queue_cursor_limit", 0)),
		"source_packet_stream": loader.packets.duplicate(true),
		"source_queue_cursor_0628": _shared_ppu_queue_cursor_0628,
		"source_queue_cursor_source": "rom_derived_presenter_state",
		"replace_primary": replace_primary,
	}


func apply_source_background_batch(event_index: int, batch_index: int) -> bool:
	if not _pending_source_background_loads.has(event_index):
		return false
	var load_state: Dictionary = _pending_source_background_loads[event_index]
	var batches: Array = load_state.get("batches", [])
	if batch_index < 0 or batch_index >= batches.size():
		return false
	var batch: Dictionary = batches[batch_index]
	for packet_variant in batch.get("packets", []):
		if not packet_variant is Dictionary:
			return false
		var packet: Dictionary = packet_variant
		var address := int(packet.get("ppu_address", -1))
		var payload: PackedByteArray = packet.get("payload", PackedByteArray())
		if address < 0 or payload.is_empty():
			return false
		for byte_index in payload.size():
			_ppu_memory[address + byte_index] = int(payload[byte_index])
	screen.set_ppu_memory(_ppu_memory)
	return true


func finish_source_background_load(event_index: int) -> bool:
	if not _pending_source_background_loads.has(event_index):
		return false
	_pending_source_background_loads.erase(event_index)
	return true


## Build the 32-byte palette payload written by the ROM's `$9A35->$9A71`
## `$F3 $00` path. The latest F9/FA record selects the background palette;
## the final active FB animation record selects the sprite palette.
func build_f3_00_palette_nmi_batch(event: Dictionary) -> Dictionary:
	var arguments: Array = event.get("arguments", [])
	if int(event.get("opcode", -1)) != 0xF3 or arguments.size() != 1 \
			or int(arguments[0]) != 0 or _active_palette_background_id < 0:
		return {"ok": false, "error": "F3 $00 has no validated active background source."}
	var background_palette := _load_active_rom_background_palette()
	if background_palette.size() != 16:
		return {"ok": false, "error": "Active background palette did not match its ROM layout and source bytes."}
	if _animations.is_empty():
		return {"ok": false, "error": "F3 $00 has no active ROM animation for its sprite palette selector."}
	# `_replace_animations` stores nodes in reverse source order. The first node
	# therefore owns the final FB record, which is the ROM's `$49` selector.
	var sprite_palette: PackedByteArray = _animations[0].get_gameplay_source_palette_bytes()
	if sprite_palette.size() != 16:
		return {"ok": false, "error": "Final FB animation has no validated ROM sprite palette."}
	var source_palette := background_palette.duplicate()
	source_palette.append_array(sprite_palette)
	var payload := FADE_MODEL.build_palette(source_palette, 0x0F, 0x0F)
	var cursor_before := _shared_ppu_queue_cursor_0628
	if payload.size() != 0x20 or cursor_before + payload.size() >= TEXT_GLYPH_QUEUE_CAPACITY_LIMIT:
		return {"ok": false, "error": "F3 $00 source queue capacity requires an unmodeled retry before palette staging."}
	var writes: Array[Dictionary] = []
	for byte_index in payload.size():
		writes.append({"packet_index": 0, "byte_index": byte_index,
			"ppu_address": 0x3F00 + byte_index, "value": int(payload[byte_index])})
	return {
		"ok": true,
		"task_kind": "f3_00_palette",
		"event_id": "f3_00_event_%d" % int(event.get("event_index", -1)),
		"event_index": int(event.get("event_index", -1)),
		"batch_index": 0,
		"queue_cursor_before": cursor_before,
		"serialized_queue_byte_count": payload.size() + 3,
		"queue_cursor_bytes": cursor_before + payload.size() + 3,
		"packets": [{"ppu_address": 0x3F00, "payload": payload}],
		"ppu_writes": writes,
		"source_palette": source_palette,
		"palette_payload": payload,
		"background_id": _active_palette_background_id,
	}


func _load_active_rom_background_palette() -> PackedByteArray:
	var id_hex := "%02X" % _active_palette_background_id
	var layout_path := "%s/background_%s_layout.json" % [
		_active_palette_background_data_root, id_hex]
	if not FileAccess.file_exists(layout_path):
		return PackedByteArray()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(layout_path))
	if not parsed is Dictionary:
		return PackedByteArray()
	var layout: Dictionary = parsed
	if str(layout.get("rom_sha256", "")) != "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097" \
			or str(layout.get("background_id", "")).to_upper() != "0X%s" % id_hex:
		return PackedByteArray()
	var record := FileAccess.get_file_as_bytes("res://" + str(layout.get("record_source_bin", "")))
	var expected_record := _bytes_from_hex(str(layout.get("record_raw_hex", "")))
	var palette_index := int(layout.get("palette_index", -1))
	if record.size() < 3 or record != expected_record \
			or palette_index != (int(record[2]) & 0x3F) \
			or _parse_source_address(String(layout.get("palette_file_offset", ""))) != 0xD010 + palette_index * 16:
		return PackedByteArray()
	var expected_source := "%s/background_palette_%02X.bin" % [
		_active_palette_background_data_root.trim_prefix("res://"), palette_index]
	if str(layout.get("palette_source_bin", "")) != expected_source:
		return PackedByteArray()
	var palette := FileAccess.get_file_as_bytes("res://" + expected_source)
	if palette.size() != 16 or palette != _bytes_from_hex(str(layout.get("palette_raw_hex", ""))):
		return PackedByteArray()
	return palette


## F9 `$5C` begins with CHR R0/R1=`$3C/$3E`, then the shared E8 `$01` / `$A160`
## IRQ path installs `$00/$02` for the lower dialogue band. The write scanline
## is measured at 130 for this shared ROM handler. The renderer's dot positions
## are candidates from the same handler's frame-2018 trace; `$5C` has only
## frame-end MMC3 snapshots, so the exact dot phase and first affected pixel
## remain unverified for this route.
func _apply_kickoff_story_chr_raster(background_id: int) -> bool:
	if background_id != FIRST_KICKOFF_STORY_BACKGROUND_ID:
		return true
	var lower_chr_writes: Array[Dictionary] = [
		{
			"scanline": FIRST_KICKOFF_STORY_LOWER_CHR_SCANLINE,
			"dot": FIRST_KICKOFF_STORY_R0_DOT_CANDIDATE,
			"register": 0,
			"value": 0x00,
			"source_pc": "$A1D4/$A1D7",
			"phase_verified": false,
		},
		{
			"scanline": FIRST_KICKOFF_STORY_LOWER_CHR_SCANLINE,
			"dot": FIRST_KICKOFF_STORY_R1_DOT_CANDIDATE,
			"register": 1,
			"value": 0x02,
			"source_pc": "$A1E0/$A1E3",
			"phase_verified": false,
		},
	]
	return screen.set_source_mmc3_chr_writes([0x3C, 0x3E], lower_chr_writes)


## Stage a ROM-source packet batch in the shared PPU queue. The source route
## receives a release receipt only after the next modeled NMI drains it.
func stage_source_nmi_packet_batch(batch: Dictionary, consumer_source_pc: int) -> bool:
	var append_f3_palette_to_fa0f_tail := String(batch.get("task_kind", "")) == "f3_00_palette" \
		and String(_pending_source_nmi_batch_receipt.get("task_kind", "")) == "fa_0f" \
		and int(batch.get("queue_cursor_before", -1)) \
			== int(_pending_source_nmi_batch_receipt.get("queue_cursor_after_staging", -2))
	if not _pending_source_nmi_batch_receipt.is_empty() and not append_f3_palette_to_fa0f_tail:
		return false
	var packets_variant: Variant = batch.get("packets", null)
	if not packets_variant is Array:
		return false
	var packets: Array = packets_variant
	var cursor_before := int(batch.get("queue_cursor_before", -1))
	if cursor_before != _shared_ppu_queue_cursor_0628 or cursor_before < 0 \
			or cursor_before > 0x3F:
		return false
	var encoded_bytes := 0
	var normalized_writes: Array[Dictionary] = []
	var normalized_packets: Array[Dictionary] = []
	for packet_index in packets.size():
		var packet_variant: Variant = packets[packet_index]
		if not packet_variant is Dictionary:
			return false
		var packet: Dictionary = packet_variant
		var address := int(packet.get("ppu_address", -1))
		var payload_variant: Variant = packet.get("payload", PackedByteArray())
		var nametable_packet := address >= 0x2000 and address < 0x2800
		var palette_packet := address >= 0x3F00 and address < 0x3F20
		if (not nametable_packet and not palette_packet) or not payload_variant is PackedByteArray:
			return false
		var payload: PackedByteArray = payload_variant
		var ppu_region_end := 0x2800 if nametable_packet else 0x3F20
		if payload.is_empty() or address + payload.size() > ppu_region_end \
				or int(packet.get("queue_encoded_bytes", payload.size() + 3)) != payload.size() + 3:
			return false
		encoded_bytes += payload.size() + 3
		normalized_packets.append({"ppu_address": address, "payload": payload.duplicate()})
		for byte_index in payload.size():
			normalized_writes.append({"packet_index": packet_index,
				"byte_index": byte_index, "ppu_address": address + byte_index,
				"value": int(payload[byte_index])})
	var declared_bytes := int(batch.get("serialized_queue_byte_count", batch.get("queued_bytes", -1)))
	var cursor_after := int(batch.get("queue_cursor_bytes", batch.get("queue_cursor_after_staging", -1)))
	if packets.is_empty() or encoded_bytes != declared_bytes \
			or cursor_after != cursor_before + encoded_bytes \
			or cursor_after > 0x3F or consumer_source_pc < 0:
		return false
	var expected_writes_variant: Variant = batch.get("ppu_writes", normalized_writes)
	if not expected_writes_variant is Array or expected_writes_variant != normalized_writes:
		return false
	if append_f3_palette_to_fa0f_tail:
		var prior_receipt := _pending_source_nmi_batch_receipt.duplicate(true)
		var combined_packets: Array[Dictionary] = _pending_source_nmi_packets.duplicate(true)
		combined_packets.append_array(normalized_packets)
		var combined_writes: Array[Dictionary] = prior_receipt.get("ppu_writes", []).duplicate(true)
		combined_writes.append_array(normalized_writes)
		_pending_source_nmi_packets = combined_packets
		prior_receipt["task_kind"] = "fa_0f_f3_00"
		prior_receipt["event_id"] = String(batch.get("event_id", ""))
		prior_receipt["event_index"] = int(batch.get("event_index", -1))
		prior_receipt["batch_index"] = int(batch.get("batch_index", -1))
		prior_receipt["consumer_source_pc"] = consumer_source_pc
		prior_receipt["queue_cursor_after_staging"] = cursor_after
		prior_receipt["serialized_queue_byte_count"] = int(prior_receipt.get(
			"serialized_queue_byte_count", 0)) + encoded_bytes
		prior_receipt["packets"] = combined_packets.duplicate(true)
		prior_receipt["ppu_writes"] = combined_writes.duplicate(true)
		prior_receipt["source_batches"] = [prior_receipt.get("source_batch", {}).duplicate(true),
			batch.duplicate(true)]
		prior_receipt["source_batch"] = {"kind": "fa_0f_final_segment_plus_f3_00",
			"batches": prior_receipt["source_batches"].duplicate(true)}
		_pending_source_nmi_batch_receipt = prior_receipt
	else:
		_pending_source_nmi_packets = normalized_packets
		_pending_source_nmi_batch_receipt = {
			"task_kind": String(batch.get("task_kind", "")),
			"event_id": String(batch.get("event_id", "")),
			"event_index": int(batch.get("event_index", -1)),
			"batch_index": int(batch.get("batch_index", batch.get("segment_index", -1))),
			"consumer_source_pc": consumer_source_pc,
			"staged_cursor_before": cursor_before,
			"queue_cursor_after_staging": cursor_after,
			"serialized_queue_byte_count": encoded_bytes,
			"packets": normalized_packets.duplicate(true),
			"ppu_writes": normalized_writes.duplicate(true),
			"source_batch": batch.duplicate(true),
		}
	_shared_ppu_queue_cursor_0628 = cursor_after
	return true


## Register a source branch that must release bytes already occupying the
## shared queue before it can reserve its first packet.
func stage_source_nmi_inherited_queue_release(task_kind: String, cursor: int,
		consumer_source_pc: int, source_event_index: int = -1) -> bool:
	if not _pending_source_nmi_batch_receipt.is_empty() or cursor <= 0 \
			or cursor != _shared_ppu_queue_cursor_0628 or consumer_source_pc < 0 \
			or task_kind.is_empty():
		return false
	_pending_source_nmi_batch_receipt = {
		"task_kind": task_kind,
		"event_id": "",
		"event_index": source_event_index,
		"batch_index": -1,
		"consumer_source_pc": consumer_source_pc,
		"staged_cursor_before": cursor,
		"queue_cursor_after_staging": cursor,
		"serialized_queue_byte_count": cursor,
		"packets": [],
		"ppu_writes": [],
		"source_batch": {},
		"flush_existing_queue": true,
	}
	return true


func advance_source_tick(source_frame: int = -1) -> Dictionary:
	_commit_pending_fade_palette()
	var queue_cursor_at_nmi := _shared_ppu_queue_cursor_0628
	var source_queue_has_pending_records := not _pending_source_zero_fill_rows.is_empty() \
		or not _pending_glyph_writes.is_empty() or not _pending_source_nmi_packets.is_empty() \
		or not _pending_source_nmi_batch_receipt.is_empty()
	_commit_pending_source_zero_fill_rows()
	_commit_pending_glyph_writes()
	var committed_packet_writes: Array[Dictionary] = []
	var committed_nametable_packet := false
	for packet_index in _pending_source_nmi_packets.size():
		var packet: Dictionary = _pending_source_nmi_packets[packet_index]
		var address := int(packet.get("ppu_address", -1))
		var payload: PackedByteArray = packet.get("payload", PackedByteArray())
		for byte_index in payload.size():
			var value := int(payload[byte_index])
			if address + byte_index < 0x3F00:
				_ppu_memory[address + byte_index] = value
				committed_nametable_packet = true
			committed_packet_writes.append({"packet_index": packet_index,
				"byte_index": byte_index, "ppu_address": address + byte_index,
				"value": value})
	if committed_nametable_packet:
		screen.set_ppu_memory(_ppu_memory)
	var receipt: Dictionary = {}
	if source_queue_has_pending_records and queue_cursor_at_nmi > 0:
		_source_nmi_sequence += 1
		var staged_receipt: Dictionary = _pending_source_nmi_batch_receipt
		var staged_cursor_before := int(staged_receipt.get("staged_cursor_before", queue_cursor_at_nmi))
		var serialized_queue_byte_count := int(staged_receipt.get(
			"serialized_queue_byte_count", queue_cursor_at_nmi))
		receipt = {
			"ok": true,
			"source_frame": source_frame,
			"nmi_sequence": _source_nmi_sequence,
			"queue_cursor_before": staged_cursor_before,
			"queue_cursor_at_nmi": queue_cursor_at_nmi,
			"queued_bytes": serialized_queue_byte_count,
			"committed_bytes": serialized_queue_byte_count,
			"queue_cursor_after": 0,
			"queue_drained": true,
			"committed_ppu_writes": committed_packet_writes.duplicate(true),
		}
		if not staged_receipt.is_empty():
			receipt["task_kind"] = String(staged_receipt.get("task_kind", ""))
			receipt["event_id"] = String(staged_receipt.get("event_id", ""))
			receipt["event_index"] = int(staged_receipt.get("event_index", -1))
			receipt["batch_index"] = int(staged_receipt.get("batch_index", -1))
			receipt["consumer_source_pc"] = int(staged_receipt.get("consumer_source_pc", -1))
			receipt["nmi_consumer_pc"] = int(staged_receipt.get("consumer_source_pc", -1))
			receipt["staged_cursor_before"] = int(staged_receipt.get("staged_cursor_before", -1))
			receipt["queue_cursor_after_staging"] = int(staged_receipt.get("queue_cursor_after_staging", -1))
			receipt["serialized_queue_byte_count"] = int(staged_receipt.get("serialized_queue_byte_count", -1))
			receipt["source_batch"] = staged_receipt.get("source_batch", {}).duplicate(true)
		_shared_ppu_queue_cursor_0628 = 0
	_pending_source_nmi_packets.clear()
	_pending_source_nmi_batch_receipt.clear()
	for animation_node in _animations:
		if is_instance_valid(animation_node):
			animation_node.advance_source_tick()
	return receipt


func clear_route_screen() -> void:
	_pending_glyph_writes.clear()
	_pending_source_zero_fill_rows.clear()
	_pending_source_nmi_packets.clear()
	_pending_source_nmi_batch_receipt.clear()
	_shared_ppu_queue_cursor_0628 = 0
	_pending_fade_palette_commit.clear()
	_source_ppu_nametable_overlay.clear()
	_source_ppu_background_palette_overlay.clear()
	_source_ppu_address = 0
	_source_ppu_address_second_write = false
	_source_ppu_scroll_x = 0
	_source_ppu_scroll_y = 0
	_source_ppuctrl_shadow = 0
	_source_ppumask_shadow = 0
	_source_ppu_register_history.clear()
	_fade_base_event_index = -1
	_fade_base_background_palette.clear()
	_fade_base_sprite_palettes.clear()
	_fade_timing_gap_reported = false
	_ppu_memory.clear()
	_clear_animations()
	_clear_meeting_cursor()
	active_background_id = -1
	active_background_data_root = ""
	text_cursor_base = TEXT_CURSOR_START
	text_cursor_column = 0
	action_menu_complete = false
	action_menu_missing_dynamic.clear()
	first_match_field_status.clear()
	first_command_actor_status = {"ok": false, "state": "not_presented"}
	_clear_first_command_actor_presenter()
	_display_enabled = false
	visible = false
	screen.visible = false
	screen.set_ppu_memory(_ppu_memory)


## Apply ordered writes emitted by a ROM-source NMI queue consumer. The source
## owns packet contents; this method models only the PPU register effects that
## the current nametable renderer can present.
func apply_source_ppu_bus_events(events: Array, initial_ppuctrl_shadow: int = -1) -> Dictionary:
	if not is_instance_valid(screen):
		return {"ok": false, "error": "The source PPU writer has no live screen renderer."}
	if initial_ppuctrl_shadow < -1 or initial_ppuctrl_shadow > 0xFF:
		return {"ok": false, "error": "The source PPUCTRL shadow is outside byte range."}
	if initial_ppuctrl_shadow >= 0:
		_source_ppuctrl_shadow = initial_ppuctrl_shadow
	var updated_memory := _ppu_memory.duplicate()
	var background_palette := screen.get_background_palette_bytes()
	var applied_nametable_writes := 0
	var applied_background_palette_writes := 0
	var ignored_chr_rom_writes := 0
	var unapplied_writes: Array[Dictionary] = []
	for event_variant in events:
		if not event_variant is Dictionary:
			return {"ok": false, "error": "A source PPU bus event is not an object."}
		var event: Dictionary = event_variant
		var operation := String(event.get("operation", ""))
		var register := int(event.get("ppu_register", -1))
		if operation == "read" and register == 0x2002:
			_source_ppu_address_second_write = false
			continue
		if operation != "write":
			return {"ok": false, "error": "Unsupported source PPU bus event `%s` at `$%04X`." % [operation, register]}
		var value := int(event.get("value", -1))
		if value < 0 or value > 0xFF:
			return {"ok": false, "error": "A source PPU write has no byte value."}
		match register:
			0x2000:
				_source_ppuctrl_shadow = value
			0x2001:
				_source_ppumask_shadow = value # PPUMASK gates display; preserve its source shadow.
			0x2005:
				if not _source_ppu_address_second_write:
					_source_ppu_scroll_x = value
					_source_ppu_address_second_write = true
				else:
					_source_ppu_scroll_y = value
					_source_ppu_address_second_write = false
					screen.set_scroll_pixels(_source_ppu_scroll_x, _source_ppu_scroll_y)
			0x2006:
				if not _source_ppu_address_second_write:
					_source_ppu_address = (value & 0x3F) << 8
					_source_ppu_address_second_write = true
				else:
					_source_ppu_address = (_source_ppu_address & 0x3F00) | value
					_source_ppu_address_second_write = false
			0x2007:
				var ppu_address := _source_ppu_address & 0x3FFF
				if ppu_address >= 0x2000 and ppu_address < 0x3F00:
					var canonical_address := ppu_address
					if canonical_address >= 0x3000:
						canonical_address = 0x2000 | (canonical_address & 0x0FFF)
					updated_memory[canonical_address] = value
					_source_ppu_nametable_overlay[canonical_address] = value
					applied_nametable_writes += 1
				elif ppu_address >= 0x3F00:
					var palette_index := ppu_address & 0x1F
					if palette_index in [0x10, 0x14, 0x18, 0x1C]:
						palette_index -= 0x10
					if palette_index < 16 and background_palette.size() == 16:
						background_palette[palette_index] = value & 0x3F
						_source_ppu_background_palette_overlay[palette_index] = value & 0x3F
						applied_background_palette_writes += 1
					else:
						unapplied_writes.append({"source_pc": int(event.get("source_pc", -1)),
							"ppu_address": ppu_address, "value": value,
							"reason": "sprite palette is outside the current background renderer"})
				else:
					if screen.has_verified_source_chr_rom():
						# The supplied mapper-4 cartridge has CHR-ROM, so PPUDATA writes
						# in this range are ignored by the PPU; MMC3 selectors choose
						# which read-only ROM banks the renderer samples.
						ignored_chr_rom_writes += 1
					else:
						unapplied_writes.append({"source_pc": int(event.get("source_pc", -1)),
							"ppu_address": ppu_address, "value": value,
							"reason": "pattern-table write needs verified CHR-ROM behavior or a modeled CHR-RAM target"})
				var increment := 32 if (_source_ppuctrl_shadow & 0x04) != 0 else 1
				_source_ppu_address = (_source_ppu_address + increment) & 0x7FFF
			_:
				return {"ok": false, "error": "Unsupported ROM-source PPU register `$%04X`." % register}
	_ppu_memory = updated_memory
	screen.set_ppu_memory(_ppu_memory)
	if applied_background_palette_writes > 0:
		screen.set_background_palette_bytes(background_palette)
	return {
		"ok": true,
		"status": "applied" if unapplied_writes.is_empty() else "applied_with_unrepresented_ppu_writes",
		"source_event_count": events.size(),
		"nametable_writes_applied": applied_nametable_writes,
		"background_palette_writes_applied": applied_background_palette_writes,
		"ignored_chr_rom_writes": ignored_chr_rom_writes,
		"unapplied_writes": unapplied_writes,
		"ppu_address_after": _source_ppu_address,
		"ppuctrl_shadow_after": _source_ppuctrl_shadow,
		"scroll_pixels_after": Vector2i(_source_ppu_scroll_x, _source_ppu_scroll_y),
		"ppu_shared_write_toggle_after": _source_ppu_address_second_write,
		"runtime_rom_dependency": false,
	}


## Apply the decoded $98A0 nametable clear through the same PPU bus path used
## for other ROM-source writes. The caller supplies the ROM shadow state and
## ordered $2000/$2001/$2006/$2007 writes; palette and actor presentation are
## intentionally left untouched by this helper.
func apply_source_ppu_clear_events(events: Array, initial_ppuctrl_shadow: int) -> Dictionary:
	if events.size() != 0x806 or initial_ppuctrl_shadow < 0 or initial_ppuctrl_shadow > 0xFF:
		return {"ok": false, "error": "The ROM $98A0 clear requires its six register writes and 2,048 data writes."}
	var result := apply_source_ppu_bus_events(events, initial_ppuctrl_shadow)
	if not bool(result.get("ok", false)):
		return result
	if int(result.get("nametable_writes_applied", -1)) != 0x800 \
			or int(result.get("ppu_address_after", -1)) != 0x2800 \
			or _source_ppu_address_second_write:
		return {"ok": false, "error": "The ROM $98A0 PPU clear did not end at $2800 with a reset write toggle."}
	return result


func get_source_ppu_state() -> Dictionary:
	return {"ctrl_shadow": _source_ppuctrl_shadow,
		"mask_shadow": _source_ppumask_shadow,
		"ppu_address": _source_ppu_address,
		"shared_write_toggle": _source_ppu_address_second_write,
		"scroll_x": _source_ppu_scroll_x,
		"scroll_y": _source_ppu_scroll_y}


## Prepare the source's bank-1 $A64C clear/scene sequence. The NES keeps its
## display active while the ROM background packets are loaded, so expose the
## cleared PPU canvas before scene $44 begins dispatching.
func prepare_pre_match_meeting_scene() -> void:
	clear_route_screen()
	_display_enabled = true
	visible = true
	screen.visible = true


## Install the source cursor after scene $44 has completed. Its position and
## graphics are built from the bank-1 $ADD0 descriptor, ROM CHR, and ROM sprite
## palette $0A; only the current Y row is supplied by the route input model.
func present_pre_match_meeting_menu(cursor_y: int = 0x98) -> bool:
	if active_background_id != 0x5F:
		presentation_gaps.append("MEETING menu requested before ROM background $5F was applied.")
		return false
	if _meeting_cursor == null:
		_meeting_cursor = MEETING_CURSOR_SCRIPT.new() as Node2D
		_meeting_cursor.name = "MeetingMenuCursor"
		sprite_layer.add_child(_meeting_cursor)
	if not _meeting_cursor.set_cursor_y(cursor_y):
		presentation_gaps.append("MEETING cursor: " + _meeting_cursor.last_error)
		return false
	_meeting_cursor.visible = true
	visible = true
	screen.visible = true
	_display_enabled = true
	return true


func set_pre_match_meeting_cursor_y(cursor_y: int) -> bool:
	if _meeting_cursor == null:
		return false
	return _meeting_cursor.set_cursor_y(cursor_y)


## Draw the two first-action windows from their target-ROM descriptors and
## source text rows. Dynamic text and values must come from match state supplied
## by the route; missing substitutions are reported instead of guessed.
func present_first_action_menu(player_state: FirstActionMenuMatchPlayerState,
		actor_source_context: Dictionary = {},
		descriptor_01_source_context: Dictionary = {}) -> bool:
	_clear_meeting_cursor()
	if first_match_field_status.is_empty() or not bool(first_match_field_status.get("ok", false)):
		if not present_first_match_field_candidate({}, descriptor_01_source_context):
			presentation_gaps.append("first-match field candidate: " + str(first_match_field_status.get("error", "source data unavailable")))
	_action_menu_panel = FIRST_ACTION_MENU_SCRIPT.new()
	if not _action_menu_panel.rebuild_for_match_state(player_state):
		presentation_gaps.append("first action menu ROM layout: " + _action_menu_panel.last_error)
		return false
	_ppu_memory = _action_menu_panel.apply_to_ppu_memory(_ppu_memory)
	action_menu_missing_dynamic = _action_menu_panel.missing_dynamic.duplicate(true)
	action_menu_complete = action_menu_missing_dynamic.is_empty()
	screen.set_ppu_memory(_ppu_memory)
	visible = true
	screen.visible = true
	_display_enabled = true
	if actor_source_context.is_empty():
		first_command_actor_status = {
			"ok": false,
			"state": "awaiting_decoded_source_context",
			"required": ["mirror_mode", "scroll_x", "clip_y_min", "clip_y_max"],
		}
		presentation_gaps.append("first-command actors await live ROM-derived mirror/scroll/clip state.")
	else:
		present_first_command_actor_pose(player_state, actor_source_context)
	return true


## Present the ROM-described descriptor-$0F PASS receiver prompt over the
## current field image. The field state remains caller-owned; this method adds
## only validated ROM menu packets and removes the old command actor layer.
func present_pass_receiver_menu() -> bool:
	_clear_meeting_cursor()
	_clear_first_command_actor_presenter()
	_pass_receiver_menu_panel = PASS_RECEIVER_MENU_SCRIPT.new()
	if not _pass_receiver_menu_panel.rebuild():
		pass_receiver_menu_status = _pass_receiver_menu_panel.status.duplicate(true)
		presentation_gaps.append("PASS receiver menu ROM layout: " + _pass_receiver_menu_panel.error_message)
		return false
	_ppu_memory = _pass_receiver_menu_panel.apply_to_ppu_memory(_ppu_memory)
	if not bool(_pass_receiver_menu_panel.status.get("ok", false)):
		pass_receiver_menu_status = _pass_receiver_menu_panel.status.duplicate(true)
		presentation_gaps.append("PASS receiver menu packet application failed: " + _pass_receiver_menu_panel.error_message)
		return false
	action_menu_complete = false
	action_menu_missing_dynamic.clear()
	_action_menu_panel = null
	screen.set_ppu_memory(_ppu_memory)
	pass_receiver_menu_status = _pass_receiver_menu_panel.status.duplicate(true)
	pass_receiver_menu_status["state"] = "presented"
	visible = true
	screen.visible = true
	_display_enabled = true
	return true


## Add the endpoint's held ROM actor pose only after the route supplies the
## mutable `$0517/$0538/$0540/$0541` values from decoded gameplay state. The
## active background's universal palette color is read from its ROM profile;
## endpoint RAM/PPU values are never accepted here.
func present_first_command_actor_pose(player_state: FirstActionMenuMatchPlayerState,
		source_context: Dictionary) -> bool:
	first_command_actor_status = {"ok": false, "state": "invalid_source_context"}
	if player_state == null:
		return _actor_pose_failure("A live ROM-derived player state is required for actor graphics/palette selection.")
	if str(source_context.get("kind", "")) != "caller_owned_decoded_game_logic" \
			or str(source_context.get("label", "")).is_empty():
		return _actor_pose_failure("Actor state must come from named decoded game logic, not an endpoint capture.")
	var player_id := player_state.player_id
	if player_id < 0 or player_id > 0x22:
		return _actor_pose_failure("The active ROM player ID is outside the normal-player palette table.")
	# The verified target route's holder is player $08. ROM `$8282` returns the
	# same palette index for ordinary IDs $02-$0E. Special/alternate selectors
	# are deliberately rejected until their live `$002A` input is available.
	if player_id < 0x02 or player_id > 0x0E:
		return _actor_pose_failure("The ROM palette selector's special-player branches need additional source state.")
	var required_byte_fields := ["mirror_mode", "scroll_x", "clip_y_min", "clip_y_max"]
	for field_name in required_byte_fields:
		if not source_context.has(field_name):
			return _actor_pose_failure("Decoded actor source context omits %s." % field_name)
		var raw_field_value: Variant = source_context[field_name]
		if typeof(raw_field_value) != TYPE_INT:
			return _actor_pose_failure("Decoded actor source field %s must be an integer ROM byte." % field_name)
		var field_value := int(raw_field_value)
		if field_value < 0 or field_value > 0xFF:
			return _actor_pose_failure("Decoded actor source field %s does not fit a ROM byte." % field_name)
	var background_palette := screen.get_background_palette_bytes()
	if background_palette.size() != 16:
		return _actor_pose_failure("The active ROM background palette is unavailable for universal sprite color.")
	_clear_first_command_actor_presenter()
	_first_command_actor_presenter = FIRST_COMMAND_ACTOR_SCRIPT.new() as FirstCommandActorSourcePresenter
	_first_command_actor_presenter.name = "FirstCommandRomActorPose"
	sprite_layer.add_child(_first_command_actor_presenter)
	if not _first_command_actor_presenter.configure_endpoint_pose(
			player_id,
			player_id,
			int(source_context["mirror_mode"]),
			int(background_palette[0]),
			int(source_context["scroll_x"]),
			int(source_context["clip_y_min"]),
			int(source_context["clip_y_max"])):
		var presenter_error := _first_command_actor_presenter.last_error
		_clear_first_command_actor_presenter()
		return _actor_pose_failure("ROM actor pose: " + presenter_error)
	first_command_actor_status = {
		"ok": true,
		"state": "rom_source_endpoint_pose",
		"player_id": player_id,
		"palette_record_index": player_id,
		"mirror_mode": int(source_context["mirror_mode"]),
		"scroll_x": int(source_context["scroll_x"]),
		"clip_y_min": int(source_context["clip_y_min"]),
		"clip_y_max": int(source_context["clip_y_max"]),
		"sprite_count": int(_first_command_actor_presenter.last_build_result.get("sprites_written", 0)),
		"source_state": _first_command_actor_presenter.source_state_summary(),
		"source_context": source_context.duplicate(true),
	}
	return true


func _actor_pose_failure(message: String) -> bool:
	first_command_actor_status["error"] = message
	if not presentation_gaps.has(message):
		presentation_gaps.append(message)
	return false


func _clear_first_command_actor_presenter() -> void:
	if is_instance_valid(_first_command_actor_presenter):
		sprite_layer.remove_child(_first_command_actor_presenter)
		_first_command_actor_presenter.free()
	_first_command_actor_presenter = null


## Apply the source menu's selected-action label overlay. The caller owns the
## `$061F` 13-iteration cadence and bit-6 phase; this presenter only builds
## ROM-derived `$04A5`-shape packets.
func set_first_action_menu_selection(action_id: int, blink_visible: bool) -> bool:
	if _action_menu_panel == null or not action_menu_complete:
		return false
	_action_menu_panel.set_action_selection(action_id, blink_visible)
	_ppu_memory = _action_menu_panel.apply_to_ppu_memory(_ppu_memory)
	screen.set_ppu_memory(_ppu_memory)
	return true


## Present the ROM-derived field candidate at the fresh-match command endpoint.
## The candidate contains BG01 row/block output plus the decoded $70/$56 block
## and palette/CHR selectors. Map/raster gaps remain; actor descriptor/OAM
## parsing exists, but route-time actor state is not yet supplied here.
func present_first_match_field_candidate(field_source_context: Dictionary = {},
		descriptor_01_source_context: Dictionary = {}) -> bool:
	var field_presenter = FIRST_MATCH_FIELD_SCRIPT.new()
	if not field_presenter.build_and_apply(screen, field_source_context,
			descriptor_01_source_context):
		first_match_field_status = {"ok": false, "error": str(field_presenter.last_error)}
		return false
	_ppu_memory = field_presenter.ppu_memory.duplicate()
	# The new field profile loads its own ROM palette. Palette writes collected
	# before this profile switch belong to the opening/meeting scene and must not
	# overwrite the field palette after the profile has reset the renderer.
	_source_ppu_background_palette_overlay.clear()
	for address_variant in _source_ppu_nametable_overlay:
		_ppu_memory[int(address_variant)] = int(_source_ppu_nametable_overlay[address_variant])
	screen.set_ppu_memory(_ppu_memory)
	active_background_id = 0x01
	active_background_data_root = "res://reference/rom_extract/intro"
	first_match_field_status = field_presenter.status.duplicate(true)
	for gap in first_match_field_status.get("gaps", []):
		var gap_text := str(gap)
		if not presentation_gaps.has(gap_text):
			presentation_gaps.append(gap_text)
	_display_enabled = true
	visible = true
	screen.visible = true
	return true


func _on_presenter_event(event: Dictionary) -> void:
	var kind := str(event.get("kind", ""))
	match kind:
		"background_1":
			if not _source_background_tasks_managed:
				_set_background(int(event.get("id", -1)), true)
		"background_2":
			# The second ROM background is a secondary draw layer. Preserve the
			# primary CHR profile while applying its ROM packet stream on top.
			if not _source_background_tasks_managed:
				_set_background(int(event.get("id", -1)), false)
		"animations":
			_replace_animations(event.get("animation_ids", []))
		"screen_on":
			_display_enabled = true
			visible = true
			screen.visible = true
		"screen_off_clear":
			# EA fades its current ROM palettes before the nametable clear ends.
			# The completion signal performs the clear after the final committed step.
			pass
		"text_cursor_back":
			text_cursor_column -= int(event.get("tile_count", 0))
		"text_base_ppu_address":
			var arguments: Array = event.get("arguments", [])
			if arguments.size() == 2:
				text_cursor_base = int(arguments[0]) | (int(arguments[1]) << 8)
				text_cursor_column = 0
		"clear_text":
			_clear_text_window()
		"palette_command":
			var arguments: Array = event.get("arguments", [])
			if int(event.get("opcode", -1)) == 0xF3 and arguments.size() == 1 \
					and int(arguments[0]) == 0x00:
				_on_screen_fade_palette_step_requested(event, 0x0F)
			else:
				presentation_gaps.append("Unresolved palette command at %s." % str(event.get("cpu_address", "?")))
		"text_brightness_command", "visual_preset", "visual_flag", "toggle_camera":
			# These commands are forwarded for a later renderer extension. The ROM
			# operands remain in the event manifest; no guessed visual effect is
			# added here.
			presentation_gaps.append("%s at %s" % [kind, str(event.get("cpu_address", "?"))])
		"jump", "dialog_window", "exit", "compact_pause", "fc_handler", "pause_frames", "sound_command", "text_speed", "text_tile_ids", "wait_for_input":
			pass
		_:
			presentation_gaps.append("unknown event %s at %s" % [kind, str(event.get("cpu_address", "?"))])


func _on_wait_completed(wait_kind: String, event: Dictionary) -> void:
	if wait_kind == "fc_handler":
		# Local ROM $8837 handler yields four scheduler ticks, increments the
		# little-endian text base by $0040, then re-enters $84E3 and seeds the
		# glyph cursor from that new base.
		text_cursor_base = (text_cursor_base + 0x40) & 0xFFFF
		text_cursor_column = 0
	elif wait_kind == "text_speed":
		pass
	else:
		pass


func _on_screen_fade_palette_step_requested(event: Dictionary, level: int) -> void:
	var opcode := int(event.get("opcode", -1))
	var fade_arguments: Array = event.get("arguments", [])
	var is_f3_rebuild: bool = opcode == 0xF3 \
		and str(event.get("kind", "")) == "palette_command" \
		and fade_arguments.size() == 1 and int(fade_arguments[0]) == 0
	if (opcode != 0xE9 and opcode != 0xEA and not is_f3_rebuild) \
			or level < 0 or level > 0x0F:
		presentation_gaps.append("Rejected a palette step without a supported ROM event and level.")
		return
	var event_index := int(event.get("event_index", -1))
	if event_index != _fade_base_event_index:
		_fade_base_event_index = event_index
		_fade_base_background_palette = _load_active_rom_background_palette()
		if _fade_base_background_palette.size() != 16:
			_fade_base_background_palette = screen.get_source_background_palette_bytes()
		_fade_base_sprite_palettes.clear()
		for animation_node in _animations:
			if not is_instance_valid(animation_node):
				continue
			var palette: PackedByteArray = animation_node.get_gameplay_source_palette_bytes()
			if palette.size() != 16:
				presentation_gaps.append("%s at %s lacks a ROM-derived palette row for %s." % [_fade_source_name(opcode), str(event.get("cpu_address", "?")), animation_node.name])
				continue
			_fade_base_sprite_palettes.append({"node": animation_node, "palette": palette})
	if _fade_base_background_palette.size() != 16:
		presentation_gaps.append("%s at %s has no active ROM background palette." % [_fade_source_name(opcode), str(event.get("cpu_address", "?"))])
		return
	var background_input := _fade_base_background_palette.duplicate()
	background_input.append_array(_fade_base_background_palette)
	var background_faded := FADE_MODEL.build_palette(background_input, level, level).slice(0, 16)
	var sprite_commits: Array[Dictionary] = []
	for palette_entry in _fade_base_sprite_palettes:
		var sprite_input := _fade_base_background_palette.duplicate()
		sprite_input.append_array(palette_entry["palette"])
		var faded := FADE_MODEL.build_palette(sprite_input, level, level)
		sprite_commits.append({"node": palette_entry["node"], "palette": faded.slice(16, 32)})
	_pending_fade_palette_commit = {
		"background_palette": background_faded,
		"sprite_palettes": sprite_commits,
		"event_index": event_index,
		"source_cpu_address": int(event.get("cpu_address", -1)),
		"level": level,
	}
	if not _fade_timing_gap_reported:
		presentation_gaps.append("E9/EA/F3 palette packets commit on the next modeled source tick; exact NMI/PPU phase remains unresolved.")
		_fade_timing_gap_reported = true


func _fade_source_name(opcode: int) -> String:
	match opcode:
		0xE9:
			return "E9"
		0xEA:
			return "EA"
		0xF3:
			return "F3 $00"
	return "palette command"


## Return the active ROM-derived background and sprite palette captured by the
## last E9/EA event. The $99F0 helper operates on this 32-byte source buffer.
func get_cleanup_fade_base_palette_bytes() -> PackedByteArray:
	if _fade_base_background_palette.size() != 16:
		return PackedByteArray()
	if screen.get_source_background_palette_bytes() != _fade_base_background_palette:
		return PackedByteArray()
	if _fade_base_sprite_palettes.is_empty():
		return PackedByteArray()
	var selected_sprite_palette := PackedByteArray()
	for entry in _fade_base_sprite_palettes:
		var palette: PackedByteArray = entry.get("palette", PackedByteArray())
		if palette.size() != 16:
			return PackedByteArray()
		if selected_sprite_palette.is_empty():
			selected_sprite_palette = palette.duplicate()
		elif selected_sprite_palette != palette:
			# $063A-$0649 contains one active 16-byte sprite-palette group. Do not
			# guess how several different animation palettes share that group.
			return PackedByteArray()
	var base_palette := _fade_base_background_palette.duplicate()
	base_palette.append_array(selected_sprite_palette)
	return base_palette


## Queue a ROM-built $05E8 palette packet for the next modeled source tick,
## matching the trace's frame-end PPU packet lag without claiming NMI bus phase.
func queue_rom_cleanup_fade_palette_packet(packet: PackedByteArray) -> bool:
	if packet.size() != 0x23 or packet[0] != 0x20 or packet[1] != 0x00 or packet[2] != 0x3F:
		presentation_gaps.append("Rejected a cleanup fade packet without a valid $05E8/$3F00 header.")
		return false
	if _fade_base_background_palette.size() != 16 or _fade_base_sprite_palettes.is_empty():
		presentation_gaps.append("Cleanup fade packet has no active ROM-derived background/sprite palette consumer.")
		return false
	var sprite_bytes := packet.slice(0x13, 0x23)
	var sprite_commits: Array[Dictionary] = []
	for entry in _fade_base_sprite_palettes:
		var animation_node: Variant = entry.get("node")
		if not is_instance_valid(animation_node):
			presentation_gaps.append("Cleanup fade packet references an expired sprite palette consumer.")
			return false
		sprite_commits.append({"node": animation_node, "palette": sprite_bytes.duplicate()})
	_pending_fade_palette_commit = {
		"background_palette": packet.slice(0x03, 0x13),
		"sprite_palettes": sprite_commits,
		"event_index": _fade_base_event_index,
		"source_cpu_address": 0x99F0,
		"level": -1,
	}
	return true


func _commit_pending_fade_palette() -> void:
	if _pending_fade_palette_commit.is_empty():
		return
	var background_palette: PackedByteArray = _pending_fade_palette_commit["background_palette"]
	screen.set_background_palette_bytes(background_palette)
	for sprite_entry in _pending_fade_palette_commit["sprite_palettes"]:
		var animation_node: Variant = sprite_entry.get("node")
		if is_instance_valid(animation_node):
			animation_node.set_fade_palette_bytes(sprite_entry["palette"])
	_pending_fade_palette_commit.clear()


func _on_screen_off_clear_completed(_event: Dictionary) -> void:
	var zero_fill_addresses: PackedInt32Array = FADE_MODEL.confirmed_ea_zero_fill_addresses()
	for address in zero_fill_addresses:
		_ppu_memory[int(address)] = 0
	screen.set_ppu_memory(_ppu_memory)
	_display_enabled = false
	visible = false
	screen.visible = false
	_clear_animations()


## Apply the source $98A0/$9B7F presentation effects after the cleanup fade:
## clear all four nametables/attribute tables and hide every active OAM actor.
## The source register-write history is applied separately; scanline gating
## and sub-frame PPU timing are not represented by this renderer.
func apply_rom_cutscene_cleanup_clear() -> bool:
	if not is_instance_valid(screen):
		return false
	_pending_fade_palette_commit.clear()
	_pending_glyph_writes.clear()
	for address in range(0x2000, 0x2800):
		_ppu_memory[address] = 0
	screen.set_ppu_memory(_ppu_memory)
	var black_palette := PackedByteArray()
	for _index in range(16):
		black_palette.append(0x0F)
	screen.set_background_palette_bytes(black_palette)
	_clear_animations()
	return true


func apply_source_ppu_register_writes(events: Array) -> bool:
	var updated_ctrl := _source_ppuctrl_shadow
	var updated_mask := _source_ppumask_shadow
	var accepted: Array[Dictionary] = []
	for event_variant in events:
		if not event_variant is Dictionary:
			return false
		var event: Dictionary = event_variant
		var register := int(event.get("ppu_register", -1))
		var value := int(event.get("value", -1))
		if value < 0 or value > 0xFF or register not in [0x2000, 0x2001]:
			return false
		if register == 0x2000:
			updated_ctrl = value
		else:
			updated_mask = value
		accepted.append(event.duplicate(true))
	_source_ppuctrl_shadow = updated_ctrl
	_source_ppumask_shadow = updated_mask
	_source_ppu_register_history.append_array(accepted)
	return true


func apply_rom_dispatch_attribute_tail_seed(ppu_address: int, value: int, byte_count: int) -> bool:
	if not is_instance_valid(screen) or ppu_address < 0x2000 \
			or ppu_address + byte_count > NAMETABLE_END or byte_count <= 0 \
			or value < 0 or value > 0xFF:
		return false
	for address in range(ppu_address, ppu_address + byte_count):
		_ppu_memory[address] = value
	screen.set_ppu_memory(_ppu_memory)
	return true


func _on_text_glyph_requested(tile_id: int, _source_cpu: int, _event_index: int, _glyph_index: int) -> void:
	var address := text_cursor_base + text_cursor_column
	if address < 0x2000 or address + 0x20 >= NAMETABLE_END:
		presentation_gaps.append("glyph cursor outside modeled nametable: $%04X" % address)
		return
	_pending_glyph_writes.append({"address": address, "value": 0x00})
	_pending_glyph_writes.append({"address": address + 0x20, "value": tile_id & 0xFF})
	_shared_ppu_queue_cursor_0628 += TEXT_GLYPH_QUEUE_RECORD_BYTES # `$88CA` three-byte header plus two payload bytes.
	text_cursor_column += 1


func _commit_pending_glyph_writes() -> void:
	if _pending_glyph_writes.is_empty():
		return
	for write in _pending_glyph_writes:
		_ppu_memory[int(write["address"])] = int(write["value"])
	_pending_glyph_writes.clear()
	screen.set_ppu_memory(_ppu_memory)


func _commit_pending_source_zero_fill_rows() -> void:
	if _pending_source_zero_fill_rows.is_empty():
		return
	for row_variant in _pending_source_zero_fill_rows:
		var row: Dictionary = row_variant
		var address := int(row["ppu_address"])
		for byte_index in int(row["payload_size"]):
			_ppu_memory[address + byte_index] = 0
		_source_zero_fill_batch_history.append({
			"committed_row_index": int(row["row_index"]),
			"ppu_address": address,
			"byte_count": int(row["payload_size"]),
			"source_pc": int(row["source_pc"]),
		})
	_pending_source_zero_fill_rows.clear()
	screen.set_ppu_memory(_ppu_memory)


func _set_background(background_id: int, replace_primary: bool) -> void:
	if background_id < 0 or background_id > 0xFF:
		presentation_gaps.append("invalid background id %d" % background_id)
		return
	var data_root := INTRO_DATA_ROOT if FileAccess.file_exists(
		INTRO_DATA_ROOT + "/background_%02X_layout.json" % background_id) else GAMEPLAY_DATA_ROOT
	if not FileAccess.file_exists(data_root + "/background_%02X_layout.json" % background_id):
		presentation_gaps.append("no ROM-derived layout for background $%02X" % background_id)
		return
	_active_palette_background_id = background_id
	_active_palette_background_data_root = data_root
	if replace_primary:
		active_background_id = background_id
		active_background_data_root = data_root
		_ppu_memory.clear()
		text_cursor_base = TEXT_CURSOR_START
		text_cursor_column = 0
		if not screen.set_background_profile(background_id, PackedByteArray(), data_root):
			presentation_gaps.append("renderer rejected background $%02X" % background_id)
			return
		if not _apply_kickoff_story_chr_raster(background_id):
			presentation_gaps.append("renderer rejected the ROM-derived CHR raster for background $%02X" % background_id)
			return
	var loader: RomBackgroundPacketLoader = BACKGROUND_PACKET_LOADER.new()
	if not loader.build_packets(background_id, data_root):
		presentation_gaps.append("packet builder rejected background $%02X: %s" % [background_id, loader.last_error])
		return
	for packet in loader.packets:
		var address := int(packet.get("ppu_address", -1))
		var payload: PackedByteArray = packet.get("payload", PackedByteArray())
		if address < 0:
			continue
		for byte_index in payload.size():
			_ppu_memory[address + byte_index] = int(payload[byte_index])
	screen.set_ppu_memory(_ppu_memory)


func _replace_animations(ids_variant: Variant) -> void:
	_clear_animations()
	_meeting_speaker = null
	if not ids_variant is Array:
		presentation_gaps.append("animation ID list is malformed")
		return
	var ids: Array = ids_variant
	# Reverse creation order so the earlier ROM FB entry draws in front, as in
	# the NES OAM list. Source animation timing remains a separate scheduler.
	for animation_index in range(ids.size() - 1, -1, -1):
		var animation_id := int(ids[animation_index])
		var animation_node: RomSpriteAnimationPrototype = SPRITE_SCRIPT.new()
		animation_node.name = "KickoffAnimation_%02X_%d" % [animation_id, animation_index]
		animation_node.animation_id = "0x%02X" % animation_id
		animation_node.timing_resource_path = GAMEPLAY_ANIMATION_TIMING
		animation_node.frame_resource_path = GAMEPLAY_SPRITE_FRAMES
		animation_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite_layer.add_child(animation_node)
		if animation_id == 0x3B:
			_meeting_speaker = animation_node
			if not animation_node.set_rom_state_branch(0):
				presentation_gaps.append("scene $44 animation $3B lacks decoded ROM $FA branch poses")
			presentation_gaps.append("scene $44 speaker branch cadence from $0099 remains untraced")
		animation_node.reset_source_timeline()
		_animations.append(animation_node)


func _clear_animations() -> void:
	_meeting_speaker = null
	for animation_node in _animations:
		if is_instance_valid(animation_node):
			sprite_layer.remove_child(animation_node)
			animation_node.queue_free()
	_animations.clear()


func _clear_meeting_cursor() -> void:
	if is_instance_valid(_meeting_cursor):
		sprite_layer.remove_child(_meeting_cursor)
		_meeting_cursor.queue_free()
	_meeting_cursor = null


func _clear_text_window() -> void:
	# FD's clear origin/width comes from its separate ROM state helper; the
	# command manifest preserves opcode order but not that RAM state. Clear the
	# currently modeled text band and reset to the verified first-line origin.
	for row in range(0, 10):
		for column in range(0, 32):
			var address := TEXT_CURSOR_START + row * 0x20 + column
			_ppu_memory[address] = 0
	text_cursor_base = TEXT_CURSOR_START
	text_cursor_column = 0
	screen.set_ppu_memory(_ppu_memory)


func _parse_source_address(value: String) -> int:
	var normalized := value.strip_edges().trim_prefix("$").trim_prefix("0x").trim_prefix("0X")
	return normalized.hex_to_int() if not normalized.is_empty() else -1


func _bytes_from_hex(value: String) -> PackedByteArray:
	var normalized := value.strip_edges().replace(" ", "").replace("_", "")
	if normalized.is_empty() or normalized.length() % 2 != 0:
		return PackedByteArray()
	var result := PackedByteArray()
	for index in range(0, normalized.length(), 2):
		var byte_text := normalized.substr(index, 2)
		if not byte_text.is_valid_hex_number(false):
			return PackedByteArray()
		result.append(byte_text.hex_to_int())
	return result
