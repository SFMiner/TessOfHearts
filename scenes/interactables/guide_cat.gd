# ===========================================
# GUIDE CAT - SIMPLE INTERACTABLE
# ===========================================

extends Interactable
class_name GuideCat

@export var cat_name: String = "Guide Cat"
@export var dialogue_key: String = "cat_default"
@export var trigger_condition: String = ""  # e.g. "hearts >= 3"
@export var vanish_after_interaction: bool = true

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var has_appeared: bool = false
var has_been_interacted: bool = false

func _ready() -> void:
	interaction_type = "guide_cat"
	super._ready()
	
	# Start hidden
	visible = false
	can_interact = false
	
	# Check if should appear
	check_trigger_condition()

func setup_visual() -> void:
	# Cats use sprite animations, not ColorRect
	pass

func check_trigger_condition() -> void:
	if trigger_condition == "":
		# No condition, appear immediately
		appear()
		return
	
	# Parse simple conditions
	if trigger_condition.begins_with("hearts >="):
		var required = int(trigger_condition.split(" ")[2])
		if GameManager.get_collected_hearts_count() >= required:
			appear()
	elif trigger_condition == "on_room_enter":
		appear()

func appear() -> void:
	if has_appeared:
		return
		
	print("Cat appearing: ", cat_name)
	has_appeared = true
	visible = true
	can_interact = true
	
	# Appear animation
	modulate = Color.TRANSPARENT
	scale = Vector2(0.8, 0.8)
	
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.5)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.5)
	
	# Start idle animation
	if animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")

func vanish() -> void:
	print("Cat vanishing: ", cat_name)
	can_interact = false
	
	# Vanish animation
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate", Color.TRANSPARENT, 0.4)
	tween.parallel().tween_property(self, "scale", Vector2(0.8, 0.8), 0.4)
	tween.tween_callback(func(): visible = false)

func handle_interaction() -> void:
	if has_been_interacted:
		return
		
	print("Cat interaction: ", cat_name)
	has_been_interacted = true
	
	# Show dialogue
	var dialogue_system = get_tree().current_scene.find_child("DialogueSystem")
	if dialogue_system:
		dialogue_system.show_dialogue(dialogue_key, global_position)
	
	# Brief animation
	if animation_player and animation_player.has_animation("speak"):
		animation_player.play("speak")
	
	# Vanish after interaction if set
	if vanish_after_interaction:
		get_tree().create_timer(2.0).timeout.connect(vanish)
