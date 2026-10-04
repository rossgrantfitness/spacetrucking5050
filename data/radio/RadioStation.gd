class_name RadioStation
extends Resource
## One radio station: its name, sound, DJ, songs and (surreal) ads.
## Each station gets its own .tres file in this folder, and
## res://data/radio/lineup.tres lists which stations are on the dial.
##
## There's no music yet (that's M4): for now the HUD's radio ticker scrolls
## these placeholder song titles and ads so the radio feels alive.
## All songs, artists and products are made up. No real ones, ever.


## The station's name, shown on the HUD ticker.
@export var display_name: String = "STATION"
## Where it sits on the dial, shown before the name ("104.2").
@export var frequency: String = "88.0"
## Just a note for now: what it plays.
@export var genre: String = ""
## The DJ, who'll talk between songs in M4.
@export var dj_name: String = ""
## Placeholder songs, as "ARTIST - TITLE".
@export var tracks: PackedStringArray = PackedStringArray()
## Fake ads for surreal products. One plays after every few songs.
@export var ads: PackedStringArray = PackedStringArray()
## How long each placeholder song "plays", in seconds, before the ticker
## moves on to the next one.
@export_range(10.0, 600.0, 5.0, "suffix:s") var track_seconds: float = 150.0
## Songs between ads.
@export_range(1, 20, 1) var tracks_per_ad: int = 3


## What's on air `seconds` after the station started broadcasting: a song,
## or an ad (starting with "AD:").
func on_air(seconds: float) -> String:
	var slot := floori(seconds / track_seconds)
	var block := tracks_per_ad + 1
	var blocks_done := floori(float(slot) / block)
	if not ads.is_empty() and slot % block == tracks_per_ad:
		return "AD: " + ads[blocks_done % ads.size()]
	if tracks.is_empty():
		return "DEAD AIR"
	# Count only the songs so far (skip the ad slots).
	return tracks[(slot - blocks_done) % tracks.size()]
