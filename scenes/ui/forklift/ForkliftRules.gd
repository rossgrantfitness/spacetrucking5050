class_name ForkliftRules
extends RefCounted
## LOADING THE RIG: the rules of the forklift minigame (ForkliftGame.gd draws
## it). Seen from above: pallets wait on the dock on the left; your rig's
## hold is on the right with a marked spot for each pallet. Drive the
## forklift up to a pallet with the forks pointing at it, lift it, carry it
## into the hold, and set it down on a free spot (it snaps in). Load every
## pallet and you're done. Bumping into things is just a bump. Nothing fails.
##
## Sizes are in the minigame's own pixels (WIDTH x HEIGHT).


const WIDTH: float = 240.0
const HEIGHT: float = 135.0
const PALLET := Vector2(14.0, 12.0)
## How far the forks reach in front of the forklift's middle.
const FORK_REACH: float = 11.0
const BODY_RADIUS: float = 6.0
const TOP_SPEED: float = 48.0
const ACCELERATION: float = 90.0
const TURN_RATE: float = 2.8
## The hold: an open-fronted box on the right (its open side faces the dock).
const HOLD := Rect2(150.0, 18.0, 80.0, 100.0)
## Faster than this into something is a bump (a thump, a little shake).
const BUMP_SPEED: float = 22.0

var position := Vector2(40.0, HEIGHT * 0.5)
## Which way the forks point (radians; 0 = right).
var heading: float = 0.0
var speed: float = 0.0
## The pallets: each {"at": Vector2 (its middle), "slot": slot index or -1, "carried": bool}.
var pallets: Array[Dictionary] = []
## The marked spots in the hold (their middles).
var slots: PackedVector2Array = PackedVector2Array()
var carrying: int = -1
var bumps: int = 0
var seconds: float = 0.0
var done := false


func _init(pallet_count: int = 4) -> void:
	pallet_count = clampi(pallet_count, 1, 8)
	var columns := 2
	var rows := ceili(pallet_count / float(columns))
	for i in pallet_count:
		var column := i % columns
		var row := floori(i / float(columns))
		slots.append(Vector2(HOLD.end.x - 14.0 - column * (PALLET.x + 8.0), HOLD.position.y + 14.0 + row * ((HOLD.size.y - 28.0) / maxf(rows - 1, 1))))
	for i in pallet_count:
		var row := floori(i / 2.0)
		pallets.append({"at": Vector2(14.0 + (i % 2) * 20.0, 22.0 + row * 24.0), "slot": -1, "carried": false})
	position = Vector2(70.0, HEIGHT * 0.5)
	heading = PI  # Facing the pallets.


## Where the tips of the forks are.
func fork_tip() -> Vector2:
	return position + Vector2.from_angle(heading) * FORK_REACH


## How many pallets are in the hold.
func loaded() -> int:
	var count := 0
	for pallet in pallets:
		if int(pallet["slot"]) >= 0:
			count += 1
	return count


## Drives on. `drive` is -1 (reverse) to 1 (forward); `turn` -1 (left) to 1
## (right). Returns "bump" when it bumped into something, otherwise "".
func step(delta: float, drive: float, turn: float) -> String:
	if done:
		return ""
	seconds += delta
	speed = move_toward(speed, drive * TOP_SPEED, ACCELERATION * delta)
	if absf(drive) < 0.05:
		speed = move_toward(speed, 0.0, ACCELERATION * 1.5 * delta)
	# Forklifts steer from the back: reversing turns the other way round.
	heading += turn * TURN_RATE * delta * (1.0 if speed >= -1.0 else -1.0)
	var before := position
	position += Vector2.from_angle(heading) * speed * delta
	var hit := _push_out()
	if carrying >= 0:
		pallets[carrying]["at"] = fork_tip() + Vector2.from_angle(heading) * PALLET.x * 0.35
	if hit and absf(speed) > BUMP_SPEED:
		bumps += 1
		speed *= -0.3
		return "bump"
	if hit:
		speed *= 0.5
		if position.distance_to(before) < 0.01:
			speed = 0.0
	return ""


## Lift or set down, whichever makes sense. Returns "lift", "slot" (set down
## in a spot in the hold), "drop" (set down on the floor), "done" (that was
## the last one) or "" (nothing to lift here).
func use_forks() -> String:
	if done:
		return ""
	if carrying < 0:
		var tip := fork_tip()
		for i in pallets.size():
			var pallet := pallets[i]
			if Rect2(pallet["at"] - PALLET * 0.5, PALLET).grow(4.0).has_point(tip):
				carrying = i
				pallet["carried"] = true
				pallet["slot"] = -1
				return "lift"
		return ""
	var carried := pallets[carrying]
	var spot := _free_slot_near(carried["at"])
	carried["carried"] = false
	carrying = -1
	if spot >= 0:
		carried["at"] = slots[spot]
		carried["slot"] = spot
		if loaded() == pallets.size():
			done = true
			return "done"
		return "slot"
	return "drop"


func _free_slot_near(point: Vector2) -> int:
	var best := -1
	var best_distance := 10.0
	for i in slots.size():
		var taken := false
		for pallet in pallets:
			if int(pallet["slot"]) == i:
				taken = true
		var distance := point.distance_to(slots[i])
		if not taken and distance < best_distance:
			best = i
			best_distance = distance
	return best


## Keeps the forklift on the floor, out of the hold's walls and out of the
## pallets (the one it's carrying aside). Returns whether it hit anything.
func _push_out() -> bool:
	var hit := false
	var clamped := Vector2(clampf(position.x, BODY_RADIUS, WIDTH - BODY_RADIUS), clampf(position.y, BODY_RADIUS, HEIGHT - BODY_RADIUS))
	if clamped != position:
		position = clamped
		hit = true
	for wall in walls():
		hit = _push_from(wall) or hit
	for i in pallets.size():
		if i != carrying:
			hit = _push_from(Rect2(pallets[i]["at"] - PALLET * 0.5, PALLET)) or hit
	return hit


## The hold's three walls (top, bottom and back; the front is open).
func walls() -> Array[Rect2]:
	return [Rect2(HOLD.position, Vector2(HOLD.size.x, 3.0)), Rect2(HOLD.position + Vector2(0.0, HOLD.size.y - 3.0), Vector2(HOLD.size.x, 3.0)),
			Rect2(Vector2(HOLD.end.x - 3.0, HOLD.position.y), Vector2(3.0, HOLD.size.y))]


func _push_from(box: Rect2) -> bool:
	var nearest := Vector2(clampf(position.x, box.position.x, box.end.x), clampf(position.y, box.position.y, box.end.y))
	var away := position - nearest
	if away.length() >= BODY_RADIUS:
		return false
	if away.length() < 0.001:
		away = (position - box.get_center()).normalized() if position != box.get_center() else Vector2.LEFT
		position = nearest + away * BODY_RADIUS
	else:
		position = nearest + away.normalized() * BODY_RADIUS
	return true
