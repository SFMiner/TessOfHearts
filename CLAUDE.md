# Tess of Hearts (Gather Hearts) — Claude Code Project Context

## Game Summary
A short, surreal, hand-drawn web game. Tess journeys through the Cosmic Bathhouse
searching for the sleeping Eldritch Empress, repairing broken hearts along the way,
and ultimately discovers she *is* the Empress. Intimate, melancholy, kind.
Tagline: *"Still doesn't like ants."*

## Objective
Personal/expressive project (not educational/curriculum-aligned). Solo dev: Sean Miner.
Free, sharable web build. Touch-first with mouse fallback.

## Godot Standards
- **Godot 4.4** (Forward Plus rendering), GDScript only
- Tabs for indentation (never spaces)
- Type hints on all variables and functions
- Signal-based communication between systems
- Gate every `print()` behind a debug flag (`scr_debug` or `GameData.sys_debug`)
- See the **gdscript-patterns** skill for full coding standards — do not duplicate here

## Architecture — see the section "Architecture reference (moved from AGENTS.md)" at the end of this file
That section is the authoritative architecture reference (autoloads, input flow,
interactable paradigms, collectable type indices, Friend NPC system, memory minigame,
export config, known pitfalls). **Read it before making structural changes.** Other key docs:
- `docs/README.md` — full project reference (systems, GDD, status)
- `docs/Developer_Quick_Reference.md` — code snippets and patterns
- `docs/Smart_Interactable_System.md` — interactable class hierarchy
- `gather_hearts_gdd.md` — original GDD
- `scene_descriptions.md` — scene node trees with visual-proxy colors

## AutoLoad Load Order (from `project.godot`)
1. `GameManager` — `scripts/autoload/game_manager.gd`
2. `HeartRepairSystem` — `scripts/autoload/heart_repair_system.gd`
3. `InputManager` — `scripts/autoload/input_manager.gd`
4. `HandwrittenTextManager` — `scripts/autoload/handwritten_text_manager.gd`
5. `GameData` — `scripts/autoload/game_data.gd`
6. `SaveSystem` — `scripts/autoload/save_system.gd`

Note: `dialogue_system.gd` (`SimpleDialogueSystem`) is **NOT** an autoload — it is
manually instantiated and references `UI/DialogueChoiceUI` at a hardcoded path.
Main scene: `uid://bk4xvlepqi83s`. Viewport 1920×1080.

## Project Structure
```
scenes/        — areas/, characters/, environments/, interactables/,
                 openable_sprites/, ui/
scripts/       — autoload/ (singletons), base/ (SmartInteractable etc.), ui/
minigame_memory/ — self-contained drag-and-drop memory puzzle (memory_hybrid.gd active)
assets/handwritten/ — pre-rendered PNG text (dialogue/, messages/, numbers/, ui/)
```

## Current Phase
**Phase 3 (Content) — in progress.** Phases 1–2 complete: all core systems built and
functional (dialogue, energy, courage, ant areas, heart repair, Smart Interactables,
UI/HUD, Friend AI with echo-follow + summon + departure, save/load with 10 slots).
Remaining: full level set, audio integration, tutorial/onboarding, web export pass.

### Uncommitted work-in-progress (as of 2026-05-31, branch `main`)
Building on commit `a177fb7 "before updates 5-2026"`. Modified but not committed:
- `scripts/autoload/dialogue_system.gd` — substantial rework (~95 lines)
- `scenes/characters/bearded_friend.gd` (+ `.tscn`) — Friend refactor (net reduction)
- `scenes/characters/tess.tscn`
- save/load: `save_system.gd`, `save_load_ui.gd`, `notebook_page.gd`
- `scripts/ui/handwritten_label.gd`
- openables: `openable_failure.gd`, `openable.tscn`, `op_china_cab.tscn`
- areas/env: `central_bath.tscn`, `bathhouse_room.gd`
- minor: `game_manager.gd`, `input_manager.gd`, `main.gd`

## Build / Export
No CLI build/lint/test — use the Godot editor. Web export preset "Web" → `./Tess of Hearts.html`;
Windows preset "Windows Desktop" → `./Tess of Hearts.exe`. Web audio must be OGG.

## Input & Click Routing

### How a click becomes movement (the full chain)
1. `InputManager._input()` → `start_touch()` converts screen→world coords via camera transform, calls `find_touched_objects()`, then **always** emits `touch_started(world_position)` — even if no physics object was hit.
2. `main.gd:_on_global_touch_started()` receives every click. Guards run in order; the first match returns early:
   - `is_click_on_ui_element()` — checks `"dialogue_choice_ui"` group nodes and hardcoded HUD button paths only.
   - `is_click_on_interactable_in_range()` — checks nodes in `"interactables"` group where `tess_in_interaction_area` is true and click is within `interaction_range`.
   - `is_moving_toward_friend()` — physics point query on `collision_mask = 2`; only catches clicks that land on the Friend's physics body, not on UI/Control nodes above it.
   - Falls through to `tess.move_to(world_position)`.

### What `find_touched_objects()` can and cannot detect
Uses `PhysicsPointQueryParameters2D` — hits **physics bodies only** (CharacterBody2D, Area2D, StaticBody2D). It **cannot** detect Control nodes (dialogue bubbles, UI panels). A click on a visible speech bubble above the Friend goes undetected here, so `touch_started` still fires and reaches the movement fallback.

### Dialogue system — `is_showing` flag
`dialogue_system.gd` (`SimpleDialogueSystem`, in `"dialogue_system"` group, **not** an autoload) tracks `is_showing: bool`. Set `true` in `show_dialogue()` / `show_dialogue_manual()`; set `false` in `hide_dialogue()`. Auto-hide fires after `fade_duration` seconds (default 5.0).

All callers of `show_dialogue()` that set `is_showing = true`:
| Caller | Trigger | Movement block appropriate? |
|---|---|---|
| `bearded_friend.gd:_on_touched()` | Player clicks Friend when in range | Yes |
| `tess.gd:call_friend_dialogue()` | Player presses "call_friend" action | Yes (Tess is mid-animation) |
| `click_dialogue_trigger.gd` | Player clicks an Area2D dialogue trigger | Yes |
| `dialogue_trigger.gd:_on_body_entered()` | Tess *walks into* an Area2D trigger | **Caution** — blocks movement for `fade_duration` s without a click; use a short `fade_duration` on walk-through triggers |
| `guide_cat.gd` | Player touches the guide cat | Minor concern — player may want to move while reading |
| `character.gd:110` | Base character dialogue method | Context-dependent |

### Friend interaction click path (and the movement-bleed bug)
The Friend's speech bubble ("Hey there!" / "Tess what is it?") is a `Control.new()` node added as a child of `DialoguePoint` (world space, above the Friend). Clicking it does **not** hit any physics body, so `find_touched_objects()` misses it, and `is_moving_toward_friend()` misses it (click is above the Friend's collider). The click falls through to `tess.move_to()`.

**Fix**: in `_on_global_touch_started()` (around line 244, before the movement call), check `dialogue_system.is_showing` and return early. The `"dialogue_system"` group is **not** checked by `is_click_on_ui_element()` — adding it there is the wrong place; the `is_showing` guard before `move_to()` is correct. If `DialogueTrigger` walk-through triggers are ever placed in scenes, give them a short `fade_duration` to avoid a 5-second movement freeze.

### Groups relevant to click routing
- `"interactables"` — checked by `is_click_on_interactable_in_range()` in main.gd
- `"dialogue_choice_ui"` — checked by `is_click_on_ui_element()` in main.gd
- `"dialogue_system"` — **not** currently checked anywhere in main.gd (source of the Friend dialogue movement-bleed bug)
- `"Friend"` — the Friend NPC group; distinct from `"interactables"`, so the Friend is **not** caught by the interactable range guard

## Known Issues / Pitfalls (see the section "Architecture reference (moved from AGENTS.md)" at the end of this file for the full list)
- `docs/directory_structure.md` is actually a copy of `Dialogue_Display_System_Fix.md` — not a real dir listing
- `index.html` at repo root is a Nextcloud sync placeholder, not the real export (real file: `Tess of Hearts.html`)
- Two parallel heart-repair systems: `HeartRepairSystem` (GDD emotional model) vs `GameManager` crafting recipes (the one actually used in-game)
- Autoload `HandwrittenTextManager` was fixed from a typo — do not reintroduce `HandwirttenTextManager`
- Root `test_*.gd` are manual scene-test scripts, not automated tests
- Two memory-minigame implementations exist; the active one is `memory_hybrid.gd`

## Asset Placeholders
Visual proxies still in use for prototyping (per GDD): Tess=purple, Friend=blue,
Hearts=red, Whiskey=tan, Cookies=brown, Gold=yellow, Barbed Wire=grey, Sutures=magenta,
Roses=pink, Biopods=green. To be swapped with final hand-drawn art. All in-game text
is pre-rendered handwritten PNGs (never Godot fonts).

## Architecture reference (moved from AGENTS.md)

Engine: **Godot 4.4** (Forward Plus). No CLI build/lint/test — use the editor.

### Autoload Singletons (6)

| Singleton | File | Role |
|-----------|------|------|
| `GameManager` | `scripts/autoload/game_manager.gd` | Game state, heart collection, crafting, area unlocking, energy/courage logic |
| `GameData` | `scripts/autoload/game_data.gd` | **All persistent state** (inventory counters, energy, courage, positions, flags). Pure data — no logic |
| `InputManager` | `scripts/autoload/input_manager.gd` | Touch/mouse → `object_touched` and `touch_started` signals. Uses `PhysicsPointQueryParameters2D(collision_mask=0b1111)` |
| `SaveSystem` | `scripts/autoload/save_system.gd` | JSON saves to `user://savegames/slot_N.save`, 10 slots. Quick-save=slot 0, auto-save=slot 9 |
| `HandwrittenTextManager` | `scripts/autoload/handwritten_text_manager.gd` | PNG texture registry. **All text uses pre-rendered handwritten PNGs, never Godot fonts** |
| `HeartRepairSystem` | `scripts/autoload/heart_repair_system.gd` | Emotional repair multipliers (GDD model). Partially integrated — actual crafting uses GameManager methods |

**Critical:** `scripts/autoload/dialogue_system.gd` (`SimpleDialogueSystem`) is **NOT an autoload**. It is not in `project.godot` and must be manually instantiated or added to scenes.

### Collectable Type Indices

Integer map used by `GameData` inventory vars and `SmartCollectable.collectable_type`:

```
0 = whole_heart    4 = whiskey       8 = barbed_wire
1 = 2/3_heart      5 = cookie        9 = gold
2 = half_heart     6 = sutures
3 = 1/3_heart      7 = tape
```

### Input Flow

6-level detection hierarchy in `main.gd._on_global_touch_started()`:

1. **Dialogue choice UI** — check `DialogueChoiceUI.is_showing` bounding rect
2. **GameHUD buttons** — check button rect hits
3. **`ui_buttons` group** — generic UI button detection
4. **`MOUSE_FILTER_STOP` controls** — respect explicit mouse filters
5. **Interactable in range** — `SmartInteractable._input()` (runs at `process_priority=100`). If Tess is inside the interaction area AND click is within range → perform interaction, block movement
6. **Movement fallback** — if above passes all checks → `Tess.move_to(world_position)`

### Two Interactable Paradigms

| | Old (Interactable) | New (SmartInteractable) |
|---|---|---|
| Extends | `Node2D` | `Area2D` |
| Visual | ColorRect | Sprite-based |
| Detection | Area2D `input_event` | `_input()` at process_priority=100 |
| Used for | GuideCat, legacy items | Collectables, Openables (dominant) |

Prefer `SmartInteractable` for new interactables. Key chain: `SmartInteractable → SmartCollectable → Heart/Cookie/Gold`, `SmartInteractable → Openable`.

### Architecture Conventions

- **Signal-based communication** — cross-system calls use signals (e.g. `GameManager.energy_changed → GameHUD`, `InputManager.touch_started → Main/SmartInteractable`)
- **Group-based node discovery** — `"Tess"`, `"Friend"`, `"collectables"`, `"interactables"`, `"ant_areas"`, `"dialogue_trigger"`, `"memories"`, `"vessels"`, `"ui_buttons"`, `"dialogue_choice_ui"`
- **Energy gates everything** — movement speed scales 100%/66%/33%/0% by energy level. 0 energy = no movement (dialogue still works). Interactions cost 1 energy
- **Debug logging pattern** — every class has `scr_debug : bool` or gates on `GameData.sys_debug`. Always gate `print()` behind `if debug:`
- **`@tool` scripts** — `SmartCollectable`, `Openable`, `OpenableFailure`, `AntArea` use `@tool` for editor preview
- **Depth sorting** — Tess and Friend: `z_index = global_position.y / 5`

### Friend NPC System

BeardedFriend follows Tess with an echo delay — Tess records `global_position` into `GameData` every frame. Friend personality states: `follow_tess` (default), `wander`, `drift`, `pause`. Summoned with **C key**, sent away via "excuse me" dialogue choice → `depart_from_screen()` which uses stored `back_to_points` for pathfinding. Test scripts: `test_back_to_points.gd`, `test_excuse_me.gd`, `test_friend_departure.gd`.

### Memory Minigame

Self-contained in `minigame_memory/`. Drag-and-drop puzzle; integrates via `GameManager.complete_memory_minigame_level()` and `GameData.memory_mini_*` vars. Uses group discovery (`"memories"`, `"vessels"`). Two memory implementations exist — the active one is `memory_hybrid.gd` (drag + RigidBody2D physics stacking).

### Export

- **Web**: `export_presets.cfg` preset "Web" → `./Tess of Hearts.html`
- **Windows**: Preset "Windows Desktop" → `./Tess of Hearts.exe`
- Viewport: **1920×1080**, touch-first with mouse fallback

### Key Docs

| File | Content |
|------|---------|
| `docs/README.md` | Full project reference (systems, GDD, status) |
| `docs/Developer_Quick_Reference.md` | Code snippets and patterns |
| `docs/Smart_Interactable_System.md` | Interactable class hierarchy detail |
| `gather_hearts_gdd.md` | Original game design document |
| `scene_descriptions.md` | Scene node trees with visual proxy colors |

### Known Pitfalls

- `docs/directory_structure.md` is actually a copy of `Dialogue_Display_System_Fix.md` — not a real directory listing
- `index.html` at repo root is a Nextcloud sync-on-demand placeholder, not the real export file. The actual web export is `Tess of Hearts.html`
- Two parallel heart repair systems exist: `HeartRepairSystem` (GDD emotional model) and `GameManager` crafting recipes (actually used in-game)
- Autoload names were fixed from a typo (`"HandwirttenTextManager"` → `"HandwrittenTextManager"`). Do not reintroduce
- Test scripts at root (`test_*.gd`) are manual scene-test scripts, not automated tests
- `dialogue_system.gd` references `UI/DialogueChoiceUI` at a hardcoded path — adding it as autoload would break this
