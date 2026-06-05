# ===========================================
# BEARDEDFRIEND.GD - SIMPLE VERSION
# ===========================================

extends Character


# Friend personality variables
var dialog_point_pos_right : Vector2
var dialog_point_pos_left : Vector2
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

# Back-to point system for retracing path
var back_to_points: Array[Vector2] = []
var last_position: Vector2 = Vector2.ZERO
var half_screen_distance: float = 0.0
var is_departing: bool = false
var has_departed: bool = false
var is_summoned: bool = false
var _departure_timer: SceneTreeTimer = null
var _choices_shown: bool = false
var _choices_timer: SceneTreeTimer = null



# Navigation system
var navigation_agent: NavigationAgent2D = null

# Interaction area system
var tess_in_interaction_area: bool = false
var interaction_area: Area2D = null

@onready var dialog_point : Marker2D = $DialoguePoint

func _ready() -> void:

	debug = scr_debug or GameData.sys_debug
	character_name = "Bearded Friend"
	dialog_point_pos_right = $DialoguePoint.position
	dialog_point_pos_left = Vector2(-dialog_point_pos_right.x, dialog_point_pos_right.y)
	uses_energy = false  # Dialogue interactions don't use energy
	can_move = true  # Friend can move to follow Tess
	anim = get_node_or_null("AnimationPlayer")
	add_to_group("Friend")
	setup_interaction_area()
	setup_touch_responder()
	super._ready()

	# Initialize back-to point system
	last_position = global_position
	half_screen_distance = get_viewport().get_visible_rect().size.x * 0.5  # Half screen width
	if debug: print("Half screen distance: ", half_screen_distance)

	# Add starting position as first back-to point
	back_to_points.append(global_position)
	if debug: print("Added starting position as first back-to point: ", global_position)

	# Setup navigation agent from scene node
	navigation_agent = get_node_or_null("NavigationAgent2D") as NavigationAgent2D
	if navigation_agent:
		navigation_agent.target_desired_distance = 50.0
		navigation_agent.path_desired_distance = 30.0
		navigation_agent.path_max_distance = 2000.0
		if debug: print("Navigation agent ready - radius: ", navigation_agent.radius)

	# Debug check
	if debug:
		print("=== FRIEND READY DEBUG ===")
		print("Interaction area exists: ", interaction_area != null)
		if interaction_area:
			print("Interaction area children: ", interaction_area.get_child_count())
			print("Interaction area collision mask: ", interaction_area.collision_mask)
			print("Interaction area collision layer: ", interaction_area.collision_layer)
			print("=== FRIEND READY COMPLETE ===")

		# Debug state flags
		print("=== FRIEND INITIAL STATE ===")
		print("is_departing: ", is_departing)
		print("has_departed: ", has_departed)
		print("is_summoned: ", is_summoned)
		print("can_move: ", can_move)
		print("is_moving: ", is_moving)
		print("visible: ", visible)
		print("process_mode: ", process_mode)
		print("input_pickable: ", input_pickable)
		print("z_index: ", z_index)
		print("z_as_relative: ", z_as_relative)

func setup_character() -> void:
	if sprite:
		create_placeholder_texture(Color("#4C8CB8"))  # Blue

func set_dialog_point():
	if direction.x > 0:
		dialog_point.position = dialog_point_pos_right
	if direction.x < 0:
		dialog_point.position = dialog_point_pos_left

func create_placeholder_texture(color: Color) -> void:
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(color)
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite.texture = texture

func track_movement_for_back_to_points() -> void:
	# Don't track if departing
	if is_departing:
		return

	# Calculate distance moved since last position
	var distance_moved = global_position.distance_to(last_position)

	# Debug movement tracking
	if distance_moved > 10.0:  # Only print for significant movement
		pass
		#if debug: print("Movement tracking - Distance moved: ", distance_moved, " / ", half_screen_distance)

	# If we've moved more than half a screen distance, create a back-to point
	if distance_moved >= half_screen_distance:
		if debug:
			print("=== CREATING BACK-TO POINT ===")
			print("Distance moved: ", distance_moved)
			print("Current position: ", global_position)
			print("Last position: ", last_position)

		# Add current position as a back-to point
		back_to_points.append(global_position)

		# Keep only the latest two points
		if back_to_points.size() > 2:
			back_to_points.remove_at(0)  # Remove oldest point

		if debug: print("Back-to points: ", back_to_points)

		# Update last position
		last_position = global_position

func setup_navigation_agent() -> void:
	if debug: print("=== SETTING UP NAVIGATION AGENT ===")

	# Create navigation agent
	navigation_agent = NavigationAgent2D.new()
	add_child(navigation_agent)

	# Configure navigation agent
	navigation_agent.radius = 16.0  # Friend's collision radius
	navigation_agent.target_desired_distance = 5.0  # How close to get to target
	navigation_agent.path_max_distance = 1000.0  # Maximum path length
	navigation_agent.path_metadata_flags = 0  # No metadata needed

	if debug: print("Navigation agent created with radius: ", navigation_agent.radius)
	if debug: print("Target desired distance: ", navigation_agent.target_desired_distance)

func _physics_process(delta: float) -> void:
	# Call parent physics process for proper physics handling
	#super._physics_process(delta)

	# Update timers
	wander_timer -= delta
	pause_timer -= delta
	drift_timer -= delta
	# Count down active drift so it actually ends (handle_drift clears is_drifting at 0)
	if is_drifting:
		handle_drift()
	z_index = get_global_position().y/5  # Temporarily disabled to test UI interaction
	# $Label.text = str(direction)
	# Track movement for back-to points
	track_movement_for_back_to_points()

	# Handle friend's personality and movement
	handle_friend_personality()

	# Handle movement without calling parent (to avoid energy system)
	if is_moving and can_move:
		move_towards_target_friend()

func handle_friend_personality() -> void:
	# Don't handle personality if departing
	if is_departing:
		return

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
	if is_departing or has_departed:
		return

	var tess_pos = GameData.get_tess_position()

	if is_colliding_with_tess():
		is_moving = false
		velocity = Vector2.ZERO
		return

	var distance_to_tess = global_position.distance_to(tess_pos)
	if distance_to_tess > 50.0 and distance_to_tess < half_screen_distance:
		target_position = tess_pos
		if navigation_agent:
			navigation_agent.target_position = tess_pos
		is_moving = true
	elif distance_to_tess >= half_screen_distance:
		is_moving = false
		velocity = Vector2.ZERO
		if debug: print("Friend stopped following - too far away")
	else:
		target_position = tess_pos
		if navigation_agent:
			navigation_agent.target_position = tess_pos
		is_moving = true

func is_colliding_with_tess() -> bool:
	var tess_nodes = get_tree().get_nodes_in_group("Tess")
	if tess_nodes.size() > 0:
		var tess_node = tess_nodes[0]
		var distance = global_position.distance_to(tess_node.global_position)
		return distance < 50.0  # Stop when within 20 pixels of Tess (closer collision)
	return false

func play_animation(anim_name : String) -> void:
	if debug: print("playing Friend animnation: " + anim_name)
	anim.play(anim_name)

func move_towards_target_friend() -> void:
	var move_target = target_position

	# Use navigation path position for steering when following Tess
	if not is_departing and navigation_agent:
		var nav_target = navigation_agent.get_next_path_position()
		var nav_distance = navigation_agent.distance_to_target()
		if nav_distance > navigation_agent.target_desired_distance:
			move_target = nav_target

	var distance_to_target = global_position.distance_to(target_position)
	set_dialog_point()

	# Stop when close to the actual target
	var tess_pos = GameData.get_tess_position()
	var distance_to_tess = global_position.distance_to(tess_pos)

	if distance_to_target < 5.0 or (not is_departing and distance_to_tess < 50.0):
		velocity = Vector2.ZERO
		is_moving = false
		if anim:
			anim.play("idle_" + last_direction)
		if is_departing:
			is_departing = false
			has_departed = true
			is_summoned = false
		return

	var speed_multiplier = 1.0

	direction = (move_target - global_position).normalized()

	# Reduce speed as we get closer to Tess
	if not is_departing and distance_to_tess < 100.0:
		speed_multiplier *= clamp(distance_to_tess / 100.0, 0.2, 1.0)

	if is_drifting and not is_departing:
		direction = (direction + drift_direction * 0.3).normalized()

	velocity = direction * base_movement_speed * speed_multiplier

	if anim:
		if direction.x > 0:
			anim.play("walk_right")
			last_direction = "right"
		elif direction.x < 0:
			anim.play("walk_left")
			last_direction = "left"

	move_and_slide()

	if debug and is_departing and velocity.length() > 0.1:
		print("Friend departing - velocity: ", velocity, " Position: ", global_position)

func _on_character_touched(position: Vector2) -> void:
	# This runs via the base Character's Area2D input_event path. In-range dialogue is
	# handled exclusively by _on_touched (the InputManager path) to avoid a double
	# trigger, so here we only handle the out-of-range movement/feedback fallback.
	if debug:
		print("=== FRIEND CHARACTER TOUCHED DEBUG ===")
		print("Position: ", position)
		print("Tess in interaction area: ", tess_in_interaction_area)

	if tess_in_interaction_area:
		# Dialogue is handled by _on_touched; do nothing (and don't move).
		return
	# Tess is not in range — allow normal touch feedback behavior.
	super._on_character_touched(position)

func summon_friend() -> void:
	if debug: print("=== SUMMONING FRIEND ===")
	if debug: print("Friend current state - has_departed: ", has_departed, " is_departing: ", is_departing, " is_summoned: ", is_summoned)

	# Reset departure state
	has_departed = false
	is_departing = false
	is_summoned = true
	# Restore visibility in case a prior departure timeout hid the friend
	visible = true

	# Get Tess's position
	var tess_nodes = get_tree().get_nodes_in_group("Tess")
	if tess_nodes.size() > 0:
		var tess = tess_nodes[0]
		var tess_position = tess.global_position

		# Move friend to Tess's position
		target_position = tess_position
		is_moving = true

		if debug:
			print("Friend summoned to Tess at: ", tess_position)
			print("Friend will now follow Tess again")

			# Debug state after summon
			print("=== FRIEND STATE AFTER SUMMON ===")
			print("is_departing: ", is_departing)
			print("has_departed: ", has_departed)
			print("is_summoned: ", is_summoned)
			print("can_move: ", can_move)
			print("is_moving: ", is_moving)
			print("visible: ", visible)
			print("process_mode: ", process_mode)
			print("input_pickable: ", input_pickable)
			print("z_index: ", z_index)
			print("z_as_relative: ", z_as_relative)
	else:
		if debug: print("ERROR: Tess not found for summoning")

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
	if debug: print("=== SETTING UP FRIEND TOUCH RESPONDER ===")
	var touch_responder = $TouchArea/TouchResponder
	if touch_responder:
		touch_responder.touched.connect(_on_touched)
		if debug:
			print("Connected TouchResponder touched signal")
			print("TouchResponder script: ", touch_responder.get_script())
	else:
		if debug: print("ERROR: TouchResponder not found")

	# Also check TouchArea setup
	var touch_area = $TouchArea
	if touch_area:
		if debug: print("TouchArea found - collision_layer: ", touch_area.collision_layer, " collision_mask: ", touch_area.collision_mask)
		if debug: print("TouchArea children: ", touch_area.get_child_count())
		for child in touch_area.get_children():
			if debug: print("  - ", child.name, " (", child.get_class(), ")")
	else:
		if debug: print("ERROR: TouchArea not found")

func setup_interaction_area() -> void:
	if debug: print("=== SETTING UP FRIEND INTERACTION AREA ===")

	# Create interaction area
	interaction_area = Area2D.new()
	interaction_area.name = "InteractionArea"
	add_child(interaction_area)
	if debug:
		print("Created interaction area: ", interaction_area)
		print("Interaction area collision_layer: ", interaction_area.collision_layer, " collision_mask: ", interaction_area.collision_mask)

	# Create collision shape
	#var collision_shape = CollisionShape2D.new()
	#var shape = RectangleShape2D.new()
	#shape.size = Vector2(100, 100)  # 100x100 pixel interaction area
	#collision_shape.shape = shape
	#interaction_area.add_child(collision_shape)
	#if debug: print("Added collision shape with size: ", shape.size)


	# Connect signals
	interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	interaction_area.body_exited.connect(_on_interaction_area_body_exited)
	if debug: print("Connected interaction area signals")

	# Add to interactable_areas group for input manager
	interaction_area.add_to_group("interactable_areas")
	if debug: print("Added to interactable_areas group")

	# Set collision layer/mask to detect Tess
	interaction_area.collision_layer = 0  # Don't collide with anything
	interaction_area.collision_mask = 4   # Detect layer 2 (2^2 = 4) - Tess's layer
	if debug: print("Set collision layer: ", interaction_area.collision_layer, " mask: ", interaction_area.collision_mask)

	# Debug: Check what Tess's collision layer actually is
	var tess_nodes = get_tree().get_nodes_in_group("Tess")
	if tess_nodes.size() > 0:
		var tess = tess_nodes[0]
		if debug:
			print("Tess collision_layer: ", tess.collision_layer)
			print("Tess collision_mask: ", tess.collision_mask)
			print("Tess groups: ", tess.get_groups())

			print("Friend interaction area setup complete")
			print("=== INTERACTION AREA SETUP COMPLETE ===")

	# Check if Tess is already in the interaction area
	await get_tree().process_frame  # Wait a frame for physics to update
	var tess_nodes_check = get_tree().get_nodes_in_group("Tess")
	if tess_nodes_check.size() > 0:
		var tess_check = tess_nodes_check[0]
		var distance = global_position.distance_to(tess_check.global_position)
		if debug: print("Tess distance after setup: ", distance)
		if distance < 50:  # Within interaction area
			if debug: print("Tess is already within interaction area - manually setting tess_in_interaction_area")
			tess_in_interaction_area = true

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if debug:
		print("=== INTERACTION AREA BODY ENTERED ===")
		print("Body name: ", body.name)
		print("Body class: ", body.get_class())
		print("Body groups: ", body.get_groups())
		print("Body is in Tess group: ", body.is_in_group("Tess"))

	if body.is_in_group("Tess"):
		tess_in_interaction_area = true
		if debug:
			print("=== INTERACTION AREA DEBUG ===")
			print("Tess entered friend interaction area")
			print("tess_in_interaction_area set to: ", tess_in_interaction_area)
	else:
		if debug: print("Body entered interaction area: ", body.name, " (not Tess)")

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if debug:
		print("=== INTERACTION AREA BODY EXITED ===")
		print("Body name: ", body.name)
		print("Body is in Tess group: ", body.is_in_group("Tess"))

	if body.is_in_group("Tess"):
		tess_in_interaction_area = false
		if debug:
			print("=== INTERACTION AREA DEBUG ===")
			print("Tess exited friend interaction area")
			print("tess_in_interaction_area set to: ", tess_in_interaction_area)
	else:
		if debug: print("Body exited interaction area: ", body.name, " (not Tess)")

func depart_from_screen() -> void:
	if debug:
		print("=== FRIEND DEPARTING FROM SCREEN ===")
		print("Friend position: ", global_position)
		print("Friend visible: ", visible)
		print("Back-to points available: ", back_to_points.size())

	# Stop all current behaviors
	is_wandering = false
	is_paused = false
	is_drifting = false
	is_moving = false
	is_departing = true
	velocity = Vector2.ZERO

	# Set a flag to prevent normal following behavior
	is_departing = true

	# Determine departure target using back-to point system
	var departure_target = determine_departure_target()
	if debug: print("Departure target: ", departure_target)

	# Move towards the departure target
	target_position = departure_target
	is_moving = true
	if debug:
		print("Friend is now departing to: ", departure_target)
		print("Friend is_departing: ", is_departing)

	# Set a timer to hide the friend when they reach the target
	_departure_timer = get_tree().create_timer(10.0)  # 10 seconds max (increased from 5)
	_departure_timer.timeout.connect(_on_departure_timeout)

func determine_departure_target() -> Vector2:
	if debug:
		print("=== DETERMINING DEPARTURE TARGET ===")
		print("Back-to points: ", back_to_points)
		print("Back-to points size: ", back_to_points.size())

	# Debug each back-to point
	for i in range(back_to_points.size()):
		if debug: print("Back-to point ", i, ": ", back_to_points[i])

	# If we have back-to points, use the less recent one (first in array)
	if back_to_points.size() >= 2:
		var back_to_target = back_to_points[0]  # Less recent point
		if debug:
			print("Using back-to point (retracing path): ", back_to_target)
			print("Current position: ", global_position)
			print("Distance to back-to point: ", global_position.distance_to(back_to_target))
		return back_to_target
	elif back_to_points.size() == 1:
		var back_to_target = back_to_points[0]  # Only one point
		if debug:
			print("Using single back-to point: ", back_to_target)
			print("Current position: ", global_position)
			print("Distance to back-to point: ", global_position.distance_to(back_to_target))
		return back_to_target
	else:
		# No back-to points available, fall back to edge-based departure
		if debug: print("No back-to points available, using edge-based departure")
		return determine_edge_departure_target()

func determine_edge_departure_target() -> Vector2:
	if debug: print("=== DETERMINING EDGE DEPARTURE TARGET ===")

	# Get viewport size
	var viewport_size = get_viewport().get_visible_rect().size

	# Calculate distances to each edge
	var distance_to_left = global_position.x
	var distance_to_right = viewport_size.x - global_position.x
	var distance_to_top = global_position.y
	var distance_to_bottom = viewport_size.y - global_position.y

	if debug:
		print("Current position: ", global_position)
		print("Viewport size: ", viewport_size)
		print("Distance to left: ", distance_to_left)
		print("Distance to right: ", distance_to_right)
		print("Distance to top: ", distance_to_top)
		print("Distance to bottom: ", distance_to_bottom)

	# Find the closest edge
	var min_distance = min(distance_to_left, distance_to_right, distance_to_top, distance_to_bottom)

	var off_screen_target: Vector2
	if min_distance == distance_to_left:
		off_screen_target = Vector2(-100, global_position.y)
	elif min_distance == distance_to_right:
		off_screen_target = Vector2(viewport_size.x + 100, global_position.y)
	elif min_distance == distance_to_top:
		off_screen_target = Vector2(global_position.x, -100)
	else:
		off_screen_target = Vector2(global_position.x, viewport_size.y + 100)

	if debug: print("Edge departure target: ", off_screen_target)
	return off_screen_target

func build_available_choices() -> Array[Dictionary]:
	var choices: Array[Dictionary] = []

	# Check inventory for cookies and whiskey
	var has_cookies = GameData.num_cookies > 0
	var has_whiskey = GameData.num_whiskey > 0

	if debug:
		print("=== BUILDING AVAILABLE CHOICES ===")
		print("Cookies in inventory: ", GameData.num_cookies)
		print("Whiskey in inventory: ", GameData.num_whiskey)
		print("Has cookies: ", has_cookies)
		print("Has whiskey: ", has_whiskey)

	# Add cookie option only if Tess has cookies
	if has_cookies:
		choices.append({"text": "Eat cookies with me", "key": "eat_cookies", "texture": "tess.eat_cookies_with_me"})
		if debug: print("Added cookie choice")

	# Add whiskey option only if Tess has whiskey
	if has_whiskey:
		choices.append({"text": "Let's have a drink", "key": "drink_whiskey", "texture": "tess_lets_have_a_drink"})
		if debug: print("Added whiskey choice")

	# Add cookies and whiskey option only if Tess has both
	if has_cookies and has_whiskey:
		choices.append({"text": "Let's have whiskey and cookies", "key": "cookies_and_whiskey", "texture": "tess_lets_have_whiskey_and_cookies"})
		if debug: print("Added cookies and whiskey choice")

	# Always add excuse me and never mind options
	choices.append({"text": "Would you excuse me for a bit?", "key": "excuse_me", "texture": "tess_excuse_me"})
	choices.append({"text": "Never mind.", "key": "never_mind", "texture": "tess_never_mind"})

	if debug: print("Total choices available: ", choices.size())
	return choices

func show_tess_choices() -> void:
	if _choices_shown:
		return
	_choices_shown = true
	var tess_nodes := get_tree().get_nodes_in_group("Tess")
	if tess_nodes.size() > 0:
		var tess := tess_nodes[0]
		if tess.has_method("show_dialogue_choices"):
			tess.show_dialogue_choices(build_available_choices())
		else:
			if debug: print("ERROR: Tess doesn't have show_dialogue_choices method")
	else:
		if debug: print("ERROR: Tess not found")

func _on_touched(position: Vector2) -> void:
	if debug:
		print("=== FRIEND _ON_TOUCHED DEBUG ===")
		print("Position: ", position)
		print("Tess in interaction area: ", tess_in_interaction_area)
		print("Interaction area exists: ", interaction_area != null)

	# Debug Tess position and distance
	var tess_nodes = get_tree().get_nodes_in_group("Tess")
	if tess_nodes.size() > 0:
		var tess = tess_nodes[0]
		var distance = global_position.distance_to(tess.global_position)
		if debug:
			print("Tess position: ", tess.global_position)
			print("Friend position: ", global_position)
			print("Distance to Tess: ", distance)
			print("Interaction area size: 100x100 pixels")
	else:
		if debug: print("No Tess found in scene!")

	# Check if Tess is in interaction area (both the stored state and current distance)
	var tess_nodes_range = get_tree().get_nodes_in_group("Tess")
	var tess_in_range = false
	if tess_nodes_range.size() > 0:
		var tess_range = tess_nodes_range[0]
		var distance = global_position.distance_to(tess_range.global_position)
		tess_in_range = distance < 65  # 65 pixel radius for 100x100 area
		if debug: print("Distance check: ", distance, " < 50 = ", tess_in_range)

	if tess_in_interaction_area or tess_in_range:
		if debug: print("BeardedFriend: 'Hey there, friend.'")

		# Show bearded friend's dialogue first (randomized response)
		var dialogue_system = get_tree().current_scene.find_child("DialogueSystem")
		if dialogue_system:
			# Use DialoguePoint as the speaker node for dialogue positioning
			var dialogue_point = $DialoguePoint if has_node("DialoguePoint") else self
			var friend_background_color = Color(0.73, 0.94, 0.96, 0.9)  # Light cyan background

			# Randomize between two possible responses
			var possible_responses = ["friend_hey_there", "tess_what_is_it"]
			var random_response = possible_responses[randi() % possible_responses.size()]

			dialogue_system.show_dialogue(random_response, dialogue_point, friend_background_color, 0.25)

			# After a short pause, show Tess's response choices.
			# show_tess_choices() is guarded by _choices_shown so clicking the bubble
			# early (via main.gd) won't cause a double-show.
			_choices_shown = false
			_choices_timer = get_tree().create_timer(1.0)
			_choices_timer.timeout.connect(func(): show_tess_choices())
		else:
			if debug:
				print("ERROR: Dialogue system not found")
				print("Available children: ")
			for child in get_tree().current_scene.get_children():
				if debug: print("  - ", child.name, " (", child.get_class(), ")")

		if debug: print("Friend interaction - Tess in interaction area")
		# DO NOT allow movement - return without doing anything
		return
	else:
		# Tess is not in interaction area, allow normal movement
		if debug: print("Friend touched but Tess not in interaction area - allowing movement")
		# Call the character touch method to allow movement
		_on_character_touched(position)

func _on_departure_timeout() -> void:
	if not is_moving or not is_departing:
		return
	if debug:
		print("Friend departure timeout - hiding friend")
		print("Final position: ", global_position)
		print("Target was: ", target_position)
		print("Distance to target: ", global_position.distance_to(target_position))
	if global_position.distance_to(target_position) < 50.0:
		if debug: print("Friend close enough to target, considering reached")
		is_departing = false
		is_moving = false
	else:
		print("Friend too far from target, hiding")
		visible = false
		is_moving = false
		is_departing = false
	_departure_timer = null

func _exit_tree() -> void:
	if _departure_timer != null and _departure_timer.timeout.is_connected(_on_departure_timeout):
		_departure_timer.timeout.disconnect(_on_departure_timeout)
