# Godot YAML Parser
 A GDScript YAML parser for Godot Engine, written in GDScript.


## How to Use
Take the `yaml_parser.gd` file found in the project root and paste it into your filesystem for your project. Then, construct a new `YAMLParser` object within the code using `.new()`, then call the `parse()` method on a file of your choice to recieve its contents as a dictionary (permitting they are formatted as shown below).
The returned dictionary uses Strings as its keys, and Variants as its values, so make sure that any data accessing uses the appropriate types.

Currently, there is no way to convert a JSON file or a Godot dictionary into a YAML file, however support for that may exist if needed.

## Layout
Currently, the parser supports string values, non-string values, and inlined arrays and dictionaries. More advanced features such as aliases are not supported.
The general layout for a YAML file is as follows:
```
root:
	item: a
	item2: b
	item3: 3
	subdirectory:
		check_a: true
		list: [1, 2, 3]
		inline_dictionary: {name: John Doe, ID: 12345, password: password}
second_root:
	string: Hello!		
```

**PLEASE NOTE:** Indentation should be at either 4 spaces per tab, or using regular tabbing amounts, otherwise the parser will get confused and be unable to read the file properly.

## Examples
See the `demos` folder for examples on how to use the parser. To see how they work, place the `demos` folder into the root of your project and load the scenes from each of the example files (you may get some UID warnings, these are fine and you can ignore them).

## Issues
There are some known issues and non-existent features with the parser - namely no multiline support at the moment. If your issue isn't related to something unrelated to YAML feature support, please open an issue on this repository to let me know of any potential problems.