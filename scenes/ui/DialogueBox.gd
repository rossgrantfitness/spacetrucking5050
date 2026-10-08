class_name DialogueBox
extends CanvasLayer
## The RPG text box (in the old console RPG menu look, RetroUI.gd): the
## speaker's name in a little window on top, then their words typed out
## letter by letter with Animal Crossing-style gibberish
## blips. Press Interact (E / A) or Enter to finish the line or go on;
## Cancel (Esc / B) closes it early (so does walking away from whoever's
## talking: see NPC.gd).
##
## Made by the Dialogue autoload; use Dialogue.say(...) rather than this.


signal done

## Whether the conversation was closed early (Cancel, or walking away).
var cancelled := false

## Letters typed per second.
const TYPE_SPEED: float = 42.0
const NAME_COLOR := RetroUI.GOLD

var _lines := PackedStringArray()
var _line := 0
var _shown := 0.0
var _pitch := 1.0
var _voice: NPCData
var _speaker := ""
var _label: Label
var _nameplate: Control
var _name_label: Label
var _next_arrow: Label
var _blip: AudioStreamPlayer
var _letters_since_blip := 0
var _hint: Label


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	# The look of an old console RPG: a beveled blue window along the bottom,
	# white words with a drop shadow, and the speaker's name in its own
	# little window sitting on the top edge (see RetroUI.gd).
	var holder := Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.theme = RetroUI.theme()
	add_child(holder)
	var box := PanelContainer.new()
	box.anchor_left = 0.0
	box.anchor_right = 1.0
	box.anchor_top = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = 60.0
	box.offset_right = -60.0
	box.offset_top = -200.0
	box.offset_bottom = -36.0
	var style := RetroUI.window()
	style.content_margin_top = 32.0
	style.content_margin_bottom = 24.0
	box.add_theme_stylebox_override("panel", style)
	holder.add_child(box)
	_label = RetroUI.label("", RetroUI.BIG_SIZE)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	box.add_child(_label)
	# The nameplate: a strip of yellow label-maker tape stuck on the box's
	# top edge, a little crooked (not inside the box, so its layout doesn't
	# move it).
	var plate := PanelContainer.new()
	var plate_style := StyleBoxFlat.new()
	plate_style.bg_color = Color(0.93, 0.76, 0.16)
	plate_style.border_color = Color(0.35, 0.26, 0.05)
	plate_style.set_border_width_all(1)
	plate_style.set_corner_radius_all(2)
	plate_style.shadow_color = Color(0, 0, 0, 0.45)
	plate_style.shadow_size = 2
	plate_style.shadow_offset = Vector2(2, 2)
	plate_style.content_margin_left = 12.0
	plate_style.content_margin_right = 12.0
	plate_style.content_margin_top = 3.0
	plate_style.content_margin_bottom = 3.0
	plate.add_theme_stylebox_override("panel", plate_style)
	plate.rotation = deg_to_rad(-1.5)
	plate.anchor_top = 1.0
	plate.anchor_bottom = 1.0
	plate.offset_left = 90.0
	plate.offset_top = -214.0
	plate.offset_bottom = -214.0  # (It grows down to fit the name.)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(plate)
	_name_label = RetroUI.label("", RetroUI.TEXT_SIZE, Color(0.1, 0.08, 0.04))
	_name_label.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.35))  # (Embossed.)
	_name_label.add_theme_constant_override("shadow_offset_x", 1)
	_name_label.add_theme_constant_override("shadow_offset_y", 1)
	plate.add_child(_name_label)
	_nameplate = plate
	_next_arrow = RetroUI.label("▼", RetroUI.TEXT_SIZE, RetroUI.WHITE)
	_next_arrow.anchor_left = 1.0
	_next_arrow.anchor_right = 1.0
	_next_arrow.anchor_top = 1.0
	_next_arrow.anchor_bottom = 1.0
	_next_arrow.offset_left = -104.0
	_next_arrow.offset_top = -82.0
	holder.add_child(_next_arrow)
	# How to leave, small, in the box's bottom-left corner.
	_hint = RetroUI.label("Esc / B: bye", RetroUI.TEXT_SIZE, RetroUI.GREY)
	_hint.anchor_top = 1.0
	_hint.anchor_bottom = 1.0
	_hint.offset_left = 92.0
	_hint.offset_top = -80.0
	holder.add_child(_hint)
	RetroUI.power_on(box)
	_blip = AudioStreamPlayer.new()
	_blip.stream = VoiceBlips.stream("soft")
	_blip.max_polyphony = 3
	_blip.bus = Settings.VOICE_BUS
	add_child(_blip)


## Shows the lines one by one and returns when the last one is closed.
func run(speaker: String, lines: PackedStringArray, voice_pitch: float, voice: NPCData = null) -> void:
	_speaker = speaker
	_lines = lines
	_pitch = voice_pitch
	_voice = voice
	if voice != null:
		_blip.stream = VoiceBlips.stream(voice.voice_type)
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


## Closes the box now, partway through (see `cancelled`).
func cancel() -> void:
	if _line >= _lines.size():
		return
	cancelled = true
	_line = _lines.size()
	done.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()  # (Esc: not the pause menu too.)
		cancel()
		return
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
	_name_label.text = _speaker
	_nameplate.visible = not _speaker.is_empty()


## A blip for every other letter, on the note that letter plays in the
## speaker's key (see VoiceBlips.gd).
func _maybe_blip(text: String, index: int) -> void:
	if index >= text.length() or text[index] == " ":
		return
	_letters_since_blip += 1
	if _letters_since_blip < 2:
		return
	_letters_since_blip = 0
	if _voice != null:
		_blip.pitch_scale = VoiceBlips.pitch_scale(_voice.voice_pitch, _voice.voice_key, _voice.voice_scale, text, index)
	else:
		_blip.pitch_scale = VoiceBlips.pitch_scale(_pitch, 9, "major", text, index)
	_blip.play()
