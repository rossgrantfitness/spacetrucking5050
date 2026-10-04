extends SceneTree
## Makes the radio's placeholder music out of math, so every station plays
## SOMETHING until real songs are dropped into its folder:
##     res://audio/radio/placeholders/<genre>.wav        - a short loop per genre
##                                                        (stations share them)
##     res://audio/generated/ambient_pad.wav             - soft music for when the radio is off
##     res://audio/generated/static_loop.wav             - the hiss under a weak signal
##
## These are deliberately simple and obviously placeholders. Real music
## (original, royalty-free or properly licensed) replaces them: see
## res://audio/radio/README.md.
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/generate_radio_placeholders.gd


const RATE: int = 22050
const FOLDER: String = "res://audio/radio/placeholders/"

var _rng := RandomNumberGenerator.new()


func _initialize() -> void:
	_rng.seed = 5050
	var failed := false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FOLDER))
	var outputs := {
		FOLDER + "drum_and_bass.wav": _drum_and_bass(),
		FOLDER + "late_night_electro.wav": _late_night_electro(),
		FOLDER + "lofi.wav": _lofi(),
		FOLDER + "dubstep.wav": _dubstep(),
		FOLDER + "synthwave.wav": _synthwave(),
		FOLDER + "happy_hardcore.wav": _happy_hardcore(),
		FOLDER + "dub.wav": _dub(),
		FOLDER + "thrash.wav": _thrash(),
		FOLDER + "doom.wav": _doom(),
		FOLDER + "chug.wav": _chug(),
		FOLDER + "rock.wav": _rock(),
		FOLDER + "punk.wav": _punk(),
		FOLDER + "grunge.wav": _grunge(),
		FOLDER + "boom_bap.wav": _boom_bap(),
		FOLDER + "trap.wav": _trap(),
		FOLDER + "talk.wav": _talk(),
		FOLDER + "numbers.wav": _numbers(),
		"res://audio/generated/ambient_pad.wav": _ambient_pad(),
		"res://audio/generated/static_loop.wav": _static_loop(),
	}
	for path: String in outputs:
		var looping := path.ends_with("ambient_pad.wav") or path.ends_with("static_loop.wav")
		var wav := SfxSynth.to_wav(_finish(outputs[path]), looping)
		var error := wav.save_to_wav(ProjectSettings.globalize_path(path))
		print("%s: %s" % [path, error_string(error)])
		failed = failed or error != OK
	quit(1 if failed else 0)


# --- The stations --------------------------------------------------------------------

## SUBSPACE FM: rolling drum & bass at 174 bpm with a growly bass.
func _drum_and_bass() -> PackedFloat32Array:
	var bars := 16
	var step := 60.0 / 174.0 / 4.0
	var out := _silence(bars * 16 * step)
	var roots := [38, 38, 34, 36]  # D, D, Bb, C (MIDI notes)
	for bar in bars:
		var start := bar * 16 * step
		_pattern(out, start, step, "x.........x.....", _kick, 1.0)
		_pattern(out, start, step, "....x.......x...", _snare, 0.85)
		_pattern(out, start, step, "x.xxx.x.x.xxx.x.", _hat, 0.25)
		_pattern(out, start, step, ".......x.....x..", _snare, 0.25)  # Ghost notes.
		var base_note: int = roots[floori(bar / 2.0) % roots.size()]
		_add(out, start, _reese(_freq(base_note), 16 * step, 0.35))
		if bar % 4 == 0:
			_add(out, start, _pad([base_note + 24, base_note + 27, base_note + 31], 64 * step, 0.12))
	return out


## LATE BLOCK 77: bouncy late-night cartoon electronica at 128 bpm, with an
## arpeggio running over the chords.
func _late_night_electro() -> PackedFloat32Array:
	var bars := 16
	var step := 60.0 / 128.0 / 4.0
	var out := _silence(bars * 16 * step)
	var chords := [[45, 48, 52], [41, 45, 48], [43, 47, 50], [40, 43, 47]]  # Am, F, G, Em
	for bar in bars:
		var start := bar * 16 * step
		_pattern(out, start, step, "x...x...x...x...", _kick, 0.9)
		_pattern(out, start, step, "....x.......x...", _clap, 0.6)
		_pattern(out, start, step, "..x...x...x...x.", _hat, 0.3)
		var chord: Array = chords[floori(bar / 2.0) % chords.size()]
		for i in 16:
			var note: int = chord[i % 3] + 12 * (1 + floori(i / 3.0) % 2)
			_add(out, start + i * step, _pluck(_freq(note), step * 0.9, 0.16))
		_add(out, start, _sub(_freq(chord[0] - 12), 16 * step, 0.3))
	return out


## LO-FI DRIFT: slow, dusty lo-fi at 82 bpm with soft electric-piano chords
## and vinyl crackle.
func _lofi() -> PackedFloat32Array:
	var bars := 8
	var step := 60.0 / 82.0 / 4.0
	var out := _silence(bars * 16 * step)
	var chords := [[50, 53, 57, 60], [55, 59, 62, 65], [48, 52, 55, 59], [45, 48, 52, 55]]  # Dm7, G7, Cmaj7, Am7
	for bar in bars:
		var start := bar * 16 * step
		_pattern(out, start, step, "x......x..x.....", _kick, 0.7)
		_pattern(out, start, step, "....x.......x...", _rim, 0.45)
		for i in 8:
			var swing := step * 0.18 if i % 2 == 1 else 0.0
			_add(out, start + i * 2 * step + swing, _hat_sound(0.12))
		var chord: Array = chords[bar % chords.size()]
		_add(out, start, _keys(chord, 16 * step, 0.16))
		_add(out, start, _sub(_freq(chord[0] - 24), 14 * step, 0.3))
	# Vinyl crackle over everything.
	for i in out.size():
		if _rng.randf() < 0.0015:
			out[i] += _rng.randf_range(-0.25, 0.25)
		out[i] += _rng.randf_range(-0.01, 0.01)
	return out


## WOBBLE BELT: half-time dubstep at 140 bpm with a wobbling bass.
func _dubstep() -> PackedFloat32Array:
	var bars := 8
	var step := 60.0 / 140.0 / 4.0
	var out := _silence(bars * 16 * step)
	var roots := [29, 29, 32, 27]  # F, F, Ab, Eb
	for bar in bars:
		var start := bar * 16 * step
		_pattern(out, start, step, "x.........x.....", _kick, 1.0)
		_pattern(out, start, step, "........x.......", _snare, 1.0)
		_pattern(out, start, step, "x.x.x.x.x.x.x.x.", _hat, 0.18)
		var base_note: int = roots[floori(bar / 2.0) % roots.size()]
		var rate := 2.0 if bar % 2 == 0 else 4.0  # Wub... wub-wub-wub.
		_add(out, start, _wobble(_freq(base_note + 12), 8 * step, rate / (8 * step) * 2.0, 0.45))
		_add(out, start + 8 * step, _wobble(_freq(base_note + 12), 8 * step, rate / (8 * step) * 3.0, 0.45))
	return out


## NEON DRIFT: synthwave at 100 bpm: gated pads, an arpeggio, a soaring lead.
func _synthwave() -> PackedFloat32Array:
	var bars := 8
	var step := 60.0 / 100.0 / 4.0
	var out := _silence(bars * 16 * step)
	var chords := [[45, 48, 52], [41, 45, 48], [36, 40, 43], [43, 47, 50]]  # Am, F, C, G
	var melody := [76, 74, 72, 74, 76, 79, 76, 74]
	for bar in bars:
		var start := bar * 16 * step
		_pattern(out, start, step, "x...x...x...x...", _kick, 0.85)
		_pattern(out, start, step, "....x.......x...", _snare, 0.7)
		var chord: Array = chords[floori(bar / 2.0) % chords.size()]
		_add(out, start, _pad([chord[0] + 12, chord[1] + 12, chord[2] + 12], 16 * step, 0.16, 0.05))
		for i in 16:
			_add(out, start + i * step, _sub(_freq(chord[0] - 12 + (12 if i % 2 == 1 else 0)), step * 0.9, 0.22))
		_add(out, start, _lead(_freq(melody[bar]), 12 * step, 0.12))
	return out


## HYPERJUMP 180: happy hardcore at 180 bpm: pounding kicks, bright piano stabs.
func _happy_hardcore() -> PackedFloat32Array:
	var bars := 8
	var step := 60.0 / 180.0 / 4.0
	var out := _silence(bars * 16 * step)
	var chords := [[60, 64, 67], [57, 60, 64], [65, 69, 72], [67, 71, 74]]  # C, Am, F, G
	for bar in bars:
		var start := bar * 16 * step
		_pattern(out, start, step, "x...x...x...x...", _kick, 1.0)
		_pattern(out, start, step, "..x...x...x...x.", _hat, 0.4)
		_pattern(out, start, step, "....x.......x...", _clap, 0.5)
		var chord: Array = chords[bar % chords.size()]
		for hit: int in [0, 3, 6, 10, 12, 14]:
			_add(out, start + hit * step, _stab(chord, step * 1.6, 0.22))
	return out


## TIDE 77: slow dub at 75 bpm: deep bass, a skanking chord, echoes.
func _dub() -> PackedFloat32Array:
	var bars := 4
	var step := 60.0 / 75.0 / 4.0
	var out := _silence(bars * 16 * step)
	var roots := [38, 38, 43, 41]  # D, D, G, F
	for bar in bars:
		var start := bar * 16 * step
		_pattern(out, start, step, "x.......x.......", _kick, 0.9)
		_pattern(out, start, step, "........x.......", _rim, 0.7)
		var base_note: int = roots[bar % roots.size()]
		for hit: int in [0, 3, 6, 10]:
			_add(out, start + hit * step, _sub(_freq(base_note - 12), 3 * step, 0.55))
		# The skank, with two fading echoes.
		for hit: int in [4, 12]:
			for echo in 3:
				_add(out, start + (hit + echo * 3) * step, _stab([base_note + 12, base_note + 16, base_note + 19], step, 0.16 * pow(0.5, echo)))
	return out


## KRSH 666 (and Event Horizon): thrash metal at 190 bpm: fast palm-muted
## riffing, double kicks and a crash.
func _thrash() -> PackedFloat32Array:
	var bars := 8
	var step := 60.0 / 190.0 / 4.0
	var out := _silence(bars * 16 * step)
	var riff := [40, 40, 40, 43, 40, 40, 46, 45]
	for bar in bars:
		var start := bar * 16 * step
		_pattern(out, start, step, "xxxxxxxxxxxxxxxx", _kick, 0.55)
		_pattern(out, start, step, "....x.......x...", _snare, 0.9)
		if bar % 4 == 0:
			_add(out, start, _crash())
		for i in 16:
			_add(out, start + i * step, _guitar(riff[i % riff.size()] - 12, step * 0.9, 0.3, true))
	return out


## BLACK HOLE RADIO: doom at 60 bpm: huge, slow, fuzzy chords that ring out.
func _doom() -> PackedFloat32Array:
	var bars := 4
	var step := 60.0 / 60.0 / 4.0
	var out := _silence(bars * 16 * step)
	var roots := [28, 31, 26, 27]  # E, G, D, Eb
	for bar in bars:
		var start := bar * 16 * step
		_pattern(out, start, step, "x.......x.......", _kick, 0.9)
		_pattern(out, start, step, "....x.......x...", _snare, 0.8)
		_add(out, start, _crash())
		_add(out, start, _guitar(roots[bar], 15 * step, 0.4, false))
	return out


## HULL BREACH 101: metalcore / nu metal chugs at 110 bpm, with gaps.
func _chug() -> PackedFloat32Array:
	var bars := 8
	var step := 60.0 / 110.0 / 4.0
	var out := _silence(bars * 16 * step)
	var chugs := ["xx.x..xx.x.x..x.", "x..x..x.xx..x..x"]
	for bar in bars:
		var start := bar * 16 * step
		var pattern: String = chugs[bar % 2]
		_pattern(out, start, step, pattern, _kick, 0.9)
		_pattern(out, start, step, "....x.......x...", _snare, 0.9)
		for i in 16:
			if pattern[i] == "x":
				_add(out, start + i * step, _guitar(26, step * 0.95, 0.35, true))
		if bar % 4 == 3:
			_add(out, start + 12 * step, _guitar(33, 4 * step, 0.3, false))
	return out


## ASTEROID ROCK (and Glam Rocket): a classic hard-rock groove at 120 bpm.
func _rock() -> PackedFloat32Array:
	var bars := 8
	var step := 60.0 / 120.0 / 4.0
	var out := _silence(bars * 16 * step)
	var riff := [[40, 4], [43, 2], [45, 2], [40, 4], [38, 2], [40, 2]]  # E, G, A, E, D, E (note, steps)
	for bar in bars:
		var start := bar * 16 * step
		_pattern(out, start, step, "x.....x.x.......", _kick, 0.9)
		_pattern(out, start, step, "....x.......x...", _snare, 0.85)
		_pattern(out, start, step, "x.x.x.x.x.x.x.x.", _hat, 0.25)
		if bar % 4 == 0:
			_add(out, start, _crash())
		var at := 0
		for part: Array in riff:
			_add(out, start + at * step, _guitar(part[0], part[1] * step, 0.3, false))
			at += part[1]
	return out


## FUEL INJECTION: fast, scrappy punk at 200 bpm. Three chords. Done.
func _punk() -> PackedFloat32Array:
	var bars := 8
	var step := 60.0 / 200.0 / 4.0
	var out := _silence(bars * 16 * step)
	var roots := [40, 45, 47, 45]  # E, A, B, A
	for bar in bars:
		var start := bar * 16 * step
		_pattern(out, start, step, "x...x...x...x...", _kick, 0.8)
		_pattern(out, start, step, "..x...x...x...x.", _snare, 0.8)
		for i in 8:
			_add(out, start + i * 2 * step, _guitar(roots[bar % 4], step * 1.9, 0.3, false))
	# Lo-fi: crunch it a bit more.
	for i in out.size():
		out[i] = tanh(out[i] * 1.2) * 0.6
	return out


## STATIC CLING: grunge at 90 bpm: quiet verse, loud chorus, repeat.
func _grunge() -> PackedFloat32Array:
	var bars := 8
	var step := 60.0 / 90.0 / 4.0
	var out := _silence(bars * 16 * step)
	var roots := [40, 43, 38, 45]
	for bar in bars:
		var start := bar * 16 * step
		var loud := bar >= 4
		_pattern(out, start, step, "x.....x...x.....", _kick, 0.9)
		_pattern(out, start, step, "....x.......x...", _snare, 0.9 if loud else 0.5)
		if loud:
			_add(out, start, _guitar(roots[bar % 4], 16 * step, 0.38, false))
		else:
			for i in 4:
				_add(out, start + i * 4 * step, _pluck(_freq(roots[bar % 4] + 12 + i * 3), 3 * step, 0.12))
	return out


## ORBIT 808 (and Mic Check Moon): dusty boom bap at 90 bpm with a jazzy loop.
func _boom_bap() -> PackedFloat32Array:
	var bars := 8
	var step := 60.0 / 90.0 / 4.0
	var out := _silence(bars * 16 * step)
	var chords := [[57, 60, 64, 67], [55, 59, 62, 65]]  # Am7, G7
	for bar in bars:
		var start := bar * 16 * step
		_pattern(out, start, step, "x.......x.x.....", _kick, 1.0)
		_pattern(out, start, step, "....x.......x...", _snare, 0.95)
		for i in 8:
			var swing := step * 0.25 if i % 2 == 1 else 0.0
			_add(out, start + i * 2 * step + swing, _hat_sound(0.05))
		_add(out, start, _keys(chords[bar % 2], 16 * step, 0.14))
		_add(out, start, _sub(_freq(chords[bar % 2][0] - 24), 6 * step, 0.4))
		_add(out, start + 10 * step, _sub(_freq(chords[bar % 2][0] - 24), 4 * step, 0.35))
	_vinyl(out)
	return out


## TRAP LANE 404: trap at 140 bpm (half-time): booming 808s, rolling hats.
func _trap() -> PackedFloat32Array:
	var bars := 8
	var step := 60.0 / 140.0 / 4.0
	var out := _silence(bars * 16 * step)
	var notes := [33, 33, 36, 31]
	for bar in bars:
		var start := bar * 16 * step
		_pattern(out, start, step, "........x.......", _clap, 0.9)
		for i in 16:
			_add(out, start + i * step, _hat_sound(0.03))
			if bar % 2 == 1 and i >= 12:  # Hat roll.
				_add(out, start + (i + 0.5) * step, _hat_sound(0.02))
		var note: int = notes[floori(bar / 2.0) % notes.size()]
		_add(out, start, _eight_o_eight(_freq(note), 7 * step, 0.7))
		_add(out, start + 10 * step, _eight_o_eight(_freq(note), 5 * step, 0.6))
	return out


## LONG HAUL TALK 55: no music, just two muffled voices chatting (a host
## and a caller on a phone line), in gibberish.
func _talk() -> PackedFloat32Array:
	var out := _silence(16.0)
	var at := 0.2
	var speaker := 0
	while at < 15.0:
		var words := _rng.randi_range(4, 11)
		var pitch := 130.0 if speaker == 0 else 210.0
		for w in words:
			var length := _rng.randf_range(0.08, 0.2)
			_add(out, at, _syllable(pitch * _rng.randf_range(0.9, 1.15), length, speaker == 1))
			at += length + _rng.randf_range(0.02, 0.08)
		at += _rng.randf_range(0.3, 0.7)
		speaker = 1 - speaker
	for i in out.size():
		out[i] += _rng.randf_range(-0.015, 0.015)
	return out


## ???: a numbers station. Two chime tones, then slow, flat "voice" tones
## in groups, under hiss. Nobody knows who runs it.
func _numbers() -> PackedFloat32Array:
	var out := _silence(20.0)
	for note: Array in [[0.3, 74], [0.9, 69]]:
		_add(out, note[0], _sub(_freq(note[1]), 0.5, 0.35))
	var at := 2.0
	for group in 5:
		for digit in 3:
			_add(out, at, _syllable(_rng.randf_range(180.0, 200.0), 0.35, false))
			at += 0.6
		at += 1.2
	var smooth := 0.0
	for i in out.size():
		smooth = lerpf(smooth, _rng.randf_range(-1.0, 1.0), 0.3)
		out[i] += smooth * 0.05
	return out


## Soft, slowly breathing chords for when the radio is off. Loops seamlessly.
func _ambient_pad() -> PackedFloat32Array:
	var seconds := 24.0
	var out := _silence(seconds)
	var chords := [[50, 57, 62, 66], [47, 54, 59, 62]]
	for i in chords.size():
		_add(out, i * seconds * 0.5, _pad(chords[i], seconds * 0.5, 0.18, 2.5))
	return out


## Radio hiss, for a weak signal. Loops seamlessly.
func _static_loop() -> PackedFloat32Array:
	var out := _silence(2.0)
	var smooth := 0.0
	for i in out.size():
		smooth = lerpf(smooth, _rng.randf_range(-1.0, 1.0), 0.5)
		out[i] = smooth * 0.4 + (_rng.randf_range(-1.0, 1.0) if _rng.randf() < 0.004 else 0.0) * 0.5
	return out


# --- Instruments ---------------------------------------------------------------------

func _kick() -> PackedFloat32Array:
	return _make(0.28, func(t: float, _phase: float) -> float:
		return sin(TAU * (45.0 * t + 90.0 * (1.0 - exp(-t * 30.0)) / 30.0)) * exp(-t * 9.0))


func _snare() -> PackedFloat32Array:
	return _make(0.2, func(t: float, _phase: float) -> float:
		return (_rng.randf_range(-1.0, 1.0) * 0.7 + sin(TAU * 190.0 * t) * 0.5) * exp(-t * 18.0))


func _clap() -> PackedFloat32Array:
	return _make(0.18, func(t: float, _phase: float) -> float:
		var bursts := 1.0 if fmod(t, 0.012) < 0.006 or t > 0.03 else 0.3
		return _rng.randf_range(-1.0, 1.0) * exp(-t * 20.0) * bursts)


func _rim() -> PackedFloat32Array:
	return _make(0.06, func(t: float, _phase: float) -> float:
		return (sin(TAU * 1700.0 * t) * 0.6 + _rng.randf_range(-0.4, 0.4)) * exp(-t * 60.0))


func _hat() -> PackedFloat32Array:
	return _hat_sound(0.04)


func _hat_sound(length: float) -> PackedFloat32Array:
	var last := 0.0
	var out := PackedFloat32Array()
	out.resize(int(length * RATE))
	for i in out.size():
		var noise := _rng.randf_range(-1.0, 1.0)
		out[i] = (noise - last) * 0.5 * exp(-float(i) / RATE * 90.0)  # High-passed noise.
		last = noise
	return out


## A detuned, slowly filtered "reese" bass, the classic drum & bass growl.
func _reese(frequency: float, length: float, volume: float) -> PackedFloat32Array:
	var low := 0.0
	var out := PackedFloat32Array()
	out.resize(int(length * RATE))
	for i in out.size():
		var t := float(i) / RATE
		var saw := fmod(frequency * t, 1.0) * 2.0 - 1.0
		var saw2 := fmod(frequency * 1.012 * t, 1.0) * 2.0 - 1.0
		var cutoff := 0.04 + 0.03 * sin(t * 3.0)
		low = lerpf(low, (saw + saw2) * 0.5, cutoff)
		out[i] = low * volume * minf(t / 0.02, 1.0) * minf((length - t) / 0.05, 1.0)
	return out


## A deep, round sine bass.
func _sub(frequency: float, length: float, volume: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(length * RATE))
	for i in out.size():
		var t := float(i) / RATE
		out[i] = sin(TAU * frequency * t) * volume * minf(t / 0.01, 1.0) * minf((length - t) / 0.08, 1.0)
	return out


## A short plucked note, for arpeggios.
func _pluck(frequency: float, length: float, volume: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(length * RATE))
	for i in out.size():
		var t := float(i) / RATE
		var square := 1.0 if fmod(frequency * t, 1.0) < 0.5 else -1.0
		out[i] = (square * 0.5 + sin(TAU * frequency * t) * 0.5) * volume * exp(-t * 14.0)
	return out


## A quick chord stab.
func _stab(notes: Array, length: float, volume: float) -> PackedFloat32Array:
	var out := _silence(length)
	for note: int in notes:
		_add(out, 0.0, _pluck(_freq(note), length, volume / notes.size() * 1.6))
	return out


## Soft electric-piano chords with a gentle wobble.
func _keys(notes: Array, length: float, volume: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(length * RATE))
	for i in out.size():
		var t := float(i) / RATE
		var sum := 0.0
		for note: int in notes:
			var frequency := _freq(note)
			sum += sin(TAU * frequency * t) + 0.3 * sin(TAU * frequency * 2.0 * t) * exp(-t * 3.0)
		var tremolo := 0.85 + 0.15 * sin(t * TAU * 4.0)
		out[i] = sum / notes.size() * volume * tremolo * exp(-t * 0.6) * minf(t / 0.01, 1.0) * minf((length - t) / 0.1, 1.0)
	return out


## A warm, slow pad: a few detuned saws, softened.
func _pad(notes: Array, length: float, volume: float, fade: float = 0.6) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(length * RATE))
	var low := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var sum := 0.0
		for note: int in notes:
			var frequency := _freq(note)
			sum += sin(TAU * frequency * t) + 0.5 * sin(TAU * frequency * 1.005 * t + 1.0)
		low = lerpf(low, sum / notes.size(), 0.2)
		out[i] = low * volume * minf(t / fade, 1.0) * minf((length - t) / fade, 1.0)
	return out


## A distorted guitar power chord (root, fifth, octave). `muted` = a short
## palm-muted chug; otherwise it rings.
func _guitar(midi_root: int, length: float, volume: float, muted: bool) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(length * RATE))
	var low := 0.0
	var notes := [_freq(midi_root), _freq(midi_root + 7), _freq(midi_root + 12)]
	for i in out.size():
		var t := float(i) / RATE
		var sum := 0.0
		for k in notes.size():
			var frequency: float = notes[k] * (1.0 + 0.003 * k)
			sum += fmod(frequency * t, 1.0) * 2.0 - 1.0
		var drive := tanh(sum * 6.0)
		low = lerpf(low, drive, 0.35 if not muted else 0.15)
		var envelope := exp(-t * 14.0) if muted else exp(-t * 0.8)
		out[i] = low * volume * envelope * minf(t / 0.004, 1.0) * minf((length - t) / 0.03, 1.0)
	return out


## A crash cymbal: a long, bright wash of noise.
func _crash() -> PackedFloat32Array:
	var last := 0.0
	var out := PackedFloat32Array()
	out.resize(int(1.4 * RATE))
	for i in out.size():
		var noise := _rng.randf_range(-1.0, 1.0)
		out[i] = (noise - last) * 0.3 * exp(-float(i) / RATE * 2.5)
		last = noise
	return out


## A wobble bass: a saw whose brightness swings `rate` times a second.
func _wobble(frequency: float, length: float, rate: float, volume: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(length * RATE))
	var low := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var saw := (fmod(frequency * t, 1.0) * 2.0 - 1.0) + (fmod(frequency * 0.995 * t, 1.0) * 2.0 - 1.0)
		var open := 0.02 + 0.3 * (0.5 + 0.5 * sin(TAU * rate * t - PI * 0.5))
		low = lerpf(low, saw * 0.5, open)
		out[i] = tanh(low * 2.0) * volume * minf(t / 0.01, 1.0) * minf((length - t) / 0.02, 1.0)
	return out


## A singing synth lead with a little vibrato.
func _lead(frequency: float, length: float, volume: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(length * RATE))
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		phase += frequency * (1.0 + 0.006 * sin(TAU * 5.0 * t) * minf(t, 1.0)) / RATE
		var square := 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
		out[i] = (square * 0.4 + sin(TAU * phase) * 0.6) * volume * minf(t / 0.05, 1.0) * minf((length - t) / 0.2, 1.0)
	return out


## A booming 808: a sine that drops in pitch, slightly overdriven.
func _eight_o_eight(frequency: float, length: float, volume: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(length * RATE))
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		phase += frequency * (1.0 + 1.5 * exp(-t * 25.0)) / RATE
		out[i] = tanh(sin(TAU * phase) * 1.8) * volume * exp(-t * 1.2) * minf((length - t) / 0.05, 1.0)
	return out


## One gibberish syllable of "speech": a buzzy tone through a moving vowel.
## `phone` = squeezed through a telephone line.
func _syllable(pitch: float, length: float, phone: bool) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(length * RATE))
	var vowel := _rng.randf_range(400.0, 900.0)
	var low := 0.0
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		phase += pitch * (1.0 - 0.15 * t / length) / RATE
		var buzz := fmod(phase, 1.0) * 2.0 - 1.0
		var formant := sin(TAU * vowel * t) * 0.5 + 0.5
		low = lerpf(low, buzz * formant, 0.25 if not phone else 0.6)
		var envelope := sin(PI * t / length)
		out[i] = (low if not phone else low - buzz * 0.2) * envelope * 0.35
	return out


## Vinyl crackle mixed into a loop.
func _vinyl(out: PackedFloat32Array) -> void:
	for i in out.size():
		if _rng.randf() < 0.0015:
			out[i] += _rng.randf_range(-0.25, 0.25)
		out[i] += _rng.randf_range(-0.01, 0.01)


# --- Helpers ---------------------------------------------------------------------------

func _make(length: float, wave: Callable) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(length * RATE))
	for i in out.size():
		out[i] = wave.call(float(i) / RATE, 0.0)
	return out


## Plays `sound` on every 'x' of a 16-step pattern.
func _pattern(out: PackedFloat32Array, start: float, step: float, pattern: String, sound: Callable, volume: float) -> void:
	for i in pattern.length():
		if pattern[i] == "x":
			var hit: PackedFloat32Array = sound.call()
			for j in hit.size():
				hit[j] *= volume
			_add(out, start + i * step, hit)


## Mixes `sound` into `out` starting at `start` seconds (wrapping around the
## end, so loops stay seamless).
func _add(out: PackedFloat32Array, start: float, sound: PackedFloat32Array) -> void:
	var offset := int(start * RATE)
	for i in sound.size():
		var index := (offset + i) % out.size()
		out[index] += sound[i]


func _silence(seconds: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(seconds * RATE))
	return out


## Gently squashes peaks and sets the loudness.
func _finish(samples: PackedFloat32Array) -> PackedFloat32Array:
	var peak := 0.001
	for value in samples:
		peak = maxf(peak, absf(value))
	for i in samples.size():
		samples[i] = tanh(samples[i] / peak * 1.2) * 0.8
	return samples


static func _freq(midi_note: int) -> float:
	return 440.0 * pow(2.0, (midi_note - 69) / 12.0)
