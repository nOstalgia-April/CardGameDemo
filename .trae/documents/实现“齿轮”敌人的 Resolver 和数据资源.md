用户补充了新需求：**死亡后重生的数值改为 0 0 0 0**。

我们将对计划进行微调：

**1. 创建 Resolver 逻辑 (`res://scripts/resolvers/gear_resolver.gd`)**
保持不变。`GearResolver` 脚本将通过 `clockwise_self` 变量控制旋转方向，满足一阶段和二阶段的不同需求。

**2. 创建敌人数据资源 (`res://Data/enemies/`)**

* **二阶段：齿轮-MaskOff (`enemy_齿轮_revealed.tres`)**

  * **数值**: 这里将根据用户新指令设置为 **N:0, E:0, S:0, W:0**。

  * **Resolver**: 挂载 `GearResolver`，设置 `clockwise_self = false`（自身逆时针，相邻顺时针）。

* **一阶段：齿轮 (`enemy_齿轮.tres`)**

  * **Resolver**: 挂载 `GearResolver`，设置 `clockwise_self = true`（自身顺时针，相邻逆时针）。

  * **Death Transform**: 指向上述配置好的 `enemy_齿轮_revealed.tres`。

  * **Flip Trigger**: `death`。

  * **Flip Effect**: `transform`。

**执行步骤**

1. 编写 `res://scripts/resolvers/gear_resolver.gd`。
2. 创建 `enemy_齿轮_revealed.tres`（数值全0）。
3. 创建 `enemy_齿轮.tres`（引用前者）。

