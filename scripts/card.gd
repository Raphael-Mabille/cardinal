extends AnimatedSprite2D

@export var id : int
@export var letter : String
@export var score : int
@onready var value: Label = $value

var state: int = Global.State.HIDDEN
var capital: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


signal pressed_is

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		pressed_is.emit(id, self)

func select() -> void:
	state = Global.State.SELECTED
	play("selected")

func reveal(maj: bool) -> void:
	value.text = letter
	capital = maj
	state = Global.State.REVEALED
	if maj:
		play("majuscule")
	else:
		play("minuscule")

func deselect() -> void:
	state = Global.State.REVEALED
	if capital:
		play("majuscule")
	else:
		play("minuscule")
