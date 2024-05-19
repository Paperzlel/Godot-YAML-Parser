class_name YAMLParser
extends Resource

# Class for a parser that turns YAML "code" into a dictionary to use in Godot
# The number of indents equals the level an item is at in the dictionary
# 
# Please NOTE: This will only save items in a key : value pair, so functions
# will have to be parsed from its text to function form


# Filepath to where the YAML folder is. Modify it to where you want to read
# files from. 
var filepath : Variant = "res://%s.yaml"

# Dictionary that holds all of the YAML information
var yaml_dict : Dictionary = { }

# String for the last key
var current_region : String = ""

# The key before the current one, used to compare whether to start a new dictionary
# or not.
var previous_key = ""

# Boolean to check if the file has read the first line or not.
var has_read_first_line : bool = false


# Class constructor. Add your new filepath (res://<filepath>/%s.yaml) here.
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


# Function to separate the string into its key and value pair.
func parse_key_and_value(line : String) -> PackedStringArray:
	# Array 0 = key, 1 = value
	var line_array = line.split(":", true)
	return line_array


# Finds the filepath for the given YAML file and parses it into a Dictionary
func get_and_parse_npc_yaml_file(name : String) -> Dictionary:
	# creates a path using a name. This is usually because we expect more than
	# one file to be used from a given location, so go crazy.
	var dialogue_filepath = filepath % name
	# If the file doesn't exist we return nothing. Customise if you have any
	# default options you want.
	if not FileAccess.file_exists(dialogue_filepath):
		return { }
	var file = FileAccess.open(dialogue_filepath, FileAccess.READ)
	
	# Interal variable for the "keys" in a path. This is effectively what we
	# use to translate YAML files to dictionaries, as instead of indent paths
	# we use dictionary keys.
	var current_keys : Array = []

	# Main file loop.
	while file.get_position() < file.get_length():
		var line = file.get_line()
		var has_value : bool = false
		
		# If the line has a # key at the start, it is a comment and we skip it
		if line.begins_with("#"):
			continue

		# Regex string that checks if the string has a colon followed by any letters
		# If there is, the line has a value, if not, it doesn't.
		var regex = RegEx.new()
		regex.compile(".+:.+[a-zA-Z0-9]")
		if regex.search(line):
			has_value = true
		
		# Nested loop, as we want to update our keys per line, which we can't do 
		# otherwise to my knowledge.
		current_keys = add_contents_to_dict(line, current_keys, has_value)
		
	return yaml_dict


# Adds the current key-value pair to the dictionary. Returns an array of the
# next iteration of keys to use in the next line.
func add_contents_to_dict(line : String, keys : Array, has_value : bool) -> Array:
	# Copy the dictionary used in the previous line.
	var dict = yaml_dict
	
	var indent_count = get_indent_count(line)
	var keys_size = keys.size()
	var line_array = parse_key_and_value(line)
	
	var key = line_array[0].dedent()
	var value
	
	# Logic for indent count and keys comparison. Used to change the number of keys
	# and therefore the index level of the keys.
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
	
	# Core match for keys. Currently very repetitive and I'm not sure on a way to avoid that (yet)
	# Anyone who wants to find a way to do this better is welcome to open an issue on GitHub and
	# let me know.
	match indent_count:
		0:
			if has_value:
				dict[key] = value
			else:
				dict[key] = Dictionary()
		1:
			# Check for if the key has a value or not
			if has_value:
				# Check if the keys are the same. Two of the same key will override one another, so
				# we copy its value and create an array for the keys.
				if previous_key == key:
					# Check if the keys do not hold an array
					if typeof(dict[keys[0]][key]) != TYPE_ARRAY:
						# Copy the key that already exists
						var value_copy = dict[keys[0]][key]
						# Convert it to an empty array
						dict[keys[0]][key] = Array()
						# Append the copied value to the array first (parser assumes the previous
						# key was the first intended entry)
						dict[keys[0]][key].append(value_copy)
						# Append the desired value
						dict[keys[0]][key].append(value)
					else:
						# Key is already an array, simply append the value to it
						dict[keys[0]][key].append(value)
				else:
					# Key is not the same as the previous, just add its value as a String
					dict[keys[0]][key] = value
			# Key does not have a value
			else:
				# Key has the same name as the previous key, but doesn't have a value, so we append
				# null to the array. DO NOT DO THIS (for now). It will mess up the code, and having
				# a dictionary as an array index is not currently supported. 
				if previous_key == key:
					if typeof(dict[keys[0]][key]) != TYPE_ARRAY:
						var value_copy = dict[keys[0]][key]
						dict[keys[0]][key] = Array()
						dict[keys[0]][key].append(value_copy)
						dict[keys[0]][key].append(value)
				else:
					# Key is not the same as before, create a new dictionary for
					# it to use instead
					dict[keys[0]][key] = Dictionary()
		# Code from this point is essentially the same as before, just with an extra keys index for it to
		# go through. 
		2:
			if has_value:
				if previous_key == key:
					if typeof(dict[keys[0]][keys[1]][key]) != TYPE_ARRAY:
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
					if typeof(dict[keys[0]][keys[1]][keys[2]][key]) != TYPE_ARRAY:
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
					if typeof(dict[keys[0]][keys[1]][keys[2]][keys[3]][key]) != TYPE_ARRAY:
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
					dict[keys[0]][keys[1]][keys[2]][key] = Dictionary()
	
	previous_key = key
	return keys
