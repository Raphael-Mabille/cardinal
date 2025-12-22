extends Control

@onready var bt_back: Button = $menu_buttons/bt_back

#--------------------------- VBoxs ---------------------------#
@onready var vbox_root: VBoxContainer = $menu_buttons/vbox_root
@onready var vbox_multiplayer: VBoxContainer = $menu_buttons/vbox_multiplayer
@onready var vbox_singleplayer: VBoxContainer = $menu_buttons/vbox_singleplayer
@onready var vbox_create_lobby: VBoxContainer = $menu_buttons/vbox_create_lobby
@onready var vbox_join_lobby: VBoxContainer = $menu_buttons/vbox_join_lobby
@onready var la_you: Label = $menu_buttons/vbox_create_lobby/la_you

#-------------------------------------------------------------#


func _on_ready() -> void:
	setCurrent(vbox_root)

var adress : String = "127.0.0.1"

var peer_id_list = [1]

#---------------------- button navigation --------------------#

var history : Array[VBoxContainer] = []

func setCurrent(box : VBoxContainer) -> void :
	if not history.is_empty() :
		history[0].hide()
		bt_back.disabled = false
	box.show()
	history.push_front(box)

func _on_bt_back_pressed() -> void:
	history.pop_front().hide()
	history[0].show()

	if history.size() <= 1 :
		bt_back.disabled = true

#-------------------------------------------------------------#

func _on_difficulty_settings_item_selected(index: int) -> void:
	Global.difficulty = index as Global.Difficulty


#-------------------- buttons events -------------------------#

func _on_bt_solo_pressed() -> void:
	setCurrent(vbox_singleplayer)

func _on_bt_multiplayer_pressed() -> void:
	setCurrent(vbox_multiplayer)

func _on_bt_start_game_mp_pressed() -> void:
	Transition.change_scene_multiplayer(Lobby.player_info.name)

func _on_le_player_name_text_changed(new_text: String) -> void:
	Lobby.player_info.name = new_text
	la_you.text = "    - " + new_text

func add_player_name_to_ui(p_name) -> void:
	var new_label = Label.new()
	new_label.text = "    - " + p_name
	la_you.add_sibling(new_label)


func add_player_name(peer_id, player_info) -> void:
	if peer_id_list.find(peer_id) == -1 :
		peer_id_list.append(peer_id)
		add_player_name_to_ui(player_info.name)


func _on_bt_create_lobby_pressed() -> void:
	Lobby.player_connected.connect(add_player_name)
	Lobby.create_game()
	setCurrent(vbox_create_lobby)


func _on_bt_join_lobby_pressed() -> void:
	setCurrent(vbox_join_lobby)


func _on_le_ip_adress_text_changed(new_text: String) -> void:
	adress = new_text


func player_connect(a, b) -> void:
	print("peer_id, player_info", a, b)

func _on_bt_join_game_pressed() -> void:
	Lobby.player_connected.connect(player_connect)
	var error = Lobby.join_game(adress)
	print("error : ", error)

#-------------------------------------------------------------#
