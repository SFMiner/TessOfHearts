# Enigmas — Uncertain Functions & Integration Points

Functions whose purpose, connections, or integration status remain unclear after code review.

---

## 1. `HeartRepairSystem` — Parallel heart repair model

**File:** `scripts/autoload/heart_repair_system.gd`  
**Functions:** `repair_heart()`, `get_available_materials()`

Per CLAUDE.md (section "Architecture reference"): "Two parallel heart repair systems exist: HeartRepairSystem (GDD emotional model) and GameManager crafting recipes (actually used in-game)." HeartRepairSystem is described as "partially integrated." It's unclear:

- Which system is authoritative for heart repair in the current build?
- Is HeartRepairSystem intended to eventually replace or augment the GameManager `craft_heart_with_*` functions?
- What specific integration points are missing?
- `RepairMaterial` enum values — are they referenced outside this file?

---

## 2. `memory.gd` vs `memory_hybrid.gd` — Dual memory implementations

**Files:** `minigame_memory/scripts/memory.gd`, `minigame_memory/scripts/memory_hybrid.gd`

CLAUDE.md (section "Architecture reference") states: "Two memory implementations exist — the active one is memory_hybrid.gd (drag + RigidBody2D physics stacking)."

- Is `memory.gd` dead code, or does it still serve a fallback/testing role?
- Which scenes or nodes still reference `memory.gd` vs `memory_hybrid.gd`?
- Should `memory.gd` be removed or marked deprecated?

---

## 3. `handwritten_game_hud.gd` vs `game_hud.gd` — Dual HUD implementations

**Files:** `scripts/handwritten_game_hud.gd`, `scripts/ui/game_hud.gd`

Two HUD scripts exist. It's unclear:

- Does `handwritten_game_hud.gd` supplement or override `game_hud.gd`?
- Are both active in the current build, or is one deprecated?
- `handwritten_game_hud.gd` references `scr_debug`/`debug` as undeclared variables — is this file abandoned?

---

## 4. `main.gd::_on_global_touch_started_old` — Legacy touch handler

**File:** `scripts/main.gd`

This function is a preserved old version of the touch handler. Purpose is documented as "kept for reference/comparison during input system development" but it's unclear:

- Is the old path still reachable from anywhere in the codebase?
- Can this function be safely removed, or is it needed for backward compatibility testing?

---

## 5. `save_system.gd::restore_available_collectables` — Scene mismatch

**File:** `scripts/autoload/save_system.gd` (line ~544)

Restores collectables by instantiating from a single scene: `res://scenes/interactables/collectable.tscn`. However, individual collectable types have their own scene files (e.g., `heart.tscn`, `cookie.tscn`, `gold.tscn`).

- Is `collectable.tscn` a generic SmartCollectable capable of representing any collectable type via its `collectable_type` property?
- Or does the restoration path fail to properly restore different collectable types with their unique visual representations?

---

## 6. `dialogue_system.gd` — Autoload directory but not an autoload

**File:** `scripts/autoload/dialogue_system.gd`

CLAUDE.md (section "Architecture reference") explicitly states: "`SimpleDialogueSystem` is NOT an autoload. It is not in `project.godot` and must be manually instantiated or added to scenes." It resides in the `autoload/` directory nonetheless.

- Why was it placed in the autoload directory if it's not one?
- Which scenes manually instantiate it vs reference it via the path `UI/DialogueChoiceUI`?

---

## 7. Cat coupling in `main.gd` — Unclear dependency

**File:** `scripts/main.gd`  
**Function:** `fix_friend_initial_state()`

This function performs friend-related initialization but its name suggests a workaround. It's unclear what bug or initial-state problem it was created to fix, and whether the fix is still needed.
