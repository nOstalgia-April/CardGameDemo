extends FlipEffect
class_name ChangePortraitEffect

@export var portrait_texture: Texture2D = preload("res://assets/Portraits/enemy2.png")

func apply(target: UnitCard, context: Dictionary = {}) -> void:
	super.apply(target, context)
	if unit == null:
		return
	
	# Try to find the GameController by traversing up from the unit
	var node = unit
	var game_controller = null
	while node != null:
		if node.get("portrait") and node.portrait is Sprite2D:
			game_controller = node
			break
		node = node.get_parent()
		
	# Fallback: Check current_scene
	if game_controller == null:
		var root = unit.get_tree().current_scene
		if root and root.get("portrait") and root.portrait is Sprite2D:
			game_controller = root

	if game_controller != null:
		game_controller.portrait.texture = portrait_texture
		# Force update if necessary, but texture assignment should be enough
	else:
		push_warning("ChangePortraitEffect: Could not find 'portrait' node (GameController) in scene tree.")
		# Debug print to help identify structure if it fails
		var root = unit.get_tree().current_scene
		print("Current scene root: ", root.name, " (", root, ")")

