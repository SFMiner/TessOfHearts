# ===========================================
# DYNAMIC PAPER BACKGROUND COMPONENT
# ===========================================

extends Node2D
class_name NotebookPage

@onready var paper_background: TextureRect = %PaperBackground
@onready var content_container: Control = %ContentContainer
@onready var tess : Character = %Tess
@onready var friend : Character = %BeardedFriend
var paper_manager: NotebookPaperManager
var current_paper_type: NotebookPaperManager.PaperType
var main


func _ready() -> void:
	debug = scr_debug or GameData.sys_debug
	main = get_tree().get_root().get_node("Main")
	main.set_tess(tess)
#	paper_manager = get_node("/root/NotebookPaperManager")
#setup_paper_background()

func get_tess() -> Character:
	return tess

func setup_paper_background() -> void:
	if paper_background:
		# Fill entire screen with paper texture
		paper_background.anchors_preset = Control.PRESET_FULL_RECT
		paper_background.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		paper_background.stretch_mode = TextureRect.STRETCH_TILE

func set_paper_context(context: String) -> void:
	var texture = paper_manager.get_paper_texture(context)
	if texture and paper_background:
		paper_background.texture = texture

func set_paper_type(type: NotebookPaperManager.PaperType) -> void:
	current_paper_type = type
	var texture = paper_manager.get_paper_by_type(type)
	if texture and paper_background:
		paper_background.texture = texture

# Smooth paper transition effect
func transition_to_paper(new_type: NotebookPaperManager.PaperType, duration: float = 0.5) -> void:
	var new_texture = paper_manager.get_paper_by_type(new_type)
	if not new_texture:
		return
	
	# Create temporary overlay for smooth transition
	var overlay = TextureRect.new()
	overlay.texture = new_texture
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	overlay.stretch_mode = TextureRect.STRETCH_TILE
	overlay.modulate = Color.TRANSPARENT
	add_child(overlay)
	
	# Fade transition
	var tween = create_tween()
	tween.tween_property(overlay, "modulate", Color.WHITE, duration)
	tween.tween_callback(func():
		paper_background.texture = new_texture
		overlay.queue_free()
	)
