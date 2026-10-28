extends SceneTree

const INPUT_SCRIPT := preload("res://scripts/gameplay/pre_match_meeting_menu_input.gd")

var _input: Node
var _confirmed: Array[int] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_input = INPUT_SCRIPT.new() as Node
	root.add_child(_input)
	_input.connect("option_confirmed", _on_confirmed)
	await process_frame

	_expect(int(_input.get("cursor_y")) == 0x98 and int(_input.get("selected_option_index")) == 0,
		"MEETING cursor must begin on ROM row $98.")
	_input.call("move_up")
	_input.call("flush_pending_input")
	_expect(int(_input.get("cursor_y")) == 0xC8 and int(_input.get("selected_option_index")) == 3,
		"Up from the first row must wrap to the final row.")
	_input.call("move_down")
	_input.call("flush_pending_input")
	_expect(int(_input.get("cursor_y")) == 0x98 and int(_input.get("selected_option_index")) == 0,
		"Down from the final row must wrap to the first row.")
	_input.call("move_down")
	_input.call("flush_pending_input")
	_input.call("move_down")
	_input.call("flush_pending_input")
	_input.call("move_down")
	_input.call("flush_pending_input")
	_expect(int(_input.get("cursor_y")) == 0xC8 and int(_input.get("selected_option_index")) == 3,
		"Three Down presses must select the ROM $06 KICK OFF row.")
	_input.call("confirm")
	_input.call("flush_pending_input")
	_expect(_confirmed == [3], "Confirm must report the currently selected KICK OFF row.")
	_expect(int(_input.get("cursor_y")) == 0xC8, "Confirmation must not move the cursor.")

	print("PASS: ROM MEETING menu starts at $98, moves/wraps by $10, and confirms the fourth row at $C8.")
	_input.queue_free()
	await process_frame
	quit(0)


func _on_confirmed(option_index: int) -> void:
	_confirmed.append(option_index)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
