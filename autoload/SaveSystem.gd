extends Node
## Saving and loading. Everything is stored as JSON files in user://, the
## player's personal data folder (in Godot: Project > Open User Data Folder).
##
## - write_json() / read_json(): little helpers (Settings uses them for
##   user://settings.json).
## - save_game() / load_game(): the game itself, in user://save.json. What
##   goes in it is decided by GameState.to_save_data().


## Bump this whenever the save file's layout changes, and add a step that
## upgrades older saves, so nobody ever loses progress after an update.
const SAVE_VERSION: int = 2  # 2: checks waiting at the OrbitalEx office.
## Where the game is saved. (The automated tests point this at a scratch
## file, so running them never touches your real save.)
var save_path: String = "user://save.json"


## Saves the game. `data` comes from GameState.to_save_data().
func save_game(data: Dictionary) -> bool:
	var stamped := data.duplicate()
	stamped["version"] = SAVE_VERSION
	return write_json(save_path, stamped)


## The saved game, or {} if there isn't one.
func load_game() -> Dictionary:
	return read_json(save_path)


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


## Deletes the save (for "New game").
func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


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
