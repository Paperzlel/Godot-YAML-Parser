# Godot YAML Parser
 A GDScript YAML parser for Godot Engine


## How to Use
Using the parser is very simple, all you need to do is to download the `yaml_parser.gd` file either from source or from the Releases page, paste it into a folder in your project, create a new instance of the class using the `.new()` method, and call `get_and_parse_yaml_file()` to recieve the dictionary.
The `yaml_dict` property only contains one dictionary per use, and will be overwritten if you use it more than once per file. If one wishes to use said dictionaries more than once, try assigning them to an array of dictionaries that one can access without worry of them being overwritten.

## Features
The current set of features are relatively simple: parse a YAML file into a Dictionary, and give to the user. As I do not have a need to convert the other way, this will not currently be implemented, however if enough people wish for this feature, I will do my best to create a version with that enabled. If you have any other ideas for features within the parser, please let me know so I can create them.

## Issues
If there is a problem that you experience with the code, whether a get/set index error or an undesired set of values, please open an issue on GitHub describing the problem in detail so I can fix it ASAP.
