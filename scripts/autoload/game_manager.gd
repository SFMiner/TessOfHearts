# ===========================================
# SCRIPTS/AUTOLOAD/GAMEMANAGER.GD
# ===========================================

extends Node

const scr_debug : bool = false 
var debug : bool


signal game_state_changed(new_state: GameState)
signal heart_collected(heart_data: Dictionary)
signal area_unlocked(area_name: String)
signal energy_changed(current_energy: int, max_energy: int)

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
	debug = scr_debug or GameData.sys_debug
	if debug: print("GameManager initialized - Gather Hearts")

func get_energy():
	return GameData.cur_energy

func get_courage():
	return GameData.cur_courage

func add_energy(amt : int):
	GameData.cur_energy += floor(amt)
	if GameData.cur_energy > 100:
		GameData.cur_energy = 100
	energy_changed.emit(GameData.cur_energy, GameData.max_energy)

func add_courage(amt : int):
	GameData.cur_courage += floor(amt)
	if GameData.cur_courage > 100:
		GameData.cur_courage = 100

func spend_energy(amt : int):
	GameData.cur_energy -= floor(amt)
	if GameData.cur_energy < 0:
		GameData.cur_energy = 0
	energy_changed.emit(GameData.cur_energy, GameData.max_energy)

func spend_courage(amt : int):
	GameData.cur_courage -= floor(amt)
	if GameData.cur_courage > 0:
		GameData.cur_courage = 0


	
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

func spend_collectable(collectable_type : int, amount : int = 1) -> void:
	match collectable_type:
		0 : GameData.num_hearts_whole  -= amount
		1 : GameData.num_hearts_2third  -= amount
		2 : GameData.num_hearts_half  -= amount
		3 : GameData.num_hearts_1third  -= amount
		4 : GameData.num_whiskey  -= amount
		5 : GameData.num_cookies  -= amount
		6 : GameData.num_sutures  -= amount
		7 : GameData.num_tape  -= amount
		8 : GameData.num_barbed_wire  -= amount
		9 : GameData.num_gold -= amount
	update_collectables()

func update_collectables():
	get_main().game_hud.set_inventory()
	get_main().game_hud.update_energy_display()


func change_state(new_state: GameState) -> void:
	if current_state != new_state:
		current_state = new_state
		game_state_changed.emit(new_state)
		if debug: print("Game state changed to: ", GameState.keys()[new_state])

func collect_heart(heart_data: Dictionary) -> void:
	collected_hearts.append(heart_data)
	heart_collected.emit(heart_data)
	if debug: print("Heart collected: ", heart_data.get("type", "unknown"))

func unlock_area(area_name: String) -> void:
	if area_name not in unlocked_areas:
		unlocked_areas.append(area_name)
		area_unlocked.emit(area_name)
		if debug: print("Area unlocked: ", area_name)

func get_collected_hearts_count() -> int:
	return collected_hearts.size()

func has_heart_type(heart_type: String) -> bool:
	for heart in collected_hearts:
		if heart.get("type") == heart_type:
			return true
	return false

func debug_game_state() -> void:
	if debug: 
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

func reset_energy() -> void:
	GameData.cur_energy = GameData.max_energy
	energy_changed.emit(GameData.cur_energy, GameData.max_energy)
	if debug: print("Energy reset to: ", GameData.cur_energy)

func consume_cookie() -> bool:
	if GameData.num_cookies > 0:
		spend_collectable(5)  # 5 = cookies
		add_energy(30)  # Cookies restore 20 energy
		if debug: print("Cookie consumed! +20 energy. Remaining cookies: ", GameData.num_cookies)
		return true
	else:
		if debug: print("No cookies available to consume")
		return false

func consume_whiskey() -> bool:
	if GameData.num_whiskey > 0:
		spend_collectable(4)  # 1 = whiskey
		add_courage(30)  # Whiskey restores 30 courage
		if debug: print("Whiskey consumed! +20 courage. Remaining whiskey: ", GameData.num_whiskey)
		return true
	else:
		print("No whiskey available to consume")
		return false

func can_consume_cookie() -> bool:
	return GameData.num_cookies > 0

func can_consume_whiskey() -> bool:
	return GameData.num_whiskey > 0

# Heart crafting functions
func craft_heart_with_tape() -> bool:
	# Check if we have tape and can make a whole heart
	if GameData.num_tape <= 0:
		if debug: print("No tape available for heart crafting")
		return false
	
	# Try different combinations to make a whole heart
	if GameData.num_hearts_half >= 2:
		# 2 half hearts = 1 whole heart
		spend_collectable(2, 2)  # Spend 2 half hearts
		spend_collectable(7, 1)  # Spend 1 tape
		GameData.num_tape_hearts += 1
		update_collectables()
		if debug: print("Crafted tape heart from 2 half hearts!")
		return true
	elif GameData.num_hearts_2third >= 1 and GameData.num_hearts_1third >= 1:
		# 1 2/3 heart + 1 1/3 heart = 1 whole heart
		spend_collectable(1, 1)  # Spend 1 2/3 heart
		spend_collectable(3, 1)  # Spend 1 1/3 heart
		spend_collectable(7, 1)  # Spend 1 tape
		GameData.num_tape_hearts += 1
		update_collectables()
		if debug: print("Crafted tape heart from 2/3 + 1/3 hearts!")
		return true
	elif GameData.num_hearts_1third >= 3:
		# 3 1/3 hearts = 1 whole heart
		spend_collectable(3, 3)  # Spend 3 1/3 hearts
		spend_collectable(7, 1)  # Spend 1 tape
		GameData.num_tape_hearts += 1
		update_collectables()
		if debug: print("Crafted tape heart from 3 1/3 hearts!")
		return true
	else:
		if debug: print("Not enough heart pieces to craft with tape")
		return false

func craft_heart_with_barbed_wire() -> bool:
	# Check if we have barbed wire and can make a whole heart
	if GameData.num_barbed_wire <= 0:
		if debug: print("No barbed wire available for heart crafting")
		return false
	
	# Try different combinations to make a whole heart
	if GameData.num_hearts_half >= 2:
		# 2 half hearts = 1 whole heart
		spend_collectable(2, 2)  # Spend 2 half hearts
		spend_collectable(8, 1)  # Spend 1 barbed wire
		GameData.num_wire_hearts += 1
		update_collectables()
		if debug: print("Crafted wire heart from 2 half hearts!")
		return true
	elif GameData.num_hearts_2third >= 1 and GameData.num_hearts_1third >= 1:
		# 1 2/3 heart + 1 1/3 heart = 1 whole heart
		spend_collectable(1, 1)  # Spend 1 2/3 heart
		spend_collectable(3, 1)  # Spend 1 1/3 heart
		spend_collectable(8, 1)  # Spend 1 barbed wire
		GameData.num_wire_hearts += 1
		update_collectables()
		if debug: print("Crafted wire heart from 2/3 + 1/3 hearts!")
		return true
	elif GameData.num_hearts_1third >= 3:
		# 3 1/3 hearts = 1 whole heart
		spend_collectable(3, 3)  # Spend 3 1/3 hearts
		spend_collectable(8, 1)  # Spend 1 barbed wire
		GameData.num_wire_hearts += 1
		update_collectables()
		if debug: print("Crafted wire heart from 3 1/3 hearts!")
		return true
	else:
		if debug: print("Not enough heart pieces to craft with barbed wire")
		return false

func craft_heart_with_sutures() -> bool:
	# Check if we have sutures and can make a whole heart
	if GameData.num_sutures <= 0:
		if debug: print("No sutures available for heart crafting")
		return false
	
	# Try different combinations to make a whole heart
	if GameData.num_hearts_half >= 2:
		# 2 half hearts = 1 whole heart
		spend_collectable(2, 2)  # Spend 2 half hearts
		spend_collectable(6, 1)  # Spend 1 sutures
		GameData.num_sewn_hearts += 1
		update_collectables()
		if debug: print("Crafted sewn heart from 2 half hearts!")
		return true
	elif GameData.num_hearts_2third >= 1 and GameData.num_hearts_1third >= 1:
		# 1 2/3 heart + 1 1/3 heart = 1 whole heart
		spend_collectable(1, 1)  # Spend 1 2/3 heart
		spend_collectable(3, 1)  # Spend 1 1/3 heart
		spend_collectable(6, 1)  # Spend 1 sutures
		GameData.num_sewn_hearts += 1
		update_collectables()
		print("Crafted sewn heart from 2/3 + 1/3 hearts!")
		return true
	elif GameData.num_hearts_1third >= 3:
		# 3 1/3 hearts = 1 whole heart
		spend_collectable(3, 3)  # Spend 3 1/3 hearts
		spend_collectable(6, 1)  # Spend 1 sutures
		GameData.num_sewn_hearts += 1
		update_collectables()
		if debug: print("Crafted sewn heart from 3 1/3 hearts!")
		return true
	else:
		if debug: print("Not enough heart pieces to craft with sutures")
		return false

# Check if crafting is possible with each material
func can_craft_with_tape() -> bool:
	return GameData.num_tape > 0 and (GameData.num_hearts_half >= 2 or 
		(GameData.num_hearts_2third >= 1 and GameData.num_hearts_1third >= 1) or 
		GameData.num_hearts_1third >= 3)

func can_craft_with_barbed_wire() -> bool:
	return GameData.num_barbed_wire > 0 and (GameData.num_hearts_half >= 2 or 
		(GameData.num_hearts_2third >= 1 and GameData.num_hearts_1third >= 1) or 
		GameData.num_hearts_1third >= 3)

func can_craft_with_sutures() -> bool:
	return GameData.num_sutures > 0 and (GameData.num_hearts_half >= 2 or 
		(GameData.num_hearts_2third >= 1 and GameData.num_hearts_1third >= 1) or 
		GameData.num_hearts_1third >= 3)

# === Memory Minigame Begin ===
func start_memory_minigame() -> void:
	GameData.memory_mini_current_level = 0
	GameData.memory_mini_passed = false
	if debug: print("Memory minigame started")

func complete_memory_minigame_level() -> void:
	GameData.memory_mini_current_level += 1
	if GameData.memory_mini_current_level >= GameData.memory_mini_total_levels:
		GameData.memory_mini_passed = true
		if debug: print("Memory minigame completed successfully!")
	else:
		if debug: print("Memory minigame level ", GameData.memory_mini_current_level, " completed")

func get_memory_minigame_progress() -> Dictionary:
	return {
		"current_level": GameData.memory_mini_current_level,
		"total_levels": GameData.memory_mini_total_levels,
		"passed": GameData.memory_mini_passed
	}

func is_memory_minigame_completed() -> bool:
	return GameData.memory_mini_passed
# === Memory Minigame End ===
