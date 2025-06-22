# ===========================================
# UPDATED GAME HUD WITH HANDWRITTEN TEXT
# ===========================================

extends Control
class_name HandwrittenGameHUD

@onready var hearts_container: HBoxContainer = $HeartsContainer
@onready var area_container: HBoxContainer = $AreaContainer

var hearts_count: int = 0
var current_area: String = "bathhouse_entry"

func _ready() -> void:
	debug = scr_debug or GameData.sys_debug
	setup_handwritten_hud()
	connect_signals()

func setup_handwritten_hud() -> void:
	# Create hearts display
	setup_hearts_display()
	
	# Create area display
	setup_area_display()

func setup_hearts_display() -> void:
	if not hearts_container:
		hearts_container = HBoxContainer.new()
		add_child(hearts_container)
		hearts_container.position = Vector2(50, 50)
	
	# Clear existing children
	for child in hearts_container.get_children():
		child.queue_free()
	
	# Add "Hearts:" label
	var hearts_label = HandwrittenLabel.new()
	hearts_label.set_handwritten_text("ui", "hearts_colon")
	hearts_container.add_child(hearts_label)
	
	# Add number
	var hearts_number = HandwrittenLabel.new()
	hearts_number.set_number(hearts_count)
	hearts_container.add_child(hearts_number)

func setup_area_display() -> void:
	if not area_container:
		area_container = HBoxContainer.new()
		add_child(area_container)
		area_container.position = Vector2(300, 50)
	
	# Clear existing children
	for child in area_container.get_children():
		child.queue_free()
	
	# Add "Area:" label
	var area_label = HandwrittenLabel.new()
	area_label.set_handwritten_text("ui", "area_colon")
	area_container.add_child(area_label)
	
	# Add area name
	var area_name = HandwrittenLabel.new()
	area_name.set_handwritten_text("areas", current_area)
	area_container.add_child(area_name)

func connect_signals() -> void:
	if GameManager:
		GameManager.heart_collected.connect(_on_heart_collected)

func _on_heart_collected(heart_data: Dictionary) -> void:
	hearts_count += 1
	update_hearts_display()

func update_hearts_display() -> void:
	# Update just the number part
	var hearts_number = hearts_container.get_child(1) as HandwrittenLabel
	if hearts_number:
		hearts_number.set_number(hearts_count)
