extends Control

@onready var panel = get_node_or_null("Panel")
@onready var inventory = %Inventory

# Connect to GameManager signals for automatic inventory updates
func _ready():
	panel.size = inventory.size + Vector2(20, 20)
	panel.position = inventory.position - Vector2(10, 10)
	
