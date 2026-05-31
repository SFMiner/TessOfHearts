extends Control
class_name SimpleDialogueSystem

@onready var dialogue_container: Control = %DialogueContainer
@onready var text_display: HandwrittenLabel = %HandwrittenLabel
@onready var background: ColorRect = %Background

var is_showing: bool = false
var dialogue_speaker_node: Node = null
var choice_ui: Control = null
var _auto_hide_timer: SceneTreeTimer = null
var _auto_hide_callable: Callable

const scr_debug : bool = false 
var debug : bool

func _ready() -> void:
	debug = scr_debug or GameData.sys_debug
	if debug: print("=== DIALOGUE SYSTEM SETUP ===")
	
	# Add to group for easy access
	add_to_group("dialogue_system")
	
	# Wait a frame to ensure all nodes are ready
	await get_tree().process_frame
	
	if debug: 
		print("DialogueSystem node: ", self.name)
		print("DialogueSystem children: ", get_children())
	
	if not dialogue_container:
		if debug: print("ERROR: No dialogue container found, setting up manually")
		setup_dialogue_container()
	else:
		if debug: 
			print("Dialogue container found: ", dialogue_container.name)
			print("Dialogue container children: ", dialogue_container.get_children())
	
	# Try to find the HandwrittenLabel
	if not text_display:
		text_display = dialogue_container.get_node_or_null("HandwrittenLabel")
		if debug: print("Looking for HandwrittenLabel in container: ", text_display != null)
		
		if not text_display:
			print("ERROR: HandwrittenLabel not found, creating manually")
			text_display = HandwrittenLabel.new()
			text_display.name = "HandwrittenLabel"
			dialogue_container.add_child(text_display)
	
	if not background:
		background = dialogue_container.get_node_or_null("Background")
		if debug: print("Background found: ", background != null)
	
	if debug: 
		print("text_display = " + str(text_display))
		print("background = " + str(background))
	
	# Find choice UI
	choice_ui = get_tree().current_scene.get_node_or_null("UI/DialogueChoiceUI")
	if choice_ui:
		if debug: print("Choice UI found: ", choice_ui.name)
		choice_ui.choice_selected.connect(_on_choice_selected)
	else:
		if debug: print("WARNING: Choice UI not found")
	
	hide_dialogue()
	if debug: print("Dialogue system setup complete")

func setup_dialogue_container() -> void:
	if debug: print("Setting up dialogue container manually")
	dialogue_container = Control.new()
	dialogue_container.name = "DialogueContainer"
	add_child(dialogue_container)
	
	# Create background
	background = ColorRect.new()
	background.name = "Background"
	background.color = Color("#FFFACD", 0.9)  # Post-it yellow
	dialogue_container.add_child(background)
	
	# Create text display
	text_display = HandwrittenLabel.new()
	text_display.name = "HandwrittenLabel"
	dialogue_container.add_child(text_display)
	
	if debug: print("Manual setup complete - text_display: ", text_display)

func show_dialogue(dialogue_key: String, speaker_node: Node = null, background_color: Color = Color(1, 0.98, 0.8, 0.9), scale_factor: float = 1.0, fade_duration: float = 5.0) -> void:
	if debug: 
		print("=== SHOWING DIALOGUE ===")
		print("Dialogue key: ", dialogue_key)
		print("Speaker node: ", speaker_node.name if speaker_node else "null")
	
	# If no speaker node provided, use the current scene
	if not speaker_node:
		speaker_node = get_tree().current_scene
	
	# Clean up any previous dialogue container
	if is_showing:
		hide_dialogue()
	
	# Create dialogue as child of speaker
	dialogue_container = Control.new()
	dialogue_container.name = "DialogueContainer"
	speaker_node.add_child(dialogue_container)
	dialogue_speaker_node = speaker_node

	# Create background
	var bg_rect = ColorRect.new()
	bg_rect.name = "Background"
	bg_rect.color = background_color
	dialogue_container.add_child(bg_rect)

	# Create text display
	var label = HandwrittenLabel.new()
	label.name = "HandwrittenLabel"
	dialogue_container.add_child(label)

	# Set the handwritten text
	label.set_handwritten_text("dialogue", dialogue_key)

	# Use the HandwrittenLabel's size with scaling
	var label_size = label.custom_minimum_size
	var scaled_size = label_size * scale_factor
	if debug:
		print("HandwrittenLabel size: ", label_size)
		print("Scale factor: ", scale_factor)
		print("Scaled size: ", scaled_size)

	# Resize the dialogue container to match the scaled label size
	dialogue_container.size = scaled_size
	if debug: print("Resized dialogue container to: ", dialogue_container.size)

	# Also resize the background to match
	bg_rect.size = scaled_size
	if debug: print("Resized background to: ", bg_rect.size)

	# Scale the text display
	label.scale = Vector2(scale_factor, scale_factor)
	if debug: print("Text display scale: ", label.scale)

	# Set z_index to be 10 above the speaker
	if speaker_node:
		dialogue_container.z_index = speaker_node.z_index + 10

	# Position dialogue above the speaker
	var y_offset = -scaled_size.y - 20  # Default offset

	# Move Tess's dialogue up by 30 pixels
	if speaker_node and speaker_node.is_in_group("Tess"):
		y_offset -= 30

	dialogue_container.position = Vector2(
		-(scaled_size.x / 2),  # Center horizontally on speaker
		y_offset                # Position above speaker
	)

	# Show with animation
	dialogue_container.visible = true
	dialogue_container.modulate = Color.TRANSPARENT

	var show_tween = create_tween()
	show_tween.tween_property(dialogue_container, "modulate", Color.WHITE, 0.3)

	# Auto-hide after specified duration. Store the timer+callable so hide_dialogue()
	# can cancel it — prevents "lambda capture freed" when the container is freed
	# before the timer fires (e.g. a second dialogue superseding this one).
	var container = dialogue_container
	_auto_hide_callable = func():
		_auto_hide_timer = null
		if not is_instance_valid(container):
			return
		if container != dialogue_container:
			return
		hide_dialogue()
	_auto_hide_timer = get_tree().create_timer(fade_duration)
	_auto_hide_timer.timeout.connect(_auto_hide_callable)

	if debug: print("Dialogue display complete")
	is_showing = true

func hide_dialogue() -> void:
	if not is_showing or not is_instance_valid(dialogue_container):
		return

	# Cancel any pending auto-hide timer so its lambda never fires against a freed container.
	if _auto_hide_timer != null:
		if _auto_hide_timer.timeout.is_connected(_auto_hide_callable):
			_auto_hide_timer.timeout.disconnect(_auto_hide_callable)
		_auto_hide_timer = null

	# Single teardown path: fade out, then free the container so dialogue bubbles
	# don't accumulate on the speaker node (the choices path has no auto-hide timer).
	var container := dialogue_container
	dialogue_container = null
	dialogue_speaker_node = null
	is_showing = false

	var tween := create_tween()
	tween.tween_property(container, "modulate", Color.TRANSPARENT, 0.3)
	tween.tween_callback(func():
		if is_instance_valid(container):
			container.queue_free()
	)

func position_dialogue_near_speaker(speaker_pos: Vector2) -> void:
	# Position dialogue bubble above and centered on the speaker
	# Since this is in the UI layer, we need to use viewport coordinates
	if debug: print("Speaker world position: ", speaker_pos)
	
	# Get the viewport size and use it for positioning
	var viewport_size = get_viewport().get_visible_rect().size
	var dialogue_size = dialogue_container.size
	
	# Convert world position to viewport position
	var viewport_pos = speaker_pos
	var canvas_transform = get_viewport().get_canvas_transform()
	viewport_pos = canvas_transform * speaker_pos
	
	# Position near the actual speaker
	var dialogue_pos = Vector2(
		viewport_pos.x - (dialogue_size.x / 2),  # Center on speaker horizontally
		viewport_pos.y - dialogue_size.y - 50    # Position above speaker
	)

	# Ensure dialogue stays within viewport bounds
	dialogue_pos.x = clamp(dialogue_pos.x, 0, viewport_size.x - dialogue_size.x)
	dialogue_pos.y = clamp(dialogue_pos.y, 0, viewport_size.y - dialogue_size.y)
	
	# Set global position of the dialogue container
	dialogue_container.global_position = dialogue_pos 
	
	# Make sure the HandwrittenLabel is properly positioned within the container
	if text_display:
		# Center the text within the container
		text_display.position = Vector2.ZERO
		text_display.size = dialogue_container.size
	
	if debug: 
		print("Viewport size: ", viewport_size)
		print("Viewport center: ", viewport_pos) # Changed from viewport_center to viewport_pos
		print("Dialogue positioned at: ", dialogue_pos)
		print("Dialogue container size: ", dialogue_container.size)
		print("Speaker position: ", speaker_pos)
		print("Text display position: ", text_display.position if text_display else "null")

# Check if dialogue system is interfering:
func say_dialogue(dialogue_key: String) -> void:
	if debug: 
		print("=== DIALOGUE DEBUG ===")
		print("Looking for dialogue system...")
	
	var dialogue_system = get_tree().current_scene.find_child("SimpleDialogueSystem")
	if dialogue_system:
		if debug: print("Dialogue system found!")
		var dialogue_point = $DialoguePoint if has_node("DialoguePoint") else self
		dialogue_system.show_dialogue(dialogue_key, dialogue_point)
	else:
		if debug: 
			print("ERROR: No dialogue system found")
			print("Current scene children: ")
		for child in get_tree().current_scene.get_children():
			if debug: print("  - ", child.name, " (", child.get_class(), ")")

func show_dialogue_with_choices(dialogue_key: String, choices: Array[Dictionary], speaker_node: Node = null, choice_speaker_position: Vector2 = Vector2.ZERO, background_color: Color = Color(1, 0.98, 0.8, 0.9)) -> void:
	if debug: 
		print("=== SHOWING DIALOGUE WITH CHOICES ===")
		print("Dialogue key: ", dialogue_key)
		print("Number of choices: ", choices.size())
		
	# Show the dialogue first (without auto-hide)
	show_dialogue_manual(dialogue_key, speaker_node, background_color)
	
	# Wait a moment, then show choices
	await get_tree().create_timer(1.0).timeout
	
	if choice_ui:
		# Use choice_speaker_position if provided, otherwise use speaker_node position
		var choice_pos = choice_speaker_position
		if choice_pos == Vector2.ZERO and speaker_node:
			choice_pos = speaker_node.global_position
		choice_ui.show_choices(choices, choice_pos)
	else:
		print("ERROR: Choice UI not available")

func show_dialogue_manual(dialogue_key: String, speaker_node: Node = null, background_color: Color = Color(1, 0.98, 0.8, 0.9), scale_factor: float = 1.0) -> void:
	if debug: 
		print("=== SHOWING DIALOGUE MANUAL ===")
		print("Dialogue key: ", dialogue_key)
		print("Speaker node: ", speaker_node.name if speaker_node else "null")
	
	# If no speaker node provided, use the current scene
	if not speaker_node:
		speaker_node = get_tree().current_scene
	
	# Clean up any previous dialogue container
	if is_showing:
		hide_dialogue()
	
	# Create dialogue as child of speaker
	dialogue_container = Control.new()
	dialogue_container.name = "DialogueContainer"
	speaker_node.add_child(dialogue_container)
	dialogue_speaker_node = speaker_node

	# Create background
	var bg_rect = ColorRect.new()
	bg_rect.name = "Background"
	bg_rect.color = background_color
	dialogue_container.add_child(bg_rect)

	# Create text display
	var label = HandwrittenLabel.new()
	label.name = "HandwrittenLabel"
	dialogue_container.add_child(label)

	# Set the handwritten text
	label.set_handwritten_text("dialogue", dialogue_key)

	# Use the HandwrittenLabel's size with scaling
	var label_size = label.custom_minimum_size
	var scaled_size = label_size * scale_factor
	if debug:
		print("HandwrittenLabel size: ", label_size)
		print("Scale factor: ", scale_factor)
		print("Scaled size: ", scaled_size)

	# Resize the dialogue container to match the scaled label size
	dialogue_container.size = scaled_size
	if debug: print("Resized dialogue container to: ", dialogue_container.size)

	# Also resize the background to match
	bg_rect.size = scaled_size
	if debug: print("Resized background to: ", bg_rect.size)

	# Scale the text display
	label.scale = Vector2(scale_factor, scale_factor)
	if debug: print("Text display scale: ", label.scale)

	# Set z_index to be 10 above the speaker
	if speaker_node:
		dialogue_container.z_index = speaker_node.z_index + 10

	# Position dialogue above the speaker
	var y_offset = -scaled_size.y - 20  # Default offset

	# Move Tess's dialogue up by 30 pixels
	if speaker_node and speaker_node.is_in_group("Tess"):
		y_offset -= 30

	dialogue_container.position = Vector2(
		-(scaled_size.x / 2),  # Center horizontally on speaker
		y_offset                # Position above speaker
	)

	# Show with animation
	dialogue_container.visible = true
	dialogue_container.modulate = Color.TRANSPARENT

	var show_tween = create_tween()
	show_tween.tween_property(dialogue_container, "modulate", Color.WHITE, 0.3)

	if debug: print("Dialogue display complete (manual - no auto-hide)")
	is_showing = true

func _on_choice_selected(choice_key: String) -> void:
	if debug: 
		print("=== DIALOGUE CHOICE SELECTED ===")
		print("Choice key: ", choice_key)
		print("Choice UI found: ", choice_ui != null)
	
	# Hide the dialogue when a choice is made
	hide_dialogue()
	
	# Handle different choice responses
	match choice_key:
		"eat_cookies":
			if debug: print("Tess chose to eat cookies")
			trigger_cookie_effects()
		"drink_whiskey":
			if debug: print("Tess chose to drink whiskey")
			trigger_whiskey_effects()
		"cookies_and_whiskey":
			if debug: print("Tess chose cookies and whiskey")
			trigger_cookie_effects()
			trigger_whiskey_effects()
		"excuse_me":
			if debug: print("Tess chose to excuse the friend")
			trigger_excuse_friend_effects()
		"never_mind":
			if debug: print("Tess chose to do nothing")
		_:
			if debug: print("Unknown choice key: ", choice_key)

func trigger_cookie_effects() -> void:
	if debug: print("=== TRIGGERING COOKIE EFFECTS ===")
	
	# Use the special friend version that doubles energy and plays animation
	if GameManager.consume_cookie_with_friend():
		if debug: print("Tess and friend shared cookies together")
	else:
		if debug: print("ERROR: No cookies available to consume with friend")

func trigger_whiskey_effects() -> void:
	if debug: print("=== TRIGGERING WHISKEY EFFECTS ===")
	# Whiskey effects: healing_amount = 5.0 * 1.5 = 7.5
	var healing_amount = 7.5
	if debug: print("Whiskey healing amount: ", healing_amount)
	
	# Consume whiskey from inventory
	if GameManager.consume_whiskey():
		if debug: print("Tess feels warmed by the whiskey")
	else:
		if debug: print("ERROR: No whiskey available to consume")

func trigger_excuse_friend_effects() -> void:
	if debug: print("=== TRIGGERING EXCUSE FRIEND EFFECTS ===")
	
	# Find the friend and send them off screen
	var friend_nodes = get_tree().get_nodes_in_group("Friend")
	if debug: print("Found ", friend_nodes.size(), " friend nodes")
	
	if friend_nodes.size() > 0:
		var friend = friend_nodes[0]
		if debug: 
			print("Friend name: ", friend.name)
			print("Friend has depart_from_screen method: ", friend.has_method("depart_from_screen"))
		
		if friend.has_method("depart_from_screen"):
			friend.depart_from_screen()
			if debug: print("Friend is departing from screen")
		else:
			if debug: print("ERROR: Friend doesn't have depart_from_screen method")
	else:
		if debug: 
			print("ERROR: No friend found in scene")
			print("Available groups: ", get_tree().get_nodes_in_group("Friend"))

# Test function to manually trigger excuse me
func test_excuse_me() -> void:
	if debug: print("=== TESTING EXCUSE ME MANUALLY ===")
	trigger_excuse_friend_effects()

# Test function to manually trigger dialogue choice selection (to fix input)
func test_dialogue_choice_fix() -> void:
	if debug: print("=== TESTING DIALOGUE CHOICE FIX ===")
	_on_choice_selected("never_mind")
