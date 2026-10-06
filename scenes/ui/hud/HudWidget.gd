class_name HudWidget
extends Control
## The base for every piece of the flight HUD (speed, radar, fuel...).
##
## The HUD is drawn small, into a low-resolution picture (about 360 rows
## tall), which is then blown up with crisp square pixels, so it looks like
## a real PlayStation HUD. Here, "1" means one of those big chunky pixels.
## FlightHUD.gd tells each piece when to redraw (at a slightly jerky rate on
## purpose) and gives it the ship, the destination and the job.
##
## The palette is strict: green readouts, hazard-yellow warnings, red alerts,
## and the current solar system's color on the frames.


const GREEN := Color("62ff7e")
const YELLOW := Color("ffd21f")
const RED := Color("ff3d32")
## Where your job's load goes (the same pink as on the course chart).
const JOB_PINK := Color("ff4dbf")
## Dark see-through panel behind readouts, so they read over bright space.
const BACKING := Color(0.0, 0.0, 0.03, 0.6)
const SHADOW := Color(0.0, 0.0, 0.0, 0.7)
## Space between the HUD and the screen edges.
const MARGIN: float = 8.0

const SMALL := PixelFont.Face.SMALL
const BIG := PixelFont.Face.BIG

## The HUD this piece belongs to. Set by FlightHUD.
var hud: FlightHUD
## Pieces in the bottom row step aside in cockpit view (the dashboard has
## its own gauges).
var bottom_row: bool = false
## Pieces that stay up even when the player hides the HUD (comm calls).
var always_shown: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


## Called by the HUD on each of its frames, with the seconds since the last
## one. `numbers_due` is true on the (fewer) frames where number readouts
## should tick over to their new values.
func hud_step(_delta: float, _numbers_due: bool) -> void:
	pass


func ship() -> Ship:
	return hud.ship if hud != null else null


## The solar system's signature color, for frames, labels and unlit parts.
func tint(alpha: float = 1.0) -> Color:
	var color := hud.tint if hud != null else Color.WHITE
	return Color(color, alpha)


## True for the first half of every `period` seconds: for blinking lights.
func blink(period: float) -> bool:
	return fposmod(hud.time if hud != null else 0.0, period) < period * 0.5


## Pixel text with a 1-pixel drop shadow.
func text(where: Vector2, words: String, color: Color, face: PixelFont.Face = SMALL,
		square: float = 1.0, slant: float = 0.0) -> void:
	PixelFont.draw(self, where.floor(), words, square, color, slant, SHADOW, face)


## Like text(), but `right_top` is the top-RIGHT corner.
func text_right(right_top: Vector2, words: String, color: Color, face: PixelFont.Face = SMALL,
		square: float = 1.0, slant: float = 0.0) -> void:
	text(right_top - Vector2(PixelFont.width(words, square, face), 0.0), words, color, face, square, slant)


## Like text(), but centered left-to-right on `center_top`.
func text_centered(center_top: Vector2, words: String, color: Color, face: PixelFont.Face = SMALL,
		square: float = 1.0, slant: float = 0.0) -> void:
	text(center_top - Vector2(floorf(PixelFont.width(words, square, face) * 0.5), 0.0), words, color, face, square, slant)


func text_width(words: String, face: PixelFont.Face = SMALL, square: float = 1.0) -> float:
	return PixelFont.width(words, square, face)


## A filled box on whole pixels.
func box(area: Rect2, color: Color) -> void:
	draw_rect(Rect2(area.position.floor(), area.size.floor()), color)


## A 1-pixel outline drawn from four thin boxes (crisper than a line).
func outline(area: Rect2, color: Color) -> void:
	var a := Rect2(area.position.floor(), area.size.floor())
	box(Rect2(a.position, Vector2(a.size.x, 1)), color)
	box(Rect2(a.position + Vector2(0, a.size.y - 1), Vector2(a.size.x, 1)), color)
	box(Rect2(a.position, Vector2(1, a.size.y)), color)
	box(Rect2(a.position + Vector2(a.size.x - 1, 0), Vector2(1, a.size.y)), color)


## A dark panel with a frame in the system's color.
func panel(area: Rect2) -> void:
	box(area, BACKING)
	outline(area, tint(0.55))


## A box leaning forward by `lean` pixels (the Wipeout slant).
func slanted(area: Rect2, lean: float, color: Color) -> void:
	var a := Rect2(area.position.floor(), area.size.floor())
	draw_colored_polygon(PackedVector2Array([
		Vector2(a.position.x + lean, a.position.y), Vector2(a.end.x + lean, a.position.y),
		a.end, Vector2(a.position.x, a.end.y)]), color)


## Draws a little picture from text rows ('#' = a pixel) at `where`.
func pixels(where: Vector2, rows: Array, color: Color) -> void:
	var corner := where.floor()
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] == "#":
				draw_rect(Rect2(corner + Vector2(x, y), Vector2.ONE), color)


## A thin 1-pixel line between two points.
func line(from: Vector2, to: Vector2, color: Color) -> void:
	draw_line(from.floor() + Vector2(0.5, 0.5), to.floor() + Vector2(0.5, 0.5), color, -1.0)


## Minutes and seconds, like "1:07".
static func clock(seconds: float) -> String:
	var whole := maxi(ceili(seconds), 0)
	return "%d:%02d" % [floori(whole / 60.0), whole % 60]


## A distance, short: "850M" up close, "5.3KM" farther away.
static func distance_text(meters: float) -> String:
	if meters < 1000.0:
		return "%dM" % roundi(meters)
	return "%.1fKM" % (meters / 1000.0)


## A panel that pops in and out in a few chunky steps, PS1 style, instead
## of sliding smoothly. Set `want`, call update() each HUD frame, and use
## hidden_share() to offset the panel while it moves.
class Pop:
	extends RefCounted
	## Whether the panel should be showing.
	var want: bool = false
	## 0 = fully hidden ... steps = fully shown.
	var step: int = 0
	var _timer: float = 0.0

	func update(delta: float) -> void:
		var tuning := GameState.tuning
		var target := tuning.hud_pop_steps if want else 0
		if step == target:
			_timer = 0.0
			return
		_timer += delta
		while _timer >= tuning.hud_pop_step_seconds and step != target:
			_timer -= tuning.hud_pop_step_seconds
			step += 1 if step < target else -1

	func shown() -> bool:
		return step > 0

	## How much of the way out the panel still is: 1 = hidden, 0 = all in.
	func hidden_share() -> float:
		return 1.0 - float(step) / maxf(GameState.tuning.hud_pop_steps, 1)
