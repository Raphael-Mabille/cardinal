extends Node

@onready var m_start: Marker2D = $m_start
@onready var m_end: Marker2D = $m_end

@onready var control_node: Control = $Control
@onready var label: Label = $Control/Label

var tween1: Tween = null
var tween2: Tween = null

func _ready() -> void:
	pass

func sendNotification(newText: String) -> void:
	if tween2:
		tween2.kill()
	tween1 = get_tree().create_tween()
	tween1.tween_property(control_node, "position", m_end.position, 0.8).set_trans(
		Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	label.text = newText
	tween2 = get_tree().create_tween()
	tween2.tween_interval(6)
	tween2.tween_property(control_node, "position", m_start.position, 0.8).set_trans(
		Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
