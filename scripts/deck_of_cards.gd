extends AnimatedSprite2D


signal pressed_is

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		pressed_is.emit(self)
