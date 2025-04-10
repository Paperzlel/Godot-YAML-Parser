extends Node

## Place these files in your root directory and attach this script to
## a node to see the results

var spider_data : Dictionary
var goblin_data : Dictionary

func _ready() -> void:
	var parser : YAMLParser = YAMLParser.new()
	var enemy_dict : Dictionary = parser.parse("res://demos/enemy_data/enemy_data.yaml")
	spider_data = enemy_dict["spider"]
	goblin_data = enemy_dict["goblin"]