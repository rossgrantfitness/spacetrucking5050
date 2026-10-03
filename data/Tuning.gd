class_name Tuning
extends Resource
## Every "feel" number in Space Truckin' 5050 lives here, in one place.
##
## HOW TO TWEAK: in the FileSystem dock (bottom-left of the editor),
## double-click res://data/tuning.tres. Its values appear in the Inspector
## (right side). Hover over a value's name to read what it does. Change it,
## press Play, and feel the difference. No code needed.
##
## The numbers written below are the STARTING values. Anything you change in
## the Inspector is saved in tuning.tres and wins over these. Click the little
## circular "revert" arrow next to a value to go back to its starting value.
##
## New groups get added as features arrive (flight in M1, money in M2, ...).


@export_group("Steering input")

## How far a stick has to move before the game listens (0 = listens to the
## tiniest twitch). Raise this if things drift while you aren't touching the
## stick; lower it if small movements feel ignored.
@export_range(0.0, 0.5, 0.01) var stick_deadzone: float = 0.15

## How quickly steering catches up with your stick, keys or mouse.
## Higher = snappier and twitchier. Lower = smoother and floatier.
## (At 10, steering is about 2/3 of the way there after 0.1 seconds.)
@export_range(1.0, 30.0, 0.5) var steer_response: float = 10.0

## How far a mouse movement pushes the "virtual stick" when steering with the
## mouse. Higher = smaller hand movements steer harder.
@export_range(0.001, 0.05, 0.001) var mouse_sensitivity: float = 0.008

## How quickly the mouse's virtual stick drifts back to center after you stop
## moving the mouse. 0 = it stays wherever you leave it.
@export_range(0.0, 10.0, 0.1) var mouse_recenter_speed: float = 2.5
