# ===========================================
# SCENES/INTERACTABLES/GOLD.GD
# ===========================================

extends SmartCollectable

@export var gold_value: float = 25.0
@export var currency_type: String = "cosmic_gold"

func _ready() -> void:
	interaction_type = "gold"
	interaction_text = "Something precious, something earned."
	super._ready()

func setup_visual() -> void:
	if visual:
		visual.color = Color("#FFD700")  # Gold/Yellow
		visual.size = Vector2(20, 20)

func handle_interaction() -> void:
	print("Gold collected - value: ", gold_value)
	
	# Sparkle effect
	create_sparkle_effect()
	
	# Could add to inventory, currency system, etc.
	var gold_data = {
		"type": currency_type,
		"value": gold_value,
		"position": global_position
	}
	
	# Shine and collect
	var tween = create_tween()
	tween.parallel().tween_property(self, "scale", Vector2(1.5, 1.5), 0.1)
	tween.parallel().tween_property(visual, "modulate", Color.WHITE * 2.0, 0.1)
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.3)
	tween.tween_callback(queue_free)

func create_sparkle_effect() -> void:
	for i in range(8):
		var sparkle = ColorRect.new()
		sparkle.color = Color("#FFFF99")  # Light yellow
		sparkle.size = Vector2(3, 3)
		get_parent().add_child(sparkle)
		
		var angle = i * PI / 4
		var offset = Vector2(cos(angle), sin(angle)) * 20
		sparkle.global_position = global_position + offset
		
		var sparkle_tween = create_tween()
		sparkle_tween.parallel().tween_property(sparkle, "position", sparkle.position + offset, 0.5)
		sparkle_tween.parallel().tween_property(sparkle, "modulate", Color.TRANSPARENT, 0.5)
		sparkle_tween.tween_callback(sparkle.queue_free)
