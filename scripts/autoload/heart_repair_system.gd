# ===========================================
# SCRIPTS/AUTOLOAD/HEARTREPAIRSYSTEM.GD
# ===========================================

extends Node

enum RepairMaterial {
	BROKEN,
	TAPE,
	SUTURES,
	BARBED_WIRE,
	ROSE_THORNS,
	SCARS,
	KINAGAMI,
	THOUGHTS_AND_PRAYERS
}

# Material effect multipliers from GDD
var material_multipliers: Dictionary = {
	RepairMaterial.BROKEN: 1.0 / 3.0,
	RepairMaterial.TAPE: 0.5,
	RepairMaterial.SUTURES: 0.75,
	RepairMaterial.BARBED_WIRE: 0.75,
	RepairMaterial.ROSE_THORNS: 0.75,
	RepairMaterial.SCARS: 1.0,
	RepairMaterial.KINAGAMI: 2.0,
	RepairMaterial.THOUGHTS_AND_PRAYERS: 0.0
}

var material_descriptions: Dictionary = {
	RepairMaterial.BROKEN: "Base value, painful but incomplete",
	RepairMaterial.TAPE: "Superficial fix",
	RepairMaterial.SUTURES: "Earnest effort, imperfect repair",
	RepairMaterial.BARBED_WIRE: "Painful coping, leaves damage",
	RepairMaterial.ROSE_THORNS: "Beauty and hurt intertwined",
	RepairMaterial.SCARS: "Healing acknowledged, not erased",
	RepairMaterial.KINAGAMI: "Sacred art of emotional restoration",
	RepairMaterial.THOUGHTS_AND_PRAYERS: "Empty gestures"
}

func repair_heart(base_value: float, material: RepairMaterial) -> Dictionary:
	var multiplier = material_multipliers.get(material, 1.0)
	var repaired_value = base_value * multiplier
	
	var repair_data = {
		"base_value": base_value,
		"material": material,
		"multiplier": multiplier,
		"final_value": repaired_value,
		"description": material_descriptions.get(material, "Unknown material")
	}
	
	print("Heart repaired with ", RepairMaterial.keys()[material], " - Value: ", repaired_value)
	return repair_data

func get_available_materials() -> Array[RepairMaterial]:
	# This would be expanded based on player progress/inventory
	return [RepairMaterial.BROKEN, RepairMaterial.TAPE, RepairMaterial.SUTURES]
