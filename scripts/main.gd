extends Node2D

const CARD = preload("res://scenes/card.tscn")
const CONFIRM_BOX = preload("res://scenes/confirm_box.tscn")

@export var card_to_return: int

@onready var play_area: Marker2D = $control/zoning/play_area
@onready var hand: Marker2D = $control/zoning/hand
@onready var zoning: Control = $control/zoning

@onready var card_to_turn_label: Label = $control/labels/cardToTurn/cardToTurnLabel
@onready var deck_of_cards: Sprite2D = $deck_of_cards
@onready var card_left_label: Label = $control/labels/cardLeft/cardLeftLabel
@onready var cardsHolder: Control = $cardsHolder
@onready var score_board: Control = $control/zoning/ScoreBoard
@onready var message: Node2D = $control/message
@onready var temp_score_val: Label = $control/labels/temp_score/temp_score_val
@onready var confirmation_prompt: Control = $control/zoning/confirmation_prompt
@onready var control: Control = $control
@onready var post_game_screen: Control = $post_game_screen
@onready var rule_container: Control = $rule_container
@onready var rules: Button = $control/rules

var playzone = Vector2i(0, 0)
var handzone = Vector2i(0, 0)
var deck_color: int = 0
var card_to_turn = 0
var letter_pool: Array = []
var current: Array = []
var difficulty := Global.difficulty
var cardLeftInDeck: int = 0
var currentWord: String = ""
var space_x := 70
var space_y := 95
var cardDict := {}
var hidddenCard := 0

var minLeft := 0
var majLeft := 0

var idCount = 0

var maxScore: Dictionary = {
	"easy": 221,
	"medium": 288,
	"hard": 353
}

var cardNumber = {
	"easy": 92,
	"medium": 108,
	"hard": 123
}

var difficultyName = {
	Global.Difficulty.EASY : "débutant",
	Global.Difficulty.MEDIUM : "confirmé",
	Global.Difficulty.HARD : "expert"
}

var cardDistribution = {
	Global.Difficulty.EASY : [
		{"letters": "ae", "quantity": 9},
		{"letters": "iou", "quantity": 5},
		{"letters": "lnrst", "quantity": 4},
		{"letters": "bcdfghmpvxz", "quantity": 1},
		{"letters": "@", "quantity": 8},
		{"letters": "AERTIOPSDFGHJLMCVBN`", "quantity": 1}
	],
	Global.Difficulty.MEDIUM : [
		{"letters": "ae", "quantity": 10 },
		{"letters": "iou", "quantity": 6},
		{"letters": "lnrst", "quantity": 4},
		{"letters": "cdfmp", "quantity": 2},
		{"letters": "bghvqxyz", "quantity": 1},
		{"letters": "@", "quantity": 8},
		{"letters": "AERTIOPSDFGHJLMCVBNKQUZ`", "quantity": 1}
	],
	Global.Difficulty.HARD : [
		{"letters": "ae", "quantity": 11 },
		{"letters": "iou", "quantity": 7},
		{"letters": "lnrst", "quantity": 4},
		{"letters": "bcdfghmpv", "quantity": 2},
		{"letters": "jkqwxyz", "quantity": 1},
		{"letters": "@", "quantity": 8},
		{"letters": "AZERTYUIOPQSDFGHJKLMWXCVBN`", "quantity": 1}
	]
}

var cardValue = [
	{"letters": "ae", "value": 1},
	{"letters": "ioulnrstAE", "value": 2},
	{"letters": "bcdfghmpv", "value": 3},
	{"letters": "IOULNRST", "value": 4},
	{"letters": "jkqwxyz", "value": 5},
	{"letters": "BCDFGHMPV", "value": 6},
	{"letters": "JKQWXYZ", "value": 10},
	{"letters": "`@", "value": 0}
]

var cardValueDict : Dictionary = {}

var players = []
var currentPlayer = 0
var confirmBox : Node = null

############################
#	labels
############################

func getCardValue(letter: String) -> int:
	var val : int = cardValueDict.get(letter)
	return val

func update_temp_score(val: int) -> void:
	temp_score_val.text = str(val + int(temp_score_val.text))

func updatecardLeftInDeck(val: int) -> void:
	cardLeftInDeck += val
	card_left_label.text = str(cardLeftInDeck)
	if cardLeftInDeck == 0:
		deck_of_cards.hide()

############################
#	game logic
############################

@rpc("authority", "call_local", "reliable")
func select_card(id: int, index : int) -> void:
	var card = cardDict[id] 
	card.moveTo(handzone + Vector2(index * (space_x - space_x / 10.0), 0))
	var val = getCardValue(card.letter)
	update_temp_score(val);


@rpc("authority", "call_local", "reliable")
func gotoGameScore(msg : String) :
	control.hide()
	deck_of_cards.hide()
	cardsHolder.hide()

	post_game_screen.show()
	post_game_screen.setMsg(msg)
	post_game_screen.setScores(players)

func cancel() :
	confirmBox.queue_free()

func endgame(force : bool, msg : String):
	if force :
		gotoGameScore.rpc(msg)
	else :
		confirmBox = CONFIRM_BOX.instantiate()
		confirmation_prompt.add_child(confirmBox)
		confirmBox.initBox(
			"Voulez vous vraiment mettre fin à la partie ?", "confirmer", "annuler")
		confirmBox.bt_1_pressed.connect(endgame.bind(true, msg))
		confirmBox.bt_2_pressed.connect(cancel)

@rpc("any_peer", "call_local", "reliable")
func endGameConditionCheck() -> void:
	if minLeft == 0:
		endgame(true, "Il n'y a plus aucune minuscule dans le paquet")

func checkCapital() -> void:
	var upper := false
	var lower := false
	
	for card in cardDict:
		if cardDict[card].state != Global.State.REVEALED:
			continue
		if is_capital(cardDict[card].letter) :
			upper = true
		else:
			lower = true
	
	if upper and lower:
		return
	
	if not upper:
		message.sendNotification(
			"aucune majuscule n'est disponible, votre tour a été automatiquement passé")
	if not lower:
		message.sendNotification(
			"aucune minuscule n'est disponible, votre tour a été automatiquement passé")
	pass_turn.rpc_id(1)

@rpc("authority", "call_local", "reliable")
func turn_card(id):
	var card = cardDict[id]
	card_to_turn -= 1
	hidddenCard -= 1
	card_to_turn_label.text = str(card_to_turn)
	if is_capital(card.letter):
		card.reveal(true)
	else:
		card.reveal(false)
	
	if card_to_turn == 0 and multiplayer.get_unique_id() == players[currentPlayer].id:
		checkCapital()
	if multiplayer.is_server():
		endGameConditionCheck.rpc_id(1)

@rpc("any_peer", "call_local", "reliable")
func card_pressed(id: int) -> void:
	if multiplayer.get_remote_sender_id() != players[currentPlayer].id:
		return
	var card = cardDict[id]
	if card.state == Global.State.REVEALED and card_to_turn == 0:
		if not can_i_select_this_letter(card.letter):
			return
		currentWord += card.letter
		var index = currentWord.length() - 1
		self.select_card.rpc(id, index)
		current.push_back(card)
		card.select()
		return

	if card.state == Global.State.SELECTED:
		return

	if card.state == Global.State.HIDDEN and card_to_turn > 0:
		self.turn_card.rpc(id)

@rpc("authority", "call_local", "reliable")
func score_and_cleanup_ui(tempScore : int, cardLeft: int, pid: int) -> void:
	players[currentPlayer].score += tempScore
	score_board.Add_score(pid ,tempScore)
	temp_score_val.text = "0"
	card_to_turn_label.text = str(cardLeft)

@rpc("authority", "call_local", "reliable")
func delete_card(id) -> void:
	var card = cardDict[id]
	cardDict.erase(id)
	card.queue_free()

func check_card_left():
	if hidddenCard >= 5:
		card_to_turn = card_to_return
	else:
		card_to_turn = hidddenCard

func score_and_cleanup() -> void:
	currentWord = ""
	var tempScore = 0
	for i in range (current.size()):
		tempScore += current[i].score
		if (is_capital(current[i].letter)):
			majLeft -= 1
		else:
			minLeft -= 1
		if (cardLeftInDeck > 0):
			var delay = (i * 4) * 0.04
			var letter = draw_letter()
			new_card.rpc(playzone.x + current[i].coords[0] * space_x,
			playzone.y + current[i].coords[1]  * space_y, idCount, letter, current[i].coords, delay)
		delete_card.rpc(current[i].id)
	current.clear()
	
	check_card_left()
	score_and_cleanup_ui.rpc(tempScore, card_to_turn, players[currentPlayer].id)
	endGameConditionCheck.rpc_id(1)

############################
#	utils
############################

func isMyTurn() -> bool:
	return multiplayer.get_remote_sender_id() == players[currentPlayer].id

func can_i_select_this_letter(letter: String) -> bool:
	var capital: bool = is_capital(letter)
	if capital and currentWord.length() == 0:
		return true
	if not capital and currentWord.length() > 0:
		return true
	return false

func is_capital(letter: String) -> bool:
	if (letter == "@"):
		return false
	return letter == letter.to_upper()

############################
#	helpers
############################

func count_joker(word: String) -> int:
	var number_of_joker := 0
	for c in word :
		if (c == '`' or c == '@') :
			number_of_joker += 1
	return number_of_joker

func S_cardPressed(id: int) -> void:
	self.card_pressed.rpc_id(1, id)

@rpc("authority", "call_local", "reliable")
func new_card(x: int, y: int, id: int, letter: String, coordinates: Vector2i, delay:= 0.0) -> void:
	idCount += 1
	var new = CARD.instantiate()
	new.position = deck_of_cards.position
	new.coords = coordinates
	new.id = id
	cardDict[id] = new
	new.originPos = Vector2(x, y)
	new.letter = letter
	new.score = cardValueDict[new.letter]
	new.frame = deck_color
	new.pressed_is.connect(S_cardPressed)
	cardsHolder.add_child(new)
	var tween = get_tree().create_tween()
	tween.tween_interval(delay)
	tween.tween_property(new, "position", Vector2(x, y), 0.8).set_trans(
		Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	updatecardLeftInDeck(-1)
	hidddenCard += 1

func clear_game() -> void:
	current.clear()
	currentWord = ""
	var cards: Array = cardsHolder.get_children()
	for i in range(cards.size()):
		cards[i].queue_free()

func new_game() -> void:
	clear_game()
	card_to_turn = card_to_return
	card_to_turn_label.text = str(card_to_return)
	
	if not multiplayer.is_server():
		return

	create_pool()
	for i in range(6):
		for y in range(4):
			var delay = (i * 4 + y) * 0.07
			var letter = draw_letter()
			var coordinates : Vector2i = Vector2i(i, y)
			self.new_card.rpc(playzone.x + i * space_x, playzone.y + y * space_y,
			idCount, letter, coordinates, delay)

############################
#	Letter pool
############################

func populate_card_value_dict() -> void:
	for group in cardValue:
		for letter in group.letters:
			cardValueDict.get_or_add(letter, group.value)

func updateMinMajCount(letter : String) -> void:
	if is_capital(letter):
		majLeft += 1
	else:
		minLeft += 1

func create_pool():
	letter_pool.clear()
	for group in cardDistribution[difficulty]:
		for letter in group.letters:
			for n in group.quantity:
				letter_pool.push_back(letter)
				updateMinMajCount(letter)
	updatecardLeftInDeck(len(letter_pool))

func draw_letter():
	var index = randi() % letter_pool.size()
	var letter = letter_pool[index]
	letter_pool.remove_at(index)
	return letter

############################
#	Main handlers
############################

@rpc("authority", "call_local", "reliable")
func initplayers(LobbyPlayers) -> void:
	for id in LobbyPlayers :
		players += [{"id": id,"score": 0,"name": LobbyPlayers[id].name}]
		score_board.Add_player(LobbyPlayers[id].name, id)
		score_board.Change_active_player(1, 1)

func _ready() -> void:
	if multiplayer.is_server() :
		var LobbyPlayers = Lobby.players
		initplayers.rpc(LobbyPlayers)

	playzone = Vector2i(int(zoning.position.x) + int(play_area.position.x),
		int(zoning.position.y) + int(play_area.position.y))
	handzone = Vector2(zoning.position.x + hand.position.x, zoning.position.y + hand.position.y)
	populate_card_value_dict()
	new_game()

func _process(_delta: float) -> void:
	pass

############################
#	buttons functions
############################

@rpc("authority", "call_local", "reliable")
func nextTurn() -> void:
	var temp = players[currentPlayer]
	currentPlayer += 1
	currentPlayer %= len(players)
	score_board.Change_active_player(players[currentPlayer].id, temp.id)

@rpc("any_peer", "call_local", "reliable")
func confirm() -> void:
	if multiplayer.get_remote_sender_id() != players[currentPlayer].id:
		return
	if (count_joker(currentWord) > 1):
		message.sendNotification("Seulement 1 joker est autorisé par mot !")
		return
	var words = Dict.exists(currentWord)
	if (len(words) > 0):
		score_and_cleanup()
		nextTurn.rpc()
	else:
		message.sendNotification("Ce mot n'est pas valide!")

@rpc("authority", "call_local", "reliable")
func delete_one_ui(id, val) -> void:
	var card = cardDict[id]
	update_temp_score(-val)
	card.deselect()
	card.resetPos()

@rpc("any_peer", "call_local", "reliable")
func delete_one() -> void:
	if not isMyTurn():
		return
	if not currentWord.length() > 0:
		return
	var letterValue = getCardValue(currentWord[currentWord.length() - 1])
	currentWord = currentWord.substr(0, currentWord.length() - 1)
	var card = current.pop_back()
	delete_one_ui.rpc(card.id, letterValue)

func reset_focus() -> void:
	if get_viewport().gui_get_focus_owner():
		get_viewport().gui_get_focus_owner().release_focus()

############################
#	buttons events
############################

func _input(event):
	if event.is_action_pressed("Delete"):
		delete_one.rpc_id(1)
	if event.is_action_pressed("Confirm"):
		if (rule_container.is_visible_in_tree()) :
			rule_container.hide()
			return
		confirm.rpc_id(1)

func _on_confirm_button_up() -> void:
	confirm.rpc_id(1)
	reset_focus()

func delete_all() -> void:
	pass

func _on_del_1_button_up() -> void:
	delete_one.rpc_id(1)
	reset_focus()

func _on_del_all_button_up() -> void:
	for i in range(current.size()):
		delete_one.rpc_id(1)
	reset_focus()

@rpc("authority", "call_local", "reliable")
func pass_turn_ui():
	reset_focus()
	check_card_left()
	card_to_turn_label.text = str(card_to_turn)

@rpc("any_peer", "call_local", "reliable")
func pass_turn():
	if not isMyTurn():
		return
	pass_turn_ui.rpc()
	nextTurn.rpc()

func _on_draw_new_card_button_up() -> void:
	pass_turn.rpc_id(1)

func _on_end_game_button_up() -> void:
	if multiplayer.is_server():
		endgame(false, "la partie a été arrêtée manuellement")
	else:
		message.sendNotification("seul l'hote a le droit de mettre fin à la partie.")


func _on_rules_pressed() -> void:
	rule_container.show()
	rules.release_focus()
	

func _on_validate_rule_pressed() -> void:
	rule_container.hide()
