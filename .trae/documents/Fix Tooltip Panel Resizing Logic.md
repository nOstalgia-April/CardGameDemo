I will fix the tooltip panel resizing issue by updating the `_on_unit_hover_started` function in `scripts/tooltip_manager.gd`.

**Problem Analysis:**
The issue is that `tooltip_panel.size` is being manually calculated and set using `max(tooltip_panel.size.x, padded_size.x)`. Since `tooltip_panel.size` persists between calls (and might have been set to a large value previously), this logic prevents the panel from ever shrinking back down when the text content is short. It only allows the panel to grow or stay the same size.

**Plan:**
1.  Modify `scripts/tooltip_manager.gd`.
2.  In `_on_unit_hover_started`, remove the dependency on the *current* `tooltip_panel.size` when calculating the new size.
3.  Instead, reset the size to `Vector2.ZERO` (or a small minimum) first to allow the `Container` layout system to recalculate the minimum required size based on the new content.
4.  Set the new size to exactly `padded_size` (the minimum size required by content + padding), ensuring it snaps to the correct dimensions for the current text.

**Specific Code Change:**
Replace:
```gdscript
tooltip_panel.size = Vector2(
    max(tooltip_panel.size.x, padded_size.x),
    max(tooltip_panel.size.y, padded_size.y)
)
```
With:
```gdscript
tooltip_panel.size = Vector2.ZERO # Reset to allow shrinking
tooltip_panel.size = padded_size # Set to the required size
```
(Or simply `tooltip_panel.custom_minimum_size = padded_size` and let the container handle it, but setting `size` directly after a reset is a common way to force a resize on a `Panel` that isn't in a container).

**Why this fixes it:**
By resetting the size or ignoring the previous size, the panel will adapt to the *current* content's size, whether it's larger or smaller than the previous tooltip.