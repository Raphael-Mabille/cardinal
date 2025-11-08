extends Node

var index_by_length: Dictionary = {}

func _ready() -> void:
	var path = "res://assests/words.json"
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open file: %s" % path)
		return
	var json_result = JSON.parse_string(file.get_as_text())
	if not json_result:
		push_error("JSON parse error in %s" % [path])
		return
	var data = json_result
	index_by_length = data.get("index_by_length", {})
	print("Loaded index with %d length categories" % index_by_length.size())

# Search words matching the query with _ or ? wildcards
func exists(query: String) -> Array:
	var results := []
	
	query = query.to_lower()
	var len_w := query.length()
	var key := str(len_w)
	if not index_by_length.has(key):
		return results

	var candidates = index_by_length[key]

	for word in candidates:
		var my_match := true
		for i in len_w:
			var qc := query[i]
			if qc != '@' and qc != '`' and qc != word[i]:
				my_match = false
				break
		if my_match:
			results.append(word)

	return results
