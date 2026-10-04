extends SceneTree
## Makes the textures for the wider world (the Tidewater system and beyond),
## small and PS1-sized, into res://textures/generated/:
##     ocean_planet.png  - Tidewater's ocean world: teal seas, white cloud
##                         swirls, a few green islands
##     sun_surface.png   - a bright, boiling sun surface (tinted per sun)
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/generate_world_textures.gd
## (The older textures are made by generate_placeholder_textures.gd.)


const OUTPUT_FOLDER: String = "res://textures/generated"


func _init() -> void:
	var images := {
		"ocean_planet.png": _ocean_planet(256, 128),
		"sun_surface.png": _sun_surface(128, 64),
	}
	var failed := false
	for file_name: String in images:
		var error := (images[file_name] as Image).save_png(OUTPUT_FOLDER.path_join(file_name))
		print("%s: %s" % [file_name, error_string(error)])
		failed = failed or error != OK
	quit(1 if failed else 0)


func _ocean_planet(width: int, height: int) -> Image:
	var land := _noise(71, 0.55)
	var clouds := _noise(72, 0.75)
	var swirl := _noise(73, 0.6)
	var image := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	for y in height:
		var latitude := absf(float(y) / height - 0.5) * 2.0  # 0 at the equator, 1 at the poles.
		for x in width:
			# Sample on a circle so the left and right edges meet seamlessly.
			var angle := TAU * x / width
			var p := Vector3(cos(angle) * 1.6, sin(angle) * 1.6, y * 0.04)
			var deep := Color("0e5f7a").lerp(Color("1fb5b0"), 0.5 + 0.5 * land.get_noise_3dv(p * 0.7))
			var color := deep
			var ground := land.get_noise_3dv(p)
			if ground > 0.22:
				color = Color("5fd17a") if ground < 0.36 else Color("e8d9a0")  # Islands with beaches.
			var twist := swirl.get_noise_3dv(p) * 2.0
			var cloud := clouds.get_noise_3d(cos(angle + twist) * 2.0, sin(angle + twist) * 2.0, y * 0.06 + twist)
			if cloud > 0.1:
				color = color.lerp(Color(0.95, 0.98, 1.0), clampf((cloud - 0.1) * 3.0, 0.0, 0.85))
			if latitude > 0.86:
				color = color.lerp(Color(0.92, 0.97, 1.0), 0.85)  # Ice caps.
			image.set_pixel(x, y, color)
	return image


func _sun_surface(width: int, height: int) -> Image:
	var boil := _noise(81, 3.0)
	var image := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	for y in height:
		for x in width:
			var angle := TAU * x / width
			var heat := 0.5 + 0.5 * boil.get_noise_3d(cos(angle) * 2.0, sin(angle) * 2.0, y * 0.08)
			image.set_pixel(x, y, Color(1.0, 0.85, 0.6).lerp(Color(1.0, 1.0, 0.95), heat))
	return image


func _noise(seed_number: int, frequency: float) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = seed_number
	noise.frequency = frequency
	return noise
