@tool
extends SmartInteractable

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var label: Label = $Label
@onready var insteraction_area : CollisionShape2D = $InteractionArea

var object_type : String = "openable"

#CircleShape2D.new()
@export var texture: Texture2D
@export var scaling: float = 1.0
@export var collision_radius: int = 15

var loaded_texture: bool = false
var is_open: bool = false

func _ready():
	super._ready()  # CRITICAL: Call parent setup
	insteraction_area.shape.radius = collision_radius
	# Set up smart interactable properties
	interaction_range = 30.0  # Set appropriate range
	energy_cost = 1  # Energy cost for opening/closing
	
	# Set up sprite
	if sprite:
		sprite.scale = Vector2(scaling, scaling)
		sprite.texture = texture
		sprite.position = Vector2.ZERO
	
	# The interaction area will be handled by SmartInteractable
	# Remove the old collision shape setup - SmartInteractable handles this
	
	if debug:
		print("Openable setup complete with SmartInteractable system for: ", name)

func handle_interaction() -> void:
	"""Override SmartInteractable's interaction method"""
	if debug:
		print("=== OPENABLE INTERACTION ===")
		print("Current state - is_open: ", is_open)
	
	# Toggle the open/close state
	match is_open:
		true: 
			close()
		false: 
			open()
	
	is_open = !is_open
	
	if debug:
		print("New state - is_open: ", is_open)

func open():
	"""Open the openable (show frame 1)"""
	if sprite and sprite.texture:
		sprite.frame = 1
		if debug: print(name, " opened")

func close():
	"""Close the openable (show frame 0)"""
	if sprite and sprite.texture:
		sprite.frame = 0
		if debug: print(name, " closed")
