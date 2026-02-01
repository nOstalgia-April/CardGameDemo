我将按照您的要求重构死亡转化逻辑，将其解耦为 Trigger 和 Effect 系统。

### 1. 代码重构
- **扩展 FlipTrigger 系统**
    - 修改 `scripts/triggers/flip_trigger.gd`：添加 `on_death(context)` 虚函数，默认返回 `false`。
    - 新建 `scripts/triggers/death_trigger.gd`：实现 `on_death`，调用 `unit.flip()` 并返回 `true`（阻断死亡）。
    - 更新 `scripts/triggers/flip_trigger_registry.gd`：注册 `"death"` 类型的触发器。

- **新增 TransformEffect**
    - 新建 `scripts/effects/transform_effect.gd`：实现 `apply` 方法。
    - 逻辑：读取 `unit.death_transform`（即二阶段数据），调用 `unit.apply_enemy_data()` 切换形态，并执行新形态的 FlipEffect。
    - 更新 `scripts/effects/flip_effect_registry.gd`：注册 `"transform"` 类型的效果。

- **清理 UnitCard 逻辑** (`tscns/battleground/board/unitcard/unit_card.gd`)
    - 在 `take_damage` 中添加对 `_flip_trigger.on_death()` 的调用。
    - 移除 `try_death_transform` 函数及相关硬编码逻辑。
    - 移除 `death_behavior` 变量。

- **清理 EnemyData** (`scripts/data/enemy_data.gd`)
    - 移除 `death_behavior` 导出变量。
    - 保留 `death_transform` 用于存储二阶段数据引用。

### 2. 数据配置
- **更新社畜配置** (`res://Data/enemies/level_1/enemy_社畜.tres`)
    - 设置 `flip_trigger_id = "death"`。
    - 设置 `flip_effect_id = "transform"`。
    - 确保 `death_transform` 正确引用 `enemy_社畜二阶段.tres`。
