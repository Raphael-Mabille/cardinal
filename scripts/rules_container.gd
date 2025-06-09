extends VBoxContainer

const BUTTON = preload("res://scenes/button.tscn")

const simple_rules = ["CARTOMANIE", "CHAPARDAGE", "DILEMME", "CROISELETTRE", "RECTO", "RÉPLICK"]
const medium_rules = ["BELETTRE", "CHAMOT", "DECRESCENDO", "GIZEH", "HEPTAGRAMME", "HUITARMORICAIN", "KALÉIDOSCOPE", "TAMBOUILLE"]
const hard_rules = ["ABALETTRE", "CROISILLON", "CUMULOVERBUS", "EMBROUILLAMINI", "GRAPHICK", "ZIGZAG"]
const expert_rules = []

func rule_bt_pressed(rule_name: String) -> void:
	Global.currentRuleSet = rule_name

func create_button(rule_name: String) -> void:
	var bt = BUTTON.instantiate()
	bt.text = rule_name
	bt.pressed_is.connect(rule_bt_pressed)
	add_child(bt)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for rule_name in simple_rules:
		create_button(rule_name)
		
	for rule_name in medium_rules:
		create_button(rule_name)
		
	for rule_name in hard_rules:
		create_button(rule_name)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
