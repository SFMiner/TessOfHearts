# ===========================================
# SMART COLLECTABLE - INHERITS FROM SMART INTERACTABLE
# ===========================================

@tool
extends SmartInteractable
class_name SmartCollectable

var object_type : String = "collectable"

enum CollectableType {
	heart_whole,
	heart_1third,
	heart_half,
	heart_2third,
	whiskey,
	cookie,
	sutures,
	tape,
	barbed_wire,
	gold
}

var rng = RandomNumberGenerator.new()
var loaded_texture: bool = false

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var label: Label = $Label

@export var collectable_type: CollectableType
@export var scaling: float = 1.0


func _ready() -> void:
	# Set up interaction range based on collectable size
	interaction_range = 30.0  # Slightly larger than the sprite
	add_to_group("collectables")

	# Call parent setup
	super._ready()
	
	# Set up sprite and texture
	setup_sprite()

	debug = scr_debug or GameData.sys_debug
	add_to_group("collectables")
	if debug: print("Collectable ", name, " added to interaction groups")
	label.text = str(collectable_type)
	sprite.scale = Vector2(scaling, scaling)
	sprite.texture = load(set_texture())
	if InputManager and not InputManager.touch_started.is_connected(_on_global_touch):
		InputManager.touch_started.connect(_on_global_touch)
	var interaction_area = get_node_or_null("InteractionArea")
	move_child(interaction_area, 0)

func setup_sprite() -> void:
	if sprite:
		sprite.scale = Vector2(scaling, scaling)
		sprite.texture = load(get_texture_path())
	
	if label:
		label.text = str(collectable_type)

func get_texture_path() -> String:
	match collectable_type:
		CollectableType.heart_whole:
			return "res://assets/textures/collectables/heart.png"
		CollectableType.heart_1third:
			return get_random_third()
		CollectableType.heart_half:
			return get_random_half()
		CollectableType.heart_2third:
			return "res://assets/textures/collectables/heart_2-3.png"
		CollectableType.whiskey:
			return "res://assets/textures/collectables/whiskey.png"
		CollectableType.cookie:
			return "res://assets/textures/collectables/cookie.png"
		CollectableType.sutures:
			return "res://assets/textures/collectables/sutures.png"
		CollectableType.tape:
			return "res://assets/textures/collectables/tape.png"
		CollectableType.barbed_wire:
			return "res://assets/textures/collectables/barbed_wire.png"
		CollectableType.gold:
			return get_random_gold()
	return ""

func get_random_half() -> String:
	var type_half = rng.randi_range(0, 1)
	if type_half == 0:
		return "res://assets/textures/collectables/heart_1-2a.png"
	else:
		return "res://assets/textures/collectables/heart_1-2b.png"

func get_random_third() -> String:
	var type_third = rng.randi_range(0, 2)
	if type_third == 0:
		return "res://assets/textures/collectables/heart_1-3a.png"
	elif type_third == 1:
		return "res://assets/textures/collectables/heart_1-3b.png"
	else:
		return "res://assets/textures/collectables/heart_1-3c.png"

func get_random_gold() -> String:
	var type_gold = rng.randi_range(0, 2)
	if type_gold == 0:
		return "res://assets/textures/collectables/gold1.png"
	elif type_gold == 1:
		return "res://assets/textures/collectables/gold2.png"
	else:
		return "res://assets/textures/collectables/gold3.png"

# Override the interaction behavior for collectables
func handle_interaction() -> void:
	if debug: print("Collecting: ", collectable_type)
	
	# Add to inventory
	GameManager.add_collectable(int(collectable_type))
	
	# Visual feedback
	create_collection_effect()
	
	# Remove from scene
	remove_from_group("collectables")
	remove_from_group("interactables")
	remove_from_group("interactive_areas")
	
	queue_free()

func create_collection_effect() -> void:
	# Simple scale and fade effect
	var tween = create_tween()
	tween.parallel().tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	tween.parallel().tween_property(self, "modulate", Color.TRANSPARENT, 0.2)

# Handle editor updates
func _process(delta):
	if Engine.is_editor_hint():
		if not loaded_texture:
			setup_sprite()
			loaded_texture = true



#=========================================

	

func set_texture() -> String:
	match collectable_type:
		0 : return "res://assets/textures/collectables/heart.png"
		1 : return random_third()
		2 : return random_half()
		3 : return "res://assets/textures/collectables/heart_2-3.png"
		4 : return "res://assets/textures/collectables/whiskey.png"
		5 : return "res://assets/textures/collectables/cookie.png"
		6 : return "res://assets/textures/collectables/sutures.png"
		7 : return "res://assets/textures/collectables/tape.png"
		8 : return "res://assets/textures/collectables/barbed_wire.png"
		9 : return random_gold()
	return ""



func random_half():
	var type_third = rng.randi_range(0, 1)
	if type_third == 0 : 
		return "res://assets/textures/collectables/heart_1-2a.png"
	else: 
		return "res://assets/textures/collectables/heart_1-2b.png"

func random_third():
	var type_third = rng.randi_range(0, 2)
	if type_third == 0 : 
		return "res://assets/textures/collectables/heart_1-3a.png"
	elif type_third == 1: 
		return "res://assets/textures/collectables/heart_1-3b.png"
	else: 
		return "res://assets/textures/collectables/heart_1-3c.png"

func random_gold():
	var type_gold = rng.randi_range(0, 2)
	if type_gold == 0 : 
		return "res://assets/textures/collectables/gold1.png"
	elif type_gold == 1: 
		return "res://assets/textures/collectables/gold2.png"
	else: 
		return "res://assets/textures/collectables/gold3.png"

func process(delta):
	if Engine.is_editor_hint():
		if loaded_texture == false:
			label.text = str(collectable_type)
			sprite.scale = Vector2(scaling, scaling)
			sprite.texture = load(set_texture())
			loaded_texture = true
		


func get_collected():
	if debug: print("Collectable collected!")
	
	# Check energy before allowing collection
	var current_energy = GameManager.get_energy()
	if current_energy <= 0:
		print(name, " cannot be collected - no energy (", current_energy, ")")
		return
	
	# Spend energy for collection
	GameManager.spend_energy(1)
	print(name, " spent 1 energy for collection. Remaining: ", GameManager.get_energy())
	
	GameManager.add_collectable(int(collectable_type))
	remove_from_group("collectables")
	remove_from_group("interactables")
	remove_from_group("interactive_areas")
	get_parent().remove_child(self)
	self.queue_free()
	
func setup_interaction_area():
	if debug: print("Setting up interaction area for: ", name)
	
	# Create interaction area
	var interaction_area_node = Area2D.new()
	interaction_area_node.name = "InteractionArea"
	add_child(interaction_area_node)
	
	# Create collision shape
	var collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = interaction_range
	collision_shape.shape = shape
	interaction_area_node.add_child(collision_shape)
	
	# CRITICAL: Connect the signals
	interaction_area_node.body_entered.connect(_on_interaction_area_body_entered)
	interaction_area_node.body_exited.connect(_on_interaction_area_body_exited)
	
	# Set collision to detect Tess (layer 2)
	interaction_area_node.collision_layer = 0
	interaction_area_node.collision_mask = 2
	
	print("Interaction area setup complete for: ", name)
	
# Also make sure your interaction area detection is working:
func _on_interaction_area_body_entered(body: Node2D):
	if body.is_in_group("Tess"):
		tess_in_interaction_area = true
		print("Tess entered interaction area for: ", name)

func _on_interaction_area_body_exited(body: Node2D):
	if body.is_in_group("Tess"):
		tess_in_interaction_area = false
		print("Tess exited interaction area for: ", name)
