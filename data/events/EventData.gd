class_name EventData
extends Resource
## One thing that can happen on the road: something to look at, a call on
## the comms, a little hazard, a line on the radio. The route-events
## director (scenes/flight/RouteEvents.gd) picks from the list in
## res://data/events/route_events.tres as you drive.
##
## The first part says WHERE and HOW OFTEN (zone, rarity, weather, story).
## The rest says WHAT HAPPENS: a 3D set piece (`kind`), someone calling
## (`speaker` + `lines`, with reply choices), the radio DJ talking
## (`dj_lines`), a HUD banner, and/or a small effect on the rig or the radio.
## Any mix works; a pure "radio" event has kind NONE and just `dj_lines`.
##
## Events that aren't built yet are in the list too, switched off
## (`playable` off), with `needs` saying what's missing. That way the whole
## design list lives in one place. (How each 3D thing looks is built in
## code, in res://scenes/flight/events/.)


## What appears in 3D (NONE = nothing: a call, a radio line, an effect).
enum Kind { BIG_SHIP, CONVOY, WHALES, JELLYFISH, BILLBOARD, COMET, JUNK, DERELICT, DUCK, ION_STORM, NONE, SIGN, LONE_SHIP }
## Where on the road it belongs (see tuning.tres, "Route events", for how
## busy each zone is). ANYWHERE events (cab, cargo, radio) fill gaps
## everywhere.
enum Zone { ANYWHERE, DEEP_SPACE, TRAFFIC_LANES, STATION_APPROACH, ORBIT, WEATHER }
## What sort of event it is.
enum Type { SIGHT, ENCOUNTER, HAZARD, OPPORTUNITY, RADIO, CAB, CARGO }
enum Tone { SILLY, CUTE, WEIRD, SERIOUS, DANGEROUS }
## Common events can come back after a few hauls, uncommon after ten,
## rare ones at most one per haul, legendary once per save.
enum Rarity { COMMON, UNCOMMON, RARE, LEGENDARY }
## How much work it is to build: text/sound only, existing props, a new
## model or effect, or a small new game system.
enum Build { CHEAP, REUSE, NEW, NEW_MECHANIC }
## A small thing it does to the rig or the radio while it lasts
## (`effect_seconds`).
##   DEAD_AIR     - the radio goes completely silent
##   STATIC       - the radio crackles and drops out
##   PINGS        - little things ping off the hull (a tiny bit of wear)
##   NUDGE        - an invisible current pushes the rig sideways
##   SWAY         - the rig rises and falls gently, like a boat
##   BUMPY        - a bumpy patch: small jolts that rattle the cargo
enum Effect { NONE, DEAD_AIR, STATIC, PINGS, NUDGE, SWAY, BUMPY }

@export_group("What it is")
## A short id, used for cooldowns and the save ("waving_spacesuit").
@export var id: String = ""
## Its number in the design list (docs/ROUTE_EVENTS_LIST.md); 0 = one of
## the original sights.
@export var number: int = 0
@export var title: String = ""
## What happens, in plain words (from the design list).
@export_multiline var summary: String = ""
@export var type: Type = Type.SIGHT
@export var tone: Tone = Tone.SILLY
@export var build: Build = Build.REUSE
## Built and switched on. Off = it's in the list but doesn't happen yet.
@export var playable: bool = true
## For events that aren't built yet: what they still need.
@export var needs: String = ""

@export_group("When it happens")
@export var zone: Zone = Zone.ANYWHERE
@export var rarity: Rarity = Rarity.COMMON
## How likely it is compared to the others in the same zone (2 = twice as
## likely as 1).
@export_range(0.0, 20.0, 0.1) var weight: float = 1.0
## Hauls before it can happen again. -1 = the rarity's usual cooldown
## (tuning.tres); 0 = no cooldown (everyday traffic like billboards).
@export_range(-1, 50, 1) var cooldown_hauls: int = -1
## Only in these solar systems (system ids like "home", "tidewater").
## Empty = anywhere.
@export var systems: PackedStringArray = PackedStringArray()
## Only at night (the night shift).
@export var night_only: bool = false
## A story event: only once this story flag is set (never random early).
@export var story_flag: String = ""
## For weather: which weather it belongs to ("ion", "dust", "ice"...).
## Inside a weather zone, weather events of a different weather are
## skipped.
@export var weather: String = ""

@export_group("What appears")
@export var kind: Kind = Kind.NONE
## Which logbook entry it is (see res://data/logbook/sights.tres).
@export var log_id: String = ""
## How big it is compared to normal (6 = a whale pod six times the size).
@export_range(0.1, 20.0, 0.1) var size: float = 1.0
## How many of it appear at once, spread out (a comet storm).
@export_range(1, 20, 1) var copies: int = 1
## A ghost: see-through and flickering.
@export var ghost: bool = false
## How far ahead of you it appears, in meters.
@export_range(300.0, 15000.0, 100.0) var ahead: float = 4500.0
## How far off to the side of your lane (a random distance between these).
@export var side_offset := Vector2(400.0, 1200.0)
## How far up or down (a random distance between these).
@export var height_offset := Vector2(-250.0, 250.0)
## Words it uses: billboard ads and signs as "HEADLINE|TAGLINE" (or
## "FRONT|BACK" for a sign), derelict names.
@export var texts: PackedStringArray = PackedStringArray()
## Names on the HUD ID labels of ships (big ships, convoys, lone ships).
## Empty = the usual funny names.
@export var ship_names: PackedStringArray = PackedStringArray()
## A color for it (a big ship's hull, a storm's glow, a ship's engine
## trail). Fully transparent = its usual colors.
@export var tint: Color = Color(0.0, 0.0, 0.0, 0.0)
## For ships: how fast they go, compared to normal (0.3 = a crawl).
@export_range(0.05, 5.0, 0.05) var speed_scale: float = 1.0
## For a lone ship: it weaves all over the lane (a student driver).
@export var weaving: bool = false
## For a lone ship: it drives your way (you overtake it) instead of
## coming the other way.
@export var same_direction: bool = false

@export_group("What's said")
## Who calls on the comms about it, and what they might say (one is picked
## at random). Optional.
@export var speaker: NPCData
@export var lines: PackedStringArray = PackedStringArray()
## What Jack can say back (press T after the call). Empty = her usual
## one-liners. Always just flavor: no reply changes what happens.
@export var replies: PackedStringArray = PackedStringArray()
## Something said on the radio about it (one picked at random), on
## whatever station you're tuned to: the DJ, or `radio_from` if set.
@export var dj_lines: PackedStringArray = PackedStringArray()
## Who's talking on the radio instead of the DJ ("JINGLE SAT", "LOCAL AM
## 540": something bleeding onto your dial). Empty = the station's DJ.
@export var radio_from: String = ""
## A banner across the HUD ("FAST LANE ENDS").
@export var banner: String = ""

## A sound it makes when it starts (heard in the cab), and its pitch.
@export var sound: AudioStream
@export_range(0.1, 4.0, 0.05) var sound_pitch: float = 1.0

@export_group("What it does")
@export var effect: Effect = Effect.NONE
@export_range(0.0, 120.0, 0.5, "suffix:s") var effect_seconds: float = 0.0


## Whether it can show up in the solar system `system_id`.
func allowed_in(system_id: String) -> bool:
	return systems.is_empty() or system_id in systems


## Rare or legendary: rolled at most once per haul.
func is_rare() -> bool:
	return rarity >= Rarity.RARE


## Whether it counts as a hazard (only one hazard at a time).
func is_hazard() -> bool:
	return type == Type.HAZARD
