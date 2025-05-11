extends Node

func _ready() -> void:
	var parser : YAMLParser = YAMLParser.new()
	var start_time : float = Time.get_ticks_usec()
	var my_dict : Dictionary = parser.parse("res://demos/simple/simple.yaml")
	var end_time : float = Time.get_ticks_usec()
	print("Total time to parse the file was ", end_time - start_time, " microseconds (", (end_time - start_time ) / 1000, " milliseconds).")

	print("Resulting dictionary: \n", JSON.stringify(my_dict, "\t"))
