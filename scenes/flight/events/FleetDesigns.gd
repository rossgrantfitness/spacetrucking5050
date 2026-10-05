class_name FleetDesigns
## The big ships from the developer's design sheets (reference/Gemini_*
## images), built from chunky shapes for the big-ship flyby
## (BigShipFlyby.gd): the STACK-SHIP armored barge, the TANKER (bulk LNG
## carrier), the ORE-CRAWLER, the ICE-TUG, the HAB-BRICK and the GARBAGE
## SCOW. Each is about a kilometer and a half long, nose along -Z, built
## around its own middle.
##
## build() adds a random one (or the one you name) to `parent` and says
## what it is: {"size": its rough box (for bumping into), "names": ID
## labels to pick from, "trail": its engine trail color}.


const DESIGNS: PackedStringArray = ["stack_ship", "tanker", "ore_crawler", "ice_tug", "hab_brick", "garbage_scow"]
const HULL := preload("res://textures/generated/hull_panels.png")
const HAZARD := preload("res://textures/generated/hazard_stripes.png")
const ROCK := preload("res://textures/generated/rock.png")
const CONTAINER := preload("res://textures/generated/container.png")
const VENTS := preload("res://textures/generated/vents.png")
## Turns a cylinder (standing along Y) to lie along Z, with flat sides up
## for 8-sided ones (the octagon frames on the sheets).
const ALONG_Z := Vector3(PI / 2.0, 0.0, 0.0)
const OCTAGON := Vector3(PI / 2.0, PI / 8.0, 0.0)


static func build(parent: Node3D, rng: RandomNumberGenerator, design: String = "") -> Dictionary:
	if design.is_empty():
		design = DESIGNS[rng.randi_range(0, DESIGNS.size() - 1)]
	match design:
		"tanker":
			return _tanker(parent)
		"ore_crawler":
			return _ore_crawler(parent, rng)
		"ice_tug":
			return _ice_tug(parent, rng)
		"hab_brick":
			return _hab_brick(parent, rng)
		"garbage_scow":
			return _garbage_scow(parent, rng)
	return _stack_ship(parent)


static func _hull(color: Color, meters: float = 40.0) -> ShaderMaterial:
	return EventKit.paint(color, 0.0, HULL, meters)


## A big neon company sign on both flanks.
static func _signs(parent: Node3D, text: String, color: Color, half_width: float, where: Vector3, size: float = 0.25) -> void:
	for side: float in [-1.0, 1.0]:
		var label := EventKit.sign(parent, text, size, color, where + Vector3(side * (half_width + 2.0), 0.0, 0.0))
		label.rotation = Vector3(0.0, side * PI / 2.0, 0.0)


## Engine nozzles at the back (+Z), each with a glow.
static func _engines(parent: Node3D, spots: Array, back_z: float, radius: float, glow_color: Color) -> void:
	var dark := EventKit.paint(Color(0.16, 0.15, 0.2), 0.0, VENTS, 8.0)
	for spot: Vector2 in spots:
		EventKit.cylinder(parent, radius, radius * 1.2, Vector3(spot.x, spot.y, back_z + radius * 0.6), dark, ALONG_Z, 10)
		EventKit.glow(parent, radius * 6.0, Vector3(spot.x, spot.y, back_z + radius * 1.6), glow_color)


## An 8-sided frame around the hull (the chunky octagon rings on the sheets):
## a frame with a dark recess inside.
static func _octagon_frame(parent: Node3D, radius: float, depth: float, z: float, frame: Material) -> void:
	EventKit.cylinder(parent, radius, depth, Vector3(0.0, 0.0, z), frame, OCTAGON, 8)
	EventKit.cylinder(parent, radius * 0.78, depth + 6.0, Vector3(0.0, 0.0, z), EventKit.paint(Color(0.1, 0.09, 0.13)), OCTAGON, 8)


# --- STACK-SHIP: the armored barge (warm gray, a fat orange stripe, octagon
# frames up front, a green neon company sign).
static func _stack_ship(parent: Node3D) -> Dictionary:
	var gray := _hull(Color(0.66, 0.62, 0.6))
	var orange := _hull(Color(0.95, 0.5, 0.16))
	EventKit.box(parent, Vector3(230.0, 250.0, 900.0), Vector3(0.0, 0.0, 120.0), gray)
	_octagon_frame(parent, 165.0, 90.0, -420.0, gray)
	_octagon_frame(parent, 165.0, 90.0, -300.0, gray)
	EventKit.box(parent, Vector3(236.0, 256.0, 70.0), Vector3(0.0, 0.0, -150.0), orange)  # The stripe.
	for x: float in [-50.0, 40.0]:
		EventKit.box(parent, Vector3(60.0, 30.0, 70.0), Vector3(x, 126.0, -60.0), EventKit.paint(Color(0.12, 0.14, 0.2)))  # Windows.
	# Scaffolding along the flank: orange decks and thin poles.
	for side: float in [-1.0, 1.0]:
		for deck in 3:
			EventKit.box(parent, Vector3(12.0, 3.0, 120.0), Vector3(side * 121.0, -60.0 + deck * 45.0, 60.0 + deck * 30.0), orange)
		for pole in 4:
			EventKit.box(parent, Vector3(2.0, 140.0, 2.0), Vector3(side * 126.0, -10.0, 10.0 + pole * 40.0), EventKit.paint(Color(0.3, 0.3, 0.35)))
	# The engine block: ribbed, narrower, at the back.
	EventKit.box(parent, Vector3(170.0, 190.0, 160.0), Vector3(0.0, 0.0, 650.0), gray)
	for rib in 5:
		EventKit.box(parent, Vector3(180.0, 200.0, 8.0), Vector3(0.0, 0.0, 590.0 + rib * 28.0), EventKit.paint(Color(0.45, 0.43, 0.42), 0.0, HULL, 40.0))
	_engines(parent, [Vector2(-45.0, -45.0), Vector2(45.0, -45.0), Vector2(-45.0, 45.0), Vector2(45.0, 45.0)], 730.0, 32.0, Color(1.0, 0.75, 0.4))
	_signs(parent, "STACK-SHIP CORP.", Color(0.4, 1.0, 0.45), 115.0, Vector3(0.0, 40.0, 150.0))
	return {"size": Vector3(330.0, 330.0, 1560.0), "trail": Color(1.0, 0.7, 0.35),
		"names": ["SLAB: SHIP LOGISTICAL ARMORED BARGE", "STACK-SHIP CORP. NO. 12", "OREO CLASS OMEGA ORE CRAWLER"]}


# --- TANKER: the bulk LNG carrier (frosty hull, two huge glowing cryo
# spheres strapped on with riveted belts, cyan neon).
static func _tanker(parent: Node3D) -> Dictionary:
	var frost := _hull(Color(0.78, 0.86, 0.9))
	var belt := _hull(Color(0.62, 0.48, 0.38), 20.0)
	EventKit.box(parent, Vector3(200.0, 240.0, 1300.0), Vector3.ZERO, frost)
	EventKit.box(parent, Vector3(206.0, 30.0, 1306.0), Vector3(0.0, -60.0, 0.0), _hull(Color(0.55, 0.62, 0.68)))  # A walkway band.
	for z: float in [-220.0, 200.0]:
		for side: float in [-1.0, 1.0]:
			EventKit.ball(parent, 170.0, Vector3(side * 70.0, 0.0, z), EventKit.paint(Color(0.7, 0.9, 1.0), 0.55))
		EventKit.torus(parent, 168.0, 186.0, Vector3(150.0, 0.0, z), belt, Vector3(0.0, 0.0, PI / 2.0))
		EventKit.torus(parent, 168.0, 186.0, Vector3(-150.0, 0.0, z), belt, Vector3(0.0, 0.0, PI / 2.0))
	# Frost and icicles hanging under the hull.
	for i in 14:
		EventKit.box(parent, Vector3(8.0, 30.0 + (i * 37) % 50, 8.0), Vector3(-90.0 + (i * 53) % 180, -135.0, -600.0 + i * 90.0), EventKit.paint(Color(0.92, 0.97, 1.0)))
	_engines(parent, [Vector2(-50.0, 60.0), Vector2(50.0, 60.0)], 650.0, 40.0, Color(0.6, 0.9, 1.0))
	_signs(parent, "CRYO-LOGISTICS", Color(0.45, 1.0, 0.95), 100.0, Vector3(0.0, 80.0, -450.0))
	return {"size": Vector3(560.0, 360.0, 1400.0), "trail": Color(0.6, 0.95, 1.0),
		"names": ["TANKER CLASS BULK LNG CARRIER", "CRYO-LOGISTICS: KEEP FROSTY", "SLIGHTLY LEAKY COLD STORAGE"]}


# --- ORE-CRAWLER: a mobile refinery that eats asteroids (construction
# yellow, hazard-striped jaws full of rocks, cranes on top).
static func _ore_crawler(parent: Node3D, rng: RandomNumberGenerator) -> Dictionary:
	var yellow := _hull(Color(1.0, 0.78, 0.16))
	var hazard := EventKit.paint(Color.WHITE, 0.0, HAZARD, 30.0)
	var gray := _hull(Color(0.4, 0.4, 0.44))
	EventKit.box(parent, Vector3(240.0, 220.0, 800.0), Vector3(0.0, 0.0, 200.0), gray)
	EventKit.box(parent, Vector3(250.0, 230.0, 160.0), Vector3(0.0, 0.0, -100.0), yellow)
	# The jaws: an upper and a lower half, open, with teeth.
	EventKit.box(parent, Vector3(260.0, 80.0, 260.0), Vector3(0.0, 90.0, -320.0), hazard)
	EventKit.box(parent, Vector3(260.0, 80.0, 260.0), Vector3(0.0, -90.0, -320.0), hazard)
	for i in 5:
		var x := -100.0 + i * 50.0
		EventKit.box(parent, Vector3(26.0, 26.0, 26.0), Vector3(x, 45.0, -430.0), EventKit.paint(Color(0.9, 0.9, 0.85)), Vector3(0.0, 0.0, PI / 4.0))
		EventKit.box(parent, Vector3(26.0, 26.0, 26.0), Vector3(x, -45.0, -430.0), EventKit.paint(Color(0.9, 0.9, 0.85)), Vector3(0.0, 0.0, PI / 4.0))
	for i in 6:
		EventKit.ball(parent, rng.randf_range(20.0, 40.0), Vector3(rng.randf_range(-90.0, 90.0), rng.randf_range(-30.0, 30.0), rng.randf_range(-380.0, -260.0)),
				EventKit.paint(Color(0.6, 0.5, 0.42), 0.0, ROCK, 30.0))
	# Two cranes on top.
	for crane_z: float in [80.0, 360.0]:
		EventKit.box(parent, Vector3(16.0, 180.0, 16.0), Vector3(60.0, 200.0, crane_z), yellow)
		EventKit.box(parent, Vector3(16.0, 16.0, 260.0), Vector3(60.0, 290.0, crane_z - 110.0), yellow)
		EventKit.box(parent, Vector3(4.0, 120.0, 4.0), Vector3(60.0, 230.0, crane_z - 230.0), EventKit.paint(Color(0.2, 0.2, 0.22)))
	_engines(parent, [Vector2(-60.0, 0.0), Vector2(60.0, 0.0)], 600.0, 50.0, Color(1.0, 0.8, 0.3))
	_signs(parent, "MINING GUILD", Color(1.0, 0.85, 0.3), 120.0, Vector3(0.0, 30.0, 150.0))
	return {"size": Vector3(260.0, 400.0, 1300.0), "trail": Color(1.0, 0.8, 0.3),
		"names": ["ORE-CRAWLER: MOBILE REFINERY", "SYSTEM MINING GUILD BULK-ORE", "ASTEROID CONSUMER (DO NOT FEED)"]}


# --- ICE-TUG: a long-range comet harvester (icy blue with black diagonal
# stripes, a little cab on top, dragging a comet on a cable).
static func _ice_tug(parent: Node3D, rng: RandomNumberGenerator) -> Dictionary:
	var ice := _hull(Color(0.55, 0.78, 0.95))
	var black := _hull(Color(0.12, 0.12, 0.16))
	EventKit.box(parent, Vector3(200.0, 190.0, 700.0), Vector3(0.0, 0.0, 150.0), ice)
	for i in 4:
		EventKit.box(parent, Vector3(206.0, 196.0, 40.0), Vector3(0.0, 0.0, -80.0 + i * 140.0), black, Vector3(0.35, 0.0, 0.0))
	EventKit.box(parent, Vector3(110.0, 70.0, 120.0), Vector3(0.0, 130.0, 120.0), ice)  # The cab.
	EventKit.box(parent, Vector3(112.0, 22.0, 60.0), Vector3(0.0, 140.0, 62.0), EventKit.paint(Color(1.0, 0.85, 0.5), 1.0))  # Lit cab windows.
	# The comet, out ahead on a cable, with a glowing tail streaming back.
	EventKit.box(parent, Vector3(4.0, 4.0, 400.0), Vector3(0.0, 0.0, -400.0), EventKit.paint(Color(0.3, 0.3, 0.35)))
	EventKit.ball(parent, 120.0, Vector3(0.0, 0.0, -690.0), EventKit.paint(Color(0.75, 0.82, 0.9), 0.0, ROCK, 40.0), Vector3(1.0, 0.85, 1.1))
	for i in 5:
		EventKit.glow(parent, 260.0 - i * 30.0, Vector3(rng.randf_range(-20.0, 20.0), rng.randf_range(-20.0, 20.0), -560.0 + i * 70.0), Color(0.55, 0.85, 1.0))
	_engines(parent, [Vector2(-50.0, -40.0), Vector2(50.0, -40.0)], 500.0, 36.0, Color(0.5, 0.9, 1.0))
	_signs(parent, "TIDEWATER CANNERY", Color(0.4, 1.0, 0.5), 100.0, Vector3(0.0, 20.0, 260.0), 0.2)
	return {"size": Vector3(260.0, 300.0, 1600.0), "trail": Color(0.5, 0.9, 1.0),
		"names": ["ICE-TUG: LONG-RANGE COMET HARVESTER", "TIDEWATER CANNERY ICE DIVISION", "FROZEN SEAFOOD, FROZEN COMET"]}


# --- HAB-BRICK: an interstellar colony block (red-brown with rows of lit
# windows, teal octagon frames, a little garden deck glowing green).
static func _hab_brick(parent: Node3D, rng: RandomNumberGenerator) -> Dictionary:
	var brick := _hull(Color(0.6, 0.3, 0.22))
	var teal := _hull(Color(0.3, 0.62, 0.62))
	EventKit.box(parent, Vector3(220.0, 220.0, 1300.0), Vector3.ZERO, brick)
	for z: float in [-560.0, -150.0, 250.0, 600.0]:
		_octagon_frame(parent, 178.0, 40.0, z, teal)
	var lit: Array[Color] = [Color(1.0, 0.82, 0.45), Color(0.5, 1.0, 0.9), Color(1.0, 0.55, 0.75)]
	for side: float in [-1.0, 1.0]:
		for column in 18:
			var z := -520.0 + column * 58.0
			if absf(z + 150.0) < 40.0 or absf(z - 250.0) < 40.0:
				continue
			EventKit.box(parent, Vector3(3.0, rng.randf_range(60.0, 150.0), 10.0), Vector3(side * 111.0, rng.randf_range(-20.0, 20.0), z),
					EventKit.paint(lit[rng.randi_range(0, lit.size() - 1)], 1.2))
	EventKit.box(parent, Vector3(224.0, 30.0, 180.0), Vector3(0.0, 0.0, 50.0), EventKit.paint(Color(0.4, 0.9, 0.4), 0.6))  # The garden deck.
	_engines(parent, [Vector2(-60.0, -60.0), Vector2(60.0, -60.0), Vector2(-60.0, 60.0), Vector2(60.0, 60.0)], 650.0, 30.0, Color(1.0, 0.6, 0.4))
	_signs(parent, "COLONY MANAGEMENT CORP.", Color(0.6, 1.0, 1.0), 110.0, Vector3(0.0, 90.0, -350.0), 0.18)
	return {"size": Vector3(300.0, 300.0, 1400.0), "trail": Color(1.0, 0.6, 0.4),
		"names": ["HAB-BRICK: INTERSTELLAR COLONY BLOCK", "COLONY BLOCK 9 (NOW WITH BALCONIES)", "4,000 NEIGHBORS IN A BOX"]}


# --- GARBAGE SCOW: a low-orbit debris collector (an open, rusty frame
# heaped with junk, a grabber crane, a magenta neon sign, space gulls).
static func _garbage_scow(parent: Node3D, rng: RandomNumberGenerator) -> Dictionary:
	var rust := _hull(Color(0.45, 0.42, 0.3))
	var size := Vector3(240.0, 200.0, 1000.0)
	var half := size * 0.5
	# The frame: the box's twelve edges, plus ribs.
	for x: float in [-half.x, half.x]:
		for y: float in [-half.y, half.y]:
			EventKit.box(parent, Vector3(14.0, 14.0, size.z), Vector3(x, y, 0.0), rust)
	for z in range(-int(half.z), int(half.z) + 1, 125):
		EventKit.box(parent, Vector3(size.x, 12.0, 12.0), Vector3(0.0, half.y, z), rust)
		EventKit.box(parent, Vector3(size.x, 12.0, 12.0), Vector3(0.0, -half.y, z), rust)
		EventKit.box(parent, Vector3(12.0, size.y, 12.0), Vector3(half.x, 0.0, z), rust)
		EventKit.box(parent, Vector3(12.0, size.y, 12.0), Vector3(-half.x, 0.0, z), rust)
	EventKit.box(parent, Vector3(size.x, 10.0, size.z), Vector3(0.0, -half.y, 0.0), rust)  # The floor.
	# The junk heap.
	var junk: Array[Color] = [Color(0.5, 0.45, 0.4), Color(0.35, 0.45, 0.4), Color(0.6, 0.35, 0.3), Color(0.5, 0.5, 0.55)]
	for i in 26:
		var spot := Vector3(rng.randf_range(-90.0, 90.0), rng.randf_range(-90.0, 0.0), rng.randf_range(-450.0, 450.0))
		if i % 3 == 0:
			EventKit.ball(parent, rng.randf_range(20.0, 45.0), spot, EventKit.paint(junk[i % junk.size()], 0.0, ROCK, 30.0))
		else:
			EventKit.box(parent, Vector3(rng.randf_range(20.0, 70.0), rng.randf_range(15.0, 50.0), rng.randf_range(20.0, 80.0)), spot,
					EventKit.paint(junk[i % junk.size()], 0.0, CONTAINER, 30.0), Vector3(rng.randf_range(-0.5, 0.5), rng.randf(), 0.0))
	# The grabber crane at the back, and the cab.
	EventKit.box(parent, Vector3(70.0, 80.0, 90.0), Vector3(0.0, half.y + 40.0, 420.0), rust)
	EventKit.box(parent, Vector3(14.0, 14.0, 240.0), Vector3(0.0, half.y + 110.0, 330.0), _hull(Color(0.85, 0.65, 0.2)), Vector3(0.5, 0.0, 0.0))
	EventKit.box(parent, Vector3(40.0, 30.0, 30.0), Vector3(0.0, half.y + 30.0, 220.0), _hull(Color(0.85, 0.65, 0.2)))
	# Space gulls, circling (well, hanging about).
	for i in 7:
		EventKit.box(parent, Vector3(12.0, 2.0, 5.0), Vector3(rng.randf_range(-80.0, 80.0), half.y + rng.randf_range(80.0, 200.0), rng.randf_range(250.0, 500.0)), EventKit.paint(Color(0.95, 0.95, 0.95)))
	_engines(parent, [Vector2(-60.0, 0.0), Vector2(60.0, 0.0)], half.z, 34.0, Color(0.9, 0.5, 1.0))
	_signs(parent, "ORBITAL SANITATION", Color(1.0, 0.4, 0.85), half.x, Vector3(0.0, half.y + 40.0, 420.0), 0.2)
	return {"size": Vector3(260.0, 260.0, 1100.0), "trail": Color(0.9, 0.5, 1.0),
		"names": ["GARBAGE SCOW: LOW-ORBIT DEBRIS COLLECTOR", "ORBITAL SANITATION DEPT.", "MUNICIPAL WASTE HAULER (SMELLS FINE)"]}
