# The radio: how to add music

The cockpit radio plays real music files. Each station has its own folder
here, and anything you drop in it plays on that station, shuffled, with ads
between songs. Stations keep "broadcasting" while you're tuned away, like
real radio, so flipping back lands you mid-song.

## Add songs to a station

1. Find the station's folder (`audio/radio/<folder>/music/`):

   | Dial | Station | Plays | DJ | Folder |
   |---|---|---|---|---|
   | 101.1 | SUBSPACE FM | Drum & bass, jungle | DJ Static (bat) | `subspace_fm` |
   | 96.6 | WOBBLE BELT | Dubstep, bass music | DJ Big Low (hippo) | `wobble_belt` |
   | 88.8 | NEON DRIFT | Synthwave, outrun | DJ Vapor (flamingo) | `neon_drift` |
   | 83.0 | HOSHIZORA 83 | J-pop, city pop, anime rock (the developer's own tracks) | Tanu-chan (tanuki) | `hoshizora_83` |
   | 92.3 | AFTERGLOW BLOCK | Downtempo, IDM (night shift only) | K-9000 (robot dog) | `afterglow_block` |
   | 106.5 | HYPERJUMP 180 | Happy hardcore, gabber | DJ Sparkz (hamster) | `hyperjump_180` |
   | 77.1 | TIDE 77 | Dub, trip-hop (clear only near Tidewater) | DJ Kelp (sea lion) | `tide_77` |
   | 66.6 | KRSH 666 THE CRUSHER | Thrash, classic heavy metal | DJ Grimsby (goat) | `krsh_666` |
   | 60.1 | BLACK HOLE RADIO | Doom, stoner metal | DJ Fuzz (tortoise) | `black_hole_radio` |
   | 93.9 | EVENT HORIZON | Death metal, black metal | DJ Corvina (raven) | `event_horizon` |
   | 101.7 | HULL BREACH 101 | Metalcore, nu metal | Brick & Mortar (rhinos) | `hull_breach_101` |
   | 99.9 | ASTEROID ROCK | Classic hard rock, long-haul classics | Big Rusty (walrus) | `asteroid_rock` |
   | 87.3 | FUEL INJECTION | Garage rock, punk (pirate: always crackly) | DJ Spit (raccoon) | `fuel_injection` |
   | 94.1 | STATIC CLING | Grunge, alt rock | DJ Mope (basset hound) | `static_cling` |
   | 102.5 | GLAM ROCKET | Glam rock, arena rock, power ballads | Roxxy Stardust (peacock) | `glam_rocket` |
   | 80.8 | ORBIT 808 | Boom bap, golden-age hip hop | DJ Mole-ecule (mole) | `orbit_808` |
   | 104.4 | TRAP LANE 404 | Trap, heavy bass hip hop | Lil Comet (ferret) | `trap_lane_404` |
   | 89.5 | COZY COIL | Lo-fi hip hop, chillhop | DJ Mochi (cat) | `cozy_coil` |
   | 91.7 | MIC CHECK MOON | Battle rap, freestyle | Twin Mics (two-headed lizard) | `mic_check_moon` |
   | 55.0 | LONG HAUL TALK 55 | Trucker talk radio, no music | Uncle Gus (bulldog) | `long_haul_talk` |
   | ??.? | ??? | A numbers station (only comes in on part of the road) | ??? | `numbers` |
   | 00.0 | MY TUNES | The player's own music (see below) | You | (user folder) |

   Each station's name, dial number, DJ, slogan, invented song names, ads
   and DJ lines are in its file in `res://data/radio/` (like
   `subspace_fm.tres`). The order on the dial is `res://data/radio/lineup.tres`.
2. Drop in **.ogg**, **.mp3** or **.wav** files. (.ogg is the best choice
   for music in Godot: small files and good quality.)
3. Name each file **`Artist - Title.ogg`**. The HUD's radio ticker shows
   exactly that (in capitals). Underscores become spaces.
4. Open the project in Godot once so it imports the new files (it does this
   by itself when the editor gets focus), then press Play.

That's it. While a station's music folder is empty, it plays a short
made-up placeholder loop in its genre instead (from
`audio/radio/placeholders/`, shared between stations of the same kind), and
the ticker shows made-up song names from the station's data file. Talk
radio plays mumbling voices; the numbers station plays tones.

**Tip:** in Godot's Import dock, songs should have **Loop** turned **off**
(the radio moves on to the next song when one ends). That's Godot's default
for .ogg and .mp3.

## Ads and DJ bits

Drop audio files into the station's `ads/` folder. One plays after every
few songs (`tracks_per_ad` in the station's data file).

Every couple of minutes (100 to 200 seconds; `radio_talk_min_seconds` and
`radio_talk_max_seconds` in tuning.tres, "Radio"), the DJ says something on
the ticker or a text ad scrolls by (`radio_ad_share` = how many of those
breaks are ads: 40% to start with, so it never feels like an ad wall).
Stations with audio ads skip the text ads.

**DJs react to you:** fly into an ion storm, get a speeding ticket, cross
into a new solar system, or deliver a load (they give you a shout-out the
next time you're on the road) and the DJ you're listening to says
something about it. Their lines are in the station files (`dj_on_storm`,
`dj_on_delivery`, `dj_on_ticket`, `dj_on_new_system`; `{bunny}`, `{place}`
and `{system}` fill in). A station with no line of its own for something
uses a general one.

## Reception: where and when stations come in

- **Regional** (Tide 77): clear near its `signal_center`, fading to
  static `signal_radius` meters away. You'll pick it up crossing into
  Tidewater.
- **Pirate** (Fuel Injection): always weak and crackly.
- **Night shift only** (Afterglow Block): off the air during the day. Until
  the game has its own shifts (M6), "night" is 9 p.m. to 6 a.m. on your
  computer's clock.
- **Hidden** (???): only comes in on one stretch of the road. Finding it
  puts it in your logbook.
- Ion storms add static to everything.

## Make a new station

1. In Godot's FileSystem dock, duplicate one of the station files in
   `res://data/radio/` (like `subspace_fm.tres`) and rename it.
2. Double-click it and change its name, dial number, genre, DJ and folders
   in the Inspector. Make the folders (`audio/radio/your_station/music/`
   and `ads/`).
3. Open `res://data/radio/lineup.tres` and add your station to the list.
   The order of that list is the order on the dial.

## MY TUNES: the players' own music

The last station on the dial, **MY TUNES (00.0)**, plays music files that
*players* drop into their own folder, `user://radio/custom/`. The game makes
that folder (with a README inside) the first time it runs. To find it: in
Godot, **Project > Open User Data Folder**, then `radio/custom/`. On a
player's computer it's in the game's save folder. New files show up the
next time you tune in.

## Licensing (important!)

Only put music in the game that you made yourself, that's royalty-free for
games, or that you have a license for (a commissioned track, for example).
**No commercial songs, no copyrighted music, no lyrics you don't own**, even
for testing builds you share. The MY TUNES folder is the exception: that's
the player's own music on their own computer, and it never ships with the
game.

There's deliberately no Spotify or streaming-service integration (see
`CLAUDE.md`).

## How it sounds where

- **In flight:** the cockpit radio. Q / E (D-pad left / right) flips
  stations with a burst of static; R (D-pad up) switches it on and off. When
  it's off, soft ambient music plays instead (`audio/generated/ambient_pad.wav`).
- **In the rig's cabin** (walking around on autopilot): through the cabin
  speakers, muffled.
- **At the truck stop and Tidewater's canteen:** the jukeboxes play the
  radio through the room's speakers, muffled.
- **Elsewhere on the base:** quiet.
- A weak signal (ion storms, the pirate station, a regional station far from
  home) adds hiss and makes the music drop out now and then.
- The radio volume is in the pause menu.

The placeholder loops, the ambient music and the hiss are made from math by
`tools/generate_radio_placeholders.gd`.
