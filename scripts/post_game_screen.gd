extends Control

const GAME_SELECTION = preload("res://scenes/game_selection.tscn")

@onready var end_reason: Label = $endReason
@onready var score_board: Control = $ScoreBoard

func getTopScore(players: Array):
	var topScore = 0
	var index = 0
	var i = 0
	for player in players:
		if player.score > topScore:
			topScore = player.score
			index = i
		i += 1
	return index

func setMsg(msg : String) -> void:
	end_reason.text = msg

func getSize(n : int) -> int:
	if n > 4:
		return 24
	else :
		return 64 - n * 8

func setScores(players: Array) -> void:
	var n = 1
	while not players.is_empty():
		var index = getTopScore(players)
		var player = players[index]
		score_board.Add_player(str(n) + " - " + player.name, player.id, player.score)
		score_board.SetFontSize(player.id, getSize(n))
		players.pop_at(index)
		n += 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_button_pressed() -> void:
	Lobby.stop_game()
	Global.difficulty = Global.Difficulty.EASY
	Transition.change_scene(GAME_SELECTION)
