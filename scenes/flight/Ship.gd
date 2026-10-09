class_name Ship
extends CharacterBody3D
## The player's rig in flight.
##
## FlightModel.gd decides HOW it moves; this script moves the actual ship in
## the world, leans the visible model into turns, and shares the ship's state
## with the camera, HUD, trails and engine sound.
##
## The look of the ship lives in its own scene inside the VisualPivot node
## (the Thumper's is RigLoadVisual.tscn: the developer's models, one per load
## size), so the art can be swapped without touching this code.


## Emitted after the ship jumps somewhere new (e.g. "back to the start"), so
## things like the engine trails can wipe themselves clean.
signal teleported
## Emitted when the ship bonks into something. `strength` runs from 0 (a
## gentle bump) to 1 (the hardest bonk); `where` is the spot that got hit.
signal bonked(strength: float, where: Vector3)
## Emitted when the docking autopilot reaches the end of its route.
signal autopilot_arrived
## Emitted when the pilot grabs the controls and the cruise autopilot lets go.
signal cruise_released
## Emitted each time rough flying knocks the cargo around enough to notice
## (a thump in the hold). `reason` says why: "turn", "brake" or "boost".
signal cargo_jostled(reason: String)
## Emitted when a catastrophic hit sends the rig out of control (`reason`:
## "crash" for a hit at crash speed, "hull" when the hull gave out).
signal lost_control(reason: String)
## Emitted when the out-of-control rig finally blows up.
signal exploded
## Newtonian flight: Flight Assist was switched on or off.
signal flight_assist_switched(on: bool)

## The ship's personality: speed, handling, boost. See res://data/ships/.
@export var ship_data: ShipData

## The rules of flying (see FlightModel.gd).
var flight := FlightModel.new()
## Jolts to the camera: a kick when boost fires, a rumble while it burns, and
## bonks. Both cameras read it.
var shake := ScreenShake.new()
## How healthy the hull is: 1 = like new, 0 = held together with duct tape.
## Nothing ever explodes; a battered rig just smokes and sparks.
var hull: float = 1.0
## How intact the cargo is: 1 = pristine, 0 = a box of crumbs. Bonks knock
## it a little. (Fragile jobs pay a bonus that shrinks with it.)
var cargo_condition: float = 1.0
## How rough the ride is for the cargo right now, 0 (smooth) to 1
## (rattling). Hard turns, slides, hard braking and boosting shake it; above
## the comfy limit the cargo slowly gets damaged. (Speeding up straight
## ahead never hurts it.)
var cargo_stress: float = 0.0
## Where the last bonk hit, relative to the ship (x = right, y = up,
## z = toward the back). The HUD's little hull picture flashes that spot.
var last_bonk_local := Vector3.ZERO
## How far the rig has flown this trip, in meters (the dashboard odometer).
var odometer: float = 0.0

## Gentle hazards (M5) report here, and the HUD's status lights read them.
## Nothing sets these yet. All run from 0 (nothing) to 1 (full on).
var gravity_pull: float = 0.0
## A gravity well you could slingshot around for free speed.
var slingshot_ready: bool = false
var storm: float = 0.0
## Space cops' speed trap nearby (the trucker's radar detector).
var speed_trap: float = 0.0
## Charging toward a system jump point: below 0 = none near, 0 to 1 = charge.
var jump_charge: float = -1.0

## While docking, the autopilot flies the rig through these spots (in the
## world, in order) and ignores the pilot. Empty = the pilot is flying.
var autopilot_route: Array[Vector3] = []
## The autopilot's cruising speed, in m/s. It slows down for the last spot
## (unless it was told to keep rolling, like out of a drive-through).
var autopilot_speed: float = 40.0
## The cruise autopilot flying a charted course (see CruisePilot.gd), or
## null when you're driving. Unlike the docking autopilot it flies by the
## normal rules, and lets go the moment you touch the controls.
var cruise: CruisePilot

const SPOOL_SOUND := preload("res://audio/generated/spool.wav")
const THUMP_SOUND := preload("res://audio/generated/thump.wav")
const RATTLE_SOUND := preload("res://audio/generated/rattle.wav")
const ALARM_SOUND := preload("res://audio/generated/alarm.wav")
const EXPLOSION_SOUND := preload("res://audio/generated/explosion.wav")
## How many sparks fly off the rig while it's out of control.
const SPARK_COUNT: int = 10
## How much cargo damage (0 to 1) adds up to one thump in the hold.
const DAMAGE_PER_THUMP: float = 0.004
## How long one boost jolt takes to push the rig sideways, in seconds.
const JOLT_SECONDS: float = 0.35

var _autopilot_stops: bool = true

## Boost jolts (see _boost_jolts): when the next one comes, which way it
## pushes, and how long it has left to push.
var _jolt_clock: float = 1.0
var _jolt_push := Vector3.ZERO
var _jolt_left: float = 0.0
## Out of control after a catastrophic hit: no steering, tumbling, sparks
## and smoke. Then `destroyed` once it's blown up.
var out_of_control: bool = false
## OVERDRIVE hull strain, 0 to 1: builds while going faster than
## overdrive_strain_kmh (faster = quicker), fades when you ease off. At 1
## the rig can't take its own speed: it loses control and blows up.
var overdrive_strain: float = 0.0
var destroyed: bool = false
var _spin := Vector3.ZERO
var _wreck_clock: float = 0.0
var _sparks: Array[MeshInstance3D] = []
var _alarm_sound: AudioStreamPlayer
var _boom_sound: AudioStreamPlayer
var _was_boosting := false
var _paint_trail := Color(1, 1, 1, 0)
## The job whose load is hanging under the rig (CargoPod), so it's only
## refitted when the job changes.
var _cargo_shown := "-"
## Cargo damage since the last thump in the hold.
var _jostle := 0.0
## Why the cargo got knocked around most recently ("turn", "brake", "boost").
var last_jostle_reason: String = ""
## How many thumps in the hold this flight (the HUD watches it).
var jostles: int = 0
var _thump_sound: AudioStreamPlayer
var _rattle_sound: AudioStreamPlayer
var _spool_sound: AudioStreamPlayer
var _last_velocity := Vector3.ZERO
var _bonk_cooldown := 0.0

@onready var controls: ShipControls = $ShipControls
## The inside of the cab, shown in cockpit view.
@onready var cockpit: Cockpit = $Cockpit
@onready var _visual_pivot: Node3D = $VisualPivot


func _ready() -> void:
	# Start facing whichever way the ship was placed in the editor.
	var facing := global_basis.get_euler()
	flight.reset(facing.y, facing.x, facing.z)
	_spool_sound = AudioStreamPlayer.new()
	_spool_sound.stream = SPOOL_SOUND
	_spool_sound.volume_db = -8.0
	add_child(_spool_sound)
	_thump_sound = AudioStreamPlayer.new()
	_thump_sound.stream = THUMP_SOUND
	add_child(_thump_sound)
	_rattle_sound = AudioStreamPlayer.new()
	_rattle_sound.stream = RATTLE_SOUND
	_rattle_sound.volume_db = -80.0
	add_child(_rattle_sound)
	_alarm_sound = AudioStreamPlayer.new()
	_alarm_sound.stream = ALARM_SOUND
	_alarm_sound.volume_db = -6.0
	add_child(_alarm_sound)
	_boom_sound = AudioStreamPlayer.new()
	_boom_sound.stream = EXPLOSION_SOUND
	add_child(_boom_sound)


func _physics_process(delta: float) -> void:
	if out_of_control:
		_tumble(delta)
		return
	if not autopilot_route.is_empty():
		_fly_autopilot(delta)
		return
	flight.shakiness = 0.5 if float(GameState.rig.get("snack", 0.0)) > 0.0 else 1.0
	# Newtonian flight: G switches Flight Assist (the autopilot always flies
	# with it on).
	if flight.newtonian and not controls.hands_free and Input.is_action_just_pressed("flight_assist"):
		flight.flight_assist = not flight.flight_assist
		flight_assist_switched.emit(flight.flight_assist)
	if flight.newtonian and cruise != null and not flight.flight_assist:
		flight.flight_assist = true
		flight_assist_switched.emit(true)
	controls.max_speed = ship_data.max_speed
	controls.forward_speed = flight.forward_speed()
	controls.newtonian = flight.newtonian
	controls.flight_assist = flight.flight_assist
	var hands := controls.read(delta)
	if cruise != null:
		if cruise.feel_hands(hands, delta):
			cruise = null
			cruise_released.emit()
		else:
			var nudge := hands
			hands = cruise.steer(self, delta)
			CruisePilot.mix_in(hands, nudge, GameState.tuning)
			# Keep the lever where the autopilot is driving, so taking over
			# is smooth.
			controls.lever = clampf(flight.forward_speed() / ship_data.max_speed, 0.0, 1.0)
	flight.load_share = load_share()
	flight.update(delta, hands, ship_data, GameState.tuning)
	global_basis = flight.orientation()
	velocity = flight.velocity
	# move_and_slide moves us along `velocity`, and if we touch an asteroid it
	# slides us along its surface instead of passing through. The momentum
	# that went into the rock is lost, so hand the result back to the flight
	# rules, after checking whether we bonked into something.
	var before := velocity
	move_and_slide()
	flight.velocity = velocity
	_check_for_bonks(before, delta)
	show_cargo()
	_shake_cargo(delta)
	_strain_the_hull(delta)
	odometer += flight.speed() * delta
	_update_shake(delta)
	# Lean the visible model into turns. Arcade: only the model leans (the
	# ship itself never rolls, so the camera's horizon stays level).
	# Newtonian: the ship really rolls, so the lean settles to nothing.
	_visual_pivot.rotation = Vector3(flight.nose_tilt, 0.0, flight.bank + flight.cargo_sway + flight.shimmy_roll(GameState.tuning))


## 0 when stopped, 1 at normal top speed, above 1 when boosted past it.
## How heavy the load in the back is for this rig: the job's weight
## against the rig's load_rating (0 = empty, 1 = a full load; capped at
## max_load_share). See FlightModel.load_share.
func load_share() -> float:
	var job := GameState.active_job()
	if job == null or ship_data == null or ship_data.load_rating <= 0.0:
		return 0.0
	return clampf(job.weight / ship_data.load_rating, 0.0, GameState.tuning.max_load_share)


func speed_ratio() -> float:
	return flight.speed() / ship_data.max_speed


## The color of this ship's engine trails (used by EngineTrail): its paint
## job's, or the rig's own.
func trail_color() -> Color:
	if out_of_control:
		return Color(0.18, 0.17, 0.2)  # Black smoke.
	return _paint_trail if _paint_trail.a > 0.0 else ship_data.trail_color


## Dresses the rig: its own model (if its data has one) and a paint job (a
## tint over the hull, and a trail color). Called by the flight scene.
func apply_look(paint: PaintJob) -> void:
	if ship_data.visual_scene != null:
		for old in _visual_pivot.get_children():
			old.queue_free()
		var look := ship_data.visual_scene.instantiate() as Node3D
		_visual_pivot.add_child(look)
	if paint != null:
		_paint_trail = paint.trail_color
		if paint.strength > 0.0:
			for part in _visual_pivot.find_children("*", "MeshInstance3D", true, false):
				_tint(part as MeshInstance3D, paint)
		for flare in _visual_pivot.find_children("*", "EngineFlare", true, false):
			(flare as EngineFlare).refresh_color()
	_add_exhausts()
	# The upgrades you can see (bumpers, a radar dish, horns...), after the
	# paint so the chrome stays chrome.
	RigAddOns.fit(_visual_pivot, GameState.owned_add_ons())
	_cargo_shown = "-"  # (Hang the load back on the new model.)
	show_cargo()


## Hangs the load you're hauling under the rig (CargoPod), if it's changed.
func show_cargo() -> void:
	var job := GameState.active_job()
	var id := job.id if job != null else ""
	if id == _cargo_shown or not is_inside_tree():
		return
	_cargo_shown = id
	# The Thumper carries its load in its own models (one per load size);
	# other models get the load slung underneath.
	var look := _rig_look()
	if look != null:
		look.show_load(job != null, load_share())
		CargoPod.fit(_visual_pivot, null, 0.0)
	else:
		CargoPod.fit(_visual_pivot, job, load_share())


## The rig model that shows its own load (RigLoadVisual), if that's what's on.
func _rig_look() -> RigLoadVisual:
	for child in _visual_pivot.get_children():
		if child is RigLoadVisual and not child.is_queued_for_deletion():
			return child as RigLoadVisual
	return null


## Puts a flame (EngineExhaust) on every engine nozzle of the model, sized
## to the glowing engine plate it sits on.
func _add_exhausts() -> void:
	for nozzle in _visual_pivot.find_children("Nozzle*", "Marker3D", true, false):
		if nozzle.is_queued_for_deletion() or nozzle.get_parent().is_queued_for_deletion():
			continue
		var exhaust := nozzle.get_node_or_null("Exhaust") as EngineExhaust
		if exhaust != null:
			exhaust.refresh_color()
			continue
		exhaust = EngineExhaust.new()
		exhaust.name = "Exhaust"
		exhaust.radius = _nozzle_radius(nozzle as Node3D)
		exhaust.length = exhaust.radius * 7.5
		nozzle.add_child(exhaust)


## Half the size of the glowing engine plate nearest the nozzle (or 1.2 m).
func _nozzle_radius(nozzle: Node3D) -> float:
	var best := 1.2
	var nearest := INF
	for glow in nozzle.get_parent().get_children():
		if glow is MeshInstance3D and str(glow.name).begins_with("EngineGlow") and (glow as MeshInstance3D).mesh is BoxMesh:
			var gap := (glow as Node3D).position.distance_to(nozzle.position)
			if gap < nearest:
				nearest = gap
				var size := ((glow as MeshInstance3D).mesh as BoxMesh).size
				best = minf(size.x, size.y) * 0.45
	return best


## Tints one part of the model, leaving glowing bits (lights, engines) alone.
func _tint(part: MeshInstance3D, paint: PaintJob) -> void:
	if part.mesh == null or part is EngineFlare or part is EngineTrail:
		return
	for i in part.mesh.get_surface_count():
		var material := part.get_active_material(i) as ShaderMaterial
		if material == null or material.get_shader_parameter("albedo") == null:
			continue
		var glow: Variant = material.get_shader_parameter("emission_strength")
		if glow != null and float(glow) > 0.0:
			continue
		var painted := material.duplicate() as ShaderMaterial
		var albedo: Color = material.get_shader_parameter("albedo")
		painted.set_shader_parameter("albedo", albedo.lerp(albedo * paint.hull_tint * 1.3, paint.strength))
		part.set_surface_override_material(i, painted)


## How far past top speed we are, from 0 (at or below top speed) to 1 (at
## full boost speed). Drives the boost-speed effects.
func overspeed_ratio() -> float:
	var top := ship_data.max_speed
	return clampf((flight.speed() - top) / (FlightModel.boosted_top_speed(ship_data) - top), 0.0, 1.0)


## Knocks the hull, shakes the camera, bounces the ship a little and tells
## everyone (sparks, sound, HUD). `impact` is how fast we hit, in m/s.
func bonk(impact: float, where: Vector3, away: Vector3 = Vector3.ZERO) -> void:
	var tuning := GameState.tuning
	var strength := bonk_strength(impact, tuning)
	# (Bumper bars and cargo cradles soften it: see the upgrades.)
	hull = maxf(hull - lerpf(tuning.bonk_damage_min, tuning.bonk_damage_max, strength) * ship_data.hull_care, 0.0)
	cargo_condition = maxf(cargo_condition - lerpf(tuning.cargo_damage_min, tuning.cargo_damage_max, strength) * ship_data.cargo_care, 0.0)
	last_bonk_local = global_basis.inverse() * (where - global_position)
	shake.add_trauma(lerpf(0.25, tuning.bonk_max_shake, strength))
	flight.velocity += away * impact * tuning.bonk_bounce
	_bonk_cooldown = tuning.bonk_cooldown
	if Settings.rumble:
		Input.start_joy_vibration(0, 0.3 + 0.5 * strength, 0.2 + 0.8 * strength, 0.15 + 0.25 * strength)
	bonked.emit(strength, where)
	if tuning.crashes_enabled:
		if impact >= tuning.crash_instant_speed:
			obliterate(where, away, impact)
		elif impact >= tuning.crash_speed:
			lose_control("crash", where, away, impact)
		elif hull <= 0.0 and tuning.crash_on_empty_hull:
			lose_control("hull", where, away, impact)


## A catastrophic hit: the rig spins out of control (no steering, the
## alarm wailing, sparks and black smoke) and blows up a moment later.
##
## It's physical: the hit knocks the rig away from what it hit (hit
## something above you and you're sent down; clip something on your left
## and you're sent right), and sets it tumbling around the point of impact,
## harder the harder the hit. `where` is where it hit (world), `away` the
## direction away from what it hit, `impact` how hard (m/s). Without them
## (no hit, like the hull just giving out) it tumbles any old way.
func lose_control(reason: String, where: Vector3 = Vector3.INF, away: Vector3 = Vector3.ZERO, impact: float = 0.0) -> void:
	if out_of_control:
		return
	var tuning := GameState.tuning
	out_of_control = true
	cruise = null
	autopilot_route.clear()
	flight.boosting = false
	if where.is_finite() and not away.is_zero_approx():
		_knock(where, away, impact)
	else:
		_spin = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized() * tuning.crash_spin_speed
	# The harder the hit, the shorter the fuse.
	_wreck_clock = lerpf(tuning.crash_spin_seconds, tuning.crash_fuse_min_seconds, crash_severity(impact, tuning))
	shake.add_trauma(1.0)
	_spool_sound.stop()
	_alarm_sound.volume_db = -6.0
	_alarm_sound.play()
	var spark_paint := EventKit.paint(Color(1.0, 0.8, 0.35), 2.6)
	for i in SPARK_COUNT:
		var spark := EventKit.box(self, Vector3(0.3, 0.3, 0.3), Vector3.ZERO, spark_paint)
		spark.visible = false
		_sparks.append(spark)
	if Settings.rumble:
		Input.start_joy_vibration(0, 1.0, 1.0, tuning.crash_spin_seconds)
	lost_control.emit(reason)


## OVERDRIVE: past overdrive_strain_kmh the hull strains, quicker the
## faster you go (see "Overdrive" in tuning.tres). The alarm starts quietly
## at half strain and gets louder. Full strain: she can't take it.
func _strain_the_hull(delta: float) -> void:
	var tuning := GameState.tuning
	var kmh := flight.speed() * 3.6
	var past := (kmh - tuning.overdrive_strain_kmh) / tuning.overdrive_strain_span_kmh
	if past > 0.0:
		# Coasting still strains her (a bit less than the burn): you can't
		# boost up to a crazy speed, let go and cruise there for free.
		var share := 1.0 if flight.boosting or not flight.newtonian else tuning.overdrive_coast_strain
		overdrive_strain += past * past * tuning.overdrive_strain_rate * share * delta
	else:
		overdrive_strain -= tuning.overdrive_strain_recovery * delta
	overdrive_strain = clampf(overdrive_strain, 0.0, 1.0)
	if overdrive_strain > 0.5:
		_alarm_sound.volume_db = lerpf(-24.0, -8.0, (overdrive_strain - 0.5) / 0.5)
		if not _alarm_sound.playing:
			_alarm_sound.play()
	elif overdrive_strain < 0.4 and _alarm_sound.playing:
		_alarm_sound.stop()
	if overdrive_strain >= 1.0 and tuning.crashes_enabled:
		lose_control("overdrive")  # Went too fast.
	# OVERSPEED: going far too fast wears the hull, boost or no boost:
	# slowly above overspeed_wobble_kmh, seriously above overspeed_danger_kmh.
	if kmh > tuning.overspeed_wobble_kmh and not out_of_control:
		var wear := tuning.overspeed_hull_rate * clampf((kmh - tuning.overspeed_wobble_kmh) / maxf(tuning.overspeed_danger_kmh - tuning.overspeed_wobble_kmh, 1.0), 0.0, 1.0)
		var danger := maxf(kmh - tuning.overspeed_danger_kmh, 0.0) / 1000.0
		wear += tuning.overspeed_danger_rate * (danger + danger * danger)
		hull = maxf(hull - wear * ship_data.hull_care * delta, 0.0)
		if hull <= 0.0 and tuning.crashes_enabled and tuning.crash_on_empty_hull:
			lose_control("hull")  # Shook herself apart.


## A hit far too hard to survive (see crash_instant_speed): the rig goes up
## right there, against what it hit. No bounce, no tumble.
func obliterate(where: Vector3, away: Vector3, impact: float) -> void:
	if destroyed:
		return
	out_of_control = true
	cruise = null
	autopilot_route.clear()
	flight.boosting = false
	lost_control.emit("impact")
	_explode(where, away, clampf(impact / maxf(GameState.tuning.crash_instant_speed, 1.0), 1.0, 2.5))


## How bad a crash at `impact` m/s is: 0 (only just a crash) to 1 (only just
## short of going up at once).
static func crash_severity(impact: float, tuning: Tuning) -> float:
	return clampf((impact - tuning.crash_speed) / maxf(tuning.crash_instant_speed - tuning.crash_speed, 1.0), 0.0, 1.0)


## The physics of a crash: bounces the rig off along `away` (the way out
## of what it hit) and spins it around the hit: like a push on one end of a
## stick, the spin axis is (where it hit, from the middle) x (the push).
func _knock(where: Vector3, away: Vector3, impact: float) -> void:
	var tuning := GameState.tuning
	var hard := clampf(impact / maxf(tuning.crash_speed, 1.0), 0.5, 2.0)
	# Heavy, and it crumples: harder hits bounce back less.
	flight.velocity += away * impact * tuning.crash_bounce * (1.0 - 0.5 * crash_severity(impact, tuning))
	var lever := where - global_position
	var axis := lever.cross(away)
	if axis.length() < 0.5:
		# Hit dead on the nose: a little sideways wobble so it still tumbles.
		axis = flight.nose().cross(away + Vector3(0.2, 0.1, 0.0))
	# The tumble is shown by turning the model, so put the axis in the
	# rig's own frame.
	var local_axis := (global_basis.inverse() * axis).normalized()
	_spin += local_axis * tuning.crash_spin_speed * hard
	_spin = _spin.limit_length(tuning.crash_spin_speed * 2.0)


## Out of control: the rig tumbles (only the model, so the camera stays
## level), keeps drifting with what's left of its speed, throws sparks,
## and then blows up. It ricochets off anything else it hits on the way.
func _tumble(delta: float) -> void:
	shake.update(delta, GameState.tuning.shake_decay)
	if destroyed:
		return
	_wreck_clock -= delta
	_visual_pivot.rotate(_spin.normalized(), _spin.length() * delta)
	if not flight.newtonian:
		flight.velocity *= exp(-0.5 * delta)  # (Newtonian: nothing slows a wreck down.)
	var before := flight.velocity
	velocity = flight.velocity
	move_and_slide()
	flight.velocity = velocity
	for i in get_slide_collision_count():
		var contact := get_slide_collision(i)
		var hit := -before.dot(contact.get_normal())
		if hit >= GameState.tuning.crash_instant_speed * 0.5:
			# Tumbling into something hard: that's the end of it.
			_explode(contact.get_position(), contact.get_normal(), 1.2)
			return
		if hit > 3.0:
			_knock(contact.get_position(), contact.get_normal(), hit)
			shake.add_trauma(0.4)
			before = flight.velocity
	shake.rumble = 0.55
	for spark in _sparks:
		spark.visible = randf() < 0.45
		spark.position = Vector3(randf_range(-4, 4), randf_range(-2, 2), randf_range(-6, 6))
	if _wreck_clock <= 0.0:
		_explode()


## Blows the rig up: where it is (in open space), or at `at` against a
## surface facing `away` (the wreckage sprays back off it and skids along
## it, and it's scorched). `power` scales the boom.
func _explode(at: Vector3 = Vector3.INF, away: Vector3 = Vector3.ZERO, power: float = 1.0) -> void:
	destroyed = true
	_visual_pivot.visible = false
	for spark in _sparks:
		spark.visible = false
	# Silence the rig (the engine, the alarm, the rattle): it's gone.
	for player: AudioStreamPlayer in find_children("*", "AudioStreamPlayer", true, false):
		if player != _boom_sound:
			player.stop()
	_boom_sound.play()
	var boom := Explosion.new()
	boom.power = power
	boom.carry = flight.velocity
	boom.surface_normal = away
	get_parent().add_child(boom)
	boom.global_position = (at + away * 1.5) if at.is_finite() else global_position
	flight.velocity = Vector3.ZERO
	velocity = Vector3.ZERO
	shake.rumble = 0.0
	shake.add_trauma(1.0)
	exploded.emit()


## How big a bonk hitting something at `impact` m/s is: 0 (gentlest) to 1.
static func bonk_strength(impact: float, tuning: Tuning) -> float:
	return clampf((impact - tuning.bonk_min_speed) / maxf(tuning.bonk_hard_speed - tuning.bonk_min_speed, 0.01), 0.0, 1.0)


## A small knock from the road (debris pinging off the hull, a bumpy
## patch): a little wear on the hull and cargo, a thump and a jolt, and a
## word under the RIDE bar saying why ("pings", "bumpy"). Never a bonk.
func knock(hull_loss: float, cargo_loss: float, reason: String) -> void:
	hull_loss *= ship_data.hull_care
	cargo_loss *= ship_data.cargo_care
	hull = maxf(hull - hull_loss, 0.0)
	if not GameState.active_job_id.is_empty():
		cargo_condition = maxf(cargo_condition - cargo_loss, 0.0)
	_thump_sound.pitch_scale = randf_range(1.1, 1.6)
	_thump_sound.play()
	shake.add_trauma(0.12)
	if Settings.rumble:
		Input.start_joy_vibration(0, 0.25, 0.05, 0.08)
	if cargo_loss > 0.0 and not GameState.active_job_id.is_empty():
		last_jostle_reason = reason
		jostles += 1
		cargo_jostled.emit(reason)


## Patches up the hull a bit (1 = all of it).
func repair(amount: float) -> void:
	hull = minf(hull + amount, 1.0)


## Rough driving damages the cargo a little at a time: sideways g-forces
## (turns and slides), hard braking, and the vibration of boosting flat out.
## Bonks are counted separately (see bonk()).
func _shake_cargo(delta: float) -> void:
	if delta <= 0.0:
		return
	var tuning := GameState.tuning
	var acceleration := (flight.velocity - _last_velocity) / delta
	_last_velocity = flight.velocity
	if _bonk_cooldown > 0.0:
		return
	var g := rough_g_force(acceleration, flight.nose())
	var rough := maxf(g - tuning.cargo_comfy_accel, 0.0) / tuning.cargo_comfy_accel
	# (Past boost's top speed, the vibration keeps getting worse: overdrive.)
	var vibration := overspeed_ratio() * (1.0 + flight.overdrive * tuning.overdrive_cargo)
	if flight.newtonian and not flight.boosting:
		vibration = 0.0  # Newtonian: no air, no road. Only the engines shake the cargo.
	var rough_loss := rough * tuning.cargo_rough_rate * delta * ship_data.cargo_care
	var shake_loss := vibration * tuning.cargo_boost_rate * delta * ship_data.cargo_care
	cargo_condition = maxf(cargo_condition - rough_loss - shake_loss, 0.0)
	var stress_now := clampf(g / (tuning.cargo_comfy_accel * 2.0) + vibration * 0.4, 0.0, 1.0)
	cargo_stress = lerpf(cargo_stress, stress_now, 1.0 - exp(-4.0 * delta))
	_feel_the_cargo(acceleration, rough_loss, shake_loss)


## Makes cargo damage something you can feel: the cab rattles on a rough
## ride, and every little bit of damage is a thump in the hold, a jolt, and
## a flash on the HUD saying why (a hard turn, hard braking, the boost).
func _feel_the_cargo(acceleration: Vector3, rough_loss: float, shake_loss: float) -> void:
	var rattle := smoothstep(0.4, 0.9, cargo_stress)
	_rattle_sound.volume_db = linear_to_db(maxf(rattle * 0.7, 0.0001))
	if rattle > 0.01 and not _rattle_sound.playing:
		_rattle_sound.play()
	elif rattle <= 0.01 and _rattle_sound.playing:
		_rattle_sound.stop()
	_jostle += rough_loss + shake_loss
	if _jostle < DAMAGE_PER_THUMP or GameState.active_job_id.is_empty():
		_jostle = minf(_jostle, DAMAGE_PER_THUMP)
		return
	_jostle = 0.0
	if rough_loss >= shake_loss:
		var braking := minf(acceleration.dot(flight.nose()), 0.0)
		var sideways := (acceleration - flight.nose() * acceleration.dot(flight.nose())).length()
		last_jostle_reason = "brake" if -braking > sideways else "turn"
	else:
		last_jostle_reason = "boost"
	_thump_sound.pitch_scale = randf_range(0.8, 1.2)
	_thump_sound.play()
	shake.add_trauma(0.18)
	if Settings.rumble:
		Input.start_joy_vibration(0, 0.4, 0.1, 0.12)
	jostles += 1
	cargo_jostled.emit(last_jostle_reason)


## The part of an acceleration that shakes cargo: everything except
## speeding up straight ahead (sideways, up-down and braking all count).
static func rough_g_force(acceleration: Vector3, nose: Vector3) -> float:
	var along := acceleration.dot(nose)
	var sideways := acceleration - nose * along
	return sqrt(sideways.length_squared() + pow(minf(along, 0.0), 2.0))


## Looks at everything we touched this step and bonks on the hardest hit.
func _check_for_bonks(before: Vector3, delta: float) -> void:
	_bonk_cooldown = maxf(_bonk_cooldown - delta, 0.0)
	var hardest := 0.0
	var where := Vector3.ZERO
	var away := Vector3.ZERO
	for i in get_slide_collision_count():
		var contact := get_slide_collision(i)
		var normal := contact.get_normal()  # Points away from what we hit.
		# How fast we were going straight into it, plus how fast it was
		# coming at us (traffic moves too).
		var impact := -before.dot(normal) + contact.get_collider_velocity().dot(normal)
		if impact > hardest:
			hardest = impact
			where = contact.get_position()
			away = normal
	if hardest >= GameState.tuning.bonk_min_speed and _bonk_cooldown <= 0.0:
		bonk(hardest, where, away)


func _update_shake(delta: float) -> void:
	var tuning := GameState.tuning
	if flight.boosting and not _was_boosting:
		shake.add_trauma(tuning.boost_kick_shake)  # The boost kicks in: thump!
	_was_boosting = flight.boosting
	_boost_jolts(delta)
	# A rumble while boosting; a faint road-feel vibration that grows with
	# speed otherwise.
	var cruise_feel := tuning.cruise_rumble_shake * pow(clampf(speed_ratio(), 0.0, 1.0), 2.0)
	if flight.newtonian:
		cruise_feel = tuning.cruise_rumble_shake * absf(flight.thrust) * flight.fuel_burn  # The engines, not the speed.
	shake.rumble = tuning.boost_rumble_shake + tuning.boost_shimmy_shake * flight.shimmy if flight.boosting else cruise_feel
	if flight.boosting or not flight.newtonian:
		shake.rumble += minf(flight.overdrive * 0.06 + overdrive_strain * 0.2, 0.45)  # Overdrive: everything rattles.
	shake.update(delta, tuning.shake_decay)
	# The boost spooling up: a rising whine while the button's held.
	if flight.spool > 0.0 and not _spool_sound.playing:
		_spool_sound.play()
	elif flight.spool <= 0.0 and _spool_sound.playing and not flight.boosting:
		_spool_sound.stop()


## Boost is barely under control: every so often the engines cough and
## kick the rig sideways, with a jolt of the camera. The push is spread
## over a moment so it's wild without bruising the cargo by itself.
func _boost_jolts(delta: float) -> void:
	var tuning := GameState.tuning
	if not flight.boosting or tuning.boost_jolt_push <= 0.0:
		_jolt_left = 0.0
		_jolt_clock = randf_range(tuning.boost_jolt_interval.x, tuning.boost_jolt_interval.y)
		return
	_jolt_clock -= delta
	if _jolt_clock <= 0.0:
		_jolt_clock = randf_range(tuning.boost_jolt_interval.x, maxf(tuning.boost_jolt_interval.y, tuning.boost_jolt_interval.x))
		var basis_now := flight.orientation()
		_jolt_push = (basis_now.x * randf_range(-1.0, 1.0) + basis_now.y * randf_range(-0.5, 0.5)).normalized() * tuning.boost_jolt_push
		_jolt_left = JOLT_SECONDS
		shake.add_trauma(tuning.boost_jolt_shake)
		if Settings.rumble:
			Input.start_joy_vibration(0, 0.5, 0.3, 0.15)
	if _jolt_left > 0.0:
		var step := minf(delta, _jolt_left)
		flight.velocity += _jolt_push * (step / JOLT_SECONDS)
		_jolt_left -= step


## Hands the controls to the docking autopilot, which flies through
## `route` and emits autopilot_arrived at the end. With `stop_at_end` off it
## keeps rolling at the end instead of parking (leaving a drive-through).
func fly_route(route: Array[Vector3], speed: float, stop_at_end: bool = true) -> void:
	autopilot_route = route.duplicate()
	autopilot_speed = speed
	_autopilot_stops = stop_at_end
	controls.clear()


## The canned docking run: steer smoothly at the next spot, ease off at the
## end, never bonk (it flies straight through, ignoring collisions).
func _fly_autopilot(delta: float) -> void:
	cargo_stress = 0.0
	if _rattle_sound.playing:
		_rattle_sound.stop()
	var target := autopilot_route[0]
	var to_target := target - global_position
	var distance := to_target.length()
	var last_spot := autopilot_route.size() == 1
	if distance < (6.0 if last_spot and _autopilot_stops else 25.0):
		autopilot_route.pop_front()
		if autopilot_route.is_empty():
			if _autopilot_stops:
				flight.velocity = Vector3.ZERO
			# Hand back the lever matching how fast we're rolling.
			controls.lever = clampf(flight.speed() / ship_data.max_speed, 0.0, 1.0)
			autopilot_arrived.emit()
		return
	var direction := to_target / distance
	var goal_speed := autopilot_speed
	if last_spot and _autopilot_stops:
		goal_speed = minf(autopilot_speed, distance * 0.5 + 5.0)
	flight.velocity = flight.velocity.lerp(direction * goal_speed, 1.0 - exp(-1.8 * delta))
	flight.thrust = 0.3
	flight.boosting = false
	# Point the nose along the way we're going.
	var travel := flight.velocity.normalized() if flight.velocity.length() > 0.5 else direction
	flight.glide_toward(travel, delta)
	flight.bank = lerpf(flight.bank, 0.0, 1.0 - exp(-3.0 * delta))
	flight.nose_tilt = lerpf(flight.nose_tilt, 0.0, 1.0 - exp(-3.0 * delta))
	global_basis = flight.orientation()
	global_position += flight.velocity * delta
	velocity = flight.velocity
	odometer += flight.speed() * delta
	_update_shake(delta)
	_last_velocity = flight.velocity
	_visual_pivot.rotation = Vector3(flight.nose_tilt, 0.0, flight.bank)


## Shows the ship from outside (chase view) or the inside of the cab
## (cockpit view, where we're sitting inside it).
func set_cockpit_view(in_cockpit: bool) -> void:
	_visual_pivot.visible = not in_cockpit
	cockpit.visible = in_cockpit


## Puts the ship somewhere new, parked, with no smoothing in between.
func teleport(where: Transform3D) -> void:
	overdrive_strain = 0.0
	global_transform = where
	var facing := where.basis.get_euler()
	flight.reset(facing.y, facing.x, facing.z)
	controls.clear()
	autopilot_route.clear()
	velocity = Vector3.ZERO
	_last_velocity = Vector3.ZERO
	cargo_stress = 0.0
	_rattle_sound.stop()
	_visual_pivot.rotation = Vector3.ZERO
	# Tell Godot's motion smoothing not to slide us from the old spot.
	reset_physics_interpolation()
	teleported.emit()
