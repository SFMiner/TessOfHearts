# ===========================================
# HANDWRITTEN BUTTON COMPONENT (FIXED)
# ===========================================

extends Control
class_name HandwrittenButton

@onready var sprite: Sprite2D = $Sprite2D
@onready var area: Area2D = $Area2D

signal pressed

var normal_texture: Texture2D
var hover_texture: Texture2D  # Optional lighter/highlighted version
var text_manager

func _ready() -> void:
	# Try multiple ways to get the HandwrittenTextManager
	text_manager = get_node_or_null("/root/HandwrittenTextManager")
	if not text_manager:
		# Try the singleton approach
		text_manager = HandwrittenTextManager
	if not text_manager:
		# Try finding it in the scene tree
		text_manager = get_tree().get_first_node_in_group("handwritten_text_manager")
	
	if not text_manager:
		print("ERROR: HandwrittenTextManager not found in HandwrittenButton")
		return
	
	# Set up input handling
	if area:
		area.input_event.connect(_on_input_event)
		area.mouse_entered.connect(_on_mouse_entered)
		area.mouse_exited.connect(_on_mouse_exited)
	else:
		print("ERROR: Area2D not found in HandwrittenButton")

func set_button_text(category: String, key: String) -> void:
	if not text_manager:
		print("ERROR: No text manager available for button text: ", category, "/", key)
		return
	
	if text_manager.has_method("get_handwritten_texture"):
		normal_texture = text_manager.get_handwritten_texture(category, key)
	else:
		print("ERROR: text_manager doesn't have get_handwritten_texture method")
		return
	
	if sprite and normal_texture:
		sprite.texture = normal_texture
	else:
		print("ERROR: Failed to set button texture - sprite: ", sprite != null, " texture: ", normal_texture != null)

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
