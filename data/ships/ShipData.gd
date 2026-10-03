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

## Top speed with the throttle all the way up, in meters per second.
## (Multiply by 3.6 for km/h: 55 m/s is about 200 km/h.)
@export_range(5.0, 300.0, 1.0, "suffix:m/s") var max_speed: float = 55.0

## How quickly it speeds up, in m/s gained every second. Heavy rigs are low.
@export_range(0.5, 100.0, 0.5, "suffix:m/s²") var acceleration: float = 6.0

## How quickly it slows down when you pull the throttle back.
@export_range(0.5, 100.0, 0.5, "suffix:m/s²") var braking: float = 10.0


@export_group("Handling")

## The fastest it can turn left or right, in degrees per second.
@export_range(5.0, 180.0, 1.0, "suffix:°/s") var turn_rate: float = 38.0

## The fastest it can point its nose up or down, in degrees per second.
@export_range(5.0, 180.0, 1.0, "suffix:°/s") var pitch_rate: float = 30.0

## How quickly turning starts and stops. Low = a heavy rig that takes a
## moment to swing around. High = a nimble ship that turns on a dime.
@export_range(0.5, 20.0, 0.1) var turn_response: float = 2.2

## How far the ship leans into a full turn, in degrees. Purely visual.
@export_range(0.0, 80.0, 1.0, "suffix:°") var max_bank: float = 28.0


@export_group("Boost")

## Extra top speed while boosting (0.6 = 60% faster than normal top speed).
@export_range(0.0, 3.0, 0.05) var boost_speed_bonus: float = 0.6

## How hard the boost shoves you forward, in m/s gained every second.
@export_range(1.0, 200.0, 1.0, "suffix:m/s²") var boost_acceleration: float = 22.0

## How many seconds a full boost tank lasts.
@export_range(0.5, 20.0, 0.25, "suffix:s") var boost_duration: float = 3.0

## How many seconds an empty boost tank takes to refill.
@export_range(0.5, 60.0, 0.5, "suffix:s") var boost_recharge_time: float = 7.0


@export_group("Looks and sound")

## The color of the glowing trail behind the engines.
@export var trail_color: Color = Color(1.0, 0.55, 0.3)

## The engine's voice: below 1 = deeper and bigger, above 1 = higher and
## smaller.
@export_range(0.3, 3.0, 0.05) var engine_pitch: float = 0.9
