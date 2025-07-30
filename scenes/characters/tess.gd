# ===========================================
# TESS.GD - SIMPLE VERSION
# ===========================================

extends Character

const scr_debug : bool = false 
var debug : bool

signal interacted()

@onready var camera : Camera2D = get_node_or_null("Camera2D")

func _ready() -> void:
	debug = scr_debug or GameData.sys_debug
	character_name = "Tess"
	super._ready()
	set_camera_limits()
	
	# Initialize movement tracking
	GameData.record_tess_position(global_position)
	
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
	
func set_camera_limits():
	camera.limit_right = GameData.camera_limit_right
	camera.limit_bottom = GameData.camera_limit_bottom
	camera.limit_left = GameData.camera_limit_left
	camera.limit_top = GameData.camera_limit_top

# Override movement functions to record movement for friend
func move_to(new_position: Vector2) -> void:
	# Call parent movement function
	super.move_to(new_position)

func move_towards_target() -> void:
	# Call parent movement function
	super.move_towards_target()

func _physics_process(delta: float) -> void:
	# Continuously update Tess's position in GameData
	GameData.record_tess_position(global_position)
	
	# Call parent physics process
	super._physics_process(delta)

func show_dialogue_choices(choices: Array[Dictionary]) -> void:
	# Get the choice UI and show Tess's dialogue choices
	var choice_ui = get_tree().current_scene.get_node_or_null("UI/DialogueChoiceUI")
	if choice_ui:
		choice_ui.show_choices(choices, global_position)
	else:
		print("ERROR: Choice UI not found")
