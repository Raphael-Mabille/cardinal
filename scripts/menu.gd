extends Control

@onready var menu_buttons: VBoxContainer = $menu_buttons
@onready var difficulty_settings: OptionButton = $menu_buttons/Difficulty_settings
@onready var diff_spearator: ColorRect = $menu_buttons/diff_spearator

var soloBt = Button.new()
var multiplayerBt = Button.new()
var backBt = Button.new()
var localBt = CheckButton.new()
var onlineBt = Button.new()
var createLobbyBt = Button.new()
var joinLobbyBt = Button.new()
var startGameBt = Button.new()
var startSoloGameBt = Button.new()

var addressInput = LineEdit.new()
var nameInput = LineEdit.new()

var gap = ColorRect.new()

var local : bool = true
var adress : String = "127.0.0.1"
var pName : String = "player"

var curr_bt = []
var prev_bt = []

func createBt(bt : Button, btName : String, function, hiden : bool) -> void:
	bt.text = btName
	if function :
		bt.pressed.connect(function)
	menu_buttons.add_child(bt)
	if hiden:
		bt.hide()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	createBt(soloBt, "Jouer seul", play_solo, false)
	createBt(multiplayerBt, "Jouer en multijoueurs", play_multiplayer, false)
	showbt(soloBt)
	showbt(multiplayerBt)
	multiplayerBt.disabled = true

	nameInput.text_changed.connect(modifyName)
	nameInput.alignment = HORIZONTAL_ALIGNMENT_CENTER
	nameInput.placeholder_text = "Entrer votre nom"
	menu_buttons.add_child(nameInput)
	nameInput.hide()
	
	createBt(onlineBt, "en ligne", play_solo, true)
	createBt(createLobbyBt, "créer une partie", createLobby, true)
	createBt(joinLobbyBt, "rejoindre une partie", joinLobby, true)
	createBt(startGameBt, "commencer la partie", startGame, true)
	createBt(startSoloGameBt, "commencer la partie", startSoloGame, true)

	createBt(localBt, "local", localTg, true)
	
	gap.color = Color(0, 0, 0, 0)
	gap.custom_minimum_size = Vector2(10, 10)
	menu_buttons.add_child(gap)
	
	createBt(backBt, "retour", goBack, true)
	
	addressInput.text_changed.connect(modifyAdress)
	addressInput.placeholder_text = "127.0.0.1"
	menu_buttons.add_child(addressInput)
	addressInput.hide()

func modifyName(newName) -> void:
	pName = newName

func modifyAdress(newAdress) -> void:
	adress = newAdress

func startGame() -> void:
	Transition.change_scene_multiplayer(pName)

func _process(_delta) -> void:
	pass

func printBt() -> void:
	print("current :")
	for bt in curr_bt:
		print(bt.text)
	print("prev :")
	for bt in prev_bt:
		print(bt.text)

func goBack() -> void:
	for bt in prev_bt:
		bt.show()
	for bt in curr_bt:
		bt.hide()
	var temp = prev_bt.duplicate()
	prev_bt = curr_bt.duplicate()
	curr_bt = temp.duplicate()

func localTg() -> void:
	local = not local

func swapCurrent() -> void:
	prev_bt.clear()
	prev_bt = curr_bt.duplicate()
	for bt in curr_bt:
		bt.hide()
	curr_bt.clear()

func showbt(bt) -> void:
	bt.show()
	curr_bt.append(bt)


func startSoloGame() -> void:
	Lobby.create_game()
	Transition.change_scene_multiplayer(pName)

func play_solo() -> void:
	swapCurrent()
	showbt(nameInput)
	showbt(startSoloGameBt)
	showbt(backBt)
	showbt(gap)
	showbt(difficulty_settings)
	showbt(diff_spearator)

func play_multiplayer() -> void:
	swapCurrent()
	showbt(createLobbyBt)
	showbt(joinLobbyBt)
	showbt(localBt)
	showbt(backBt)
	showbt(addressInput)
	showbt(nameInput)

func createLobby() -> void:
	Lobby.create_game()
	showbt(startGameBt)
	
func joinLobby() -> void:
	Lobby.join_game(adress, pName)


func _on_difficulty_settings_item_selected(index: int) -> void:
	Global.difficulty = index as Global.Difficulty
