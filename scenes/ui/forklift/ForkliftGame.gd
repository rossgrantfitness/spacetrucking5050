class_name ForkliftGame
extends CanvasLayer
## LOADING THE RIG yourself: the forklift minigame, seen from above (the
## rules are in ForkliftRules.gd). Arrows / stick drive, E / A lifts and sets
## down, Esc / B lets the dock crew finish. It's offered when you take a job.
##
##     var result := await ForkliftGame.play(tree, 4)
##     result: {"done": true if you loaded it all, "bumps": int, "seconds": float}


signal finished(result: Dictionary)

const PICTURE := Vector2(ForkliftRules.WIDTH, ForkliftRules.HEIGHT)
const SMALL := PixelFont.Face.SMALL
const NO_SHADOW := Color(0, 0, 0, 0)
const FLOOR := Color("2b3140")
const FLOOR_LINE := Color("343b4d")
const HAZARD := Color("ffd21f")
const CRATE_COLORS: Array[Color] = [Color("e07a3a"), Color("4f8fc4"), Color("c9b44a"), Color("78b06a"), Color("c66a9e"), Color("8e7ad1")]

var rules: ForkliftRules
var _canvas: Control
var _thump: AudioStreamPlayer
var _ending: float = -1.0
var _note: String = ""
var _note_time: float = 0.0


## Opens the dock for `pallets` pallets and waits until it's loaded (or the
## crew takes over).
static func play(tree: SceneTree, pallets: int) -> Dictionary:
	var game := ForkliftGame.new()
	game.rules = ForkliftRules.new(pallets)
	var paused_before := tree.paused
	tree.paused = true
	tree.root.add_child(game)
	var result: Dictionary = await game.finished
	tree.paused = paused_before
	game.queue_free()
	return result


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.draw.connect(_draw_dock)
	add_child(_canvas)
	_thump = AudioStreamPlayer.new()
	_thump.stream = preload("res://audio/generated/thump.wav")
	_thump.bus = Settings.SFX_BUS
	_thump.volume_db = -6.0
	add_child(_thump)
	_say("PICK UP A PALLET", 3.0)


func _process(delta: float) -> void:
	_note_time = maxf(_note_time - delta, 0.0)
	if _ending >= 0.0:
		_ending += delta
		if _ending > 1.6:
			finished.emit({"done": rules.done, "bumps": rules.bumps, "seconds": rules.seconds})
			_ending = -100.0
		_canvas.queue_redraw()
		return
	var drive := Input.get_axis("ui_down", "ui_up") + Input.get_axis("move_back", "move_forward")
	var turn := Input.get_axis("ui_left", "ui_right") + Input.get_axis("move_left", "move_right")
	if rules.step(delta, clampf(drive, -1.0, 1.0), clampf(turn, -1.0, 1.0)) == "bump":
		_thump.pitch_scale = randf_range(0.9, 1.2)
		_thump.play()
		_say("BONK", 0.8)
	_canvas.queue_redraw()


func _input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo() or event is InputEventMouse or _ending >= 0.0:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_say("THE CREW'LL FINISH UP", 2.0)
		_ending = 0.0
		Sfx.play("ui_back")
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		match rules.use_forks():
			"lift":
				Sfx.play("ui_move", 0.0, 0.7)
				_say("INTO THE HOLD", 2.0)
			"slot":
				Sfx.play("ui_confirm")
				_say("%d OF %d" % [rules.loaded(), rules.pallets.size()], 1.5)
			"drop":
				Sfx.play("ui_move", 0.0, 0.5)
			"done":
				Sfx.play("job_accept")
				_say("ALL LOADED. NEAT AS A PIN.", 3.0)
				_ending = 0.0
			_:
				_say("POINT THE FORKS AT A PALLET", 1.5)


func _say(words: String, seconds: float) -> void:
	_note = words
	_note_time = seconds


# --- Drawing -------------------------------------------------------------------------

func _draw_dock() -> void:
	var size := _canvas.size
	_canvas.draw_rect(Rect2(Vector2.ZERO, size), Color("101320"))
	var zoom := maxf(1.0, floorf(minf(size.x / (PICTURE.x + 16.0), size.y / (PICTURE.y + 30.0))))
	var corner := ((size - PICTURE * zoom) * 0.5).floor()
	_canvas.draw_set_transform(corner, 0.0, Vector2(zoom, zoom))
	# The dock floor: plates, and a painted lane.
	_canvas.draw_rect(Rect2(Vector2.ZERO, PICTURE), FLOOR)
	for x in range(0, int(PICTURE.x), 20):
		_canvas.draw_rect(Rect2(x, 0.0, 1.0, PICTURE.y), FLOOR_LINE)
	for y in range(0, int(PICTURE.y), 20):
		_canvas.draw_rect(Rect2(0.0, y, PICTURE.x, 1.0), FLOOR_LINE)
	_text(Vector2(4.0, 4.0), "DOCK", Color(0.7, 0.75, 0.9))
	# Your rig's hold: hazard-striped walls, open toward the dock.
	var hold := ForkliftRules.HOLD
	_canvas.draw_rect(hold, Color("1f2433"))
	for wall in rules.walls():
		_canvas.draw_rect(wall, HAZARD)
		for k in range(0, int(maxf(wall.size.x, wall.size.y)), 6):
			var stripe := Rect2(wall.position + (Vector2(k, 0.0) if wall.size.x > wall.size.y else Vector2(0.0, k)), Vector2(3.0, 3.0))
			_canvas.draw_rect(stripe.intersection(wall), Color("1a1a1a"))
	_text(Vector2(hold.position.x + 4.0, hold.end.y + 4.0), "YOUR RIG'S HOLD", HAZARD)
	for slot in rules.slots:
		_outline(Rect2(slot - ForkliftRules.PALLET * 0.5, ForkliftRules.PALLET), Color(1.0, 0.85, 0.3, 0.55))
	# The pallets (the one on the forks is drawn last, on top).
	for i in rules.pallets.size():
		if i != rules.carrying:
			_draw_pallet(rules.pallets[i]["at"], i)
	_draw_forklift()
	if rules.carrying >= 0:
		_draw_pallet(rules.pallets[rules.carrying]["at"] - Vector2(0.0, 1.0), rules.carrying)
	# Readouts.
	_text(Vector2(PICTURE.x - 60.0, 4.0), "LOADED %d/%d" % [rules.loaded(), rules.pallets.size()], Color(0.6, 1.0, 0.6))
	if _note_time > 0.0:
		PixelFont.draw_centered(_canvas, Vector2(PICTURE.x * 0.5, PICTURE.y - 10.0), _note, 1.0, Color.WHITE, 0.0, Color(0, 0, 0, 0.7), SMALL)
	_canvas.draw_set_transform(Vector2.ZERO)
	var help := "ARROWS / STICK: DRIVE    E / A: LIFT, SET DOWN    ESC / B: LET THE CREW DO IT"
	PixelFont.draw_centered(_canvas, Vector2(size.x * 0.5, corner.y + (PICTURE.y + 10.0) * zoom), help, maxf(1.0, zoom * 0.5), Color(0.7, 0.72, 0.85), 0.0, NO_SHADOW, SMALL)


func _draw_pallet(at: Vector2, index: int) -> void:
	var box := Rect2(at - ForkliftRules.PALLET * 0.5, ForkliftRules.PALLET).abs()
	_canvas.draw_rect(box, Color("7a5a36"))  # The wooden pallet.
	_canvas.draw_rect(box.grow(-2.0), CRATE_COLORS[index % CRATE_COLORS.size()])  # The crate on it.
	_canvas.draw_rect(Rect2(box.position + Vector2(2.0, box.size.y * 0.5 - 0.5), Vector2(box.size.x - 4.0, 1.0)), Color(0, 0, 0, 0.35))  # A strap.


func _draw_forklift() -> void:
	var forward := Vector2.from_angle(rules.heading)
	var side := forward.orthogonal()
	var at := rules.position
	# The forks: two prongs out front.
	for k: float in [-2.5, 2.5]:
		var base := at + forward * 4.0 + side * k
		_canvas.draw_line(base, base + forward * 8.0, Color("9aa0aa"), 1.5)
	# The body: a yellow box, with a dark cab and a tiny bunny driver.
	var body := PackedVector2Array([at + forward * 5.0 + side * 4.5, at + forward * 5.0 - side * 4.5, at - forward * 6.0 - side * 4.5, at - forward * 6.0 + side * 4.5])
	_canvas.draw_colored_polygon(body, HAZARD)
	_canvas.draw_colored_polygon(PackedVector2Array([at + forward * 2.0 + side * 3.0, at + forward * 2.0 - side * 3.0, at - forward * 3.0 - side * 3.0, at - forward * 3.0 + side * 3.0]), Color("2a2a33"))
	_canvas.draw_circle(at - forward * 0.5, 1.8, Color("f0d2b4"))  # Her head...
	_canvas.draw_line(at - forward * 0.5 + side * 1.0, at - forward * 3.5 + side * 1.6, Color("f0d2b4"), 1.0)  # ...and lop ears.
	_canvas.draw_line(at - forward * 0.5 - side * 1.0, at - forward * 3.5 - side * 1.6, Color("f0d2b4"), 1.0)


func _outline(box: Rect2, color: Color) -> void:
	_canvas.draw_rect(box, color, false, 1.0)


func _text(where: Vector2, words: String, color: Color) -> void:
	PixelFont.draw(_canvas, where, words, 1.0, color, 0.0, NO_SHADOW, SMALL)
