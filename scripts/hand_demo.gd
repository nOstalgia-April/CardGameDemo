extends Control

@onready var hand_view: HandView = $HandView
@onready var add_button: Button = $VBox/AddCardButton

func _ready() -> void:
	add_button.pressed.connect(_on_add_pressed)

func _on_add_pressed() -> void:
	hand_view.add_card()
