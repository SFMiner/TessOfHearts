# ===========================================
# SCENES/MAIN.GD (DEBUGGING VERSION)
# ===========================================

extends Node2D

const scr_debug : bool = true 
var debug : bool


@onready var save_load_ui: SaveLoadUI
var save_system: Node

@onready var scene_holder: Node2D = $SceneHolder
@onready var ui: CanvasLayer = $UI
@onready var game_hud: Control = %GameHUD
@onready var current_scene: Node2D
@onready var tess: Character
@onready var friend: Character

var recent_interaction_time: float = 0.0
var interaction_cooldown: float = 0.1  # 100ms cooldown after interactions

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
	setup_save_system()
	# Fix friend's initial state by programmatically dismissing and recalling
	await get_tree().process_frame  # Wait for scene to be ready
	fix_friend_initial_state()
	
	# Test: Try to fix input issue by triggering dialogue choice selection
	await get_tree().create_timer(1.0).timeout  # Wait a bit longer
	test_dialogue_input_fix()

	setup_global_input_handling()
	
	# Do not remove this, it is important.
	scene_holder.get_children()[0].name = "Room"

func setup_save_system() -> void:
	print("=== SETTING UP SAVE SYSTEM ===")
	
	# Create and add save system as autoload (or add manually)
	if not get_node_or_null("/root/SaveSystem"):
		var save_system_script = preload("res://scripts/autoload/save_system.gd")
		save_system = save_system_script.new()
		save_system.name = "SaveSystem"
		get_tree().root.add_child(save_system)
		print("Save system created and added to scene tree")
	else:
		save_system = get_node("/root/SaveSystem")
		print("Save system found in scene tree")
	
	# Create save/load UI
	var save_load_ui_scene = preload("res://scenes/ui/save_load_ui.tscn")
	save_load_ui = save_load_ui_scene.instantiate()
	save_load_ui.visible = false

	# Add to UI layer
	var ui_layer = get_node("UI")  # Assuming you have a UI CanvasLayer
	if ui_layer:
		ui_layer.add_child(save_load_ui)
		print("Save/Load UI added to UI layer")
	else:
		add_child(save_load_ui)  # Fallback
		print("Save/Load UI added to main scene")
	
	# Connect signals
	save_load_ui.save_selected.connect(_on_save_selected)
	save_load_ui.load_selected.connect(_on_load_selected)
	save_load_ui.ui_closed.connect(_on_save_ui_closed)
	
	# Set up auto-save (optional - every 5 minutes)
	save_system.setup_auto_save(300.0)

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
		# Check if already connected to avoid duplicate connections
		if not InputManager.touch_started.is_connected(_on_global_touch_started):
			InputManager.touch_started.connect(_on_global_touch_started)
			if debug: print("InputManager touch_started signal connected to main.gd")
		else:
			if debug: print("InputManager touch_started signal already connected")
	else:
		if debug: print("ERROR: InputManager not found!")

# Also add this to double-check the connection:
func _on_global_touch_started(position: Vector2) -> void:
	if debug: print("=== MAIN TOUCH DETECTED ===")
	if debug: print("Touch position (screen): ", position)
	if debug: print("Signal connection working!")
	
	# CRITICAL: Check UI elements BEFORE doing anything else
	if is_click_on_ui_element(position):
		if debug: print("MAIN: Click is on UI element - completely ignoring")
		return
	else:
		if debug: print("MAIN: Click is NOT on UI element")
	
	# NEW: Check if click is on an interactable that Tess is already in range of
	if is_click_on_interactable_in_range(position):
		if debug: print("MAIN: Click is on interactable in range - letting interactable handle it")
		return
	else:
		if debug: print("MAIN: Click is NOT on interactable in range")
		
	
	# Also check if click is in the UI layer area (fallback)
	var viewport_size = get_viewport().get_visible_rect().size
	var ui_area_rect = Rect2(Vector2(0, 0), viewport_size)
	if ui_area_rect.has_point(position):
		# Check if there are any UI elements at this position
		var ui_layer = get_tree().get_root().get_node_or_null("UI")
		if ui_layer:
			if debug: print("Click is in UI layer area - checking for UI elements")
			# For now, let's be more conservative and check if click is in the inventory area
			var inventory_area = Rect2(Vector2(0, viewport_size.y - 400), Vector2(400, 400))
			if inventory_area.has_point(position):
				if debug: print("Click is in inventory area - preventing movement")
				return
	
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
#	if is_tess_in_interactive_area():
#		# Only allow movement if click is far enough away to exit the area
#		var distance_to_click = tess.global_position.distance_to(world_position)
#		if distance_to_click < 100:  # Adjust this threshold as needed
#			if debug: print("Click too close while in interactive area - ignoring")
#			return
#		else:
#			if debug: print("Click far enough to exit area - allowing movement")
	
	# Check if Tess is moving toward the friend and should stop at interaction area
	if is_moving_toward_friend(world_position):
		if debug: print("Tess is moving toward friend - will stop at interaction area")
		# Don't call tess.move_to() - let the friend's interaction area handle stopping
		return
	
	if debug: print("Calling tess.move_to() with: ", world_position)
	tess.move_to(world_position)


func is_click_on_interactable_in_range(click_position: Vector2) -> bool:
	if debug: print("=== CHECKING SMART INTERACTABLE CLICK ===")
	
	# Convert click position to world coordinates
	var world_click_position = get_global_mouse_position()
	if debug: print("World click position: ", world_click_position)
	
	# Get all smart interactables
	var smart_interactables = get_tree().get_nodes_in_group("interactables")
	if debug: print("Found ", smart_interactables.size(), " interactables")
	
	for interactable in smart_interactables:
		if debug: print("Checking interactable: ", interactable.name, " at position: ", interactable.global_position)
		
		# Check if Tess is in THIS specific interactable's area
		var tess_in_area = false
		if "tess_in_interaction_area" in interactable:
			tess_in_area = interactable.tess_in_interaction_area
		elif interactable.has_method("is_tess_in_range"):
			tess_in_area = interactable.is_tess_in_range()
		
		if debug: print("  - Tess in area: ", tess_in_area)
		
		if tess_in_area:
			# Get the interaction range
			var interaction_range = 50.0  # Default
			if "interaction_range" in interactable:
				interaction_range = interactable.interaction_range
			elif interactable.get("interaction_range"):
				interaction_range = interactable.get("interaction_range")
			
			# Calculate distance to clicked position
			var distance_to_click = interactable.global_position.distance_to(world_click_position)
			
			if debug: print("  - Interaction range: ", interaction_range)
			if debug: print("  - Distance to click: ", distance_to_click)
			if debug: print("  - Will block movement: ", distance_to_click <= interaction_range)
			
			# Only block if the click is on the SAME interactable that Tess is near
			if distance_to_click <= interaction_range:
				if debug: print("BLOCKING MOVEMENT - Click is on interactable Tess is near: ", interactable.name)
				return true
			else:
				if debug: print("ALLOWING MOVEMENT - Click is far from interactable Tess is near")
	
	if debug: print("ALLOWING MOVEMENT - No blocking interactables found")
	return false
	
func is_tess_in_interactive_area() -> bool:
	# Simple check - you could make this more sophisticated
	var interactive_areas = get_tree().get_nodes_in_group("interactive_areas")
	for area in interactive_areas:
		if area.player_has:  # Assuming your areas have this variable
			return true
	return false

# Replace your is_click_on_ui_element function with this debug version:

func is_click_on_ui_element(click_position: Vector2) -> bool:
	if debug: print("=== CHECKING UI CLICK ===")
	if debug: print("Click position (world): ", click_position)
	
	# CRITICAL FIX: Convert world coordinates to screen coordinates for UI comparison
	var camera = get_viewport().get_camera_2d()
	var screen_click_position = click_position
	if camera:
		# Convert world position to screen position
		var canvas_transform = get_viewport().get_canvas_transform()
		screen_click_position = canvas_transform * click_position
	
	if debug: print("Click position (screen): ", screen_click_position)
	
	# Check dialogue choice UI first with corrected coordinates
	var choice_ui_nodes = get_tree().get_nodes_in_group("dialogue_choice_ui")
	if debug: print("Found ", choice_ui_nodes.size(), " dialogue choice UI nodes")
	
	for choice_ui in choice_ui_nodes:
		if debug: print("Checking choice UI: ", choice_ui.name)
		if debug: print("  - Visible: ", choice_ui.visible)
		
		if choice_ui.visible and "is_showing" in choice_ui and choice_ui.is_showing:
			if debug: print("Found ACTIVE dialogue choice UI!")
			
			# Check if click is within the entire dialogue choice UI area
			var choice_container = choice_ui.get_node_or_null("ChoiceContainer")
			if choice_container:
				if debug: print("  - Choice container found")
				if debug: print("  - Container global_position: ", choice_container.global_position)
				if debug: print("  - Container size: ", choice_container.size)
				
				# Use screen coordinates for comparison
				var container_rect = Rect2(choice_container.global_position, choice_container.size)
				if debug: print("  - Container rect: ", container_rect)
				if debug: print("  - Screen click position: ", screen_click_position)
				
				if container_rect.has_point(screen_click_position):
					if debug: print("BLOCKING CLICK - Within dialogue choice container bounds!")
					return true
				else:
					if debug: print("  - Click NOT in container bounds")
					
					# Check individual choice children
					if debug: print("  - Checking ", choice_container.get_child_count(), " choice container children")
					for i in range(choice_container.get_child_count()):
						var child = choice_container.get_child(i)
						if debug: print("    - Child ", i, ": ", child.name, " at ", child.global_position, " size ", child.size)
						var child_rect = Rect2(child.global_position, child.size)
						if child_rect.has_point(screen_click_position):
							if debug: print("BLOCKING CLICK - Within dialogue choice child bounds!")
							return true
			else:
				if debug: print("  - No ChoiceContainer found in dialogue UI")
				
				# Fallback: check the entire dialogue UI bounds
				var ui_rect = Rect2(choice_ui.global_position, choice_ui.size)
				if debug: print("  - Fallback: checking entire UI rect: ", ui_rect)
				if ui_rect.has_point(screen_click_position):
					if debug: print("BLOCKING CLICK - Within dialogue UI bounds (fallback)!")
					return true
	
	# Check GameHUD buttons (use original click_position since this was working)
	var game_hud = get_tree().current_scene.get_node_or_null("UI/GameHUD")
	if game_hud:
		var button_paths = [
			"VBoxContainer2/InventoryContainer/Inventory/ConsumeCookieButton",
			"VBoxContainer2/InventoryContainer/Inventory/ConsumeWhiskeyButton",
			"VBoxContainer2/InventoryContainer/Inventory/CraftTapeHeartButton",
			"VBoxContainer2/InventoryContainer/Inventory/CraftWireHeartButton",
			"VBoxContainer2/InventoryContainer/Inventory/CraftSewnHeartButton",
			"VBoxContainer2/InventoryContainer/Inventory/Settings"
		]
		
		for button_path in button_paths:
			var button = game_hud.get_node_or_null(button_path)
			if button and button.visible and not button.disabled:
				var button_rect = Rect2(button.global_position, button.size)
				if button_rect.has_point(screen_click_position):
					if debug: print("Click is on GameHUD button: ", button.name)
					return true
	
	if debug: print("No UI element clicked - allowing movement")
	return false
	
# Helper function to find any Control that should block clicks at a position
func find_blocking_control_at_position(node: Node, position: Vector2) -> Control:
	# Check if this node is a blocking Control
	if node is Control:
		var control = node as Control
		# Only consider visible controls that explicitly stop input
		if control.visible and control.mouse_filter == Control.MOUSE_FILTER_STOP:
			var control_rect = Rect2(control.global_position, control.size)
			if control_rect.has_point(position):
				# Additional check: make sure it's actually a UI element we care about
				if control is Button or control is Panel or control.name.contains("Button"):
					return control
	
	# Recursively check children
	for child in node.get_children():
		var result = find_blocking_control_at_position(child, position)
		if result:
			return result
	
	return null


func is_moving_toward_friend(target_position: Vector2) -> bool:
	# Check if the target position overlaps with the friend's collision areas
	var friend_nodes = get_tree().get_nodes_in_group("Friend")
	if friend_nodes.size() > 0:
		var friend = friend_nodes[0]
		
		# Check if target position overlaps with friend's collision shapes
		var space_state = get_viewport().world_2d.direct_space_state
		var query = PhysicsPointQueryParameters2D.new()
		query.position = target_position
		query.collision_mask = 2  # Friend's collision layer
		
		var results = space_state.intersect_point(query)
		for result in results:
			var collider = result.collider
			# Check if this collider belongs to the friend
			if collider.get_parent() == friend or collider == friend:
				if debug: print("Target position overlaps with friend's collision area")
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
	if event.is_action_pressed("save_menu"):  # Define this in input map
		show_save_menu()
	elif event.is_action_pressed("load_menu"):  # Define this in input map
		show_load_menu()
	elif event.is_action_pressed("quick_save"):  # F5
		save_system.quick_save()
	elif event.is_action_pressed("quick_load"):  # F9
		save_system.quick_load()

	'''
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
'''
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
	var animation_timer = get_tree().create_timer(3.0)
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

func fix_friend_initial_state() -> void:
	if debug: print("=== FIXING FRIEND INITIAL STATE ===")
	
	# Find the friend
	var friend_nodes = get_tree().get_nodes_in_group("Friend")
	if friend_nodes.size() == 0:
		if debug: print("ERROR: No friend found for state fix")
		return
	var friend = friend_nodes[0]
	
	if debug: print("Found friend: ", friend.name)
	
	# Programmatically dismiss the friend (without dialogue)
#	if friend.has_method("depart_from_screen"):
#		if debug: print("Dismissing friend...")
#		friend.depart_from_screen()
		
		# Wait a moment for departure to start
#		await get_tree().create_timer(0.5).timeout
		
		# Then immediately summon them back
#		if friend.has_method("summon_friend"):
#			if debug: print("Summoning friend back...")
#			friend.summon_friend()
#			if debug: print("Friend initial state fixed")
#		else:
#			if debug: print("ERROR: Friend doesn't have summon_friend method")
#	else:
#		if debug: print("ERROR: Friend doesn't have depart_from_screen method")

func test_dialogue_input_fix() -> void:
	if debug: print("=== TESTING DIALOGUE INPUT FIX ===")
	
	# Try to trigger the dialogue choice selection process to fix input
	var dialogue_system = get_tree().current_scene.get_node_or_null("DialogueSystem")
	if dialogue_system and dialogue_system.has_method("test_dialogue_choice_fix"):
		if debug: print("Calling dialogue choice fix...")
		dialogue_system.test_dialogue_choice_fix()
	else:
		if debug: print("ERROR: Dialogue system not found or missing test method")
		
func show_save_menu() -> void:
	if save_load_ui:
		save_load_ui.show_save_ui()

func show_load_menu() -> void:
	if save_load_ui:
		save_load_ui.show_load_ui()

func _on_save_selected(slot_number: int) -> void:
	print("Save initiated for slot: ", slot_number)
	# Optionally pause the game during save
	# get_tree().paused = true

func _on_load_selected(slot_number: int) -> void:
	print("Load initiated for slot: ", slot_number)
	# Optionally pause the game during load
	# get_tree().paused = true

func _on_save_ui_closed() -> void:
	print("Save/Load UI closed")
	# Unpause game if it was paused
	# get_tree().paused = false
