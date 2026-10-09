class_name RetroUI
## The look of every menu and dialogue box, after late-90s console RPG menus:
## beveled blue windows with a woven gradient (RetroWindowStyle.gd), white
## pixel lettering with a black drop shadow (MenuFont.gd), options with no
## boxes around them, and a white-gloved hand pointing at the one you're on
## (GlovePointer.gd). The flight HUD keeps its own Wipeout-style look.
##
## Give a menu the look with `control.theme = RetroUI.theme()`, a window
## with `RetroUI.window()`, and the pointer with RetroUI.add_pointer(menu).

const MENU_FONT: FontFile = preload("res://fonts/menu_font.tres")
## The menu font is 10 pixels tall; it's drawn 2x (20) or 3x (30).
const TEXT_SIZE: int = 20
const BIG_SIZE: int = 30
## Text colors: white, the soft gold of titles and names, and greyed out.
const WHITE := Color(1.0, 1.0, 1.0)
const GOLD := Color(1.0, 0.86, 0.45)
const GREY := Color(0.62, 0.66, 0.8)
const SHADOW := Color(0.0, 0.0, 0.0, 0.92)

static var _theme: Theme


## The shared look for menus and dialogue (built once).
static func theme() -> Theme:
	if _theme != null:
		return _theme
	var look := Theme.new()
	look.default_font = MENU_FONT
	look.default_font_size = TEXT_SIZE
	for type: String in ["Label", "RichTextLabel"]:
		look.set_color("font_color" if type == "Label" else "default_color", type, WHITE)
		look.set_color("font_shadow_color", type, SHADOW)
		look.set_constant("shadow_offset_x", type, 2)
		look.set_constant("shadow_offset_y", type, 2)
		look.set_constant("shadow_outline_size", type, 0)
		look.set_constant("outline_size", type, 0)
	look.set_stylebox("panel", "PanelContainer", window())
	look.set_stylebox("panel", "Panel", window())
	# Options are just words: no boxes. Room on the left for the glove.
	for type: String in ["Button", "CheckButton", "CheckBox", "OptionButton"]:
		var plain := StyleBoxEmpty.new()
		plain.content_margin_left = 40.0
		plain.content_margin_right = 8.0
		plain.content_margin_top = 4.0
		plain.content_margin_bottom = 4.0
		for state: String in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed", "normal_mirrored", "hover_mirrored", "pressed_mirrored", "hover_pressed_mirrored", "disabled_mirrored"]:
			look.set_stylebox(state, type, plain)
		look.set_color("font_color", type, WHITE)
		look.set_color("font_hover_color", type, WHITE)
		look.set_color("font_focus_color", type, WHITE)
		look.set_color("font_pressed_color", type, WHITE)
		look.set_color("font_hover_pressed_color", type, WHITE)
		look.set_color("font_disabled_color", type, GREY)
		look.set_color("font_outline_color", type, SHADOW)
		look.set_constant("outline_size", type, 0)
	# Little pixel switches for the on / off options.
	look.set_icon("checked", "CheckButton", _switch(true))
	look.set_icon("unchecked", "CheckButton", _switch(false))
	look.set_icon("checked", "CheckBox", _switch(true))
	look.set_icon("unchecked", "CheckBox", _switch(false))
	# Sliders and scroll bars in the window's colors.
	var groove := StyleBoxFlat.new()
	groove.bg_color = Color(0.06, 0.08, 0.25)
	groove.border_color = Color(0.45, 0.5, 0.68)
	groove.set_border_width_all(1)
	groove.content_margin_top = 3.0
	groove.content_margin_bottom = 3.0
	var filled := groove.duplicate() as StyleBoxFlat
	filled.bg_color = Color(0.6, 0.7, 1.0)
	look.set_stylebox("slider", "HSlider", groove)
	look.set_stylebox("grabber_area", "HSlider", filled)
	look.set_stylebox("grabber_area_highlight", "HSlider", filled)
	look.set_icon("grabber", "HSlider", _knob(WHITE))
	look.set_icon("grabber_highlight", "HSlider", _knob(GOLD))
	var bar := groove.duplicate() as StyleBoxFlat
	bar.content_margin_left = 3.0
	bar.content_margin_right = 3.0
	var thumb := StyleBoxFlat.new()
	thumb.bg_color = Color(0.85, 0.88, 1.0)
	thumb.set_corner_radius_all(2)
	for type: String in ["VScrollBar", "HScrollBar"]:
		look.set_stylebox("scroll", type, bar)
		look.set_stylebox("grabber", type, thumb)
		look.set_stylebox("grabber_highlight", type, thumb)
		look.set_stylebox("grabber_pressed", type, thumb)
	_theme = look
	return _theme


## The maker's plate on the main menu screens (an invented brand: every
## terminal in the galaxy seems to be one of these).
const MAKER_PLATE: String = "Haultec Terminal 5050"


## A fresh window frame: a terminal screen in a metal bezel (see
## RetroWindowStyle.gd). `plate` is stamped on the bezel ("" = none).
static func window(plate: String = "") -> RetroWindowStyle:
	var frame := RetroWindowStyle.new()
	frame.plate_text = plate
	return frame


## A smaller, plainer screen (help boxes, name tags): a thin bezel, no tape,
## no LED.
static func small_window() -> RetroWindowStyle:
	var frame := RetroWindowStyle.new()
	frame.bezel = 11.0
	frame.corner_radius = 8.0
	frame.hazard_tape = false
	frame.power_led = false
	frame.content_margin_left = 24.0
	frame.content_margin_right = 24.0
	frame.content_margin_top = 18.0
	frame.content_margin_bottom = 18.0
	return frame


## Switches a screen on like an old CRT: a bright line that opens up into
## the picture. Call it as a menu or box appears.
static func power_on(screen: Control) -> void:
	if not screen.is_inside_tree():
		return
	screen.modulate = Color(1.0, 1.0, 1.0, 0.0)
	await screen.get_tree().process_frame  # (So it knows its size.)
	if not is_instance_valid(screen):
		return
	screen.pivot_offset = screen.size * 0.5
	screen.scale = Vector2(1.0, 0.03)
	screen.modulate = Color(1.8, 1.8, 1.8, 1.0)
	var tween := screen.create_tween().set_parallel()
	tween.tween_property(screen, "scale", Vector2.ONE, 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(screen, "modulate", Color.WHITE, 0.22)


## Adds the white glove that points at whichever option of `menu` has the
## focus. Returns it.
static func add_pointer(menu: Control) -> GlovePointer:
	var glove := GlovePointer.new()
	glove.name = "GlovePointer"
	glove.scope = menu
	menu.add_child(glove)
	return glove


## Dresses an existing menu (one made in the editor, like the pause menu)
## in the look: the theme on `root`, every button's words left-aligned with
## a drop shadow, and the glove pointing at the focused one.
static func dress(root: Control) -> void:
	root.theme = theme()
	for node in root.find_children("*", "BaseButton", true, false):
		var button := node as Button
		if button == null or button.has_node("TextShadow"):
			continue
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var shadow := ButtonShadow.new()
		shadow.name = "TextShadow"
		button.add_child(shadow)
	add_pointer(root)


## A button's words again in black, two pixels down and right, behind the
## button's own words: the drop shadow (buttons can't draw one themselves).
## It keeps up with the button's text as it changes.
class ButtonShadow extends Label:
	func _ready() -> void:
		show_behind_parent = true
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)
		vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_theme_color_override("font_color", SHADOW)
		add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
		_follow()

	func _process(_delta: float) -> void:
		_follow()

	func _follow() -> void:
		var button := get_parent() as Button
		if button == null:
			return
		text = button.text
		horizontal_alignment = button.alignment
		add_theme_font_size_override("font_size", button.get_theme_font_size("font_size"))
		var box := button.get_theme_stylebox("normal")
		offset_left = (box.content_margin_left if box != null else 0.0) + 2.0
		offset_right = -(box.content_margin_right if box != null else 0.0) + 2.0
		offset_top = 2.0
		offset_bottom = 2.0
		visible = not button.disabled


## A label in the menu look: white (or `color`) with the drop shadow.
static func label(words: String, font_size: int = TEXT_SIZE, color: Color = WHITE) -> Label:
	var text := Label.new()
	text.text = words
	text.add_theme_font_override("font", MENU_FONT)
	text.add_theme_font_size_override("font_size", font_size)
	text.add_theme_color_override("font_color", color)
	text.add_theme_color_override("font_shadow_color", SHADOW)
	text.add_theme_constant_override("shadow_offset_x", 2 if font_size < BIG_SIZE else 3)
	text.add_theme_constant_override("shadow_offset_y", 2 if font_size < BIG_SIZE else 3)
	return text


## An on / off switch: a little dark box, lit with a white check when on.
static func _switch(on: bool) -> ImageTexture:
	var picture := [
		"kkkkkkkkkkkk",
		"kbbbbbbbbbbk",
		"kbbbbbbbbwwk" if on else "kbbbbbbbbbbk",
		"kbbbbbbbwwbk" if on else "kbbbbbbbbbbk",
		"kbwwbbbwwbbk" if on else "kbbbbbbbbbbk",
		"kbbwwbwwbbbk" if on else "kbbbbbbbbbbk",
		"kbbbwwwbbbbk" if on else "kbbbbbbbbbbk",
		"kbbbbwbbbbbk" if on else "kbbbbbbbbbbk",
		"kbbbbbbbbbbk",
		"kkkkkkkkkkkk",
	]
	return _picture(picture, {"k": Color(0.85, 0.88, 1.0), "b": Color(0.05, 0.07, 0.22), "w": WHITE}, 2)


static func _knob(color: Color) -> ImageTexture:
	return _picture(["kkkkkk", "kwwwwk", "kwwwwk", "kwwwwk", "kwwwwk", "kkkkkk"], {"k": Color(0.05, 0.05, 0.1), "w": color}, 2)


static func _picture(rows: Array, colors: Dictionary, scale: int) -> ImageTexture:
	var image := Image.create(rows[0].length() * scale, rows.size() * scale, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in rows.size():
		var line: String = rows[y]
		for x in line.length():
			if colors.has(line[x]):
				image.fill_rect(Rect2i(x * scale, y * scale, scale, scale), colors[line[x]])
	return ImageTexture.create_from_image(image)
