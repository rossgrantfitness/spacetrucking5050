class_name FlightHUD
extends CanvasLayer
## The flight HUD: deliberately minimal and tucked into the corners. A speed
## gauge bottom-right, a marker pointing at the truck stop, a marker showing
## where your momentum is really carrying you, a ring showing the mouse's
## steering, and a controls reminder that fades after a while.
##
## The player can hide all of it from the pause menu ("Show HUD"). In cockpit
## view the corner gauge steps aside, because the dashboard shows the same.


## How long the controls reminder stays up, in seconds.
const HINT_SECONDS: float = 25.0

@onready var _gauge: SpeedGauge = $SpeedGauge
@onready var _marker: StationMarker = $StationMarker
@onready var _reticle: MouseReticle = $MouseReticle
@onready var _drift: DriftMarker = $DriftMarker
@onready var _hint: Label = $ControlsHint

var _in_cockpit := false
var _time := 0.0


func _ready() -> void:
	Events.settings_changed.connect(_refresh)
	_refresh()


## Tells the HUD which ship to show and where the destination is.
func setup(ship: Ship, destination: Node3D) -> void:
	_gauge.ship = ship
	_drift.ship = ship
	_reticle.controls = ship.controls
	_marker.target = destination


## Shows what the truck stop is doing for you (boost fuel, hull patching)
## next to its marker while it happens.
func set_truck_stop_service(refueling: bool, repairing: bool) -> void:
	var services: Array[String] = []
	if refueling:
		services.append("BOOST FUEL")
	if repairing:
		services.append("HULL PATCH")
	_marker.label = "TRUCK STOP" if services.is_empty() else "TRUCK STOP · " + " + ".join(services)


func set_cockpit_view(in_cockpit: bool) -> void:
	_in_cockpit = in_cockpit
	_refresh()


func _process(delta: float) -> void:
	_time += delta
	# Fade the controls reminder out over its last 3 seconds.
	_hint.modulate.a = clampf((HINT_SECONDS - _time) / 3.0, 0.0, 1.0)
	_gauge.queue_redraw()
	_reticle.queue_redraw()


func _refresh() -> void:
	var show_hud := Settings.show_hud
	_gauge.visible = show_hud and not _in_cockpit
	_marker.visible = show_hud
	_reticle.visible = show_hud
	_drift.visible = show_hud
	_hint.visible = show_hud and not _in_cockpit  # It would cover the dashboard.
