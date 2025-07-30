# ===========================================
# SCENES/MAIN.GD (DEBUGGING VERSION)
# ===========================================

extends Node2D

const scr_debug : bool = false 
var debug : bool

@onready var scene_holder: Node2D = $SceneHolder
@onready var ui: CanvasLayer = $UI
@onready var game_hud: Control = %GameHUD
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
	debug = scr_debug or GameData.sys_debug
	switch_scenes("central_bath")
	if debug: print("current scene = ", str(current_scene))
	if debug: print("=== GATHER HEARTS - SCENE SYSTEM ===")
	setup_game()
	load_initial_scene()

#func set_tess(tess_node : Character) -> void:
#	tess = tess_node

#func set_friend(friend_node : Character) -> void:
#	friend = friend_node


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
	if debug: print("Scene system ready")

func load_initial_scene() -> void:
	load_scene("central_bath")

func load_scene(scene_name: String) -> void:
	if debug: print("Loading scene: ", scene_name)
	
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
			
			if debug: print("Scene loaded: ", scene_name)
		else:
			if debug: print("ERROR: Could not load scene: ", scene_path)
	else:
		if debug: print("ERROR: Scene not found: ", scene_name)

func get_tess() -> Character:
	return tess

func transition_to_scene(scene_name: String, fade_duration: float = 0.5) -> void:
	if debug: print("Transitioning to: ", scene_name)
	
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
	if debug: print("Area unlocked: ", area_name)
	# Could auto-transition or show unlock message

func connect_signals() -> void:
	if debug: print("Connecting signals...")
	# Connect to game manager signals
	if GameManager:
		GameManager.heart_collected.connect(_on_heart_collected)
		GameManager.game_state_changed.connect(_on_game_state_changed)
		if debug: print("GameManager signals connected")
	else:
		if debug: print("ERROR: GameManager not found!")

func setup_global_input_handling() -> void:
	if debug: print("Setting up global input handling...")
	
	# Connect to InputManager if available
	if InputManager:
		InputManager.touch_started.connect(_on_global_touch_started)
		if debug: print("InputManager connected")
	else:
		if debug: print("ERROR: InputManager not found!")

func _on_global_touch_started(position: Vector2) -> void:
	if debug: print("=== TOUCH DETECTED ===")
	if debug: print("Touch position (screen): ", position)
	tess = GameManager.get_tess()
	if not tess:
		if debug: print("ERROR: No Tess to move!")
		return
	
	# Check if Tess has enough energy to move
	if tess.uses_energy:
		var current_energy = GameManager.get_energy()
		if current_energy <= 0:
			if debug: print("Tess cannot move - no energy (", current_energy, ")")
			return
		if debug: print("Tess energy before movement: ", current_energy)
	
	var world_position = get_global_mouse_position()
	if debug: print("World position (converted): ", world_position)
	
	# Check if Tess is in an interactive area
	if is_tess_in_interactive_area():
		# Only allow movement if click is far enough away to exit the area
		var distance_to_click = tess.global_position.distance_to(world_position)
		if distance_to_click < 100:  # Adjust this threshold as needed
			if debug: print("Click too close while in interactive area - ignoring")
			return
		else:
			if debug: print("Click far enough to exit area - allowing movement")
	
	if debug: print("Calling tess.move_to() with: ", world_position)
	tess.move_to(world_position)

func is_tess_in_interactive_area() -> bool:
	# Simple check - you could make this more sophisticated
	var interactive_areas = get_tree().get_nodes_in_group("interactive_areas")
	for area in interactive_areas:
		if area.player_has:  # Assuming your areas have this variable
			return true
	return false

func is_position_over_interactive_area(world_pos: Vector2) -> bool:
	var space_state = get_viewport().world_2d.direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	query.collision_mask = 0b1111  # Check all layers (1, 2, 4, 8)
	
	var results = space_state.intersect_point(query)
	if debug: print("Checking position: ", world_pos, " - Found ", results.size(), " colliders")
	
	for result in results:
		var collider = result.collider
		var area = collider.get_parent()
		if debug: print("Found object: ", area.name, " (", area.get_class(), ")")
		
		if area.has_method("toggle_open_close") or area.name.contains("Cab"):
			if debug: print("Found interactive area: ", area.name)
			return true
	
	return false


func _on_global_touch_started_old(position: Vector2) -> void:
	if debug: print("=== TOUCH DETECTED ===")
	if debug: print("Touch position (screen): ", position)
	
	if not tess:
		if debug: print("ERROR: No Tess to move!")
		return
	
	# Convert screen coordinates to world coordinates
	var world_position = get_global_mouse_position()
	'''
	print("World position (converted): ", world_position)
	print("Offset difference: ", position - world_position)
	
	print("Tess current position: ", tess.global_position)
	print("Tess can_move: ", tess.can_move)
	print("Tess is_moving: ", tess.is_moving)
	
	# Tell Tess to move to WORLD position, not screen position
	print("Calling tess.move_to() with: ", world_position)
	'''
	tess.move_to(world_position)
	'''
	print("After move_to call:")
	print("Tess target_position: ", tess.target_position)
	print("Tess is_moving: ", tess.is_moving)
'''
func _input(event: InputEvent) -> void:
	# Handle call friend input
	if event.is_action_pressed("call_friend"):
		if debug: print("=== CALL FRIEND ACTION DETECTED ===")
		call_friend()
		return
	
	# Backup input handling if InputManager fails
	if event is InputEventScreenTouch:
		if event.pressed:
			if debug: print("=== BACKUP TOUCH DETECTED ===")
			if debug: print("Touch position (screen): ", event.position)
			# Use world coordinates for movement
			var world_pos = get_global_mouse_position()
			if debug: print("World position (converted): ", world_pos)
			_on_global_touch_started(world_pos)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if debug: print("=== BACKUP MOUSE CLICK DETECTED ===")
			if debug: print("Click position (screen): ", event.position)
			# Use world coordinates for movement
			var world_pos = get_global_mouse_position()
			if debug: print("World position (converted): ", world_pos)
			_on_global_touch_started(world_pos)

func _on_heart_collected(heart_data: Dictionary) -> void:
	if debug: print("Main: Heart collected - ", heart_data)

func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	if debug: print("Main: Game state changed to - ", GameManager.GameState.keys()[new_state])

func test_simple_movement() -> void:
	if debug: print("=== SIMPLE MOVEMENT TEST ===")
	if tess:
		if debug: print("Testing direct movement...")
		if debug: print("Tess current position: ", tess.global_position)
		if debug: print("Moving to (400, 400)")
		
		tess.target_position = Vector2(400, 400)
		tess.is_moving = true
		
		if debug: print("Movement set - target: ", tess.target_position)
		if debug: print("is_moving: ", tess.is_moving)
	else:
		if debug: print("ERROR: Tess not found!")

func call_friend() -> void:
	if debug: print("=== CALLING FRIEND ===")

	var tess = get_tree().get_nodes_in_group("Tess")[0]
	
	# Play the call animation
	tess.anim.play("call_friend")
	
	# Wait 1.5 seconds, then show Tess's dialogue
	await get_tree().create_timer(1.5).timeout
	tess.call_friend_dialogue()
	
	# Wait for animation to complete or timeout after 4 seconds
	var animation_timer = get_tree().create_timer(4.0)
	animation_timer.timeout.connect(func():
		if debug: print("Call animation completed or timed out")
	)
	
	# Wait for either animation to finish or timeout
	await animation_timer.timeout
#	tess.anim.play("idle_right")
	# Find the friend in the scene
	var friend_nodes = get_tree().get_nodes_in_group("Friend")
	if friend_nodes.size() > 0:
		var friend = friend_nodes[0]
		if friend.has_method("summon_friend"):
			friend.summon_friend()
			if debug: print("Friend summoned successfully")
		else:
			if debug: print("ERROR: Friend doesn't have summon_friend method")
	else:
		if debug: print("ERROR: No friend found in scene")
		if debug: print("Available groups: ", get_tree().get_nodes_in_group("Friend"))
