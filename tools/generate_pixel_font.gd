extends SceneTree
## Turns the HUD's chunky pixel letters (scenes/ui/PixelFont.gd, the BIG
## face) into a real font file, res://fonts/pixel_font.tres, so every menu,
## dialogue box, button and sign in the game uses the same Wipeout-style
## lettering as the HUD. The project uses it as its default font
## (Project Settings > GUI > Theme > Custom Font).
##
## It's all capitals: lowercase letters use the capital shapes. Characters
## the pixel font doesn't have fall back to Godot's built-in font.
##
## The font is 8 pixels tall and only scales by whole steps (8, 16, 24...),
## so the squares stay crisp: a font size of 16 to 23 draws it twice as
## big, 24 to 31 three times, and so on.
##
## Run it from the project folder (after adding letters to PixelFont.gd):
##     godot --headless --path . -s tools/generate_pixel_font.gd


const OUTPUT: String = "res://fonts/pixel_font.tres"
## The font's height in pixels (7 rows of letter, 1 below the baseline).
const SIZE: int = 8
const ASCENT: int = 7


func _initialize() -> void:
	var glyphs: Dictionary = PixelFont.GLYPHS
	# Lay every letter side by side in one picture (with a gap between).
	var width := 0
	for character: String in glyphs:
		width += (glyphs[character][0] as String).length() + 1
	var atlas := Image.create(maxi(width, 1), SIZE, false, Image.FORMAT_RGBA8)
	atlas.fill(Color(1, 1, 1, 0))
	var font := FontFile.new()
	font.fixed_size = SIZE
	font.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.hinting = TextServer.HINTING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	font.generate_mipmaps = false
	var size := Vector2i(SIZE, 0)
	font.set_cache_ascent(0, SIZE, ASCENT)
	font.set_cache_descent(0, SIZE, SIZE - ASCENT + 1)
	var x := 0
	var places := {}  # Character -> [x, width] in the picture.
	for character: String in glyphs:
		var rows: Array = glyphs[character]
		var columns := (rows[0] as String).length()
		for row in rows.size():
			var line: String = rows[row]
			for column in columns:
				if line[column] == "#":
					atlas.set_pixel(x + column, row, Color.WHITE)
		places[character] = [x, columns]
		x += columns + 1
	font.set_texture_image(0, size, 0, atlas)
	for character: String in places:
		var spot: Array = places[character]
		_add_glyph(font, size, character.unicode_at(0), spot[0], spot[1])
		# Lowercase letters use the capital shapes.
		var lower := character.to_lower()
		if lower != character:
			_add_glyph(font, size, lower.unicode_at(0), spot[0], spot[1])
	var error := ResourceSaver.save(font, OUTPUT)
	print("%s: %s (%d characters)" % [OUTPUT, error_string(error), places.size()])
	quit(0 if error == OK else 1)


func _add_glyph(font: FontFile, size: Vector2i, code: int, x: int, columns: int) -> void:
	font.set_glyph_advance(0, SIZE, code, Vector2(columns + 1, 0))
	font.set_glyph_offset(0, size, code, Vector2(0, -ASCENT))
	font.set_glyph_size(0, size, code, Vector2(columns, ASCENT))
	font.set_glyph_uv_rect(0, size, code, Rect2(x, 0, columns, ASCENT))
	font.set_glyph_texture_idx(0, size, code, 0)
