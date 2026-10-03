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
