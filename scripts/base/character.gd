# ===========================================
# SIMPLE CHARACTER.GD - CHARACTERBODY2D
# ===========================================

extends CharacterBody2D
class_name Character

@export var character_name: String = ""
@export var movement_speed: float = 200.0
@export var can_move: bool = true
@export var uses_energy: bool = true  # Whether this character uses energy for movement
var anim : AnimationPlayer = null
@onready var sprite: Sprite2D = $Sprite2D
@onready var touch_area: Area2D = $TouchArea

const scr_debug : bool = false
var debug : bool
var direction : Vector2
var target_position: Vector2
var is_moving: bool = false
var is_highlighted: bool = false
var original_modulate: Color
var last_direction: String = "left"
var base_movement_speed: float = 200.0

func _ready() -> void:
	debug = scr_debug or GameData.sys_debug
	if debug: 
		print("=== CHARACTER SETUP ===")
		print(character_name, " _ready() called")
		print("Position: ", global_position)
		print("Can move: ", can_move)
		print("Uses energy: ", uses_energy)
	
	target_position = global_position
	original_modulate = modulate
	base_movement_speed = movement_speed
#	setup_character()
	setup_touch_detection()
	
	print(character_name, " setup complete")
	print("Sprite found: ", sprite != null)
	print("TouchArea found: ", touch_area != null)

func setup_character() -> void:
	# Override in derived classes to set sprite texture
	pass

func get_effective_movement_speed() -> float:
	if not uses_energy:
		return movement_speed
	
	var energy = GameManager.get_energy()
	var speed_multiplier = 1.0
	
	# Apply speed reduction based on energy levels
	if energy <= 0:
		speed_multiplier = 0.0  # No movement at 0 energy
	elif energy <= 25:
		speed_multiplier = 0.33  # 33% speed at 1-25 energy
	elif energy <= 50:
		speed_multiplier = 0.66  # 66% speed at 26-50 energy
	# Above 50 energy: full speed (100%)
	
	var effective_speed = base_movement_speed * speed_multiplier
	if name != "Tess" : print("Energy: ", energy, " - Speed multiplier: ", speed_multiplier, " - Effective speed: ", effective_speed)
	return effective_speed

func can_move_with_energy() -> bool:
	if not uses_energy:
		return true
	
	var energy = GameManager.get_energy()
	var can_move = energy > 0
	
	if not can_move:
		print(character_name, " cannot move - no energy (", energy, ")")
	
	return can_move

func spend_energy_for_action(amount: int = 1) -> bool:
	if not uses_energy:
		return true
	
	var current_energy = GameManager.get_energy()
	if current_energy < amount:
		print(character_name, " cannot perform action - insufficient energy (", current_energy, " < ", amount, ")")
		return false
	
	GameManager.spend_energy(amount)
	print(character_name, " spent ", amount, " energy. Remaining: ", GameManager.get_energy())
	return true

func say_dialogue(dialogue_key: String) -> void:
	print("=== CHARACTER SAYING DIALOGUE ===")
	print("Character: ", character_name)
	print("Dialogue key: ", dialogue_key)
	
	var dialogue_point = $DialoguePoint if has_node("DialoguePoint") else self
	var speaker_position = dialogue_point #.global_position
	
	print("Speaker position: ", speaker_position)
	
	# Find dialogue system in scene
	var dialogue_system = get_tree().current_scene.find_child("DialogueSystem")
	if dialogue_system:
		dialogue_system.show_dialogue(dialogue_key, speaker_position)
	else:
		print("ERROR: DialogueSystem not found in scene")

func setup_touch_detection() -> void:
	if touch_area:
		touch_area.input_event.connect(_on_area_input_event)
		touch_area.mouse_entered.connect(_on_mouse_entered)
		touch_area.mouse_exited.connect(_on_mouse_exited)
 
func _physics_process(delta: float) -> void:
	# Debug visibility
	if not visible:
		print("WARNING: ", character_name, " is not visible!")
	# Debug position
	var viewport_size = get_viewport().get_visible_rect().size
	if global_position.x < 0 or global_position.x > viewport_size.x or global_position.y < 0 or global_position.y > viewport_size.y:
		print("WARNING: ", character_name, " is off-screen at: ", global_position)
	
	if is_moving and can_move:
		move_towards_target()

func stop_movement() -> void:
	"""Stop the character's movement immediately"""
	is_moving = false
	velocity = Vector2.ZERO
	target_position = global_position
	if debug: print(character_name, " movement stopped")

func move_to(new_position: Vector2) -> void:
	
	if not can_move:
		print(character_name, " cannot move - movement disabled")
		return
	
	if not can_move_with_energy():
		print(character_name, " cannot move - insufficient energy")
		return
	
	# Spend energy for movement
	if not spend_energy_for_action(1):
		print(character_name, " movement cancelled - no energy")
		return
	
	#print("=== MOVE DEBUG ===")
	#print(character_name, " current position: ", global_position)
	#print(character_name, " target position: ", new_position)
	target_position = new_position
	is_moving = true
	#print(character_name, " is_moving set to: ", is_moving)

# Add to Character.gd in move_towards_target():
func move_towards_target() -> void:
	'''print("=== MOVEMENT DEBUG ===")
	print(character_name, " attempting to move")
	print("Current position: ", global_position)
	print("Target position: ", target_position)
	print("Distance: ", global_position.distance_to(target_position))
	print("can_move: ", can_move)
	print("is_moving: ", is_moving)'''
	
	var distance = global_position.distance_to(target_position)
	if distance > 5.0:
		direction = (target_position - global_position).normalized()
		#print("Direction: ", direction)
		
		# Use effective movement speed based on energy
		var effective_speed = get_effective_movement_speed()
		velocity = direction * effective_speed
		
		if velocity == Vector2.ZERO:
			anim.play("idle_" + last_direction)
		elif direction.x > 0:
			anim.play("walk_right")
			last_direction = "left"				
		elif direction.x < 0:
			anim.play("walk_left")
			last_direction = "right"				
		#print("Velocity set to: ", velocity)
		
		# Check for collision issues
		var old_position = global_position
		move_and_slide()
		var new_position = global_position
		
		#print("Position after move_and_slide: ", new_position)
		#print("Position changed: ", old_position != new_position)
	'''
	if is_on_wall():
		print("Hit wall!")
	if is_on_floor():
		print("On floor!")
	if is_on_ceiling():
		print("Hit ceiling!")
	else:
		print("Reached target, stopping")
		global_position = target_position
		velocity = Vector2.ZERO
		is_moving = false
'''
func _on_area_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	print("=== CHARACTER AREA INPUT EVENT ===")
	print("Event type: ", event.get_class())
	print("Event pressed: ", event.pressed if event.has_method("pressed") else "N/A")
	
	if event is InputEventScreenTouch and event.pressed:
		print("Screen touch detected - calling _on_character_touched")
		_on_character_touched(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("Mouse button detected - calling _on_character_touched")
		_on_character_touched(event.position)

func _on_mouse_entered() -> void:
	highlight_character()

func _on_mouse_exited() -> void:
	remove_highlight()

func highlight_character() -> void:
	if not is_highlighted:
		is_highlighted = true
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color.WHITE * 1.3, 0.15)

func remove_highlight() -> void:
	if is_highlighted:
		is_highlighted = false
		var tween = create_tween()
		tween.tween_property(self, "modulate", original_modulate, 0.15)

func _on_character_touched(position: Vector2) -> void:
	if debug:
		print("=== CHARACTER TOUCHED DEBUG ===")
		print(character_name, " was touched at position: ", position)
		print("can_move: ", can_move)
		print("is_moving: ", is_moving)
	
	# Spend energy for interaction
	if uses_energy:
		if not spend_energy_for_action(1):
			print(character_name, " interaction cancelled - no energy")
			return
	
	# Visual feedback
	var tween = create_tween()
	tween.parallel().tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
	tween.parallel().tween_property(self, "modulate", Color.WHITE * 1.5, 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)
	tween.parallel().tween_property(self, "modulate", original_modulate, 0.1)
