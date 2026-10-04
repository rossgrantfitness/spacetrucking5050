class_name RouteSign
extends RoadsideThing
## A big highway sign floating by the space lane, classic green with white
## letters: distances, the next fuel stop, welcome messages. Mundane trucker
## stuff in the middle of the void. It reads from both sides: `front_text`
## faces its +Z side, `back_text` its -Z side (for the trip back).


@export_multiline var front_text: String = "TIDEWATER  40 KM"
@export_multiline var back_text: String = "HOME BASE  20 KM"
@export var board_color: Color = Color(0.1, 0.45, 0.25)


func _ready() -> void:
	var board := EventKit.paint(board_color)
	var trim := EventKit.paint(Color(0.95, 0.95, 0.9), 0.6)
	var steel := EventKit.paint(Color(0.55, 0.58, 0.62), 0.0, EventKit.HULL, 6.0)
	EventKit.box(self, Vector3(360.0, 100.0, 4.0), Vector3.ZERO, board)
	for edge: Array in [[Vector3(364.0, 4.0, 5.0), Vector3(0.0, 50.0, 0.0)], [Vector3(364.0, 4.0, 5.0), Vector3(0.0, -50.0, 0.0)],
			[Vector3(4.0, 104.0, 5.0), Vector3(-180.0, 0.0, 0.0)], [Vector3(4.0, 104.0, 5.0), Vector3(180.0, 0.0, 0.0)]]:
		EventKit.box(self, edge[0], edge[1], trim)
	# A truss underneath, like a highway gantry, with blinking lamps.
	EventKit.box(self, Vector3(12.0, 160.0, 12.0), Vector3(0.0, -130.0, 0.0), steel)
	for x: float in [-150.0, 150.0]:
		EventKit.glow(self, 30.0, Vector3(x, 58.0, 6.0), Color(1.0, 0.9, 0.6))
	EventKit.sign(self, front_text, 0.24, Color(0.98, 0.98, 0.95), Vector3(0.0, 0.0, 2.5))
	var back := EventKit.sign(self, back_text, 0.24, Color(0.98, 0.98, 0.95), Vector3(0.0, 0.0, -2.5))
	back.rotation = Vector3(0.0, PI, 0.0)
	EventKit.solid(self, Vector3(360.0, 100.0, 6.0))
