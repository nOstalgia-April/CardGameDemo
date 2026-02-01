extends FlipEffect
class_name TransformEffect

func apply(target: UnitCard, context: Dictionary = {}) -> void:
	super.apply(target, context)
	if unit == null or unit.death_transform == null:
		return

	var new_data: EnemyData = unit.death_transform
	# Apply new data (true = is_enemy)
	unit.apply_enemy_data(new_data, unit.is_enemy)
	
	# If the new form has an effect (e.g. entrance effect or immediate trigger), apply it
	# Note: UnitCard.flip() will call _on_flip() after this returns, updating visuals
	if unit.effect_id != "":
		# We need to access the registry to apply the new effect
		# Since we can't easily import the Registry here due to cyclic dependency risk if not careful,
		# we rely on the fact that UnitCard.flip logic might handle it, OR we call it dynamically.
		# However, UnitCard.flip() logic is:
		# 1. Apply Effect (this TransformEffect)
		# 2. _flipped = true
		# 3. _on_flip()
		# So the new form's effect won't be automatically triggered by the CURRENT flip() call 
		# because we are currently executing the effect of the OLD form.
		
		# So we should trigger the new form's effect here if desired.
		# Using dynamic access to avoid cyclic preload issues if Registry preloads this script.
		var registry = load("res://scripts/effects/flip_effect_registry.gd")
		if registry:
			await registry.apply(unit.effect_id, unit, context)
