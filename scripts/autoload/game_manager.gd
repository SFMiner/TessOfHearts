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


func add_collectable(collectable_type : int) -> void:
	match collectable_type:
		0 : GameData.num_hearts_whole  += 1
		1 : GameData.num_hearts_2third  += 1
		2 : GameData.num_hearts_half  += 1
		3 : GameData.num_hearts_1third  += 1
		4 : GameData.num_whiskey  += 1
		5 : GameData.num_cookies  += 1
		6 : GameData.num_sutures  += 1
		7 : GameData.num_tape  += 1
		8 : GameData.num_barbed_wire  += 1
		9 : GameData.num_gold += 1
	update_collectables()

func spend_collectable(collectable_type : int) -> void:
	match collectable_type:
		"hearts_whole" : GameData.num_hearts_whole  -= 1
		"hearts_2third"  : GameData.num_hearts_2third  -= 1
		"hearts_half"  : GameData.num_hearts_half  -= 1
		"hearts_2third"  : GameData.num_hearts_1third  -= 1
		"whiskey"  : GameData.num_whiskey  -= 1
		"cookies"  : GameData.num_cookies  -= 1
		"sutures"  : GameData.num_sutures  -= 1
		"tape"  : GameData.num_tape  -= 1
		"barbed_wire"  : GameData.num_barbed_wire  -= 1
		"gold"  : GameData.num_gold  -= 1
	update_collectables()

func update_collectables():
	get_main().GameHUD.set_inventory()


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

func get_main() -> Node2D:
	return get_tree().get_root().get_node("Main")	
	
func get_tess() -> Node2D:
	return get_tree().get_nodes_in_group("Tess")[0]
