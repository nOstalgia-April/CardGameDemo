我将开始执行任务，实现“蜘蛛”在有“蜘蛛卵”时每回合打乱手牌的逻辑。

**执行步骤：**

1.  **创建 `scripts/triggers/turn_start_trigger.gd`**：
    *   继承自 `FlipTrigger`。
    *   在 `_bind()` 中监听 `BattleEventBus.turn_started`。
    *   收到信号时调用 `unit.flip()`。
    *   记得在 `cleanup()` 中断开信号连接。

2.  **创建 `scripts/effects/shuffle_hand_effect.gd`**：
    *   继承自 `FlipEffect`。
    *   实现 `execute(unit)` 方法。
    *   逻辑：
        *   获取所有单位，检查是否有 `display_name` 包含 "蜘蛛卵" 的敌方单位。
        *   如果没有，直接返回 `false`。
        *   如果有，获取 `HandView` (通过 `unit.get_tree().get_first_node_in_group("hand_view")` 或类似方式)。
        *   遍历手牌，对每张卡调用 `rotate_direction_numbers(true, randi_range(1, 3))`。
        *   播放洗牌音效。
        *   返回 `true`。

3.  **更新注册表**：
    *   修改 `scripts/triggers/flip_trigger_registry.gd` 添加 `"turn_start"`。
    *   修改 `scripts/effects/flip_effect_registry.gd` 添加 `"shuffle_hand"`。

4.  **配置资源**：
    *   修改 `Data/enemies/enemy_蜘蛛.tres`，设置触发器为 `turn_start`，效果为 `shuffle_hand`。

我将按照这个计划直接开始编写代码。