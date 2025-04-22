extends VBoxContainer

const BUTTON = preload("res://scenes/button.tscn")

@onready var v_box_container: VBoxContainer = $"../../rules_container/VBoxContainer"

const CARTOMANIE_REGLE_1 = null
const CARTOMANIE_REGLE_2 = null

const simple_rules = ["CARTOMANIE", "CHAPARDAGE", "DILEMME", "CROISELETTRE", "RECTO", "RÉPLICK"]
const medium_rules = ["BELETTRE", "CHAMOT", "DECRESCENDO", "GIZEH", "HEPTAGRAMME", "HUITARMORICAIN", "KALÉIDOSCOPE", "TAMBOUILLE"]
const hard_rules = ["ABALETTRE", "CROISILLON", "CUMULOVERBUS", "EMBROUILLAMINI", "GRAPHICK", "ZIGZAG"]
const expert_rules = []

const rules_pdf = {
	"CARTOMANIE": [CARTOMANIE_REGLE_1, CARTOMANIE_REGLE_2]
}

func reset_Vbox_child() -> void:
	for child in v_box_container.get_children():
		child.queue_free()

func new_sprite(png_name) -> Sprite2D:
	var new : Sprite2D = Sprite2D.new()
	new.texture = png_name
	new.scale = Vector2(0.8,0.8)
	new.position = Vector2i(400, 0)
	return new

func rule_bt_pressed(rule_name: String) -> void:
	print(rule_name)
	reset_Vbox_child()
	print(rules_pdf)
	print(rules_pdf[rule_name])
	for page in rules_pdf[rule_name]:
		print(page)
		var new = new_sprite(page)
		v_box_container.add_child(new)
	

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
