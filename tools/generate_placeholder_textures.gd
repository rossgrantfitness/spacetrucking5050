extends SceneTree
## Generates the small placeholder textures in res://textures/generated/.
## Run it from the project folder with:
##     godot --headless --path . -s tools/generate_placeholder_textures.gd
## (Running it again simply recreates the same images.)
##
## They're small (32 to 256 pixels), like late PS1 textures, and mostly gray:
## the models tint them with their own paint colors.
##
## The hand-painted surface textures (walls, floors, hulls, containers,
## doors, wood, carpet, machinery...) are painted by tools/paint_textures.gd.


const OUTPUT_FOLDER: String = "res://textures/generated"
const HAZARD_YELLOW := Color("ffc21a")
const HAZARD_BLACK := Color("1c1a22")
const Letters := preload("res://scenes/ui/PixelFont.gd")
## The MML / MGS painter for rocks and planets (flat tones, dither, light
## painted in).
const Paint := preload("res://tools/texture_paint.gd")


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_FOLDER))
	var images := {
		"hazard_stripes.png": _hazard_stripes(32, 8),
		"chevrons.png": _chevrons(64, 32),
		"flare.png": _flare(64),
		"puff.png": _puff(32),
		"fuzz.png": _fuzz(32),
		"photo.png": _photo(),
		"blanket.png": _blanket(64),
		"space_view.png": _space_view(256, 128),
		"job_board.png": _job_board(),
		"terminal.png": _terminal(),
		"nebula.png": _nebula(256, 128),
		"rock.png": Paint.rock(128, 3),
		"station_windows.png": _station_windows(64),
		"planet_swirl.png": Paint.paint_pass(_planet_swirl(256, 128), 6),
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


## White chevron arrows on dark, like racing-track barriers.
func _chevrons(width: int, height: int) -> Image:
	var image := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.1, 0.09, 0.14))
	for y in height:
		var bend := absi(y - (height >> 1))
		for x in width:
			var along := posmod(x - bend, 32)
			if along >= 6 and along < 16:
				image.set_pixel(x, y, Color(0.95, 0.93, 0.85))
	return image


## A four-pointed star glow, for the lens flares on engines (late-90s style).
func _flare(image_size: int) -> Image:
	var image := Image.create_empty(image_size, image_size, false, Image.FORMAT_RGBA8)
	var half := image_size * 0.5
	for y in image_size:
		for x in image_size:
			var dx := absf(x + 0.5 - half) / half
			var dy := absf(y + 0.5 - half) / half
			var core := exp(-(dx * dx + dy * dy) * 18.0)
			var streaks := exp(-dy * 40.0) * (1.0 - dx) + exp(-dx * 40.0) * (1.0 - dy)
			var glow := clampf(core + streaks * 0.8 + exp(-(dx * dx + dy * dy) * 4.0) * 0.25, 0.0, 1.0)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, glow))
	return image


## A soft, slightly lumpy round puff, for smoke. White, so particles can tint
## it; see-through at the edges.
func _puff(image_size: int) -> Image:
	var lumps := _noise(71, 0.25)
	var image := Image.create_empty(image_size, image_size, false, Image.FORMAT_RGBA8)
	var half := image_size * 0.5
	for y in image_size:
		for x in image_size:
			var distance := Vector2(x + 0.5 - half, y + 0.5 - half).length() / half
			var edge := 0.75 + 0.2 * lumps.get_noise_2d(x, y)
			var alpha := clampf((edge - distance) / 0.35, 0.0, 1.0)
			var shade := 0.85 + 0.15 * lumps.get_noise_2d(x + 40, y)
			image.set_pixel(x, y, Color(shade, shade, shade, alpha))
	return image


## Fuzzy faux fur, for pink steering-wheel covers and fuzzy dice. Light, so
## the paint color tints it.
func _fuzz(image_size: int) -> Image:
	var rng := _rng(8)
	var image := Image.create_empty(image_size, image_size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.82, 0.82, 0.82))
	# Lots of tiny diagonal strands, light and dark.
	for strand in 160:
		var start := Vector2i(rng.randi_range(0, image_size - 1), rng.randi_range(0, image_size - 1))
		var shade := rng.randf_range(0.6, 1.0)
		for step in rng.randi_range(2, 4):
			image.set_pixel((start.x + step) % image_size, (start.y + step) % image_size, Color(shade, shade, shade))
	return image


## A tiny faded snapshot taped to the dash: two figures under a pink sky,
## one with long bunny ears. (Somebody she misses.)
func _photo() -> Image:
	var image := Image.create_empty(24, 30, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.95, 0.93, 0.88))  # The white instant-photo border.
	for y in range(2, 22):
		var sky := Color(0.98, 0.7, 0.75).lerp(Color(0.55, 0.45, 0.75), y / 22.0)
		for x in range(2, 22):
			image.set_pixel(x, y, sky)
	var figure := Color(0.25, 0.2, 0.3)
	image.fill_rect(Rect2i(6, 12, 4, 10), figure)  # Her, with ears.
	image.fill_rect(Rect2i(6, 7, 1, 5), figure)
	image.fill_rect(Rect2i(9, 7, 1, 5), figure)
	image.fill_rect(Rect2i(13, 10, 5, 12), figure)  # Him, a bit taller.
	image.fill_rect(Rect2i(14, 8, 3, 2), figure)
	return image


## A cozy blanket: wavy zigzag stripes in warm colors (like the sketch's rug).
func _blanket(image_size: int) -> Image:
	var stripes: Array[Color] = [Color("e8735a"), Color("f2c75c"), Color("5aa9a0"), Color("f4e9d8"), Color("8a5aa6")]
	var image := Image.create_empty(image_size, image_size, false, Image.FORMAT_RGBA8)
	for y in image_size:
		for x in image_size:
			var wave := absi((x % 16) - 8)
			var band := posmod(floori((y + wave) / 8.0), stripes.size())
			image.set_pixel(x, y, stripes[band])
	return image


## The view out of a window: deep space, stars, a nebula and a big planet.
func _space_view(width: int, height: int) -> Image:
	var rng := _rng(30)
	var clouds := _noise(31, 0.02)
	var image := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	for y in height:
		for x in width:
			var gas := clampf(clouds.get_noise_2d(x, y) * 0.8 + 0.2, 0.0, 1.0)
			image.set_pixel(x, y, Color(0.02, 0.02, 0.06).lerp(Color(0.45, 0.25, 0.6), gas * 0.6))
	for star in 220:
		var bright := rng.randf_range(0.5, 1.0)
		image.set_pixel(rng.randi_range(0, width - 1), rng.randi_range(0, height - 1), Color(bright, bright, bright * 1.05))
	var planet := Vector2(width * 0.72, height * 0.7)
	for y in height:
		for x in width:
			var distance := Vector2(x, y).distance_to(planet)
			if distance < 34.0:
				var band := sin(y * 0.4 + sin(x * 0.1) * 2.0) * 0.5 + 0.5
				var color := Color("f6c27a").lerp(Color("e98a6f"), band)
				var shade := clampf(1.2 - (x - planet.x + 20.0) / 60.0, 0.25, 1.0)  # Lit from the left.
				image.set_pixel(x, y, color * shade)
	return image


## A corkboard covered in pinned job notes.
func _job_board() -> Image:
	var rng := _rng(32)
	var image := Image.create_empty(128, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 128:
			var shade := 0.6 + rng.randf_range(-0.06, 0.06)
			image.set_pixel(x, y, Color(shade, shade * 0.72, shade * 0.45))
	var notes: Array[Color] = [Color(1, 0.95, 0.6), Color(0.95, 0.95, 0.95), Color(0.7, 0.9, 1.0), Color(1.0, 0.75, 0.8)]
	for i in 9:
		var corner := Vector2i(6 + (i % 5) * 24 + rng.randi_range(-2, 2), 6 + floori(i / 5.0) * 30 + rng.randi_range(-2, 2))
		image.fill_rect(Rect2i(corner, Vector2i(18, 22)), notes[i % notes.size()])
		for line in 4:
			image.fill_rect(Rect2i(corner + Vector2i(3, 5 + line * 4), Vector2i(rng.randi_range(6, 12), 1)), Color(0.3, 0.3, 0.4))
		image.fill_rect(Rect2i(corner + Vector2i(8, 1), Vector2i(2, 2)), Color(0.9, 0.2, 0.2))  # Pin.
	Letters.stamp(image, Vector2i(42, 58), "JOBS", 1, Color(0.2, 0.15, 0.1))
	return image


## A green computer terminal screen full of text.
func _terminal() -> Image:
	var rng := _rng(33)
	var image := Image.create_empty(64, 48, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.02, 0.08, 0.04))
	for line in 9:
		var x := 3
		while x < 58:
			var word := rng.randi_range(2, 7)
			image.fill_rect(Rect2i(x, 3 + line * 5, mini(word, 60 - x), 2), Color(0.4, 1.0, 0.5))
			x += word + 2
	return image


## Soft clouds of space gas, wrapped around the sky (tiles left to right).
## Grayscale: the sky shader tints it with the solar system's color.
func _nebula(width: int, height: int) -> Image:
	var clouds := _noise(61, 0.9)
	clouds.fractal_octaves = 5
	var band := _noise(62, 0.5)
	var image := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	for y in height:
		var latitude := (float(y) / height - 0.5) * PI
		for x in width:
			var angle := TAU * x / width
			var point := Vector3(cos(angle) * cos(latitude), sin(latitude), sin(angle) * cos(latitude)) * 1.5
			# Thickest in a wavy band across the sky, like a galaxy's arm.
			var arm := 1.0 - absf(sin(latitude) - band.get_noise_3dv(point) * 0.5) * 1.6
			var amount := clampf((clouds.get_noise_3dv(point) * 0.5 + 0.5) * arm, 0.0, 1.0)
			amount = amount * amount
			image.set_pixel(x, y, Color(amount, amount, amount))
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


## A big, bold, swirly gas giant: bands of candy colors, bent into swirls,
## with a big storm spot. It's wrapped around a sphere, so it tiles left to
## right.
func _planet_swirl(width: int, height: int) -> Image:
	var warp := _noise(51, 0.5)
	var fine := _noise(52, 2.0)
	var bands: Array[Color] = [
		Color("f7a3c4"), Color("f6c27a"), Color("fbe3b0"), Color("e98a6f"),
		Color("c27ac9"), Color("f6c27a"), Color("8fd3d9"), Color("f7a3c4")]
	var storm := Vector2(width * 0.3, height * 0.62)
	var image := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	for y in height:
		for x in width:
			# Sample the noise on a circle so the left and right edges match.
			var angle := TAU * x / width
			var wobble := warp.get_noise_3d(cos(angle) * 1.6, sin(angle) * 1.6, y * 0.03)
			wobble += fine.get_noise_3d(cos(angle) * 2.0, sin(angle) * 2.0, y * 0.05) * 0.15
			# Swirl the bands around the storm.
			var to_storm := Vector2(x, y) - storm
			var swirl := exp(-to_storm.length_squared() / 160.0) * 1.4
			var band := float(y) / height * bands.size() * 0.999 + wobble * 0.9 + swirl * sin(to_storm.angle() * 2.0)
			band = clampf(band, 0.0, bands.size() - 1.001)
			var low := int(band)
			var color := bands[low].lerp(bands[low + 1], smoothstep(0.3, 0.7, band - low))
			if to_storm.length() < 7.0:
				color = color.lerp(Color("d9534f"), 0.6)
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
