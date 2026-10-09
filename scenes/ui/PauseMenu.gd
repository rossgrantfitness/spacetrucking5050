class_name PauseMenu
extends CanvasLayer
## A small pause menu: keep going, look up the controls, flip a few comfort
## switches, or head somewhere else. It works with the mouse, the keyboard (arrows + Enter) or
## a gamepad (D-pad + A). (The full options menu comes in M10.)
##
## Used in flight and on foot; `flying` decides which buttons show.
##
## Opens and closes with Esc / Start; B / Esc also closes it.


signal resumed
signal back_to_start_pressed
signal dock_pressed
signal quit_to_title_pressed

## On in flight: shows "Back to the start" and "Get towed to the truck stop", and the
## flying-only switches.
@export var flying: bool = true

@onready var _resume: Button = %Resume
@onready var _invert_y: CheckButton = %InvertY
@onready var _camera_roll: CheckButton = %CameraRoll
@onready var _show_hud: CheckButton = %ShowHud
@onready var _screen_shake: CheckButton = %ScreenShake
@onready var _rumble: CheckButton = %Rumble
@onready var _radio_volume: HSlider = %RadioVolume
@onready var _sfx_volume: HSlider = %SfxVolume
@onready var _voice_volume: HSlider = %VoiceVolume
@onready var _dock: Button = %DockAtBase
@onready var _logbook: Button = %Logbook
@onready var _controls: Button = %Controls
@onready var _back_to_start: Button = %BackToStart
@onready var _quit_to_title: Button = %QuitToTitle


func _ready() -> void:
	# Keep working while the rest of the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	# Show the saved settings first, THEN start listening for changes.
	_invert_y.button_pressed = Settings.invert_y
	_camera_roll.button_pressed = Settings.camera_roll
	_show_hud.button_pressed = Settings.show_hud
	_screen_shake.button_pressed = Settings.screen_shake
	_rumble.button_pressed = Settings.rumble
	_radio_volume.value = Settings.radio_volume
	_sfx_volume.value = Settings.sfx_volume
	_voice_volume.value = Settings.voice_volume
	_invert_y.toggled.connect(Settings.set_invert_y)
	_camera_roll.toggled.connect(Settings.set_camera_roll)
	_show_hud.toggled.connect(Settings.set_show_hud)
	_screen_shake.toggled.connect(Settings.set_screen_shake)
	_rumble.toggled.connect(Settings.set_rumble)
	_radio_volume.value_changed.connect(Settings.set_radio_volume)
	_sfx_volume.value_changed.connect(Settings.set_sfx_volume)
	_voice_volume.value_changed.connect(Settings.set_voice_volume)
	_resume.pressed.connect(close)
	_back_to_start.pressed.connect(_on_back_to_start)
	_dock.pressed.connect(_on_dock)
	for flight_only: Control in [_invert_y, _camera_roll, _show_hud, _screen_shake, _dock, _back_to_start]:
		flight_only.visible = flying
	_quit_to_title.pressed.connect(_on_quit_to_title)
	_logbook.pressed.connect(_on_logbook)
	_controls.pressed.connect(_on_controls)
	_add_pro_docking()
	_add_window_options()
	_dress()
	_make_scrollable()


## The old console RPG menu look (RetroUI.gd): a beveled blue window, white
## words with drop shadows, and the white glove.
func _dress() -> void:
	var panel := $Center/Panel as PanelContainer
	var frame := RetroUI.window("Haultec Rig Systems 5050")
	panel.add_theme_stylebox_override("panel", frame)
	var title := $Center/Panel/Items/Title as Label
	for override: String in ["font_outline_color"]:
		title.remove_theme_color_override(override)
	title.remove_theme_constant_override("outline_size")
	title.add_theme_color_override("font_color", RetroUI.GOLD)
	title.add_theme_font_size_override("font_size", RetroUI.BIG_SIZE)
	var hint := $Center/Panel/Items/Hint as Label
	hint.add_theme_color_override("font_color", RetroUI.GREY)
	hint.add_theme_font_size_override("font_size", RetroUI.TEXT_SIZE)
	RetroUI.dress($Center as Control)


var _pro_docking: CheckButton


## The pro docking switch (flying only), just after camera roll.
func _add_pro_docking() -> void:
	_pro_docking = CheckButton.new()
	_pro_docking.text = "Pro docking (park in the bay yourself, for a tip)"
	_pro_docking.button_pressed = Settings.pro_docking
	_pro_docking.toggled.connect(Settings.set_pro_docking)
	_pro_docking.visible = flying
	_camera_roll.add_sibling(_pro_docking)


var _fullscreen: CheckButton
var _scroller: ScrollContainer


## The menu is long: if it's taller than the screen (a small window, or the
## big menu size), it scrolls, following whatever's highlighted.
func _make_scrollable() -> void:
	var items := $Center/Panel/Items as Control
	var panel := items.get_parent()
	_scroller = ScrollContainer.new()
	_scroller.name = "Scroller"
	_scroller.follow_focus = true
	_scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.remove_child(items)
	panel.add_child(_scroller)
	_scroller.add_child(items)
	items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	get_viewport().size_changed.connect(_fit_scroller)
	Events.settings_changed.connect(_fit_scroller)
	_fit_scroller()


func _fit_scroller() -> void:
	if _scroller == null:
		return
	var items := _scroller.get_child(0) as Control
	var tallest := get_viewport().get_visible_rect().size.y - 70.0
	_scroller.custom_minimum_size = Vector2(items.get_combined_minimum_size().x, minf(items.get_combined_minimum_size().y, tallest))
var _ui_size: Button


## Fullscreen on/off and the UI size, under the gamepad rumble switch.
func _add_window_options() -> void:
	_fullscreen = _rumble.duplicate(0) as CheckButton
	_fullscreen.name = "Fullscreen"
	_fullscreen.unique_name_in_owner = false
	_fullscreen.text = "Fullscreen (F11)"
	_fullscreen.button_pressed = Settings.fullscreen
	_rumble.add_sibling(_fullscreen)
	_fullscreen.toggled.connect(Settings.set_fullscreen)
	_ui_size = _controls.duplicate(0) as Button
	_ui_size.name = "UiSize"
	_ui_size.unique_name_in_owner = false
	_fullscreen.add_sibling(_ui_size)
	_ui_size.pressed.connect(func() -> void: Settings.set_ui_size((Settings.ui_size + 1) % Settings.UI_SCALES.size()))
	_show_window_options()
	Events.settings_changed.connect(_show_window_options)


## Keeps the switches matching the settings (F11 can change them anytime).
func _show_window_options() -> void:
	_fullscreen.set_pressed_no_signal(Settings.fullscreen)
	_ui_size.text = "Menu and HUD size: %s" % Settings.UI_SIZE_NAMES[Settings.ui_size]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	visible = true
	# The title says how far along you are (see Completion.gd).
	var title := find_child("Title", true, false) as Label  # (Inside the scroller.)
	if title != null:
		title.text = "PAUSED · COMPLETION %d%%" % Completion.percent()
	_fit_scroller()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_resume.grab_focus()  # So a gamepad or keyboard can navigate right away.
	RetroUI.power_on($Center/Panel as Control)


func close() -> void:
	visible = false
	get_tree().paused = false
	resumed.emit()


func _on_back_to_start() -> void:
	close()
	back_to_start_pressed.emit()


func _on_dock() -> void:
	visible = false
	get_tree().paused = false
	dock_pressed.emit()


func _on_logbook() -> void:
	await LogbookView.open(get_tree())
	_logbook.grab_focus()


func _on_controls() -> void:
	await ControlsView.open(get_tree())
	_controls.grab_focus()


func _on_quit_to_title() -> void:
	visible = false
	get_tree().paused = false
	quit_to_title_pressed.emit()
