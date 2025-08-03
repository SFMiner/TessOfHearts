# ===========================================
# HANDWRITTEN TEXT SYSTEM - ALL UI ELEMENTS
# ===========================================

extends Node

const scr_debug : bool = false 
var debug : bool

func _ready() -> void:
	debug = scr_debug or GameData.sys_debug

# Central repository for all handwritten text assets
var handwritten_assets: Dictionary = {
	
	# === NUMBERS (0-100+) ===
	"numbers": {
		"0": preload("res://assets/handwritten/numbers/zero.png"),
		"1": preload("res://assets/handwritten/numbers/one.png"),
		"2": preload("res://assets/handwritten/numbers/two.png"),
		"3": preload("res://assets/handwritten/numbers/three.png"),
		"4": preload("res://assets/handwritten/numbers/four.png"),
		"5": preload("res://assets/handwritten/numbers/five.png"),
		# Add more as you create them
	},
	
	# === UI LABELS ===
	"ui": {
		"hearts_colon": preload("res://assets/handwritten/ui/hearts_colon.png"),  # "Hearts:"
		"area_colon": preload("res://assets/handwritten/ui/area_colon.png"),      # "Area:"
		"touch_to_interact": preload("res://assets/handwritten/ui/touch_to_interact.png"),
		"call_friend": preload("res://assets/handwritten/ui/call_friend.png"),
		"send_home": preload("res://assets/handwritten/ui/send_home.png")
	},
	
	# === DIALOGUE (expanded) ===
	"dialogue": {
		"tess_what_is_it": preload("res://assets/handwritten/dialogue/friend_tess_what_is_it.png"),
		"friend_hey_there": preload("res://assets/handwritten/dialogue/friend_hey_there.png"),
		"cat_wisdom": preload("res://assets/handwritten/dialogue/cat_wisdom.png"),
		"still_doesnt_like_ants": preload("res://assets/handwritten/dialogue/still_doesnt_like_ants.png"),
		"tess_come_over_here": preload("res://assets/handwritten/dialogue/tess_come_over_here.png")
	},
	
	# === MESSAGES (expanded) ===
	"messages": {
		"heart_collected": preload("res://assets/handwritten/messages/heart_collected.png"),
		"barrier_locked": preload("res://assets/handwritten/messages/barrier_locked.png"),
		"area_unlocked": preload("res://assets/handwritten/messages/area_unlocked.png"),
		"friend_summoned": preload("res://assets/handwritten/messages/friend_summoned.png"),
		"whiskey_shared": preload("res://assets/handwritten/messages/whiskey_shared.png")
	}
}

# Get handwritten texture for any text element
func get_handwritten_texture(category: String, key: String) -> Texture2D:
	if category in handwritten_assets and key in handwritten_assets[category]:
		return handwritten_assets[category][key]
	else:
		if debug: print("Handwritten asset not found: ", category, "/", key)
		# Return a fallback texture or create one
		return create_fallback_texture(category + "/" + key)

# Create number texture from integer
func get_number_texture(number: int) -> Texture2D:
	var number_str = str(number)
	return get_handwritten_texture("numbers", number_str)

# Create fallback texture for missing assets
func create_fallback_texture(text: String) -> Texture2D:
	if debug: print("Creating fallback for: ", text)
	
	# Create colored rectangle with text label for testing
	var image = Image.create(150, 40, false, Image.FORMAT_RGBA8)
	image.fill(Color("#FFE066"))  # Yellow like post-it
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture
