class_name StatusLights
extends HudWidget
## The left edge: a column of tiny warning lights that stay dark until
## something happens. When one lights up, its name appears next to it.
## - PROX:  something is close; blinks faster the closer it gets.
## - GRAV:  a gravity well is pulling you (SLING: you could slingshot).
## - STORM: a solar or ion storm around you.
## - COPS:  a speed trap nearby (the trucker's radar detector).
## - FUEL:  under 20% fuel.
## Gravity wells, storms and cops arrive with M5; until then those lights
## only come on in the HUD demo (F9).


const ICONS := {
	"PROX": ["..###..", ".#...#.", "#..#..#", "#.###.#", "#..#..#", ".#...#.", "..###.."],
	"GRAV": [".#####.", "#.....#", "#.###.#", "#.#.#.#", "#.#...#", "#.#####", "......."],
	"STORM": ["...##..", "..##...", ".##....", ".#####.", "...##..", "..##...", ".##...."],
	"COPS": ["..###..", ".##.##.", ".#####.", ".#####.", "#######", "#######", "......."],
	"FUEL": ["####...", "#..#.#.", "#..#..#", "####..#", "####..#", "####.##", "####..."],
}
const ROW_SPACING: float = 11.0


func _draw() -> void:
	var rig := ship()
	if rig == null:
		return
	var tuning := GameState.tuning
	var top := floorf(size.y * 0.5 - ROW_SPACING * 2.5)
	var row := 0
	for light: String in ICONS:
		var state := _light(light, rig, tuning)  # [on, color, label]
		var spot := Vector2(MARGIN, top + row * ROW_SPACING)
		box(Rect2(spot - Vector2(1, 1), Vector2(9, 9)), BACKING)
		if state[0]:
			pixels(spot, ICONS[light], state[1])
			text(spot + Vector2(10, 1), state[2], state[1])
		else:
			pixels(spot, ICONS[light], tint(0.16))
		row += 1


## Whether a light is on, its color right now (blinking included) and its
## label.
func _light(light: String, rig: Ship, tuning: Tuning) -> Array:
	match light:
		"PROX":
			var nearest := hud.nearest_obstacle()
			if hud.demo:
				nearest = tuning.proximity_range * (0.5 + 0.5 * sin(hud.time * 0.7))
			if nearest >= tuning.proximity_range:
				return [false]
			var closeness := nearest / tuning.proximity_range
			var on := blink(lerpf(0.1, 0.8, closeness))
			return [true, (RED if closeness < 0.25 else YELLOW) if on else tint(0.25), "PROX"]
		"GRAV":
			if rig.slingshot_ready or (hud.demo and blink(4.0)):
				return [true, GREEN if blink(0.4) else tint(0.4), "SLING"]
			if rig.gravity_pull > 0.05 or hud.demo:
				return [true, YELLOW, "GRAV"]
		"STORM":
			if rig.storm > 0.05 or hud.demo:
				return [true, YELLOW if blink(1.2) or rig.storm < 0.5 else RED, "STORM"]
		"COPS":
			if rig.speed_trap > 0.05 or hud.demo:
				return [true, RED if blink(0.3) else YELLOW, "COPS"]
		"FUEL":
			var fuel := rig.flight.fuel
			if fuel < tuning.low_fuel_warning or hud.demo:
				return [true, RED if blink(0.25 if fuel <= 0.0 else 0.9) else tint(0.3), "FUEL"]
	return [false]
