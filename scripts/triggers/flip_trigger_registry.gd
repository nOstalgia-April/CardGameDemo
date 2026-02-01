extends Node
class_name FlipTriggerRegistry

const _TRIGGERS: Dictionary = {
	"input": preload("res://scripts/triggers/flip_trigger.gd"),
	"on_place": preload("res://scripts/triggers/on_place_trigger.gd"),
	"none": preload("res://scripts/triggers/null_flip_trigger.gd"),
	"death": preload("res://scripts/triggers/death_trigger.gd"),
	"turn_start": preload("res://scripts/triggers/turn_start_trigger.gd"),
	"parity_change": preload("res://scripts/triggers/parity_change_trigger.gd"),
}

static func create(trigger_id: String) -> FlipTrigger:
	var resolved_id: String = trigger_id
	if resolved_id == "":
		resolved_id = "none"
	var script: Script = _TRIGGERS.get(resolved_id, null)
	if script == null:
		script = _TRIGGERS.get("none")
	return script.new()
