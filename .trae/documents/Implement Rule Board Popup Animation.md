I will implement the "Game Rules" board popup functionality and add it to the battle scene.

**Plan:**

1.  **Create Script `scripts/rule_board.gd`**:
    -   It will handle the animation of the `TextureButton` (the rules panel).
    -   **Logic**:
        -   Define `collapsed_pos` (Y = -500) and `expanded_pos` (Y = -20).
        -   Connect `mouse_entered` and `mouse_exited` signals from the `TextureButton`.
        -   Use a `Tween` to smoothly animate the `position:y` of the `TextureButton` when hovered.
        -   Ensure the "Game Rules" `Label` allows mouse events to pass through to the `TextureButton` (or handles them if it covers the button).

2.  **Modify `rule_board.tscn`**:
    -   Attach the new `scripts/rule_board.gd` script to the root node.
    -   Change the root `Control`'s `anchors_preset` to `0` (Custom/Top-Left) so it doesn't automatically resize to fit the small `HUD` container in the battle scene.
    -   Set the "Game Rules" `Label`'s `mouse_filter` to `IGNORE` so it doesn't block mouse interactions with the underlying `TextureButton`.

3.  **Update `tscns/battle.tscn`**:
    -   Instantiate `rule_board.tscn` as a child of the `HUD` node.
    -   This will place the "Game Rules" button in the top-left area (offset by the HUD's position), allowing the rules to slide down from the top.

**Outcome**:
Hovering over the "Game Rules" area will smoothly slide down the rules panel. Moving the mouse away will slide it back up.