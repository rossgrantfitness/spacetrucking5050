class_name RadioStation
extends Resource
## One radio station: its name, sound, DJ, music and (surreal) ads.
## Each station gets its own .tres file in this folder, and
## res://data/radio/lineup.tres lists which stations are on the dial.
##
## HOW TO GIVE A STATION MUSIC: drop .ogg, .mp3 or .wav files into its
## `music_folder` (like res://audio/radio/subspace_fm/music/). Name them
## "Artist - Title.ogg" and the ticker shows that. Audio ads go in
## `ads_folder` the same way. See res://audio/radio/README.md.
##
## Until a station has music, it plays its `placeholder_loop` (a little
## made-up beat) and the ticker shows the made-up `tracks` names.
## All songs, artists and products here are invented. No real ones, ever.


## The station's name, shown on the HUD ticker.
@export var display_name: String = "STATION"
## Where it sits on the dial, shown before the name ("104.2").
@export var frequency: String = "88.0"
## Just a note: what it plays.
@export var genre: String = ""
## The DJ (DJ voice clips can go in the ads folder for now).
@export var dj_name: String = ""

@export_group("Music")
## The folder its music files live in.
@export_dir var music_folder: String = ""
## The folder its audio ads (and DJ bits) live in. Optional.
@export_dir var ads_folder: String = ""
## Shuffle the songs (on) or play them in file-name order (off).
@export var shuffle: bool = true
## Songs between ads.
@export_range(1, 20, 1) var tracks_per_ad: int = 3
## Played (and repeated) while the music folder is empty.
@export var placeholder_loop: AudioStream
## On: this station plays the player's own music files from
## user://radio/custom/ instead of a folder in the game.
@export var reads_player_folder: bool = false

@export_group("Words")
## Made-up song names, shown on the ticker while the placeholder plays.
@export var tracks: PackedStringArray = PackedStringArray()
## Fake ads for surreal products. If the station has no audio ads, these
## scroll across the ticker between songs instead.
@export var ads: PackedStringArray = PackedStringArray()


## A made-up song name for the `turn`th time through the placeholder.
func placeholder_title(turn: int) -> String:
	if tracks.is_empty():
		return "PLACEHOLDER LOOP"
	return tracks[posmod(turn, tracks.size())]


## A text ad for the `turn`th ad break.
func ad_text(turn: int) -> String:
	return ads[posmod(turn, ads.size())] if not ads.is_empty() else ""
