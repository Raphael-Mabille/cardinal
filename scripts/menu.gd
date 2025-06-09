extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _process(_delta) -> void:
	pass


func _on_start_game_button_up() -> void:
	Transition.change_scene("res://scenes/main.tscn")
