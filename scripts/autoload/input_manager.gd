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

func _ready() -> void:
	debug = scr_debug or GameData.sys_debug
	if debug: print("InputManager initialized - Touch controls active")

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

func handle_touch_event(event: InputEventScreenTouch) -> void:
	if event.pressed:
		start_touch(event.position)
	else:
		end_touch(event.position)

func handle_drag_event(event: InputEventScreenDrag) -> void:
	if is_touching:
		current_touch_position = event.position
		touch_moved.emit(event.position)

func handle_mouse_event(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_touch(event.position)
		else:
			end_touch(event.position)

func handle_mouse_motion(event: InputEventMouseMotion) -> void:
	current_touch_position = event.position
	touch_moved.emit(event.position)

func start_touch(position: Vector2) -> void:
	is_touching = true
	touch_start_position = position
	current_touch_position = position
	touched_objects.clear()
	
	# Convert to world coordinates before emitting
	var camera = get_viewport().get_camera_2d()
	var world_position = position  # Default to screen position
	if camera:
		world_position = camera.get_global_mouse_position()
	touch_started.emit(world_position)  # Emit world coordinates instead of screen
	
	# Find all objects at touch position using world coordinates
	find_touched_objects(world_position)

func end_touch(position: Vector2) -> void:
	is_touching = false
	current_touch_position = position
	touched_objects.clear()
	
	touch_ended.emit(position)

func find_touched_objects(position: Vector2) -> void:
	print("=== INPUT MANAGER FINDING TOUCHED OBJECTS ===")
	print("Touch position: ", position)
	
	var space_state = get_viewport().world_2d.direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = position
	query.collision_mask = 0b1111  # Check multiple layers
	
	var results = space_state.intersect_point(query)
	print("Found ", results.size(), " objects at touch position")
	
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
		
		print("  - Collider: ", collider.name, " (", collider.get_class(), ")")
		print("  - Body: ", body.name if body else "null", " (", body.get_class() if body else "null", ")")
		print("  - Body groups: ", body.get_groups() if body else "[]")
		
		if body and body not in touched_objects:
			touched_objects.append(body)
			print("  - Emitting object_touched for: ", body.name)
			object_touched.emit(body, position)
			
			# Check energy before allowing interaction
			if body.has_method("uses_energy") and body.uses_energy:
				var current_energy = GameManager.get_energy()
				if current_energy <= 0:
					print("Cannot interact with ", body.name, " - no energy (", current_energy, ")")
					continue
			
			# Special handling for different object types
			if body.has_method("_on_touched"):
				body._on_touched(position)
			elif body.has_signal("touched"):
				body.touched.emit(position)

func get_current_touch_position() -> Vector2:
	return current_touch_position

func is_currently_touching() -> bool:
	return is_touching
