# ===========================================
# SCRIPTS/BASE/TOUCHRESPONDER.GD
# ===========================================

extends Node

signal touched(position: Vector2)
signal touch_started(position: Vector2)
signal touch_ended(position: Vector2)

@export var highlight_on_touch: bool = true
@export var highlight_color: Color = Color.WHITE
@export var highlight_intensity: float = 1.5

var parent_node: Node2D
var original_modulate: Color
var is_highlighted: bool = false

func _ready() -> void:
	parent_node = get_parent() as Node2D
	if parent_node:
		original_modulate = parent_node.modulate
	
	# Connect to input manager
	if InputManager:
		InputManager.object_touched.connect(_on_object_touched)

func _on_object_touched(object: Node2D, position: Vector2) -> void:
	if object == parent_node:
		handle_touch(position)

func handle_touch(position: Vector2) -> void:
	touched.emit(position)
	
	if highlight_on_touch:
		highlight()
		# Auto-remove highlight after brief moment
		get_tree().create_timer(0.2).timeout.connect(remove_highlight)

func highlight() -> void:
	if parent_node and not is_highlighted:
		is_highlighted = true
		var tween = create_tween()
		tween.tween_property(parent_node, "modulate", highlight_color * highlight_intensity, 0.1)

func remove_highlight() -> void:
	if parent_node and is_highlighted:
		is_highlighted = false
		var tween = create_tween()
		tween.tween_property(parent_node, "modulate", original_modulate, 0.1)
