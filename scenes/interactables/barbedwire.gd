# ===========================================
# SCENES/INTERACTABLES/BARBEDWIRE.GD
# ===========================================

extends SmartCollectable

@export var repair_material_type: HeartRepairSystem.RepairMaterial = HeartRepairSystem.RepairMaterial.BARBED_WIRE
@export var damage_on_touch: float = 2.0

func _ready() -> void:
	interaction_type = "repair_material"
	interaction_text = "Painful coping - it hurts, but it holds things together."
	super._ready()

func setup_visual() -> void:
	if visual:
		visual.color = Color("#808080")  # Grey
		visual.size = Vector2(40, 16)

func handle_interaction() -> void:
	print("Barbed wire collected - painful but functional")
	
	# Add to repair materials inventory
	var material_data = {
		"type": "barbed_wire",
		"repair_type": repair_material_type,
		"description": "Painful coping, leaves damage"
	}
	
	# Harsh collection effect
