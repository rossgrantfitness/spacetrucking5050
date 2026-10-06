class_name NPC
extends Interactable
## Somebody on the base you can talk to. Who they are and what they say lives
## in their data file (`data`, in res://data/npcs/); their look is the
## "Visual" child (a model scene).
##
## While they talk, she can walk off: that ends the conversation (so does
## Cancel, Esc / B). Leaving early skips whatever came after (a job offer, a
## menu) and doesn't count as hearing it, so they'll say it again next time.


## How far (meters) she can wander from them mid-conversation before it ends.
const WALK_AWAY_DISTANCE: float = 2.6

## Their name and lines.
@export var data: NPCData

var _talking := false
var _listener: Node3D  # Who's listening right now (to notice them walking off).

@onready var _visual: Node3D = get_node_or_null("Visual")


func _ready() -> void:
	super()
	prompt = "TALK"


func _process(delta: float) -> void:
	if _visual != null and _visual.has_method("animate"):
		_visual.call("animate", delta, 0.0)
	if _listener != null:
		var apart := _listener.global_position - global_position
		if Vector2(apart.x, apart.z).length() > WALK_AWAY_DISTANCE:
			Dialogue.cancel()  # She walked off.


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
	# What they say depends on the story so far (see Conversation.gd).
	var conversation := data.pick_conversation()
	var lines := conversation.lines if conversation != null and not conversation.lines.is_empty() else data.lines
	var heard := await _talk(hub_player, lines)
	if heard and conversation != null:
		hub_player.set_busy(true)
		for flag in conversation.sets_flags:
			GameState.set_flag(flag)
		if conversation.offers_job != null:
			await HubServices.offer_job(get_tree(), conversation.offers_job)
		if not conversation.opens_menu.is_empty():
			var room := HubRoom.find(self)
			await HubServices.open(conversation.opens_menu, get_tree(), room.place_id if room != null else "")
		GameState.save_game()
	hub_player.set_busy(false)
	_talking = false


## Whether they have a job for you (one they haven't given you yet): the
## on-foot HUD hangs a "!" over them. (So does being who the objective
## points at; see HubHUD.)
func has_news() -> bool:
	var story := data.pick_conversation() if data != null else null
	if story == null or story.offers_job == null:
		return false
	var job := story.offers_job
	return GameState.active_job_id != job.id and not job.id in GameState.finished_jobs


func _has_new_flags(story: Conversation) -> bool:
	for flag in story.sets_flags:
		if not GameState.has_flag(flag):
			return true
	return false


func _exit_tree() -> void:
	if _listener != null:
		Dialogue.cancel()  # Leaving the room mid-sentence (walked through a door).


## Says `lines` while she's free to walk away (which ends it). Returns
## whether she heard them all.
func _talk(player: HubPlayer, lines: PackedStringArray) -> bool:
	player.set_busy(false)
	_listener = player
	var heard := await Dialogue.say(data.display_name, lines, data.voice_pitch, data)
	_listener = null
	return heard
