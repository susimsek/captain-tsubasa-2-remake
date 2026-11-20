extends SceneTree

const RESOLVER := preload("res://scripts/gameplay/rom_scenario36_fd00_mirror_resolver.gd")

var _failed := false


func _init() -> void:
	var resolver: RefCounted = RESOLVER.new()
	_check(resolver.configure(), "hash-checked scenario-$36 `$FD $00` sources configure")
	if _failed:
		quit(1)
		return

	var ram := PackedByteArray()
	ram.resize(0x800)
	ram[0x0441] = 0
	var initial: Dictionary = resolver.execute(ram)
	_check(bool(initial.get("ok", false)), "live RAM resolves the ROM player-record pointer")
	if _failed:
		quit(1)
		return

	var record_base := int(initial.get("player_record_cpu_address", -1))
	_check(record_base >= 0x0300 and record_base + 8 < ram.size(), "resolved player record fits RAM")
	if _failed:
		quit(1)
		return

	# $0638=13 gives quotient=1/remainder=1, so the source helper returns
	# X=$3C and Y=$5C. The record values distinguish the two comparisons:
	# Y >= record[+8] ($58), while X < record[+6] ($40).
	ram[0x0638] = 13
	ram[record_base + 8] = 0x58
	ram[record_base + 6] = 0x40
	var result: Dictionary = resolver.execute(ram)
	_check(bool(result.get("ok", false)), "source-derived FD00 executes for live RAM")
	_check(int(result.get("division_quotient", -1)) == 1
		and int(result.get("division_remainder", -1)) == 1,
		"$CDC9 quotient and remainder match the test input")
	_check(int(result.get("compare_value_for_record_08", -1)) == 0x5C
		and int(result.get("compare_value_for_record_06", -1)) == 0x3C,
		"ROM helper's Y and X values remain distinct for the two record fields")
	_check(result.get("borrow_flags", []) == [false, true]
		and int(result.get("comparison_count", -1)) == 2
		and int(result.get("mirror_flag", -1)) == 0,
		"$8877 uses Y for record +8 and X for record +6 when deriving the mirror flag")
	if _failed:
		quit(1)
		return

	print("PASS: scenario-$36 `$FD $00` uses ROM `$CDC9` Y/X outputs for the matching `$8877` record comparisons.")
	quit(0)


func _check(condition: bool, label: String) -> void:
	if condition:
		return
	_failed = true
	push_error("FAIL: " + label)
