# ===========================================
# SCENES/INTERACTABLES/EXTRASUTURES.GD
# ===========================================

extends Interactable

@export var repair_material_type: HeartRepairSystem.RepairMaterial = HeartRepairSystem.RepairMaterial.SUTURES
@export var extra_precision: float = 0.1

func _ready() -> void:
	interaction_type = "repair_material"
	interaction_text = "Extra sutures - when the first attempt needs refinement."
	super._ready()

func setup_visual() -> void:
	if visual:
		visual.color = Color("#FFA500")  # Orange
		visual.size = Vector2(24, 6)

func handle_interaction() -> void:
	print("Extra sutures collected - enhanced precision available")
	
	var material_data = {
		"type": "extra_sutures",
		"repair_type": repair_material_type,
		"extra_precision": extra_precision,
		"description": "Enhanced medical precision"
	}
	
	# Precise, technical collection effect
	var tween = create_tween()
	tween.parallel().tween_property(self, "scale", Vector2(0.5, 0.5), 0.1)
	tween.parallel().tween_property(visual, "modulate", Color("#FFD700"), 0.1)
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.25)
	tween.tween_callback(queue_free)
