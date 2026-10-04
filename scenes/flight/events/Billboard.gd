class_name Billboard
extends RoadsideThing
## A giant billboard floating by the lane, advertising something surreal.
## The ad copy comes from the event's data (res://data/events/).


## The ad, as a headline and a smaller line underneath.
var headline: String = "MOON MILK"
var tagline: String = "NOW WITH 30% LESS GRAVITY"
var colors: Array[Color] = [Color(1.0, 0.45, 0.8), Color(0.45, 0.95, 1.0), Color(1.0, 0.8, 0.3), Color(0.5, 1.0, 0.55)]


func _ready() -> void:
	var accent: Color = colors[rng.randi_range(0, colors.size() - 1)]
	var frame := EventKit.paint(Color(0.2, 0.2, 0.26), 0.0, EventKit.HULL, 20.0)
	EventKit.box(self, Vector3(360.0, 160.0, 8.0), Vector3.ZERO, EventKit.paint(Color(0.08, 0.06, 0.16)))
	EventKit.box(self, Vector3(370.0, 8.0, 10.0), Vector3(0.0, 84.0, 0.0), EventKit.paint(accent, 1.5))
	EventKit.box(self, Vector3(370.0, 8.0, 10.0), Vector3(0.0, -84.0, 0.0), EventKit.paint(accent, 1.5))
	EventKit.box(self, Vector3(14.0, 200.0, 14.0), Vector3(0.0, -180.0, 0.0), frame)
	EventKit.sign(self, headline, 0.7, accent, Vector3(0.0, 22.0, 5.0))
	EventKit.sign(self, tagline, 0.3, Color(0.95, 0.95, 1.0), Vector3(0.0, -36.0, 5.0))
	for x: float in [-150.0, 0.0, 150.0]:
		EventKit.glow(self, 50.0, Vector3(x, 95.0, 10.0), Color(1.0, 0.95, 0.75))
	EventKit.solid(self, Vector3(360.0, 160.0, 10.0))
	# Face the oncoming traffic (you).
	look_at(global_position + travel, Vector3.UP)
