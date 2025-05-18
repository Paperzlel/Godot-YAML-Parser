class_name YAMLParser
extends Resource

## Class for a parser that turns YAML code into a dictionary type to be used
## within Godot Engine
## All code written by Paperzlel

var _data : Dictionary

## Helper variables to make some of the stuff we pass around less painful

## Cache the last used key for when multiline datatypes need to know their key
var _last_key : String

func _init() -> void:
	pass

## Returns the last parsed YAML file in Dictionary format, in case the user 
## forgot to format.
func get_data() -> Dictionary:
	return _data

## Parses the YAML file found at the given path and turns it into a dictionary.
## The file found is not cached, nor is its final dictionary, so please ensure
## that any parsed data is stored appropriately.
func parse(path : String) -> Dictionary:
	
	# If the file doesn't exist return a blank dictionary and print an error.
	if not FileAccess.file_exists(path):
		printerr("Given filepath does not exist.")
		return { }
	
	var file : FileAccess = FileAccess.open(path, FileAccess.READ)
	
	## Temporary dictionary to store all of the items in as the parser goes along
	var dict : Dictionary = { }
	## Current "depth" into the file, or the number of indentations on a line
	var index : int = 0
	## Dictionary full of arrays of the lines at a given index, pre-parsed
	var lines_at_index : Dictionary = { }
	## List of the last items at the given index
	var last_at_index : Array = []
	
	# Iterate over every line in a file until the EOF is reached
	while file.get_position() < file.get_length():
		## Reads the given line and outputs information about the line
		var line : Dictionary = _return_line_key_and_value(file)
		
		# Create an object of the line's key and value
		if line.is_empty():
			continue
		
		var line_index : int = line["index"]
		# Remove all previous entries that are greater than the index size
		# to prevent the scope being messed up
		while last_at_index.size() > line_index + 1:
			last_at_index.remove_at(line_index)
		# Check if the index is greater than the size of the array to determine
		# if the array needs to have values removed or not before appending
		if line_index > last_at_index.size() - 1:
			last_at_index.append(line["key"])
		else:
			last_at_index.remove_at(line_index)
			last_at_index.insert(line_index, line["key"])
		
		# Create a parent variable to keep track of the possesion of nodes
		# This is to prevent the recursive function from adding items where
		# they don't belong.
		var parent : Variant
		if line_index - 1 < 0:
			parent = null
		else:
			parent = last_at_index[line_index - 1]
		
		## Returns a path that the node takes in the tree, to determine if the
		## node being used is loading into the correct place
		var node_path : String = _get_node_path(last_at_index)
		
		## Creates all the relevant values to be passed into the dictionary creator
		var object : Dictionary = {"key": line["key"], "value": line["value"], \
				"parent": parent, "path" : node_path}
		
		# Check if line at the given index exists so as to not overwrite it
		if lines_at_index.has(line_index):
			lines_at_index[line_index].append(object)
		else:
			lines_at_index[line_index] = Array()
			lines_at_index[line_index].append(object)
	
	# Set the dictionary to be formatted into the desired type
	dict = _format_dict_from_other_r(dict, lines_at_index, index, "", "")


	_data = dict
	# Return the formatted dictionary as given
	return dict


## Returns the number of indentations in a line. Assumes that you are either using tab 
## indentation or 4-space line indentation. Other forms will not work
func _get_indent_count(line : String) -> int:
	var line2 : String = line.dedent()
	if line2 == line:
		return 0
	var net_length : int = len(line) - len(line2)
	if line.begins_with(" "):
		net_length /= 4
	return net_length


## Method that returns the path a node takes from the root to its place in a file
func _get_node_path(line_index : Array) -> String:
	var end_str : String = ""
	for item in line_index:
		end_str += "/" + item
	return end_str


## Checks if the value for the item is empty/unused
func _is_variant_nullable(v : Variant) -> bool:
	match typeof(v):
		TYPE_ARRAY:
			var arr : Array = v
			return arr.is_empty()
		TYPE_DICTIONARY:
			var dict : Dictionary = v
			return dict.is_empty()
		TYPE_STRING:
			var string : String = v
			return string.is_empty()
		TYPE_NIL:
			return true
	return false

## Separates out a line into its key and value.
func _parse_key_and_value(line : String) -> PackedStringArray:
	# Array 0 = key, 1 = value
	# As it turns out, reading the docs is a good idea.
	var line_array : PackedStringArray = line.split(":", true, 1)
	return line_array


## Calculates several values a given line will have for use later on in the pipeline
func _return_line_key_and_value(file : FileAccess) -> Dictionary:
	# Get the current line to read from the file
	var line : String = file.get_line()
	# Check for if the file is just the null terminator
	if len(line) == 0: 
		return { }

	# If the version is specified, ignore it.
	if line.begins_with("%"):
		return { }
	# Check if the line being parsed is the header or footer
	if line.begins_with("---") or line.begins_with("..."):
		return { }
	
	# Check if the line is a comment or has a comment
	if line.begins_with("#"):
		return { }
	line = line.split("#")[0]

	# Clear all "- " characters from the string
	line = line.replace("- ", "\t")

	# Parse out the key and value, and set them as their own variables
	var line_array : PackedStringArray = _parse_key_and_value(line)

	var key : String = line_array[0].dedent()
	var value : Variant

	var ofs : int = 0

	# In this case, there is only a value. Set ofs to 1 and remove any
	# trailing commas
	if line_array.size() == 1:
		value = _string_to_variant(key)
		# Only return this if a closed bracket is detected on an end-line.
		if value == null:
			return { }
		ofs = 1
		key = _last_key
	else: 
		# Should usually be the case. Test extensively.
		_last_key = key

		# Check only when the array has a key-value pair and not just a value
		if line_array[1] == "":
			value = null
		else:
			var strval : String = line_array[1].strip_edges()
			value = _string_to_variant(strval)

	# Get the indent count from the given line (no. of tab spaces)
	var index : int = _get_indent_count(line)

	# Return with all the values set
	return {"index": index - ofs, "key": key, "value": value}


## Converts the a string into a Variant, if possible. Used for
## value conversion
func _string_to_variant(string : String) -> Variant:
	string = string.strip_edges()
	if string.contains(".") and string.is_valid_float():
		return string.to_float()
	else:
		if string.is_valid_int():
			return string.to_int()
		else:
			if string == "true":
				return true
			elif string == "false":
				return false
			else:
				return _check_if_list(string)


## Checks if the given string is a list or dictionary, parsing
## it if so, otherwise returning it as a String.
func _check_if_list(string : String) -> Variant:
	var ret : Variant
	# Is an array
	if string.begins_with("[") and string.ends_with("]"):
		string = string.left(-1)
		string = string.right(-1)
		var arr : Array = Array()
		var split_str : PackedStringArray = string.split(", ", false)
		for substr in split_str:
			var index : int = split_str.find(substr)
			while substr.begins_with("\"") and not substr.ends_with("\""):
				substr += ", " + split_str[index + 1]
				split_str.remove_at(index + 1)
			
			arr.append(_string_to_variant(substr))
		ret = arr
	elif string.begins_with("{") and string.ends_with("}"):
		string = string.left(-1)
		string = string.right(-1)
		var dict : Dictionary = Dictionary()

		var key_values : PackedStringArray = string.split(", ")
		# Split by comma, re-order each key-value, split by colon
		for kv in key_values:
			kv = kv.strip_edges()
			var quote : int = kv.find("\"")
			if quote != -1:
				var subst : String = kv.right(-quote)
				var pos : int = key_values.find(kv)
				while subst.begins_with("\"") and not subst.ends_with("\""):
					subst += ", " + key_values[pos + 1]
					key_values.remove_at(pos + 1)
				kv = kv.left(quote) + subst
			
			var kv_split : PackedStringArray = kv.split(": ")
			dict[kv_split[0]] = _string_to_variant(kv_split[1])
		ret = dict
	else:
		if string.begins_with("{"):
			ret = Dictionary()
		elif string.begins_with("["):
			ret = Array()
		elif string.ends_with("}") or string.ends_with("]"):
			ret = null
		else:
			ret = string.replace("\"", "").strip_edges()
			if ret.is_empty():
				ret = null

	return ret


## Recursive formatting method, adds all the relevant items into a dictionary.
func _format_dict_from_other_r(end_dict : Dictionary, indexed_dict : Dictionary,  \
		index : int, parent : String, expected_path : String) -> Dictionary:
	# Check the index is not larger the the size of the dictionary
	if index + 1 > indexed_dict.size():
		return { }
	# Loop through every item at the given index
	for item in indexed_dict[index]:
		# Check for if the parent of the node exists and is not equal to the given
		# parent so as to avoid duplicate lines in the resulting dictionary
		if parent != "" and item["parent"] != null:
			if parent != item["parent"]:
				continue
		
		# Apply the current key to the expected path to ensure it syncs
		expected_path += "/" + item["key"]
		
		# Splits the expected path and removed any extra nodes that shouldn't exist.
		var expected_split_path : Array = Array(expected_path.split("/", false))
		while expected_split_path.size() > index + 1:
			expected_split_path.remove_at(index)
		
		# Compares the cached path and the expected path. If they aren't the same,
		# then ignore this item as it's not relevant to the sub-dictionary.
		var item_path : Array = Array(item["path"].split("/", false))
		if not expected_split_path == item_path:
			continue
		
		expected_path = _get_node_path(item_path)
		
		var key : String = item["key"]
		
		var value : Variant
		if not _is_variant_nullable(item["value"]):
			value = item["value"]
		else:
			value = null
		
		var path : String = item["path"]
		var is_array_type : bool
		if end_dict.is_empty() or not end_dict.has(key):
			is_array_type = false # Doesn't have a accessible value yet
		else:
			is_array_type = typeof(end_dict[key]) == TYPE_ARRAY

		# Item's value is null
		if value == null:
			# Check if item's value is null and the item's name does not yet exist
			if not end_dict.has(key):
				end_dict[key] = Dictionary()
				var n_value : Dictionary = _format_dict_from_other_r(end_dict[key], indexed_dict, 	\
						index + 1, key, path)
				end_dict[key] = n_value
			else:
				# Check if item's value is null and the name exists, but is not an array
				if not is_array_type:
					var saved_item : Variant = end_dict[key]
					var last_index : int = 0
					end_dict[key] = Array()
					if not _is_variant_nullable(saved_item):
						end_dict[key].append(saved_item)
						last_index = 1
					end_dict[key].append(Dictionary())
					
					var n_value : Dictionary = _format_dict_from_other_r(end_dict[key][last_index], \
							indexed_dict, index + 1, key, path)
					end_dict[key].append(n_value)
				# Check if item's value is null and the name exists and is an array
				else:
					var last_index : int = end_dict[key].size()
					end_dict[key].append(Dictionary())
					
					var n_value : Dictionary = _format_dict_from_other_r(end_dict[key][last_index],	\
							indexed_dict, index + 1, key, path)
					end_dict[key][last_index] = n_value
		# Item is not null
		else:
			if not end_dict.has(key):
				end_dict[key] = value
			else:
				# Item's name exists, but is not an array
				if not is_array_type:
					var saved_item : Variant = end_dict[key]
					end_dict[key] = Array()
					# If the variant is empty/ignorable, we ignore it when re-appending
					if not _is_variant_nullable(saved_item):
						end_dict[key].append(saved_item)

					end_dict[key].append(value)

				# Item's name exists, and is an array
				else:
					end_dict[key].append(value)

	# Return once all lines are configured, recusion means deeper dictionaries
	# will return the same way as the main one
	return end_dict
