# Godot YAML Parser
 A GDScript YAML parser for Godot Engine

## Usage
Simply paste the script into your Godot project and use `YAMLParser.new(filepath)` to create an instance of it in your code. The filepath should be in the format `path/to/folder/`, do NOT add the `.yaml` ending to the path as it will not work correctly and the parser will break.

To parse a file, use `YAMLParser.get_and_parse_yaml_file(name)`. This will look for a file under the name given. Do NOT give it the `.yaml` file ending, as that has already been accounted for in the filepath.
The returned file will be an undindented dictionary, so you can save it using Godot's own JSON resource. The parser does not currently support converting dictionaries into YAML files, so be aware.

Once the file has been parsed, it is saved to `YAMLParser.yaml_dict`, which you can re-use to prevent repetitive re-parsing. 