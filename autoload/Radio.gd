extends Node
## The radio. GTA-style: several stations, each with its own music, ads and
## made-up products, that keep "broadcasting" while you're tuned away, so
## flipping back lands you mid-song, like real radio.
##
## WHERE THE MUSIC COMES FROM (see res://audio/radio/README.md):
## - Each station (res://data/radio/*.tres) has a music folder. Any .ogg,
##   .mp3 or .wav in it plays, named "Artist - Title". Ads go in its ads folder.
## - Until a folder has songs, the station plays a short placeholder beat.
## - MY TUNES plays the PLAYER's own files from user://radio/custom/ (the
##   game makes that folder and puts instructions in it).
##
## WHERE IT PLAYS:
## - In flight: the cockpit radio. Q / E flips stations (with a burst of
##   static), R switches it on and off. When it's off, soft ambient music
##   plays instead, swelling a little when you fly fast.
## - In the truck stop: the jukebox, muffled through the room's speakers.
## - Elsewhere on the base it's quiet (the stations keep going, though).
## A weak signal (ion storms, a pirate station, a regional station far from
## home) adds hiss and makes the music drop out. Some stations only come in
## near their part of space (Tide 77 near Tidewater), or only at night
## (Afterglow Block), and one has no name at all...
##
## THE DJs: every couple of minutes the DJ says something or an ad scrolls
## across the ticker (tuning.tres, "Radio"). DJs also react to what you do:
## ion storms, speeding tickets, crossing into a new system, and (next time
## you're on the road) your last delivery. See the station files.
##
## There is deliberately no streaming-service integration (see CLAUDE.md).


## Emitted when the player tunes to another station.
signal station_changed
## Emitted when the radio is switched on or off.
signal power_changed

## Where the radio is playing (see the notes at the top).
enum Context { OFF_AIR, FLIGHT, ROOM }

## The player's own music folder (for the MY TUNES station).
const PLAYER_FOLDER: String = "user://radio/custom"
const MUSIC_EXTENSIONS: Array[String] = ["ogg", "mp3", "wav"]
const TUNE_STATIC := preload("res://audio/generated/static.wav")
const HISS := preload("res://audio/generated/static_loop.wav")
const AMBIENT := preload("res://audio/generated/ambient_pad.wav")
## The audio buses (mixer channels) the radio plays through. Made in code.
const RADIO_BUS: String = "Radio"
const AMBIENT_BUS: String = "Ambient"
## How the radio sounds through a room's speakers: quieter and muffled.
const ROOM_VOLUME_DB: float = -8.0
const ROOM_MUFFLE_HZ: float = 1100.0
const WEAK_SIGNAL_MUFFLE_HZ: float = 2400.0
## Seconds a text ad or DJ line stays on the ticker.
const TEXT_AD_SECONDS: float = 14.0
## What DJs say when their station has no line of its own for something.
const GENERAL_REACTIONS := {
	"storm": "Heads up, haulers: ion storm on the lanes. Ride it out.",
	"delivery": "Shout-out to {bunny}, just made a delivery at {place}.",
	"ticket": "Somebody just met the space patrol. Ease off out there.",
	"new_system": "Welcome to {system}, haulers.",
}
## Songs with an unknown length are treated as this long.
const UNKNOWN_LENGTH: float = 180.0

## The stations on the dial (see res://data/radio/lineup.tres).
var lineup: RadioLineup = preload("res://data/radio/lineup.tres")
## Which station is tuned in.
var station_index: int = 0
## Whether the radio is switched on.
var powered: bool = true
## How clear the signal is, 1 = crystal, 0 = nothing but static. The flight
## scene lowers it in solar storms (M5).
var signal_strength: float = 1.0
## 0 = drifting slowly, 1 = flying flat out. The ambient music (radio off)
## swells a little with it.
var intensity: float = 0.0
## Where the listener is in the flight world (the flight scene keeps this
## up to date), for regional stations.
var listener_position := Vector3.ZERO
## Turn the radio down for something else (0 = normal, 1 = silent), like the
## docking computer's waltz. It fades there smoothly.
var duck: float = 0.0
var _duck_level: float = 0.0

var _context: Context = Context.OFF_AIR
var _clock: float = 0.0
# One entry per station: its playlist and where it is in it.
var _stations: Array[Dictionary] = []
var _music: AudioStreamPlayer
var _hiss: AudioStreamPlayer
var _tune: AudioStreamPlayer
var _ambient: AudioStreamPlayer
var _text_ad: String = ""
var _text_ad_left: float = 0.0
var _talk_left: float = 60.0
# A DJ reaction waiting for the next time you're on the road: [event, fill-ins].
var _queued_reaction: Array = []
var _reaction_delay: float = 0.0
var _dropout: float = 0.0
## Seconds left of total silence (a route event: "dead air").
var _dead_air: float = 0.0
## Seconds left of extra crackle (a route event: a jingle satellite, a
## sunspot, a skip signal).
var _interference: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_make_bus(RADIO_BUS, true)
	_make_bus(AMBIENT_BUS, false)
	_music = _player(null, RADIO_BUS)
	_music.finished.connect(_on_song_finished)
	_hiss = _player(HISS, RADIO_BUS)
	_tune = _player(TUNE_STATIC, "Master")
	_tune.volume_db = -12.0
	_ambient = _player(AMBIENT, AMBIENT_BUS)
	for radio_station in lineup.stations:
		_stations.append({"items": [], "loaded": false, "index": 0, "position": 0.0,
				"left_at": 0.0, "songs_since_ad": 0, "round": 0, "ad_round": 0})
	make_player_folder()


func _process(delta: float) -> void:
	_clock += delta
	_text_ad_left = maxf(_text_ad_left - delta, 0.0)
	_dead_air = maxf(_dead_air - delta, 0.0)
	_interference = maxf(_interference - delta, 0.0)
	_update_levels(delta)
	_update_talk(delta)


# --- Using the radio -------------------------------------------------------------

func station() -> RadioStation:
	return lineup.stations[station_index]


## Where the radio is playing: the cockpit, a room's speakers, or nowhere.
func set_context(context: Context) -> void:
	if context == _context:
		return
	_leave_station()
	_context = context
	_start_station()
	if context == Context.FLIGHT and not _queued_reaction.is_empty():
		_reaction_delay = 6.0  # A few seconds after takeoff.


func next_station() -> void:
	tune_to(station_index + 1)


func previous_station() -> void:
	tune_to(station_index - 1)


## Tunes to a station by its place on the dial.
func tune_to(index: int) -> void:
	_leave_station()
	station_index = posmod(index, lineup.stations.size())
	_text_ad_left = 0.0
	if _context != Context.OFF_AIR:
		_tune.pitch_scale = _rng.randf_range(0.9, 1.15)
		_tune.play()
	_start_station()
	station_changed.emit()


func toggle_power() -> void:
	_leave_station()
	powered = not powered
	if _context != Context.OFF_AIR:
		_tune.play()
	_start_station()
	power_changed.emit()


## What's on air right now: "ARTIST - TITLE", "AD: ..." during an ad, or
## "DJ NAME: ..." while the DJ talks.
func now_playing() -> String:
	if not powered:
		return "RADIO OFF"
	if reception() < 0.05:
		if station().night_only and not TimeOfDay.is_night():
			return "OFF THE AIR TILL THE NIGHT SHIFT"
		return "~ STATIC ~"
	if _text_ad_left > 0.0:
		return _text_ad
	var state := _stations[station_index]
	var items: Array = state["items"]
	if items.is_empty():
		return station().placeholder_title(0)
	var item: Dictionary = items[state["index"] % items.size()]
	if item["placeholder"]:
		return station().placeholder_title(state["round"])
	return ("AD: " if item["ad"] else "") + str(item["title"])


## How well the station you're tuned to comes in: 1 = clear, 0 = static.
func reception() -> float:
	var at_night := TimeOfDay.is_night()
	if _context == Context.ROOM:
		# A jukebox or the cabin speakers: no distance to worry about.
		return 0.0 if station().night_only and not at_night else 1.0
	return station().reception(listener_position, at_night)


## The DJ reacts to something that happened ("storm", "delivery", "ticket",
## "new_system"). `fill` fills in words like {place} and {system}.
## With `later` on, it waits for the next time you're on the road.
func dj_react(event: String, fill: Dictionary = {}, later: bool = false) -> void:
	if later or _context == Context.OFF_AIR:
		_queued_reaction = [event, fill]
		return
	if not powered or reception() < 0.3:
		return
	var radio_station := station()
	var options := radio_station.reaction_lines(event)
	var words: String = options[_rng.randi_range(0, options.size() - 1)] if not options.is_empty() else GENERAL_REACTIONS.get(event, "")
	if words.is_empty():
		return
	for key: String in fill:
		words = words.replace("{%s}" % key, str(fill[key]))
	_show_words(radio_station, GameState.names.fill_in(words), false)


## The DJ on the station you're tuned to says `words` (a route event). With
## `from` set, someone else is talking ("JINGLE SAT"). Skipped if the radio's
## off or out of range.
func announce(words: String, from: String = "") -> void:
	if not powered or _context == Context.OFF_AIR or reception() < 0.3 or _dead_air > 0.0:
		return
	if from.is_empty():
		_show_words(station(), GameState.names.fill_in(words), false)
		return
	_text_ad = from.to_upper() + ": " + GameState.names.fill_in(words).to_upper()
	_text_ad_left = TEXT_AD_SECONDS
	_talk_left = maxf(_talk_left, GameState.tuning.radio_talk_min_seconds * 0.5)


## Total silence for `seconds`: no music, no hiss, nothing.
func dead_air(seconds: float) -> void:
	_dead_air = maxf(_dead_air, seconds)


## Extra static and dropouts for `seconds`.
func interference(seconds: float) -> void:
	_interference = maxf(_interference, seconds)


## Whether the radio is in a stretch of dead air.
func is_dead_air() -> bool:
	return _dead_air > 0.0


## Stops every radio sound (when quitting).
func stop_everything() -> void:
	for player in [_music, _hiss, _tune, _ambient]:
		player.stop()


## Makes the player's music folder, with instructions inside, if it's not
## there yet. Returns its full path on this computer.
func make_player_folder() -> String:
	DirAccess.make_dir_recursive_absolute(PLAYER_FOLDER)
	var readme := PLAYER_FOLDER.path_join("README.txt")
	if not FileAccess.file_exists(readme):
		var file := FileAccess.open(readme, FileAccess.WRITE)
		if file != null:
			file.store_string("MY TUNES - your own radio station in Space Truckin' 5050\n\n"
					+ "Drop music files in this folder (.ogg, .mp3 or .wav) and tune the\n"
					+ "cockpit radio to MY TUNES (00.0). Name files \"Artist - Title.mp3\"\n"
					+ "and the HUD shows the artist and title. New files are picked up\n"
					+ "the next time you tune in.\n")
	return ProjectSettings.globalize_path(PLAYER_FOLDER)


## The songs and ads for one station, as playlist items:
## {stream, title, ad, placeholder}. Public so tests can check it.
func build_playlist(radio_station: RadioStation) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	var folder := PLAYER_FOLDER if radio_station.reads_player_folder else radio_station.music_folder
	var songs := _load_folder(folder, false)
	if songs.is_empty():
		if radio_station.placeholder_loop != null:
			items.append({"stream": radio_station.placeholder_loop, "title": "", "ad": false, "placeholder": true})
		return items
	if radio_station.shuffle:
		_shuffle(songs)
	var ads := _load_folder(radio_station.ads_folder, true)
	var ad_index := 0
	for i in songs.size():
		items.append(songs[i])
		if not ads.is_empty() and (i + 1) % radio_station.tracks_per_ad == 0:
			items.append(ads[ad_index % ads.size()])
			ad_index += 1
	return items


## "Some Artist - Some Song.ogg" -> "SOME ARTIST - SOME SONG".
static func title_from_file(file_name: String) -> String:
	return file_name.get_basename().replace("_", " ").strip_edges().to_upper()


# --- Behind the scenes ----------------------------------------------------------

func _start_station() -> void:
	_music.stop()
	_hiss.stop()
	_ambient.stop()
	if _context == Context.OFF_AIR:
		return
	if not powered:
		if _context == Context.FLIGHT:
			_ambient.play()
		return
	var state := _stations[station_index]
	if not state["loaded"] or station().reads_player_folder:
		state["items"] = build_playlist(station())
		state["loaded"] = true
		state["index"] = 0
		state["position"] = 0.0
	# Catch up on what this station played while we were away.
	_catch_up(state, _clock - float(state["left_at"]))
	_hiss.play()
	var items: Array = state["items"]
	if items.is_empty():
		return
	var item: Dictionary = items[state["index"]]
	_music.stream = item["stream"]
	_music.play(state["position"])


## Remembers where the current station was, so it can carry on "broadcasting".
func _leave_station() -> void:
	var state := _stations[station_index]
	if _music.playing:
		state["position"] = _music.get_playback_position()
	state["left_at"] = _clock


## Moves a station's playlist on by `seconds`, as if it had kept playing.
func _catch_up(state: Dictionary, seconds: float) -> void:
	var items: Array = state["items"]
	if items.is_empty() or seconds <= 0.0:
		return
	for i in 1000:  # (A cap, so a huge gap can't loop forever.)
		var item: Dictionary = items[state["index"]]
		var left := _length(item) - float(state["position"])
		if seconds < left:
			state["position"] = float(state["position"]) + seconds
			return
		seconds -= left
		_step(state)


## Goes on to the next item in a station's playlist.
func _step(state: Dictionary) -> void:
	var items: Array = state["items"]
	var finished: Dictionary = items[state["index"]]
	state["position"] = 0.0
	state["index"] = (int(state["index"]) + 1) % items.size()
	if state["index"] == 0:
		state["round"] = int(state["round"]) + 1
	if finished["ad"]:
		return
	state["songs_since_ad"] = int(state["songs_since_ad"]) + 1


func _on_song_finished() -> void:
	var state := _stations[station_index]
	var items: Array = state["items"]
	if items.is_empty():
		return
	_step(state)
	_music.stream = items[state["index"]]["stream"]
	_music.play()


func _length(item: Dictionary) -> float:
	var stream: AudioStream = item["stream"]
	var length := stream.get_length() if stream != null else 0.0
	return length if length > 0.1 else UNKNOWN_LENGTH


## Every few minutes, the DJ says something or an ad scrolls by. Also
## plays a DJ reaction that was waiting for you to get back on the road.
func _update_talk(delta: float) -> void:
	if _context == Context.OFF_AIR or not powered:
		return
	if not _queued_reaction.is_empty() and _context == Context.FLIGHT:
		_reaction_delay -= delta
		if _reaction_delay <= 0.0:
			var waiting := _queued_reaction
			_queued_reaction = []
			dj_react(waiting[0], waiting[1])
	_talk_left -= delta
	if _talk_left > 0.0:
		return
	var tuning := GameState.tuning
	_talk_left = _rng.randf_range(tuning.radio_talk_min_seconds, maxf(tuning.radio_talk_max_seconds, tuning.radio_talk_min_seconds))
	if _text_ad_left > 0.0 or reception() < 0.3:
		return
	var radio_station := station()
	var state := _stations[station_index]
	var has_audio_ads := (state["items"] as Array).any(func(entry: Dictionary) -> bool: return entry["ad"])
	var wants_ad := _rng.randf() < tuning.radio_ad_share
	if wants_ad and not has_audio_ads and not radio_station.ads.is_empty():
		state["ad_round"] = int(state["ad_round"]) + 1
		_show_words(radio_station, radio_station.ad_text(state["ad_round"]), true)
	elif not radio_station.dj_lines.is_empty():
		_show_words(radio_station, radio_station.dj_lines[_rng.randi_range(0, radio_station.dj_lines.size() - 1)], false)


## Puts words on the ticker: an ad, or the DJ talking.
func _show_words(radio_station: RadioStation, words: String, is_ad: bool) -> void:
	var speaker := radio_station.dj_name.to_upper() if not radio_station.dj_name.is_empty() else "???"
	_text_ad = ("AD: " if is_ad else speaker + ": ") + words.to_upper()
	_text_ad_left = TEXT_AD_SECONDS
	_talk_left = maxf(_talk_left, GameState.tuning.radio_talk_min_seconds * 0.5)


## Volume, muffling, hiss and dropouts, every frame.
func _update_levels(delta: float) -> void:
	_duck_level = move_toward(_duck_level, clampf(duck, 0.0, 1.0), delta * 0.8)
	var volume := linear_to_db(maxf(Settings.radio_volume * (1.0 - _duck_level), 0.0001))
	var room := _context == Context.ROOM
	# A weak signal: hiss rises and the music cuts out now and then.
	var clear := reception() if _context != Context.OFF_AIR else 1.0
	var weakness := clampf(1.0 - signal_strength * clear, 0.0, 1.0)
	if _interference > 0.0:
		weakness = maxf(weakness, 0.65)
	if weakness > 0.3 and _rng.randf() < weakness * delta * 2.0:
		_dropout = _rng.randf_range(0.15, 0.5)
	_dropout = maxf(_dropout - delta, 0.0)
	var music_db := volume + (ROOM_VOLUME_DB if room else 0.0) - (18.0 if _dropout > 0.0 else 0.0)
	if clear < 0.05:
		music_db = -80.0  # Out of range (or off the air): nothing but hiss.
	_music.volume_db = music_db
	_hiss.volume_db = linear_to_db(maxf(weakness * 0.5 + 0.02, 0.0001)) + volume - 6.0
	if _dead_air > 0.0:
		_music.volume_db = -80.0
		_hiss.volume_db = -80.0
	var bus := AudioServer.get_bus_index(RADIO_BUS)
	var muffle := AudioServer.get_bus_effect(bus, 0) as AudioEffectLowPassFilter
	muffle.cutoff_hz = ROOM_MUFFLE_HZ if room else WEAK_SIGNAL_MUFFLE_HZ
	AudioServer.set_bus_effect_enabled(bus, 0, room or weakness > 0.5)
	# The ambient music swells a touch when you fly fast.
	_ambient.volume_db = volume - 10.0 + intensity * 4.0
	if _dead_air > 0.0:
		_ambient.volume_db = -80.0


func _load_folder(folder: String, ads: bool) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	if folder.is_empty() or not DirAccess.dir_exists_absolute(folder):
		return found
	# In an exported game, res:// files show up as "song.ogg.import", so
	# strip that back off.
	var names := {}
	for file_name in DirAccess.get_files_at(folder):
		var clean := file_name.trim_suffix(".import").trim_suffix(".remap")
		if clean.get_extension().to_lower() in MUSIC_EXTENSIONS:
			names[clean] = true
	var sorted: Array = names.keys()
	sorted.sort()
	for file_name: String in sorted:
		var stream := _load_stream(folder.path_join(file_name))
		if stream != null:
			found.append({"stream": stream, "title": title_from_file(file_name), "ad": ads, "placeholder": false})
	return found


func _load_stream(path: String) -> AudioStream:
	if path.begins_with("res://"):
		return load(path) as AudioStream
	# Files from the player's folder are loaded straight from disk.
	match path.get_extension().to_lower():
		"ogg":
			return AudioStreamOggVorbis.load_from_file(path)
		"mp3":
			return AudioStreamMP3.load_from_file(path)
		"wav":
			return AudioStreamWAV.load_from_file(path)
	return null


func _shuffle(items: Array[Dictionary]) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var swap := items[i]
		items[i] = items[j]
		items[j] = swap


func _player(stream: AudioStream, bus: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = bus
	add_child(player)
	return player


## Adds a mixer channel (bus) if it's not there, optionally with a muffling
## low-pass filter (switched on for room speakers and weak signals).
func _make_bus(bus_name: String, with_muffle: bool) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")
	if with_muffle:
		var muffle := AudioEffectLowPassFilter.new()
		muffle.cutoff_hz = ROOM_MUFFLE_HZ
		AudioServer.add_bus_effect(index, muffle)
		AudioServer.set_bus_effect_enabled(index, 0, false)
