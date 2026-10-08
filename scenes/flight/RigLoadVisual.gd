class_name RigLoadVisual
extends Node3D
## The Thumper's look: one rig, in five states of loaded (the developer's
## models, art/models/rig_load_0..4.glb). Load0 is the bare rig with an
## empty deck; Load1 to Load4 carry more and more cargo, up to an overloaded
## heap with junk hanging off it. Only one shows at a time: Ship calls
## show_load() whenever the job in the back changes.
##
## Built by tools/build_player_rig.gd (which also places the engine
## nozzles). It replaces the slung cargo pod (CargoPod) on this rig, since
## the cargo is part of each model.

## Load shares (the job's weight against the rig's load rating: 1 = a full
## load) where the next model takes over. Below the first: Load1, a light
## load; at or above the last: Load4, piled high.
@export var thresholds := PackedFloat32Array([0.35, 0.7, 1.05])

## Which model is showing (0 = empty).
var stage: int = 0


func _ready() -> void:
	_show(stage)


## Shows the model for a load: none (`loaded` false = the empty rig) or a
## job weighing `share` of a full load.
func show_load(loaded: bool, share: float) -> void:
	var next := 0
	if loaded:
		next = 1
		for limit in thresholds:
			if share >= limit:
				next += 1
	_show(next)


func _show(which: int) -> void:
	stage = clampi(which, 0, 4)
	for i in 5:
		var model := get_node_or_null("Load%d" % i) as Node3D
		if model != null:
			model.visible = i == stage
