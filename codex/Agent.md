# 语法注意点（GDScript / 项目约定）

- **Warning treated as error**：尽量显式类型/转换，避免 Variant 推断。
  - 例：`var label: Label = node.get_node_or_null("Value") as Label`
  - 例：`var card: Card = card_node as Card`

- **数组类型要一致**：`Array[Cell]` 不能直接赋给 `Array[Node]`。
  - 需要统一声明或显式转换。

- **节点获取优先导出 NodePath**：避免 `get_first_node_in_group()` / `has_method()`。
  - 用 `@export var turn_manager_path: NodePath` + `get_node()`。

- **空节点保护**：在 `get_node()` 前先判断 node 是否为 null，或用 `get_node_or_null()`。

- **queue_free 之后不要再使用对象**：取引用前先 `is_instance_valid()`。

- **异步 resolve**：resolver 的 `resolve()` 返回 `bool`，直接 `await` 即可。

- **信号连接时机**：如需使用 `game_started/turn_started`，保证在 `start_turn()` 之前连接。

