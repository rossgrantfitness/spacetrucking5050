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


## A short code name, used by saves ("lazy_susan").
@export var id: String = "rig"
## The ship's name, shown in menus.
@export var display_name: String = "Unnamed Rig"
## What the dealer says about it.
@export_multiline var description: String = ""


@export_group("For sale")

## What it would cost (there's no rig dealer for now: you only get the Thumper).
@export_range(0, 10000000, 100) var price: int = 0
## Special order: shown at the dealer as something to save up for, but it
## can't be bought yet.
@export var special_order: bool = false
## How much more a delivery pays in this rig, for its bigger hold
## (1.35 = +35% of a job's base pay). Never below 1: small rigs make up
## for it with speed.
@export_range(1.0, 5.0, 0.05) var pay_bonus: float = 1.0


@export_group("Speed")

## Top speed of the main engines, in meters per second. Only boost goes
## faster. (Multiply by 3.6 for km/h: 55 m/s is about 200 km/h.)
@export_range(5.0, 300.0, 1.0, "suffix:m/s") var max_speed: float = 55.0

## Forward thrust: how much speed it gains every second while burning
## forward. Heavy rigs are low.
@export_range(0.5, 100.0, 0.5, "suffix:m/s²") var acceleration: float = 9.0

## Reverse thrusters (S): how much speed they shed every second, or how
## fast they push her backwards from a standstill. Small nose thrusters,
## much weaker than the main engines (a third of `acceleration` on the
## Thumper), so plan your stops: or flip round and burn the main engines.
@export_range(0.5, 100.0, 0.5, "suffix:m/s²") var retro_thrust: float = 3.0


@export_group("Hauling")
## How many tons this rig hauls before a load really weighs on it. A load
## this heavy is a "full" load: noticeably slower to speed up, stop and
## turn. Big haulers shrug off what the little ones feel.
@export_range(1.0, 1e13, 1.0, "suffix:t") var load_rating: float = 1.5e9

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

## The boost fuel tank: how many seconds of boosting a full tank holds
## (6 minutes: more than enough to boost flat out all the way to
## Tidewater, about 4½ minutes since round 12). Boost
## fuel doesn't refill by itself; buy it at a station's pumps.
@export_range(1.0, 900.0, 0.5, "suffix:s") var boost_fuel_seconds: float = 360.0


@export_group("Fuel")

## The main fuel tank: how many seconds of full thrust at low speed a full
## tank holds. Flying fast burns it quicker; coasting burns nothing. (Buying
## fuel arrives with the economy; the truck stop tops you up for now.)
@export_range(10.0, 3600.0, 5.0, "suffix:s") var fuel_tank_seconds: float = 300.0


@export_group("Looks and sound")

## The ship's model. Empty = the starter rig's (ShipVisual.tscn).
@export var visual_scene: PackedScene

## The color of the glowing trail behind the engines.
@export var trail_color: Color = Color(1.0, 0.55, 0.3)

## The engine's voice: below 1 = deeper and bigger, above 1 = higher and
## smaller.
@export_range(0.3, 3.0, 0.05) var engine_pitch: float = 0.9

@export_group("Toughness and gear (upgrades change these)")
## How much of a knock reaches the cargo (0.6 = 40% gentler on it).
@export_range(0.1, 1.0, 0.05) var cargo_care: float = 1.0
## How much of a knock dents the hull (0.6 = 40% less damage).
@export_range(0.1, 1.0, 0.05) var hull_care: float = 1.0
## How far the radar globe sees, compared with usual (tuning: radar_range).
@export_range(0.5, 3.0, 0.05) var radar_reach: float = 1.0
## A docking computer: takes over from farther out, flies you in through
## the rocks and the ring, and plays its waltz.
@export var docking_computer: bool = false
## An air horn (B / left stick click in flight). Truckers honk back.
@export var air_horn: bool = false

@export_group("Inside")
## Inside, every rig has the same rooms (so you never get lost), but each
## has its own color cast over them, so you can tell which rig you're in.
## White = none. Keep it soft: a little goes a long way.
@export var interior_tint: Color = Color.WHITE
