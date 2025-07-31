# ===========================================
# CLICK DIALOGUE TRIGGER - CLICK TO TALK
# ===========================================
extends Area2D
class_name ClickDialogueTrigger

@export var dialogue_key: String = "tess_what_is_it"
@export var trigger_once: bool = true

var has_triggered: bool = false
var dialogue_system: Node

func _ready() -> void:
	print("=== CLICK DIALOGUE TRIGGER SETUP ===")
	print("Dialogue key: ", dialogue_key)
	print("Trigger once: ", trigger_once)
	add_to_group("dialogue_trigger")

	# Find dialogue system in scene
	dialogue_system = get_tree().current_scene.find_child("DialogueSystem")
	if not dialogue_system:
		print("ERROR: No dialogue system found in scene")
		return

	# Connect input event
	connect("input_event", Callable(self, "_on_input_event"))
	print("Click dialogue trigger setup complete")

func _on_input_event(viewport, event, shape_idx):
	print("=== CLICK DIALOGUE TRIGGER INPUT EVENT ===")
	print("Event type: ", event.get_class())
	print("Event pressed: ", event.pressed if event.has_method("pressed") else "N/A")
	print("Event button: ", event.button_index if event.has_method("button_index") else "N/A")
	
	if not dialogue_system:
		print("ERROR: No dialogue system available")
		return
	if trigger_once and has_triggered:
		print("Dialogue already triggered once, ignoring")
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("=== CLICK DIALOGUE TRIGGER ACTIVATED ===")
		print("Dialogue key: ", dialogue_key)
		dialogue_system.show_dialogue(dialogue_key, self)
		has_triggered = true
	elif event is InputEventScreenTouch and event.pressed:
		print("=== CLICK DIALOGUE TRIGGER ACTIVATED (TOUCH) ===")
		print("Dialogue key: ", dialogue_key)
		dialogue_system.show_dialogue(dialogue_key, self)
		has_triggered = true 
