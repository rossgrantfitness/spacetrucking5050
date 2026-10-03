class_name FlightControls
extends RefCounted
## What the pilot is asking for at this instant. ShipControls fills it in from
## the keyboard, mouse or gamepad; later an autopilot (docking, M2) can fill it
## in instead, and the ship won't know the difference.


## Steering, each axis from -1 to 1:
##   x: +1 = turn right, -1 = turn left
##   y: +1 = nose up,    -1 = nose down (invert Y is already applied)
var steer := Vector2.ZERO

## Moving the throttle lever: +1 = pushing it up, -1 = pulling it down,
## 0 = leaving it where it is. Analog triggers give in-between values.
var throttle_change := 0.0

## True while the boost button is held.
var boost := false
