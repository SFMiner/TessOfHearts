# ===========================================
# SCENES/UI/GAMEHUD.GD
# ===========================================

extends Control

const scr_debug : bool = false 
var debug : bool

@onready var hearts_collected_label: Label = $HeartsCollected
@onready var current_area_label: Label = $CurrentArea
@onready var interaction_hint: Label = $InteractionHint

var hearts_count: int = 0

func _ready() -> void:
	debug = scr_debug or GameData.sys_debug
	# Connect to game manager signals
	if GameManager:
		GameManager.heart_collected.connect(_on_heart_collected)
		GameManager.game_state_changed.connect(_on_game_state_changed)
	
	update_display()

func _on_heart_collected(heart_data: Dictionary) -> void:
	hearts_count += 1
	update_display()
	
	# Show collection feedback
	show_heart_collected_feedback(heart_data)

func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	update_interaction_hint(new_state)

func update_display() -> void:
	if hearts_collected_label:
		hearts_collected_label.text = "Hearts: " + str(hearts_count)
	
	if current_area_label:
		current_area_label.text = "Area: " + GameManager.current_area

func show_heart_collected_feedback(heart_data: Dictionary) -> void:
	if interaction_hint:
		interaction_hint.text = "Heart collected: " + heart_data.get("type", "unknown")
		interaction_hint.modulate = Color.WHITE
		
		# Fade out after showing
		var tween = create_tween()
		tween.tween_delay(1.0)
		tween.tween_property(interaction_hint, "modulate", Color.TRANSPARENT, 0.5)

func update_interaction_hint(state: GameManager.GameState) -> void:
	if not interaction_hint:
		return
		
	match state:
		GameManager.GameState.EXPLORING:
			interaction_hint.text = "Touch to interact"
		GameManager.GameState.INTERACTING:
			interaction_hint.text = "Interacting..."
		GameManager.GameState.DIALOGUE:
			interaction_hint.text = "Listening..."
		GameManager.GameState.INVENTORY:
			interaction_hint.text = "Managing hearts..."
		GameManager.GameState.TRANSITION:
			interaction_hint.text = "Moving between spaces..."
