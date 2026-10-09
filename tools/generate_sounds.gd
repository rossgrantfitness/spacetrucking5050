extends SceneTree
## Writes the game's made-from-math sounds as .wav files in
## res://audio/generated/:
##     engine_drone.wav, engine_whine.wav, engine_air.wav, engine_growl.wav
##         (the engine hum's four loops, from scenes/flight/EngineSynth.gd)
##     bonk.wav, blip.wav, static.wav, big_engine.wav, whale_song.wav, whoosh.wav,
##     power_on.wav, post_beep.wav, thump.wav, rattle.wav, spool.wav,
##     alarm.wav, explosion.wav, cue_horn.wav (the air horn upgrade)
##     docking_waltz.wav (the docking computer's music: scenes/common/MusicSynth.gd)
##     voice_square.wav, voice_reed.wav, voice_gruff.wav, voice_chirp.wav
##         (the other gibberish voices; "soft" is blip.wav)
##     cue_*.wav (menus, accepting a job, the nav computer, money, finding
##         things, notices, doors, the vending tray, the forklift: see
##         SfxSynth.make_cue; the busiest ones also get cue_*_2.wav and
##         cue_*_3.wav, slightly different takes so they never repeat exactly)
##         (a cartoon bump, a dialogue voice blip, a burst of radio static, a
##         big ship's engines, a space whale's song, a comet's whoosh, the
##         intro's power-on chime and self-test beep, a crate thumping in the
##         hold, the cab rattling, the boost spooling up, the out-of-control
##         alarm and the rig blowing up, from
##         scenes/common/SfxSynth.gd)
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/generate_sounds.gd
##
## Tip: click any of those files in the FileSystem dock to hear it in the
## Inspector. To use a real recorded engine sound instead, just replace a file
## with your own seamless loop (same name), or point EngineHum at a new file.
## The import settings next to each file (the engine loops: Loop Mode:
## Forward, no compression) are kept when you regenerate.


const OUTPUT_FOLDER: String = "res://audio/generated"


# _initialize runs once the game's scripts are fully ready.
func _initialize() -> void:
	var loops := {
		"engine_drone": EngineSynth.make_drone(),
		"engine_whine": EngineSynth.make_whine(),
		"engine_air": EngineSynth.make_air(),
		"engine_growl": EngineSynth.make_growl(),
		"bonk": SfxSynth.make_bonk(),
		"blip": SfxSynth.make_blip(),
		"static": SfxSynth.make_static(),
		"big_engine": SfxSynth.make_big_engine(),
		"whale_song": SfxSynth.make_whale_song(),
		"whoosh": SfxSynth.make_whoosh(),
		"power_on": SfxSynth.make_power_on(),
		"post_beep": SfxSynth.make_post_beep(),
		"thump": SfxSynth.make_thump(),
		"rattle": SfxSynth.make_rattle(),
		"spool": SfxSynth.make_spool(),
		"alarm": SfxSynth.make_alarm(),
		"explosion": SfxSynth.make_explosion(),
		"cue_horn": SfxSynth.make_horn(),
		"docking_waltz": MusicSynth.make_docking_waltz(),
	}
	for kind: String in ["square", "reed", "gruff", "chirp"]:
		loops["voice_" + kind] = SfxSynth.make_voice(kind)
	for cue: String in SfxSynth.CUES:
		loops["cue_" + cue] = SfxSynth.make_cue(cue)
		if cue in SfxSynth.VARIED_CUES:
			loops["cue_%s_2" % cue] = SfxSynth.make_cue(cue, 1)
			loops["cue_%s_3" % cue] = SfxSynth.make_cue(cue, 2)
	var failed := false
	for file_name: String in loops:
		var path := ProjectSettings.globalize_path(OUTPUT_FOLDER.path_join(file_name + ".wav"))
		var error := (loops[file_name] as AudioStreamWAV).save_to_wav(path)
		print("%s.wav: %s" % [file_name, error_string(error)])
		failed = failed or error != OK
	quit(1 if failed else 0)
