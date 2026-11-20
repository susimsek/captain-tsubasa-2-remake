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
## The title selector's ROM-executed `$A8BB` roster loop writes these player IDs
## before the cutscene-to-match scheduler handoff. Keep the source receipt so
## the later scheduler can adopt only those writes, not a captured RAM image.
var selector_roster_write_receipt: Dictionary = {}
## Bounded ROM `$811F->$C572->$DB62` result. The live scheduler adopts only
## its ordered energy-record writes; the rest of its source RAM remains owned
## by the existing task context.
var stamina_initialization_receipt: Dictionary = {}


func to_period_task_inputs() -> Dictionary:
	return {
		"task_slot_base": task_slot_base,
		"entry_pc": entry_pc,
		"entry_sp": entry_sp,
		"period_0027": period_0027,
		"opponent_id_002b": opponent_id_002b,
		"source_context": provenance.duplicate(true),
		"scheduler_dispatch": scheduler_dispatch.duplicate(true),
		"selector_roster_write_receipt": selector_roster_write_receipt.duplicate(true),
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
		"selector_roster_write_count": selector_roster_write_receipt.get("ram_writes", []).size(),
		"stamina_initialization_write_count": int(stamina_initialization_receipt.get("energy_write_count", 0)),
	}
