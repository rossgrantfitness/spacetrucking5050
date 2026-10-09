extends SceneTree
## Makes the textures for the wider world (the Tidewater system and beyond),
## small and PS1-sized, into res://textures/generated/:
##     ocean_planet.png  - Tidewater's ocean world: teal seas, white cloud
##                         swirls, a few green islands
##     sun_surface.png   - a bright, boiling sun surface (tinted per sun)
##     glimmer_planet.png - the Glimmer System's gas giant: bands of magenta
##                         and violet, swirly storms, glittering specks
##     moon_craters.png  - a pockmarked gray moon (tinted per moon)
##     desert_planet.png - the Dustbowl's desert world: amber dunes in
##                         wavy bands, dry canyons, a dust storm or two
##     jungle_planet.png - Greenhouse Reach's garden world: deep greens,
##                         blue lakes, flower-pink meadows, wispy clouds
##     ice_planet.png    - the Frostline's frozen world: lavender and white
##                         ice sheets, blue cracks, snowy swirls
## All painted MML / MGS style: a few flat tones per color, dithered where
## they meet, light painted in (see tools/texture_paint.gd).
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/generate_world_textures.gd
## (The older textures are made by generate_placeholder_textures.gd.)


const OUTPUT_FOLDER: String = "res://textures/generated"
const Paint := preload("res://tools/texture_paint.gd")


func _init() -> void:
	var images := {
		"ocean_planet.png": Paint.paint_pass(_ocean_planet(256, 128), 6),
		"sun_surface.png": Paint.paint_pass(_sun_surface(128, 64), 5, 1.0),
		"glimmer_planet.png": Paint.paint_pass(_glimmer_planet(256, 128), 6),
		"moon_craters.png": Paint.moon(256, 128, 77),
		"desert_planet.png": Paint.paint_pass(_desert_planet(256, 128), 6),
		"jungle_planet.png": Paint.paint_pass(_jungle_planet(256, 128), 6),
		"ice_planet.png": Paint.paint_pass(_ice_planet(256, 128), 6),
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


func _glimmer_planet(width: int, height: int) -> Image:
	var bands := _noise(91, 0.9)
	var swirl := _noise(92, 0.7)
	var sparkle := _noise(93, 6.0)
	var image := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	var colors: Array[Color] = [Color("5a1a6e"), Color("c0287e"), Color("ff5fb4"), Color("8a3ad0"), Color("ffb3e0")]
	for y in height:
		for x in width:
			var angle := TAU * x / width
			var p := Vector3(cos(angle) * 1.6, sin(angle) * 1.6, y * 0.04)
			# Bands that wobble, pushed around by swirls (like a gas giant).
			var twist := swirl.get_noise_3dv(p) * 3.0
			var band := float(y) / height * 7.0 + twist + bands.get_noise_3dv(p * 0.5) * 1.5
			var index := posmod(int(floor(band)), colors.size())
			var color: Color = colors[index].lerp(colors[(index + 1) % colors.size()], band - floor(band))
			if sparkle.get_noise_3dv(p * 2.0) > 0.55:
				color = color.lerp(Color("ffe08a"), 0.7)  # City lights? Casinos. Definitely casinos.
			image.set_pixel(x, y, color)
	return image


func _desert_planet(width: int, height: int) -> Image:
	var dunes := _noise(101, 0.8)
	var canyons := _noise(102, 0.6)
	var storm := _noise(103, 0.5)
	var image := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	var sands: Array[Color] = [Color("8a4a1c"), Color("c8782a"), Color("f0a640"), Color("ffd27a"), Color("d98a3a")]
	for y in height:
		for x in width:
			var angle := TAU * x / width
			var p := Vector3(cos(angle) * 1.6, sin(angle) * 1.6, y * 0.04)
			# Wavy dune bands, like wind-combed sand seen from orbit.
			var band := float(y) / height * 5.0 + dunes.get_noise_3dv(p) * 2.2
			var index := posmod(int(floor(band)), sands.size())
			var color: Color = sands[index].lerp(sands[(index + 1) % sands.size()], band - floor(band))
			if absf(canyons.get_noise_3dv(p)) < 0.02:
				color = Color("5a2a14")  # Dry canyons.
			var dust := storm.get_noise_3dv(p * 0.8)
			if dust > 0.25:
				color = color.lerp(Color("ffe2b0"), clampf((dust - 0.25) * 2.5, 0.0, 0.7))  # Dust storms.
			image.set_pixel(x, y, color)
	return image


func _jungle_planet(width: int, height: int) -> Image:
	var land := _noise(111, 0.6)
	var meadows := _noise(112, 1.0)
	var clouds := _noise(113, 0.8)
	var image := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	for y in height:
		var latitude := absf(float(y) / height - 0.5) * 2.0
		for x in width:
			var angle := TAU * x / width
			var p := Vector3(cos(angle) * 1.6, sin(angle) * 1.6, y * 0.04)
			var ground := land.get_noise_3dv(p)
			var color := Color("1d6b3a").lerp(Color("7fd84a"), clampf(0.5 + ground * 1.4, 0.0, 1.0))
			if ground < -0.25:
				color = Color("2a8fd0")  # Lakes.
			elif meadows.get_noise_3dv(p) > 0.32:
				color = Color("ff8fc8")  # Flower meadows, visible from space.
			if latitude > 0.8:
				color = color.lerp(Color("b8f0a8"), 0.6)  # Pale moss at the poles.
			var cloud := clouds.get_noise_3d(cos(angle) * 2.0, sin(angle) * 2.0, y * 0.07)
			if cloud > 0.2:
				color = color.lerp(Color(0.95, 1.0, 0.95), clampf((cloud - 0.2) * 3.0, 0.0, 0.75))
			image.set_pixel(x, y, color)
	return image


func _ice_planet(width: int, height: int) -> Image:
	var sheets := _noise(121, 0.7)
	var cracks := _noise(122, 1.0)
	var swirl := _noise(123, 0.6)
	var image := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	for y in height:
		for x in width:
			var angle := TAU * x / width
			var p := Vector3(cos(angle) * 1.6, sin(angle) * 1.6, y * 0.04)
			var color := Color("8a78d0").lerp(Color("eae6ff"), 0.5 + 0.5 * sheets.get_noise_3dv(p))
			if absf(cracks.get_noise_3dv(p)) < 0.022:
				color = Color("5ac8ff")  # Blue cracks in the ice.
			var twist := swirl.get_noise_3dv(p) * 2.0
			var snow := swirl.get_noise_3d(cos(angle + twist) * 2.0, sin(angle + twist) * 2.0, y * 0.06)
			if snow > 0.15:
				color = color.lerp(Color(1.0, 1.0, 1.0), clampf((snow - 0.15) * 3.0, 0.0, 0.8))
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
