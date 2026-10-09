extends SceneTree
## Used by tools/validate.sh: OVERSPEED. Boosting up to a crazy speed and
## letting go mustn't be a free ride. Puts the rig at 2,400 km/h coasting
## (no boost), and checks it keeps losing control (shakes, the nose pulled
## off course), the hull wears and the overdrive strain builds; then at a
## sane speed, all of that stops. Saves to a scratch file, never the
## player's real save.
##
## Run it with:  godot --headless --path . -s tools/smoke_overspeed.gd


const FAST_KMH: float = 2400.0
const SANE_KMH: float = 700.0

var _time := 0.0
var _started := false
var _stage := 0
var _stage_time := 0.0
var _nose := Vector3.ZERO
var _hull := 1.0


func _initialize() -> void:
	root.get_node("SaveSystem").set("save_path", "user://smoke_test_save.json")
	root.get_node("GameState").call("new_game")


func _process(delta: float) -> bool:
	if not _started:
		_started = true
		root.get_node("DebugMenu").call("skip_opening")
		change_scene_to_file("res://scenes/flight/FlightSandbox.tscn")
		return false
	var flight := current_scene
	if flight == null or not flight.scene_file_path.ends_with("FlightSandbox.tscn"):
		return false
	_time += delta
	if _time < 1.0:
		return false
	var ship: Node3D = flight.get_node("World/Ship")
	var model: Object = ship.get("flight")
	var controls: Object = ship.get("controls")
	match _stage:
		0:
			# Out in empty space, coasting (no boost) at a crazy speed, the
			# throttle up so Flight Assist doesn't brake.
			ship.call("teleport", Transform3D(Basis.IDENTITY, Vector3(0.0, 40000.0, 0.0)))
			model.set("velocity", (model.call("nose") as Vector3) * FAST_KMH / 3.6)
			model.set("boosting", false)
			controls.set("lever", 1.0)
			_nose = model.call("nose")
			_hull = float(ship.get("hull"))
			_stage = 1
			_stage_time = _time
		1:
			if _time - _stage_time > 6.0:
				var instability := float(model.get("instability"))
				var drift := rad_to_deg(_nose.angle_to(model.call("nose") as Vector3))
				if instability <= 0.0:
					return _fail("coasting at %d km/h the rig should be losing control" % FAST_KMH)
				if drift < 1.0:
					return _fail("the nose should get pulled off course (only %.2f° in 6 s)" % drift)
				if float(ship.get("hull")) >= _hull - 0.01:
					return _fail("the hull should wear at %d km/h (%.3f -> %.3f)" % [FAST_KMH, _hull, float(ship.get("hull"))])
				if float(ship.get("overdrive_strain")) <= 0.0:
					return _fail("coasting past the strain speed should still strain her")
				print("Smoke overspeed: at %d km/h coasting, instability %.2f, nose off %.1f°, hull %.0f%%, strain %.2f." % [
						FAST_KMH, instability, drift, float(ship.get("hull")) * 100.0, float(ship.get("overdrive_strain"))])
				# Slow right down: it should all settle.
				model.set("velocity", (model.call("nose") as Vector3) * SANE_KMH / 3.6)
				_hull = float(ship.get("hull"))
				_stage = 2
				_stage_time = _time
		2:
			if _time - _stage_time > 3.0:
				if float(model.get("instability")) > 0.0:
					return _fail("at %d km/h the overspeed shakes should stop" % SANE_KMH)
				if float(ship.get("hull")) < _hull - 0.0001:
					return _fail("at %d km/h the hull should stop wearing" % SANE_KMH)
				print("Smoke overspeed: slowed to %d km/h, all calm again." % SANE_KMH)
				_stage = 3
				root.get_node("GameState").call("quit_game")
	return false


func _fail(why: String) -> bool:
	push_error("Smoke test (overspeed): " + why)
	quit(1)
	return false
