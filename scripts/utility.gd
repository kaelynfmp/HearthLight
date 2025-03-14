@tool
## For utility functions that can be run in editor as well as game.

extends Node

func _enter_tree():
	pass

func load_path(path:String, strings_list:Array[String] = []) -> Array[String]:
	var dir: DirAccess = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while true:
			if file_name == "":
				break
			if file_name.ends_with(".remap"):
				file_name = file_name.trim_suffix(".remap")
			if file_name.ends_with(".tres"):
				if dir.current_is_dir():
					strings_list = load_path(dir.get_current_dir(), strings_list)
				else:
					var full_path:String = path + "/" + file_name
					strings_list.append(full_path)
				# found
				file_name = dir.get_next()
		dir.list_dir_end()
		return strings_list
	else:
		assert(dir != null, "Directory not found! Should be at " + path)
		return []

## Takes a [String] and a [RichTextLabel] and truncates the label to its width, appending '...', while accounting for
## BBCode sizing.
func set_truncated_text(text:String, label:RichTextLabel) -> void:
	var result:String = ""
	var visible_width:float = 0.0
	var width:float = label.get_size().x
	var tokens:Array[String] = parse_bbcode(text)

	for token in tokens:
		label.set_text(token)
		visible_width += label.get_content_width()
		if visible_width > width:
			result += "..."
			label.set_text(result)
			return
		result += token

	label.set_text(result)

## Takes words and BBCode-entries in a [String] and returns an array of individual 'tokens'. A token is either a word
## seperated by spaces, or a section surrounded by BBCode.
func parse_bbcode(text:String) -> Array[String]:
	# Truncates text while accounting for BBCode
	var tokens:Array[String] = []
	var pos:int = 0
	while pos < text.length():
		var next_tag_pos:int = text.find("[", pos)
		var next_space_pos:int = text.find(" ", pos)
		if next_tag_pos == -1:
			if next_space_pos == -1:
				tokens.append(text.substr(pos, text.length() - pos))
				break
			tokens.append(text.substr(pos, next_space_pos + 1 - pos))
			pos = next_space_pos + 1
			continue

		if next_tag_pos > pos:
			if next_space_pos != -1 and next_space_pos < next_tag_pos:
				tokens.append(text.substr(pos, next_space_pos + 1 - pos))
				pos = next_space_pos + 1
				continue
			tokens.append(text.substr(pos, next_tag_pos - pos))

		var end_tag_pos:int = text.find("]", next_tag_pos)
		if end_tag_pos == -1:
			# invalid bbcode
			tokens.append(text.substr(next_tag_pos, text.length() - next_tag_pos))
			push_warning("Incorrect BBCode, opening tag invalid: " + text)

		var tag_str:String = text.substr(next_tag_pos, end_tag_pos - next_tag_pos + 1)
		var contents_start_pos:int = next_tag_pos + tag_str.length()
		var contents_end_pos:int = text.find("[/", next_tag_pos)
		if contents_end_pos == -1:
			tokens.append(tag_str)
			pos += tag_str.length()
			push_warning("Incorrect BBCode, missing closing tag to opening tag \'" + tag_str + "\'. Total text: " + text)
			continue
		var contents_str:String = text.substr(contents_start_pos, contents_end_pos - contents_start_pos)
		var closing_tag_end_pos:int = text.find("]", contents_end_pos)
		if closing_tag_end_pos == -1:
			tokens.append(tag_str + contents_str)
			pos += tag_str.length() + contents_str.length()
			push_warning("Incorrect BBCode, closing tag invalid: " + text)
			continue
		var closing_tag_str:String = text.substr(contents_end_pos, closing_tag_end_pos - contents_end_pos + 1)
		var token:String = tag_str + contents_str + closing_tag_str

		tokens.append(token)
		pos = closing_tag_end_pos + 1
	return tokens
