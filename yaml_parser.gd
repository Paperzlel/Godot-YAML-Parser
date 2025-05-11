class_name YAMLParser
extends Resource

## Class for a parser that turns YAML code into a dictionary type to be used
## within Godot Engine
## All code written by Paperzlel

func _init() -> void:
	pass


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
		
		# Remove all previous entries that are greater than the index size
		# to prevent the scope being messed up
		while last_at_index.size() > line["index"] + 1:
			last_at_index.remove_at(line["index"])
		# Check if the index is greater than the size of the array to determine
		# if the array needs to have values removed or not before appending
		if line["index"] > last_at_index.size() - 1:
			last_at_index.append(line["key"])
		else:
			last_at_index.remove_at(line["index"])
			last_at_index.insert(line["index"], line["key"])
		
		# Create a parent variable to keep track of the possesion of nodes
		# This is to prevent the recursive function from adding items where
		# they don't belong.
		var parent : Variant
		if line["index"] - 1 < 0:
			parent = null
		else:
			parent = last_at_index[line["index"] - 1]
		
		## Returns a path that the node takes in the tree, to determine if the
		## node being used is loading into the correct place
		var node_path : String = _get_node_path(last_at_index)
		
		## Creates all the relevant values to be passed into the dictionary creator
		var object : Dictionary = {"key": line["key"], "value": line["value"], \
				"parent": parent, "path" : node_path}
		
		# Check if line at the given index exists so as to not overwrite it
		if lines_at_index.has(line["index"]):
			lines_at_index[line["index"]].append(object)
		else:
			lines_at_index[line["index"]] = Array()
			lines_at_index[line["index"]].append(object)
	
	# Set the dictionary to be formatted into the desired type
	dict = _format_dict_from_other_r(dict, lines_at_index, index, "", "")

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


## Separates out a line into its key and value.
func _parse_key_and_value(line : String) -> PackedStringArray:
	# Array 0 = key, 1 = value
	var line_array : PackedStringArray = line.split(":", true)
	# Since key-value pairs can be inlined, merge them together for the later tokenizers
	if line_array.size() > 2:
		for i in range(line_array.size()):
			if i < 2:
				pass
			else:
				line_array[1] += ":" + line_array[i]
	line_array.resize(2)
	return line_array


## Calculates several values a given line will have for use later on in the pipeline
func _return_line_key_and_value(file : FileAccess) -> Dictionary:
	# Get the current line to read from the file
	var line : String = file.get_line()
	# Replace any "- " characters for lists with a tab (as it often implies indentation)
	line = line.replace("- ", "\t")
	# Get the indent count from the given line (no. of tab spaces)
	var index : int = _get_indent_count(line)
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

	# Parse out the key and value, and set them as their own variables
	var line_array : PackedStringArray = _parse_key_and_value(line)
	var key : String = line_array[0].dedent()
	if key == "|":
		printerr("Attempted to use a multiline datatype, which is unsupported.")
	
	var value : Variant
	if line_array.size() <= 1:
		return { }
	if line_array[1] == "":
		value = null
	else:
		var strval : String = line_array[1].strip_edges()
		value = _string_to_variant(strval)
	# Return with all the values set
	return {"index": index, "key": key, "value": value}


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
		for substr in string.split(", "):
			arr.append(_string_to_variant(substr))
		ret = arr
	elif string.begins_with("{") and string.ends_with("}"):
		string = string.left(-1)
		string = string.right(-1)
		var dict : Dictionary = Dictionary()

		var key_values : PackedStringArray = string.split(", ")
		var key_count : int = string.count(":")
		# Detect an escape by an array or nested dictionary
		if key_values.size() > key_count:
			for i in range(key_values.size()):
				if i < key_count:
					continue
				else:
					key_values[key_count - 1] += ", " + key_values[i]
		key_values.resize(key_count)
		for kv in key_values:
			var kv_arr : PackedStringArray = kv.split(":")
			dict[kv_arr[0]] = _string_to_variant(kv_arr[1])

		ret = dict
	else:
		if string.begins_with("{") or string.begins_with("["):
			printerr("Attempted to use a multiline array, which is unsupported.", \
				"Please use single-line arrays for multiple data types.")
			ret = null
		else:
			ret = string

	return ret


## Method that returns the path a node takes from the root to its place in a file
func _get_node_path(line_index : Array) -> String:
	var end_str : String = ""
	for item in line_index:
		end_str += "/" + item
	return end_str


## Recursive formatting method, adds all the relevant items into a dictionary.
func _format_dict_from_other_r(end_dict : Dictionary, indexed_dict : Dictionary,  \
		index : int, parent : String, expected_path : String) -> Dictionary:
	# Check the index is not larger the the size of the dictionary
	if index + 1 > indexed_dict.size():
		printerr("The index is greater than the size of the indexed dictionary!")
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
		## Splits the expected_path into its individual nodes to be removed and
		## re-assembled into a better expected_path
		var split_path : Array = Array(expected_path.split("/", false))
		# Remove all the entries that are not the current item
		while split_path.size() > index + 1:
			split_path.remove_at(index)
		# Re-create the current node path from the split version
		expected_path = _get_node_path(split_path)
		# Check if the paths given do not sync together, if they do not the wrong
		# nodes are being loaded in and should not be added here
		if expected_path != item["path"]:
			continue
		
		var value : Variant = item["value"]
		var is_array_type : bool
		if end_dict.is_empty() or not end_dict.has(item["key"]):
			is_array_type = false # Doesn't have a accessible value yet
		else:
			is_array_type = typeof(end_dict[item["key"]]) == TYPE_ARRAY

		# Check if item's value is null and the item's name does not yet exist
		if value == null and not end_dict.has(item["key"]):
			
			end_dict[item["key"]] = Dictionary()
			end_dict[item["key"]] = _format_dict_from_other_r(end_dict[item["key"]],  \
					indexed_dict, index + 1, item["key"], expected_path)
		# Check if item's value is null and the name exists, but is not an array
		elif value == null and not is_array_type:

			var saved_item : Variant = end_dict[item["key"]]
			end_dict[item["key"]] = Array()
			end_dict[item["key"]].append(saved_item)
			end_dict[item["key"]].append(_format_dict_from_other_r(end_dict[item["key"]], \
					indexed_dict, index + 1, item["key"], expected_path))
			
		# Check if item's value is null and the name exists and is an array
		elif value == null and is_array_type:

			var last_index = end_dict[item["key"]].size()
			end_dict[item["key"]].append(Dictionary())
			end_dict[item["key"]][last_index] = _format_dict_from_other_r( \
					end_dict[item["key"]][last_index], indexed_dict, index + 1, \
					item["key"], expected_path)
		# Item's value is not null
		else:
			# Item's name exists, but is not an array
			if end_dict.has(item["key"]) and not is_array_type:

				var saved_item : Variant = end_dict[item["key"]]
				end_dict[item["key"]] = Array()
				end_dict[item["key"]].append(saved_item)
				end_dict[item["key"]].append(value)
			# Item's name exists, and is an array
			elif end_dict.has(item["key"]) and is_array_type:

				end_dict[item["key"]].append(value)
			# Item's name does not exist so we can safely assign the item
			else:
				end_dict[item["key"]] = value
	# Return once all lines are configured, recusion means deeper dictionaries
	# will return the same way as the main one
	return end_dict
