# ===========================================
# SIMPLE CHARACTER.GD - CHARACTERBODY2D
# ===========================================

extends CharacterBody2D
class_name Character

@export var character_name: String = ""
@export var movement_speed: float = 200.0
@export var can_move: bool = true
var anim : AnimationPlayer = null
@onready var sprite: Sprite2D = $Sprite2D
@onready var touch_area: Area2D = $TouchArea

var target_position: Vector2
var is_moving: bool = false
var is_highlighted: bool = false
var original_modulate: Color
var last_direction: String = "left"

func _ready() -> void:
	print("=== CHARACTER SETUP ===")
	print(character_name, " _ready() called")
	print("Position: ", global_position)
	print("Can move: ", can_move)
	
	target_position = global_position
	original_modulate = modulate
#	setup_character()
	setup_touch_detection()
	
	print(character_name, " setup complete")
	print("Sprite found: ", sprite != null)
	print("TouchArea found: ", touch_area != null)

func setup_character() -> void:
	# Override in derived classes to set sprite texture
	pass

func say_dialogue(dialogue_key: String) -> void:
	var dialogue_system = get_tree().current_scene.find_child("SimpleDialogueSystem")
	if dialogue_system:
		var dialogue_point = $DialoguePoint if has_node("DialoguePoint") else self
		dialogue_system.show_dialogue(dialogue_key, dialogue_point.global_position)

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

func move_to(new_position: Vector2) -> void:
	if can_move:
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
		var direction = (target_position - global_position).normalized()
		#print("Direction: ", direction)
		velocity = direction * movement_speed
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
	if event is InputEventScreenTouch and event.pressed:
		_on_character_touched(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
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
	print("=== CHARACTER TOUCHED DEBUG ===")
	print(character_name, " was touched at position: ", position)
	print("can_move: ", can_move)
	print("is_moving: ", is_moving)
	
	# Visual feedback
	var tween = create_tween()
	tween.parallel().tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
	tween.parallel().tween_property(self, "modulate", Color.WHITE * 1.5, 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)
	tween.parallel().tween_property(self, "modulate", original_modulate, 0.1)
