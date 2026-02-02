extends FlipEffect
class_name ChangeFlippedArtEffect

func apply(target: UnitCard, context: Dictionary = {}) -> void:
	super.apply(target, context)
	if unit == null or unit.death_transform == null:
		return

	unit.art.texture = unit._card_art_flipped
