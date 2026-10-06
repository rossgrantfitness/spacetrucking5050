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
	for cue in ["ui_move", "ui_confirm", "ui_back", "job_accept", "course_set", "autopilot_off", "cash", "pickup", "notice", "door"]:
		check(ResourceLoader.exists("res://audio/generated/cue_%s.wav" % cue), "the %s sound should exist" % cue)
