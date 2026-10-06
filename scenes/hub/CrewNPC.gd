class_name CrewNPC
extends NPC
## A crew member aboard the rig, placed by HubRoom at the spot their
## current activity says (see ShipLife.gd), in its pose, maybe holding
## something. Talking to them plays ShipLife's conversation; their story
## conversations (like Raccoony's job offers) still come first when one is
## waiting, and Raccoony at his counter opens the job board.


const PROP_COLORS := {
	"mug": Color(0.95, 0.9, 0.85), "wrench": Color(0.6, 0.62, 0.68), "book": Color(0.8, 0.3, 0.3),
	"cards": Color(0.95, 0.95, 0.95), "broom": Color(0.75, 0.55, 0.3), "clipboard": Color(0.7, 0.5, 0.3),
	"plate": Color(0.9, 0.92, 0.95), "guitar": Color(0.85, 0.45, 0.2),
}

var member: CrewMember
var activity: CrewActivity


## Builds them: their model in its pose, a prop, a reach for talking, a
## body to bump into.
func setup(new_member: CrewMember, new_activity: CrewActivity) -> void:
	member = new_member
	activity = new_activity
	data = member.npc
	name = member.id.capitalize()
	var visual := member.visual.instantiate() as Node3D
	visual.name = "Visual"
	add_child(visual)
	visual.set("pose", activity.pose)
	if activity.pose == "sleep" and not visual is ModelVisual:
		visual.position.y = 0.25  # Lying on a cot or couch (one-piece models sleep standing).
	_add_prop(visual, activity.prop)
	var reach := CollisionShape3D.new()
	reach.name = "TalkReach"
	var sphere := SphereShape3D.new()
	sphere.radius = 1.1
	reach.shape = sphere
	reach.position = Vector3(0.0, 0.6, -0.6)  # A little in front of them (over a counter).
	add_child(reach)
	if activity.pose != "sleep":
		var body := StaticBody3D.new()
		body.name = "Body"
		var shape := CollisionShape3D.new()
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.25
		capsule.height = 1.0
		shape.shape = capsule
		shape.position = Vector3(0.0, 0.5, 0.0)
		body.add_child(shape)
		add_child(body)


func _ready() -> void:
	super()
	prompt = "WAKE UP" if activity != null and activity.pose == "sleep" else "TALK"


func interact(player: Node3D) -> void:
	if _talking or member == null:
		return
	# A story conversation waiting (a job offer, news)? That comes first.
	var story := data.pick_conversation() if data != null else null
	if story != null and (story.offers_job != null or _has_new_flags(story)):
		await super(player)
		return
	_talking = true
	interacted.emit(player)
	var hub_player := player as HubPlayer
	hub_player.set_busy(true)
	var to_player := player.global_position - global_position
	if _visual != null and activity.pose != "sleep":
		_visual.rotation.y = atan2(-to_player.x, -to_player.z) - global_rotation.y
	hub_player.face(atan2(to_player.x, to_player.z))
	var heard := await _talk(hub_player, ShipLife.conversation(member, activity))
	if heard and not member.menu.is_empty() and activity.id == member.post_activity:
		hub_player.set_busy(true)
		var room := HubRoom.find(self)
		await HubServices.open(member.menu, get_tree(), room.place_id if room != null else "")
	hub_player.set_busy(false)
	_talking = false


## A little thing in their right hand (built from simple shapes).
func _add_prop(visual: Node3D, prop: String) -> void:
	if prop.is_empty() or not PROP_COLORS.has(prop):
		return
	var hand := visual.get_node_or_null("Body/ArmRight") as Node3D
	if hand == null:
		return
	var mesh := BoxMesh.new()
	match prop:
		"mug":
			mesh.size = Vector3(0.08, 0.1, 0.08)
		"wrench":
			mesh.size = Vector3(0.04, 0.25, 0.03)
		"book", "clipboard":
			mesh.size = Vector3(0.18, 0.24, 0.03)
		"cards":
			mesh.size = Vector3(0.1, 0.14, 0.02)
		"broom":
			mesh.size = Vector3(0.04, 0.9, 0.04)
		"plate":
			mesh.size = Vector3(0.22, 0.02, 0.22)
		"guitar":
			mesh.size = Vector3(0.25, 0.6, 0.08)
	var material := StandardMaterial3D.new()
	material.albedo_color = PROP_COLORS[prop]
	mesh.material = material
	var piece := MeshInstance3D.new()
	piece.name = "Prop"
	piece.mesh = mesh
	# About where the hand is: down the arm, a little forward.
	piece.position = Vector3(0.0, -0.32, -0.08)
	hand.add_child(piece)
