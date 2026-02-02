extends FlipEffect
class_name ShuffleHandEffect

func apply(target: UnitCard, context: Dictionary = {}) -> void:
	super.apply(target, context)
	execute(target)

func execute(unit: UnitCard) -> bool:
	print("[ShuffleHandEffect] Executing for unit: ", unit.name)
	if unit == null or !is_instance_valid(unit):
		print("[ShuffleHandEffect] Unit invalid")
		return false
	
	# Check if any "Spider Egg" is on the board
	var has_egg: bool = false
	
	# Better way: use BattleEventBus to request units
	var context: Dictionary = { "units": [] }
	BattleEventBus.emit_signal("units_requested", "enemy", context)
	var enemies: Array = context.get("units", [])
	print("[ShuffleHandEffect] Found enemies count: ", enemies.size())
	
	for enemy in enemies:
		if enemy is UnitCard:
			print("[ShuffleHandEffect] Checking enemy: ", enemy.display_name)
			if "蜘蛛卵" in enemy.display_name:
				has_egg = true
				print("[ShuffleHandEffect] Found Spider Egg!")
				break
	
	if !has_egg:
		print("[ShuffleHandEffect] No Spider Egg found on board.")
		return false
		
	# Get HandView
	# We can try to find it via unique name or group
	var hand_view: HandView = unit.get_tree().root.find_child("HandView", true, false) as HandView
	if hand_view == null:
		print("[ShuffleHandEffect] HandView not found!")
		return false
		
	if hand_view.cards.is_empty():
		print("[ShuffleHandEffect] Hand is empty.")
		return false
		
	print("[ShuffleHandEffect] Shuffling hand cards...")
	# Shuffle Logic
	SoundManager.play_sfx("CardHover") # Or a dedicated shuffle sound if available
	
	for card_node in hand_view.cards:
		var card: Card = card_node as Card
		if card == null:
			continue
		
		# Rotate 1 to 3 times
		var rotations: int = randi_range(1, 3)
		print("[ShuffleHandEffect] Rotating card ", card.card_display_name, " by ", rotations, " times.")
		card.rotate_direction_numbers(true, rotations)
		
		# Visual feedback (small shake or flash could be added here)
		
	return true
