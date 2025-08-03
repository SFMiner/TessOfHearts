# ===========================================
# ANT AREA SYSTEM - INFESTED AREAS
# ===========================================
@tool
extends Area2D
class_name AntArea

signal area_cleared(ant_area: AntArea)
signal ant_stepped_on(ant_area: AntArea, remaining_ants: int)

@export var ant_count: int = 10
@export var area_size: Vector2 = Vector2(200, 150):
	set(value):
		area_size = value
		if is_inside_tree():
			setup_collision_area()
@export var ant_speed: float = 30.0
@export var ant_size: float = 4.0
@export var ant_color: Color = Color.BROWN

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var ant_container: Node2D = $AntContainer
@onready var ant_counter: Label = $AntCounter
@onready var visual_indicator: ColorRect = $VisualIndicator

var ants: Array[Node2D] = []
var ant_targets: Array[Vector2] = []
var is_player_in_area: bool = false
var player_node: Node2D
var _loaded = false

const scr_debug : bool =  false
var debug : bool

func _ready() -> void:
	debug = scr_debug or GameData.sys_debug
	if debug:  
		print("=== ANT AREA SETUP ===")
		print("Ant count: ", ant_count)
		print("Area size: ", area_size)
	
	# Set up collision area
	setup_collision_area()
	
	# Create ants
	spawn_ants()
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Connect to input manager for ant stepping
	if InputManager:
		InputManager.touch_started.connect(_on_global_touch)
	
	add_to_group("ant_areas")
	
	if debug: print("Ant area setup complete")
	

func setup_collision_area() -> void:
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		add_child(collision_shape)
	
	var shape = RectangleShape2D.new()
	shape.size = area_size
	collision_shape.shape = shape
	
	# Update visual indicator to match collision area
	update_visual_indicator()
	
	# Set collision detection for Tess (layer 2)
	collision_layer = 0  # Don't collide with anything
	collision_mask = 2   # Only detect Tess (layer 2)

func update_visual_indicator() -> void:
	if visual_indicator:
		var half_size = area_size / 2
		visual_indicator.offset_left = -half_size.x
		visual_indicator.offset_top = -half_size.y
		visual_indicator.offset_right = half_size.x
		visual_indicator.offset_bottom = half_size.y
		if debug: print("Visual indicator resized to: ", area_size)

func spawn_ants() -> void:
	if debug: print("Spawning ", ant_count, " ants...")
	
	# Create ant container if it doesn't exist
	if not ant_container:
		ant_container = Node2D.new()
		ant_container.name = "AntContainer"
		add_child(ant_container)
	
	# Clear existing ants
	for ant in ants:
		if ant:
			ant.queue_free()
	ants.clear()
	ant_targets.clear()
	
	# Spawn new ants
	for i in range(ant_count):
		var ant = create_ant()
		ant_container.add_child(ant)
		ants.append(ant)
		
		# Set random initial position within area bounds
		var random_pos = get_random_position_in_area()
		ant.global_position = random_pos
		
		# Set random target
		var target = get_random_position_in_area()
		ant_targets.append(target)
		
		if debug: print("Ant ", i, " spawned at: ", random_pos, " with target: ", target)

func create_ant() -> Node2D:
	var ant = Node2D.new()
	ant.name = "Ant"
	
	# Create visual representation (dot)
	var ant_sprite = ColorRect.new()
	ant_sprite.size = Vector2(ant_size, ant_size)
	ant_sprite.color = ant_color
	ant_sprite.position = Vector2(-ant_size/2, -ant_size/2)  # Center the dot
	ant.add_child(ant_sprite)
	
	# Add collision area for stepping
	var ant_area = Area2D.new()
	ant_area.name = "AntArea"
	ant.add_child(ant_area)
	
	var ant_collision = CollisionShape2D.new()
	var ant_shape = CircleShape2D.new()
	ant_shape.radius = ant_size/2
	ant_collision.shape = ant_shape
	ant_area.add_child(ant_collision)
	
	# Connect ant area signals
	ant_area.input_event.connect(_on_ant_touched.bind(ant))
	
	return ant

func get_random_position_in_area() -> Vector2:
	var half_size = area_size / 2
	var random_x = randf_range(-half_size.x, half_size.x)
	var random_y = randf_range(-half_size.y, half_size.y)
	return global_position + Vector2(random_x, random_y)

func _process(delta: float) -> void:
	# Animate ants moving to their targets
	if Engine.is_editor_hint():
		if _loaded == false:
			setup_collision_area()
			_loaded = true
	else:
		for i in range(ants.size()):
			var ant = ants[i]
			if not ant or not is_instance_valid(ant):
				continue
			
			var target = ant_targets[i]
			var direction = (target - ant.global_position).normalized()
			var distance = ant.global_position.distance_to(target)
			
			# Move ant towards target
			if distance > 2.0:
				ant.global_position += direction * ant_speed * delta
			else:
				# Reached target, set new random target
				ant_targets[i] = get_random_position_in_area()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Tess":
		if debug: print("Tess entered ant area: ", name)
		is_player_in_area = true
		player_node = body
		
		# Spend courage equal to current ant count when entering
		var courage_cost = ants.size()
		GameData.spend_courage(courage_cost)
		if debug: print("Courage penalty for entering area: ", courage_cost, " (", ants.size(), " ants)")
		
		update_ant_counter()

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Tess":
		if debug: print("Tess left ant area: ", name)
		
		# Spend courage equal to current ant count when leaving
		var courage_cost = ants.size()
		GameData.spend_courage(courage_cost)
		if debug: print("Courage penalty for leaving area: ", courage_cost, " (", ants.size(), " ants)")
		
		is_player_in_area = false
		player_node = null
		if ant_counter:
			ant_counter.visible = false

func _on_global_touch(position: Vector2) -> void:
	if not is_player_in_area:
		return
	
	# Check if touch is within this ant area
	var local_pos = to_local(position)
	var half_size = area_size / 2
	
	if abs(local_pos.x) <= half_size.x and abs(local_pos.y) <= half_size.y:
		if debug: print("Touch detected in ant area: ", name)
		check_ant_stepping(position)

func check_ant_stepping(touch_position: Vector2) -> void:
	# Check if any ant was stepped on
	for i in range(ants.size() - 1, -1, -1):  # Reverse order to avoid index issues
		var ant = ants[i]
		if not ant or not is_instance_valid(ant):
			continue
		
		var distance = ant.global_position.distance_to(touch_position)
		if distance <= ant_size:
			step_on_ant(i)
			break

func _on_ant_touched(viewport: Node, event: InputEvent, shape_idx: int, ant: Node2D) -> void:
	if not is_player_in_area:
		return
	
	# Check if it's a touch/click event
	if event is InputEventScreenTouch and event.pressed:
		step_on_ant_by_reference(ant)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		step_on_ant_by_reference(ant)

func step_on_ant_by_reference(ant: Node2D) -> void:
	# Find the ant index
	for i in range(ants.size()):
		if ants[i] == ant:
			step_on_ant(i)
			break

func step_on_ant(ant_index: int) -> void:
	if ant_index < 0 or ant_index >= ants.size():
		return
	
	var ant = ants[ant_index]
	if not ant or not is_instance_valid(ant):
		return
	
	# Calculate courage cost based on current ant count (before removing this ant)
	var courage_cost = ants.size()
	
	# Check if player has enough courage
	if GameData.cur_courage < courage_cost:
		print("Cannot step on ant - not enough courage (", GameData.cur_courage, " < ", courage_cost, ")")
		return
	
	# Spend courage for stepping on ant (cost equals current ant count)
	GameData.spend_courage(courage_cost)
	if debug: print("Stepping on ant ", ant_index, " at position: ", ant.global_position, " - Courage cost: ", courage_cost, " (", ants.size(), " ants), Remaining courage: ", GameData.cur_courage)
	
	# Visual feedback for stepping
	var step_tween = create_tween()
	step_tween.parallel().tween_property(ant, "scale", Vector2.ZERO, 0.2)
	step_tween.parallel().tween_property(ant, "modulate", Color.RED, 0.2)
	step_tween.tween_callback(func():
		# Remove ant
		ant.queue_free()
		ants.remove_at(ant_index)
		ant_targets.remove_at(ant_index)
		
		if debug: print("Ant removed. Remaining ants: ", ants.size())
		
		# Emit signal for ant stepped on
		ant_stepped_on.emit(self, ants.size())
		
		# Update ant counter
		update_ant_counter()
		
		# Check if area is cleared
		if ants.size() <= 0:
			on_area_cleared()
	)

func on_area_cleared() -> void:
	if debug: print("Ant area cleared: ", name)
	
	# Visual feedback for cleared area
	var clear_tween = create_tween()
	clear_tween.parallel().tween_property(self, "modulate", Color.GREEN, 0.5)
	clear_tween.parallel().tween_property(self, "scale", Vector2(1.1, 1.1), 0.5)
	clear_tween.tween_property(self, "modulate", Color.WHITE, 0.5)
	clear_tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.5)
	clear_tween.tween_callback(func():
		# Emit signal for area cleared
		area_cleared.emit(self)
		
		# Remove from all groups
		for group in get_groups():
			remove_from_group(group)
		
		# Remove from parent
		if get_parent():
			get_parent().remove_child(self)
		
		# Destroy the ant area
		queue_free()
	)

func get_remaining_ant_count() -> int:
	return ants.size()

func is_area_cleared() -> bool:
	return ants.size() <= 0

func update_ant_counter() -> void:
	if ant_counter:
		ant_counter.text = str(ants.size()) + " ants"
		ant_counter.visible = is_player_in_area and ants.size() > 0 

func set_ant_count(new_count: int) -> void:
	# Remove excess ants
	while ants.size() > new_count:
		var ant = ants.pop_back()
		if ant:
			ant.queue_free()
		ant_targets.pop_back()
	
	# Add missing ants
	while ants.size() < new_count:
		var ant = create_ant()
		ant_container.add_child(ant)
		ants.append(ant)
		
		var random_pos = get_random_position_in_area()
		ant.global_position = random_pos
		var target = get_random_position_in_area()
		ant_targets.append(target)
	
	update_ant_counter()
