extends Node
class_name TurnManager

signal turn_started(turn_index: int)
signal resources_changed(energy: int, energy_cap: int, flips_left: int)
signal request_turn_resolution(units: Array)
signal turn_resolution_finished

@export var start_energy: int = 0
@export var max_energy: int = 10
@export var flip_per_turn: int = 1

var turn_index: int = 0
var energy_cap: int = 0
var energy: int = 0
var flips_left: int = 0

func _ready() -> void:
	start_turn()

func next_turn(units: Array = []) -> void:
	emit_signal("request_turn_resolution", units)
	await turn_resolution_finished
	start_turn()

func start_turn() -> void:
	turn_index += 1
	if turn_index == 1:
		energy_cap = clamp(start_energy, 0, max_energy)
	else:
		energy_cap = clamp(energy_cap + 1, 0, max_energy)
	energy = energy_cap
	flips_left = max(0, flip_per_turn)
	emit_signal("turn_started", turn_index)
	emit_signal("resources_changed", energy, energy_cap, flips_left)

func spend_energy(cost: int) -> bool:
	if cost <= 0:
		return true
	if energy < cost:
		return false
	energy -= cost
	emit_signal("resources_changed", energy, energy_cap, flips_left)
	return true

func use_flip() -> bool:
	if flips_left <= 0:
		return false
	flips_left -= 1
	emit_signal("resources_changed", energy, energy_cap, flips_left)
	return true
