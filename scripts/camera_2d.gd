extends Camera2D

@export var smooth_speed: float = 5.0
@export var move_time: float = 2  # Time in seconds for the movement

var tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func move_to_position(target_position: Vector2):
	if tween:
		tween.kill()  # Stop any previous movement
	tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", target_position, move_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_choose_rules_button_up() -> void:
	move_to_position(Vector2(-500, 300))
