# ===========================================
# SCRIPTS/AUTOLOAD/INPUTMANAGER.GD (ENHANCED)
# ===========================================

extends Node

const scr_debug : bool = false 
var debug : bool

signal object_touched(object: Node2D, position: Vector2)
signal touch_started(position: Vector2)
signal touch_ended(position: Vector2)
signal touch_moved(position: Vector2)

var is_touching: bool = false
var touch_start_position: Vector2
var current_touch_position: Vector2
var touched_objects: Array[Node2D] = []

# Initialize debug flag from GameData settings
func _ready() -> void:
	debug = scr_debug or GameData.sys_debug
	if debug: print("InputManager initialized - Touch controls active")

# Route incoming input to touch, drag, mouse, or motion handlers based on event type
func _input(event: InputEvent) -> void:
	# Handle touch input (primary)
	if event is InputEventScreenTouch:
		handle_touch_event(event)
	elif event is InputEventScreenDrag:
		handle_drag_event(event)
	# Handle mouse input as fallback
	elif event is InputEventMouseButton:
		handle_mouse_event(event)
	elif event is InputEventMouseMotion and is_touching:
		handle_mouse_motion(event)

# Convert screen touch press/release into start_touch/end_touch calls
func handle_touch_event(event: InputEventScreenTouch) -> void:
	if event.pressed:
		start_touch(event.position)
	else:
		end_touch(event.position)

# Update current touch position and emit touch_moved on drag
func handle_drag_event(event: InputEventScreenDrag) -> void:
	if is_touching:
		current_touch_position = event.position
		touch_moved.emit(event.position)

# Treat left mouse button as touch input (desktop fallback)
func handle_mouse_event(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_touch(event.position)
		else:
			end_touch(event.position)

# Track mouse position during active touches for movement
func handle_mouse_motion(event: InputEventMouseMotion) -> void:
	current_touch_position = event.position
	touch_moved.emit(event.position)

# Begin a touch: convert screen coords to world, scan for intersected objects, emit touch_started
func start_touch(position: Vector2) -> void:
	is_touching = true
	touch_start_position = position
	current_touch_position = position
	touched_objects.clear()
	
	# Convert to world coordinates before emitting
	var camera = get_viewport().get_camera_2d()
	var world_position = position  # Default to screen position
	if camera:
		world_position = camera.get_canvas_transform().affine_inverse() * position
	
	# Find all objects at touch position using world coordinates
	find_touched_objects(world_position)
	
	# ONLY emit touch_started here, not in find_touched_objects
	if debug: print("INPUT MANAGER: Emitting touch_started signal")
	touch_started.emit(world_position)

# End the active touch, clear tracked objects, emit touch_ended
func end_touch(position: Vector2) -> void:
	is_touching = false
	current_touch_position = position
	touched_objects.clear()
	
	touch_ended.emit(position)

# Run PhysicsPointQueryParameters2D at position; emit object_touched for each hit and call _on_touched
func find_touched_objects(position: Vector2) -> void:
	if debug: 
		print("=== INPUT MANAGER FINDING TOUCHED OBJECTS ===")
		print("Touch position: ", position)
	
	var space_state = get_viewport().world_2d.direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = position
	query.collision_mask = 0b1111  # Check multiple layers
	
	var results = space_state.intersect_point(query)
	if debug: print("Found ", results.size(), " objects at touch position")
	
	for result in results:
		var collider = result.collider
		var body = collider
		
		# If the collider is a CharacterBody2D, use it directly
		# If it's an Area2D, use its parent
		if collider is CharacterBody2D:
			body = collider
		elif collider is Area2D:
			body = collider.get_parent()
		else:
			body = collider.get_parent()
		
		if debug: 
			print("  - Collider: ", collider.name, " (", collider.get_class(), ")")
			print("  - Body: ", body.name if body else "null", " (", body.get_class() if body else "null", ")")
			print("  - Body groups: ", body.get_groups() if body else "[]")
		
		if body and body not in touched_objects:
			touched_objects.append(body)
			if debug: print("  - Emitting object_touched for: ", body.name)
			object_touched.emit(body, position)
			
			# Special handling for different object types
			if body.has_method("_on_touched"):
				body._on_touched(position)
			elif body.has_signal("touched"):
				body.touched.emit(position)
	# CRITICAL DEBUG: Check if touch_started signal is being emitted
	#if debug: print("INPUT MANAGER: About to emit touch_started signal")
	#touch_started.emit(position)
	#if debug: print("INPUT MANAGER: touch_started signal emitted")

# Return the latest touch or mouse position during an active drag
func get_current_touch_position() -> Vector2:
	return current_touch_position

# Return whether a touch or mouse drag is currently in progress
func is_currently_touching() -> bool:
	return is_touching
