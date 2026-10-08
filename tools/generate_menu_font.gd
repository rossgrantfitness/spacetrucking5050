extends SceneTree
## Turns the menu lettering (scenes/ui/MenuFont.gd) into a real font file,
## res://fonts/menu_font.tres, used by every menu and dialogue box (through
## RetroUI.gd's theme). The flight HUD keeps its own font.
##
## The font is 10 pixels tall (7 above the line, 2 below, 1 between lines)
## and only scales by whole steps (10, 20, 30...), so the pixels stay crisp:
## a font size of 20 to 29 draws it twice as big, and so on.
##
## Run it from the project folder (after changing a letter in MenuFont.gd):
##     godot --headless --path . -s tools/generate_menu_font.gd

const OUTPUT: String = "res://fonts/menu_font.tres"
## Rows in the font picture: above the line, below it, and a gap.
const SIZE: int = 10


func _initialize() -> void:
	var glyphs: Dictionary = load("res://scenes/ui/MenuFont.gd").call("all_glyphs")
	var ascent: int = MenuFont.ASCENT
	var rows_tall := ascent + MenuFont.DESCENT
	var width := 0
	for character: String in glyphs:
		width += (glyphs[character][0] as String).length() + 1
	var atlas := Image.create(maxi(width, 1), rows_tall, false, Image.FORMAT_RGBA8)
	atlas.fill(Color(1, 1, 1, 0))
	var font := FontFile.new()
	font.fixed_size = SIZE
	font.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.hinting = TextServer.HINTING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	font.generate_mipmaps = false
	var size := Vector2i(SIZE, 0)
	# A pixel of headroom above the capitals, so lines don't touch.
	font.set_cache_ascent(0, SIZE, ascent + 1)
	font.set_cache_descent(0, SIZE, SIZE - ascent - 1)
	var x := 0
	for character: String in glyphs:
		var rows: Array = glyphs[character]
		var columns := (rows[0] as String).length()
		for row in rows.size():
			var line: String = rows[row]
			for column in mini(columns, line.length()):
				if line[column] == "#":
					atlas.set_pixel(x + column, row, Color.WHITE)
		var code := character.unicode_at(0)
		font.set_glyph_advance(0, SIZE, code, Vector2(columns + 1, 0))
		font.set_glyph_offset(0, size, code, Vector2(0, -ascent))
		font.set_glyph_size(0, size, code, Vector2(columns, rows_tall))
		font.set_glyph_uv_rect(0, size, code, Rect2(x, 0, columns, rows_tall))
		font.set_glyph_texture_idx(0, size, code, 0)
		x += columns + 1
	font.set_texture_image(0, size, 0, atlas)
	var error := ResourceSaver.save(font, OUTPUT)
	print("%s: %s (%d characters)" % [OUTPUT, error_string(error), glyphs.size()])
	quit(0 if error == OK else 1)
