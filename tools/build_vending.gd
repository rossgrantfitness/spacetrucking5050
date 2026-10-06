extends "res://tools/build_placeholder_models.gd"
## Builds the vending machine, res://scenes/hub/VendingMachine.tscn: a dark
## cabinet with a glowing window full of colorful packets (in the galaxy's
## brand colors, res://data/brands/brands.tres), a coin slot, a drop tray,
## and the ServicePoint that opens the vending menu (HubServices.vending).
## Drop it into a room's "Things" and it works; what it sells depends on the
## room's place_id.
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/build_vending.gd

const OUTPUT := "res://scenes/hub/VendingMachine.tscn"
const SERVICE := "res://scenes/hub/ServicePoint.gd"


func _initialize() -> void:
	var machine := Node3D.new()
	machine.name = "VendingMachine"
	var body := _paint(Color(0.12, 0.13, 0.22), null)
	var trim := _paint(Color(0.9, 0.3, 0.6), null)
	_box(machine, "Cabinet", Vector3(1.0, 1.95, 0.75), Vector3(0.0, 0.975, 0.0), body)
	_box(machine, "Header", Vector3(1.02, 0.18, 0.77), Vector3(0.0, 1.86, 0.0), _glow(Color(1.0, 0.35, 0.75), 2.0))
	# The window: a glowing back, shelves, and rows of packets.
	_box(machine, "Window", Vector3(0.62, 1.15, 0.02), Vector3(-0.12, 1.12, 0.38), _glow(Color(0.55, 0.8, 1.0), 0.8, Color(0.2, 0.3, 0.45)))
	var catalog: BrandCatalog = load("res://data/brands/brands.tres")
	var colors: Array[Color] = []
	for brand in catalog.brands:
		colors.append(brand.color)
	for row in 4:
		var y := 0.66 + row * 0.27
		_box(machine, "Shelf", Vector3(0.62, 0.02, 0.08), Vector3(-0.12, y - 0.07, 0.36), trim)
		for column in 4:
			var color := colors[(row * 4 + column) % colors.size()]
			_box(machine, "Packet", Vector3(0.11, 0.13, 0.05), Vector3(-0.36 + column * 0.16, y, 0.37), _glow(color, 0.6, color))
	# Buttons and the coin slot on the right, the drop tray at the bottom.
	_box(machine, "Keypad", Vector3(0.22, 0.4, 0.03), Vector3(0.36, 1.2, 0.38), _paint(Color(0.25, 0.26, 0.32), null))
	for k in 6:
		_box(machine, "Key", Vector3(0.05, 0.04, 0.02), Vector3(0.31 + (k % 2) * 0.1, 1.3 - floori(k / 2.0) * 0.09, 0.4), _glow(Color(1.0, 0.85, 0.3), 1.2))
	_box(machine, "CoinSlot", Vector3(0.04, 0.1, 0.02), Vector3(0.36, 0.92, 0.4), _glow(Color(0.4, 1.0, 0.5), 1.5))
	_box(machine, "Tray", Vector3(0.62, 0.22, 0.06), Vector3(-0.12, 0.3, 0.36), _paint(Color(0.05, 0.05, 0.08), null))
	_box(machine, "TrayFlap", Vector3(0.6, 0.12, 0.02), Vector3(-0.12, 0.34, 0.39), _paint(Color(0.3, 0.32, 0.4), null))
	# Something solid to bump into.
	var solid := StaticBody3D.new()
	solid.name = "Solid"
	machine.add_child(solid)
	var solid_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(1.0, 1.95, 0.75)
	solid_shape.shape = box_shape
	solid_shape.position = Vector3(0.0, 0.975, 0.0)
	solid.add_child(solid_shape)
	# Walk up to the front and press E.
	var use := Area3D.new()
	use.name = "Use"
	use.set_script(load(SERVICE))
	use.set("prompt", "VENDING")
	use.set("menu", "vending")
	use.position = Vector3(0.0, 1.0, 0.7)
	machine.add_child(use)
	var use_shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.0
	use_shape.shape = sphere
	use.add_child(use_shape)
	_save(machine, OUTPUT)
	quit()
