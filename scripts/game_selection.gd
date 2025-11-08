extends Control

@onready var display: Node2D = $display
const MENU = preload("uid://cxm0drsbde21d")

func _on_catomancie_bt_pressed() -> void:
	Transition.change_scene(MENU)


func _on_chapardage_bt_pressed() -> void:
	display.sendNotification("ce mode de jeu n'est pas encore disponible.")


func _on_réplik_bt_pressed() -> void:
	display.sendNotification("ce mode de jeu n'est pas encore disponible.")


func _on_dileme_bt_pressed() -> void:
	display.sendNotification("ce mode de jeu n'est pas encore disponible.")


func _on_croiselettre_bt_pressed() -> void:
	display.sendNotification("ce mode de jeu n'est pas encore disponible.")


func _on_recto_bt_pressed() -> void:
	display.sendNotification("ce mode de jeu n'est pas encore disponible.")
