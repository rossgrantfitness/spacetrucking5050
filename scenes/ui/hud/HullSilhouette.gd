class_name HullSilhouette
extends HudWidget
## The very bottom-right corner: a tiny top-down picture of your rig. It's
## green when healthy, yellow when battered, red when it really needs a
## patch, and the spot you just bonked flashes red. The hull percentage sits
## on top.


## The rig from above, nose up. '#' = hull.
const PICTURE := [
	"...###...",
	"..#####..",
	"..#####..",
	"...###...",
	".#######.",
	"#########",
	"#########",
	"#########",
	"#########",
	"#########",
	".#######.",
	"..#####..",
	".###.###.",
	".#.#.#.#.",
]

enum Zone { NOSE, LEFT, MIDDLE, RIGHT, TAIL }

## Seconds the bonked spot keeps flashing.
const FLASH_SECONDS: float = 1.5

var _last_hull: float = 1.0
var _flash: float = 0.0
var _zone: Zone = Zone.MIDDLE
var _shown_hull: int = 100


func _init() -> void:
	bottom_row = true


func hud_step(delta: float, numbers_due: bool) -> void:
	var rig := ship()
	if rig == null:
		return
	if rig.hull < _last_hull - 0.0001:
		_flash = FLASH_SECONDS
		_zone = zone_for(rig.last_bonk_local)
	_last_hull = rig.hull
	_flash = maxf(_flash - delta, 0.0)
	if numbers_due:
		_shown_hull = roundi(rig.hull * 100.0)


## Which part of the picture a bonk at `spot` (relative to the ship: x =
## right, y = up, z = toward the back) should light up.
static func zone_for(spot: Vector3) -> Zone:
	if absf(spot.y) > maxf(absf(spot.x), absf(spot.z)):
		return Zone.MIDDLE  # Hit from above or below.
	if absf(spot.x) > absf(spot.z) * 0.6:
		return Zone.RIGHT if spot.x > 0.0 else Zone.LEFT
	return Zone.TAIL if spot.z > 0.0 else Zone.NOSE


func _draw() -> void:
	var rig := ship()
	if rig == null:
		return
	var corner := Vector2(size.x - MARGIN - 9.0, size.y - MARGIN - PICTURE.size())
	var health := GREEN
	if rig.hull < 0.3:
		health = RED
	elif rig.hull < 0.6:
		health = YELLOW
	box(Rect2(corner - Vector2(2, 2), Vector2(13, PICTURE.size() + 4)), BACKING)
	var flashing := _flash > 0.0 and blink(0.2)
	for y in PICTURE.size():
		var row: String = PICTURE[y]
		for x in row.length():
			if row[x] != "#":
				continue
			var color := health
			if flashing and _zone_at(x, y) == _zone:
				color = RED
			box(Rect2(corner + Vector2(x, y), Vector2.ONE), color)
	text_right(corner + Vector2(10, -8), str(_shown_hull), RED if _flash > 0.0 else tint(0.85))


func _zone_at(x: int, y: int) -> Zone:
	if y <= 3:
		return Zone.NOSE
	if y >= 11:
		return Zone.TAIL
	if x <= 2:
		return Zone.LEFT
	if x >= 6:
		return Zone.RIGHT
	return Zone.MIDDLE
