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
## Used both as fixed landmarks along the route (placed in the flight scene)
## and as random sights (RouteEvents spawns derelicts and ducks).


enum Kind { LIGHTHOUSE, DONUT, DUCK, DERELICT, BORDER_GATE }

@export var kind: Kind = Kind.LIGHTHOUSE
## Words for it: the derelict's name, or the border gate's sign.
@export var label: String = ""

var _spinner: Node3D
var _blinker: MeshInstance3D
var _time: float = 0.0
var _tumble := Vector3.ZERO


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


func _process(delta: float) -> void:
	_time += delta
	if _spinner != null:
		_spinner.rotate_y(delta * (0.8 if kind == Kind.LIGHTHOUSE else 0.05))
	if _blinker != null:
		_blinker.visible = fposmod(_time, 1.6) < 0.4
	if kind == Kind.DERELICT:
		rotate(_tumble.normalized(), _tumble.length() * delta)
	elif kind == Kind.DUCK:
		position.y += sin(_time * 0.4) * 2.0 * delta  # Bobbing on an invisible pond.


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
		EventKit.box(self, Vector3(70.0, 30.0, 70.0), Vector3(side * 650.0, 300.0, 0.0), EventKit.paint(Color(0.4, 1.0, 0.85), 1.6))
		EventKit.solid(self, Vector3(60.0, 700.0, 60.0), Vector3(side * 650.0, 0.0, 0.0))
		var light := EventKit.glow(self, 140.0, Vector3(side * 650.0, 370.0, 0.0), Color(0.5, 1.0, 0.9))
		light.name = "GateLight"
	EventKit.box(self, Vector3(1360.0, 20.0, 20.0), Vector3(0.0, 340.0, 0.0), EventKit.paint(Color(0.4, 1.0, 0.85), 1.4))
	var words := label if not label.is_empty() else "NOW ENTERING TIDEWATER SYSTEM"
	EventKit.sign(self, words, 0.9, Color(0.5, 1.0, 0.9), Vector3(0.0, 420.0, 12.0))
	EventKit.sign(self, "NOW LEAVING TIDEWATER · HOME SPACE AHEAD", 0.9, Color(0.85, 0.75, 1.0), Vector3(0.0, 420.0, -12.0)).rotation = Vector3(0.0, PI, 0.0)
