extends SceneTree
## Cuts the developer's interior texture sheet (reference/interior_texture_sheet.webp)
## into the tiles the walkable rooms use, saved to res://textures/interior/.
## The room sets (scenes/hub/sets/) point at these instead of the old
## generated placeholders; the ships and stations out in space keep theirs.
##
## The sheet is grimy and dark. The rooms tint each texture with their own
## paint color, so each tile is lifted (a gamma curve, which brightens the
## darks without blowing out the highlights) to about the brightness of the
## placeholder it replaces, and a little of its color is taken out so the
## room's own paint still shows through. Edit the table to re-cut a tile.
##
## Run it with:  godot --headless --path . -s tools/cut_interior_textures.gd
## then:         godot --headless --path . --import

const SHEET := "res://reference/interior_texture_sheet.webp"
const OUT := "res://textures/interior/"

## name: [where on the sheet (x, y, width, height), saved size,
##        how bright on average (0-1; 0 = leave it), how much color kept (0-1)]
const TILES := {
	"wall_panels": [Rect2i(0, 0, 256, 256), Vector2i(128, 128), 0.52, 0.75],      # Rusty riveted panels.
	"floor_tiles": [Rect2i(640, 896, 128, 128), Vector2i(128, 128), 0.38, 0.7],    # Tread plate.
	"door": [Rect2i(512, 256, 128, 256), Vector2i(128, 256), 0.5, 0.85],           # Bulkhead door with a porthole.
	"machinery": [Rect2i(256, 256, 256, 256), Vector2i(128, 128), 0.46, 0.9],      # Switches and PSI / BAR gauges.
	"pipes": [Rect2i(256, 0, 256, 256), Vector2i(128, 128), 0.5, 0.8],             # Pipe runs.
	"vents": [Rect2i(0, 512, 128, 128), Vector2i(64, 64), 0.4, 0.8],               # Louvered vent.
	"grate": [Rect2i(768, 512, 128, 128), Vector2i(64, 64), 0.37, 0.75],           # Stamped deck plate.
	"crate": [Rect2i(512, 768, 128, 128), Vector2i(128, 128), 0.6, 0.8],           # "Interstellar Cargo" crate.
	"container": [Rect2i(896, 640, 128, 128), Vector2i(128, 128), 0.66, 0.7],      # "Sealed Container #42".
	"terminal": [Rect2i(514, 4, 124, 93), Vector2i(128, 96), 0.0, 1.0],            # Green CRT (it glows; left as is).
}

## The sheet's hazard tape: dusty yellow and soot black.
const HAZARD_YELLOW := Color8(196, 180, 86)
const HAZARD_BLACK := Color8(40, 40, 36)


func _initialize() -> void:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(SHEET))
	if sheet == null or sheet.is_empty():
		push_error("Couldn't read " + SHEET)
		quit(1)
		return
	sheet.convert(Image.FORMAT_RGBA8)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for tile_name: String in TILES:
		var spec: Array = TILES[tile_name]
		var tile := sheet.get_region(spec[0])
		var size: Vector2i = spec[1]
		if tile.get_size() != size:
			tile.resize(size.x, size.y, Image.INTERPOLATE_BILINEAR)
		_grade(tile, spec[2], spec[3])
		tile.save_png(OUT + tile_name + ".png")
		print("Cut %s (%dx%d)" % [tile_name, size.x, size.y])
	var stripes := _hazard_stripes(sheet.get_region(TILES["wall_panels"][0]))
	stripes.save_png(OUT + "hazard_stripes.png")
	print("Made hazard_stripes (64x64)")
	quit()


## Lifts `image` to an average brightness of `target` and keeps `color` of
## its saturation.
func _grade(image: Image, target: float, color: float) -> void:
	var lift := 1.0
	if target > 0.0:
		var total := 0.0
		for y in image.get_height():
			for x in image.get_width():
				total += image.get_pixel(x, y).get_luminance()
		var average := clampf(total / (image.get_width() * image.get_height()), 0.02, 0.98)
		lift = log(target) / log(average)
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			var grey := pixel.get_luminance()
			pixel = Color(grey, grey, grey, pixel.a).lerp(pixel, color)
			pixel = Color(pow(pixel.r, lift), pow(pixel.g, lift), pow(pixel.b, lift), pixel.a)
			image.set_pixel(x, y, pixel)


## Diagonal hazard tape that tiles seamlessly (the sheet's own stripes don't
## line up at the edges), in the sheet's colors, scuffed with the grime of
## its rusty panels.
func _hazard_stripes(grime_source: Image) -> Image:
	var grime := grime_source.duplicate() as Image
	grime.resize(64, 64, Image.INTERPOLATE_BILINEAR)
	var total := 0.0
	for y in 64:
		for x in 64:
			total += grime.get_pixel(x, y).get_luminance()
	var average := total / 4096.0
	var image := Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var yellow := posmod(x + y, 32) < 16  # Two stripes per tile, like the old one.
			var dirt := clampf(grime.get_pixel(x, y).get_luminance() / average, 0.6, 1.25)
			var base := HAZARD_YELLOW if yellow else HAZARD_BLACK
			image.set_pixel(x, y, Color(base.r * lerpf(1.0, dirt, 0.5), base.g * lerpf(1.0, dirt, 0.5), base.b * lerpf(1.0, dirt, 0.5)))
	return image
