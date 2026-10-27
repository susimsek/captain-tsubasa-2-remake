extends CanvasLayer
class_name ApplicationAbout
## Handles the macOS About notification and the desktop shortcut.

const APPLICATION_NAME := "Captain Tsubasa 2 Remake"
const ABOUT_INPUT_ACTION := "application_about"
const ABOUT_WINDOW_SIZE := Vector2i(380, 310)
const RELEASE_MONTHS := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

var _about_dialog: Window
var _version_label: Label
var _release_date_label: Label


func _ready() -> void:
	# Keep About independent of the game's 256x224 pixel-art viewport. An
	# embedded child window inherits the game's stretch scale and becomes huge.
	get_viewport().gui_embed_subwindows = false
	_create_about_dialog()
	_install_about_input_action()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_ABOUT:
		show_about_dialog()


func show_about_dialog() -> void:
	if _about_dialog == null:
		return
	_version_label.text = "Version %s" % str(ProjectSettings.get_setting("application/config/version", "0.1.0"))
	_release_date_label.text = "Released %s" % _format_release_date()
	_about_dialog.popup_centered(ABOUT_WINDOW_SIZE)


func _create_about_dialog() -> void:
	_about_dialog = Window.new()
	_about_dialog.name = "AboutDialog"
	_about_dialog.title = "About " + APPLICATION_NAME
	_about_dialog.size = ABOUT_WINDOW_SIZE
	_about_dialog.min_size = ABOUT_WINDOW_SIZE
	_about_dialog.unresizable = true
	_about_dialog.transient = true
	_about_dialog.exclusive = true
	_about_dialog.visible = false
	_about_dialog.close_requested.connect(_about_dialog.hide)

	var background := PanelContainer.new()
	background.name = "Background"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background_style := StyleBoxFlat.new()
	background_style.bg_color = Color("202122")
	background.add_theme_stylebox_override("panel", background_style)
	_about_dialog.add_child(background)

	var margins := MarginContainer.new()
	margins.name = "Margins"
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margins.add_theme_constant_override("margin_left", 24)
	margins.add_theme_constant_override("margin_top", 18)
	margins.add_theme_constant_override("margin_right", 24)
	margins.add_theme_constant_override("margin_bottom", 18)
	background.add_child(margins)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 14)
	margins.add_child(content)

	var icon := TextureRect.new()
	icon.name = "ApplicationIcon"
	icon.texture = load("res://assets/branding/captain-tsubasa-2-icon.png") as Texture2D
	icon.custom_minimum_size = Vector2(72, 72)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(icon)

	var name_label := Label.new()
	name_label.name = "ApplicationName"
	name_label.text = APPLICATION_NAME
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color("f3f3f3"))
	content.add_child(name_label)

	_version_label = Label.new()
	_version_label.name = "Version"
	_version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_version_label.add_theme_font_size_override("font_size", 14)
	_version_label.add_theme_color_override("font_color", Color("c7c7c7"))
	content.add_child(_version_label)

	_release_date_label = Label.new()
	_release_date_label.name = "ReleaseDate"
	_release_date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_release_date_label.add_theme_font_size_override("font_size", 14)
	_release_date_label.add_theme_color_override("font_color", Color("c7c7c7"))
	content.add_child(_release_date_label)

	add_child(_about_dialog)


func _format_release_date() -> String:
	var date_parts := str(ProjectSettings.get_setting("application/config/original_release_date", "1990-07-20")).split("-")
	if date_parts.size() != 3:
		return ""
	var month_index := int(date_parts[1]) - 1
	if month_index < 0 or month_index >= RELEASE_MONTHS.size():
		return ""
	return "%s %d, %s" % [RELEASE_MONTHS[month_index], int(date_parts[2]), date_parts[0]]


func _install_about_input_action() -> void:
	if not InputMap.has_action(ABOUT_INPUT_ACTION):
		InputMap.add_action(ABOUT_INPUT_ACTION)
	var f1_key := InputEventKey.new()
	f1_key.keycode = KEY_F1
	if not InputMap.action_has_event(ABOUT_INPUT_ACTION, f1_key):
		InputMap.action_add_event(ABOUT_INPUT_ACTION, f1_key)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed(ABOUT_INPUT_ACTION):
		show_about_dialog()
		get_viewport().set_input_as_handled()
