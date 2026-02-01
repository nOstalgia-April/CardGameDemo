extends Control

signal restart_level

@onready var defeat_label = $VBoxContainer/DefeatLabel as Label
@onready var info_label = $VBoxContainer/InfoLabel
@onready var press_key_label = $VBoxContainer/PressKeyLabel
@onready var animation_player = $AnimationPlayer
@onready var defeat_sound = $DefeatSound

var can_input = false

func _ready():
	hide()
	defeat_label.visible = false
	info_label.visible = false
	press_key_label.visible = false
	animation_player.stop()

func open():
	visible = true
	defeat_label.visible = true
	defeat_sound.play()
	defeat_label.set_anchors_preset(Control.PRESET_CENTER)
	defeat_label.offset_left = -defeat_label.size.x / 2
	defeat_label.offset_top = -defeat_label.size.y / 2
	defeat_label.offset_right = defeat_label.size.x / 2
	defeat_label.offset_bottom = defeat_label.size.y / 2
	defeat_label.pivot_offset = Vector2(defeat_label.size.x / 2, defeat_label.size.y / 2)
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(defeat_label, "rotation_degrees", 15, 0.5)
	tween.tween_property(defeat_label, "rotation_degrees", -15, 0.5)
	await get_tree().create_timer(2.0).timeout
	defeat_label.visible = false
	info_label.visible = true
	press_key_label.visible = true
	animation_player.play("blink")
	can_input = true

func _input(event):
	if can_input:
		if event is InputEventMouseButton or event is InputEventKey:
			restart_level.emit()
			can_input = false
