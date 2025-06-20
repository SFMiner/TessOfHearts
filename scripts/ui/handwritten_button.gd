# ===========================================
# HANDWRITTEN BUTTON COMPONENT
# ===========================================

extends Control
class_name HandwrittenButton

@onready var sprite: Sprite2D = $Sprite2D
@onready var area: Area2D = $Area2D

signal pressed

var normal_texture: Texture2D
var hover_texture: Texture2D  # Optional lighter/highlighted version
var text_manager: HandwrittenTextManager

func _ready() -> void:
	text_manager = get_node("/root/HandwrittenTextManager")
	
	# Set up input handling
	area.input_event.connect(_on_input_event)
	area.mouse_entered.connect(_on_mouse_entered)
	area.mouse_exited.connect(_on_mouse_exited)

func set_button_text(category: String, key: String) -> void:
	normal_texture = text_manager.get_handwritten_texture(category, key)
	if sprite and normal_texture:
		sprite.texture = normal_texture

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventScreenTouch and event.pressed:
		pressed.emit()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pressed.emit()

func _on_mouse_entered() -> void:
	# Slight highlight effect
	if sprite:
		sprite.modulate = Color.WHITE * 1.2

func _on_mouse_exited() -> void:
	if sprite:
		sprite.modulate = Color.WHITE
