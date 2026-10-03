class_name SystemData
extends Resource
## One solar system. Each system gets its own .tres file in this folder.
##
## For now, the signature color tints the space dust and the haze color
## tints faraway things. Sights, hazards and the system's client arrive in
## later milestones.


## The system's name, shown on maps later on.
@export var display_name: String = "Unnamed System"

## The system's signature color. It tints the space dust, so you always know
## where you are.
@export var signature_color: Color = Color(1.0, 1.0, 1.0)

## The color of the distance haze that faraway things fade into. Usually a
## darker, deeper version of the signature color. (How thick the haze is lives
## in res://data/tuning.tres, under "PS1 look".)
@export var haze_color: Color = Color(0.3, 0.3, 0.3)
