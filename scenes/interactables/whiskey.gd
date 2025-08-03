# ===========================================
# SCENES/INTERACTABLES/WHISKEY.GD
# ===========================================

extends SmartCollectable

@export var whiskey_type: String = "comfort"
@export var healing_amount: float = 5.0

func _ready() -> void:
	interaction_type = "whiskey"
	interaction_text = "A small comfort in difficult times."
	super._ready()

#func setup_visual() -> void:
#	if visual:
#		visual.color = Color("#D2B48C")  # Tan
#		visual.size = Vector2(24, 32)

func handle_interaction() -> void:
	print("Whiskey consumed - warmth spreads through your chest")
	# Could heal hearts, provide comfort, unlock dialogue, etc.
	
	# Visual feedback - fade out with a warm glow
	var tween = create_tween()
#	tween.parallel().tween_property(visual, "modulate", Color("#FFE4B5", 0.8), 0.2)
	tween.parallel().tween_property(self, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.5)
	tween.tween_callback(queue_free)
