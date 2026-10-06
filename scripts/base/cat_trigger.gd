# ===========================================
# CAT TRIGGER SYSTEM
# ===========================================

extends Node
class_name CatTrigger

@export var cat_scene: PackedScene
@export var spawn_position: Vector2
@export var trigger_condition: String = ""

var spawned_cat: GuideCat

# Connect heart_collected signal to check if guide cat should appear
func _ready() -> void:
	# Connect to game events
	if GameManager:
		GameManager.heart_collected.connect(_on_heart_collected)

# When any heart is collected, check if the cat spawn condition is now met
func _on_heart_collected(heart_data: Dictionary) -> void:
	check_spawn_condition()

# If the required number of hearts has been collected, spawn the guide cat
func check_spawn_condition() -> void:
	if spawned_cat or not cat_scene:
		return
	
	# Check if condition is met
	var should_spawn = false
	
	if trigger_condition == "":
		should_spawn = true
	elif trigger_condition.begins_with("hearts >="):
		var required = int(trigger_condition.split(" ")[2])
		should_spawn = GameManager.get_collected_hearts_count() >= required
	
	if should_spawn:
		spawn_cat()

# Instantiate the guide cat scene and add it to the current scene at the configured position
func spawn_cat() -> void:
	spawned_cat = cat_scene.instantiate()
	spawned_cat.global_position = spawn_position
	get_parent().add_child(spawned_cat)
	print("Cat triggered and spawned")

# ===========================================
# SIMPLE NODE STRUCTURE
# ===========================================

# GuideCat (Node2D) [GuideCat.gd extends Interactable]
# ├── Sprite2D [cat sprite]
# ├── AnimationPlayer [idle, speak animations]
# ├── Area2D [inherited from Interactable]
# │   └── CollisionShape2D
# └── (other Interactable components)
