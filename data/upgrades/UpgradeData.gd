class_name UpgradeData
extends Resource
## One upgrade for the rig, bought from a mechanic. Each upgrade gets its own
## .tres file in this folder. Bought upgrades multiply the ship's numbers
## (from res://data/ships/), so they're FELT, not just shown.


## A short code name, used in saves. Keep it unique.
@export var id: String = "upgrade"
## The name on the shop list.
@export var display_name: String = "Upgrade"
## A line about it for the shop.
@export_multiline var description: String = ""
@export_range(0, 1000000, 10) var price: int = 500
## Only buyable after this upgrade (empty = no requirement).
@export var requires_upgrade: String = ""
## Only fits a rig of at least this level (rigs level up from deliveries;
## see Economy.gd). 1 = any rig.
@export_range(1, 10, 1) var min_level: int = 1
## Which shelf at Dusty's it's on: engine and handling, hauling (the
## cargo and the hold), navigation (radar, docking), or the cab (fun stuff).
@export_enum("engine", "hauling", "navigation", "cab") var category: String = "engine"

@export_group("What it changes (1 = no change)")
## Top speed of the main engines.
@export_range(0.5, 3.0, 0.01) var max_speed: float = 1.0
## How hard the engines push (speeding up).
@export_range(0.5, 3.0, 0.01) var acceleration: float = 1.0
## How fast it turns.
@export_range(0.5, 3.0, 0.01) var turn_rate: float = 1.0
## How big the main fuel tank is.
@export_range(0.5, 3.0, 0.01) var fuel_tank: float = 1.0
## How much boost the boost tank holds.
@export_range(0.5, 3.0, 0.01) var boost_tank: float = 1.0
## How well it holds a line in turns (less sliding).
@export_range(0.5, 3.0, 0.01) var grip: float = 1.0
## Fuel burned, compared with usual (0.85 = 15% less: the tank lasts longer).
@export_range(0.3, 1.0, 0.01) var fuel_burn: float = 1.0
## How much of a knock reaches the cargo (0.6 = 40% gentler).
@export_range(0.1, 1.0, 0.05) var cargo_care: float = 1.0
## How much of a knock dents the hull (0.6 = 40% less).
@export_range(0.1, 1.0, 0.05) var hull_care: float = 1.0
## Pay per delivery, compared with usual (1.1 = +10%: room for more cargo).
@export_range(1.0, 2.0, 0.01) var pay: float = 1.0
## How far the radar sees, compared with usual.
@export_range(1.0, 3.0, 0.05) var radar_reach: float = 1.0
## A part you can see on the outside of the rig (see
## scenes/flight/RigAddOns.gd): bumpers, radar_dish, horns, light_bar,
## racks, solar_fins or stacks; "none" = nothing to see.
@export_enum("none", "bumpers", "radar_dish", "horns", "light_bar", "racks", "solar_fins", "stacks") var add_on: String = "none"
## Adds a docking computer.
@export var docking_computer: bool = false
## Adds an air horn.
@export var air_horn: bool = false


## Applies this upgrade to a copy of a ship's numbers.
func apply_to(ship: ShipData) -> void:
	ship.max_speed *= max_speed
	ship.acceleration *= acceleration
	ship.retro_thrust *= acceleration
	ship.turn_rate *= turn_rate
	ship.fuel_tank_seconds *= fuel_tank
	ship.boost_fuel_seconds *= boost_tank
	ship.grip *= grip
	ship.fuel_tank_seconds /= fuel_burn
	ship.cargo_care *= cargo_care
	ship.hull_care *= hull_care
	ship.pay_bonus *= pay
	ship.radar_reach *= radar_reach
	ship.docking_computer = ship.docking_computer or docking_computer
	ship.air_horn = ship.air_horn or air_horn
