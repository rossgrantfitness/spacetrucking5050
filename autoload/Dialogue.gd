extends Node
## Dialogue boxes: typewriter text with Animal Crossing-style gibberish voice
## blips (each character has their own pitch).
##
##     await Dialogue.say("Dottie", ["Morning, {bunny}."], 1.3)
##
## Lines can use {bunny}, {husband}, {base} and {currency}; they're filled in
## from res://data/world_names.tres. Who says what lives in data files under
## res://data/npcs/ (and later res://data/dialogue/). Comm portraits and radio
## chatter while flying arrive in M5.


## Emitted when a conversation starts and ends.
signal started
signal finished

var _box: DialogueBox


## Whether a dialogue box is open right now.
func is_active() -> bool:
	return _box != null


## Shows `lines` from `speaker`, one box at a time, and returns once the
## player has read them all.
func say(speaker: String, lines: PackedStringArray, voice_pitch: float = 1.0) -> void:
	if _box != null:
		return
	var filled := PackedStringArray()
	for line in lines:
		filled.append(GameState.names.fill_in(line))
	_box = DialogueBox.new()
	get_tree().root.add_child(_box)
	started.emit()
	await _box.run(speaker, filled, voice_pitch)
	_box.queue_free()
	_box = null
	finished.emit()
