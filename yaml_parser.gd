class_name YAMLParser
extends Resource

## Class for a parser that turns YAML code into a dictionary type to be used
## within Godot Engine
## All code written by Paperzlel


## Filepath to the folder where the YAML files are stored. The code expects to
## only deal with a single folder, sub-folders and files outside of the folder
## WILL NOT be accounted for, you will have to change the filepath manually.
var filepath : Variant = "res://%s.yaml"

## The dictionary that holds all of the parsed values to be used elsewhere. The 
## parser will only fill this up when the method `get_and_parse_yaml_file` is
## called. 
var yaml_dict : Dictionary = { }

## Class constructor for the parser.
func _init(n_filepath : String):
	filepath = "res://" + n_filepath + "%s.yaml"


## The main function one will use. The parameter `name` will use the given
## filepath combined with a given name.
func get_and_parse_yaml_file(name : String) -> Dictionary:
	# The path to the file to read
	var dialogue_filepath : String = filepath % name
	
	# If the file doesn't exist return a blank dictionary and print an error.
	if not FileAccess.file_exists(dialogue_filepath):
		printerr("File does not exist and the parser is unable to parse, returning a blank dictionary. Please give a valid name for the file.")
		return { }
	
	var file = FileAccess.open(dialogue_filepath, FileAccess.READ)
	
	## Temporary dictionary to store all of the items in as the parser goes along
	var dict : Dictionary = { }
	## Current "depth" into the file, or the number of indentations on a line
	var index = 0
	## Dictionary full of arrays of the lines at a given index, pre-parsed
	var lines_at_index = { }
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
		var parent
		if line["index"] - 1 < 0:
			parent = null
		else:
			parent = last_at_index[line["index"] - 1]
		
		## Returns a path that the node takes in the tree, to determine if the
		## node being used is loading into the correct place
		var path : String = _get_node_path(last_at_index)
		
		## Creates all the relevant values to be passed into the dictionary creator
		var object : Dictionary= {"key": line["key"], "value": line["value"], \
				"parent": parent, "path" : path}
		
		# Check if line at the given index exists so as to not overwrite it
		if lines_at_index.has(line["index"]):
			lines_at_index[line["index"]].append(object)
		else:
			lines_at_index[line["index"]] = Array()
			lines_at_index[line["index"]].append(object)
	
	# Set the dictionary to be formatted into the desired type
	dict = _format_dict_from_other_r(dict, lines_at_index, index, "", "")
	
	# Set the public dictionary to be the same as the private one
	yaml_dict = dict
	# Return the formatted dictionary as given
	return dict


## Returns the number of indents in a line
func _get_indent_count(line : String) -> int:
	var line2 = line.dedent()
	if line2 == line:
		return 0
	return len(line) - len(line2)


## Separates out a line into its key and value.
func _parse_key_and_value(line : String) -> PackedStringArray:
	# Array 0 = key, 1 = value
	var line_array = line.split(":", true)
	return line_array


## Calculates several values a given line will have for use later on in the pipeline
func _return_line_key_and_value(file) -> Dictionary:
	# Get the current line to read from the file
	var line = file.get_line()
	# Get the indent count from the given line (no. of tab spaces)
	var index = _get_indent_count(line)
	# Check for if the file is just the null terminator
	if len(line) == 0: 
		return { }
	# Check if the line is a comment or has a comment
	if line.begins_with("#"):
		return { }
	line = line.split("#")[0]
	# Parse out the key and value, and set them as their own variables
	var line_array = _parse_key_and_value(line)
	var key = line_array[0].dedent()
	var value
	if line_array.size() <= 1:
		return { }
	if line_array[1] == "":
		value = null
	else:
		value = line_array[1].strip_edges()
	# Return with all the values set NOTE: has_value CAN be removed, but for
	# the meantime I will keep it
	return {"index": index, "line_array": line_array, "key": key, "value": value}


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
		
		# Check if item's value is null and the item's name does not yet exist
		if (item["value"] == null or item["value"] == "") and \
				not end_dict.has(item["key"]):
			end_dict[item["key"]] = Dictionary()
			end_dict[item["key"]] = _format_dict_from_other_r(end_dict[item["key"]],  \
					indexed_dict, index + 1, item["key"], expected_path)
		# Check if item's value is null and the name exists, but is not an array
		elif (item["value"] == null or item["value"] == "") and \
				typeof(end_dict[item["key"]]) != TYPE_ARRAY:
			var saved_item = end_dict[item["key"]]
			end_dict[item["key"]] = Array()
			end_dict[item["key"]].append(saved_item)
			end_dict[item["key"]].append(_format_dict_from_other_r(end_dict[item["key"]], \
					indexed_dict, index + 1, item["key"], expected_path))
		# Check if item's value is null and the name exists and is an array
		elif (item["value"] == null or item["value"] == "") and \
				typeof(end_dict[item["key"]]) == TYPE_ARRAY:
			var last_index = end_dict[item["key"]].size()
			end_dict[item["key"]].append(Dictionary())
			end_dict[item["key"]][last_index] = _format_dict_from_other_r( \
					end_dict[item["key"]][last_index], indexed_dict, index + 1, \
					item["key"], expected_path)
		# Item's value is not null
		else:
			# Item's name exists, but is not an array
			if end_dict.has(item["key"]) and \
					typeof(end_dict[item["key"]]) != TYPE_ARRAY:
				var saved_item = end_dict[item["key"]]
				end_dict[item["key"]] = Array()
				end_dict[item["key"]].append(saved_item)
				end_dict[item["key"]].append(item["value"])
			# Item's name exists, and is an array
			elif end_dict.has(item["key"]) and \
					typeof(end_dict[item["key"]]) == TYPE_ARRAY:
				end_dict[item["key"]].append(item["value"])
			# Item's name does not exist so we can safely assign the item
			else:
				end_dict[item["key"]] = item["value"]
	# Return once all lines are configured, recusion means deeper dictionaries
	# will return the same way as the main one
	return end_dict
