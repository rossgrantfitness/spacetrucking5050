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


func _leave() -> void:
	var room := HubRoom.find(self)
	if room != null:
		room.leave_to(target_scene, target_spawn)
