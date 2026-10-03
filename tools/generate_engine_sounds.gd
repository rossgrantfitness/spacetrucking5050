extends SceneTree
## Writes the engine hum's four sound loops (made from pure math by
## scenes/flight/EngineSynth.gd) as .wav files in res://audio/generated/:
##     engine_drone.wav, engine_whine.wav, engine_air.wav, engine_growl.wav
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/generate_engine_sounds.gd
##
## Tip: click any of those files in the FileSystem dock to hear it in the
## Inspector. To use a real recorded engine sound instead, just replace a file
## with your own seamless loop (same name), or point EngineHum at a new file.
## The import settings next to each file (Loop Mode: Forward, no compression)
## are kept when you regenerate.


const OUTPUT_FOLDER: String = "res://audio/generated"


# _initialize runs once the game's scripts are fully ready.
func _initialize() -> void:
	var loops := {
		"engine_drone": EngineSynth.make_drone(),
		"engine_whine": EngineSynth.make_whine(),
		"engine_air": EngineSynth.make_air(),
		"engine_growl": EngineSynth.make_growl(),
	}
	var failed := false
	for file_name: String in loops:
		var path := ProjectSettings.globalize_path(OUTPUT_FOLDER.path_join(file_name + ".wav"))
		var error := (loops[file_name] as AudioStreamWAV).save_to_wav(path)
		print("%s.wav: %s" % [file_name, error_string(error)])
		failed = failed or error != OK
	quit(1 if failed else 0)
