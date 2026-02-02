我明白了。您希望的是**视觉主体对齐**。

*   **Normal 状态** (962x962)：缩放 0.5，显示大小 481x481。
*   **Hover 状态** (576x646)：这张图里包含了一个与 Normal 状态相同的主体（481x481），但周围可能多了些发光或特效，导致整体图片变大了。
*   **目标**：当切换到 Hover 时，那个“主体部分”在屏幕上的大小和位置必须依然保持 481x481，不能忽大忽小。

**计算逻辑：**
如果 Hover 图片的“主体”真的是和 Normal 图片的“主体”是 1:1 对应的（即 Hover 图并未对主体进行缩放，只是加了边框），那么：

1.  **缩放比例**：Hover 状态也应该保持 `scale = 0.5`。因为如果主体在原图中大小一致，且都缩放 0.5，那么主体在屏幕上就会一样大。
2.  **位置偏移 (Pivot/Offset)**：
    *   Normal 图是 962x962，中心点是 (481, 481)。
    *   Hover 图是 576x646，中心点是 (288, 323)。
    *   如果直接切换图片且保持中心对齐，可能需要调整 `pivot_offset`，或者依赖 Godot `TextureButton` 的自动居中行为。
    *   但通常情况下，如果主体在两张图的**物理中心**，那么只要 `pivot_offset` 设置为当前纹理大小的一半，就能保证中心对齐。

**修正方案：**
既然您说“它们是能重合的”，这意味着 Hover 图片中的主体部分并未被缩放，只是画布变了。
所以，**Hover 状态下的缩放比例应该也维持在 `0.5`**。
之前我错误地把 Hover 图强行放大到了 481px 宽（缩放约 0.835），这导致主体被放大了，产生了“忽大忽小”的违和感。

**结论**：
Hover 状态下，**不要改变 Scale**，保持 `scale = Vector2(0.5, 0.5)` 即可。
只要两张图的主体在各自画布中都是居中的，Godot 切换纹理时会自动对齐（前提是 `ignore_texture_size` 为 false，或者使用了正确的锚点）。
或者，如果 Hover 图片本身就比 Normal 大（因为它包含了发光外边），那么显示出来自然就会“大一点”（主体不变，多了边框），这正是您想要的效果。

**代码调整**：
完全移除 `mouse_entered` 和 `mouse_exited` 中的缩放代码，或者确保它们都设置 `scale = 0.5`。
实际上，如果不需要动画，也不需要改变缩放，那么这两个信号连接都可以移除了。只要在 `_ready` 里设一次 `scale = 0.5` 就行了。

**等等，还有一个细节**：
Godot 的 `TextureButton` 在切换 `texture_hover` 时，如果纹理大小不同，按钮的 `size` 会变。如果 `pivot_offset` 是固定的数值（比如 481, 481），切换到小图（或大图）时中心点可能会偏。
但在您的例子中：
Normal: 962x962 -> pivot 481,481
Hover: 576x646 -> pivot 应该变成 288,323 才能保持中心对齐。

**最稳妥的做法**：
在 `_ready` 中开启 `ignore_texture_size = false`（默认就是），并设置 `stretch_mode` 为 `Keep Aspect Centered`（如果是 TextureRect），但在 TextureButton 中，我们主要关注 `pivot_offset`。

如果您的按钮已经配置了 `texture_hover` 属性（在编辑器里），那么脚本只需要负责：
1. `_ready` 时 `scale = 0.5`。
2. **关键**：当纹理切换时，更新 `pivot_offset` 为新纹理大小的一半。
   *   不过 `TextureButton` 没有 "texture_changed" 信号。
   *   简单的做法：在 `mouse_entered` 和 `mouse_exited` 里手动更新 `pivot_offset`。

**修正后的计划**：
1. `_ready`: `scale = 0.5`。
2. `mouse_entered`: `pivot_offset = texture_hover.get_size() / 2.0` (如果有 `texture_hover`)。
3. `mouse_exited`: `pivot_offset = texture_normal.get_size() / 2.0`。
4. **保持 Scale 恒定为 0.5**。这样主体大小就是 1:1 的，Hover 多出来的像素就是外发光。

(注：如果 `texture_hover` 为空，则不需要处理)

我将执行这个修改。
