class_name SfxSynth
## Makes short sound effects out of pure math (no audio files needed), like
## EngineSynth does for the engine. tools/generate_sounds.gd saves them as
## .wav files in res://audio/generated/, where you can swap in real sounds.


const MIX_RATE: int = 22050


## A soft cartoon "bonk" for bumping into things: a rubbery tone that drops
## in pitch, with a little knock at the start. Cozy, not crunchy.
static func make_bonk() -> AudioStreamWAV:
	var seconds := 0.35
	var count := int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5050
	var phase := 0.0
	for i in count:
		var t := float(i) / MIX_RATE
		var pitch := lerpf(340.0, 120.0, minf(t / 0.18, 1.0))  # Boinnng...
		phase += TAU * pitch / MIX_RATE
		var tone := sin(phase) * 0.7 + sin(phase * 2.0) * 0.2 + sin(phase * 3.0) * 0.08
		var knock := rng.randf_range(-1.0, 1.0) * exp(-t * 90.0) * 0.6
		var fade := exp(-t * 11.0) * minf(t / 0.004, 1.0)
		samples[i] = tanh((tone * fade + knock) * 1.2) * 0.9
	return to_wav(samples, false)


## One tiny "blip" of Animal Crossing-style gibberish voice. The dialogue box
## plays it for each letter, at a different pitch for each character.
static func make_blip() -> AudioStreamWAV:
	var seconds := 0.07
	var count := int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t := float(i) / MIX_RATE
		# A soft square-ish wave (a few odd harmonics) for that chirpy voice.
		var wave := sin(TAU * 440.0 * t) + sin(TAU * 1320.0 * t) / 3.0 + sin(TAU * 2200.0 * t) / 5.0
		var envelope := minf(t / 0.005, 1.0) * clampf((seconds - t) / 0.03, 0.0, 1.0)
		samples[i] = wave * envelope * 0.35
	return to_wav(samples, false)


## The other voice blips (all on the same note, A, like `blip`, so the
## dialogue box can play them in any key). Each character picks one in
## their data file (`voice_type`):
##   square - a hard 8-bit beep (robots, clerks, Marge)
##   reed   - nasal and buzzy, like a kazoo (Sal, Moe)
##   gruff  - low and growly, with a little rasp (Chang Ma, Wendell)
##   chirp  - a quick upward bird chirp (Pip, the owl)
## ("soft" is `blip` above.)
static func make_voice(kind: String) -> AudioStreamWAV:
	var seconds := 0.075
	var count := int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var phase := 0.0
	for i in count:
		var t := float(i) / MIX_RATE
		var hz := 440.0
		if kind == "chirp":
			hz = 440.0 * lerpf(0.8, 1.25, t / seconds)  # Sweeps up through the note.
		phase += TAU * hz / MIX_RATE
		var wave := 0.0
		match kind:
			"square":
				wave = (1.0 if sin(phase) > 0.0 else -1.0) * 0.55
			"reed":
				# A sawtooth through a little wobble: nasal.
				wave = (fposmod(phase / TAU, 1.0) * 2.0 - 1.0) * 0.6 + sin(phase * 3.0) * 0.15
			"gruff":
				# Down an octave in its overtones, with a raspy buzz.
				wave = sin(phase) * 0.6 + sin(phase * 0.5) * 0.5 + rng.randf_range(-1.0, 1.0) * 0.18
				wave = tanh(wave * 1.8) * 0.7
			_:
				wave = sin(phase) * 0.8 + sin(phase * 2.0) * 0.2
		var envelope := minf(t / 0.004, 1.0) * clampf((seconds - t) / 0.03, 0.0, 1.0)
		samples[i] = wave * envelope * 0.4
	return to_wav(samples, false)


## How the little game sounds are designed (the "pleasant product sound"
## rules, like a good rice cooker or a console's menu clicks):
##   - One home key: A major pentatonic (A B C# E F#). Every cue's notes come
##     from it, so any two cues that overlap still sound nice together.
##   - One motif: E - A - C# (up a fourth, then a major third). Startup,
##     jobs, getting paid and notices all borrow it, so the game "sounds
##     like itself".
##   - Soft materials, not beeps: wood (marimba), glass (chimes) and felt
##     (a soft mallet). Gentle attacks, natural rings.
##   - No harsh highs: notes stay under about 1.5 kHz and everything goes
##     through a soft low-pass (_soften), so the shrill 2-4 kHz band (the
##     part of a sound that grates) stays quiet.
##   - Weight matches meaning: tiny high ticks for small things (moving the
##     menu), warm middle notes for good things (jobs, money).
##   - Rising = yes/done, falling = back/off. Never a sour note, except the
##     out-of-control alarm, which is meant to worry you.
## Sfx.gd adds the last rule: sounds you hear a lot never play exactly the
## same twice (see VARIED_CUES).

## Note frequencies (Hz) in the home key, A major pentatonic.
const NOTE := {
	"A3": 220.0, "C#4": 277.18, "E4": 329.63, "F#4": 369.99,
	"A4": 440.0, "B4": 493.88, "C#5": 554.37, "E5": 659.26, "F#5": 739.99,
	"A5": 880.0, "B5": 987.77, "C#6": 1108.73, "E6": 1318.51, "F#6": 1479.98,
}

## The cues you hear over and over. Each gets three slightly different takes
## (cue_ui_move.wav, cue_ui_move_2.wav, cue_ui_move_3.wav) so a busy menu
## doesn't sound like a machine gun.
const VARIED_CUES: Array[String] = ["ui_move", "ui_confirm", "ui_back", "door", "clunk", "bump"]

## Every cue tools/generate_sounds.gd makes.
const CUES: Array[String] = [
	"ui_move", "ui_confirm", "ui_back", "job_accept", "course_set", "autopilot_off",
	"cash", "pickup", "notice", "door", "clunk", "forks_up", "nope", "bump",
]


## Little game sounds (menus, jobs, the nav computer, money, doors). Each is
## a few soft notes (see `_tones`). `take` 0, 1 or 2 picks a slightly
## different version (brighter, darker, a different puff of air) for the
## VARIED_CUES.
##   ui_move     - a tiny wooden tick moving between menu buttons
##   ui_confirm  - wood then glass, up a major third: "ba-ding"
##   ui_back     - two felt notes stepping down: "back we go"
##   job_accept  - a soft rubber stamp, then the motif on wood and glass
##   course_set  - the nav computer: two wooden pips, a chime up a fourth, a relay tick
##   autopilot_off - the nav computer letting go: a chime falling a fourth
##   cash        - a few glassy coins, then a warm two-note chime (getting paid, buying)
##   pickup      - a quick pentatonic sparkle up (finding something)
##   notice      - a gentle two-note glass chime, like a train station (something's up aboard)
##   door        - a soft pneumatic puff that settles with a felt thunk
##   clunk       - something dropping into a vending machine tray
##   forks_up    - the forklift's forks taking a load: a hum rising a fifth
##   nope        - a gentle "mm-mm" (that didn't work, no harm done)
##   bump        - a padded knock (the forklift nudging a wall)
static func make_cue(cue: String, take: int = 0) -> AudioStreamWAV:
	var bright := _pick([1.0, 0.7, 1.3], take)
	match cue:
		"ui_move":
			return _tones([[0.0, NOTE["E6"], 0.035, "wood", 0.16]], 0.12, bright, 2200.0)
		"ui_confirm":
			return _tones([[0.0, NOTE["A5"], 0.05, "wood", 0.2], [0.055, NOTE["C#6"], 0.22, "glass", 0.17]], 0.45, bright)
		"ui_back":
			return _tones([[0.0, NOTE["E5"], 0.07, "felt", 0.24], [0.07, NOTE["C#5"], 0.14, "felt", 0.24]], 0.35, bright)
		"job_accept":
			var run := _tones([
				[0.14, NOTE["E5"], 0.08, "wood", 0.2], [0.23, NOTE["A5"], 0.08, "wood", 0.2],
				[0.32, NOTE["C#6"], 0.5, "glass", 0.18], [0.32, NOTE["A4"], 0.5, "felt", 0.14],
			], 1.1)
			return _mix(run, _stamp())
		"course_set":
			var pips := _tones([
				[0.0, NOTE["B5"], 0.04, "wood", 0.15], [0.09, NOTE["B5"], 0.04, "wood", 0.15],
				[0.19, NOTE["E6"], 0.3, "glass", 0.14], [0.19, NOTE["E5"], 0.3, "felt", 0.1],
			], 0.7)
			return _mix(pips, _click(0.42))
		"autopilot_off":
			return _tones([[0.0, NOTE["A5"], 0.08, "glass", 0.15], [0.12, NOTE["E5"], 0.3, "glass", 0.15], [0.12, NOTE["A4"], 0.3, "felt", 0.1]], 0.65)
		"cash":
			var chime := _tones([[0.16, NOTE["A5"], 0.6, "glass", 0.16], [0.16, NOTE["C#6"], 0.6, "glass", 0.13], [0.16, NOTE["A4"], 0.4, "felt", 0.14]], 1.1)
			return _mix(chime, _coins())
		"pickup":
			return _tones([
				[0.0, NOTE["A5"], 0.05, "glass", 0.17], [0.05, NOTE["B5"], 0.05, "glass", 0.17],
				[0.1, NOTE["C#6"], 0.05, "glass", 0.17], [0.15, NOTE["E6"], 0.4, "glass", 0.17],
				[0.15, NOTE["A4"], 0.3, "felt", 0.1],
			], 0.75)
		"notice":
			return _tones([[0.0, NOTE["E5"], 0.4, "glass", 0.17], [0.22, NOTE["A5"], 0.6, "glass", 0.17], [0.22, NOTE["A4"], 0.4, "felt", 0.08]], 1.2)
		"door":
			return _mix(_hiss(take), _tones([[0.3, NOTE["A3"] * _pick([1.0, 0.89, 1.12], take), 0.08, "felt", 0.18]], 0.5, bright))
		"clunk":
			return _mix(_knock(take, 0.0, 90.0), _tones([[0.0, NOTE["E4"], 0.06, "wood", 0.18 * bright]], 0.4, 0.6))
		"forks_up":
			return _tones([[0.0, NOTE["A3"], 0.25, "felt", 0.2], [0.18, NOTE["E4"], 0.3, "felt", 0.2], [0.18, NOTE["A4"], 0.2, "wood", 0.1]], 0.7)
		"nope":
			return _tones([[0.0, NOTE["B4"], 0.07, "felt", 0.22], [0.1, NOTE["F#4"], 0.14, "felt", 0.22]], 0.4)
		"bump":
			return _knock(take, 0.0, 60.0)
	return _tones([[0.0, NOTE["A5"], 0.05, "wood", 0.15]], 0.15)


## A few soft notes: each [start seconds, Hz, length, material, volume].
## Materials:
##   "wood"  - a marimba bar: a quick knock that rings briefly
##   "glass" - a chime: a long, clear ring with a faint shimmer
##   "felt"  - a soft mallet on a low string: round and muffled
## `bright` turns the overtones up or down a touch (for the varied takes).
## The whole thing goes through _soften at `cutoff` Hz to round off the top.
static func _tones(notes: Array, seconds: float, bright: float = 1.0, cutoff: float = 2400.0) -> AudioStreamWAV:
	var count := int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for note: Array in notes:
		var start := int(float(note[0]) * MIX_RATE)
		var hz: float = note[1]
		var length: float = maxf(note[2], 0.02)
		var material: String = note[3]
		var volume: float = note[4]
		for i in range(start, count):
			var t := float(i - start) / MIX_RATE
			var wave := 0.0
			var envelope := 0.0
			match material:
				"wood":
					# The bar's knock (its 4x overtone) dies fast, leaving a round tone.
					envelope = minf(t / 0.003, 1.0) * exp(-t * 3.0 / length)
					wave = sin(TAU * hz * t) + bright * 0.3 * sin(TAU * hz * 3.93 * t) * exp(-t * 60.0)
				"glass":
					# A slow-ish attack and a long ring; the out-of-tune overtone is the shimmer.
					envelope = minf(t / 0.006, 1.0) * exp(-t * 1.6 / length)
					wave = sin(TAU * hz * t) + bright * 0.18 * sin(TAU * hz * 2.76 * t) * exp(-t * 9.0) + 0.06 * sin(TAU * hz * 2.003 * t)
				_:
					# Felt: the softest attack and only a hint of overtone.
					envelope = minf(t / 0.01, 1.0) * exp(-t * 2.5 / length)
					wave = sin(TAU * hz * t) + bright * 0.2 * sin(TAU * hz * 2.0 * t) * exp(-t * 25.0)
			if envelope < 0.0005 and t > 0.02:
				break
			samples[i] += wave * envelope * volume
	_soften(samples, cutoff)
	return to_wav(samples, false)


## Rounds off the shrill top end: a gentle low-pass filter (run twice), like
## putting the speaker behind a cloth grille.
static func _soften(samples: PackedFloat32Array, cutoff: float) -> void:
	var k := 1.0 - exp(-TAU * cutoff / MIX_RATE)
	for pass_number in 2:
		var smooth := 0.0
		for i in samples.size():
			smooth += (samples[i] - smooth) * k
			samples[i] = smooth


## A rubber stamp coming down on a felt pad: a soft thud and a papery pat.
static func _stamp() -> AudioStreamWAV:
	var count := int(MIX_RATE * 1.1)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	var smooth := 0.0
	for i in mini(count, int(MIX_RATE * 0.2)):
		var t := float(i) / MIX_RATE
		smooth = lerpf(smooth, rng.randf_range(-1.0, 1.0), 0.15)
		var thud := sin(TAU * lerpf(160.0, 80.0, minf(t / 0.05, 1.0)) * t) * exp(-t * 30.0) * minf(t / 0.004, 1.0)
		samples[i] = tanh(thud * 0.9 + smooth * exp(-t * 50.0) * 0.9) * 0.5
	_soften(samples, 1800.0)
	return to_wav(samples, false)


## The relay tick of the nav computer locking in (a soft one).
static func _click(at: float) -> AudioStreamWAV:
	var count := int(MIX_RATE * 0.7)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var start := int(at * MIX_RATE)
	for i in range(start, mini(count, start + int(MIX_RATE * 0.04))):
		var t := float(i - start) / MIX_RATE
		samples[i] = sin(TAU * 1200.0 * t) * exp(-t * 150.0) * 0.18 + sin(TAU * 300.0 * t) * exp(-t * 80.0) * 0.12
	_soften(samples, 2000.0)
	return to_wav(samples, false)


## Coins dropping into a tray: a handful of quick glassy ticks, each on a
## note of the home key (so even the coins are in tune).
static func _coins() -> AudioStreamWAV:
	var count := int(MIX_RATE * 1.1)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 50
	var notes: Array[float] = [1318.51, 1479.98, 1108.73, 987.77, 1318.51]  # E6 F#6 C#6 B5 E6.
	for coin in notes.size():
		var start := int((coin * 0.035 + rng.randf_range(0.0, 0.015)) * MIX_RATE)
		var hz := notes[coin]
		for i in range(start, mini(count, start + int(MIX_RATE * 0.15))):
			var t := float(i - start) / MIX_RATE
			samples[i] += (sin(TAU * hz * t) + 0.25 * sin(TAU * hz * 2.4 * t) * exp(-t * 80.0)) * exp(-t * 35.0) * minf(t / 0.002, 1.0) * 0.07
	_soften(samples, 2400.0)
	return to_wav(samples, false)


## A door sliding: a short puff of soft air. `take` changes the puff a little.
static func _hiss(take: int = 0) -> AudioStreamWAV:
	var seconds := 0.5
	var count := int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9 + take * 31
	var smooth := 0.0
	var air := _pick([0.18, 0.14, 0.22], take)
	for i in count:
		var t := float(i) / MIX_RATE
		smooth = lerpf(smooth, rng.randf_range(-1.0, 1.0), air)
		var swell := minf(t / 0.04, 1.0) * exp(-t * 8.0)
		samples[i] = smooth * swell * 0.6
	_soften(samples, 1600.0)
	return to_wav(samples, false)


## One of three values, for take 0, 1 or 2.
static func _pick(values: Array[float], take: int) -> float:
	return values[clampi(take, 0, values.size() - 1)]


## A padded knock: a low, round thud with a little woody tap on top. `low`
## sets how deep it goes (Hz). `take` nudges the pitch for variety.
static func _knock(take: int, at: float, low: float) -> AudioStreamWAV:
	var seconds := 0.4
	var count := int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 21 + take
	var nudge := _pick([1.0, 0.9, 1.12], take)
	var smooth := 0.0
	var start := int(at * MIX_RATE)
	var phase := 0.0
	for i in range(start, count):
		var t := float(i - start) / MIX_RATE
		phase += TAU * lerpf(low * 2.2, low, minf(t / 0.06, 1.0)) * nudge / MIX_RATE
		smooth = lerpf(smooth, rng.randf_range(-1.0, 1.0), 0.2)
		var body := sin(phase) * exp(-t * 20.0) * minf(t / 0.003, 1.0)
		samples[i] = tanh(body * 0.9 + smooth * exp(-t * 70.0) * 0.5) * 0.55
	_soften(samples, 1500.0)
	return to_wav(samples, false)


## Two sounds played at once (the first sets the length).
static func _mix(a: AudioStreamWAV, b: AudioStreamWAV) -> AudioStreamWAV:
	var out := PackedFloat32Array()
	var a_bytes := a.data
	var b_bytes := b.data
	out.resize(floori(a_bytes.size() / 2.0))
	for i in out.size():
		var sample := a_bytes.decode_s16(i * 2) / 32767.0
		if i * 2 + 1 < b_bytes.size():
			sample += b_bytes.decode_s16(i * 2) / 32767.0
		out[i] = sample
	return to_wav(out, false)


## A short burst of radio static: hiss with crackles, swelling in and out.
## Plays before and after every comm call, and when you flip stations.
static func make_static() -> AudioStreamWAV:
	var seconds := 0.32
	var count := int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 104
	var smooth := 0.0
	for i in count:
		var t := float(i) / MIX_RATE
		# Hiss, softened a little so it's fuzzy rather than harsh.
		smooth = lerpf(smooth, rng.randf_range(-1.0, 1.0), 0.45)
		var crackle := rng.randf_range(-1.0, 1.0) if rng.randf() < 0.012 else 0.0
		# A wobbly whistle, like a dial passing a station.
		var whistle := sin(TAU * (900.0 + 500.0 * sin(t * 20.0)) * t) * 0.08
		var envelope := sin(PI * t / seconds)
		samples[i] = (smooth * 0.55 + crackle * 0.8 + whistle) * envelope * 0.8
	return to_wav(samples, false)


## The deep, throbbing rumble of a huge ship's engines. Loops seamlessly.
## Played from the big ship as it passes, with the Doppler effect, so it
## rises as it comes at you and drops away as it goes.
static func make_big_engine() -> AudioStreamWAV:
	var seconds := 2.0
	var count := int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 707
	var low := 0.0
	for i in count:
		var t := float(i) / MIX_RATE
		# Whole-number cycles per loop, so the loop is seamless.
		var drone := sin(TAU * 42.0 * t) + 0.6 * sin(TAU * 63.0 * t) + 0.3 * sin(TAU * 84.0 * t)
		var throb := 0.75 + 0.25 * sin(TAU * 2.0 * t)
		low = lerpf(low, rng.randf_range(-1.0, 1.0), 0.08)
		samples[i] = (drone * 0.35 * throb + low * 0.5) * 0.8
	return to_wav(samples, true)


## A space whale's song: a slow, wobbly glide up and back down.
static func make_whale_song() -> AudioStreamWAV:
	var seconds := 3.5
	var count := int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var phase := 0.0
	for i in count:
		var t := float(i) / MIX_RATE
		var glide := 170.0 + 260.0 * sin(PI * t / seconds) + 12.0 * sin(TAU * 5.0 * t)
		phase += TAU * glide / MIX_RATE
		var voice := sin(phase) + 0.4 * sin(phase * 2.0) + 0.15 * sin(phase * 3.01)
		var envelope := sin(PI * t / seconds)
		samples[i] = voice * envelope * 0.4
	return to_wav(samples, false)


## A soft rushing whoosh, for a comet streaking past.
static func make_whoosh() -> AudioStreamWAV:
	var seconds := 2.0
	var count := int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	var low := 0.0
	for i in count:
		var t := float(i) / MIX_RATE
		var openness := 0.03 + 0.25 * sin(PI * t / seconds)
		low = lerpf(low, rng.randf_range(-1.0, 1.0), openness)
		samples[i] = low * sin(PI * t / seconds) * 0.9
	return to_wav(samples, false)


## The "power on" chime for the intro: our own hello, in the spirit of
## the great startup sounds (a console's warm chord, a famous six-second
## piece by an ambient composer). A soft low breath, the game's motif
## (E - A - C#) on glass, then a warm A major add 9 chord that blooms in
## slowly and rings out, with one faint high sparkle on top. All in the
## home key, so it sets up every other sound in the game.
static func make_power_on() -> AudioStreamWAV:
	var seconds := 3.4
	var count := int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(count)
	# The motif: E5, A5, C#6, each a glass chime.
	var motif: Array[Array] = [[0.12, 659.26], [0.27, 880.0], [0.42, 1108.73]]
	# The chord: A major add 9 (A2 E3 A3 C#4 E4 B4), warm and wide.
	var chord: Array[float] = [110.0, 164.81, 220.0, 277.18, 329.63, 493.88]
	for i in count:
		var t := float(i) / MIX_RATE
		var sample := 0.0
		# The breath: a low A that swells in and fades, more felt than boom.
		sample += sin(TAU * 55.0 * t) * minf(t / 0.06, 1.0) * exp(-t * 4.0) * 0.35
		for note: Array in motif:
			var start: float = note[0]
			if t >= start:
				var nt := t - start
				var hz: float = note[1]
				sample += (sin(TAU * hz * nt) + 0.15 * sin(TAU * hz * 2.76 * nt) * exp(-nt * 9.0)) * minf(nt / 0.006, 1.0) * exp(-nt * 2.2) * 0.17
		if t >= 0.5:
			# The chord blooms in over a third of a second (no hard edge) and rings.
			var ct := t - 0.5
			var bloom := smoothstep(0.0, 0.35, ct) * exp(-ct * 0.75)
			for note in chord:
				# Each note slightly detuned against itself for a soft chorus shimmer.
				sample += (sin(TAU * note * ct) + 0.5 * sin(TAU * note * 1.003 * ct) + 0.15 * sin(TAU * note * 2.0 * ct)) * bloom * 0.065
		if t >= 0.85:
			# The sparkle: a quiet E6 glass ring above the chord.
			var st := t - 0.85
			sample += sin(TAU * 1318.51 * st) * minf(st / 0.01, 1.0) * exp(-st * 1.4) * 0.06
		# The last moments fade to nothing (no click at the end).
		samples[i] = tanh(sample * 1.1) * 0.8 * clampf((seconds - t) / 0.5, 0.0, 1.0)
	_soften(samples, 2600.0)
	return to_wav(samples, false)


## The "beep" of a power-on self test (POST). An old PC speaker made a
## harsh square wave; ours is a rounder A, still a beep but a friendly one.
static func make_post_beep() -> AudioStreamWAV:
	var seconds := 0.12
	var count := int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t := float(i) / MIX_RATE
		var tone := sin(TAU * 880.0 * t) + 0.2 * sin(TAU * 1760.0 * t)
		samples[i] = tone * 0.2 * minf(t / 0.004, 1.0) * clampf((seconds - t) / 0.02, 0.0, 1.0)
	_soften(samples, 2400.0)
	return to_wav(samples, false)


## A crate thumping against the walls of the cargo hold: a dull, woody knock.
static func make_thump() -> AudioStreamWAV:
	var seconds := 0.3
	var count := int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var low := 0.0
	for i in count:
		var t := float(i) / MIX_RATE
		var body := sin(TAU * lerpf(150.0, 70.0, minf(t / 0.08, 1.0)) * t) * exp(-t * 22.0)
		low = lerpf(low, rng.randf_range(-1.0, 1.0), 0.2)
		var knock := low * exp(-t * 60.0)
		samples[i] = tanh((body * 0.9 + knock * 0.8) * 1.5) * 0.8
	return to_wav(samples, false)


## The cab rattling on a rough ride: loose panels and a tool box buzzing.
## Loops; its volume follows how rough the ride is.
static func make_rattle() -> AudioStreamWAV:
	var seconds := 1.0
	var count := int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	for i in count:
		var t := float(i) / MIX_RATE
		# Fast irregular clicks: a few "loose things" tapping at their own rates.
		var clicks := 0.0
		for rate: float in [23.0, 31.0, 17.0]:
			var since := fposmod(t * rate, 1.0) / rate
			clicks += exp(-since * 400.0) * rng.randf_range(0.5, 1.0)
		var buzz := sin(TAU * 61.0 * t) * 0.15 * (0.5 + 0.5 * sin(TAU * 3.0 * t))
		samples[i] = clampf(clicks * 0.35 + buzz, -1.0, 1.0)
	return to_wav(samples, true)


## The boost spooling up: a rising turbine whine with a growl under it.
static func make_spool() -> AudioStreamWAV:
	var seconds := 1.3
	var count := int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var phase := 0.0
	var growl := 0.0
	for i in count:
		var t := float(i) / MIX_RATE
		var rise := t / seconds
		phase += TAU * lerpf(300.0, 1400.0, rise * rise) / MIX_RATE
		growl += TAU * lerpf(50.0, 110.0, rise) / MIX_RATE
		var envelope := minf(t / 0.1, 1.0) * clampf((seconds - t) / 0.08, 0.0, 1.0)
		samples[i] = (sin(phase) * 0.3 * rise + sin(growl) * 0.35 + sin(growl * 3.0) * 0.1) * envelope
	return to_wav(samples, false)


## The out-of-control alarm: a two-tone warble, like a klaxon in a cockpit
## that's about to have a very bad day. The one sound in the game that's
## meant to be sour: its two notes are a tritone apart (A5 and about D#5),
## the classic "something's wrong" interval. Still round and filtered, so it
## worries you without hurting your ears. Loops.
static func make_alarm() -> AudioStreamWAV:
	var seconds := 0.8
	var half := seconds * 0.5
	var count := int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t := float(i) / MIX_RATE
		# Whole cycles in each half (880 x 0.4 = 352, 625 x 0.4 = 250): a seamless loop.
		var pitch := 880.0 if t < half else 625.0
		var local := fmod(t, half)
		var phase := TAU * pitch * local
		# A soft triangle-ish tone (a few odd overtones, turned down).
		var tone := sin(phase) - sin(phase * 3.0) / 9.0 + sin(phase * 5.0) / 25.0
		var envelope := minf(local / 0.015, 1.0) * clampf((half - local) / 0.03, 0.0, 1.0)
		samples[i] = tone * envelope * 0.32
	return to_wav(samples, true)


## The rig blowing up: a sharp crack, a roaring wall of noise, and a long
## low rumble that rolls away.
static func make_explosion() -> AudioStreamWAV:
	var seconds := 2.8
	var count := int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	var low := 0.0
	var lower := 0.0
	for i in count:
		var t := float(i) / MIX_RATE
		var noise := rng.randf_range(-1.0, 1.0)
		low = lerpf(low, noise, 0.08)
		lower = lerpf(lower, low, 0.04)
		var crack := noise * exp(-t * 40.0)
		var roar := low * exp(-t * 2.2) * 2.5
		var rumble := lower * exp(-t * 0.9) * 6.0 + sin(TAU * lerpf(55.0, 30.0, minf(t, 1.0)) * t) * exp(-t * 1.6) * 0.6
		samples[i] = tanh((crack * 0.8 + roar + rumble) * 1.4) * 0.9
	return to_wav(samples, false)


## A big rig's two-tone air horn: two buzzy reeds a third apart, with a
## little wobble as the air comes up to pressure. "BWAAAMP."
static func make_horn() -> AudioStreamWAV:
	var seconds := 0.95
	var count := int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var smooth := 0.0
	for i in count:
		var t := float(i) / MIX_RATE
		var droop := 1.0 - 0.04 * exp(-t * 12.0)  # Flat for a moment, then up to pitch.
		var wave := 0.0
		for hz: float in [233.0, 294.0, 349.0]:
			var phase := fposmod(hz * droop * t + 0.002 * sin(TAU * 6.0 * t), 1.0)
			wave += (phase * 2.0 - 1.0) * 0.33  # A buzzy sawtooth reed.
		smooth = lerpf(smooth, wave, 0.25)  # Take the fizz off the top.
		var envelope := minf(t / 0.04, 1.0) * clampf((seconds - t) / 0.18, 0.0, 1.0)
		samples[i] = tanh(smooth * 2.2) * envelope * 0.55
	return to_wav(samples, false)


## Packs samples (-1 to 1) into a 16-bit audio stream.
static func to_wav(samples: PackedFloat32Array, looping: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = bytes
	if looping:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = samples.size()
	return wav
