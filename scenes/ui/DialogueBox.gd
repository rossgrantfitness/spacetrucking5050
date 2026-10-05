class_name DialogueBox
extends CanvasLayer
## The RPG text box: the speaker's name in chunky pixel letters, then their
## words typed out letter by letter with Animal Crossing-style gibberish
## blips. Press Interact (E / A) or Enter to finish the line or go on.
##
## Made by the Dialogue autoload; use Dialogue.say(...) rather than this.


signal done

const BLIP := preload("res://audio/generated/blip.wav")
## Letters typed per second.
const TYPE_SPEED: float = 42.0
const NAME_COLOR := Color(1.0, 0.85, 0.25)

var _lines := PackedStringArray()
var _line := 0
var _shown := 0.0
var _pitch := 1.0
var _speaker := ""
var _label: Label
var _nameplate: Control
var _next_arrow: Label
var _blip: AudioStreamPlayer
var _letters_since_blip := 0


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	var box := PanelContainer.new()
	box.anchor_left = 0.0
	box.anchor_right = 1.0
	box.anchor_top = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = 60.0
	box.offset_right = -60.0
	box.offset_top = -200.0
	box.offset_bottom = -36.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.2, 0.92)
	style.border_color = Color(0.85, 0.88, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	style.content_margin_left = 28.0
	style.content_margin_right = 28.0
	style.content_margin_top = 40.0
	style.content_margin_bottom = 18.0
	box.add_theme_stylebox_override("panel", style)
	add_child(box)
	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_label.add_theme_font_size_override("font_size", 26)
	_label.add_theme_color_override("font_color", Color(0.97, 0.97, 1.0))
	_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.1))
	_label.add_theme_constant_override("outline_size", 4)
	box.add_child(_label)
	# The nameplate sits on the box's top edge (not inside it, so the box's
	# layout doesn't move it).
	_nameplate = Control.new()
	_nameplate.anchor_top = 1.0
	_nameplate.anchor_bottom = 1.0
	_nameplate.offset_left = 100.0
	_nameplate.offset_top = -200.0
	_nameplate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_nameplate.draw.connect(_draw_nameplate)
	add_child(_nameplate)
	_next_arrow = Label.new()
	_next_arrow.text = "▼"
	_next_arrow.add_theme_color_override("font_color", NAME_COLOR)
	_next_arrow.anchor_left = 1.0
	_next_arrow.anchor_right = 1.0
	_next_arrow.anchor_top = 1.0
	_next_arrow.anchor_bottom = 1.0
	_next_arrow.offset_left = -96.0
	_next_arrow.offset_top = -72.0
	add_child(_next_arrow)
	_blip = AudioStreamPlayer.new()
	_blip.stream = BLIP
	_blip.max_polyphony = 3
	_blip.bus = Settings.VOICE_BUS
	add_child(_blip)


## Shows the lines one by one and returns when the last one is closed.
func run(speaker: String, lines: PackedStringArray, voice_pitch: float) -> void:
	_speaker = speaker
	_lines = lines
	_pitch = voice_pitch
	_line = 0
	_start_line()
	await done


func _process(delta: float) -> void:
	if _line >= _lines.size():
		return
	var total := _label.get_total_character_count()
	if _shown < total:
		var before := int(_shown)
		_shown = minf(_shown + TYPE_SPEED * delta, total)
		for i in range(before, int(_shown)):
			_maybe_blip(_lines[_line], i)
	_label.visible_characters = int(_shown)
	_next_arrow.visible = _shown >= total and fposmod(Time.get_ticks_msec() / 1000.0, 0.8) < 0.5


func _unhandled_input(event: InputEvent) -> void:
	if not (event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")):
		return
	get_viewport().set_input_as_handled()
	if _shown < _label.get_total_character_count():
		_shown = _label.get_total_character_count()  # Show the rest at once.
		return
	_line += 1
	if _line >= _lines.size():
		done.emit()
	else:
		_start_line()


func _start_line() -> void:
	_label.text = _lines[_line]
	_shown = 0.0
	_label.visible_characters = 0
	_nameplate.queue_redraw()


## A blip for every other letter, at the speaker's pitch with a little wobble.
func _maybe_blip(text: String, index: int) -> void:
	if index >= text.length() or text[index] == " ":
		return
	_letters_since_blip += 1
	if _letters_since_blip < 2:
		return
	_letters_since_blip = 0
	_blip.pitch_scale = _pitch * randf_range(0.88, 1.15)
	_blip.play()


func _draw_nameplate() -> void:
	var square := 3.0
	var width := PixelFont.width(_speaker, square)
	_nameplate.draw_rect(Rect2(-12.0, -14.0, width + 24.0, 34.0), Color(0.05, 0.06, 0.2))
	_nameplate.draw_rect(Rect2(-12.0, -14.0, width + 24.0, 34.0), Color(0.85, 0.88, 1.0), false, 3.0)
	PixelFont.draw(_nameplate, Vector2(0.0, -7.0), _speaker, square, NAME_COLOR, 0.15)
