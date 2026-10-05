class_name BigShipFlyby
extends RoadsideThing
## A BIG ship crosses the lane ahead of you, well over a kilometer long:
## one of the designs from the developer's sheets (FleetDesigns.gd: the
## Stack-Ship barge, the cryo Tanker, the Ore-Crawler, the Ice-Tug, the
## Hab-Brick or the Garbage Scow), or, when an event asks for a particular
## color, the classic capital freighter built from flat slabs. Its deep engine rumble rises as it comes and drops away as
## it goes (the Doppler effect). The moment the brief calls "the big-ship
## flyby".


const RUMBLE := preload("res://audio/generated/big_engine.wav")
const NAMES := ["RETIREE CRUISE LINER", "NAVY LEISURE BARGE", "DISCOUNT MATTRESS FREIGHTER",
	"MUNICIPAL WASTE HAULER", "BULK SOUP CARRIER", "THE GRAND OLD OPRY-TUNITY", "COLONY MOVING CO."]

## How fast it crosses, in m/s.
@export var crossing_speed: float = 160.0
## Names to pick its ID label from (empty = the usual ones).
var names := PackedStringArray()
## Its hull color (fully transparent = the usual gray).
var hull_color := Color(0.0, 0.0, 0.0, 0.0)
## How fast it crosses compared to normal.
var speed_scale: float = 1.0

var _velocity := Vector3.ZERO
var _travelled: float = 0.0
var _trail := Color(0.5, 0.8, 1.0)


func _ready() -> void:
	if hull_color.a > 0.0:
		_build_classic()
	else:
		var design := FleetDesigns.build(self, rng)
		EventKit.solid(self, design["size"])
		_trail = design["trail"]
		if names.is_empty():
			names = PackedStringArray(design["names"])
	_set_off()


## The classic capital freighter: flat slabs, windows, big engines.
func _build_classic() -> void:
	var hull := EventKit.paint(hull_color if hull_color.a > 0.0 else Color(0.55, 0.58, 0.68), 0.0, EventKit.HULL, 40.0)
	var trim := EventKit.paint(Color(0.85, 0.55, 0.3), 0.0, EventKit.HULL, 40.0)
	var length := 1400.0
	EventKit.box(self, Vector3(220.0, 160.0, length), Vector3.ZERO, hull)
	EventKit.box(self, Vector3(150.0, 90.0, 500.0), Vector3(0.0, 120.0, 300.0), hull)  # Superstructure.
	EventKit.box(self, Vector3(300.0, 30.0, 160.0), Vector3(0.0, 0.0, -500.0), trim)  # Fins.
	for band_z: float in [-400.0, -100.0, 200.0, 500.0]:
		EventKit.box(self, Vector3(226.0, 166.0, 30.0), Vector3(0.0, 0.0, band_z), trim)
	for side: float in [-1.0, 1.0]:
		for row: float in [-40.0, 20.0]:
			EventKit.box(self, Vector3(3.0, 14.0, 1100.0), Vector3(side * 111.0, row, 0.0), EventKit.paint(Color(1.0, 0.85, 0.55), 1.4))
	for engine: Vector3 in [Vector3(-60.0, -40.0, 0.0), Vector3(60.0, -40.0, 0.0), Vector3(-60.0, 40.0, 0.0), Vector3(60.0, 40.0, 0.0)]:
		EventKit.cylinder(self, 45.0, 60.0, engine + Vector3(0.0, 0.0, length * 0.5 + 30.0), EventKit.paint(Color(0.15, 0.15, 0.2)), Vector3(PI / 2.0, 0.0, 0.0))
		EventKit.glow(self, 320.0, engine + Vector3(0.0, 0.0, length * 0.5 + 70.0), Color(0.5, 0.8, 1.0))
	EventKit.solid(self, Vector3(220.0, 160.0, length))


func _set_off() -> void:
	# Cross the lane: start well off to one side and sail across in front,
	# timed to pass just as you get there.
	var across := travel.cross(Vector3.UP).normalized()
	if rng.randf() < 0.5:
		across = -across
	if ship != null:
		var ahead := maxf((global_position - ship.global_position).length(), 1.0)
		crossing_speed = clampf(2600.0 * maxf(ship.flight.speed(), 20.0) / ahead, 60.0, 320.0) * speed_scale
	global_position -= across * 2600.0
	_velocity = across * crossing_speed
	look_at(global_position + _velocity, Vector3.UP)  # Nose first (-Z).
	var label: String = NAMES[rng.randi_range(0, NAMES.size() - 1)]
	if not names.is_empty():
		label = names[rng.randi_range(0, names.size() - 1)]
	show_on_radar(label, 700.0)
	var rumble := EventKit.sound(self, RUMBLE, 6.0, 5000.0)
	rumble.play()


func _physics_process(delta: float) -> void:
	global_position += _velocity * delta
	_travelled += crossing_speed * delta


func is_done() -> bool:
	return _travelled > 6000.0


func trail_color() -> Color:
	return _trail
