class_name EngineSynth
## Makes the engine's sound loops out of pure math, so the game needs no audio
## files for its engine. Each loop is exactly 2 seconds long and repeats
## seamlessly. EngineHum plays them all at once and bends their pitch and
## volume to follow the ship.
##
## The layers:
##   drone - a deep note plus a few harmonics, and a slightly out-of-tune twin
##           of the low note for a slow, warm "wah-wah" (a 0.5 Hz beat)
##   whine - a faint turbine tone, three octaves above the drone
##   air   - soft filtered noise, the "whoosh" of speed
##   growl - a gritty buzz for boosting
##
## The trick that makes the loops seamless: every tone completes a whole
## number of cycles in 2 seconds (55 Hz x 2 s = 110 cycles, 55.5 Hz x 2 s =
## 111 cycles...), so the end of each loop flows straight into its start.


## Samples per second. Low, rumbly sounds don't need more than this.
const MIX_RATE: int = 22050
## Loop length in seconds.
const LOOP_SECONDS: float = 2.0
## The drone's lowest note at pitch 1.0, in Hz (an A, two octaves below the A
## musicians tune to). Laptop speakers mostly play its harmonics, and that's fine.
const BASE_FREQUENCY: float = 55.0


static func make_drone() -> AudioStreamWAV:
	return _loop(func(t: float) -> float:
		var hum := sin(TAU * BASE_FREQUENCY * t) * 0.45 \
				+ sin(TAU * (BASE_FREQUENCY + 0.5) * t) * 0.35 \
				+ sin(TAU * BASE_FREQUENCY * 2.0 * t) * 0.3 \
				+ sin(TAU * BASE_FREQUENCY * 3.0 * t) * 0.15
		# Soft clipping: rounds off the loudest peaks so it never sounds harsh.
		return tanh(hum * 0.9) * 0.95)


static func make_whine() -> AudioStreamWAV:
	return _loop(func(t: float) -> float:
		return sin(TAU * BASE_FREQUENCY * 8.0 * t) * 0.5)


static func make_growl() -> AudioStreamWAV:
	# A soft sawtooth built from its first 12 harmonics (a raw sawtooth would
	# sound fizzy), one and a half times the drone's note.
	return _loop(func(t: float) -> float:
		var buzz := 0.0
		for harmonic in range(1, 13):
			buzz += sin(TAU * BASE_FREQUENCY * 1.5 * harmonic * t) / harmonic
		return buzz * 0.4)


static func make_air() -> AudioStreamWAV:
	# White noise, smoothed by a simple filter so it sounds like rushing air.
	# Noise has no cycles to line up, so instead the last bit of the loop is
	# blended into the first bit to hide the seam.
	var count := int(MIX_RATE * LOOP_SECONDS)
	var blend := int(MIX_RATE * 0.1)  # 0.1 seconds of overlap.
	var rng := RandomNumberGenerator.new()
	rng.seed = 5050
	var noise := PackedFloat32Array()
	noise.resize(count + blend)
	var smooth := 0.0
	for i in noise.size():
		smooth += (rng.randf_range(-1.0, 1.0) - smooth) * 0.12
		noise[i] = smooth * 2.5
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		samples[i] = noise[i]
		if i < blend:
			var mix := float(i) / blend
			samples[i] = noise[i] * mix + noise[count + i] * (1.0 - mix)
	return _to_wav(samples)


## Fills a 2-second loop by asking `wave` for the sound at each moment.
static func _loop(wave: Callable) -> AudioStreamWAV:
	var count := int(MIX_RATE * LOOP_SECONDS)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		samples[i] = wave.call(float(i) / MIX_RATE)
	return _to_wav(samples)


## Packs samples (-1 to 1) into a looping 16-bit audio stream.
static func _to_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = bytes
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = samples.size()
	return wav
