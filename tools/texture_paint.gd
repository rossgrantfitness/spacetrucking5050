extends RefCounted
## Painting helpers for the space textures (rocks, moons and planets), in
## the Mega Man Legends / Metal Gear Solid style: a few flat, hand-picked
## tones per color instead of smooth gradients, the steps between them
## broken up with an ordered dither (the PS1's own trick), light from the
## top left painted right in, cool shadows and warm highlights.
##
## Used by tools/generate_placeholder_textures.gd and
## tools/generate_world_textures.gd (preload this file; it has no class
## name, so it stays out of the game).


## The PS1's ordered dither pattern (4 x 4), as fractions from 0 to 1.
const BAYER := [
	[0.0, 8.0, 2.0, 10.0], [12.0, 4.0, 14.0, 6.0],
	[3.0, 11.0, 1.0, 9.0], [15.0, 7.0, 13.0, 5.0]]


## Squashes an image's smooth shading into `levels` flat tones per color
## (dithered where they meet), and pushes the saturation up a little:
## the painted, posterized look. Hue is kept.
static func paint_pass(image: Image, levels: int = 6, saturation_boost: float = 1.12) -> Image:
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			var threshold: float = (BAYER[y % 4][x % 4] + 0.5) / 16.0 - 0.5
			var value := floorf(c.v * (levels - 1) + 0.5 + threshold * 0.9) / (levels - 1)
			var saturation := floorf(minf(c.s * saturation_boost, 1.0) * 4.0 + 0.5 + threshold * 0.5) / 4.0
			var painted := Color.from_hsv(c.h, clampf(saturation, 0.0, 1.0), clampf(value, 0.0, 1.0), c.a)
			image.set_pixel(x, y, warm_cool(painted, value))
	return image


## Shadows lean cool (blue-purple), highlights lean warm (yellow).
static func warm_cool(c: Color, light: float) -> Color:
	if light < 0.5:
		return c.lerp(Color(c.r * 0.85, c.g * 0.88, c.b * 1.12), (0.5 - light) * 1.2)
	return c.lerp(Color(minf(c.r * 1.05, 1.0), minf(c.g * 1.02, 1.0), c.b * 0.9), (light - 0.5) * 0.8)


## Faceted, chiselled stone (seamless, light and nearly neutral, so each
## rock's own color shows through): flat-shaded facets, each lit or shaded
## by its own angle to the light, with a bright edge on the top left of
## every facet, dark crevices between them, hairline cracks and a few pits.
static func rock(size: int, seed_number: int) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_number
	var sites: Array[Vector2] = []
	var tones: Array[float] = []
	for i in 22:
		sites.append(Vector2(rng.randf() * size, rng.randf() * size))
		# Each facet faces a different way: some catch the light, some don't.
		tones.append(rng.randf_range(0.62, 1.0))
	var cell := PackedInt32Array()
	cell.resize(size * size)
	var edge := PackedFloat32Array()
	edge.resize(size * size)
	for y in size:
		for x in size:
			var best := INF
			var second := INF
			var owner := 0
			for i in sites.size():
				var d := _wrapped(Vector2(x, y), sites[i], size)
				if d < best:
					second = best
					best = d
					owner = i
				elif d < second:
					second = d
			cell[y * size + x] = owner
			edge[y * size + x] = second - best
	var cracks := FastNoiseLite.new()
	cracks.seed = seed_number + 1
	cracks.frequency = 0.045
	cracks.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	var image := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var base := Color(0.86, 0.83, 0.8)
	for y in size:
		for x in size:
			var here := cell[y * size + x]
			var light := tones[here]
			# The facet's top-left edge catches the light; its bottom-right
			# edge falls into shadow; right on the seam is a dark crevice.
			if cell[posmod(y - 1, size) * size + posmod(x - 1, size)] != here:
				light *= 1.28
			elif cell[posmod(y + 1, size) * size + posmod(x + 1, size)] != here:
				light *= 0.7
			if edge[y * size + x] < 0.9:
				light *= 0.42
			# Hairline cracks: a dark line with a lit lip just below-right.
			if cracks.get_noise_2d(x, y) > 0.72:
				light *= 0.55
			elif cracks.get_noise_2d(x - 1, y - 1) > 0.72:
				light *= 1.15
			light += rng.randf_range(-0.04, 0.04)  # Grit.
			image.set_pixel(x, y, Color(base.r * light, base.g * light, base.b * light))
	for i in 7:
		_pit(image, Vector2(rng.randf() * size, rng.randf() * size), rng.randf_range(1.5, 3.5))
	return paint_pass(image, 7, 1.0)


## A pockmarked moon (wraps around a ball): mottled gray plains, darker
## "seas", and craters painted with their rims lit on the top left and
## their insides shaded, the way MGS painted its rock walls.
static func moon(width: int, height: int, seed_number: int) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_number
	var plains := FastNoiseLite.new()
	plains.seed = seed_number
	plains.frequency = 0.6
	var image := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	for y in height:
		for x in width:
			var angle := TAU * x / width
			var p := Vector3(cos(angle) * 1.6, sin(angle) * 1.6, y * 0.035)
			var mottle := plains.get_noise_3dv(p)
			var light := 0.78 + 0.18 * mottle
			if mottle < -0.25:
				light *= 0.72  # A dark sea.
			light += rng.randf_range(-0.03, 0.03)
			image.set_pixel(x, y, Color(light * 0.95, light * 0.94, light * 0.92))
	for i in 70:
		var radius := pow(rng.randf(), 2.5) * 10.0 + 1.5
		_pit(image, Vector2(rng.randf() * width, rng.randf_range(0.12, 0.88) * height), radius)
	return paint_pass(image, 6, 1.0)


## A crater: dark inside on its top-left (in shadow), lit inside on its
## bottom-right, a bright rim on top-left outside. Wraps left to right.
static func _pit(image: Image, center: Vector2, radius: float) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var reach := int(ceil(radius + 2.0))
	for dy in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			var y := int(center.y) + dy
			if y < 0 or y >= height:
				continue
			var x := posmod(int(center.x) + dx, width)
			var offset := Vector2(dx, dy)
			var distance := offset.length()
			var factor := 1.0
			if distance <= radius:
				# Inside: shaded toward the top left, lit toward the bottom right.
				var slope := (offset.x + offset.y) / maxf(radius * 1.4, 0.001)
				factor = 0.72 + 0.28 * slope
			elif distance <= radius + 1.2:
				# The rim: lit on the top left, shadowed on the bottom right.
				factor = 1.22 if offset.x + offset.y < 0.0 else 0.82
			else:
				continue
			var c := image.get_pixel(x, y)
			image.set_pixel(x, y, Color(clampf(c.r * factor, 0.0, 1.0), clampf(c.g * factor, 0.0, 1.0), clampf(c.b * factor, 0.0, 1.0)))


## Distance on a tile that wraps around (so the rock texture is seamless).
static func _wrapped(a: Vector2, b: Vector2, size: int) -> float:
	var d := (a - b).abs()
	d = Vector2(minf(d.x, size - d.x), minf(d.y, size - d.y))
	return d.length()
