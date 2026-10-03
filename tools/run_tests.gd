extends SceneTree
## Used by tools/validate.sh: runs every *Tests.gd file in res://tools/tests/.
##
## These are quick automatic checks of game logic that can be tested without
## playing. Feel can't be tested this way (that's what playtests are for);
## this catches "the math or the data broke".
##
## The test files are loaded AFTER startup, so they can use autoloads like
## Settings and GameState by name. (This runner can't: it gets compiled
## before the autoloads exist.)


const TESTS_FOLDER: String = "res://tools/tests"


func _initialize() -> void:
	var tests_run := 0
	var problems := 0
	for file_name in DirAccess.get_files_at(TESTS_FOLDER):
		if not file_name.ends_with("Tests.gd"):
			continue
		var suite: Object = (load(TESTS_FOLDER.path_join(file_name)) as GDScript).new()
		for method in suite.get_method_list():
			var method_name: String = method["name"]
			if method_name.begins_with("test_"):
				suite.call(method_name)
				tests_run += 1
		problems += int(suite.get("problems"))
	print("Self-tests finished: %d test(s), %d problem(s)." % [tests_run, problems])
	quit(1 if problems > 0 else 0)
