# ===========================================
# SCENES/INTERACTABLES/ROSES.GD
# ===========================================

extends Interactable

@export var repair_material_type: HeartRepairSystem.RepairMaterial = HeartRepairSystem.RepairMaterial.ROSE_THORNS
@export var beauty_pain_balance: float = 0.75

func _ready() -> void:
	interaction_type = "repair_material"
	interaction_text = "Beauty and hurt intertwined."
	super._ready()

func setup_visual() -> void:
	if visual:
		visual.color = Color("#FFC0CB")  # Pink
		visual.size = Vector2(36, 36)

func handle_interaction() -> void:
	print("Rose collected - beauty with thorns")
	
	var material_data = {
		"type": "rose_thorns",
		"repair_type": repair_material_type,
		"description": "Beauty and hurt intertwined"
	}
	
	# Petal effect - beautiful but with a sharp edge
	create_petal_effect()
	
	var tween = create_tween()
	tween.parallel().tween_property(self, "rotation", PI * 2, 0.6)
	tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.6)
	tween.tween_callback(queue_free)

func create_petal_effect() -> void:
	for i in range(6):
		var petal = ColorRect.new()
		petal.color = Color("#FFB6C1")  # Light pink
		petal.size = Vector2(8, 12)
		get_parent().add_child(petal)
		
		var angle = i * PI / 3
		var direction = Vector2(cos(angle), sin(angle))
		petal.global_position = global_position
		
		var petal_tween = create_tween()
		petal_tween.parallel().tween_property(petal, "position", petal.position + direction * 30, 0.8)
		petal_tween.parallel().tween_property(petal, "rotation", randf_range(-PI, PI), 0.8)
		petal_tween.parallel().tween_property(petal, "modulate", Color.TRANSPARENT, 0.8)
		petal_tween.tween_callback(petal.queue_free)
