class_name HazardZone
extends RoadsideThing
## A gentle hazard you can fly through or around:
##   ION_STORM   - a glowing, crackling cloud. Inside, the radio fills with
##                 static, the HUD's STORM light comes on and the rig gets
##                 the odd jolt. Nothing breaks; it's just weather.
##   SPEED_TRAP  - a space-cop radar buoy. Nearby, the HUD's COPS light (the
##                 trucker's radar detector) comes on. Zoom past it faster
##                 than the limit and you get a small fine and a comm call
##                 from the deputy. A speed trap, not a fight.
## The flight scene asks every zone how strongly it affects the rig each
## frame (see influence()).


## Emitted when a speed trap catches you speeding.
signal caught_speeding(kmh: int)

enum Kind { ION_STORM, SPEED_TRAP }

@export var kind: Kind = Kind.ION_STORM
## How far it reaches, in meters.
@export var radius: float = 1500.0
## Speed traps only: the limit, and the fine.
@export var speed_limit_kmh: float = 250.0
@export var fine: int = 25
## Ion storms only: the color of its glow (fully transparent = the usual
## minty green).
@export var tint := Color(0.0, 0.0, 0.0, 0.0)

var _flashes: Array[MeshInstance3D] = []
var _lights: Array[MeshInstance3D] = []
var _time: float = 0.0
var _caught: bool = false


func _ready() -> void:
	add_to_group("hazard_zones")
	if kind == Kind.ION_STORM:
		_build_storm()
	else:
		_build_speed_trap()


## How strongly this zone affects `rig` right now: {"storm": 0..1,
## "speed_trap": 0..1}. Also catches speeders.
func influence(rig: Ship) -> Dictionary:
	var distance := rig.global_position.distance_to(global_position)
	var strength := clampf((radius - distance) / (radius * 0.4), 0.0, 1.0)
	if kind == Kind.ION_STORM:
		return {"storm": strength}
	# The radar buoy: the detector lights up within reach; the trap itself
	# only clocks you when you pass close.
	var close := distance < radius * 0.3
	var kmh := rig.flight.speed() * 3.6
	if close and kmh > speed_limit_kmh and not _caught:
		_caught = true
		caught_speeding.emit(roundi(kmh))
	elif not close:
		_caught = false
	return {"speed_trap": strength}


func _process(delta: float) -> void:
	_time += delta
	for flash in _flashes:
		flash.visible = randf() < 0.04  # Lightning crackles.
	for i in _lights.size():
		_lights[i].visible = fposmod(_time + i * 0.35, 0.7) < 0.35  # Red, blue, red...


func _build_storm() -> void:
	var colors: Array[Color] = [Color(0.3, 1.0, 0.8), Color(0.5, 0.9, 1.0), Color(0.4, 1.0, 0.55)]
	if tint.a > 0.0:
		colors = [tint, tint.lightened(0.3), tint.darkened(0.2)]
	for i in 34:
		var spot := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.5, 0.5), rng.randf_range(-1, 1)) * radius * 0.7
		EventKit.glow(self, rng.randf_range(500.0, 1100.0), spot, Color(colors[i % 3], 0.35))
	for i in 10:
		var spot := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.4, 0.4), rng.randf_range(-1, 1)) * radius * 0.6
		var flash := EventKit.glow(self, 420.0, spot, Color(0.85, 1.0, 1.0))
		flash.visible = false
		_flashes.append(flash)


func _build_speed_trap() -> void:
	EventKit.cylinder(self, 14.0, 60.0, Vector3.ZERO, EventKit.paint(Color(0.15, 0.2, 0.4)))
	EventKit.cylinder(self, 20.0, 8.0, Vector3(0.0, -34.0, 0.0), EventKit.paint(Color(0.95, 0.95, 0.95)))
	EventKit.box(self, Vector3(30.0, 12.0, 12.0), Vector3(0.0, 40.0, 0.0), EventKit.paint(Color(0.2, 0.2, 0.25)))
	for side: float in [-1.0, 1.0]:
		var color := Color(1.0, 0.2, 0.2) if side < 0.0 else Color(0.3, 0.5, 1.0)
		EventKit.box(self, Vector3(10.0, 8.0, 10.0), Vector3(side * 12.0, 48.0, 0.0), EventKit.paint(color, 2.5))
		_lights.append(EventKit.glow(self, 90.0, Vector3(side * 12.0, 50.0, 0.0), color))
	EventKit.sign(self, "SPEED CHECKED BY RADAR", 0.12, Color(1.0, 1.0, 1.0), Vector3(0.0, 80.0, 0.0), true)
	EventKit.sign(self, "LIMIT %d KM/H" % roundi(speed_limit_kmh), 0.12, Color(1.0, 0.85, 0.3), Vector3(0.0, 64.0, 0.0), true)
	EventKit.solid(self, Vector3(40.0, 80.0, 40.0))
	show_on_radar("SPACE PATROL RADAR BUOY", 40.0)
