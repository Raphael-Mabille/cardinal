extends AnimatedSprite2D

@export var id : int
@export var letter : String = "`"
@export var score : int
@export var coords : Vector2i
@onready var value: Label = $value

var state: int = Global.State.HIDDEN
var capital: bool = false
var originPos: Vector2i = Vector2i(0, 0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func moveTo(newPos: Vector2) -> void:
	position = newPos

func resetPos() -> void:
	position = originPos

signal pressed_is

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		pressed_is.emit(id)

func select() -> void:
	state = Global.State.SELECTED

func letter_to_index(_letter: String) -> int:
	if (_letter == '`'):
		return 0
	return _letter.to_upper().unicode_at(0) - "A".unicode_at(0) + 1

func reveal(maj: bool) -> void:
	capital = maj
	state = Global.State.REVEALED
	if maj:
		value.add_theme_color_override("font_color", Color("#B82010"))
		animation = "maj"
		frame = letter_to_index(letter)
	else:
		value.add_theme_color_override("font_color", Color("#4485c6"))
		animation = "min"
		frame = letter_to_index(letter)

func deselect() -> void:
	state = Global.State.REVEALED
