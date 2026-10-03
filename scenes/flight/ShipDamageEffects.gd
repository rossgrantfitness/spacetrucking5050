class_name ShipDamageEffects
extends Node3D
## Everything you see and hear when the rig takes a knock:
## - a shower of sparks and a cartoon "bonk" on every bump;
## - smoke trailing from the engines once the hull is battered, thicker the
##   worse it gets;
## - little spark spits now and then when it's really beaten up.
## Nothing ever explodes. Patch the hull and it all goes away.
##
## Put this node inside the Ship. It listens to the ship's `bonked` signal.


const BONK_SOUND := preload("res://audio/generated/bonk.wav")
const PUFF_TEXTURE := preload("res://textures/generated/puff.png")
## Where the smoke comes out, relative to the ship (the engine block).
@export var smoke_spot := Vector3(0.0, 3.0, 12.0)

# The particle and sound nodes are made in _ready (not up here), so they
# only exist once this node is really in the game.
var _ship: Ship
var _sparks: CPUParticles3D
var _smoke: CPUParticles3D
var _sound: AudioStreamPlayer
var _rng := RandomNumberGenerator.new()
var _spit_timer := 2.0


func _ready() -> void:
	_ship = get_parent() as Ship
	_ship.bonked.connect(_on_bonked)
	_build_sparks()
	_build_smoke()
	_sound = AudioStreamPlayer.new()
	_sound.stream = BONK_SOUND
	_sound.bus = &"Master"
	add_child(_sound)


func _process(delta: float) -> void:
	var tuning := GameState.tuning
	var hull := _ship.hull
	# Smoke: none above the threshold, thicker and darker as the hull drops.
	var battered := clampf((tuning.smoke_below_hull - hull) / maxf(tuning.smoke_below_hull, 0.01), 0.0, 1.0)
	_smoke.emitting = battered > 0.0
	# Light gray-lilac smoke: dark smoke would vanish against black space.
	_smoke.color = Color(0.8 - 0.2 * battered, 0.78 - 0.2 * battered, 0.86 - 0.2 * battered, 0.4 + 0.5 * battered)
	# Below a third of the hull, the engine block spits a few sparks now and then.
	if hull < 0.33:
		_spit_timer -= delta
		if _spit_timer <= 0.0:
			_spit_timer = _rng.randf_range(0.8, 2.5)
			_burst(_ship.to_global(smoke_spot), Vector3.UP, 0.25)


func _on_bonked(strength: float, where: Vector3) -> void:
	var away := (where.direction_to(_ship.global_position) if where != _ship.global_position else Vector3.UP)
	_burst(where, away, strength)
	_sound.pitch_scale = lerpf(1.25, 0.8, strength) * _rng.randf_range(0.93, 1.07)
	_sound.volume_db = lerpf(-12.0, 0.0, strength)
	_sound.play()


## Fires a shower of sparks at `where`, flying mostly toward `direction`.
func _burst(where: Vector3, direction: Vector3, strength: float) -> void:
	_sparks.global_position = where
	_sparks.direction = direction
	_sparks.initial_velocity_max = lerpf(10.0, 30.0, strength)
	_sparks.amount = int(lerpf(20.0, 64.0, strength))
	_sparks.restart()


func _build_sparks() -> void:
	_sparks = CPUParticles3D.new()
	_sparks.top_level = true  # Sparks stay where they were thrown.
	_sparks.emitting = false
	_sparks.one_shot = true
	_sparks.explosiveness = 1.0
	_sparks.lifetime = 0.9
	_sparks.spread = 65.0
	_sparks.initial_velocity_min = 4.0
	_sparks.gravity = Vector3.ZERO  # Space!
	_sparks.damping_min = 4.0
	_sparks.damping_max = 9.0
	_sparks.scale_amount_min = 0.6
	_sparks.scale_amount_max = 1.6
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color(1.0, 1.0, 0.8), Color(1.0, 0.7, 0.2), Color(1.0, 0.3, 0.1, 0.0)])
	ramp.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	_sparks.color_ramp = ramp
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * 1.2
	quad.material = _particle_material(BaseMaterial3D.BLEND_MODE_ADD, PUFF_TEXTURE)
	_sparks.mesh = quad
	add_child(_sparks)


func _build_smoke() -> void:
	_smoke = CPUParticles3D.new()
	_smoke.position = smoke_spot
	_smoke.emitting = false
	_smoke.local_coords = false  # Puffs stay behind as the ship flies on.
	_smoke.amount = 48
	_smoke.lifetime = 3.0
	_smoke.direction = Vector3(0.0, 0.6, 1.0)
	_smoke.spread = 25.0
	_smoke.initial_velocity_min = 2.0
	_smoke.initial_velocity_max = 5.0
	_smoke.gravity = Vector3.ZERO
	_smoke.scale_amount_min = 1.2
	_smoke.scale_amount_max = 2.2
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.4))
	grow.add_point(Vector2(1.0, 1.0))
	_smoke.scale_amount_curve = grow
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	_smoke.color_ramp = fade
	_smoke.angle_min = 0.0
	_smoke.angle_max = 360.0
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * 5.0
	quad.material = _particle_material(BaseMaterial3D.BLEND_MODE_MIX, PUFF_TEXTURE)
	_smoke.mesh = quad
	add_child(_smoke)


## A flat, camera-facing, unlit particle look (crisp pixels, PS1 style).
func _particle_material(blend: BaseMaterial3D.BlendMode, texture: Texture2D) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = blend
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	if texture != null:
		material.albedo_texture = texture
	return material
