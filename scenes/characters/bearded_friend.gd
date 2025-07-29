# ===========================================
# BEARDEDFRIEND.GD - SIMPLE VERSION
# ===========================================

extends Character

const scr_debug : bool = true
var debug : bool

# Friend personality variables
var wander_timer: float = 0.0
var pause_timer: float = 0.0
var is_wandering: bool = false
var is_paused: bool = false
var wander_target: Vector2 = Vector2.ZERO
var wander_duration: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO
var pause_duration: float = 0.0

# Drift system for path variations
var drift_timer: float = 0.0
var is_drifting: bool = false
var drift_direction: Vector2 = Vector2.ZERO
var drift_duration: float = 0.0

# Interaction area system
var tess_in_interaction_area: bool = false
var interaction_area: Area2D = null

func _ready() -> void:
	debug = scr_debug or GameData.sys_debug
	character_name = "Bearded Friend"
	uses_energy = false  # Dialogue interactions don't use energy
	can_move = true  # Friend can move to follow Tess
	anim = get_node_or_null("AnimationPlayer")
	add_to_group("Friend")
	setup_interaction_area()
	setup_touch_responder()
	super._ready()
	
	# Debug check
	print("=== FRIEND READY DEBUG ===")
	print("Interaction area exists: ", interaction_area != null)
	if interaction_area:
		print("Interaction area children: ", interaction_area.get_child_count())
		print("Interaction area collision mask: ", interaction_area.collision_mask)
		print("Interaction area collision layer: ", interaction_area.collision_layer)
	print("=== FRIEND READY COMPLETE ===")
	
func setup_character() -> void:
	if sprite:
		create_placeholder_texture(Color("#4C8CB8"))  # Blue

func create_placeholder_texture(color: Color) -> void:
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(color)
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite.texture = texture

func _physics_process(delta: float) -> void:
	# Update timers
	wander_timer -= delta
	pause_timer -= delta
	drift_timer -= delta
	
	# Handle friend's personality and movement
	handle_friend_personality()
	
	# Handle movement without calling parent (to avoid energy system)
	if is_moving and can_move:
		move_towards_target_friend()

func handle_friend_personality() -> void:
	var tess_pos = GameData.get_tess_position()
	var tess_is_moving = GameData.is_tess_moving()
	
	# Check if we're too close to Tess
	if is_colliding_with_tess():
		is_moving = false
		velocity = Vector2.ZERO
		#if debug: print("Friend stopped - touching Tess")
		return
	
	# Random wandering behavior (very rare)
	if wander_timer <= 0.0 and not is_wandering and randf() < 0.0001:  # 0.01% chance per frame
		start_wandering()
	
	# Handle wandering
	if is_wandering:
		handle_wandering()
		return
	
	# Random drift behavior (creates path variations)
	if drift_timer <= 0.0 and not is_drifting and randf() < 0.001:  # 0.1% chance per frame
		start_drift()
	
	# Random pause behavior (very rare)
	if pause_timer <= 0.0 and not is_paused and randf() < 0.00005:  # 0.005% chance per frame
		start_pause()
	
	# Handle pause
	if is_paused:
		handle_pause()
		return
	
	# Normal following behavior - always follow Tess when not doing personality behaviors
	follow_tess()

func follow_tess() -> void:
	# Get Tess's current position
	var tess_pos = GameData.get_tess_position()
	
	# Check if we're too close to Tess (collision check)
	if is_colliding_with_tess():
		# Stop moving if touching Tess
		is_moving = false
		velocity = Vector2.ZERO
		if debug: print("Friend stopped - touching Tess")
		return
	
	# Move towards Tess's position
	var distance_to_tess = global_position.distance_to(tess_pos)
	if distance_to_tess > 50.0:  # Only move if more than 50 pixels away (increased minimum distance)
		target_position = tess_pos
		is_moving = true
		if debug: print("Friend moving to Tess at: ", tess_pos, " (distance: ", distance_to_tess, ")")
	else:
		# Within reasonable distance, still move but with natural drift
		target_position = tess_pos
		is_moving = true

func is_colliding_with_tess() -> bool:
	var tess_nodes = get_tree().get_nodes_in_group("Tess")
	if tess_nodes.size() > 0:
		var tess_node = tess_nodes[0]
		var distance = global_position.distance_to(tess_node.global_position)
		return distance < 50.0  # Stop when within 20 pixels of Tess (closer collision)
	return false

func move_towards_target_friend() -> void:
	# Friend-specific movement without energy costs
	var distance = global_position.distance_to(target_position)
	if distance > 5.0:
		var direction = (target_position - global_position).normalized()
		var speed_multiplier = 1.0
		
		# Reduce speed as we get closer to Tess (smoother following)
		var tess_pos = GameData.get_tess_position()
		var distance_to_tess = global_position.distance_to(tess_pos)
		if distance_to_tess < 100.0:  # Start slowing down within 100 pixels
			var speed_factor = clamp(distance_to_tess / 100.0, 0.2, 1.0)  # 20% to 100% speed
			speed_multiplier *= speed_factor
			if debug: print("Friend speed factor: ", speed_factor, " (distance: ", distance_to_tess, ")")
		
		# Apply drift if currently drifting
		if is_drifting:
			var original_direction = direction
			# Add drift direction to create sustained path variation
			direction = (direction + drift_direction * 0.5).normalized()  # 50% drift influence
			
			# Check if drift aligns with movement direction
			var alignment = original_direction.dot(direction)
			if alignment > 0.8:  # If directions are well-aligned
				speed_multiplier *= 1.3  # Speed up (might go past Tess)
				if debug: print("Friend speeding up! Alignment: ", alignment)
			elif alignment < 0.5:  # If directions are poorly aligned
				speed_multiplier *= 0.6  # Slow down (might fall behind)
				if debug: print("Friend slowing down! Alignment: ", alignment)
		
		# Use base movement speed with potential speed multiplier
		velocity = direction * movement_speed * speed_multiplier
		
		# Handle animations if available
		if anim:
			if velocity == Vector2.ZERO:
				anim.play("idle_" + last_direction)
			elif direction.x > 0:
				anim.play("walk_right")
				last_direction = "left"				
			elif direction.x < 0:
				anim.play("walk_left")
				last_direction = "right"				
		
		# Move the character
		move_and_slide()
	else:
		# Reached target
		global_position = target_position
		velocity = Vector2.ZERO
		is_moving = false

func _on_character_touched(position: Vector2) -> void:
	print("=== FRIEND CHARACTER TOUCHED DEBUG ===")
	print("Position: ", position)
	print("Tess in interaction area: ", tess_in_interaction_area)
	print("Interaction area exists: ", interaction_area != null)
	
	# Check if Tess is in interaction area
	if tess_in_interaction_area:
		print("BeardedFriend: 'Hey there, friend.'")
		say_dialogue("friend_hey_there")
		if debug: print("Friend interaction - Tess in interaction area")
		# DO NOT call super - prevent any movement
		return
	else:
		# Tess is not in interaction area, allow normal movement
		if debug: print("Friend touched but Tess not in interaction area - allowing movement")
		# Call super to allow normal movement behavior
		super._on_character_touched(position)

func start_wandering() -> void:
	is_wandering = true
	wander_direction = Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5)).normalized()
	wander_duration = randf_range(3.0, 4.0)  # 3-4 seconds exploration
	wander_timer = randf_range(3.0, 4.0)  # 3-4 seconds cooldown between wanders
	if debug: print("Friend started exploring for ", wander_duration, " seconds")

func handle_wandering() -> void:
	wander_duration -= get_process_delta_time()
	if wander_duration <= 0.0:
		is_wandering = false
		velocity = Vector2.ZERO
		if debug: print("Friend finished wandering")
		return
	
	# During wandering, move in a random direction away from Tess
	var tess_pos = GameData.get_tess_position()
	var direction_away_from_tess = (global_position - tess_pos).normalized()
	
	# Add the wander direction to create variation
	var final_direction = (direction_away_from_tess.normalized()  + wander_direction)
	
	# Move in the combined direction
	velocity = final_direction * 100.0
	move_and_slide()

func start_pause() -> void:
	is_paused = true
	pause_duration = randf_range(0.5, 1.0)  # 0.5-1.0 seconds max
	pause_timer = randf_range(5.0, 12.0)  # Longer cooldown between pauses (5-12 seconds instead of 2-5)
	if debug: print("Friend started pause for ", pause_duration, " seconds")

func handle_pause() -> void:
	pause_duration -= get_process_delta_time()
	if pause_duration <= 0.0:
		is_paused = false
		if debug: print("Friend finished pause")
		return

func start_drift() -> void:
	is_drifting = true
	drift_direction = Vector2(randf_range(-0.8, 0.8), randf_range(-0.8, 0.8)).normalized()
	drift_duration = randf_range(3.0, 8.0)  # 3-8 seconds of drifting
	drift_timer = randf_range(5.0, 15.0)  # 5-15 seconds cooldown between drifts
	if debug: print("Friend started drifting for ", drift_duration, " seconds")

func handle_drift() -> void:
	drift_duration -= get_process_delta_time()
	if drift_duration <= 0.0:
		is_drifting = false
		if debug: print("Friend finished drifting")
		return

func setup_touch_responder() -> void:
	print("=== SETTING UP FRIEND TOUCH RESPONDER ===")
	var touch_responder = $TouchArea/TouchResponder
	if touch_responder:
		touch_responder.touched.connect(_on_touched)
		print("Connected TouchResponder touched signal")
		print("TouchResponder script: ", touch_responder.get_script())
	else:
		print("ERROR: TouchResponder not found")
	
	# Also check TouchArea setup
	var touch_area = $TouchArea
	if touch_area:
		print("TouchArea found - collision_layer: ", touch_area.collision_layer, " collision_mask: ", touch_area.collision_mask)
		print("TouchArea children: ", touch_area.get_child_count())
		for child in touch_area.get_children():
			print("  - ", child.name, " (", child.get_class(), ")")
	else:
		print("ERROR: TouchArea not found")

func setup_interaction_area() -> void:
	print("=== SETTING UP FRIEND INTERACTION AREA ===")
	
	# Create interaction area
	interaction_area = Area2D.new()
	interaction_area.name = "InteractionArea"
	add_child(interaction_area)
	print("Created interaction area: ", interaction_area)
	print("Interaction area collision_layer: ", interaction_area.collision_layer, " collision_mask: ", interaction_area.collision_mask)
	
	# Create collision shape
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(100, 100)  # 100x100 pixel interaction area
	collision_shape.shape = shape
	interaction_area.add_child(collision_shape)
	print("Added collision shape with size: ", shape.size)
	
	# Connect signals
	interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	interaction_area.body_exited.connect(_on_interaction_area_body_exited)
	print("Connected interaction area signals")
	
	# Add to interactable_areas group for input manager
	interaction_area.add_to_group("interactable_areas")
	print("Added to interactable_areas group")
	
	# Set collision layer/mask to detect Tess
	interaction_area.collision_layer = 0  # Don't collide with anything
	interaction_area.collision_mask = 4   # Detect layer 2 (2^2 = 4) - Tess's layer
	print("Set collision layer: ", interaction_area.collision_layer, " mask: ", interaction_area.collision_mask)
	
	# Debug: Check what Tess's collision layer actually is
	var tess_nodes = get_tree().get_nodes_in_group("Tess")
	if tess_nodes.size() > 0:
		var tess = tess_nodes[0]
		print("Tess collision_layer: ", tess.collision_layer)
		print("Tess collision_mask: ", tess.collision_mask)
		print("Tess groups: ", tess.get_groups())
	
	if debug: print("Friend interaction area setup complete")
	print("=== INTERACTION AREA SETUP COMPLETE ===")
	
	# Check if Tess is already in the interaction area
	await get_tree().process_frame  # Wait a frame for physics to update
	var tess_nodes_check = get_tree().get_nodes_in_group("Tess")
	if tess_nodes_check.size() > 0:
		var tess_check = tess_nodes_check[0]
		var distance = global_position.distance_to(tess_check.global_position)
		print("Tess distance after setup: ", distance)
		if distance < 50:  # Within interaction area
			print("Tess is already within interaction area - manually setting tess_in_interaction_area")
			tess_in_interaction_area = true

func _on_interaction_area_body_entered(body: Node2D) -> void:
	print("=== INTERACTION AREA BODY ENTERED ===")
	print("Body name: ", body.name)
	print("Body class: ", body.get_class())
	print("Body groups: ", body.get_groups())
	print("Body is in Tess group: ", body.is_in_group("Tess"))
	
	if body.is_in_group("Tess"):
		tess_in_interaction_area = true
		print("=== INTERACTION AREA DEBUG ===")
		print("Tess entered friend interaction area")
		print("tess_in_interaction_area set to: ", tess_in_interaction_area)
	else:
		print("Body entered interaction area: ", body.name, " (not Tess)")

func _on_interaction_area_body_exited(body: Node2D) -> void:
	print("=== INTERACTION AREA BODY EXITED ===")
	print("Body name: ", body.name)
	print("Body is in Tess group: ", body.is_in_group("Tess"))
	
	if body.is_in_group("Tess"):
		tess_in_interaction_area = false
		print("=== INTERACTION AREA DEBUG ===")
		print("Tess exited friend interaction area")
		print("tess_in_interaction_area set to: ", tess_in_interaction_area)
	else:
		print("Body exited interaction area: ", body.name, " (not Tess)")

func _on_touched(position: Vector2) -> void:
	print("=== FRIEND _ON_TOUCHED DEBUG ===")
	print("Position: ", position)
	print("Tess in interaction area: ", tess_in_interaction_area)
	print("Interaction area exists: ", interaction_area != null)
	
	# Debug Tess position and distance
	var tess_nodes = get_tree().get_nodes_in_group("Tess")
	if tess_nodes.size() > 0:
		var tess = tess_nodes[0]
		var distance = global_position.distance_to(tess.global_position)
		print("Tess position: ", tess.global_position)
		print("Friend position: ", global_position)
		print("Distance to Tess: ", distance)
		print("Interaction area size: 100x100 pixels")
	else:
		print("No Tess found in scene!")
	
	# Check if Tess is in interaction area (both the stored state and current distance)
	var tess_nodes_range = get_tree().get_nodes_in_group("Tess")
	var tess_in_range = false
	if tess_nodes_range.size() > 0:
		var tess_range = tess_nodes_range[0]
		var distance = global_position.distance_to(tess_range.global_position)
		tess_in_range = distance < 50  # 50 pixel radius for 100x100 area
		print("Distance check: ", distance, " < 50 = ", tess_in_range)
	
	if tess_in_interaction_area or tess_in_range:
		print("BeardedFriend: 'Hey there, friend.'")
		say_dialogue("friend_hey_there")
		if debug: print("Friend interaction - Tess in interaction area")
		# DO NOT allow movement - return without doing anything
		return
	else:
		# Tess is not in interaction area, allow normal movement
		if debug: print("Friend touched but Tess not in interaction area - allowing movement")
		# Call the character touch method to allow movement
		_on_character_touched(position)
