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

## Architecture — see `AGENTS.md`
`AGENTS.md` is the authoritative architecture reference (autoloads, input flow,
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

## Known Issues / Pitfalls (see `AGENTS.md` for the full list)
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
