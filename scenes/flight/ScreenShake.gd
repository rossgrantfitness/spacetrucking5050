class_name ScreenShake
extends RefCounted
## Trauma-based screen shake (from Squirrel Eiserloh's GDC talk "Juicing Your
## Cameras With Math").
##
## Things that jolt the ship add "trauma", a number from 0 to 1 that drains
## away over time. The actual shake is trauma SQUARED, so small bumps barely
## register while big ones really kick. The wobble comes from smooth noise,
## never pure randomness, so it feels like a jolt rather than a glitch.
## Players can switch shake off in the pause menu.


## How shaken up we are right now, 0 to 1.
var trauma := 0.0
## A steady minimum, e.g. a gentle rumble while boosting.
var rumble := 0.0

var _noise := FastNoiseLite.new()
var _time := 0.0


func _init() -> void:
	_noise.seed = 5050
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH


func add_trauma(amount: float) -> void:
	trauma = minf(trauma + amount, 1.0)


## Drains trauma; call once per step.
func update(delta: float, decay: float) -> void:
	_time += delta
	trauma = maxf(trauma - decay * delta, 0.0)


## How strong the shake is right now, 0 to 1 (0 if the player turned it off).
func strength() -> float:
	if not Settings.screen_shake:
		return 0.0
	var level := maxf(trauma, rumble)
	return level * level


## A camera nudge, up to `max_offset` meters in each direction.
func offset(max_offset: float) -> Vector3:
	var amount := strength() * max_offset
	return Vector3(_wobble(0.0), _wobble(100.0), _wobble(200.0)) * amount


## A camera tilt, up to `max_tilt` radians either way.
func tilt(max_tilt: float) -> float:
	return _wobble(300.0) * strength() * max_tilt


func _wobble(channel: float) -> float:
	return _noise.get_noise_2d(_time * 30.0, channel)
