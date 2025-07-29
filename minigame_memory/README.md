# Memory Assignment Minigame

A self-contained drag-and-drop memory assignment minigame for the Tess of Hearts project.

## Overview

This minigame presents players with memory fragments that must be assigned to character vessels. The goal is to place all memories in a single vessel with no connections between vessels.

## How to Play

1. **Drag Memories**: Click and drag memory fragments to drop them into vessels
2. **Create Connections**: Right-click on a vessel to start a connection, then left-click on another vessel to complete it
3. **Win Condition**: All memories must be assigned to the same vessel with no connections between vessels

## File Structure

```
minigame_memory/
├── scenes/
│   ├── Memory.tscn          # Individual memory fragment scene
│   ├── Vessel.tscn          # Drop target vessel scene
│   ├── MemoryMinigame.tscn  # Main minigame scene
│   └── TestMemoryMinigame.tscn # Test scene
├── scripts/
│   ├── memory.gd            # Memory fragment behavior
│   ├── vessel.gd            # Vessel behavior
│   └── memory_minigame.gd   # Main minigame logic
└── data/
    └── failure_responses.json # Poetic failure messages
```

## Integration with Main Game

The minigame is completely self-contained and uses namespaced variables in GameData and GameManager:

### GameData Variables
- `memory_mini_passed`: Boolean indicating if minigame is completed
- `memory_mini_current_level`: Current level (0-based)
- `memory_mini_total_levels`: Total number of levels

### GameManager Functions
- `start_memory_minigame()`: Initialize the minigame
- `complete_memory_minigame_level()`: Mark current level as complete
- `get_memory_minigame_progress()`: Get current progress
- `is_memory_minigame_completed()`: Check if all levels are done

## Customization

### Memory Fragments
Edit the `_create_sample_memories()` function in `memory_minigame.gd` to change:
- Number of memories
- Memory text content
- Memory positioning

### Vessels
Edit the `_create_sample_vessels()` function to change:
- Number of vessels
- Vessel names
- Vessel positioning

### Failure Responses
The `failure_responses.json` file contains poetic, context-aware failure messages that escalate based on failure count. The system supports:
- Specific conditions (memories_split_two, vessel_connections, etc.)
- Escalation tiers (1-3) based on failure count
- Oblique/poetic responses
- Tone variations

## Testing

To test the minigame:
1. Open `TestMemoryMinigame.tscn` in Godot
2. Run the scene
3. Try different configurations to test win/fail conditions

## Win Conditions

The minigame automatically checks for win conditions when all memories are assigned:
- ✅ **Win**: All memories in one vessel, no connections
- ❌ **Fail**: Memories split across vessels OR connections exist

## Failure Response System

The minigame provides context-aware, escalating feedback:
- **Tier 1** (0-2 failures): Gentle guidance
- **Tier 2** (3-4 failures): More direct feedback
- **Tier 3** (5+ failures): Sharp emotional truths
- **Specific conditions**: Tailored responses for exact failure types
- **Oblique responses**: Poetic, metaphorical feedback

## Usage in Main Game

To integrate this minigame into the main game:

```gdscript
# Start the minigame
GameManager.start_memory_minigame()

# Load the minigame scene
get_tree().change_scene_to_file("res://minigame_memory/scenes/MemoryMinigame.tscn")

# Check completion
if GameManager.is_memory_minigame_completed():
    print("Player has completed the memory minigame!")
```

## Technical Notes

- Uses Area2D for drag-and-drop functionality
- Implements collision detection for memory-vessel assignment
- Supports visual feedback during interactions
- Maintains state through GameData integration
- Provides comprehensive failure tracking and escalation 