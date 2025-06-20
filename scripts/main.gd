# ===========================================
# SCENES/MAIN.GD (DEBUGGING VERSION)
# ===========================================

extends Node2D

@onready var scene_holder: Node2D = $SceneHolder
@onready var ui: CanvasLayer = $UI
@onready var current_scene: Node2D
@onready var tess: Character
@onready var friend: Character

# Test heart scenes to instance
@export var heart_scene: PackedScene = preload("res://scenes/interactables/Heart.tscn")
@export var whiskey_scene: PackedScene = preload("res://scenes/interactables/Whiskey.tscn")
@export var cookie_scene: PackedScene = preload("res://scenes/interactables/Cookie.tscn")


# Scene management
var scene_files: Dictionary = {
	"central_bath": "res://scenes/areas/central_bath.tscn",
#	"central_bath": "res://scenes/areas/CentralBath.tscn",
#	"heart_chamber": "res://scenes/areas/HeartChamber.tscn",
#	"entrance_hall": "res://scenes/areas/EntranceHall.tscn"
}

func _ready() -> void:
	switch_scenes("central_bath")
	tess = current_scene.tess
	print("=== GATHER HEARTS - SCENE SYSTEM ===")
	setup_game()
	load_initial_scene()

func switch_scenes(scene_name : String) -> void:
	var loaded_scene = load(scene_files[scene_name]).instantiate()
	while scene_holder.get_children().size() > 0:
		scene_holder.remove_child(scene_holder.get_child(0))
	scene_holder.add_child(loaded_scene)
	current_scene = loaded_scene
	
func setup_game() -> void:
	# Connect to game events for scene transitions
	if GameManager:
		GameManager.area_unlocked.connect(_on_area_unlocked)
	
	print("Scene system ready")

func load_initial_scene() -> void:
	load_scene("central_bath")

func load_scene(scene_name: String) -> void:
	print("Loading scene: ", scene_name)
	
	# Unload current scene
	if current_scene:
		current_scene.queue_free()
		current_scene = null
	
	# Load new scene
	if scene_name in scene_files:
		var scene_path = scene_files[scene_name]
		var scene_resource = load(scene_path)
		if scene_resource:
			current_scene = scene_resource.instantiate()
			scene_holder.add_child(current_scene)
			
			# Update GameManager
			if GameManager:
				GameManager.current_area = scene_name
			
			print("Scene loaded: ", scene_name)
		else:
			print("ERROR: Could not load scene: ", scene_path)
	else:
		print("ERROR: Scene not found: ", scene_name)

func transition_to_scene(scene_name: String, fade_duration: float = 0.5) -> void:
	print("Transitioning to: ", scene_name)
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(scene_holder, "modulate", Color.TRANSPARENT, fade_duration)
	tween.tween_callback(func():
		load_scene(scene_name)
		# Fade in
		var fade_in_tween = create_tween()
		fade_in_tween.tween_property(scene_holder, "modulate", Color.WHITE, fade_duration)
	)

func _on_area_unlocked(area_name: String) -> void:
	print("Area unlocked: ", area_name)
	# Could auto-transition or show unlock message

func connect_signals() -> void:
	print("Connecting signals...")
	# Connect to game manager signals
	if GameManager:
		GameManager.heart_collected.connect(_on_heart_collected)
		GameManager.game_state_changed.connect(_on_game_state_changed)
		print("GameManager signals connected")
	else:
		print("ERROR: GameManager not found!")

func setup_global_input_handling() -> void:
	print("Setting up global input handling...")
	
	# Connect to InputManager if available
	if InputManager:
		InputManager.touch_started.connect(_on_global_touch_started)
		print("InputManager connected")
	else:
		print("ERROR: InputManager not found!")

func _on_global_touch_started(position: Vector2) -> void:
	print("=== TOUCH DETECTED ===")
	print("Touch position (screen): ", position)
	
	if not tess:
		print("ERROR: No Tess to move!")
		return
	
	# Convert screen coordinates to world coordinates
	var world_position = get_global_mouse_position()
	print("World position (converted): ", world_position)
	print("Offset difference: ", position - world_position)
	
	print("Tess current position: ", tess.global_position)
	print("Tess can_move: ", tess.can_move)
	print("Tess is_moving: ", tess.is_moving)
	
	# Tell Tess to move to WORLD position, not screen position
	print("Calling tess.move_to() with: ", world_position)
	tess.move_to(world_position)
	
	print("After move_to call:")
	print("Tess target_position: ", tess.target_position)
	print("Tess is_moving: ", tess.is_moving)

func _input(event: InputEvent) -> void:
	# Backup input handling if InputManager fails
	if event is InputEventScreenTouch:
		if event.pressed:
			print("=== BACKUP TOUCH DETECTED ===")
			print("Touch position (screen): ", event.position)
			# Use world coordinates for movement
			var world_pos = get_global_mouse_position()
			print("World position (converted): ", world_pos)
			_on_global_touch_started(world_pos)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("=== BACKUP MOUSE CLICK DETECTED ===")
			print("Click position (screen): ", event.position)
			# Use world coordinates for movement
			var world_pos = get_global_mouse_position()
			print("World position (converted): ", world_pos)
			_on_global_touch_started(world_pos)

func _on_heart_collected(heart_data: Dictionary) -> void:
	print("Main: Heart collected - ", heart_data)

func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	print("Main: Game state changed to - ", GameManager.GameState.keys()[new_state])

func test_simple_movement() -> void:
	print("=== SIMPLE MOVEMENT TEST ===")
	if tess:
		print("Testing direct movement...")
		print("Tess current position: ", tess.global_position)
		print("Moving to (400, 400)")
		
		tess.target_position = Vector2(400, 400)
		tess.is_moving = true
		
		print("Movement set - target: ", tess.target_position)
		print("is_moving: ", tess.is_moving)
	else:
		print("ERROR: Tess not found!")
