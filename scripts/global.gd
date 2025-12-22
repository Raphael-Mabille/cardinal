extends Node

enum State {
	HIDDEN,
	REVEALED,
	SELECTED
}

enum Difficulty {
	EASY,
	MEDIUM,
	HARD
}

var current_scene = null
var currentRuleSet = ""

var tempString := ""
var difficulty := Difficulty.EASY
