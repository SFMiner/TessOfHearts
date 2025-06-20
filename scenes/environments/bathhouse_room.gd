# ===========================================
# SCENES/ENVIRONMENTS/BATHHOUSEROOM.GD
# ===========================================

extends Node2D

@export var room_name: String = "bathhouse_entry"
@export var required_hearts: int = 0
@export var is_locked: bool = false

@onready var room_background: Sprite2D
@onready var spawn_points: Node2D = $SpawnPoints
@onready var ward_barrier: Node2D = $WardBarrier

func _ready() -> void:
	setup_room()
	check_access()

func setup_room() -> void:
	# Set up room visual (placeholder background)
	if room_background:
		room_background.color = Color("#2C1810")  # Dark bathhouse color
		room_background.size = get_viewport().get_visible_rect().size

func check_access() -> void:
	var player_hearts = GameManager.get_collected_hearts_count()
	
#	if is_locked and player_hearts < required_hearts:
#		show_ward_barrier()
#	else:
#		hide_ward_barrier()
		
	hide_ward_barrier()
	unlock_room()

func show_ward_barrier() -> void:
	if ward_barrier:
		ward_barrier.visible = true
		ward_barrier.modulate = Color("#FF6666")  # Red barrier

func hide_ward_barrier() -> void:
	if ward_barrier:
		ward_barrier.visible = false
		# CRITICAL: Disable the collision!
		var barrier_collision = ward_barrier.find_child("BarrierCollision")
		if barrier_collision:
			barrier_collision.collision_layer = 0
			barrier_collision.collision_mask = 0
			# OR completely disable it:
			barrier_collision.set_deferred("disabled", true)

func unlock_room() -> void:
	if is_locked:
		is_locked = false
		GameManager.unlock_area(room_name)
		print("Room unlocked: ", room_name)
		
		
func debug_static_bodies() -> void:
	var static_bodies = get_tree().get_nodes_in_group("walls")
	for body in static_bodies:
		if body is StaticBody2D:
			print("=== WALL DEBUG ===")
			print("Wall name: ", body.name)
			print("Wall collision_layer: ", body.collision_layer)
			print("Wall collision_mask: ", body.collision_mask)
			print("Wall position: ", body.global_position)
