class_name DesktopPC
extends CanvasLayer
## Her desktop computer, on the desk in the apartment: a chunky old PC
## running CARROT OS. It fills the screen like you're sitting at it.
##
## On the desktop:
## - MAIL: her inbox (res://data/pc/emails.tres). New mail arrives as the
##   story moves along; unread ones have a dot.
## - OLD LOGS: {husband}'s notes from the Thumper's old trip computer
##   (res://data/pc/trip_logs.tres). It's slow: it recovers about one more
##   each delivery.
## - INVOICES: every delivery she's been paid for, newest first.
## - ASTEROID ALLEY: a little lane-hopping game (AsteroidAlley.gd), with a
##   high score that's saved.
## - SHUT DOWN: back to the room.
##
## Keys: arrows / D-pad / stick to move, E / Enter / A to open, Esc / B to
## go back. The mouse works too: click icons and emails.
##
## Everything is drawn in the PC screen's own little pixels (SCREEN big),
## scaled up crisply to fit the window, with the pixel font.
##
## Use it with:
##     await DesktopPC.open(get_tree())


signal closed

enum App { BOOT, DESKTOP, MAIL, READ, LOGS, LOG, INVOICES, GAME, SHUTDOWN }

## The PC screen's size in its own pixels.
const SCREEN := Vector2(320.0, 240.0)
## The desktop icons: [label, which app].
const ICONS: Array = [["MAIL", App.MAIL], ["OLD LOGS", App.LOGS], ["INVOICES", App.INVOICES], ["ASTEROID ALLEY", App.GAME], ["SHUT DOWN", App.SHUTDOWN]]
const TRIP_LOGS: TripLogList = preload("res://data/pc/trip_logs.tres")
## The window everything opens in (in screen pixels).
const WINDOW := Rect2(34.0, 14.0, 272.0, 202.0)
const TEAL := Color("2b7a78")
const NAVY := Color("1d2b6b")
const GRAY := Color("c3c0b8")
const INK := Color("1c1a22")
const PAPER := Color("f4efe1")
const SMALL := PixelFont.Face.SMALL

var _app: App = App.BOOT
var _icon: int = 0
var _mail_index: int = 0
var _inbox: Array[EmailData] = []
var _logs: Array[TripLog] = []
var _log_index: int = 0
var _canvas: Control
var _time: float = 0.0
## How long the current boot or shutdown animation has been running.
var _anim: float = 0.0
var _game := AsteroidAlley.new()
## Where the PC screen sits in the real window, and how much it's scaled.
var _offset := Vector2.ZERO
var _scale: float = 1.0


## Shows the PC and waits until she shuts it down.
static func open(tree: SceneTree) -> void:
	var pc := DesktopPC.new()
	tree.root.add_child(pc)
	await pc.closed
	pc.queue_free()


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_inbox = GameState.emails.inbox(GameState.flags)
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.draw.connect(_draw_pc)
	_canvas.gui_input.connect(_on_click)
	add_child(_canvas)


func _process(delta: float) -> void:
	_time += delta
	_anim += delta
	if _app == App.BOOT and _anim > 1.4:
		_app = App.DESKTOP
	elif _app == App.SHUTDOWN and _anim > 0.5:
		_close()
	elif _app == App.GAME:
		var happened := _game.step(delta)
		if happened == "bonk" and _game.score > GameState.pc_high_score:
			GameState.pc_high_score = _game.score
	_canvas.queue_redraw()


# --- Keys and buttons --------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo() or event is InputEventMouse:
		return  # (Mouse clicks go to _on_click.)
	get_viewport().set_input_as_handled()
	var back := event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")
	var go := event.is_action_pressed("ui_accept") or event.is_action_pressed("interact")
	var up := _pressed(event, ["ui_up", "move_forward"])
	var down := _pressed(event, ["ui_down", "move_back"])
	var left := _pressed(event, ["ui_left", "move_left", "steer_left"])
	var right := _pressed(event, ["ui_right", "move_right", "steer_right"])
	match _app:
		App.DESKTOP:
			if up or left:
				_icon = posmod(_icon - 1, ICONS.size())
			elif down or right:
				_icon = posmod(_icon + 1, ICONS.size())
			elif go:
				_launch(ICONS[_icon][1])
			elif back:
				_launch(App.SHUTDOWN)
		App.MAIL:
			if up:
				_mail_index = maxi(_mail_index - 1, 0)
			elif down:
				_mail_index = mini(_mail_index + 1, maxi(_inbox.size() - 1, 0))
			elif go and not _inbox.is_empty():
				_read(_mail_index)
			elif back:
				_app = App.DESKTOP
		App.READ:
			if back or go:
				_app = App.MAIL
		App.LOGS:
			if up:
				_log_index = maxi(_log_index - 1, 0)
			elif down:
				_log_index = mini(_log_index + 1, maxi(_logs.size() - 1, 0))
			elif go and not _logs.is_empty():
				_read_log(_log_index)
			elif back:
				_app = App.DESKTOP
		App.LOG:
			if back or go:
				_app = App.LOGS
		App.INVOICES:
			if back or go:
				_app = App.DESKTOP
		App.GAME:
			if back:
				_app = App.DESKTOP
				_game.state = AsteroidAlley.State.TITLE
			elif _game.state == AsteroidAlley.State.PLAYING:
				if left:
					_game.steer(-1)
				elif right:
					_game.steer(1)
			elif go:
				_game.start()


func _pressed(event: InputEvent, actions: Array) -> bool:
	for action: String in actions:
		if InputMap.has_action(action) and event.is_action_pressed(action):
			return true
	return false


## Mouse clicks: icons on the desktop, emails in the inbox, the window's X.
func _on_click(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	var spot := (click.position - _offset) / _scale
	if _app == App.DESKTOP:
		for i in ICONS.size():
			if _icon_rect(i).has_point(spot):
				if _icon == i:
					_launch(ICONS[i][1])  # Second click opens it.
				_icon = i
		return
	if _app in [App.MAIL, App.READ, App.LOGS, App.LOG, App.INVOICES, App.GAME] and _close_box().has_point(spot):
		_app = App.MAIL if _app == App.READ else (App.LOGS if _app == App.LOG else App.DESKTOP)
		return
	if _app == App.LOGS:
		for i in _logs.size():
			if _mail_row(i).has_point(spot):
				if _log_index == i:
					_read_log(i)
				_log_index = i
		return
	if _app == App.MAIL:
		for i in _inbox.size():
			if _mail_row(i).has_point(spot):
				if _mail_index == i:
					_read(i)
				_mail_index = i


func _launch(app: App) -> void:
	_app = app
	_anim = 0.0
	if app == App.MAIL:
		_inbox = GameState.emails.inbox(GameState.flags)
		_mail_index = clampi(_mail_index, 0, maxi(_inbox.size() - 1, 0))
	elif app == App.LOGS:
		_logs = TRIP_LOGS.recovered()
		# Start at the first one she hasn't read.
		_log_index = maxi(_logs.size() - 1, 0)
		for i in _logs.size():
			if not GameState.has_flag("log_read_" + _logs[i].id):
				_log_index = i
				break
	elif app == App.GAME:
		_game.state = AsteroidAlley.State.TITLE


func _read(index: int) -> void:
	_mail_index = index
	GameState.set_flag("email_read_" + _inbox[index].id)
	_app = App.READ


func _read_log(index: int) -> void:
	_log_index = index
	GameState.set_flag("log_read_" + _logs[index].id)
	_app = App.LOG


func _unread_logs() -> int:
	var count := 0
	for log_entry in TRIP_LOGS.recovered():
		if not GameState.has_flag("log_read_" + log_entry.id):
			count += 1
	return count


func _close() -> void:
	if _app == App.SHUTDOWN and _anim < 0.0:
		return
	_anim = -100.0  # Only once.
	closed.emit()


func _unread() -> int:
	var count := 0
	for email in GameState.emails.inbox(GameState.flags):
		if not GameState.has_flag("email_read_" + email.id):
			count += 1
	return count


# --- Drawing -----------------------------------------------------------------------

func _draw_pc() -> void:
	var size := _canvas.size
	# The monitor's beige plastic all around the screen.
	_canvas.draw_rect(Rect2(Vector2.ZERO, size), Color("2a2730"))
	_scale = maxf(1.0, floorf(minf(size.x / (SCREEN.x + 24.0), size.y / (SCREEN.y + 30.0))))
	_offset = ((size - SCREEN * _scale) * 0.5).floor() - Vector2(0.0, 4.0 * _scale)
	var bezel := Rect2(_offset - Vector2(12.0, 10.0) * _scale, (SCREEN + Vector2(24.0, 28.0)) * _scale)
	_canvas.draw_rect(bezel, Color("d8d0bc"))
	_canvas.draw_rect(Rect2(bezel.position, Vector2(bezel.size.x, 2.0 * _scale)), Color("efe8d6"))
	_canvas.draw_rect(Rect2(bezel.position + Vector2(0.0, bezel.size.y - 2.0 * _scale), Vector2(bezel.size.x, 2.0 * _scale)), Color("a89f8a"))
	PixelFont.draw(_canvas, _offset + Vector2(0.0, SCREEN.y + 5.0) * _scale, "CARROT 98", _scale, Color("8a826e"), 0.0, Color(0, 0, 0, 0), SMALL)
	var led := Color(0.3, 1.0, 0.4) if _app != App.SHUTDOWN else Color(1.0, 0.6, 0.2)
	_canvas.draw_rect(Rect2(_offset + Vector2(SCREEN.x - 8.0, SCREEN.y + 6.0) * _scale, Vector2(4.0, 3.0) * _scale), led)

	# Everything below is in the PC screen's own pixels.
	_canvas.draw_set_transform(_offset, 0.0, Vector2(_scale, _scale))
	match _app:
		App.BOOT:
			_draw_boot()
		App.SHUTDOWN:
			_draw_desktop()
			var squash := clampf(_anim / 0.4, 0.0, 1.0)
			var gap := SCREEN.y * 0.5 * squash
			_canvas.draw_rect(Rect2(0.0, 0.0, SCREEN.x, gap), Color.BLACK)
			_canvas.draw_rect(Rect2(0.0, SCREEN.y - gap, SCREEN.x, gap), Color.BLACK)
		_:
			_draw_desktop()
			match _app:
				App.MAIL:
					_draw_mail()
				App.READ:
					_draw_letter()
				App.LOGS:
					_draw_logs()
				App.LOG:
					_draw_log()
				App.INVOICES:
					_draw_invoices()
				App.GAME:
					_draw_game()
	# A faint CRT shimmer: dark scanlines.
	for y in range(0, int(SCREEN.y), 2):
		_canvas.draw_rect(Rect2(0.0, y, SCREEN.x, 1.0), Color(0, 0, 0, 0.12))
	_canvas.draw_set_transform(Vector2.ZERO)


func _text(where: Vector2, text: String, color: Color = INK, square: float = 1.0) -> void:
	PixelFont.draw(_canvas, where, text, square, color, 0.0, Color(0, 0, 0, 0), SMALL)


func _draw_boot() -> void:
	_canvas.draw_rect(Rect2(Vector2.ZERO, SCREEN), Color.BLACK)
	_draw_carrot(Vector2(148.0, 84.0), 2.0)
	PixelFont.draw_centered(_canvas, Vector2(160.0, 130.0), "CARROT OS", 2.0, Color(1.0, 0.6, 0.25), 0.0, Color(0, 0, 0, 0), SMALL)
	var progress := clampf(_anim / 1.2, 0.0, 1.0)
	_canvas.draw_rect(Rect2(110.0, 150.0, 100.0, 6.0), Color(0.3, 0.3, 0.35))
	_canvas.draw_rect(Rect2(111.0, 151.0, 98.0 * progress, 4.0), Color(0.4, 0.9, 1.0))
	_text(Vector2(112.0, 162.0), "LOADING. BE PATIENT. IT'S OLD.", Color(0.55, 0.55, 0.6))


func _draw_desktop() -> void:
	# Wallpaper: teal in painted bands, stars, and a big ringed planet.
	for band in 12:
		_canvas.draw_rect(Rect2(0.0, band * 20.0, SCREEN.x, 20.0), TEAL.darkened(band * 0.025))
	for i in 30:
		var star := Vector2(fposmod(i * 73.0, SCREEN.x), fposmod(i * 41.0, 210.0))
		_canvas.draw_rect(Rect2(star, Vector2.ONE), Color(1, 1, 1, 0.35 + 0.3 * sin(_time * 2.0 + i)))
	var planet := Vector2(262.0, 172.0)
	_canvas.draw_circle(planet, 30.0, Color("f2a65a"))
	_canvas.draw_circle(planet + Vector2(-6.0, -6.0), 22.0, Color("f6c27a"))
	_canvas.draw_rect(Rect2(planet.x - 46.0, planet.y - 2.0, 92.0, 4.0), Color("f7a3c4"))
	_text(Vector2(206.0, 206.0), "CARROT OS 98", Color(1, 1, 1, 0.35))
	# Icons down the left.
	for i in ICONS.size():
		_draw_icon(i)
	# The taskbar.
	_canvas.draw_rect(Rect2(0.0, 226.0, SCREEN.x, 14.0), GRAY)
	_canvas.draw_rect(Rect2(0.0, 226.0, SCREEN.x, 1.0), Color.WHITE)
	_canvas.draw_rect(Rect2(2.0, 228.0, 38.0, 10.0), GRAY.lightened(0.15))
	_draw_carrot(Vector2(5.0, 229.0), 0.5)
	_text(Vector2(14.0, 230.0), "START")
	var tray := "%s  %s  %d %s" % [Economy.short_date_text(), Economy.clock_text().left(5), GameState.credits, GameState.names.currency_short]
	var width := PixelFont.width(tray, 1.0, SMALL)
	_canvas.draw_rect(Rect2(SCREEN.x - width - 10.0, 228.0, width + 8.0, 10.0), GRAY.darkened(0.1))
	_text(Vector2(SCREEN.x - width - 6.0, 230.0), tray)


func _icon_rect(index: int) -> Rect2:
	return Rect2(4.0, 4.0 + index * 44.0, 48.0, 42.0)


func _draw_icon(index: int) -> void:
	var box := _icon_rect(index)
	var center := box.position + Vector2(24.0, 16.0)
	match ICONS[index][1]:
		App.MAIL:
			_canvas.draw_rect(Rect2(center - Vector2(11.0, 7.0), Vector2(22.0, 15.0)), PAPER)
			_canvas.draw_line(center - Vector2(11.0, 7.0), center + Vector2(0.0, 2.0), INK)
			_canvas.draw_line(center + Vector2(11.0, -7.0), center + Vector2(0.0, 2.0), INK)
			_canvas.draw_rect(Rect2(center - Vector2(11.0, 7.0), Vector2(22.0, 15.0)), INK, false)
			var unread := _unread()
			if unread > 0:
				_canvas.draw_circle(center + Vector2(11.0, -8.0), 5.0, Color(0.9, 0.2, 0.25))
				PixelFont.draw_centered(_canvas, center + Vector2(11.0, -8.0), str(unread), 1.0, Color.WHITE, 0.0, Color(0, 0, 0, 0), SMALL)
		App.LOGS:
			# A chunky old data cassette.
			_canvas.draw_rect(Rect2(center - Vector2(12.0, 8.0), Vector2(24.0, 16.0)), Color("3a3640"))
			_canvas.draw_rect(Rect2(center - Vector2(9.0, 6.0), Vector2(18.0, 6.0)), PAPER)
			_canvas.draw_circle(center + Vector2(-5.0, 3.0), 2.5, GRAY)
			_canvas.draw_circle(center + Vector2(5.0, 3.0), 2.5, GRAY)
			_canvas.draw_rect(Rect2(center - Vector2(12.0, 8.0), Vector2(24.0, 16.0)), INK, false)
			var unread_logs := _unread_logs()
			if unread_logs > 0:
				_canvas.draw_circle(center + Vector2(11.0, -8.0), 5.0, Color(0.9, 0.2, 0.25))
				PixelFont.draw_centered(_canvas, center + Vector2(11.0, -8.0), str(unread_logs), 1.0, Color.WHITE, 0.0, Color(0, 0, 0, 0), SMALL)
		App.INVOICES:
			_canvas.draw_rect(Rect2(center - Vector2(8.0, 11.0), Vector2(16.0, 21.0)), PAPER)
			_canvas.draw_rect(Rect2(center - Vector2(8.0, 11.0), Vector2(16.0, 21.0)), INK, false)
			for line in 4:
				_canvas.draw_rect(Rect2(center + Vector2(-5.0, -7.0 + line * 3.0), Vector2(10.0, 1.0)), Color(0.5, 0.5, 0.55))
			_text(center + Vector2(1.0, 3.0), "$", Color(0.2, 0.6, 0.3))
		App.GAME:
			_canvas.draw_rect(Rect2(center - Vector2(12.0, 10.0), Vector2(24.0, 19.0)), Color("1b1630"))
			_canvas.draw_circle(center + Vector2(-4.0, -3.0), 4.0, Color("9a7b62"))
			_canvas.draw_rect(Rect2(center + Vector2(3.0, 2.0), Vector2(4.0, 5.0)), Color(1.0, 0.8, 0.2))
			_canvas.draw_rect(Rect2(center - Vector2(12.0, 10.0), Vector2(24.0, 19.0)), INK, false)
		App.SHUTDOWN:
			_canvas.draw_arc(center, 8.0, deg_to_rad(-60.0), deg_to_rad(240.0), 16, Color(0.9, 0.25, 0.25), 2.0)
			_canvas.draw_rect(Rect2(center - Vector2(1.0, 10.0), Vector2(2.0, 9.0)), Color(0.9, 0.25, 0.25))
	var label: String = ICONS[index][0]
	var label_width := PixelFont.width(label, 1.0, SMALL)
	var label_at := Vector2(box.position.x + (box.size.x - label_width) * 0.5, box.position.y + 32.0)
	if _icon == index and _app == App.DESKTOP:
		_canvas.draw_rect(Rect2(label_at - Vector2(2.0, 1.0), Vector2(label_width + 4.0, 8.0)), NAVY)
		_canvas.draw_rect(Rect2(center - Vector2(14.0, 13.0), Vector2(28.0, 27.0)), Color(1, 1, 1, 0.5), false)
	_text(label_at, label, Color.WHITE)


## A little carrot (the CARROT OS logo).
func _draw_carrot(where: Vector2, size: float) -> void:
	var orange := Color(1.0, 0.55, 0.2)
	for row in 8:
		var half := (8.0 - row) * 0.5
		_canvas.draw_rect(Rect2(where + Vector2(4.0 - half, 4.0 + row) * size * 2.0, Vector2(half * 2.0, 1.0) * size * 2.0), orange)
	_canvas.draw_rect(Rect2(where + Vector2(3.0, 0.0) * size * 2.0, Vector2(2.0, 4.0) * size * 2.0), Color(0.35, 0.8, 0.35))


## An app window with its title bar; returns the inside.
func _draw_window(title: String) -> Rect2:
	_canvas.draw_rect(WINDOW.grow(1.0), INK)
	_canvas.draw_rect(WINDOW, GRAY)
	_canvas.draw_rect(Rect2(WINDOW.position, Vector2(WINDOW.size.x, 1.0)), Color.WHITE)
	var bar := Rect2(WINDOW.position + Vector2(2.0, 2.0), Vector2(WINDOW.size.x - 4.0, 10.0))
	for i in int(bar.size.x):
		_canvas.draw_rect(Rect2(bar.position + Vector2(i, 0.0), Vector2(1.0, bar.size.y)), NAVY.lerp(TEAL, i / bar.size.x))
	_text(bar.position + Vector2(3.0, 3.0), title, Color.WHITE)
	var close := _close_box()
	_canvas.draw_rect(close, GRAY)
	_text(close.position + Vector2(2.0, 1.0), "X")
	return Rect2(WINDOW.position + Vector2(4.0, 15.0), WINDOW.size - Vector2(8.0, 19.0))


func _close_box() -> Rect2:
	return Rect2(WINDOW.end.x - 12.0, WINDOW.position.y + 3.0, 9.0, 8.0)


func _mail_row(index: int) -> Rect2:
	return Rect2(WINDOW.position.x + 6.0, WINDOW.position.y + 28.0 + index * 12.0, WINDOW.size.x - 12.0, 11.0)


func _draw_mail() -> void:
	var inside := _draw_window("MAIL - INBOX (%d)" % _inbox.size())
	_canvas.draw_rect(inside, PAPER)
	_text(inside.position + Vector2(4.0, 3.0), "FROM", Color(0.4, 0.4, 0.45))
	_text(inside.position + Vector2(96.0, 3.0), "SUBJECT", Color(0.4, 0.4, 0.45))
	if _inbox.is_empty():
		_text(inside.position + Vector2(4.0, 20.0), "NO MAIL. NOBODY WRITES ANY MORE.")
	for i in _inbox.size():
		var row := _mail_row(i)
		if row.end.y > inside.end.y - 10.0:
			break
		var email := _inbox[i]
		var unread := not GameState.has_flag("email_read_" + email.id)
		var ink := INK
		if i == _mail_index:
			_canvas.draw_rect(row, NAVY)
			ink = Color.WHITE
		if unread:
			_canvas.draw_rect(Rect2(row.position + Vector2(1.0, 4.0), Vector2(3.0, 3.0)), Color(0.9, 0.2, 0.25))
		_text(row.position + Vector2(6.0, 3.0), _fit(email.from_name, 78.0), ink)
		_text(row.position + Vector2(90.0, 3.0), _fit(GameState.names.fill_in(email.subject), row.size.x - 92.0), ink)
	_text(Vector2(inside.position.x + 4.0, inside.end.y - 8.0), "E: READ   ESC: BACK", Color(0.4, 0.4, 0.45))


func _draw_letter() -> void:
	var email := _inbox[_mail_index]
	var inside := _draw_window("MAIL - READING")
	_canvas.draw_rect(inside, PAPER)
	_text(inside.position + Vector2(4.0, 4.0), "FROM:    " + email.from_name)
	_text(inside.position + Vector2(4.0, 13.0), "SUBJECT: " + _fit(GameState.names.fill_in(email.subject), inside.size.x - 50.0))
	_canvas.draw_rect(Rect2(inside.position + Vector2(4.0, 22.0), Vector2(inside.size.x - 8.0, 1.0)), Color(0.6, 0.6, 0.65))
	var y := 28.0
	for paragraph in GameState.names.fill_in(email.body).split("\n"):
		for line in PixelFont.wrap(paragraph, inside.size.x - 12.0, 1.0, SMALL):
			_text(inside.position + Vector2(6.0, y), line)
			y += 8.0
		if paragraph.is_empty():
			y += 6.0  # A blank line between paragraphs.
	_text(Vector2(inside.position.x + 4.0, inside.end.y - 8.0), "ESC: BACK TO THE INBOX", Color(0.4, 0.4, 0.45))


func _draw_logs() -> void:
	var inside := _draw_window("OLD LOGS - THE THUMPER'S TRIP COMPUTER")
	_canvas.draw_rect(inside, Color("10221a"))
	var green := Color(0.45, 1.0, 0.55)
	var dim := Color(0.25, 0.6, 0.32)
	_text(inside.position + Vector2(4.0, 3.0), "RECOVERED %d OF %d" % [_logs.size(), TRIP_LOGS.logs.size()], dim)
	if _logs.is_empty():
		_text(inside.position + Vector2(4.0, 20.0), "RECOVERING. IT'S AN OLD MACHINE.", green)
		_text(inside.position + Vector2(4.0, 29.0), "ABOUT ONE A DELIVERY.", green)
	for i in _logs.size():
		var row := _mail_row(i)
		if row.end.y > inside.end.y - 10.0:
			break
		var log_entry := _logs[i]
		var ink := green
		if i == _log_index:
			_canvas.draw_rect(row, green.darkened(0.45))
			ink = Color.WHITE
		if not GameState.has_flag("log_read_" + log_entry.id):
			_canvas.draw_rect(Rect2(row.position + Vector2(1.0, 4.0), Vector2(3.0, 3.0)), Color(1.0, 0.8, 0.3))
		_text(row.position + Vector2(6.0, 3.0), log_entry.day, ink)
		var first := GameState.names.fill_in(log_entry.body).split("\n")[0]
		_text(row.position + Vector2(60.0, 3.0), _fit(first, row.size.x - 62.0), ink)
	var hint := "E: READ   ESC: BACK" + ("   STILL RECOVERING..." if _logs.size() < TRIP_LOGS.logs.size() else "")
	_text(Vector2(inside.position.x + 4.0, inside.end.y - 8.0), hint, dim)


func _draw_log() -> void:
	var log_entry := _logs[_log_index]
	var inside := _draw_window("OLD LOGS - " + log_entry.day)
	_canvas.draw_rect(inside, Color("10221a"))
	var green := Color(0.45, 1.0, 0.55)
	var y := 6.0
	for paragraph in GameState.names.fill_in(log_entry.body).to_upper().split("\n"):
		for line in PixelFont.wrap(paragraph, inside.size.x - 12.0, 1.0, SMALL):
			_text(inside.position + Vector2(6.0, y), line, green)
			y += 8.0
		if paragraph.is_empty():
			y += 6.0  # A blank line between paragraphs.
	_text(Vector2(inside.position.x + 4.0, inside.end.y - 8.0), "ESC: BACK TO THE LOGS", Color(0.25, 0.6, 0.32))


func _draw_invoices() -> void:
	var inside := _draw_window("INVOICES AND BILLS")
	_canvas.draw_rect(inside, PAPER)
	var total := 0
	for invoice in GameState.invoices:
		total += int(invoice["total"])
	_text(inside.position + Vector2(4.0, 3.0), "DELIVERIES: %d   NET: %d %s   %s" % [GameState.deliveries, total, GameState.names.currency_short,
			"TAB: %d" % GameState.tab if GameState.tab > 0 else Economy.calendar_text()], INK)
	_canvas.draw_rect(Rect2(inside.position + Vector2(4.0, 11.0), Vector2(inside.size.x - 8.0, 1.0)), Color(0.6, 0.6, 0.65))
	if GameState.invoices.is_empty():
		_text(inside.position + Vector2(4.0, 20.0), "NOTHING YET. GO HAUL SOMETHING.")
	var row := 0
	for i in range(GameState.invoices.size() - 1, -1, -1):
		var y := inside.position.y + 16.0 + row * 16.0
		if y > inside.end.y - 24.0:
			break
		var invoice: Dictionary = GameState.invoices[i]
		_text(Vector2(inside.position.x + 4.0, y), "%s  %s" % [Economy.short_date_text(int(invoice["day"])), _fit(str(invoice["cargo"]), 150.0)])
		var bill := int(invoice["total"]) < 0  # Weekly bills: money out.
		var who := str(invoice["client"]) if bill else "%s > %s" % [invoice["client"], invoice["to"]]
		_text(Vector2(inside.position.x + 12.0, y + 7.0), _fit(who, 170.0), Color(0.4, 0.4, 0.45))
		var amount := ("%d" if bill else "+%d") % int(invoice["total"])
		_text(Vector2(inside.end.x - 70.0, y + 3.0), amount, Color(0.7, 0.2, 0.2) if bill else Color(0.15, 0.5, 0.25))
		# The PAID stamp.
		_canvas.draw_rect(Rect2(inside.end.x - 32.0, y + 1.0, 26.0, 10.0), Color(0.8, 0.2, 0.2), false)
		_text(Vector2(inside.end.x - 29.0, y + 3.0), "PAID", Color(0.8, 0.2, 0.2))
		row += 1
	_text(Vector2(inside.position.x + 4.0, inside.end.y - 8.0), "ESC: BACK", Color(0.4, 0.4, 0.45))


func _draw_game() -> void:
	var inside := _draw_window("ASTEROID ALLEY")
	_canvas.draw_rect(inside, Color("0d0b1a"))
	var field := Rect2(inside.position + Vector2((inside.size.x - AsteroidAlley.WIDTH) * 0.5, 4.0), Vector2(AsteroidAlley.WIDTH, AsteroidAlley.HEIGHT))
	_canvas.draw_rect(field, Color("15112a"))
	for star in _game.stars:
		_canvas.draw_rect(Rect2(field.position + star, Vector2.ONE), Color(1, 1, 1, 0.6))
	for lane in range(1, AsteroidAlley.LANES):
		var x := field.position.x + AsteroidAlley.WIDTH * lane / AsteroidAlley.LANES
		for y in range(0, int(field.size.y), 8):
			_canvas.draw_rect(Rect2(x, field.position.y + y, 1.0, 4.0), Color(0.4, 0.4, 0.6, 0.5))
	for thing in _game.things:
		var spot := field.position + Vector2(AsteroidAlley.lane_x(int(thing["lane"])), float(thing["y"]))
		if spot.y < field.position.y - 8.0 or spot.y > field.end.y + 8.0:
			continue
		if thing["kind"] == "rock":
			_canvas.draw_circle(spot, 7.0, Color("6e5546"))
			_canvas.draw_circle(spot + Vector2(-2.0, -2.0), 4.0, Color("9a7b62"))
		else:
			_canvas.draw_rect(Rect2(spot - Vector2(3.0, 4.0), Vector2(6.0, 8.0)), Color(1.0, 0.8, 0.2))
			_canvas.draw_rect(Rect2(spot - Vector2(1.0, 6.0), Vector2(2.0, 2.0)), Color(0.9, 0.3, 0.2))
	# The little rig: a cab, a trailer and an engine glow.
	var rig := field.position + Vector2(_game.rig_x, AsteroidAlley.RIG_Y)
	_canvas.draw_rect(Rect2(rig - Vector2(4.0, 8.0), Vector2(8.0, 6.0)), Color(0.9, 0.3, 0.3))
	_canvas.draw_rect(Rect2(rig - Vector2(5.0, 2.0), Vector2(10.0, 9.0)), Color(0.85, 0.85, 0.9))
	_canvas.draw_rect(Rect2(rig + Vector2(-3.0, 7.0), Vector2(6.0, 2.0 + 2.0 * absf(sin(_time * 20.0)))), Color(1.0, 0.6, 0.2))
	# Scores beside the field.
	var side := Vector2(inside.position.x + 6.0, inside.position.y + 8.0)
	_text(side, "SCORE", Color(0.6, 0.6, 0.8))
	_text(side + Vector2(0.0, 8.0), str(_game.score), Color.WHITE)
	_text(side + Vector2(0.0, 24.0), "BEST", Color(0.6, 0.6, 0.8))
	_text(side + Vector2(0.0, 32.0), str(maxi(GameState.pc_high_score, _game.score)), Color(1.0, 0.85, 0.3))
	_text(Vector2(field.end.x + 6.0, inside.position.y + 8.0), "< > HOP", Color(0.6, 0.6, 0.8))
	_text(Vector2(field.end.x + 6.0, inside.position.y + 16.0), "ESC QUIT", Color(0.6, 0.6, 0.8))
	match _game.state:
		AsteroidAlley.State.TITLE:
			_banner(field, "ASTEROID ALLEY", "E: START")
		AsteroidAlley.State.OVER:
			_banner(field, "BONK!", "SCORE %d   E: AGAIN" % _game.score)


func _banner(field: Rect2, title: String, hint: String) -> void:
	var middle := field.get_center()
	_canvas.draw_rect(Rect2(field.position.x, middle.y - 16.0, field.size.x, 30.0), Color(0, 0, 0, 0.7))
	PixelFont.draw_centered(_canvas, middle - Vector2(0.0, 6.0), title, 1.0, Color(1.0, 0.6, 0.25), 0.0, Color(0, 0, 0, 0))
	PixelFont.draw_centered(_canvas, middle + Vector2(0.0, 7.0), hint, 1.0, Color.WHITE, 0.0, Color(0, 0, 0, 0), SMALL)


## Cuts `text` short (with "..") so it fits in `width` screen pixels.
func _fit(text: String, width: float) -> String:
	if PixelFont.width(text, 1.0, SMALL) <= width:
		return text
	while text.length() > 1 and PixelFont.width(text + "..", 1.0, SMALL) > width:
		text = text.left(text.length() - 1)
	return text + ".."
