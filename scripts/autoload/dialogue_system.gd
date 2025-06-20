extends Control
class_name SimpleDialogueSystem

@onready var dialogue_container: Control = %DialogueContainer
@onready var text_display: HandwrittenLabel 
@onready var background: ColorRect = $DialogueContainer/Background

var is_showing: bool = false

func _ready() -> void:
	if not dialogue_container:
		setup_dialogue_container()
	text_display = dialogue_container.get_node_or_null("TextDisplay")
	hide_dialogue()

func setup_dialogue_container() -> void:
	dialogue_container = Control.new()
	add_child(dialogue_container)
	
	# Create background
	background = ColorRect.new()
	background.color = Color("#FFFACD", 0.9)  # Post-it yellow
	dialogue_container.add_child(background)
	
	# Create text display
	text_display = HandwrittenLabel.new()
	dialogue_container.add_child(text_display)

func show_dialogue(dialogue_key: String, speaker_position: Vector2 = Vector2.ZERO) -> void:
	print("Showing dialogue: ", dialogue_key)
	
	# Set the handwritten text
	text_display.set_handwritten_text("dialogue", dialogue_key)
	
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

func hide_dialogue() -> void:
	if not is_showing:
		return
		
	var tween = create_tween()
	tween.tween_property(dialogue_container, "modulate", Color.TRANSPARENT, 0.3)
	tween.tween_callback(func(): dialogue_container.visible = false)
	
	is_showing = false

func position_dialogue_near_speaker(speaker_pos: Vector2) -> void:
	# Position dialogue bubble above and to the side of speaker
	dialogue_container.global_position = speaker_pos + Vector2(50, -100)

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
