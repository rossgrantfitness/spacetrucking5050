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
## Numbers that belong to ONE ship (its top speed, how heavy it turns...) live
## in that ship's own file in res://data/ships/ instead.


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


@export_group("Flying")

## How fast the throttle lever moves while you hold throttle up or down, in
## full sweeps per second. 0.5 = two seconds from stopped to full throttle.
@export_range(0.1, 3.0, 0.05) var throttle_lever_speed: float = 0.5

## How gently the speed settles onto the throttle setting at the very end.
## Higher = snaps onto the target speed. Lower = creeps the last bit softly.
@export_range(0.2, 5.0, 0.1) var speed_settle: float = 1.2

## The steepest the nose can point up or down, in degrees. Kept below 90 so
## you can never flip upside down and lose the horizon.
@export_range(30.0, 89.0, 1.0, "suffix:°") var max_pitch_degrees: float = 70.0

## How strongly the nose drifts back to level when you let go of up/down.
## 0 = it stays wherever you leave it. Higher = it levels out faster.
@export_range(0.0, 2.0, 0.05) var nose_auto_level: float = 0.35

## How quickly the ship's lean into turns follows your steering. Purely
## visual: the lean never changes where the ship goes.
@export_range(0.5, 15.0, 0.5) var bank_response: float = 3.0

## How far the nose visibly dips or lifts while you pitch. Purely visual.
@export_range(0.0, 20.0, 0.5, "suffix:°") var nose_tilt_degrees: float = 5.0


@export_group("Chase camera")

## How far behind the ship the camera hangs.
@export_range(5.0, 60.0, 0.5, "suffix:m") var chase_distance: float = 30.0

## How far above the ship the camera hangs.
@export_range(0.0, 20.0, 0.25, "suffix:m") var chase_height: float = 8.5

## How far ahead of the ship the camera looks. Bigger = the ship sits lower on
## screen and you see more of the road ahead.
@export_range(0.0, 100.0, 1.0, "suffix:m") var chase_look_ahead: float = 45.0

## How quickly the camera swings back around behind the ship after a turn.
## Lower = a lazier camera, so you see the rig lead into its turns.
@export_range(0.5, 20.0, 0.25) var chase_turn_follow: float = 3.0

## How much farther back the camera drifts while boosting.
@export_range(0.0, 20.0, 0.25, "suffix:m") var chase_boost_pullback: float = 4.0

## How quickly that boost pull-back eases in and out.
@export_range(0.5, 10.0, 0.25) var chase_pullback_response: float = 2.0

## Only used if the player switches on "camera roll": how much of the ship's
## lean the camera copies (1 = all of it).
@export_range(0.0, 1.0, 0.05) var camera_roll_amount: float = 0.5


@export_group("Field of view")

## The normal field of view, in degrees. Bigger = a wider, more fish-eye view.
@export_range(40.0, 110.0, 1.0, "suffix:°") var base_fov: float = 70.0

## How much wider the view gets at top speed. Subtle is good.
@export_range(0.0, 30.0, 0.5, "suffix:°") var speed_fov_bonus: float = 8.0

## The view only starts widening above this fraction of top speed
## (0.7 = 70% of top speed).
@export_range(0.0, 0.95, 0.05) var speed_fov_threshold: float = 0.7

## How smoothly the view widens and narrows.
@export_range(0.5, 20.0, 0.25) var fov_response: float = 4.0


@export_group("Cockpit view")

## How far the cockpit frame sways when you turn, in pixels at a full turn. It
## sells the weight of the rig. 0 = rock solid.
@export_range(0.0, 60.0, 1.0, "suffix:px") var cockpit_sway: float = 18.0

## How quickly the cockpit sway follows your turning.
@export_range(0.5, 20.0, 0.5) var cockpit_sway_response: float = 4.0


@export_group("Space dust")

## How many specks of dust float around you. (Read when a flight starts.)
@export_range(100, 6000, 50) var dust_count: int = 1400

## The size of the invisible box of dust that travels with the camera.
## A smaller box with the same count = denser dust.
@export_range(20.0, 200.0, 1.0, "suffix:m") var dust_box_size: float = 80.0

## How long the dust streaks are: your speed times this many seconds.
## 0 = little dots that never stretch.
@export_range(0.0, 0.2, 0.005, "suffix:s") var dust_streak_seconds: float = 0.02

## How thick each speck of dust is.
@export_range(0.01, 0.5, 0.01, "suffix:m") var dust_size: float = 0.045

## How brightly the dust glows.
@export_range(0.0, 3.0, 0.05) var dust_brightness: float = 0.55


@export_group("Boost effects")

## How strong the speed lines are while boosting. 0 = no speed lines.
@export_range(0.0, 2.0, 0.05) var speed_lines_strength: float = 0.6

## How quickly the speed lines fade in and out.
@export_range(0.5, 20.0, 0.5) var speed_lines_response: float = 6.0


@export_group("Engine trail")

## How long each bit of trail lingers, in seconds. Because the ship keeps
## moving, faster flying automatically leaves a longer trail.
@export_range(0.05, 3.0, 0.05, "suffix:s") var trail_lifetime: float = 0.3

## How wide the trail is where it leaves the engine.
@export_range(0.1, 5.0, 0.05, "suffix:m") var trail_width: float = 0.9

## How bright the trail is at top speed. It fades away as you slow down.
@export_range(0.0, 3.0, 0.05) var trail_brightness: float = 1.0


@export_group("Engine sound")

## Overall engine loudness in decibels. 0 = full, -6 = about half as loud.
@export_range(-40.0, 6.0, 0.5, "suffix:dB") var engine_volume_db: float = -6.0

## Engine pitch when idling (1 = the ship's normal voice).
@export_range(0.2, 2.0, 0.05) var engine_idle_pitch: float = 0.7

## Engine pitch at top speed. Boosting pushes it a little higher still.
@export_range(0.2, 3.0, 0.05) var engine_top_pitch: float = 1.35

## How much the hum wobbles while you turn. 0 = perfectly steady.
@export_range(0.0, 0.2, 0.005) var engine_turn_wobble: float = 0.03

## How much airy "whoosh" is mixed into the hum at speed.
@export_range(0.0, 1.0, 0.05) var engine_whoosh: float = 0.35
