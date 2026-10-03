class_name SystemData
extends Resource
## One solar system. Each system gets its own .tres file in this folder.
##
## For now (M1) only the signature color is used: it tints the space dust.
## Fog, haze, sights, hazards and the system's client arrive in later
## milestones.


## The system's name, shown on maps later on.
@export var display_name: String = "Unnamed System"

## The system's signature color. It tints the space dust now, and the fog and
## haze from M4 on, so you always know where you are.
@export var signature_color: Color = Color(1.0, 1.0, 1.0)
