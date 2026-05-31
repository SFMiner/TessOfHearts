# ===========================================
# SAVE/LOAD SYSTEM - COMPREHENSIVE GAME STATE
# ===========================================

extends Node

const scr_debug: bool = true
var debug: bool

const SAVE_FILE_PATH = "user://savegames/"
const SAVE_FILE_EXTENSION = ".save"
const MAX_SAVE_SLOTS = 10

signal save_completed(slot_number: int, success: bool)
signal load_completed(slot_number: int, success: bool)

var current_save_slot: int = -1

func _ready() -> void:
	debug = scr_debug or GameData.sys_debug
	# Ensure save directory exists
	if not DirAccess.dir_exists_absolute(SAVE_FILE_PATH):
		DirAccess.open("user://").make_dir_recursive("savegames")
	if debug: print("Save system initialized")

# ===========================================
# SAVE FUNCTIONS
# ===========================================

func save_game(slot_number: int = 0) -> bool:
	if slot_number < 0 or slot_number >= MAX_SAVE_SLOTS:
		if debug: print("ERROR: Invalid save slot: ", slot_number)
		save_completed.emit(slot_number, false)
		return false
	
	if debug: print("=== SAVING GAME TO SLOT ", slot_number, " ===")
	
	var save_data = collect_save_data()
	var file_path = get_save_file_path(slot_number)
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		if debug: print("ERROR: Could not open save file for writing: ", file_path)
		save_completed.emit(slot_number, false)
		return false
	
	# Add metadata
	save_data["metadata"] = {
		"save_slot": slot_number,
		"save_time": Time.get_unix_time_from_system(),
		"save_date": Time.get_datetime_string_from_system(),
		"game_version": "1.0.0"
	}
	
	file.store_string(JSON.stringify(save_data))
	file.close()
	
	current_save_slot = slot_number
	if debug: print("Game saved successfully to slot ", slot_number)
	save_completed.emit(slot_number, true)
	return true

func collect_save_data() -> Dictionary:
	var save_data = {}
	
	# Player data
	save_data["player"] = collect_player_data()
	
	# Game state data
	save_data["game_state"] = collect_game_state_data()
	
	# Inventory data
	save_data["inventory"] = collect_inventory_data()
	
	# World state data
	save_data["world_state"] = collect_world_state_data()
	
	# Progress data
	save_data["progress"] = collect_progress_data()
	
	if debug:
		print("Save data collected:")
		for key in save_data.keys():
			print("  - ", key, ": ", typeof(save_data[key]))
	
	return save_data

func collect_player_data() -> Dictionary:
	var player_data = {}
	
	# Find Tess
	var tess_nodes = get_tree().get_nodes_in_group("Tess")
	if tess_nodes.size() > 0:
		var tess = tess_nodes[0]
		player_data["position"] = {
			"x": tess.global_position.x,
			"y": tess.global_position.y
		}
		player_data["last_direction"] = tess.last_direction
		print("Player position saved: ", tess.global_position)
	else:
		print("WARNING: Tess not found for saving")
		player_data["position"] = {"x": 0, "y": 0}
		player_data["last_direction"] = "right"
	
	# Energy and courage (only save current values, max values are constants)
	player_data["energy"] = GameData.cur_energy
	player_data["courage"] = GameData.cur_courage
	
	print("Player data: Energy=", GameData.cur_energy, " Courage=", GameData.cur_courage)
	
	return player_data

func collect_game_state_data() -> Dictionary:
	var game_state_data = {}
	
	# Current area/scene
	var current_scene = get_tree().current_scene
	if current_scene:
		game_state_data["current_scene"] = current_scene.scene_file_path
		print("Current scene: ", current_scene.scene_file_path)
	
	# Game manager state
	if GameManager:
		game_state_data["game_manager_state"] = GameManager.current_state
		game_state_data["current_area"] = GameManager.current_area
	
	# Camera limits
	game_state_data["camera_limits"] = {
		"top": GameData.camera_limit_top,
		"left": GameData.camera_limit_left,
		"bottom": GameData.camera_limit_bottom,
		"right": GameData.camera_limit_right
	}
	
	return game_state_data

func collect_inventory_data() -> Dictionary:
	var inventory_data = {}
	
	# Basic collectibles
	inventory_data["hearts_whole"] = GameData.num_hearts_whole
	inventory_data["hearts_2third"] = GameData.num_hearts_2third
	inventory_data["hearts_half"] = GameData.num_hearts_half
	inventory_data["hearts_1third"] = GameData.num_hearts_1third
	
	# Crafted hearts
	inventory_data["tape_hearts"] = GameData.num_tape_hearts
	inventory_data["wire_hearts"] = GameData.num_wire_hearts
	inventory_data["sewn_hearts"] = GameData.num_sewn_hearts
	inventory_data["scarred_hearts"] = GameData.num_scarred_hearts
	inventory_data["scarred_tape_hearts"] = GameData.num_scarred_tape_hearts
	inventory_data["scarred_wire_hearts"] = GameData.num_scarred_wire_hearts
	inventory_data["scarred_sewn_hearts"] = GameData.num_scarred_sewn_hearts
	inventory_data["kintsugi_hearts"] = GameData.num_kintsugi_hearts
	
	# Consumables and materials
	inventory_data["whiskey"] = GameData.num_whiskey
	inventory_data["cookies"] = GameData.num_cookies
	inventory_data["sutures"] = GameData.num_sutures
	inventory_data["tape"] = GameData.num_tape
	inventory_data["barbed_wire"] = GameData.num_barbed_wire
	inventory_data["gold"] = GameData.num_gold
	
	print("Inventory data collected - Hearts: ", GameData.num_hearts_whole, " Cookies: ", GameData.num_cookies)
	
	return inventory_data

func collect_world_state_data() -> Dictionary:
	var world_state_data = {}
	
	# Collectables state (which ones are still available to collect)
	world_state_data["available_collectables"] = []
	var collectables = get_tree().get_nodes_in_group("collectables")
	print("Found ", collectables.size(), " collectables still in scene")
	
	# For collectables still in scene, save their info so we can restore them
	for collectable in collectables:
		if debug: print("Saving collectable: ", collectable.name)
		if collectable.has_method("get_global_position"):
			if debug: print("=== DEBUG: Processing collectable: ", collectable.name, " at ", collectable.global_position)
			if debug: print("Collectable parent: ", collectable.get_parent().name)
			
			var parent_path = get_node_path_from_scene_root(collectable.get_parent())
			if debug: print("node_path to " + str(collectable.name) + " = " + str(parent_path))
			var item_data = {
				"type": "collectable",
				"global_position": {  # Save global position for reference
					"x": collectable.global_position.x,
					"y": collectable.global_position.y
				},
				"local_position": {  # Save local position relative to parent
					"x": collectable.position.x,
					"y": collectable.position.y
				},
				"collectable_type": collectable.collectable_type if "collectable_type" in collectable else 0,
				"scaling": collectable.scaling if "scaling" in collectable else 1.0,
				"parent_path": parent_path,
				"collectable_name": collectable.name,
				"child_index": collectable.get_index()  # Save the position in parent's children
			}
			if debug: print(collectable.name + " local position = " + str(item_data.local_position))
			if debug: print(collectable.name + " global position = " + str(item_data.global_position))
			if debug: print("Saved parent path: ", parent_path)
			if debug: print("Saved local position: ", collectable.position)
			if debug: print("Saved child index: ", collectable.get_index())
			world_state_data["available_collectables"].append(item_data)
	
	print("Saved ", world_state_data["available_collectables"].size(), " available collectables")
	
	# Interactables state (doors, cabinets, etc.)
	world_state_data["interactable_states"] = []
	var interactables = get_tree().get_nodes_in_group("interactive_areas")
	print("Found ", interactables.size(), " interactables in scene")
	
	for interactable in interactables:
		var item_data = {
			"position": {
				"x": interactable.global_position.x,
				"y": interactable.global_position.y
			}
		}
		
		# Save openable state
		if interactable.has_method("get") and "is_open" in interactable:
			item_data["is_open"] = interactable.is_open
		
		# Save usage count for limited-use items like biopods
		if interactable.has_method("get") and "usage_count" in interactable:
			item_data["usage_count"] = interactable.usage_count
		
		# Save interaction state
		if interactable.has_method("get") and "can_interact" in interactable:
			item_data["can_interact"] = interactable.can_interact
		
		world_state_data["interactable_states"].append(item_data)
	
	# Ant areas state
	world_state_data["ant_areas"] = []
	var ant_areas = get_tree().get_nodes_in_group("ant_areas") # You'll need to add this group
	for ant_area in ant_areas:
		if ant_area.has_method("get_remaining_ant_count"):
			var ant_data = {
				"position": {
					"x": ant_area.global_position.x,
					"y": ant_area.global_position.y
				},
				"remaining_ants": ant_area.get_remaining_ant_count(),
				"is_cleared": ant_area.is_area_cleared()
			}
			world_state_data["ant_areas"].append(ant_data)
	
	# Dialogue triggers state
	world_state_data["dialogue_triggers"] = []
	var dialogue_triggers = get_tree().get_nodes_in_group("dialogue_trigger")
	for trigger in dialogue_triggers:
		if trigger.has_method("get") and "has_triggered" in trigger:
			var trigger_data = {
				"position": {
					"x": trigger.global_position.x,
					"y": trigger.global_position.y
				},
				"has_triggered": trigger.has_triggered
			}
			world_state_data["dialogue_triggers"].append(trigger_data)
	
	return world_state_data


func collect_progress_data() -> Dictionary:
	var progress_data = {}
	
	# Collected hearts from GameManager
	if GameManager:
		progress_data["collected_hearts"] = GameManager.collected_hearts.duplicate()
		progress_data["collected_hearts_count"] = GameManager.get_collected_hearts_count()
	
	# Memory minigame progress
	progress_data["memory_minigame"] = {
		"passed": GameData.memory_mini_passed,
		"current_level": GameData.memory_mini_current_level,
		"total_levels": GameData.memory_mini_total_levels
	}
	
	# Friend movement tracking
	progress_data["friend_tracking"] = {
		"tess_current_position": {
			"x": GameData.tess_current_position.x,
			"y": GameData.tess_current_position.y
		},
		"tess_is_moving": GameData.tess_is_moving
	}
	
	return progress_data

# ===========================================
# LOAD FUNCTIONS
# ===========================================

func load_game(slot_number: int = 0) -> bool:
	if slot_number < 0 or slot_number >= MAX_SAVE_SLOTS:
		print("ERROR: Invalid load slot: ", slot_number)
		load_completed.emit(slot_number, false)
		return false
	
	var file_path = get_save_file_path(slot_number)
	if not FileAccess.file_exists(file_path):
		print("ERROR: Save file does not exist: ", file_path)
		load_completed.emit(slot_number, false)
		return false
	
	print("=== LOADING GAME FROM SLOT ", slot_number, " ===")
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("ERROR: Could not open save file for reading: ", file_path)
		load_completed.emit(slot_number, false)
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("ERROR: Could not parse save file JSON")
		load_completed.emit(slot_number, false)
		return false
	
	var save_data = json.data
	
	# Validate save data
	if not validate_save_data(save_data):
		print("ERROR: Invalid save data")
		load_completed.emit(slot_number, false)
		return false
	
	# Apply save data
	await apply_save_data(save_data)
	
	current_save_slot = slot_number
	print("Game loaded successfully from slot ", slot_number)
	load_completed.emit(slot_number, true)
	return true

func validate_save_data(save_data: Dictionary) -> bool:
	var required_keys = ["player", "game_state", "inventory", "world_state", "progress"]
	
	for key in required_keys:
		if not save_data.has(key):
			print("ERROR: Missing required save data key: ", key)
			return false
	
	# Check for metadata
	if save_data.has("metadata"):
		print("Save file metadata: ", save_data["metadata"])
	
	return true

func apply_save_data(save_data: Dictionary) -> void:
	print("=== APPLYING SAVE DATA ===")
	
	# Apply inventory data first
	apply_inventory_data(save_data["inventory"])
	
	# Apply player data
	apply_player_data(save_data["player"])
	
	# Apply game state data
	apply_game_state_data(save_data["game_state"])
	
	# Apply progress data
	apply_progress_data(save_data["progress"])
	
	# Apply world state data (must be last)
	await apply_world_state_data(save_data["world_state"])
	
	print("Save data applied successfully")

func apply_player_data(player_data: Dictionary) -> void:
	print("=== APPLYING PLAYER DATA ===")
	
	# Restore energy and courage (max values are constants)
	GameData.cur_energy = player_data.get("energy", GameData.max_energy)
	GameData.cur_courage = player_data.get("courage", GameData.max_courage)
	
	# Emit signals to update UI
	if GameManager:
		GameManager.energy_changed.emit(GameData.cur_energy, GameData.max_energy)
	GameData.courage_changed.emit(GameData.cur_courage, GameData.max_courage)
	
	# Restore player position
	var position_data = player_data.get("position", {"x": 0, "y": 0})
	var tess_nodes = get_tree().get_nodes_in_group("Tess")
	if tess_nodes.size() > 0:
		var tess = tess_nodes[0]
		tess.global_position = Vector2(position_data["x"], position_data["y"])
		tess.last_direction = player_data.get("last_direction", "right")
		print("Player position restored: ", tess.global_position)
	
	print("Player data applied - Energy: ", GameData.cur_energy, " Courage: ", GameData.cur_courage)

func apply_inventory_data(inventory_data: Dictionary) -> void:
	print("=== APPLYING INVENTORY DATA ===")
	
	# Basic collectibles
	GameData.num_hearts_whole = inventory_data.get("hearts_whole", 0)
	GameData.num_hearts_2third = inventory_data.get("hearts_2third", 0)
	GameData.num_hearts_half = inventory_data.get("hearts_half", 0)
	GameData.num_hearts_1third = inventory_data.get("hearts_1third", 0)
	
	# Crafted hearts
	GameData.num_tape_hearts = inventory_data.get("tape_hearts", 0)
	GameData.num_wire_hearts = inventory_data.get("wire_hearts", 0)
	GameData.num_sewn_hearts = inventory_data.get("sewn_hearts", 0)
	GameData.num_scarred_hearts = inventory_data.get("scarred_hearts", 0)
	GameData.num_scarred_tape_hearts = inventory_data.get("scarred_tape_hearts", 0)
	GameData.num_scarred_wire_hearts = inventory_data.get("scarred_wire_hearts", 0)
	GameData.num_scarred_sewn_hearts = inventory_data.get("scarred_sewn_hearts", 0)
	GameData.num_kintsugi_hearts = inventory_data.get("kintsugi_hearts", 0)
	
	# Consumables and materials
	GameData.num_whiskey = inventory_data.get("whiskey", 0)
	GameData.num_cookies = inventory_data.get("cookies", 0)
	GameData.num_sutures = inventory_data.get("sutures", 0)
	GameData.num_tape = inventory_data.get("tape", 0)
	GameData.num_barbed_wire = inventory_data.get("barbed_wire", 0)
	GameData.num_gold = inventory_data.get("gold", 0)
	
	# Update UI
	if GameManager:
		GameManager.update_collectables()
	
	print("Inventory data applied - Hearts: ", GameData.num_hearts_whole, " Cookies: ", GameData.num_cookies)

func apply_game_state_data(game_state_data: Dictionary) -> void:
	print("=== APPLYING GAME STATE DATA ===")
	
	# Camera limits
	if game_state_data.has("camera_limits"):
		var limits = game_state_data["camera_limits"]
		GameData.camera_limit_top = limits.get("top", 32)
		GameData.camera_limit_left = limits.get("left", 0)
		GameData.camera_limit_bottom = limits.get("bottom", 5000)
		GameData.camera_limit_right = limits.get("right", 5000)
	
	# Game manager state
	if GameManager and game_state_data.has("game_manager_state"):
		GameManager.current_state = game_state_data["game_manager_state"]
		GameManager.current_area = game_state_data.get("current_area", "bathhouse_entry")
	
	print("Game state data applied")

func apply_progress_data(progress_data: Dictionary) -> void:
	print("=== APPLYING PROGRESS DATA ===")
	
	# Collected hearts
	if GameManager and progress_data.has("collected_hearts"):
		GameManager.collected_hearts.clear()
		for heart in progress_data["collected_hearts"]:
			GameManager.collected_hearts.append(heart)
	
	# Memory minigame progress
	if progress_data.has("memory_minigame"):
		var memory_data = progress_data["memory_minigame"]
		GameData.memory_mini_passed = memory_data.get("passed", false)
		GameData.memory_mini_current_level = memory_data.get("current_level", 0)
		GameData.memory_mini_total_levels = memory_data.get("total_levels", 3)
	
	# Friend tracking
	if progress_data.has("friend_tracking"):
		var friend_data = progress_data["friend_tracking"]
		var pos_data = friend_data.get("tess_current_position", {"x": 0, "y": 0})
		GameData.tess_current_position = Vector2(pos_data["x"], pos_data["y"])
		GameData.tess_is_moving = friend_data.get("tess_is_moving", false)
	
	print("Progress data applied")

func apply_world_state_data(world_state_data: Dictionary) -> void:
	print("=== APPLYING WORLD STATE DATA ===")
	
	# Restore available collectables
	if world_state_data.has("available_collectables"):
		var available_collectables = world_state_data["available_collectables"]
		await restore_available_collectables(available_collectables)
	
	# Restore interactable states
	if world_state_data.has("interactable_states"):
		var interactable_states = world_state_data["interactable_states"]
		restore_interactable_states(interactable_states)
	
	# Restore ant area states
	if world_state_data.has("ant_areas"):
		var ant_areas = world_state_data["ant_areas"]
		restore_ant_area_states(ant_areas)
	
	# Restore dialogue trigger states
	if world_state_data.has("dialogue_triggers"):
		var dialogue_triggers = world_state_data["dialogue_triggers"]
		restore_dialogue_trigger_states(dialogue_triggers)
	
	print("World state data applied")

func remove_collected_items(collected_items: Array) -> void:
	print("=== REMOVING COLLECTED ITEMS ===")
	print("Items to remove: ", collected_items.size())
	
	# Note: This is tricky because the items that were collected are no longer in the scene
	# We need to track which items to NOT spawn or remove items that match saved positions
	
	var collectables = get_tree().get_nodes_in_group("collectables")
	print("Current collectables in scene: ", collectables.size())
	
	# For now, we remove all collectables since they were already collected
	# In a more sophisticated system, you'd track individual item IDs
	for collectable in collectables:
		print("Removing collectable at: ", collectable.global_position)
		collectable.queue_free()

func restore_available_collectables(available_collectables: Array) -> void:
	print("=== RESTORING AVAILABLE COLLECTABLES ===")
	print("Collectables to restore: ", available_collectables.size())
	
	# First, remove all current collectables from the scene
	var current_collectables = get_tree().get_nodes_in_group("collectables")
	print("Removing ", current_collectables.size(), " current collectables")
	for collectable in current_collectables:
		print("Removing collectable: ", collectable.name, " at ", collectable.global_position)
		collectable.get_parent().remove_child(collectable)
		collectable.queue_free()
	
	# Wait a frame for removal to complete
	await get_tree().process_frame
	
	# Verify removal worked
	var remaining_collectables = get_tree().get_nodes_in_group("collectables")
	print("Collectables remaining after removal: ", remaining_collectables.size())
	
	# Sort collectables by child_index to restore them in the correct order
	available_collectables.sort_custom(func(a, b): return a.get("child_index", 0) < b.get("child_index", 0))
	
	# Then spawn the saved collectables
	var collectable_scene = preload("res://scenes/interactables/collectable.tscn")
	
	for collectable_data in available_collectables:
		var new_collectable = collectable_scene.instantiate()
		
		# Set properties first (before adding to parent)
		new_collectable.collectable_type = collectable_data.get("collectable_type", 0)
		new_collectable.scaling = collectable_data.get("scaling", 1.0)
		new_collectable.name = collectable_data.get("collectable_name", "Collectable")
		
		# Use the saved parent path to find the correct parent
		var parent_node = null
		if collectable_data.has("parent_path"):
			var parent_path = collectable_data["parent_path"]
			print("Trying to find parent using saved path: ", parent_path)
			
			# Try to get the node using the saved path
			parent_node = get_tree().current_scene.get_node_or_null(parent_path)
			
			if parent_node:
				print("Found parent node using saved path: ", parent_node.name)
			else:
				print("Could not find parent using saved path: ", parent_path)
				# Try to find it by parsing the path manually
				parent_node = find_node_by_path_parts(parent_path)
		
		# Fallback to old method if saved path doesn't work
		if not parent_node:
			print("Using fallback parent search")
			parent_node = get_tree().current_scene.find_child("Interactables")
			if not parent_node:
				var content_container = get_tree().current_scene.find_child("ContentContainer")
				if content_container:
					parent_node = content_container.find_child("Interactables")
		
		# Add to the found parent or fallback to main scene
		if parent_node:
			parent_node.add_child(new_collectable)
			
			# CRITICAL: Wait for the collectable to fully initialize
			await get_tree().process_frame
			
			# Set position AFTER the collectable is fully initialized
			# Use local position if available, otherwise convert global to local
			if collectable_data.has("local_position"):
				var local_pos = collectable_data["local_position"]
				var target_position = Vector2(local_pos["x"], local_pos["y"])
				new_collectable.position = target_position
				print("Set local position: ", target_position)
				print("Actual position after setting: ", new_collectable.position)
				print("Actual global position after setting: ", new_collectable.global_position)
				
				# Double-check: if position was changed, force it again
				await get_tree().process_frame
				if new_collectable.position != target_position:
					print("WARNING: Position was changed! Forcing it again...")
					new_collectable.position = target_position
					print("Forced position to: ", new_collectable.position)
			else:
				# Fallback: convert global position to local position
				var global_pos = collectable_data["global_position"]
				var world_pos = Vector2(global_pos["x"], global_pos["y"])
				new_collectable.global_position = world_pos
				print("Set global position (fallback): ", new_collectable.global_position)
			
			# Restore child order if we have the index
			if collectable_data.has("child_index"):
				var target_index = collectable_data["child_index"]
				var current_index = new_collectable.get_index()
				if current_index != target_index and target_index < parent_node.get_child_count():
					parent_node.move_child(new_collectable, target_index)
					print("Moved collectable to index: ", target_index)
			
			print("Restored collectable '", new_collectable.name, "' to parent: ", parent_node.name, " at local pos: ", new_collectable.position)
		else:
			print("WARNING: No suitable parent found, adding to current scene")
			get_tree().current_scene.add_child(new_collectable)
			# If adding to main scene, use global position
			var global_pos = collectable_data["global_position"]
			new_collectable.global_position = Vector2(global_pos["x"], global_pos["y"])
	
	print("Collectables restoration complete - spawned ", available_collectables.size(), " collectables")

func find_node_by_path_parts(path_string: String) -> Node:
	"""Try to find a node by manually parsing the path parts"""
	var path_parts = path_string.split("/")
	var current_node = get_tree().current_scene
	
	print("Parsing path parts: ", path_parts)
	
	# Skip the first part if it's the scene root
	var start_index = 0
	if path_parts.size() > 0 and (path_parts[0] == "SceneHolder" or path_parts[0] == "Main"):
		start_index = 1
	
	for i in range(start_index, path_parts.size()):
		var part = path_parts[i]
		print("Looking for child: ", part, " in ", current_node.name)
		
		var found_child = null
		for child in current_node.get_children():
			if child.name == part:
				found_child = child
				break
		
		if found_child:
			current_node = found_child
			print("Found: ", current_node.name)
		else:
			print("Could not find child: ", part)
			return null
	
	return current_node


func restore_interactable_states(interactable_states: Array) -> void:
	print("=== RESTORING INTERACTABLE STATES ===")
	
	var interactables = get_tree().get_nodes_in_group("interactive_areas")
	
	for state_data in interactable_states:
		var target_pos = Vector2(state_data["position"]["x"], state_data["position"]["y"])
		
		# Find matching interactable by position
		for interactable in interactables:
			if interactable.global_position.distance_to(target_pos) < 10.0:  # Within 10 pixels
				# Restore openable state
				if state_data.has("is_open") and "is_open" in interactable:
					interactable.is_open = state_data["is_open"]
					# Update visual state if needed
					if interactable.has_method("_set_open_state"):
						interactable._set_open_state(interactable.is_open)
				
				# Restore usage count
				if state_data.has("usage_count") and "usage_count" in interactable:
					interactable.usage_count = state_data["usage_count"]
				
				# Restore interaction state
				if state_data.has("can_interact") and "can_interact" in interactable:
					interactable.can_interact = state_data["can_interact"]
				
				print("Restored state for interactable at: ", target_pos)
				break

func restore_ant_area_states(ant_areas_data: Array) -> void:
	print("=== RESTORING ANT AREA STATES ===")
	
	var ant_areas = get_tree().get_nodes_in_group("ant_areas")
	
	for area_data in ant_areas_data:
		var target_pos = Vector2(area_data["position"]["x"], area_data["position"]["y"])
		
		for ant_area in ant_areas:
			if ant_area.global_position.distance_to(target_pos) < 10.0:
				if area_data["is_cleared"]:
					# Remove the ant area if it was cleared
					ant_area.queue_free()
					print("Removed cleared ant area at: ", target_pos)
				else:
					# Restore ant count
					var remaining_ants = area_data.get("remaining_ants", ant_area.ant_count)
					# You'd need to implement a method to set ant count
					if ant_area.has_method("set_ant_count"):
						ant_area.set_ant_count(remaining_ants)
					print("Restored ant area with ", remaining_ants, " ants at: ", target_pos)
				break

func restore_dialogue_trigger_states(dialogue_triggers_data: Array) -> void:
	print("=== RESTORING DIALOGUE TRIGGER STATES ===")
	
	var dialogue_triggers = get_tree().get_nodes_in_group("dialogue_trigger")
	
	for trigger_data in dialogue_triggers_data:
		var target_pos = Vector2(trigger_data["position"]["x"], trigger_data["position"]["y"])
		
		for trigger in dialogue_triggers:
			if trigger.global_position.distance_to(target_pos) < 10.0:
				if trigger_data.has("has_triggered") and "has_triggered" in trigger:
					trigger.has_triggered = trigger_data["has_triggered"]
					print("Restored dialogue trigger state at: ", target_pos, " triggered: ", trigger.has_triggered)
				break

# ===========================================
# UTILITY FUNCTIONS
# ===========================================

func get_save_file_path(slot_number: int) -> String:
	return SAVE_FILE_PATH + "slot_" + str(slot_number) + SAVE_FILE_EXTENSION

func save_file_exists(slot_number: int) -> bool:
	return FileAccess.file_exists(get_save_file_path(slot_number))

func get_save_info(slot_number: int) -> Dictionary:
	if not save_file_exists(slot_number):
		return {}
	
	var file_path = get_save_file_path(slot_number)
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		return {}
	
	var save_data = json.data
	return save_data.get("metadata", {})

func delete_save(slot_number: int) -> bool:
	var file_path = get_save_file_path(slot_number)
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
		print("Deleted save file: ", file_path)
		return true
	return false

func get_all_save_slots() -> Array[Dictionary]:
	var save_slots: Array[Dictionary] = []
	
	for i in range(MAX_SAVE_SLOTS):
		var slot_info = {
			"slot_number": i,
			"exists": save_file_exists(i),
			"metadata": get_save_info(i)
		}
		save_slots.append(slot_info)
	
	return save_slots

func quick_save() -> bool:
	print("=== QUICK SAVE ===")
	return save_game(0)  # Save to slot 0

func quick_load() -> bool:
	print("=== QUICK LOAD ===")
	return await load_game(0)  # Load from slot 0

# Auto-save functionality
func auto_save() -> bool:
	print("=== AUTO SAVE ===")
	var auto_save_slot = MAX_SAVE_SLOTS - 1  # Use last slot for auto-save
	return save_game(auto_save_slot)

func get_node_path_from_scene_root(node: Node) -> String:
	"""Get the path from the current scene root to the given node"""
	var scene_root = get_tree().current_scene
	var return_path = scene_root.get_path_to(node)
	return return_path

func find_node_recursive(start_node: Node, target_name: String) -> Node:
	"""Recursively search for a node with the given name"""
	if start_node.name == target_name:
		return start_node
	
	for child in start_node.get_children():
		var result = find_node_recursive(child, target_name)
		if result:
			return result
	
	return null

func debug_print_children(node: Node, depth: int, max_depth: int) -> void:
	"""Print the tree structure for debugging"""
	if depth > max_depth:
		return
	
	var indent = "  ".repeat(depth)
	print(indent, "- ", node.name, " (", node.get_class(), ")")
	
	for child in node.get_children():
		debug_print_children(child, depth + 1, max_depth)

func setup_auto_save(interval_seconds: float = 300.0) -> void:
	var timer = Timer.new()
	timer.wait_time = interval_seconds
	timer.timeout.connect(auto_save)
	timer.autostart = true
	add_child(timer)
	print("Auto-save set up with ", interval_seconds, " second interval")
	
	
	
