extends GdUnitTestSuite

const BoardScene := preload("res://tscns/battleground/board/board.tscn")

func _create_board() -> Board:
	var board := BoardScene.instantiate() as Board
	add_child(board)
	await await_idle_frame()
	return board

func _spawn_unit(cell: Cell, n: int, e: int, s: int, w: int, is_enemy: bool = false) -> UnitCard:
	var placed := cell.spawn_unit("Test", n, e, s, w, is_enemy)
	assert_that(placed).is_true()
	return cell.get_unit() as UnitCard

func test_knockback_blocked_triggers_domino_attack() -> void:
	var board := await _create_board()
	var pushed_cell := board.get_cell_at(Vector2i(1, 1))
	var target_cell := board.get_cell_at(Vector2i(2, 1))
	assert_that(pushed_cell).is_not_null()
	assert_that(target_cell).is_not_null()

	var pushed := _spawn_unit(pushed_cell, 0, 5, 0, 0, false)
	var blocker := _spawn_unit(target_cell, 0, 0, 0, 1, true)
	var ctx := {}

	board._on_unit_knockback_requested(pushed, 1, ctx) # dir=East

	assert_that(pushed_cell.get_unit()).is_same(pushed)
	assert_that(target_cell.get_unit()).is_same(blocker)
	assert_that(blocker.get_dir_value(3)).is_equal(0) # West reduced to 0
	assert_that(ctx.get("accepted", false)).is_true()
	assert_that(pushed.get_dir_value(1)).is_equal(4) # counterattack still applies

func test_knockback_empty_moves_unit() -> void:
	var board := await _create_board()
	var from_cell := board.get_cell_at(Vector2i(1, 1))
	var to_cell := board.get_cell_at(Vector2i(2, 1))
	assert_that(from_cell).is_not_null()
	assert_that(to_cell).is_not_null()

	var pushed := _spawn_unit(from_cell, 0, 5, 0, 0, false)
	var ctx := {}

	board._on_unit_knockback_requested(pushed, 1, ctx) # dir=East

	assert_that(from_cell.get_unit()).is_null()
	assert_that(to_cell.get_unit()).is_same(pushed)
	assert_that(ctx.get("accepted", false)).is_true()

func test_knockback_blocked_no_attack_if_zero_value() -> void:
	var board := await _create_board()
	var pushed_cell := board.get_cell_at(Vector2i(1, 1))
	var target_cell := board.get_cell_at(Vector2i(2, 1))
	assert_that(pushed_cell).is_not_null()
	assert_that(target_cell).is_not_null()

	var pushed := _spawn_unit(pushed_cell, 0, 0, 0, 0, false)
	var blocker := _spawn_unit(target_cell, 0, 0, 0, 4, true)
	var ctx := {}

	board._on_unit_knockback_requested(pushed, 1, ctx) # dir=East

	assert_that(pushed_cell.get_unit()).is_same(pushed)
	assert_that(target_cell.get_unit()).is_same(blocker)
	assert_that(blocker.get_dir_value(3)).is_equal(4)
	assert_that(ctx.get("accepted", false)).is_false()
