extends Control

@onready var unbroken_hearts_collected : Label = %WholeHearts
@onready var current_area : Label = %CurrentArea
@onready var energy_display : Label = %EnergyDisplay
@onready var courage_display : Label = %CourageDisplay
@onready var inventory : VBoxContainer = %Inventory
@onready var broken_hearts_collected : Label = %HeartsCollected
@onready var tape_collected : Label = %TapeCollected
@onready var sutures_collected : Label = %SuturesCollected
@onready var barbed_wire_collected : Label = %BarbedWireCollected
@onready var gold_collected : Label = %GoldCollected
@onready var cookies_collected : Label = %CookiesCollected
@onready var whiskey_collected : Label = %WhiskeyCollected

@onready var tape_hearts : Label = %TapeHearts
@onready var sewn_hearts : Label = %SewnHearts
@onready var wire_hearts : Label = %WireHearts
@onready var scarred_hearts : Label = %ScarredHearts
@onready var scarred_tape_hearts : Label = %ScarredTapeHearts
@onready var scarred_sewn_hearts : Label = %ScarredSewnHearts
@onready var scarred_wire_hearts : Label = %ScarredWireHearts
@onready var kintsugi_hearts : Label = %KintsugiHearts
# Consumption buttons
@onready var consume_cookie_button : Button = %ConsumeCookieButton
@onready var consume_whiskey_button : Button = %ConsumeWhiskeyButton

# Heart crafting buttons
@onready var craft_tape_heart_button : Button = %CraftTapeHeartButton
@onready var craft_wire_heart_button : Button = %CraftWireHeartButton
@onready var craft_sewn_heart_button : Button = %CraftSewnHeartButton

const scr_debug : bool = false 
var debug : bool

func _ready() -> void:
	debug = scr_debug or GameData.sys_debug
	update_energy_display()
	update_courage_display()
	setup_consumption_buttons()
	setup_ui_groups()
	
	# Connect to energy changes if GameManager is available
	if GameManager:
		GameManager.energy_changed.connect(_on_energy_changed)
		if debug: print("Connected to GameManager energy_changed signal")
	
	# Connect to courage changes
	if GameData:
		GameData.courage_changed.connect(_on_courage_changed)
		if debug: print("Connected to GameData courage_changed signal")
	ensure_ui_buttons_clickable()
	mouse_filter = Control.MOUSE_FILTER_PASS  # This allows children to receive input, but parent can also process it
	
func _gui_input(event: InputEvent) -> void:
	# Consume any input that happens within the GameHUD area
	if event is InputEventMouseButton and event.pressed:
		print("GameHUD consumed mouse click - preventing movement")
		accept_event()  # Prevent event from reaching main.gd
	elif event is InputEventScreenTouch and event.pressed:
		print("GameHUD consumed touch - preventing movement")
		accept_event()  # Prevent event from reaching main.gd


func ensure_ui_buttons_clickable() -> void:
	# Force all UI buttons to have proper mouse filter settings
	var ui_buttons = [
		consume_cookie_button,
		consume_whiskey_button,
		craft_tape_heart_button,
		craft_wire_heart_button,
		craft_sewn_heart_button
	]
	for button in ui_buttons:
		if button:
			button.mouse_filter = Control.MOUSE_FILTER_STOP
			print("Ensured ", button.name, " is clickable")
	
	# Also ensure the main UI container doesn't block input
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	print("UI buttons accessibility ensured")

func set_inventory():
	unbroken_hearts_collected.text = "Unbroken Hearts: " + str(GameData.num_hearts_whole)
	var total_broken_hearts = (GameData.num_hearts_whole *2 / 3) + (GameData.num_hearts_half / 2) + (GameData.num_hearts_2third / 3)
	broken_hearts_collected.text = "Hearts: " + str(total_broken_hearts)
	tape_collected.text = "Tape: " + str(GameData.num_tape)
	sutures_collected.text = "Sutures: " + str(GameData.num_sutures)
	barbed_wire_collected.text = "Wire: " + str(GameData.num_barbed_wire)
	gold_collected.text = "Gold: " + str(GameData.num_gold)
	cookies_collected.text = "Cookies: " + str(GameData.num_cookies)
	whiskey_collected.text = "Whiskey: " + str(GameData.num_whiskey)
	
	# Update consumption buttons
	update_consumption_buttons()
	update_crafting_buttons()

func set_hearts():
	tape_hearts.text = "Tape Hearts: " + str(GameData.num_tape_hearts)
	sewn_hearts.text = "Sewn Hearts: " + str(GameData.num_sewn_hearts)
	wire_hearts.text = "Wire Hearts: " + str(GameData.num_wire_hearts)
	scarred_hearts.text = "   Scarred: " + str(GameData.num_scarred_hearts)
	scarred_tape_hearts.text = "   Tape: " + str(GameData.num_scarred_tape_hearts)
	scarred_sewn_hearts.text = "   Sewn: " + str(GameData.num_scarred_sewn_hearts)
	scarred_wire_hearts.text = "   Wire: " + str(GameData.num_scarred_wire_hearts)
	kintsugi_hearts.text = "Kintsugi: " + str(GameData.num_kintsugi_hearts)


func update_energy_display() -> void:
	var current_energy = GameManager.get_energy()
	var max_energy = GameData.max_energy
	
	# Color code the energy display based on level
	var energy_color = Color.WHITE
	if current_energy <= 25:
		energy_color = Color.RED
	elif current_energy <= 50:
		energy_color = Color.YELLOW
	
	energy_display.text = "Energy: " + str(current_energy) + "/" + str(max_energy)
	energy_display.modulate = energy_color
	
	if debug: print("Energy display updated: ", current_energy, "/", max_energy)

func _on_energy_changed(current_energy: int, max_energy: int) -> void:
	update_energy_display()
	if debug: print("Energy changed signal received: ", current_energy, "/", max_energy)

func update_courage_display() -> void:
	var current_courage = GameData.cur_courage
	var max_courage = GameData.max_courage
	
	# Color code the courage display based on level
	var courage_color = Color.WHITE
	if current_courage <= 25:
		courage_color = Color.RED
	elif current_courage <= 50:
		courage_color = Color.YELLOW
	
	courage_display.text = "Courage: " + str(current_courage) + "/" + str(max_courage)
	courage_display.modulate = courage_color
	
	if debug: print("Courage display updated: ", current_courage, "/", max_courage)

func _on_courage_changed(current_courage: int, max_courage: int) -> void:
	update_courage_display()
	if debug: print("Courage changed signal received: ", current_courage, "/", max_courage)

func setup_consumption_buttons() -> void:
	# Set up cookie consumption button
	if consume_cookie_button:
		consume_cookie_button.pressed.connect(_on_consume_cookie_pressed)
		consume_cookie_button.text = "Eat Cookie (+25 Energy)"
		consume_cookie_button.add_to_group("ui_buttons")
		consume_cookie_button.mouse_filter = Control.MOUSE_FILTER_STOP  # Ensure button can receive input
		update_consumption_buttons()
	
	# Set up whiskey consumption button
	if consume_whiskey_button:
		consume_whiskey_button.pressed.connect(_on_consume_whiskey_pressed)
		consume_whiskey_button.text = "Drink Whiskey (+30 Courage)"
		consume_whiskey_button.add_to_group("ui_buttons")
		consume_whiskey_button.mouse_filter = Control.MOUSE_FILTER_STOP  # Ensure button can receive input
		update_consumption_buttons()
	
	# Set up heart crafting buttons
	if craft_tape_heart_button:
		craft_tape_heart_button.pressed.connect(_on_craft_tape_heart_pressed)
		craft_tape_heart_button.text = "Craft Tape Heart"
		craft_tape_heart_button.add_to_group("ui_buttons")
		craft_tape_heart_button.mouse_filter = Control.MOUSE_FILTER_STOP  # Ensure button can receive input
		update_crafting_buttons()
	
	if craft_wire_heart_button:
		craft_wire_heart_button.pressed.connect(_on_craft_wire_heart_pressed)
		craft_wire_heart_button.text = "Craft Wire Heart"
		craft_wire_heart_button.add_to_group("ui_buttons")
		craft_wire_heart_button.mouse_filter = Control.MOUSE_FILTER_STOP  # Ensure button can receive input
		update_crafting_buttons()
	
	if craft_sewn_heart_button:
		craft_sewn_heart_button.pressed.connect(_on_craft_sewn_heart_pressed)
		craft_sewn_heart_button.text = "Craft Sewn Heart"
		craft_sewn_heart_button.add_to_group("ui_buttons")
		craft_sewn_heart_button.mouse_filter = Control.MOUSE_FILTER_STOP  # Ensure button can receive input
		update_crafting_buttons()

func update_consumption_buttons() -> void:
	if consume_cookie_button:
		var can_consume = GameManager.can_consume_cookie()
		consume_cookie_button.disabled = not can_consume
		consume_cookie_button.modulate = Color.WHITE if can_consume else Color.GRAY
		if debug: print("Cookie button - disabled: ", not can_consume, " mouse_filter: ", consume_cookie_button.mouse_filter)
	
	if consume_whiskey_button:
		var can_consume = GameManager.can_consume_whiskey()
		consume_whiskey_button.disabled = not can_consume
		consume_whiskey_button.modulate = Color.WHITE if can_consume else Color.GRAY
		if debug: print("Whiskey button - disabled: ", not can_consume, " mouse_filter: ", consume_whiskey_button.mouse_filter)

func update_crafting_buttons() -> void:
	if craft_tape_heart_button:
		craft_tape_heart_button.disabled = not GameManager.can_craft_with_tape()
		craft_tape_heart_button.modulate = Color.WHITE if GameManager.can_craft_with_tape() else Color.GRAY
	
	if craft_wire_heart_button:
		craft_wire_heart_button.disabled = not GameManager.can_craft_with_barbed_wire()
		craft_wire_heart_button.modulate = Color.WHITE if GameManager.can_craft_with_barbed_wire() else Color.GRAY
	
	if craft_sewn_heart_button:
		craft_sewn_heart_button.disabled = not GameManager.can_craft_with_sutures()
		craft_sewn_heart_button.modulate = Color.WHITE if GameManager.can_craft_with_sutures() else Color.GRAY

func _on_consume_cookie_pressed() -> void:
	# Stop any ongoing movement immediately
	stop_tess_movement()
	
	if GameManager.consume_cookie():
		update_consumption_buttons()
		if debug: print("Cookie consumed via button")

func _on_consume_whiskey_pressed() -> void:
	# Stop any ongoing movement immediately
	stop_tess_movement()
	
	if GameManager.consume_whiskey():
		update_consumption_buttons()
		if debug: print("Whiskey consumed via button")

func _on_craft_tape_heart_pressed() -> void:
	# Stop any ongoing movement immediately
	stop_tess_movement()
	
	if GameManager.craft_heart_with_tape():
		update_crafting_buttons()
		set_hearts()
		if debug: print("Tape Heart crafted via button")

func _on_craft_wire_heart_pressed() -> void:
	# Stop any ongoing movement immediately
	stop_tess_movement()
	
	if GameManager.craft_heart_with_barbed_wire():
		update_crafting_buttons()
		set_hearts()
		if debug: print("Wire Heart crafted via button")

func _on_craft_sewn_heart_pressed() -> void:
	# Stop any ongoing movement immediately
	stop_tess_movement()
	
	if GameManager.craft_heart_with_sutures():
		update_crafting_buttons()
		set_hearts()
		if debug: print("Sewn Heart crafted via button")

func stop_tess_movement() -> void:
	# Find Tess and stop her movement immediately
	var tess_nodes = get_tree().get_nodes_in_group("Tess")
	if tess_nodes.size() > 0:
		var tess = tess_nodes[0]
		if tess.has_method("stop_movement"):
			tess.stop_movement()
			if debug: print("Stopped Tess movement via UI button")
		else:
			# Fallback: set target to current position
			tess.target_position = tess.global_position
			tess.is_moving = false
			if debug: print("Stopped Tess movement via fallback method")

func setup_ui_groups() -> void:
	# Add any other UI elements to groups for click detection
	var settings_button = get_node_or_null("VBoxContainer2/InventoryContainer/Inventory/Settings")
	if settings_button:
		settings_button.add_to_group("ui_buttons")
		if debug: print("Settings button added to ui_buttons group")
	else:
		if debug: print("Settings button not found")
	
	# Debug: Check how many UI buttons are in the group
	var ui_buttons = get_tree().get_nodes_in_group("ui_buttons")
	if debug: print("Total UI buttons in group: ", ui_buttons.size())
	for button in ui_buttons:
		if debug: print("  - ", button.name, " (", button.get_class(), ")")


	
