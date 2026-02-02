### 调试日志分析
日志显示了一个非常奇怪的现象：
```text
[DEBUG] UnitCard.flip: Called on 愤怒. _flipped=false, effect_id=charge 
[DEBUG] UnitCard.flip: Applying effect charge... 
[DEBUG] UnitCard.take_damage: 马牛 taking 7 damage from dir 3. Current def: 0 
[DEBUG] UnitCard.take_damage: Lethal damage detected. Checking on_death trigger... 
[DEBUG] UnitCard.flip: Flip complete. New art set.
```

1.  **"愤怒" (Angry)** 似乎是一个玩家单位，它正在进行某种操作（可能是放置时触发的 charge 效果？）。
2.  **"马牛" (社畜?)** 受到了 7 点伤害，防御为 0，触发了致死检测。
3.  **关键缺失**：
    - 没有看到 `DeathTrigger.on_death` 的日志！
    - 没有看到 `TransformEffect.apply` 的日志！
    - 没有看到 `UnitCard.apply_enemy_data` 的日志！
    
4.  **"Death BLOCKED by trigger." 也没有出现**。

这意味着：
`_flip_trigger.on_death(...)` 返回了 `false`！

### 为什么 on_death 返回 false？
查看 `FlipTrigger` 基类 (`scripts/triggers/flip_trigger.gd`):
```gdscript
func on_death(_context: Dictionary = {}) -> bool:
    return false
```

这意味着当前的 `_flip_trigger` **不是** `DeathTrigger` 的实例，而是基类或者其他子类的实例。

### 为什么 trigger 类型不对？
查看 `enemy_社畜.tres`：
`flip_trigger_id = "death"`

查看 `UnitCard.apply_enemy_data`:
```gdscript
flip_trigger_id = data.flip_trigger_id
# ...
# 这里有一个 setter 会调用 _apply_flip_trigger()
```

查看 `UnitCard.gd`:
```gdscript
var flip_trigger_id: String:
    set(value):
        _flip_trigger_id = value
        _apply_flip_trigger()

func _apply_flip_trigger() -> void:
    _flip_trigger.cleanup()
    _flip_trigger = FlipTriggerRegistry.create(flip_trigger_id)
    _flip_trigger.bind(self)
```

如果 `data.flip_trigger_id` 是 "death"，那么 `_flip_trigger` 应该是 `DeathTrigger`。

**推测原因**：
1.  **数据未正确加载**：也许场上的单位并不是用这个 tres 生成的，或者是旧数据的缓存？
2.  **被覆盖**：在某些地方 `flip_trigger_id` 被重置为了 "none" 或其他值。
    - 例如在 `Board.place_card_on_cell` 里会根据 `effect_id` 覆盖 trigger id。但那是针对玩家卡牌的。
    - 针对敌人，`GameController.create_enemy_unit` 会设置 trigger id。

**更奇怪的日志**：
`[DEBUG] UnitCard.flip: Called on 愤怒...`
这是玩家卡牌（愤怒）在翻牌。这可能是攻击者触发的效果？
紧接着是 `UnitCard.take_damage`。

**核心问题**：
`_flip_trigger` 实例没有正确响应 `on_death`。
最大的可能性是：该单位的 `flip_trigger_id` 并不是 "death"。

**可能的线索**：
日志中显示的单位名字是 **"马牛"**。
而 `enemy_社畜.tres` 的 `display_name` 是 **"社畜"**。
这说明场上的这个单位可能根本不是加载的 `enemy_社畜.tres`！或者是另一个同名资源？
或者是在 `GameController` 里生成的临时名字？

**验证计划**：
1.  在 `UnitCard.take_damage` 中打印当前的 `flip_trigger_id` 和 `_flip_trigger` 的类型。
2.  检查 "马牛" 到底对应哪个敌人配置。

**修正方向**：
如果是配置问题，需要找到正确的配置文件。
如果是代码逻辑覆盖了 trigger，需要修复覆盖逻辑。

**但还有一个可能性**：
`DeathTrigger.on_death` 里的 `unit == null` 检查失败了？
不，如果失败会打印 `[DEBUG] DeathTrigger.on_death: Unit is null!`，但日志里没有。
所以只能是 `_flip_trigger` 根本就不是 `DeathTrigger`。

**行动**：
我将添加更多调试信息来确认 Trigger 的真实类型和 ID。同时，我会检查项目中是否还有其他名为 "马牛" 或类似的敌人配置。
（注：日志里的“马牛”可能是 OCR 识别错误，或者是用户自定义的名字，对应“社畜牛马”？）

Wait, `UnitCard.take_damage` 的日志显示：
`[DEBUG] UnitCard.take_damage: Lethal damage detected. Checking on_death trigger...`
下一行直接就是：
`[DEBUG] UnitCard.flip: Flip complete. New art set.`
这说明 `die()` 也没被调用（否则会有 UnitOnDeath 音效或日志）？
不对，如果 `on_death` 返回 false，就会调用 `die()`。
`die()` 会打印日志吗？我没加。
但是 `UnitCard.flip` 是谁调用的？
日志里的 `UnitCard.flip: Flip complete` 是属于 **"愤怒"** 这张卡的吗？
看时间顺序：
1. `UnitCard.flip` (愤怒) 开始
2. `Applying effect charge` (愤怒) -> 这可能会导致攻击！
3. `UnitCard.take_damage` (马牛) -> 愤怒攻击了马牛
4. `Lethal damage` (马牛)
5. `UnitCard.flip` (愤怒) 结束

所以，马牛的死亡处理完全没有下文了？
如果不返回 true，就会执行 `die()`。
`die()` 会发出 `died` 信号。
`Board` 收到 `died` 信号，调用 `on_unit_died`，移除单位。

结论：**马牛确实死了，Trigger 没生效。**

**为什么 Trigger 没生效？**
因为 `_flip_trigger` 不是 `DeathTrigger`。

**任务**：
1. 在 `UnitCard` 中打印 `flip_trigger_id` 和 `_flip_trigger.get_class()`。
2. 确认 "社畜" 配置是否正确加载。
3. 检查是否有代码在 `_ready` 或初始化后修改了 `flip_trigger_id`。
