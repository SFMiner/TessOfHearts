# Smart Interactable System

## Overview

The Smart Interactable System is a clean, extensible architecture for handling all interactive objects in Tess of Hearts. It solves critical input handling issues and provides a consistent interaction experience across all game elements.

## Architecture

### Class Hierarchy

```
SmartInteractable (Base Class)
├── SmartCollectable (Inventory Items)
├── GuideCat (Dialogue NPCs)
├── Openable (Doors, Containers)
└── Other Interactables (Biopods, Kilns, etc.)
```

### Key Features

1. **Automatic Interaction Areas**: Each interactable has a circular detection area
2. **Smart Click Handling**: Distinguishes between movement vs interaction
3. **Integrated Energy Management**: Automatic energy cost handling
4. **Visual Feedback**: Highlighting, scaling, and fade effects
5. **Proper Input Hierarchy**: Respects UI button priority

## Core Components

### SmartInteractable (Base Class)

**Location**: `scripts/base/smart_interactable.gd`

**Key Properties**:
- `interaction_range`: Circular detection area radius (default: 50 pixels)
- `energy_cost`: Energy required for interaction (default: 1)
- `auto_collect_on_enter`: Whether to auto-collect when Tess enters range
- `uses_energy`: Whether this interactable consumes energy

**Key Methods**:
- `perform_interaction()`: Main interaction logic with energy checking
- `handle_interaction()`: Override for specific behavior
- `is_tess_in_range()`: Helper to check if Tess is in interaction range

**Smart Click Logic**:
```gdscript
func _on_interactable_touched(position: Vector2) -> void:
    if tess_in_interaction_area:
        # Tess is in range - perform interaction
        perform_interaction()
        return  # Don't allow movement
    else:
        # Tess is not in range - allow movement toward interactable
        pass  # Let click propagate to movement system
```

### SmartCollectable (Inventory Items)

**Location**: `scripts/smart_collectable.gd`

**Features**:
- Automatic texture loading based on collectable type
- Visual collection effects (scale + fade)
- Inventory integration via GameManager
- Random texture variants for variety

**Collectable Types**:
```gdscript
enum CollectableType {
    heart_whole,
    heart_1third,
    heart_half,
    heart_2third,
    whiskey,
    cookie,
    sutures,
    tape,
    barbed_wire,
    gold
}
```

## Input Handling Improvements

### UI Click Detection

The system includes sophisticated UI click detection in `main.gd`:

```gdscript
func is_click_on_ui_element(click_position: Vector2) -> bool:
    # Check dialogue choice UI
    # Check specific UI button paths
    # Check ui_buttons group
    # Check any Control with MOUSE_FILTER_STOP
```

**Detection Hierarchy**:
1. Dialogue choice UI bounds
2. Specific UI button paths in GameHUD
3. UI buttons in the `ui_buttons` group
4. Any Control with `MOUSE_FILTER_STOP` containing interactive elements

### Coordinate System Consistency

**Fixed Issue**: Dialogue choice movement interference due to coordinate system mismatch.

**Solution**: Proper coordinate conversion in `is_click_on_ui_element()`:
- Convert world click position to screen coordinates before comparing to UI bounds
- Proper detection of dialogue choice container and individual choice button areas
- Prevents movement when clicking dialogue options

### Precise Input Event Filtering

**Fixed Issue**: Openables triggering on mouse hover instead of clicks.

**Solution**: Enhanced input filtering in `openable.gd`:
```gdscript
# Only respond to actual press events
if event is InputEventScreenTouch and event.pressed:
    handle_interaction()
elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
    handle_interaction()
# Ignore all mouse movement and hover events
```

### Legacy Code Cleanup

**Fixed Issue**: Movement paralysis in clustered item areas.

**Solution**: Removed outdated `is_tess_in_interactive_area()` distance check from `main.gd`:
- Old code was blocking movement to ANY target if Tess was in ANY interaction area
- New smart interactable system handles range detection properly
- Movement is only blocked when clicking on the specific interactable Tess is already near

### Mouse Filter Management

**Fixed Issues**:
- UI buttons now work immediately at game start
- No unwanted movement when clicking UI buttons
- Proper input event hierarchy

**Key Fixes**:
```gdscript
# In dialogue_choice_ui.gd
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE  # Start non-blocking
    choice_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

func hide_choices() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE  # Reset when hiding
    choice_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
```

## Creating New Interactables

### Basic Interactable

```gdscript
extends SmartInteractable

func _ready() -> void:
    super._ready()  # Call parent setup
    interaction_range = 60.0  # Custom range
    energy_cost = 2  # Custom energy cost

func handle_interaction() -> void:
    # Your custom interaction logic here
    print("Custom interaction performed!")
    # Don't call queue_free() unless you want to destroy the object
```

### Auto-Collecting Item

```gdscript
extends SmartInteractable

func _ready() -> void:
    super._ready()
    auto_collect_on_enter = true  # Auto-collect when Tess enters range
    energy_cost = 0  # No energy cost for auto-collection

func handle_interaction() -> void:
    # Add to inventory or perform effect
    GameManager.add_collectable(CollectableType.whiskey)
    queue_free()
```

### Dialogue NPC

```gdscript
extends SmartInteractable

func _ready() -> void:
    super._ready()
    interaction_range = 80.0  # Larger range for NPCs
    energy_cost = 0  # Dialogue doesn't cost energy

func handle_interaction() -> void:
    # Trigger dialogue
    DialogueSystem.show_dialogue("npc_greeting")
```

## Migration Guide

### Converting Existing Interactables

**Step 1**: Change inheritance
```gdscript
# Old
extends Area2D

# New
extends SmartInteractable
```

**Step 2**: Update _ready() method
```gdscript
func _ready() -> void:
    super._ready()  # Call parent setup
    # Your existing setup code here
```

**Step 3**: Move interaction logic to handle_interaction()
```gdscript
# Old
func _on_area_input_event(viewport, event, shape_idx):
    if event is InputEventScreenTouch and event.pressed:
        perform_collection()

# New
func handle_interaction() -> void:
    perform_collection()  # Your existing logic here
```

**Step 4**: Remove duplicate input handling
- Remove `_on_area_input_event` connections
- Remove manual energy checking (handled by base class)
- Remove manual touch detection (handled by base class)

### Example Migration

**Before**:
```gdscript
extends Area2D

func _ready() -> void:
    input_event.connect(_on_area_input_event)

func _on_area_input_event(viewport, event, shape_idx):
    if event is InputEventScreenTouch and event.pressed:
        var energy = GameManager.get_energy()
        if energy > 0:
            GameManager.spend_energy(1)
            collect_item()
```

**After**:
```gdscript
extends SmartInteractable

func _ready() -> void:
    super._ready()
    energy_cost = 1

func handle_interaction() -> void:
    collect_item()  # Your existing collection logic
```

## Energy System Integration

### Automatic Energy Management

The base class automatically handles:
- Energy cost checking before interaction
- Energy spending when interaction is performed
- Blocking interactions when energy is insufficient

### Custom Energy Logic

Override `perform_interaction()` for custom energy handling:

```gdscript
func perform_interaction() -> void:
    # Custom energy logic
    if GameManager.get_energy() >= 5:
        GameManager.spend_energy(5)
        handle_interaction()
    else:
        # Show "not enough energy" message
        DialogueSystem.show_dialogue("not_enough_energy")
```

## Visual Feedback System

### Built-in Effects

The system provides automatic visual feedback:
- Hover highlighting (30% brightness increase)
- Click animations (10% scale + 50% brightness)
- Collection effects (scale + fade for collectables)

### Custom Visual Effects

```gdscript
func handle_interaction() -> void:
    # Custom visual effect
    var tween = create_tween()
    tween.parallel().tween_property(self, "scale", Vector2(2.0, 2.0), 0.3)
    tween.parallel().tween_property(self, "modulate", Color.RED, 0.3)
    
    # Your interaction logic
    perform_custom_action()
```

## Debug Features

### Debug Output

Enable debug mode for detailed logging:

```gdscript
const scr_debug: bool = true  # Set to true for debug output
```

**Debug Information**:
- Interaction area setup
- Touch detection events
- Energy cost calculations
- Tess position tracking

### Visual Debug

The system includes visual indicators for:
- Interaction area boundaries
- Tess position relative to interactables
- Energy cost displays

## Best Practices

### 1. Always Call super._ready()

```gdscript
func _ready() -> void:
    super._ready()  # Required for proper setup
    # Your custom setup code
```

### 2. Override handle_interaction() for Custom Logic

```gdscript
func handle_interaction() -> void:
    # Your custom interaction logic
    # Don't call queue_free() unless you want to destroy the object
```

### 3. Use Appropriate Interaction Ranges

- **Small items**: 40-50 pixels
- **NPCs**: 60-80 pixels  
- **Large objects**: 80-100 pixels

### 4. Set Energy Costs Appropriately

- **Simple interactions**: 1 energy
- **Complex interactions**: 2-3 energy
- **Dialogue**: 0 energy
- **Auto-collection**: 0 energy

### 5. Test Input Handling

Always test:
- UI button functionality
- Movement vs interaction behavior
- Energy cost application
- Visual feedback effects

## Troubleshooting

### Common Issues

**Issue**: Interactable not responding to clicks
**Solution**: Ensure `super._ready()` is called and interaction area is properly set up

**Issue**: UI buttons not working
**Solution**: Check mouse filter settings and ensure proper input hierarchy

**Issue**: Movement conflicts with interaction
**Solution**: Verify `tess_in_interaction_area` logic and click propagation

**Issue**: Energy not being spent
**Solution**: Check `energy_cost` property and ensure `perform_interaction()` is called

### Debug Commands

```gdscript
# Check if Tess is in range
print("Tess in range: ", is_tess_in_range())

# Check energy cost
print("Energy cost: ", energy_cost)

# Check interaction area
print("Interaction range: ", interaction_range)
```

## Performance Considerations

### Optimization Tips

1. **Reuse interaction areas**: Don't create new areas for each instance
2. **Limit debug output**: Disable debug in production builds
3. **Efficient collision detection**: Use appropriate collision layers/masks
4. **Minimize signal connections**: Only connect necessary signals

## Additional Technical Improvements

### Precise Input Event Filtering

**Problem**: Openables (doors, cabinets) were triggering on mouse hover instead of clicks, causing rapid energy drain as they flashed open/closed when scanning the mouse over them.

**Root Cause**: Input event handling was responding to mouse movement events (`InputEventMouseMotion`) as if they were click events.

**Solution**: Enhanced input filtering in `openable.gd` to only respond to actual press events:
- `InputEventScreenTouch` with `event.pressed`
- `InputEventMouseButton` with `event.pressed` and `MOUSE_BUTTON_LEFT`
- Ignore all mouse movement and hover events

### Smart Interactable Movement Blocking

**Problem**: When standing near one collectable, player couldn't move to nearby collectables even when not in their interaction range, causing "movement paralysis" in areas with clustered items.

**Root Cause**: Old legacy code in `main.gd` was checking `is_tess_in_interactive_area()` and blocking movement to ANY target if Tess was in ANY interaction area, regardless of which specific interactable was clicked.

**Solution**: Removed the legacy `is_tess_in_interactive_area()` distance check from `_on_global_touch_started()`, allowing the new smart interactable system to handle range detection properly. Now movement is only blocked when clicking on the specific interactable Tess is already near.

### Dialogue Choice Movement Interference

**Problem**: Clicking on dialogue choice buttons caused player movement to the click location instead of just selecting the dialogue option.

**Root Cause**: Coordinate system mismatch - dialogue choice UI positions were in screen coordinates, but click detection was comparing them to world coordinates.

**Solution**: Fixed coordinate conversion in `is_click_on_ui_element()`:
- Convert world click position to screen coordinates before comparing to UI bounds
- Proper detection of dialogue choice container and individual choice button areas
- Prevents movement when clicking dialogue options

### Enhanced Debug Output

**Improvement**: Better diagnostic information for troubleshooting input issues:
- Detailed logging of input event types and filtering decisions
- Coordinate system conversion debugging
- Movement blocking decision tracking
- Energy usage monitoring for input events

### Memory Management

- Properly remove from groups when destroying objects
- Clean up signal connections in `_exit_tree()`
- Use weak references for long-lived connections

## Future Extensions

### Planned Features

1. **Interaction Chains**: Multi-step interaction sequences
2. **Conditional Interactions**: Requirements-based interaction availability
3. **Animation Integration**: Seamless animation system integration
4. **Audio Integration**: Automatic sound effect triggering
5. **Particle Effects**: Built-in particle system for interactions

### Extension Points

The system is designed for easy extension:
- Override `handle_interaction()` for custom behavior
- Extend `SmartInteractable` for new interactable types
- Add new signal types for complex interactions
- Implement custom visual feedback systems 