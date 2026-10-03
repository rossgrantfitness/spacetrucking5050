class_name PauseMenu
extends CanvasLayer
## A small pause menu: keep driving, flip a few comfort switches, or head
## back. It works with the mouse, the keyboard (arrows + Enter) or a gamepad
## (D-pad + A). (The full options menu comes in M10.)
##
## Opens and closes with Esc / Start; B / Esc also closes it.


signal resumed
signal back_to_start_pressed
signal quit_to_title_pressed

@onready var _resume: Button = %Resume
@onready var _invert_y: CheckButton = %InvertY
@onready var _camera_roll: CheckButton = %CameraRoll
@onready var _show_hud: CheckButton = %ShowHud
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
	_invert_y.toggled.connect(Settings.set_invert_y)
	_camera_roll.toggled.connect(Settings.set_camera_roll)
	_show_hud.toggled.connect(Settings.set_show_hud)
	_resume.pressed.connect(close)
	_back_to_start.pressed.connect(_on_back_to_start)
	_quit_to_title.pressed.connect(_on_quit_to_title)


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
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_resume.grab_focus()  # So a gamepad or keyboard can navigate right away.


func close() -> void:
	visible = false
	get_tree().paused = false
	resumed.emit()


func _on_back_to_start() -> void:
	close()
	back_to_start_pressed.emit()


func _on_quit_to_title() -> void:
	visible = false
	get_tree().paused = false
	quit_to_title_pressed.emit()
