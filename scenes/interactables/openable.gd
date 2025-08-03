@tool
extends Area2D

const scr_debug : bool = true 
var debug : bool

@onready var sprite : Sprite2D = get_node_or_null("Sprite2D")
@onready var interaction_area: CollisionShape2D = $InteractionArea
@onready var label: Label = $Label

@export var interaction_area_rect : RectangleShape2D = RectangleShape2D.new()

@export var texture : Texture2D
@export var scaling : float = 1.0

var original_scene_position: int = -1
var loaded_texture : bool = false

var is_open : bool = false
var player_has : bool = false

var collectables_behind: Array[Node2D] = []
var collectables_moved: bool = false

func _ready():
	debug = scr_debug or GameData.sys_debug

	sprite.scale = Vector2(scaling, scaling)
	sprite.texture = texture
	sprite.position = Vector2.ZERO
	interaction_area.shape = interaction_area_rect
	interaction_area.position = Vector2.ZERO

	if InputManager:
		InputManager.touch_started.connect(_on_global_touch)
		
	add_to_group("interactive_areas")
	# Connect signals
	input_pickable = true
	input_event.connect(_on_area_input)

	# Connect input signals properly
	if not input_event.is_connected(_on_area_input):
		input_event.connect(_on_area_input)
	
	# Connect mouse signals for debugging (but don't use them for interaction)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Connect to global input system
	if InputManager:
		if not InputManager.touch_started.is_connected(_on_global_touch):
			InputManager.touch_started.connect(_on_global_touch)
	
	if debug: print("Openable input connections established for: ", name)
	

func _on_global_touch(position: Vector2) -> void:
	if debug: print("=== OPENABLE GLOBAL TOUCH ===")
	if debug: print("World position: ", position)
	if debug: print("Player has: ", player_has)
	
	if not player_has:
		if debug: print("Player not in range, ignoring touch")
		return
	
	# Convert to local coordinates and check if touch is within bounds
	var local_position = to_local(position)
	if debug: print("Local position: ", local_position)
	
	# Check collision shape bounds
	for child in get_children():
		if child is CollisionShape2D:
			var collision_shape = child as CollisionShape2D
			if collision_shape.shape is RectangleShape2D:
				var shape = collision_shape.shape as RectangleShape2D
				var half_size = shape.size / 2
				
				if abs(local_position.x - collision_shape.position.x) <= half_size.x and abs(local_position.y - collision_shape.position.y) <= half_size.y:
					if debug: print("=== TOUCH WITHIN OPENABLE BOUNDS ===")
					toggle_open_close()
					return
				else:
					if debug: print("Touch outside bounds - half_size: ", half_size, " offset: ", Vector2(abs(local_position.x), abs(local_position.y)))
			break

func _on_mouse_entered() -> void:
	if debug: print("=== MOUSE ENTERED OPENABLE ===")
	# Just for debug - don't take any action

func _on_mouse_exited() -> void:
	if debug: print("=== MOUSE EXITED OPENABLE ===")
	# Just for debug - don't take any action

func _on_area_input(viewport, event: InputEvent, shape_idx: int) -> void:
	if debug: print("=== OPENABLE AREA INPUT EVENT ===")
	if debug: print("Event type: ", event.get_class())
	if debug: print("Player has: ", player_has)
	
	if not player_has:
		if debug: print("Cannot interact - Tess not in range")
		return
	
	# CRITICAL FIX: Only respond to actual click/touch PRESS events, not movement
	if event is InputEventScreenTouch and event.pressed:
		if debug: print("SCREEN TOUCH PRESS - opening/closing")
		toggle_open_close()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if debug: print("MOUSE BUTTON PRESS - opening/closing")
		get_viewport().set_input_as_handled() 
		toggle_open_close()
	else:
		if debug: print("Ignoring event: ", event.get_class())
		

func _process(delta):
	if Engine.is_editor_hint():
		if loaded_texture == false:
			sprite.scale = Vector2(scaling, scaling)
			sprite.texture = texture
			sprite.position = Vector2.ZERO
			interaction_area.shape = interaction_area_rect
			interaction_area.position = Vector2.ZERO
			loaded_texture = true
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Tess":
		player_has = true
		label.text = "Tess in area"
		
func _on_body_exited(body: Node2D) -> void:
	if body.name == "Tess":
		player_has = false
		label.text = ""
		
func open():
	if debug: print("Opening")
	sprite.set_frame(1)
	move_openable_to_back()
	

func close():
	if debug: print("Closing")
	sprite.set_frame(0)
	move_openable_to_front()
	'''
func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	print("Openable input event.")
	if event is InputEventScreenTouch:
		print("Screen touch - pressed: ", event.pressed)
	elif event is InputEventMouseButton:
		print("Mouse button - button: ", event.button_index, " pressed: ", event.pressed)
	
	if not player_has:
		print("Cannot interact - Tess not in range")
		return
	
	if event is InputEventScreenTouch and event.pressed:
		print("TOUCH INTERACTION!")
		toggle_open_close()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("CLICK INTERACTION!")
		toggle_open_close()
'''

func toggle_open_close():
	# Check energy before allowing interaction
	var current_energy = GameManager.get_energy()
	if current_energy <= 0:
		print(name, " cannot open/close - no energy (", current_energy, ")")
		return
	
	# Spend energy for interaction
	GameManager.spend_energy(1)
	print(name, " spent 1 energy for open/close. Remaining: ", GameManager.get_energy())
	
	match is_open:
		true: close()
		false: open()
	is_open = !is_open


func move_openable_to_back():
	var parent_node = get_parent()
	if original_scene_position == -1:
		original_scene_position = get_index()
	
	# Move this openable to position 0 (processed last for input)
	parent_node.move_child(self, 0)
	if debug: print("Moved openable to back of input processing")

func move_openable_to_front():
	if original_scene_position >= 0:
		var parent_node = get_parent()
		# Move back to original position, or end if position no longer valid
		var target_position = min(original_scene_position, parent_node.get_child_count() - 1)
		parent_node.move_child(self, target_position)
		if debug: print("Moved openable back to original position: ", target_position)
