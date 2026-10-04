extends SceneTree
## Makes the radio's placeholder music out of math, so every station plays
## SOMETHING until real songs are dropped into its folder:
##     res://audio/radio/<station>/placeholder_loop.wav   - a short beat per station
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

var _rng := RandomNumberGenerator.new()


func _initialize() -> void:
	_rng.seed = 5050
	var failed := false
	var outputs := {
		"res://audio/radio/subspace_fm/placeholder_loop.wav": _drum_and_bass(),
		"res://audio/radio/jungle_juice/placeholder_loop.wav": _jungle(),
		"res://audio/radio/late_block/placeholder_loop.wav": _late_night_electro(),
		"res://audio/radio/lofi_drift/placeholder_loop.wav": _lofi(),
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


## JUNGLE JUICE: choppy breakbeats at 165 bpm with a deep dub bass.
func _jungle() -> PackedFloat32Array:
	var bars := 16
	var step := 60.0 / 165.0 / 4.0
	var out := _silence(bars * 16 * step)
	var roots := [33, 33, 31, 36]  # A, A, G, C
	var breaks := ["x.x.......x.x...", "x.........xx...."]
	var snares := ["....x..x.x..x..x", "....x.x...x.x.xx"]
	for bar in bars:
		var start := bar * 16 * step
		_pattern(out, start, step, breaks[bar % 2], _kick, 0.95)
		_pattern(out, start, step, snares[bar % 2], _snare, 0.75)
		_pattern(out, start, step, "xxxxxxxxxxxxxxxx", _hat, 0.16)
		var base_note: int = roots[floori(bar / 2.0) % roots.size()]
		for hit: int in [0, 6, 10]:
			_add(out, start + hit * step, _sub(_freq(base_note), 5 * step, 0.5))
		if bar % 2 == 1:
			_add(out, start + 8 * step, _stab([base_note + 24, base_note + 28, base_note + 31], 0.6, 0.18))
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
