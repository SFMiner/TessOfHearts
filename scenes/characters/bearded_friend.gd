# ===========================================
# BEARDEDFRIEND.GD - SIMPLE VERSION
# ===========================================

extends Character

func _ready() -> void:
	character_name = "Bearded Friend"
	super._ready()

func setup_character() -> void:
	if sprite:
		create_placeholder_texture(Color("#4C8CB8"))  # Blue

func create_placeholder_texture(color: Color) -> void:
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(color)
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite.texture = texture

func _on_character_touched(position: Vector2) -> void:
	super._on_character_touched(position)
	print("BeardedFriend: 'Hey there, friend.'")
	say_dialogue("friend_hey_there")
