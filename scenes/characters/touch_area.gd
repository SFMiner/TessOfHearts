extends Area2D

var player_has : bool = false

# Register this touch area in the interactive_areas group for input detection
func add_to_interactive_areas():
	add_to_group("interactive_areas")

# Track when Tess enters this touch area zone
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Tess":
		player_has = true

# Track when Tess leaves this touch area zone
func _on_body_exited(body: Node2D) -> void:
	if body.name == "Tess":
		player_has = false
