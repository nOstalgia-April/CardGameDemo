extends Node
class_name FlipEffectRegistry

const _EFFECTS: Dictionary = {
	"charge": preload("res://scripts/effects/charge_effect.gd"),
	"rotate": preload("res://scripts/effects/rotate_effect.gd"),
	"knockback": preload("res://scripts/effects/knockback_effect.gd"),
	"heal_adjacent": preload("res://scripts/effects/heal_adjacent_effect.gd"),
	"heal_self": preload("res://scripts/effects/heal_self_effect.gd"),
	"swap": preload("res://scripts/effects/swap_effect.gd"),
	"change_portrait": preload("res://scripts/effects/change_portrait_effect.gd"),
	"transform": preload("res://scripts/effects/transform_effect.gd"),
	"shuffle_hand": preload("res://scripts/effects/shuffle_hand_effect.gd"),
	"advantage_attack": preload("res://scripts/effects/advantage_attack_effect.gd"),
}

static func apply(effect_id: String, unit: UnitCard, context: Dictionary = {}) -> void:
	if effect_id == "" or unit == null:
		return
	var script: Script = _EFFECTS.get(effect_id, null)
	if script == null:
		return
	var effect: FlipEffect = script.new()
	if effect.persistent:
		unit._register_effect(effect_id, effect)
	await effect.apply(unit, context)
