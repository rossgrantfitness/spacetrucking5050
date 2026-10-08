class_name Snack
extends RefCounted
## Something from a vending machine, enjoyed: it drops with a clunk, appears
## in her right hand (a little low-poly can, bottle, cup, bar, bag or box in
## the brand's colors), she eats or drinks it, says what she thinks, and its
## effect kicks in. The first time she tries a brand, she reads the back of
## the packet: the brand's story (res://data/brands/).


## How long she spends on it, in seconds.
const ENJOY_SECONDS: float = 2.6
## How much bigger than life the packet is in her hand (chibi props read
## better a bit oversized).
const HELD_SCALE: float = 1.8
## Where her right hand is, on her right arm's pivot (BunnyVisual.tscn).
const HAND_SPOT := Vector3(0.05, -0.36, -0.02)


## The whole moment: clunk, hold, eat, a line, maybe the packet's story,
## then the effect.
static func enjoy(tree: SceneTree, product: ProductData) -> void:
	var brand := GameState.brands.find_brand(product.brand_id)
	var first_of_brand := not tried_brand(product.brand_id)
	GameState.tasted[product.id] = int(GameState.tasted.get(product.id, 0)) + 1
	Sfx.play("clunk")  # *clunk*
	var room := HubRoom.find(tree.current_scene) if tree.current_scene != null else null
	if room == null:
		room = _room_in(tree)
	var animator: Node3D = null
	var held: Node3D = null
	if room != null and room.player != null:
		animator = room.player.visual
		# Her right hand: the rigged Jacki has one (JackiAnimator.hand());
		# the hand-animated bunny has an arm pivot.
		var arm: Node3D = null
		if animator.has_method("hand"):
			arm = animator.call("hand") as Node3D
		elif animator.get_child_count() > 0:
			arm = animator.get_child(0).get_node_or_null("Body/ArmRight") as Node3D
		if arm != null:
			held = build(product, brand)
			held.position = HAND_SPOT
			held.scale = Vector3.ONE * HELD_SCALE
			arm.add_child(held)
			if animator.has_method("hand"):
				# Right in the rigged hand, the same size in the world.
				held.position = Vector3.ZERO
				held.scale = Vector3.ONE * HELD_SCALE / maxf(arm.global_basis.get_scale().x, 0.001)
	if animator != null and "pose" in animator:
		animator.set("pose", "eat")
	await tree.create_timer(ENJOY_SECONDS).timeout
	if animator != null and is_instance_valid(animator) and "pose" in animator:
		animator.set("pose", "stand")
	if held != null and is_instance_valid(held):
		held.queue_free()
	var lines := product.taste_lines
	var line := lines[randi() % lines.size()] if not lines.is_empty() else "...Huh."
	await Dialogue.say(GameState.names.bunny_name, [line], Dialogue.BUNNY_VOICE.voice_pitch, Dialogue.BUNNY_VOICE)
	if first_of_brand and brand != null:
		await MenuPanel.ask(tree, "ON THE BACK OF THE PACKET", "%s\n\n%s\n\n\"%s\"" % [brand.display_name, brand.story, brand.slogan], [{"text": "HUH"}])
	var effect := apply_effect(tree, product)
	if not effect.is_empty() and room != null:
		room.notice_requested.emit(effect)


## Whether she's tried anything by this brand before.
static func tried_brand(brand_id: String) -> bool:
	for id: String in GameState.tasted:
		var product := GameState.brands.find_product(id)
		if product != null and product.brand_id == brand_id and int(GameState.tasted[id]) > 0:
			return true
	return false


## How many different snacks and drinks she's tried, out of all of them.
static func tried_count() -> int:
	var count := 0
	for product in GameState.brands.products:
		if int(GameState.tasted.get(product.id, 0)) > 0:
			count += 1
	return count


## Does what the product does. Returns a few words about it for the HUD
## ("" for nothing).
static func apply_effect(tree: SceneTree, product: ProductData) -> String:
	var ship := _flying_ship(tree)
	match product.effect:
		"steady":
			GameState.rig["snack"] = 1.0
			if ship != null:
				ship.flight.shakiness = 0.5
			return "STEADY HANDS NEXT TRIP"
		"zoom":
			if ship != null:
				ship.flight.boost_fuel = minf(ship.flight.boost_fuel + 0.25, 1.0)
			else:
				GameState.rig["boost_fuel"] = minf(float(GameState.rig.get("boost_fuel", 1.0)) + 0.25, 1.0)
			return "BOOST TANK TOPPED UP"
	return ""


## The little packet she holds, in the brand's colors, by its shape.
static func build(product: ProductData, brand: BrandData) -> Node3D:
	var color := brand.color if brand != null else Color(0.8, 0.8, 0.8)
	var holder := Node3D.new()
	holder.name = "Snack"
	match product.package:
		"can":
			_cylinder(holder, 0.035, 0.1, Vector3.ZERO, color)
			_cylinder(holder, 0.036, 0.025, Vector3.ZERO, Color.WHITE)  # A band round the middle.
			_cylinder(holder, 0.03, 0.006, Vector3(0.0, 0.053, 0.0), Color(0.75, 0.75, 0.8))  # The lid.
		"bottle":
			_cylinder(holder, 0.032, 0.09, Vector3.ZERO, Color(0.95, 0.95, 1.0))
			_cylinder(holder, 0.034, 0.035, Vector3(0.0, -0.01, 0.0), color)  # The label.
			_cylinder(holder, 0.014, 0.035, Vector3(0.0, 0.06, 0.0), Color(0.95, 0.95, 1.0))
			_cylinder(holder, 0.016, 0.01, Vector3(0.0, 0.08, 0.0), color)  # The cap.
		"cup":
			var cup := CylinderMesh.new()
			cup.top_radius = 0.045
			cup.bottom_radius = 0.033
			cup.height = 0.08
			cup.radial_segments = 8
			cup.rings = 1
			cup.material = _paint(Color(0.97, 0.95, 0.9))
			_mesh(holder, cup, Vector3.ZERO)
			_cylinder(holder, 0.043, 0.025, Vector3(0.0, 0.0, 0.0), color)
		"bar":
			_box(holder, Vector3(0.11, 0.035, 0.02), Vector3.ZERO, color)
			_box(holder, Vector3(0.04, 0.036, 0.021), Vector3(0.02, 0.0, 0.0), Color.WHITE)
		"bag":
			_box(holder, Vector3(0.09, 0.12, 0.035), Vector3.ZERO, color)
			_box(holder, Vector3(0.092, 0.015, 0.02), Vector3(0.0, 0.062, 0.0), Color(0.85, 0.85, 0.85))  # The crimped top.
		"box":
			_box(holder, Vector3(0.09, 0.06, 0.06), Vector3.ZERO, color)
			_box(holder, Vector3(0.091, 0.02, 0.061), Vector3(0.0, 0.01, 0.0), Color.WHITE)
		_:
			_cylinder(holder, 0.008, 0.12, Vector3.ZERO, Color(0.95, 0.9, 0.8))
			_box(holder, Vector3(0.04, 0.04, 0.01), Vector3(0.0, 0.07, 0.0), color)
	return holder


static func _flying_ship(tree: SceneTree) -> Ship:
	var scene := tree.current_scene
	if scene != null and scene.scene_file_path.ends_with("FlightSandbox.tscn"):
		return scene.get("_ship") as Ship
	return null


## The room she's in, wherever it is (in flight, the cabin's room sits
## inside the flight scene).
static func _room_in(tree: SceneTree) -> HubRoom:
	for node in tree.get_nodes_in_group("hub_rooms"):
		if node is HubRoom:
			return node as HubRoom
	if tree.current_scene != null:
		for node in tree.current_scene.find_children("*", "HubRoom", true, false):
			return node as HubRoom
	return null


static func _paint(color: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/psx_surface.gdshader")
	material.set_shader_parameter("albedo", color)
	material.set_shader_parameter("box_uv", false)
	return material


static func _mesh(parent: Node3D, mesh: Mesh, where: Vector3) -> void:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = where
	parent.add_child(part)


static func _box(parent: Node3D, size: Vector3, where: Vector3, color: Color) -> void:
	var box := BoxMesh.new()
	box.size = size
	box.material = _paint(color)
	_mesh(parent, box, where)


static func _cylinder(parent: Node3D, radius: float, height: float, where: Vector3, color: Color) -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	cylinder.radial_segments = 8
	cylinder.rings = 1
	cylinder.material = _paint(color)
	_mesh(parent, cylinder, where)
