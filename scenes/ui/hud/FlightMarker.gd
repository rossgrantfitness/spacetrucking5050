class_name FlightMarker
extends HudWidget
## The middle of the screen, kept tiny:
## - The flight marker: a dot with little wings, sitting where your momentum
##   is really carrying you. After a hard turn or a boost it slides away
##   from where the rig points, then drifts back as grip catches up. It's
##   not a gun sight; there's nothing to shoot.


## How far ahead along our path the marker is placed, in meters.
const LOOK_AHEAD: float = 400.0

func _draw() -> void:
	var rig := ship()
	if rig == null:
		return
	if rig.flight.speed() > 3.0:
		var heading_to := rig.get_global_transform_interpolated().origin + rig.flight.velocity.normalized() * LOOK_AHEAD
		if not hud.is_behind(heading_to):
			var spot := hud.to_hud(heading_to).round()
			pixels(spot - Vector2.ONE, ["###", "#.#", "###"], Color(GREEN, 0.9))
			box(Rect2(spot + Vector2(-7, 0), Vector2(4, 1)), Color(GREEN, 0.9))
			box(Rect2(spot + Vector2(4, 0), Vector2(4, 1)), Color(GREEN, 0.9))
