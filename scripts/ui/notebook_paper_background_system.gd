# ===========================================
# NOTEBOOK PAPER BACKGROUND SYSTEM
# ===========================================

extends Node
class_name NotebookPaperManager

enum PaperType {
	RULED,          # Traditional lined notebook paper
	DOTTED,         # Bullet journal dot grid
	UNRULED,        # Plain cream/white paper
	GRAPH,          # Optional: graph/grid paper
	AGED,           # Optional: yellowed, vintage paper
	SKETCH          # Optional: thicker sketch paper texture
}

# Paper background textures
var paper_textures: Dictionary = {
	PaperType.RULED: preload("res://assets/paper/ruled_paper.png"),
	PaperType.DOTTED: preload("res://assets/paper/dotted_paper.png"),
	PaperType.UNRULED: preload("res://assets/paper/unruled_paper.png"),
	PaperType.GRAPH: preload("res://assets/paper/graph_paper.png"),
	PaperType.AGED: preload("res://assets/paper/aged_paper.jpg"),
	PaperType.SKETCH: preload("res://assets/paper/sketch_paper.png")
}

# Paper styles for different game contexts
var paper_assignments: Dictionary = {
	# ROOM/AREA BACKGROUNDS
	"bathhouse_entry": PaperType.UNRULED,     # Clean start
	"heart_sanctum": PaperType.DOTTED,        # Organized, bullet journal feel
	"throne_of_rest": PaperType.AGED,         # Ancient, sacred space
	"puzzle_room": PaperType.GRAPH,           # Structured, mathematical
	
	# UI CONTEXTS
	"main_hud": PaperType.RULED,              # Traditional notebook
	"inventory": PaperType.DOTTED,            # Organized lists
	"dialogue": PaperType.UNRULED,            # Clean for readability
	"credits": PaperType.AGED,                # Elegant, timeless
	"menu": PaperType.SKETCH                  # Artistic, textured
}

func get_paper_texture(context: String) -> Texture2D:
	var paper_type = paper_assignments.get(context, PaperType.UNRULED)
	return paper_textures.get(paper_type, null)

func get_paper_by_type(type: PaperType) -> Texture2D:
	return paper_textures.get(type, null)
