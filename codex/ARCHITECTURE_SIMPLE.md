# 简化架构（确定实现版）

## BattleEventBus（信号 + 谁订阅）

核心信号（逻辑层，必须实现）
- `unit_placed(unit, cell, context)`
  - 订阅：Board（刷新格子/可见性）、UI/HUD（更新资源）、特效系统
- `unit_moved(unit, from_cell, to_cell, context)`
  - 订阅：Board（刷新格子/可见性）、Camera/FX（移动动画）
- `attack_started(attacker, target, dir, context)`
  - 订阅：UnitCard（播放攻击动画）、FX
- `damage_applied(attacker, target, dir, value, context)`
  - 订阅：UnitCard（受击反馈/数字刷新）
- `unit_died(unit, killer, dir, context)`
  - 订阅：Board（移除单位/格子刷新）、掉落/剧情/音效
- `turn_started(turn_index, context)`
  - 订阅：HUD、AI
- `turn_ended(turn_index, context)`
  - 订阅：AI、日志、存档
- `resource_changed(energy, flips, context)`
  - 订阅：HUD

扩展信号（本项目也实现）
- `cell_visibility_changed(cell, state)`
- `flip_used(unit, context)`
- `effect_triggered(effect_id, unit, context)`

---

## Board（必须实现函数）

已有：放棋子、处理攻击、处理移动
- `get_cell(pos)`
- `get_neighbor_cells(cell)`（返回一个 dir 的字典）
- `is_cell_empty(cell)`
- `get_unit_at(cell)`
- `remove_unit(unit)`（从格子卸载）
- `highlight_cells(cells, color)` / `clear_highlight()`
- `update_visibility()`（迷雾）
- `get_distance(cell_a, cell_b)`（曼哈顿）
- `find_units(filter)`（友方/敌方）

---

## Cell（必须实现函数）

你已有：切换边框、切换显示状态
- `set_unit(unit)` / `remove_unit()`
- `is_occupied()`
- `set_highlight(active, color)`（白色/红色）
- `set_state(state)`（隐藏/可见/可选）
- `get_pos()`（坐标）
- `set_clickable(enabled)`（用于交互）

---

## UnitCard（必须实现函数）

你已有：`Attack_dir` / `TakeDmg`
- `get_dir_value(dir)` / `set_dir_value(dir, v)`
- `rotate_numbers(clockwise)`
- `heal_full()` / `heal_dir(dir)`
- `is_enemy()`
- `play_attack_anim(dir)`
- `can_attack_dir(dir)`
- `apply_effect(effect_id, context)`

---

## 全局辅助脚本（必须实现）

- `dir_to_vec(dir)` / `vec_to_dir(vec)`
- `opposite_dir(dir)`
- `dir_name(dir)`
- `clamp_board_pos(pos)`
- `is_valid_pos(pos, board_size)`
