extends Control

@onready var current_area : Label = %HeartsCollected
@onready var inventory : VBoxContainer = $VBoxContainer2/Inventory
@onready var hearts_collected : Label = %HeartsCollected
@onready var tape_collected : Label = %TapeCollected
@onready var sutures_collected : Label = %SuturesCollected
@onready var barbed_wire_collected : Label = %BarbedWireCollected
@onready var gold_collected : Label = %GoldCollected
@onready var cookies_collected : Label = %CookiesCollected
@onready var whiskey_collected : Label = %WhiskeyCollected


func set_inventory():
	var total_hearts = GameData.num_hearts_whole + (GameData.num_hearts_whole *2 / 3) +  (GameData.num_hearts_half / 2) + (GameData.num_hearts_2third / 3)
	hearts_collected.text = "Hearts: " + str(total_hearts)
	tape_collected.text = "Tape: " + str(GameData.num_tape)
	sutures_collected.text = "Sutures: " + str(GameData.num_sutures)
	barbed_wire_collected.text = "Barbed Wire: " + str(GameData.num_barbed_wire)
	gold_collected.text = "Gold: " + str(GameData.num_gold)
	cookies_collected.text = "Cookies: " + str(GameData.num_cookies)
	whiskey_collected.text = "Whiskey: " + str(GameData.num_whiskey)


	
