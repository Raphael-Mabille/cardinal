extends CanvasLayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func change_scene(new_scene : PackedScene) -> void:
	animation_player.play("enter_screen")
	await animation_player.animation_finished
	get_tree().change_scene_to_packed(new_scene)
	animation_player.play("leave_screen")

func change_scene_multiplayer(pName : String) -> void:
	animation_player.play("enter_screen")
	await animation_player.animation_finished
	Lobby.load_game.rpc("res://scenes/main.tscn", pName)
	animation_player.play("leave_screen")
