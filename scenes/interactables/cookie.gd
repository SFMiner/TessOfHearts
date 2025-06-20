# ===========================================
# SCENES/INTERACTABLES/COOKIE.GD
# ===========================================

extends Interactable

@export var cookie_type: String = "friendship"
@export var comfort_value: float = 3.0

func _ready() -> void:
	interaction_type = "cookie"
	interaction_text = "Shared sweetness makes everything better."
	super._ready()

func setup_visual() -> void:
	if visual:
		visual.color = Color("#8B4513")  # Brown
		visual.size = Vector2(28, 28)

func handle_interaction() -> void:
	print("Cookie shared - simple joys matter most")
	
	# Crumb effect - multiple small pieces
	create_crumb_effect()
	
	# Gentle fade
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.4)
	tween.tween_callback(queue_free)

func create_crumb_effect() -> void:
	# Create small crumb particles
	for i in range(5):
		var crumb = ColorRect.new()
		crumb.color = Color("#D2691E")  # Lighter brown
		crumb.size = Vector2(4, 4)
		get_parent().add_child(crumb)
		crumb.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		
		# Animate crumbs falling
		var crumb_tween = create_tween()
		crumb_tween.parallel().tween_property(crumb, "position", crumb.position + Vector2(0, 50), 0.8)
		crumb_tween.parallel().tween_property(crumb, "modulate", Color.TRANSPARENT, 0.8)
		crumb_tween.tween_callback(crumb.queue_free)
