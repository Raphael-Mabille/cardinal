extends Control

@onready var label: Label = $Label
@onready var button_1: Button = $HBoxContainer/Button_1
@onready var button_2: Button = $HBoxContainer/Button_2

func initBox(label_text, bt_1_text, bt_2_text) -> void:
	label.text = label_text
	button_1.text = bt_1_text
	button_2.text = bt_2_text

signal bt_1_pressed
signal bt_2_pressed

func _on_button_1_pressed() -> void:
	bt_1_pressed.emit()

func _on_button_2_pressed() -> void:
	bt_2_pressed.emit()
