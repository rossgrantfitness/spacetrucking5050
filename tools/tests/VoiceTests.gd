extends "res://tools/tests/TestSuite.gd"
## Checks for the gibberish voices (scenes/common/VoiceBlips.gd) and the
## little game sounds (autoload/Sfx.gd).


func test_voices_play_notes_in_their_key() -> void:
	var text := "Hello there, hon."
	var first := VoiceBlips.pitch_scale(1.0, 9, "major", text, 1)
	check(is_equal_approx(first, VoiceBlips.pitch_scale(1.0, 9, "major", text, 1)), "the same letter always plays the same note")
	# Every note lands on the scale: a whole number of semitones from the key.
	for i in text.length():
		var semitones := 12.0 * log(VoiceBlips.pitch_scale(1.0, 9, "major", text, i)) / log(2.0)
		check(absf(semitones - roundf(semitones)) < 0.01, "letter %d should be on a real note" % i)
	check(not is_equal_approx(first, VoiceBlips.pitch_scale(1.0, 2, "major", text, 1)), "a different key sounds different")
	var low := VoiceBlips.pitch_scale(0.5, 9, "minor", text, 1)
	var high := VoiceBlips.pitch_scale(1.9, 9, "minor", text, 1)
	check(high > low * 2.0, "squeaky voices are higher than deep ones")
	check(VoiceBlips.pitch_scale(1.0, 9, "major", "Really?", 6) > VoiceBlips.pitch_scale(1.0, 9, "major", "Really.", 6) * 0.99, "questions lift at the end")


func test_everyone_has_a_voice() -> void:
	for file_name in DirAccess.get_files_at("res://data/npcs"):
		if not file_name.ends_with(".tres"):
			continue
		var npc := load("res://data/npcs/" + file_name) as NPCData
		check(VoiceBlips.STREAMS.has(npc.voice_type), "%s needs a known voice type" % file_name)
		check(VoiceBlips.SCALES.has(npc.voice_scale), "%s needs a known scale" % file_name)


func test_every_cue_has_a_sound() -> void:
	for cue in SfxSynth.CUES:
		check(ResourceLoader.exists("res://audio/generated/cue_%s.wav" % cue), "the %s sound should exist" % cue)
	for cue in SfxSynth.VARIED_CUES:
		check(SfxSynth.CUES.has(cue), "%s is varied, so it should be a cue" % cue)
		check(Sfx.takes_of(cue).size() == 3, "the %s sound should have three takes" % cue)


## The "pleasant sounds" rules (SfxSynth.make_cue): no shrill highs, gentle
## starts, and nothing too loud.
func test_cues_are_gentle() -> void:
	for cue in SfxSynth.CUES:
		var samples := _samples(SfxSynth.make_cue(cue))
		# How much a sound changes sample to sample, against how loud it is:
		# a quick, rough measure of how much high treble it has. A pure note
		# at 1.8 kHz scores about 0.25; the old square-wave beeps scored 0.4-0.9.
		var energy := 0.0
		var change := 0.0
		var peak := 0.0
		for i in range(1, samples.size()):
			energy += samples[i] * samples[i]
			change += (samples[i] - samples[i - 1]) * (samples[i] - samples[i - 1])
			peak = maxf(peak, absf(samples[i]))
		check(energy > 0.0, "%s should make a sound" % cue)
		check(change / maxf(energy, 0.000001) < 0.2, "%s should have no shrill highs (scored %.2f)" % [cue, change / maxf(energy, 0.000001)])
		check(peak < 0.7, "%s should stay well under full volume (peak %.2f)" % [cue, peak])
		check(absf(samples[0]) < 0.05, "%s should start softly, not with a click" % cue)


func test_repeated_sounds_vary() -> void:
	var pitches := {}
	for i in 40:
		var pitch: float = Sfx.varied_pitch("notice")
		check(absf(1200.0 * log(pitch) / log(2.0)) <= Sfx.DRIFT_CENTS + 0.01, "a drift stays a hair, not out of tune")
	for i in 40:
		var cents := 1200.0 * log(Sfx.varied_pitch("ui_move")) / log(2.0)
		var step := roundi(cents / 100.0)
		check(absf(cents - step * 100.0) <= Sfx.DRIFT_CENTS + 0.01, "the menu tick wanders by whole notes")
		check((Sfx.WANDER["ui_move"] as Array).has(step), "the menu tick stays in the home key")
		pitches[step] = true
	check(pitches.size() > 1, "the menu tick shouldn't play the same note every time")


static func _samples(wav: AudioStreamWAV) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(floori(wav.data.size() / 2.0))
	for i in out.size():
		out[i] = wav.data.decode_s16(i * 2) / 32767.0
	return out
