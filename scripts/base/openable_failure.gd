@tool
extends Area2D



@onready var sprite : Sprite2D = get_node_or_null("Sprite2D")
@onready var closed_area: CollisionShape2D = $ClosedAreas
@onready var open_area_1: CollisionShape2D = $OpenDoor1
@onready var open_area_2: CollisionShape2D = get_node_or_null("OpenDoor2")

@export var closed_area_shape : RectangleShape2D = RectangleShape2D.new()
@export var open_area_1_rect : RectangleShape2D = RectangleShape2D.new()
@export var open_area_1_pos : Vector2
@export var open_area_2_rect : RectangleShape2D = RectangleShape2D.new()
@export var open_area_2_pos : Vector2

@export var texture : Texture2D
@export var scaling : float = 1.0
var is_open : bool = false
var player_has : bool = false

func _ready():

	sprite.scale = Vector2(scaling, scaling)
	sprite.texture = texture
	sprite.position = Vector2.ZERO
	open_area_1.shape = open_area_1_rect
	open_area_1.position = open_area_1_pos
	closed_area.shape = closed_area_shape
	closed_area.position = Vector2.ZERO
	if open_area_2:
		open_area_2.shape = open_area_2_rect
		open_area_2.position = open_area_2_pos

	add_to_group("interactive_areas")
	# Connect signals
	input_pickable = true
	input_event.connect(_on_area_input)
	_set_open_state(false)	
	# Connect to global input system with debug
#	print("Attempting to connect to InputManager...")
	if InputManager:
#		print("InputManager found! Connecting touch_started signal...")
		InputManager.touch_started.connect(_on_global_touch)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
func _set_open_state(open: bool) -> void:
	closed_area.set_deferred("disabled", open)
#	open_area_1.set_deferred("disabled", false)
#	if open_area_2:
#		open_area_2.set_deferred("disabled", false)

func _on_area_input(viewport, event: InputEvent, shape_idx: int) -> void:
	print("=== AREA INPUT EVENT TRIGGERED ===")
	print("Event type: ", event.get_class(), " shape_idx: ", shape_idx)
	if not player_has or !(event is InputEventMouseButton and event.pressed):
		return

	var shapes := get_children().filter(func(n): return n is CollisionShape2D)
#	if shape_idx >= 0 and shape_idx < shapes.size():
#		var clicked_shape = shapes[shape_idx]

#		if clicked_shape == closed_area or clicked_shape == open_area_1 or clicked_shape == open_area_2:
	match is_open:
		true: close()
		false: open()
				
func _get_shape_from_index(shape_idx: int) -> CollisionShape2D:
	var all_shapes := get_children().filter(func(n): return n is CollisionShape2D)
	if shape_idx >= 0 and shape_idx < all_shapes.size():
		return all_shapes[shape_idx]
	return null

func _process(delta):
	if Engine.is_editor_hint():
		sprite.texture = texture
		sprite.scale = Vector2(scaling, scaling)
		closed_area.shape = closed_area_shape
		closed_area.position = Vector2.ZERO
		sprite.position = Vector2.ZERO
		open_area_1.shape = open_area_1_rect
		open_area_1.position = open_area_1_pos
		if open_area_2:
			open_area_2.shape = open_area_2_rect
			open_area_2.position = open_area_2_pos


func _on_global_touch(world_position: Vector2) -> void:
	print("=== GLOBAL TOUCH RECEIVED ===")
	print("World position: ", world_position)
	print("Player has: ", player_has)
	
	if not player_has:
		print("Player not in range, ignoring touch")
		return
	
	var local_position = to_local(world_position)
	print("Local position: ", local_position)
	
	# Check collision shape bounds
	for child in get_children():
		if child is CollisionShape2D:
			var collision_shape = child as CollisionShape2D
			if collision_shape.shape is RectangleShape2D:
				var shape = collision_shape.shape as RectangleShape2D
				var half_size = shape.size / 2
				
				if abs(local_position.x) <= half_size.x and abs(local_position.y) <= half_size.y:
					print("=== TOUCH WITHIN AREA BOUNDS ===")
					match is_open:
						true: close()
						false: open()
					return
				else:
					print("Touch outside bounds")
			break



func _on_body_entered(body: Node2D) -> void:
	print("=== BODY ENTERED ===")
	print("Body: ", body.name)
	if body.name == "Tess":
		player_has = true
		print("Tess entered range of: ", name)

func _on_body_exited(body: Node2D) -> void:
	print("=== BODY EXITED ===")
	print("Body: ", body.name)
	if body.name == "Tess":
		player_has = false
		print("Tess left range of: ", name)

func _on_mouse_entered() -> void:
	print("=== MOUSE ENTERED ===")
	print("Mouse over: ", name)

func _on_mouse_exited() -> void:
	print("=== MOUSE EXITED ===")
	print("Mouse left: ", name)

func open():
	print("Opening")
	_set_open_state(true)
	sprite.set_frame(1)

func close():
	print("Closing")
	_set_open_state(false)
	sprite.set_frame(0)
	
func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	print("=== INPUT EVENT RECEIVED ===")
	print("Event type: ", event.get_class())
	print("Player has: ", player_has)
	
	if event is InputEventScreenTouch:
		print("Screen touch - pressed: ", event.pressed)
	elif event is InputEventMouseButton:
		print("Mouse button - button: ", event.button_index, " pressed: ", event.pressed)
	
	if not player_has:
		print("Cannot interact - Tess not in range")
		return
	
	if event is InputEventScreenTouch and event.pressed:
		print("TOUCH INTERACTION!")
		match is_open:
			true: close()
			false: open()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("CLICK INTERACTION!")
		match is_open:
			true: close()
			false: open()
