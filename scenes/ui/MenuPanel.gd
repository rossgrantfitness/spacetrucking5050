class_name MenuPanel
extends CanvasLayer
## A pop-up list to pick from: the job board, a shop, the jukebox, "take
## the job?". Arrow keys / D-pad to move, E / A / Enter to pick, Esc / B to
## back out. The mouse works too.
##
## Use it with:
##     var choice := await MenuPanel.ask(get_tree(), "TITLE", "Some words.", options)
## where each option is {"text": "...", "detail": "...", "disabled": false,
## "description": "..."}. It returns the chosen option's number, or -1 if
## the player backed out.
##
## Pass a `side` Control (like the course chart's map) to show it next to
## the list; it hears `focused(index)` as the player moves through the list.


signal chosen(index: int)
## The player moved to option number `index` (for a side panel to follow).
signal focused(index: int)

const TITLE_COLOR := Color(1.0, 0.85, 0.25)
const BOX_COLOR := Color(0.05, 0.06, 0.2, 0.95)

var _title: String = ""
var _body: String = ""
var _options: Array = []
var _buttons: Array[Button] = []
var _description: Label
var _done: bool = false
var _shown := false
var _side: Control


## Shows a menu and waits for the player's pick (-1 = backed out).
static func ask(tree: SceneTree, title: String, body: String, options: Array, side: Control = null) -> int:
	var panel := MenuPanel.new()
	panel._title = title
	panel._body = body
	panel._options = options
	panel._side = side
	if side != null and side.has_method("show_option"):
		panel.focused.connect(Callable(side, "show_option"))
	tree.root.add_child(panel)
	var index: int = await panel.chosen
	panel.queue_free()
	return index


func _ready() -> void:
	layer = 35
	process_mode = Node.PROCESS_MODE_ALWAYS
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.05, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(700.0, 0.0)
	var style := StyleBoxFlat.new()
	style.bg_color = BOX_COLOR
	style.border_color = Color(0.85, 0.88, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(24.0)
	box.add_theme_stylebox_override("panel", style)
	if _side != null:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		center.add_child(row)
		row.add_child(_side)
		row.add_child(box)
	else:
		center.add_child(box)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	box.add_child(column)
	column.add_child(_label(_title, 30, TITLE_COLOR))
	if not _body.is_empty():
		var body := _label(_body, 20, Color(0.9, 0.92, 1.0))
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(body)
	# Long lists (like the jukebox) scroll; the list follows the focus.
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	if _options.size() > 8:
		var scroller := ScrollContainer.new()
		scroller.follow_focus = true
		scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroller.custom_minimum_size = Vector2(0.0, 400.0)
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroller.add_child(list)
		column.add_child(scroller)
	else:
		column.add_child(list)
	for i in _options.size():
		var option: Dictionary = _options[i]
		var button := Button.new()
		var detail: String = option.get("detail", "")
		button.text = option.get("text", "?") + ("    " + detail if not detail.is_empty() else "")
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = option.get("disabled", false)
		button.add_theme_font_size_override("font_size", 22)
		_style_button(button)
		button.pressed.connect(_pick.bind(i))
		button.focus_entered.connect(_describe.bind(i))
		button.mouse_entered.connect(button.grab_focus)
		list.add_child(button)
		_buttons.append(button)
	_description = _label("", 18, Color(0.6, 0.95, 1.0))
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.custom_minimum_size = Vector2(0.0, 48.0)
	column.add_child(_description)
	column.add_child(_label("Arrows / D-pad: choose   ·   E / A: pick   ·   Esc / B: back", 16, Color(0.7, 0.72, 0.85)))
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_focus_first()
	_shown = true  # (From now on, moving between buttons ticks.)


func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_pick(-1)
	elif event.is_action_pressed("interact") and not event.is_echo():
		var button := get_viewport().gui_get_focus_owner() as Button
		if button != null and not button.disabled:
			get_viewport().set_input_as_handled()
			button.pressed.emit()


func _pick(index: int) -> void:
	if _done:
		return
	_done = true
	Sfx.play("ui_confirm" if index >= 0 else "ui_back")
	chosen.emit(index)


func _describe(index: int) -> void:
	if _shown:
		Sfx.play("ui_move", -6.0)
	_description.text = (_options[index] as Dictionary).get("description", "")
	focused.emit(index)


func _focus_first() -> void:
	for button in _buttons:
		if not button.disabled:
			button.grab_focus()
			return


func _label(words: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = words
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _style_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.1, 0.12, 0.3, 0.9)
	normal.set_content_margin_all(10.0)
	normal.set_corner_radius_all(4)
	var focus := normal.duplicate() as StyleBoxFlat
	focus.bg_color = Color(0.2, 0.22, 0.5, 1.0)
	focus.border_color = TITLE_COLOR
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", focus)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_stylebox_override("pressed", focus)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_color_override("font_color", Color(0.95, 0.96, 1.0))
	button.add_theme_color_override("font_focus_color", TITLE_COLOR)
	button.add_theme_color_override("font_hover_color", TITLE_COLOR)
	button.add_theme_color_override("font_disabled_color", Color(0.5, 0.52, 0.65))
