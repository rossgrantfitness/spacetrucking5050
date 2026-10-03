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

## While coasting (no thrust), the fraction of speed lost per second. Space
## is nearly frictionless, so keep this tiny. 0 = coast forever.
@export_range(0.0, 0.5, 0.005) var coast_drag: float = 0.01

## How fast you can fly backwards, as a fraction of top speed.
@export_range(0.0, 1.0, 0.05) var reverse_speed_fraction: float = 0.3

## After a boost, how quickly speed above the ship's top speed bleeds away.
## Lower = you stay rocketing (and harder to handle) for longer.
@export_range(0.05, 5.0, 0.05) var overspeed_drag: float = 0.25

## How much grip you lose for going faster than top speed. Higher = going
## too fast gets slidier and easier to overshoot.
@export_range(0.0, 10.0, 0.1) var overspeed_slip: float = 1.5

## Grip multiplier while boosting (0.3 = 30% of the ship's normal grip).
## Lower = boost feels wilder and the rig slides more in turns.
@export_range(0.05, 1.0, 0.05) var boost_grip: float = 0.3

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


@export_group("On foot")

## How fast the bunny walks around the base.
@export_range(0.5, 8.0, 0.1, "suffix:m/s") var walk_speed: float = 2.6

## How quickly she gets up to walking speed and stops again.
@export_range(1.0, 40.0, 0.5) var walk_acceleration: float = 14.0

## How quickly she turns to face where she's walking.
@export_range(1.0, 30.0, 0.5) var walk_turn_speed: float = 12.0

## When the camera cuts to a new angle, she keeps walking the way you were
## pushing until you let go of the stick or turn it more than this much.
## (So a camera cut never suddenly flips your controls.)
@export_range(10.0, 90.0, 1.0, "suffix:°") var camera_cut_hold_angle: float = 45.0

## The rooms are "pre-rendered": each camera angle is painted once into a
## picture when you enter, and the bunny walks in front of it. This is the
## picture's size compared to your screen. Lower = softer, older-looking
## backgrounds (and faster to paint).
@export_range(0.25, 1.0, 0.05) var prerender_scale: float = 0.75


@export_group("Bonks and damage")

## Bumping into things slower than this is just a nudge: no bonk, no damage.
@export_range(0.0, 20.0, 0.5, "suffix:m/s") var bonk_min_speed: float = 3.0

## Hitting something this fast (straight on) is the biggest possible bonk.
@export_range(5.0, 150.0, 1.0, "suffix:m/s") var bonk_hard_speed: float = 35.0

## Hull lost by the gentlest bonk and by the biggest one (1 = the whole
## hull). Nothing ever explodes: a battered hull just smokes and sparks until
## it's patched up.
@export_range(0.0, 0.5, 0.01) var bonk_damage_min: float = 0.02
@export_range(0.0, 1.0, 0.01) var bonk_damage_max: float = 0.2

## How much screen shake the biggest bonk gives (0 to 1).
@export_range(0.0, 1.0, 0.05) var bonk_max_shake: float = 0.75

## How much the ship bounces off what it hit (0 = it just slides along,
## 1 = a full rubber-ball bounce). A little bounce makes it a cartoon "bonk".
@export_range(0.0, 1.0, 0.05) var bonk_bounce: float = 0.35

## After a bonk, ignore further bumps for this long, so scraping along a rock
## counts as one bonk, not dozens.
@export_range(0.0, 2.0, 0.05, "suffix:s") var bonk_cooldown: float = 0.4

## The engines start trailing smoke when the hull drops below this (1 = 100%).
@export_range(0.0, 1.0, 0.05) var smoke_below_hull: float = 0.6


@export_group("Chase camera")

## How far behind the ship the camera hangs.
@export_range(5.0, 120.0, 0.5, "suffix:m") var chase_distance: float = 44.0

## How far above the ship the camera hangs.
@export_range(0.0, 40.0, 0.25, "suffix:m") var chase_height: float = 12.0

## How far ahead of the ship the camera looks. Bigger = the ship sits lower on
## screen and you see more of the road ahead.
@export_range(0.0, 150.0, 1.0, "suffix:m") var chase_look_ahead: float = 60.0

## How quickly the camera swings back around behind the ship after a turn.
## Lower = a lazier camera, so you see the rig lead into its turns.
@export_range(0.5, 20.0, 0.25) var chase_turn_follow: float = 3.0

## How much farther back the camera drifts while boosting.
@export_range(0.0, 40.0, 0.25, "suffix:m") var chase_boost_pullback: float = 12.0

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

## Extra widening on top of that while going faster than top speed (boost).
@export_range(0.0, 30.0, 0.5, "suffix:°") var boost_fov_bonus: float = 12.0

## The view only starts widening above this fraction of top speed
## (0.7 = 70% of top speed).
@export_range(0.0, 0.95, 0.05) var speed_fov_threshold: float = 0.7

## How smoothly the view widens and narrows.
@export_range(0.5, 20.0, 0.25) var fov_response: float = 4.0


@export_group("Screen shake")

## The biggest camera jolt, in meters, at full shake. Players can switch shake
## off in the pause menu.
@export_range(0.0, 3.0, 0.05, "suffix:m") var shake_max_offset: float = 0.6

## The biggest camera tilt at full shake, in degrees.
@export_range(0.0, 10.0, 0.1, "suffix:°") var shake_max_tilt: float = 1.5

## How quickly shake dies away (shake "trauma" lost per second).
@export_range(0.1, 5.0, 0.05) var shake_decay: float = 1.4

## How hard the boost kicks the camera when it fires (0 to 1).
@export_range(0.0, 1.0, 0.05) var boost_kick_shake: float = 0.55

## A gentle rumble while boosting, as shake held at this level (0 to 1).
@export_range(0.0, 1.0, 0.05) var boost_rumble_shake: float = 0.25


@export_group("Cockpit view")

## How far your head sways in the seat when you turn or pitch, in meters. It
## sells the weight of the rig. 0 = rock solid.
@export_range(0.0, 0.3, 0.005, "suffix:m") var cockpit_head_sway: float = 0.06

## How quickly your head follows the turning.
@export_range(0.5, 20.0, 0.5) var cockpit_sway_response: float = 4.0

## How much the fuzzy dice, air freshener and bobblehead swing around.
## 0 = glued in place, 1 = normal, 2 = very loose.
@export_range(0.0, 3.0, 0.1) var cockpit_toy_swing: float = 1.0


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
@export_range(0.0, 2.0, 0.05) var speed_lines_strength: float = 0.9

## How quickly the speed lines fade in and out.
@export_range(0.5, 20.0, 0.5) var speed_lines_response: float = 6.0


@export_group("Engine trail")

## How long each bit of trail lingers, in seconds. Because the ship keeps
## moving, faster flying automatically leaves a longer trail.
@export_range(0.05, 3.0, 0.05, "suffix:s") var trail_lifetime: float = 0.3

## How wide the trail is where it leaves the engine.
@export_range(0.1, 5.0, 0.05, "suffix:m") var trail_width: float = 2.0

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


@export_group("PS1 look")

## How much models wobble. Model corners snap to an invisible grid this many
## rows tall (the grid is as wide as your screen's shape needs). Fewer rows =
## wobblier: 240 is early-PS1 jelly, 480 is a late-PS1 shimmer, 1000+ is
## nearly still. It doesn't change the screen's resolution.
@export_range(120.0, 2160.0, 10.0) var vertex_snap_rows: float = 360.0

## How much textures bend and swim on big polygons close to the camera, the
## PS1's famous "affine" warping. 0 = modern, 1 = full PS1.
@export_range(0.0, 1.0, 0.05) var affine_strength: float = 0.35

## Shades per color channel. The PS1 had 32. Lower = more posterized.
@export_range(4.0, 256.0, 1.0) var color_levels: float = 32.0

## How strong the fine checkered dither pattern is. 0 = off.
@export_range(0.0, 2.0, 0.05) var dither_strength: float = 0.9

## How big the dither dots are: sized as if the screen had this many rows,
## so the pattern looks the same on any screen. Fewer = chunkier dots.
@export_range(120.0, 2160.0, 10.0) var dither_rows: float = 360.0

## Where the solar system's colored distance haze starts, and where it's at
## its thickest. It tints faraway things with the system's haze color (set in
## the system's data file).
@export_range(0.0, 10000.0, 50.0, "suffix:m") var haze_start: float = 1200.0
@export_range(100.0, 20000.0, 50.0, "suffix:m") var haze_end: float = 10000.0

## How thick the haze gets at its thickest (0 = none, 1 = solid color).
@export_range(0.0, 1.0, 0.05) var haze_strength: float = 0.75
