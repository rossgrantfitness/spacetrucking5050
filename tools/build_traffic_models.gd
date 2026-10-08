extends SceneTree
## Turns the developer's traffic ship models (res://art/models/traffic_*.glb)
## into ship visuals other truckers fly (res://scenes/flight/traffic/*Visual.tscn),
## like the hand-built ones there:
##   - the model turned so its nose points forward (-Z, the way ships fly),
##     centered and scaled to `length` meters nose to tail;
##   - two engine nozzles at the tail with engine trails and flares (move
##     the Nozzle markers in the editor to sit them on the real engines);
##   - its size (width, height, length) saved as "hull_size", so whatever
##     flies it gets a bump box that fits (see TrafficShip.hull_for()).
## Passing ships, convoys and the road traffic pick from these.
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/build_traffic_models.gd
## (Safe to run again: it rebuilds each visual from scratch.)

## (Loaded when it runs: these scripts use the game's autoloads, which a
## -s tool can't see while it's being compiled.)
const ENGINE_TRAIL := "res://scenes/flight/EngineTrail.gd"
const ENGINE_FLARE := "res://scenes/flight/EngineFlare.gd"

## model file: [visual's scene name, length (m), which way the model's nose
## points (+1 = the model's +X, -1 = its -X), engine spacing (fraction of
## the half width, from the middle), engine height (fraction of the height,
## from the middle)]
const SHIPS := {
	"res://art/models/traffic_rustbound_skyfreighter.glb": ["RustboundSkyfreighterVisual", 30.0, -1, 0.35, 0.08],  # The red tugboat.
	"res://art/models/traffic_rustbound_starforge.glb": ["RustboundStarforgeVisual", 34.0, -1, 0.3, 0.0],          # Teal, with the crane arm.
	"res://art/models/traffic_industrial_starfreighter_a.glb": ["IndustrialStarfreighterVisual", 38.0, -1, 0.35, 0.0],  # Yellow, pods on outriggers.
	"res://art/models/traffic_industrial_starfreighter_b.glb": ["LongHaulStarfreighterVisual", 42.0, -1, 0.45, 0.0],   # Long and thin, container racks.
}


func _initialize() -> void:
	for path: String in SHIPS:
		var spec: Array = SHIPS[path]
		var visual := Node3D.new()
		visual.name = spec[0]
		var model := (load(path) as PackedScene).instantiate() as Node3D
		model.name = "Model"
		visual.add_child(model)
		model.owner = visual
		# The model's size, nose to tail along its X.
		var box := _bounds(model)
		var scale := float(spec[1]) / box.size.x
		var nose := int(spec[2])
		model.rotation.y = PI * 0.5 * nose  # Nose (+X or -X) to -Z.
		model.scale = Vector3.ONE * scale
		model.position = -(model.transform.basis * box.get_center())
		# Engines at the tail.
		var tail_z := box.size.x * scale * 0.5
		var half_width := box.size.z * scale * 0.5
		var height := float(spec[4]) * box.size.y * scale
		for side in [-1.0, 1.0]:
			var nozzle := Marker3D.new()
			nozzle.name = "Nozzle" if side < 0.0 else "Nozzle2"
			nozzle.position = Vector3(side * half_width * float(spec[3]), height, tail_z + 0.3)
			visual.add_child(nozzle)
			nozzle.owner = visual
			var trail := MeshInstance3D.new()
			trail.name = "EngineTrail"
			trail.set_script(load(ENGINE_TRAIL))
			nozzle.add_child(trail)
			trail.owner = visual
			var flare := MeshInstance3D.new()
			flare.name = "EngineFlare"
			flare.set_script(load(ENGINE_FLARE))
			flare.position = Vector3(0.0, 0.0, 0.4)
			flare.set("size_at_top_speed", 6.0)
			nozzle.add_child(flare)
			flare.owner = visual
		# A bump box a little inside the model's outline.
		visual.set_meta("hull_size", Vector3(box.size.z, box.size.y, box.size.x) * scale * 0.85)
		var scene := PackedScene.new()
		var error := scene.pack(visual)
		var out := "res://scenes/flight/traffic/%s.tscn" % spec[0]
		if error == OK:
			error = ResourceSaver.save(scene, out)
		print("%s: %s (%.0f x %.0f x %.0f m)" % [out, error_string(error), box.size.z * scale, box.size.y * scale, box.size.x * scale])
		visual.free()
	quit()


## The box around every mesh in `model` (in the model's own space).
func _bounds(model: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var to_model := Transform3D.IDENTITY
		var walker: Node = mesh
		while walker != null and walker != model:
			if walker is Node3D:
				to_model = (walker as Node3D).transform * to_model
			walker = walker.get_parent()
		var part := to_model * mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return box
