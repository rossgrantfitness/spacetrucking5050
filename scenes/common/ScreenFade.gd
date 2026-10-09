class_name ScreenFade
extends CanvasLayer
## A black curtain for fading in and out between rooms and scenes.
##     await fade.fade_out()   # to black
##     await fade.fade_in()    # back to the picture


## How long a fade takes, in seconds.
@export var seconds: float = 0.35

var _curtain: ColorRect


func _ready() -> void:
	layer = 50  # Above everything else.
	_curtain = ColorRect.new()
	_curtain.color = Color.BLACK
	_curtain.set_anchors_preset(Control.PRESET_FULL_RECT)
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_curtain)


## Starts fully black, so a scene can set itself up unseen.
func cover() -> void:
	_curtain.modulate.a = 1.0


func fade_out() -> void:
	await _fade_to(1.0)


func fade_in() -> void:
	await _fade_to(0.0)


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_curtain, "modulate:a", alpha, seconds)
	await tween.finished
