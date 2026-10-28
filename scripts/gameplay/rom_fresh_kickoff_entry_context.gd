extends RefCounted
class_name RomFreshKickoffEntryContext
## Typed source-owned inputs for the bounded first slot-$05 fresh-period task.

var match_index: int = -1
var period_0027: int = -1
var opponent_id_002b: int = -1
var task_slot_base: int = -1
var entry_pc: int = -1
var entry_sp: int = -1
var scheduler_dispatch: Dictionary = {}
var provenance: Dictionary = {}


func to_period_task_inputs() -> Dictionary:
	return {
		"task_slot_base": task_slot_base,
		"entry_pc": entry_pc,
		"entry_sp": entry_sp,
		"period_0027": period_0027,
		"opponent_id_002b": opponent_id_002b,
		"source_context": provenance.duplicate(true),
		"scheduler_dispatch": scheduler_dispatch.duplicate(true),
	}


func to_dictionary() -> Dictionary:
	return {
		"ok": match_index >= 0 and period_0027 >= 0 and opponent_id_002b >= 0 \
				and task_slot_base >= 0 and entry_pc >= 0 and entry_sp >= 0,
		"match_index": match_index,
		"period_0027": period_0027,
		"opponent_id_002b": opponent_id_002b,
		"task_slot_base": task_slot_base,
		"entry_pc": entry_pc,
		"entry_sp": entry_sp,
		"scheduler_dispatch": scheduler_dispatch.duplicate(true),
		"provenance": provenance.duplicate(true),
	}
