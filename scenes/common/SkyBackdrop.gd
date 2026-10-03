class_name SkyBackdrop
extends Node3D
## Holds the huge faraway things in the sky (oversized planets, their rings).
## Like the starfield, it sticks to the camera's position (but not its
## turning), so they act as if they were infinitely far away: you can fly for
## hours and the planet stays put on the horizon.
##
## Put planets in here as children, a few thousand meters out (but within the
## cameras' 12 km view distance), using res://shaders/psx_sky.gdshader so the
## distance haze doesn't wash them out.


func _ready() -> void:
	# We move every frame ourselves; Godot's motion smoothing would lag.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		global_position = camera.global_position
