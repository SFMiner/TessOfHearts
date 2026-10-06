# ===========================================
# SCRIPTS/BASE/INTERACTABLE.GD (UPDATED FOR TOUCH)
# ===========================================

extends Node2D
class_name Interactable

signal interacted(interactable: Interactable)
signal interaction_finished(interactable: Interactable)
signal touched(position: Vector2)

@export var interaction_type: String = "default"
@export var can_interact: bool = true
@export var destroy_on_interact: bool = false
@export var interaction_text: String = ""
@export var uses_energy: bool = true  # Whether this interactable uses energy

@onready var area_2d: Area2D = $Area2D
@onready var visual: ColorRect = $Visual

var interaction_data: Dictionary = {}
var is_highlighted: bool = false
var original_modulate: Color

# Initialize the legacy interactable: set up touch detection, visuals, and interaction
func _ready() -> void:
	original_modulate = modulate
	setup_interaction()
	setup_visual()
	setup_touch_detection()

# Create the clickable area and connect touch and mouse signals
func setup_touch_detection() -> void:
	# Connect to Area2D for direct touch events
	if area_2d:
		area_2d.input_event.connect(_on_area_input_event)
		area_2d.mouse_entered.connect(_on_mouse_entered)
		area_2d.mouse_exited.connect(_on_mouse_exited)

# Handle mouse clicks on the interactable's Area2D
func _on_area_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if not can_interact:
		return
		
	# Handle touch and mouse events
	if event is InputEventScreenTouch:
		if event.pressed:
			_on_touched(event.position)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_touched(event.position)

# Highlight the interactable when the mouse cursor enters its area
func _on_mouse_entered() -> void:
	if can_interact:
		highlight()

# Remove highlight when the mouse cursor leaves the interactable
func _on_mouse_exited() -> void:
	remove_highlight()

# Handle touch events: delegate to perform_interaction if conditions are met
func _on_touched(position: Vector2) -> void:
	if can_interact:
		touched.emit(position)
		perform_interaction()

# Apply a highlight shader or visual effect to the interactable
func highlight() -> void:
	if not is_highlighted and can_interact:
		is_highlighted = true
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color.WHITE * 1.4, 0.1)

# Remove the highlight shader or visual effect from the interactable
func remove_highlight() -> void:
	if is_highlighted:
		is_highlighted = false
		var tween = create_tween()
		tween.tween_property(self, "modulate", original_modulate, 0.1)

# Configure interaction-specific properties (override in derived classes)
func setup_interaction() -> void:
	# Set up Area2D for touch detection if it doesn't exist
	if not has_node("Area2D"):
		var area = Area2D.new()
		add_child(area)
		
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(64, 64)  # Default size
		collision.shape = shape
		area.add_child(collision)
		
		area_2d = area

# Set up the visual representation (ColorRect) with the configured color and size
func setup_visual() -> void:
	# Override in derived classes to set specific colors
	pass

# Check if the player has enough energy to perform this interaction
func can_interact_with_energy() -> bool:
	# Dialogue interactions don't use energy
	if interaction_type == "dialogue" or interaction_type == "guide_cat":
		return true
	
	if not uses_energy:
		return true
	
	var energy = GameManager.get_energy()
	var can_interact = energy > 0
	
	if not can_interact:
		print(name, " cannot interact - no energy (", energy, ")")
	
	return can_interact

# Deduct energy for this interaction; return true if energy was available and spent
func spend_energy_for_interaction(amount: int = 1) -> bool:
	# Dialogue interactions don't use energy
	if interaction_type == "dialogue" or interaction_type == "guide_cat":
		return true
	
	if not uses_energy:
		return true
	
	var current_energy = GameManager.get_energy()
	if current_energy < amount:
		print(name, " cannot interact - insufficient energy (", current_energy, " < ", amount, ")")
		return false
	
	GameManager.spend_energy(amount)
	print(name, " spent ", amount, " energy for interaction. Remaining: ", GameManager.get_energy())
	return true

# Execute the interaction: check energy, call handle_interaction, then disable
func perform_interaction() -> void:
	print("Interacting with: ", name)
	
	# Check energy before allowing interaction
	if not can_interact_with_energy():
		print(name, " interaction cancelled - insufficient energy")
		return
	
	# Spend energy for interaction
	if not spend_energy_for_interaction(1):
		print(name, " interaction cancelled - no energy")
		return
	
	interacted.emit(self)
	
	# Visual feedback for interaction
	var feedback_tween = create_tween()
	feedback_tween.parallel().tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	feedback_tween.parallel().tween_property(self, "modulate", Color.WHITE * 1.8, 0.1)
	feedback_tween.tween_property(self, "scale", Vector2.ONE, 0.1)
	feedback_tween.parallel().tween_property(self, "modulate", original_modulate, 0.1)
	
	# Placeholder for specific interaction logic
	handle_interaction()
	
	if destroy_on_interact:
		var destroy_tween = create_tween()
		destroy_tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.3)
		destroy_tween.parallel().tween_property(self, "modulate", Color.TRANSPARENT, 0.3)
		destroy_tween.tween_callback(queue_free)
	
	interaction_finished.emit(self)

# Placeholder for derived classes to implement specific interaction logic
func handle_interaction() -> void:
	# Override in derived classes for specific behavior
	pass

# Prevent further interactions with this object (gray out visuals, remove from groups)
func disable_interaction() -> void:
	can_interact = false
	if visual:
		visual.modulate = Color(0.5, 0.5, 0.5, 0.7)

# Re-enable interaction with this object (restore visuals, add back to groups)
func enable_interaction() -> void:
	can_interact = true
	if visual:
		visual.modulate = Color.WHITE
