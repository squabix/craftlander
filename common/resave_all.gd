@tool
extends EditorScript

func _run():
	var dir = DirAccess.open("res://")
	var processed_count := _process_dir("res://")
	print("Batch save complete! Processed %s files" % processed_count)

func _process_dir(path) -> int:
	var count := 0
	var dir = DirAccess.open(path)
	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir():
			if not file_name.begins_with("."):
				count += _process_dir(path + file_name + "/")
		else:
			if file_name.ends_with(".tscn") or file_name.ends_with(".tres"):
				var full_path = path + file_name
				var res = load(full_path)
				if res:
					ResourceSaver.save(res, full_path)
					print("Updated: ", file_name)
					count += 1
		file_name = dir.get_next()
	return count
