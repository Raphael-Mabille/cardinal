extends CanvasLayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func change_scene(new_scene) -> void:
	animation_player.play("enter_screen")
	await animation_player.animation_finished
	get_tree().change_scene_to_file(new_scene)
	animation_player.play("leave_screen")
