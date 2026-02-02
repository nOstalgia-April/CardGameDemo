我将为您创建一个名为 `enemy-manager` 的 Skill，专门用于高效创建和管理新敌人。

### 计划步骤

1. **创建目录**：`.trae/skills/enemy-manager/`
2. **创建 Skill 文件**：`.trae/skills/enemy-manager/SKILL.md`

### Skill 内容设计

这个 Skill 将包含以下核心能力：

* **创建新敌人**：提供标准化的流程，自动生成 `EnemyData` 资源文件 (`.tres`)。

* **配置属性**：指导用户设置敌人的显示名称、描述、四维数值 (N/E/S/W)、立绘和卡面资源。

* **配置 Resolver**：帮助用户选择现有的 Resolver（如 `AttackOrMoveResolver`、`GearResolver`、`SelfBossResolver`）或引导创建新的自定义 Resolver。

* **配置变身/翻面**：设置死亡变身 (`death_transform`)、翻面触发器 (`flip_trigger`) 和翻面效果 (`flip_effect`)。

* **验证配置**：提供检查清单，确保所有必要字段（尤其是 `enemy_key` 和资源引用）都已正确填写。

### 预期文件结构

```markdown
---
name: "enemy-manager"
description: "Creates and manages enemy configurations (EnemyData). Invoke when user wants to add a new enemy, modify enemy stats, or set up enemy behaviors/resolvers."
---

# Enemy Manager

此 Skill 旨在帮助用户快速、规范地创建和管理游戏中的敌人数据。

## 功能
1. **创建新敌人**：生成 `.tres` 资源文件。
2. **配置属性**：设置数值、立绘、描述。
3. **绑定逻辑**：关联 Resolver 和触发器。

## 创建步骤
1. 确定 `enemy_key`（唯一标识）。
2. 创建 `res://Data/enemies/enemy_<key>.tres`。
3. 填写 `EnemyData` 字段：
   - `display_name`: 显示名称
   - `desc`: 技能描述
   - `n/e/s/w`: 四维数值
   - `card_art` / `card_art_flipped`: 卡面图片
   - `portrait` / `portrait_flipped`: 立绘图片
   - `resolver_script`: 行为逻辑脚本
   - `death_transform`: (可选) 死亡后变身的数据
   - `flip_trigger_id` / `flip_effect_id`: 翻面相关配置

## 常用 Resolver
- `AttackOrMoveResolver`: 标准敌人（攻击或移动）。
- `GearResolver`: 齿轮敌人（旋转）。
- `SelfBossResolver`: "自己" Boss（属性成长+多重行动）。
在理解敌人逻辑时，看看它是否能是目前已有“常用”“基础”Resolver的组合

## 验证清单
- [ ] `enemy_key` 是否唯一？
- [ ] 图片资源路径是否正确？
- [ ] Resolver 是否已挂载？
```

我将立即为您执行创建操作。
