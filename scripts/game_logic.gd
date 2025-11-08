extends Node
const CARD = preload("res://scenes/card.tscn")

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
	pass

############################
#	game logic
############################

func card_pressed(_id: int, card: Node) -> void:
	pass

func score_and_cleanup() -> void:
	pass

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
	pass

func clear_game() -> void:
	pass

func new_game() -> void:
	clear_game()
	create_pool()
	for i in range(6):
		for j in range(4):
			var delay = (i * 4 + j) * 0.07
			var x = playzone.x + i * space_x
			var y = playzone.y + j * space_y
			var line = i * 10 + j
			self.new_card.rpc(x, y, line, delay)


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
	new_game()

func _process(_delta: float) -> void:
	pass

############################
#	buttons functions
############################

############################
#	buttons events
############################
