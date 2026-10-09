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
## The station's slogan.
@export var tagline: String = ""

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
## scroll across the ticker every few minutes instead (how often is in
## tuning.tres under "Radio").
@export var ads: PackedStringArray = PackedStringArray()
## The DJ's banter, read out on the ticker every few minutes.
@export var dj_lines: PackedStringArray = PackedStringArray()

@export_group("DJ reactions")
## What the DJ says when things happen to you. Lines can use {bunny},
## {place} (where you delivered) and {system} (the solar system). Empty =
## a general line in the DJ's name.
@export var dj_on_storm: PackedStringArray = PackedStringArray()
@export var dj_on_delivery: PackedStringArray = PackedStringArray()
@export var dj_on_ticket: PackedStringArray = PackedStringArray()
@export var dj_on_new_system: PackedStringArray = PackedStringArray()

@export_group("Reception")
## Only on the air during the night shift. (Until the game's shifts arrive,
## that's 9 p.m. to 6 a.m. on your computer's clock.)
@export var night_only: bool = false
## A pirate station: the signal is always weak and crackly.
@export var pirate: bool = false
## A regional station: it comes in clearly near `signal_center` (a spot in
## the flight world) and fades to static `signal_radius` meters away.
## Radius 0 = it comes in everywhere.
@export var signal_center: Vector3 = Vector3.ZERO
@export var signal_radius: float = 0.0
## Hidden: it isn't announced on the dial (the ticker shows no name), for
## mysteries.
@export var hidden: bool = false
## Only on the dial once this story flag is set (empty = always there).
@export var requires_flag: String = ""


## Whether you can tune to it yet (see `requires_flag`).
func on_the_dial() -> bool:
	return requires_flag.is_empty() or GameState.has_flag(requires_flag)


## A made-up song name for the `turn`th time through the placeholder.
func placeholder_title(turn: int) -> String:
	if tracks.is_empty():
		return "PLACEHOLDER LOOP"
	return tracks[posmod(turn, tracks.size())]


## How well it comes in at `spot` (in the flight world): 1 = clear, 0 =
## nothing but static. `at_night` says whether it's the night shift.
func reception(spot: Vector3, at_night: bool) -> float:
	if night_only and not at_night:
		return 0.0
	var strength := 0.45 if pirate else 1.0
	if signal_radius > 0.0:
		var distance := spot.distance_to(signal_center)
		strength *= clampf((signal_radius - distance) / (signal_radius * 0.4), 0.0, 1.0)
	return strength


## What the DJ says when `event` happens ("storm", "delivery", "ticket",
## "new_system"); empty if they have nothing for it.
func reaction_lines(event: String) -> PackedStringArray:
	match event:
		"storm":
			return dj_on_storm
		"delivery":
			return dj_on_delivery
		"ticket":
			return dj_on_ticket
		"new_system":
			return dj_on_new_system
	return PackedStringArray()


## A text ad for the `turn`th ad break.
func ad_text(turn: int) -> String:
	return ads[posmod(turn, ads.size())] if not ads.is_empty() else ""
