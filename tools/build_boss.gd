extends "res://tools/build_truck_stop.gd"
## Builds the boss's look:
##     res://scenes/hub/WeaselVisual.tscn - {boss}, OrbitalEx's regional
##         manager at the truck stop: a weasel in a short-sleeve white shirt
##         and a red tie, hair slicked back, a little mustache, a name badge.
##         Hook: long and thin, with a long thin tail.
## (Only this one scene: it doesn't touch the truck stop or its people.)
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/build_boss.gd


func _initialize() -> void:
	_animator_script = load(ANIMATOR_PATH)
	_blinker_script = load(BLINKER_SCRIPT_PATH)
	_save(_weasel(), "res://scenes/hub/WeaselVisual.tscn")
	quit()


func _weasel() -> Node3D:
	var fur := Color(0.62, 0.45, 0.28)
	var shirt := Color(0.96, 0.96, 0.98)
	var critter := _build_critter("WeaselVisual", _look(fur, Color(0.95, 0.9, 0.78), shirt, Color(0.25, 0.26, 0.3), Color(0, 0, 0, 0), "round", "puff"))
	_remove(critter, ["Body/Head/Headset", "Body/Head/Mic", "Body/Tail"])
	var body := critter.get_node("Body") as Node3D
	body.scale = Vector3(0.88, 1.15, 0.88)  # Long and thin.
	var head := _head(critter)
	head.scale = Vector3(0.88, 0.95, 1.08)
	var snout := head.get_node_or_null("Snout") as Node3D
	if snout != null:
		snout.scale = Vector3(0.9, 0.9, 1.35)  # A pointy face.
	var red := _paint(Color(0.85, 0.12, 0.18), null)
	_box(body, "Tie", Vector3(0.05, 0.2, 0.015), Vector3(0.0, 0.12, -0.12), red)
	_box(body, "TieKnot", Vector3(0.065, 0.045, 0.02), Vector3(0.0, 0.245, -0.12), red)
	_box(body, "Badge", Vector3(0.06, 0.03, 0.01), Vector3(0.1, 0.21, -0.118), _paint(Color(1.0, 0.82, 0.3), null))
	var slick := _paint(fur.darkened(0.45), null)
	_box(head, "SlickedHair", Vector3(0.22, 0.05, 0.24), Vector3(0.0, 0.47, 0.01), slick)
	_box(head, "Mustache", Vector3(0.12, 0.022, 0.015), Vector3(0.0, 0.095, -0.235), slick)
	var tail := _box(body, "LongTail", Vector3(0.06, 0.06, 0.55), Vector3(0.0, -0.22, 0.36), _paint(fur, FUZZ, Vector2(8, 8)))
	tail.rotation = Vector3(-0.45, 0.0, 0.0)
	return critter
