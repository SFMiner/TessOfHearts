# AGENTS.md — Tess of Hearts

Engine: **Godot 4.4** (Forward Plus). No CLI build/lint/test — use the editor.

## Autoload Singletons (6)

| Singleton | File | Role |
|-----------|------|------|
| `GameManager` | `scripts/autoload/game_manager.gd` | Game state, heart collection, crafting, area unlocking, energy/courage logic |
| `GameData` | `scripts/autoload/game_data.gd` | **All persistent state** (inventory counters, energy, courage, positions, flags). Pure data — no logic |
| `InputManager` | `scripts/autoload/input_manager.gd` | Touch/mouse → `object_touched` and `touch_started` signals. Uses `PhysicsPointQueryParameters2D(collision_mask=0b1111)` |
| `SaveSystem` | `scripts/autoload/save_system.gd` | JSON saves to `user://savegames/slot_N.save`, 10 slots. Quick-save=slot 0, auto-save=slot 9 |
| `HandwrittenTextManager` | `scripts/autoload/handwritten_text_manager.gd` | PNG texture registry. **All text uses pre-rendered handwritten PNGs, never Godot fonts** |
| `HeartRepairSystem` | `scripts/autoload/heart_repair_system.gd` | Emotional repair multipliers (GDD model). Partially integrated — actual crafting uses GameManager methods |

**Critical:** `scripts/autoload/dialogue_system.gd` (`SimpleDialogueSystem`) is **NOT an autoload**. It is not in `project.godot` and must be manually instantiated or added to scenes.

## Collectable Type Indices

Integer map used by `GameData` inventory vars and `SmartCollectable.collectable_type`:

```
0 = whole_heart    4 = whiskey       8 = barbed_wire
1 = 2/3_heart      5 = cookie        9 = gold
2 = half_heart     6 = sutures
3 = 1/3_heart      7 = tape
```

## Input Flow

6-level detection hierarchy in `main.gd._on_global_touch_started()`:

1. **Dialogue choice UI** — check `DialogueChoiceUI.is_showing` bounding rect
2. **GameHUD buttons** — check button rect hits
3. **`ui_buttons` group** — generic UI button detection
4. **`MOUSE_FILTER_STOP` controls** — respect explicit mouse filters
5. **Interactable in range** — `SmartInteractable._input()` (runs at `process_priority=100`). If Tess is inside the interaction area AND click is within range → perform interaction, block movement
6. **Movement fallback** — if above passes all checks → `Tess.move_to(world_position)`

## Two Interactable Paradigms

| | Old (Interactable) | New (SmartInteractable) |
|---|---|---|
| Extends | `Node2D` | `Area2D` |
| Visual | ColorRect | Sprite-based |
| Detection | Area2D `input_event` | `_input()` at process_priority=100 |
| Used for | GuideCat, legacy items | Collectables, Openables (dominant) |

Prefer `SmartInteractable` for new interactables. Key chain: `SmartInteractable → SmartCollectable → Heart/Cookie/Gold`, `SmartInteractable → Openable`.

## Architecture Conventions

- **Signal-based communication** — cross-system calls use signals (e.g. `GameManager.energy_changed → GameHUD`, `InputManager.touch_started → Main/SmartInteractable`)
- **Group-based node discovery** — `"Tess"`, `"Friend"`, `"collectables"`, `"interactables"`, `"ant_areas"`, `"dialogue_trigger"`, `"memories"`, `"vessels"`, `"ui_buttons"`, `"dialogue_choice_ui"`
- **Energy gates everything** — movement speed scales 100%/66%/33%/0% by energy level. 0 energy = no movement (dialogue still works). Interactions cost 1 energy
- **Debug logging pattern** — every class has `scr_debug : bool` or gates on `GameData.sys_debug`. Always gate `print()` behind `if debug:`
- **`@tool` scripts** — `SmartCollectable`, `Openable`, `OpenableFailure`, `AntArea` use `@tool` for editor preview
- **Depth sorting** — Tess and Friend: `z_index = global_position.y / 5`

## Friend NPC System

BeardedFriend follows Tess with an echo delay — Tess records `global_position` into `GameData` every frame. Friend personality states: `follow_tess` (default), `wander`, `drift`, `pause`. Summoned with **C key**, sent away via "excuse me" dialogue choice → `depart_from_screen()` which uses stored `back_to_points` for pathfinding. Test scripts: `test_back_to_points.gd`, `test_excuse_me.gd`, `test_friend_departure.gd`.

## Memory Minigame

Self-contained in `minigame_memory/`. Drag-and-drop puzzle; integrates via `GameManager.complete_memory_minigame_level()` and `GameData.memory_mini_*` vars. Uses group discovery (`"memories"`, `"vessels"`). Two memory implementations exist — the active one is `memory_hybrid.gd` (drag + RigidBody2D physics stacking).

## Export

- **Web**: `export_presets.cfg` preset "Web" → `./Tess of Hearts.html`
- **Windows**: Preset "Windows Desktop" → `./Tess of Hearts.exe`
- Viewport: **1920×1080**, touch-first with mouse fallback

## Key Docs

| File | Content |
|------|---------|
| `docs/README.md` | Full project reference (systems, GDD, status) |
| `docs/Developer_Quick_Reference.md` | Code snippets and patterns |
| `docs/Smart_Interactable_System.md` | Interactable class hierarchy detail |
| `gather_hearts_gdd.md` | Original game design document |
| `scene_descriptions.md` | Scene node trees with visual proxy colors |

## Known Pitfalls

- `docs/directory_structure.md` is actually a copy of `Dialogue_Display_System_Fix.md` — not a real directory listing
- `index.html` at repo root is a Nextcloud sync-on-demand placeholder, not the real export file. The actual web export is `Tess of Hearts.html`
- Two parallel heart repair systems exist: `HeartRepairSystem` (GDD emotional model) and `GameManager` crafting recipes (actually used in-game)
- Autoload names were fixed from a typo (`"HandwirttenTextManager"` → `"HandwrittenTextManager"`). Do not reintroduce
- Test scripts at root (`test_*.gd`) are manual scene-test scripts, not automated tests
- `dialogue_system.gd` references `UI/DialogueChoiceUI` at a hardcoded path — adding it as autoload would break this
