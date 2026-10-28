extends CanvasLayer
class_name ApplicationAbout
## Provides consistent desktop Help commands and About/update dialogs.

const APPLICATION_NAME := "Captain Tsubasa 2 Remake"
const UI_SURFACE_COLOR := "202122"
const UI_TEXT_PRIMARY := "f3f3f3"
const UI_TEXT_SECONDARY := "d0d0d0"
const UI_TEXT_MUTED := "a7a7a7"
const UI_ACCENT_COLOR := "0a84ff"
const UI_MARGIN_HORIZONTAL := 24
const UI_MARGIN_VERTICAL := 18
const UI_SECTION_GAP := 16
const UI_FONT_HEADING := 18
const UI_FONT_BODY := 14
const UI_FONT_METADATA := 12
const UI_BUTTON_HEIGHT := 40
const UI_BUTTON_RADIUS := 8
const DESKTOP_MENU_HEIGHT := 7.0
const DESKTOP_MENU_VIEWPORT_SIZE := Vector2i(256, 231)
const DESKTOP_MENU_LOGICAL_SCALE := Vector2(0.25, 0.25)
const DESKTOP_MENU_ITEM_ABOUT := 1
const DESKTOP_MENU_ITEM_UPDATES := 2
const APPLICATION_ICON := preload("res://assets/branding/captain-tsubasa-2-icon.png")
const ABOUT_INPUT_ACTION := "application_about"
const UPDATE_INPUT_ACTION := "application_check_for_updates"
const ABOUT_WINDOW_SIZE := Vector2i(380, 230)
const UPDATE_WINDOW_SIZE := Vector2i(520, 250)
const UPDATE_RELEASE_API_URL := "https://api.github.com/repos/susimsek/captain-tsubasa-2-remake/releases/latest"
const UPDATE_ASSET_URL_PREFIX := "https://github.com/susimsek/captain-tsubasa-2-remake/releases/download/"
const UPDATE_MENU_TAG := "captain_tsubasa_check_for_updates"
const UPDATE_MENU_LABEL := "Check for Updates…"
const UPDATE_MENU_RETRY_SECONDS := 0.5
const RELEASE_MONTHS := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

var _about_dialog: Window
var _version_label: Label
var _release_date_label: Label
var _update_dialog: Window
var _update_status_label: Label
var _update_message_label: Label
var _update_date_label: Label
var _update_progress_bar: ProgressBar
var _update_action_button: Button
var _update_later_button: Button
var _update_request: HTTPRequest
var _update_download_request: HTTPRequest
var _update_asset_name := ""
var _update_download_url := ""
var _update_expected_sha256 := ""
var _update_available_version := ""
var _update_asset_size := 0
var _update_download_path := ""
var _last_download_percent := -1
var _update_state := "idle"
var _checking_for_updates := false
var _desktop_help_menu: MenuBar


func _ready() -> void:
	# Keep About independent of the game's 256x224 pixel-art viewport. An
	# embedded child window inherits the game's stretch scale and becomes huge.
	get_viewport().gui_embed_subwindows = false
	if _uses_inline_desktop_help_menu():
		if DisplayServer.get_name() != "headless":
			_configure_inline_desktop_window()
		_create_inline_desktop_help_menu()
	_create_about_dialog()
	_create_update_dialog()
	_install_about_input_action()
	_install_update_input_action()
	_install_update_menu_item.call_deferred()
	_show_pending_update_result()


func _uses_inline_desktop_help_menu() -> bool:
	return OS.get_name() in ["Windows", "Linux"]


func _configure_inline_desktop_window() -> void:
	var main_window := get_tree().root
	var scale_factor := maxf(float(main_window.size.x) / float(DESKTOP_MENU_VIEWPORT_SIZE.x), 3.0)
	main_window.content_scale_size = DESKTOP_MENU_VIEWPORT_SIZE
	main_window.size = Vector2i(
		int(round(float(DESKTOP_MENU_VIEWPORT_SIZE.x) * scale_factor)),
		int(round(float(DESKTOP_MENU_VIEWPORT_SIZE.y) * scale_factor))
	)


func _create_inline_desktop_help_menu() -> void:
	layer = 10
	var menu_background := ColorRect.new()
	menu_background.name = "DesktopMenuBackground"
	menu_background.position = Vector2.ZERO
	menu_background.size = Vector2(1024, 28)
	menu_background.scale = DESKTOP_MENU_LOGICAL_SCALE
	menu_background.color = Color(UI_SURFACE_COLOR)
	menu_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(menu_background)

	var menu_divider := ColorRect.new()
	menu_divider.name = "DesktopMenuDivider"
	menu_divider.position = Vector2(0, 27)
	menu_divider.size = Vector2(1024, 1)
	menu_divider.scale = DESKTOP_MENU_LOGICAL_SCALE
	menu_divider.color = Color("44474b")
	menu_divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(menu_divider)

	_desktop_help_menu = MenuBar.new()
	_desktop_help_menu.name = "DesktopMenuBar"
	_desktop_help_menu.position = Vector2.ZERO
	_desktop_help_menu.size = Vector2(1024, 28)
	_desktop_help_menu.scale = DESKTOP_MENU_LOGICAL_SCALE
	_desktop_help_menu.prefer_global_menu = false
	_desktop_help_menu.add_theme_font_size_override("font_size", 14)
	_desktop_help_menu.add_theme_color_override("font_color", Color(UI_TEXT_SECONDARY))
	_desktop_help_menu.add_theme_color_override("font_hover_color", Color(UI_TEXT_PRIMARY))
	_desktop_help_menu.add_theme_color_override("font_pressed_color", Color.WHITE)
	_desktop_help_menu.add_theme_stylebox_override("normal", _create_menu_item_style(Color("00000000")))
	_desktop_help_menu.add_theme_stylebox_override("hover", _create_menu_item_style(Color("303236")))
	_desktop_help_menu.add_theme_stylebox_override("pressed", _create_menu_item_style(Color("3a3d42")))
	_desktop_help_menu.add_theme_stylebox_override("focus", _create_menu_item_style(Color("303236")))

	var help_popup := PopupMenu.new()
	help_popup.name = "Help"
	help_popup.add_theme_font_size_override("font_size", 14)
	help_popup.add_theme_color_override("font_color", Color(UI_TEXT_SECONDARY))
	help_popup.add_theme_color_override("font_hover_color", Color(UI_TEXT_PRIMARY))
	help_popup.add_theme_stylebox_override("panel", _create_menu_item_style(Color(UI_SURFACE_COLOR)))
	help_popup.add_theme_stylebox_override("hover", _create_menu_item_style(Color("303236")))
	help_popup.add_item("About " + APPLICATION_NAME + "…", DESKTOP_MENU_ITEM_ABOUT)
	help_popup.add_item(UPDATE_MENU_LABEL, DESKTOP_MENU_ITEM_UPDATES)
	help_popup.id_pressed.connect(_on_inline_desktop_help_menu_selected)
	_desktop_help_menu.add_child(help_popup)
	_desktop_help_menu.set_menu_title(0, "Help")
	add_child(_desktop_help_menu)


func _create_menu_item_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style


func _on_inline_desktop_help_menu_selected(item_id: int) -> void:
	match item_id:
		DESKTOP_MENU_ITEM_ABOUT:
			show_about_dialog()
		DESKTOP_MENU_ITEM_UPDATES:
			check_for_updates()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_ABOUT:
		show_about_dialog()


func _exit_tree() -> void:
	_remove_update_menu_item()


func show_about_dialog() -> void:
	if _about_dialog == null:
		return
	_version_label.text = "Version %s" % str(ProjectSettings.get_setting("application/config/version", "0.1.0"))
	_release_date_label.text = "Original release · %s" % _format_release_date()
	_about_dialog.popup_centered(ABOUT_WINDOW_SIZE)


func check_for_updates() -> void:
	if _update_dialog == null or _update_request == null or _checking_for_updates:
		return
	if _update_state in ["downloading", "ready", "installing"]:
		_update_dialog.popup_centered(UPDATE_WINDOW_SIZE)
		_clear_update_button_focus.call_deferred()
		return

	_checking_for_updates = true
	_update_state = "checking"
	_update_status_label.text = "Checking for Updates…"
	_update_message_label.text = "Checking for the latest version."
	_update_date_label.text = ""
	_update_date_label.visible = false
	_update_progress_bar.value = 0
	_update_progress_bar.indeterminate = true
	_update_progress_bar.visible = true
	_set_update_actions("", "Close")
	_update_dialog.popup_centered(UPDATE_WINDOW_SIZE)
	_clear_update_button_focus.call_deferred()

	var headers := PackedStringArray([
		"Accept: application/vnd.github+json",
		"X-GitHub-Api-Version: 2022-11-28",
		"User-Agent: Captain-Tsubasa-2-Remake"
	])
	var request_error := _update_request.request(UPDATE_RELEASE_API_URL, headers)
	if request_error != OK:
		_show_update_error()


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

	var background := _create_dialog_surface(_about_dialog)

	var margins := MarginContainer.new()
	margins.name = "Margins"
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margins.add_theme_constant_override("margin_left", UI_MARGIN_HORIZONTAL)
	margins.add_theme_constant_override("margin_top", UI_MARGIN_VERTICAL)
	margins.add_theme_constant_override("margin_right", UI_MARGIN_HORIZONTAL)
	margins.add_theme_constant_override("margin_bottom", UI_MARGIN_VERTICAL)
	background.add_child(margins)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 14)
	margins.add_child(content)

	var icon := TextureRect.new()
	icon.name = "ApplicationIcon"
	icon.texture = APPLICATION_ICON
	icon.custom_minimum_size = Vector2(72, 72)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(icon)

	var name_label := Label.new()
	name_label.name = "ApplicationName"
	name_label.text = APPLICATION_NAME
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", UI_FONT_HEADING)
	name_label.add_theme_color_override("font_color", Color(UI_TEXT_PRIMARY))
	content.add_child(name_label)

	_version_label = Label.new()
	_version_label.name = "Version"
	_version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_version_label.add_theme_font_size_override("font_size", UI_FONT_BODY)
	_version_label.add_theme_color_override("font_color", Color(UI_TEXT_SECONDARY))
	content.add_child(_version_label)

	_release_date_label = Label.new()
	_release_date_label.name = "ReleaseDate"
	_release_date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_release_date_label.add_theme_font_size_override("font_size", UI_FONT_BODY)
	_release_date_label.add_theme_color_override("font_color", Color(UI_TEXT_MUTED))
	content.add_child(_release_date_label)

	add_child(_about_dialog)


func _create_dialog_surface(dialog: Window) -> PanelContainer:
	var surface := PanelContainer.new()
	surface.name = "Background"
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(UI_SURFACE_COLOR)
	surface.add_theme_stylebox_override("panel", style)
	dialog.add_child(surface)
	return surface


func _create_update_dialog() -> void:
	_update_dialog = Window.new()
	_update_dialog.name = "UpdateDialog"
	_update_dialog.title = "Check for Updates"
	_update_dialog.size = UPDATE_WINDOW_SIZE
	_update_dialog.min_size = UPDATE_WINDOW_SIZE
	_update_dialog.unresizable = true
	_update_dialog.transient = true
	_update_dialog.exclusive = true
	_update_dialog.visible = false
	_update_dialog.close_requested.connect(_on_update_later_button_pressed)

	var background := _create_dialog_surface(_update_dialog)

	var margins := MarginContainer.new()
	margins.name = "Margins"
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margins.add_theme_constant_override("margin_left", UI_MARGIN_HORIZONTAL)
	margins.add_theme_constant_override("margin_top", UI_MARGIN_VERTICAL)
	margins.add_theme_constant_override("margin_right", UI_MARGIN_HORIZONTAL)
	margins.add_theme_constant_override("margin_bottom", UI_MARGIN_VERTICAL)
	background.add_child(margins)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", UI_SECTION_GAP)
	margins.add_child(content)

	var details := HBoxContainer.new()
	details.name = "Details"
	details.add_theme_constant_override("separation", 16)
	content.add_child(details)

	var icon := TextureRect.new()
	icon.name = "ApplicationIcon"
	icon.texture = APPLICATION_ICON
	icon.custom_minimum_size = Vector2(60, 60)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	details.add_child(icon)

	var details_text := VBoxContainer.new()
	details_text.name = "DetailsText"
	details_text.add_theme_constant_override("separation", 6)
	details_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_child(details_text)

	_update_status_label = Label.new()
	_update_status_label.name = "UpdateStatus"
	_update_status_label.text = "Checking for Updates…"
	_update_status_label.add_theme_font_size_override("font_size", UI_FONT_HEADING)
	_update_status_label.add_theme_color_override("font_color", Color(UI_TEXT_PRIMARY))
	_update_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	details_text.add_child(_update_status_label)

	_update_message_label = Label.new()
	_update_message_label.name = "UpdateMessage"
	_update_message_label.text = "Checking for the latest version."
	_update_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_update_message_label.add_theme_font_size_override("font_size", UI_FONT_BODY)
	_update_message_label.add_theme_color_override("font_color", Color(UI_TEXT_SECONDARY))
	details_text.add_child(_update_message_label)

	_update_date_label = Label.new()
	_update_date_label.name = "UpdateDate"
	_update_date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_update_date_label.add_theme_font_size_override("font_size", UI_FONT_METADATA)
	_update_date_label.add_theme_color_override("font_color", Color(UI_TEXT_MUTED))
	details_text.add_child(_update_date_label)

	_update_progress_bar = ProgressBar.new()
	_update_progress_bar.name = "UpdateProgress"
	_update_progress_bar.min_value = 0
	_update_progress_bar.max_value = 100
	_update_progress_bar.value = 0
	_update_progress_bar.show_percentage = false
	_update_progress_bar.custom_minimum_size = Vector2(0, 5)
	_update_progress_bar.visible = false
	_update_progress_bar.indeterminate = false
	_update_progress_bar.add_theme_stylebox_override("background", _create_update_progress_style(Color("383a3d")))
	_update_progress_bar.add_theme_stylebox_override("fill", _create_update_progress_style(Color(UI_ACCENT_COLOR)))
	content.add_child(_update_progress_bar)

	_update_action_button = Button.new()
	_update_action_button.name = "UpdateAction"
	_update_action_button.text = "OK"
	_update_action_button.custom_minimum_size = Vector2(0, UI_BUTTON_HEIGHT)
	_update_action_button.add_theme_font_size_override("font_size", UI_FONT_BODY)
	_update_action_button.add_theme_color_override("font_color", Color.WHITE)
	_update_action_button.add_theme_color_override("font_hover_color", Color.WHITE)
	_update_action_button.add_theme_color_override("font_pressed_color", Color.WHITE)
	_update_action_button.add_theme_color_override("font_disabled_color", Color("aeb8c4"))
	_update_action_button.add_theme_stylebox_override("normal", _create_update_button_style(Color(UI_ACCENT_COLOR)))
	_update_action_button.add_theme_stylebox_override("hover", _create_update_button_style(Color("2790ff")))
	_update_action_button.add_theme_stylebox_override("pressed", _create_update_button_style(Color("0874e5")))
	_update_action_button.add_theme_stylebox_override("disabled", _create_update_button_style(Color("3a4b5e")))
	_update_action_button.add_theme_stylebox_override("focus", _create_update_focus_style())
	_update_action_button.pressed.connect(_on_update_action_button_pressed)

	_update_later_button = Button.new()
	_update_later_button.name = "UpdateLater"
	_update_later_button.text = "Later"
	_update_later_button.custom_minimum_size = Vector2(0, UI_BUTTON_HEIGHT)
	_update_later_button.add_theme_font_size_override("font_size", UI_FONT_BODY)
	_update_later_button.add_theme_color_override("font_color", Color("d2d5d9"))
	_update_later_button.add_theme_color_override("font_hover_color", Color("f3f3f3"))
	_update_later_button.add_theme_color_override("font_pressed_color", Color("ffffff"))
	_update_later_button.add_theme_stylebox_override("normal", _create_update_button_style(Color("00000000")))
	_update_later_button.add_theme_stylebox_override("hover", _create_update_button_style(Color("303236")))
	_update_later_button.add_theme_stylebox_override("pressed", _create_update_button_style(Color("3a3d42")))
	_update_later_button.add_theme_stylebox_override("focus", _create_update_focus_style())
	_update_later_button.pressed.connect(_on_update_later_button_pressed)

	var button_row := HBoxContainer.new()
	button_row.name = "ButtonRow"
	button_row.alignment = BoxContainer.ALIGNMENT_END
	button_row.add_theme_constant_override("separation", 10)
	button_row.add_child(_update_later_button)
	button_row.add_child(_update_action_button)
	content.add_child(button_row)

	_update_request = HTTPRequest.new()
	_update_request.name = "UpdateRequest"
	_update_request.timeout = 12.0
	_update_request.request_completed.connect(_on_update_request_completed)
	add_child(_update_request)

	_update_download_request = HTTPRequest.new()
	_update_download_request.name = "UpdateDownloadRequest"
	_update_download_request.timeout = 0.0
	_update_download_request.use_threads = true
	_update_download_request.request_completed.connect(_on_update_download_completed)
	add_child(_update_download_request)
	add_child(_update_dialog)


func _create_update_button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(UI_BUTTON_RADIUS)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _create_update_progress_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(3)
	return style


func _create_update_focus_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("00000000")
	style.border_color = Color("8abfff")
	style.set_border_width_all(2)
	style.set_corner_radius_all(UI_BUTTON_RADIUS)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _set_update_actions(primary_text: String, secondary_text := "", primary_disabled := false) -> void:
	_update_action_button.text = primary_text
	_update_action_button.visible = not primary_text.is_empty()
	_update_action_button.disabled = primary_disabled
	_update_later_button.text = secondary_text
	_update_later_button.visible = not secondary_text.is_empty()
	_update_later_button.disabled = false
	_clear_update_button_focus.call_deferred()


func _clear_update_button_focus() -> void:
	if _update_action_button != null and _update_action_button.has_focus():
		_update_action_button.release_focus()
	if _update_later_button != null and _update_later_button.has_focus():
		_update_later_button.release_focus()


func _format_megabytes(byte_count: int) -> String:
	return "%.1f" % (float(byte_count) / 1048576.0)


func _process(_delta: float) -> void:
	if _update_state != "downloading" or _update_download_request == null:
		return

	var downloaded_bytes := _update_download_request.get_downloaded_bytes()
	var percent := 0
	if _update_asset_size > 0:
		percent = clampi(int(float(downloaded_bytes) * 100.0 / float(_update_asset_size)), 0, 99)
	_update_progress_bar.value = percent
	if percent != _last_download_percent:
		_last_download_percent = percent
		_update_message_label.text = "Downloading version %s · %s / %s MB" % [
			_update_available_version,
			_format_megabytes(downloaded_bytes),
			_format_megabytes(_update_asset_size)
		]


func _on_update_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_checking_for_updates = false
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		_show_update_error()
		return

	var release: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(release) != TYPE_DICTIONARY:
		_show_update_error()
		return

	var latest_tag := str(release.get("tag_name", ""))
	var latest_version := latest_tag.trim_prefix("v")
	var latest_parts := _parse_version(latest_version)
	var current_version := str(ProjectSettings.get_setting("application/config/version", "0.1.0"))
	var current_parts := _parse_version(current_version)
	if latest_parts.is_empty() or current_parts.is_empty():
		_show_update_error("The version information could not be read. Try again later.", "Version Information Unavailable")
		return

	var original_release_date := _format_release_date()
	_update_date_label.visible = not original_release_date.is_empty()
	if not original_release_date.is_empty():
		_update_date_label.text = "Original release · %s" % original_release_date

	if _compare_versions(latest_parts, current_parts) > 0:
		var update_asset := _find_platform_download_asset(release, latest_tag)
		if update_asset.is_empty():
			_show_update_unavailable("A download package for this platform is not available yet.")
			return
		var digest := str(update_asset.get("digest", ""))
		if not digest.begins_with("sha256:") or digest.length() != 71:
			_show_update_unavailable("The update package cannot be verified right now. Try again later.")
			return
		var asset_size := int(update_asset.get("size", 0))
		if asset_size <= 0:
			_show_update_unavailable("The update package is not available right now.")
			return

		_update_available_version = latest_version
		_update_asset_name = str(update_asset.get("name", ""))
		_update_download_url = str(update_asset.get("browser_download_url", ""))
		_update_expected_sha256 = digest.trim_prefix("sha256:").to_lower()
		_update_asset_size = asset_size
		_update_state = "available"
		_update_status_label.text = "Update Available"
		_update_message_label.text = _format_update_message(latest_version, current_version)
		_update_progress_bar.visible = false
		_update_progress_bar.indeterminate = false
		_set_update_actions("Download Update", "Later")
	else:
		_update_state = "current"
		_update_status_label.text = "You're up to date!"
		_update_message_label.text = "Version %s is the latest available." % latest_version
		_update_progress_bar.visible = false
		_update_progress_bar.indeterminate = false
		_set_update_actions("OK")
	_clear_update_button_focus.call_deferred()


func _show_update_error(message := "Check your connection and try again.", status := "Couldn't Check for Updates") -> void:
	_checking_for_updates = false
	_update_state = "error"
	_update_status_label.text = status
	_update_message_label.text = message
	_update_date_label.text = ""
	_update_date_label.visible = false
	_update_progress_bar.visible = false
	_update_progress_bar.indeterminate = false
	_set_update_actions("Try Again", "Close")


func _show_update_unavailable(message: String) -> void:
	_update_state = "unavailable"
	_update_status_label.text = "Update Unavailable"
	_update_message_label.text = message
	_update_progress_bar.visible = false
	_update_progress_bar.indeterminate = false
	_set_update_actions("Close")


func _on_update_action_button_pressed() -> void:
	match _update_state:
		"available":
			_start_update_download()
		"ready":
			_start_update_installer()
		"error":
			check_for_updates()
		_:
			_update_dialog.hide()


func _on_update_later_button_pressed() -> void:
	_update_dialog.hide()


func _find_platform_download_asset(release: Dictionary, latest_tag: String) -> Dictionary:
	var platform_suffix := ""
	match OS.get_name():
		"macOS":
			platform_suffix = "macos-universal.zip"
		"Windows":
			platform_suffix = "windows-x86_64.zip"
		"Linux":
			platform_suffix = "linux-x86_64.tar.gz"
		_:
			return {}

	var expected_name := "captain-tsubasa-2-remake-%s-%s" % [latest_tag, platform_suffix]
	var assets: Variant = release.get("assets", [])
	if typeof(assets) != TYPE_ARRAY:
		return {}

	for asset_value in assets:
		if typeof(asset_value) != TYPE_DICTIONARY:
			continue
		var asset: Dictionary = asset_value
		if str(asset.get("name", "")) != expected_name:
			continue
		var download_url := str(asset.get("browser_download_url", ""))
		if download_url.begins_with(UPDATE_ASSET_URL_PREFIX):
			return asset
	return {}


func _format_update_message(latest_version: String, current_version: String) -> String:
	var message := "Version %s is available. You're using version %s." % [latest_version, current_version]
	if OS.get_name() == "macOS":
		message += " After updating, macOS may ask you to approve opening the app."
	return message


func _start_update_download() -> void:
	var update_directory := ProjectSettings.globalize_path("user://update_staging")
	if DirAccess.make_dir_recursive_absolute(update_directory) != OK and not DirAccess.dir_exists_absolute(update_directory):
		_show_update_error("A local folder for the update could not be created. Check folder permissions and try again.", "Download Could Not Start")
		return

	_update_download_path = update_directory.path_join(_update_asset_name)
	if FileAccess.file_exists(_update_download_path):
		DirAccess.remove_absolute(_update_download_path)
	_update_download_request.download_file = _update_download_path
	_last_download_percent = -1
	_update_state = "downloading"
	_update_status_label.text = "Downloading Update…"
	_update_message_label.text = "Preparing the download for version %s." % _update_available_version
	_update_progress_bar.value = 0
	_update_progress_bar.visible = true
	_update_progress_bar.indeterminate = false
	_set_update_actions("", "Continue in Background")

	var request_error := _update_download_request.request(_update_download_url)
	if request_error != OK:
		_show_update_error("The update download could not be started. Try again.", "Download Could Not Start")


func _on_update_download_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		_show_update_error("Check your connection and try again.", "Download Failed")
		return

	var downloaded_sha256 := FileAccess.get_sha256(_update_download_path).to_lower()
	if downloaded_sha256.is_empty() or downloaded_sha256 != _update_expected_sha256:
		DirAccess.remove_absolute(_update_download_path)
		_show_update_error("The downloaded package could not be verified. Download the update again.", "Package Verification Failed")
		return

	_update_state = "ready"
	_update_status_label.text = "Ready to Install"
	_update_message_label.text = "Version %s has been downloaded and verified." % _update_available_version
	_update_progress_bar.value = 100
	_update_progress_bar.visible = true
	_update_progress_bar.indeterminate = false
	_set_update_actions("Install and Relaunch", "Later")


func _start_update_installer() -> void:
	var executable_path := OS.get_executable_path()
	var helper_resource := ""
	var helper_arguments := PackedStringArray()
	var helper_program := ""
	var status_path := ProjectSettings.globalize_path("user://update_staging/update_status.txt")
	var helper_path := ProjectSettings.globalize_path("user://update_staging/apply_update")
	var game_pid := str(OS.get_process_id())
	DirAccess.remove_absolute(status_path)

	match OS.get_name():
		"macOS":
			var app_bundle_path := _get_mac_app_bundle_path(executable_path)
			if app_bundle_path.is_empty():
				_show_update_error("The game app could not be located. Download and install the game again.", "Installation Could Not Start")
				return
			helper_resource = "res://scripts/updater/apply_update_macos.sh"
			helper_program = "/bin/sh"
			helper_arguments = PackedStringArray([helper_path, _update_download_path, app_bundle_path, game_pid, status_path])
		"Windows":
			helper_resource = "res://scripts/updater/apply_update_windows.ps1"
			helper_path += ".ps1"
			helper_program = "powershell.exe"
			helper_arguments = PackedStringArray([
				"-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", helper_path,
				game_pid, _update_download_path, executable_path, status_path
			])
		"Linux":
			helper_resource = "res://scripts/updater/apply_update_linux.sh"
			helper_program = "/bin/sh"
			helper_arguments = PackedStringArray([helper_path, _update_download_path, executable_path, game_pid, status_path])
		_:
			_show_update_unavailable("Automatic installation is not supported on this platform.")
			return

	if not FileAccess.file_exists(helper_resource):
		_show_update_error("Automatic installation could not be started. Download and install the game again.", "Installation Could Not Start")
		return
	var helper_source := FileAccess.get_file_as_string(helper_resource)
	if helper_source.is_empty():
		_show_update_error("The installer could not be read. Download the game again and try once more.", "Installation Could Not Start")
		return
	var helper_file := FileAccess.open(helper_path, FileAccess.WRITE)
	if helper_file == null:
		_show_update_error("The installer could not be prepared. Check folder permissions and try again.", "Installation Could Not Start")
		return
	helper_file.store_string(helper_source)
	helper_file.close()

	if OS.create_process(helper_program, helper_arguments) < 0:
		_show_update_error("The update installer could not be started. Try again.", "Installation Could Not Start")
		return

	_update_state = "installing"
	_update_status_label.text = "Installing Update…"
	_update_message_label.text = "The game will close and reopen when installation is complete."
	_update_progress_bar.indeterminate = true
	_update_progress_bar.visible = true
	_set_update_actions("", "")
	get_tree().quit()


func _get_mac_app_bundle_path(executable_path: String) -> String:
	var marker_index := executable_path.rfind(".app/")
	if marker_index < 0:
		return ""
	return executable_path.substr(0, marker_index + 4)


func _show_pending_update_result() -> void:
	var status_path := "user://update_staging/update_status.txt"
	if not FileAccess.file_exists(status_path):
		return
	var status_file := FileAccess.open(status_path, FileAccess.READ)
	if status_file == null:
		return
	var update_result := status_file.get_as_text().strip_edges()
	status_file.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(status_path))
	if update_result == "installed":
		_update_state = "current"
		_update_status_label.text = "Update Installed"
		_update_message_label.text = "The game is now running version %s." % str(ProjectSettings.get_setting("application/config/version", "0.1.0"))
		_update_progress_bar.visible = false
		_set_update_actions("OK")
		_update_dialog.popup_centered(UPDATE_WINDOW_SIZE)
		_clear_update_button_focus.call_deferred()
	elif update_result.begins_with("failed:"):
		_show_update_error(_format_install_failure(update_result), "Installation Failed")
		_update_dialog.popup_centered(UPDATE_WINDOW_SIZE)
		_clear_update_button_focus.call_deferred()


func _format_install_failure(result: String) -> String:
	match result.trim_prefix("failed:"):
		"folder":
			return "The game folder isn't writable. Move the game to a folder you own, then try again."
		"stage":
			return "The update couldn't be prepared. Check available disk space and try again."
		"unpack", "package":
			return "The downloaded package couldn't be opened. Download the update again and try once more."
		"identity":
			return "The downloaded app doesn't match this game. Download the update again."
		"security":
			return "macOS couldn't preserve the app's security settings. Reinstall the game, then try again."
		"backup":
			return "The current game couldn't be backed up. Check folder permissions and try again."
		"replace", "install":
			return "The update couldn't be installed. The previous version was restored."
		"relaunch":
			return "The updated game couldn't be reopened. The previous version was restored."
		"recovery":
			return "The update couldn't be completed. The previous version is saved beside the game for recovery."
		_:
			return "The update couldn't be completed. Check folder permissions and try again."


func _parse_version(version: String) -> Array[int]:
	var segments := version.split(".")
	if segments.size() != 3:
		return []
	var result: Array[int] = []
	for segment in segments:
		if not segment.is_valid_int():
			return []
		result.append(int(segment))
	return result


func _compare_versions(left: Array[int], right: Array[int]) -> int:
	for index in range(3):
		if left[index] > right[index]:
			return 1
		if left[index] < right[index]:
			return -1
	return 0


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


func _install_update_input_action() -> void:
	if not InputMap.has_action(UPDATE_INPUT_ACTION):
		InputMap.add_action(UPDATE_INPUT_ACTION)
	var f2_key := InputEventKey.new()
	f2_key.keycode = KEY_F2
	if not InputMap.action_has_event(UPDATE_INPUT_ACTION, f2_key):
		InputMap.action_add_event(UPDATE_INPUT_ACTION, f2_key)


func _install_update_menu_item() -> void:
	if OS.get_name() != "macOS":
		return
	if not NativeMenu.has_system_menu(NativeMenu.APPLICATION_MENU_ID):
		_retry_update_menu_install()
		return
	var application_menu := NativeMenu.get_system_menu(NativeMenu.APPLICATION_MENU_ID)
	if not application_menu.is_valid() or NativeMenu.find_item_index_with_tag(application_menu, UPDATE_MENU_TAG) >= 0:
		return

	var insertion_index := 0
	for index in range(NativeMenu.get_item_count(application_menu)):
		if NativeMenu.get_item_text(application_menu, index).begins_with("About"):
			insertion_index = index + 1
			break

	var inserted_index := NativeMenu.add_item(
		application_menu,
		UPDATE_MENU_LABEL,
		Callable(self, "_on_update_menu_selected"),
		Callable(),
		UPDATE_MENU_TAG,
		0,
		insertion_index
	)
	if inserted_index < 0:
		_retry_update_menu_install()


func _retry_update_menu_install() -> void:
	if not is_inside_tree():
		return
	var retry_timer := get_tree().create_timer(UPDATE_MENU_RETRY_SECONDS)
	retry_timer.timeout.connect(_install_update_menu_item)


func _remove_update_menu_item() -> void:
	if OS.get_name() != "macOS" or not NativeMenu.has_system_menu(NativeMenu.APPLICATION_MENU_ID):
		return
	var application_menu := NativeMenu.get_system_menu(NativeMenu.APPLICATION_MENU_ID)
	var item_index := NativeMenu.find_item_index_with_tag(application_menu, UPDATE_MENU_TAG)
	if item_index >= 0:
		NativeMenu.remove_item(application_menu, item_index)


func _on_update_menu_selected(_tag: Variant) -> void:
	check_for_updates()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed(ABOUT_INPUT_ACTION):
		show_about_dialog()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(UPDATE_INPUT_ACTION):
		check_for_updates()
		get_viewport().set_input_as_handled()
