extends Area2D
class_name Memory

signal memory_assigned(memory: Memory, vessel: Vessel)
signal memory_unassigned(memory: Memory)
signal connection_created(from_memory: Memory, to_memory: Memory)

@export var memory_text: String = "Memory Fragment"
@export var memory_id: int = 0

var assigned_vessel: Vessel = null
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_position: Vector2 = Vector2.ZERO
var connections: Dictionary = {}  # memory_id -> bool

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	# Enable input processing
	input_pickable = true
	
	# Set up the label if it exists
	if label:
		label.text = memory_text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Connect input events
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_input_event(_viewport, event, _shape_idx):
	print("Input event received: ", event)
	if event is InputEventMouseButton:
		print("Mouse button event: button=", event.button_index, " pressed=", event.pressed)
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				print("Starting drag...")
				_start_drag(event.global_position)
			else:
				if is_dragging:
					print("Ending drag...")
					_end_drag()
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				print("Middle-click detected - removing from vessel...")
				if assigned_vessel:
					unassign()
					global_position = original_position

func _start_drag(mouse_pos: Vector2):
	is_dragging = true
	drag_offset = global_position - mouse_pos
	original_position = global_position

	# Turn off collision layer so it doesn't physically collide
	collision_layer = 0

	# If currently assigned to a vessel, unassign it
	if assigned_vessel:
		unassign()

	# Visual feedback
	if sprite:
		sprite.modulate = Color(1.2, 1.2, 1.2)  # Brighten when dragging

func _end_drag():
	is_dragging = false

	# Restore collision layer
	collision_layer = 1

	# Reset visual feedback
	if sprite:
		_update_visual_state()
	
	# Check for memory collision first (for connections)
	var overlapping_areas = get_overlapping_areas()
	var target_memory: Memory = null
	var target_vessel: Vessel = null
	
	for area in overlapping_areas:
		if area is Memory and area != self:
			target_memory = area
			break
		elif area is Vessel:
			target_vessel = area
	
	# Handle memory-to-memory connection
	if target_memory:
		_connect_to_memory(target_memory)
		# Return to original position after connecting
		global_position = original_position
		print("Memory ", memory_id, " connected to memory ", target_memory.memory_id)
	# Handle memory-to-vessel assignment
	elif target_vessel:
		assign_to_vessel(target_vessel)
	else:
		# Return to original position if not over anything
		global_position = original_position
		print("Memory ", memory_id, " returned to original position")

func _connect_to_memory(other_memory: Memory):
	# Check if already connected - if so, disconnect
	if other_memory.memory_id in connections:
		# Remove bidirectional connection
		remove_connection(other_memory)
		other_memory.remove_connection(self)
		print("Memory ", memory_id, " disconnected from memory ", other_memory.memory_id)
	else:
		# Create bidirectional connection
		add_connection(other_memory)
		other_memory.add_connection(self)
		print("Memory ", memory_id, " connected to memory ", other_memory.memory_id)
	
	# Emit connection signal
	connection_created.emit(self, other_memory)
	
	# Update visual states
	_update_visual_state()
	other_memory._update_visual_state()

func add_connection(other_memory: Memory):
	connections[other_memory.memory_id] = true

func remove_connection(other_memory: Memory):
	if other_memory.memory_id in connections:
		connections.erase(other_memory.memory_id)

func remove_all_connections():
	connections.clear()

func has_memory_connections() -> bool:
	return connections.size() > 0

func get_connection_count() -> int:
	return connections.size()

func get_connected_memory_ids() -> Array:
	return connections.keys()

func assign_to_vessel(vessel: Vessel):
	# Unassign from previous vessel if any
	if assigned_vessel:
		assigned_vessel.remove_memory(self)
		memory_unassigned.emit(self)

	# Assign to new vessel
	assigned_vessel = vessel
	vessel.add_memory(self)

	# Stack vertically based on how many memories are in the vessel
	var stack_index = vessel.get_memory_count() - 1
	var stack_offset = Vector2(0, 40 * stack_index)
	global_position = vessel.global_position + stack_offset

	memory_assigned.emit(self, vessel)
	print("Memory ", memory_id, " assigned to vessel ", vessel.vessel_name)

func unassign():
	if assigned_vessel:
		print("Memory ", memory_id, " unassigned from vessel ", assigned_vessel.vessel_name)
		assigned_vessel.remove_memory(self)
		assigned_vessel = null
		memory_unassigned.emit(self)

func _process(_delta):
	if is_dragging:
		var viewport = get_viewport()
		if viewport:
			global_position = viewport.get_mouse_position() + drag_offset

func _on_mouse_entered():
	if sprite and not is_dragging:
		sprite.modulate = Color(1.1, 1.1, 1.1)  # Slight highlight on hover

func _on_mouse_exited():
	if sprite and not is_dragging:
		_update_visual_state()

func _update_visual_state():
	if sprite:
		if connections.size() > 0:
			# Memory with connections - make it more prominent
			sprite.modulate = Color(1.0, 1.2, 1.2)  # Slight cyan tint
		elif assigned_vessel:
			# Memory assigned to vessel
			sprite.modulate = Color(1.2, 1.2, 1.0)  # Slight yellow tint
		else:
			# Unassigned memory
			sprite.modulate = Color.WHITE

func get_memory_data() -> Dictionary:
	return {
		"id": memory_id,
		"text": memory_text,
		"assigned_vessel_id": assigned_vessel.vessel_id if assigned_vessel else -1,
		"connection_count": connections.size(),
		"connection_ids": connections.keys()
	}

func _unhandled_input(event):
	if is_dragging and event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_end_drag()
 
