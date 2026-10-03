class_name Interactable
extends Area3D
## Something the bunny can use when she's next to it: a person to talk to,
## a door, a terminal. When she's in reach, a prompt pops up; pressing
## Interact (E / A) calls interact().
##
## Give it a CollisionShape3D child for its reach. Other scripts (NPC,
## RoomExit) build on this one.


## Emitted when the player uses this.
signal interacted(player: Node3D)

## The word shown on the prompt, like "TALK" or "BOARD SHIP".
@export var prompt: String = "USE"
## Whether it can be used right now.
@export var enabled: bool = true


func _ready() -> void:
	add_to_group("interactable")
	monitoring = false  # The player looks for us, not the other way around.


## Whether to show a prompt for this when the player is in reach.
func shows_prompt() -> bool:
	return enabled


## Called by the player. Scripts that build on this one add their own
## behavior and then call super.
func interact(player: Node3D) -> void:
	interacted.emit(player)
