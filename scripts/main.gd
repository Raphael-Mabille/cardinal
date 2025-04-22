extends Node2D

const CARD = preload("res://scenes/card.tscn")

@export var card_to_return: int

@onready var score_label_val: Label = $score_label/score_label_val
@onready var play_area: Marker2D = $play_area
@onready var hand_label: Label = $hand/hand_label
@onready var card_left_label: Label = $card_left/card_left_label
@onready var deck_of_cards: AnimatedSprite2D = $deck_of_cards
@onready var temp_score_val: Label = $temp_score/temp_score_val

var deck_color: int = 0
var card_left = 0
var score: int = 0
var letter_pool: Array = []
var current: Array = []
var discarded: Array = []
var difficulty: String = "easy"

var cardDistribution = {
	"easy" : [
		{"letters": "ae", "quantity": 9 },
		{"letters": "iou", "quantity": 4},
		{"letters": "bcdfghmpvxz", "quantity": 1},
		{"letters": "*", "quantity": 8},
		{"letters": "AERTIOPSDFGHJLMCVBN?", "quantity": 1}
	],
	"medium" : [
		{"letters": "ae", "quantity": 9 },
		{"letters": "iou", "quantity": 4},
		{"letters": "bcdfghmpvxz", "quantity": 1},
		{"letters": "*", "quantity": 8},
		{"letters": "AERTIOPSDFGHJLMCVBN?", "quantity": 1}
	],
	"hard" : [
		{"letters": "ae", "quantity": 9 },
		{"letters": "iou", "quantity": 4},
		{"letters": "bcdfghmpvxz", "quantity": 1},
		{"letters": "*", "quantity": 8},
		{"letters": "AERTIOPSDFGHJLMCVBN?", "quantity": 1}
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
	{"letters": "*?", "value": 0}
]

var cardValueDict : Dictionary = {}


func is_ok(letter: String):
	var capital: bool = is_capital(letter)
	
	if capital and hand_label.text.length() == 0:
		return true
	if not capital and hand_label.text.length() > 0:
		return true
	return false

func is_capital(letter: String) -> bool:
	return letter == letter.to_upper()

func update_temp_score(letter: String, add: bool) -> void:
	var val : int = cardValueDict.get(letter);
	if not add :
		val *= - 1
	temp_score_val.text = str(val + int(temp_score_val.text))

func card_pressed(_id: int, card: Node) -> void:
	if card.state == Global.State.REVEALED and card_left == 0:
		if not is_ok(card.letter):
			return
		hand_label.text += card.letter
		update_temp_score(card.letter, 1);
		
		current.push_back(card)
		card.select()
		return

	if card.state == Global.State.SELECTED:
		return

	if card.state == Global.State.HIDDEN and card_left > 0:
		card_left -= 1
		card_left_label.text = str(card_left)
		if is_capital(card.letter):
			card.reveal(true)
		else:
			card.reveal(false)

func new_card(x: int, y: int, id: int) -> Node2D:
	var new = CARD.instantiate()
	new.position = Vector2i(x, y)
	new.id = id
	new.score = id
	new.frame = deck_color
	new.letter = draw_letter()
	new.pressed_is.connect(card_pressed)
	return new

func clear_game() -> void:
	current.clear()
	discarded.clear()
	score = 0
	hand_label.text = ""
	score_label_val.text = "0"
	var cards: Array = play_area.get_children()
	for i in range(cards.size()):
		cards[i].queue_free()

func new_game() -> void:
	clear_game()
	card_left = card_to_return
	card_left_label.text = str(card_to_return)
	create_pool()
	for i in range(5):
		for y in range(5):
			var card = new_card(i * 65, y * 70, i * 10 + y)
			play_area.add_child(card)


func change_color(deck: AnimatedSprite2D) -> void:
	deck_color = (deck.frame + 1) % 4
	deck.frame = deck_color
	var cards: Array = play_area.get_children()
	for i in range(cards.size()):
		if cards[i].state == Global.State.HIDDEN:
			cards[i].frame = deck_color

func populate_card_value_dict() -> void:
	for group in cardValue:
		for letter in group.letters:
			cardValueDict.get_or_add(letter, group.value)
	print(cardValueDict)
	

func _ready() -> void:
	populate_card_value_dict()
	new_game()
	deck_of_cards.pressed_is.connect(change_color)

func _process(_delta: float) -> void:
	pass

func is_a_word(_word: String) -> bool:
	return true

func score_and_cleanup() -> void:
	hand_label.text = ""

	for i in range (current.size()):
		score += current[i].score
		var x = current[i].id / 10
		var y = current[i].id % 10
		var new = new_card(x * 65, y  * 70, current[i].id)
		play_area.add_child(new)
		discarded.push_back(current[i].letter)
		current[i].queue_free()
	current.clear()
	
	score_label_val.text = str(score)
	card_left = card_to_return
	card_left_label.text = str(card_left)


func _input(event):
	if event.is_action_pressed("Delete"):
		delete_one()
		
	if event.is_action_pressed("Confirm"):
		confirm()


func create_pool():
	letter_pool.clear()
	for group in cardDistribution[difficulty]:
		for letter in group.letters:
			for n in group.quantity:
				letter_pool.push_back(letter)

func draw_letter():
	if letter_pool.size() == 0:
		letter_pool = discarded.duplicate()
		discarded.clear()
	var index = randi() % letter_pool.size()
	var letter = letter_pool[index]
	letter_pool.remove_at(index)
	return letter


func confirm() -> void:
	if hand_label.text.length() > 2 and is_a_word(hand_label.text):
		score_and_cleanup()

func delete_one() -> void:
	if not hand_label.text.length() > 0:
		return
	update_temp_score(hand_label.text[hand_label.text.length() - 1], 0)
	hand_label.text = hand_label.text.substr(0, hand_label.text.length() - 1)
	var card = current.pop_back()
	card.deselect()

func reset_focus() -> void:
	if get_viewport().gui_get_focus_owner():
		get_viewport().gui_get_focus_owner().release_focus()

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

func _on_new_game_button_up() -> void:
	new_game()
	reset_focus()
