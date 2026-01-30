extends CanvasLayer

@export var default_duration := 0.1
@export var fade_texture: Texture2D

@onready var _rect: ColorRect = $ColorRect
@onready var _texture_rect: TextureRect = $TextureRect

var _tween: Tween
var _active_fade_texture: Texture2D
var _next_fade_texture: Texture2D

func _ready() -> void:
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect_alpha(0.0)
	_set_texture_alpha(0.0)
	hide()

func prepare(_scene_key: String) -> void:
	_next_fade_texture = fade_texture

func fade_out(duration: float = -1.0) -> void:
	var d := default_duration if duration < 0.0 else duration
	show()
	_kill_tween()

	_active_fade_texture = _next_fade_texture
	if _active_fade_texture != null:
		_rect.visible = false
		_texture_rect.visible = true
		_texture_rect.texture = _active_fade_texture
		_set_texture_alpha(0.0)
		_tween = create_tween()
		_tween.tween_property(_texture_rect, "modulate:a", 1.0, d)
		await _tween.finished
		return

	_texture_rect.visible = false
	_rect.visible = true
	_set_rect_alpha(0.0)
	_tween = create_tween()
	_tween.tween_property(_rect, "color:a", 1.0, d)
	await _tween.finished

func fade_in(duration: float = -1.0) -> void:
	var d := default_duration if duration < 0.0 else duration
	show()
	_kill_tween()

	if _active_fade_texture != null:
		_rect.visible = false
		_texture_rect.visible = true
		_texture_rect.texture = _active_fade_texture
		_set_texture_alpha(1.0)
		_tween = create_tween()
		_tween.tween_property(_texture_rect, "modulate:a", 0.0, d)
		await _tween.finished
		_active_fade_texture = null
		hide()
		return

	_texture_rect.visible = false
	_rect.visible = true
	_set_rect_alpha(1.0)
	_tween = create_tween()
	_tween.tween_property(_rect, "color:a", 0.0, d)
	await _tween.finished
	hide()

func _set_rect_alpha(a: float) -> void:
	var c := _rect.color
	c.a = clampf(a, 0.0, 1.0)
	_rect.color = c

func _set_texture_alpha(a: float) -> void:
	var c := _texture_rect.modulate
	c.a = clampf(a, 0.0, 1.0)
	_texture_rect.modulate = c

func _kill_tween() -> void:
	if _tween != null and _tween.is_running():
		_tween.kill()
	_tween = null
