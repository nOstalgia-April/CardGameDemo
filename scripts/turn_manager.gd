extends Node
class_name TurnManager
var mouse_tool_tip := preload("res://tscns/ui/mouse_tooltip.tscn")
@export_group("Refs")
@export var board: Board

@export_group("Config")
@export var start_energy: int = 1
@export var max_energy: int = 4
@export var flip_per_turn: int = 1
@export_group("")

var turn_index: int = 0
var energy_cap: int = 0
var energy: int = 0
var flips_left: int = 0
var _resolving_turn: bool = false

func _ready() -> void:
	BattleEventBus.unit_placed.connect(_on_unit_placed)
	pass

func start_turn() -> void:
	turn_index += 1
	if turn_index == 1:
		energy_cap = clamp(start_energy, 0, max_energy)
	else:
		energy_cap = clamp(energy_cap + 1, 0, max_energy)
	energy = energy_cap
	flips_left = max(0, flip_per_turn)
	_emit_turn_started()
	_emit_resource_changed()

func end_turn() -> void:
	if _resolving_turn:
		return
	_resolving_turn = true
	BattleEventBus.emit_signal("turn_ended", turn_index, {})
	BattleEventBus.emit_signal("turn_banner_requested", "敌方回合", {
		"team": "enemy",
		"play_sfx": true,
		"expand": true,
	})
	await BattleEventBus.turn_banner_finished
	await board.resolve_enemy_turn()
	_resolving_turn = false
	start_turn()

func can_spend_energy(cost: int) -> bool:
	if cost <= 0:
		return true
	var cannot := energy < cost
	if cannot:
		no_cost_hint()
	return energy >= cost

func spend_energy(cost: int) -> bool:
	if cost <= 0:
		return true
	if energy < cost:
		return false
	energy -= cost
	_emit_resource_changed()
	return true

func can_use_flip() -> bool:
	return flips_left > 0

func use_flip() -> bool:
	if flips_left <= 0:
		return false
	flips_left -= 1
	_emit_resource_changed()
	return true

func _emit_turn_started() -> void:
	BattleEventBus.emit_signal("turn_started", turn_index, {})

func _emit_resource_changed() -> void:
	BattleEventBus.emit_signal("resource_changed", energy, flips_left, {
		"energy_cap": energy_cap,
	})

func _on_unit_placed(_unit: Node, _cell: Node, _context: Dictionary) -> void:
	print(turn_index)
	
func no_cost_hint() -> void:
	print("hehe")
	SoundManager.play_sfx("HandviewNoCostError")
