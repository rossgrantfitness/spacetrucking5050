class_name Landmark
extends RoadsideThing
## A roadside attraction or sight you pass on the long haul. Pick its `kind`:
##   LIGHTHOUSE   - a lighthouse in space, beam sweeping, warning ships off a
##                  rock that isn't there anymore
##   DONUT        - THE WORLD'S BIGGEST DONUT, pink frosting, sprinkles
##   DUCK         - a giant rubber duck, slowly turning. Nobody knows why.
##   DERELICT     - an old abandoned hulk, slowly tumbling, one light
##                  still blinking. Shows its name on the HUD.
##   BORDER_GATE  - two huge pylons and a glowing arch where one solar
##                  system ends and the next begins
##   SLOT_MACHINE - THE WORLD'S BIGGEST SLOT MACHINE, reels spinning, lights
##                  chasing round the edge (it has never paid out)
##   DICE         - two giant fuzzy-cornered dice tumbling forever
##   CHAPEL       - the Little Chapel of the Void: a tiny white wedding
##                  chapel on a rock, with a buzzing neon heart
##   SKULL        - the Big Steer Skull: a cow skull the size of a moon,
##                  bleached in the Dustbowl's amber sun
##   WINDMILL     - an old farm windmill turning in the solar wind
##   TREE         - a whole tree floating in space, roots and all, with
##                  little glowing fruit
##   WATERING_CAN - a giant tin watering can, tipping out a stream of
##                  glittering water that never runs out
##   SNOWMAN      - three snowballs the size of hills, a carrot nose, a
##                  scarf. Somebody built it. Nobody knows who.
##   CONE         - a giant ice-cream cone frozen into a comet, three scoops
## Used both as fixed landmarks along the route (placed in the flight scene)
## and as random sights (RouteEvents spawns derelicts and ducks).


enum Kind { LIGHTHOUSE, DONUT, DUCK, DERELICT, BORDER_GATE, SLOT_MACHINE, DICE, CHAPEL, SKULL, WINDMILL, TREE, WATERING_CAN, SNOWMAN, CONE }

@export var kind: Kind = Kind.LIGHTHOUSE
## Words for it: the derelict's name, or the border gate's sign.
@export var label: String = ""
## The border gate only: the sign on its far side (for the trip back), and
## the color of its glow.
@export var back_label: String = "NOW LEAVING TIDEWATER · HOME SPACE AHEAD"
@export var glow_color := Color(0.4, 1.0, 0.85)

var _spinner: Node3D
var _blinker: MeshInstance3D
var _time: float = 0.0
var _tumble := Vector3.ZERO
## Parts that turn on their own (the slot machine's reels, the dice).
var _tumblers: Array[Node3D] = []
var _lights: Array[MeshInstance3D] = []


func _ready() -> void:
	match kind:
		Kind.LIGHTHOUSE:
			_build_lighthouse()
		Kind.DONUT:
			_build_donut()
		Kind.DUCK:
			_build_duck()
		Kind.DERELICT:
			_build_derelict()
		Kind.BORDER_GATE:
			_build_border_gate()
		Kind.SLOT_MACHINE:
			_build_slot_machine()
		Kind.DICE:
			_build_dice()
		Kind.CHAPEL:
			_build_chapel()
		Kind.SKULL:
			_build_skull()
		Kind.WINDMILL:
			_build_windmill()
		Kind.TREE:
			_build_tree()
		Kind.WATERING_CAN:
			_build_watering_can()
		Kind.SNOWMAN:
			_build_snowman()
		Kind.CONE:
			_build_cone()
	# Every sign on a board, held up by a strut (the lettering's measured a
	# frame after it's built).
	await get_tree().process_frame
	if is_inside_tree():
		SignBoards.mount_in_space(self)


func _process(delta: float) -> void:
	_time += delta
	if _spinner != null:
		if kind == Kind.WINDMILL:
			_spinner.rotate_z(delta * 0.35)  # The blades turn in the solar wind.
		else:
			_spinner.rotate_y(delta * (0.8 if kind == Kind.LIGHTHOUSE else 0.05))
	if _blinker != null:
		_blinker.visible = fposmod(_time, 1.6) < 0.4
	if kind == Kind.DERELICT or kind == Kind.DICE:
		for part in _tumblers:
			part.rotate(_tumble.normalized(), _tumble.length() * delta)
		if kind == Kind.DERELICT:
			rotate(_tumble.normalized(), _tumble.length() * delta)
	elif kind == Kind.SLOT_MACHINE:
		for i in _tumblers.size():
			_tumblers[i].rotate_x(delta * (1.5 + i * 0.4))  # The reels spin.
		for i in _lights.size():
			_lights[i].visible = (i + int(_time * 6.0)) % 3 != 0  # Chasing lights.
	elif kind == Kind.DUCK or kind == Kind.TREE:
		position.y += sin(_time * 0.4) * 2.0 * delta  # Bobbing on an invisible pond.
	elif kind == Kind.WATERING_CAN:
		for i in _lights.size():
			# The water drops fall and start again at the spout.
			var fall := fposmod(_time * 60.0 + i * 37.0, 300.0)
			_lights[i].position = Vector3(330.0 + fall * 0.35, 40.0 - fall, (i % 3 - 1) * 14.0)


func _build_lighthouse() -> void:
	var white := EventKit.paint(Color(0.95, 0.95, 0.92))
	var red := EventKit.paint(Color(0.85, 0.2, 0.2))
	for i in 6:
		EventKit.cylinder(self, 40.0 - i * 3.0, 40.0, Vector3(0.0, i * 40.0, 0.0), white if i % 2 == 0 else red)
	EventKit.cylinder(self, 28.0, 30.0, Vector3(0.0, 250.0, 0.0), EventKit.paint(Color(1.0, 0.95, 0.7), 2.0))
	EventKit.cylinder(self, 32.0, 10.0, Vector3(0.0, 270.0, 0.0), red)
	EventKit.glow(self, 260.0, Vector3(0.0, 250.0, 0.0), Color(1.0, 0.92, 0.6))
	# The sweeping beam: two long glowing wedges that turn.
	_spinner = Node3D.new()
	_spinner.position = Vector3(0.0, 250.0, 0.0)
	add_child(_spinner)
	for side: float in [-1.0, 1.0]:
		EventKit.box(_spinner, Vector3(6.0, 6.0, 900.0), Vector3(0.0, 0.0, 450.0 * side), EventKit.paint(Color(1.0, 0.95, 0.7), 1.2))
	EventKit.box(self, Vector3(160.0, 20.0, 160.0), Vector3(0.0, -30.0, 0.0), EventKit.paint(Color(0.45, 0.42, 0.4), 0.0, EventKit.HULL, 20.0))
	EventKit.sign(self, "LIGHTHOUSE · NO ROCK HERE SINCE 4987", 0.25, Color(1.0, 0.9, 0.5), Vector3(0.0, -60.0, 82.0))
	EventKit.solid(self, Vector3(80.0, 280.0, 80.0), Vector3(0.0, 120.0, 0.0))
	show_on_radar("LIGHTHOUSE (DECOMMISSIONED)", 120.0)


func _build_donut() -> void:
	var dough := EventKit.paint(Color(0.85, 0.6, 0.35))
	var frosting := EventKit.paint(Color(1.0, 0.5, 0.8), 0.3)
	_spinner = Node3D.new()
	add_child(_spinner)
	EventKit.torus(_spinner, 120.0, 260.0, Vector3.ZERO, dough, Vector3(PI / 2.0, 0.0, 0.0))
	EventKit.torus(_spinner, 130.0, 250.0, Vector3(0.0, 0.0, 12.0), frosting, Vector3(PI / 2.0, 0.0, 0.0))
	var sprinkles: Array[Color] = [Color(1, 1, 1), Color(0.4, 0.9, 1.0), Color(1.0, 0.9, 0.3), Color(0.5, 1.0, 0.5)]
	for i in 40:
		var angle := TAU * i / 40.0 + rng.randf() * 0.1
		var reach := rng.randf_range(150.0, 230.0)
		EventKit.box(_spinner, Vector3(18.0, 5.0, 5.0), Vector3(cos(angle) * reach, sin(angle) * reach, 70.0),
				EventKit.paint(sprinkles[i % sprinkles.size()], 0.6), Vector3(0.0, 0.0, rng.randf() * TAU))
	EventKit.sign(self, "THE WORLD'S BIGGEST DONUT", 0.6, Color(1.0, 0.6, 0.85), Vector3(0.0, 330.0, 0.0))
	EventKit.sign(self, "(NOT EDIBLE) (WE CHECKED)", 0.25, Color(0.5, 1.0, 1.0), Vector3(0.0, 280.0, 0.0))
	show_on_radar("WORLD'S BIGGEST DONUT", 260.0)


func _build_duck() -> void:
	var yellow := EventKit.paint(Color(1.0, 0.85, 0.15), 0.15)
	EventKit.ball(self, 100.0, Vector3.ZERO, yellow, Vector3(1.3, 0.8, 1.0))
	EventKit.ball(self, 60.0, Vector3(70.0, 90.0, 0.0), yellow)
	EventKit.box(self, Vector3(60.0, 14.0, 40.0), Vector3(130.0, 85.0, 0.0), EventKit.paint(Color(1.0, 0.5, 0.15)))
	for side: float in [-1.0, 1.0]:
		EventKit.ball(self, 9.0, Vector3(105.0, 105.0, 30.0 * side), EventKit.paint(Color(0.05, 0.05, 0.08)))
	EventKit.box(self, Vector3(60.0, 50.0, 10.0), Vector3(-110.0, 50.0, 0.0), yellow, Vector3(0.0, 0.0, 0.6))
	rotation.y = rng.randf() * TAU
	show_on_radar("GIANT RUBBER DUCK (LOST)", 140.0)


func _build_derelict() -> void:
	var hull := EventKit.paint(Color(0.45, 0.43, 0.4), 0.0, EventKit.HULL, 30.0)
	var rust := EventKit.paint(Color(0.55, 0.32, 0.22), 0.0, EventKit.HULL, 30.0)
	EventKit.box(self, Vector3(80.0, 60.0, 260.0), Vector3.ZERO, hull)
	EventKit.box(self, Vector3(60.0, 40.0, 90.0), Vector3(30.0, 45.0, -60.0), rust, Vector3(0.1, 0.0, 0.3))
	EventKit.box(self, Vector3(120.0, 8.0, 50.0), Vector3(-80.0, 0.0, 40.0), hull, Vector3(0.0, 0.2, -0.4))  # A bent wing.
	EventKit.box(self, Vector3(40.0, 40.0, 30.0), Vector3(-10.0, -20.0, 150.0), rust, Vector3(0.5, 0.3, 0.0))  # A loose chunk.
	EventKit.box(self, Vector3(70.0, 10.0, 4.0), Vector3(0.0, 10.0, -131.0), EventKit.paint(Color(0.3, 0.5, 0.6), 0.4))  # Dim windows.
	_blinker = EventKit.box(self, Vector3(8.0, 8.0, 8.0), Vector3(0.0, 34.0, -100.0), EventKit.paint(Color(1.0, 0.3, 0.2), 2.5))
	EventKit.sign(self, "OUT OF ORDER", 0.2, Color(1.0, 0.85, 0.4), Vector3(41.0, 0.0, 0.0)).rotation = Vector3(0.0, PI / 2.0, 0.0)
	_tumble = Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized() * 0.03
	EventKit.solid(self, Vector3(80.0, 60.0, 260.0))
	show_on_radar("DERELICT: " + (label if not label.is_empty() else "UNKNOWN"), 140.0)


func _build_border_gate() -> void:
	add_to_group("border_gates")  # The route events treat gates like stations: busy lanes.
	var steel := EventKit.paint(Color(0.5, 0.55, 0.62), 0.0, EventKit.HULL, 20.0)
	for side: float in [-1.0, 1.0]:
		EventKit.box(self, Vector3(60.0, 700.0, 60.0), Vector3(side * 650.0, 0.0, 0.0), steel)
		EventKit.box(self, Vector3(70.0, 30.0, 70.0), Vector3(side * 650.0, 300.0, 0.0), EventKit.paint(glow_color, 1.6))
		EventKit.solid(self, Vector3(60.0, 700.0, 60.0), Vector3(side * 650.0, 0.0, 0.0))
		var light := EventKit.glow(self, 140.0, Vector3(side * 650.0, 370.0, 0.0), glow_color.lightened(0.2))
		light.name = "GateLight"
	EventKit.box(self, Vector3(1360.0, 20.0, 20.0), Vector3(0.0, 340.0, 0.0), EventKit.paint(glow_color, 1.4))
	var words := label if not label.is_empty() else "NOW ENTERING TIDEWATER SYSTEM"
	EventKit.sign(self, words, 0.9, glow_color.lightened(0.2), Vector3(0.0, 420.0, 12.0))
	EventKit.sign(self, back_label, 0.9, Color(0.85, 0.75, 1.0), Vector3(0.0, 420.0, -12.0)).rotation = Vector3(0.0, PI, 0.0)


func _build_slot_machine() -> void:
	var cabinet := EventKit.paint(Color(0.85, 0.15, 0.55), 0.2)
	var gold := EventKit.paint(Color(1.0, 0.8, 0.3), 0.6)
	var dark := EventKit.paint(Color(0.08, 0.05, 0.12))
	EventKit.box(self, Vector3(420.0, 520.0, 200.0), Vector3.ZERO, cabinet)
	EventKit.box(self, Vector3(440.0, 30.0, 220.0), Vector3(0.0, 275.0, 0.0), gold)
	EventKit.box(self, Vector3(440.0, 30.0, 220.0), Vector3(0.0, -275.0, 0.0), gold)
	EventKit.box(self, Vector3(360.0, 150.0, 10.0), Vector3(0.0, 40.0, 100.0), dark)  # The window.
	# Three reels: drums with colored stripes, spinning forever.
	var symbols: Array[Color] = [Color(1.0, 0.25, 0.3), Color(1.0, 0.85, 0.2), Color(0.3, 0.9, 1.0), Color(0.5, 1.0, 0.4)]
	for i in 3:
		var reel := Node3D.new()
		reel.position = Vector3(-115.0 + i * 115.0, 40.0, 60.0)
		add_child(reel)
		EventKit.cylinder(reel, 70.0, 95.0, Vector3.ZERO, EventKit.paint(Color(0.95, 0.95, 0.9), 0.4), Vector3(0.0, 0.0, PI / 2.0))
		for k in 4:
			var angle := TAU * k / 4.0
			EventKit.box(reel, Vector3(96.0, 30.0, 8.0), Vector3(0.0, sin(angle) * 71.0, cos(angle) * 71.0),
					EventKit.paint(symbols[(k + i) % symbols.size()], 1.4), Vector3(-angle, 0.0, 0.0))
		_tumblers.append(reel)
	# The lever, and the lights chasing round the top.
	EventKit.box(self, Vector3(20.0, 260.0, 20.0), Vector3(240.0, 120.0, 0.0), gold)
	EventKit.ball(self, 34.0, Vector3(240.0, 260.0, 0.0), EventKit.paint(Color(1.0, 0.25, 0.3), 0.8))
	for i in 12:
		_lights.append(EventKit.box(self, Vector3(22.0, 22.0, 10.0), Vector3(-200.0 + i * 36.0, 225.0, 102.0), EventKit.paint(Color(1.0, 0.95, 0.6), 2.4)))
	EventKit.sign(self, "THE WORLD'S BIGGEST SLOT MACHINE", 0.5, Color(1.0, 0.85, 0.35), Vector3(0.0, 340.0, 0.0))
	EventKit.sign(self, "JACKPOT: 0 TIMES SINCE 4990", 0.25, Color(1.0, 0.45, 0.85), Vector3(0.0, -150.0, 105.0))
	EventKit.solid(self, Vector3(420.0, 520.0, 200.0))
	show_on_radar("WORLD'S BIGGEST SLOT MACHINE", 280.0)


func _build_dice() -> void:
	var pip := EventKit.paint(Color(0.08, 0.06, 0.1))
	for i in 2:
		var die := Node3D.new()
		die.position = Vector3(-260.0 + i * 520.0, i * 90.0, 0.0)
		die.rotation = Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)
		add_child(die)
		var body := EventKit.paint(Color(1.0, 0.25, 0.4) if i == 0 else Color(0.95, 0.95, 0.9), 0.3)
		EventKit.box(die, Vector3(300.0, 300.0, 300.0), Vector3.ZERO, body)
		# Pips on three faces (the others you'll just have to imagine).
		for face: Array in [[Vector3(0.0, 0.0, 151.0), Vector3.ZERO], [Vector3(151.0, 0.0, 0.0), Vector3(0.0, PI / 2.0, 0.0)], [Vector3(0.0, 151.0, 0.0), Vector3(PI / 2.0, 0.0, 0.0)]]:
			var turn := Basis.from_euler(face[1])
			for spot: Vector2 in [Vector2(-80.0, -80.0), Vector2(0.0, 0.0), Vector2(80.0, 80.0)]:
				EventKit.box(die, Vector3(50.0, 50.0, 4.0), face[0] + turn * Vector3(spot.x, spot.y, 0.0), pip, face[1])
		EventKit.solid(die, Vector3(300.0, 300.0, 300.0))
		_tumblers.append(die)
	_tumble = Vector3(0.6, 1.0, 0.3).normalized() * 0.08
	EventKit.sign(self, "THE GIANT DICE · PLACE YOUR BETS", 0.45, Color(1.0, 0.5, 0.85), Vector3(0.0, 380.0, 0.0))
	show_on_radar("THE GIANT DICE (STILL ROLLING)", 400.0)


func _build_chapel() -> void:
	var white := EventKit.paint(Color(0.95, 0.93, 0.95))
	var roof := EventKit.paint(Color(1.0, 0.45, 0.75), 0.3)
	var rock := EventKit.paint(Color(0.45, 0.38, 0.5), 0.0, EventKit.ROCK, 30.0)
	EventKit.ball(self, 160.0, Vector3(0.0, -150.0, 0.0), rock, Vector3(1.4, 0.6, 1.2))
	EventKit.box(self, Vector3(120.0, 90.0, 180.0), Vector3(0.0, 0.0, 0.0), white)
	EventKit.box(self, Vector3(130.0, 20.0, 190.0), Vector3(0.0, 55.0, 0.0), roof)
	EventKit.box(self, Vector3(30.0, 120.0, 30.0), Vector3(0.0, 110.0, 70.0), white)  # The steeple.
	EventKit.box(self, Vector3(36.0, 40.0, 36.0), Vector3(0.0, 185.0, 70.0), roof)
	EventKit.box(self, Vector3(40.0, 60.0, 4.0), Vector3(0.0, -15.0, 91.0), EventKit.paint(Color(1.0, 0.85, 0.5), 1.4))  # The door, lit.
	# The neon heart: two balls and a turned box, buzzing.
	var heart := Node3D.new()
	heart.position = Vector3(0.0, 250.0, 70.0)
	add_child(heart)
	var neon := EventKit.paint(Color(1.0, 0.2, 0.55), 2.6)
	EventKit.ball(heart, 22.0, Vector3(-16.0, 10.0, 0.0), neon)
	EventKit.ball(heart, 22.0, Vector3(16.0, 10.0, 0.0), neon)
	EventKit.box(heart, Vector3(36.0, 36.0, 16.0), Vector3(0.0, -10.0, 0.0), neon, Vector3(0.0, 0.0, PI / 4.0))
	_blinker = EventKit.glow(self, 120.0, Vector3(0.0, 250.0, 70.0), Color(1.0, 0.3, 0.6))
	EventKit.sign(self, "LITTLE CHAPEL OF THE VOID", 0.35, Color(1.0, 0.75, 0.9), Vector3(0.0, 310.0, 70.0))
	EventKit.sign(self, "WEDDINGS · VOW RENEWALS · NO REFUNDS", 0.2, Color(0.6, 1.0, 1.0), Vector3(0.0, -100.0, 160.0))
	EventKit.solid(self, Vector3(130.0, 100.0, 190.0))
	show_on_radar("LITTLE CHAPEL OF THE VOID", 160.0)


func _build_skull() -> void:
	var bone := EventKit.paint(Color(0.96, 0.9, 0.78), 0.1, EventKit.ROCK, 60.0)
	var dark := EventKit.paint(Color(0.12, 0.08, 0.06))
	EventKit.ball(self, 220.0, Vector3.ZERO, bone, Vector3(1.0, 0.85, 1.1))  # The brain case.
	EventKit.box(self, Vector3(220.0, 180.0, 300.0), Vector3(0.0, -60.0, 220.0), bone)  # The long face.
	for side: float in [-1.0, 1.0]:
		EventKit.box(self, Vector3(70.0, 60.0, 20.0), Vector3(side * 90.0, 10.0, 210.0), dark)  # Eye holes.
		EventKit.box(self, Vector3(24.0, 40.0, 20.0), Vector3(side * 30.0, -90.0, 370.0), dark)  # Nostrils.
		# The horns: out sideways, then curving up.
		EventKit.box(self, Vector3(320.0, 50.0, 50.0), Vector3(side * 330.0, 80.0, 0.0), bone, Vector3(0.0, 0.0, 0.25 * side))
		EventKit.box(self, Vector3(50.0, 200.0, 50.0), Vector3(side * 500.0, 210.0, 0.0), bone, Vector3(0.0, 0.0, -0.2 * side))
	EventKit.sign(self, "THE BIG STEER · EST. A LONG TIME AGO", 0.4, Color(1.0, 0.7, 0.3), Vector3(0.0, 330.0, 0.0))
	EventKit.solid(self, Vector3(440.0, 380.0, 600.0), Vector3(0.0, -20.0, 100.0))
	show_on_radar("THE BIG STEER (SKULL)", 360.0)


func _build_windmill() -> void:
	var wood := EventKit.paint(Color(0.55, 0.38, 0.25), 0.0, EventKit.HULL, 30.0)
	var tin := EventKit.paint(Color(0.85, 0.82, 0.75), 0.1)
	var red := EventKit.paint(Color(0.85, 0.3, 0.2), 0.2)
	# The tower: four legs leaning in, cross braces, a little platform.
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		EventKit.box(self, Vector3(14.0, 420.0, 14.0), Vector3(corner.x * 50.0, -10.0, corner.y * 50.0), wood, Vector3(-corner.y * 0.12, 0.0, corner.x * 0.12))
	for y: float in [-150.0, 0.0, 120.0]:
		EventKit.box(self, Vector3(140.0 - y * 0.15, 8.0, 8.0), Vector3(0.0, y, 0.0), wood)
	EventKit.box(self, Vector3(60.0, 40.0, 70.0), Vector3(0.0, 210.0, 0.0), red)
	EventKit.box(self, Vector3(10.0, 70.0, 120.0), Vector3(0.0, 210.0, -90.0), tin)  # The tail vane.
	# The blades, turning.
	_spinner = Node3D.new()
	_spinner.position = Vector3(0.0, 210.0, 50.0)
	add_child(_spinner)
	for i in 12:
		var angle := TAU * i / 12.0
		EventKit.box(_spinner, Vector3(22.0, 120.0, 4.0), Vector3(sin(angle) * 90.0, cos(angle) * 90.0, 0.0), tin, Vector3(0.0, 0.0, -angle))
	EventKit.cylinder(_spinner, 18.0, 20.0, Vector3.ZERO, red, Vector3(PI / 2.0, 0.0, 0.0), 8)
	EventKit.sign(self, "PUMPING NOTHING SINCE 4971", 0.3, Color(1.0, 0.75, 0.35), Vector3(0.0, -260.0, 60.0))
	EventKit.solid(self, Vector3(140.0, 460.0, 140.0), Vector3(0.0, 0.0, 0.0))
	show_on_radar("OLD WINDMILL (STILL TURNING)", 200.0)


func _build_tree() -> void:
	var bark := EventKit.paint(Color(0.45, 0.3, 0.2), 0.0, EventKit.HULL, 40.0)
	var leaves := EventKit.paint(Color(0.35, 0.85, 0.4), 0.15, EventKit.ROCK, 80.0)
	EventKit.cylinder(self, 40.0, 360.0, Vector3.ZERO, bark)
	# Roots, trailing below like a jellyfish.
	for i in 7:
		var angle := TAU * i / 7.0
		EventKit.box(self, Vector3(14.0, 240.0, 14.0), Vector3(sin(angle) * 50.0, -280.0, cos(angle) * 50.0), bark, Vector3(cos(angle) * 0.35, 0.0, -sin(angle) * 0.35))
	# The crown: lumpy balls of leaves with little glowing fruit.
	for spot: Vector3 in [Vector3(0.0, 300.0, 0.0), Vector3(150.0, 240.0, 40.0), Vector3(-140.0, 250.0, -50.0), Vector3(30.0, 260.0, 150.0), Vector3(-40.0, 380.0, -40.0)]:
		EventKit.ball(self, 150.0, spot, leaves, Vector3(1.0, 0.8, 1.0))
	for i in 18:
		var spot := Vector3(rng.randf_range(-260.0, 260.0), rng.randf_range(180.0, 420.0), rng.randf_range(-200.0, 260.0))
		EventKit.ball(self, 12.0, spot, EventKit.paint(Color(1.0, 0.75, 0.3), 2.2))
	EventKit.glow(self, 300.0, Vector3(0.0, 300.0, 0.0), Color(0.6, 1.0, 0.5))
	EventKit.solid(self, Vector3(420.0, 300.0, 420.0), Vector3(0.0, 300.0, 0.0))
	EventKit.solid(self, Vector3(80.0, 360.0, 80.0))
	show_on_radar("FLOATING TREE (FREE RANGE)", 360.0)


func _build_watering_can() -> void:
	var tin := EventKit.paint(Color(0.6, 0.85, 0.75), 0.15, EventKit.HULL, 40.0)
	var trim := EventKit.paint(Color(0.95, 0.85, 0.3), 0.3)
	EventKit.cylinder(self, 160.0, 260.0, Vector3.ZERO, tin, Vector3(0.0, 0.0, 0.0), 14)
	EventKit.torus(self, 150.0, 175.0, Vector3(0.0, 130.0, 0.0), trim)
	EventKit.torus(self, 120.0, 140.0, Vector3(-150.0, 160.0, 0.0), tin, Vector3(PI / 2.0, 0.0, 0.0))  # The handle.
	EventKit.box(self, Vector3(260.0, 36.0, 36.0), Vector3(240.0, 80.0, 0.0), tin, Vector3(0.0, 0.0, 0.55))  # The spout.
	EventKit.cylinder(self, 40.0, 30.0, Vector3(345.0, 150.0, 0.0), trim, Vector3(0.0, 0.0, -1.0), 10)  # The rose.
	# Water drops pouring out forever (they fall and loop back in _process).
	for i in 12:
		_lights.append(EventKit.ball(self, 9.0, Vector3(330.0, 40.0, 0.0), EventKit.paint(Color(0.55, 0.9, 1.0), 2.0)))
	EventKit.sign(self, "PLEASE DO NOT DRINK THE NEBULA", 0.3, Color(0.7, 1.0, 0.7), Vector3(0.0, 230.0, 0.0))
	EventKit.solid(self, Vector3(320.0, 260.0, 320.0))
	show_on_radar("GIANT WATERING CAN (ON)", 300.0)


func _build_snowman() -> void:
	var snow := EventKit.paint(Color(0.92, 0.94, 1.0), 0.25, EventKit.ROCK, 80.0)
	var coal := EventKit.paint(Color(0.08, 0.07, 0.1))
	EventKit.ball(self, 260.0, Vector3(0.0, -260.0, 0.0), snow)
	EventKit.ball(self, 190.0, Vector3(0.0, 140.0, 0.0), snow)
	EventKit.ball(self, 130.0, Vector3(0.0, 420.0, 0.0), snow)
	EventKit.box(self, Vector3(24.0, 24.0, 160.0), Vector3(0.0, 420.0, 200.0), EventKit.paint(Color(1.0, 0.5, 0.15), 0.4))  # The carrot.
	for side: float in [-1.0, 1.0]:
		EventKit.ball(self, 18.0, Vector3(side * 45.0, 460.0, 118.0), coal)
		EventKit.box(self, Vector3(260.0, 14.0, 14.0), Vector3(side * 290.0, 200.0, 0.0), EventKit.paint(Color(0.4, 0.28, 0.18)), Vector3(0.0, 0.0, 0.4 * side))  # Twig arms.
	for i in 3:
		EventKit.ball(self, 16.0, Vector3(0.0, 220.0 - i * 70.0, 186.0 - i * 6.0), coal)  # Buttons.
	EventKit.torus(self, 110.0, 150.0, Vector3(0.0, 320.0, 0.0), EventKit.paint(Color(0.75, 0.4, 1.0), 0.3))  # The scarf.
	EventKit.box(self, Vector3(40.0, 180.0, 12.0), Vector3(90.0, 230.0, 120.0), EventKit.paint(Color(0.75, 0.4, 1.0), 0.3), Vector3(0.0, 0.0, -0.2))
	EventKit.sign(self, "WHO BUILT THIS. PLEASE COME FORWARD.", 0.35, Color(0.8, 0.7, 1.0), Vector3(0.0, 640.0, 0.0))
	EventKit.solid(self, Vector3(500.0, 940.0, 500.0), Vector3(0.0, 40.0, 0.0))
	show_on_radar("THE BIG SNOWMAN (UNCLAIMED)", 520.0)


func _build_cone() -> void:
	var ice := EventKit.paint(Color(0.75, 0.85, 1.0), 0.2, EventKit.ROCK, 80.0)
	var waffle := EventKit.paint(Color(0.85, 0.6, 0.3), 0.1, EventKit.HULL, 30.0)
	EventKit.ball(self, 300.0, Vector3(0.0, -120.0, 0.0), ice, Vector3(1.3, 0.8, 1.1))  # The comet it's frozen into.
	var cone := CylinderMesh.new()
	cone.top_radius = 120.0
	cone.bottom_radius = 4.0
	cone.height = 380.0
	cone.radial_segments = 10
	var shell := MeshInstance3D.new()
	shell.mesh = cone
	shell.material_override = waffle
	shell.position = Vector3(0.0, 200.0, 0.0)  # Point down, scoops up.
	add_child(shell)
	var scoops: Array[Color] = [Color(1.0, 0.7, 0.85), Color(0.95, 0.95, 0.85), Color(0.6, 0.4, 0.3)]
	for i in 3:
		EventKit.ball(self, 115.0 - i * 10.0, Vector3(0.0, 410.0 + i * 150.0, 0.0), EventKit.paint(scoops[i], 0.25))
	EventKit.ball(self, 26.0, Vector3(0.0, 820.0, 0.0), EventKit.paint(Color(1.0, 0.15, 0.25), 1.2))  # The cherry.
	EventKit.sign(self, "FLURRY'S · 1 SCOOP FREE WITH EVERY COMET", 0.35, Color(0.9, 0.75, 1.0), Vector3(0.0, -330.0, 300.0))
	EventKit.solid(self, Vector3(260.0, 900.0, 260.0), Vector3(0.0, 400.0, 0.0))
	show_on_radar("GIANT CONE (NOT MELTING)", 450.0)
