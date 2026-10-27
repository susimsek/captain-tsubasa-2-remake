extends Node2D
class_name ColdStartLogoPresenter
## Isolated composition of the first six ROM cutscene commands.
## This is a research presenter; the main opening scene does not use it.

const NES_FPS := 60.0988
const NES_FRAME_SECONDS := 1.0 / NES_FPS
const CUTSCENE_VM_SCRIPT := preload("res://scripts/opening/rom_cutscene_vm.gd")

@onready var background: Node2D = $Background
@onready var logo_sprite: Node2D = $LogoSprite

var _cutscene: Variant
var _frame_accumulator := 0.0
var _presenter_stopped := false


func _ready() -> void:
	_cutscene = CUTSCENE_VM_SCRIPT.from_project_data()
	if _cutscene == null:
		set_process(false)
		return
	_cutscene.command_executed.connect(_on_command_executed)
	_apply_state(_cutscene.begin())


func _process(delta: float) -> void:
	_frame_accumulator += delta
	while _frame_accumulator >= NES_FRAME_SECONDS and not _presenter_stopped:
		_frame_accumulator -= NES_FRAME_SECONDS
		_apply_state(_cutscene.advance_one_script_tick())


func _on_command_executed(event: Dictionary, _state_snapshot: Dictionary) -> void:
	# The presenter intentionally stops at the original logo's EA command. The
	# full VM contains the following ED cue and later intro events as well.
	if str(event.get("k", "")) == "screen_off_clear":
		_presenter_stopped = true


func _apply_state(state: Dictionary) -> void:
	# The ROM command VM supplies command order and the 240-tick wait. This
	# visibility edge is only a prototype mapping; hardware PPU commit timing
	# for these uploads has not been proven.
	var show_logo := bool(state.get("screen_enabled", false)) and not bool(state.get("clear_requested", false))
	background.visible = show_logo and int(state.get("background_1", -1)) == 0
	var animation_loaded := false
	var animation_ids: Variant = state.get("animation_ids", [])
	if animation_ids is Array:
		for animation_id: Variant in animation_ids:
			# JSON.parse_string() materializes numbers as floats in Godot. Compare
			# numeric IDs after conversion so ROM animation 0x8D (141) is visible.
			if int(animation_id) == 0x8D:
				animation_loaded = true
				break
	logo_sprite.visible = show_logo and animation_loaded
