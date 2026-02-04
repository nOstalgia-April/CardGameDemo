extends Node2D

@export var hover_color: Color = Color(1, 1, 1, 0.9)
@export var select_color: Color = Color(1, 0.2, 0.2, 1)

@export var BGM: AudioStream

@onready var board: Control = %Board
@onready var grid: GridContainer = board.get_node("GridContainer") as GridContainer
@onready var hand_view: HandView = %HandView
@onready var hud: Control = get_node_or_null("Root/HUD") as Control
@onready var turn_end_button: Control = get_node_or_null("Root/HUD/TurnEndButton") as Control
@onready var rule_board: Control = get_node_or_null("Root/HUD/RuleBoard") as Control
@onready var message_label: Label = %MessageLabel
@onready var portrait: Sprite2D = get_node_or_null("Portrait") as Sprite2D

var turn_end_button_ui: TextureButton = null
var level_select_cell_scene: PackedScene = preload("res://tscns/level_select_cell.tscn")

var _selected_cell: Control = null
var _selected_level_index: int = 0
var _message_timer: Timer = null
var _portrait_start_x: float = -350.0
var _portrait_end_x: float = 323.0

func _ready() -> void:
	_lock_battle_logic()
	_setup_message_label()
	_init_cells()
	SoundManager.play_bgm(BGM)
	if portrait != null:
		portrait.position.x = _portrait_start_x

func _lock_battle_logic() -> void:
	if hand_view != null:
		hand_view.visible = false
	if hud != null:
		hud.visible = true
		for child in hud.get_children():
			if child != turn_end_button and child != rule_board and child != null:
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
		print("[LevelSelect] _init_cells: Grid is null!")
		return
	
	# 替换战斗用的 Cell 为 LevelSelectCell
	var existing_children = grid.get_children()
	for child in existing_children:
		if not child.has_method("setup"): # 简单的检测是否为 LevelSelectCell
			print("[LevelSelect] Replacing cell ", child.name, " with LevelSelectCell")
			var new_cell = level_select_cell_scene.instantiate()
			new_cell.name = child.name
			var idx = child.get_index()
			child.get_parent().remove_child(child)
			child.queue_free()
			grid.add_child(new_cell)
			grid.move_child(new_cell, idx)

	var cells: Array = grid.get_children()
	print("[LevelSelect] _init_cells: Found ", cells.size(), " cells")
	cells.sort_custom(func(a, b): return a.name.naturalnocasecmp_to(b.name) < 0)
	var max_unlocked: int = GameState.max_unlocked_level if GameState != null else 1
	var level_index: int = 1
	for entry in cells:
		var cell: Control = entry as Control
		if cell == null:
			continue
		cell.set_meta("level_index", level_index)
		var unlocked: bool = level_index <= max_unlocked
		if cell.has_method("set_state"):
			# 兼容旧 Cell 逻辑，虽然我们已经替换了，但以防万一
			cell.set_state(Cell.CellState.AVAILABLE if unlocked else Cell.CellState.HIDDEN)
		
		# Determine style
		var style: String = "default"
		var level_data: LevelData = LevelLoader.load_by_index(level_index)
		
		if not unlocked:
			style = "default"
		elif level_index == GameState.max_level:
			style = "super_red"
		elif unlocked and level_index < max_unlocked:
			# Completed level
			style = "green"

		_ensure_level_label(cell, level_index, unlocked, style)
		_bind_cell_input(cell)
		level_index += 1

func _ensure_level_label(cell: Control, level_index: int, unlocked: bool, style: String = "default") -> void:
	print("[LevelSelect] _ensure_level_label: cell=", cell.name, " index=", level_index, " unlocked=", unlocked, " style=", style)
	if cell.has_method("setup"):
		print("[LevelSelect] Calling setup on ", cell.name)
		var is_even: bool = (level_index % 2) == 0
		cell.call("setup", level_index, is_even, unlocked, style)
		return
	else:
		print("[LevelSelect] Cell ", cell.name, " does not have setup method!")
	
	if cell.has_method("set_level_number"):
		cell.call("set_level_number", level_index, unlocked)
		var root_for_number: Control = cell.get_node_or_null("Root") as Control
		if root_for_number != null:
			var label_for_number: Label = root_for_number.get_node_or_null("LevelNumber") as Label
			if label_for_number != null:
				label_for_number.visible = false
		return
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

func _bind_cell_input(cell: Control) -> void:
	if cell.has_signal("pressed"):
		if not cell.is_connected("pressed", _on_cell_pressed):
			cell.connect("pressed", _on_cell_pressed)
		return

	var root: Control = cell.get_node_or_null("Root") as Control
	if root == null:
		return
	root.mouse_entered.connect(_on_cell_mouse_entered.bind(cell))
	root.mouse_exited.connect(_on_cell_mouse_exited.bind(cell))
	root.gui_input.connect(_on_cell_gui_input.bind(cell))

func _on_cell_mouse_entered(cell: Control) -> void:
	if _is_cell_locked(cell):
		return
	if _selected_cell == cell:
		return
	SoundManager.play_sfx("UiBlockPassby")
	if cell.has_method("set_highlight"):
		cell.call("set_highlight", true, hover_color)

func _on_cell_mouse_exited(cell: Control) -> void:
	if _selected_cell == cell:
		return
	if cell.has_method("set_highlight"):
		cell.call("set_highlight", false)

func _on_cell_gui_input(event: InputEvent, cell: Control) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_cell_pressed(cell)

func _on_cell_pressed(cell: Control) -> void:
	if _is_cell_locked(cell):
		_show_message("请先通过上一关")
		return
	var level_index: int = int(cell.get_meta("level_index", 0))
	_select_cell(cell, level_index)

func _select_cell(cell: Control, level_index: int) -> void:
	if _selected_cell != null and is_instance_valid(_selected_cell):
		if _selected_cell.has_method("set_highlight"):
			_selected_cell.call("set_highlight", false)
		elif _selected_cell.has_method("set_selected"):
			_selected_cell.call("set_selected", false)
	_selected_cell = cell
	_selected_level_index = level_index
	if _selected_cell.has_method("set_highlight"):
		_selected_cell.call("set_highlight", true, select_color)
	elif _selected_cell.has_method("set_selected"):
		_selected_cell.call("set_selected", true)
	SoundManager.play_sfx("UnitMove")
	if turn_end_button_ui != null:
		turn_end_button_ui.visible = true
	_show_portrait_for_level(level_index)

func _clear_selection() -> void:
	if _selected_cell != null and is_instance_valid(_selected_cell):
		if _selected_cell.has_method("set_highlight"):
			_selected_cell.call("set_highlight", false)
		elif _selected_cell.has_method("set_selected"):
			_selected_cell.call("set_selected", false)
	_selected_cell = null
	_selected_level_index = 0
	if turn_end_button_ui != null:
		turn_end_button_ui.visible = false
	if portrait != null:
		portrait.position.x = _portrait_start_x
		portrait.texture = null

func _is_cell_locked(cell: Control) -> bool:
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

func _show_portrait_for_level(level_index: int) -> void:
	if portrait == null:
		return
	var level: LevelData = LevelLoader.load_by_index(level_index)
	if level == null or level.portrait == null:
		portrait.position.x = _portrait_start_x
		portrait.texture = null
		return
	portrait.texture = level.portrait

	# 重置 Portrait 的默认值
	portrait.position = Vector2(323.00003, 478.00003)
	portrait.scale = Vector2(0.37, 0.37)

	# 第2关和第4关的特殊调整
	var target_x: float = _portrait_end_x
	if level_index == 2 or level_index == 4:
		portrait.scale = Vector2(0.325, 0.325)
		portrait.position = Vector2(200, 464)
		target_x = 300.0
		if level_index == 4:
			target_x = 310.0
			portrait.scale = Vector2(0.3583125, 0.3583125)

	if portrait.has_meta("tween"):
		var old_tween: Tween = portrait.get_meta("tween")
		if is_instance_valid(old_tween):
			old_tween.kill()
	portrait.position.x = _portrait_start_x
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(portrait, "position:x", target_x, 0.5)
	portrait.set_meta("tween", tween)
