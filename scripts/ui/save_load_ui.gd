# ===========================================
# SAVE/LOAD UI - COMPLETE SAVE SYSTEM INTERFACE
# ===========================================

extends Control
class_name SaveLoadUI

signal save_selected(slot_number: int)
signal load_selected(slot_number: int)
signal ui_closed()

@onready var background: ColorRect = %Background
@onready var title_label: Label = %TitleLabel
@onready var slots_container: VBoxContainer = %SlotsContainer
@onready var close_button: Button = %CloseButton
@onready var quick_save_button: Button = %QuickSaveButton
@onready var quick_load_button: Button = %QuickLoadButton

var save_system: Node
var current_mode: String = "save"  # "save" or "load"
var slot_buttons: Array[Control] = []

func _ready() -> void:
	print("=== SAVE/LOAD UI SETUP ===")
	
	# Find save system
	save_system = get_node("/root/SaveSystem")
	if not save_system:
		print("ERROR: SaveSystem not found!")
		return
	
	# Connect signals
	save_system.save_completed.connect(_on_save_completed)
	save_system.load_completed.connect(_on_load_completed)
	
	# Set up UI
	setup_ui()
	
	# Start hidden
	hide_ui()

func setup_ui() -> void:
	# Set up background
	if background:
		background.color = Color(0, 0, 0, 0.7)  # Semi-transparent black
	
	# Set up close button
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	# Set up quick save/load buttons
	if quick_save_button:
		quick_save_button.pressed.connect(_on_quick_save_pressed)
		quick_save_button.text = "Quick Save (F5)"
	
	if quick_load_button:
		quick_load_button.pressed.connect(_on_quick_load_pressed)
		quick_load_button.text = "Quick Load (F9)"

func show_save_ui() -> void:
	current_mode = "save"
	if title_label:
		title_label.text = "Save Game"
	
	refresh_save_slots()
	show_ui()

func show_load_ui() -> void:
	current_mode = "load"
	if title_label:
		title_label.text = "Load Game"
	
	refresh_save_slots()
	show_ui()

func show_ui() -> void:
	visible = true
	# Fade in animation
	modulate = Color.TRANSPARENT
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)

func hide_ui() -> void:
	# Fade out animation
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.3)
	tween.tween_callback(func(): visible = false)
	
	ui_closed.emit()

func refresh_save_slots() -> void:
	# Clear existing slot buttons
	for slot_button in slot_buttons:
		slot_button.queue_free()
	slot_buttons.clear()
	
	# Get save slot information
	var save_slots = save_system.get_all_save_slots()
	
	# Create slot buttons
	for slot_info in save_slots:
		create_slot_button(slot_info)

func create_slot_button(slot_info: Dictionary) -> void:
	var slot_number = slot_info["slot_number"]
	var exists = slot_info["exists"]
	var metadata = slot_info["metadata"]
	
	# Create slot container
	var slot_container = HBoxContainer.new()
	slot_container.custom_minimum_size = Vector2(400, 60)
	slots_container.add_child(slot_container)
	
	# Create slot button
	var slot_button = Button.new()
	slot_button.custom_minimum_size = Vector2(300, 60)
	slot_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Set button text based on whether save exists
	if exists and metadata.has("save_date"):
		var save_date = metadata.get("save_date", "Unknown")
		var hearts = "Unknown"
		var energy = "Unknown"
		
		# Try to extract additional info if available
		if metadata.has("preview_data"):
			var preview = metadata["preview_data"]
			hearts = str(preview.get("hearts", "?"))
			energy = str(preview.get("energy", "?"))
		
		slot_button.text = "Slot " + str(slot_number + 1) + "\n" + save_date + "\nHearts: " + hearts + " Energy: " + energy
	else:
		slot_button.text = "Slot " + str(slot_number + 1) + "\n[Empty]"
	
	# Style the button based on mode and save existence
	if current_mode == "save":
		slot_button.modulate = Color.WHITE
	else:  # load mode
		if exists:
			slot_button.modulate = Color.WHITE
		else:
			slot_button.modulate = Color.GRAY
			slot_button.disabled = true
	
	# Connect button signal
	slot_button.pressed.connect(func(): _on_slot_selected(slot_number))
	slot_container.add_child(slot_button)
	
	# Add delete button for existing saves
	if exists:
		var delete_button = Button.new()
		delete_button.text = "Delete"
		delete_button.custom_minimum_size = Vector2(80, 60)
		delete_button.modulate = Color.RED
		delete_button.pressed.connect(func(): _on_delete_slot(slot_number))
		slot_container.add_child(delete_button)
	
	slot_buttons.append(slot_container)

func _on_slot_selected(slot_number: int) -> void:
	print("=== SLOT SELECTED ===")
	print("Mode: ", current_mode, " Slot: ", slot_number)
	
	if current_mode == "save":
		# Show confirmation if save exists
		if save_system.save_file_exists(slot_number):
			show_overwrite_confirmation(slot_number)
		else:
			perform_save(slot_number)
	else:  # load mode
		perform_load(slot_number)

func show_overwrite_confirmation(slot_number: int) -> void:
	# Create confirmation dialog
	var dialog = AcceptDialog.new()
	dialog.title = "Overwrite Save?"
	dialog.dialog_text = "This will overwrite the existing save in slot " + str(slot_number + 1) + ". Continue?"
	
	# Add custom buttons
	dialog.add_button("Overwrite", true, "overwrite")
	dialog.add_button("Cancel", false, "cancel")
	
	add_child(dialog)
	dialog.popup_centered()
	
	# Connect signals
	dialog.custom_action.connect(func(action: String):
		if action == "overwrite":
			perform_save(slot_number)
		dialog.queue_free()
	)
	
	dialog.confirmed.connect(func():
		perform_save(slot_number)
		dialog.queue_free()
	)

func perform_save(slot_number: int) -> void:
	print("Performing save to slot: ", slot_number)
	save_system.save_game(slot_number)
	save_selected.emit(slot_number)

func perform_load(slot_number: int) -> void:
	print("Performing load from slot: ", slot_number)
	await save_system.load_game(slot_number)
	load_selected.emit(slot_number)
	hide_ui()

func _on_delete_slot(slot_number: int) -> void:
	# Create confirmation dialog
	var dialog = AcceptDialog.new()
	dialog.title = "Delete Save?"
	dialog.dialog_text = "This will permanently delete the save in slot " + str(slot_number + 1) + ". This cannot be undone!"
	
	add_child(dialog)
	dialog.popup_centered()
	
	# Connect confirmation
	dialog.confirmed.connect(func():
		save_system.delete_save(slot_number)
		refresh_save_slots()  # Refresh the UI
		dialog.queue_free()
	)

func _on_close_pressed() -> void:
	hide_ui()

func _on_quick_save_pressed() -> void:
	save_system.quick_save()
	hide_ui()

func _on_quick_load_pressed() -> void:
	await save_system.quick_load()
	hide_ui()

func _on_save_completed(slot_number: int, success: bool) -> void:
	if success:
		print("Save completed successfully for slot: ", slot_number)
		show_feedback_message("Game saved to slot " + str(slot_number + 1) + "!", Color.GREEN)
		refresh_save_slots()  # Refresh to show new save
	else:
		print("Save failed for slot: ", slot_number)
		show_feedback_message("Save failed!", Color.RED)

func _on_load_completed(slot_number: int, success: bool) -> void:
	if success:
		print("Load completed successfully from slot: ", slot_number)
		show_feedback_message("Game loaded from slot " + str(slot_number + 1) + "!", Color.GREEN)
	else:
		print("Load failed from slot: ", slot_number)
		show_feedback_message("Load failed!", Color.RED)

func show_feedback_message(message: String, color: Color = Color.WHITE) -> void:
	# Create temporary feedback label
	var feedback = Label.new()
	feedback.text = message
	feedback.modulate = color
	feedback.add_theme_font_size_override("font_size", 24)
	feedback.position = Vector2(get_viewport().get_visible_rect().size.x / 2 - 100, 100)
	
	get_tree().current_scene.add_child(feedback)
	
	# Animate and remove
	var tween = create_tween()
	tween.tween_property(feedback, "modulate", Color.TRANSPARENT, 2.0)
	tween.tween_callback(feedback.queue_free)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("quick_save"):  # You'll need to define this action
		save_system.quick_save()
	elif event.is_action_pressed("quick_load"):  # You'll need to define this action
		await save_system.quick_load()
	elif event.is_action_pressed("ui_cancel") and visible:
		hide_ui()
