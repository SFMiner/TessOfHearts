# ===========================================
# SCENES/ENVIRONMENTS/BATHHOUSEROOM.GD
# ===========================================

extends Node2D

@export var room_name: String = "bathhouse_entry"
@export var required_hearts: int = 0
@export var is_locked: bool = false

@onready var room_background: Sprite2D = $Background
@onready var spawn_points: Node2D = $SpawnPoints
@onready var ward_barrier: Node2D = $WardBarrier

# Initialize the bathhouse room: check access, set up barriers, and connect signals
func _ready() -> void:
	setup_room()
	check_access()

# Configure room-specific visuals, barriers, and interactive elements
func setup_room() -> void:
	# Set up room visual (placeholder background)
	if room_background:
		room_background.self_modulate = Color("#2C1810")  # Dark bathhouse tint

# Verify if the player has unlocked this room; show/hide barriers accordingly
func check_access() -> void:
	var player_hearts = GameManager.get_collected_hearts_count()
	
#	if is_locked and player_hearts < required_hearts:
#		show_ward_barrier()
#	else:
#		hide_ward_barrier()
		
	hide_ward_barrier()
	unlock_room()

# Display a visual barrier preventing entry to the locked room
func show_ward_barrier() -> void:
	if ward_barrier:
		ward_barrier.visible = true
		ward_barrier.modulate = Color("#FF6666")  # Red barrier

# Remove the visual barrier when the room is unlocked
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

# Mark the room as unlocked, hide barriers, and update visuals
func unlock_room() -> void:
	if is_locked:
		is_locked = false
		GameManager.unlock_area(room_name)
	print("Room unlocked: ", room_name)

# Print info about StaticBody2D nodes for collision debugging
func debug_static_bodies() -> void:
	var static_bodies = get_tree().get_nodes_in_group("walls")
	for body in static_bodies:
		if body is StaticBody2D:
			print("=== WALL DEBUG ===")
			print("Wall name: ", body.name)
			print("Wall collision_layer: ", body.collision_layer)
			print("Wall collision_mask: ", body.collision_mask)
			print("Wall position: ", body.global_position)
