# ===========================================
# TESS.GD - SIMPLE VERSION
# ===========================================

extends Character

signal interacted()

@onready var camera : Camera2D = get_node_or_null("Camera2D")
@onready var dialog_point : Marker2D = $DialoguePoint
var dialog_point_pos_right : Vector2
var dialog_point_pos_left : Vector2

func _ready() -> void:
	debug = scr_debug or GameData.sys_debug
	character_name = "Tess"
	dialog_point_pos_right = $DialoguePoint.position
	dialog_point_pos_left = Vector2(-dialog_point_pos_right.x, dialog_point_pos_right.y)
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

func set_dialog_point():
	if direction.x > 0:
		dialog_point.position = dialog_point_pos_right
	if direction.x < 0:
		dialog_point.position = dialog_point_pos_left

func create_placeholder_texture(color: Color) -> void:
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(color)
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite.texture = texture

func _on_character_touched(position: Vector2) -> void:
	super._on_character_touched(position)
	if debug: print("Tess touched - no dialogue")
	# say_dialogue("tess_what_is_it")  # Commented out - Tess doesn't speak when clicked
	
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
	set_dialog_point()
	super.move_to(new_position)

func move_towards_target() -> void:
	# Call parent movement function
	set_dialog_point()
	super.move_towards_target()

func _physics_process(delta: float) -> void:
	# Continuously update Tess's position in GameData
	GameData.record_tess_position(global_position)
	z_index = get_global_position().y/5
	# Call parent physics process
	super._physics_process(delta)

func show_dialogue_choices(choices: Array[Dictionary]) -> void:
	# Get the choice UI and show Tess's dialogue choices
	var choice_ui = get_tree().current_scene.get_node_or_null("UI/DialogueChoiceUI")
	if choice_ui:
		choice_ui.show_choices(choices, global_position)
	else:
		print("ERROR: Choice UI not found")

func call_friend_dialogue() -> void:
	# Show Tess's dialogue during the call animation
	var dialogue_system = get_tree().current_scene.find_child("DialogueSystem")
	if dialogue_system:
		# Use Tess herself as the speaker (so the Tess group check works)
		var tess_background_color = Color(1, 0.98, 0.8, 0.9)  # Yellowish off-white background
		dialogue_system.show_dialogue("tess_come_over_here", self, tess_background_color, 0.25)
	else:
		print("ERROR: Dialogue system not found")
