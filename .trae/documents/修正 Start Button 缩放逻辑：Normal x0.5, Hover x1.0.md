我明白了。您是说 **Hover 图片 (576x646) 已经是我们想要的“最终大小”了**，不需要再缩放。而 **Normal 图片 (962x962) 太大了**，所以需要 `scale = 0.5` 才能和 Hover 图片的主体部分匹配。

**修正后的逻辑：**

1.  **Normal 状态**：
    *   纹理：`texture_normal` (962x962)
    *   缩放：`scale = Vector2(0.5, 0.5)`
    *   结果大小：962 * 0.5 = 481px (主体部分)

2.  **Hover 状态**：
    *   纹理：`texture_hover` (576x646)
    *   缩放：`scale = Vector2(1.0, 1.0)` (因为这张图本身就是设计好的大小，不需要缩放)
    *   结果大小：576px (其中主体部分约为 481px，其余是外发光)

3.  **对齐问题**：
    *   当从 Normal (scale 0.5) 切换到 Hover (scale 1.0) 时，必须调整 `pivot_offset`，确保它们的**中心点**重合。
    *   Normal 中心：`962 * 0.5 / 2` 或 `pivot = 962/2` 且 `scale=0.5` -> 屏幕上中心位移是 `(481, 481) * 0.5 = (240.5, 240.5)`。
    *   Hover 中心：`576 / 2 = 288`, `646 / 2 = 323`。
    *   如果简单的切换 scale 和 pivot，可能还是会跳动。
    *   更简单的方法：让 `pivot_offset` 始终是**当前纹理的中心**。

**代码逻辑修正：**

*   `_ready()`:
    *   `scale = Vector2(0.5, 0.5)`
    *   `pivot_offset = texture_normal.get_size() / 2.0`

*   `_on_mouse_entered()`:
    *   `scale = Vector2(1.0, 1.0)`  <-- 关键变化：恢复原大
    *   `pivot_offset = texture_hover.get_size() / 2.0` <-- 更新中心点

*   `_on_mouse_exited()`:
    *   `scale = Vector2(0.5, 0.5)`
    *   `pivot_offset = texture_normal.get_size() / 2.0`

这样，Normal 状态会被缩小一半显示，而 Hover 状态会按原图显示（即比 Normal 状态大一倍的像素密度，但视觉主体大小一致），从而达到您想要的“x1 质感”。

我将立即执行此修改。
