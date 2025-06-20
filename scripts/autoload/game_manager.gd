# ===========================================
# SCRIPTS/AUTOLOAD/GAMEMANAGER.GD
# ===========================================

extends Node

signal game_state_changed(new_state: GameState)
signal heart_collected(heart_data: Dictionary)
signal area_unlocked(area_name: String)

enum GameState {
	EXPLORING,
	INTERACTING,
	DIALOGUE,
	INVENTORY,
	TRANSITION
}

var current_state: GameState = GameState.EXPLORING
var collected_hearts: Array[Dictionary] = []
var current_area: String = "bathhouse_entry"
var player_position: Vector2
var unlocked_areas: Array[String] = ["bathhouse_entry"]

@onready var tess_reference: Node2D

func _ready() -> void:
	print("GameManager initialized - Gather Hearts")

func change_state(new_state: GameState) -> void:
	if current_state != new_state:
		current_state = new_state
		game_state_changed.emit(new_state)
		print("Game state changed to: ", GameState.keys()[new_state])

func collect_heart(heart_data: Dictionary) -> void:
	collected_hearts.append(heart_data)
	heart_collected.emit(heart_data)
	print("Heart collected: ", heart_data.get("type", "unknown"))

func unlock_area(area_name: String) -> void:
	if area_name not in unlocked_areas:
		unlocked_areas.append(area_name)
		area_unlocked.emit(area_name)
		print("Area unlocked: ", area_name)

func get_collected_hearts_count() -> int:
	return collected_hearts.size()

func has_heart_type(heart_type: String) -> bool:
	for heart in collected_hearts:
		if heart.get("type") == heart_type:
			return true
	return false

func debug_game_state() -> void:
	print("=== GAME STATE DEBUG ===")
	if GameManager:
		print("Current game state: ", GameManager.current_state)
		print("GameState enum values: ", GameManager.GameState)
	else:
		print("ERROR: GameManager not found!")
