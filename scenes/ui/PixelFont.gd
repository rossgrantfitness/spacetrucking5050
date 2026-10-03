class_name PixelFont
## A chunky, blocky pixel font in the style of late-90s racing-game HUDs
## (think Wipeout 3). Every letter is a tiny grid of squares drawn as big as
## you like, so it stays crunchy and readable from 800x600 up to 4K.
##
## It's made from text pictures right here in GLYPHS ('#' = filled square),
## so no font file is needed and new letters are easy to add.
##
## Draw with:   PixelFont.draw(self, Vector2(20, 20), "TRUCK STOP", 3.0, Color.WHITE)
## Stamp into a texture with PixelFont.stamp(image, ...).


## Every letter is this many squares tall.
const HEIGHT: int = 7
## Empty squares between letters.
const SPACING: int = 1

const GLYPHS := {
	"A": ["#####", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"B": ["####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."],
	"C": ["#####", "#....", "#....", "#....", "#....", "#....", "#####"],
	"D": ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
	"E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
	"F": ["#####", "#....", "#....", "####.", "#....", "#....", "#...."],
	"G": ["#####", "#....", "#....", "#.###", "#...#", "#...#", "#####"],
	"H": ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"I": ["###", ".#.", ".#.", ".#.", ".#.", ".#.", "###"],
	"J": ["....#", "....#", "....#", "....#", "#...#", "#...#", "#####"],
	"K": ["#...#", "#..#.", "#.#..", "###..", "#..#.", "#...#", "#...#"],
	"L": ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
	"M": ["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"],
	"N": ["#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#"],
	"O": ["#####", "#...#", "#...#", "#...#", "#...#", "#...#", "#####"],
	"P": ["#####", "#...#", "#...#", "#####", "#....", "#....", "#...."],
	"Q": ["#####", "#...#", "#...#", "#...#", "#.#.#", "#..#.", "###.#"],
	"R": ["#####", "#...#", "#...#", "#####", "#.#..", "#..#.", "#...#"],
	"S": ["#####", "#....", "#....", "#####", "....#", "....#", "#####"],
	"T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
	"U": ["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", "#####"],
	"V": ["#...#", "#...#", "#...#", "#...#", ".#.#.", ".#.#.", "..#.."],
	"W": ["#...#", "#...#", "#...#", "#.#.#", "#.#.#", "##.##", "#...#"],
	"X": ["#...#", ".#.#.", ".#.#.", "..#..", ".#.#.", ".#.#.", "#...#"],
	"Y": ["#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."],
	"Z": ["#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"],
	"0": ["#####", "#...#", "#..##", "#.#.#", "##..#", "#...#", "#####"],
	"1": [".#.", "##.", ".#.", ".#.", ".#.", ".#.", "###"],
	"2": ["#####", "....#", "....#", "#####", "#....", "#....", "#####"],
	"3": ["#####", "....#", "....#", ".####", "....#", "....#", "#####"],
	"4": ["#...#", "#...#", "#...#", "#####", "....#", "....#", "....#"],
	"5": ["#####", "#....", "#....", "#####", "....#", "....#", "#####"],
	"6": ["#####", "#....", "#....", "#####", "#...#", "#...#", "#####"],
	"7": ["#####", "....#", "....#", "...#.", "..#..", "..#..", "..#.."],
	"8": ["#####", "#...#", "#...#", "#####", "#...#", "#...#", "#####"],
	"9": ["#####", "#...#", "#...#", "#####", "....#", "....#", "#####"],
	".": [".", ".", ".", ".", ".", ".", "#"],
	",": [".", ".", ".", ".", ".", "#", "#"],
	":": [".", "#", ".", ".", ".", "#", "."],
	"·": [".", ".", ".", "#", ".", ".", "."],
	"'": ["#", "#", ".", ".", ".", ".", "."],
	"!": ["#", "#", "#", "#", "#", ".", "#"],
	"?": ["#####", "....#", "....#", "..###", "..#..", ".....", "..#.."],
	"-": ["...", "...", "...", "###", "...", "...", "..."],
	"+": [".....", "..#..", "..#..", "#####", "..#..", "..#..", "....."],
	"/": ["....#", "...#.", "...#.", "..#..", ".#...", ".#...", "#...."],
	"%": ["##..#", "##.#.", "...#.", "..#..", ".#...", ".#.##", "#..##"],
	"#": [".#.#.", "#####", ".#.#.", ".#.#.", ".#.#.", "#####", ".#.#."],
	" ": ["...", "...", "...", "...", "...", "...", "..."],
}


## How wide `text` is when each square is `square` big.
static func width(text: String, square: float) -> float:
	var columns := 0
	for character in text.to_upper():
		columns += _glyph(character)[0].length() + SPACING
	return maxf(columns - SPACING, 0) * square


## How tall a line of text is when each square is `square` big.
static func height(square: float) -> float:
	return HEIGHT * square


## Draws `text` with its top-left corner at `where`. `slant` leans the
## letters forward like speedy italics (0 = upright, 0.25 = racing slant).
## A dark drop shadow keeps it readable over bright space stuff.
static func draw(canvas: CanvasItem, where: Vector2, text: String, square: float, color: Color,
		slant: float = 0.0, shadow: Color = Color(0, 0, 0, 0.55)) -> void:
	if shadow.a > 0.0:
		_draw_squares(canvas, where + Vector2.ONE * maxf(1.0, square * 0.5), text, square, shadow, slant)
	_draw_squares(canvas, where, text, square, color, slant)


## Like draw(), but centered on `center`.
static func draw_centered(canvas: CanvasItem, center: Vector2, text: String, square: float, color: Color,
		slant: float = 0.0, shadow: Color = Color(0, 0, 0, 0.55)) -> void:
	var corner := center - Vector2(width(text, square), height(square)) * 0.5
	draw(canvas, corner, text, square, color, slant, shadow)


## Paints `text` into an image (for textures like painted lettering on a
## cargo container), each square `square` pixels big.
static func stamp(image: Image, where: Vector2i, text: String, square: int, color: Color) -> void:
	var x := where.x
	for character in text.to_upper():
		var glyph := _glyph(character)
		for row in HEIGHT:
			var line: String = glyph[row]
			for column in line.length():
				if line[column] == "#":
					image.fill_rect(Rect2i(x + column * square, where.y + row * square, square, square), color)
		x += (glyph[0].length() + SPACING) * square


static func _draw_squares(canvas: CanvasItem, where: Vector2, text: String, square: float, color: Color, slant: float) -> void:
	var x := where.x
	for character in text.to_upper():
		var glyph := _glyph(character)
		for row in HEIGHT:
			var line: String = glyph[row]
			# Higher rows shift right, so the letter leans forward.
			var lean := (HEIGHT - 1 - row) * slant * square
			for column in line.length():
				if line[column] == "#":
					canvas.draw_rect(Rect2(x + column * square + lean, where.y + row * square, square, square), color)
		x += (glyph[0].length() + SPACING) * square


## The picture for one character (unknown characters show as "?").
static func _glyph(character: String) -> Array:
	return GLYPHS.get(character, GLYPHS["?"])
