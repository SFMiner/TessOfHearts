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

@onready var area_2d: Area2D = $Area2D
@onready var visual: ColorRect = $Visual

var interaction_data: Dictionary = {}
var is_highlighted: bool = false
var original_modulate: Color

func _ready() -> void:
	original_modulate = modulate
	setup_interaction()
	setup_visual()
	setup_touch_detection()

func setup_touch_detection() -> void:
	# Connect to Area2D for direct touch events
	if area_2d:
		area_2d.input_event.connect(_on_area_input_event)
		area_2d.mouse_entered.connect(_on_mouse_entered)
		area_2d.mouse_exited.connect(_on_mouse_exited)

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

func _on_mouse_entered() -> void:
	if can_interact:
		highlight()

func _on_mouse_exited() -> void:
	remove_highlight()

func _on_touched(position: Vector2) -> void:
	if can_interact:
		touched.emit(position)
		perform_interaction()

func highlight() -> void:
	if not is_highlighted and can_interact:
		is_highlighted = true
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color.WHITE * 1.4, 0.1)

func remove_highlight() -> void:
	if is_highlighted:
		is_highlighted = false
		var tween = create_tween()
		tween.tween_property(self, "modulate", original_modulate, 0.1)

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

func setup_visual() -> void:
	# Override in derived classes to set specific colors
	pass

func perform_interaction() -> void:
	print("Interacting with: ", name)
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

func handle_interaction() -> void:
	# Override in derived classes for specific behavior
	pass

func disable_interaction() -> void:
	can_interact = false
	if visual:
		visual.modulate = Color(0.5, 0.5, 0.5, 0.7)

func enable_interaction() -> void:
	can_interact = true
	if visual:
		visual.modulate = Color.WHITE
