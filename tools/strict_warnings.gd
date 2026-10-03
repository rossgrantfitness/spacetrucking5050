extends SceneTree
## Used by tools/validate.sh. Writes a temporary override.cfg that turns every
## GDScript warning that is normally a yellow "warning" into a hard error, so
## the automated check can't miss one. validate.sh deletes the file again.
##
## (Godot reads override.cfg from the project folder on startup and lets it
## override any project setting. It's in .gitignore so it never gets committed.)


const WARN: int = 1
const ERROR: int = 2


func _init() -> void:
	var overrides := ConfigFile.new()
	for property in ProjectSettings.get_property_list():
		var setting: String = property["name"]
		if not setting.begins_with("debug/gdscript/warnings/"):
			continue
		var level: Variant = ProjectSettings.get_setting(setting)
		if level is int and level == WARN:
			overrides.set_value("debug", setting.trim_prefix("debug/"), ERROR)
	var error := overrides.save("res://override.cfg")
	quit(0 if error == OK else 1)
