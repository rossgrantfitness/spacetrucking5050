extends SceneTree
## Used by tools/validate.sh. Loads every script, scene, resource and shader
## in the project so Godot reports anything broken, and builds each scene
## once to make sure it can actually be created.
##
## To check just some files, list them after "--":
##     godot --headless --path . -s tools/validate_project.gd -- scenes/boot/Boot.gd


const CHECKED_EXTENSIONS: PackedStringArray = ["gd", "tscn", "tres", "gdshader"]


# _initialize runs once the game's autoloads exist, unlike _init. That's why
# this is more reliable than Godot's --check-only for scripts that use them.
func _initialize() -> void:
	var paths := PackedStringArray()
	for requested in OS.get_cmdline_user_args():
		paths.append(requested if requested.begins_with("res://") else "res://" + requested)
	if paths.is_empty():
		_collect_files("res://", paths)
	var failures := 0
	for path in paths:
		var resource := ResourceLoader.load(path)
		if resource == null:
			push_error("Could not load " + path)
			failures += 1
		elif resource is GDScript and not (resource as GDScript).can_instantiate():
			# A script with errors still "loads", but is unusable.
			push_error("Script has errors: " + path)
			failures += 1
		elif resource is PackedScene:
			var instance := (resource as PackedScene).instantiate()
			if instance == null:
				push_error("Could not build scene " + path)
				failures += 1
			else:
				instance.free()
	print("Checked %d file(s), %d failed." % [paths.size(), failures])
	quit(1 if failures > 0 else 0)


func _collect_files(folder: String, paths: PackedStringArray) -> void:
	for file_name in DirAccess.get_files_at(folder):
		if file_name.get_extension() in CHECKED_EXTENSIONS:
			paths.append(folder.path_join(file_name))
	for subfolder in DirAccess.get_directories_at(folder):
		if not subfolder.begins_with("."):  # Skip .godot, .git and friends.
			_collect_files(folder.path_join(subfolder), paths)
