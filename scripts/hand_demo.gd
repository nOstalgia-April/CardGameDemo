extends Control

@onready var hand_view: Node = $VBox/HandView
@onready var add_button: Button = $VBox/AddCardButton

func _ready() -> void:
	add_button.pressed.connect(_on_add_pressed)

func _on_add_pressed() -> void:
	if hand_view and hand_view.has_method("add_card"):
		hand_view.call("add_card")
