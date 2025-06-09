extends Node2D

const CARD = preload("res://scenes/card.tscn")

@export var card_to_return: int

@onready var score_label_val: Label = $control/labels/score_label/score_label_val
@onready var play_area: Marker2D = $control/zoning/play_area
@onready var hand: Marker2D = $control/zoning/hand
@onready var zoning: Control = $control/zoning

@onready var card_to_turn_label: Label = $control/labels/cardToTurn/cardToTurnLabel
@onready var deck_of_cards: Sprite2D = $deck_of_cards
@onready var max_score_label: Label = $control/labels/maxScore/maxScoreLabel
@onready var difficulty_label: Label = $control/labels/difficulty/difficulty_label
@onready var card_left_label: Label = $control/labels/cardLeft/cardLeftLabel
@onready var cardsHolder: Node = $cardsHolder

var playzone = Vector2i(0, 0)
var handzone = Vector2i(0, 0)
var deck_color: int = 0
var card_to_turn = 0
var score: int = 0
var letter_pool: Array = []
var current: Array = []
var discarded: Array = []
var difficulty: String = "easy"
var cardCount: int = 0
var currentWord: String = ""
var space_x = 70
var space_y = 95

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
	"easy": "débutant",
	"medium": "confirmé",
	"hard": "expert"
}

var cardDistribution = {
	"easy" : [
		{"letters": "ae", "quantity": 9 },
		{"letters": "iou", "quantity": 5},
		{"letters": "lnrst", "quantity": 4},
		{"letters": "bcdfghmpvxz", "quantity": 1},
		{"letters": "@", "quantity": 8},
		{"letters": "AERTIOPSDFGHJLMCVBN`", "quantity": 1}
	],
	"medium" : [
		{"letters": "ae", "quantity": 10 },
		{"letters": "iou", "quantity": 6},
		{"letters": "lnrst", "quantity": 4},
		{"letters": "cdfmp", "quantity": 2},
		{"letters": "bghvqxyz", "quantity": 1},
		{"letters": "@", "quantity": 8},
		{"letters": "AERTIOPSDFGHJLMCVBNKQUZ`", "quantity": 1}
	],
	"hard" : [
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

############################
#	labels
############################

@onready var temp_score_val: Label = $control/labels/temp_score/temp_score_val

func update_temp_score(letter: String, add: bool) -> void:
	var val : int = cardValueDict.get(letter);
	if not add :
		val *= - 1
	temp_score_val.text = str(val + int(temp_score_val.text))

func updateCardCount(val: int) -> void:
	cardCount += val
	card_left_label.text = str(cardCount)

############################
#	game logic
############################

func card_pressed(_id: int, card: Node) -> void:
	if card.state == Global.State.REVEALED and card_to_turn == 0:
		if not can_i_select_this_letter(card.letter):
			return
		currentWord += card.letter
		var index = currentWord.length() - 1
		card.moveTo(handzone + Vector2(index * (space_x - space_x / 10), 0))
		update_temp_score(card.letter, 1);
		
		current.push_back(card)
		card.select()
		return

	if card.state == Global.State.SELECTED:
		return

	if card.state == Global.State.HIDDEN and card_to_turn > 0:
		card_to_turn -= 1
		card_to_turn_label.text = str(card_to_turn)
		if is_capital(card.letter):
			card.reveal(true)
		else:
			card.reveal(false)

func score_and_cleanup() -> void:
	currentWord = ""

	for i in range (current.size()):
		score += current[i].score
		var x = current[i].id / 10
		var y = current[i].id % 10
		if (cardCount > 0):	
			var delay = (i * 4) * 0.04
			new_card(playzone.x + x * space_x, playzone.y + y  * space_y, current[i].id, delay)
		discarded.push_back(current[i].letter)
		current[i].queue_free()
	current.clear()
	
	score_label_val.text = str(score)
	card_to_turn = card_to_return
	if (cardCount == 0):
		var childs = cardsHolder.get_children()
		var tmp : int = 0
		for child in childs:
			if child.state == Global.State.HIDDEN:
				tmp += 1
		if tmp < 5:
			card_to_turn = tmp
	card_to_turn_label.text = str(card_to_turn)
	temp_score_val.text = "0"

############################
#	utils
############################

func can_i_select_this_letter(letter: String):
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

func new_card(x: int, y: int, id: int, delay:= 0.0) -> void:
	var new = CARD.instantiate()
	new.position = deck_of_cards.position
	new.id = id
	new.originPos = Vector2(x, y)
	new.letter = draw_letter()
	new.score = cardValueDict[new.letter]
	new.frame = deck_color
	new.pressed_is.connect(card_pressed)
	cardsHolder.add_child(new)
	var tween = get_tree().create_tween()
	tween.tween_interval(delay)
	tween.tween_property(new, "position", Vector2(x, y), 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	updateCardCount(-1)

func clear_game() -> void:
	current.clear()
	discarded.clear()
	score = 0
	currentWord = ""
	score_label_val.text = "0"
	var cards: Array = cardsHolder.get_children()
	for i in range(cards.size()):
		cards[i].queue_free()

func new_game() -> void:
	clear_game()
	card_to_turn = card_to_return
	card_to_turn_label.text = str(card_to_return)
	create_pool()
	for i in range(6):
		for y in range(4):
			var delay = (i * 4 + y) * 0.07
			new_card(playzone.x + i * space_x, playzone.y + y * space_y, i * 10 + y, delay)


############################
#	Letter pool
############################

func populate_card_value_dict() -> void:
	for group in cardValue:
		for letter in group.letters:
			cardValueDict.get_or_add(letter, group.value)

func create_pool():
	letter_pool.clear()
	for group in cardDistribution[difficulty]:
		for letter in group.letters:
			for n in group.quantity:
				letter_pool.push_back(letter)
	updateCardCount(len(letter_pool))

func draw_letter():
	var index = randi() % letter_pool.size()
	var letter = letter_pool[index]
	letter_pool.remove_at(index)
	return letter

############################
#	Main handlers
############################


func _ready() -> void:
	playzone = Vector2i(int(zoning.position.x) + int(play_area.position.x), int(zoning.position.y) + int(play_area.position.y))
	handzone = Vector2(zoning.position.x + hand.position.x, zoning.position.y + hand.position.y)
	populate_card_value_dict()
	difficulty_label.text = difficultyName[difficulty]
	max_score_label.text = str(maxScore[difficulty])
	new_game()

func _process(_delta: float) -> void:
	pass


############################
#	buttons functions
############################

func confirm() -> void:
	var words = Dict.exists(currentWord)
	if (len(words) > 0):
		score_and_cleanup()
	else:
		print("ce mot n'est pas valide!")

func delete_one() -> void:
	if not currentWord.length() > 0:
		return
	update_temp_score(currentWord[currentWord.length() - 1], 0)
	currentWord = currentWord.substr(0, currentWord.length() - 1)
	var card = current.pop_back()
	card.deselect()
	card.resetPos()

func reset_focus() -> void:
	if get_viewport().gui_get_focus_owner():
		get_viewport().gui_get_focus_owner().release_focus()

############################
#	buttons events
############################

func _input(event):
	if event.is_action_pressed("Delete"):
		delete_one()
		
	if event.is_action_pressed("Confirm"):
		confirm()

func _on_confirm_button_up() -> void:
	confirm()
	reset_focus()

func _on_del_1_button_up() -> void:
	delete_one()
	reset_focus()

func _on_del_all_button_up() -> void:
	for i in range(current.size()):
		delete_one()
	reset_focus()

func _on_draw_new_card_button_up() -> void:
	reset_focus()
	card_to_turn = card_to_return
	card_to_turn_label.text = str(card_to_turn)

func _on_end_game_button_up() -> void:
	pass # Replace with function body.
