class_name Billboard
extends RoadsideThing
## A giant billboard floating by the lane, advertising something surreal.
## The ad copy comes from the event's data (res://data/events/), or is set
## here for billboards placed along a road (like the Glimmer System's).


## The ad, as a headline and a smaller line underneath.
@export var headline: String = "MOON MILK"
@export var tagline: String = "NOW WITH 30% LESS GRAVITY"
var colors: Array[Color] = [Color(1.0, 0.45, 0.8), Color(0.45, 0.95, 1.0), Color(1.0, 0.8, 0.3), Color(0.5, 1.0, 0.55)]


## The billboard itself: the developer's model (a frame with a blank screen
## on the front), scaled up from its 1 m size. The ad is drawn on the screen.
const MODEL := preload("res://art/models/space_billboard.glb")
const MODEL_SCALE := 420.0
## Where the model's screen is (its center, and its size), as a share of
## the model's size. Move these if the ad doesn't sit on the screen.
const SCREEN_CENTER := Vector3(0.0, 0.02, 0.27)
const SCREEN_SIZE := Vector2(0.84, 0.5)


func _ready() -> void:
	if ship == null:
		rng.seed = hash(headline)  # Billboards along a road: each its own color.
	var accent: Color = colors[rng.randi_range(0, colors.size() - 1)]
	var model := MODEL.instantiate() as Node3D
	model.scale = Vector3.ONE * MODEL_SCALE
	add_child(model)
	# The ad, printed on the model's white screen: a big headline in the
	# billboard's color and a dark tagline, lit by lamps along the top.
	var screen := SCREEN_CENTER * MODEL_SCALE
	var width := SCREEN_SIZE.x * MODEL_SCALE
	var height := SCREEN_SIZE.y * MODEL_SCALE
	var headline_sign := EventKit.sign(self, headline, 0.42, accent.darkened(0.35), screen + Vector3(0.0, height * 0.1, 2.0))
	headline_sign.outline_modulate = Color(0.08, 0.06, 0.16)
	var tagline_sign := EventKit.sign(self, tagline, 0.2, Color(0.1, 0.08, 0.2), screen + Vector3(0.0, -height * 0.22, 2.0))
	tagline_sign.outline_size = 0
	for words in [headline_sign, tagline_sign]:
		_fit(words, width * 0.9)
	for x: float in [-0.35, 0.0, 0.35]:
		EventKit.glow(self, 40.0, screen + Vector3(x * width, height * 0.5 + 20.0, 10.0), Color(1.0, 0.95, 0.75))
	EventKit.solid(self, Vector3(1.0, 0.68, 0.52) * MODEL_SCALE)
	# Random ones face the oncoming traffic (you); ones placed along a road
	# keep the way they were placed.
	if ship != null:
		look_at(global_position + travel, Vector3.UP)


## Shrinks `words` until they're no wider than `width` (long ads still fit
## the screen).
func _fit(words: Label3D, width: float) -> void:
	var wide := words.get_aabb().size.x
	if wide > width:
		words.pixel_size *= width / wide
