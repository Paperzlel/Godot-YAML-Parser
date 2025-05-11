extends Node

var spider_data : Dictionary
var goblin_data : Dictionary

func _ready() -> void:
	var parser : YAMLParser = YAMLParser.new()
	var start_time : float = Time.get_ticks_usec()
	var enemy_dict : Dictionary = parser.parse("res://demos/enemy_data/enemy_data.yaml")
	var end_time : float = Time.get_ticks_usec()
	print("Total time to parse the file was ", end_time - start_time, " microseconds (", (end_time - start_time ) / 1000, " milliseconds).")

	spider_data = enemy_dict["spider"]
	goblin_data = enemy_dict["goblin"]
	print("Resulting dictionary: \n", JSON.stringify(enemy_dict, "\t"))
