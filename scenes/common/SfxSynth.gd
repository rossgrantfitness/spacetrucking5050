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
##   gruff  - low and growly, with a little rasp (Digby, Wendell)
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


## Little game sounds (menus, jobs, the nav computer, money, doors). Each is
## a few short notes; see `_notes`.
##   ui_move     - a soft tick moving between menu buttons
##   ui_confirm  - a bright two-note "ba-ding" pressing a button
##   ui_back     - a two-note drop backing out of a menu
##   job_accept  - a rubber stamp "ka-chunk" and a happy little three-note run
##   course_set  - the nav computer: beep-beep-boop and a relay click
##   autopilot_off - the nav computer letting go: two falling beeps
##   cash        - coins and a register bell (getting paid, buying things)
##   pickup      - a sparkly little rise (finding something)
##   notice      - a soft two-note chime (something's up aboard)
##   door        - a short pneumatic hiss (doors between rooms)
static func make_cue(cue: String) -> AudioStreamWAV:
	match cue:
		"ui_move":
			return _notes([[0.0, 1760.0, 0.03, "square", 0.08]], 0.05)
		"ui_confirm":
			return _notes([[0.0, 988.0, 0.06, "square", 0.12], [0.06, 1319.0, 0.12, "square", 0.12]], 0.2)
		"ui_back":
			return _notes([[0.0, 880.0, 0.06, "square", 0.1], [0.06, 587.0, 0.1, "square", 0.1]], 0.18)
		"job_accept":
			return _mix(_stamp(), _notes([[0.12, 784.0, 0.1, "bell", 0.22], [0.22, 988.0, 0.1, "bell", 0.22], [0.32, 1319.0, 0.35, "bell", 0.25]], 0.75))
		"course_set":
			return _mix(_notes([[0.0, 1568.0, 0.07, "square", 0.1], [0.1, 1568.0, 0.07, "square", 0.1], [0.2, 2093.0, 0.18, "square", 0.11]], 0.5), _click(0.42))
		"autopilot_off":
			return _notes([[0.0, 1568.0, 0.08, "square", 0.1], [0.11, 1047.0, 0.16, "square", 0.1]], 0.32)
		"cash":
			return _mix(_coins(), _notes([[0.18, 2637.0, 0.5, "bell", 0.2], [0.18, 3520.0, 0.4, "bell", 0.1]], 0.8))
		"pickup":
			return _notes([[0.0, 1047.0, 0.06, "bell", 0.18], [0.05, 1319.0, 0.06, "bell", 0.18], [0.1, 1568.0, 0.06, "bell", 0.18], [0.15, 2093.0, 0.3, "bell", 0.2]], 0.5)
		"notice":
			return _notes([[0.0, 1175.0, 0.25, "bell", 0.16], [0.14, 1568.0, 0.45, "bell", 0.16]], 0.65)
		"door":
			return _hiss()
	return _notes([[0.0, 1000.0, 0.05, "square", 0.1]], 0.08)


## A few notes: each [start seconds, Hz, length, "square" or "bell", volume].
static func _notes(notes: Array, seconds: float) -> AudioStreamWAV:
	var count := int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for note: Array in notes:
		var start := int(float(note[0]) * MIX_RATE)
		var hz: float = note[1]
		var length: float = note[2]
		var volume: float = note[4]
		for i in range(start, mini(count, start + int((length + 0.3) * MIX_RATE))):
			var t := float(i - start) / MIX_RATE
			var wave := 0.0
			var envelope := minf(t / 0.003, 1.0)
			if note[3] == "bell":
				wave = sin(TAU * hz * t + 1.2 * sin(TAU * hz * 2.0 * t) * exp(-t * 8.0))
				envelope *= exp(-t * 3.0 / maxf(length, 0.05))
			else:
				wave = 1.0 if sin(TAU * hz * t) > 0.0 else -1.0
				envelope *= clampf((length - t) / 0.015, 0.0, 1.0)
			samples[i] += wave * envelope * volume
	return to_wav(samples, false)


## A rubber stamp coming down: a thud and a papery slap.
static func _stamp() -> AudioStreamWAV:
	var count := int(MIX_RATE * 0.75)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	var smooth := 0.0
	for i in mini(count, int(MIX_RATE * 0.2)):
		var t := float(i) / MIX_RATE
		smooth = lerpf(smooth, rng.randf_range(-1.0, 1.0), 0.3)
		var thud := sin(TAU * lerpf(180.0, 70.0, minf(t / 0.05, 1.0)) * t) * exp(-t * 30.0)
		samples[i] = tanh((thud * 0.9 + smooth * exp(-t * 45.0) * 1.2) * 1.3) * 0.7
	return to_wav(samples, false)


## The relay click of the nav computer locking in.
static func _click(at: float) -> AudioStreamWAV:
	var count := int(MIX_RATE * 0.5)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var start := int(at * MIX_RATE)
	for i in range(start, mini(count, start + int(MIX_RATE * 0.03))):
		var t := float(i - start) / MIX_RATE
		samples[i] = rng.randf_range(-1.0, 1.0) * exp(-t * 200.0) * 0.6
	return to_wav(samples, false)


## Coins tumbling into a tray: a handful of quick, bright metallic ticks.
static func _coins() -> AudioStreamWAV:
	var count := int(MIX_RATE * 0.8)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 50
	for coin in 7:
		var start := int(rng.randf_range(0.0, 0.2) * MIX_RATE)
		var hz := rng.randf_range(3000.0, 5200.0)
		for i in range(start, mini(count, start + int(MIX_RATE * 0.12))):
			var t := float(i - start) / MIX_RATE
			samples[i] += (sin(TAU * hz * t) + 0.5 * sin(TAU * hz * 1.5 * t)) * exp(-t * 40.0) * 0.12
	return to_wav(samples, false)


## A door sliding: a short puff of filtered air.
static func _hiss() -> AudioStreamWAV:
	var seconds := 0.45
	var count := int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var smooth := 0.0
	for i in count:
		var t := float(i) / MIX_RATE
		smooth = lerpf(smooth, rng.randf_range(-1.0, 1.0), 0.25)
		var swell := minf(t / 0.03, 1.0) * exp(-t * 7.0)
		samples[i] = smooth * swell * 0.45
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


## The "power on" chime for the intro: a soft whoomp, a sparkly little
## run of bell notes, then a big warm chord that rings out. Our own jingle,
## in the spirit of 90s consoles saying hello.
static func make_power_on() -> AudioStreamWAV:
	var seconds := 3.2
	var count := int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(count)
	# The sparkle: three quick bell notes (E6, B5, E6 up an octave-ish).
	var bells: Array[Array] = [[0.18, 1318.5], [0.30, 987.8], [0.42, 1975.5]]
	# The chord: A major add 9, warm and wide.
	var chord: Array[float] = [110.0, 164.8, 220.0, 277.2, 329.6, 493.9]
	for i in count:
		var t := float(i) / MIX_RATE
		var sample := 0.0
		# Whoomp: a low sine dropping in pitch.
		var whoomp_t := t
		sample += sin(TAU * lerpf(90.0, 40.0, minf(whoomp_t / 0.4, 1.0)) * whoomp_t) * exp(-whoomp_t * 5.0) * 0.5
		for bell: Array in bells:
			var start: float = bell[0]
			if t >= start:
				var bt := t - start
				var hz: float = bell[1]
				# A bell: a tone plus a slightly out-of-tune overtone (FM-ish shimmer).
				sample += (sin(TAU * hz * bt + 1.5 * sin(TAU * hz * 2.01 * bt) * exp(-bt * 6.0))) * exp(-bt * 4.5) * 0.22
		if t >= 0.55:
			var ct := t - 0.55
			var swell := minf(ct / 0.08, 1.0) * exp(-ct * 0.9)
			for note in chord:
				# Each note slightly detuned against itself for a chorus shimmer.
				sample += (sin(TAU * note * ct) + 0.5 * sin(TAU * note * 1.003 * ct) + 0.25 * sin(TAU * note * 2.0 * ct)) * swell * 0.07
		samples[i] = tanh(sample * 1.1) * 0.85
	return to_wav(samples, false)


## The PC-speaker style "beep" of a power-on self test (POST).
static func make_post_beep() -> AudioStreamWAV:
	var seconds := 0.12
	var count := int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t := float(i) / MIX_RATE
		var square := 1.0 if sin(TAU * 1000.0 * t) > 0.0 else -1.0
		samples[i] = square * 0.18 * clampf((seconds - t) / 0.01, 0.0, 1.0)
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


## The out-of-control alarm: a harsh two-tone warble, like a klaxon in a
## cockpit that's about to have a very bad day. Loops.
static func make_alarm() -> AudioStreamWAV:
	var seconds := 0.8
	var count := int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var phase := 0.0
	for i in count:
		var t := float(i) / MIX_RATE
		var pitch := 880.0 if t < seconds * 0.5 else 660.0
		phase += TAU * pitch / MIX_RATE
		var square := 1.0 if sin(phase) > 0.0 else -1.0
		samples[i] = (square * 0.6 + sin(phase * 0.5) * 0.4) * 0.35
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
