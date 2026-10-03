class_name ShipData
extends Resource
## One ship's personality: how fast it goes, how heavy it feels, how it turns.
## Every ship gets its own .tres file in this folder (e.g. starter_rig.tres).
##
## HOW TO TWEAK: double-click the ship's .tres file and use the Inspector.
## Hover over a value to see what it does.
##
## (Feel numbers shared by ALL ships, like steering smoothness or camera
## distance, live in res://data/tuning.tres instead.)


## The ship's name, shown in menus later on.
@export var display_name: String = "Unnamed Rig"


@export_group("Speed")

## Top speed of the main engines, in meters per second. Only boost goes
## faster. (Multiply by 3.6 for km/h: 55 m/s is about 200 km/h.)
@export_range(5.0, 300.0, 1.0, "suffix:m/s") var max_speed: float = 55.0

## Forward thrust: how much speed it gains every second while burning
## forward. Heavy rigs are low.
@export_range(0.5, 100.0, 0.5, "suffix:m/s²") var acceleration: float = 9.0

## Reverse thrust: how much speed it sheds every second while burning
## backward. This is the ship's brake. Lower = easier to overshoot.
@export_range(0.5, 100.0, 0.5, "suffix:m/s²") var retro_thrust: float = 7.0


@export_group("Handling")

## The fastest it can turn left or right, in degrees per second.
@export_range(5.0, 180.0, 1.0, "suffix:°/s") var turn_rate: float = 38.0

## The fastest it can point its nose up or down, in degrees per second.
@export_range(5.0, 180.0, 1.0, "suffix:°/s") var pitch_rate: float = 30.0

## How quickly turning starts and stops. Low = a heavy rig that takes a
## moment to swing around. High = a nimble ship that turns on a dime.
@export_range(0.5, 20.0, 0.1) var turn_response: float = 2.2

## How quickly the ship's direction of travel swings around to follow its
## nose after a turn. Low = slidey, wide arcs and easy overshooting.
## High = on rails. (Boosting loosens it even more; see tuning.tres.)
@export_range(0.1, 10.0, 0.05) var grip: float = 1.6

## How far the ship leans into a full turn, in degrees. Purely visual.
@export_range(0.0, 80.0, 1.0, "suffix:°") var max_bank: float = 28.0


@export_group("Boost")

## Extra top speed while boosting (2.0 = three times normal top speed).
@export_range(0.0, 5.0, 0.05) var boost_speed_bonus: float = 2.0

## How hard the boost shoves you forward, in m/s gained every second.
@export_range(1.0, 300.0, 1.0, "suffix:m/s²") var boost_acceleration: float = 70.0

## The boost fuel tank: how many seconds of boosting a full tank holds. Boost
## fuel doesn't refill by itself; you top it up at a station. (Buying it
## arrives in M2.)
@export_range(1.0, 120.0, 0.5, "suffix:s") var boost_fuel_seconds: float = 15.0


@export_group("Looks and sound")

## The color of the glowing trail behind the engines.
@export var trail_color: Color = Color(1.0, 0.55, 0.3)

## The engine's voice: below 1 = deeper and bigger, above 1 = higher and
## smaller.
@export_range(0.3, 3.0, 0.05) var engine_pitch: float = 0.9
