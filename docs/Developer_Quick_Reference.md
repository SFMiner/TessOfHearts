# Developer Quick Reference

## Smart Interactable System

### Creating a New Interactable

```gdscript
extends SmartInteractable

func _ready() -> void:
    super._ready()  # REQUIRED
    interaction_range = 50.0
    energy_cost = 1

func handle_interaction() -> void:
    # Your custom interaction logic
    print("Interaction performed!")
```

### Creating a Collectable Item

```gdscript
extends SmartCollectable

func _ready() -> void:
    super._ready()
    collectable_type = CollectableType.whiskey
    interaction_range = 40.0
    energy_cost = 1
```

### Creating an Auto-Collecting Item

```gdscript
extends SmartInteractable

func _ready() -> void:
    super._ready()
    auto_collect_on_enter = true
    energy_cost = 0

func handle_interaction() -> void:
    GameManager.add_collectable(CollectableType.whiskey)
    queue_free()
```

## Input Handling

### UI Click Detection

The system automatically prevents movement when clicking UI elements:
- Dialogue choice UI
- GameHUD buttons
- Any Control with `MOUSE_FILTER_STOP`

### Precise Input Event Filtering

**For Openables**: Only respond to actual press events, not hover:

```gdscript
func _on_area_input_event(viewport, event, shape_idx):
    if event is InputEventScreenTouch and event.pressed:
        handle_interaction()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        handle_interaction()
    # Ignore all mouse movement and hover events
```

### Coordinate System Consistency

**For UI Detection**: Convert world coordinates to screen coordinates:

```gdscript
# Convert world click position to screen coordinates
var screen_pos = get_viewport().get_canvas_transform() * world_position
var ui_rect = Rect2(ui_element.global_position, ui_element.size)
if ui_rect.has_point(screen_pos):
    return true
```

### Mouse Filter Management

```gdscript
# Start non-blocking
mouse_filter = Control.MOUSE_FILTER_IGNORE

# Block when active
mouse_filter = Control.MOUSE_FILTER_STOP

# Reset when hiding
mouse_filter = Control.MOUSE_FILTER_IGNORE
```

## Energy System

### Automatic Energy Management

```gdscript
# Set energy cost
energy_cost = 2

# Custom energy logic (override perform_interaction)
func perform_interaction() -> void:
    if GameManager.get_energy() >= 5:
        GameManager.spend_energy(5)
        handle_interaction()
    else:
        DialogueSystem.show_dialogue("not_enough_energy")
```

## Visual Feedback

### Built-in Effects

- Hover highlighting (30% brightness)
- Click animations (10% scale + 50% brightness)
- Collection effects (scale + fade)

### Custom Effects

```gdscript
func handle_interaction() -> void:
    var tween = create_tween()
    tween.parallel().tween_property(self, "scale", Vector2(2.0, 2.0), 0.3)
    tween.parallel().tween_property(self, "modulate", Color.RED, 0.3)
    
    # Your interaction logic
    perform_action()
```

## Debug Features

### Enable Debug Output

```gdscript
const scr_debug: bool = true
```

### Debug Commands

```gdscript
# Check if Tess is in range
print("Tess in range: ", is_tess_in_range())

# Check energy cost
print("Energy cost: ", energy_cost)

# Check interaction area
print("Interaction range: ", interaction_range)
```

## Common Patterns

### Dialogue NPC

```gdscript
extends SmartInteractable

func _ready() -> void:
    super._ready()
    interaction_range = 80.0
    energy_cost = 0

func handle_interaction() -> void:
    DialogueSystem.show_dialogue("npc_greeting")
```

### Door/Container

```gdscript
extends SmartInteractable

func _ready() -> void:
    super._ready()
    interaction_range = 60.0
    energy_cost = 1

func handle_interaction() -> void:
    # Toggle door state
    toggle_door()
```

### Complex Interactable

```gdscript
extends SmartInteractable

func _ready() -> void:
    super._ready()
    interaction_range = 100.0
    energy_cost = 3

func handle_interaction() -> void:
    # Check requirements
    if GameManager.has_item("key"):
        perform_complex_action()
    else:
        DialogueSystem.show_dialogue("need_key")
```

## Migration Checklist

### Converting Old Interactables

1. **Change inheritance**:
   ```gdscript
   # Old
   extends Area2D
   
   # New
   extends SmartInteractable
   ```

2. **Update _ready()**:
   ```gdscript
   func _ready() -> void:
       super._ready()  # REQUIRED
       # Your existing setup code
   ```

3. **Move interaction logic**:
   ```gdscript
   # Old
   func _on_area_input_event(viewport, event, shape_idx):
       if event is InputEventScreenTouch and event.pressed:
           perform_action()
   
   # New
   func handle_interaction() -> void:
       perform_action()
   ```

4. **Remove duplicate code**:
   - Remove `_on_area_input_event` connections
   - Remove manual energy checking
   - Remove manual touch detection

## Best Practices

### 1. Always Call super._ready()

```gdscript
func _ready() -> void:
    super._ready()  # Required for proper setup
    # Your custom setup code
```

### 2. Use Appropriate Ranges

- **Small items**: 40-50 pixels
- **NPCs**: 60-80 pixels
- **Large objects**: 80-100 pixels

### 3. Set Energy Costs Appropriately

- **Simple interactions**: 1 energy
- **Complex interactions**: 2-3 energy
- **Dialogue**: 0 energy
- **Auto-collection**: 0 energy

### 4. Test Input Handling

Always test:
- UI button functionality
- Movement vs interaction behavior
- Energy cost application
- Visual feedback effects

## Troubleshooting

### Common Issues

**Issue**: Interactable not responding to clicks
**Solution**: Ensure `super._ready()` is called

**Issue**: UI buttons not working
**Solution**: Check mouse filter settings

**Issue**: Movement conflicts with interaction
**Solution**: Verify `tess_in_interaction_area` logic

**Issue**: Energy not being spent
**Solution**: Check `energy_cost` property

**Issue**: Openables triggering on mouse hover
**Solution**: Filter input events to only respond to press events, not movement

**Issue**: Movement paralysis in clustered areas
**Solution**: Remove legacy `is_tess_in_interactive_area()` checks from main.gd

**Issue**: Dialogue choices causing movement
**Solution**: Fix coordinate system conversion in UI click detection

### Debug Commands

```gdscript
# Check if Tess is in range
print("Tess in range: ", is_tess_in_range())

# Check energy cost
print("Energy cost: ", energy_cost)

# Check interaction area
print("Interaction range: ", interaction_range)
```

## File Locations

### Core System Files

- `scripts/base/smart_interactable.gd` - Base class
- `scripts/smart_collectable.gd` - Collectable items
- `scripts/main.gd` - Input handling improvements
- `scripts/ui/dialogue_choice_ui.gd` - UI fixes

### Documentation

- `docs/Smart_Interactable_System.md` - Complete guide
- `docs/README.md` - Updated with new system
- `docs/Developer_Quick_Reference.md` - This file

## Performance Tips

1. **Reuse interaction areas**: Don't create new areas for each instance
2. **Limit debug output**: Disable debug in production builds
3. **Efficient collision detection**: Use appropriate collision layers/masks
4. **Minimize signal connections**: Only connect necessary signals 