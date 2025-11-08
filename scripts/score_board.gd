extends Control

const NAME_VALUE_LABEL = preload("res://scenes/name_value_label.tscn")
@onready var v_box_container: VBoxContainer = $VBoxContainer

var player_list = {}

func Add_player(playerName : String, id : int, score := 0):
	var newPlayer = NAME_VALUE_LABEL.instantiate()
	newPlayer.setName(playerName)
	newPlayer.addScore(score)
	player_list[id] = v_box_container.get_child_count()
	v_box_container.add_child(newPlayer)

func Change_active_player(id : int, old_id : int) :
	var old_p = v_box_container.get_child(player_list[old_id])
	old_p.get_child(0).remove_theme_font_size_override("font_size")
	old_p.get_child(1).remove_theme_font_size_override("font_size")
	var new_p = v_box_container.get_child(player_list[id])
	new_p.get_child(0).add_theme_font_size_override("font_size", 32)
	new_p.get_child(1).add_theme_font_size_override("font_size", 32)

func SetFontSize(id : int, fontSize: int) :
	var box = v_box_container.get_child(player_list[id])
	box.get_child(0).add_theme_font_size_override("font_size", fontSize)
	box.get_child(1).add_theme_font_size_override("font_size", fontSize)

func Add_score(id: int, score: int):
	var player = v_box_container.get_child(player_list[id])
	player.addScore(score)
	print(player_list)

func _on_ready() -> void:
	pass
