class_name HubHUD
extends CanvasLayer
## The little on-foot HUD: when the bunny can use something (talk to someone,
## board the ship), a bouncing "!" pops up over it and a prompt at the bottom
## of the screen says which button to press. Your wallet sits top-right, and
## short messages ("NOT WHILE WE'RE MOVING.") show at the top.


const PROMPT_COLOR := Color(1.0, 0.85, 0.25)

## The player to watch. Set by HubRoom.
var player: HubPlayer

var _canvas: Control
var _time := 0.0
var _notice: String = ""
var _notice_left: float = 0.0


## Shows a short message at the top of the screen for `seconds`.
func show_notice(text: String, seconds: float = 2.5) -> void:
	_notice = text
	_notice_left = seconds


func _ready() -> void:
	layer = 10
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_prompt)
	add_child(_canvas)


func _process(delta: float) -> void:
	_time += delta
	_notice_left -= delta
	_canvas.queue_redraw()


func _draw_prompt() -> void:
	_draw_wallet()
	if _notice_left > 0.0 and not _notice.is_empty():
		var notice_width := PixelFont.width(_notice, 3.0)
		var notice_box := Rect2(Vector2((_canvas.size.x - notice_width) * 0.5 - 16.0, 70.0), Vector2(notice_width + 32.0, 40.0))
		_canvas.draw_rect(notice_box, Color(0.05, 0.06, 0.2, 0.85))
		_canvas.draw_rect(notice_box, Color(1.0, 0.45, 0.4), false, 2.0)
		PixelFont.draw(_canvas, notice_box.position + Vector2(16.0, 9.0), _notice, 3.0, Color.WHITE, 0.15)
	if player == null or player.is_busy() or Dialogue.is_active():
		return
	var target := player.nearest_interactable()
	var camera := get_viewport().get_camera_3d()
	if target == null or camera == null:
		return
	# A bouncing "!" over the thing.
	var above := target.global_position + Vector3.UP * 1.9
	if not camera.is_position_behind(above):
		var spot := camera.unproject_position(above) + Vector2(0.0, sin(_time * 5.0) * 4.0)
		_canvas.draw_rect(Rect2(spot - Vector2(14, 20), Vector2(28, 36)), Color(0.05, 0.06, 0.2, 0.9))
		_canvas.draw_rect(Rect2(spot - Vector2(14, 20), Vector2(28, 36)), Color.WHITE, false, 2.0)
		PixelFont.draw_centered(_canvas, spot - Vector2(0, 2), "!", 4.0, PROMPT_COLOR)
	# The button prompt at the bottom.
	var text := "E / A  " + target.prompt
	var size := _canvas.size
	var square := 3.0
	var width := PixelFont.width(text, square)
	var box := Rect2(Vector2((size.x - width) * 0.5 - 16.0, size.y - 86.0), Vector2(width + 32.0, 40.0))
	_canvas.draw_rect(box, Color(0.05, 0.06, 0.2, 0.85))
	_canvas.draw_rect(box, PROMPT_COLOR, false, 2.0)
	PixelFont.draw(_canvas, box.position + Vector2(16.0, 9.0), text, square, Color.WHITE, 0.15)


## How much money you have, top-right.
func _draw_wallet() -> void:
	var text := "%d %s" % [GameState.credits, GameState.names.currency_short]
	var square := 3.0
	var width := PixelFont.width(text, square)
	var box := Rect2(Vector2(_canvas.size.x - width - 52.0, 24.0), Vector2(width + 28.0, 36.0))
	_canvas.draw_rect(box, Color(0.05, 0.06, 0.2, 0.75))
	PixelFont.draw(_canvas, box.position + Vector2(14.0, 8.0), text, square, Color(0.4, 1.0, 0.5), 0.15)
	# Under it: the clock, the date, when the bills are due, and any tab.
	var lines := [[Economy.clock_text(), 3.0, Color(0.45, 0.95, 1.0)], [Economy.date_text(), 2.0, Color(1.0, 0.85, 0.3)],
			["BILLS IN %d DAY%s" % [Economy.days_to_bills(), "" if Economy.days_to_bills() == 1 else "S"], 2.0, Color(0.7, 0.75, 0.95)]]
	if GameState.tab > 0:
		lines.append(["TAB %d %s" % [GameState.tab, GameState.names.currency_short], 2.0, Color(1.0, 0.7, 0.4)])
	# Aboard your rig: which one (its rooms are tinted its own color too).
	var room := HubRoom.find(player)
	if room != null and room.scene_file_path in HubRoom.RIG_ROOMS:
		var rig := GameState.active_ship_data()
		lines.append([rig.display_name.to_upper().split(" (")[0], 2.0, rig.interior_tint.lerp(Color(0.7, 0.75, 0.95), 0.3)])
	var widest := 0.0
	for line: Array in lines:
		widest = maxf(widest, PixelFont.width(line[0], line[1]))
	var panel := Rect2(Vector2(box.end.x - widest - 24.0, box.end.y + 6.0), Vector2(widest + 24.0, 22.0 + lines.size() * 21.0))
	_canvas.draw_rect(panel, Color(0.05, 0.06, 0.2, 0.6))
	var y := panel.position.y + 9.0
	for line: Array in lines:
		var line_width := PixelFont.width(line[0], line[1])
		PixelFont.draw(_canvas, Vector2(panel.end.x - line_width - 12.0, y), line[0], line[1], line[2], 0.15)
		y += 21.0 + (4.0 if line[1] > 2.0 else 0.0)
