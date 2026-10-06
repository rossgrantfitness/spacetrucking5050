class_name HubHUD
extends CanvasLayer
## The little on-foot HUD: when the bunny can use something (talk to someone,
## board the ship), a bouncing "!" pops up over it and a prompt at the bottom
## of the screen says which button to press. Your wallet sits top-right, and
## short messages ("NOT WHILE WE'RE MOVING.") show at the top.
##
## Top-left: what you're meant to be doing (Objective.gd), with a yellow
## diamond bobbing over the door or stairs it points to in this room, and
## a "!" over the person it means. Anyone with a job for you has a "!" too.


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
	_draw_objective()
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


## The objective line (top-left) and the markers over people and places.
func _draw_objective() -> void:
	if Dialogue.is_active():
		return
	var goal := Objective.current(false)
	var words := "> " + str(goal["text"])
	var square := 2.0
	var box := Rect2(Vector2(24.0, 24.0), Vector2(PixelFont.width(words, square) + 24.0, 28.0))
	_canvas.draw_rect(box, Color(0.05, 0.06, 0.2, 0.75))
	_canvas.draw_rect(Rect2(box.position, Vector2(4.0, box.size.y)), PROMPT_COLOR)
	PixelFont.draw(_canvas, box.position + Vector2(14.0, 7.0), words, square, PROMPT_COLOR, 0.15)
	var camera := get_viewport().get_camera_3d()
	if camera == null or player == null:
		return
	var nearest := player.nearest_interactable() if not player.is_busy() else null
	var target: String = goal["target"]
	for node in get_tree().get_nodes_in_group("interactable"):
		var thing := node as Interactable
		if thing == null or thing == nearest or thing.get_viewport() != get_viewport() or not thing.is_visible_in_tree():
			continue
		# A "!" over people with a job for you or who the objective means; a
		# diamond over the door or stairs it means.
		var npc := thing as NPC
		var aimed := _is_target(thing, target)
		if npc != null and (aimed or npc.has_news()):
			_marker(camera, thing.global_position + Vector3.UP * 1.9, true)
		elif aimed:
			_marker(camera, thing.global_position + Vector3.UP * 0.5, false)


## Whether `thing` is what the objective points at (see Objective.gd).
func _is_target(thing: Interactable, target: String) -> bool:
	if target.is_empty():
		return false
	var exit := thing as RoomExit
	match target:
		"wheel":
			return exit != null and exit.target_scene.ends_with("FlightSandbox.tscn")
		"airlock":
			# The rig's airlock, or (in a station) the door back aboard the rig.
			var room := HubRoom.find(thing)
			var in_station := room != null and not room.scene_file_path in HubRoom.RIG_ROOMS
			return exit != null and (exit.to_docked_place or (in_station and exit.target_scene in HubRoom.RIG_ROOMS))
	var npc := thing as NPC
	return target.begins_with("npc:") and npc != null and npc.data != null and npc.data.resource_path.get_file().get_basename() == target.trim_prefix("npc:")


## A bobbing marker over a spot: a "!" (someone has news) or a diamond
## (where the objective points).
func _marker(camera: Camera3D, where: Vector3, news: bool) -> void:
	if camera.is_position_behind(where):
		return
	var spot := camera.unproject_position(where) + Vector2(0.0, sin(_time * 4.0) * 5.0)
	if news:
		# Solid yellow with a dark "!" (the "you could use this" marker over
		# whatever's nearest is dark with a yellow one, so they don't mix up).
		_canvas.draw_rect(Rect2(spot - Vector2(15, 21), Vector2(30, 38)), Color(0.05, 0.06, 0.2, 0.9))
		_canvas.draw_rect(Rect2(spot - Vector2(12, 18), Vector2(24, 32)), PROMPT_COLOR)
		PixelFont.draw_centered(_canvas, spot - Vector2(0, 2), "!", 4.0, Color(0.08, 0.06, 0.15))
		return
	var r := 11.0
	var diamond := PackedVector2Array([spot + Vector2(0, -r), spot + Vector2(r * 0.75, 0), spot + Vector2(0, r), spot + Vector2(-r * 0.75, 0)])
	var outline := PackedVector2Array([spot + Vector2(0, -r - 3), spot + Vector2(r * 0.75 + 3, 0), spot + Vector2(0, r + 3), spot + Vector2(-r * 0.75 - 3, 0)])
	_canvas.draw_colored_polygon(outline, Color(0.05, 0.06, 0.2, 0.85))
	_canvas.draw_colored_polygon(diamond, PROMPT_COLOR)


## How much money you have, top-right.
func _draw_wallet() -> void:
	var text := "%d %s" % [GameState.credits, GameState.names.currency_short]
	var square := 3.0
	var width := PixelFont.width(text, square)
	var box := Rect2(Vector2(_canvas.size.x - width - 52.0, 24.0), Vector2(width + 28.0, 36.0))
	_canvas.draw_rect(box, Color(0.05, 0.06, 0.2, 0.75))
	PixelFont.draw(_canvas, box.position + Vector2(14.0, 8.0), text, square, Color(0.4, 1.0, 0.5), 0.15)
	# Under it: the clock, the date, when the bills are due, and any tab.
	# Two colors only: gold for the date and anything owed, soft white for
	# the rest.
	var gold := Color(1.0, 0.85, 0.3)
	var soft := Color(0.78, 0.8, 0.92)
	var lines := [[Economy.clock_text(), 2.0, soft], [Economy.date_text(), 2.0, gold],
			["BILLS IN %d DAY%s" % [Economy.days_to_bills(), "" if Economy.days_to_bills() == 1 else "S"], 2.0, soft]]
	if GameState.tab > 0:
		lines.append(["TAB %d %s" % [GameState.tab, GameState.names.currency_short], 2.0, gold])
	# Aboard your rig: which one (its rooms are tinted its own color too).
	var room := HubRoom.find(player)
	if room != null and room.scene_file_path in HubRoom.RIG_ROOMS:
		var rig := GameState.active_ship_data()
		lines.append([rig.display_name.to_upper().split(" (")[0], 2.0, soft])
	var widest := 0.0
	for line: Array in lines:
		widest = maxf(widest, PixelFont.width(line[0], line[1]))
	var panel := Rect2(Vector2(box.end.x - widest - 24.0, box.end.y + 6.0), Vector2(widest + 24.0, 18.0 + lines.size() * 21.0))
	_canvas.draw_rect(panel, Color(0.05, 0.06, 0.2, 0.6))
	var y := panel.position.y + 9.0
	for line: Array in lines:
		var line_width := PixelFont.width(line[0], line[1])
		PixelFont.draw(_canvas, Vector2(panel.end.x - line_width - 12.0, y), line[0], line[1], line[2], 0.15)
		y += 21.0
