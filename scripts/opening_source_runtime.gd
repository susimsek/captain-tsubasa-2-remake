extends Node2D
## Runs the ROM-command opening, its offline ROM-driver audio timeline, and the
## title endpoint. The title choices are displayed but never confirmed here.

const NES_CPU_CLOCK_HZ := 1789773.0
# The live FCEUX NTSC window displays 224 lines from the 240-line PPU output,
# cropping eight overscan rows from both ends. Keep source renderers in their
# native 256x240 coordinate space. Windows/Linux reserve a seven-pixel-high
# desktop Help menu above the same 224-line gameplay area.
const FCEUX_VISIBLE_HEIGHT := 224
const PPU_TOP_OVERSCAN_LINES := 8
const DESKTOP_MENU_VIEWPORT_HEIGHT := 231
const DESKTOP_MENU_HEIGHT := 7
# Same-input PPU snapshots are black on frames 4662–4691 after Start at 4661;
# the title palette returns on 4692. This is a captured 30-frame boundary.
const START_POLL_TO_STOP_CPU_CYCLES := 38
const AUDIO_RELATIVE_PATH := "assets/opening/audio/opening_timeline_rom_driver.wav"
const AUDIO_PATH := "res://" + AUDIO_RELATIVE_PATH
const AUDIO_METADATA_PATH := "res://assets/opening/audio/opening_timeline_rom_driver.json"
const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

@onready var source_presenter: ColdStartSourceCommandPresenter = $SourcePresenter
@onready var title_menu: RomTitleMenu = $TitleMenu
@onready var opening_audio = $OpeningAudio
@onready var transition_black: ColorRect = $TransitionBlack

var _transition_active := false
var _transition_cpu_cycles_elapsed := 0.0
var _transition_blackout_presented := false
var _start_input_held := false
var _audio_loop_start_frame := -1
var _audio_frame_rate := 0.0
var _last_audio_sync_source_frame := -1


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	_apply_fceux_visible_crop()
	title_menu.visible = false
	transition_black.visible = false
	if not _load_audio_metadata():
		set_process(false)
		return
	opening_audio.stream = load(AUDIO_PATH) as AudioStream
	if opening_audio.stream == null:
		push_error("The ROM-driver opening audio resource could not be loaded.")
		set_process(false)
		return
	opening_audio.finished.connect(_on_opening_audio_finished)
	source_presenter.rom_sound_requested.connect(_on_rom_sound_requested)
	source_presenter.source_start_poll_completed.connect(_on_source_start_poll_completed)
	# This WAV is an offline render of the supplied ROM's sound driver and data.
	# It contains the scheduled cues; ROM cue signals re-anchor its music timeline.
	_play_opening_audio()


func _apply_fceux_visible_crop() -> void:
	# Diagnostic capture harnesses explicitly use a 256x240 viewport to compare
	# every PPU output row. macOS uses a 256x224 game viewport; Windows/Linux
	# add seven rows above it for the Help menu, without scaling or covering the
	# game image. Offset source art so the gameplay rows stay the same on both.
	var visible_height := int(round(get_viewport().get_visible_rect().size.y))
	if visible_height == DESKTOP_MENU_VIEWPORT_HEIGHT:
		position.y = float(DESKTOP_MENU_HEIGHT - PPU_TOP_OVERSCAN_LINES)
	elif visible_height == FCEUX_VISIBLE_HEIGHT:
		position.y = -PPU_TOP_OVERSCAN_LINES


func _process(delta: float) -> void:
	if _transition_active:
		_advance_title_transition(delta)
	elif not title_menu.visible and not opening_audio.playback_expected_active() \
			and _audio_loop_start_frame >= 0:
		# The ROM repeats its opening music from the first emitted $58 command.
		# Learn that loop point from the source presenter instead of loading a
		# captured cue-frame schedule from the audio manifest.
		_play_opening_audio(float(_audio_loop_start_frame) / _audio_frame_rate)


func _on_rom_sound_requested(sound_id: int, source_frame: int) -> void:
	# The mixed ROM-driver render already contains the cue. Re-seek on ROM $58
	# commands so audio-server clock drift cannot move the opening loop away from
	# the decoded command timeline. Do not start a second stream for the event.
	if sound_id != 0x58 or source_frame < 0:
		return
	if _audio_loop_start_frame < 0:
		_audio_loop_start_frame = source_frame
	if _transition_active or title_menu.visible:
		return
	_play_opening_audio(float(source_frame) / _audio_frame_rate)
	_last_audio_sync_source_frame = source_frame


func _play_opening_audio(from_position: float = 0.0) -> void:
	opening_audio.play(from_position)
	opening_audio.set_playback_expected_active(true)


func _on_opening_audio_finished() -> void:
	opening_audio.set_playback_expected_active(false)


func _unhandled_input(event: InputEvent) -> void:
	if _transition_active or title_menu.visible:
		return
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("opening_start"):
		_start_input_held = true
		get_viewport().set_input_as_handled()
	elif event.is_action_released("opening_start"):
		_start_input_held = false


func _on_source_start_poll_completed(_source_frame: int) -> void:
	if not _start_input_held or _transition_active or title_menu.visible:
		return
	if not title_menu.begin_source_handoff():
		push_warning("ROM title queue could not start; the opening will continue running.")
		return
	source_presenter.freeze_source_for_title_handoff()
	_transition_active = true
	# The accepted `$802C` path reaches `$8048` after 38 CPU cycles in the
	# measured frame. The poll's within-frame position is still a coarse model.
	_transition_cpu_cycles_elapsed = -float(START_POLL_TO_STOP_CPU_CYCLES)
	_transition_blackout_presented = false


func _advance_title_transition(delta: float) -> void:
	# Playback consumes source-stepper CPU-cycle events. The event sequence is
	# anchored at the ROM's `$8048` Start stop. `$802C` is serviced once per
	# source frame, but its within-frame poll phase is not reproduced here.
	_transition_cpu_cycles_elapsed += delta * NES_CPU_CLOCK_HZ
	var cycle_offset := int(floor(_transition_cpu_cycles_elapsed))
	if cycle_offset < 0:
		return
	var title_queue_complete := title_menu.advance_source_handoff_to_cpu_cycle(cycle_offset)
	if not _transition_blackout_presented and title_menu.source_handoff_blackout_started():
		# The first accepted post-Start NMI is the ROM-derived beginning of the
		# black handoff. Keep the ROM-rendered scene until that event arrives.
		source_presenter.visible = false
		transition_black.visible = true
		_transition_blackout_presented = true
	if title_queue_complete:
		transition_black.visible = false
		title_menu.visible = true
		_transition_active = false


func _load_audio_metadata() -> bool:
	if not FileAccess.file_exists(AUDIO_METADATA_PATH):
		push_error("The ROM-driver opening audio metadata is missing.")
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(AUDIO_METADATA_PATH))
	if not parsed is Dictionary:
		push_error("The ROM-driver opening audio metadata is invalid.")
		return false
	var metadata: Dictionary = parsed
	if str(metadata.get("source_rom_sha256", "")) != SOURCE_ROM_SHA256 \
			or str(metadata.get("audio_path", "")) != AUDIO_RELATIVE_PATH \
			or bool(metadata.get("captured_pcm_used", true)) \
			or bool(metadata.get("runtime_needs_rom_or_emulator", true)):
		push_error("Opening audio metadata does not describe the expected ROM-derived, standalone asset.")
		return false
	_audio_frame_rate = float(metadata.get("frame_rate_hz", 0.0))
	if _audio_frame_rate <= 0.0:
		push_error("Opening audio metadata has no valid NES frame rate.")
		return false
	var audio_bytes := FileAccess.get_file_as_bytes(AUDIO_PATH)
	var expected_audio_sha256 := str(metadata.get("audio_sha256", ""))
	if audio_bytes.is_empty() or expected_audio_sha256.is_empty() \
			or _sha256_hex(audio_bytes) != expected_audio_sha256:
		push_error("Opening audio WAV does not match its source manifest checksum.")
		return false
	return true


func _sha256_hex(bytes: PackedByteArray) -> String:
	var hasher := HashingContext.new()
	if hasher.start(HashingContext.HASH_SHA256) != OK:
		return ""
	if hasher.update(bytes) != OK:
		return ""
	return hasher.finish().hex_encode()
