# ===========================================
# SCENES/INTERACTABLES/SUTURES.GD
# ===========================================

extends SmartCollectable

@export var repair_material_type: HeartRepairSystem.RepairMaterial = HeartRepairSystem.RepairMaterial.SUTURES
@export var repair_quality: float = 0.75

func _ready() -> void:
	interaction_type = "repair_material"
	interaction_text = "Earnest effort, imperfect repair."
	super._ready()

#func setup_visual() -> void:
#	if visual:
#		visual.color = Color("#FF00FF")  # Magenta
#		visual.size = Vector2(32, 8)

func handle_interaction() -> void:
	print("Sutures collected - medical precision")
	
	var material_data = {
		"type": "sutures",
		"repair_type": repair_material_type,
		"description": "Earnest effort, imperfect repair"
	}
	
	# Clean, medical collection effect
	var tween = create_tween()
	tween.parallel().tween_property(self, "scale", Vector2(0.8, 0.8), 0.15)
#	tween.parallel().tween_property(visual, "modulate", Color("#FF99FF"), 0.15)
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.3)
	tween.tween_callback(queue_free)
