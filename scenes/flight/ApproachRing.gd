class_name ApproachRing
extends Node3D
## A docking portal floating in front of a docking bay: the developer's model
## (art/models/docking_portal.glb), a chunky ring of girders, lamps and
## DOCKING PORTAL stencils. Fly through it and the autopilot takes over and
## docks you (see FlightSandbox.gd).
##
## Every portal is turned to its own random angle and slowly turns at its own
## pace, so no two look alike (the same portal always looks the same: the
## randomness is seeded by where it is in the scene).
##
## The ring faces along its own Z axis: fly through it along -Z (put it in
## front of the bay, rotated so its -Z points at the bay).


const MODEL := preload("res://art/models/docking_portal.glb")
## The model's clear hole: its middle and its radius, as shares of the
## model's size (the hub block on one side narrows it, so this is the narrow
## side). The model is scaled so this hole is `radius` across.
const MODEL_HOLE_CENTER := Vector2(-0.05, 0.0)
const MODEL_HOLE_RADIUS := 0.21

## How big the hole is (radius, in meters). Generous: docking should be easy.
@export var radius: float = 60.0
## The color of things that point at this ring (like a rest stop's neon);
## the portal model has its own paint.
@export var color: Color = Color(0.35, 0.95, 1.0)
## The fastest a portal turns, in degrees per second (each picks its own
## speed and direction, up to this).
@export var max_spin_degrees: float = 6.0

var _spinner: Node3D
var _spin: float = 0.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(get_path()))
	_spinner = Node3D.new()
	_spinner.name = "Portal"
	_spinner.rotation.z = rng.randf() * TAU
	add_child(_spinner)
	var model := MODEL.instantiate() as Node3D
	var size := radius / MODEL_HOLE_RADIUS
	model.scale = Vector3.ONE * size
	model.position = -Vector3(MODEL_HOLE_CENTER.x, MODEL_HOLE_CENTER.y, 0.0) * size
	_spinner.add_child(model)
	_spin = deg_to_rad(rng.randf_range(0.3, 1.0) * max_spin_degrees) * (1.0 if rng.randf() < 0.5 else -1.0)


func _process(delta: float) -> void:
	_spinner.rotation.z += _spin * delta


## Whether `point` (in the world) is passing through the ring's hole.
func is_inside(point: Vector3) -> bool:
	return hole_contains(to_local(point), radius)


## Whether a spot measured from the ring's middle is in its hole (within
## 25 m in front or behind, and inside the radius).
static func hole_contains(local: Vector3, hole_radius: float) -> bool:
	return absf(local.z) < 25.0 and Vector2(local.x, local.y).length() < hole_radius


## The direction you fly through it (toward the bay), in the world.
func through_direction() -> Vector3:
	return -global_basis.z
