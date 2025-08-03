# ===========================================
# SCENES/INTERACTABLES/BIOPOD.GD
# ===========================================

extends SmartInteractable

@export var pod_type: String = "healing"
@export var organic_value: float = 15.0
var usage_count: int = 0

func _ready() -> void:
	interaction_type = "biopod"
	interaction_text = "Living vessels of potential."
	super._ready()
	

#func setup_visual() -> void:
#	if visual:
#		visual.color = Color("#4CB84C")  # Green
#		visual.size = Vector2(28, 40)

func handle_interaction() -> void:
	if usage_count == 0:

		print("Biopod harvested - organic essence collected")
		
		var pod_data = {
			"type": pod_type,
			"organic_value": organic_value,
			"position": global_position
		}
		
		# Organic burst effect
		create_organic_burst()
		
		var tween = create_tween()
		tween.parallel().tween_property(self, "scale", Vector2(1.3, 0.7), 0.2)
#		tween.parallel().tween_property(visual, "modulate", Color("#90EE90"), 0.2)
		tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.4)
		tween.tween_callback(queue_free)

	else: 
			print("This biopod has already been used")


func create_organic_burst() -> void:
	usage_count += 1
	# Create organic matter particles
	for i in range(10):
		var particle = ColorRect.new()
		particle.color = Color("#228B22")  # Forest green
		particle.size = Vector2(randf_range(2, 6), randf_range(2, 6))
		get_parent().add_child(particle)
		
		var offset = Vector2(randf_range(-25, 25), randf_range(-25, 25))
		particle.global_position = global_position + offset
		
		var particle_tween = create_tween()
		particle_tween.parallel().tween_property(particle, "position", particle.position + offset * 0.5, 0.6)
		particle_tween.parallel().tween_property(particle, "modulate", Color.TRANSPARENT, 0.6)
		particle_tween.tween_callback(particle.queue_free)
