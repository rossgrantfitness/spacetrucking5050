extends SceneTree
## Films the shots for the 30-second trailer, straight out of the real game,
## with a feature caption on each (in the game's own pixel font). Run by
## tools/trailer/make_trailer.sh, which films each part with Godot's Movie
## Maker, cuts the shots to the beat, and lays the music under them.
##
## One part per run (pass it after "--"):
##     flight - out in space: boost, billboards, landmarks, the cockpit
##              radio, a drive-through, a dust storm, a crash, the
##              cinema camera
##     rooms  - on foot: the cabin, dispatch, the casino, the creamery,
##              the boss's office
##     cards  - the two title cards
## Each shot prints "CUT|name|first frame|last frame" so the script knows
## where to cut (frames before a shot's first frame are just the camera
## settling, and get thrown away).
##
## It saves to a scratch file, never the player's real save.

const GLIMMER_START := Vector3(0.0, 0.0, -10600.0)
const GLIMMER_ALONG := Vector3(-0.7727, -0.2588, -0.5796)
const DUSTBOWL_END := Vector3(52000.0, -34000.0, 12000.0)

## How long each shot is filmed (the script trims to the beat), and how
## long the camera gets to settle before it starts.
const SHOT_FRAMES := 84
const SETTLE_FRAMES := 45

var _part := "flight"
var _shots: Array = []
var _shot := -1
var _shot_started := 0
var _frame := 0
var _game: Node
var _overlay: Control
var _caption := ""
var _caption_top := false
var _caption_from := 0
var _card_title := ""
var _card_sub := ""
var _black := false
## The game's pixel font (loaded by path: a "-s" script can't name the
## game's classes directly).
var _font: Variant


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("part="):
			_part = arg.trim_prefix("part=")
	root.get_node("SaveSystem").set("save_path", "user://trailer_save.json")
	_font = load("res://scenes/ui/PixelFont.gd")
	_game = root.get_node("GameState")
	_game.call("new_game")
	for flag in ["opening_called", "met_boss", "first_check", "heard_about_marge", "met_marge", "first_mission_done",
			"glimmer_heard", "glimmer_open", "dustbowl_open", "greenhouse_open", "frostline_open"]:
		_game.call("set_flag", flag)
	_game.set("launch_from", "truck_stop")
	root.get_node("Settings").call("set_show_hud", false)
	var layer := CanvasLayer.new()
	layer.layer = 120
	root.add_child.call_deferred(layer)
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_overlay)
	layer.add_child(_overlay)
	match _part:
		"flight":
			_shots = ["boost", "billboards", "slot_machine", "cockpit_radio", "drive_through", "dust_storm", "cinema", "crash"]
			change_scene_to_file("res://scenes/flight/FlightSandbox.tscn")
		"rooms":
			_shots = ["cabin", "dispatch", "casino", "creamery", "office"]
		"cards":
			_shots = ["card_wheel", "card_title"]


func _process(_delta: float) -> bool:
	_frame += 1
	_overlay.queue_redraw()
	if _frame < 40:
		return false
	var waited := _frame - _shot_started
	if _shot < 0 or waited >= _length():
		if _shot >= 0:
			print("CUT|%s|%d|%d" % [_shots[_shot], _shot_started + _settle(), _frame - 1])
		_shot += 1
		if _shot >= _shots.size():
			root.get_node("Settings").call("set_show_hud", true)
			quit()
			return false
		_shot_started = _frame
		_caption = ""
		_caption_top = false
		_card_title = ""
		_card_sub = ""
		_black = false
		_begin(_shots[_shot])
		return false
	_during(_shots[_shot], waited)
	if waited == _settle():
		_caption_from = _frame
	return false


func _settle() -> int:
	return 0 if _part == "cards" else SETTLE_FRAMES


func _length() -> int:
	if _part == "cards":
		return 80
	return _settle() + SHOT_FRAMES


# --- The shots ----------------------------------------------------------------------

func _begin(shot: String) -> void:
	match shot:
		# Out in space.
		"boost":
			# Out of the truck stop through the ring of rocks, boosting.
			var dir := Vector3(0.15, 0.05, 1.0).normalized()
			_place_ship(Vector3(0.0, 40.0, -10600.0 + 900.0), dir, 60.0)
			_lever(1.0)
			Input.action_press("boost")
			_caption = "HAUL ODD CARGO ACROSS A SURREAL GALAXY"
		"billboards":
			Input.action_release("boost")
			_place_ship(GLIMMER_START + GLIMMER_ALONG * 45500.0 + Vector3.UP * 60.0, GLIMMER_ALONG, 55.0)
			_lever(1.0)
			_caption = "SIX STAR SYSTEMS TO HAUL THROUGH"
		"slot_machine":
			var thing := _node("World/GlimmerRoadside/BiggestSlotMachine")
			var right := GLIMMER_ALONG.cross(Vector3.UP).normalized()
			_place_ship(thing.global_position - GLIMMER_ALONG * 1700.0 - right * 700.0 - Vector3.UP * 150.0, GLIMMER_ALONG, 55.0)
			_lever(1.0)
			_caption = "WEIRD ROADSIDE ATTRACTIONS"
		"cockpit_radio":
			var place := _node("World/Places/tidewater")
			var ring := _node("World/Places/tidewater/ApproachRing")
			var through: Vector3 = ring.call("through_direction")
			_place_ship(ring.global_position - through * 2600.0, (place.global_position - (ring.global_position - through * 2600.0)).normalized(), 50.0)
			_lever(0.9)
			_press("toggle_camera")
			root.get_node("Settings").call("set_show_hud", true)
			_caption = "20 RADIO STATIONS, DJS, AND YOUR OWN MUSIC"
		"drive_through":
			_press("toggle_camera")
			root.get_node("Settings").call("set_show_hud", false)
			var ring := _node("World/Places/gas_n_go/ApproachRing")
			var through: Vector3 = ring.call("through_direction")
			_place_ship(ring.global_position - through * 420.0, through, 45.0)
			current_scene.call("engage_course", PackedStringArray(["gas_n_go"]))
			_caption = "PULL IN, FILL UP, DELIVER, GET PAID"
		"dust_storm":
			var storm := _node("World/DustbowlRoadside/Storm40Km")
			var along := (DUSTBOWL_END - GLIMMER_START).normalized()
			_place_ship(storm.global_position - along * 900.0, along, 55.0)
			_lever(1.0)
			_caption = "STORMS, TRAFFIC AND SPEED TRAPS"
		"crash":
			# Straight into the side of The High Roller, far too fast.
			var station := _node("World/Places/high_roller/HighRollerStation")
			var target := station.global_transform * Vector3(0.0, 0.0, -120.0)  # The middle of the drum.
			var side := station.global_transform.basis.x
			var start := target + side * 720.0  # The drum's hull is 260 m out.
			_place_ship(start, (target - start).normalized(), 30.0)
			_lever(1.0)
			_caption = "JUST DON'T HIT THE CASINO AT 900 KM/H"
		"cinema":
			var ring := _node("World/Places/tidewater/ApproachRing")
			var through: Vector3 = ring.call("through_direction")
			_place_ship(ring.global_position - through * 6000.0 + Vector3.UP * 300.0, through, 55.0)
			current_scene.call("engage_course", PackedStringArray(["tidewater"]))
			_caption = "OR KICK BACK ON AUTOPILOT"
		# On foot.
		"cabin":
			_room("res://scenes/hub/Apartment.tscn", "")
			_caption = "A COZY PS1-STYLE SPACE TRUCKING GAME"
		"dispatch":
			_room("res://scenes/hub/Dispatch.tscn", "")
			_caption = "YOUR RIG IS YOUR HOME. YOUR CREW COMES TOO."
			_caption_top = true
		"casino":
			_room("res://scenes/hub/HighRollerLounge.tscn", "FromShip")
			_caption = "CLIENTS WITH STORIES OF THEIR OWN"
			_caption_top = true
		"creamery":
			_room("res://scenes/hub/Creamery.tscn", "FromShip")
			_caption = "CLIMB OUT AND WANDER EVERY STOP"
			_caption_top = true
		"office":
			_room("res://scenes/hub/OrbitalExOffice.tscn", "")
			_caption = "WORK FOR THE MAN. THEN BUY HIS COMPANY."
			_caption_top = true
		# Cards.
		"card_wheel":
			_black = true
			_card_title = "TAKE THE WHEEL."
		"card_title":
			_black = true
			_card_title = "SPACE TRUCKIN' 5050"
			_card_sub = "A COZY SPACE TRUCKER  ·  IN DEVELOPMENT"


func _during(shot: String, waited: int) -> void:
	match shot:
		"cockpit_radio":
			if waited == SETTLE_FRAMES + 8:
				_press("radio_next")
		"crash":
			if waited == SETTLE_FRAMES - 20:
				var ship := _ship()
				ship.get("flight").set("velocity", -ship.global_basis.z * 330.0)
		"cinema":
			if waited == 10:
				_press("cinema_camera")
		"dispatch":
			if waited == SETTLE_FRAMES:
				_say("dispatch_morning", "Morning, hon. You look like you slept in your jacket again.")
		"casino":
			if waited == 5:
				(current_scene.get("player") as Node3D).global_position = Vector3(-5.6, 0.0, -2.6)
			if waited == SETTLE_FRAMES:
				_say("casino_sal", "Champ! My favorite hauler. Don't tell the others. There are no others.")
		"creamery":
			if waited == 5:
				(current_scene.get("player") as Node3D).global_position = Vector3(-2.0, 0.0, 1.0)
			if waited == SETTLE_FRAMES:
				_say("frostline_penny", "You made the climb! Nobody comes back! Cone? Cone.")
		"office":
			if waited == 5:
				(current_scene.get("player") as Node3D).global_position = Vector3(0.0, 0.0, -6.5)
			if waited == SETTLE_FRAMES:
				_say("company_boss", "Rabbit. You're late. Here's your check. Don't spend it all in one place.")
	if waited == 6 and _part == "rooms":
		_hide_room_hud()


# --- Helpers ------------------------------------------------------------------------

func _node(path: String) -> Node3D:
	return current_scene.get_node(path) as Node3D


func _ship() -> Node3D:
	return current_scene.get_node("World/Ship") as Node3D


## Puts the rig at `where`, pointed along `dir`, already moving at `speed`,
## with the chase camera snapped in behind.
func _place_ship(where: Vector3, dir: Vector3, speed: float) -> void:
	var ship := _ship()
	ship.call("teleport", Transform3D(Basis.looking_at(dir, Vector3.UP), where))
	ship.get("flight").set("velocity", dir * speed)
	var chase := current_scene.find_child("ChaseCamera", true, false)
	if chase != null:
		chase.call("snap_behind_target")


func _lever(value: float) -> void:
	_ship().get("controls").set("lever", value)


func _press(action: String) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)


func _room(scene: String, spawn: String) -> void:
	root.get_node("Dialogue").call("cancel")  # The last room's chat ends here.
	_game.set("next_spawn", spawn)
	change_scene_to_file(scene)


func _say(npc_file: String, line: String) -> void:
	var npc: Resource = load("res://data/npcs/%s.tres" % npc_file)
	var dialogue := root.get_node("Dialogue")
	var speaker: String = _game.get("names").call("fill_in", str(npc.get("display_name")))
	dialogue.call("say", speaker.split(" (")[0], PackedStringArray([line]), float(npc.get("voice_pitch")), npc)


func _hide_room_hud() -> void:
	for node in current_scene.find_children("*", "CanvasLayer", true, false):
		if node.get_script() != null and str(node.get_script().resource_path).ends_with("HubHUD.gd"):
			(node as CanvasLayer).visible = false


func _draw_overlay() -> void:
	var size := _overlay.size
	if _black:
		_overlay.draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.02, 0.05))
		var k := clampf(float(_frame - _shot_started) / 8.0, 0.0, 1.0)
		if not _card_title.is_empty():
			var square := 9.0
			_font.draw_centered(_overlay, size * 0.5 - Vector2(0.0, 30.0 if not _card_sub.is_empty() else 0.0), _card_title, square,
					Color(1.0, 0.85, 0.3, k), 0.15)
		if not _card_sub.is_empty():
			_font.draw_centered(_overlay, size * 0.5 + Vector2(0.0, 60.0), _card_sub, 3.0, Color(0.75, 0.8, 1.0, k))
			_overlay.draw_rect(Rect2(Vector2(size.x * 0.5 - 300.0, size.y * 0.5 + 25.0), Vector2(600.0, 6.0)), Color(1.0, 0.4, 0.75, k))
		return
	if _caption.is_empty() or _shot < 0 or _frame - _shot_started < _settle():
		return
	# A lower-third (or top, when someone's talking): a hazard-yellow bar
	# and big pixel letters, sliding in.
	var t := clampf(float(_frame - _caption_from) / 6.0, 0.0, 1.0)
	var square := 4.0
	var width: float = _font.width(_caption, square)
	var y := 60.0 if _caption_top else size.y - 140.0
	var x := 48.0 - (1.0 - t) * 60.0
	var box := Rect2(Vector2(x, y), Vector2(width + 44.0, 52.0))
	_overlay.draw_rect(box, Color(0.04, 0.03, 0.1, 0.82 * t))
	_overlay.draw_rect(Rect2(box.position, Vector2(8.0, box.size.y)), Color(1.0, 0.85, 0.25, t))
	_font.draw(_overlay, box.position + Vector2(26.0, 12.0), _caption, square, Color(1.0, 1.0, 1.0, t), 0.15)
