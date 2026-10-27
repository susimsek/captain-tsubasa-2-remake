extends Node2D
class_name ColdStartSourceCommandPresenter
## Isolated cold-start command slice driven by cutscene bytes and a cooperative
## scheduler model. It models source-backed commands across extracted F9/FA
## backgrounds, F3 palettes and the EC stream; it is not a complete NES VM.

signal source_command_applied(event: Dictionary, state_snapshot: Dictionary)
signal rom_sound_requested(sound_id: int, source_frame: int)
# Frame-level model of the ROM's `$9FA8` wait followed by its `$001E & $10`
# Start poll. The exact instruction's variable CPU-cycle position is not modeled.
signal source_start_poll_completed(source_frame: int)

const NES_FPS := 60.0988
const SCRIPT_PATH := "res://reference/rom_extract/intro/cutscene_00.bin"
const SCRIPT_START_FILE_OFFSET := 0x6030
const SCRIPT_START_CPU_ADDRESS := 0xA020
const SCRIPT_LENGTH_BYTES := 641
const SCRIPT_SHA256 := "499ccb62b8b2b9118d7ebfaa6e6b9fce46806cd3b9173b5e1d5d61de21c2a6b7"
const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const COLD_START_BOOTSTRAP_PHASE_PATH := "res://assets/opening/rom_logic/cold_start_bootstrap_phase.json"
const F8_HELPER_RETURN_EVENT_PATH := "res://assets/opening/rom_logic/f8_helper_return_event.json"
const NES_RGB_PALETTE_PATH := "res://reference/palettes/FCEUX_internal_default_2.7.0_rgb.pal"
const BASE_BACKGROUND_PALETTE_PATH := "res://reference/rom_extract/intro/background_palette_01.bin"
const BASE_SPRITE_PALETTE_PATH := "res://reference/rom_extract/intro/animation_8D_sprite_palette.bin"
const F3_SPRITE_PALETTE_TABLE_PATH := "res://reference/rom_extract/intro/sprite_palette_table_00_08.bin"
const F3_SPRITE_PALETTE_TABLE_METADATA_PATH := "res://reference/rom_extract/intro/sprite_palette_table_00_08.json"
const F3_ANIMATION_PALETTE_HEADERS_PATH := "res://reference/rom_extract/intro/animation_palette_headers.json"
const FADE_MODEL := preload("res://scripts/opening/prototypes/ea_fade/ea_palette_fade_reference.gd")
const SCHEDULER_MODEL := preload("res://scripts/opening/rom_cooperative_scheduler.gd")
const EC_STREAM_PLAYER := preload("res://scripts/opening/rom_ec_stream_player.gd")
const BACKGROUND_01_LOADER := preload("res://scripts/opening/rom_background_01_loader.gd")
const BACKGROUND_PACKET_LOADER := preload("res://scripts/opening/rom_background_packet_loader.gd")
const F1_GRAPHICS_LOADER := preload("res://scripts/opening/rom_f1_graphics_packet_loader.gd")
const SPRITE_ANIMATION_SCRIPT := preload("res://scripts/opening/rom_sprite_animation_prototype.gd")
const BG08_SPRITE_OAM_COMPOSER_SCRIPT := preload("res://scripts/opening/rom_bg08_sprite_oam_composer.gd")
const RUNNER_MOTION_RECORD_SCRIPT := preload("res://scripts/opening/rom_runner_motion_record.gd")
const RASTER_EVENT_GENERATOR_SCRIPT := preload("res://scripts/opening/rom_raster_event_generator.gd")
const SOURCE_PPU_WRITE_TIMELINE_SCRIPT := preload("res://scripts/opening/rom_source_ppu_write_timeline.gd")
const BG08_RASTER_MODEL_SCRIPT := preload("res://scripts/opening/rom_bg08_raster_model.gd")
const BG0A_RASTER_MODEL_SCRIPT := preload("res://scripts/opening/rom_bg0a_raster_model.gd")
const BACKGROUND_CAMERA_WORKER_SCRIPT := preload("res://scripts/opening/rom_background_camera_worker.gd")
const BG0B_CAMERA_VISIBLE_PHASE_TRACE := "reference/rom_extract/intro/bg0b_camera_oam_trace_20261025.md"
const F8_TITLE_IRQ_TIMING_MODEL := preload("res://scripts/opening/f8_title_irq_timing_model.gd")
const BG09_PALETTE_EFFECT_SCRIPT := preload("res://scripts/opening/rom_bg09_palette_effect_model.gd")
const RUNNER_PALETTE_EFFECT_SCRIPT := preload("res://scripts/opening/rom_f5_00_palette_effect_model.gd")
const RUNNER_SOURCE_START_FRAME := 378
const SPRITE_FETCH_PLANE1_FIRST_DOT := 262
const SPRITE_FETCH_SLOT_DOT_STRIDE := 8
const F8_TITLE_BACKGROUND_ID := 0x17
const F8_TITLE_PRECLEAR_ROW_COUNT := 16
const F8_TITLE_RECORD_CAPACITY_YIELDS := 26
const F8_TITLE_RECORD_PACKETS_PER_BATCH := 9
const F8_TITLE_PRESET_3_RAM_0079 := 0x04
const F8_TITLE_PRESET_3_RAM_007C := 0x68
const F8_TITLE_PRESET_3_RAM_007F := 0x80
const F8_TITLE_PRESET_3_RAM_0080 := 0xC0
const F8_TITLE_PRESET_3_RAM_0081 := 0x21
const STARTUP_ATTRIBUTE_TAIL_SOURCE_FILE := "res://reference/rom_extract/intro/startup_dispatch_attribute_tail_seed.bin"
const STARTUP_ATTRIBUTE_TAIL_SOURCE_SHA256 := "266560cc1d52cf2152f982b21742c84c1420c64f5871a90ab78b597c58b27170"
const STARTUP_ATTRIBUTE_TAIL_SOURCE_BYTES: Array[int] = [
	0xA9, 0xE0, 0x85, 0xE6, 0xA9, 0x23, 0x85, 0xE7, 0xA0,
	0x01, 0xA2, 0x20, 0xA9, 0x55, 0x20, 0xEA, 0x98,
]
const STARTUP_ATTRIBUTE_TAIL_PPU_ADDRESS := 0x23E0
const STARTUP_ATTRIBUTE_TAIL_SIZE := 0x20
const STARTUP_ATTRIBUTE_TAIL_VALUE := 0x55
const OAM_DISPLAY_LATCH_SOURCE_FRAMES := 1
const CUTSCENE_TASK_SLOT := 5
const F9_BACKGROUND_00_ID := 0x00
const F9_BACKGROUND_01_ID := 0x01
const BG07_BACKGROUND_ID := 0x07
const F9_PPU_QUEUE_CURSOR_LIMIT := 0x3D
const F9_OBSERVED_PPU_BUFFER_INDEX := 0x39
const F9_OBSERVED_PPU_RESERVATION_SIZE := 0x04
const F9_PPU_BUFFER_CAPACITY_LIMIT := 0x3D
const F1_OPENING_GRAPHICS_POINTER := 0xBB9A
const EC_STREAM_BASE_BY_POINTER_TABLE_INDEX: Dictionary = {
	0: 0xBD0C,
	2: 0xBD24,
	4: 0xBD41,
	5: 0xBD4E,
}
## The first twelve script bytes are pinned as the verified cold-start prefix.
## The source-backed continuation models `$DC`, the ROM-gated `$F1 01` path,
## four EC streams, and ROM background loaders. Unsupported occurrences
## still fail closed rather than borrowing an unrelated timing anchor.
const REQUIRED_SCRIPT_PREFIX: Array[int] = [
	0xE8, 0x01, 0xF9, 0x00, 0xFB, 0x01, 0x8D, 0xE9, 0xDF, 0xEA, 0xED, 0x58,
]

## ROM bank-0 compact wait table at file offset $0AF6, verified in the local
## ROM as [1, 10, 20, 40, 60, 80, 120, 240] scheduler delay decrements.
const COMPACT_PAUSE_VALUES: Array[int] = [1, 10, 20, 40, 60, 80, 120, 240]

## Verified handler entries for the small supported command prefix.
const HANDLER_ENTRY_BY_OPCODE: Dictionary = {
	0xE8: "$8575",
	0xF9: "$8814",
	0xFA: "$881B",
	0xFB: "$8831",
	0xE9: "$8580",
	0xDF: "$8508",
	0xEA: "$858D",
	0xED: "$85EC",
	0xEC: "$85D2",
	0xEE: "$8604",
	0xF2: "$8678",
	0xF3: "$8682",
	0xF4: "$86B8",
	0xF8: "$87F8",
	0xF1: "$864A",
	0xF5: "$87B8",
	0xFD: "$8855",
	0xFE: "$8862",
}

@onready var background: RomBackground00Renderer = $Background
var state: Dictionary = {}
var _scheduler: RomCooperativeScheduler
var _script_bytes := PackedByteArray()
var _script_cursor := 0
var _command_sequence := 0
var _pending_command: Dictionary = {}
var _pending_handler := ""
var _pending_handler_phase := ""
var _frame_accumulator := 0.0
var _startup_phase: Dictionary = {}
var _f8_helper_return_event: Dictionary = {}
var _first_literal_scheduler_scan_source_frame := -1
var _worker_ready_install_source_frame := -1
var _first_ready_worker_scan_source_frame := -1
var _first_nmi_release_source_frame := -1
var _initial_black_palette_commit_source_frame := -1
var _startup_worker_slot_registered := false
var _base_palette := PackedByteArray()
var _staged_palette := PackedByteArray()
var _committed_palette := PackedByteArray()
var _nes_rgb_palette := PackedByteArray()
var _fade_running := false
var _fade_started_source_frame := -1
var _fade_staged_source_frame := -1
var _staged_palette_commit_not_before_source_frame := -1
var _palette_commit_source_frame := -1
var _fade_up_running := false
var _fade_up_level := 0
var _cutscene_task_stopped := false
var _f9_background_01_loader
var _f9_background_01_packet_index := 0
var _background_01_queue_packets: Array[Dictionary] = []
var _background_01_queue_cursor := 0
var _background_01_ppu_memory: Dictionary = {}
var _background_01_committed_packets := 0
var _background_01_committed_writes := 0
var _background_01_queued_packets := 0
var _generic_background_loader
var _generic_background_packet_index := 0
var _generic_background_committed_packets := 0
var _generic_background_committed_writes := 0
var _f1_graphics_loader
var _f1_graphics_pending_packets: Array[Dictionary] = []
var _f1_graphics_packet_index := 0
var _f1_graphics_committed_packets := 0
var _f1_graphics_committed_writes := 0
var _fd_clear_pending_rows: Array[Dictionary] = []
var _fd_clear_next_row := 0
var _fd_clear_committed_rows := 0
var _fd_clear_committed_writes := 0
var _fd_clear_active := false
var _f8_title_loader_packets: Array[Dictionary] = []
var _f8_title_loader_packet_index := 0
var _f8_title_loader_batch_index := 0
var _f8_title_loader_capacity_yields := 0
var _f8_title_preclear_rows_staged := 0
var _f8_title_record_capacity_yields := 0
var _f8_title_oam_shift_count := 0
var _f8_title_motion_step := 0
var _f8_palette_fade_step := 0
var _ec_stream_player
var _staged_text_glyph_writes: Array[Dictionary] = []
var _runner_animation_started := false
var _runner_motion_record: RomRunnerMotionRecord
var _a2_animation_started := false
var _a2_motion_record: RomRunnerMotionRecord
var _7d_animation_started := false
var _7d_motion_record: RomRunnerMotionRecord
var _raster_event_generator
var _source_ppu_write_timeline: RomSourcePpuWriteTimeline
var _bg08_raster_model
var _bg0a_raster_model
var _bg0b_camera_model
var _bg07_camera_model
var _bg03_camera_model
var _bg0b_sprite_x_motion_offset := 0
var _bg0b_sprite_last_motion_source_frame := -1
var _bg0b_sprite_motion_set_start_source_frame := -1
var _f5_palette_effect_model
var _f5_palette_pending_update: Dictionary = {}
var _animation_nodes: Array[RomSpriteAnimationPrototype] = []
var _latched_animation_nodes: Array[RomSpriteAnimationPrototype] = []
var _oam_scanline_evaluation_revision := 0
var _bg08_sprite_oam_composer: RomBg08SpriteOamComposer
var _latched_bg08_sprite_oam_composers: Array[RomBg08SpriteOamComposer] = []
var _latched_animation_nodes_release_frame := -1
var _rendered_animation_generation := -1
var _animation_set_start_source_frame := -1
var _animation_last_source_frame := -1
var _capture_render_updates_suppressed := false

@onready var field_screen: RomPpuNametableScreenRenderer = $FieldScreen
@onready var power_on_backdrop: ColorRect = $PowerOnBackdrop


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	queue_redraw()
	if not _load_rom_script():
		set_process(false)
		return
	if not _load_startup_phase():
		set_process(false)
		return
	if not _load_f8_helper_return_event():
		set_process(false)
		return
	_source_ppu_write_timeline = SOURCE_PPU_WRITE_TIMELINE_SCRIPT.new()
	var use_ce6_diagnostic_candidate := OS.get_cmdline_user_args().has(
		"--a160-ce6-candidate-diagnostics")
	if not _source_ppu_write_timeline.configure(use_ce6_diagnostic_candidate):
		push_error("Could not load ROM-derived subframe PPU timeline: " + _source_ppu_write_timeline.last_error)
		set_process(false)
		return
	_nes_rgb_palette = FileAccess.get_file_as_bytes(NES_RGB_PALETTE_PATH)
	if _nes_rgb_palette.size() != 192:
		push_error("The external NES RGB palette is missing or has an unexpected size.")
		set_process(false)
		return
	_base_palette = FileAccess.get_file_as_bytes(BASE_BACKGROUND_PALETTE_PATH)
	_base_palette.append_array(FileAccess.get_file_as_bytes(BASE_SPRITE_PALETTE_PATH))
	if _base_palette.size() != FADE_MODEL.PALETTE_SIZE:
		push_error("EA palette prototype requires the ROM-derived 16+16 source palette bytes.")
		set_process(false)
		return
	# The fade model begins at the ROM's all-$0F black level. Hardware palette
	# RAM is still all-$00 at power-on; the startup NMI commits the first black
	# packet at source frame 9, before E9's first nonblack packet at frame 13.
	_committed_palette = FADE_MODEL.build_palette(_base_palette, 0, 0)
	_scheduler = SCHEDULER_MODEL.new()
	state = {
		"source_frame": 0,
		"scheduler_tick": 0,
		"dispatch_count": 0,
		"cutscene_cpu_pointer": "$A020",
		"visual_preset": -1,
		"background_id": -1,
		"animation_ids": [],
		"oam_priority_behind_background": false,
		"oam_priority_display_latched": false,
		"oam_priority_display_source_frame": -1,
		"screen_enabled_command_seen": false,
		"fade_clear_started": false,
		"fade_counters": Vector2i(0x0F, 0x0F),
		"palette_staged_level": 0,
		"palette_committed_level": 0,
		"palette_commit_delay_frames": 1,
		"palette_commit_source_frame": -1,
		"fade_up_status": "waiting_for_E9",
		"background_profile_ready": false,
		"text_ppu_cursor_known": false,
		"text_ppu_cursor_base_address": -1,
		"text_ppu_cursor_column": 0,
		"text_ppu_cursor_address": -1,
		"field_palette_override_active": false,
		"field_palette_override_pending": false,
		"palette_frame_edge_status": "Source frame 13 shows the first logo pixel at output (79, 77); its PPU dot is not sampled.",
		"first_visible_source_frame": 13,
		"first_visible_output_pixel": Vector2i(79, 77),
		"first_visible_dot_measured": false,
		"ea_clear_applied": false,
		"ea_clear_display_edge_status": "Frame 282 is black from the first displayed scanline; exact transition dot is not sampled.",
		"rom_global_scroll_state_reset": {},
		"sound_requests": [],
		"compact_pause_current_release_credit": false,
		"first_ed58_dispatched": false,
		"script_loop_phase_origin_source_frame": -1,
		"script_loop_phase_origin_script_frame": _first_ready_worker_scan_source_frame,
		"background_01_queued_packets": 0,
		"background_01_committed_packets": 0,
		"background_01_committed_ppu_writes": 0,
		"stopped_before_unmodeled_command": false,
		"scheduler_bootstrap": "ROM-stepper startup events: first literal $9EED scan frame %d; slot $0005 ready install frame %d; first ready-worker scan frame %d; first NMI-ready release frame %d." % [
			_first_literal_scheduler_scan_source_frame,
			_worker_ready_install_source_frame,
			_first_ready_worker_scan_source_frame,
			_first_nmi_release_source_frame,
		],
		"first_literal_scheduler_scan_source_frame": _first_literal_scheduler_scan_source_frame,
		"worker_ready_install_source_frame": _worker_ready_install_source_frame,
		"first_ready_worker_scan_source_frame": _first_ready_worker_scan_source_frame,
		"first_nmi_release_source_frame": _first_nmi_release_source_frame,
		"startup_phase_resource_path": COLD_START_BOOTSTRAP_PHASE_PATH,
		"startup_phase_rom_events": _startup_phase.get("events", {}),
		"f8_helper_return_event_path": F8_HELPER_RETURN_EVENT_PATH,
		"f8_helper_return_source_events": _f8_helper_return_event.get("events", []),
		"source_ppu_write_timeline": _source_ppu_write_timeline.debug_snapshot(),
		"startup_dispatch_attribute_tail_seed_applied": false,
		"rom_sha256": SOURCE_ROM_SHA256,
	}
	_apply_visual_state()


func freeze_source_for_title_handoff() -> void:
	_cutscene_task_stopped = true
	set_process(false)


## Source clocks, command execution, OAM and PPU state continue to advance;
## expensive bitmap builds are deferred until the newest requested frame.
func set_render_updates_suppressed(suppressed: bool) -> void:
	_capture_render_updates_suppressed = suppressed
	for animation_node in _animation_nodes:
		if is_instance_valid(animation_node):
			animation_node.set_render_updates_suppressed(suppressed)
	for animation_node in _latched_animation_nodes:
		if is_instance_valid(animation_node):
			animation_node.set_render_updates_suppressed(suppressed)
	if _bg08_sprite_oam_composer != null and is_instance_valid(_bg08_sprite_oam_composer):
		_bg08_sprite_oam_composer.set_render_updates_suppressed(suppressed)
	for composer in _latched_bg08_sprite_oam_composers:
		if is_instance_valid(composer):
			composer.set_render_updates_suppressed(suppressed)


## Backwards-compatible entry point used by deterministic capture tools.
func set_capture_render_updates_suppressed(suppressed: bool) -> void:
	set_render_updates_suppressed(suppressed)


func _draw() -> void:
	# Draw the PPU's reset backdrop in the scene's 256x240 coordinate space.
	draw_rect(Rect2(Vector2.ZERO, Vector2(256.0, 240.0)), Color.BLACK)


func _process(delta: float) -> void:
	_frame_accumulator += delta
	var source_frame_duration := 1.0 / NES_FPS
	var source_frames_due := int(floor(_frame_accumulator / source_frame_duration))
	var defer_intermediate_rendering := source_frames_due > 1
	if defer_intermediate_rendering:
		# This Godot frame can display only the newest catch-up state. Keep
		# executing every ROM source frame, but avoid rebuilding images for
		# intermediate states that cannot be presented.
		set_render_updates_suppressed(true)
		field_screen.set_rendering_enabled(false)
	while _frame_accumulator >= source_frame_duration and not _cutscene_task_stopped:
		_frame_accumulator -= source_frame_duration
		_advance_source_frame()
	if defer_intermediate_rendering:
		set_render_updates_suppressed(false)
		field_screen.set_rendering_enabled(true)


func _advance_source_frame() -> void:
	# PPU state can be updated by several source tasks during one NES frame.
	# Defer the expensive full-screen rebuild until all frame-edge writes and
	# raster state have been applied; the displayed result is the same final PPU
	# state, without rendering intermediate states that are never presented.
	# The frame's OAM DMA occurs in the NMI before the cooperative cutscene task
	# runs. Preserve the priority state that existed before this frame's source
	# commands, just as animation OAM uses its preceding-frame display latch.
	state["oam_priority_display_latched"] = bool(
		state.get("oam_priority_behind_background", false))
	state["oam_priority_display_source_frame"] = int(state.get("source_frame", -1))
	field_screen.begin_state_update()
	_advance_source_frame_state()
	field_screen.end_state_update()
	var source_frame := int(state.get("source_frame", -1))
	if not _cutscene_task_stopped and source_frame >= _first_nmi_release_source_frame:
		source_start_poll_completed.emit(source_frame)


func _advance_source_frame_state() -> void:
	var source_frame := int(state["source_frame"]) + 1
	state["source_frame"] = source_frame
	if not _activate_pending_f8_background_profile(source_frame):
		return
	# The boot dispatcher at $8464 seeds the PPU attribute-table tail through
	# $98EA before the first cutscene worker release. The captured frame-8 state
	# brackets this write; its exact in-frame pixel edge remains unmodeled.
	if not _apply_startup_dispatch_attribute_tail_seed(source_frame):
		return
	# The sampled NMI path transfers the staged PPU packet before it raises the
	# scheduler-ready latch. Keep this order: a task awakened below can only
	# stage a packet for a later source frame.
	_commit_staged_palette(source_frame)
	_commit_staged_text_glyph(source_frame)
	_commit_background_01_queue(source_frame)
	_pump_fd_clear_queue(source_frame)
	_advance_ec_stream(source_frame)
	# The title raster NMI writes vertical scroll from the current $44 before
	# the cooperative cutscene task advances its per-frame $44/$79/$7C state.
	# Preserve that pre-task value so the rendered source frame uses the same
	# vblank scroll even though the frame-end RAM snapshot contains the later
	# scheduler result.
	_capture_f8_title_scroll_for_nmi(source_frame)
	# Consume source-only reset-stepper milestones. `$9F69` installs slot $0005
	# before the main task's `$9FA8` startup scan; the first NMI-ready scheduler
	# release follows on its independently derived source frame.
	if source_frame == _worker_ready_install_source_frame:
		if not _scheduler.register_task(CUTSCENE_TASK_SLOT, RomCooperativeScheduler.READY_TASK_DELAY_SENTINEL):
			_fail_slice("Could not install the ROM-traced cutscene task in scheduler slot $0005.")
			return
		_startup_worker_slot_registered = true
		state["startup_worker_slot_registered"] = true
	if source_frame == _first_ready_worker_scan_source_frame:
		if not _startup_worker_slot_registered:
			_fail_slice("The ROM startup scan arrived before the worker slot install event.")
			return
		if not _scheduler.begin_initial_ready_scan():
			_fail_slice("Could not begin the traced pre-NMI startup scheduler scan.")
			return
		_drain_scheduler()
	elif source_frame >= _first_nmi_release_source_frame:
		_scheduler.notify_nmi_ready()
		_drain_scheduler()
		_prepare_f5_palette_effect(source_frame)
		_finish_f5_palette_effect(source_frame)
	state["scheduler_tick"] = _scheduler.scheduler_tick
	_apply_visual_state()


func _apply_startup_dispatch_attribute_tail_seed(source_frame: int) -> bool:
	if source_frame != _first_ready_worker_scan_source_frame \
			or bool(state.get("startup_dispatch_attribute_tail_seed_applied", false)):
		return true
	var source_bytes := FileAccess.get_file_as_bytes(STARTUP_ATTRIBUTE_TAIL_SOURCE_FILE)
	if source_bytes != PackedByteArray(STARTUP_ATTRIBUTE_TAIL_SOURCE_BYTES) \
			or _sha256_hex(source_bytes) != STARTUP_ATTRIBUTE_TAIL_SOURCE_SHA256:
		_fail_slice("The preserved $8464/$98EA startup PPU seed bytes are missing or changed.")
		return false
	for address in range(STARTUP_ATTRIBUTE_TAIL_PPU_ADDRESS,
			STARTUP_ATTRIBUTE_TAIL_PPU_ADDRESS + STARTUP_ATTRIBUTE_TAIL_SIZE):
		_background_01_ppu_memory[address] = STARTUP_ATTRIBUTE_TAIL_VALUE
	field_screen.set_ppu_memory(_background_01_ppu_memory)
	state["startup_dispatch_attribute_tail_seed_applied"] = true
	state["startup_dispatch_attribute_tail_seed"] = {
		"source_pc": "$8464 -> $84B0/$84BE -> $98EA/$9953",
		"source_file_offset": "0x004C0",
		"source_bytes": "A9 E0 85 E6 A9 23 85 E7 A0 01 A2 20 A9 55 20 EA 98",
		"source_frame_state_edge": source_frame,
		"ppu_address": "$23E0",
		"byte_count": STARTUP_ATTRIBUTE_TAIL_SIZE,
		"byte_value": "$55",
		"same_input_bus_trace_verified": true,
		"within_frame_pixel_edge_measured": false,
	}
	return true


func _capture_f8_title_scroll_for_nmi(source_frame: int) -> void:
	if int(state.get("background_id", -1)) != F8_TITLE_BACKGROUND_ID:
		return
	var scroll_y := (int(state.get("ram_0044_value", 0)) - 1) & 0xFF
	state["f8_title_scroll_y"] = scroll_y
	state["f8_title_scroll_source_frame"] = source_frame


func _advance_ec_stream(source_frame: int) -> void:
	if _ec_stream_player == null:
		return
	var commit_event: Dictionary = _ec_stream_player.commit_pending_packets(
		source_frame, _background_01_ppu_memory)
	if str(commit_event.get("kind", "")) == "committed":
		field_screen.set_ppu_memory(_background_01_ppu_memory)
		state["ec_stream_last_commit"] = commit_event
	# Bank-0 `$89FF` has a single ROM callsite: `$84FC -> $895D -> $896D`.
	# `$895D` reaches it once per `$9FA8(A=1)` tick while a nonzero text speed
	# (`$55`) glyph wait is active. Do not advance the EC delay on unrelated
	# source frames; pauses, loader work, and FC/EA helpers naturally hold it.
	var stream_event: Dictionary = {}
	if _ec_consumer_tick_due():
		stream_event = _ec_stream_player.advance_consumer_tick(source_frame)
	state["ec_stream_player"] = _ec_stream_player.get_state()
	if not stream_event.is_empty() and str(stream_event.get("kind", "")) != "inactive":
		state["ec_stream_last_event"] = stream_event


func _ec_consumer_tick_due() -> bool:
	# The PC-verified `$84FC` call is skipped entirely when `$55 == 0`. A
	# positive speed enters `$895D`; its current yielded phase represents the
	# interval after `$9FA8(A=1)` and before the paired `$89FF` call.
	return _pending_handler == "text_glyph" \
		and _pending_handler_phase == "text_speed_wait" \
		and int(state.get("text_speed", 0)) > 0 \
		and not _pending_command.is_empty()


func _drain_scheduler() -> void:
	while true:
		var outcome: int = _scheduler.step()
		match outcome:
			RomCooperativeScheduler.StepOutcome.TASK_RESUME_REQUIRED:
				_run_cutscene_task_until_yield()
				if _scheduler.current_task_slot_offset >= 0:
					_fail_slice("Cutscene task returned without yielding or finishing.")
					return
				if _cutscene_task_stopped:
					return
			RomCooperativeScheduler.StepOutcome.PASS_COMPLETED, RomCooperativeScheduler.StepOutcome.WAITING_FOR_NMI:
				return
			RomCooperativeScheduler.StepOutcome.WAITING_FOR_TASK_OUTCOME:
				_fail_slice("Scheduler was stepped while the cutscene task still owns the CPU context.")
				return


func _run_cutscene_task_until_yield() -> void:
	# The ROM interpreter can dispatch multiple immediate commands in one worker
	# run. Bound the prototype loop so unsupported/corrupt bytes fail closed.
	for _instruction_budget in range(32):
		var dispatch_not_before := int(state.get("script_dispatch_not_before_frame", -1))
		if dispatch_not_before >= 0 and int(state["source_frame"]) < dispatch_not_before:
			return _yield_cutscene_task(
				dispatch_not_before - int(state["source_frame"]),
				"ROM-stepper F8 helper-return source-frame event"
			)
		if not bool(state.get("fd_fill_inputs_initialized", false)):
			_initialize_fd_fill_inputs_from_rom_worker_setup()
		if not _pending_command.is_empty():
			if not _resume_pending_handler():
				return
			continue
		var decoded := _decode_command_at_cursor()
		if decoded.is_empty():
			_fail_slice("Could not decode the current cutscene command from the extracted bytes.")
			return
		if not _dispatch_decoded_command(decoded):
			return
		if _cutscene_task_stopped:
			return
	_fail_slice("Cutscene immediate-command budget exceeded before a ROM scheduler yield.")


func _initialize_fd_fill_inputs_from_rom_worker_setup() -> void:
	# Byte-verified bank-0 worker setup at `$84CF–$84E5`:
	# `$4F=$49`, `$50=$22`, `$51=$4F`, `$54=$4F & $1F`,
	# `$52=$50`, then `$53=$51` at the `$84E3` interpreter entry.
	var initial_low := 0x49
	var initial_high := 0x22
	var initial_text_origin := (initial_high << 8) | initial_low
	state["fd_fill_inputs_initialized"] = true
	state["ram_004F_value"] = initial_low
	state["ram_0050_value"] = initial_high
	state["ram_0054_value"] = initial_low & 0x1F
	state["ram_0053_value"] = initial_low
	state["fd_fill_inputs_source"] = {
		"rom_cpu_range": "$84CF–$84E5",
		"file_offset_range": "0x0004DF–0x0004F5",
		"initial_origin": "$%04X" % initial_text_origin,
		"initial_fill_limit": "$%02X" % int(state["ram_0054_value"]),
		"source_trace": "reference/rom_extract/intro/cutscene_boot_task_install_trace.md",
	}
	state["text_ppu_cursor_known"] = true
	state["text_ppu_cursor_base_address"] = initial_text_origin
	state["text_ppu_cursor_column"] = 0
	state["text_ppu_cursor_address"] = initial_text_origin


func _decode_command_at_cursor() -> Dictionary:
	if _script_cursor < 0 or _script_cursor >= _script_bytes.size():
		return {}
	var opcode := int(_script_bytes[_script_cursor])
	var consumed_length := 0
	if opcode <= 0xD7:
		consumed_length = 1
	elif opcode >= 0xD8 and opcode <= 0xDF:
		consumed_length = 1
	elif opcode >= 0xE0 and opcode <= 0xE7:
		consumed_length = 1
	else:
		match opcode:
			0xE8, 0xF9, 0xFA, 0xED:
				consumed_length = 2
			0xF1, 0xEC, 0xF3, 0xF4, 0xF5, 0xF2, 0xF8:
				consumed_length = 2
			0xFE:
				consumed_length = 3
			0xFC:
				consumed_length = 1
			0xFD, 0xEE:
				consumed_length = 1
			0xFB:
				if _script_cursor + 1 >= _script_bytes.size():
					return {}
				consumed_length = 2 + int(_script_bytes[_script_cursor + 1])
			0xE9, 0xEA:
				consumed_length = 1
			_:
				return {}
	if _script_cursor + consumed_length > _script_bytes.size():
		return {}
	var consumed := _script_bytes.slice(_script_cursor, _script_cursor + consumed_length)
	return {
		"opcode": opcode,
		"consumed_length": consumed_length,
		"consumed_bytes": consumed,
		"operands": consumed.slice(1),
		"script_cursor": _script_cursor,
	}


func _dispatch_decoded_command(decoded: Dictionary) -> bool:
	var opcode := int(decoded["opcode"])
	var event := _make_dispatch_event(decoded)
	var source_frame := int(event["source_frame"])
	var operands: PackedByteArray = decoded["operands"]
	_command_sequence += 1
	state["dispatch_count"] = _command_sequence
	state["cutscene_cpu_pointer"] = str(event["script_cpu"])
	state["last_rom_bytes"] = str(event["rom_consumed_bytes"])
	state["last_handler_entry"] = str(event["handler_entry_pc"])
	state["source_frame_of_last_dispatch"] = int(event["source_frame"])
	_apply_source_command(opcode, operands, int(event["source_frame"]))
	source_command_applied.emit(event.duplicate(true), state.duplicate(true))
	if opcode <= 0xD7:
		var text_tiles: Array = state.get("text_tile_ids", [])
		text_tiles.append(opcode)
		state["text_tile_ids"] = text_tiles
		state["text_tile_count"] = int(state.get("text_tile_count", 0)) + 1
		if _text_glyph_queue_capacity_blocked(opcode):
			_pending_command = decoded.duplicate(true)
			_pending_handler = "text_glyph"
			_pending_handler_phase = "queue_capacity_wait"
			state["text_glyph_queue_capacity_wait"] = {
				"glyph_id": opcode,
				"queue_cursor_0628": _background_01_queue_cursor,
				"requested_payload_bytes": 2,
				"capacity_limit": F9_PPU_QUEUE_CURSOR_LIMIT,
				"rom_check": "$0628 + requested payload >= $3D at $9B28",
				"retry_count": 1,
				"first_wait_source_frame": source_frame,
				"resume_source_frame": -1,
			}
			state["last_text_tile"] = {
				"tile_id": opcode,
				"script_cpu": event["script_cpu"],
				"ppu_glyph_upload_modeled": false,
				"waiting_for_shared_ppu_queue_capacity": true,
			}
			return _yield_cutscene_task(1, "ROM text-glyph $9B28 PPU queue back-pressure")
		var glyph_upload_modeled := _stage_text_glyph(opcode, int(event["source_frame"]))
		state["last_text_tile"] = {
			"tile_id": opcode,
			"script_cpu": event["script_cpu"],
			"ppu_glyph_upload_modeled": glyph_upload_modeled,
		}
		_pending_command = decoded.duplicate(true)
		_pending_handler = "text_glyph"
		var text_speed := int(state.get("text_speed", 0))
		if text_speed > 0:
			_pending_handler_phase = "text_speed_wait"
			return _yield_cutscene_task(text_speed, "ROM text tile $%02X speed wait" % opcode)
		_complete_pending_command(int(decoded["consumed_length"]))
		return true
	if opcode >= 0xD8 and opcode <= 0xDF:
		var pause_delay := _compact_pause_delay(opcode)
		var current_release_already_elapsed := bool(state.get("compact_pause_current_release_credit", false))
		state["compact_pause_current_release_credit"] = false
		state["pending_compact_pause_delay"] = pause_delay
		state["compact_pause_release_accounting"] = {
			"rom_delay": pause_delay,
			"same_frame_release_precounted": current_release_already_elapsed,
			"basis": "frame-end slot-$0005 RAM after F8 00 tail" if current_release_already_elapsed else "standard later-NMI countdown",
		}
		_pending_command = decoded.duplicate(true)
		_pending_handler = "compact_pause"
		return _yield_cutscene_task(
			pause_delay,
			"ROM compact pause $%02X" % opcode,
			current_release_already_elapsed
		)
	if opcode >= 0xE0 and opcode <= 0xE7:
		var rewind_tiles := opcode - 0xE0
		if not bool(state.get("text_ppu_cursor_known", false)):
			_stop_before_unmodeled_handler(
				str(event["script_cpu"]), opcode, operands,
				"E0–E7 needs the ROM-derived active text cursor ($53)."
			)
			return false
		# ROM subtracts directly from the low-byte cursor ($53); the result
		# may lie before the current base. The opening's E3 after FD moves
		# $2249 back to $2246, so keep this relative offset signed.
		var text_column := int(state.get("text_ppu_cursor_column", 0)) - rewind_tiles
		state["text_ppu_cursor_column"] = text_column
		state["text_ppu_cursor_address"] = int(state["text_ppu_cursor_base_address"]) + text_column
		# `$8520` subtracts the E-command distance from `$53`, masks it to
		# a nametable column, and lowers `$54` when the new column is smaller.
		# The FD helper later consumes that live limit to derive its width.
		var new_text_cursor_low := int(state["text_ppu_cursor_address"]) & 0xFF
		state["ram_0053_value"] = new_text_cursor_low
		var new_fill_limit := new_text_cursor_low & 0x1F
		var current_fill_limit := int(state.get("ram_0054_value", -1))
		if current_fill_limit < 0:
			_stop_before_unmodeled_handler(
				str(event["script_cpu"]), opcode, operands,
				"E0–E7 needs the ROM-initialized `$54` text-column limit."
			)
			return false
		if new_fill_limit < current_fill_limit:
			state["ram_0054_value"] = new_fill_limit
		state["fd_fill_limit_last_update"] = {
			"script_cpu": str(event["script_cpu"]),
			"source_frame": source_frame,
			"opcode": "$%02X" % opcode,
			"cursor_low_after_rom_subtract": "$%02X" % new_text_cursor_low,
			"column_candidate": "$%02X" % new_fill_limit,
			"previous_limit": "$%02X" % current_fill_limit,
			"new_limit": "$%02X" % int(state["ram_0054_value"]),
			"rom_handler": "$8520–$8532",
		}
		state["text_cursor_back_tiles"] = rewind_tiles
		_script_cursor += int(decoded["consumed_length"])
		return true
	match opcode:
		0xE8:
			if operands.size() != 1 or int(operands[0]) != 0x01:
				_stop_before_unmodeled_handler(
					str(event["script_cpu"]), opcode, operands,
					"Only the ROM-verified E8 $01 raster preset is decoded."
				)
				return false
			_bg0a_raster_model = BG0A_RASTER_MODEL_SCRIPT.new()
			if not _bg0a_raster_model.configure_from_e8(int(operands[0]), source_frame):
				_fail_slice("Could not load the ROM E8 $01 raster preset: " + _bg0a_raster_model.last_error)
				return false
			state["e8_raster_preset"] = _bg0a_raster_model.preset_state()
			_script_cursor += int(decoded["consumed_length"])
			return true
		0xFB:
			_script_cursor += int(decoded["consumed_length"])
			return true
		0xF9, 0xFA:
			if operands.size() != 1:
				_stop_before_unmodeled_handler(
					str(event["script_cpu"]),
					opcode,
					operands,
					"F9/FA requires one background ID operand."
				)
				return false
			var selected_background_id := int(operands[0])
			_stop_f5_palette_effect("new background selection")
			var previous_2k_chr_selectors := field_screen.get_source_2k_chr_selectors()
			state["background_id"] = selected_background_id
			# A new background/camera record owns its own global scroll history.
			# Do not carry a prior EA clear's $007B reset across this source event.
			state["rom_global_scroll_state_reset"] = {}
			# Horizontal camera scroll belongs to BG0A. Preserve the current
			# vertical register state while clearing it at every background edge.
			var previous_ppu_scroll: Vector2i = field_screen.get_scroll_pixels()
			field_screen.set_scroll_pixels(0, previous_ppu_scroll.y)
			_bg08_raster_model = null
			state.erase("bg08_raster_model")
			_bg0b_camera_model = null
			state.erase("bg0b_camera_model")
			_bg07_camera_model = null
			state.erase("bg07_camera_model")
			_bg0b_sprite_x_motion_offset = 0
			_bg0b_sprite_last_motion_source_frame = -1
			_bg0b_sprite_motion_set_start_source_frame = -1
			state["field_palette_override_active"] = false
			if selected_background_id == F9_BACKGROUND_01_ID and opcode == 0xF9:
				_f9_background_01_loader = BACKGROUND_01_LOADER.new()
				if not _f9_background_01_loader.build_packets():
					_fail_slice("Could not build the byte-preserved F9 background-01 packet stream.")
					return false
				if not field_screen.set_background_profile(F9_BACKGROUND_01_ID):
					_fail_slice("Could not select the ROM-derived F9 background-01 screen profile.")
					return false
				state["background_profile_ready"] = true
				_background_01_committed_packets = 0
				_background_01_committed_writes = 0
				_background_01_queued_packets = 0
				state["background_01_committed_packets"] = 0
				state["background_01_committed_ppu_writes"] = 0
				state["background_01_queued_packets"] = 0
				_f9_background_01_packet_index = 0
				_background_01_queue_packets.clear()
				_background_01_queue_cursor = 0
				_pending_command = decoded.duplicate(true)
				_pending_handler = "f9_background_01"
				_pending_handler_phase = "loader_initial_wait"
				state["f9_background_01_loader"] = {
					"packet_count": _f9_background_01_loader.packets.size(),
					"payload_byte_count": _f9_background_01_loader.payload_byte_count,
					"queue_buffer_cpu_range": "$05E8-$0627",
					"queue_buffer_bytes": 64,
					"capacity_cursor_limit": F9_PPU_QUEUE_CURSOR_LIMIT,
					"producer_status": "waiting at shared $8BB0 one-count loader yield",
					"initial_loader_release_credit": false,
					"initial_loader_wait_reason": "ROM $8BB0 calls $9FA8(A=$01); the next $9EED scheduler release resumes the F9 producer",
					"producer_complete": false,
					"ppu_committed": false,
					"committed_packets": 0,
					"committed_ppu_writes": 0,
					"complete": false,
				}
				return _yield_cutscene_task(1, "F9 background-01 $8BB0 initial loader yield")
			if selected_background_id == F9_BACKGROUND_00_ID and opcode == 0xF9:
				state["background_profile_ready"] = false
				# The same ROM script loops back to the logo segment at source
				# frame 4207. EA's prior clear has completed by then; F9 starts
				# a new background occurrence while the PPU palette is still black.
				state["ea_clear_applied"] = false
				_pending_command = decoded.duplicate(true)
				_pending_handler = "f9"
				_pending_handler_phase = "loader_wait"
				state["f9_path_scope"] = "F9 00 background record $A0D4 only"
				state["f9_path_status"] = "waiting at first $8BB0 one-count loader yield"
				return _yield_cutscene_task(1, "F9 background-00 $8BB0 loader yield")
			_generic_background_loader = BACKGROUND_PACKET_LOADER.new()
			if not _generic_background_loader.build_packets(selected_background_id):
				_stop_before_unmodeled_handler(
					str(event["script_cpu"]), opcode, operands,
					"No verified ROM packet layout for background $%02X: %s" % [selected_background_id, _generic_background_loader.last_error]
				)
				return false
			if not field_screen.set_background_profile(selected_background_id):
				_fail_slice("Could not select the ROM-derived screen profile for background $%02X." % selected_background_id)
				return false
			if selected_background_id == 0x08:
				_bg08_raster_model = BG08_RASTER_MODEL_SCRIPT.new()
				if not _bg08_raster_model.configure(1048, previous_2k_chr_selectors):
					_fail_slice("Could not initialize the ROM BG08 raster model: " + _bg08_raster_model.last_error)
					return false
				state["bg08_pending_pair_source"] = previous_2k_chr_selectors.duplicate()
				state["bg08_loaded_pair_target"] = field_screen.get_source_2k_chr_selectors()
			if selected_background_id == 0x0A and opcode == 0xF9:
				if _bg0a_raster_model == null \
						or not _bg0a_raster_model.configure_camera_from_f9(selected_background_id, source_frame):
					var camera_error := "E8 $01 preset was not initialized before F9 $0A."
					if _bg0a_raster_model != null and not _bg0a_raster_model.last_error.is_empty():
						camera_error = _bg0a_raster_model.last_error
					_fail_slice("Could not initialize ROM BG0A camera motion: " + camera_error)
					return false
				state["bg0a_raster_model"] = _bg0a_raster_model.debug_snapshot(source_frame)
			if selected_background_id == 0x07 and opcode == 0xFA:
				_bg07_camera_model = BACKGROUND_CAMERA_WORKER_SCRIPT.new()
				if not _bg07_camera_model.configure_from_fa(selected_background_id, source_frame):
					_fail_slice("Could not decode ROM BG07 camera record: " + _bg07_camera_model.last_error)
					return false
				state["bg07_camera_model"] = _bg07_camera_model.debug_snapshot(source_frame)
			if selected_background_id == 0x0B and opcode == 0xFA:
				_bg0b_camera_model = BACKGROUND_CAMERA_WORKER_SCRIPT.new()
				if not _bg0b_camera_model.configure_from_fa(selected_background_id, source_frame):
					_fail_slice("Could not decode ROM BG0B camera record: " + _bg0b_camera_model.last_error)
					return false
				state["bg0b_camera_model"] = _bg0b_camera_model.debug_snapshot(source_frame)
			if selected_background_id == 0x03 and opcode == 0xFA:
				_bg03_camera_model = BACKGROUND_CAMERA_WORKER_SCRIPT.new()
				if not _bg03_camera_model.configure_from_fa(selected_background_id, source_frame):
					_fail_slice("Could not decode ROM BG03 camera record: " + _bg03_camera_model.last_error)
					return false
				state["bg03_camera_model"] = _bg03_camera_model.debug_snapshot(source_frame)
			state["background_profile_ready"] = true
			_generic_background_packet_index = 0
			_background_01_queue_packets.clear()
			_background_01_queue_cursor = 0
			_generic_background_committed_packets = 0
			_generic_background_committed_writes = 0
			_pending_command = decoded.duplicate(true)
			_pending_handler = "generic_background"
			_pending_handler_phase = "loader_initial_wait"
			state["generic_background_loader"] = {
				"command": "FA" if opcode == 0xFA else "F9",
				"background_id": selected_background_id,
				"packet_count": _generic_background_loader.packets.size(),
				"payload_byte_count": _generic_background_loader.payload_byte_count,
				"encoded_packet_byte_count": _generic_background_loader.encoded_packet_byte_count,
				"metadata": _generic_background_loader.metadata.duplicate(true),
				"producer_status": "waiting at the ROM loader's first yield; subframe phase unresolved",
				"producer_complete": false,
				"committed_packets": 0,
				"committed_ppu_writes": 0,
			}
			return _yield_cutscene_task(1, "%s background-$%02X initial loader wait" % ["FA" if opcode == 0xFA else "F9", selected_background_id])
		0xE9:
			_pending_command = decoded.duplicate(true)
			_pending_handler = "e9"
			return _yield_cutscene_task(2, "E9 ROM pre-wait $02")
		0xEA:
			_pending_command = decoded.duplicate(true)
			_pending_command["script_cpu"] = str(event["script_cpu"])
			_pending_handler = "ea"
			return _yield_cutscene_task(1, "EA palette step")
		0xED:
			_script_cursor += int(decoded["consumed_length"])
			if int(operands[0]) == 0x58:
				state["first_ed58_dispatched"] = true
			return true
		0xEE:
			_apply_rom_ppu_zero_fill(0x2221, 11, 30, 0x20, source_frame, "EE")
			_script_cursor += int(decoded["consumed_length"])
			return true
		0xF2:
			if operands.size() != 1:
				_stop_before_unmodeled_handler(str(event["script_cpu"]), opcode, operands,
					"F2 must contain one observed text-speed operand.")
				return false
			state["text_speed"] = int(operands[0])
			state["text_speed_source_byte"] = "$%02X" % int(operands[0])
			# ROM `$8678` F2 only writes text speed to `$55`; cursor state is
			# established by startup/FD setup and FC line-break handlers.
			_script_cursor += int(decoded["consumed_length"])
			return true
		0xF5:
			if operands.size() != 1:
				_stop_before_unmodeled_handler(str(event["script_cpu"]), opcode, operands,
					"F5 must contain one observed visual-state operand.")
				return false
			var f5_operand := int(operands[0])
			if f5_operand != 0xFF and _f5_palette_effect_model != null \
					and _f5_palette_effect_model.active:
				_stop_f5_palette_effect("new F5 effect selection")
			state["ram_004C_value_or_delta"] = 0 if f5_operand == 0xFF else (f5_operand | 0x80)
			state["f5_00_semantics"] = "F5 00 selects bank-6 palette stream 0 and rotates $0637-$0639 through its ROM three-record loop." if f5_operand == 0x00 else "ROM F5 operand applied."
			if f5_operand == 0x00 and int(state.get("background_id", -1)) == 0x01:
				_f5_palette_effect_model = RUNNER_PALETTE_EFFECT_SCRIPT.new()
				if not _f5_palette_effect_model.configure(source_frame):
					_fail_slice("Could not initialize the ROM F5 00 palette effect: " + _f5_palette_effect_model.last_error)
					return false
				state["f5_00_palette_effect"] = _f5_palette_effect_model.debug_snapshot()
				state["f5_00_palette_effect"]["selected_by_script_cpu"] = str(event["script_cpu"])
				state["f5_00_palette_effect"]["selected_by_f5_source_frame"] = source_frame
				state["f5_00_palette_effect"]["palette_ram_addresses"] = "$0637-$0639"
				state["f5_00_palette_effect"]["ppu_addresses"] = "$3F0D-$3F0F"
			elif f5_operand == 0x01 and int(state.get("background_id", -1)) == 0x09:
				_f5_palette_effect_model = BG09_PALETTE_EFFECT_SCRIPT.new()
				if not _f5_palette_effect_model.configure(source_frame):
					_fail_slice("Could not initialize the ROM BG09 palette effect: " + _f5_palette_effect_model.last_error)
					return false
				state["bg09_palette_effect"] = _f5_palette_effect_model.debug_snapshot()
				state["bg09_palette_effect"]["selected_by_f5_source_frame"] = source_frame
				state["bg09_palette_effect"]["palette_ram_address"] = "$0633"
				state["bg09_palette_effect"]["ppu_address"] = "$3F09"
			elif f5_operand == 0xFF:
				_stop_f5_palette_effect("F5 FF clears $4C")
			if f5_operand == 0x10 and int(state.get("background_id", -1)) == 0x08:
				if _bg08_raster_model == null:
					_fail_slice("BG08 F5 10 stream started without its preset/raster model.")
					return false
				state["bg08_raster_model"] = _bg08_raster_model.debug_snapshot()
			_script_cursor += int(decoded["consumed_length"])
			return true
		0xFC:
			# The cold-start trace establishes this one-byte path: update $99,
			# yield with A=$04, add $40 to $51:$52, then resume at the next byte.
			state["fc_scene_step"] = {
				"ram_0099_operation": "($99 & $80) | $40",
				"ram_0051_0052_delta": 0x0040,
				"counter_initial_value_known": false,
				"delay_releases": 4,
			}
			_pending_command = decoded.duplicate(true)
			_pending_handler = "fc_scene_step"
			return _yield_cutscene_task(4, "FC ROM scene-step delay $04")
		0xFD:
			_stop_f5_palette_effect("FD scene transition")
			# The live trace keeps $4C=$81 through frame 2116; FD's scene
			# transition clears it on the observed frame-2117 boundary.
			state["ram_004C_value_or_delta"] = 0
			if not bool(state.get("fd_fill_inputs_initialized", false)):
				_stop_before_unmodeled_handler(
					str(event["script_cpu"]), opcode, operands,
					"FD needs the ROM worker's `$4F/$50/$54` setup state."
				)
				return false
			var fd_base_low := int(state["ram_004F_value"])
			var fd_base_high := int(state["ram_0050_value"])
			var fd_fill_limit := int(state["ram_0054_value"])
			var fd_text_origin := (fd_base_high << 8) | fd_base_low
			var fd_start := (fd_base_high << 8) | (fd_base_low & 0xE0) | fd_fill_limit
			var fd_width := (0x1E - fd_fill_limit) & 0xFF
			var fd_brightness_counters: Vector2i = state.get("fade_counters", Vector2i.ZERO)
			var fd_buffered := fd_brightness_counters.x != 0 or fd_brightness_counters.y != 0
			var fd_mode := "buffered" if fd_buffered else "direct"
			var fd_brightness_text := "%02X %02X" % [
				fd_brightness_counters.x & 0xFF, fd_brightness_counters.y & 0xFF,
			]
			state["fd_scene_clear"] = {
				"handler_entry": "$8855",
				"helper": "$88B1 → $98E8",
				"dispatch_source_frame": source_frame,
				"dispatch_script_cpu": str(event["script_cpu"]),
				"row_count": 8,
				"ram_004F_0050_0054": "%02X %02X %02X" % [fd_base_low, fd_base_high, fd_fill_limit],
				"width_from_rom_ram_0054": fd_width,
				"ppu_fill_start_from_rom_ram_004F_0050_0054": "$%04X" % fd_start,
				"ppu_fill_start_address": fd_start,
				"fill_width_bytes": fd_width,
				"text_cursor_reset_origin_from_004F_0050": fd_text_origin,
				"mode_from_rom_004A_004B_gate": fd_mode,
				"brightness_counters_004A_004B": fd_brightness_text,
				"fill_value": 0,
				"ppu_writes_modeled": true,
				"source_trace": "reference/rom_extract/intro/fd_scene_clear_trace.md",
				"delay_releases": 4,
			}
			if not fd_buffered:
				_apply_rom_ppu_zero_fill(fd_start, 8, fd_width, 0x20, source_frame, "FD")
				state["fd_scene_clear"]["direct_ppu_writes"] = 8 * fd_width
			else:
				if not _background_01_queue_packets.is_empty() or _background_01_queue_cursor != 0:
					_stop_before_unmodeled_handler(
						str(event["script_cpu"]), opcode, operands,
						"ROM-buffered FD path requires an empty PPU queue at entry."
					)
					return false
				_fd_clear_pending_rows.clear()
				_fd_clear_next_row = 0
				_fd_clear_committed_rows = 0
				_fd_clear_committed_writes = 0
				_fd_clear_active = true
				for row in range(8):
					var clear_payload := PackedByteArray()
					clear_payload.resize(fd_width)
					clear_payload.fill(0)
					_fd_clear_pending_rows.append({
						"kind": "fd_clear_row",
						"ppu_address": fd_start + row * 0x20,
						"payload": clear_payload,
						"queue_encoded_bytes": 3 + clear_payload.size(),
						"row": row,
					})
				_stage_fd_clear_queue(source_frame)
			_pending_command = decoded.duplicate(true)
			_pending_handler = "fd_scene_clear"
			if fd_buffered and _fd_clear_next_row < _fd_clear_pending_rows.size():
				_pending_handler_phase = "queue_capacity_wait"
				state["fd_scene_clear"]["queue_capacity_yields_inside_88b1"] = 1
				state["fd_scene_clear"]["initial_queue_rows_staged"] = _fd_clear_next_row
				return _yield_cutscene_task(1, "FD $88B1/$9B28 buffered-row capacity retry 1")
			_pending_handler_phase = "post_clear_wait"
			return _yield_cutscene_task(4, "FD ROM scene-clear helper delay $04")
		0xF4:
			if operands.size() != 1 or (int(operands[0]) != 0x04 and int(operands[0]) != 0x05):
				_stop_before_unmodeled_handler(str(event["script_cpu"]), opcode, operands,
					"Only F4 operands 04 and 05 have a byte-traced four-pass palette path.")
				return false
			var f4_values: Array[int] = [0x0F, 0x10, 0x20, 0x30]
			if int(operands[0]) == 0x05:
				f4_values.reverse()
			state["f4_palette_sweep"] = {
				"operand": int(operands[0]),
				"palette_slot": 7,
				"values": f4_values.duplicate(),
				"pass_index": 0,
				"wait_releases_per_pass": 4,
			}
			_pending_command = decoded.duplicate(true)
			_pending_handler = "f4_palette_sweep"
			_pending_handler_phase = "queue_capacity_wait"
			var f4_queue_request_end := _background_01_queue_cursor + 0x20
			state["f4_palette_queue_reservation"] = {
				"script_cpu": str(event["script_cpu"]),
				"queue_cursor_0628": _background_01_queue_cursor,
				"requested_payload_bytes": 0x20,
				"sum": f4_queue_request_end,
				"capacity_limit": F9_PPU_QUEUE_CURSOR_LIMIT,
				"capacity_yield": f4_queue_request_end >= F9_PPU_QUEUE_CURSOR_LIMIT,
				"capacity_rule_source": "$9B28 compares cursor plus requested payload before staging the three-byte header and payload",
			}
			if f4_queue_request_end >= F9_PPU_QUEUE_CURSOR_LIMIT:
				return _yield_cutscene_task(1, "F4 $9B28 palette queue capacity retry")
			if not _stage_f4_palette_pass(source_frame):
				_fail_slice("Could not stage the ROM-derived F4 palette sweep.")
				return false
			_pending_handler_phase = "palette_pass_wait"
			return _yield_cutscene_task(4, "F4 palette pass 1/4 delay $04")
		0xEC:
			if operands.size() != 1:
				_stop_before_unmodeled_handler(
					str(event["script_cpu"]), opcode, operands,
					"EC must contain its one-byte stream selector."
				)
				return false
			if int(operands[0]) == 0xFF:
				if _ec_stream_player != null:
					state["ec_stream_stop_event"] = _ec_stream_player.stop_from_command(source_frame)
					state["ec_stream_player"] = _ec_stream_player.get_state()
				state["ec_stream_stop_source_frame"] = source_frame
				state["ec_stream_stop_operand"] = "$FF"
				_script_cursor += int(decoded["consumed_length"])
				return true
			var stream_selector := int(operands[0])
			if stream_selector != 0x00 and stream_selector != 0x02 \
					and stream_selector != 0x04 and stream_selector != 0x05:
				_stop_before_unmodeled_handler(
					str(event["script_cpu"]), opcode, operands,
					"Only byte-verified EC stream selectors 00/02/04/05 and EC FF are modeled."
				)
				return false
			# `$89D2` selects the operand's bank-6 pointer-table entry, writes
			# $0652-$0655, initializes $90/$91, then restores PRG R7 from $56.
			# Its first stream byte is consumed later by the text helper's first
			# `$89FF` call; the ROM has no dispatch-relative frame timer here.
			_ec_stream_player = EC_STREAM_PLAYER.new()
			if not _ec_stream_player.start(stream_selector):
				_fail_slice("Could not start the source-verified bank-6 EC stream player.")
				return false
			var ec_state: Dictionary = _ec_stream_player.get_state()
			var stream_base_pointer := int(EC_STREAM_BASE_BY_POINTER_TABLE_INDEX[stream_selector])
			state["ec_stream_pointer_table_index"] = stream_selector
			state["ec_stream_setup"] = {
				"pointer_table_index": stream_selector,
				"stream_pointer": "$%04X" % stream_base_pointer,
				"pointer_table_cpu": "$BD00",
				"ram_0652_0655_hex": "80 01 %02X %02X" % [
					stream_base_pointer & 0xFF,
					(stream_base_pointer >> 8) & 0xFF,
				],
				"ram_0090_0091_hex": "00 02",
				"temporary_prg_r7_bank": 6,
				"restored_prg_r7_bank_from_ram_0056": 3,
				"stream_consumer_modeled": true,
				"first_record_frame": -1,
				"first_record_frame_is_capture_anchor": false,
				"first_record_trigger": "$84FC -> $895D -> $896D -> $89FF after $9FA8(A=1)",
			}
			state["ec_stream_player"] = ec_state
			_script_cursor += int(decoded["consumed_length"])
			return true
		0xF3:
			if operands.size() != 1 or int(operands[0]) != 0x00:
				_stop_before_unmodeled_handler(
					str(event["script_cpu"]), opcode, operands,
					"Only the source-traced F3 00 palette-table path is implemented."
				)
				return false
			if not bool(state.get("background_profile_ready", false)):
				_stop_before_unmodeled_handler(
					str(event["script_cpu"]), opcode, operands,
					"F3 00 requires an active ROM-derived background and FB animation palette selector."
				)
				return false
			_pending_command = decoded.duplicate(true)
			_pending_handler = "f3_palette"
			_pending_handler_phase = "queue_capacity_wait"
			var palette_request_end := _background_01_queue_cursor + 0x20
			state["f3_palette_queue_reservation"] = {
				"background_id": int(state.get("background_id", -1)),
				"script_cpu": str(event["script_cpu"]),
				"queue_cursor_0628": _background_01_queue_cursor,
				"requested_payload_bytes": 0x20,
				"sum": palette_request_end,
				"capacity_limit": F9_PPU_QUEUE_CURSOR_LIMIT,
				"capacity_yield": palette_request_end >= F9_PPU_QUEUE_CURSOR_LIMIT,
			}
			if palette_request_end >= F9_PPU_QUEUE_CURSOR_LIMIT:
				return _yield_cutscene_task(1, "F3 00 $9B28 palette queue capacity retry")
			if not _stage_f3_palette(source_frame):
				_fail_slice("Could not load the source-verified F3 00 palette records.")
				return false
			_complete_pending_command(int(decoded["consumed_length"]))
			return true
		0xF1:
			if operands.size() != 1 or int(operands[0]) != 0x01:
				_stop_before_unmodeled_handler(
					str(event["script_cpu"]), opcode, operands,
					"Only opening operand F1 01 has a byte- and capture-verified data-table path."
				)
				return false
			# The ROM `$97B6` handler branches on `$4A | $4B`: zero draws directly,
			# nonzero queues the clear and ROM graphics packets for the NMI writer.
			# In the current opening replay, `fade_counters` tracks those two bytes;
			# its values were checked against RAM at every supported F1 dispatch.
			var f1_brightness_counters: Vector2i = state.get("fade_counters", Vector2i.ZERO)
			var f1_buffered := f1_brightness_counters.x != 0 or f1_brightness_counters.y != 0
			var f1_mode := "buffered" if f1_buffered else "direct"
			var f1_brightness_text := "%02X %02X" % [
				f1_brightness_counters.x & 0xFF, f1_brightness_counters.y & 0xFF,
			]
			_f1_graphics_loader = F1_GRAPHICS_LOADER.new()
			if not _f1_graphics_loader.build_packets():
				_stop_before_unmodeled_handler(
					str(event["script_cpu"]), opcode, operands,
					"Could not load the byte-preserved F1 01 graphics packets: %s" % _f1_graphics_loader.last_error
				)
				return false
			# `$864A` requests an 11×30 clear at $2221 and selects `$BB9A`.
			# Geometry is fixed by the ROM handler. Direct/buffered selection comes
			# from the same `$4A | $4B` branch as the source `$97B6` routine.
			state["f1_01_setup"] = {
				"dispatch_source_frame": source_frame,
				"dispatch_script_cpu": str(event["script_cpu"]),
				"ppu_fill_start": "$2221",
				"ppu_fill_rows": 11,
				"ppu_fill_bytes_per_row": 30,
				"ppu_fill_tile_value": 0,
				"ppu_fill_write_count": 330,
				"ppu_fill_source_frame": source_frame,
				"selected_data_pointer": "$%04X" % F1_OPENING_GRAPHICS_POINTER,
				"brightness_counters_004A_004B": f1_brightness_text,
				"selected_draw_path": f1_mode,
				"selected_draw_data_applied": false,
				"selected_draw_data_source_trace": "reference/rom_extract/intro/f1_01_graphics_gate_trace.md",
				"ppu_visible_edge_or_cycle_timing_modeled": false,
			}
			if not f1_buffered:
				_apply_rom_ppu_zero_fill(0x2221, 11, 30, 0x20, source_frame, "F1 01")
				_apply_f1_direct_graphics(source_frame)
				state["f1_01_setup"]["selected_draw_data_applied"] = true
				_script_cursor += int(decoded["consumed_length"])
				return true
			if not _background_01_queue_packets.is_empty() or _background_01_queue_cursor != 0:
				_stop_before_unmodeled_handler(
					str(event["script_cpu"]), opcode, operands,
					"Buffered F1 01 requires the captured PPU queue to be empty at entry."
				)
				return false
			_f1_graphics_pending_packets.clear()
			_f1_graphics_packet_index = 0
			for row in range(11):
				var clear_payload := PackedByteArray()
				clear_payload.resize(30)
				clear_payload.fill(0)
				_f1_graphics_pending_packets.append({
					"kind": "f1_zero_fill_row",
					"ppu_address": 0x2221 + row * 0x20,
					"payload": clear_payload,
					"queue_encoded_bytes": 3 + clear_payload.size(),
					"row": row,
				})
			for packet_value in _f1_graphics_loader.packets:
				var packet: Dictionary = packet_value.duplicate(true)
				packet["kind"] = "f1_table_record"
				_f1_graphics_pending_packets.append(packet)
			_pending_command = decoded.duplicate(true)
			_pending_handler = "f1_buffered_graphics"
			_pending_handler_phase = "queue_capacity_wait"
			state["f1_01_loader"] = {
				"mode": "buffered_nonzero_brightness",
				"packet_count": _f1_graphics_pending_packets.size(),
				"clear_row_count": 11,
				"table_record_count": _f1_graphics_loader.packets.size(),
				"producer_complete": false,
				"committed_packets": _f1_graphics_committed_packets,
				"committed_ppu_writes": _f1_graphics_committed_writes,
			}
			return _fill_f1_graphics_queue(source_frame)
		0xF8:
			if operands.size() != 1:
				_stop_before_unmodeled_handler(
					str(event["script_cpu"]), opcode, operands,
					"F8 requires one service-index operand."
				)
				return false
			if int(operands[0]) == 0x00:
				return _start_f8_title_service(decoded, source_frame, str(event["script_cpu"]))
			if int(operands[0]) != 0x0A:
				_stop_before_unmodeled_handler(
					str(event["script_cpu"]), opcode, operands,
					"Only source-traced F8 service indices 00 and 0A are modeled."
				)
				return false
			_raster_event_generator = RASTER_EVENT_GENERATOR_SCRIPT.new()
			if not _raster_event_generator.configure(source_frame):
				_fail_slice("Could not initialize ROM raster-event state: " + _raster_event_generator.last_error)
				return false
			state["runner_motion_reset"] = {
				"operand": "$0A",
				"ram_000D": 0,
				"ram_000E": 0,
				"helper_return": "$02",
				"trace_source": "reference/rom_extract/intro/runner_motion_trace.md",
			}
			state["runner_raster_event_model"] = _raster_event_generator.debug_snapshot()
			_script_cursor += int(decoded["consumed_length"])
			return true
		0xFE:
			if operands.size() != 2:
				_stop_before_unmodeled_handler(str(event["script_cpu"]), opcode, operands,
					"FE loop requires its two-byte little-endian script target.")
				return false
			var target_address := int(operands[0]) | (int(operands[1]) << 8)
			if target_address != SCRIPT_START_CPU_ADDRESS:
				_stop_before_unmodeled_handler(str(event["script_cpu"]), opcode, operands,
					"Only the observed cold-opening FE target $A020 is modeled.")
				return false
			_script_cursor = target_address - SCRIPT_START_CPU_ADDRESS
			state["script_loop_count"] = int(state.get("script_loop_count", 0)) + 1
			# The ROM FE command is the actual loop boundary. Derive each later
			# phase from this dispatched boundary instead of assuming a fixed
			# observed 4199-frame interval. The phase origin 8 is the
			# separately traced first startup scheduler scan.
			state["script_loop_phase_origin_source_frame"] = source_frame
			state["last_fe_loop"] = {
				"source_frame": source_frame,
				"script_cpu": str(event["script_cpu"]),
				"target_cpu": "$%04X" % target_address,
				"loop_count": int(state["script_loop_count"]),
				"phase_origin_script_frame": int(state["script_loop_phase_origin_script_frame"]),
				"handler_effect": "write $004D/$004E, then return to $84E7",
				"blanket_presenter_state_reset": false,
				"rom_verified": true,
			}
			return true
	return false


func _start_f8_title_service(decoded: Dictionary, source_frame: int, script_cpu: String) -> bool:
	if not _background_01_queue_packets.is_empty() or _background_01_queue_cursor != 0:
		_stop_before_unmodeled_handler(script_cpu, 0xF8, PackedByteArray([0x00]),
			"F8 00 entry requires the traced empty PPU queue.")
		return false
	_f8_palette_fade_step = 0
	_f8_title_oam_shift_count = 0
	_f8_title_motion_step = 0
	state["f8_00_service"] = {
		"handler": "$A4C0",
		"phase": "background_fade",
		"entry_source_frame": source_frame,
		"script_cpu": script_cpu,
		"background_fade_steps": 0,
		"background_fade_counters_start": "0F 0F",
		"oam_y_shift_steps": 0,
		"title_background_id": F8_TITLE_BACKGROUND_ID,
		"title_loader_capacity_yields": 0,
		"title_loader_explicit_yield_frame": -1,
		"motion_steps": 0,
		"paired_fade_steps": 0,
		"source_trace": "reference/rom_extract/intro/f8_00_sequence_trace.md",
		"helper_waits_source_verified": true,
		"queue_packet_order_fully_verified": false,
	}
	_pending_command = decoded.duplicate(true)
	_pending_handler = "f8_title_service"
	_pending_handler_phase = "background_fade"
	_stage_f8_background_fade(source_frame)
	return _yield_cutscene_task(1, "F8 $9A0D initial background-palette fade step")


func _stage_f8_background_fade(source_frame: int) -> void:
	_f8_palette_fade_step += 1
	var background_level := maxi(0, 0x0F - _f8_palette_fade_step)
	_staged_palette = FADE_MODEL.build_palette(_base_palette, background_level, 0x0F)
	_fade_staged_source_frame = source_frame
	_staged_palette_commit_not_before_source_frame = -1
	state["fade_counters"] = Vector2i(background_level, 0x0F)
	state["palette_staged_level"] = background_level
	state["palette_staged_source_frame"] = source_frame
	state["f8_00_service"]["background_fade_steps"] = _f8_palette_fade_step
	state["f8_00_service"]["background_fade_last_source_frame"] = source_frame


func _begin_f8_title_background_loader(source_frame: int) -> bool:
	# The NMI scroll code reads the still-zero $44 while the title background
	# loader is active; it writes $FF until the ROM sets $44=$68 at loader exit.
	# `$8AF7` selects the loader target and reads its preserved record. Stage the
	# record's CHR selectors in the same modeled `$75/$76` RAM pair used by the
	# ROM; the later F8 helper copy makes them active only after loader completion.
	state["f8_title_scroll_y"] = 0xFF
	state["f8_title_scroll_source_frame"] = source_frame
	state["ram_005B_value"] = 0
	state["ram_007B_value"] = 0
	state["field_palette_override_active"] = false
	state["field_palette_override_pending"] = false
	_generic_background_loader = BACKGROUND_PACKET_LOADER.new()
	if not _generic_background_loader.build_packets(F8_TITLE_BACKGROUND_ID):
		_fail_slice("F8 $8AF7 could not decode the preserved ROM background-$17 record.")
		return false
	var raw_chr_selectors: Variant = _generic_background_loader.metadata.get("record_chr_selector_bytes", [])
	if not raw_chr_selectors is Array or raw_chr_selectors.size() != 2:
		_fail_slice("F8 $8AF7 background-$17 record did not expose its two validated CHR selector bytes.")
		return false
	var chr_selector_a := int(raw_chr_selectors[0])
	var chr_selector_b := int(raw_chr_selectors[1])
	if chr_selector_a < 0 or chr_selector_a > 0xFF or chr_selector_b < 0 or chr_selector_b > 0xFF:
		_fail_slice("F8 $8AF7 background-$17 CHR selector bytes are outside the ROM byte range.")
		return false
	if chr_selector_a != 0x7C or chr_selector_b != 0x7E:
		_fail_slice("F8 background-$17 record selectors differ from the verified `$7C/$7E` title profile.")
		return false
	state["ram_0075_value"] = chr_selector_a
	state["ram_0076_value"] = chr_selector_b
	var block_page_selector := int(_generic_background_loader.metadata.get("block_page_selector", -1))
	if block_page_selector < 0 or block_page_selector > 1:
		_fail_slice("F8 $8AF7 did not resolve the ROM-selected block page from record bit 7.")
		return false
	state["ram_005B_value"] = block_page_selector
	_generic_background_packet_index = 0
	_generic_background_committed_packets = 0
	_generic_background_committed_writes = 0
	_f8_title_loader_packets.clear()
	for packet_value in _generic_background_loader.packets:
		_f8_title_loader_packets.append(packet_value.duplicate(true))
	_f8_title_loader_packet_index = 0
	_f8_title_loader_batch_index = 0
	_f8_title_loader_capacity_yields = 0
	_f8_title_preclear_rows_staged = 0
	_f8_title_record_capacity_yields = 0
	_background_01_queue_packets.clear()
	_background_01_queue_cursor = 0
	state["shared_ppu_queue_cursor_0628"] = 0
	state["f8_00_service"]["background_selection_source_frame"] = source_frame
	state["f8_00_service"]["active_background_profile_id"] = int(state.get("background_id", -1))
	state["f8_00_service"]["active_profile_switch_source_frame"] = -1
	state["f8_00_service"]["background_loader"] = {
		"background_id": F8_TITLE_BACKGROUND_ID,
		"packet_count": _f8_title_loader_packets.size(),
		"record_chr_selector_bytes": [chr_selector_a, chr_selector_b],
		"record_chr_selector_source": {
			"record_cpu_address": str(_generic_background_loader.metadata.get("record_cpu_address", "")),
			"record_file_offset": str(_generic_background_loader.metadata.get("record_file_offset", "")),
			"record_byte_offsets": [0, 1],
			"record_values_hex": "%02X %02X" % [chr_selector_a, chr_selector_b],
			"staged_to_ram": "$0075/$0076",
			"project_owned_record": "reference/rom_extract/intro/background_17.bin",
			"source_rom_sha256": SOURCE_ROM_SHA256,
		},
		"packet_source": "ROM-selected PRG-bank-8 block page from palette-flag bit 7",
		"block_page_selector": block_page_selector,
		"block_page_offset": str(_generic_background_loader.metadata.get("block_page_offset", "0x0000")),
		"block_page_base_file_offset": str(_generic_background_loader.metadata.get("block_page_base_file_offset", "")),
		"runtime_record_producer_verified": false,
		"source_rom_live_record_producer_verified": true,
		"source_rom_live_record_producer_scope": "Original ROM F8 $17/$80 path in the silent live queue trace",
		"source_rom_selector_write_live_verified": true,
		"godot_runtime_packet_producer_verified": false,
		"runtime_block_selection_and_source_copy_verified": true,
		"live_trace_block_calls": 48,
		"live_trace_unique_block_ids": 31,
		"live_trace_ids_match_rom_record_order": true,
		"live_trace_tile_bytes_copied": 768,
		"live_trace_attribute_bytes_queued": 48,
		"live_trace_attribute_direct_path_calls": 48,
		"live_trace_attribute_merge_path_calls": 0,
		"live_trace_ppu_queue_packets": 240,
		"live_trace_packet_batches": "26 batches of 9, then 6",
		"trailer_special_mode": "$17 $80 path uses six rows/eight columns; live trace confirms all 48 requests and 240 queued packets",
		"preclear_rows": F8_TITLE_PRECLEAR_ROW_COUNT,
		"record_packets_per_batch": F8_TITLE_RECORD_PACKETS_PER_BATCH,
		"record_capacity_yields": F8_TITLE_RECORD_CAPACITY_YIELDS,
		"packet_destinations_and_order_match_capture": true,
		"payload_bytes_fully_verified_against_capture": true,
		"payload_capture_scope": "All 240 queue packets reconstructed from live $05E8-$0627 writes for the observed ROM $17/$80 run",
		"source_payload_bytes_verified_in_live_queue_trace": true,
		"ppu_commit_and_raster_composition_verified": false,
		"selected_page_snapshot_crosscheck": "815/816 title PPU payload bytes match frame 4692; the remaining byte is the expected $7F cursor overlay at $220A",
		"loader_yields": 0,
		"producer_complete": false,
	}
	_pending_handler_phase = "title_preclear"
	state["f8_00_service"]["phase"] = _pending_handler_phase
	return _stage_f8_title_preclear_row(source_frame)


func _activate_pending_f8_background_profile(source_frame: int) -> bool:
	var f8_state: Dictionary = state.get("f8_00_service", {})
	var activation_frame := int(f8_state.get("active_profile_switch_source_frame", -1))
	# The F8 service schedules one MMC3 profile change for the next source-frame
	# NMI. This is an edge, not a persistent condition: replaying an old frame
	# anchor after a later F9 selection would incorrectly restore BG17 forever.
	if activation_frame < 0 or source_frame != activation_frame:
		return true
	if int(state.get("background_id", -1)) == F8_TITLE_BACKGROUND_ID:
		return true
	if not field_screen.set_background_profile(F8_TITLE_BACKGROUND_ID):
		_fail_slice("F8 MMC3 activation could not select ROM background-$17 CHR and palette data.")
		return false
	state["background_id"] = F8_TITLE_BACKGROUND_ID
	state["background_profile_ready"] = true
	f8_state["active_background_profile_id"] = F8_TITLE_BACKGROUND_ID
	f8_state["active_profile_switch_source_frame"] = source_frame
	f8_state["active_profile_switch_basis"] = "next source-frame NMI after frame-end $8E/$8F=$7C/$7E; MMC3 R0/R1 write observed at source frame 3598"
	return true


func _stage_f8_title_preclear_row(source_frame: int) -> bool:
	if _f8_title_preclear_rows_staged >= F8_TITLE_PRECLEAR_ROW_COUNT:
		return false
	var payload := PackedByteArray()
	payload.resize(0x20)
	payload.fill(0)
	var row_index := _f8_title_preclear_rows_staged
	_background_01_queue_packets.append({
		"kind": "f8_title_preclear_row",
		"ppu_address": 0x2000 + row_index * 0x20,
		"payload": payload,
		"queue_encoded_bytes": 3 + payload.size(),
		"owner": "generic_background",
		"background_id": F8_TITLE_BACKGROUND_ID,
		"row": row_index,
	})
	_background_01_queue_cursor += 3 + payload.size()
	_f8_title_preclear_rows_staged += 1
	state["shared_ppu_queue_cursor_0628"] = _background_01_queue_cursor
	state["f8_00_service"]["background_loader"]["preclear_rows_staged"] = _f8_title_preclear_rows_staged
	state["f8_00_service"]["background_loader"]["last_preclear_stage_source_frame"] = source_frame
	return true


func _stage_f8_title_packet_batch(source_frame: int) -> bool:
	if _f8_title_loader_packet_index >= _f8_title_loader_packets.size():
		return false
	var batch_size := mini(
		F8_TITLE_RECORD_PACKETS_PER_BATCH,
		_f8_title_loader_packets.size() - _f8_title_loader_packet_index
	)
	var staged := 0
	while staged < batch_size and _f8_title_loader_packet_index < _f8_title_loader_packets.size():
		var packet: Dictionary = _f8_title_loader_packets[_f8_title_loader_packet_index].duplicate(true)
		var payload: PackedByteArray = packet["payload"]
		var encoded_size := int(packet.get("queue_encoded_bytes", 3 + payload.size()))
		if _background_01_queue_cursor + encoded_size >= F9_PPU_QUEUE_CURSOR_LIMIT:
			_fail_slice("F8 title-background packet batch exceeded the observed PPU queue capacity.")
			return false
		packet["owner"] = "generic_background"
		packet["background_id"] = F8_TITLE_BACKGROUND_ID
		_background_01_queue_packets.append(packet)
		_background_01_queue_cursor += encoded_size
		_f8_title_loader_packet_index += 1
		_generic_background_packet_index = _f8_title_loader_packet_index
		staged += 1
	_f8_title_loader_batch_index += 1
	state["shared_ppu_queue_cursor_0628"] = _background_01_queue_cursor
	state["f8_00_service"]["background_loader"]["batch_index"] = _f8_title_loader_batch_index
	state["f8_00_service"]["background_loader"]["packet_index"] = _f8_title_loader_packet_index
	state["f8_00_service"]["background_loader"]["last_batch_source_frame"] = source_frame
	return staged > 0


func _stage_f8_full_palette_rebuild(source_frame: int) -> bool:
	if not _load_f3_palette_sources():
		return false
	_staged_palette = FADE_MODEL.build_palette(_base_palette, 0x0F, 0x0F)
	_fade_staged_source_frame = source_frame
	_staged_palette_commit_not_before_source_frame = -1
	state["field_palette_override_pending"] = true
	state["fade_counters"] = Vector2i(0x0F, 0x0F)
	state["palette_staged_level"] = 0x0F
	state["palette_staged_source_frame"] = source_frame
	state["f8_00_service"]["9a35_palette_source"] = state["last_f3_palette_source"].duplicate(true)
	state["f8_00_service"]["9a35_palette_staged_source_frame"] = source_frame
	state["f8_00_service"]["88fb_oam_priority_xor"] = true
	state["oam_priority_behind_background"] = true
	_background_01_queue_cursor += 0x23
	state["shared_ppu_queue_cursor_0628"] = _background_01_queue_cursor
	return _staged_palette.size() == FADE_MODEL.PALETTE_SIZE


func _finish_f8_title_service(source_frame: int, consumed_length: int) -> void:
	var helper_completion_frame := int(_f8_helper_return_event.get(
		"service_completion_source_frame", -1))
	var dispatch_frame := int(_f8_helper_return_event.get("runtime_dispatch_frame", -1))
	if source_frame != helper_completion_frame or dispatch_frame <= source_frame:
		_fail_slice("The F8 helper-return event reached an unexpected source frame.")
		return
	# `$9B7F` fills the OAM shadow and its DMA image with hidden Y values.
	state["oam_shadow_cleared"] = true
	state["oam_y_shadow_fill"] = 0xF8
	state["oam_dma_shadow_fill"] = 0xF8
	state["oam_motion_record_cleared_addresses"] = ["$0568", "$0588", "$05A8", "$05C8"]
	state["oam_motion_record_clear_value"] = 0
	# `$98A0` disables rendering and clears $2000-$27FF; with both palette
	# counters at zero, `$98EA` then writes the 64 `$55` bytes directly.
	for address in range(0x2000, 0x2800):
		_background_01_ppu_memory[address] = 0
	for row in range(2):
		for column in range(0x20):
			_background_01_ppu_memory[0x23C0 + row * 0x20 + column] = 0x55
	_committed_palette.resize(FADE_MODEL.PALETTE_SIZE)
	_committed_palette.fill(0x0F)
	_staged_palette.clear()
	_fade_staged_source_frame = -1
	state["visual_preset"] = 1
	state["f8_00_service"]["nametable_zero_fill"] = {
		"start": "$2000", "end_exclusive": "$2800", "write_count": 2048,
		"source_helper": "$98A0", "source_bytes_verified": true,
	}
	state["f8_00_service"]["attribute_fill"] = {
		"start": "$23C0", "rows": 2, "bytes_per_row": 32,
		"value": "$55", "source_helper": "$98EA", "write_count": 64,
	}
	state["f8_00_service"]["return_a"] = "$02"
	state["f8_00_service"]["complete_source_frame"] = source_frame
	state["f8_00_service"]["helper_return_to_script"] = true
	field_screen.set_ppu_memory(_background_01_ppu_memory)
	field_screen.set_background_palette_bytes(_committed_palette.slice(0, 16))
	_apply_visual_state()
	_complete_pending_command(consumed_length)
	# The ROM-only source stepper traces the wrapper return through `$8879`, then
	# the next script dispatch and `$9FA8` compact-wait call on this frame edge.
	# Runtime consumes only the event's frame label, never modeled cycle offsets.
	state["script_dispatch_not_before_frame"] = dispatch_frame
	state["f8_helper_return_dispatch_event"] = {
		"source": F8_HELPER_RETURN_EVENT_PATH,
		"service_completion_source_frame": helper_completion_frame,
		"dispatch_source_frame": dispatch_frame,
		"script_cpu": "$A29D",
		"next_opcode": "$DF",
		"runtime_consumes_cycle_offsets": false,
	}
	# The frame-3968 RAM snapshot shows the just-dispatched $DF already at $EF,
	# so one scheduler release has elapsed by that frame edge. Preserve the
	# command's ROM-table value (240); let the scheduler account for the observed
	# first-release phase instead of shortening the script command itself.
	state["compact_pause_current_release_credit"] = true
	state["compact_pause_release_credit_basis"] = {
		"rom_helper_return_frame": helper_completion_frame,
		"next_dispatch_frame": dispatch_frame,
		"next_command_cpu": "$A29D",
		"rom_wait_value": 240,
		"observed_slot_0005_after_dispatch": "$EF",
		"ram_trace": "reference/opening_timing_capture_20261024_125300/ram_states/ram_03968.bin",
		"cycle_phase_verified": false,
	}


func _advance_f8_motion_step() -> bool:
	_f8_title_motion_step += 1
	state["ram_0079_value"] = (int(state.get("ram_0079_value", 0)) + 1) & 0xFF
	state["ram_007C_value"] = (int(state.get("ram_007C_value", F8_TITLE_PRESET_3_RAM_007C)) - 2) & 0xFF
	state["ram_0044_value"] = maxi(0x02, int(state.get("ram_0044_value", 0x68)) - 2)
	state["f8_00_service"]["motion_steps"] = _f8_title_motion_step
	state["f8_00_service"]["motion_state"] = {
		"ram_0079": state["ram_0079_value"],
		"ram_007C": state["ram_007C_value"],
		"ram_0044": state["ram_0044_value"],
	}
	return _f8_title_motion_step >= 51


func _resume_f8_motion_loop(source_frame: int) -> bool:
	if not _advance_f8_motion_step():
		return _yield_cutscene_task(1, "F8 $A4FE 51-step raster-state loop")
	state["f8_00_service"]["raster_last_active_source_frame"] = source_frame
	state["visual_preset"] = 0
	state["ram_001B_bit_01"] = true
	_pending_handler_phase = "wait_f0"
	state["f8_00_service"]["phase"] = _pending_handler_phase
	return _yield_cutscene_task(0xF0, "F8 $9FA8 delay $F0")


func _resume_f8_title_service(source_frame: int, consumed_length: int) -> bool:
	var f8_state: Dictionary = state["f8_00_service"]
	match _pending_handler_phase:
		"background_fade":
			if _f8_palette_fade_step < 15:
				_stage_f8_background_fade(source_frame)
				return _yield_cutscene_task(1, "F8 $9A0D background-palette fade")
			_pending_handler_phase = "initial_wait_16"
			f8_state["phase"] = _pending_handler_phase
			return _yield_cutscene_task(16, "F8 $9FA8 delay $10")
		"initial_wait_16":
			_pending_handler_phase = "oam_shift"
			f8_state["phase"] = _pending_handler_phase
			_f8_title_oam_shift_count = 0
			_f8_title_motion_step = 0
			state["ram_0079_value"] = int(state.get("ram_0079_value", 0))
			state["ram_007C_value"] = int(state.get("ram_007C_value", 0x80))
			# `$A4C0` performs a one-release `$9FA8($01)` wait before its first
			# `$890C` OAM-Y increment. Keep the displayed OAM shadow unchanged
			# until that source wait has elapsed.
			state["oam_y_shift_pixels"] = _f8_title_oam_shift_count
			f8_state["oam_y_shift_steps"] = _f8_title_oam_shift_count
			_apply_visual_state()
			return _yield_cutscene_task(1, "F8 $9FA8 delay $01 before first $890C OAM-Y shift")
		"oam_shift":
			var display_shift := _f8_title_oam_shift_count
			_f8_title_oam_shift_count += 1
			# The screen uses the OAM shadow copied on the previous frame edge.
			state["oam_y_shift_pixels"] = display_shift
			f8_state["oam_y_shift_steps"] = _f8_title_oam_shift_count
			_apply_visual_state()
			if _f8_title_oam_shift_count < 48:
				return _yield_cutscene_task(1, "F8 $890C OAM-Y shift %d/48" % _f8_title_oam_shift_count)
			# The final shift is the last `$A4CF` return recorded at frame 3554;
			# PC-tagged `$A4DC` and the first `$8AF7` queue work occur at frame
			# 3555. The ROM has no extra `$9FA8` wait here, so begin the loader on
			# this worker release instead of spending another source frame.
			_pending_handler_phase = "title_loader_entry"
			f8_state["phase"] = _pending_handler_phase
			f8_state["oam_shift_complete_source_frame"] = source_frame
			if not _begin_f8_title_background_loader(source_frame):
				return false
			_f8_title_loader_capacity_yields = 1
			f8_state["title_loader_capacity_yields"] = 1
			return _yield_cutscene_task(1, "F8 $9B32 preclear row reservation retry 1/15")
		"title_loader_entry":
			# Publish the final OAM-Y shadow after the one-frame display latch.
			state["oam_y_shift_pixels"] = _f8_title_oam_shift_count
			_apply_visual_state()
			if not _begin_f8_title_background_loader(source_frame):
				return false
			_f8_title_loader_capacity_yields = 1
			f8_state["title_loader_capacity_yields"] = 1
			return _yield_cutscene_task(1, "F8 $9B32 preclear row reservation retry 1/15")
		"title_preclear":
			# Frame-end RAM reaches +48 at frame 3555, while the displayed OAM value
			# remains +47 for that frame. Publish +48 on the next source frame;
			# RAM and same-input pixels support this edge, but subframe `$4014` DMA
			# timing is not present in the capture.
			if int(state.get("oam_y_shift_pixels", -1)) < _f8_title_oam_shift_count:
				state["oam_y_shift_pixels"] = _f8_title_oam_shift_count
				_apply_visual_state()
			if not _stage_f8_title_preclear_row(source_frame):
				_fail_slice("F8 title preclear exceeded its 16 traced rows.")
				return false
			if _f8_title_preclear_rows_staged < F8_TITLE_PRECLEAR_ROW_COUNT:
				_f8_title_loader_capacity_yields += 1
				f8_state["title_loader_capacity_yields"] = _f8_title_loader_capacity_yields
				return _yield_cutscene_task(1, "F8 $9B32 preclear row reservation retry %d/15" % _f8_title_loader_capacity_yields)
			_pending_handler_phase = "title_preclear_explicit_yield"
			f8_state["phase"] = _pending_handler_phase
			f8_state["title_loader_explicit_yield_frame"] = source_frame
			return _yield_cutscene_task(1, "F8 $8BB2 explicit background-loader yield")
		"title_preclear_explicit_yield":
			if not _stage_f8_title_packet_batch(source_frame):
				_fail_slice("F8 title-background loader could not stage the first record packets.")
				return false
			_f8_title_record_capacity_yields = 1
			_f8_title_loader_capacity_yields += 1
			f8_state["title_loader_capacity_yields"] = _f8_title_loader_capacity_yields
			f8_state["background_loader"]["record_batches_staged"] = _f8_title_loader_batch_index
			_pending_handler_phase = "title_record_loader"
			f8_state["phase"] = _pending_handler_phase
			return _yield_cutscene_task(1, "F8 $9B32 background-record queue retry 1/26")
		"title_record_loader":
			if _f8_title_record_capacity_yields < F8_TITLE_RECORD_CAPACITY_YIELDS:
				if not _stage_f8_title_packet_batch(source_frame):
					_fail_slice("F8 title-background record packets did not match the traced 240-packet span.")
					return false
				_f8_title_record_capacity_yields += 1
				_f8_title_loader_capacity_yields += 1
				f8_state["title_loader_capacity_yields"] = _f8_title_loader_capacity_yields
				f8_state["background_loader"]["record_capacity_yields"] = _f8_title_record_capacity_yields
				f8_state["background_loader"]["record_batches_staged"] = _f8_title_loader_batch_index
				return _yield_cutscene_task(1, "F8 $9B32 background-record queue retry %d/26" % _f8_title_record_capacity_yields)
			if not _stage_f8_title_packet_batch(source_frame):
				_fail_slice("F8 title-background loader could not stage its final partial batch.")
				return false
			f8_state["background_loader"]["producer_complete"] = true
			f8_state["background_loader"]["producer_complete_source_frame"] = source_frame
			f8_state["background_loader"]["record_batches_staged"] = _f8_title_loader_batch_index
			# The ROM sets $44 and loads preset 3 after $8AF7 returns. The record
			# selectors were staged from bytes 0/1 into $75/$76 by the validated
			# background loader; its helper copies them to $8E/$8F at this modeled
			# completion edge, then F8 copies $8E/$8F to $90/$91. Frame labels are
			# cross-checked against RAM snapshots; these store cycles are modeled,
			# not independently measured by a FCEUX PC-cycle trace.
			state["ram_0044_value"] = 0x68
			state["ram_0079_value"] = F8_TITLE_PRESET_3_RAM_0079
			state["ram_007C_value"] = F8_TITLE_PRESET_3_RAM_007C
			state["ram_007D_value"] = 0x00
			state["ram_007E_value"] = 0x01
			state["ram_007F_value"] = F8_TITLE_PRESET_3_RAM_007F
			state["ram_0080_value"] = F8_TITLE_PRESET_3_RAM_0080
			state["ram_0081_value"] = F8_TITLE_PRESET_3_RAM_0081
			state["visual_preset"] = 3
			f8_state["preset_3_loaded"] = true
			f8_state["preset_3_load_source_frame"] = source_frame
			f8_state["preset_3_rom_record"] = {
				"bank": 6,
				"cpu_address": "$BF49",
				"file_offset": "0x00DF49",
				"leading_bytes": "04 68 00 01 80 C0 21",
				"copied_to_ram": "$79,$7C-$8D",
				"source_bytes_verified": true,
			}
			var source_chr_selectors := Vector2i(
				int(state.get("ram_0075_value", -1)),
				int(state.get("ram_0076_value", -1))
			)
			var expected_record_chr_selectors: Array = f8_state.get("background_loader", {}).get(
				"record_chr_selector_bytes", []
			)
			if not expected_record_chr_selectors is Array \
					or expected_record_chr_selectors.size() != 2 \
					or source_chr_selectors.x != int(expected_record_chr_selectors[0]) \
					or source_chr_selectors.y != int(expected_record_chr_selectors[1]):
				_fail_slice("F8 selector copy source `$75/$76` no longer matches the validated background-$17 record.")
				return false
			state["ram_008E_008F"] = source_chr_selectors
			state["ram_0090_0091"] = Vector2i(
				int(source_chr_selectors.x), int(source_chr_selectors.y)
			)
			# Frame-end RAM first shows the new selector pair here; the next
			# source-frame vblank applies it through MMC3 R0/R1. Keep BG0B active
			# for the current rendered frame, then switch the visible profile.
			f8_state["active_profile_switch_source_frame"] = source_frame + 1
			f8_state["active_profile_switch_scheduled_after_source_frame"] = source_frame
			f8_state["active_profile_switch_pending_selectors"] = [source_chr_selectors.x, source_chr_selectors.y]
			f8_state["ram_0090_0091_copy"] = {
				"source": "$008E-$008F",
				"destination": "$0090-$0091",
				"source_values_hex": "%02X %02X" % [source_chr_selectors.x, source_chr_selectors.y],
				"source_values_basis": "validated project-owned background-$17 record bytes 0/1 -> $75/$76 -> $8E/$8F",
				"rom_copy_routine": "$A4EB-$A4F0",
				"frame_timing_basis": "frame-3597 RAM snapshot plus ROM-only source trace; copy cycles not independently matched PC-for-PC to FCEUX",
				"executed_source_frame": source_frame,
				"rom_operation_verified": true,
			}
			_pending_handler_phase = "post_loader_wait_04"
			f8_state["phase"] = _pending_handler_phase
			return _yield_cutscene_task(4, "F8 $9FA8 delay $04")
		"post_loader_wait_04":
			if not _stage_f8_full_palette_rebuild(source_frame):
				_fail_slice("F8 $9A35 could not rebuild the ROM-selected title palette.")
				return false
			_pending_handler_phase = "palette_commit_wait_01"
			f8_state["phase"] = _pending_handler_phase
			return _yield_cutscene_task(1, "F8 $88FB palette/OAM setup release")
		"palette_commit_wait_01":
			_pending_handler_phase = "motion_loop"
			f8_state["phase"] = _pending_handler_phase
			_f8_title_motion_step = 0
			f8_state["motion_state_origin"] = {
				"ram_0079": "$04", "ram_007C": "$68", "ram_0044": "$68",
				"basis": "ROM preset 3 at bank-6 $BF49; 51-step RAM cross-check through frame 3651",
				"first_iteration_wait_precedes_update": true,
			}
			# The `$A4FE` one-tick wait has already returned on this phase edge.
			# ROM resumes at `$A503` and executes the first `$79/$7C/$44` update
			# immediately; yielding here again would add an unsupported frame.
			return _resume_f8_motion_loop(source_frame)
		"motion_loop":
			return _resume_f8_motion_loop(source_frame)
		"wait_f0":
			_pending_handler_phase = "wait_3c"
			f8_state["phase"] = _pending_handler_phase
			return _yield_cutscene_task(0x3C, "F8 $9FA8 delay $3C")
		"wait_3c":
			state["ram_001B_bit_01"] = false
			state["ram_0090_0091"] = Vector2i(0x00, 0x02)
			_f8_palette_fade_step = 0
			# `$99F0`'s first saved return is on the frame immediately after the
			# `$3C` wait returns (source frames 3952–3966 in the traced pass).
			# Stage that first fade step now; yielding through a separate start
			# phase adds an unsupported extra frame and shifts `$FE`'s replay.
			_stage_fade_tick(source_frame)
			_f8_palette_fade_step = 1
			f8_state["paired_fade_steps"] = _f8_palette_fade_step
			f8_state["paired_fade_last_source_frame"] = source_frame
			_pending_handler_phase = "paired_palette_fade"
			f8_state["phase"] = _pending_handler_phase
			return _yield_cutscene_task(1, "F8 $99F0 paired-palette fade step 1/15")
		"paired_palette_fade":
			if _f8_palette_fade_step < 15:
				_stage_fade_tick(source_frame)
				_f8_palette_fade_step += 1
				f8_state["paired_fade_steps"] = _f8_palette_fade_step
				f8_state["paired_fade_last_source_frame"] = source_frame
				return _yield_cutscene_task(1, "F8 $99F0 paired-palette fade")
			_finish_f8_title_service(source_frame, consumed_length)
			return true
		_:
			_fail_slice("Unknown F8 00 pending phase: %s" % _pending_handler_phase)
			return false
	return false


func _resume_pending_handler() -> bool:
	var source_frame := int(state["source_frame"])
	var consumed_length := int(_pending_command["consumed_length"])
	match _pending_handler:
		"f8_title_service":
			return _resume_f8_title_service(source_frame, consumed_length)
		"f9":
			if _pending_handler_phase == "loader_wait":
				var operands: PackedByteArray = _pending_command["operands"]
				if operands.size() != 1 or int(operands[0]) != F9_BACKGROUND_00_ID:
					_fail_slice("F9 resume left the observed background-00 loader path.")
					return false
				# The saved frame-9 context is inside the four-byte block reservation:
				# $0628=$39, $0629=$04 reaches $3D and takes $9B2E's capacity wait.
				var buffer_end := F9_OBSERVED_PPU_BUFFER_INDEX + F9_OBSERVED_PPU_RESERVATION_SIZE
				if buffer_end < F9_PPU_BUFFER_CAPACITY_LIMIT:
					_fail_slice("Observed F9 buffer reservation no longer reaches the $9B2E capacity wait.")
					return false
				state["f9_capacity_wait"] = {
					"source_frame": source_frame,
					"buffer_index_0628": F9_OBSERVED_PPU_BUFFER_INDEX,
					"requested_bytes_0629": F9_OBSERVED_PPU_RESERVATION_SIZE,
					"reservation_end": buffer_end,
					"capacity_limit": F9_PPU_BUFFER_CAPACITY_LIMIT,
					"handler_entry": "$9B2E",
					"saved_return": "$9B32",
					"reservation_return": "$8F46",
					"outer_f9_return": "$8826",
					"trace_source": "reference/rom_extract/intro/f9_task_timing_trace.md",
				}
				state["f9_path_status"] = "waiting at second $9B2E one-count PPU-buffer capacity yield"
				_pending_handler_phase = "buffer_capacity_wait"
				return _yield_cutscene_task(1, "F9 background-00 $9B2E capacity wait")
			if _pending_handler_phase == "buffer_capacity_wait":
				state["f9_path_status"] = "F9 background-00 completed after second wait"
				state["f9_completed_source_frame"] = source_frame
				_complete_pending_command(consumed_length)
				return true
			_fail_slice("Unknown F9 resume phase: %s" % _pending_handler_phase)
			return false
		"f9_background_01":
			if _pending_handler_phase == "loader_initial_wait":
				_pending_handler_phase = "queue_capacity_wait"
				state["f9_background_01_loader"]["producer_status"] = "resumed after $8BB0; queue packets until $9B28 back-pressure"
				return _fill_f9_background_01_queue(source_frame)
			if _pending_handler_phase == "queue_capacity_wait":
				if not _background_01_queue_packets.is_empty():
					_fail_slice("F9 background-01 resumed before the prior NMI queue was drained.")
					return false
				return _fill_f9_background_01_queue(source_frame)
			_fail_slice("Unknown F9 background-01 resume phase: %s" % _pending_handler_phase)
			return false
		"generic_background":
			if _pending_handler_phase == "loader_initial_wait":
				_pending_handler_phase = "queue_capacity_wait"
				state["generic_background_loader"]["producer_status"] = "resumed; staging ROM-derived packets until $9B28 back-pressure"
				return _fill_generic_background_queue(source_frame)
			if _pending_handler_phase == "queue_capacity_wait":
				if not _background_01_queue_packets.is_empty() or _background_01_queue_cursor != 0:
					_fail_slice("Generic background producer resumed before its prior NMI queue drained.")
					return false
				return _fill_generic_background_queue(source_frame)
			_fail_slice("Unknown generic background loader resume phase: %s" % _pending_handler_phase)
			return false
		"f1_buffered_graphics":
			if _pending_handler_phase != "queue_capacity_wait":
				_fail_slice("Unknown buffered F1 graphics queue resume phase.")
				return false
			if not _background_01_queue_packets.is_empty() or _background_01_queue_cursor != 0:
				_fail_slice("Buffered F1 graphics resumed before the prior NMI queue drained.")
				return false
			return _fill_f1_graphics_queue(source_frame)
		"f3_palette":
			if _pending_handler_phase != "queue_capacity_wait":
				_fail_slice("Unknown F3 palette queue resume phase.")
				return false
			if not _background_01_queue_packets.is_empty() or _background_01_queue_cursor != 0:
				_fail_slice("F3 palette resumed before the prior NMI queue was drained.")
				return false
			if not _stage_f3_palette(source_frame):
				_fail_slice("Could not load the source-verified F3 00 palette records after its capacity wait.")
				return false
			_complete_pending_command(consumed_length)
			return true
		"f4_palette_sweep":
			if _pending_handler_phase == "queue_capacity_wait":
				var f4_queue_request_end := _background_01_queue_cursor + 0x20
				state["f4_palette_queue_reservation"]["queue_cursor_0628"] = _background_01_queue_cursor
				state["f4_palette_queue_reservation"]["sum"] = f4_queue_request_end
				state["f4_palette_queue_reservation"]["capacity_yield"] = f4_queue_request_end >= F9_PPU_QUEUE_CURSOR_LIMIT
				if f4_queue_request_end >= F9_PPU_QUEUE_CURSOR_LIMIT:
					return _yield_cutscene_task(1, "F4 $9B28 palette queue capacity retry")
				if not _stage_f4_palette_pass(source_frame):
					_fail_slice("Could not stage the ROM-derived F4 palette pass after queue capacity cleared.")
					return false
				_pending_handler_phase = "palette_pass_wait"
				return _yield_cutscene_task(4, "F4 palette pass 1/4 delay $04")
			if _pending_handler_phase != "palette_pass_wait":
				_fail_slice("Unknown F4 palette-sweep resume phase: %s" % _pending_handler_phase)
				return false
			var next_pass := int(state["f4_palette_sweep"]["pass_index"]) + 1
			if next_pass >= 4:
				state["f4_palette_sweep"]["pass_index"] = 4
				state["f4_palette_sweep"]["complete_source_frame"] = source_frame
				_complete_pending_command(consumed_length)
				return true
			state["f4_palette_sweep"]["pass_index"] = next_pass
			if not _stage_f4_palette_pass(source_frame):
				_fail_slice("Could not stage the next ROM-derived F4 palette pass.")
				return false
			return _yield_cutscene_task(4, "F4 palette pass %d/4 delay $04" % (next_pass + 1))
		"e9":
			if int(state.get("fade_up_counters", Vector2i.ZERO).x) == 0:
				# The source handler resumes after its initial $02 wait and enters
				# $997E, staging level 1 in source frame 12 in the sampled replay.
				if not _stage_e9_fade_up_level(source_frame):
					_fail_slice("E9 could not reload the active ROM background and sprite palettes.")
					return false
				return _yield_cutscene_task(1, "E9 fade-up pass")
			if _fade_up_level < 0x0F:
				if not _stage_e9_fade_up_level(source_frame):
					_fail_slice("E9 could not stage the next source-derived palette level.")
					return false
				return _yield_cutscene_task(1, "E9 fade-up pass")
			_fade_up_running = false
			state["fade_up_status"] = "ROM fade-up complete"
			_complete_pending_command(consumed_length)
			return true
		"compact_pause":
			_complete_pending_command(consumed_length)
			return true
		"text_glyph":
			if _pending_handler_phase == "queue_capacity_wait":
				var glyph_id := int(_pending_command["opcode"])
				if _text_glyph_queue_capacity_blocked(glyph_id):
					var retry_state: Dictionary = state.get("text_glyph_queue_capacity_wait", {})
					retry_state["retry_count"] = int(retry_state.get("retry_count", 1)) + 1
					retry_state["last_retry_cursor_0628"] = _background_01_queue_cursor
					state["text_glyph_queue_capacity_wait"] = retry_state
					return _yield_cutscene_task(1, "ROM text-glyph $9B28 PPU queue capacity retry")
				var glyph_upload_modeled := _stage_text_glyph(glyph_id, source_frame)
				state["last_text_tile"] = {
					"tile_id": glyph_id,
					"script_cpu": "$%04X" % (SCRIPT_START_CPU_ADDRESS + int(_pending_command["script_cursor"])),
					"ppu_glyph_upload_modeled": glyph_upload_modeled,
				}
				var retry_state: Dictionary = state.get("text_glyph_queue_capacity_wait", {})
				retry_state["resume_source_frame"] = source_frame
				state["text_glyph_queue_capacity_wait"] = retry_state
				var text_speed := int(state.get("text_speed", 0))
				if text_speed > 0:
					_pending_handler_phase = "text_speed_wait"
					return _yield_cutscene_task(text_speed, "ROM text tile $%02X speed wait after queue retry" % glyph_id)
				_complete_pending_command(consumed_length)
				return true
			_complete_pending_command(consumed_length)
			return true
		"fc_scene_step":
			state["fc_scene_step"]["resumed_source_frame"] = source_frame
			if bool(state.get("text_ppu_cursor_known", false)):
				var new_text_base := int(state.get("text_ppu_cursor_base_address", 0x2249)) + 0x0040
				state["text_ppu_cursor_base_address"] = new_text_base
				state["text_ppu_cursor_column"] = 0
				state["text_ppu_cursor_address"] = new_text_base
				state["ram_0053_value"] = new_text_base & 0xFF
				state["fc_scene_step"]["text_cursor_after_return"] = "$%04X" % new_text_base
			state["fc_scene_step"]["post_fc_glyph_nmi_timing_verified"] = false
			_complete_pending_command(consumed_length)
			return true
		"fd_scene_clear":
			if _pending_handler_phase == "queue_capacity_wait":
				if _fd_clear_next_row < _fd_clear_pending_rows.size():
					state["fd_scene_clear"]["queue_capacity_yields_inside_88b1"] = int(
						state["fd_scene_clear"].get("queue_capacity_yields_inside_88b1", 0)
					) + 1
					state["fd_scene_clear"]["producer_resume_staged_rows"] = _fd_clear_next_row
					return _yield_cutscene_task(1, "FD $88B1/$9B28 buffered-row capacity retry")
				_pending_handler_phase = "post_clear_wait"
				state["fd_scene_clear"]["producer_complete_source_frame"] = source_frame
				return _yield_cutscene_task(4, "FD ROM scene-clear helper delay $04 after queue producer")
			if _pending_handler_phase != "post_clear_wait":
				_fail_slice("FD scene-clear resumed in an unknown helper phase.")
				return false
			if str(state["fd_scene_clear"].get("mode_from_rom_004A_004B_gate", "")) == "buffered" \
					and not bool(state["fd_scene_clear"].get("all_rows_committed", false)):
				_fail_slice("ROM-buffered FD helper delay returned before the NMI row batches completed.")
				return false
			state["fd_scene_clear"]["resumed_source_frame"] = source_frame
			state["fd_scene_clear"]["command_complete"] = true
			# The resumed ROM path is $885D → $8887 → $84D7. After advancing
			# past FD, $84D7 copies the FD clear origin ($4F/$50) into the active
			# text base ($51/$52), then seeds the text cursor ($53) from $51.
			# The PC-tagged frame-2908 trace confirms this happens before F2/E3
			# and the first glyph at $A238. Keep this data-driven from the decoded
			# FD origin; do not tie the reset to a source-frame number.
			var text_cursor_reset_origin := int(
				state["fd_scene_clear"].get("text_cursor_reset_origin_from_004F_0050", -1)
			)
			if text_cursor_reset_origin >= 0:
				state["text_ppu_cursor_known"] = true
				state["text_ppu_cursor_base_address"] = text_cursor_reset_origin
				state["text_ppu_cursor_column"] = 0
				state["text_ppu_cursor_address"] = text_cursor_reset_origin
				state["ram_0053_value"] = text_cursor_reset_origin & 0xFF
				state["fd_scene_clear"]["text_cursor_base_after_resume"] = "$%04X" % text_cursor_reset_origin
			_complete_pending_command(consumed_length)
			return true
		"ea":
			if _fade_running:
				_stage_fade_tick(source_frame)
				return _yield_cutscene_task(1, "EA palette step")
			# The level-zero packet was committed before this NMI release. The
			# traced EA handler finishes its nametable clear before ED. The F5
			# selector remains live until the following FD scene transition.
			_apply_ea_clear_end_state(str(_pending_command.get("script_cpu", "")))
			_complete_pending_command(consumed_length)
			return true
		_:
			_fail_slice("Unknown pending cutscene handler: %s" % _pending_handler)
			return false


func _complete_pending_command(consumed_length: int) -> void:
	_script_cursor += consumed_length
	_pending_command.clear()
	_pending_handler = ""
	_pending_handler_phase = ""


func _yield_cutscene_task(
	delay: int,
	reason: String,
	current_release_already_elapsed: bool = false
) -> bool:
	state["last_scheduler_yield"] = {
		"delay": delay,
		"reason": reason,
		"source_frame": int(state["source_frame"]),
		"scheduler_tick": _scheduler.scheduler_tick,
		"current_release_already_elapsed": current_release_already_elapsed,
		"effective_delay_after_release_phase": delay - 1 if current_release_already_elapsed and delay > 0 else delay,
	}
	if not _scheduler.yield_current(delay, current_release_already_elapsed):
		_fail_slice("Could not yield the source cutscene task with delay %d." % delay)
		return false
	return false


func _make_dispatch_event(decoded: Dictionary) -> Dictionary:
	var cursor := int(decoded["script_cursor"])
	var opcode := int(decoded["opcode"])
	var consumed: PackedByteArray = decoded["consumed_bytes"]
	var byte_labels: Array[String] = []
	var byte_labels_for_text := PackedStringArray()
	for value in consumed:
		var label := "$%02X" % int(value)
		byte_labels.append(label)
		byte_labels_for_text.append(label)
	var operand_labels: Array[String] = []
	for value in decoded["operands"]:
		operand_labels.append("$%02X" % int(value))
	var cpu_address := SCRIPT_START_CPU_ADDRESS + cursor
	var file_offset := SCRIPT_START_FILE_OFFSET + cursor
	return {
		"seq": _command_sequence + 1,
		"source_frame": int(state["source_frame"]),
		"byte": "$%02X" % opcode,
		"script_cpu": "$%04X" % cpu_address,
		"rom_file_offset": "0x%06X" % file_offset,
		"consumed_bytes_array": byte_labels,
		"rom_consumed_bytes": " ".join(byte_labels_for_text),
		"operand_bytes_array": operand_labels,
		"handler_entry_pc": str(HANDLER_ENTRY_BY_OPCODE.get(opcode, "")),
	}


func _apply_source_command(opcode: int, operands: PackedByteArray, source_frame: int) -> void:
	match opcode:
		0xE8:
			state["visual_preset"] = int(operands[0])
		0xF9, 0xFA:
			state["background_id"] = int(operands[0])
			state["background_profile_ready"] = false
			state["field_palette_override_active"] = false
			state["field_palette_override_pending"] = false
		0xFB:
			var count := int(operands[0])
			var ids: Array[int] = []
			for i in range(count):
				ids.append(int(operands[i + 1]))
			state["animation_ids"] = ids
			state["oam_shadow_cleared"] = false
			state["oam_y_shift_pixels"] = 0
			state["oam_priority_behind_background"] = false
			state["animation_generation"] = int(state.get("animation_generation", 0)) + 1
			state["animation_set_source_frame"] = source_frame
		0xE9:
			if int(state.get("background_id", -1)) == F9_BACKGROUND_00_ID \
					and state.get("animation_ids", []).has(0x8D):
				if not _restore_logo_fade_palette_base(source_frame):
					return
			state["screen_enabled_command_seen"] = true
			state["fade_clear_started"] = false
			state["ea_clear_applied"] = false
			_fade_up_running = true
			_fade_up_level = 0
			state["fade_up_status"] = "E9 initial two-release delay"
			state["fade_up_source_frame"] = source_frame
			state["fade_up_counters"] = Vector2i(0, 0)
		0xEA:
			state["fade_clear_started"] = true
			_begin_ea_fade(source_frame)
		0xED:
			var sound_id := int(operands[0])
			var sounds: Array = state["sound_requests"]
			sounds.append({
				"sound_id": sound_id,
				"sound_test_ordinal": 0 if sound_id == 0x58 else -1,
				"sequence_name": "Sound 00" if sound_id == 0x58 else "unresolved",
				"source_frame": source_frame,
			})
			state["sound_requests"] = sounds
			# Preserve the raw ROM runtime cue. The verified driver's ID-minus-one
			# lookup resolves $58 to Sound 00; actual playback is not wired here.
			rom_sound_requested.emit(sound_id, source_frame)
	state["source_frame_of_last_dispatch"] = source_frame


func _compact_pause_delay(opcode: int) -> int:
	var table_index := opcode - 0xD8
	if table_index < 0 or table_index >= COMPACT_PAUSE_VALUES.size():
		return -1
	return COMPACT_PAUSE_VALUES[table_index]


func _source_script_phase_frame(source_frame: int) -> int:
	# Before the first ROM FE, the opening script phase equals the source frame.
	# Each FE establishes a new origin from its actual dispatch, then returns to
	# $A020 in that worker run. This keeps handler-table phase local to the ROM
	# loop instead of subtracting a fixed capture-measured loop period.
	var loop_origin := int(state.get("script_loop_phase_origin_source_frame", -1))
	if loop_origin < 0:
		return source_frame
	return int(state.get("script_loop_phase_origin_script_frame", _first_ready_worker_scan_source_frame)) \
		+ source_frame - loop_origin


func _begin_ea_fade(source_frame: int) -> void:
	state["fade_clear_started"] = true
	_fade_running = true
	_fade_started_source_frame = source_frame
	state["ea_fade_status"] = "ROM-derived $99F0 conversion; each $9FA8($01) release stages one palette step."
	# The sampled frame-267 end state already includes EA's first decrement.
	_stage_fade_tick(source_frame)



func _stage_e9_fade_up_level(source_frame: int) -> bool:
	if _fade_up_level == 0:
		var animation_ids: Array = state.get("animation_ids", [])
		var is_cold_start_logo := int(state.get("background_id", -1)) == F9_BACKGROUND_00_ID \
				and animation_ids.has(0x8D)
		if not is_cold_start_logo:
			# ROM `$8580` waits, then `$997E` calls `$9ADA` to reload the active
			# `$48/$49` palette selectors before staging the first fade-up packet.
			# The cold-start `$8D` logo has a separate, byte-verified palette path.
			if not _load_f3_palette_sources():
				return false
			state["e9_palette_reload_source"] = state["last_f3_palette_source"].duplicate(true)
	_fade_up_level += 1
	_staged_palette = FADE_MODEL.build_palette(_base_palette, _fade_up_level, _fade_up_level)
	if _staged_palette.size() != FADE_MODEL.PALETTE_SIZE:
		return false
	_fade_staged_source_frame = source_frame
	_staged_palette_commit_not_before_source_frame = -1
	state["fade_up_counters"] = Vector2i(_fade_up_level, _fade_up_level)
	state["fade_up_staged_source_frame"] = source_frame
	state["fade_up_status"] = "ROM level %d staged; commit on next NMI" % _fade_up_level
	state["fade_counters"] = Vector2i(_fade_up_level, _fade_up_level)
	state["palette_staged_level"] = _fade_up_level
	state["palette_staged_source_frame"] = source_frame
	return true


func _stage_fade_tick(source_frame: int) -> void:
	var levels: Vector2i = FADE_MODEL.fade_down_tick(
		int(state["fade_counters"].x), int(state["fade_counters"].y))
	state["fade_counters"] = levels
	state["palette_staged_level"] = levels.x
	_staged_palette = FADE_MODEL.build_palette(_base_palette, levels.x, levels.y)
	state["palette_staged_source_frame"] = source_frame
	_fade_staged_source_frame = source_frame
	_staged_palette_commit_not_before_source_frame = -1
	# EA uses the same $05E8 queue as the independent F5 palette stream. This
	# cursor reservation makes the effect reader's $0628+$20 capacity retry
	# observe the fade packet and stall its next record, as the ROM does.
	_background_01_queue_cursor += 0x23
	state["shared_ppu_queue_cursor_0628"] = _background_01_queue_cursor
	if not FADE_MODEL.has_fade_work(levels.x, levels.y):
		_fade_running = false


func _prepare_f5_palette_effect(source_frame: int) -> void:
	if _f5_palette_effect_model == null or not _f5_palette_effect_model.active \
			or not _f5_palette_pending_update.is_empty():
		return
	var events: Array[Dictionary] = _f5_palette_effect_model.advance_to_source_frame(source_frame)
	var effect_id := int(_f5_palette_effect_model.effect_id)
	var effect_key := _active_f5_palette_effect_state_key()
	for event in events:
		var writes: Array = event.get("writes", [])
		if writes.is_empty():
			continue
		if _base_palette.size() != FADE_MODEL.PALETTE_SIZE:
			_fail_slice("F5 palette effect ran before the ROM F3 palette was selected.")
			return
		for write_value in writes:
			if not write_value is Dictionary:
				continue
			var write: Dictionary = write_value
			var palette_index := int(write.get("palette_index", -1))
			var palette_value := int(write.get("value", -1))
			var valid_index := palette_index == 9 if effect_id == 1 else palette_index >= 13 and palette_index <= 15
			if not valid_index or palette_value < 0 or palette_value > 0x3F:
				_fail_slice("F5 effect produced a palette write outside its ROM-verified destination bytes.")
				return
			_base_palette[palette_index] = palette_value
			if effect_id == 1:
				state["ram_00633_value"] = palette_value
		_f5_palette_pending_update = event.duplicate(true)
		var effect_state: Dictionary = state.get(effect_key, {})
		effect_state["last_palette_byte_write_source_frame"] = int(event.get("source_frame", source_frame))
		if effect_id == 1:
			effect_state["last_palette_byte_write"] = "$%02X" % int(_base_palette[9])
			effect_state["ram_00633_value"] = int(_base_palette[9])
		else:
			effect_state["ram_0637_0639_hex"] = _packed_bytes_hex(_base_palette.slice(13, 16))
		effect_state["capacity_retry_pending"] = true
		effect_state["decoded_update"] = event.duplicate(true)
		state[effect_key] = effect_state
		state[effect_key + "_model"] = _f5_palette_effect_model.debug_snapshot()


func _finish_f5_palette_effect(source_frame: int) -> void:
	if _f5_palette_effect_model == null or not _f5_palette_effect_model.active:
		return
	if _f5_palette_pending_update.is_empty():
		return
	var queue_reservation_end := _background_01_queue_cursor + 0x20
	var effect_key := _active_f5_palette_effect_state_key()
	var effect_state: Dictionary = state.get(effect_key, {})
	effect_state["queue_cursor_before_9a43"] = _background_01_queue_cursor
	effect_state["queue_reservation_end"] = queue_reservation_end
	effect_state["queue_capacity_limit"] = F9_PPU_QUEUE_CURSOR_LIMIT
	effect_state["capacity_retry_pending"] = queue_reservation_end >= F9_PPU_QUEUE_CURSOR_LIMIT
	if queue_reservation_end >= F9_PPU_QUEUE_CURSOR_LIMIT:
		state[effect_key] = effect_state
		state[effect_key + "_model"] = _f5_palette_effect_model.debug_snapshot()
		return
	if _base_palette.size() != FADE_MODEL.PALETTE_SIZE:
		_fail_slice("F5 palette effect ran before the ROM F3 palette was selected.")
		return
	_staged_palette = FADE_MODEL.build_palette(_base_palette, 0x0F, 0x0F)
	if _staged_palette.size() != FADE_MODEL.PALETTE_SIZE:
		_fail_slice("F5 palette effect could not rebuild the ROM $20 00 3F palette packet.")
		return
	var effect_event_source_frame := int(_f5_palette_pending_update.get("source_frame", source_frame))
	var first_update_anchor := bool(_f5_palette_pending_update.get("first_update_phase_anchor", false))
	var commit_source_frame := source_frame + 1
	if first_update_anchor and effect_event_source_frame == source_frame:
		commit_source_frame = source_frame + 2
	_fade_staged_source_frame = source_frame
	_staged_palette_commit_not_before_source_frame = commit_source_frame
	state["field_palette_override_pending"] = true
	state["fade_counters"] = Vector2i(0x0F, 0x0F)
	state["palette_staged_level"] = 0x0F
	state["palette_staged_source_frame"] = source_frame
	_background_01_queue_cursor += 0x23
	state["shared_ppu_queue_cursor_0628"] = _background_01_queue_cursor
	if not _f5_palette_effect_model.complete_palette_packet_stage(source_frame):
		_fail_slice("F5 effect could not advance its decoded stream after $9A43 accepted the packet.")
		return
	effect_state["last_packet_stage_source_frame"] = source_frame
	effect_state["last_commit_source_frame"] = commit_source_frame
	effect_state["pending_commit_source_frame"] = commit_source_frame
	effect_state["capacity_retry_pending"] = false
	effect_state["last_delay_wait_count"] = int(_f5_palette_pending_update.get("delay_wait_count", 0))
	effect_state["first_update_phase_anchor"] = first_update_anchor
	effect_state["palette_packet_header_hex"] = "20 00 3F"
	state[effect_key] = effect_state
	_f5_palette_pending_update.clear()
	state[effect_key + "_model"] = _f5_palette_effect_model.debug_snapshot()


func _stop_f5_palette_effect(reason: String) -> void:
	if _f5_palette_effect_model == null:
		return
	_f5_palette_effect_model.stop()
	_f5_palette_pending_update.clear()
	var effect_key := _active_f5_palette_effect_state_key()
	if state.has(effect_key) and state[effect_key] is Dictionary:
		var effect_state: Dictionary = state[effect_key]
		effect_state["active"] = false
		effect_state["stop_reason"] = reason
		state[effect_key] = effect_state
		state[effect_key + "_model"] = _f5_palette_effect_model.debug_snapshot()


func _active_f5_palette_effect_state_key() -> String:
	if _f5_palette_effect_model != null and int(_f5_palette_effect_model.effect_id) == 0:
		return "f5_00_palette_effect"
	return "bg09_palette_effect"


func _packed_bytes_hex(bytes: PackedByteArray) -> String:
	var parts := PackedStringArray()
	for value in bytes:
		parts.append("%02X" % int(value))
	return " ".join(parts)


func _commit_staged_palette(source_frame: int) -> void:
	if _staged_palette.is_empty():
		return
	var natural_commit_frame := _fade_staged_source_frame + 1
	var commit_not_before := maxi(natural_commit_frame,
		_staged_palette_commit_not_before_source_frame)
	if commit_not_before < 0:
		commit_not_before = natural_commit_frame
	if source_frame < commit_not_before:
		return
	_committed_palette = _staged_palette.duplicate()
	_palette_commit_source_frame = source_frame
	state["palette_committed_level"] = state.get("palette_staged_level", 0x0F)
	state["palette_commit_source_frame"] = source_frame
	state["palette_commit_origin_source_frame"] = _fade_staged_source_frame
	state["palette_commit_status"] = "One-NMI packet transfer is modeled; exact within-frame visible pixel edge remains unresolved."
	for effect_key in ["f5_00_palette_effect", "bg09_palette_effect"]:
		if state.has(effect_key) and state[effect_key] is Dictionary:
			var effect_state: Dictionary = state[effect_key]
			if int(effect_state.get("pending_commit_source_frame", -1)) == source_frame:
				var palette_index := 13 if int(effect_state.get("effect_id", -1)) == 0 else 9
				effect_state["last_commit_source_frame"] = source_frame
				effect_state["ppu_palette_value"] = int(_committed_palette[palette_index])
				effect_state["ppu_palette_address"] = "$3F%02X" % palette_index
				effect_state["pending_commit_source_frame"] = -1
				state[effect_key] = effect_state
	if bool(state.get("field_palette_override_pending", false)):
		state["field_palette_override_active"] = true
		state["field_palette_override_pending"] = false
	_staged_palette.clear()
	_fade_staged_source_frame = -1
	_staged_palette_commit_not_before_source_frame = -1
	if _staged_text_glyph_writes.is_empty():
		_background_01_queue_cursor = 0
		state["shared_ppu_queue_cursor_0628"] = 0


func _fill_f9_background_01_queue(source_frame: int) -> bool:
	while _f9_background_01_packet_index < _f9_background_01_loader.packets.size():
		var packet: Dictionary = _f9_background_01_loader.packets[_f9_background_01_packet_index]
		var payload: PackedByteArray = packet["payload"]
		var payload_size := payload.size()
		# `$9B28` rejects a reservation when cursor + payload reaches `$3D`;
		# the three-byte header and zero terminator are included in the buffer.
		if _background_01_queue_cursor + payload_size >= F9_PPU_QUEUE_CURSOR_LIMIT:
			state["f9_background_01_loader"]["producer_status"] = "yielded at $9B28 capacity; cursor=$%02X request=$%02X" % [
				_background_01_queue_cursor, payload_size,
			]
			state["f9_background_01_loader"]["queue_cursor_0628"] = _background_01_queue_cursor
			state["f9_background_01_loader"]["pending_request_0629"] = payload_size
			state["f9_background_01_loader"]["packet_index"] = _f9_background_01_packet_index
			return _yield_cutscene_task(1, "F9 background-01 $9B28 PPU queue back-pressure")
		_background_01_queue_packets.append(packet)
		packet["owner"] = "background_01"
		_background_01_queue_cursor += int(packet["queue_encoded_bytes"])
		state["shared_ppu_queue_cursor_0628"] = _background_01_queue_cursor
		_f9_background_01_packet_index += 1
		_background_01_queued_packets += 1
		state["background_01_queued_packets"] = _background_01_queued_packets
	state["f9_background_01_loader"]["producer_status"] = "all ROM-derived packets staged; script command complete"
	state["f9_background_01_loader"]["packet_index"] = _f9_background_01_packet_index
	state["f9_background_01_loader"]["producer_complete"] = true
	state["f9_background_01_loader"]["producer_complete_source_frame"] = source_frame
	_complete_pending_command(int(_pending_command["consumed_length"]))
	return true


func _commit_background_01_queue(source_frame: int) -> void:
	if _background_01_queue_packets.is_empty():
		return
	var committed_packet_count := 0
	var committed_write_count := 0
	var generic_packet_count := 0
	var generic_write_count := 0
	var f1_packet_count := 0
	var f1_write_count := 0
	var fd_packet_count := 0
	var fd_write_count := 0
	var f1_final_record_committed := false
	for packet in _background_01_queue_packets:
		var address := int(packet["ppu_address"])
		var payload: PackedByteArray = packet["payload"]
		var packet_owner := str(packet.get("owner", ""))
		if packet_owner.is_empty():
			var packet_background_id := int(packet.get("background_id", F9_BACKGROUND_01_ID))
			packet_owner = "background_01" if packet_background_id == F9_BACKGROUND_01_ID else "generic_background"
		var write_stride := int(packet.get("increment", 1)) if packet_owner == "f1_graphics" else 1
		for payload_index in range(payload.size()):
			_background_01_ppu_memory[address + payload_index * write_stride] = int(payload[payload_index])
			if packet_owner == "background_01":
				committed_write_count += 1
			elif packet_owner == "f1_graphics":
				f1_write_count += 1
			elif packet_owner == "fd_scene_clear":
				fd_write_count += 1
			else:
				generic_write_count += 1
		if packet_owner == "background_01":
			committed_packet_count += 1
		elif packet_owner == "f1_graphics":
			f1_packet_count += 1
			if bool(packet.get("final", false)):
				f1_final_record_committed = true
		elif packet_owner == "fd_scene_clear":
			fd_packet_count += 1
		else:
			generic_packet_count += 1
	_background_01_committed_packets += committed_packet_count
	_background_01_committed_writes += committed_write_count
	_generic_background_committed_packets += generic_packet_count
	_generic_background_committed_writes += generic_write_count
	_f1_graphics_committed_packets += f1_packet_count
	_f1_graphics_committed_writes += f1_write_count
	_fd_clear_committed_rows += fd_packet_count
	_fd_clear_committed_writes += fd_write_count
	state["background_01_committed_packets"] = _background_01_committed_packets
	state["background_01_committed_ppu_writes"] = _background_01_committed_writes
	state["background_01_queued_packets"] = _background_01_queued_packets
	if committed_packet_count > 0:
		state["background_01_last_commit_packet_count"] = committed_packet_count
		state["background_01_last_commit_ppu_write_count"] = committed_write_count
		state["background_01_last_commit_source_frame"] = source_frame
	if generic_packet_count > 0 and state.has("generic_background_loader"):
		state["generic_background_loader"]["committed_packets"] = _generic_background_committed_packets
		state["generic_background_loader"]["committed_ppu_writes"] = _generic_background_committed_writes
		state["generic_background_loader"]["last_commit_source_frame"] = source_frame
	if f1_packet_count > 0 and state.has("f1_01_loader"):
		state["f1_01_loader"]["committed_packets"] = _f1_graphics_committed_packets
		state["f1_01_loader"]["committed_ppu_writes"] = _f1_graphics_committed_writes
		state["f1_01_loader"]["last_commit_source_frame"] = source_frame
	if f1_final_record_committed and state.has("f1_01_setup"):
		state["f1_01_setup"]["selected_draw_data_applied"] = true
		state["f1_01_setup"]["selected_draw_data_commit_source_frame"] = source_frame
	if fd_packet_count > 0 and state.has("fd_scene_clear"):
		state["fd_scene_clear"]["committed_rows"] = _fd_clear_committed_rows
		state["fd_scene_clear"]["committed_ppu_writes"] = _fd_clear_committed_writes
		state["fd_scene_clear"]["last_nmi_commit_source_frame"] = source_frame
	if committed_packet_count > 0 and state.has("f9_background_01_loader"):
		state["f9_background_01_loader"]["committed_packets"] = _background_01_committed_packets
		state["f9_background_01_loader"]["committed_ppu_writes"] = _background_01_committed_writes
	field_screen.set_ppu_memory(_background_01_ppu_memory)
	if committed_packet_count > 0 and _background_01_committed_writes == 1088:
		state["background_01_ppu_bytes_complete"] = true
		state["f9_background_01_loader"]["ppu_committed"] = true
		state["f9_background_01_loader"]["ppu_commit_source_frame"] = source_frame
		state["f9_background_01_loader"]["complete"] = true
	_background_01_queue_packets.clear()
	_background_01_queue_cursor = 0
	state["shared_ppu_queue_cursor_0628"] = 0


func _stage_fd_clear_queue(source_frame: int) -> void:
	while _fd_clear_next_row < _fd_clear_pending_rows.size():
		var packet: Dictionary = _fd_clear_pending_rows[_fd_clear_next_row].duplicate(true)
		var payload: PackedByteArray = packet["payload"]
		if _background_01_queue_cursor + payload.size() >= F9_PPU_QUEUE_CURSOR_LIMIT:
			break
		packet["owner"] = "fd_scene_clear"
		_background_01_queue_packets.append(packet)
		_background_01_queue_cursor += int(packet["queue_encoded_bytes"])
		_fd_clear_next_row += 1
	state["shared_ppu_queue_cursor_0628"] = _background_01_queue_cursor
	state["fd_scene_clear"]["queued_rows_total"] = _fd_clear_next_row
	state["fd_scene_clear"]["producer_complete"] = _fd_clear_next_row >= _fd_clear_pending_rows.size()
	state["fd_scene_clear"]["producer_source_frame"] = source_frame


func _pump_fd_clear_queue(source_frame: int) -> void:
	if not _fd_clear_active or not _background_01_queue_packets.is_empty():
		return
	if _fd_clear_next_row >= _fd_clear_pending_rows.size():
		_fd_clear_active = false
		state["fd_scene_clear"]["all_rows_committed"] = _fd_clear_committed_rows == _fd_clear_pending_rows.size()
		return
	_stage_fd_clear_queue(source_frame)


func _fill_generic_background_queue(source_frame: int) -> bool:
	if _generic_background_loader == null:
		_fail_slice("Generic background producer has no ROM packet loader.")
		return false
	while _generic_background_packet_index < _generic_background_loader.packets.size():
		var packet: Dictionary = _generic_background_loader.packets[_generic_background_packet_index].duplicate(true)
		var payload: PackedByteArray = packet["payload"]
		if _background_01_queue_cursor + payload.size() >= F9_PPU_QUEUE_CURSOR_LIMIT:
			if _background_01_queue_packets.is_empty():
				_fail_slice("Generic background packet exceeds the observed PPU queue capacity.")
				return false
			state["generic_background_loader"]["producer_status"] = "yielded at $9B28 capacity; cursor=$%02X request=$%02X" % [
				_background_01_queue_cursor, payload.size(),
			]
			state["generic_background_loader"]["packet_index"] = _generic_background_packet_index
			state["generic_background_loader"]["queue_cursor_0628"] = _background_01_queue_cursor
			state["generic_background_loader"]["pending_request_0629"] = payload.size()
			return _yield_cutscene_task(1, "Generic background $9B28 PPU queue back-pressure")
		packet["background_id"] = int(state["generic_background_loader"]["background_id"])
		packet["owner"] = "generic_background"
		_background_01_queue_packets.append(packet)
		_background_01_queue_cursor += int(packet["queue_encoded_bytes"])
		state["shared_ppu_queue_cursor_0628"] = _background_01_queue_cursor
		_generic_background_packet_index += 1
	state["generic_background_loader"]["producer_status"] = "all ROM-derived packets staged; script command complete"
	state["generic_background_loader"]["producer_complete"] = true
	state["generic_background_loader"]["producer_complete_source_frame"] = source_frame
	state["generic_background_loader"]["packet_index"] = _generic_background_packet_index
	if int(state["generic_background_loader"].get("background_id", -1)) == 0x0A \
			and _bg0a_raster_model != null:
		if not _bg0a_raster_model.activate_camera_after_background_load(source_frame):
			_fail_slice("Could not start ROM BG0A camera after its source background load: " + _bg0a_raster_model.last_error)
			return false
		state["bg0a_raster_model"] = _bg0a_raster_model.debug_snapshot(source_frame)
	if int(state["generic_background_loader"].get("background_id", -1)) == 0x0B \
			and _bg0b_camera_model != null:
		if not _bg0b_camera_model.activate_after_background_load(source_frame):
			_fail_slice("Could not start ROM BG0B camera after its background load: " + _bg0b_camera_model.last_error)
			return false
		state["bg0b_camera_model"] = _bg0b_camera_model.debug_snapshot(source_frame)
	if int(state["generic_background_loader"].get("background_id", -1)) == 0x07 \
			and _bg07_camera_model != null:
		if not _bg07_camera_model.activate_after_background_load(source_frame):
			_fail_slice("Could not start ROM BG07 camera after its source background load: " + _bg07_camera_model.last_error)
			return false
		state["bg07_camera_model"] = _bg07_camera_model.debug_snapshot(source_frame)
	if int(state["generic_background_loader"].get("background_id", -1)) == 0x03 \
			and _bg03_camera_model != null:
		if not _bg03_camera_model.activate_after_background_load(source_frame):
			_fail_slice("Could not start ROM BG03 camera after its source background load: " + _bg03_camera_model.last_error)
			return false
		state["bg03_camera_model"] = _bg03_camera_model.debug_snapshot(source_frame)
	if int(state["generic_background_loader"].get("background_id", -1)) == 0x08 \
			and _bg08_raster_model != null:
		var loaded_pair: Array[int] = []
		for selector_value in state.get("bg08_loaded_pair_target", []):
			loaded_pair.append(int(selector_value))
		if not _bg08_raster_model.set_background_pair_transition(loaded_pair, source_frame + 1):
			_fail_slice("Could not schedule the ROM BG08 CHR-pair commit after its background load.")
			return false
		state["bg08_raster_model"]["background_pair_commit_source_frame"] = source_frame + 1
	_complete_pending_command(int(_pending_command["consumed_length"]))
	return true


func _apply_f1_direct_graphics(source_frame: int) -> void:
	var committed_records: Array[Dictionary] = []
	var write_count := 0
	for packet_value in _f1_graphics_loader.packets:
		var packet: Dictionary = packet_value
		var start_address := int(packet["ppu_address"])
		var increment := int(packet["increment"])
		var payload: PackedByteArray = packet["payload"]
		for payload_index in range(payload.size()):
			_background_01_ppu_memory[start_address + payload_index * increment] = int(payload[payload_index])
			write_count += 1
		committed_records.append({
			"record_index": int(packet["record_index"]),
			"ppu_address": "$%04X" % start_address,
			"increment": increment,
			"write_count": payload.size(),
			"source_file_offset": str(packet["source_file_offset"]),
		})
	_f1_graphics_committed_packets += committed_records.size()
	_f1_graphics_committed_writes += write_count
	state["f1_01_direct_draw"] = {
		"source_frame": source_frame,
		"path": "direct_ppudata",
		"record_count": committed_records.size(),
		"ppu_write_count": write_count,
		"records": committed_records,
		"subdot_visibility_measured": false,
	}
	state["f1_01_graphics_committed_packets"] = _f1_graphics_committed_packets
	state["f1_01_graphics_committed_ppu_writes"] = _f1_graphics_committed_writes
	field_screen.set_ppu_memory(_background_01_ppu_memory)


func _fill_f1_graphics_queue(source_frame: int) -> bool:
	while _f1_graphics_packet_index < _f1_graphics_pending_packets.size():
		var packet: Dictionary = _f1_graphics_pending_packets[_f1_graphics_packet_index].duplicate(true)
		var payload: PackedByteArray = packet["payload"]
		if _background_01_queue_cursor + payload.size() >= F9_PPU_QUEUE_CURSOR_LIMIT:
			if _background_01_queue_packets.is_empty():
				_fail_slice("Buffered F1 graphics packet exceeds the observed PPU queue capacity.")
				return false
			state["f1_01_loader"]["producer_status"] = "yielded at $9B28 capacity; cursor=$%02X request=$%02X" % [
				_background_01_queue_cursor, payload.size(),
			]
			state["f1_01_loader"]["queue_cursor_0628"] = _background_01_queue_cursor
			state["f1_01_loader"]["packet_index"] = _f1_graphics_packet_index
			return _yield_cutscene_task(1, "Buffered F1 graphics $9B28 PPU queue back-pressure")
		packet["owner"] = "f1_graphics"
		_background_01_queue_packets.append(packet)
		_background_01_queue_cursor += int(packet.get("queue_encoded_bytes", 3 + payload.size()))
		state["shared_ppu_queue_cursor_0628"] = _background_01_queue_cursor
		_f1_graphics_packet_index += 1
	state["f1_01_loader"]["producer_status"] = "all clear and ROM table packets staged"
	state["f1_01_loader"]["producer_complete"] = true
	state["f1_01_loader"]["producer_complete_source_frame"] = source_frame
	state["f1_01_loader"]["packet_index"] = _f1_graphics_packet_index
	_complete_pending_command(int(_pending_command["consumed_length"]))
	return true


func _stage_text_glyph(tile_id: int, source_frame: int) -> bool:
	if not bool(state.get("text_ppu_cursor_known", false)):
		return false
	var cursor_base := int(state.get("text_ppu_cursor_base_address", -1))
	var text_column := int(state.get("text_ppu_cursor_column", 0))
	var top_address := cursor_base + text_column
	if top_address < 0x2000 or top_address >= 0x2400:
		state["text_ppu_cursor_known"] = false
		return false
	var writes := [
		{"ppu_address": top_address, "value": 0x00},
		{"ppu_address": top_address + 0x20, "value": tile_id},
	]
	for write in writes:
		_staged_text_glyph_writes.append({
			"ppu_address": int(write["ppu_address"]),
			"value": int(write["value"]),
			"tile_id": tile_id,
			"stage_source_frame": source_frame,
		})
	state["text_ppu_cursor_column"] = text_column + 1
	state["text_ppu_cursor_address"] = cursor_base + text_column + 1
	state["ram_0053_value"] = (cursor_base + text_column + 1) & 0xFF
	_background_01_queue_cursor += 5 # 3-byte $82/address header + two-byte glyph payload.
	state["shared_ppu_queue_cursor_0628"] = _background_01_queue_cursor
	state["last_text_glyph_queue_packet"] = {
		"header_hex": "82 %02X %02X" % [top_address & 0xFF, (top_address >> 8) & 0xFF],
		"payload_hex": "00 %02X" % tile_id,
		"ppu_increment": 32,
		"writes": writes,
		"stage_source_frame": source_frame,
		"nmi_commit_source_frame": source_frame + 1,
	}
	return true


func _text_glyph_queue_capacity_blocked(tile_id: int) -> bool:
	# `$88CA` uses `$82` for the observed direct `$00–$9F` glyph path. `$9B28`
	# checks the requested two-byte payload before writing its five-byte record.
	if tile_id > 0x9F or not bool(state.get("text_ppu_cursor_known", false)):
		return false
	var cursor_base := int(state.get("text_ppu_cursor_base_address", -1))
	var text_column := int(state.get("text_ppu_cursor_column", 0))
	var top_address := cursor_base + text_column
	if top_address < 0x2000 or top_address >= 0x2400:
		return false
	return _background_01_queue_cursor + 2 >= F9_PPU_QUEUE_CURSOR_LIMIT


func _commit_staged_text_glyph(source_frame: int) -> void:
	if _staged_text_glyph_writes.is_empty():
		return
	var committed_writes: Array[Dictionary] = []
	for write in _staged_text_glyph_writes:
		var address := int(write["ppu_address"])
		var value := int(write["value"])
		_background_01_ppu_memory[address] = value
		committed_writes.append({
			"ppu_address": "$%04X" % address,
			"value": "$%02X" % value,
		})
	state["last_text_glyph_nmi_commit"] = {
		"source_frame": source_frame,
		"writes": committed_writes,
		"ppu_pixel_edge_measured": false,
	}
	state["text_glyph_committed_ppu_writes"] = int(state.get("text_glyph_committed_ppu_writes", 0)) + committed_writes.size()
	_staged_text_glyph_writes.clear()
	_background_01_queue_cursor = 0
	state["shared_ppu_queue_cursor_0628"] = 0
	field_screen.set_ppu_memory(_background_01_ppu_memory)


func _apply_rom_ppu_zero_fill(start_address: int, row_count: int, row_width: int,
		row_stride: int, source_frame: int, source_command: String) -> void:
	var write_count := 0
	for row in range(row_count):
		var row_address := start_address + row * row_stride
		for column in range(row_width):
			_background_01_ppu_memory[row_address + column] = 0
			write_count += 1
	state["last_rom_ppu_zero_fill"] = {
		"command": source_command,
		"start_address": "$%04X" % start_address,
		"rows": row_count,
		"bytes_per_row": row_width,
		"row_stride": row_stride,
		"write_count": write_count,
		"source_frame": source_frame,
		"source_bytes_verified": true,
		"within_frame_bus_timing_modeled": false,
	}
	field_screen.set_ppu_memory(_background_01_ppu_memory)


func _apply_ea_clear_end_state(source_script_cpu: String = "") -> void:
	# EA's traced $98E8 loops zero 16 rows at $2000 and 32 rows at $2400 after $99F0.
	# Palette level zero also maps every source color to NES black ($0F).
	var zero_fill_addresses: PackedInt32Array = FADE_MODEL.confirmed_ea_zero_fill_addresses()
	for address in zero_fill_addresses:
		_background_01_ppu_memory[int(address)] = 0
	_committed_palette = PackedByteArray()
	_committed_palette.resize(FADE_MODEL.PALETTE_SIZE)
	_committed_palette.fill(0x0F)
	state["ea_clear_applied"] = true
	state["rom_global_scroll_state_reset"] = {
		"ram_address": "$007B",
		"value": 0,
		"source_opcode": "$EA",
		"source_script_cpu": source_script_cpu,
		"handler_cpu": "$858D",
		"source_frame": int(state["source_frame"]),
		"rom_write_cpu": "$85B5",
		"rom_write_file_offset": "0x0005C5",
		"rom_write_bytes": "85 7B",
		"trace_source": "reference/diagnostics/bg0b_ea_scroll_reset_20261025/README.md",
	}
	state["ea_clear_zero_fill_addresses"] = zero_fill_addresses
	state["ea_clear_zero_fill_write_count"] = zero_fill_addresses.size()
	state["ea_clear_within_frame_bus_timing_modeled"] = false
	state["palette_committed_level"] = 0
	state["palette_commit_source_frame"] = int(state["source_frame"])
	state["palette_commit_status"] = "Frame-282 end-state is black; final palette/clear pixel ordering is not scanline-verified."
	field_screen.set_ppu_memory(_background_01_ppu_memory)


func _apply_visual_state() -> void:
	var frame := int(state.get("source_frame", 0))
	# NMI writes $4014=$02 from the game's OAM DMA path. The visible frame uses
	# the OAM shadow copied before the current source-frame gameplay update, so
	# delay the sprite presentation sample by one frame without shifting command
	# dispatch, animation-source, or motion-record timestamps.
	var animation_display_source_frame := frame - OAM_DISPLAY_LATCH_SOURCE_FRAMES
	_release_latched_animation_nodes(frame)
	var active_background_id := int(state.get("background_id", -1))
	var has_background := active_background_id == F9_BACKGROUND_00_ID
	var has_field_background := active_background_id > F9_BACKGROUND_00_ID \
			and bool(state.get("background_profile_ready", false))
	var sprites_behind_background := bool(state.get("oam_priority_display_latched",
		state.get("oam_priority_behind_background", false)))
	var animation_ids: Array = state.get("animation_ids", [])
	var animation_generation := int(state.get("animation_generation", -1))
	if animation_generation != _rendered_animation_generation:
		_replace_active_animation_nodes(animation_ids, frame)
		_rendered_animation_generation = animation_generation
		_animation_set_start_source_frame = int(state.get("animation_set_source_frame", frame))
		_animation_last_source_frame = frame
	if animation_display_source_frame > _animation_last_source_frame:
		for _tick in range(animation_display_source_frame - _animation_last_source_frame):
			for animation_node in _animation_nodes:
				animation_node.advance_source_tick()
		_animation_last_source_frame = animation_display_source_frame
	if _bg08_sprite_oam_composer != null:
		if animation_display_source_frame >= _animation_set_start_source_frame \
				and not _bg08_sprite_oam_composer.advance_to_source_frame(animation_display_source_frame):
			_fail_slice("Could not advance ROM BG08 shared OAM compositor: " + _bg08_sprite_oam_composer.last_error)
			return
		_bg08_sprite_oam_composer.position = Vector2(0.0, float(state.get("oam_y_shift_pixels", 0)))
		_bg08_sprite_oam_composer.z_index = 0
		_bg08_sprite_oam_composer.visible = active_background_id == 0x08 \
				and animation_ids.has(0xC1) and animation_ids.has(0x82) \
				and animation_display_source_frame >= _animation_set_start_source_frame \
				and not bool(state.get("oam_shadow_cleared", false))
	var has_runner_animation := animation_ids.has(0x6E)
	var first_visible_frame := int(state.get("first_visible_source_frame", 13))
	var ppu_visible := frame >= first_visible_frame
	var logo_scene_active := has_background and ppu_visible \
			and bool(state.get("screen_enabled_command_seen", false)) \
			and not bool(state.get("ea_clear_applied", false))
	background.visible = logo_scene_active
	field_screen.visible = has_field_background
	field_screen.set_sprites_behind_background(sprites_behind_background)
	field_screen.z_index = 1 if sprites_behind_background else 0
	for animation_node in _animation_nodes:
		animation_node.z_index = 0
		animation_node.position = Vector2(0.0, float(state.get("oam_y_shift_pixels", 0)))
		var sprite_x_motion_offset := 0
		var camera_follow_x_wrap_marker := false
		if active_background_id == 0x03 \
				and (animation_node.animation_id == "0x75" \
					or animation_node.animation_id == "0x77") \
				and _bg03_camera_model != null:
			var bg03_camera_state: Dictionary = _bg03_camera_model.frame_state(animation_display_source_frame)
			if bool(bg03_camera_state.get("active", false)):
				sprite_x_motion_offset = int(bg03_camera_state.get("sprite_x_cumulative_offset", 0))
				camera_follow_x_wrap_marker = true
			state["bg03_sprite_x_motion"] = {
				"kind": "rom_worker_inverse_camera_step",
				"animation_id": animation_node.animation_id,
				"display_source_frame": animation_display_source_frame,
				"camera_ram_007a": int(bg03_camera_state.get("ram_007a", 0)),
				"sprite_x_delta_pixels": int(bg03_camera_state.get("sprite_x_delta_pixels", 0)),
				"accumulated_x_offset": sprite_x_motion_offset,
				"camera_follow_x_wrap_marker_active": camera_follow_x_wrap_marker,
				"oam_y_hidden_attribute_mask": 0x0C,
				"trace_source": "reference/diagnostics/bg03_camera_oam_transform_20261025/README.md",
				"source_oam_anchor_frames": [2147, 2148, 2149, 2150, 2151],
			}
		if active_background_id == 0x0B \
				and animation_node.animation_id == "0x7C" \
				and _bg0b_camera_model != null:
			camera_follow_x_wrap_marker = true
			if _bg0b_sprite_motion_set_start_source_frame != _animation_set_start_source_frame:
				_bg0b_sprite_x_motion_offset = 0
				_bg0b_sprite_last_motion_source_frame = _animation_set_start_source_frame - 1
				_bg0b_sprite_motion_set_start_source_frame = _animation_set_start_source_frame
			while _bg0b_sprite_last_motion_source_frame < animation_display_source_frame:
				var next_motion_frame := _bg0b_sprite_last_motion_source_frame + 1
				var bg0b_camera_state: Dictionary = _bg0b_camera_model.frame_state(next_motion_frame)
				if not bool(bg0b_camera_state.get("active", false)):
					break
				_bg0b_sprite_x_motion_offset += int(bg0b_camera_state.get("sprite_x_delta_pixels", 0))
				_bg0b_sprite_last_motion_source_frame = next_motion_frame
			sprite_x_motion_offset = _bg0b_sprite_x_motion_offset
			var bg0b_camera_state: Dictionary = _bg0b_camera_model.frame_state(animation_display_source_frame)
			state["bg0b_sprite_x_motion"] = {
				"kind": "rom_worker_inverse_camera_step",
				"display_source_frame": animation_display_source_frame,
				"camera_ram_0047_step_pixels": int(bg0b_camera_state.get("ram_0047_step_pixels", 0)),
				"sprite_x_delta_pixels": int(bg0b_camera_state.get("sprite_x_delta_pixels", 0)),
				"accumulated_x_offset": sprite_x_motion_offset,
				"motion_started_at_animation_set_frame": _bg0b_sprite_motion_set_start_source_frame,
				"camera_follow_x_wrap_marker_active": camera_follow_x_wrap_marker,
				"oam_y_hidden_attribute_mask": 0x0C,
				"validated_oam_checkpoints": [2694, 2700, 2710, 2713, 2714, 2715, 2720, 2722],
				"trace_source": BG0B_CAMERA_VISIBLE_PHASE_TRACE,
				"dot_level_oam_copy_timing_verified": false,
			}
		if active_background_id == 0x07 \
				and animation_node.animation_id == "0x76" \
				and _bg07_camera_model != null:
			camera_follow_x_wrap_marker = true
			var bg07_camera_state: Dictionary = _bg07_camera_model.frame_state(animation_display_source_frame)
			if bool(bg07_camera_state.get("active", false)):
				sprite_x_motion_offset = int(bg07_camera_state.get("sprite_x_cumulative_offset", 0))
			state["bg07_sprite_x_motion"] = {
				"kind": "rom_worker_inverse_camera_step",
				"camera_ram_0047_step_pixels": int(bg07_camera_state.get("ram_0047_step_pixels", 0)),
				"sprite_x_delta_pixels": int(bg07_camera_state.get("sprite_x_delta_pixels", 0)),
				"accumulated_x_offset": sprite_x_motion_offset,
				"camera_follow_x_wrap_marker_active": camera_follow_x_wrap_marker,
				"oam_y_hidden_attribute_mask": 0x0C,
				"trace_source": "reference/rom_extract/intro/bg07_portrait_oam_trace_20261025.md",
				"dot_level_oam_copy_timing_verified": false,
			}
		animation_node.set_origin_x_motion_offset(sprite_x_motion_offset)
		animation_node.set_camera_follow_x_wrap_marker_active(camera_follow_x_wrap_marker)
		animation_node.visible = _animation_node_visible(
			animation_node.animation_id, animation_display_source_frame, active_background_id)
	if active_background_id == F9_BACKGROUND_01_ID and has_runner_animation:
		if not _runner_animation_started:
			_runner_motion_record = RUNNER_MOTION_RECORD_SCRIPT.new()
			if not _runner_motion_record.configure(_animation_set_start_source_frame):
				_fail_slice("Could not initialize ROM runner motion record: " + _runner_motion_record.last_error)
				return
			_runner_animation_started = true
			state["runner_motion_model"] = {
				"animation_id": "0x6E",
				"start_source_frame": _animation_set_start_source_frame,
				"position_model": "16-byte motion record: ROM F1/F7 setup and $975B source-order integration",
				"f7_to_live_motion_record_bridge_verified": true,
				"oam_overflow_culling": "unwrapped 9-bit OAM origin; entries carrying $04/$08 are hidden in DMA with Y=$F8",
				"oam_overflow_trace_source": "reference/diagnostics/field_runner_oam_palette_fetch_audit_20261024.md",
				"overflow_marker_writer_instruction_traced": false,
				"trace_source": "reference/rom_extract/intro/runner_motion_live_bridge.md",
			}
		if _runner_motion_record == null:
			_fail_slice("Could not initialize ROM runner motion record for the OAM display latch.")
			return
		if animation_display_source_frame >= _animation_set_start_source_frame \
				and not _runner_motion_record.advance_to_source_frame(animation_display_source_frame):
			var motion_error := "runner motion record could not advance"
			if not _runner_motion_record.last_error.is_empty():
				motion_error = _runner_motion_record.last_error
			_fail_slice("Could not advance ROM runner motion record: " + motion_error)
			return
		state["runner_motion_model"]["current_record"] = _runner_motion_record.snapshot()
		state["runner_motion_model"]["display_source_frame"] = animation_display_source_frame
		for animation_node in _animation_nodes:
			if animation_node.animation_id == "0x6E" \
					and animation_display_source_frame >= _animation_set_start_source_frame:
				animation_node.set_origin_override(_runner_motion_record.screen_x(), 60)
				animation_node.set_source_oam_origin_unwrapped(
					_runner_motion_record.oam_x_unwrapped_pixels(),
					_runner_motion_record.oam_y_unwrapped_pixels())
	else:
		_runner_animation_started = false
		_runner_motion_record = null
	var has_a2_animation := animation_ids.has(0xA2)
	if has_a2_animation:
		if not _a2_animation_started:
			_a2_motion_record = RUNNER_MOTION_RECORD_SCRIPT.new()
			if not _a2_motion_record.configure_a2(_animation_set_start_source_frame):
				_fail_slice("Could not initialize ROM A2 motion record: " + _a2_motion_record.last_error)
				return
			_a2_animation_started = true
			state["a2_motion_model"] = {
				"animation_id": "0xA2",
				"start_source_frame": _animation_set_start_source_frame,
				"position_model": "F1/F7 record from bank-10 `$A50E` and bank-0 `$975B` source-order integration",
				"motion_record_ram_snapshot_anchor": "$0588 at source frame 2367",
				"oam_shadow_range": "$04A8-$04CB",
				"cpu_ram_dma_source_range": "$0240-$0263",
				"oam_overflow_culling": "source Q8.8 doubled coordinates retain bit 8 as attr $04/$08; marked sprites use DMA Y=$F8",
				"culling_trace_source": "reference/rom_extract/intro/a2_oam_dma_culling_trace_20261025.md",
				"trace_source": "reference/rom_extract/intro/a2_motion_record_trace_20261025.md",
			}
		if _a2_motion_record == null:
			_fail_slice("Could not initialize ROM A2 motion record for the OAM display latch.")
			return
		if animation_display_source_frame >= _animation_set_start_source_frame \
				and not _a2_motion_record.advance_to_source_frame(animation_display_source_frame):
			var a2_motion_error := "A2 motion record could not advance"
			if not _a2_motion_record.last_error.is_empty():
				a2_motion_error = _a2_motion_record.last_error
			_fail_slice("Could not advance ROM A2 motion record: " + a2_motion_error)
			return
		state["a2_motion_model"]["current_record"] = _a2_motion_record.snapshot()
		state["a2_motion_model"]["display_source_frame"] = animation_display_source_frame
		state["a2_motion_model"]["oam_origin_unwrapped_pixels"] = [
			_a2_motion_record.oam_x_unwrapped_pixels(),
			_a2_motion_record.oam_y_unwrapped_pixels(),
		]
		for animation_node in _animation_nodes:
			if animation_node.animation_id == "0xA2" \
					and animation_display_source_frame >= _animation_set_start_source_frame:
				animation_node.set_origin_override(
					_a2_motion_record.screen_x(), _a2_motion_record.screen_y())
				animation_node.set_source_oam_origin_unwrapped(
					_a2_motion_record.oam_x_unwrapped_pixels(),
					_a2_motion_record.oam_y_unwrapped_pixels())
	else:
		_a2_animation_started = false
		_a2_motion_record = null
	var has_7d_animation := animation_ids.has(0x7D)
	if has_7d_animation:
		if not _7d_animation_started:
			_7d_motion_record = RUNNER_MOTION_RECORD_SCRIPT.new()
			if not _7d_motion_record.configure_7d(_animation_set_start_source_frame):
				_fail_slice("Could not initialize ROM 7D motion record: " + _7d_motion_record.last_error)
				return
			_7d_animation_started = true
			state["7d_motion_model"] = {
				"animation_id": "0x7D",
				"start_source_frame": _animation_set_start_source_frame,
				"position_model": "F1/F7 record from bank-10 `$A1CA` and bank-0 `$975B` source-order integration",
				"motion_record_ram_snapshot_anchor": "$05A8 at source frame 2367",
				"oam_shadow_range": "$04CC onward (entry 25)",
				"trace_source": "reference/diagnostics/opening_runtime_full_chunks_20261025_161258/foreground_7d_motion_gap.md",
			}
	if _7d_motion_record == null and has_7d_animation:
		_fail_slice("Could not initialize ROM 7D motion record for the OAM display latch.")
		return
	if _7d_motion_record != null and not has_7d_animation:
		_7d_animation_started = false
		_7d_motion_record = null
	elif has_7d_animation:
		if animation_display_source_frame >= _animation_set_start_source_frame \
				and not _7d_motion_record.advance_to_source_frame(animation_display_source_frame):
			var seven_d_motion_error := "7D motion record could not advance"
			if not _7d_motion_record.last_error.is_empty():
				seven_d_motion_error = _7d_motion_record.last_error
			_fail_slice("Could not advance ROM 7D motion record: " + seven_d_motion_error)
			return
		state["7d_motion_model"]["current_record"] = _7d_motion_record.snapshot()
		state["7d_motion_model"]["display_source_frame"] = animation_display_source_frame
		state["7d_motion_model"]["oam_origin_unwrapped_pixels"] = [
			_7d_motion_record.oam_x_unwrapped_pixels(),
			_7d_motion_record.oam_y_unwrapped_pixels(),
		]
		for animation_node in _animation_nodes:
			if animation_node.animation_id == "0x7D" \
					and animation_display_source_frame >= _animation_set_start_source_frame:
				animation_node.set_origin_override(
					_7d_motion_record.screen_x(), _7d_motion_record.screen_y())
	# F8 $0A installs the verified field-runner raster producer. Its preset and
	# delta bytes describe BG01 only; do not carry those scroll/address events
	# into BG08 dialogue or the separate F8 title IRQ path.
	var has_field_runner_raster := active_background_id == F9_BACKGROUND_01_ID \
			and has_runner_animation
	var f8_state: Dictionary = state.get("f8_00_service", {})
	var has_f8_title_raster := active_background_id == F8_TITLE_BACKGROUND_ID \
			and bool(f8_state.get("preset_3_loaded", false)) \
			and (str(f8_state.get("phase", "")) == "motion_loop" \
				or (str(f8_state.get("phase", "")) == "wait_f0" \
					and frame <= int(f8_state.get("raster_last_active_source_frame", -1))))
	var raster_events: Array[Dictionary] = []
	if active_background_id == 0x03 and _bg03_camera_model != null:
		# BG03 `$A086-$A091` samples the preceding camera-worker state for its
		# first-row `$2005` value. Its shared IRQ path reloads `$2200`, resets
		# scroll, and selects lower R0/R1 at the same line-129/130 boundary traced
		# for the related BG0A/BG09 scenes.
		var camera_ppu_state: Dictionary = _bg03_camera_model.frame_state(frame - 1)
		var camera_active := bool(camera_ppu_state.get("active", false))
		var camera_scroll_x := int(camera_ppu_state.get("ram_007a", 0)) if camera_active else 0
		var camera_page_bit := int(camera_ppu_state.get("ppu_nametable_x_bit",
			int(camera_ppu_state.get("ram_007b", 0)) & 0x01)) if camera_active else 0
		var ppuctrl := 0x88 | camera_page_bit
		field_screen.set_scroll_pixels(0, 0)
		raster_events.append({
			"kind": "scroll",
			"scanline": 0,
			"scroll_x": camera_scroll_x,
			"control_nametable_bit": camera_page_bit,
			"ppuctrl_nametable_bit_observed": camera_page_bit,
			"control_value": ppuctrl,
			"scroll_y_base": 0xFF,
			"source_pc": "$A086-$A091",
			"camera_ram_source_frame": frame - 1,
		})
		raster_events.append({
			"kind": "ppu_address",
			"scanline": 129,
			"address": 0x2200,
			"source_pc": "$A160-$A178",
		})
		raster_events.append({
			"kind": "scroll",
			"scanline": 130,
			"scroll_x": 0,
			"control_nametable_bit": 0,
			"source_pc": "$A182-$A18A",
		})
		var lower_chr_writes: Array[Dictionary] = [
			{"scanline": 130, "dot": 0, "register": 0, "value": 0x00,
				"source_pc": "$A1D4/$A1D7", "phase_verified": false},
			{"scanline": 130, "dot": 0, "register": 1, "value": 0x02,
				"source_pc": "$A1E0/$A1E3", "phase_verified": false},
		]
		var initial_bg03_selectors: Array[int] = [0x3A, 0x00]
		if not field_screen.set_source_mmc3_chr_writes(initial_bg03_selectors, lower_chr_writes):
			_fail_slice("Could not apply ROM BG03's source-derived lower CHR pair.")
			return
		state["bg03_raster_model"] = {
			"source": "BG03 camera RAM + shared `$A160-$A1E3` IRQ handler",
			"camera_ram_source_frame": frame - 1,
			"scroll_x": camera_scroll_x,
			"ram_007b": int(camera_ppu_state.get("ram_007b", 0)),
			"ppu_nametable_x_bit": camera_page_bit,
			"ppuctrl": ppuctrl,
			"ppu_address_reload_scanline_candidate": 129,
			"lower_scroll_scanline_candidate": 130,
			"initial_chr_2k_selectors": [0x3A, 0x00],
			"lower_chr_2k_selectors": [0x00, 0x02],
			"lower_chr_write_dot_verified": false,
			"trace_source": "reference/diagnostics/bg03_camera_oam_transform_20261025/README.md",
		}
	elif has_field_runner_raster and _raster_event_generator != null:
		if not _raster_event_generator.advance_to_source_frame(frame):
			_fail_slice("Could not advance ROM raster-event generator: " + _raster_event_generator.last_error)
			return
		raster_events = _raster_event_generator.raster_events()
		state["runner_raster_event_model"] = _raster_event_generator.debug_snapshot()
	elif active_background_id == 0x08 and _bg08_raster_model != null:
		if not _bg08_raster_model.advance_to_source_frame(frame):
			_fail_slice("Could not advance ROM BG08 raster model: " + _bg08_raster_model.last_error)
			return
		var bg08_frame_state: Dictionary = _bg08_raster_model.frame_state()
		var initial_selectors: Array[int] = []
		for selector_value in bg08_frame_state.get("initial_2k_selectors", []):
			initial_selectors.append(int(selector_value))
		var bg08_chr_writes: Array[Dictionary] = bg08_frame_state.get("chr_writes", [])
		if not field_screen.set_source_mmc3_chr_writes(initial_selectors, bg08_chr_writes):
			_fail_slice("Could not apply ROM BG08 MMC3 CHR write state.")
			return
		raster_events = bg08_frame_state.get("ppu_events", [])
		state["bg08_raster_model"] = _bg08_raster_model.debug_snapshot()
	elif active_background_id == 0x0A and _bg0a_raster_model != null:
		var bg0a_frame_state: Dictionary = _bg0a_raster_model.frame_state(frame)
		if not bool(bg0a_frame_state.get("active", false)):
			_fail_slice("Could not advance ROM BG0A raster state: " + str(bg0a_frame_state.get("reason", "unknown state")))
			return
		# BG0A's raw `$2000=$89` and `$2005` values are retained by the model.
		# The raw `$2000=$89` and `$2005=$7A,$FF` writes stay in model metadata.
		# Neither starting-axis offset is enabled until the two-page/vertical
		# mapping is reconciled with ROM packet writes and first-line fetches.
		# Keep base X at zero to avoid applying `$7A` twice.
		field_screen.set_scroll_pixels(0,
				int(bg0a_frame_state["renderer_initial_scroll_y_candidate"]))
		var bg0a_initial_selectors: Array[int] = []
		for selector_value in bg0a_frame_state.get("initial_2k_chr_selectors", []):
			bg0a_initial_selectors.append(int(selector_value))
		var bg0a_chr_writes: Array[Dictionary] = bg0a_frame_state.get("chr_writes", [])
		if not field_screen.set_source_mmc3_chr_writes(bg0a_initial_selectors, bg0a_chr_writes):
			_fail_slice("Could not apply ROM BG0A's source-derived lower CHR pair.")
			return
		raster_events = bg0a_frame_state.get("ppu_events", [])
		state["bg0a_raster_model"] = bg0a_frame_state
	elif active_background_id == 0x0B and _bg0b_camera_model != null:
		# BG0B's `$A086-$A091` setup samples the preceding worker state for the
		# first-row PPUCTRL/PPUSCROLL values. Captured bytes at 2700/2710/2715/
		# 2721 match camera state at 2699/2709/2714/2720 respectively.
		var camera_ppu_state: Dictionary = _bg0b_camera_model.frame_state(frame - 1)
		var camera_active := bool(camera_ppu_state.get("active", false))
		var camera_scroll_x := int(camera_ppu_state.get("ram_007a", 0)) if camera_active else 0
		var camera_page_bit := 1 if camera_active \
				and int(camera_ppu_state.get("ram_007b", 0)) == 0xFF else 0
		var camera_page_bit_source := "camera worker RAM $007B at source frame %d" % (frame - 1)
		var global_scroll_reset: Dictionary = state.get("rom_global_scroll_state_reset", {})
		var scroll_reset_source_frame := int(global_scroll_reset.get("source_frame", -1))
		if not global_scroll_reset.is_empty() and frame - 1 >= scroll_reset_source_frame:
			camera_page_bit = int(global_scroll_reset.get("value", 0)) & 0x01
			camera_page_bit_source = "EA clear completion reset $007B at source frame %d" % scroll_reset_source_frame
		var ppuctrl := 0x88 | camera_page_bit
		raster_events.append({
			"kind": "scroll",
			"scanline": 0,
			"scroll_x": camera_scroll_x,
			"control_nametable_bit": camera_page_bit,
			"ppuctrl_nametable_bit_observed": camera_page_bit,
			"control_value": ppuctrl,
			"scroll_y_base": 0xFF,
			"source_pc": "$A086-$A091",
		})
		raster_events.append({
			"kind": "ppu_address",
			"scanline": 129,
			"address": 0x2200,
			"source_pc": "$A178-$A17B",
		})
		raster_events.append({
			"kind": "scroll",
			"scanline": 130,
			"scroll_x": 0,
			"control_nametable_bit": 0,
			"source_pc": "$A182-$A18A",
		})
		state["bg0b_raster_model"] = {
			"active": camera_active,
			"source": "ROM `$A086-$A091` camera scroll latch and `$A178-$A18A` split",
			"camera_state_source_frame": frame - 1,
			"scroll_x": camera_scroll_x,
			"ppuctrl": ppuctrl,
			"ram_007b_from_camera_worker": int(camera_ppu_state.get("ram_007b", 0)),
			"camera_page_bit": camera_page_bit,
			"camera_page_bit_source": camera_page_bit_source,
			"global_scroll_reset": global_scroll_reset.duplicate(true),
			"ppu_address_reload_scanline": 129,
			"lower_scroll_scanline": 130,
			"chr_profile_source": "BG0B renderer ROM record plus shared `$A160` IRQ handler",
			"trace_source": "reference/opening_timing_capture_20261024_125300/bus_events.csv",
		}
	elif active_background_id == BG07_BACKGROUND_ID and _bg07_camera_model != null:
		# BG07's `$A086-$A091` vblank setup latches the camera byte from the
		# preceding worker update into PPUCTRL/PPUSCROLL. The one-frame delay is
		# visible in the trace: source frame 1548 writes `$89,$AA,$FF`, matching
		# camera state at 1547; frame 1550 writes `$89,$9B,$FF`, matching 1549.
		var camera_ppu_state: Dictionary = _bg07_camera_model.frame_state(frame - 1)
		var camera_active := bool(camera_ppu_state.get("active", false))
		var camera_scroll_x := int(camera_ppu_state.get("ram_007a", 0)) if camera_active else 0
		var camera_page_bit := 1 if camera_active \
				and int(camera_ppu_state.get("ram_007b", 0)) == 0xFF else 0
		var ppuctrl := 0x88 | camera_page_bit
		var bg07_chr_writes: Array[Dictionary] = [
			{
				"scanline": 130,
				"dot": 146,
				"register": 0,
				"value": 0x00,
				"source_pc": "$A1D4/$A1D7",
				"phase_verified": false,
			},
			{
				"scanline": 130,
				"dot": 197,
				"register": 1,
				"value": 0x02,
				"source_pc": "$A1E0/$A1E3",
				"phase_verified": false,
			},
		]
		var bg07_initial_chr_selectors: Array[int] = [0x3A, 0x00]
		if not field_screen.set_source_mmc3_chr_writes(bg07_initial_chr_selectors, bg07_chr_writes):
			_fail_slice("Could not apply ROM BG07's source-derived lower CHR pair.")
			return
		raster_events.append({
			"kind": "scroll",
			"scanline": 0,
			"scroll_x": camera_scroll_x,
			"control_nametable_bit": camera_page_bit,
			"ppuctrl_nametable_bit_observed": camera_page_bit,
			"control_value": ppuctrl,
			"scroll_y_base": 0xFF,
			"source_pc": "$A086-$A091",
		})
		raster_events.append({
			"kind": "ppu_address",
			"scanline": 129,
			"address": 0x2200,
			"source_pc": "$A178-$A17B",
		})
		raster_events.append({
			"kind": "scroll",
			"scanline": 130,
			"scroll_x": 0,
			"control_nametable_bit": 0,
			"source_pc": "$A182-$A18A",
		})
		state["bg07_raster_model"] = {
			"active": camera_active,
			"source": "ROM `$A086-$A091` camera scroll latch and `$A178-$A18A` split",
			"camera_state_source_frame": frame - 1,
			"scroll_x": camera_scroll_x,
			"ppuctrl": ppuctrl,
			"ppu_address_reload_scanline": 129,
			"lower_scroll_scanline": 130,
			"initial_chr_selectors": [0x3A, 0x00],
			"lower_chr_selectors": [0x00, 0x02],
			"chr_write_dot_phase_verified": false,
			"trace_source": "reference/opening_timing_capture_20261024_125300/bus_events.csv",
		}
	elif has_f8_title_raster:
		var ram_0079 := int(state.get("ram_0079_value", F8_TITLE_PRESET_3_RAM_0079))
		var ram_007C := int(state.get("ram_007C_value", F8_TITLE_PRESET_3_RAM_007C))
		var motion_steps := int(f8_state.get("motion_steps", 0))
		# Source-frame advances begin at PPU line 240. The palette commit runs
		# after the presenter increments the source frame and before that frame's
		# scheduler/NMI work, so the synchronized IRQ restart belongs to this same
		# rendered source frame.
		var palette_upload_committed_this_frame := int(state.get("palette_commit_source_frame", -1)) == frame
		var timing_model: Dictionary = F8_TITLE_IRQ_TIMING_MODEL.calculate(
			ram_0079, ram_007C, motion_steps, palette_upload_committed_this_frame)
		var first_irq_scanline := int(timing_model["first_irq_scanline"])
		var ppu_address_write_scanline := int(timing_model["ppu_address_write_scanline"])
		if first_irq_scanline >= 0 \
				and first_irq_scanline < RomPpuNametableScreenRenderer.SCREEN_HEIGHT:
			raster_events.append({
				"kind": "scroll",
				"scanline": first_irq_scanline,
				"scroll_x": 0,
				"control_nametable_bit": 1,
			})
		if ppu_address_write_scanline >= 0 \
				and ppu_address_write_scanline < RomPpuNametableScreenRenderer.SCREEN_HEIGHT:
			raster_events.append({
				"kind": "ppu_address",
				"scanline": ppu_address_write_scanline,
				"address": 0x21C0,
			})
		state["f8_title_raster_model"] = {
			"active": true,
			"source": "ROM preset 3, bank-2 IRQ handler, MMC3 counter and PPU timing",
			"preset_file_offset": "0x00DF49",
			"ram_0079": ram_0079,
			"ram_007C": ram_007C,
			"motion_steps": motion_steps,
			"palette_upload_committed_this_frame": palette_upload_committed_this_frame,
			"first_irq_scanline": first_irq_scanline,
			"counter_reload_scanline": int(timing_model["counter_reload_scanline"]),
			"counter_marker_before_loop_tick": int(timing_model["counter_marker_before_loop_tick"]),
			"counter_latch": int(timing_model["counter_latch"]),
			"completed_loop_decrements_before_reload": int(timing_model["completed_loop_decrements_before_reload"]),
			"ppu_address_write_scanline": ppu_address_write_scanline,
			"irq_handler_to_address_write_cpu_cycles": int(timing_model["irq_handler_to_address_write_cpu_cycles"]),
			"ppu_reload_address": "$21C0",
			"ppu_scroll_y": int(state.get("f8_title_scroll_y", 0)),
			"comparison_basis": "ROM-derived MMC3 scanline model; renderer applies the register write at that scanline boundary",
			"absolute_irq_scanline_verified": bool(timing_model["initial_irq_phase_verified"]),
			"irq_to_write_dot_phase_verified": bool(timing_model["irq_to_write_dot_phase_verified"]),
			"first_affected_pixel_phase_verified": false,
			"model_basis": str(timing_model["model_basis"]),
			"trace_source": "reference/rom_extract/intro/f8_00_sequence_trace.md",
		}
	else:
		state["f8_title_raster_model"] = {
			"active": false,
			"reason": "F8 preset-3 motion-loop IRQ is not active.",
		}
	if active_background_id == F8_TITLE_BACKGROUND_ID:
		field_screen.set_scroll_pixels(0, int(state.get("f8_title_scroll_y", 0)))
	var subframe_ppu_writes: Array[Dictionary] = []
	if _source_ppu_write_timeline != null:
		subframe_ppu_writes = _source_ppu_write_timeline.writes_for_source_frame(frame)
	state["source_ppu_register_writes"] = subframe_ppu_writes
	field_screen.set_source_raster_events(raster_events)
	if not has_field_runner_raster and _raster_event_generator != null:
		state["runner_raster_event_model"] = {
			"active": false,
			"source_profile": "BG01 field runner only",
			"current_background_id": active_background_id,
			"reason": "The BG01 preset/delta model is not the active scene raster source.",
		}
	_apply_palette_to_renderers()
	_sync_ppu_backdrop_color()
	_apply_shared_oam_scanline_evaluation()


func _replace_active_animation_nodes(animation_ids: Array, source_frame: int) -> void:
	if not _animation_nodes.is_empty() or _bg08_sprite_oam_composer != null:
		# Preserve the just-rendered OAM image through this displayed frame.
		# The new ROM animation set becomes visible on the next frame edge.
		_latched_animation_nodes.append_array(_animation_nodes)
		if _bg08_sprite_oam_composer != null:
			_latched_bg08_sprite_oam_composers.append(_bg08_sprite_oam_composer)
			_bg08_sprite_oam_composer = null
		_latched_animation_nodes_release_frame = source_frame + OAM_DISPLAY_LATCH_SOURCE_FRAMES
	_animation_nodes.clear()
	_runner_animation_started = false
	_runner_motion_record = null
	_a2_animation_started = false
	_a2_motion_record = null
	_7d_animation_started = false
	_7d_motion_record = null
	_bg0b_sprite_x_motion_offset = 0
	_bg0b_sprite_last_motion_source_frame = -1
	_bg0b_sprite_motion_set_start_source_frame = -1
	if animation_ids.size() == 2 and int(animation_ids[0]) == 0xC1 \
			and int(animation_ids[1]) == 0x82:
		_bg08_sprite_oam_composer = BG08_SPRITE_OAM_COMPOSER_SCRIPT.new()
		_bg08_sprite_oam_composer.name = "RomBg08SharedSpriteOam"
		_bg08_sprite_oam_composer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_bg08_sprite_oam_composer.set_render_updates_suppressed(_capture_render_updates_suppressed)
		add_child(_bg08_sprite_oam_composer)
		if not _bg08_sprite_oam_composer.configure(animation_ids, source_frame):
			_fail_slice("Could not initialize ROM BG08 shared OAM compositor: " + _bg08_sprite_oam_composer.last_error)
			return
		_animation_set_start_source_frame = source_frame
		_animation_last_source_frame = source_frame
		return
	# Earlier FB entries receive lower OAM indices and render in front. Godot
	# draws later siblings over earlier ones, so create the ROM list in reverse.
	var nodes_by_fb_order: Dictionary = {}
	for animation_index in range(animation_ids.size() - 1, -1, -1):
		var animation_id := int(animation_ids[animation_index])
		var animation_node: RomSpriteAnimationPrototype = SPRITE_ANIMATION_SCRIPT.new()
		animation_node.name = "RomAnimation_%02X_%d" % [animation_id, animation_index]
		animation_node.animation_id = "0x%02X" % animation_id
		animation_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		animation_node.set_render_updates_suppressed(_capture_render_updates_suppressed)
		add_child(animation_node)
		animation_node.reset_source_timeline()
		_animation_nodes.append(animation_node)
		nodes_by_fb_order[animation_index] = animation_node
	var next_oam_slot := 0
	for animation_index in animation_ids.size():
		var animation_node: RomSpriteAnimationPrototype = nodes_by_fb_order[animation_index]
		animation_node.set_source_oam_allocation(next_oam_slot, animation_index)
		next_oam_slot += animation_node.source_oam_slot_extent()
	_animation_set_start_source_frame = source_frame
	_animation_last_source_frame = source_frame


func _apply_shared_oam_scanline_evaluation() -> void:
	if _animation_nodes.is_empty():
		return
	_oam_scanline_evaluation_revision += 1
	var nodes_by_order := _animation_nodes.duplicate()
	nodes_by_order.sort_custom(
		func(a: RomSpriteAnimationPrototype, b: RomSpriteAnimationPrototype) -> bool:
			return a.source_oam_allocation_order() < b.source_oam_allocation_order())
	var entries_by_slot: Dictionary = {}
	for animation_node in nodes_by_order:
		if not is_instance_valid(animation_node) or not animation_node.visible:
			continue
		for entry in animation_node.source_oam_evaluation_entries():
			# FB objects reserve cumulative OAM ranges in list order. If a later
			# allocation wraps and writes a slot again, its source entry wins.
			entries_by_slot[int(entry["slot"])] = entry
	var candidates_by_row := PackedInt32Array()
	candidates_by_row.resize(240)
	candidates_by_row.fill(0)
	var visibility_by_slot: Dictionary = {}
	for slot in range(64):
		if not entries_by_slot.has(slot):
			continue
		var entry: Dictionary = entries_by_slot[slot]
		var first_row := int(entry["first_visible_row"])
		var rows := PackedByteArray()
		rows.resize(240)
		rows.fill(0)
		var fetch_slots := PackedByteArray()
		fetch_slots.resize(240)
		fetch_slots.fill(0xFF)
		for row in range(maxi(0, first_row), mini(240, first_row + 8)):
			if candidates_by_row[row] >= 8:
				continue
			rows[row] = 1
			fetch_slots[row] = candidates_by_row[row]
			candidates_by_row[row] += 1
		visibility_by_slot[slot] = {
			"owner_instance_id": int(entry["owner_instance_id"]),
			"sprite_index": int(entry["sprite_index"]),
			"rows": rows,
			"fetch_slots": fetch_slots,
			"plane1_bytes_by_source_row": {},
			"plane1_override_events_by_source_row": {},
		}
	_apply_source_timed_shared_address_sprite_fetches(entries_by_slot, visibility_by_slot)
	for animation_node in _animation_nodes:
		if is_instance_valid(animation_node):
			animation_node.set_shared_oam_scanline_visibility(
				visibility_by_slot, _oam_scanline_evaluation_revision)
	for animation_node in _latched_animation_nodes:
		if is_instance_valid(animation_node):
			animation_node.set_shared_oam_scanline_visibility(
				visibility_by_slot, _oam_scanline_evaluation_revision)


func _apply_source_timed_shared_address_sprite_fetches(entries_by_slot: Dictionary,
		visibility_by_slot: Dictionary) -> void:
	## A real `$2006` low-byte store updates shared RefreshAddr. If it lands on a
	## sprite's plane-1 read dot, FCEUX NewPPU reads RefreshAddr+8 through the
	## full PPU bus address. In this slice the resulting `$21xx/$22xx` address
	## selects nametable RAM, not CHR. Event dots are produced by the ROM-only
	## CPU/MMC3 timeline; captures are validation data only.
	var writes_variant: Variant = state.get("source_ppu_register_writes", [])
	if not writes_variant is Array or writes_variant.size() < 2:
		return
	var high_write: Dictionary = writes_variant[0]
	var low_write: Dictionary = writes_variant[1]
	if str(high_write.get("source_pc", "")) != "$A175" \
			or str(low_write.get("source_pc", "")) != "$A178":
		return
	var high_value := int(high_write.get("value", 0)) & 0x3F
	var low_value := int(low_write.get("value", 0)) & 0xFF
	var full_ppu_address := (((high_value << 8) | low_value) + 8) & 0x3FFF
	var event_scanline := int(low_write.get("scanline", -1))
	var event_dot := int(low_write.get("dot", -1))
	if event_scanline < 0 or event_scanline >= 240 or event_dot < 0:
		return
	var plane1_byte := field_screen.read_nametable_ppu_byte(full_ppu_address)
	if plane1_byte < 0:
		return
	for slot in range(64):
		if not entries_by_slot.has(slot) or not visibility_by_slot.has(slot):
			continue
		var entry: Dictionary = entries_by_slot[slot]
		var rule: Dictionary = visibility_by_slot[slot]
		var fetch_slots: PackedByteArray = rule.get("fetch_slots", PackedByteArray())
		if event_scanline >= fetch_slots.size() or fetch_slots[event_scanline] == 0xFF:
			continue
		var fetch_slot := int(fetch_slots[event_scanline])
		var plane1_fetch_dot := SPRITE_FETCH_PLANE1_FIRST_DOT \
				+ fetch_slot * SPRITE_FETCH_SLOT_DOT_STRIDE
		if event_dot != plane1_fetch_dot:
			continue
		var source_row := event_scanline - int(entry["first_visible_row"])
		if source_row < 0 or source_row >= 8:
			continue
		var plane1_overrides: Dictionary = rule.get("plane1_bytes_by_source_row", {})
		plane1_overrides[source_row] = plane1_byte
		rule["plane1_bytes_by_source_row"] = plane1_overrides
		var override_events: Dictionary = rule.get("plane1_override_events_by_source_row", {})
		override_events[source_row] = {
			"source_frame": int(state.get("source_frame", -1)),
			"source_pc": "$A178",
			"cpu_cycle": int(low_write.get("cpu_cycle", -1)),
			"scanline": event_scanline,
			"dot": event_dot,
			"ppu_address": full_ppu_address,
			"fetch_slot": fetch_slot,
			"nametable_byte": plane1_byte,
		}
		rule["plane1_override_events_by_source_row"] = override_events


func _release_latched_animation_nodes(source_frame: int) -> void:
	if _latched_animation_nodes.is_empty() \
			or source_frame < _latched_animation_nodes_release_frame:
		return
	for animation_node in _latched_animation_nodes:
		if is_instance_valid(animation_node):
			remove_child(animation_node)
			animation_node.queue_free()
	for composer in _latched_bg08_sprite_oam_composers:
		if is_instance_valid(composer):
			remove_child(composer)
			composer.queue_free()
	_latched_animation_nodes.clear()
	_latched_bg08_sprite_oam_composers.clear()
	_latched_animation_nodes_release_frame = -1


func _animation_node_visible(animation_id: String, source_frame: int, active_background_id: int) -> bool:
	if bool(state.get("oam_shadow_cleared", false)):
		return false
	# The animation clock here already uses the previous OAM shadow frame.
	# Compare its displayed edge, not the underlying animation tick: otherwise
	# the first logo sprite stays hidden one extra frame after the PPU reveal.
	if source_frame + OAM_DISPLAY_LATCH_SOURCE_FRAMES \
			< int(state.get("first_visible_source_frame", 13)):
		return false
	if source_frame < _animation_set_start_source_frame:
		return false
	if animation_id == "0x8D":
		return active_background_id == F9_BACKGROUND_00_ID \
				and bool(state.get("screen_enabled_command_seen", false)) \
				and not bool(state.get("ea_clear_applied", false))
	if animation_id == "0x6E":
		return active_background_id == F9_BACKGROUND_01_ID and source_frame >= RUNNER_SOURCE_START_FRAME
	return true


func _apply_palette_to_renderers() -> void:
	if _committed_palette.size() != FADE_MODEL.PALETTE_SIZE:
		return
	background.set_fade_palette_bytes(_committed_palette.slice(0, FADE_MODEL.PALETTE_GROUP_SIZE))
	var sprite_palette := _committed_palette.slice(FADE_MODEL.PALETTE_GROUP_SIZE, FADE_MODEL.PALETTE_SIZE)
	for animation_node in _animation_nodes:
		animation_node.set_fade_palette_bytes(sprite_palette)
	if _bg08_sprite_oam_composer != null:
		_bg08_sprite_oam_composer.set_fade_palette_bytes(sprite_palette)
	# A background profile supplies ROM layout/CHR metadata, not the palette
	# currently visible in PPU memory. Keep the renderer on the committed PPU
	# palette until the queued ROM palette packet reaches its NMI commit.
	field_screen.set_background_palette_bytes(_committed_palette.slice(0, FADE_MODEL.PALETTE_GROUP_SIZE))


func _sync_ppu_backdrop_color() -> void:
	if _nes_rgb_palette.size() != 192 or not is_instance_valid(power_on_backdrop):
		return
	# Cold start first outputs PPU universal color $00 (gray in the documented
	# FCEUX hardware palette). The frame-8 `$05E8` packet is 32 bytes of `$0F`;
	# the NMI consumer at `$A03C` commits it during source frame 9. Later palette
	# commits use the source-presenter's staged ROM-derived palette.
	var source_frame := int(state.get("source_frame", 0))
	var color_index := 0x00
	if source_frame >= _initial_black_palette_commit_source_frame:
		color_index = 0x0F
	if int(state.get("palette_commit_source_frame", -1)) >= 0 \
			and _committed_palette.size() >= FADE_MODEL.PALETTE_SIZE:
		color_index = int(_committed_palette[0]) & 0x3F
	var rgb_offset := color_index * 3
	power_on_backdrop.color = Color(
		float(_nes_rgb_palette[rgb_offset]) / 255.0,
		float(_nes_rgb_palette[rgb_offset + 1]) / 255.0,
		float(_nes_rgb_palette[rgb_offset + 2]) / 255.0,
		1.0)


func _load_f3_palette_sources() -> bool:
	var background_id := int(state.get("background_id", -1))
	var background_layout_path := "res://reference/rom_extract/intro/background_%02X_layout.json" % background_id
	if background_id < 0 or not FileAccess.file_exists(background_layout_path):
		return false
	var background_layout_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(background_layout_path))
	if not background_layout_value is Dictionary:
		return false
	var background_layout: Dictionary = background_layout_value
	if str(background_layout.get("rom_sha256", "")) != SOURCE_ROM_SHA256:
		return false
	var background_palette_index := int(background_layout.get("palette_index", -1))
	var palette_flag := _parse_hex_byte(str(background_layout.get("palette_flag_byte", "")))
	if background_palette_index < 0 or palette_flag < 0 or (palette_flag & 0x3F) != background_palette_index:
		return false
	var background_palette_path := "res://" + str(background_layout.get("palette_source_bin", ""))
	var background_palette := FileAccess.get_file_as_bytes(background_palette_path)
	var expected_background_palette := _parse_hex_bytes(str(background_layout.get("palette_raw_hex", "")))
	if background_palette.size() != 16 or background_palette != expected_background_palette:
		return false

	var animation_ids: Array = state.get("animation_ids", [])
	if animation_ids.is_empty():
		return false
	var animation_id := int(animation_ids[animation_ids.size() - 1])
	var header_metadata_value: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(F3_ANIMATION_PALETTE_HEADERS_PATH))
	var table_metadata_value: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(F3_SPRITE_PALETTE_TABLE_METADATA_PATH))
	if not header_metadata_value is Dictionary or not table_metadata_value is Dictionary:
		return false
	var header_metadata: Dictionary = header_metadata_value
	var table_metadata: Dictionary = table_metadata_value
	if str(header_metadata.get("rom_sha256", "")) != SOURCE_ROM_SHA256 \
			or str(table_metadata.get("rom_sha256", "")) != SOURCE_ROM_SHA256:
		return false
	var animation_entry: Dictionary = _find_animation_palette_header(header_metadata, animation_id)
	var animation_path := "res://reference/rom_extract/intro/animation_%02X.bin" % animation_id
	var animation_bytes := FileAccess.get_file_as_bytes(animation_path)
	if animation_bytes.is_empty():
		return false
	var sprite_palette_index := -1
	var sprite_palette := PackedByteArray()
	var sprite_palette_file_offset := ""
	if not animation_entry.is_empty():
		sprite_palette_index = int(animation_entry.get("palette_index", -1))
		if int(animation_bytes[0]) != sprite_palette_index:
			return false
		if str(animation_entry.get("source_bin", "")) != "reference/rom_extract/intro/animation_%02X.bin" % animation_id \
				or str(animation_entry.get("source_sha256", "")) != _sha256_hex(animation_bytes) \
				or _parse_hex_byte(str(animation_entry.get("raw_first_byte", ""))) != int(animation_bytes[0]):
			return false
		if sprite_palette_index < 0 or sprite_palette_index > 8:
			return false
		var sprite_palette_table := FileAccess.get_file_as_bytes(F3_SPRITE_PALETTE_TABLE_PATH)
		if sprite_palette_table.size() != 9 * 16 \
				or str(table_metadata.get("source_file_offset", "")) != "0x00D310" \
				or str(table_metadata.get("source_sha256", "")) != _sha256_hex(sprite_palette_table):
			return false
		sprite_palette = sprite_palette_table.slice(sprite_palette_index * 16, (sprite_palette_index + 1) * 16)
		var expected_sprite_palette := _metadata_palette_bytes(table_metadata, sprite_palette_index)
		if expected_sprite_palette.size() != 16 or expected_sprite_palette != sprite_palette:
			return false
		sprite_palette_file_offset = "0x%06X" % (0x00D310 + sprite_palette_index * 16)
	else:
		# The title's final FB animation 0D selects palette index 09, which is
		# beyond the nine-row 00–08 table used by the ordinary F3 prototype.
		# Validate its separately preserved raw ROM record and sidecar instead.
		var palette_sidecar_path := "res://reference/rom_extract/intro/animation_%02X_sprite_palette.json" % animation_id
		if not FileAccess.file_exists(palette_sidecar_path):
			return false
		var palette_sidecar_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(palette_sidecar_path))
		if not palette_sidecar_value is Dictionary:
			return false
		var palette_sidecar: Dictionary = palette_sidecar_value
		if str(palette_sidecar.get("rom_sha256", "")) != SOURCE_ROM_SHA256 \
				or _parse_hex_byte(str(palette_sidecar.get("animation_id", ""))) != animation_id:
			return false
		sprite_palette_index = _parse_hex_byte(str(palette_sidecar.get("animation_palette_operand", "")))
		if sprite_palette_index < 0 or int(animation_bytes[0]) != sprite_palette_index:
			return false
		var sprite_palette_path := "res://reference/rom_extract/intro/animation_%02X_sprite_palette.bin" % animation_id
		sprite_palette = FileAccess.get_file_as_bytes(sprite_palette_path)
		var expected_palette := _parse_hex_bytes(str(palette_sidecar.get("bytes_hex", "")))
		if sprite_palette.size() != 16 or sprite_palette != expected_palette:
			return false
		sprite_palette_file_offset = str(palette_sidecar.get("source_file_offset", ""))
	_base_palette = background_palette.duplicate()
	_base_palette.append_array(sprite_palette)
	state["last_f3_palette_source"] = {
		"background_id": background_id,
		"background_palette_index": background_palette_index,
		"background_palette_file_offset": str(background_layout.get("palette_file_offset", "")),
		"animation_id": "$%02X" % animation_id,
		"sprite_palette_index": sprite_palette_index,
		"sprite_palette_file_offset": sprite_palette_file_offset,
		"source_bytes_preserved": true,
	}
	return _base_palette.size() == FADE_MODEL.PALETTE_SIZE


func _restore_logo_fade_palette_base(source_frame: int) -> bool:
	## The repeated E8/F9/FB/E9 logo pass reuses the same ROM palettes as the
	## cold-start logo. Earlier cutscene F3/F5 effects mutate _base_palette, so
	## restore these byte-verified inputs before the ROM's E9 fade-up runs again.
	var background_layout_path := "res://reference/rom_extract/intro/background_00_layout.json"
	var background_layout_value: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(background_layout_path))
	if not background_layout_value is Dictionary:
		_fail_slice("Repeated logo palette restore could not read background-00 ROM metadata.")
		return false
	var background_layout: Dictionary = background_layout_value
	if str(background_layout.get("rom_sha256", "")) != SOURCE_ROM_SHA256 \
			or int(background_layout.get("palette_index", -1)) != 1 \
			or str(background_layout.get("palette_file_offset", "")) != "0x00D020":
		_fail_slice("Repeated logo background palette metadata does not match the supplied ROM.")
		return false
	var background_palette := FileAccess.get_file_as_bytes(BASE_BACKGROUND_PALETTE_PATH)
	var expected_background_palette := _parse_hex_bytes(
		str(background_layout.get("palette_raw_hex", "")))
	var sprite_palette := FileAccess.get_file_as_bytes(BASE_SPRITE_PALETTE_PATH)
	var expected_sprite_palette := _parse_hex_bytes("0F 05 16 15 0F 30 27 37 0F 10 0F 0F 0F 0F 00 30")
	if background_palette.size() != 16 or background_palette != expected_background_palette \
			or sprite_palette != expected_sprite_palette \
			or _sha256_hex(sprite_palette) != "ec42f3f85cb8d9fae82740c0ee5c10c56d337279e05d556c3f4a27cfbca505cb":
		_fail_slice("Repeated logo palette bytes do not match their preserved ROM records.")
		return false
	_base_palette = background_palette.duplicate()
	_base_palette.append_array(sprite_palette)
	state["logo_fade_palette_restore"] = {
		"source_frame": source_frame,
		"background_palette_file_offset": str(background_layout.get("palette_file_offset", "")),
		"background_palette_source": BASE_BACKGROUND_PALETTE_PATH,
		"sprite_palette_file_offset": "0x00D670",
		"sprite_palette_source": BASE_SPRITE_PALETTE_PATH,
		"sprite_palette_sha256": _sha256_hex(sprite_palette),
		"rom_sha256": SOURCE_ROM_SHA256,
		"source_bytes_verified": true,
	}
	return _base_palette.size() == FADE_MODEL.PALETTE_SIZE


func _find_animation_palette_header(metadata: Dictionary, animation_id: int) -> Dictionary:
	var entries: Variant = metadata.get("entries", [])
	if not entries is Array:
		return {}
	for entry_value in entries:
		if not entry_value is Dictionary:
			continue
		var entry: Dictionary = entry_value
		if _parse_hex_byte(str(entry.get("animation_id", ""))) == animation_id:
			return entry
	return {}


func _metadata_palette_bytes(metadata: Dictionary, palette_index: int) -> PackedByteArray:
	var rows: Variant = metadata.get("rows", [])
	if not rows is Array:
		return PackedByteArray()
	for row_value in rows:
		if not row_value is Dictionary:
			continue
		var row: Dictionary = row_value
		if int(row.get("palette_index", -1)) == palette_index:
			return _parse_hex_bytes(str(row.get("bytes_hex", "")))
	return PackedByteArray()


func _parse_hex_byte(hex_text: String) -> int:
	var value := hex_text.strip_edges()
	if value.begins_with("0x") or value.begins_with("0X"):
		value = value.substr(2)
	if value.is_empty() or value.length() > 2:
		return -1
	var parsed := value.hex_to_int()
	return parsed if parsed >= 0 and parsed <= 0xFF else -1


func _stage_f3_palette(source_frame: int) -> bool:
	if not _load_f3_palette_sources():
		return false
	# $9A35 selects the current background's $48 palette and last FB animation's
	# $49 palette, then $9A71 stages the $20 00 3F packet. At $0F/$0F the ROM LUT
	# preserves each source byte.
	_staged_palette = FADE_MODEL.build_palette(_base_palette, 0x0F, 0x0F)
	_fade_staged_source_frame = source_frame
	_staged_palette_commit_not_before_source_frame = -1
	state["field_palette_override_pending"] = true
	state["fade_counters"] = Vector2i(0x0F, 0x0F)
	state["palette_staged_level"] = 0x0F
	state["palette_staged_source_frame"] = source_frame
	_background_01_queue_cursor += 0x23 # 3-byte header + 32-byte payload; terminator at $23.
	state["shared_ppu_queue_cursor_0628"] = _background_01_queue_cursor
	state["f3_00_palette_rebuild"] = {
		"background_id": int(state.get("background_id", -1)),
		"background_palette_index": int(state["last_f3_palette_source"]["background_palette_index"]),
		"background_palette_file_offset": str(state["last_f3_palette_source"]["background_palette_file_offset"]),
		"animation_id": str(state["last_f3_palette_source"]["animation_id"]),
		"sprite_palette_index": int(state["last_f3_palette_source"]["sprite_palette_index"]),
		"sprite_palette_file_offset": str(state["last_f3_palette_source"]["sprite_palette_file_offset"]),
		"brightness_counters_004A_004B": "0F 0F",
		"source_palette_bytes_preserved": true,
		"queue_header_hex": "20 00 3F",
		"queue_cursor_after_packet": "$%04X" % _background_01_queue_cursor,
		"staged_source_frame": source_frame,
		"ppu_commit_source_frame": source_frame + 1,
		"exact_within_frame_visible_edge_measured": false,
	}
	return _staged_palette.size() == FADE_MODEL.PALETTE_SIZE


func _stage_f4_palette_pass(source_frame: int) -> bool:
	if not state.has("f3_00_palette_rebuild") or _base_palette.size() != FADE_MODEL.PALETTE_SIZE:
		return false
	var pass_index := int(state["f4_palette_sweep"]["pass_index"])
	var values: Array = state["f4_palette_sweep"]["values"]
	if pass_index < 0 or pass_index >= values.size():
		return false
	var selected_value := int(values[pass_index])
	_base_palette[7] = selected_value
	_staged_palette = FADE_MODEL.build_palette(_base_palette, 0x0F, 0x0F)
	_fade_staged_source_frame = source_frame
	_staged_palette_commit_not_before_source_frame = -1
	state["field_palette_override_pending"] = true
	_background_01_queue_cursor += 0x23
	state["shared_ppu_queue_cursor_0628"] = _background_01_queue_cursor
	state["f4_palette_sweep"]["staged_value"] = selected_value
	state["f4_palette_sweep"]["last_staged_source_frame"] = source_frame
	state["f4_palette_sweep"]["last_commit_source_frame"] = source_frame + 1
	state["f4_palette_sweep"]["palette_packet_hex"] = "20 00 3F"
	state["palette_staged_source_frame"] = source_frame
	return _staged_palette.size() == FADE_MODEL.PALETTE_SIZE


func _load_rom_script() -> bool:
	_script_bytes = FileAccess.get_file_as_bytes(SCRIPT_PATH)
	if _script_bytes.size() != SCRIPT_LENGTH_BYTES:
		push_error("Extracted cutscene script has an unexpected length; expected the byte-preserved 641-byte span.")
		return false
	var hash_context := HashingContext.new()
	if hash_context.start(HashingContext.HASH_SHA256) != OK or hash_context.update(_script_bytes) != OK:
		push_error("Could not hash the extracted cutscene script.")
		return false
	if hash_context.finish().hex_encode() != SCRIPT_SHA256:
		push_error("Extracted cutscene script does not match its recorded source hash.")
		return false
	for index in range(REQUIRED_SCRIPT_PREFIX.size()):
		if int(_script_bytes[index]) != REQUIRED_SCRIPT_PREFIX[index]:
			push_error("Cutscene prefix differs from the verified E8/F9/FB/E9/DF/EA/ED path.")
			return false
	return true


func _load_startup_phase() -> bool:
	if not FileAccess.file_exists(COLD_START_BOOTSTRAP_PHASE_PATH):
		push_error("The ROM-derived cold-start bootstrap phase resource is missing.")
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(COLD_START_BOOTSTRAP_PHASE_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("The ROM-derived cold-start bootstrap phase resource is not a JSON object.")
		return false
	var document: Dictionary = parsed
	if int(document.get("schema_version", -1)) != 1 \
			or str(document.get("source_rom_sha256", "")) != SOURCE_ROM_SHA256:
		push_error("The cold-start bootstrap phase resource targets a different ROM or schema.")
		return false
	var frame_data: Variant = document.get("runtime_phase_frames", {})
	var event_data: Variant = document.get("events", {})
	if typeof(frame_data) != TYPE_DICTIONARY or typeof(event_data) != TYPE_DICTIONARY:
		push_error("The cold-start bootstrap phase resource is missing frame/event maps.")
		return false
	var frames: Dictionary = frame_data
	var events: Dictionary = event_data
	for key in [
			"first_literal_scheduler_scan",
			"worker_ready_sentinel_install",
			"first_ready_worker_scan",
			"first_nmi_release",
			"first_black_palette_commit",
	]:
		if not frames.has(key) or int(frames[key]) < 1:
			push_error("The cold-start bootstrap phase has a missing or invalid frame: " + key)
			return false
	_first_literal_scheduler_scan_source_frame = int(frames["first_literal_scheduler_scan"])
	_worker_ready_install_source_frame = int(frames["worker_ready_sentinel_install"])
	_first_ready_worker_scan_source_frame = int(frames["first_ready_worker_scan"])
	_first_nmi_release_source_frame = int(frames["first_nmi_release"])
	_initial_black_palette_commit_source_frame = int(frames["first_black_palette_commit"])
	if not (_first_literal_scheduler_scan_source_frame < _worker_ready_install_source_frame \
			and _worker_ready_install_source_frame <= _first_ready_worker_scan_source_frame \
			and _first_ready_worker_scan_source_frame < _first_nmi_release_source_frame \
			and _first_nmi_release_source_frame == _initial_black_palette_commit_source_frame):
		push_error("The cold-start source milestones are not in a valid startup order.")
		return false
	var worker_install: Variant = events.get("worker_ready_sentinel_install", {})
	var ready_scan: Variant = events.get("initial_ready_scan_trigger", {})
	var first_nmi: Variant = events.get("first_nmi_scheduler_latch", {})
	var black_palette: Variant = events.get("first_black_palette_commit", {})
	if typeof(worker_install) != TYPE_DICTIONARY or typeof(ready_scan) != TYPE_DICTIONARY \
			or typeof(first_nmi) != TYPE_DICTIONARY or typeof(black_palette) != TYPE_DICTIONARY:
		push_error("The cold-start source events are missing required scheduler milestones.")
		return false
	if str(worker_install.get("pc", "")) != "$9F69" \
			or int(worker_install.get("slot_offset", -1)) != CUTSCENE_TASK_SLOT \
			or int(worker_install.get("delay_byte", -1)) != RomCooperativeScheduler.READY_TASK_DELAY_SENTINEL \
			or int(worker_install.get("source_frame", -1)) != _worker_ready_install_source_frame:
		push_error("The cold-start worker-install event does not match the ROM scheduler contract.")
		return false
	if str(ready_scan.get("pc", "")) != "$9FA8" \
			or str(ready_scan.get("first_worker_resume_pc", "")) != "$84C6" \
			or int(ready_scan.get("source_frame", -1)) != _first_ready_worker_scan_source_frame:
		push_error("The cold-start initial ready-scan event does not match the ROM trace.")
		return false
	if str(first_nmi.get("pc", "")) != "$A133" \
			or int(first_nmi.get("source_frame", -1)) != _first_nmi_release_source_frame:
		push_error("The cold-start first NMI-ready latch event does not match the ROM trace.")
		return false
	if str(black_palette.get("ppu_address", "")) != "$3F00" \
			or int(black_palette.get("byte_count", -1)) != 32 \
			or str(black_palette.get("bytes_hex", "")) != "0F".repeat(32) \
			or int(black_palette.get("source_frame", -1)) != _initial_black_palette_commit_source_frame:
		push_error("The initial black palette milestone does not match ROM-only PPU RAM output.")
		return false
	_startup_phase = document
	return true


func _load_f8_helper_return_event() -> bool:
	if not FileAccess.file_exists(F8_HELPER_RETURN_EVENT_PATH):
		push_error("The ROM-derived F8 helper-return event resource is missing.")
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(F8_HELPER_RETURN_EVENT_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("The F8 helper-return event resource is not a JSON object.")
		return false
	var document: Dictionary = parsed
	if str(document.get("schema", "")) != "ct2-f8-helper-return-source-events-v1" \
			or str(document.get("source_rom_sha256", "")) != SOURCE_ROM_SHA256 \
			or bool(document.get("captured_frame_intervals_used", true)) \
			or bool(document.get("captured_pixels_or_audio_used", true)) \
			or bool(document.get("runtime_consumes_cycle_offsets", true)):
		push_error("The F8 helper-return event resource has incompatible provenance or schema.")
		return false
	var script_sequence := PackedByteArray([0xF8, 0x00, 0xDF, 0xFE, 0x20, 0xA0])
	if _script_bytes.slice(0x27B, 0x27B + script_sequence.size()) != script_sequence:
		push_error("The F8 return resource does not match the extracted script sequence.")
		return false
	var event_value: Variant = document.get("events", [])
	if typeof(event_value) != TYPE_ARRAY:
		push_error("The F8 helper-return resource is missing its source PC events.")
		return false
	var edge_frames: Dictionary = {}
	for event_value_item in event_value:
		if typeof(event_value_item) != TYPE_DICTIONARY:
			push_error("The F8 helper-return source event list contains an invalid entry.")
			return false
		var event: Dictionary = event_value_item
		var edge := str(event.get("pc", "")) + ">" + str(event.get("next_pc", ""))
		edge_frames[edge] = int(event.get("source_frame", -1))
	var expected_edges := {
		"$98DC>$A541": 3967,
		"$895C>$A557": 3968,
		"$A559>$880A": 3968,
		"$8811>$8879": 3968,
		"$84E7>$84E9": 3968,
		"$8508>$8509": 3968,
		"$8514>$9FA8": 3968,
		"$9FA8>$9FAA": 3968,
	}
	for expected_edge in expected_edges:
		if int(edge_frames.get(expected_edge, -1)) != int(expected_edges[expected_edge]):
			push_error("The F8 helper-return event sequence is missing source edge " + expected_edge + ".")
			return false
	if int(document.get("service_completion_source_frame", -1)) != 3967 \
			or int(document.get("runtime_dispatch_frame", -1)) != 3968:
		push_error("The F8 helper-return frame edge is missing or inconsistent.")
		return false
	_f8_helper_return_event = document.duplicate(true)
	return true


func _sha256_hex(bytes: PackedByteArray) -> String:
	var hash_context := HashingContext.new()
	if hash_context.start(HashingContext.HASH_SHA256) != OK:
		return ""
	if hash_context.update(bytes) != OK:
		return ""
	return hash_context.finish().hex_encode()


func _parse_hex_bytes(hex_text: String) -> PackedByteArray:
	var result := PackedByteArray()
	for token in hex_text.split(" ", false):
		var value := token.strip_edges()
		if value.is_empty():
			continue
		var parsed := value.hex_to_int()
		if parsed < 0 or parsed > 0xFF:
			return PackedByteArray()
		result.append(parsed)
	return result


func _fail_slice(reason: String) -> void:
	push_error(reason)
	if _scheduler != null and _scheduler.current_task_slot_offset >= 0:
		_scheduler.finish_current_task()
	_cutscene_task_stopped = true
	state["slice_error"] = reason


func _stop_before_unmodeled_handler(script_cpu: String, opcode: int,
		operands: PackedByteArray, reason: String) -> void:
	state["unresolved_command"] = {
		"opcode": "$%02X" % opcode,
		"script_cpu": script_cpu,
		"operands": operands,
		"reason": reason,
	}
	state["stopped_before_unmodeled_command"] = true
	_cutscene_task_stopped = true
	if _scheduler == null or not _scheduler.finish_current_task():
		_fail_slice("Could not release the cutscene task at unresolved opcode $%02X." % opcode)

