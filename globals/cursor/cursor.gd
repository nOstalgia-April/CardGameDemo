extends TextureRect

@export var Default : Texture2D
@export var Clicking : Texture2D
@export var CursorScale : = 0.7
@onready var hotspot: Control = %Hotspot

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var offset := hotspot.position
	scale = CursorScale * Vector2i.ONE
	position = get_viewport().get_mouse_position() - offset
	if Input.is_mouse_button_pressed(MouseButton.MOUSE_BUTTON_LEFT):
		texture = Clicking 
	else:
		texture = Default
	pass
