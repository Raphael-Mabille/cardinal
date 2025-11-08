extends Node

enum State {
	HIDDEN,
	REVEALED,
	SELECTED
}

var current_scene = null
var currentRuleSet = ""

var tempString := ""
