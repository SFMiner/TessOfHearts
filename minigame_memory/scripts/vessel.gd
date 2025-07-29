extends Area2D
class_name Vessel

signal vessel_clicked(vessel: Vessel)

@export var vessel_id: int = 0
@export var vessel_name: String = "Vessel"
@export var is_placeholder: bool = false

var memories: Array[Node] = []
var inherited_connections: Dictionary = {}  # vessel_id -> bool

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var static_body: StaticBody2D = $StaticBody2D

func _ready():
	# Set up the label if it exists
	if label:
		label.text = vessel_name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Turn off collision layer for StaticBody2D so memories can fall through
	if static_body:
		static_body.collision_layer = 0
		static_body.collision_mask = 0
	
	# Add to groups for discovery by the minigame system
	add_to_group("vessels")
	add_to_group("elements")
	
	# Make placeholder vessels invisible
	if is_placeholder:
		if sprite:
			sprite.modulate = Color(1, 1, 1, 0.1)  # Very transparent
			z_index = -0
		if label:
			label.modulate = Color(1, 1, 1, 0.1)  # Very transparent
		remove_child(static_body)
		static_body.queue_free()
		
		
	# Connect input events
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				vessel_clicked.emit(self)

func add_memory(memory):
	if memory not in memories:
		memories.append(memory)
		_update_inherited_connections()
		_update_visual_state()

func remove_memory(memory):
	if memory in memories:
		memories.erase(memory)
		_update_inherited_connections()
		_update_visual_state()

func _update_inherited_connections():
	inherited_connections.clear()
	
	# Check all memories in this vessel
	for memory in memories:
		# For each connected memory, find which vessel it's in
		for connected_memory_id in memory.get_connected_memory_ids():
			var connected_memory = _find_memory_by_id(connected_memory_id)
			if connected_memory and connected_memory.assigned_vessel:
				var connected_vessel_id = connected_memory.assigned_vessel.vessel_id
				if connected_vessel_id != vessel_id:  # Don't connect to self
					inherited_connections[connected_vessel_id] = true

func _find_memory_by_id(memory_id: int):
	# This would need to be implemented by the main minigame script
	# For now, we'll search through all memories in this vessel
	for memory in memories:
		if memory.has_method("get_memory_data") and memory.get_memory_data().get("id") == memory_id:
			return memory
	return null

func has_inherited_connections() -> bool:
	return inherited_connections.size() > 0

func get_inherited_connection_count() -> int:
	return inherited_connections.size()

func get_memory_count() -> int:
	return memories.size()

func has_memories() -> bool:
	return memories.size() > 0

func remove_all_connections():
	# Remove all connections from memories in this vessel
	for memory in memories:
		memory.remove_all_connections()
	inherited_connections.clear()

func _update_visual_state():
	# Update visual appearance based on state
	if sprite:
		if memories.size() > 0:
			if inherited_connections.size() > 0:
				# Vessel with memories and inherited connections
				sprite.modulate = Color(1.0, 1.2, 1.2)  # Slight cyan tint
			else:
				# Vessel with memories but no connections
				sprite.modulate = Color(1.2, 1.2, 1.0)  # Slight yellow tint
		else:
			# Empty vessel
			sprite.modulate = Color.WHITE

func _on_mouse_entered():
	if sprite:
		sprite.modulate = Color(1.1, 1.1, 1.1)  # Slight highlight on hover

func _on_mouse_exited():
	if sprite:
		_update_visual_state()

func get_vessel_data() -> Dictionary:
	var memory_ids = []
	for memory in memories:
		memory_ids.append(memory.memory_id)
	
	return {
		"id": vessel_id,
		"name": vessel_name,
		"memory_count": memories.size(),
		"memory_ids": memory_ids,
		"inherited_connection_count": inherited_connections.size(),
		"inherited_connection_ids": inherited_connections.keys()
	} 
 
