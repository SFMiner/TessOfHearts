extends Node2D
class_name MemoryMinigame

signal minigame_completed(success: bool)
signal minigame_started()

@export var memory_scene: PackedScene
@export var vessel_scene: PackedScene

var memories: Array[Node] = []
var vessels: Array[Node] = []
var failure_responses: Array = []
var failure_count: int = 0
var is_completed: bool = false

# Color registry for connection lines
var connection_colors: Array[Color] = [
	Color(1.0, 0.0, 0.0, 0.8),    # Red
	Color(0.0, 1.0, 0.0, 0.8),    # Green
	Color(0.0, 0.0, 1.0, 0.8),    # Blue
	Color(1.0, 1.0, 0.0, 0.8),    # Yellow
	Color(1.0, 0.0, 1.0, 0.8),    # Magenta
	Color(0.0, 1.0, 1.0, 0.8),    # Cyan
	Color(1.0, 0.5, 0.0, 0.8),    # Orange
	Color(0.5, 0.0, 1.0, 0.8),    # Purple
	Color(0.0, 0.5, 0.0, 0.8),    # Dark Green
	Color(0.5, 0.5, 0.0, 0.8),    # Olive
	Color(0.8, 0.4, 0.8, 0.8),    # Pink
	Color(0.4, 0.8, 0.4, 0.8),    # Light Green
]

# Dictionary to track which connections use which colors
# Key: "memory1_id-memory2_id" (always smaller ID first)
# Value: {"color_index": int, "line": Line2D}
var active_connections: Dictionary = {}

@onready var memory_container: Node2D = $MemoryContainer
@onready var vessel_container: Node2D = $VesselContainer
@onready var ui_container: Control = $UIContainer
@onready var result_dialog: Control = $UIContainer/ResultDialog
@onready var connection_lines: Node2D = $ConnectionLines

func _ready():
	_load_failure_responses()
	_setup_minigame()
	_connect_signals()
	_connect_ui_signals()
	# Set up global input handling for physics memory pickups
	set_process_input(true)

func _process(_delta):
	_update_connection_lines()

func _update_connection_lines():
	# Clear existing lines
	for child in connection_lines.get_children():
		child.queue_free()
	
	# Clear active connections tracking
	active_connections.clear()

	# Draw lines between connected memories
	for memory in memories:
		if memory.has_method("get_connected_memory_ids"):
			for connected_memory_id in memory.get_connected_memory_ids():
				var connected_memory = _find_memory_by_id(connected_memory_id, memories)
				if connected_memory and memory.memory_id < connected_memory.memory_id:
					_draw_connection_line(memory, connected_memory)

func _find_memory_by_id(memory_id: int, all_memories: Array):
	for memory in all_memories:
		if memory.memory_id == memory_id:
			return memory
	return null

func _draw_connection_line(from_memory, to_memory):
	# Create connection key (always smaller ID first)
	var connection_key = str(from_memory.memory_id) + "-" + str(to_memory.memory_id)
	
	# Find an available color
	var color_index = _get_available_color_index()
	if color_index == -1:
		print("Warning: No more colors available for connections!")
		return
	
	# Create the line
	var line = Line2D.new()
	var from_pos = connection_lines.to_local(from_memory.get_connection_position())
	var to_pos = connection_lines.to_local(to_memory.get_connection_position())
	line.add_point(from_pos)
	line.add_point(to_pos)
	line.width = 3
	line.default_color = connection_colors[color_index]
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	connection_lines.add_child(line)
	
	# Track this connection
	active_connections[connection_key] = {
		"color_index": color_index,
		"line": line
	}
	
	print("Created connection ", connection_key, " with color index ", color_index)

func _get_available_color_index() -> int:
	# Find the first color that's not currently in use
	var used_colors = []
	for connection_data in active_connections.values():
		used_colors.append(connection_data["color_index"])
	
	for i in range(connection_colors.size()):
		if i not in used_colors:
			return i
	
	return -1  # No colors available

func _load_failure_responses():
	var file = FileAccess.open("res://minigame_memory/data/failure_responses.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			failure_responses = json.data
		file.close()

func _setup_minigame():
	# All memories and vessels are added manually in the scene
	# They add themselves to groups in their _ready() functions
	_gather_existing_elements()
	_position_elements()

func _gather_existing_elements():
	# Gather existing memories and vessels from groups
	memories = get_tree().get_nodes_in_group("memories")
	vessels = get_tree().get_nodes_in_group("vessels")
	print("Found ", memories.size(), " memories and ", vessels.size(), " vessels")

func _position_elements():
	# Position memories in a row at the top (if they don't already have positions)
	var memory_spacing = 150
	var start_x = 100
	for i in range(memories.size()):
		if memories[i].global_position == Vector2.ZERO:
			var memory_pos = Vector2(start_x + i * memory_spacing, 100)
			memories[i].global_position = memory_pos
			memories[i].original_position = memory_pos
	
	# Position vessels in a row at the bottom (if they don't already have positions)
	var vessel_spacing = 200
	var vessel_start_x = 150
	for i in range(vessels.size()):
		if vessels[i].global_position == Vector2.ZERO:
			vessels[i].global_position = Vector2(vessel_start_x + i * vessel_spacing, 400)

func _connect_signals():
	# Connect memory signals
	for memory in memories:
		if memory.has_signal("memory_assigned"):
			memory.memory_assigned.connect(_on_memory_assigned)
		if memory.has_signal("memory_unassigned"):
			memory.memory_unassigned.connect(_on_memory_unassigned)
		if memory.has_signal("connection_created"):
			memory.connection_created.connect(_on_memory_connection_created)
	
	# Connect vessel signals
	for vessel in vessels:
		if vessel.has_signal("vessel_clicked"):
			vessel.vessel_clicked.connect(_on_vessel_clicked)

func _on_memory_assigned(_memory, _vessel):
	_check_win_condition()

func _on_memory_unassigned(_memory):
	_check_win_condition()

func _on_memory_connection_created(from_memory, to_memory):
	print("Memory connection created between ", from_memory.memory_id, " and ", to_memory.memory_id)
	_check_win_condition()

func _on_vessel_clicked(vessel: Vessel):
	print("Vessel clicked: ", vessel.vessel_name)

func _check_win_condition():
	if is_completed:
		return
	
	print("Checking win condition...")
	
	# Check if all memories are assigned
	var all_memories_assigned = true
	for memory in memories:
		if not memory.assigned_vessel:
			all_memories_assigned = false
			break
	
	print("All memories assigned: ", all_memories_assigned)
	
	if not all_memories_assigned:
		return  # Wait for all memories to be assigned
	
	# All memories are assigned - now check the final configuration
	var vessels_with_memories = 0
	var total_inherited_connections = 0
	
	for vessel in vessels:
		if vessel.has_memories():
			vessels_with_memories += 1
			print("Vessel ", vessel.vessel_name, " has ", vessel.get_memory_count(), " memories")
		# Count inherited connections but divide by 2 to avoid double-counting
		total_inherited_connections += vessel.get_inherited_connection_count()
	
	# Divide by 2 because each inherited connection is stored in both vessels
	total_inherited_connections = total_inherited_connections / 2
	
	print("Vessels with memories: ", vessels_with_memories)
	print("Total inherited connections: ", total_inherited_connections)
	
	# Check if all required connections are satisfied
	var all_connections_satisfied = true
	for memory in memories:
		if not memory.are_required_connections_satisfied():
			all_connections_satisfied = false
			print("Memory ", memory.memory_id, " missing required connections: ", memory.required_connections)
			break
	
	print("All required connections satisfied: ", all_connections_satisfied)
	
	# Determine success: exactly one vessel has memories, no inherited connections, and all required connections are satisfied
	var is_success = vessels_with_memories == 1 and total_inherited_connections == 0 and all_connections_satisfied
	
	if is_success:
		print("WIN CONDITION MET!")
		_complete_minigame(true)
	else:
		print("Win condition not met - showing failure")
		_complete_minigame(false)

func _complete_minigame(success: bool):
	is_completed = true
	
	if success:
		_show_success_message()
	else:
		failure_count += 1
		_show_failure_message()
	
	minigame_completed.emit(success)

func _show_success_message():
	_show_result_dialog("Memory Restored", "Perfect. All memories are now contained within a single vessel, forming a complete and unified truth. The fragments have become whole again.")

func _show_failure_message():
	var failure_type = _determine_failure_type()
	var response = _get_failure_response(failure_type)
	_show_result_dialog("Memory Fragmented", response)

func _determine_failure_type() -> String:
	var vessels_with_memories = 0
	var total_inherited_connections = 0
	var unassigned_memories = 0
	
	for memory in memories:
		if not memory.assigned_vessel:
			unassigned_memories += 1
	
	for vessel in vessels:
		if vessel.has_memories():
			vessels_with_memories += 1
		total_inherited_connections += vessel.get_inherited_connection_count()
	
	if total_inherited_connections > 0:
		return "vessel_connections"
	elif vessels_with_memories == 2:
		return "memories_split_two"
	elif vessels_with_memories == 3:
		return "memories_split_three"
	else:
		return "generic_failure"

func _get_failure_response(failure_type: String) -> String:
	var possible_responses = []
	
	# Find responses that match the failure type
	for response in failure_responses:
		if response.get("condition") == failure_type:
			possible_responses.append(response)
	
	# If no specific responses found, get generic ones
	if possible_responses.is_empty():
		for response in failure_responses:
			if response.get("condition") == "generic_failure":
				possible_responses.append(response)
	
	# If still no responses, return a default message
	if possible_responses.is_empty():
		return "The memories remain fragmented. Try again."
	
	# Select a random response, with escalation based on failure count
	var selected_response = _select_escalated_response(possible_responses)
	return selected_response.get("text", "The memories remain fragmented.")

func _select_escalated_response(possible_responses: Array) -> Dictionary:
	# Filter responses based on failure count for escalation
	var tiered_responses = []
	var oblique_responses = []
	var other_responses = []
	
	for response in possible_responses:
		if response.has("tier"):
			tiered_responses.append(response)
		elif response.has("style") and response.get("style") == "oblique":
			oblique_responses.append(response)
		else:
			other_responses.append(response)
	
	# Determine which tier to use based on failure count
	var target_tier = 1
	if failure_count >= 5:
		target_tier = 3
	elif failure_count >= 3:
		target_tier = 2
	
	# Try to get a response from the target tier
	var tier_responses = []
	for response in tiered_responses:
		if response.get("tier") == target_tier:
			tier_responses.append(response)
	
	# If we have tiered responses, use them
	if not tier_responses.is_empty():
		return tier_responses[randi() % tier_responses.size()]
	
	# Otherwise, mix oblique and other responses
	var all_responses = oblique_responses + other_responses
	if not all_responses.is_empty():
		return all_responses[randi() % all_responses.size()]
	
	# Fallback
	return possible_responses[randi() % possible_responses.size()]

func _show_result_dialog(title: String, message: String):
	if result_dialog:
		result_dialog.get_node("TitleLabel").text = title
		result_dialog.get_node("MessageLabel").text = message
		result_dialog.visible = true

func reset_minigame():
	# Reload the entire scene to restore exact starting conditions
	get_tree().reload_current_scene()

func get_minigame_state() -> Dictionary:
	var memory_states = []
	for memory in memories:
		memory_states.append(memory.get_memory_data())
	
	var vessel_states = []
	for vessel in vessels:
		vessel_states.append(vessel.get_vessel_data())
	
	return {
		"memories": memory_states,
		"vessels": vessel_states,
		"completed": is_completed,
		"failure_count": failure_count
	}

func _connect_ui_signals():
	if result_dialog:
		var continue_button = result_dialog.get_node("ContinueButton")
		var reset_button = result_dialog.get_node("ResetButton")
		var exit_button = result_dialog.get_node("ExitButton")
		
		if continue_button:
			continue_button.pressed.connect(_on_continue_pressed)
		if reset_button:
			reset_button.pressed.connect(_on_reset_pressed)
		if exit_button:
			exit_button.pressed.connect(_on_exit_pressed)

func _on_continue_pressed():
	result_dialog.visible = false
	if is_completed:
		# Minigame completed successfully
		GameManager.complete_memory_minigame_level()
		# Could transition to next level or return to main game
		print("Memory minigame level completed!")

func _on_reset_pressed():
	reset_minigame()

func _on_exit_pressed():
	# Return to main game or close minigame
	result_dialog.visible = false
	# Could emit a signal to return to main game
	print("Exiting memory minigame")

func _input(event):
	# Global input handler for physics memory pickups
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_physics_memory_pickup(event.position)

func _handle_physics_memory_pickup(mouse_pos: Vector2):
	# Find all physics memories (memories in physics mode)
	var physics_memories = []
	for memory in memories:
		if memory.physics_body.visible and not memory.drag_area.monitoring:
			physics_memories.append(memory)
	
	if physics_memories.is_empty():
		return
	
	# Find the closest memory to the mouse position
	var closest_memory = null
	var closest_distance = 50.0  # Maximum pickup distance
	
	for memory in physics_memories:
		var distance = mouse_pos.distance_to(memory.physics_body.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_memory = memory
	
	# Pick up the closest memory if found
	if closest_memory:
		closest_memory.pickup_from_physics() 
 
