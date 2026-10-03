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
