extends Node2D

signal memory_assigned(memory, vessel)
signal memory_unassigned(memory)
signal connection_created(from_memory, to_memory)

@export var memory_text: String = "Memory Fragment"
@export var memory_id: int = 0
@export var required_connections: Array[int] = []  # Array of memory IDs this memory should be connected to

@onready var drag_area: Area2D = $DragArea
@onready var drag_sprite: Sprite2D = $DragArea/Sprite2D
@onready var drag_label: Label = $DragArea/Label
@onready var drag_collision: CollisionShape2D = $DragArea/CollisionShape2D

@onready var physics_body: RigidBody2D = $PhysicsBody
@onready var physics_sprite: Sprite2D = $PhysicsBody/Sprite2D
@onready var physics_label: Label = $PhysicsBody/Label
@onready var physics_collision: CollisionShape2D = $PhysicsBody/CollisionShape2D

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_position: Vector2 = Vector2.ZERO
var assigned_vessel = null
var connections: Dictionary = {}  # memory_id -> bool
var collision_check_timer: float = 0.0
var collision_check_duration: float = 2.0  # Check for 2 seconds after falling

func _ready():
	print("Hybrid memory ", memory_id, " _ready() called at position ", global_position)
	drag_label.text = memory_text
	physics_label.text = memory_text
	_update_collision_shapes()
	
	# Connect the Area2D input event signal
	drag_area.input_event.connect(_input_event)
	
	# Connect physics body collision signal
	physics_body.body_entered.connect(_on_physics_body_entered)
	
	# Add to groups for discovery by the minigame system
	add_to_group("memories")
	add_to_group("elements")
	
	set_drag_mode()
	print("Hybrid memory ", memory_id, " _ready() completed at position ", global_position)

func _update_collision_shapes():
	# Update physics collision shape to match texture size exactly
	if physics_sprite.texture:
		var texture_size = physics_sprite.texture.get_size()
		if physics_collision.shape is RectangleShape2D:
			physics_collision.shape.size = texture_size
		else:
			# Create new rectangle shape if needed
			var new_shape = RectangleShape2D.new()
			new_shape.size = texture_size
			physics_collision.shape = new_shape
	
	# Keep drag area collision shape larger for easier interaction
	if drag_sprite.texture:
		var texture_size = drag_sprite.texture.get_size()
		var larger_size = texture_size + Vector2(20, 20)  # 10 pixels padding on each side
		if drag_collision.shape is RectangleShape2D:
			drag_collision.shape.size = larger_size
		else:
			# Create new rectangle shape if needed
			var new_shape = RectangleShape2D.new()
			new_shape.size = larger_size
			drag_collision.shape = new_shape

func set_drag_mode():
	drag_area.visible = true
	drag_area.set_deferred("monitoring", true)
	drag_area.set_deferred("input_pickable", true)
	# Re-enable collision detection
	drag_area.collision_layer = 1  # Layer for memory detection
	drag_area.collision_mask = 1   # Detect other memories and vessels
	
	physics_body.visible = false
	physics_body.freeze = true  # Freeze the body when not in physics mode

func set_physics_mode():
	drag_area.visible = false
	drag_area.set_deferred("monitoring", false)
	drag_area.set_deferred("input_pickable", false)
	# Also disable collision detection to prevent interference
	drag_area.collision_layer = 0
	drag_area.collision_mask = 0
	
	physics_body.visible = true
	physics_body.sleeping = false
	physics_body.freeze = false  # Unfreeze the body for physics
	
	# Set collision layers so memories can fall through vessel detection areas
	# but still collide with other memories and vessel walls
	physics_body.collision_layer = 2  # Layer for memory physics
	physics_body.collision_mask = 2   # Only collide with other memories

func _input_event(viewport, event, shape_idx):
	if not drag_area.visible:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_offset = global_position - get_global_mouse_position()
				original_position = global_position
			else:
				if is_dragging:
					is_dragging = false
					_end_drag()

func _end_drag():
	print("Ending drag for memory ", memory_id, " at position ", global_position)
	
	# Check for memory collision first (for connections)
	var overlapping_areas = drag_area.get_overlapping_areas()
	var target_memory = null
	var target_vessel = null
	
	print("Found ", overlapping_areas.size(), " overlapping areas")
	
	# First, check if we're over a vessel
	for area in overlapping_areas:
		print("Checking area: ", area.name, " parent: ", area.get_parent().name if area.get_parent() else "none")
		print("  Area has get_connected_memory_ids: ", area.has_method("get_connected_memory_ids"))
		print("  Parent has get_connected_memory_ids: ", area.get_parent().has_method("get_connected_memory_ids") if area.get_parent() else "false")
		print("  Area has add_memory: ", area.has_method("add_memory"))
		print("  Area is in vessel group: ", area.is_in_group("vessels"))
		
		# Check if this is a vessel first (priority for vessel assignment)
		if area.has_method("add_memory"):
			target_vessel = area
			print("Found target vessel: ", target_vessel.vessel_name)
			break
	
	# If no vessel found, then check for memory connections
	if not target_vessel:
		for area in overlapping_areas:
			# Check if this is a memory (look for the memory root node)
			if area.get_parent() and area.get_parent().has_method("get_connected_memory_ids") and area.get_parent() != self:
				target_memory = area.get_parent()
				print("Found target memory: ", target_memory.memory_id)
				break
	
	# Handle memory-to-vessel assignment (priority)
	if target_vessel:
		assign_to_vessel(target_vessel)
		print("Memory ", memory_id, " assigned to vessel ", target_vessel.vessel_name)
	# Handle memory-to-memory connection
	elif target_memory:
		_connect_to_memory(target_memory)
		# Return to original position after connecting
		global_position = original_position
		print("Memory ", memory_id, " connected to memory ", target_memory.memory_id)
	else:
		# Fallback: check if we're over a vessel using the existing method
		if _is_over_vessel():
			print("Fallback vessel detection succeeded - finding vessel...")
			# Find the vessel we're over
			var vessels = get_tree().get_nodes_in_group("vessels")
			for vessel in vessels:
				var distance = global_position.distance_to(vessel.global_position)
				if distance < 100:  # Within 100 pixels of vessel center
					assign_to_vessel(vessel)
					print("Memory ", memory_id, " assigned to vessel ", vessel.vessel_name, " via fallback")
					return
		
		# Return to original position if not over anything
		global_position = original_position
		print("Memory ", memory_id, " returned to original position")

func _connect_to_memory(other_memory):
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

func _process(_delta):
	if is_dragging:
		global_position = get_global_mouse_position() + drag_offset
	
	# Update collision check timer for physics memories
	if physics_body.visible and not drag_area.monitoring:
		collision_check_timer += _delta
		# After the check duration, we can optimize other things but keep collision detection
		# The collision layers should remain active to prevent falling through vessels

func _is_over_vessel() -> bool:
	# Check for overlap with any vessel (StaticBody2D or Area2D with a certain group)
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = global_position
	query.collision_mask = 1  # Adjust based on your collision layers
	query.collide_with_bodies = true
	query.collide_with_areas = true
	
	var result = space_state.intersect_point(query)
	for collision in result:
		if collision.collider and (collision.collider is StaticBody2D or (collision.collider is Area2D and collision.collider.is_in_group("vessel"))):
			return true
	return false

func pickup_from_physics():
	# Call this to pick up the memory from the vessel (e.g., on click)
	set_drag_mode()
	# Move both the memory and its Area2D to the current mouse position
	var mouse_pos = get_global_mouse_position()
	global_position = mouse_pos
	drag_area.global_position = mouse_pos

# Call this when the texture changes at runtime
func set_texture(new_texture: Texture2D):
	drag_sprite.texture = new_texture
	physics_sprite.texture = new_texture
	_update_collision_shapes()

# Methods required by memory minigame system
func get_connected_memory_ids() -> Array:
	return connections.keys()

func add_connection(other_memory):
	connections[other_memory.memory_id] = true

func remove_connection(other_memory):
	if other_memory.memory_id in connections:
		connections.erase(other_memory.memory_id)

func remove_all_connections():
	connections.clear()

func assign_to_vessel(vessel):
	# Unassign from previous vessel if any
	if assigned_vessel:
		assigned_vessel.remove_memory(self)
		memory_unassigned.emit(self)

	# Assign to new vessel
	assigned_vessel = vessel
	vessel.add_memory(self)

	# Switch to physics mode and let it fall naturally
	set_physics_mode()
	physics_body.global_position = global_position
	
	# Let physics handle the stacking - don't manually position
	memory_assigned.emit(self, vessel)
	print("Memory ", memory_id, " assigned to vessel ", vessel.vessel_name)

func unassign():
	if assigned_vessel:
		print("Memory ", memory_id, " unassigned from vessel ", assigned_vessel.vessel_name)
		assigned_vessel.remove_memory(self)
		assigned_vessel = null
		memory_unassigned.emit(self)

func get_memory_data() -> Dictionary:
	return {
		"id": memory_id,
		"text": memory_text,
		"assigned_vessel_id": assigned_vessel.vessel_id if assigned_vessel else -1,
		"connection_count": connections.size(),
		"connection_ids": connections.keys(),
		"required_connections": required_connections
	}

# Check if all required connections are satisfied
func are_required_connections_satisfied() -> bool:
	if required_connections.is_empty():
		return true  # No required connections means success
	
	for required_id in required_connections:
		if required_id not in connections:
			return false
	return true

# Get the correct position for connection lines
func get_connection_position() -> Vector2:
	if physics_body.visible:
		return physics_body.global_position
	else:
		return global_position

func _on_physics_body_entered(body):
	# Reset the collision check timer when we hit something
	# This allows for future optimizations while keeping collision detection active
	collision_check_timer = 0.0
 
