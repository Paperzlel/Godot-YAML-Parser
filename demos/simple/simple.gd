extends Node

## Place these files in your root directory and attach this script to
## a node to see the results

func _ready() -> void:
	var parser : YAMLParser = YAMLParser.new()
	var my_dict : Dictionary = parser.parse("res://demos/simple/simple.yaml")
	print(my_dict)