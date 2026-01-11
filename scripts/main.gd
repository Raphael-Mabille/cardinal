extends Node2D

const CARD = preload("res://scenes/card.tscn")
const CONFIRM_BOX = preload("res://scenes/confirm_box.tscn")
const NUMBER_OF_CARD_PER_TURN = 5

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

var deck_color: int = 0
var card_to_turn = 0
var letter_pool: Array = []
var cards_in_hand: Array = []
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

#---------------------------------- INPUTS -----------------------------------#

func _on_draw_new_card_button_up() -> void:
	pass_turn.rpc_id(1)

func _on_end_game_button_up() -> void:
	if multiplayer.is_server():
		endgame.rpc_id(1, false, "la partie a été arrêtée manuellement")
	else:
		message.sendNotification("seul l'hote a le droit de mettre fin à la partie.")

# this button is for the end_game context window
func _on_confirm_button_up() -> void:
	confirm.rpc_id(1)
	reset_focus()

func _on_del_all_button_up() -> void:
	for i in range(cards_in_hand.size()):
		delete_one.rpc_id(1)
	reset_focus()

func _on_del_1_button_up() -> void:
	delete_one.rpc_id(1)
	reset_focus()

func _input(event):
	if event.is_action_pressed("Delete"):
		delete_one.rpc_id(1)
	if event.is_action_pressed("Confirm"):
		if (rule_container.is_visible_in_tree()) :
			rule_container.hide()
			return
		confirm.rpc_id(1)

func _on_card_pressed(id: int) -> void:
	card_pressed.rpc_id(1, id)

#-------------------------------- INDEPENDENT --------------------------------#

func _on_rules_pressed() -> void:
	rule_container.show()
	rules.release_focus()

func _on_validate_rule_pressed() -> void:
	rule_container.hide()

func reset_focus() -> void:
	if get_viewport().gui_get_focus_owner():
		get_viewport().gui_get_focus_owner().release_focus()

#------------------------------------ UI -------------------------------------#

@rpc("authority", "call_local", "reliable")
func pass_turn_ui():
	reset_focus()
	set_card_to_turn()
	card_to_turn_label.text = str(card_to_turn)

@rpc("authority", "call_local", "reliable")
func delete_one_ui(id, val) -> void:
	var card = cardDict[id]
	temp_score_val.text = str(int(temp_score_val.text) - val)
	card.deselect()
	card.resetPos()

@rpc("authority", "call_local", "reliable")
func send_notification_ui(notif : String) :
	message.sendNotification(notif)

@rpc("authority", "call_local", "reliable")
func next_turn_ui(current_player_id, next_player_id) -> void:
	score_board.Change_active_player(next_player_id, current_player_id)

@rpc("authority", "call_local", "reliable")
func init_players_ui(LobbyPlayers) -> void:
	for id in LobbyPlayers :
		players += [{"id": id,"score": 0,"name": LobbyPlayers[id].name}]
		score_board.Add_player(LobbyPlayers[id].name, id)
		score_board.Change_active_player(1, 1)

@rpc("authority", "call_local", "reliable")
func update_card_to_turn_ui(n : int) -> void:
	card_to_turn_label.text = str(n)

@rpc("authority", "call_local", "reliable")
func select_card_ui(id: int, index : int) -> void:
	var card = cardDict[id]
	card.moveTo(hand.position + Vector2(index * (space_x - space_x / 10.0), 0))
	var val = cardValueDict.get(card.letter)
	temp_score_val.text = str(int(temp_score_val.text) + val)

@rpc("authority", "call_local", "reliable")
func update_card_left_in_deck_ui(newVal: int) -> void:
	card_left_label.text = str(newVal)
	if newVal == 0:
		deck_of_cards.hide()

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
	new.pressed_is.connect(_on_card_pressed)
	cardsHolder.add_child(new)
	var tween = get_tree().create_tween()
	tween.tween_interval(delay)
	tween.tween_property(new, "position", Vector2(x, y), 0.8).set_trans(
		Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	hidddenCard += 1

@rpc("authority", "call_local", "reliable")
func delete_card_ui(id) -> void:
	var card = cardDict[id]
	cardDict.erase(id)
	card.queue_free()

@rpc("authority", "call_local", "reliable")
func score_and_cleanup_ui(tempScore : int, cardLeft: int, pid: int) -> void:
	players[currentPlayer].score += tempScore
	score_board.Add_score(pid ,tempScore)
	temp_score_val.text = "0"
	card_to_turn_label.text = str(cardLeft)

@rpc("authority", "call_local", "reliable")
func turn_card_ui(id, newVal):
	var card = cardDict[id]
	card_to_turn_label.text = str(newVal)
	if is_capital(card.letter):
		card.reveal(true)
	else:
		card.reveal(false)

@rpc("authority", "call_local", "reliable")
func gotoGameScore(msg : String) :
	control.hide()
	deck_of_cards.hide()
	cardsHolder.hide()

	post_game_screen.show()
	post_game_screen.setMsg(msg)
	post_game_screen.setScores(players)

@rpc("authority", "call_local", "reliable")
func populate_card_value_dict() -> void:
	for group in cardValue:
		for letter in group.letters:
			cardValueDict.get_or_add(letter, group.value)

#---------------------------------- SERVER -----------------------------------#

@rpc("any_peer", "call_local", "reliable")
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
func pass_turn():
	if not is_sender_turn():
		return
	nextTurn()
	pass_turn_ui.rpc()

@rpc("any_peer", "call_local", "reliable")
func delete_one() -> void:
	if not is_sender_turn():
		return
	if not currentWord.length() > 0:
		return
	var letterValue = cardValueDict.get(currentWord[currentWord.length() - 1])
	currentWord = currentWord.substr(0, currentWord.length() - 1)
	var card = cards_in_hand.pop_back()
	delete_one_ui.rpc(card.id, letterValue)

@rpc("any_peer", "call_local", "reliable")
func confirm() -> void:
	var senderId = multiplayer.get_remote_sender_id()
	if senderId != players[currentPlayer].id:
		return
	if (count_joker(currentWord) > 1):
		send_notification_ui.rpc_id(senderId, "Seulement 1 joker est autorisé par mot !")
		return
	var words = Dict.exists(currentWord)
	if (len(words) > 0):
		score_and_cleanup()
		nextTurn()
	else:
		send_notification_ui.rpc_id(senderId, "Ce mot n'est pas valide!")

@rpc("any_peer", "call_local", "reliable")
func card_pressed(id: int) -> void:
	if not is_sender_turn():
		return
	var card = cardDict[id]
	if card.state == Global.State.SELECTED:
		return
	if card.state == Global.State.REVEALED and card_to_turn == 0:
		if not can_i_select_this_letter(card.letter):
			return
		currentWord += card.letter
		var index = currentWord.length() - 1
		select_card_ui.rpc(id, index)
		cards_in_hand.push_back(card)
		card.select()

	if card.state == Global.State.HIDDEN and card_to_turn > 0:
		card_to_turn -= 1
		hidddenCard -= 1
		turn_card_ui.rpc(id, card_to_turn)
		if card_to_turn == 0 :
			checkCapital(multiplayer.get_remote_sender_id())

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

func count_joker(word: String) -> int:
	var number_of_joker := 0
	for c in word :
		if (c == '`' or c == '@') :
			number_of_joker += 1
	return number_of_joker

func nextTurn() -> void:
	var temp = players[currentPlayer]
	currentPlayer += 1
	currentPlayer %= len(players)
	next_turn_ui.rpc(temp.id, players[currentPlayer].id)

func _ready() -> void:
	if not multiplayer.is_server() :
		return

	init_players_ui.rpc(Lobby.players)
	populate_card_value_dict.rpc()
	new_game()

func update_min_maj_count(letter : String, negative : int = 1) -> void:
	if is_capital(letter):
		majLeft += 1 * negative
	else:
		minLeft += 1 * negative

func create_pool():
	letter_pool.clear()
	for group in cardDistribution[difficulty]:
		for letter in group.letters:
			for n in group.quantity:
				letter_pool.push_back(letter)
				update_min_maj_count(letter)
	cardLeftInDeck = len(letter_pool)
	update_card_left_in_deck_ui.rpc(cardLeftInDeck)

func draw_letter():
	var index = randi() % letter_pool.size()
	var letter = letter_pool[index]
	letter_pool.remove_at(index)
	return letter

func new_game() -> void:
	card_to_turn = NUMBER_OF_CARD_PER_TURN
	update_card_to_turn_ui.rpc(NUMBER_OF_CARD_PER_TURN)

	create_pool()
	for i in range(6):
		for y in range(4):
			var delay = (i * 4 + y) * 0.07
			var letter = draw_letter()
			var coordinates : Vector2i = Vector2i(i, y)
			new_card.rpc(i * space_x, y * space_y,
			idCount, letter, coordinates, delay)
			cardLeftInDeck += 1
			update_card_left_in_deck_ui.rpc(cardLeftInDeck)

func score_and_cleanup() -> void:
	currentWord = ""
	var i_score = 0
	for i in range (cards_in_hand.size()):
		i_score += cards_in_hand[i].score
		update_min_maj_count(cards_in_hand[i].letter, -1)
		if (cardLeftInDeck > 0):
			var delay = (i * 4) * 0.04
			var letter = draw_letter()
			new_card.rpc(cards_in_hand[i].coords[0] * space_x, cards_in_hand[i].coords[1] * space_y,
						 idCount, letter, cards_in_hand[i].coords, delay)
			cardLeftInDeck -= 1
			update_card_left_in_deck_ui.rpc(cardLeftInDeck)
		delete_card_ui.rpc(cards_in_hand[i].id)
	cards_in_hand.clear()
	
	set_card_to_turn()
	score_and_cleanup_ui.rpc(i_score, card_to_turn, players[currentPlayer].id)
	endGameConditionCheck()

func set_card_to_turn():
	if hidddenCard >= 5:
		card_to_turn = NUMBER_OF_CARD_PER_TURN
	else:
		card_to_turn = hidddenCard

func endGameConditionCheck() -> void:
	if majLeft == 0:
		endgame(true, "Il n'y a plus aucune majuscule dans le paquet")

func is_sender_turn() -> bool:
	return multiplayer.get_remote_sender_id() == players[currentPlayer].id

func cancel() :
	confirmBox.queue_free()

func checkCapital(senderId) -> void:
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
		send_notification_ui.rpc_id(senderId,
		"aucune majuscule n'est disponible, votre tour a été automatiquement passé")
	if not lower:
		send_notification_ui.rpc_id(senderId, 
		"aucune minuscule n'est disponible, votre tour a été automatiquement passé")
	pass_turn.rpc_id(1)
