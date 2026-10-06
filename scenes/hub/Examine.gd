class_name Examine
extends Interactable
## Something to look at: a shuttered shop, a window, an arcade cabinet. The
## bunny says what she thinks about it (her lines, in her voice).


## What she thinks, one box per line. Can use {bunny}, {husband}, {base},
## {currency}.
@export var lines: PackedStringArray = PackedStringArray(["Huh."])

var _busy := false


func _ready() -> void:
	super()
	if prompt == "USE":
		prompt = "LOOK"


func interact(player: Node3D) -> void:
	if _busy:
		return
	super(player)
	_busy = true
	var hub_player := player as HubPlayer
	hub_player.set_busy(true)
	await Dialogue.say(GameState.names.bunny_name, lines, Dialogue.BUNNY_VOICE.voice_pitch, Dialogue.BUNNY_VOICE)
	hub_player.set_busy(false)
	_busy = false
