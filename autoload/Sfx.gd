extends Node
## Little game sounds, from anywhere:
##
##     Sfx.play("job_accept")
##
## Each cue is a file in res://audio/generated/ called cue_<name>.wav, made
## from math by tools/generate_sounds.gd (see SfxSynth.make_cue for the
## list). To use a real sound instead, replace the file, keeping its name.
## They play on the SFX channel (the pause menu's "Sound effects" slider),
## even while the game is paused, so menus click.


## How many cues can overlap.
const VOICES: int = 4

var _cues := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		player.bus = Settings.SFX_BUS
		add_child(player)
		_players.append(player)


## Plays the cue called `cue` ("ui_move", "job_accept", "course_set"...).
func play(cue: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var stream := _stream(cue)
	if stream == null:
		return
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()


func _stream(cue: String) -> AudioStream:
	if not _cues.has(cue):
		var path := "res://audio/generated/cue_%s.wav" % cue
		_cues[cue] = load(path) if ResourceLoader.exists(path) else null
		if _cues[cue] == null:
			push_warning("Sfx: no sound called '%s' (%s)" % [cue, path])
	return _cues[cue]


func _exit_tree() -> void:
	# Let go of the sounds on the way out (so nothing's left playing at exit).
	for player in _players:
		player.stop()
		player.stream = null
	_cues.clear()
