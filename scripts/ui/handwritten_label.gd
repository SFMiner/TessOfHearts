# ===========================================
# HANDWRITTEN UI COMPONENTS - FIXED VERSION
# ===========================================

extends Control
class_name HandwrittenLabel

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
var text_manager


const scr_debug : bool = false 
var debug : bool

func _ready() -> void:
	debug = scr_debug or GameData.sys_debug
	if debug: print("=== HANDWRITTEN LABEL SETUP ===")
	text_manager = get_node_or_null("/root/HandwrittenTextManager")
	if not text_manager:
		text_manager = HandwrittenTextManager
	if not text_manager:
		text_manager = get_tree().get_first_node_in_group("handwritten_text_manager")
	
	# Create sprite if it doesn't exist
	if not sprite:
		if debug: print("Creating sprite manually")
		sprite = Sprite2D.new()
		add_child(sprite)
		sprite.name = "Sprite2D"
	
	if debug: print("Handwritten label setup complete")

func set_handwritten_text(category: String, key: String) -> void:
	if not text_manager:
		return
	if debug: 
		print("=== SETTING HANDWRITTEN TEXT ===")
		print("Category: ", category)
		print("Key: ", key)
	
	var texture = text_manager.get_handwritten_texture(category, key)
	if texture and sprite:
		if debug: print("Texture loaded: ", texture.get_size())
		sprite.texture = texture
		
		# Center the sprite within the control (accounting for sprite origin at top-left)
		var margin = 20
		sprite.position = Vector2(margin, margin) + (texture.get_size() / 2)
		
		# Adjust control size to match texture + margins
		if texture.get_size() != Vector2.ZERO:
			var content_size = texture.get_size() + Vector2(margin * 2, margin * 2)
			custom_minimum_size = content_size
			size = content_size
			if debug: 
				print("Control resized to: ", size)
				print("Sprite positioned at: ", sprite.position)
	else:
		if debug: print("ERROR: Failed to load texture or sprite not found")

func set_number(value: int) -> void:
	if not text_manager:
		return
	if debug: 
		print("=== SETTING NUMBER ===")
		print("Value: ", value)
	
	var texture = text_manager.get_number_texture(value)
	if texture and sprite:
		if debug: print("Number texture loaded: ", texture.get_size())
		sprite.texture = texture
		
		# Center the sprite within the control
		var margin = 20
		sprite.position = Vector2(margin, margin) + (texture.get_size() / 2)
		
		if texture.get_size() != Vector2.ZERO:
			var content_size = texture.get_size() + Vector2(margin * 2, margin * 2)
			custom_minimum_size = content_size
			size = content_size
			if debug: print("Number control resized to: ", size)
	else:
		if debug: print("ERROR: Failed to load number texture")
