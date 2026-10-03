class_name NPC
extends Interactable
## Somebody on the base you can talk to. Who they are and what they say lives
## in their data file (`data`, in res://data/npcs/); their look is the
## "Visual" child (a model scene).


## Their name and lines.
@export var data: NPCData

var _talking := false

@onready var _visual: Node3D = get_node_or_null("Visual")


func _ready() -> void:
	super()
	prompt = "TALK"


func _process(delta: float) -> void:
	if _visual != null and _visual.has_method("animate"):
		_visual.call("animate", delta, 0.0)


func interact(player: Node3D) -> void:
	if _talking or data == null:
		return
	super(player)
	_talking = true
	var hub_player := player as HubPlayer
	hub_player.set_busy(true)
	# Turn to look at each other.
	var to_player := player.global_position - global_position
	if _visual != null:
		_visual.rotation.y = atan2(-to_player.x, -to_player.z) - global_rotation.y
	hub_player.face(atan2(to_player.x, to_player.z))
	await Dialogue.say(data.display_name, data.lines, data.voice_pitch)
	hub_player.set_busy(false)
	_talking = false
