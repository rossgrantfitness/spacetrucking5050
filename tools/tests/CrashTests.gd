extends "res://tools/tests/TestSuite.gd"
## Checks for round 12's crashes: a hard enough hit (or an empty hull)
## sends the rig out of control, it blows up a moment later, and gentle
## bonks stay bonks. (The trip back to the last save is played by
## tools/smoke_crash.gd.)

const SHIP_SCENE := preload("res://scenes/flight/Ship.tscn")


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## A rig in the scene (so it can make its sounds and explosion).
func _ship() -> Ship:
	var holder := Node3D.new()
	_tree().root.add_child(holder)
	var ship := SHIP_SCENE.instantiate() as Ship
	holder.add_child(ship)
	return ship


func _done(ship: Ship) -> void:
	ship.get_parent().free()


func test_gentle_bonks_stay_bonks() -> void:
	var ship := _ship()
	var lost := []
	ship.lost_control.connect(func(reason: String) -> void: lost.append(reason))
	ship.bonk(GameState.tuning.bonk_hard_speed, ship.global_position)
	check(not ship.out_of_control and lost.is_empty(), "a hard bonk at cruise speed is still just a bonk")
	check(GameState.tuning.crash_speed > ship.ship_data.max_speed * 1.5, "crashing takes much more than cruising into something")
	_done(ship)


func test_a_crash_sends_the_rig_out_of_control_then_it_blows_up() -> void:
	var ship := _ship()
	var lost := []
	var boom := []
	ship.lost_control.connect(func(reason: String) -> void: lost.append(reason))
	ship.exploded.connect(func() -> void: boom.append(true))
	ship.bonk(GameState.tuning.crash_speed + 10.0, ship.global_position)
	check(ship.out_of_control and lost == ["crash"], "hitting something at crash speed sends the rig out of control")
	check(ship.trail_color().v < 0.3, "an out-of-control rig trails black smoke")
	# Tumble for the whole spin time: then it blows up.
	var steps := ceili(GameState.tuning.crash_spin_seconds / 0.05) + 2
	for i in steps:
		ship.call("_tumble", 0.05)
	check(ship.destroyed and boom.size() == 1, "after spinning out, the rig explodes")
	var explosions := ship.get_parent().get_children().filter(func(n: Node) -> bool: return n is Explosion)
	check(explosions.size() == 1, "there's an explosion where the rig was")
	ship.call("_tumble", 0.05)
	check(boom.size() == 1, "it only blows up once")
	_done(ship)


func test_an_empty_hull_is_a_wreck_too() -> void:
	var ship := _ship()
	var lost := []
	ship.lost_control.connect(func(reason: String) -> void: lost.append(reason))
	ship.hull = 0.01
	ship.bonk(GameState.tuning.bonk_hard_speed, ship.global_position)
	check(ship.out_of_control and lost == ["hull"], "when the hull gives out, the rig is wrecked")
	_done(ship)


func test_crashes_can_be_switched_off() -> void:
	var tuning := GameState.tuning
	var was := tuning.crashes_enabled
	tuning.crashes_enabled = false
	var ship := _ship()
	ship.bonk(tuning.crash_speed * 2.0, ship.global_position)
	check(not ship.out_of_control, "with crashes off, even a huge hit is a bonk")
	tuning.crashes_enabled = was
	_done(ship)


func test_jack_has_something_to_say() -> void:
	var lines: LineList = load("res://data/dialogue/wreck_lines.tres")
	check(lines.lines.size() >= 5, "Jacki has a few things to say on the WRECKED card")


func test_crashes_knock_you_away_from_what_you_hit() -> void:
	var tuning := GameState.tuning
	# Hit something above the rig: it's knocked down.
	var ship := _ship()
	ship.bonk(tuning.crash_speed + 10.0, ship.global_position + Vector3(0.0, 3.0, 0.0), Vector3.DOWN)
	check(ship.out_of_control and ship.flight.velocity.y < -20.0, "hitting the top of the rig sends it down")
	_done(ship)
	# Clip something on the left: knocked to the right, spinning about the hit.
	ship = _ship()
	ship.bonk(tuning.crash_speed + 10.0, ship.global_position + Vector3(-4.0, 0.0, -10.0), Vector3.RIGHT)
	check(ship.flight.velocity.x > 20.0, "hitting the left side sends it right")
	var spin: Vector3 = ship.get("_spin")
	check(absf(spin.normalized().y) > 0.7, "a hit on the nose's side spins it round like a pushed stick (about the up axis)")
	_done(ship)
