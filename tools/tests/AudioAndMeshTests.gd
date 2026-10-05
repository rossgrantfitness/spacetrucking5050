extends "res://tools/tests/TestSuite.gd"
## Checks for the M1 generated assets: the engine sound loops and the asteroid
## meshes.


const LOOP_FILES: Array[String] = [
	"res://audio/generated/engine_drone.wav",
	"res://audio/generated/engine_whine.wav",
	"res://audio/generated/engine_air.wav",
	"res://audio/generated/engine_growl.wav",
]


func test_engine_loops_are_seamless_and_not_silent() -> void:
	var loops: Array[AudioStreamWAV] = [
		EngineSynth.make_drone(), EngineSynth.make_whine(), EngineSynth.make_air(), EngineSynth.make_growl()]
	for wav in loops:
		var samples := _samples(wav)
		var biggest_step := 0
		var loudest := 0
		for i in samples.size() - 1:
			biggest_step = maxi(biggest_step, absi(samples[i + 1] - samples[i]))
			loudest = maxi(loudest, absi(samples[i]))
		var seam := absi(samples[0] - samples[samples.size() - 1])
		check(loudest > 3000, "an engine loop shouldn't be (nearly) silent")
		# A seamless loop's end-to-start jump is no bigger than an ordinary step.
		check(seam <= biggest_step * 1.5, "an engine loop has a click at its seam (%d vs %d)" % [seam, biggest_step])


func test_engine_loop_files_are_set_to_loop() -> void:
	for path in LOOP_FILES:
		var wav: AudioStreamWAV = load(path)
		check(wav != null, "missing sound file " + path)
		if wav != null:
			check(wav.loop_mode == AudioStreamWAV.LOOP_FORWARD, path + " should be imported with Loop Mode: Forward")
			check(wav.format == AudioStreamWAV.FORMAT_16_BITS, path + " should be imported uncompressed (16-bit)")


func test_rock_triangles_face_outward() -> void:
	var arrays := RockMesh.build(123).surface_get_arrays(0)
	var corners: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	check(corners.size() == 80 * 3, "a rock should have 80 triangles")
	var wrong_way := 0
	for i in range(0, corners.size(), 3):
		# Plane() works out which way a triangle faces from its corner order,
		# exactly like Godot decides which side of a triangle to draw.
		var facing := Plane(corners[i], corners[i + 1], corners[i + 2]).normal
		if facing.dot(normals[i]) <= 0.0:
			wrong_way += 1
	check(wrong_way == 0, "%d rock triangles face inward (they'd be invisible)" % wrong_way)


## The raw 16-bit samples inside a sound.
func _samples(wav: AudioStreamWAV) -> PackedInt32Array:
	var samples := PackedInt32Array()
	for i in range(0, wav.data.size(), 2):
		samples.append(wav.data.decode_s16(i))
	return samples


func test_sound_effects_and_voices_have_their_own_volume() -> void:
	check(AudioServer.get_bus_index(Settings.SFX_BUS) != -1 and AudioServer.get_bus_index(Settings.VOICE_BUS) != -1, "there are SFX and voice channels")
	check(Settings.sfx_volume < Settings.radio_volume or Settings.sfx_volume <= 0.7, "sound effects sit a bit under the music by default")
	var tree := Engine.get_main_loop() as SceneTree
	var player := AudioStreamPlayer.new()
	tree.root.add_child(player)
	check(player.bus == &"SFX", "a sound with nowhere in particular to go plays through the SFX channel")
	player.free()
	var music := AudioStreamPlayer.new()
	music.bus = &"Radio"
	tree.root.add_child(music)
	check(music.bus == &"Radio", "music stays on the music channel")
	music.free()
	var before := Settings.sfx_volume
	Settings.apply_saved_data({"sfx_volume": 0.25, "voice_volume": 0.5})
	check(is_equal_approx(Settings.sfx_volume, 0.25) and is_equal_approx(Settings.voice_volume, 0.5), "the volumes load from the settings file")
	check(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(Settings.SFX_BUS)) < -10.0, "turning sound effects down turns their channel down")
	Settings.apply_saved_data({"sfx_volume": before, "voice_volume": 0.9})
