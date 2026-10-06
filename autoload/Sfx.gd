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
##
## Sounds you hear a lot never play exactly the same twice (so they don't
## nag, the way a phone's identical beep starts to grate):
##   - cues with extra takes (cue_<name>_2.wav, _3.wav: SfxSynth.VARIED_CUES)
##     pick a different take each time;
##   - every cue drifts a hair in pitch (DRIFT_CENTS), too little to sound
##     out of tune;
##   - the menu tick wanders between neighbouring notes of the game's home
##     key (WANDER), like a little wind chime as you scroll.


## How many cues can overlap.
const VOICES: int = 4
## How far (in cents, hundredths of a note) each play can drift in pitch.
const DRIFT_CENTS: float = 7.0
## Cues that wander between notes: semitone steps they can move by (all
## land on the home key, A major pentatonic, from the cue's own note).
const WANDER := {"ui_move": [0, 2, -3, -5]}

var _cues := {}
var _last_take := {}
var _last_step := {}
var _rng := RandomNumberGenerator.new()
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
	var takes := takes_of(cue)
	if takes.is_empty():
		return
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = takes[_fresh(_last_take, cue, takes.size())]
	player.volume_db = volume_db
	player.pitch_scale = pitch * varied_pitch(cue)
	player.play()


## How much to nudge `cue`'s pitch this time (1.0 = as recorded).
func varied_pitch(cue: String) -> float:
	var cents := _rng.randf_range(-DRIFT_CENTS, DRIFT_CENTS)
	if WANDER.has(cue):
		var steps: Array = WANDER[cue]
		cents += 100.0 * float(steps[_fresh(_last_step, cue, steps.size())])
	return pow(2.0, cents / 1200.0)


## Every take of `cue` there is (the plain one first). Empty if none.
func takes_of(cue: String) -> Array[AudioStream]:
	if not _cues.has(cue):
		var found: Array[AudioStream] = []
		for suffix: String in ["", "_2", "_3"]:
			var path := "res://audio/generated/cue_%s%s.wav" % [cue, suffix]
			if ResourceLoader.exists(path):
				found.append(load(path) as AudioStream)
		if found.is_empty():
			push_warning("Sfx: no sound called '%s' (res://audio/generated/cue_%s.wav)" % [cue, cue])
		_cues[cue] = found
	return _cues[cue]


# A random index below `count`, not the same as last time for this cue.
func _fresh(last: Dictionary, cue: String, count: int) -> int:
	if count <= 1:
		return 0
	var previous := int(last.get(cue, -1))
	var pick := _rng.randi_range(0, count - 1 if previous < 0 else count - 2)
	if previous >= 0 and pick >= previous:
		pick += 1
	last[cue] = pick
	return pick


func _exit_tree() -> void:
	# Let go of the sounds on the way out (so nothing's left playing at exit).
	for player in _players:
		player.stop()
		player.stream = null
	_cues.clear()
