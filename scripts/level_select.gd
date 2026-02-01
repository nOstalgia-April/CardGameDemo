extends Node2D

@export var hover_color: Color = Color(1, 1, 1, 0.9)
@export var select_color: Color = Color(1, 0.2, 0.2, 1)

@export var BGM: AudioStream

@onready var board: Board = %Board
@onready var grid: GridContainer = board.get_node("GridContainer") as GridContainer
@onready var hand_view: HandView = %HandView
@onready var hud: Control = get_node_or_null("Root/HUD") as Control
@onready var turn_end_button: Control = get_node_or_null("Root/HUD/TurnEndButton") as Control
@onready var message_label: Label = %MessageLabel

var turn_end_button_ui: TextureButton = null

var _selected_cell: Cell = null
var _selected_level_index: int = 0
var _message_timer: Timer = null

func _ready() -> void:
	_lock_battle_logic()
	_setup_message_label()
	_init_cells()
	SoundManager.play_bgm(BGM)

func _lock_battle_logic() -> void:
	if hand_view != null:
		hand_view.visible = false
	if hud != null:
		hud.visible = true
		for child in hud.get_children():
			if child != turn_end_button and child != null:
				# 安全地检查child是否为CanvasItem类型
				var canvas_item: CanvasItem = child as CanvasItem
				if canvas_item != null:
					canvas_item.visible = false
	var turn_manager: Node = get_node_or_null("TurnManager")
	if turn_manager != null:
		turn_manager.process_mode = Node.PROCESS_MODE_DISABLED
	if turn_end_button != null:
		turn_end_button.visible = true
		turn_end_button_ui = turn_end_button.get_node_or_null("NextTurn") as TextureButton
		if turn_end_button.has_method("set_mode"):
			turn_end_button.call("set_mode", 1)
		if turn_end_button.has_signal("confirm_pressed"):
			turn_end_button.connect("confirm_pressed", _on_confirm_pressed)
	if turn_end_button_ui != null:
		turn_end_button_ui.visible = false

func _init_cells() -> void:
	if grid == null:
		return
	var cells: Array = grid.get_children()
	cells.sort_custom(func(a, b): return a.name.naturalnocasecmp_to(b.name) < 0)
	var max_unlocked: int = GameState.max_unlocked_level if GameState != null else 1
	var level_index: int = 1
	for entry in cells:
		var cell: Cell = entry as Cell
		if cell == null:
			continue
		cell.set_meta("level_index", level_index)
		var unlocked: bool = level_index <= max_unlocked
		cell.set_state(Cell.CellState.AVAILABLE if unlocked else Cell.CellState.HIDDEN)
		_ensure_level_label(cell, level_index, unlocked)
		_bind_cell_input(cell)
		level_index += 1

func _ensure_level_label(cell: Cell, level_index: int, unlocked: bool) -> void:
	var root: Control = cell.get_node_or_null("Root") as Control
	var label: Label = null
	if root != null:
		label = root.get_node_or_null("LevelNumber") as Label
		if label == null:
			label = Label.new()
			label.name = "LevelNumber"
			label.layout_mode = 1
			label.anchors_preset = Control.PRESET_CENTER
			label.grow_horizontal = Control.GROW_DIRECTION_BOTH
			label.grow_vertical = Control.GROW_DIRECTION_BOTH
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			root.add_child(label)
	if label == null:
		return
	label.text = str(level_index)
	label.visible = unlocked

func _bind_cell_input(cell: Cell) -> void:
	var root: Control = cell.get_node_or_null("Root") as Control
	if root == null:
		return
	root.mouse_entered.connect(_on_cell_mouse_entered.bind(cell))
	root.mouse_exited.connect(_on_cell_mouse_exited.bind(cell))
	root.gui_input.connect(_on_cell_gui_input.bind(cell))

func _on_cell_mouse_entered(cell: Cell) -> void:
	if _is_cell_locked(cell):
		return
	if _selected_cell == cell:
		return
	cell.set_highlight(true, hover_color)

func _on_cell_mouse_exited(cell: Cell) -> void:
	if _selected_cell == cell:
		return
	cell.set_highlight(false)

func _on_cell_gui_input(event: InputEvent, cell: Cell) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_cell_pressed(cell)

func _on_cell_pressed(cell: Cell) -> void:
	if _is_cell_locked(cell):
		_clear_selection()
		_show_message("请先通过上一关")
		return
	var level_index: int = int(cell.get_meta("level_index", 0))
	_select_cell(cell, level_index)

func _select_cell(cell: Cell, level_index: int) -> void:
	if _selected_cell != null and is_instance_valid(_selected_cell):
		_selected_cell.set_highlight(false)
	_selected_cell = cell
	_selected_level_index = level_index
	_selected_cell.set_highlight(true, select_color)
	SoundManager.play_sfx("UnitMove")
	if turn_end_button_ui != null:
		turn_end_button_ui.visible = true

func _clear_selection() -> void:
	if _selected_cell != null and is_instance_valid(_selected_cell):
		_selected_cell.set_highlight(false)
	_selected_cell = null
	_selected_level_index = 0
	if turn_end_button_ui != null:
		turn_end_button_ui.visible = false

func _is_cell_locked(cell: Cell) -> bool:
	var level_index: int = int(cell.get_meta("level_index", 0))
	var max_unlocked: int = GameState.max_unlocked_level if GameState != null else 1
	return level_index <= 0 or level_index > max_unlocked

func _setup_message_label() -> void:
	message_label.visible = false
	message_label.modulate.a = 0.0
	_message_timer = Timer.new()
	_message_timer.wait_time = 2.0
	_message_timer.one_shot = true
	_message_timer.timeout.connect(_on_message_timeout)
	add_child(_message_timer)

func _on_confirm_pressed() -> void:
	if _selected_level_index <= 0:
		return
	if GameState != null:
		GameState.set_current_level(_selected_level_index)
	BattleEventBus.go("battle")

func _show_message(text: String) -> void:
	message_label.text = text
	message_label.visible = true
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(message_label, "modulate:a", 1.0, 0.25)
	if _message_timer != null:
		_message_timer.start()

func _on_message_timeout() -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(message_label, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func() -> void:
		message_label.visible = false
	)
