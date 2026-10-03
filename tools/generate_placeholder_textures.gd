extends SceneTree
## Generates the small placeholder textures in res://textures/generated/.
## Run it from the project folder with:
##     godot --headless --path . -s tools/generate_placeholder_textures.gd
## (Running it again simply recreates the same images.)
##
## They're deliberately tiny (32 to 128 pixels), like real PS1 textures, and
## mostly gray: the models tint them with their own paint colors.


const OUTPUT_FOLDER: String = "res://textures/generated"
const HAZARD_YELLOW := Color("ffc21a")
const HAZARD_BLACK := Color("1c1a22")


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_FOLDER))
	var images := {
		"hazard_stripes.png": _hazard_stripes(32, 8),
		"hull_panels.png": _hull_panels(64),
		"vents.png": _vents(32),
		"rock.png": _rock(64),
		"station_windows.png": _station_windows(64),
		"planet_swirl.png": _planet_swirl(128, 64),
	}
	var failed := false
	for file_name: String in images:
		var error := (images[file_name] as Image).save_png(OUTPUT_FOLDER.path_join(file_name))
		print("%s: %s" % [file_name, error_string(error)])
		failed = failed or error != OK
	quit(1 if failed else 0)


## Diagonal yellow-and-black stripes that tile seamlessly (the image size must
## be a multiple of two stripe widths for the pattern to line up at the edges).
func _hazard_stripes(image_size: int, stripe_width: int) -> Image:
	var image := Image.create_empty(image_size, image_size, false, Image.FORMAT_RGBA8)
	for y in image_size:
		for x in image_size:
			var yellow := posmod(x + y, stripe_width * 2) < stripe_width
			image.set_pixel(x, y, HAZARD_YELLOW if yellow else HAZARD_BLACK)
	return image


## Light gray hull plating: a grid of panels, each a slightly different shade,
## with dark seams, little rivets in the corners and a bit of grime. It tiles
## seamlessly, and models tint it with their paint color.
func _hull_panels(image_size: int) -> Image:
	var rng := _rng(1)
	var grime := _noise(11, 0.12)
	var image := Image.create_empty(image_size, image_size, false, Image.FORMAT_RGBA8)
	var panel := 16  # Panel size in pixels.
	var shades := {}
	for y in image_size:
		for x in image_size:
			# Every other row of panels is offset by half, like brickwork.
			var row := floori(y / float(panel))
			var shifted_x := posmod(x + (panel >> 1 if row % 2 == 1 else 0), image_size)
			var cell := Vector2i(floori(shifted_x / float(panel)), row)
			if not shades.has(cell):
				shades[cell] = rng.randf_range(0.82, 1.0)
			var shade: float = shades[cell]
			var in_x := shifted_x % panel
			var in_y := y % panel
			if in_x == 0 or in_y == 0:
				shade = 0.5  # Seam.
			elif in_x == panel - 1 or in_y == panel - 1:
				shade *= 0.88  # Seam shadow.
			elif (in_x == 2 or in_x == panel - 3) and (in_y == 2 or in_y == panel - 3):
				shade *= 0.7  # Rivet.
			shade *= 0.92 + 0.08 * grime.get_noise_2d(x, y)
			image.set_pixel(x, y, Color(shade, shade, shade))
	return image


## Dark horizontal grille slats, for engine intakes and vents.
func _vents(image_size: int) -> Image:
	var image := Image.create_empty(image_size, image_size, false, Image.FORMAT_RGBA8)
	for y in image_size:
		var slat := y % 4
		var shade := [0.12, 0.35, 0.28, 0.18][slat] as float
		for x in image_size:
			image.set_pixel(x, y, Color(shade, shade, shade * 1.1))
	return image


## Speckled, cracked stone, light gray so each rock's color shows through.
func _rock(image_size: int) -> Image:
	var rng := _rng(3)
	var lumps := _noise(31, 0.09)
	var cracks := _noise(32, 0.05)
	cracks.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	var image := Image.create_empty(image_size, image_size, false, Image.FORMAT_RGBA8)
	for y in image_size:
		for x in image_size:
			var shade := 0.82 + 0.14 * lumps.get_noise_2d(x, y) + rng.randf_range(-0.06, 0.06)
			if cracks.get_noise_2d(x, y) > 0.62:
				shade *= 0.6
			image.set_pixel(x, y, Color(shade, shade * 0.98, shade * 0.95))
	return image


## A dark station wall with rows of little windows, most lit warm, some pink
## or cyan, a few dark (somebody's asleep). Used with "glow from texture" so
## only the lit windows shine.
func _station_windows(image_size: int) -> Image:
	var rng := _rng(4)
	var lit: Array[Color] = [Color(1.0, 0.8, 0.4), Color(1.0, 0.8, 0.4), Color(1.0, 0.7, 0.35), Color(1.0, 0.5, 0.75), Color(0.45, 0.95, 1.0)]
	var image := Image.create_empty(image_size, image_size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.07, 0.065, 0.1))
	for row in image_size >> 3:  # >> 3 = divided by 8, rounded down.
		for column in image_size >> 3:
			var color := Color(0.12, 0.11, 0.16)
			if rng.randf() < 0.75:
				color = lit[rng.randi_range(0, lit.size() - 1)]
			for y in range(row * 8 + 2, row * 8 + 6):
				for x in range(column * 8 + 1, column * 8 + 6):
					image.set_pixel(x, y, color)
	return image


## A big, bold, swirly gas giant: bands of candy colors, bent into swirls.
## It's wrapped around a sphere, so it tiles left to right.
func _planet_swirl(width: int, height: int) -> Image:
	var warp := _noise(51, 0.55)
	var bands: Array[Color] = [
		Color("f7a3c4"), Color("f6c27a"), Color("fbe3b0"), Color("e98a6f"),
		Color("c27ac9"), Color("f6c27a"), Color("8fd3d9"), Color("f7a3c4")]
	var image := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	for y in height:
		for x in width:
			# Sample the noise on a circle so the left and right edges match.
			var angle := TAU * x / width
			var wobble := warp.get_noise_3d(cos(angle) * 1.6, sin(angle) * 1.6, y * 0.06)
			var band := float(y) / height * bands.size() * 0.999 + wobble * 1.1
			band = clampf(band, 0.0, bands.size() - 1.001)
			var low := int(band)
			var color := bands[low].lerp(bands[low + 1], smoothstep(0.35, 0.65, band - low))
			image.set_pixel(x, y, color)
	return image


func _rng(seed_number: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5050 + seed_number
	return rng


func _noise(seed_number: int, frequency: float) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = seed_number
	noise.frequency = frequency
	return noise
