class_name MusicSynth
## Little pieces of music made out of pure math, like SfxSynth does for sound
## effects. tools/generate_sounds.gd saves them as .wav files in
## res://audio/generated/, where you can swap in a real recording (same file
## name) whenever you like.
##
## The docking computer's waltz is an original tune (a nod to the classic
## space-sim joke of docking to a waltz, not a copy of any real piece).


const MIX_RATE: int = SfxSynth.MIX_RATE
## Beats per minute (three beats to a bar: it's a waltz).
const WALTZ_BPM: float = 96.0

## The chords, one per bar (32 bars, then it loops).
const WALTZ_CHORDS: Array[String] = [
	"D", "D", "A7", "A7", "A7", "A7", "D", "D", "D", "D", "G", "G", "D", "A7", "D", "D",
	"G", "G", "D", "D", "A7", "A7", "D", "D", "Em", "Em", "A7", "A7", "D", "A7", "D", "D"]
## Each chord: [bass note, the three notes played on beats two and three]
## (MIDI note numbers: 60 is middle C).
const CHORD_NOTES := {
	"D": [50, [54, 57, 62]], "A7": [45, [55, 61, 64]], "G": [43, [55, 59, 62]], "Em": [52, [55, 59, 64]]}
## The tune: [bar (from 1), beat (0 to 2), note, how many beats it lasts].
const WALTZ_MELODY: Array = [
	[1, 0, 69, 1], [1, 1, 74, 1], [1, 2, 78, 1], [2, 0, 78, 2], [2, 2, 76, 1],
	[3, 0, 76, 1], [3, 1, 73, 1], [3, 2, 69, 1], [4, 0, 76, 3],
	[5, 0, 67, 1], [5, 1, 73, 1], [5, 2, 76, 1], [6, 0, 79, 2], [6, 2, 78, 1],
	[7, 0, 78, 1], [7, 1, 74, 1], [7, 2, 69, 1], [8, 0, 74, 3],
	[9, 0, 69, 1], [9, 1, 74, 1], [9, 2, 78, 1], [10, 0, 81, 2], [10, 2, 79, 1],
	[11, 0, 79, 1], [11, 1, 71, 1], [11, 2, 74, 1], [12, 0, 79, 2], [12, 2, 78, 1],
	[13, 0, 78, 1], [13, 1, 81, 1], [13, 2, 78, 1], [14, 0, 76, 1], [14, 1, 73, 1], [14, 2, 76, 1],
	[15, 0, 74, 3],
	[17, 0, 71, 1], [17, 1, 74, 1], [17, 2, 79, 1], [18, 0, 83, 2], [18, 2, 81, 1],
	[19, 0, 81, 1], [19, 1, 78, 1], [19, 2, 74, 1], [20, 0, 81, 3],
	[21, 0, 79, 1], [21, 1, 76, 1], [21, 2, 73, 1], [22, 0, 76, 2], [22, 2, 79, 1],
	[23, 0, 78, 2], [23, 2, 76, 1], [24, 0, 74, 3],
	[25, 0, 79, 1], [25, 1, 76, 1], [25, 2, 71, 1], [26, 0, 76, 2], [26, 2, 79, 1],
	[27, 0, 81, 1], [27, 1, 79, 1], [27, 2, 76, 1], [28, 0, 73, 2], [28, 2, 76, 1],
	[29, 0, 74, 1], [29, 1, 78, 1], [29, 2, 81, 1], [30, 0, 79, 2], [30, 2, 76, 1],
	[31, 0, 74, 3], [32, 1, 69, 1]]


## The docking computer's lounge waltz: a soft "oom" of bass on each bar's
## first beat, "pah pah" piano chords on the other two, and a vibraphone
## tune on top, with a brushed snare. Loops seamlessly.
static func make_docking_waltz() -> AudioStreamWAV:
	var beat := 60.0 / WALTZ_BPM
	var bars := WALTZ_CHORDS.size()
	var count := int(MIX_RATE * beat * 3.0 * bars)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5050
	for bar in bars:
		var chord: Array = CHORD_NOTES[WALTZ_CHORDS[bar]]
		var bar_start := bar * 3.0 * beat
		_play(samples, bar_start, _hz(chord[0]), beat * 1.6, "bass", 0.32)
		for b in [1, 2]:
			for note: int in chord[1]:
				_play(samples, bar_start + b * beat, _hz(note), beat * 0.7, "piano", 0.07)
			_brush(samples, bar_start + b * beat, rng, 0.05)
	for note: Array in WALTZ_MELODY:
		var start := ((int(note[0]) - 1) * 3 + int(note[1])) * beat
		_play(samples, start, _hz(note[2]), float(note[3]) * beat, "vibes", 0.2)
	return SfxSynth.to_wav(samples, true)


static func _hz(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)


## Adds one note to `samples` (wrapping round the end, so the loop is seamless).
static func _play(samples: PackedFloat32Array, start_seconds: float, hz: float, seconds: float, voice: String, volume: float) -> void:
	var start := int(start_seconds * MIX_RATE)
	var ring := seconds + (1.2 if voice == "vibes" else 0.25)
	var length := int(ring * MIX_RATE)
	for i in length:
		var t := float(i) / MIX_RATE
		var wave := 0.0
		var envelope := minf(t / 0.008, 1.0)
		match voice:
			"bass":
				wave = sin(TAU * hz * t) + 0.3 * sin(TAU * hz * 2.0 * t)
				envelope *= exp(-t * 2.2)
			"piano":
				# A soft electric piano: a bell-ish tine that fades fast.
				wave = sin(TAU * hz * t + 0.8 * sin(TAU * hz * t) * exp(-t * 6.0))
				envelope *= exp(-t * 4.5)
			"vibes":
				# A vibraphone: a pure tone, a quiet bright partial, and a slow
				# tremolo, ringing on after the note.
				wave = sin(TAU * hz * t) + 0.15 * sin(TAU * hz * 4.0 * t) * exp(-t * 10.0)
				envelope *= exp(-t * 1.4) * (0.85 + 0.15 * sin(TAU * 5.5 * t))
				if t > seconds:
					envelope *= exp(-(t - seconds) * 4.0)
		samples[(start + i) % samples.size()] += wave * envelope * volume


## A brushed snare: a short swish of soft noise.
static func _brush(samples: PackedFloat32Array, start_seconds: float, rng: RandomNumberGenerator, volume: float) -> void:
	var start := int(start_seconds * MIX_RATE)
	var smooth := 0.0
	for i in int(0.18 * MIX_RATE):
		var t := float(i) / MIX_RATE
		smooth = lerpf(smooth, rng.randf_range(-1.0, 1.0), 0.35)
		samples[(start + i) % samples.size()] += smooth * exp(-t * 18.0) * minf(t / 0.01, 1.0) * volume
