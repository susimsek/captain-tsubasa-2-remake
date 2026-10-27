extends CanvasLayer
class_name ApplicationAbout
## Connects the macOS application-menu About item to the game's branded dialog.

const APPLICATION_NAME := "Captain Tsubasa 2 Remake"
const PROJECT_URL := "https://github.com/susimsek/captain-tsubasa-2-remake"
const ABOUT_INPUT_ACTION := "application_about"
const ABOUT_DIALOG_SIZE := Vector2i(520, 300)

var _about_dialog: AcceptDialog
var _application_menu := RID()
var _about_item_index := -1
var _previous_about_callback := Callable()


func _ready() -> void:
	_create_about_dialog()
	_install_about_input_action()
	if OS.has_feature("macos") and DisplayServer.get_name() != "headless":
		call_deferred("_connect_native_about_item")


func show_about_dialog() -> void:
	if _about_dialog == null:
		return
	_about_dialog.dialog_text = _build_about_text()
	_about_dialog.popup_centered(ABOUT_DIALOG_SIZE)


func _create_about_dialog() -> void:
	_about_dialog = AcceptDialog.new()
	_about_dialog.name = "AboutDialog"
	_about_dialog.title = "About " + APPLICATION_NAME
	_about_dialog.dialog_autowrap = true
	_about_dialog.dialog_close_on_escape = true
	_about_dialog.ok_button_text = "Close"
	_about_dialog.dialog_text = _build_about_text()
	_about_dialog.custom_action.connect(_on_about_dialog_custom_action)
	_about_dialog.add_button("Project Website", true, "project_website")
	add_child(_about_dialog)


func _build_about_text() -> String:
	var version := str(ProjectSettings.get_setting("application/config/version", "0.1.0"))
	return "%s\nVersion %s\n\nAn unofficial fan-made reconstruction of the Turkish NES release.\nCurrent milestone: opening sequence and title screen.\n\nProject code: Apache-2.0. Original game content remains the property of its respective rights holders." % [APPLICATION_NAME, version]


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


func _connect_native_about_item() -> void:
	if not NativeMenu.has_feature(NativeMenu.FEATURE_GLOBAL_MENU) \
			or not NativeMenu.has_system_menu(NativeMenu.APPLICATION_MENU_ID):
		return
	_application_menu = NativeMenu.get_system_menu(NativeMenu.APPLICATION_MENU_ID)
	if not _application_menu.is_valid() or not NativeMenu.has_menu(_application_menu):
		return

	var callback := Callable(self, "_on_native_about_selected")
	for item_index in range(NativeMenu.get_item_count(_application_menu)):
		var item_text := NativeMenu.get_item_text(_application_menu, item_index).strip_edges().to_lower()
		if item_text.begins_with("about ") or item_text == "about" or item_text.begins_with("hakkında "):
			_about_item_index = item_index
			_previous_about_callback = NativeMenu.get_item_callback(_application_menu, item_index)
			NativeMenu.set_item_callback(_application_menu, item_index, callback)
			return

	# Some exported builds omit the default About command. Add it at the top of
	# the app menu so the same feature remains available from the expected place.
	_about_item_index = NativeMenu.add_item(
		_application_menu,
		"About " + APPLICATION_NAME,
		callback,
		Callable(),
		null,
		0,
		0
	)


func _on_native_about_selected(_tag: Variant) -> void:
	call_deferred("show_about_dialog")


func _on_about_dialog_custom_action(action: StringName) -> void:
	if action == &"project_website":
		OS.shell_open(PROJECT_URL)


func _exit_tree() -> void:
	if _about_item_index < 0 or not _application_menu.is_valid():
		return
	if NativeMenu.has_menu(_application_menu):
		NativeMenu.set_item_callback(_application_menu, _about_item_index, _previous_about_callback)
