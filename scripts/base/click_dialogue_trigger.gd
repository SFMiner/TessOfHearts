# ===========================================
# CLICK DIALOGUE TRIGGER - CLICK TO TALK
# ===========================================
extends Area2D
class_name ClickDialogueTrigger

@export var dialogue_key: String = "tess_what_is_it"
@export var trigger_once: bool = true

var has_triggered: bool = false
var dialogue_system: Node

const scr_debug : bool =  false
var debug : bool

func _ready() -> void:
	debug = scr_debug or GameData.sys_debug

	if debug: 
		print("=== CLICK DIALOGUE TRIGGER SETUP ===")
		print("Dialogue key: ", dialogue_key)
		print("Trigger once: ", trigger_once)
	add_to_group("dialogue_trigger")

	# Find dialogue system in scene
	dialogue_system = get_tree().current_scene.find_child("DialogueSystem")
	if not dialogue_system:
		if debug: print("ERROR: No dialogue system found in scene")
		return

	# Connect input event
	connect("input_event", Callable(self, "_on_input_event"))
	if debug: print("Click dialogue trigger setup complete")

func _on_input_event(viewport, event, shape_idx):
	if debug: 
		print("=== CLICK DIALOGUE TRIGGER INPUT EVENT ===")
		print("Event type: ", event.get_class())
		print("Event pressed: ", event.pressed if event.has_method("pressed") else "N/A")
		print("Event button: ", event.button_index if event.has_method("button_index") else "N/A")
	
	if not dialogue_system:
		if debug: print("ERROR: No dialogue system available")
		return
	if trigger_once and has_triggered:
		if debug: print("Dialogue already triggered once, ignoring")
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if debug: print("=== CLICK DIALOGUE TRIGGER ACTIVATED ===")
		if debug: print("Dialogue key: ", dialogue_key)
		dialogue_system.show_dialogue(dialogue_key, self)
		has_triggered = true
	elif event is InputEventScreenTouch and event.pressed:
		if debug: print("=== CLICK DIALOGUE TRIGGER ACTIVATED (TOUCH) ===")
		if debug: print("Dialogue key: ", dialogue_key)
		dialogue_system.show_dialogue(dialogue_key, self)
		has_triggered = true 
