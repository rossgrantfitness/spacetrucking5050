extends Node
## The live state of the game while it runs. From M2 on, everything that ends
## up in a save file lives here too.
##
## M0: holds the shared tuning file, so every script reads the same numbers.
## M2: money, cargo condition, fuel, ship upgrades, the active job.
## M6: day, shift, rent, ship XP and levels.
##
## Any script can reach it as `GameState` because it's an autoload (Godot
## creates it once at startup and keeps it alive the whole time).


## The one shared copy of every feel number. To change values, open
## res://data/tuning.tres and use the Inspector.
var tuning: Tuning = preload("res://data/tuning.tres")
