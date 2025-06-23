extends Area2D

var player_has : bool = false

func add_to_interactive_areas():
	add_to_group("interactive_areas")

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Tess":
		player_has = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Tess":
		player_has = false
