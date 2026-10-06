extends Node
## Dialogue boxes: typewriter text with Animal Crossing-style gibberish voice
## blips (each character has their own pitch).
##
##     await Dialogue.say("Dottie", ["Morning, {bunny}."], 1.3)
##     await Dialogue.say(npc.display_name, lines, npc.voice_pitch, npc)
##
## Passing the speaker's NPCData gives the blips their own voice (type, key
## and scale; see VoiceBlips.gd).
##
## Lines can use {bunny}, {husband}, {base} and {currency}; they're filled in
## from res://data/world_names.tres. Who says what lives in data files under
## res://data/npcs/ (and later res://data/dialogue/). Comm portraits and radio
## chatter while flying arrive in M5.


## Emitted when a conversation starts and ends.
signal started
signal finished

## Jacki's own voice, for when she talks to herself (looking at things).
const BUNNY_VOICE: NPCData = preload("res://data/npcs/bunny_jack.tres")

var _box: DialogueBox


## Whether a dialogue box is open right now.
func is_active() -> bool:
	return _box != null


## Shows `lines` from `speaker`, one box at a time, and returns once the
## player has read them all (true) or left early (false: Cancel, or
## cancel() when they walk away).
func say(speaker: String, lines: PackedStringArray, voice_pitch: float = 1.0, voice: NPCData = null) -> bool:
	if _box != null:
		return false
	var filled := PackedStringArray()
	for line in lines:
		filled.append(GameState.names.fill_in(line))
	_box = DialogueBox.new()
	get_tree().root.add_child(_box)
	started.emit()
	await _box.run(speaker, filled, voice_pitch, voice)
	var read_it_all := not _box.cancelled
	_box.queue_free()
	_box = null
	finished.emit()
	return read_it_all


## Ends the conversation on screen now (like walking away mid-sentence).
func cancel() -> void:
	if _box != null:
		_box.cancel()
