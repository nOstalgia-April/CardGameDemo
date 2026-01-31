extends CanvasLayer

signal restart_level

var can_input: bool = false

func _ready():
	hide()
	can_input = false

func open():
	show()
	find_child("DefeatLabel").show()
	await get_tree().create_timer(0.5).timeout
	find_child("PressKeyLabel").show()
	var animation_player = find_child("AnimationPlayer")
	if animation_player:
		animation_player.play("blink_1")
	var defeat_sound = find_child("DefeatSound")
	if defeat_sound:
		defeat_sound.play()
	can_input = true

func _input(event):
	if can_input and event.is_pressed():
		restart_level.emit()