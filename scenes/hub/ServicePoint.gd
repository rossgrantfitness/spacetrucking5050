class_name ServicePoint
extends Interactable
## Something to use that opens a menu: the job board, the jukebox, the
## vending machine. (People who run counters do this through their
## conversations instead.) See HubServices.gd for the menus.


## Which menu: "job_board", "fuel", "mechanic", "jukebox", "vending".
@export var menu: String = "job_board"

var _busy := false


func interact(player: Node3D) -> void:
	if _busy:
		return
	super(player)
	_busy = true
	var hub_player := player as HubPlayer
	hub_player.set_busy(true)
	var room := HubRoom.find(self)
	await HubServices.open(menu, get_tree(), room.place_id if room != null else "")
	hub_player.set_busy(false)
	_busy = false
