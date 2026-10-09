extends SceneTree
## Saves every room camera's auto-painted background that doesn't have
## hand-made art yet (see HubRoom.ART_FOLDER) to art/to_paint/<room>/<shot>.jpg,
## with a list in art/to_paint/README.md. Paint over one (same size, same
## framing), save it as art/backgrounds/<room>/<shot>.jpg and the game uses
## it instead. The folder has a .gdignore so Godot doesn't import these.
##
## It needs a real (or virtual) screen to render on, so run it with:
##     RES=1920x1080 tools/capture.sh 100000 /tmp/ignore -s res://tools/export_paint_list.gd

const OUT := "res://art/to_paint/"
## Each room, and the place to arrive at (which decides the view outside).
const ROOMS := [
	["res://scenes/hub/Apartment.tscn", "truck_stop"],
	["res://scenes/hub/Hallway.tscn", "truck_stop"],
	["res://scenes/hub/Dispatch.tscn", "truck_stop"],
	["res://scenes/hub/Galley.tscn", "truck_stop"],
	["res://scenes/hub/CargoBay.tscn", "truck_stop"],
	["res://scenes/hub/EngineRoom.tscn", "truck_stop"],
	["res://scenes/hub/TruckStop.tscn", "truck_stop"],
	["res://scenes/hub/OrbitalExOffice.tscn", "truck_stop"],
	["res://scenes/hub/CanneryCanteen.tscn", "tidewater"],
	["res://scenes/hub/HighRollerLounge.tscn", "high_roller"],
	["res://scenes/hub/Arboretum.tscn", "arboretum"],
	["res://scenes/hub/SalvageYard.tscn", "salvage_yard"],
	["res://scenes/hub/Creamery.tscn", "creamery"],
]

var _index := -1
var _wait := 0.0
var _list := PackedStringArray()
var _painted := PackedStringArray()


func _initialize() -> void:
	root.get_node("SaveSystem").set("save_path", "user://smoke_test_save.json")
	var state := root.get_node("GameState")
	state.call("new_game")
	for flag: String in ["opening_called", "met_boss", "first_check", "met_marge"]:
		state.call("set_flag", flag)
	state.get("tuning").set("prerender_scale", 1.0)
	var folder := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(folder)
	FileAccess.open(OUT + ".gdignore", FileAccess.WRITE).close()
	create_timer(0.5).timeout.connect(_next_room)


func _next_room() -> void:
	_index += 1
	if _index >= ROOMS.size():
		_write_list()
		quit()
		return
	var state := root.get_node("GameState")
	state.set("launch_from", ROOMS[_index][1])
	state.set("next_spawn", "")
	change_scene_to_file(ROOMS[_index][0])
	_wait = 0.0


func _process(delta: float) -> bool:
	if _index < 0 or _index >= ROOMS.size():
		return false
	_wait += delta
	var room := current_scene
	if room == null or room.get("_ready_to_play") != true or _wait < 1.0:
		if _wait > 60.0:
			push_error("Stuck loading " + ROOMS[_index][0])
			_next_room()
		return false
	var room_folder := String(ROOMS[_index][0]).get_file().get_basename().to_snake_case()
	for shot: Node in room.get("_shots"):
		var shot_name := String(shot.name).to_snake_case()
		if room.call("art_for", shot) != null:
			_painted.append("%s/%s" % [room_folder, shot_name])
			continue
		var picture: Texture2D = shot.get("background")
		if picture == null:
			push_error("No painting for %s/%s" % [room_folder, shot_name])
			continue
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + room_folder))
		picture.get_image().save_jpg(OUT + "%s/%s.jpg" % [room_folder, shot_name], 0.92)
		_list.append("| %s | %s | %dx%d | `art/backgrounds/%s/%s.jpg` |" % [room_folder, shot_name,
				picture.get_width(), picture.get_height(), room_folder, shot_name])
	_next_room()
	return false


func _write_list() -> void:
	var lines := PackedStringArray([
		"# Rooms still waiting for hand-painted art",
		"",
		"Made by `tools/export_paint_list.gd`. Each picture here is what one fixed camera",
		"sees right now, painted automatically from the room's hidden 3D set. Paint over",
		"it (keep the size and framing so the walls and floor still line up with where",
		"the bunny walks), save it to the path in the last column, and the game uses it.",
		"",
		"| Room | Camera | Size | Save your painting as |",
		"|---|---|---|---|",
	])
	lines.append_array(_list)
	lines.append("")
	lines.append("Already hand-painted: " + ", ".join(_painted) + ".")
	var file := FileAccess.open(OUT + "README.md", FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	file.close()
	print("Export paint list: %d to paint, %d already painted." % [_list.size(), _painted.size()])
