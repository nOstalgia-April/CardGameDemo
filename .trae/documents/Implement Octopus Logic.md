我将按照新的要求实现章鱼的逻辑。

**执行计划：**

1.  **修改 `UnitCard.gd`**：
    *   添加 `signal values_changed`。
    *   在 `_apply_dir_value` 中发射该信号。
    *   修改 `_on_flip()` 方法，确保翻转时正确切换贴图（之前代码中已有相关逻辑，我将检查并确保 `flip()` 调用时 `_on_flip` 被执行且贴图被切换）。

2.  **创建触发器：`ParityChangeTrigger`** (`scripts/triggers/parity_change_trigger.gd`)：
    *   监听 `values_changed`。
    *   计算 `sum = N+E+S+W`。
    *   如果 `sum % 2` 与 `last_parity` 不同，则触发 `unit.flip()`。
    *   初始化时记录 `last_parity`。

3.  **创建效果：`AdvantageAttackEffect`** (`scripts/effects/advantage_attack_effect.gd`)：
    *   复用 `res://scripts/resolvers/adjacent_attack_resolver.gd` 的逻辑。
    *   `AdjacentAttackResolver` 是一个 `UnitResolver`，我有两种选择：
        1.  实例化 `AdjacentAttackResolver` 并调用其 `resolve(unit)` 方法。
        2.  复制代码逻辑到 `AdvantageAttackEffect` 中。
    *   考虑到 `UnitResolver.resolve` 通常是异步的且设计用于回合结算，直接调用可能需要适配。但我将查看 `AdjacentAttackResolver` 的源码，如果逻辑简单，直接调用或复制代码皆可。**重点是确保攻击是“优势攻击” (`advantage=true`)**。如果 `AdjacentAttackResolver` 默认不是优势攻击，我可能需要修改或复制逻辑并强制设为 `advantage=true`。

4.  **更新注册表**：
    *   注册 `parity_change` 和 `advantage_attack`。

5.  **更新资源**：
    *   `enemy_章鱼.tres`：设置 `flip_trigger_id="parity_change"`，`flip_effect_id="advantage_attack"`。

**关于切换贴图**：
`UnitCard.flip()` 方法中已经调用了 `_on_flip()`，其中包含了：
```gdscript
if _card_art_flipped != null:
    art.texture = _card_art_flipped
```
但是，如果触发器再次触发（例如奇偶性变回来），我们可能希望它翻转回正面？
通常 "Flip" 意味着从正面变反面。如果已经在反面，`flip()` 会直接返回 `false`（虽然我刚刚注释掉了那个检查）。
如果章鱼的逻辑是“Mask change”，意味着它可能在两个状态间切换。
如果是这样，`flip()` 应该支持 `toggle` 效果，即在 `_card_art` 和 `_card_art_flipped` 之间切换。
目前的 `_on_flip` 只是单向切换到 `_card_art_flipped`。
我将在 `UnitCard.gd` 中改进 `_on_flip` 逻辑，使其支持在两张贴图间切换（如果 `_flipped` 状态被允许反复切换）。
或者，更简单的做法是：`flip()` 只是触发效果的入口，而贴图切换是效果的一部分？
不，`flip` 本身就有“翻面”的含义。
我会修改 `UnitCard.gd`，让 `_on_flip` 根据当前的 `_flipped` 状态（或者增加一个 toggle 逻辑）来切换贴图。
或者，考虑到章鱼是“奇偶变换”，它可能就在两种形态间切换。
**修正**：`UnitCard.flip()` 设置 `_flipped = true`。如果允许重复 flip，那么它一直是 `true`。
我需要让 `flip()` 支持“切换状态”。即 `_flipped = !_flipped`。
我将修改 `UnitCard.gd` 的 `flip()` 逻辑为 `_flipped = !_flipped`，并据此切换贴图。

Let's start.