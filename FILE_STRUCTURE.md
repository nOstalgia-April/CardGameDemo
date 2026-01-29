# File Structure (Skeleton)

This is a proposed, UI-decoupled folder layout aligned with the rewritten architecture.

```
/
├─ ARCHITECTURE.md
├─ FILE_STRUCTURE.md
├─ assets/
│  ├─ cards/
│  └─ data/
│     ├─ cardinfos.csv
│     └─ enemyinfos.csv
├─ globals/
│  └─ autoloads.gd          # optional: keep autoload list / bootstrap
├─ scripts/
│  ├─ composition/
│  │  └─ game_controller.gd
│  ├─ data/
│  │  ├─ card_data_repo.gd
│  │  ├─ enemy_data_repo.gd
│  │  └─ effect_catalog.gd
│  ├─ state/
│  │  ├─ game_state.gd
│  │  ├─ board_state.gd
│  │  ├─ unit_state.gd
│  │  ├─ hand_state.gd
│  │  └─ turn_state.gd
│  ├─ systems/
│  │  ├─ action_system.gd
│  │  ├─ fog_system.gd
│  │  ├─ combat_system.gd
│  │  ├─ turn_system.gd
│  │  ├─ ai_system.gd
│  │  └─ effect_system.gd
│  ├─ presentation/
│  │  ├─ board_view.gd
│  │  ├─ cell_view.gd
│  │  ├─ unit_view.gd
│  │  ├─ hand_view.gd
│  │  └─ hud_view.gd
│  ├─ ai/
│  │  ├─ profiles/
│  │  └─ resolvers/
│  └─ effects/
│     ├─ effect_base.gd
│     └─ effects/
├─ tscns/
│  ├─ main.tscn
│  ├─ board.tscn
│  ├─ cell.tscn
│  ├─ hand_view.tscn
│  ├─ unit_card.tscn
│  └─ hud.tscn
└─ project.godot
```

Notes:
- `scripts/state` contains pure data and is UI-agnostic.
- `scripts/systems` is the only place that mutates state.
- `scripts/presentation` owns visuals and input only.
- `scripts/composition` wires everything together at runtime.
