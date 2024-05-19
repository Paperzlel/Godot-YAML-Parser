class_name YAMLParser
extends Resource

# Class for a parser that turns YAML "code" into a dictionary to use in Godot
# The number of indents equals the level an item is at in the dictionary
# 
# Please NOTE: This will only save items in a key : value pair, so functions
# will have to be parsed from its text to function form


# Filepath for the YAML file. Change this to where your YAML files will be, or
# convert to an array for multiple file paths
var filepath : Variant = "res://dialogue/%s.yaml"

# Dictionary that holds all of the YAML information
var yaml_dict : Dictionary = { }

# String for the last key
var current_region : String = ""

var previous_key = ""
var previous_indent = 0

var has_read_first_line : bool = false


func _init(n_filepath : String):
	filepath = n_filepath


# Checks if the given line has an indentation in it.
# Returns false if no, true if yes.
func has_indent(line : String) -> bool:
	var line2 = line
	if line2.dedent() == line:
		return false
	return true


# Checks a line and returns the number of indents in that line. 0 is none.
func get_indent_count(line : String) -> int:
	var line2 = line.dedent()
	if line2 == line:
		return 0
	return len(line) - len(line2)


# Finds the filepath for the given YAML file and parses it into a Dictionary
func get_and_parse_npc_yaml_file(name : String) -> Dictionary:
	var dialogue_filepath = filepath % name
	if not FileAccess.file_exists(dialogue_filepath):
		return { }
	var file = FileAccess.open(dialogue_filepath, FileAccess.READ)
	
	var current_keys : Array = []
	while file.get_position() < file.get_length():
		var line = file.get_line()
		var has_value : bool = false
		
		var regex = RegEx.new()
		regex.compile(".+:.+[a-zA-Z0-9]")
		if regex.search(line):
			has_value = true
		
		current_keys = add_contents_to_dict(line, 
				current_keys, 
				has_value)
		
	# TODO: remove
	return yaml_dict


func parse_key_and_value(line : String) -> PackedStringArray:
	# Array 0 = key, 1 = value
	var line_array = line.split(":", true)
	return line_array

# Adds the current key-value pair to the dictionary. Returns an array of the
# next iteration of keys
func add_contents_to_dict(line : String, 
			keys : Array, 
			has_value : bool) -> Array:
	var dict = yaml_dict
	
	var indent_count = get_indent_count(line)
	var keys_size = keys.size()
	var line_array = parse_key_and_value(line)
	
	var key = line_array[0].dedent()
	var value
	
	
	if indent_count == 0 and keys_size > 0:
		keys.clear()
		keys.append(key)
		current_region = key
	
	elif keys_size == indent_count:
		keys.append(key)
		if not has_read_first_line:
			current_region = key
			has_read_first_line = true
	
	elif keys_size == indent_count + 1:
		var n_key = keys.pop_back()

		if n_key == key:
			keys.push_back(n_key)
		else:
			keys.push_back(key)
			
	elif keys_size > indent_count + 1:
		while keys_size > indent_count:
			keys.pop_back()
			keys_size = keys.size()
		keys.push_back(key)
	
	
	if has_value and len(line_array) > 1:
		value = line_array[1]
		value = value.right(-1)
	
	match indent_count:
		0:
			if has_value:
				dict[key] = value
			else:
				dict[key] = Dictionary()
		1:
			if has_value:
				if previous_key == key:
					if typeof(dict[keys[0]][key]) != TYPE_ARRAY:
						var value_copy = dict[keys[0]][key]
						dict[keys[0]][key] = Array()
						dict[keys[0]][key].append(value_copy)
						dict[keys[0]][key].append(value)
					else:
						dict[keys[0]][key].append(value)
				else:
					dict[keys[0]][key] = value
			else:
				if previous_key == key:
					if typeof(dict[keys[0]][key]) != TYPE_ARRAY:
						var value_copy = dict[keys[0]][key]
						dict[keys[0]][key] = Array()
						dict[keys[0]][key].append(value_copy)
						dict[keys[0]][key].append(value)
				else:
					# Technically this means having a dict as a point in
					# an array is impossible, but we don't really need that
					# so I've omitted it.
					dict[keys[0]][key] = Dictionary()
		2:
			if has_value:
				if previous_key == key:
					if typeof(dict[keys[0]][keys[1]]) == TYPE_ARRAY:
						var dict_in_array = dict[keys[0]][keys[1]] \
							[dict[keys[0]][keys[1]].size() - 1]
						
						if typeof(dict_in_array[key]) != TYPE_ARRAY:
							dict[keys[0]][keys[1]].erase(dict_in_array)
							var value_copy = dict_in_array[key]
							dict_in_array[key] = Array()
							dict_in_array[key].append(value_copy)
							dict_in_array[key].append(value)
							dict[keys[0]][keys[1]].append(dict_in_array)
							
					elif typeof(dict[keys[0]][keys[1]][key]) != TYPE_ARRAY:
						var value_copy = dict[keys[0]][keys[1]][key]
						dict[keys[0]][keys[1]][key] = Array()
						dict[keys[0]][keys[1]][key].append(value_copy)
						dict[keys[0]][keys[1]][key].append(value)
					else:
						dict[keys[0]][keys[1]][key].append(value)
				else:
					dict[keys[0]][keys[1]][key] = value
			else:
				if previous_key == key:
					if typeof(dict[keys[0]][keys[1]][key]) != TYPE_ARRAY:
						var value_copy = dict[keys[0]][keys[1]][key]
						dict[keys[0]][keys[1]][key] = Array()
						dict[keys[0]][keys[1]][key].append(value_copy)
						dict[keys[0]][keys[1]][key].append(value)
				else:
					dict[keys[0]][keys[1]][key] = Dictionary()
		3:
			if has_value:
				if previous_key == key:
					if typeof(dict[keys[0]][keys[1]][keys[2]]) == TYPE_ARRAY:
						var dict_in_array = dict[keys[0]][keys[1]][keys[2]] \
							[dict[keys[0]][keys[1]][keys[2]].size() - 1]
					
						if typeof(dict_in_array[key]) != TYPE_ARRAY:
							dict[keys[0]][keys[1]][keys[2]][key].erase(dict_in_array)
							var value_copy = dict_in_array[key]
							dict_in_array[key] = Array()
							dict_in_array[key].append(value_copy)
							dict_in_array[key].append(value)
							dict[keys[0]][keys[1]].append(dict_in_array)
							
					elif typeof(dict[keys[0]][keys[1]][keys[2]][key]) != TYPE_ARRAY:
						var value_copy = dict[keys[0]][keys[1]][keys[2]][key]
						dict[keys[0]][keys[1]][keys[2]][key] = Array()
						dict[keys[0]][keys[1]][keys[2]][key].append(value_copy)
						dict[keys[0]][keys[1]][keys[2]][key].append(value)
					else:
						dict[keys[0]][keys[1]][keys[2]][key].append(value)
				else:
					dict[keys[0]][keys[1]][keys[2]][key] = value
					
			else:
				if previous_key == key:
					if typeof(dict[keys[0]][keys[1]][keys[2]][key]) != TYPE_ARRAY:
						var value_copy = dict[keys[0]][keys[1]][keys[2]][key]
						dict[keys[0]][keys[1]][keys[2]][key] = Array()
						dict[keys[0]][keys[1]][keys[2]][key].append(value_copy)
						dict[keys[0]][keys[1]][keys[2]][key].append(value)
				else:
					dict[keys[0]][keys[1]][keys[2]][key] = Dictionary()
		4:
			if has_value:
				if previous_key == key:
					if typeof(dict[keys[0]][keys[1]][keys[2]][keys[3]]) == TYPE_ARRAY:
						var dict_in_array = dict[keys[0]][keys[1]][keys[2]][keys[3]] \
							[dict[keys[0]][keys[1]][keys[2]][keys[3]].size() - 1]
						if typeof(dict_in_array[key]) != TYPE_ARRAY:
							dict[keys[0]][keys[1]][keys[2]][keys[3]].erase(dict_in_array)
							var value_copy = dict_in_array[key]
							dict_in_array[key] = Array()
							dict_in_array[key].append(value_copy)
							dict_in_array[key].append(value)
							dict[keys[0]][keys[1]][keys[2]][keys[3]].append(dict_in_array)
							
					elif typeof(dict[keys[0]][keys[1]][keys[2]][keys[3]][key]) != TYPE_ARRAY:
						var value_copy = dict[keys[0]][keys[1]][keys[2]][keys[3]][key]
						dict[keys[0]][keys[1]][keys[2]][keys[3]][key] = Array()
						dict[keys[0]][keys[1]][keys[2]][keys[3]][key].append(value_copy)
						dict[keys[0]][keys[1]][keys[2]][keys[3]][key].append(value)
					else:
						dict[keys[0]][keys[1]][keys[2]][keys[3]][key].append(value)
				else:
					dict[keys[0]][keys[1]][keys[2]][keys[3]][key] = value
			else:
				if previous_key == key:
					if typeof(dict[keys[0]][keys[1]][keys[2]][keys[3]][key]) != TYPE_ARRAY:
						var value_copy = dict[keys[0]][keys[1]][keys[2]][keys[3]][key]
						dict[keys[0]][keys[1]][keys[2]][keys[3]][key] = Array()
						dict[keys[0]][keys[1]][keys[2]][keys[3]][key].append(value_copy)
						dict[keys[0]][keys[1]][keys[2]][keys[3]][key].append(value)
				else:
					dict[keys[0]][keys[1]][keys[2]][keys[3]][key] = Dictionary()
	
	previous_key = key
	previous_indent = indent_count
	return keys
