# ===========================================
# HANDWRITTEN UI COMPONENTS
# ===========================================

extends Control
class_name HandwrittenLabel

@onready var sprite: Sprite2D = $Sprite2D
var text_manager

func _ready() -> void:
	text_manager = get_node("/root/HandwrittenTextManager")
	# Create sprite if it doesn't exist
	if not sprite:
		sprite = Sprite2D.new()
		add_child(sprite)

func set_handwritten_text(category: String, key: String) -> void:
	var texture = text_manager.get_handwritten_texture(category, key)
	if texture and sprite:
		sprite.texture = texture
		# Adjust control size to match texture
		if texture.get_size() != Vector2.ZERO:
			custom_minimum_size = texture.get_size()

func set_number(value: int) -> void:
	var texture = text_manager.get_number_texture(value)
	if texture and sprite:
		sprite.texture = texture
		if texture.get_size() != Vector2.ZERO:
			custom_minimum_size = texture.get_size()
