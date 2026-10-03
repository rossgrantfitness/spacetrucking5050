@tool
class_name RoomShot
extends Node3D
## One fixed camera angle in a room, Final Fantasy VIII style, plus the zone
## where it's used: while the bunny stands inside the zone, the view cuts to
## this camera.
##
## HOW TO EDIT: select the "Camera" child and move/aim it in the editor
## (click "Preview" in the 3D view to look through it). Select the "Zone"
## child's box shape and drag its handles to change where the shot is used.
## Zones can overlap: the current shot stays until she leaves its zone.
##
## Each shot's background picture is painted (pre-rendered) when the room
## loads; see HubRoom.gd.


## The painted background for this shot. Filled in by HubRoom when the room
## loads.
var background: Texture2D


## The camera for this shot.
func camera() -> Camera3D:
	return get_node_or_null("Camera") as Camera3D


## Whether `point` (in the world) is inside this shot's zone. Zones are boxes.
func contains(point: Vector3) -> bool:
	return contains_local(global_transform.affine_inverse() * point)


## Like contains(), but with `point` measured from this shot's own position.
func contains_local(point: Vector3) -> bool:
	var zone := get_node_or_null("Zone") as Node3D
	var shape := get_node_or_null("Zone/Shape") as CollisionShape3D
	if zone == null or shape == null or not shape.shape is BoxShape3D:
		return false
	var local := (zone.transform * shape.transform).affine_inverse() * point
	var half := (shape.shape as BoxShape3D).size * 0.5
	return absf(local.x) <= half.x and absf(local.y) <= half.y and absf(local.z) <= half.z


func _ready() -> void:
	# The zone is only a box to edit in the editor; it never touches physics.
	var zone := get_node_or_null("Zone") as Area3D
	if zone != null:
		zone.monitoring = false
		zone.monitorable = false
		zone.collision_layer = 0
		zone.collision_mask = 0
