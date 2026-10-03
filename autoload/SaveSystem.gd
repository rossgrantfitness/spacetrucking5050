extends Node
## Saving and loading. Everything is stored as JSON files in user://, the
## player's personal data folder (in Godot: Project > Open User Data Folder).
##
## M0: just the JSON helpers that Settings uses for user://settings.json.
## M2: save_game() / load_game() for the real game (money, ship, upgrades...).


## Bump this whenever the save file's layout changes, and add a step that
## upgrades older saves, so nobody ever loses progress after an update.
const SAVE_VERSION: int = 1


## Writes a Dictionary to a JSON file. Returns true if it worked.
func write_json(path: String, data: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Couldn't write %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return false
	# "\t" indents the file so it's easy for humans to read too.
	return file.store_string(JSON.stringify(data, "\t"))


## Reads a JSON file into a Dictionary.
## Returns an empty Dictionary if the file is missing or unreadable.
func read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	push_warning("Ignoring unreadable file %s" % path)
	return {}
