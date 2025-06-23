# Dialogue System Usage Guide

## Overview
The dialogue system has been implemented according to the specifications in `Dialogue_Display_System_Fix.md`. This guide explains how to use the system in your game.

## Components Implemented

### 1. Dialogue Trigger (`scripts/base/dialogue_trigger.gd`)
A simple Area2D trigger that activates dialogue when Tess gets close.

**Properties:**
- `dialogue_key`: String - Which dialogue to display
- `trigger_once`: Bool - Whether to trigger only once (default: true)
- `trigger_distance`: Float - Detection range (default: 100.0)

**Usage:**
1. Instance `scenes/interactables/dialogue_trigger.tscn` in your scene
2. Set the `dialogue_key` property to one of the available options
3. Position the trigger where you want dialogue to appear

### 2. Dialogue System (`scripts/autoload/dialogue_system.gd`)
Core dialogue display system with comprehensive fixes.

**Features:**
- Proper UI positioning and scaling
- Centered text display with margins
- Automatic container sizing
- Debug output for troubleshooting
- 0.5x scaling for appropriate caption size

### 3. Handwritten Text Manager (`scripts/autoload/handwritten_text_manager.gd`)
Asset management system for handwritten text images.

**Available Dialogue Assets:**
- `"tess_what_is_it"` - Tess asking what something is
- `"friend_hey_there"` - Friend greeting
- `"cat_wisdom"` - Cat giving wisdom
- `"still_doesnt_like_ants"` - Something about not liking ants

### 4. Handwritten Label (`scripts/ui/handwritten_label.gd`)
UI component for displaying handwritten text images.

**Features:**
- Debug output for texture loading
- Fixed sprite centering with 20px margins
- Properly centers sprite within the control

## How to Add Dialogue to Your World

### Method 1: Using Dialogue Triggers
1. **Create Trigger**: Instance `dialogue_trigger.tscn` in your scene
2. **Set Dialogue**: Choose dialogue key from available options
3. **Position**: Place trigger where you want dialogue to appear
4. **Test**: Walk Tess into the trigger area

### Method 2: Using Character Interaction
Characters can trigger dialogue through their `say_dialogue()` method:

```gdscript
# In a character script
func _on_character_touched(position: Vector2) -> void:
    say_dialogue("friend_hey_there")
```

### Method 3: Direct System Call
You can call the dialogue system directly:

```gdscript
# Get the dialogue system
var dialogue_system = get_node("/root/DialogueSystem")
if dialogue_system:
    dialogue_system.show_dialogue("cat_wisdom", global_position)
```

## Available Dialogue Options

| Key | Description |
|-----|-------------|
| `"tess_what_is_it"` | Tess asking what something is |
| `"friend_hey_there"` | Friend greeting |
| `"cat_wisdom"` | Cat giving wisdom |
| `"still_doesnt_like_ants"` | Something about not liking ants |

## Adding New Dialogue

1. **Create Image**: Add new dialogue image to `assets/handwritten/dialogue/`
2. **Update Manager**: Add preload entry to `handwritten_text_manager.gd`:
   ```gdscript
   "your_new_dialogue": preload("res://assets/handwritten/dialogue/your_new_dialogue.png")
   ```
3. **Use in Game**: Use the new dialogue key in triggers or character interactions

## Testing

A test scene has been created at `scenes/test_dialogue.tscn` with:
- Four dialogue triggers with different dialogue keys
- A bearded friend character for interaction testing
- Visual indicators for trigger areas

## Debug Output

The system provides comprehensive debug output:
- Dialogue trigger activation
- Texture loading status
- Positioning calculations
- Container sizing information

Check the console for detailed information about dialogue system operation.

## Troubleshooting

### Common Issues

1. **Dialogue not appearing**: 
   - Check if trigger is in correct collision layer (mask = 2 for Tess)
   - Verify dialogue key exists in HandwrittenTextManager
   - Check console for error messages

2. **Null texture errors**: 
   - Verify dialogue key exists in HandwrittenTextManager
   - Check that image files exist in the correct paths

3. **Wrong positioning**: 
   - Check viewport size and positioning calculations in debug output
   - Verify camera setup if using world coordinates

4. **Text not centered**: 
   - Check sprite positioning and container sizing in debug output
   - Verify margins are being applied correctly

## Technical Details

### Dialogue Triggering Process
1. Tess enters dialogue trigger area
2. Trigger detects Tess (collision layer 2)
3. Trigger calls dialogue system with specified key
4. Dialogue system loads texture from HandwrittenTextManager
5. Container and background are resized to fit texture + margins
6. Dialogue is positioned in the center of the screen with proper centering
7. Dialogue fades in and auto-hides after 3 seconds

### Positioning System
- Uses viewport coordinates for UI elements in CanvasLayer
- Centers dialogue horizontally on screen
- Positions above viewport center with gap
- Ensures dialogue stays within viewport bounds
- Automatically scales to 0.5x for appropriate size
- **Note**: Uses simplified positioning approach for UI elements (no camera coordinate conversion needed)

### Text Display System
- Loads handwritten image textures instead of text
- Centers text within dialogue bubble
- Adds 20px margins around text
- Automatically sizes container to fit content
- Handles different text lengths appropriately 