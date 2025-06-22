@tool

extends Area2D

const scr_debug : bool = false 
var debug : bool

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
var loaded_texture : bool = false
	
@onready var sprite : Sprite2D = get_node_or_null("Sprite2D")
@onready var interaction_area: CollisionShape2D = $InteractionArea
@onready var label: Label = $Label


@export var collectable_type: CollectableType
@export var scaling : float = 1.0


var player_has : bool = false

func _ready():
	debug = scr_debug or GameData.sys_debug
	add_to_group("collectables")
	add_to_group("interactables")
	add_to_group("interactive_areas")
	label.text = str(collectable_type)
	sprite.scale = Vector2(scaling, scaling)
	sprite.texture = load(set_texture())
	if InputManager:
		InputManager.touch_started.connect(_on_global_touch)
	

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


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Tess":
		player_has = true
		label.text = "Tess in area"

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Tess":
		player_has = false
	label.text = str(collectable_type)
	
func _on_area_input(viewport, event: InputEvent, shape_idx: int) -> void:
	if debug: print("Collectable input detected!")
	if player_has:
		get_collected()

func _on_global_touch(position: Vector2) -> void:
	if debug: print("Collectable input detected!")

	if not player_has:
		return
	if debug: print("PLayer has collectable!!")	
	# Convert to world coordinates 
	var world_position = get_global_mouse_position()
	var local_position = to_local(world_position)
	
	# Check if touch is within bounds
	for child in get_children():
		if child is CollisionShape2D:
			var collision_shape = child as CollisionShape2D
			if collision_shape.shape is RectangleShape2D:
				var shape = collision_shape.shape as RectangleShape2D
				var half_size = shape.size / 2
				
				if abs(local_position.x) <= half_size.x and abs(local_position.y) <= half_size.y:
					get_collected()
					return
			break

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
	GameManager.add_collectable(int(collectable_type))
	remove_from_group("collectables")
	remove_from_group("interactables")
	remove_from_group("interactive_areas")
	get_parent().remove_child(self)
	self.queue_free()
	
	
