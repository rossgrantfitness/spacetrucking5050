extends Node
## The live state of the game while it runs. From M2 on, everything that ends
## up in a save file lives here too.
##
## M0: holds the shared tuning file, so every script reads the same numbers.
## M1: quits the game politely (see quit_game), and keeps the window at
##     least 800x600 (the smallest screen we support; up to 4K works).
## M2: money, cargo condition, fuel, ship upgrades, the active job.
## M6: day, shift, rent, ship XP and levels.
##
## Any script can reach it as `GameState` because it's an autoload (Godot
## creates it once at startup and keeps it alive the whole time).


## The one shared copy of every feel number. To change values, open
## res://data/tuning.tres and use the Inspector.
var tuning: Tuning = preload("res://data/tuning.tres")

## The smallest the game window can get. Everything is drawn at the screen's
## own resolution, from this up to 4K.
const MIN_WINDOW_SIZE := Vector2i(800, 600)

var _quitting := false


func _ready() -> void:
	# When the window's close button is clicked, let quit_game() handle it
	# instead of Godot closing on the spot.
	get_tree().auto_accept_quit = false
	get_tree().root.min_size = MIN_WINDOW_SIZE


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()


## Closes the game politely: stops every sound, gives the audio system a
## moment to let go of them, then quits. (Quitting while sounds are still
## playing makes Godot print a harmless but alarming "leaked at exit"
## warning.) From M2 on, this is also where the game saves on the way out.
func quit_game() -> void:
	if _quitting:
		return
	_quitting = true
	for type_name: String in ["AudioStreamPlayer", "AudioStreamPlayer2D", "AudioStreamPlayer3D"]:
		for player in get_tree().root.find_children("*", type_name, true, false):
			player.call("stop")
	await get_tree().create_timer(0.1, true).timeout
	get_tree().quit()
