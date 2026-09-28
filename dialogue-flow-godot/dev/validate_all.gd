@tool
extends EditorScript

func _run():
	var paths = find_tres_files("res://dev/dialogue_data")
	for p in paths:
		var res = load(p)
		if not (res is ConversationGraph):
			print("pass")
			continue
		var result = res.validate()
		if result["errors"].is_empty() and result["warnings"].is_empty():
			print("OK    ", p)
		else:
			print("ISSUE ", p)
			for e in result["errors"]:
				print("  ERROR:   ", e)
			for w in result["warnings"]:
				print("  Warning: ", w)

func find_tres_files(path: String) -> Array[String]:
	var results: Array[String] = []
	var dir = DirAccess.open(path)
	if dir == null:
		return results
	dir.list_dir_begin()
	var entry = dir.get_next()
	while entry != "":
		if not entry.begins_with("."):
			var full_path = path.path_join(entry)
			if dir.current_is_dir():
				results.append_array(find_tres_files(full_path))
			elif entry.ends_with(".tres"):
				results.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
	return results
