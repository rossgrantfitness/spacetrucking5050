class_name FlightControls
extends RefCounted
## What the pilot is asking for at this instant. ShipControls fills it in from
## the keyboard, mouse or gamepad; later an autopilot (docking, M2) can fill it
## in instead, and the ship won't know the difference.


## Steering, each axis from -1 to 1:
##   x: +1 = turn right, -1 = turn left
##   y: +1 = nose up,    -1 = nose down (invert Y is already applied)
var steer := Vector2.ZERO

## Engine thrust: +1 = full burn forward, -1 = full burn backward (that's how
## you brake), 0 = engines idle, just coasting. Analog triggers give
## in-between values.
var thrust := 0.0

## True while the boost button is held.
var boost := false

## Newtonian flight only (see "Newtonian flight" in tuning.tres):
## Rolling: +1 = roll right (clockwise, seen from behind), -1 = roll left.
var roll := 0.0
## The side and up/down thrusters: x +1 = slide right, y +1 = slide up.
var strafe := Vector2.ZERO

## How hard the throttle keys (or triggers) are pushed this step, -1 to 1
## (0 = not touching them).
var throttle_push := 0.0

## True when the pilot's hands are actually on the controls this step
## (moving the throttle lever, boosting, or steering for real). Grabbing the
## controls takes over from the cruise autopilot.
var touched := false


## Whether the pilot is actually doing something (not just resting a hand on
## the mouse). Grabbing the controls takes over from the cruise autopilot.
func is_touched() -> bool:
	return touched or steer.length() > 0.3 or boost or absf(roll) > 0.3 or strafe.length() > 0.3
