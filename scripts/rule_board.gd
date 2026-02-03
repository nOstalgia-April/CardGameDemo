extends Control
@onready var label: Label = $TextureButton/Label

@onready var texture_button: TextureButton = $TextureButton
@onready var rule_label: Label = $TextureButton/CenterContainer/Rule
@onready var center_container: CenterContainer = $TextureButton/CenterContainer
@onready var b_board: Control = $TextureButton/B_Board

const COLLAPSED_Y: float = -570.0
const EXPANDED_Y: float = -30.0
const ANIM_DURATION: float = 0.3

var _tween: Tween

func _ready() -> void:
	BattleEventBus.request_scene.connect(_on_scene_change_requested)
	rule_label.visible = false
	print("[RuleBoard] _ready called")
	# Ensure the button starts at the collapsed position
	if texture_button:
		print("[RuleBoard] TextureButton found")
		texture_button.position.y = COLLAPSED_Y
		texture_button.mouse_entered.connect(_on_mouse_entered)
		texture_button.mouse_exited.connect(_on_mouse_exited)
	else:
		print("[RuleBoard] TextureButton NOT found!")
	
	# Ensure the label doesn't block mouse events so we can hover the button underneath
	if label:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		print("[RuleBoard] Label configured to IGNORE mouse")
	
	# Ensure the rule content label also ignores mouse events so they pass to the button
	if rule_label:
		rule_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if center_container:
		center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_mouse_entered() -> void:
	print("[RuleBoard] Mouse Entered!")
	if _tween:
		_tween.kill()
	
	label.visible = false
	rule_label.visible = true
	SoundManager.play_sfx('UiWoodHover')
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(texture_button, "position:y", EXPANDED_Y, ANIM_DURATION)

func _on_mouse_exited() -> void:
	print("[RuleBoard] Mouse Exited!")
	if _tween:
		_tween.kill()
	label.visible = true
	rule_label.visible = false
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(texture_button, "position:y", COLLAPSED_Y, ANIM_DURATION)
	await _tween.finished

func _on_scene_change_requested(scene_key: String, payload: Dictionary) -> void:
	match scene_key:
		'level_select':
			b_board.visible = false
			return
		'battle':
			b_board.visible = true
			return
	b_board.visible = true
	pass

func _process(delta: float) -> void:
	var scene_key = get_tree().current_scene.name
	if scene_key == 'LevelSelect':
		b_board.visible = false
	else:
		b_board.visible = true
