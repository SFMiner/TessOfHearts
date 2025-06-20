# ===========================================
# TESS.GD - SIMPLE VERSION
# ===========================================

extends Character

func _ready() -> void:
	character_name = "Tess"
	super._ready()
	print("=== TESS COLLISION DEBUG ===")
	print("Tess collision_layer: ", collision_layer)
	print("Tess collision_mask: ", collision_mask)
	anim = get_node_or_null("AnimationPlayer")
	print("AnimationPlayer = " + str(anim.name))
	anim.play("idle_right")
	
#func setup_character() -> void:
#	if sprite:
#		create_placeholder_texture(Color("#8B4CB8"))  # Purple

func create_placeholder_texture(color: Color) -> void:
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(color)
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite.texture = texture

func _on_character_touched(position: Vector2) -> void:
	super._on_character_touched(position)
	print("Tess: 'What is it?'")
	say_dialogue("tess_what_is_it")
