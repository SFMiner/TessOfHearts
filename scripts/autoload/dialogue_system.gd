extends Control
class_name SimpleDialogueSystem

@onready var dialogue_container: Control = %DialogueContainer
@onready var text_display: HandwrittenLabel = %HandwrittenLabel
@onready var background: ColorRect = %Background

var is_showing: bool = false

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

func show_dialogue(dialogue_key: String, speaker_position: Vector2 = Vector2.ZERO) -> void:
	print("=== SHOWING DIALOGUE ===")
	print("Dialogue key: ", dialogue_key)
	print("Speaker position: ", speaker_position)
	
	# Ensure we have the text display
	if not text_display:
		print("ERROR: text_display is null! Trying to find it again...")
		text_display = dialogue_container.get_node_or_null("HandwrittenLabel")
		if not text_display:
			print("ERROR: Still can't find HandwrittenLabel, creating new one")
			text_display = HandwrittenLabel.new()
			text_display.name = "HandwrittenLabel"
			dialogue_container.add_child(text_display)
	
	# Set the handwritten text
	if text_display:
		print("text_display found, setting text...")
		text_display.set_handwritten_text("dialogue", dialogue_key)
		
		# Use the HandwrittenLabel's size (which includes margins) and scale it down
		var label_size = text_display.custom_minimum_size
		var scaled_size = label_size * 0.5  # Scale to half size
		print("HandwrittenLabel size: ", label_size)
		print("Scaled size: ", scaled_size)
		
		# Resize the dialogue container to match the scaled label size
		dialogue_container.size = scaled_size
		print("Resized dialogue container to: ", dialogue_container.size)
		
		# Also resize the background to match
		if background:
			background.size = scaled_size
			print("Resized background to: ", background.size)
		
		# Scale the text display to match
		text_display.scale = Vector2(0.5, 0.5)
		print("Scaled text display to: ", text_display.scale)
	else:
		print("ERROR: text_display is still null!")
		return
	
	# Position near speaker
	if speaker_position != Vector2.ZERO:
		position_dialogue_near_speaker(speaker_position)
	
	# Show with animation
	dialogue_container.visible = true
	dialogue_container.modulate = Color.TRANSPARENT
	
	var tween = create_tween()
	tween.tween_property(dialogue_container, "modulate", Color.WHITE, 0.3)
	
	is_showing = true
	
	# Auto-hide after a few seconds
	get_tree().create_timer(3.0).timeout.connect(hide_dialogue)
	
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
	
	# For UI elements, we can position relative to the viewport center
	# Let's try positioning it at a fixed offset from the viewport center
	var viewport_center = viewport_size / 2
	var dialogue_pos = Vector2(
		viewport_center.x - (dialogue_size.x / 2),  # Center horizontally in viewport
		viewport_center.y - dialogue_size.y - 100   # Position above center with gap
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
	
	print("Viewport size: ", viewport_size)
	print("Viewport center: ", viewport_center)
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
