# ===========================================
# DIALOGUE CHOICE UI - MULTIPLE CHOICE DIALOGUE
# ===========================================

extends Control
class_name DialogueChoiceUI

signal choice_selected(choice_key: String)

@onready var choice_container: VBoxContainer = $ChoiceContainer
@onready var background: ColorRect = $Background

var choice_buttons: Array[Button] = []
var is_showing: bool = false

func _ready() -> void:
	print("=== DIALOGUE CHOICE UI SETUP ===")
	add_to_group("dialogue_choice_ui")
	hide_choices()

func show_choices(choices: Array[Dictionary], speaker_position: Vector2 = Vector2.ZERO) -> void:
	print("=== SHOWING DIALOGUE CHOICES ===")
	print("Number of choices: ", choices.size())
	print("Speaker position: ", speaker_position)
	
	# Clear existing choice containers
	for child in choice_container.get_children():
		child.queue_free()
	choice_buttons.clear()
	
	# Create choice buttons with handwritten text
	for choice in choices:
		# Create container for this choice
		var choice_container = Control.new()
		choice_container.custom_minimum_size = Vector2(0, 0)
		
		# Create background
		var background = ColorRect.new()
		background.color = Color(1, 0.98, 0.8, 0.9)  # Same as regular dialogue system
		background.name = "Background"
		choice_container.add_child(background)
		
		# Create handwritten text sprite
		var sprite = TextureRect.new()
		sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.anchors_preset = Control.PRESET_TOP_LEFT
		sprite.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		sprite.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		# Load handwritten texture
		var texture_path = "res://assets/handwritten/dialogue/" + choice.get("texture", choice.get("key", "unknown")) + ".png"
		var texture = load(texture_path)
		if texture:
			sprite.texture = texture
			print("Loaded texture: ", texture_path)
			
			# Size the container to the image with margins (same as HandwrittenLabel)
			var image_size = texture.get_size()
			var margin = 20  # 20 pixel margin on all sides
			var container_size = image_size + Vector2(margin * 2, margin * 2)
			
			choice_container.custom_minimum_size = container_size
			background.size = container_size
			
			# Scale the sprite to 0.5 (same as regular dialogue system)
			sprite.scale = Vector2(0.5, 0.5)
			var scaled_image_size = image_size * 0.5
			
			# Set explicit size and position (use original size, let scale handle the reduction)
			sprite.size = image_size
			sprite.position = Vector2(margin, margin)
			
			# Use the same scaling approach as regular dialogue system
			choice_container.custom_minimum_size = scaled_image_size + Vector2(margin * 2, margin * 2)
			background.size = choice_container.custom_minimum_size
			
			print("Image size: ", image_size)
			print("Scaled image size: ", scaled_image_size)
			print("Container size: ", choice_container.custom_minimum_size)
			print("Sprite positioned at: ", sprite.position)
		else:
			print("WARNING: Could not load texture: ", texture_path)
			# Fallback to simple text for now
			choice_container.custom_minimum_size = Vector2(200, 50)
			background.size = Vector2(200, 50)
		
		# Set sprite to draw on top
		sprite.z_index = 1
		choice_container.add_child(sprite)
		
		# Create button overlay for interaction
		var button = Button.new()
		button.flat = true  # Make button transparent
		button.mouse_filter = Control.MOUSE_FILTER_STOP  # Stop clicks here
		button.size = choice_container.custom_minimum_size
		button.z_index = 2  # Draw on top of sprite
		
		# Ensure button is properly sized and positioned
		button.custom_minimum_size = choice_container.custom_minimum_size
		button.position = Vector2.ZERO
		
		# Connect button signal
		var choice_key = choice.get("key", "")
		print("Connecting button for choice: ", choice_key)
		print("Button size: ", button.size)
		print("Button custom_minimum_size: ", button.custom_minimum_size)
		print("Choice container size: ", choice_container.custom_minimum_size)
		button.pressed.connect(func(): _on_choice_selected(choice_key))
		
		choice_container.add_child(button)
		
		self.choice_container.add_child(choice_container)
		choice_buttons.append(button)
	
	# Position choices above speaker
	print("Speaker position for positioning: ", speaker_position)
	
	# Wait a frame to ensure all children are properly sized
	await get_tree().process_frame
	
	if speaker_position != Vector2.ZERO:
		position_choices_above_speaker(speaker_position)
	else:
		print("WARNING: No speaker position provided, positioning at center")
		# Fallback positioning at center
		var viewport_size = get_viewport().get_visible_rect().size
		var choice_size = choice_container.size
		var center_pos = Vector2(
			(viewport_size.x - choice_size.x) / 2,
			(viewport_size.y - choice_size.y) / 2
		)
		choice_container.global_position = center_pos
	
	# Show with animation
	visible = true
	modulate = Color(1, 1, 1, 1)  # Ensure full opacity
	
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.3)
	
	is_showing = true
	print("Dialogue choices displayed")
	
	# Add a test button to manually trigger excuse me
	add_test_button()

func add_test_button():
	# Create a test button to manually trigger excuse me
	var test_button = Button.new()
	test_button.text = "TEST: Excuse Me"
	test_button.position = Vector2(10, 10)
	test_button.size = Vector2(150, 30)
	add_child(test_button)
	
	test_button.pressed.connect(func():
		print("=== TEST BUTTON PRESSED ===")
		_on_choice_selected("excuse_me")
	)

func position_choices_above_speaker(speaker_pos: Vector2) -> void:
	print("=== POSITIONING CHOICES ===")
	print("Speaker world position: ", speaker_pos)
	
	# Get the viewport size
	var viewport_size = get_viewport().get_visible_rect().size
	var choice_size = choice_container.size
	
	print("Choice container size before positioning: ", choice_size)
	print("Choice container children count: ", choice_container.get_child_count())
	
	# If choice size is zero, calculate it from children
	if choice_size == Vector2.ZERO:
		var total_height = 0
		var max_width = 0
		for child in choice_container.get_children():
			if child is Control:
				total_height += child.custom_minimum_size.y
				max_width = max(max_width, child.custom_minimum_size.x)
		choice_size = Vector2(max_width, total_height)
		print("Calculated choice size from children: ", choice_size)
	
	# Position relative to viewport center (like regular dialogue system)
	var viewport_center = viewport_size / 2
	var choice_pos = Vector2(
		viewport_center.x - (choice_size.x / 2) + 200,  # Center horizontally + 200px right
		viewport_center.y - choice_size.y - 100 + 50     # Position above center with gap + 50px lower
	)
	
	# Ensure choices stay within viewport bounds
	choice_pos.x = clamp(choice_pos.x, 0, viewport_size.x - choice_size.x)
	choice_pos.y = clamp(choice_pos.y, 0, viewport_size.y - choice_size.y)
	
	# Set position of the choice container
	choice_container.global_position = choice_pos
	
	print("Viewport size: ", viewport_size)
	print("Viewport center: ", viewport_center)
	print("Final choice size: ", choice_size)
	print("Choice positioned at: ", choice_pos)

func hide_choices() -> void:
	if not is_showing:
		return
		
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.3)
	tween.tween_callback(func(): visible = false)
	
	is_showing = false

func get_choice_buttons() -> Array[Button]:
	return choice_buttons

func _on_choice_selected(choice_key: String) -> void:
	print("=== CHOICE SELECTED ===")
	print("Choice key: ", choice_key)
	print("Emitting choice_selected signal with key: ", choice_key)
	print("Choice UI visible: ", visible)
	print("Choice container visible: ", choice_container.visible)
	choice_selected.emit(choice_key)
	hide_choices()



func create_button_style(color: Color = Color.WHITE) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color.BLACK
	return style 
