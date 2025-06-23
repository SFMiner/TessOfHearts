extends Node

signal courage_changed(current_courage: int, max_courage: int)

const sys_debug : bool = false

var camera_limit_top = 32
var camera_limit_left = 0
var camera_limit_bottom = 5000
var camera_limit_right = 5000	

var num_hearts_whole : int = 0
var num_hearts_2third : int = 0
var num_hearts_half : int = 0
var num_hearts_1third : int = 0

# Crafted heart types
var num_tape_hearts : int = 0
var num_wire_hearts : int = 0
var num_sewn_hearts : int = 0
var num_scarred_hearts : int = 0
var num_scarred_tape_hearts : int = 0
var num_scarred_wire_hearts : int = 0
var num_scarred_sewn_hearts : int = 0
var num_kintsugi_hearts : int = 0

var num_whiskey : int = 0
var num_cookies : int = 0
var num_sutures : int = 0
var num_tape : int = 0
var num_barbed_wire : int = 0
var num_gold : int = 0


const max_courage = 100
var cur_courage = 100
const max_energy = 100
var cur_energy = 100

# Friend movement echo settings
const friend_movement_delay: float = 1.0  # Delay in seconds before friend follows player path

# Movement tracking for friend echo (simplified - just follow Tess)
var tess_current_position: Vector2 = Vector2.ZERO
var tess_is_moving: bool = false
var tess_last_position: Vector2 = Vector2.ZERO

func add_courage(amt: int) -> void:
	cur_courage += floor(amt)
	if cur_courage > max_courage:
		cur_courage = max_courage
	print("Courage added: ", amt, " (Total: ", cur_courage, ")")
	courage_changed.emit(cur_courage, max_courage)

func spend_courage(amt: int) -> void:
	cur_courage -= floor(amt)
	if cur_courage < 0:
		cur_courage = 0
	print("Courage spent: ", amt, " (Remaining: ", cur_courage, ")")
	courage_changed.emit(cur_courage, max_courage)

# Movement tracking functions for friend echo (simplified)
func record_tess_position(position: Vector2) -> void:
	# Check if Tess is moving
	if position != tess_last_position:
		if not tess_is_moving:
			tess_is_moving = true
			print("Tess started moving")
	else:
		if tess_is_moving:
			tess_is_moving = false
			print("Tess stopped moving")
	
	tess_current_position = position
	tess_last_position = position

func get_tess_position() -> Vector2:
	return tess_current_position

func is_tess_moving() -> bool:
	return tess_is_moving

func _process(delta: float) -> void:
	# No cleanup needed for simplified position tracking
	pass
