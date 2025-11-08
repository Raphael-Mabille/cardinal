extends HBoxContainer

var score := 0

func setName(newName: String):
	var label_name : Label = self.get_child(0)
	label_name.text = newName + " : "

func addScore(newValue: int):
	score += newValue
	var label_val : Label = self.get_child(1)
	label_val.text = str(score)
