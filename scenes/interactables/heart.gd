# ===========================================
# SCENES/INTERACTABLES/HEART.GD
# ===========================================

extends Interactable

@export var heart_type: String = "broken"
@export var base_value: float = 10.0
@export var is_repaired: bool = false

func _ready() -> void:
	interaction_type = "heart"
	super._ready()

func setup_visual() -> void:
	if visual:
		visual.color = Color("#B84C4C")  # Red
		visual.size = Vector2(32, 32)

func handle_interaction() -> void:
	# Collect the heart
	var heart_data = {
		"type": heart_type,
		"base_value": base_value,
		"is_repaired": is_repaired,
		"position": global_position
	}
	
	GameManager.collect_heart(heart_data)
	print("Heart collected: ", heart_type)
	
	# Visual feedback
	var tween = create_tween()
	tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.3)
	tween.parallel().tween_property(self, "modulate", Color.TRANSPARENT, 0.3)
	tween.tween_callback(queue_free)
