# ===========================================
# TESS.GD - SIMPLE VERSION
# ===========================================

extends Character

const scr_debug : bool = false 
var debug : bool

signal interacted()


func _ready() -> void:
	debug = scr_debug or GameData.sys_debug
	character_name = "Tess"
	super._ready()
	if debug: print("=== TESS COLLISION DEBUG ===")
	if debug: print("Tess collision_layer: ", collision_layer)
	if debug: print("Tess collision_mask: ", collision_mask)
	anim = get_node_or_null("AnimationPlayer")
	if debug: print("AnimationPlayer = " + str(anim.name))
	anim.play("idle_right")
	if debug: print("Tess group includes: " + str(get_tree().get_nodes_in_group("Tess")))
	if get_tree().get_nodes_in_group("Tess").size() > 0:
		for child in get_tree().get_nodes_in_group("Tess"):
			child.remove_from_group("Tess")
	add_to_group("Tess")
	if debug: print("Tess group includes: " + str(get_tree().get_nodes_in_group("Tess")))
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
	if debug: print("Tess: 'What is it?'")
	say_dialogue("tess_what_is_it")
	
func interact():
	emit_signal("interacted")
