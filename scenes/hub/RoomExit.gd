class_name RoomExit
extends Interactable
## A doorway out of the room. Walk into it (or, if `needs_button` is on,
## stand in it and press Interact) and you're taken to `target_scene`, at the
## spawn spot called `target_spawn`.


## The room (or other scene) this door leads to.
@export_file("*.tscn") var target_scene: String = ""
## Which spawn spot (a Marker3D under the target room's "Spawns") to arrive at.
@export var target_spawn: String = ""
## Off: just walk through. On: press Interact here (for things like boarding
## the ship).
@export var needs_button: bool = false
## For doors onto the ship: the place the rig launches from (a place id
## like "truck_stop"). Empty for ordinary doors, and for the cockpit door
## inside the rig (it launches from wherever the rig is parked).
@export var launch_from: String = ""
## The rig's airlock: leads out into whatever station the rig is parked at
## (GameState.launch_from), instead of to `target_scene`. Locked in flight.
@export var to_docked_place: bool = false


func _ready() -> void:
	super()
	if not needs_button:
		monitoring = true
		body_entered.connect(_on_body_entered)


func shows_prompt() -> bool:
	return enabled and needs_button


func interact(player: Node3D) -> void:
	super(player)
	_leave()


func _on_body_entered(body: Node3D) -> void:
	if body is HubPlayer and enabled and not (body as HubPlayer).is_busy():
		_leave()


## Goes through the door now (the room calls this when she walks out of the
## camera's view right next to it; see HubRoom._walk_out_of_frame).
func walk_through() -> void:
	if enabled and not needs_button:
		_leave()


func _leave() -> void:
	var room := HubRoom.find(self)
	Sfx.play("door", -3.0)
	if to_docked_place:
		_step_outside(room)
		return
	if not launch_from.is_empty():
		GameState.launch_from = launch_from
	if room != null:
		room.leave_to(target_scene, target_spawn)


## The airlock: out into the station the rig is parked at.
func _step_outside(room: HubRoom) -> void:
	if room == null:
		return
	if room.aboard:
		room.notice_requested.emit("NOT WHILE WE'RE MOVING.")
		return
	var place := GameState.places.find(GameState.launch_from)
	if place == null or place.interior_scene.is_empty():
		room.notice_requested.emit("NOTHING OUT THERE BUT VACUUM.")
		return
	room.leave_to(place.interior_scene, place.arrival_spawn)
