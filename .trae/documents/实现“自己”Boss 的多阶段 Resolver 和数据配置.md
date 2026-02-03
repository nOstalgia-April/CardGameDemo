根据您的需求，我将为“自己”这个 Boss 设计并实现一套通用的 Resolver 逻辑。

### **设计思路**

我们将创建一个名为 `SelfBossResolver` 的通用 Resolver 脚本，通过导出变量来控制不同阶段的行为差异。这样，三个阶段可以使用同一个脚本，只需调整参数即可。

**Resolver 逻辑结构 (`resolve` 方法)**

1.  **数字增强 (Power Up)**
    *   统计场上除自身以外的所有单位数量（`other_units_count`）。
    *   根据阶段配置的倍率（`stat_multiplier`），计算增量：`increment = other_units_count * stat_multiplier`。
    *   如果 `increment > 0`，则将自身的 N, E, S, W 四个方向的数值全部增加 `increment`。
    *   播放强化音效/特效（可选）。
    *   等待一帧或短时间，确保数值更新在视觉上可被感知。

2.  **多重行动 (Multi-Action)**
    *   根据阶段配置的行动次数（`action_count`），进行循环。
    *   在每次循环中，执行标准的“攻击或移动”逻辑（复用 `AttackOrMoveResolver` 的逻辑，或者直接组合它）。
    *   **一阶段**：`action_count = 1`
    *   **二阶段**：`action_count = 2`
    *   **三阶段**：`action_count = 3`

### **实现计划**

1.  **创建脚本 `res://scripts/resolvers/self_boss_resolver.gd`**
    *   继承自 `UnitResolver`。
    *   导出变量：
        *   `stat_multiplier: int = 1` （每有一个单位增加的数值量，一阶段为1，二/三阶段为2）
        *   `action_count: int = 1` （每回合行动次数）
    *   实现 `resolve(unit)` 方法，按顺序执行“加数字”和“移动攻击”。

2.  **更新数据文件**
    *   **`enemy_自己.tres`**：
        *   挂载 `SelfBossResolver`。
        *   设置 `stat_multiplier = 1`。
        *   设置 `action_count = 1`。
        *   配置 `death_transform` 指向二阶段数据。
        *   配置 `flip_trigger = "death"`，`flip_effect = "transform"`。
    *   **`enemy_自己二阶段.tres`**：
        *   挂载 `SelfBossResolver`。
        *   设置 `stat_multiplier = 2`。
        *   设置 `action_count = 2`。
        *   配置 `death_transform` 指向三阶段数据。
        *   配置 `flip_trigger = "death"`，`flip_effect = "transform"`。
    *   **`enemy_自己三阶段.tres`**：
        *   挂载 `SelfBossResolver`。
        *   设置 `stat_multiplier = 2`。
        *   设置 `action_count = 3`。
        *   （可选）不再配置 `death_transform`，或者是游戏结束。

3.  **验证**
    *   确保 Boss 在回合结束时先涨数值，再进行相应次数的移动/攻击。
    *   确保 Boss 死亡后能正确变身进入下一阶段。

这个方案完全符合您描述的逻辑顺序：先结算加数字，再执行（多次）移动攻击。