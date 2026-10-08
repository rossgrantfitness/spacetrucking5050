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

const TITLE_COLOR := RetroUI.GOLD

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
	shade.color = Color(0.0, 0.0, 0.05, 0.4)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.theme = RetroUI.theme()
	add_child(center)
	# Two windows, stacked: the menu itself, and a little help window under it
	# that describes the option you're on (like an old RPG menu).
	var windows := VBoxContainer.new()
	windows.add_theme_constant_override("separation", 6)
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(700.0, 0.0)
	var frame := RetroUI.window()
	frame.content_margin_left = 26.0
	frame.content_margin_right = 26.0
	frame.content_margin_top = 18.0
	frame.content_margin_bottom = 18.0
	box.add_theme_stylebox_override("panel", frame)
	windows.add_child(box)
	if _side != null:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		center.add_child(row)
		row.add_child(_side)
		row.add_child(windows)
	else:
		center.add_child(windows)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	box.add_child(column)
	column.add_child(_label(_title, RetroUI.BIG_SIZE, TITLE_COLOR))
	if not _body.is_empty():
		var body := _label(_body, RetroUI.TEXT_SIZE, RetroUI.WHITE)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(body)
	# Long lists (like the jukebox), or lists too tall for the screen (a
	# small window, or big menus), scroll; the list follows the focus.
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 2)
	var room := maxf(get_viewport().get_visible_rect().size.y - 330.0, 140.0)
	if _options.size() > 8 or _options.size() * 40.0 > room:
		var scroller := ScrollContainer.new()
		scroller.follow_focus = true
		scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroller.custom_minimum_size = Vector2(0.0, minf(400.0, room))
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroller.add_child(list)
		column.add_child(scroller)
	else:
		column.add_child(list)
	for i in _options.size():
		var option: Dictionary = _options[i]
		var color: Color = option.get("color", RetroUI.WHITE)
		var button := option_row(str(option.get("text", "?")), str(option.get("detail", "")), color)
		button.disabled = option.get("disabled", false)
		if button.disabled:
			for words in button.get_children():
				(words as Label).add_theme_color_override("font_color", RetroUI.GREY)
		button.pressed.connect(_pick.bind(i))
		button.focus_entered.connect(_describe.bind(i))
		button.mouse_entered.connect(button.grab_focus)
		list.add_child(button)
		_buttons.append(button)
	RetroUI.add_pointer(box)
	var help := PanelContainer.new()
	var help_frame := RetroUI.window()
	help_frame.content_margin_top = 10.0
	help_frame.content_margin_bottom = 10.0
	help.add_theme_stylebox_override("panel", help_frame)
	help.custom_minimum_size = Vector2(700.0, 0.0)
	windows.add_child(help)
	var help_column := VBoxContainer.new()
	help_column.add_theme_constant_override("separation", 4)
	help.add_child(help_column)
	_description = _label("", RetroUI.TEXT_SIZE, RetroUI.WHITE)
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.custom_minimum_size = Vector2(0.0, 44.0)
	help_column.add_child(_description)
	help_column.add_child(_label("Arrows / D-pad: choose   E / A: pick   Esc / B: back", RetroUI.TEXT_SIZE, RetroUI.GREY))
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_focus_first()
	_shown = true  # (From now on, moving between buttons ticks.)


## One option in the menu look: its words on the left (white with a drop
## shadow), an optional detail on the right (a price, a distance), and room
## on the left for the glove. Public so other menus can use it.
static func option_row(words: String, detail: String = "", color: Color = RetroUI.WHITE) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_ALL
	button.theme = RetroUI.theme()
	var text := RetroUI.label(words, RetroUI.TEXT_SIZE, color)
	text.set_anchors_preset(Control.PRESET_FULL_RECT)
	text.offset_left = 40.0
	text.offset_right = -8.0
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(text)
	var width := 40.0 + text.get_combined_minimum_size().x + 16.0
	if not detail.is_empty():
		var extra := RetroUI.label(detail, RetroUI.TEXT_SIZE, color)
		extra.set_anchors_preset(Control.PRESET_FULL_RECT)
		extra.offset_left = 40.0
		extra.offset_right = -8.0
		extra.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		extra.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		extra.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(extra)
		width += extra.get_combined_minimum_size().x + 40.0
	button.custom_minimum_size = Vector2(width, text.get_combined_minimum_size().y + 10.0)
	return button


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
	return RetroUI.label(words, font_size, color)
