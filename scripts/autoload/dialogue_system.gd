extends Control
class_name SimpleDialogueSystem

@onready var dialogue_container: Control = %DialogueContainer
@onready var text_display: HandwrittenLabel = %HandwrittenLabel
@onready var background: ColorRect = %Background

var is_showing: bool = false
var choice_ui: Control = null

func _ready() -> void:
	print("=== DIALOGUE SYSTEM SETUP ===")
	
	# Add to group for easy access
	add_to_group("dialogue_system")
	
	# Wait a frame to ensure all nodes are ready
	await get_tree().process_frame
	
	print("DialogueSystem node: ", self.name)
	print("DialogueSystem children: ", get_children())
	
	if not dialogue_container:
		print("ERROR: No dialogue container found, setting up manually")
		setup_dialogue_container()
	else:
		print("Dialogue container found: ", dialogue_container.name)
		print("Dialogue container children: ", dialogue_container.get_children())
	
	# Try to find the HandwrittenLabel
	if not text_display:
		text_display = dialogue_container.get_node_or_null("HandwrittenLabel")
		print("Looking for HandwrittenLabel in container: ", text_display != null)
		
		if not text_display:
			print("ERROR: HandwrittenLabel not found, creating manually")
			text_display = HandwrittenLabel.new()
			text_display.name = "HandwrittenLabel"
			dialogue_container.add_child(text_display)
	
	if not background:
		background = dialogue_container.get_node_or_null("Background")
		print("Background found: ", background != null)
	
	print("text_display = " + str(text_display))
	print("background = " + str(background))
	
	# Find choice UI
	choice_ui = get_tree().current_scene.get_node_or_null("UI/DialogueChoiceUI")
	if choice_ui:
		print("Choice UI found: ", choice_ui.name)
		choice_ui.choice_selected.connect(_on_choice_selected)
	else:
		print("WARNING: Choice UI not found")
	
	hide_dialogue()
	print("Dialogue system setup complete")

func setup_dialogue_container() -> void:
	print("Setting up dialogue container manually")
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
	
	print("Manual setup complete - text_display: ", text_display)

func show_dialogue(dialogue_key: String, speaker_node: Node = null, background_color: Color = Color(1, 0.98, 0.8, 0.9), scale_factor: float = 1.0, fade_duration: float = 5.0) -> void:
	print("=== SHOWING DIALOGUE ===")
	print("Dialogue key: ", dialogue_key)
	print("Speaker node: ", speaker_node.name if speaker_node else "null")
	
	# If no speaker node provided, use the current scene
	if not speaker_node:
		speaker_node = get_tree().current_scene
	
	# Create dialogue as child of speaker
	var dialogue_container = Control.new()
	dialogue_container.name = "DialogueContainer"
	speaker_node.add_child(dialogue_container)
	
	# Create background
	var background = ColorRect.new()
	background.name = "Background"
	background.color = background_color
	dialogue_container.add_child(background)
	
	# Create text display
	var text_display = HandwrittenLabel.new()
	text_display.name = "HandwrittenLabel"
	dialogue_container.add_child(text_display)
	
	# Set the handwritten text
	text_display.set_handwritten_text("dialogue", dialogue_key)
	
	# Use the HandwrittenLabel's size with scaling
	var label_size = text_display.custom_minimum_size
	var scaled_size = label_size * scale_factor
	print("HandwrittenLabel size: ", label_size)
	print("Scale factor: ", scale_factor)
	print("Scaled size: ", scaled_size)
	
	# Resize the dialogue container to match the scaled label size
	dialogue_container.size = scaled_size
	print("Resized dialogue container to: ", dialogue_container.size)
	
	# Also resize the background to match
	background.size = scaled_size
	print("Resized background to: ", background.size)
	
	# Scale the text display
	text_display.scale = Vector2(scale_factor, scale_factor)
	print("Text display scale: ", text_display.scale)
	
	# Position dialogue above the speaker
	dialogue_container.position = Vector2(
		-(scaled_size.x / 2),  # Center horizontally on speaker
		-scaled_size.y - 20    # Position above speaker
	)
	
	# Show with animation
	dialogue_container.visible = true
	dialogue_container.modulate = Color.TRANSPARENT
	
	var tween = create_tween()
	tween.tween_property(dialogue_container, "modulate", Color.WHITE, 0.3)
	
	# Auto-hide after specified duration (for all dialogue except choice dialogue)
	get_tree().create_timer(fade_duration).timeout.connect(func(): 
		var hide_tween = create_tween()
		hide_tween.tween_property(dialogue_container, "modulate", Color.TRANSPARENT, 0.3)
		hide_tween.tween_callback(func(): dialogue_container.queue_free())
	)
	
	print("Dialogue display complete")

func hide_dialogue() -> void:
	if not is_showing:
		return
		
	var tween = create_tween()
	tween.tween_property(dialogue_container, "modulate", Color.TRANSPARENT, 0.3)
	tween.tween_callback(func(): dialogue_container.visible = false)
	
	is_showing = false

func position_dialogue_near_speaker(speaker_pos: Vector2) -> void:
	# Position dialogue bubble above and centered on the speaker
	# Since this is in the UI layer, we need to use viewport coordinates
	print("Speaker world position: ", speaker_pos)
	
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
	
	# OLD CODE (commented out):
	# # For UI elements, we can position relative to the viewport center
	# # Let's try positioning it at a fixed offset from the viewport center
	# var viewport_center = viewport_size / 2
	# var dialogue_pos = Vector2(
	# 	viewport_center.x - (dialogue_size.x / 2),  # Center horizontally in viewport
	# 	viewport_center.y - dialogue_size.y - 100   # Position above center with gap
	# )
	
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
	
	print("Viewport size: ", viewport_size)
	print("Viewport center: ", viewport_pos) # Changed from viewport_center to viewport_pos
	print("Dialogue positioned at: ", dialogue_pos)
	print("Dialogue container size: ", dialogue_container.size)
	print("Speaker position: ", speaker_pos)
	print("Text display position: ", text_display.position if text_display else "null")

# Check if dialogue system is interfering:
func say_dialogue(dialogue_key: String) -> void:
	print("=== DIALOGUE DEBUG ===")
	print("Looking for dialogue system...")
	
	var dialogue_system = get_tree().current_scene.find_child("SimpleDialogueSystem")
	if dialogue_system:
		print("Dialogue system found!")
		var dialogue_point = $DialoguePoint if has_node("DialoguePoint") else self
		dialogue_system.show_dialogue(dialogue_key, dialogue_point.global_position)
	else:
		print("ERROR: No dialogue system found")
		print("Current scene children: ")
		for child in get_tree().current_scene.get_children():
			print("  - ", child.name, " (", child.get_class(), ")")

func show_dialogue_with_choices(dialogue_key: String, choices: Array[Dictionary], speaker_node: Node = null, choice_speaker_position: Vector2 = Vector2.ZERO, background_color: Color = Color(1, 0.98, 0.8, 0.9)) -> void:
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
	print("=== SHOWING DIALOGUE MANUAL ===")
	print("Dialogue key: ", dialogue_key)
	print("Speaker node: ", speaker_node.name if speaker_node else "null")
	
	# If no speaker node provided, use the current scene
	if not speaker_node:
		speaker_node = get_tree().current_scene
	
	# Create dialogue as child of speaker
	var dialogue_container = Control.new()
	dialogue_container.name = "DialogueContainer"
	speaker_node.add_child(dialogue_container)
	
	# Create background
	var background = ColorRect.new()
	background.name = "Background"
	background.color = background_color
	dialogue_container.add_child(background)
	
	# Create text display
	var text_display = HandwrittenLabel.new()
	text_display.name = "HandwrittenLabel"
	dialogue_container.add_child(text_display)
	
	# Set the handwritten text
	text_display.set_handwritten_text("dialogue", dialogue_key)
	
	# Use the HandwrittenLabel's size with scaling
	var label_size = text_display.custom_minimum_size
	var scaled_size = label_size * scale_factor
	print("HandwrittenLabel size: ", label_size)
	print("Scale factor: ", scale_factor)
	print("Scaled size: ", scaled_size)
	
	# Resize the dialogue container to match the scaled label size
	dialogue_container.size = scaled_size
	print("Resized dialogue container to: ", dialogue_container.size)
	
	# Also resize the background to match
	background.size = scaled_size
	print("Resized background to: ", background.size)
	
	# Scale the text display
	text_display.scale = Vector2(scale_factor, scale_factor)
	print("Text display scale: ", text_display.scale)
	
	# Position dialogue above the speaker
	dialogue_container.position = Vector2(
		-(scaled_size.x / 2),  # Center horizontally on speaker
		-scaled_size.y - 20    # Position above speaker
	)
	
	# Show with animation
	dialogue_container.visible = true
	dialogue_container.modulate = Color.TRANSPARENT
	
	var tween = create_tween()
	tween.tween_property(dialogue_container, "modulate", Color.WHITE, 0.3)
	
	print("Dialogue display complete (manual - no auto-hide)")

func _on_choice_selected(choice_key: String) -> void:
	print("=== DIALOGUE CHOICE SELECTED ===")
	print("Choice key: ", choice_key)
	print("Choice UI found: ", choice_ui != null)
	
	# Hide the dialogue when a choice is made
	hide_dialogue()
	
	# Handle different choice responses
	match choice_key:
		"eat_cookies":
			print("Tess chose to eat cookies")
			trigger_cookie_effects()
		"drink_whiskey":
			print("Tess chose to drink whiskey")
			trigger_whiskey_effects()
		"cookies_and_whiskey":
			print("Tess chose cookies and whiskey")
			trigger_cookie_effects()
			trigger_whiskey_effects()
		"excuse_me":
			print("Tess chose to excuse the friend")
			trigger_excuse_friend_effects()
		"never_mind":
			print("Tess chose to do nothing")
		_:
			print("Unknown choice key: ", choice_key)

func trigger_cookie_effects() -> void:
	print("=== TRIGGERING COOKIE EFFECTS ===")
	# Cookie effects: comfort_value = 3.0 * 1.5 = 4.5
	var comfort_value = 4.5
	print("Cookie comfort value: ", comfort_value)
	
	# Consume a cookie from inventory
	if GameManager.consume_cookie():
		print("Tess feels comforted by the cookies")
	else:
		print("ERROR: No cookies available to consume")

func trigger_whiskey_effects() -> void:
	print("=== TRIGGERING WHISKEY EFFECTS ===")
	# Whiskey effects: healing_amount = 5.0 * 1.5 = 7.5
	var healing_amount = 7.5
	print("Whiskey healing amount: ", healing_amount)
	
	# Consume whiskey from inventory
	if GameManager.consume_whiskey():
		print("Tess feels warmed by the whiskey")
	else:
		print("ERROR: No whiskey available to consume")

func trigger_excuse_friend_effects() -> void:
	print("=== TRIGGERING EXCUSE FRIEND EFFECTS ===")
	
	# Find the friend and send them off screen
	var friend_nodes = get_tree().get_nodes_in_group("Friend")
	print("Found ", friend_nodes.size(), " friend nodes")
	
	if friend_nodes.size() > 0:
		var friend = friend_nodes[0]
		print("Friend name: ", friend.name)
		print("Friend has depart_from_screen method: ", friend.has_method("depart_from_screen"))
		
		if friend.has_method("depart_from_screen"):
			friend.depart_from_screen()
			print("Friend is departing from screen")
		else:
			print("ERROR: Friend doesn't have depart_from_screen method")
	else:
		print("ERROR: No friend found in scene")
		print("Available groups: ", get_tree().get_nodes_in_group("Friend"))

# Test function to manually trigger excuse me
func test_excuse_me() -> void:
	print("=== TESTING EXCUSE ME MANUALLY ===")
	trigger_excuse_friend_effects()
