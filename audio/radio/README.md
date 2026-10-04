# The radio: how to add music

The cockpit radio plays real music files. Each station has its own folder
here, and anything you drop in it plays on that station, shuffled, with ads
between songs. Stations keep "broadcasting" while you're tuned away, like
real radio, so flipping back lands you mid-song.

## Add songs to a station

1. Find the station's folder:

   | Station | Dial | Folder |
   |---|---|---|
   | SUBSPACE FM (drum & bass) | 104.2 | `audio/radio/subspace_fm/music/` |
   | JUNGLE JUICE (jungle) | 99.1 | `audio/radio/jungle_juice/music/` |
   | LATE BLOCK 77 (late-night cartoon electronica) | 77.7 | `audio/radio/late_block/music/` |
   | LO-FI DRIFT (chill / lo-fi) | 66.6 | `audio/radio/lofi_drift/music/` |

2. Drop in **.ogg**, **.mp3** or **.wav** files. (.ogg is the best choice
   for music in Godot: small files and good quality.)
3. Name each file **`Artist - Title.ogg`**. The HUD's radio ticker shows
   exactly that (in capitals). Underscores become spaces.
4. Open the project in Godot once so it imports the new files (it does this
   by itself when the editor gets focus), then press Play.

That's it. While a station's music folder is empty, it plays a short
made-up placeholder beat instead (`placeholder_loop.wav` in the station's
folder), and the ticker shows made-up song names from the station's data
file.

**Tip:** in Godot's Import dock, songs should have **Loop** turned **off**
(the radio moves on to the next song when one ends). That's Godot's default
for .ogg and .mp3.

## Ads and DJ bits

Drop audio files into the station's `ads/` folder. One plays after every
few songs (`tracks_per_ad` in the station's data file). If a station has no
audio ads, it scrolls its text ads across the HUD ticker instead.

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
- **At the truck stop:** the jukebox plays the radio through the room's
  speakers, muffled.
- **Elsewhere on the base:** quiet.
- A weak signal (solar storms, coming later) adds hiss and makes the music
  drop out now and then.
- The radio volume is in the pause menu.

The placeholder beats, the ambient music and the hiss are made from math by
`tools/generate_radio_placeholders.gd`.
