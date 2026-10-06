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
## (At 6, steering is about 2/3 of the way there after 0.17 seconds.)
@export_range(1.0, 30.0, 0.5) var steer_response: float = 6.0

## (The mouse no longer steers: it looks around. These two only drive the
## mouse gauge on the title screen's input check.)
## How far a mouse movement pushes the input check's mouse gauge.
@export_range(0.001, 0.05, 0.001) var mouse_sensitivity: float = 0.008

## How quickly the mouse's virtual stick drifts back to center after you stop
## moving the mouse. 0 = it stays wherever you leave it.
@export_range(0.0, 10.0, 0.1) var mouse_recenter_speed: float = 2.5


@export_group("Throttle")

## The throttle is a lever you set, like a real truck's cruise control or a
## plane's throttle: W / right trigger pushes it up, S / left trigger pulls
## it down, and the rig speeds up or slows down to match, then holds that
## speed. How fast the lever moves while you hold the key (per second;
## 0.45 = about 2 seconds from idle to full).
@export_range(0.05, 3.0, 0.05) var throttle_lever_speed: float = 0.45

## How far below its matching speed the rig has to be before the engines
## push at full power (in m/s). Smaller = snappier speed holding; bigger =
## gentler, lazier speed changes.
@export_range(0.5, 30.0, 0.5, "suffix:m/s") var throttle_band: float = 5.0

## How far the lever goes below zero, into reverse (as a fraction of the
## lever's travel). Pulling it all the way back = backing up slowly.
@export_range(0.0, 1.0, 0.05) var reverse_lever: float = 0.25


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

## How long you hold boost before it lights (it spools up first, so it's a
## decision, not a tap). Let go early and nothing happens.
@export_range(0.0, 3.0, 0.05, "suffix:s") var boost_spool_seconds: float = 0.8

## Once lit, boost keeps burning at least this long, even if you let go
## (it's hard to turn off).
@export_range(0.0, 10.0, 0.25, "suffix:s") var boost_min_burn_seconds: float = 3.0

## On: boost only lights with the throttle lever at full.
@export var boost_needs_full_throttle: bool = true

## Grip multiplier while boosting (0.3 = 30% of the ship's normal grip).
## Lower = boost feels wilder and the rig slides more in turns.
@export_range(0.05, 1.0, 0.05) var boost_grip: float = 0.22

## SPEED WOBBLES. Boosting is like a car going too fast on the highway:
## the rig shakes harder and harder the longer you hold boost, and as it
## shakes it slowly drifts off course, so you keep correcting.
##
## The drift: this many degrees per second off course at full shakes (a
## slow, steady pull one way, not a sudden swerve).
@export_range(0.0, 30.0, 0.5, "suffix:°/s") var boost_wander_degrees: float = 1.0

## Extra drift when the rig is shaky from jerky steering under boost.
@export_range(0.0, 60.0, 0.5, "suffix:°/s") var boost_wobble_degrees: float = 1.5

## How many seconds of boosting until the shakes are at their worst.
@export_range(0.5, 20.0, 0.5, "suffix:s") var boost_wobble_build_seconds: float = 3.5

## The shimmy: how far the nose snaps side to side at the worst (degrees),
## how fast (shakes per second), and how far the hull rocks (degrees).
@export_range(0.0, 10.0, 0.1, "suffix:°") var boost_shimmy_degrees: float = 0.8
@export_range(1.0, 12.0, 0.5, "suffix:Hz") var boost_shimmy_hz: float = 5.5
@export_range(0.0, 30.0, 0.5, "suffix:°") var boost_shimmy_roll_degrees: float = 4.5

## Extra screen shake at the worst of the wobbles, on top of the boost rumble.
@export_range(0.0, 1.0, 0.05) var boost_shimmy_shake: float = 0.15

## Steering is this much twitchier under boost (1 = normal). Easy to
## over-correct.
@export_range(1.0, 3.0, 0.05) var boost_steer_gain: float = 1.7

## How much jerky steering under boost shakes the rig. Higher = you need
## smoother hands.
@export_range(0.0, 2.0, 0.01) var boost_jerk_shake: float = 0.16

## How quickly the shakes settle when you hold steady.
@export_range(0.05, 5.0, 0.05) var boost_steady_recovery: float = 0.6

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


@export_group("Overdrive")
## OVERDRIVE: keep holding boost past boost's top speed (about 800 km/h in
## the Thumper) and the rig keeps climbing, slowly, with no ceiling. The
## faster you go, the worse the wobbles and the harder on the cargo. Past
## overdrive_strain_kmh the HULL STRAIN builds (warnings, alarms, worried
## calls), and at full strain the rig can't take its own speed: it goes out
## of control and blows up. Let go of boost and it all calms down.
## How fast speed keeps climbing past boost's top speed (m/s each second;
## 8 = about 29 km/h a second).
@export_range(0.0, 100.0, 0.5, "suffix:m/s²") var overdrive_acceleration: float = 8.0
## The wobbles and drift get one notch worse for every this many km/h past
## boost's top speed.
@export_range(100.0, 5000.0, 50.0, "suffix:km/h") var overdrive_shake_kmh: float = 800.0
## How hard the nose drifts per notch (degrees a second).
@export_range(0.0, 20.0, 0.25, "suffix:°/s") var overdrive_wander_degrees: float = 2.0
## Cargo damage from the vibration grows by this much per notch (1 = twice
## as bad one notch in, three times two notches in...).
@export_range(0.0, 5.0, 0.05) var overdrive_cargo: float = 1.0
## Hull strain starts building above this speed...
@export_range(500.0, 10000.0, 50.0, "suffix:km/h") var overdrive_strain_kmh: float = 1800.0
## ...faster the further past it you are: at this many km/h past it, the
## strain builds at overdrive_strain_rate (twice as far = four times as fast).
@export_range(50.0, 5000.0, 50.0, "suffix:km/h") var overdrive_strain_span_kmh: float = 700.0
## Strain gained per second at overdrive_strain_kmh + span (0.05 = about 20
## seconds at 2,500 km/h until she blows).
@export_range(0.0, 1.0, 0.005) var overdrive_strain_rate: float = 0.05
## Strain that fades away per second once you're back under the strain speed.
@export_range(0.0, 1.0, 0.01) var overdrive_strain_recovery: float = 0.1
## A hard speed limit, only used when crashes_enabled is off (so nothing
## blows up and the number doesn't run away forever).
@export_range(1000.0, 50000.0, 100.0, "suffix:km/h") var overdrive_max_kmh: float = 5000.0

@export_group("Load weight")
## How heavy loads feel ("momentum and mass"). A job's weight (tons) against
## the rig's load_rating gives the LOAD SHARE: 0 = empty, 1 = a full load
## for this rig, more = overloaded (capped at max_load_share). Each number
## below is how much a FULL load changes something: 0.8 means a full load
## makes it 1 / (1 + 0.8) = about 55% as strong. The rig still always goes
## where its nose points (no drifting); it's just slower to answer.
@export_range(0.5, 3.0, 0.05) var max_load_share: float = 1.5
## Speeding up: heavy loads take longer to get going.
@export_range(0.0, 3.0, 0.05) var load_acceleration_drag: float = 0.8
## Braking (retro thrust): heavy loads take longer to stop. Plan ahead!
@export_range(0.0, 3.0, 0.05) var load_braking_drag: float = 0.9
## Turning: heavy loads turn slower and take longer to start and stop turning.
@export_range(0.0, 3.0, 0.05) var load_turn_drag: float = 0.45
## Grip: heavy loads swing wide in turns (the motion catches up with the
## nose more slowly).
@export_range(0.0, 3.0, 0.05) var load_grip_drag: float = 0.6
## Coasting: momentum carries a heavy rig further when you ease off.
@export_range(0.0, 5.0, 0.05) var load_coast_carry: float = 1.0
## Fuel: hauling weight burns a little more (0.25 = 25% more at a full load).
@export_range(0.0, 2.0, 0.05) var load_fuel_burn: float = 0.25
## The rig rocks a little after you start or stop a turn, more with a heavy
## load (just looks): how hard, how fast (rocks per second) and how quickly
## it settles (0 = rocks forever, 1 = no rocking).
@export_range(0.0, 3.0, 0.05) var load_sway: float = 0.8
@export_range(0.1, 3.0, 0.05, "suffix:Hz") var load_sway_hz: float = 0.6
@export_range(0.0, 1.0, 0.05) var load_sway_settle: float = 0.25

@export_group("Fuel")

## Flying faster burns more fuel: at top speed, thrusting burns this much
## extra on top of the normal burn (1 = twice as much). Coasting is free.
## (How big each ship's tank is lives in its own file in res://data/ships/.)
@export_range(0.0, 4.0, 0.05) var fuel_speed_burn: float = 1.0

## Holding top speed on the limiter only sips fuel: this much of the
## normal burn (0.2 = a fifth). It's speeding up that drinks fuel.
@export_range(0.0, 1.0, 0.01) var cruise_burn: float = 0.18

## With an empty tank, the engines run "on fumes" at this fraction of their
## thrust, so you can always limp to a pump. Nobody gets stranded.
@export_range(0.05, 1.0, 0.05) var empty_tank_thrust: float = 0.25

## The LOW FUEL light comes on below this much fuel (0.2 = 20%).
@export_range(0.0, 0.5, 0.01) var low_fuel_warning: float = 0.2

## The fuel-economy arrow turns yellow, then red, when you burn fuel harder
## than these (1 = flooring it at top speed). Coasting is always green.
@export_range(0.0, 1.0, 0.05) var economy_yellow: float = 0.35
@export_range(0.0, 1.0, 0.05) var economy_red: float = 0.7


@export_group("Prices")

## What filling the main fuel tank from empty costs. A half-empty tank
## costs half.
@export_range(0, 10000, 5) var fuel_tank_price: int = 90

## What filling the boost tank from empty costs.
@export_range(0, 10000, 5) var boost_tank_price: int = 120

## What patching a fully battered hull costs at a garage.
@export_range(0, 10000, 5) var hull_repair_price: int = 220


@export_group("Time and bills")

## The calendar (365 days, 12 months: see res://data/calendar.tres) and the
## clock run while you play. Flying, time goes fast: this many in-game
## minutes pass per real second (4 = an hour every 15 seconds, so a
## 10-minute haul is about a day and two-thirds on the road).
@export_range(0.0, 60.0, 0.1, "suffix:min/s") var flight_minutes_per_second: float = 4.0
## Walking around while parked, time goes gently: this many in-game minutes
## per real second (1 = an hour every real minute).
@export_range(0.0, 60.0, 0.1, "suffix:min/s") var aboard_minutes_per_second: float = 1.0
## Napping in the bunk with no course set: this many hours pass.
@export_range(0.0, 24.0, 0.5, "suffix:h") var nap_hours: float = 4.0
## Sleeping in your bed while parked, you wake up at this hour (0 to 23).
@export_range(0, 23, 1) var wake_up_hour: int = 7
## A new game starts at this hour on day 1.
@export_range(0, 23, 1) var start_hour: int = 8

## The weekly bills, paid every 7 days on the calendar: OrbitalEx's berth
## and dispatch fee (the company keeps your rig on its books and feeds you
## jobs)...
@export_range(0, 100000, 10) var weekly_dispatch_fee: int = 1500
## ...and insurance, if you've signed up at Dusty's.
@export_range(0, 100000, 10) var weekly_insurance: int = 250
## With insurance, repairs cost this much of the usual price (0.5 = half).
@export_range(0.0, 1.0, 0.05) var insured_repair_share: float = 0.5
## Bills you can't pay go on a tab, paid off from your next delivery. No
## interest, no penalty: it's a cozy galaxy.


@export_group("Rig levels")

## Every rig earns experience from its deliveries: this many points per
## credit the delivery paid (0.05 = 60 XP for a 1,200 credit job), plus a
## few just for showing up.
@export_range(0.0, 1.0, 0.005) var xp_per_credit: float = 0.05
@export_range(0, 1000, 1) var xp_per_delivery: int = 10
## The XP a rig needs to reach each level (level 1 is 0; ten levels).
@export var level_xp := PackedInt32Array([0, 100, 250, 450, 700, 1000, 1400, 1900, 2500, 3200])
## What each level above 1 adds to the rig (0.02 = +2% per level), so
## upgrades and levels are felt: top speed, push, turning, grip, fuel tank.
@export_range(0.0, 0.2, 0.005) var level_speed: float = 0.02
@export_range(0.0, 0.2, 0.005) var level_acceleration: float = 0.03
@export_range(0.0, 0.2, 0.005) var level_turn: float = 0.025
@export_range(0.0, 0.2, 0.005) var level_grip: float = 0.02
@export_range(0.0, 0.2, 0.005) var level_fuel: float = 0.04

## The Lucky Molar (the slot machine at The High Roller): what a pull costs,
## and what it pays for two of a kind, three of a kind, and three SEVENs.
## With five symbols, these numbers give back about 88% of what goes in
## over time (like a real casino, the house wins a little).
@export_range(0, 1000, 1) var slots_price: int = 10
@export_range(0, 10000, 1) var slots_pair_pays: int = 8
@export_range(0, 10000, 1) var slots_three_pays: int = 80
@export_range(0, 100000, 1) var slots_jackpot_pays: int = 300


@export_group("On foot")

## How fast the bunny walks around the base.
@export_range(0.5, 8.0, 0.1, "suffix:m/s") var walk_speed: float = 2.6

## Her running speed (hold Shift / X), in meters per second.
@export_range(0.5, 12.0, 0.1, "suffix:m/s") var run_speed: float = 5.6

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
@export_range(0.25, 1.0, 0.05) var prerender_scale: float = 0.6


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

## Cargo condition lost by the gentlest bonk and by the biggest one
## (1 = all of it). Fragile jobs pay a bonus that shrinks with this.
@export_range(0.0, 0.5, 0.005) var cargo_damage_min: float = 0.01
@export_range(0.0, 0.5, 0.005) var cargo_damage_max: float = 0.08

## Rough driving shakes the cargo. Up to this much g-force (sideways,
## braking, speeding up, in m/s²) is fine; above it the cargo slowly gets
## damaged. Normal thrust is about 9; a hard turn at top speed is about 30.
@export_range(5.0, 200.0, 1.0, "suffix:m/s²") var cargo_comfy_accel: float = 26.0

## How fast cargo gets damaged by rough driving: the share of the cargo lost
## per second when the g-force is double the comfy limit.
@export_range(0.0, 0.2, 0.001) var cargo_rough_rate: float = 0.02

## How fast cargo gets damaged by the vibration of boosting flat out: the
## share lost per second at full boost speed. Boosting is fast but rough.
@export_range(0.0, 0.02, 0.0001) var cargo_boost_rate: float = 0.0015

## The engines start trailing smoke when the hull drops below this (1 = 100%).
@export_range(0.0, 1.0, 0.05) var smoke_below_hull: float = 0.6


@export_group("Chase camera")

## How far behind the ship the camera hangs.
@export_range(5.0, 120.0, 0.5, "suffix:m") var chase_distance: float = 44.0

## How far above the ship the camera hangs.
@export_range(0.0, 40.0, 0.25, "suffix:m") var chase_height: float = 12.0

## Mouse wheel zoom while flying: how close (0.4 = 40% of the usual
## distance) and how far (2.5 = two and a half times) the camera can go,
## how much one click of the wheel moves it, and how quickly it glides there.
@export_range(0.2, 1.0, 0.05) var chase_zoom_min: float = 0.4
@export_range(1.0, 5.0, 0.1) var chase_zoom_max: float = 2.5
@export_range(1.01, 1.5, 0.01) var chase_zoom_step: float = 1.12
@export_range(1.0, 20.0, 0.5) var chase_zoom_response: float = 8.0

## How far ahead of the ship the camera looks. Bigger = the ship sits lower on
## screen and you see more of the road ahead.
@export_range(0.0, 150.0, 1.0, "suffix:m") var chase_look_ahead: float = 60.0

## How quickly the camera swings back around behind the ship after a turn.
## Lower = a lazier camera, so you see the rig lead into its turns.
@export_range(0.5, 20.0, 0.25) var chase_turn_follow: float = 2.2

## How much farther back the camera drifts while boosting.
@export_range(0.0, 40.0, 0.25, "suffix:m") var chase_boost_pullback: float = 18.0

## How quickly that boost pull-back eases in and out.
@export_range(0.5, 10.0, 0.25) var chase_pullback_response: float = 2.0
## LOOKING AROUND: the mouse (or the right stick) swings the camera around
## the rig in any direction, the rig staying in the middle; hold the right
## mouse button and drag to pan. How far one pixel of mouse turns it
## (degrees), and how fast the right stick turns it (degrees a second).
@export_range(0.02, 1.0, 0.01, "suffix:°/px") var orbit_mouse_degrees: float = 0.2
@export_range(10.0, 360.0, 5.0, "suffix:°/s") var orbit_stick_degrees: float = 140.0
## How far up or down the camera can swing (degrees).
@export_range(10.0, 89.0, 1.0, "suffix:°") var orbit_pitch_limit: float = 80.0
## After this many seconds of not looking around, the camera eases back to
## its spot behind the rig (0 = it stays where you left it; middle-click
## always snaps it back).
@export_range(0.0, 30.0, 0.5, "suffix:s") var orbit_return_seconds: float = 4.0
## How quickly it eases back.
@export_range(0.2, 10.0, 0.1) var orbit_return_speed: float = 1.5
## Panning: meters per pixel of right-drag, and how far it can pan.
@export_range(0.01, 1.0, 0.01, "suffix:m/px") var orbit_pan_meters: float = 0.08
@export_range(1.0, 100.0, 1.0, "suffix:m") var orbit_pan_max: float = 30.0

## Only used if the player switches on "camera roll": how much of the ship's
## lean the camera copies (1 = all of it).
@export_range(0.0, 1.0, 0.05) var camera_roll_amount: float = 0.5


@export_group("Cinematic camera")

## On autopilot, V / R3 hands the view to a film director: it picks shots by
## itself (orbits, tracking shots, fly-bys...). Shortest a shot lasts.
@export_range(2.0, 30.0, 0.5, "suffix:s") var cinema_shot_min: float = 7.0

## Longest a director's shot lasts before it cuts to another.
@export_range(2.0, 40.0, 0.5, "suffix:s") var cinema_shot_max: float = 10.0

## How fast the director's orbit shot circles the rig.
@export_range(0.0, 60.0, 1.0, "suffix:deg/s") var cinema_orbit_speed: float = 9.0

## Free camera: how fast the stick (or keys) swings the camera around the rig.
@export_range(10.0, 360.0, 5.0, "suffix:deg/s") var cinema_free_turn: float = 90.0

## Free camera: how far moving the mouse swings it.
@export_range(0.01, 1.0, 0.01) var cinema_mouse_turn: float = 0.25

## Free camera: how fast holding the throttle keys / triggers zooms.
@export_range(0.1, 5.0, 0.1) var cinema_zoom_speed: float = 1.2

## Free camera: closest and farthest it can sit from the rig.
@export_range(4.0, 100.0, 1.0, "suffix:m") var cinema_min_distance: float = 22.0
@export_range(20.0, 600.0, 5.0, "suffix:m") var cinema_max_distance: float = 220.0

## How tall the black film bars at the top and bottom are (share of the screen).
@export_range(0.0, 0.25, 0.01) var cinema_letterbox: float = 0.09


@export_group("Field of view")

## The normal field of view, in degrees. Bigger = a wider, more fish-eye view.
@export_range(40.0, 110.0, 1.0, "suffix:°") var base_fov: float = 70.0

## How much wider the view gets at top speed. Subtle is good.
@export_range(0.0, 30.0, 0.5, "suffix:°") var speed_fov_bonus: float = 10.0

## Extra widening on top of that while going faster than top speed (boost).
@export_range(0.0, 30.0, 0.5, "suffix:°") var boost_fov_bonus: float = 26.0

## The view only starts widening above this fraction of top speed
## (0.3 = 30% of top speed).
@export_range(0.0, 0.95, 0.05) var speed_fov_threshold: float = 0.3

## How smoothly the view widens and narrows.
@export_range(0.5, 20.0, 0.25) var fov_response: float = 4.0


@export_group("Crashes")

## Catastrophic crashes (asked for in round 12): hit something hard enough,
## or wear the hull down to nothing, and the rig spins out of control and
## blows up. Then it's straight back to your last save, nothing lost.
## Off = every hit is just a bonk, like before.
@export var crashes_enabled: bool = true
## Hitting something at this speed (or faster) is a crash, not a bonk. The
## starter rig cruises at 55 m/s, so in practice this means boosting into
## things (or a head-on with fast traffic). 110 m/s is about 400 km/h.
@export_range(10.0, 500.0, 1.0, "suffix:m/s") var crash_speed: float = 110.0
## Also crash when bonks have worn the hull down to nothing.
@export var crash_on_empty_hull: bool = true
## How long the rig tumbles out of control before it blows up.
@export_range(0.5, 10.0, 0.1, "suffix:s") var crash_spin_seconds: float = 2.5
## How fast it tumbles, in turns per second... roughly (radians per second).
@export_range(0.0, 30.0, 0.5, "suffix:rad/s") var crash_spin_speed: float = 7.0

## How hard a crash knocks the rig away from what it hit (1 = bounces off
## as fast as it hit; 0 = just slides along it).
@export_range(0.0, 2.0, 0.05) var crash_bounce: float = 0.75


@export_group("Screen shake")

## The biggest camera jolt, in meters, at full shake. Players can switch shake
## off in the pause menu.
@export_range(0.0, 3.0, 0.05, "suffix:m") var shake_max_offset: float = 0.6

## The biggest camera tilt at full shake, in degrees.
@export_range(0.0, 10.0, 0.1, "suffix:°") var shake_max_tilt: float = 1.5

## How quickly shake dies away (shake "trauma" lost per second).
@export_range(0.1, 5.0, 0.05) var shake_decay: float = 1.4

## How hard the boost kicks the camera when it fires (0 to 1).
@export_range(0.0, 1.0, 0.05) var boost_kick_shake: float = 0.85

## Boost jolts: every so often while boosting, the engines cough and kick
## the rig sideways (a random time between these, in seconds), this hard
## (m/s, spread over a third of a second), with this much camera jolt.
## Push 0 = no jolts.
@export var boost_jolt_interval := Vector2(0.7, 2.2)
@export_range(0.0, 20.0, 0.25, "suffix:m/s") var boost_jolt_push: float = 0.75
@export_range(0.0, 1.0, 0.05) var boost_jolt_shake: float = 0.3

## A rumble while boosting, as shake held at this level (0 to 1).
@export_range(0.0, 1.0, 0.05) var boost_rumble_shake: float = 0.38

## A faint road-feel vibration that grows with speed (at top cruise speed),
## so going fast feels like going fast. 0 = none.
@export_range(0.0, 0.5, 0.01) var cruise_rumble_shake: float = 0.07


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
@export_range(100, 6000, 50) var dust_count: int = 1300

## The size of the invisible box of dust that travels with the camera.
## A smaller box with the same count = denser dust.
@export_range(20.0, 200.0, 1.0, "suffix:m") var dust_box_size: float = 80.0

## How long the dust streaks are: your speed times this many seconds.
## 0 = little dots that never stretch.
@export_range(0.0, 0.2, 0.005, "suffix:s") var dust_streak_seconds: float = 0.045

## How thick each speck of dust is.
@export_range(0.01, 0.5, 0.01, "suffix:m") var dust_size: float = 0.045

## How brightly the dust glows.
@export_range(0.0, 3.0, 0.05) var dust_brightness: float = 0.7


@export_group("Boost effects")

## How strong the speed lines are while boosting. 0 = no speed lines.
@export_range(0.0, 2.0, 0.05) var speed_lines_strength: float = 1.3

## How quickly the speed lines fade in and out.
@export_range(0.5, 20.0, 0.5) var speed_lines_response: float = 6.0


@export_group("Testing")
## The debug menu (F10): jump a few minutes out from any station, skip the
## opening, free credits. Turn it off for a release build.
@export var debug_menu: bool = true

@export_group("HUD")

## How chunky the HUD's pixels are: it's drawn as if the screen had this
## many rows of pixels, then blown up with crisp square pixels. Fewer rows =
## bigger, chunkier HUD. (It always uses whole-pixel steps, so it stays
## crisp: at 1080p, 360 rows means each HUD pixel is 3x3 screen pixels.)
@export_range(180.0, 720.0, 10.0) var hud_rows: float = 360.0

## How many times a second the HUD redraws. Old games often ran their HUD
## slower than the screen, which makes it tick and jitter. 60 = smooth.
@export_range(5.0, 60.0, 1.0, "suffix:fps") var hud_frame_rate: float = 30.0

## How many times a second the numbers (speed, distance, pay...) update.
## Low = they tick over in little jumps, like an old digital display.
@export_range(1.0, 30.0, 0.5, "suffix:/s") var hud_number_rate: float = 8.0

## Pop-up panels (calls, rush timer, cargo...) slide in over this many
## steps, a few frames at a time, instead of smoothly.
@export_range(1, 12, 1) var hud_pop_steps: int = 4

## Seconds between those steps.
@export_range(0.01, 0.2, 0.01, "suffix:s") var hud_pop_step_seconds: float = 0.05

## How far the radar globe sees. Ships and rocks beyond this don't show.
@export_range(200.0, 6000.0, 50.0, "suffix:m") var radar_range: float = 1500.0

## The PROXIMITY light comes on when a rock or ship is this close (to its
## surface), and blinks faster the closer it gets.
@export_range(10.0, 600.0, 5.0, "suffix:m") var proximity_range: float = 150.0

## Passing ships closer than this get a little ID label.
@export_range(50.0, 3000.0, 10.0, "suffix:m") var target_label_range: float = 800.0
## Stations and other big buildings get the green ID label (their name)
## from this far away, when no ship is close enough to label.
@export_range(500.0, 20000.0, 100.0, "suffix:m") var station_label_range: float = 6000.0

## Docking brackets appear around the bay when it's this close.
@export_range(100.0, 5000.0, 50.0, "suffix:m") var docking_bracket_range: float = 1500.0


@export_group("Autopilot")

## The cruise autopilot forgives small inputs: steering up to this much
## (0 to 1, how far the stick is pushed) just nudges the rig, and the
## autopilot steers back on course by itself.
@export_range(0.0, 1.0, 0.05) var autopilot_tolerance: float = 0.55
## How much of your small nudges the rig actually follows while the
## autopilot drives (1 = all of it, 0 = none).
@export_range(0.0, 1.0, 0.05) var autopilot_nudge_share: float = 0.6
## To take over, push harder than the tolerance (or use the throttle) for
## this long. A full push takes over twice as fast. Boost takes over at
## once. Let go and the "grab" fades away again.
@export_range(0.0, 3.0, 0.05, "suffix:s") var autopilot_grab_seconds: float = 0.6


@export_group("Radio")

## The DJ talks, or a text ad scrolls by, every so often: at least this many
## seconds apart...
@export_range(10.0, 1200.0, 5.0, "suffix:s") var radio_talk_min_seconds: float = 100.0
## ...and at most this many.
@export_range(10.0, 1200.0, 5.0, "suffix:s") var radio_talk_max_seconds: float = 200.0
## Of those breaks, the share that are ads (the rest are the DJ talking).
## 0 = never any ads; 1 = only ads.
@export_range(0.0, 1.0, 0.05) var radio_ad_share: float = 0.4


@export_group("Upgrades")

## The docking computer (an upgrade) takes the wheel this close to your
## destination, in meters (the rocks around stations start about 1.5 to 2.5
## km out, so this is before them).
@export_range(500.0, 20000.0, 100.0, "suffix:m") var docking_computer_range: float = 4000.0
## The air horn (an upgrade): truckers within this many meters may honk back...
@export_range(100.0, 5000.0, 50.0, "suffix:m") var horn_reply_range: float = 1500.0
## ...this often (0 to 1).
@export_range(0.0, 1.0, 0.05) var horn_reply_chance: float = 0.75



@export_group("Route events")

## How often something happens, by ZONE (a random time between the two, in
## seconds of driving). Deep space is quiet on purpose: minutes of nothing
## but the radio. Traffic lanes near stations and gates are busy.
@export var event_gap_deep_space := Vector2(180.0, 300.0)
@export var event_gap_traffic_lanes := Vector2(27.5, 83.0)
@export var event_gap_station_approach := Vector2(20.0, 45.0)
@export var event_gap_orbit := Vector2(90.0, 150.0)
@export var event_gap_weather := Vector2(60.0, 120.0)

## Where the zones are. Traffic lanes: within this distance of a station or
## a border gate. (The design list says about 10 km; our map is small, so
## 10 km would make nearly the whole road a traffic lane.)
@export_range(1000.0, 30000.0, 500.0, "suffix:m") var event_lane_radius: float = 6000.0
## Station approach: the final stretch before a station.
@export_range(500.0, 10000.0, 100.0, "suffix:m") var event_approach_radius: float = 3000.0
## Orbit: within this height above a planet or moon's surface. (Our planets
## are huge and far: the whole road is 29-34 km up, so 30 km means "the
## stretches closest to a planet".)
@export_range(1000.0, 100000.0, 1000.0, "suffix:m") var event_orbit_altitude: float = 30000.0
## Weather events (a hail shower, a dust storm) can also happen out in the
## open, away from a storm, at this share of their usual odds.
@export_range(0.0, 1.0, 0.05) var event_weather_outside: float = 0.5

## How many hauls before the same event can happen again: common ones,
## and uncommon (and rare) ones. Legendary ones happen once per save.
@export_range(0, 50, 1) var event_cooldown_common: int = 3
@export_range(0, 50, 1) var event_cooldown_uncommon: int = 10

## The most 3D sights out there at once.
@export_range(1, 10, 1) var event_max_active: int = 3

## Nothing happens when you're slower than this (parked, docking).
@export_range(0.0, 100.0, 1.0, "suffix:m/s") var event_min_speed: float = 15.0

## Sights are cleaned up once they're this far behind you.
@export_range(1000.0, 20000.0, 100.0, "suffix:m") var event_despawn_distance: float = 7000.0

## No 3D sights within this distance of a station (except the station
## approach's own, which keep well to the side).
@export_range(0.0, 20000.0, 100.0, "suffix:m") var event_keep_clear: float = 4000.0

## Don't repeat any of the last this-many events (or the same kind of 3D
## sight: no jellyfish twice in a row, or even close).
@export_range(0, 8, 1) var event_no_repeat: int = 4

## The chance that an event is a RARE or LEGENDARY one instead (at most
## one per haul). 0.012 = about one every ten long hauls.
@export_range(0.0, 1.0, 0.001) var event_rare_chance: float = 0.012


@export_group("Comms chatter")

## Seconds after takeoff before dispatch first calls.
@export_range(0.0, 30.0, 0.5, "suffix:s") var comm_first_call_seconds: float = 4.0

## When nothing is happening, somebody calls every this-many seconds or so
## (a random time between the two).
@export_range(10.0, 600.0, 5.0, "suffix:s") var comm_idle_min_seconds: float = 50.0
@export_range(10.0, 600.0, 5.0, "suffix:s") var comm_idle_max_seconds: float = 110.0

## The fewest seconds of quiet between two calls.
@export_range(0.0, 60.0, 0.5, "suffix:s") var comm_quiet_seconds: float = 8.0

## How fast a call's words type out, in letters per second.
@export_range(5.0, 120.0, 1.0) var comm_letters_per_second: float = 28.0

## How long a call stays up after its words finish typing.
@export_range(0.5, 10.0, 0.25, "suffix:s") var comm_hold_seconds: float = 3.0

## The chance that somebody teases you about a bonk (0 = never, 1 = always).
@export_range(0.0, 1.0, 0.05) var comm_bonk_chance: float = 0.35


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
@export_range(-40.0, 6.0, 0.5, "suffix:dB") var engine_volume_db: float = -13.0

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
@export_range(120.0, 2160.0, 10.0) var vertex_snap_rows: float = 480.0

## How much textures bend and swim on big polygons close to the camera, the
## PS1's famous "affine" warping. 0 = modern, 1 = full PS1.
@export_range(0.0, 1.0, 0.05) var affine_strength: float = 0.3

## Shades per color channel. The PS1 had 32. Lower = more posterized.
@export_range(4.0, 256.0, 1.0) var color_levels: float = 30.0

## How strong the fine checkered dither pattern is. 0 = off.
@export_range(0.0, 2.0, 0.05) var dither_strength: float = 0.6

## How big the dither dots are: sized as if the screen had this many rows,
## so the pattern looks the same on any screen. Fewer = chunkier dots.
@export_range(120.0, 2160.0, 10.0) var dither_rows: float = 400.0

## Where the solar system's colored distance haze starts, and where it's at
## its thickest. It tints faraway things with the system's haze color (set in
## the system's data file).
@export_range(0.0, 10000.0, 50.0, "suffix:m") var haze_start: float = 1200.0
@export_range(100.0, 20000.0, 50.0, "suffix:m") var haze_end: float = 14000.0

## How thick the haze gets at its thickest (0 = none, 1 = solid color).
@export_range(0.0, 1.0, 0.05) var haze_strength: float = 0.75
