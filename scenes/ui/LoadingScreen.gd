class_name LoadingScreen
extends CanvasLayer
## The "loading" screen between big scenes (boarding the rig, climbing out
## at a place, starting the game). It's a quick black screen where a few
## trucker-flavored lines type themselves out in the top-left corner, old
## computer style: "LOADING CARGO.......OK!", "MAPPING COORDINATES...OK!".
## The screen stays up `MIN_SECONDS` so the lines can be read, then the
## next scene loads (quickly; our scenes are small) and the black fades away.
##
## Use it with:
##     LoadingScreen.go(get_tree(), "res://scenes/flight/FlightSandbox.tscn", "flight")
## The kinds ("flight", "place", "start") pick which lines it uses: see
## LINES below to add more.


const MIN_SECONDS: float = 1.5
const BLIP := preload("res://audio/generated/blip.wav")

## Kind -> lines it picks from: [what's happening, how it went].
const LINES := {
	"flight": [["LOADING CARGO", "OK!"], ["STRAPPING IT DOWN", "OK!"], ["MAPPING COORDINATES", "OK!"],
			["WARMING UP THE ENGINES", "OK!"], ["TUNING THE RADIO", "OK!"], ["CHECKING MIRRORS", "OK!"],
			["ENTERING HYPERDRIVE", "JUST KIDDING"], ["FINDING A GOOD SONG", "OK!"], ["SEALING THE CAB", "OK!"],
			["CALCULATING SPACEWAY", "OK!"], ["DE-ICING THE WINDSHIELD", "OK!"]],
	"place": [["DOCKING CLAMPS", "LOCKED"], ["PRESSURIZING AIRLOCK", "OK!"], ["FINDING YOUR KEYS", "OK!"],
			["UNBUCKLING", "OK!"], ["STRETCHING", "CRACK"], ["UNLOADING CARGO", "OK!"],
			["LOCATING SNACKS", "OK!"], ["PUTTING ON PANTS", "OK!"]],
	"start": [["LOADING SAVE", "OK!"], ["WAKING UP", "BARELY"], ["MAKING COFFEE", "OK!"],
			["COUNTING CREDITS", "OK!"]],
}

const GRAY := Color(0.78, 0.8, 0.86)
const GREEN := Color(0.4, 1.0, 0.45)

var _path: String = ""
var _lines: Array = []
var _time: float = 0.0
var _canvas: Control
var _blips: AudioStreamPlayer
var _shown: int = 0
var _switched: bool = false


## Covers the screen, loads `path` and switches to it.
static func go(tree: SceneTree, path: String, kind: String = "flight") -> void:
	var screen := LoadingScreen.new()
	screen._path = path
	var pool: Array = (LINES.get(kind, LINES["flight"]) as Array).duplicate()
	pool.shuffle()
	screen._lines = pool.slice(0, 3)
	tree.root.add_child(screen)


func _ready() -> void:
	layer = 60  # Above everything, even fades.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.draw.connect(_draw_lines)
	add_child(_canvas)
	_blips = AudioStreamPlayer.new()
	_blips.stream = BLIP
	_blips.volume_db = -14.0
	_blips.pitch_scale = 1.6
	add_child(_blips)


func _process(delta: float) -> void:
	_time += delta
	var each := (MIN_SECONDS - 0.3) / maxf(_lines.size(), 1)
	var shown := mini(floori(_time / each) + 1, _lines.size())
	if shown > _shown:
		_shown = shown
		_blips.play()
	_canvas.queue_redraw()
	if _switched:
		# Fade the black away once the new scene is up.
		_canvas.modulate.a = maxf(_canvas.modulate.a - delta * 4.0, 0.0)
		if _canvas.modulate.a <= 0.0:
			queue_free()
		return
	if _time >= MIN_SECONDS:
		_switched = true
		get_tree().paused = false
		get_tree().change_scene_to_file(_path)


func _draw_lines() -> void:
	var screen := _canvas.size
	_canvas.draw_rect(Rect2(Vector2.ZERO, screen), Color.BLACK)
	var square := maxf(1.0, floorf(screen.y / 240.0))
	var left := square * 8.0
	var y := square * 8.0
	var each := (MIN_SECONDS - 0.3) / maxf(_lines.size(), 1)
	for i in mini(_shown, _lines.size()):
		var line: Array = _lines[i]
		var label: String = line[0]
		var typed := clampf((_time - i * each) / (each * 0.7), 0.0, 1.0)
		PixelFont.draw(_canvas, Vector2(left, y), label + ".".repeat(roundi(typed * 8.0)), square, GRAY, 0.0, Color(0, 0, 0, 0))
		if typed >= 1.0:
			var at := left + PixelFont.width(label + "........", square) + square * 3.0
			PixelFont.draw(_canvas, Vector2(at, y), line[1], square, GREEN, 0.0, Color(0, 0, 0, 0))
		y += square * 10.0
	# The date and time, bottom left: life goes on while it loads.
	PixelFont.draw(_canvas, Vector2(left, screen.y - square * 15.0), "%s  ·  %s" % [Economy.date_text(), Economy.clock_text()],
			square, Color(1.0, 0.85, 0.3), 0.0, Color(0, 0, 0, 0))
	# A little spinning wheel in the corner while it works.
	var center := screen - Vector2(square * 14.0, square * 14.0)
	for k in 8:
		var angle := TAU * k / 8.0 + floorf(_time * 10.0) * TAU / 8.0
		var spot := center + Vector2(cos(angle), sin(angle)) * square * 6.0
		_canvas.draw_rect(Rect2(spot - Vector2.ONE * square, Vector2.ONE * square * 2.0), Color(1, 0.55, 0.3, 0.3 + 0.7 * k / 8.0))
