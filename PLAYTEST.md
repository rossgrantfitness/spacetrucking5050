# Playtest: round 7 (the first mission, the truck stop, the radio)

**What you asked for:** a first mission, the truck stop twice as far away,
an inside for the truck stop where you take that mission (with room to grow
into a hub), the radio system so you can start making stations, and more
wobble and dither. "Do a lot of work before you ask me again."

**Time needed:** 30-40 minutes (the trip is longer now, on purpose).

> Honest note: I played all of this with automated test runs (the whole
> first mission plays itself start to finish in the checks) and looked at
> screenshots of every room angle. How long the trip feels, whether the
> truck stop feels cozy and big in a good way, and whether the wobble and
> dither are too much are yours to judge. I couldn't *hear* anything: the
> placeholder beats are made from math and might sound odd.

---

## What's new

**The first mission**
- Start a **new game** (boot screen: "start a new game"; it'll say
  CONTINUE from now on, because the game saves itself).
- Talk to **Dottie** at dispatch: Marge, who runs the truck stop, needs a
  hauler. Board the rig.
- Fly to the **truck stop, now about 10 km out** past the asteroid field (a
  ~3 minute drive at the rig's top speed). Follow the yellow diamond on the
  compass strip.
- Fly through the big **glowing ring** in front of the bay: the
  **autopilot docks you**, and you climb out inside.
- Find **Marge** behind the diner counter. Take her **pie run**: nebula
  pies (fragile!) for your base's cafeteria. 450 credits, plus up to 150
  if they arrive without a scratch.
- Fly home, through the base's ring (the base is a huge old starship now,
  sitting right behind where you launch). You get paid when you climb out:
  a **payout card** shows the bonus breakdown.
- That opens the **job boards** at both places (4 repeatable jobs), so you
  can keep hauling back and forth.

**The truck stop inside** (big on purpose, with room to grow)
- **Marge's Diner:** counter, stools, booths (Big Wendell is in one), a pie
  case and a **jukebox** that plays the radio through the speakers.
- **Job board** in front of a huge window onto space.
- **Dusty's Garage:** patch the hull, buy **upgrades**. Hot-Rod Injectors
  (+25% top speed, 1400 credits) is the one you should *feel*. Also Twin
  Afterburners, Power Steering and Saddle Tanks.
- **Lily's Pumps:** buy fuel and boost fuel (the base's pumps are free).
- **Arcade lounge:** Pip's at the cabinets; a vending machine with neon
  soda; restrooms.
- **"Coming soon" shops:** Outfitters, Home & Decor, Insurance and the Nap
  Motel, shuttered for now. That's where wardrobe, decor, insurance and
  rest go later.
- Look at things with **E**: windows, cabinets, the pie case, the porthole...

**The radio plays real music now**
- Drop songs into a station's folder and they play:
  `audio/radio/subspace_fm/music/` and friends. Name them
  `Artist - Title.ogg` (or .mp3 / .wav). Full guide:
  **`audio/radio/README.md`**. Until a station has songs, it plays a short
  made-up placeholder beat in its genre.
- Stations keep playing while you're tuned away, like real radio.
- **Q / E** flip stations, **R** (D-pad up) turns the radio off: then soft
  ambient music plays, swelling a little when you fly fast.
- **MY TUNES (00.0)** plays your own files from the game's
  `radio/custom/` folder (Godot: Project → Open User Data Folder).
- Radio volume is in the pause menu.

**More PS1:** wobblier models, more texture swim, fewer colors with a
stronger, chunkier dither, and softer painted backgrounds in the rooms.

## What to do

1. Pull the update. Open the project in Godot (let it import), press **F5**.
2. Click **start a new game** and play the first mission start to finish.
3. Spend your pay: fuel at Lily's, then do two more jobs and buy the
   **Hot-Rod Injectors** from Dusty. Fly. Feel the difference?
4. Put a song or two into `audio/radio/subspace_fm/music/` and listen in
   the cockpit. Try **MY TUNES** with your own folder.
5. Walk every corner of the truck stop. Use the jukebox. Talk to everyone.
6. Optional knobs in `data/tuning.tres`: **PS1 look** (wobble, dither,
   color shades), **Prices**, **HUD**, **Comms chatter**.

## What to pay attention to

- Does the ~3 minute trip feel like a nice cruise, or too long?
- Is docking through the ring satisfying? Is the ring easy to find?
- Does the truck stop feel cozy, big and alive? Which camera angles work?
- Is the PS1 look now "old enough", or too crunchy?
- Does the money feel right? (Starting 150, the first job pays up to 600,
  fuel at the truck stop up to 90 a tank, the speed upgrade 1400.)

---

## Questions for you

1. **The first mission:** does Marge's pie run work as a first mission? Is
   the story setup (Dottie → Marge) the right amount of talking?
2. **Distance and docking:** is 10 km (about 3 minutes) the right drive for
   now? Is the autopilot docking too long, too short, or just right?
3. **The truck stop:** what should open first behind those "coming soon"
   shutters (outfits, decor, insurance, motel), and is anything missing that
   a truck stop should have?
4. **The look:** more wobble and dither, less, or just right? (All in
   `tuning.tres` → PS1 look.)
5. **The radio:** how do you want to make your stations? Tell me each
   station's name, genre, DJ and vibe, and I'll set up their files (and DJ
   lines and fake ads) for you.

## Still open from round 5 (walking the base)

1. **The base:** do the pre-rendered rooms hit the look you wanted? Which
   camera angle do you like best, and which would you change?
2. **The bunny:** right proportions and outfit? (Fur color, cap, jacket and
   the wheat stalk are all easy to change.)
3. **Damage:** should a battered rig handle worse (say, a bit slower) until
   it's repaired, or stay purely cosmetic?
4. **The cockpit:** what other toys or gizmos do you want in there?
5. **Wobble/dither:** better now, or push further?
