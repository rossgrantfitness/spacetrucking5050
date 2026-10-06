extends Node
## The galaxy's clock. It runs while you play: fast while you're flying (a
## 10-minute haul is a day or two on the road), gently while you walk around
## the parked rig, and not at all on the title screen or in paused menus.
## How fast is in tuning.tres ("Time and bills"); the calendar itself (days,
## months, weeks, bills) is in Economy.gd.
##
## There are no shifts (the developer's call: space truckers don't do three
## deliveries a day). Night is just night: the crew turn in, and the
## Afterglow Block radio station comes on.


enum Pace {
	STOPPED,  ## Menus, the title screen, loading: the clock stands still.
	ABOARD,  ## Walking around while parked.
	FLYING,  ## On the road.
}

## Emitted every time the clock ticks over to a new in-game minute.
signal minute_passed

## How fast the clock runs right now (worked out each frame from what's on
## screen; see _current_pace).
var pace: Pace = Pace.STOPPED


func _process(delta: float) -> void:
	pace = _current_pace()
	var rate := 0.0
	match pace:
		Pace.FLYING:
			rate = GameState.tuning.flight_minutes_per_second
		Pace.ABOARD:
			rate = GameState.tuning.aboard_minutes_per_second
	if rate <= 0.0:
		return
	var before := floori(GameState.minute)
	Economy.advance_minutes(delta * rate)
	if floori(GameState.minute) != before:
		minute_passed.emit()


## Flying (the flight scene, even with her up and about in the cabin),
## walking around a room, or neither.
func _current_pace() -> Pace:
	var scene := get_tree().current_scene
	if scene == null:
		return Pace.STOPPED
	if scene.scene_file_path.ends_with("FlightSandbox.tscn"):
		return Pace.FLYING
	if scene is HubRoom:
		return Pace.ABOARD
	return Pace.STOPPED


## Whether it's night on the galaxy's clock: 9 p.m. to 6 a.m.
func is_night() -> bool:
	var hour := Economy.hour()
	return hour >= 21 or hour < 6
