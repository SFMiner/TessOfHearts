# ===========================================
# DIALOGUE TRIGGER - SIMPLE AREA2D TRIGGER
# ===========================================

extends Area2D
class_name DialogueTrigger

@export var dialogue_key: String = "tess_what_is_it"
@export var trigger_once: bool = true
@export var trigger_distance: float = 100.0
@export var fade_duration: float = 5.0

var has_triggered: bool = false
var dialogue_system: Node

const scr_debug : bool =  false
var debug : bool

func _ready() -> void:
	debug = scr_debug or GameData.sys_debug
	if debug: 
		print("=== DIALOGUE TRIGGER SETUP ===")
		print("Dialogue key: ", dialogue_key)
		print("Trigger once: ", trigger_once)
		print("Trigger distance: ", trigger_distance)
		
	# Find dialogue system in scene
	dialogue_system = get_tree().current_scene.find_child("DialogueSystem")
	if not dialogue_system:
		print("ERROR: No dialogue system found in scene")
		return
	
	# Connect to body entered signal
	body_entered.connect(_on_body_entered)
	
	# Set collision detection for Tess (layer 2)
	collision_layer = 0  # Don't collide with anything
	collision_mask = 2   # Only detect Tess (layer 2)
	
	if debug: print("Dialogue trigger setup complete")

func _on_body_entered(body: Node2D) -> void:
	if not dialogue_system:
		if debug: print("ERROR: No dialogue system available")
		return
		
	if trigger_once and has_triggered:
		if debug: print("Dialogue already triggered once, ignoring")
		return
		
	# Check if it's Tess
	if body.is_in_group("Player") or body.name == "Tess":
		if debug: 
			print("=== DIALOGUE TRIGGER ACTIVATED ===")
			print("Speaker: ", body.name)
			print("Dialogue key: ", dialogue_key)
			print("Speaker position: ", body.global_position)
		
		# Show dialogue positioned at the trigger area (not moving with the character)
		dialogue_system.show_dialogue(dialogue_key, self, Color(1, 0.98, 0.8, 0.9), 0.25, fade_duration)
		
		has_triggered = true
		
		if trigger_once:
			if debug: print("Dialogue triggered once, disabling trigger")
			# Optionally disable the trigger
			# queue_free() 
