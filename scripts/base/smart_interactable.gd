# ===========================================
# SMART INTERACTABLE BASE CLASS
# ===========================================

extends Area2D
class_name SmartInteractable

signal interacted()
signal collected()

@export var interaction_type: String = "default"
@export var can_interact: bool = true
@export var destroy_on_interact: bool = false
@export var interaction_text: String = ""
@export var uses_energy: bool = true  # Whether this interactable uses energy

#@onready var area_2d: Area2D = $Area2D
#@onready var visual: ColorRect = $Visual

var interaction_data: Dictionary = {}
var is_highlighted: bool = false
var original_modulate: Color


@export var interaction_range: float = 50.0  # Pixels
@export var auto_collect_on_enter: bool = false  # Some items auto-collect, others need click
@export var energy_cost: int = 1

var tess_in_interaction_area: bool = false
var interaction_area: Area2D = null

const scr_debug: bool = true
var debug: bool

func _ready() -> void:
	debug = scr_debug or GameData.sys_debug
	
	add_to_group("interactables")
	add_to_group("interactive_areas")
	
	setup_interaction_area()
	# setup_touch_detection()
	
	# CRITICAL: Set process priority to handle input before InputManager
	process_priority = 100  # Higher priority than default (0)
	
	# Connect to InputManager with DEFERRED flag to process after area events
	if InputManager:
		InputManager.touch_started.connect(_on_global_touch, CONNECT_DEFERRED)

func _input(event: InputEvent) -> void:
	"""Handle input with highest priority before other systems"""
	if not can_interact:
		return
		
	# Only handle clicks when Tess is in interaction area
	if not tess_in_interaction_area:
		return
		
	var is_valid_click = false
	if event is InputEventScreenTouch and event.pressed:
		is_valid_click = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		is_valid_click = true
	
	if is_valid_click:
		# Check if click is within interaction range.
		# event.position is in screen space; convert to world space the same way
		# InputManager.start_touch() does, so this works on touch devices (no mouse cursor).
		var world_position: Vector2 = event.position
		var camera := get_viewport().get_camera_2d()
		if camera:
			world_position = get_viewport().get_canvas_transform().affine_inverse() * event.position
		var distance_to_click: float = global_position.distance_to(world_position)
		
		if distance_to_click <= interaction_range:
			if debug: print("SmartInteractable handling input with priority: ", name)
			perform_interaction()
			# Mark input as handled to prevent other systems from processing it
			get_viewport().set_input_as_handled()
			return


func setup_interaction_area() -> void:
	if debug: print("=== SETTING UP INTERACTION AREA FOR: ", name, " ===")
	
	# Create interaction area
	interaction_area = Area2D.new()
	interaction_area.name = "InteractionArea"
	add_child(interaction_area)
	move_child(interaction_area, 0)
	
	# Create collision shape for interaction range
	var collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = interaction_range
	collision_shape.shape = shape
	interaction_area.add_child(collision_shape)
	
	# Connect signals
	interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	interaction_area.body_exited.connect(_on_interaction_area_body_exited)
	
	# Set collision layer/mask to detect Tess (layer 2)
	interaction_area.collision_layer = 0  # Don't collide with anything
	interaction_area.collision_mask = 2   # Detect Tess's layer
	
	if debug: print("Interaction area setup complete for: ", name)

#func setup_touch_detection() -> void:
	# Connect to this interactable's input events
#	input_event.connect(_on_area_input_event)

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if debug: print("=== INTERACTION AREA BODY ENTERED: ", name, " ===")
	if debug: print("Body name: ", body.name)
	
	if body.is_in_group("Tess"):
		tess_in_interaction_area = true
		if debug: print("Tess entered interaction area for: ", name)
		
		# Auto-collect if enabled
		if auto_collect_on_enter:
			perform_interaction()

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if debug: print("=== INTERACTION AREA BODY EXITED: ", name, " ===")
	
	if body.is_in_group("Tess"):
		tess_in_interaction_area = false
		if debug: print("Tess exited interaction area for: ", name)


func _on_area_input_event_old(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if debug: print("=== INTERACTABLE INPUT EVENT: ", name, " ===")
	if debug: print("Event type: ", event.get_class())
	if debug: print("Tess in interaction area: ", tess_in_interaction_area)
	
	if event is InputEventScreenTouch and event.pressed:
		if debug: print("CONSUMING TOUCH INPUT for: ", name)
		get_viewport().set_input_as_handled()
		#_on_interactable_touched(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if debug: print("CONSUMING MOUSE INPUT for: ", name)
		get_viewport().set_input_as_handled()
		#_on_interactable_touched(event.position)

func _on_global_touch_old(position: Vector2) -> void:
	if not tess_in_interaction_area:
		return
	
	# Convert to local coordinates and check if touch is on this interactable
	var local_position = to_local(position)
	var distance = local_position.length()
	
	if distance <= interaction_range:
		if debug: print("Global touch detected on interactable: ", name)
		#_on_interactable_touched(position)

#func _on_interactable_touched(position: Vector2) -> void:
#	if debug: print("=== INTERACTABLE TOUCHED: ", name, " ===")
#	if debug: print("Tess in interaction area: ", tess_in_interaction_area)
	
	# If Tess is in interaction area, interact instead of moving
#	if tess_in_interaction_area:
#		if debug: print("Tess in range - performing interaction instead of movement")
#		perform_interaction()
#		# CRITICAL: Consume the input event AFTER the interaction
#		get_viewport().set_input_as_handled()
#		return
#	else:
		# Tess is not in range, allow normal movement toward the interactable
#		if debug: print("Tess not in range - allowing movement toward interactable")
		# Don't consume input - let it propagate to movement system
#		pass

# Also update the area input event handler:
#func _on_area_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
#	if debug: print("=== INTERACTABLE INPUT EVENT: ", name, " ===")
#	if debug: print("Event type: ", event.get_class())
#	if debug: print("Tess in interaction area: ", tess_in_interaction_area)
	
	# Only handle actual presses, not mouse movement
#	if event is InputEventScreenTouch and event.pressed:
#		if debug: print("Processing touch press for: ", name)
#		_on_interactable_touched(event.position)
#	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
#		if debug: print("Processing mouse press for: ", name)
#		_on_interactable_touched(event.position)
	# Note: Input consumption now happens in _on_interactable_touched if interaction occurs

# And update the global touch handler:
func _on_global_touch(position: Vector2) -> void:
	if not tess_in_interaction_area:
		return
	
	# Convert to local coordinates and check if touch is on this interactable
	var local_position = to_local(position)
	var distance = local_position.length()
	
	if distance <= interaction_range:
		if debug: print("Global touch detected on interactable: ", name)
		#_on_interactable_touched(position)
		# Input consumption is handled in _on_interactable_touched
		
func perform_interaction() -> void:
	if debug: print("=== PERFORMING INTERACTION: ", name, " ===")
	
	# Check energy
	var current_energy = GameManager.get_energy()
	if current_energy < energy_cost:
		if debug: print("Cannot interact - insufficient energy (", current_energy, " < ", energy_cost, ")")
		return
	
	# Spend energy
	GameManager.spend_energy(energy_cost)
	if debug: print("Spent ", energy_cost, " energy. Remaining: ", GameManager.get_energy())
	
	# Call the specific interaction behavior (override in derived classes)
	handle_interaction()
	
	# Emit signals
	interacted.emit()

# Override this in derived classes for specific behavior
func handle_interaction() -> void:
	if debug: print("Base interaction for: ", name)
	# Default behavior - just remove the interactable
	collected.emit()
	queue_free()

# Helper function to check if Tess is in range without the area system
func is_tess_in_range() -> bool:
	var tess_nodes = get_tree().get_nodes_in_group("Tess")
	if tess_nodes.size() > 0:
		var tess = tess_nodes[0]
		var distance = global_position.distance_to(tess.global_position)
		return distance <= interaction_range
	return false
