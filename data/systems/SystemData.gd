class_name SystemData
extends Resource
## One solar system. Each system gets its own .tres file in this folder.
##
## Each system has its own colors: its signature color tints the space
## dust, the nebula clouds and the HUD's frames, its haze color tints
## faraway things, and its sun lights everything. Flying from one system to
## the next blends smoothly between them. Its planets and sun are SkyBody
## nodes in the flight scene.


## A short code name ("home", "tidewater"). Sky bodies (planets, suns) say
## which system they belong to with it.
@export var id: String = "home"
## The system's name, shown when you fly into it (and on maps later on).
@export var display_name: String = "Unnamed System"
## Roughly where the system's middle is, in the flight world. Colors blend
## smoothly from one system to the next as you fly between their middles.
@export var center: Vector3 = Vector3.ZERO

## The system's signature color. It tints the space dust, so you always know
## where you are.
@export var signature_color: Color = Color(1.0, 1.0, 1.0)

## The color of the distance haze that faraway things fade into. Usually a
## darker, deeper version of the signature color. (How thick the haze is lives
## in res://data/tuning.tres, under "PS1 look".)
@export var haze_color: Color = Color(0.3, 0.3, 0.3)

## The color of this system's sunlight, and how bright it is.
@export var sun_color: Color = Color(1.0, 0.9, 0.78)
@export_range(0.0, 4.0, 0.05) var sun_energy: float = 1.3
## The soft light that fills in shadows here.
@export var ambient_color: Color = Color(0.42, 0.38, 0.62)
## How bright the nebula clouds across the sky are here (0 = none).
@export_range(0.0, 1.0, 0.01) var nebula_strength: float = 0.35
