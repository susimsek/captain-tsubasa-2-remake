extends CanvasLayer
class_name ApplicationAbout
## Provides consistent desktop Help commands and About/update dialogs.

const APPLICATION_NAME := "Captain Tsubasa 2 Remake"
const DESKTOP_UI_THEME := preload("res://scripts/desktop_ui_theme.gd")
const UI_SURFACE_COLOR := DESKTOP_UI_THEME.SURFACE_COLOR
const UI_TEXT_PRIMARY := DESKTOP_UI_THEME.TEXT_PRIMARY_COLOR
const UI_TEXT_SECONDARY := DESKTOP_UI_THEME.TEXT_SECONDARY_COLOR
const UI_TEXT_MUTED := DESKTOP_UI_THEME.TEXT_MUTED_COLOR
const UI_MARGIN_HORIZONTAL := DESKTOP_UI_THEME.MARGIN_HORIZONTAL
const UI_MARGIN_VERTICAL := DESKTOP_UI_THEME.MARGIN_VERTICAL
const UI_SECTION_GAP := DESKTOP_UI_THEME.SECTION_GAP
const UI_FONT_HEADING := DESKTOP_UI_THEME.FONT_HEADING
const UI_FONT_BODY := DESKTOP_UI_THEME.FONT_BODY
const UI_FONT_METADATA := DESKTOP_UI_THEME.FONT_METADATA
const DESKTOP_MENU_HEIGHT := 7.0
const DESKTOP_MENU_VIEWPORT_SIZE := Vector2i(256, 231)
const DESKTOP_MENU_LOGICAL_SCALE := Vector2(0.25, 0.25)
const DESKTOP_MENU_ITEM_ABOUT := 1
const DESKTOP_MENU_ITEM_UPDATES := 2
const APPLICATION_ICON := preload("res://assets/branding/captain-tsubasa-2-icon.png")
const ABOUT_INPUT_ACTION := "application_about"
const UPDATE_INPUT_ACTION := "application_check_for_updates"
const ABOUT_WINDOW_SIZE := Vector2i(380, 230)
const UPDATE_WINDOW_SIZE := Vector2i(520, 280)
const UPDATE_RELEASE_API_URL := "https://api.github.com/repos/susimsek/captain-tsubasa-2-remake/releases/latest"
const UPDATE_ASSET_URL_PREFIX := "https://github.com/susimsek/captain-tsubasa-2-remake/releases/download/"
const UPDATE_SETTINGS_PATH := "user://update_settings.cfg"
const UPDATE_READY_METADATA_PATH := "user://update_staging/ready_update.cfg"
const UPDATE_AUTO_CHECK_DELAY := 3.0
const UPDATE_REMINDER_DELAY_SECONDS := 24 * 60 * 60
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
var _update_progress_bar: ProgressBar
var _auto_update_checkbox: CheckBox
var _update_action_button: Button
var _update_later_button: Button
var _update_skip_button: Button
var _update_request: HTTPRequest
var _update_download_request: HTTPRequest
var _update_asset_name := ""
var _update_download_url := ""
var _update_expected_sha256 := ""
var _update_available_version := ""
var _update_release_tag := ""
var _update_asset_size := 0
var _update_package_kind := "archive"
var _update_download_path := ""
var _last_download_percent := -1
var _update_state := "idle"
var _restored_ready_update := false
var _pending_update_result_dialog := false
var _background_update_check_deferred := false
var _checking_for_updates := false
var _interactive_update_check := false
var _automatic_update_checks_enabled := true
var _skipped_update_version := ""
var _remind_later_version := ""
var _remind_later_until := 0.0
var _desktop_help_menu: MenuBar


func _ready() -> void:
	_load_update_preferences()
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
	if _is_updater_enabled_for_this_build() and _automatic_update_checks_enabled:
		var auto_check_timer := get_tree().create_timer(UPDATE_AUTO_CHECK_DELAY)
		auto_check_timer.timeout.connect(_check_for_updates_in_background)


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
	menu_divider.color = Color(DESKTOP_UI_THEME.MENU_DIVIDER_COLOR)
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
	_desktop_help_menu.add_theme_stylebox_override("normal", DESKTOP_UI_THEME.create_menu_item_style(Color.TRANSPARENT))
	_desktop_help_menu.add_theme_stylebox_override("hover", DESKTOP_UI_THEME.create_menu_item_style(Color(DESKTOP_UI_THEME.MENU_HOVER_COLOR)))
	_desktop_help_menu.add_theme_stylebox_override("pressed", DESKTOP_UI_THEME.create_menu_item_style(Color(DESKTOP_UI_THEME.MENU_PRESSED_COLOR)))
	_desktop_help_menu.add_theme_stylebox_override("focus", DESKTOP_UI_THEME.create_menu_item_style(Color(DESKTOP_UI_THEME.MENU_HOVER_COLOR)))

	var help_popup := PopupMenu.new()
	help_popup.name = "Help"
	help_popup.add_theme_font_size_override("font_size", 14)
	help_popup.add_theme_color_override("font_color", Color(UI_TEXT_SECONDARY))
	help_popup.add_theme_color_override("font_hover_color", Color(UI_TEXT_PRIMARY))
	help_popup.add_theme_stylebox_override("panel", DESKTOP_UI_THEME.create_menu_item_style(Color(UI_SURFACE_COLOR)))
	help_popup.add_theme_stylebox_override("hover", DESKTOP_UI_THEME.create_menu_item_style(Color(DESKTOP_UI_THEME.MENU_HOVER_COLOR)))
	help_popup.add_item("About " + APPLICATION_NAME + "…", DESKTOP_MENU_ITEM_ABOUT)
	help_popup.add_item(UPDATE_MENU_LABEL, DESKTOP_MENU_ITEM_UPDATES)
	help_popup.id_pressed.connect(_on_inline_desktop_help_menu_selected)
	_desktop_help_menu.add_child(help_popup)
	_desktop_help_menu.set_menu_title(0, "Help")
	add_child(_desktop_help_menu)


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
	if _update_dialog == null or _update_request == null:
		return
	if (
		_update_state in ["available", "downloading", "ready", "installing"]
		and not (_update_state == "ready" and _restored_ready_update)
	):
		_update_dialog.popup_centered(UPDATE_WINDOW_SIZE)
		_clear_update_button_focus.call_deferred()
		return
	_interactive_update_check = true
	if _checking_for_updates:
		_update_dialog.popup_centered(UPDATE_WINDOW_SIZE)
		_clear_update_button_focus.call_deferred()
		return
	if not _is_updater_enabled_for_this_build():
		_show_update_unavailable("Updates are available in installed release builds.")
		_update_dialog.popup_centered(UPDATE_WINDOW_SIZE)
		return
	_checking_for_updates = true
	_update_state = "checking"
	_update_status_label.text = "Checking for Updates…"
	_update_message_label.text = "Checking for the latest version."
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


func _check_for_updates_in_background() -> void:
	if not _automatic_update_checks_enabled or not _is_updater_enabled_for_this_build():
		return
	if _checking_for_updates or _update_state in ["downloading", "installing"]:
		return
	if _pending_update_result_dialog and _update_dialog.visible:
		_background_update_check_deferred = true
		return
	if _update_state == "ready" and not _restored_ready_update:
		return
	_interactive_update_check = false
	_checking_for_updates = true
	if not _restored_ready_update:
		_update_state = "checking"
		_update_progress_bar.visible = false
	var headers := PackedStringArray([
		"Accept: application/vnd.github+json",
		"X-GitHub-Api-Version: 2022-11-28",
		"User-Agent: Captain-Tsubasa-2-Remake"
	])
	var request_error := _update_request.request(UPDATE_RELEASE_API_URL, headers)
	if request_error != OK:
		if not _preserve_restored_ready_update():
			_show_update_error()


func _finish_pending_update_result(resume_background_check: bool) -> void:
	if not _pending_update_result_dialog:
		return
	_pending_update_result_dialog = false
	if not _background_update_check_deferred:
		return
	_background_update_check_deferred = false
	if (
		not resume_background_check
		or not _automatic_update_checks_enabled
		or not _is_updater_enabled_for_this_build()
	):
		return
	var auto_check_timer := get_tree().create_timer(UPDATE_AUTO_CHECK_DELAY)
	auto_check_timer.timeout.connect(_check_for_updates_in_background)


func _is_updater_enabled_for_this_build() -> bool:
	var channel := str(ProjectSettings.get_setting("application/config/update_channel", "development"))
	var build_commit := str(ProjectSettings.get_setting("application/config/build_commit", ""))
	return channel == "stable" and build_commit.length() >= 7


func _get_update_target_path() -> String:
	var executable_path := OS.get_executable_path()
	match OS.get_name():
		"macOS":
			var app_bundle_path := _get_mac_app_bundle_path(executable_path)
			return app_bundle_path.get_base_dir() if not app_bundle_path.is_empty() else ""
		"Windows":
			return executable_path.get_base_dir()
		"Linux":
			var appimage_path := OS.get_environment("APPIMAGE").strip_edges()
			return appimage_path.get_base_dir() if not appimage_path.is_empty() else executable_path.get_base_dir()
	return ""


func _is_directory_writable(directory_path: String) -> bool:
	if directory_path.is_empty() or not DirAccess.dir_exists_absolute(directory_path):
		return false
	var probe_path := directory_path.path_join(
		".captain-tsubasa-update-check-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	)
	var probe_file := FileAccess.open(probe_path, FileAccess.WRITE)
	if probe_file == null:
		return false
	probe_file.close()
	return DirAccess.remove_absolute(probe_path) == OK


func _get_update_permission_message(package_kind: String = "") -> String:
	var target_directory := _get_update_target_path()
	if OS.get_name() == "Windows":
		var selected_package := package_kind
		if selected_package.is_empty():
			selected_package = "setup" if _windows_should_use_setup() else "archive"
		if selected_package == "setup":
			var per_user_directory := _get_windows_per_user_install_path()
			if per_user_directory.is_empty() or not _is_directory_writable_or_nearest_existing(per_user_directory):
				return "The per-user install folder can't be written to. Check your Windows account's folder permissions, then try again."
		elif target_directory.is_empty():
			return "The game installation could not be located. Reinstall the game, then try again."
		elif not _is_directory_writable(target_directory):
			return "This portable install folder can't be updated. Move the game to a folder you can write to, then try again."
	elif target_directory.is_empty():
		return "The game installation could not be located. Reinstall the game, then try again."
	elif not _is_directory_writable(target_directory):
		return "This install folder can't be updated. Move the game to a folder you can write to, then try again."

	if not _is_update_staging_path_writable():
		return "The update folder can't be written to. Check your account's folder permissions, then try again."
	return ""


func _get_windows_per_user_install_path() -> String:
	var local_app_data := OS.get_environment("LOCALAPPDATA").strip_edges()
	if local_app_data.is_empty():
		return ""
	return local_app_data.path_join("Programs").path_join(APPLICATION_NAME)


func _is_directory_writable_or_nearest_existing(directory_path: String) -> bool:
	var candidate := directory_path.simplify_path()
	while not candidate.is_empty():
		if DirAccess.dir_exists_absolute(candidate):
			return _is_directory_writable(candidate)
		var parent := candidate.get_base_dir()
		if parent == candidate:
			break
		candidate = parent
	return false


func _is_update_staging_path_writable() -> bool:
	var update_directory := ProjectSettings.globalize_path("user://update_staging")
	return _is_directory_writable_or_nearest_existing(update_directory)


func _windows_should_use_setup() -> bool:
	if OS.get_name() != "Windows":
		return false
	var target_directory := _get_update_target_path()
	if not _is_directory_writable(target_directory):
		return true
	var temp_directory := OS.get_environment("TEMP").replace("\\", "/").trim_suffix("/").to_lower()
	var executable_path := OS.get_executable_path().replace("\\", "/").to_lower()
	return not temp_directory.is_empty() and executable_path.begins_with(temp_directory + "/")


func _load_update_preferences() -> void:
	var preferences := ConfigFile.new()
	if preferences.load(UPDATE_SETTINGS_PATH) == OK:
		_automatic_update_checks_enabled = bool(preferences.get_value("updates", "automatic_checks", true))
		_skipped_update_version = str(preferences.get_value("updates", "skipped_version", ""))
		_remind_later_version = str(preferences.get_value("updates", "remind_later_version", ""))
		_remind_later_until = float(preferences.get_value("updates", "remind_later_until", 0.0))


func _save_update_preferences() -> void:
	var preferences := ConfigFile.new()
	preferences.load(UPDATE_SETTINGS_PATH)
	preferences.set_value("updates", "automatic_checks", _automatic_update_checks_enabled)
	preferences.set_value("updates", "skipped_version", _skipped_update_version)
	preferences.set_value("updates", "remind_later_version", _remind_later_version)
	preferences.set_value("updates", "remind_later_until", _remind_later_until)
	preferences.save(UPDATE_SETTINGS_PATH)


func _on_auto_update_checkbox_toggled(enabled: bool) -> void:
	_automatic_update_checks_enabled = enabled
	_save_update_preferences()


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

	var background := DESKTOP_UI_THEME.create_dialog_surface(_about_dialog)

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

	var background := DESKTOP_UI_THEME.create_dialog_surface(_update_dialog)

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

	_update_progress_bar = ProgressBar.new()
	_update_progress_bar.name = "UpdateProgress"
	_update_progress_bar.min_value = 0
	_update_progress_bar.max_value = 100
	_update_progress_bar.value = 0
	_update_progress_bar.show_percentage = false
	_update_progress_bar.custom_minimum_size = Vector2(0, 5)
	_update_progress_bar.visible = false
	_update_progress_bar.indeterminate = false
	_update_progress_bar.add_theme_stylebox_override("background", DESKTOP_UI_THEME.create_progress_style(Color(DESKTOP_UI_THEME.PROGRESS_TRACK_COLOR)))
	_update_progress_bar.add_theme_stylebox_override("fill", DESKTOP_UI_THEME.create_progress_style(DESKTOP_UI_THEME.palette_color(&"blue", 500)))
	content.add_child(_update_progress_bar)

	_auto_update_checkbox = CheckBox.new()
	_auto_update_checkbox.name = "AutomaticUpdateChecks"
	_auto_update_checkbox.text = "Automatically check for updates"
	_auto_update_checkbox.tooltip_text = "Checks for a new release after launch. Updates are never downloaded until you choose Download Update."
	_auto_update_checkbox.add_theme_font_size_override("font_size", UI_FONT_METADATA)
	_auto_update_checkbox.add_theme_color_override("font_color", Color(UI_TEXT_MUTED))
	_auto_update_checkbox.add_theme_color_override("font_hover_color", Color(UI_TEXT_SECONDARY))
	_auto_update_checkbox.set_pressed_no_signal(_automatic_update_checks_enabled)
	_auto_update_checkbox.toggled.connect(_on_auto_update_checkbox_toggled)
	content.add_child(_auto_update_checkbox)

	_update_action_button = Button.new()
	_update_action_button.name = "UpdateAction"
	_update_action_button.text = "OK"
	DESKTOP_UI_THEME.apply_button_style(_update_action_button, DESKTOP_UI_THEME.BUTTON_PRIMARY)
	_update_action_button.pressed.connect(_on_update_action_button_pressed)

	_update_later_button = Button.new()
	_update_later_button.name = "UpdateLater"
	_update_later_button.text = "Later"
	_update_later_button.tooltip_text = "Show this update reminder again after 24 hours."
	DESKTOP_UI_THEME.apply_button_style(_update_later_button, DESKTOP_UI_THEME.BUTTON_SECONDARY)
	_update_later_button.pressed.connect(_on_update_later_button_pressed)

	_update_skip_button = Button.new()
	_update_skip_button.name = "UpdateSkipVersion"
	_update_skip_button.text = "Skip This Version"
	_update_skip_button.tooltip_text = "Stop automatic reminders for this version."
	_update_skip_button.visible = false
	DESKTOP_UI_THEME.apply_button_style(_update_skip_button, DESKTOP_UI_THEME.BUTTON_SECONDARY)
	_update_skip_button.pressed.connect(_on_update_skip_button_pressed)

	var button_row := HBoxContainer.new()
	button_row.name = "ButtonRow"
	button_row.alignment = BoxContainer.ALIGNMENT_END
	button_row.add_theme_constant_override("separation", 10)
	button_row.add_child(_update_skip_button)
	var button_spacer := Control.new()
	button_spacer.name = "ButtonSpacer"
	button_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_row.add_child(button_spacer)
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


func _set_update_actions(primary_text: String, secondary_text := "", skip_text := "", primary_disabled := false) -> void:
	_update_action_button.text = primary_text
	_update_action_button.visible = not primary_text.is_empty()
	_update_action_button.disabled = primary_disabled
	_update_later_button.text = secondary_text
	_update_later_button.visible = not secondary_text.is_empty()
	_update_later_button.disabled = false
	_update_skip_button.text = skip_text
	_update_skip_button.visible = not skip_text.is_empty()
	_update_skip_button.disabled = false
	_clear_update_button_focus.call_deferred()


func _clear_update_button_focus() -> void:
	if _update_action_button != null and _update_action_button.has_focus():
		_update_action_button.release_focus()
	if _update_later_button != null and _update_later_button.has_focus():
		_update_later_button.release_focus()
	if _update_skip_button != null and _update_skip_button.has_focus():
		_update_skip_button.release_focus()


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
		if _preserve_restored_ready_update():
			return
		_show_update_error()
		return

	var release: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(release) != TYPE_DICTIONARY:
		if _preserve_restored_ready_update():
			return
		_show_update_error()
		return

	var latest_tag := str(release.get("tag_name", ""))
	var latest_version := latest_tag.trim_prefix("v")
	var latest_parts := _parse_version(latest_version)
	var current_version := str(ProjectSettings.get_setting("application/config/version", "0.1.0"))
	var current_parts := _parse_version(current_version)
	if latest_parts.is_empty() or current_parts.is_empty():
		if _preserve_restored_ready_update():
			return
		_show_update_error("The version information could not be read. Try again later.", "Version Information Unavailable")
		return

	if _restored_ready_update:
		var cached_package_kind := _update_package_kind
		var latest_asset := _find_platform_download_asset(release, latest_tag)
		var latest_digest := str(latest_asset.get("digest", "")).trim_prefix("sha256:").to_lower()
		var latest_size := int(latest_asset.get("size", 0))
		var cached_package_is_latest := (
			latest_version == _update_available_version
			and not latest_asset.is_empty()
			and _update_package_kind == cached_package_kind
			and str(latest_asset.get("name", "")) == _update_asset_name
			and latest_digest == _update_expected_sha256
			and latest_size == _update_asset_size
		)
		if cached_package_is_latest:
			_update_release_tag = latest_tag
			_update_state = "ready"
			_update_status_label.text = "Ready to Install"
			_update_message_label.text = "Version %s has been downloaded and verified." % _update_available_version
			_set_update_actions("Install and Relaunch", "Later")
			_restored_ready_update = false
			_interactive_update_check = false
			_clear_update_button_focus.call_deferred()
			return
		_clear_ready_update_cache()
		_restored_ready_update = false
		_update_state = "idle"

	if _compare_versions(latest_parts, current_parts) > 0:
		if not _interactive_update_check and latest_version == _skipped_update_version:
			_update_state = "skipped"
			_interactive_update_check = false
			return

		var update_asset := _find_platform_download_asset(release, latest_tag)
		if update_asset.is_empty():
			_show_update_unavailable("A download package for this platform is not available yet.")
			return
		var permission_message := _get_update_permission_message(_update_package_kind)
		if not permission_message.is_empty():
			_show_update_permission_blocked(latest_version, permission_message)
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
		_update_release_tag = latest_tag
		_update_asset_name = str(update_asset.get("name", ""))
		_update_download_url = str(update_asset.get("browser_download_url", ""))
		_update_expected_sha256 = digest.trim_prefix("sha256:").to_lower()
		_update_asset_size = asset_size

		_update_state = "available"
		_update_status_label.text = "Update Available"
		_update_message_label.text = _format_update_message(latest_version, current_version)
		_update_progress_bar.visible = false
		_update_progress_bar.indeterminate = false
		_set_update_actions("Download Update", "Remind Me Later", "Skip This Version")
		if not _interactive_update_check and not _is_update_reminder_active(latest_version):
			_update_dialog.popup_centered(UPDATE_WINDOW_SIZE)
			_clear_update_button_focus.call_deferred()
	else:
		_update_state = "current"
		_update_status_label.text = "You're up to date!"
		_update_message_label.text = "Version %s is the latest available." % latest_version
		_update_progress_bar.visible = false
		_update_progress_bar.indeterminate = false
		_set_update_actions("OK")
	_interactive_update_check = false
	_clear_update_button_focus.call_deferred()


func _show_update_error(message := "Check your connection and try again.", status := "Couldn't Check for Updates") -> void:
	_checking_for_updates = false
	_update_state = "error"
	_update_status_label.text = status
	_update_message_label.text = message
	_update_progress_bar.visible = false
	_update_progress_bar.indeterminate = false
	_set_update_actions("Try Again", "Close")


func _preserve_restored_ready_update() -> bool:
	if not _restored_ready_update:
		return false
	_restored_ready_update = false
	_checking_for_updates = false
	_interactive_update_check = false
	_update_state = "ready"
	_update_status_label.text = "Ready to Install"
	_update_message_label.text = "Version %s has been downloaded and verified." % _update_available_version
	_update_progress_bar.value = 100
	_update_progress_bar.visible = true
	_update_progress_bar.indeterminate = false
	_set_update_actions("Install and Relaunch", "Later")
	return true


func _show_update_unavailable(message: String, status := "Update Unavailable") -> void:
	_update_state = "unavailable"
	_update_status_label.text = status
	_update_message_label.text = message
	_update_progress_bar.visible = false
	_update_progress_bar.indeterminate = false
	_set_update_actions("Close")


func _show_update_permission_blocked(version: String, permission_message: String) -> void:
	var show_background_prompt := not _interactive_update_check and not _is_update_reminder_active(version)
	_update_available_version = version
	_show_update_unavailable(
		"Version %s is available. %s" % [version, permission_message], "Update Available"
	)
	_set_update_actions("Close", "Remind Me Later", "Skip This Version")
	_interactive_update_check = false
	if show_background_prompt:
		_update_dialog.popup_centered(UPDATE_WINDOW_SIZE)
	_clear_update_button_focus.call_deferred()


func _on_update_action_button_pressed() -> void:
	var dismissed_state := _update_state
	_finish_pending_update_result(dismissed_state == "current")
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
	if _update_state in ["available", "unavailable", "ready"] and not _update_available_version.is_empty():
		_remind_later_version = _update_available_version
		_remind_later_until = Time.get_unix_time_from_system() + UPDATE_REMINDER_DELAY_SECONDS
		if _skipped_update_version == _update_available_version:
			_skipped_update_version = ""
		_save_update_preferences()
	_update_dialog.hide()
	_finish_pending_update_result(true)


func _on_update_skip_button_pressed() -> void:
	if _update_state not in ["available", "unavailable"] or _update_available_version.is_empty():
		return
	_skipped_update_version = _update_available_version
	if _remind_later_version == _update_available_version:
		_remind_later_version = ""
		_remind_later_until = 0.0
	_save_update_preferences()
	_clear_ready_update_cache()
	_update_state = "skipped"
	_update_dialog.hide()


func _is_update_reminder_active(version: String) -> bool:
	if version != _remind_later_version:
		return false
	if Time.get_unix_time_from_system() < _remind_later_until:
		return true
	_remind_later_version = ""
	_remind_later_until = 0.0
	_save_update_preferences()
	return false


func _find_platform_download_asset(release: Dictionary, latest_tag: String) -> Dictionary:
	var platform_suffix := ""
	match OS.get_name():
		"macOS":
			platform_suffix = "macos-universal.zip"
		"Windows":
			_update_package_kind = "setup" if _windows_should_use_setup() else "archive"
			platform_suffix = "windows-x86_64-setup.exe" if _update_package_kind == "setup" else "windows-x86_64.zip"
		"Linux":
			_update_package_kind = "appimage" if _is_running_as_appimage() else "archive"
			platform_suffix = "x86_64.AppImage" if _is_running_as_appimage() else "linux-x86_64.tar.gz"
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


func _get_current_update_package_kind() -> String:
	match OS.get_name():
		"Windows":
			return "setup" if _windows_should_use_setup() else "archive"
		"Linux":
			return "appimage" if _is_running_as_appimage() else "archive"
		"macOS":
			return "archive"
	return ""


func _get_update_asset_suffix(package_kind: String) -> String:
	match OS.get_name():
		"macOS":
			return "macos-universal.zip" if package_kind == "archive" else ""
		"Windows":
			if package_kind == "setup":
				return "windows-x86_64-setup.exe"
			if package_kind == "archive":
				return "windows-x86_64.zip"
		"Linux":
			if package_kind == "appimage":
				return "x86_64.AppImage"
			if package_kind == "archive":
				return "linux-x86_64.tar.gz"
	return ""


func _save_ready_update_metadata() -> bool:
	var metadata := ConfigFile.new()
	metadata.set_value("update", "version", _update_available_version)
	metadata.set_value("update", "tag", _update_release_tag)
	metadata.set_value("update", "asset_name", _update_asset_name)
	metadata.set_value("update", "sha256", _update_expected_sha256)
	metadata.set_value("update", "size", _update_asset_size)
	metadata.set_value("update", "package_kind", _update_package_kind)
	return metadata.save(UPDATE_READY_METADATA_PATH) == OK


func _clear_ready_update_cache() -> void:
	var asset_names: Array[String] = []
	var metadata := ConfigFile.new()
	if metadata.load(UPDATE_READY_METADATA_PATH) == OK:
		var cached_asset_name := str(metadata.get_value("update", "asset_name", ""))
		if not cached_asset_name.is_empty() and cached_asset_name.get_file() == cached_asset_name:
			asset_names.append(cached_asset_name)
	if not _update_asset_name.is_empty() and _update_asset_name.get_file() == _update_asset_name:
		if not asset_names.has(_update_asset_name):
			asset_names.append(_update_asset_name)

	var staging_directory := ProjectSettings.globalize_path("user://update_staging")
	for asset_name in asset_names:
		var asset_path := staging_directory.path_join(asset_name)
		if FileAccess.file_exists(asset_path):
			DirAccess.remove_absolute(asset_path)
	var metadata_path := ProjectSettings.globalize_path(UPDATE_READY_METADATA_PATH)
	if FileAccess.file_exists(metadata_path):
		DirAccess.remove_absolute(metadata_path)


func _restore_ready_update() -> bool:
	if not _is_updater_enabled_for_this_build() or not FileAccess.file_exists(UPDATE_READY_METADATA_PATH):
		return false

	var metadata := ConfigFile.new()
	if metadata.load(UPDATE_READY_METADATA_PATH) != OK:
		_clear_ready_update_cache()
		return false

	var cached_version := str(metadata.get_value("update", "version", ""))
	var cached_tag := str(metadata.get_value("update", "tag", ""))
	var cached_asset_name := str(metadata.get_value("update", "asset_name", ""))
	var cached_sha256 := str(metadata.get_value("update", "sha256", "")).to_lower()
	var cached_size := int(metadata.get_value("update", "size", 0))
	var cached_package_kind := str(metadata.get_value("update", "package_kind", ""))
	var current_version := str(ProjectSettings.get_setting("application/config/version", "0.1.0"))
	var cached_parts := _parse_version(cached_version)
	var current_parts := _parse_version(current_version)
	var asset_suffix := _get_update_asset_suffix(cached_package_kind)
	var expected_asset_name := "captain-tsubasa-2-remake-%s-%s" % [cached_tag, asset_suffix]
	var cache_metadata_is_valid := (
		not cached_parts.is_empty()
		and not current_parts.is_empty()
		and cached_tag.begins_with("v")
		and cached_tag.trim_prefix("v") == cached_version
		and _compare_versions(cached_parts, current_parts) > 0
		and cached_package_kind == _get_current_update_package_kind()
		and not asset_suffix.is_empty()
		and cached_asset_name == expected_asset_name
		and cached_sha256.length() == 64
		and cached_size > 0
	)
	if not cache_metadata_is_valid:
		_clear_ready_update_cache()
		return false

	var package_path := ProjectSettings.globalize_path("user://update_staging").path_join(cached_asset_name)
	if not FileAccess.file_exists(package_path):
		_clear_ready_update_cache()
		return false
	var package_file := FileAccess.open(package_path, FileAccess.READ)
	if package_file == null:
		_clear_ready_update_cache()
		return false
	var actual_size := package_file.get_length()
	package_file.close()
	if actual_size != cached_size or FileAccess.get_sha256(package_path).to_lower() != cached_sha256:
		_clear_ready_update_cache()
		return false
	if not _get_update_permission_message(cached_package_kind).is_empty():
		return false

	_update_available_version = cached_version
	_update_release_tag = cached_tag
	_update_asset_name = cached_asset_name
	_update_expected_sha256 = cached_sha256
	_update_asset_size = cached_size
	_update_package_kind = cached_package_kind
	_update_download_path = package_path
	_update_state = "ready"
	_restored_ready_update = true
	_update_status_label.text = "Ready to Install"
	_update_message_label.text = "Version %s has been downloaded and verified." % cached_version
	_update_progress_bar.value = 100
	_update_progress_bar.visible = true
	_update_progress_bar.indeterminate = false
	_set_update_actions("Install and Relaunch", "Later")
	if not _is_update_reminder_active(cached_version):
		_update_dialog.popup_centered(UPDATE_WINDOW_SIZE)
		_clear_update_button_focus.call_deferred()
	return true


func _format_update_message(latest_version: String, current_version: String) -> String:
	return "%s %s is now available—you have %s. Would you like to download it now?" % [
		APPLICATION_NAME,
		latest_version,
		current_version
	]


func _is_running_as_appimage() -> bool:
	return OS.get_name() == "Linux" and not OS.get_environment("APPIMAGE").strip_edges().is_empty()


func _start_update_download() -> void:
	var permission_message := _get_update_permission_message(_update_package_kind)
	if not permission_message.is_empty():
		_show_update_unavailable(permission_message)
		return

	var update_directory := ProjectSettings.globalize_path("user://update_staging")
	if DirAccess.make_dir_recursive_absolute(update_directory) != OK and not DirAccess.dir_exists_absolute(update_directory):
		_show_update_error("A local folder for the update could not be created. Check folder permissions and try again.", "Download Could Not Start")
		return
	if not _is_directory_writable(update_directory):
		_show_update_error("The update folder can't be written to. Check your account's folder permissions, then try again.", "Download Could Not Start")
		return

	_clear_ready_update_cache()
	_update_download_path = update_directory.path_join(_update_asset_name)
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
	if _save_ready_update_metadata():
		_set_update_actions("Install and Relaunch", "Later")
	else:
		_update_message_label.text += " Keep this window open to install it; the package couldn't be saved for later."
		_set_update_actions("Install and Relaunch", "Close")


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
				game_pid, _update_download_path, executable_path, status_path, _update_package_kind
			])
		"Linux":
			helper_resource = "res://scripts/updater/apply_update_linux.sh"
			helper_program = "/bin/sh"
			var appimage_path := OS.get_environment("APPIMAGE").strip_edges()
			var linux_target := appimage_path if not appimage_path.is_empty() else executable_path
			var package_kind := "appimage" if not appimage_path.is_empty() else "archive"
			helper_arguments = PackedStringArray([
				helper_path, _update_download_path, linux_target, game_pid, status_path, package_kind
			])
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
	_update_progress_bar.indeterminate = false
	_update_progress_bar.visible = false
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
		_restore_ready_update()
		return
	var status_file := FileAccess.open(status_path, FileAccess.READ)
	if status_file == null:
		_restore_ready_update()
		return
	var update_result := status_file.get_as_text().strip_edges()
	status_file.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(status_path))
	if update_result == "installed":
		_clear_ready_update_cache()
		_update_state = "current"
		_update_status_label.text = "Update Installed"
		_update_message_label.text = "The game is now running version %s." % str(ProjectSettings.get_setting("application/config/version", "0.1.0"))
		_update_progress_bar.visible = false
		_set_update_actions("OK")
		_pending_update_result_dialog = true
		_update_dialog.popup_centered(UPDATE_WINDOW_SIZE)
		_clear_update_button_focus.call_deferred()
	elif update_result.begins_with("failed:"):
		_pending_update_result_dialog = true
		var failure_message := _format_install_failure(update_result)
		if _restore_ready_update():
			_update_status_label.text = "Installation Failed"
			_update_message_label.text = "%s The verified update is still available to retry." % failure_message
			_set_update_actions("Install and Relaunch", "Later")
			_update_dialog.popup_centered(UPDATE_WINDOW_SIZE)
			_clear_update_button_focus.call_deferred()
		else:
			_show_update_error(failure_message, "Installation Failed")
			_update_dialog.popup_centered(UPDATE_WINDOW_SIZE)
			_clear_update_button_focus.call_deferred()
	else:
		_restore_ready_update()


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
			return "The updated game couldn't be reopened. Your previous copy is still available."
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
