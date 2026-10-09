class_name CrewMember
extends Resource
## Somebody who lives and works aboard the rig. Their name, voice and comm
## portrait come from their NPCData (`npc`); their look is `visual`. What
## they get up to (`activities`) and what they chat about (`small_talk`) is
## picked fresh every trip and every day by scenes/hub/ShipLife.gd.


## A short code name, used in saves and by ship events.
@export var id: String = "crew"
@export var npc: NPCData
@export var visual: PackedScene
## Their job aboard, for the docs and the PC.
@export var role: String = "Crew"
@export var activities: Array[CrewActivity] = []
@export var small_talk: Array[CrewLine] = []
## The first thing they say to you each day (one is picked).
@export var greetings: PackedStringArray = PackedStringArray()
## A menu they open when you talk to them during `post_activity` (Raccoony at
## her counter opens the job board).
@export var menu: String = ""
@export var post_activity: String = ""
