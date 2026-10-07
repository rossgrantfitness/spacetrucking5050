# Asset list for beta

Everything the game shows or plays that is still a **placeholder**: either
built from simple shapes in code, or a sound made from math. Each one can be
swapped for real art without changing how the game works. This list is made
from what's in the game today (round 23).

It's split into **tiers**:

- **Tier 1:** what you see and hear every session, which decides how
  "finished" the game feels. Do these first.
- **Tier 2:** things you meet regularly.
- **Tier 3:** rare things and later milestones.

Tick things off as you go. When something is ready, drop it in the right
folder (see "Your pipeline" below) and tell me; I'll wire it in, scale it,
cut it into parts and check it in game.

---

## Your pipeline (and a few upgrades to it)

Your plan is good: **sketch → another AI refines it → Meshy makes the
model → hand it to me.** It already worked for Jacki, Raccoony, Chang Ma and
Clem. These tweaks will save you a lot of redos.

### 1. Make a style anchor first (once)

Before the big batch, make **one style sheet**: Jacki next to a palette
strip (hazard yellow, red, cyan, neon green, neon purple, warm orange, dark
blue-gray). Give that image to the refining AI **every time**, with the
same short prompt, for example:

> *"Mega Man Legends / PS1 style, chunky toy proportions, flat bright color
> blocks, minimal texture noise, friendly, no text or logos."*

Keeping one anchor and one prompt is what keeps 60 assets looking like one
game.

### 2. Sketches that Meshy reads well

- **Characters:**
  - Draw them standing in an **A-pose** (arms out and down at about 45°,
    legs slightly apart, hands open), facing front.
  - Hands empty. Props are separate models.
  - If your refining AI can do a **turnaround** (front, side, back on one
    sheet), Meshy gets the back of the head right much more often.
- **Ships and props:**
  - A clean **three-quarter view** on a plain background.
  - Simple, chunky shapes. Thin antennas and railings come out melted.
    Leave them off and I'll add them in code.
- **No words on anything.** Meshy smears text, and painted text can't be
  translated. Leave signs, labels and screens blank. I draw the text in
  game, crisp at any size.

### 3. Meshy settings

- If there's a **low-poly**, **polycount** or **remesh** option, use the
  lowest it allows. I'll reduce the rest, but less clean-up means fewer
  surprises.
- Turn off extra PBR maps (metal, roughness, normal) if you can. We only
  use the base color.
- Download as **GLB**.

### 4. Where to put files

Uploading to `reference/` is fine: I move each file into the game's art
folder and wire it up. The game's art lives in `art/`:

```
art/backgrounds/<room>/<shot>.jpg   pre-rendered room backgrounds (FF7 style)
art/models/<name>.glb               models (characters, props, stations)
art/alternates/                     spare versions not used yet (hidden from Godot)
```

**Background names:** `<room>` is the room's scene name and `<shot>` is
the camera's name, both in lower_case_with_underscores, e.g.
`art/backgrounds/engine_room/toward_door.jpg`. The 29 screenshots I sent
(and `cameras.txt`) list every room and camera. A picture there replaces
the game's own painting for that camera. Nothing else is needed; a missing
one just falls back to the game's own. Any 16:9-ish size works: the
picture's full height fills the screen.

**Keep the camera and layout:** paint over the clean export without
moving the camera or the furniture (low "strength" in image-to-image).
The game hides Jacki behind the room's hidden 3D furniture, so if the
painting moves the bed or the door, she ends up standing on the bed or
cut off by nothing. The apartment's two paintings did this. I refit the
room to them, but a matching repaint is always better.

**Blank signs:** if your painting leaves a sign board blank, I can have
the game draw that sign's words live on top (per camera; the dispatch
and engine room signs work like this now).

### 5. What I do with each model

- Reduce it to the PS1 budget.
- Shrink its texture to 256 or 128 px with crisp (nearest) pixels.
- Scale it (1 unit = 1 m).
- Point it the right way (ships face forward along −Z).
- Cut characters into rigid swinging parts like Jacki.
- Add the PS1 wobble shader.

You don't need Blender. If you ever want to learn one tool, **Blockbench**
(free) is the friendliest for small PS1-style props.

### Budgets (from `CHARACTER_BIBLE.md`)

| Kind | Triangles (after my clean-up) | Texture |
|---|---|---|
| Jacki | 800–1,200 | 256 px |
| Named NPC | 400–800 | 128 px |
| Comm-only head and shoulders | ~300 | 128 px |
| Rig (player ship) | 1,500–3,000 | 256 px |
| Traffic ship | 300–800 | 128 px |
| Station exterior | 2,000–5,000 | 256 px, can reuse tiles |
| Big prop (vending machine) | 300–800 | 128 px |
| Small prop (snack, toy) | 50–200 | 64 px |

### What Meshy is *not* good at (use something else)

| Thing | Better way |
|---|---|
| **Rooms and buildings** | Keep them built from boxes in code, but give me **textures**: 64 or 128 px square tiles (wall panels, floor grates, neon strips, carpet). Paint them, or have an AI draw them and shrink them. This is the biggest visual upgrade for the least work. |
| **Signs, posters, billboards, packaging labels, screens** | Flat 2D images (128×64 and the like). Blank space where text goes, or tell me the text and I'll draw it. |
| **Planets, nebulae, sky** | 2D textures: a 256×128 "wrapped" planet map with bold swirly bands. |
| **Faces (expressions)** | Small painted sheets (see Jacki's face sheet in the bible): eyes and mouth cells on a grid. |
| **Logo and title screen** | 2D art. |

---

## Art: Tier 1 (every session)

### Jacki and the crew
- [ ] **Jacki: face sheet**
  - 128×128 px, a 4×4 grid of 32 px cells: eyes open, half-lidded (her
    default), closed, surprised, happy; mouths closed, talk A, talk O,
    smirk, frown.
  - Her body model is in; this is what makes her talk and emote.
- [ ] **Jacki: separate accessories**
  - Cigarette (her default), a soda can, a coffee cup.
  - Small props, any style.
- [ ] **Raccoony** (raccoon, dispatch): face sheet, 64×64 (2×4 cells).
- [ ] **Chang Ma** (mole, engineer): face sheet, 64×64.
- [ ] **Clem** (donkey, cargo hand): face sheet, 64×64.
- [x] **The boss** (Dale Pembrook, lion): your model is in, in the OrbitalEx office.
- [x] **Olivia** (ostrich, ditzy crew mascot): your model is in, aboard the rig.
- [x] **Marge** (owl, the truck stop diner): your model is in.
- [x] **Bonnie** (polar bear, OrbitalEx receptionist) and **Mort** (weasel, the boss's coworker): your models are in.

### Your rig: The Thumper
- [ ] **Exterior model.** The one you look at for hours. Gunmetal, amber
  cockpit glass, silver engine pods with yellow trim (see
  `reference/ship_bb42_cargo_aircraft.webp`). Mark where the **engine
  nozzles** are on your sketch; trails and flames come out there.
- [ ] **Cockpit props:**
  - hazard-striped struts (texture: a 64 px yellow-and-black stripe tile);
  - the bobblehead (a tiny Jacki-style figure, or anything you like);
  - fuzzy dice;
  - an air freshener (blank, I'll put a brand on it);
  - a coffee cup;
  - a dashboard photo frame (the husband, later; leave the picture blank).
- [ ] **Cockpit screen frames** (2D): green monochrome screen borders and
  a radar globe look.

### The truck stop (first station, home base)
- [ ] **Marge** (owl, traffic control and diner): body model.
- [ ] **Lily** (frog, fuel pumps): body model.
- [ ] **Dusty** (beaver, mechanic and rig dealer): body model.
- [ ] **Truck stop textures:**
  - wall panel;
  - floor;
  - diner counter;
  - neon strips (green, purple, orange, cyan);
  - one window-onto-space tile.
- [x] **Truck stop exterior** (seen in flight): your model is in.

### Rig rooms (her home while she flies)
- [x] **Pre-rendered backgrounds** for all 12 rig cameras (cabin, hallway,
  dispatch, galley, cargo bay, engine room): yours are in.
- [ ] **Pre-rendered backgrounds** for the truck stop (8 cameras), the
  OrbitalEx office (3), the Tidewater canteen (3) and the casino (3).

### Flight, every trip
- [ ] **Asteroids:** 3 to 4 chunky rock models (rough, round, long, flat)
  plus 2 rock textures. I tumble, scale and tint them, so a few go a long
  way.
- [ ] **Planet textures:**
  - a 256×128 swirly map for each planet you pass: home, Tidewater ocean
    world, Glimmer casino world;
  - the sun.
- [ ] **Station exteriors:** Tidewater Cannery, Gas-N-Go 47, The High
  Roller casino, the OrbitalEx base.
- [ ] **Title logo:** "SPACE TRUCKIN' 5050" (2D; I'll do the PS1 effects).

---

## Art: Tier 2 (met regularly)

### Other characters (body models)
- [ ] **Gill** (otter, Tidewater client)
- [ ] **Sal Grinwell** (crocodile, casino owner)
- [ ] **Big Wendell** (walrus, trucker)
- [ ] **Pip** (hamster, courier)
- [ ] **Face sheets** for each (64×64)

### Comm-only voices (head and shoulders, for the call portrait)
- [ ] **Moe** (sloth, Gas-N-Go)
- [ ] **Fern** (mole, approach control)
- [ ] **Gus** (pigeon post)
- [ ] **Deputy Biscuit** (dog, Space Patrol)
- [ ] **Bev** (pig, tourist)

### The other 13 rigs (buyable at Dusty's)
Each is a big sale moment, so it should look like what it's called.
- [ ] **The Garbage Scow**
- [ ] **The Zippy Zenith**
- [ ] **The Ice-Tug**
- [ ] **Big Bertha**
- [ ] **SLAB** (Stack-Ship Corp.)
- [ ] **The Capsule Cruiser** (see `reference/ship_capsule_hauler_sketch.png`)
- [ ] **The Catamaran**
- [ ] **The Cryo Tanker**
- [ ] **The Hab-Brick**
- [ ] **The Bulk-Ore**
- [ ] **The Ore-Crawler**
- [ ] **The Omega Ore Crawler**
- [ ] **The Megahauler**

### Traffic and set pieces
- [ ] **Traffic ships:** 4 to 6 small generic haulers. I recolor them and
  hang funny names on them. Currently they're free low-poly ships from
  OpenGameArt, which are fine but not ours.
- [ ] **The big ship** for the flyby: one huge, slab-sided freighter.
  Cheap flat panels are fine; it reads as huge because it fills the
  screen.
- [ ] **Space whales:** one model, gently swimming. It can have a swinging
  tail part.
- [ ] **Cosmic jellyfish:** one model, see-through look (I do the glow).
- [x] **Billboards:** your frame model is in (the game prints each ad on
  its white screen). Optional later: **ad images** (2D) for the brands.
- [ ] **Derelicts and junk:**
  - 2 or 3 wrecks;
  - a floating couch, a fridge, a shopping cart (for the junk clouds).
- [ ] **Road signs and route markers:** 2D faces.
- [ ] **Comet:** texture only.

### Upgrades you can see on the rig
- [ ] **Bumper bars, radar dish, horn trumpets, roof light bar, stacking
  rack with crates, exhaust stacks, solar sails.** Small, separate pieces;
  I fit them to every rig.

### Vending and snacks
- [x] **Vending machine** model: yours is in (Tidewater and the casino).
- [ ] **Brand logos** (2D, 64 px) for the 12 brands:
  - Moon Milk
  - Neon Soda Works
  - Zoom Juice
  - Old Orbit Space Jerky
  - Galaxy Gumballs
  - Mochi Moons
  - Star-Stop Ramen
  - Cozy Coil Cocoa
  - Dr. Sprinkle's
  - Tidewater Cannery
  - Marge's
  - The High Roller
- [ ] **Packaging** for the 22 snacks: can, bottle, cup, bag and box
  shapes exist already. Label art (64 px) is all they need; a few special
  ones (the ramen cup, the pie slice, the starfish tin) could be models.

### Station interiors
- [ ] **Tidewater cannery canteen:** textures, plus tins and nets props.
- [ ] **The High Roller lounge:** carpet, slot machine and card table
  models, neon.

---

## Art: Tier 3 (rare, or later milestones)

- [ ] **Outfits** (parked): hats, jackets, boots, accessories (see the
  bible).
- [ ] **Furniture and decor** for the cabin (parked): rugs, plants,
  posters, lamps, a fish tank...
- [ ] **New systems and clients** (M8):
  - one signature color;
  - a client character;
  - a station;
  - a planet texture;
  - one gimmick set piece each.
- [ ] **The husband's story** (M8):
  - his photo (2D);
  - a voicemail tape;
  - a ship log screen;
  - an old jacket.
- [ ] **Rare cosmic events:** the rarer sights in the logbook.
- [ ] **TV console mini-games:** pixel sprites, if you want them nicer
  than the current blocks.
- [ ] **Controller button icons** (M10).

---

## Sound

### How the game sounds now (round 23)

Every little sound is made from math in **one gentle key, A major
pentatonic** (A B C# E F#), with soft **wood, glass and felt** tones and
no shrill highs. If you replace any of them, keep to that and they'll fit
together:

- **Recording your own is easy and on-style:**
  - knock on wooden spoons or a cutting board;
  - tap glasses with a pencil (tune them with water);
  - tap felt-covered things;
  - a phone voice-memo app is enough.
- Trim it, keep it short, and drop it in `assets/sounds/`. I'll match the
  volume, tune it into the key and filter the harsh top off.
- **Free sounds:** Freesound.org, filtered to the **CC0** license (no
  credit needed, safe to sell). Avoid anything "Attribution-NonCommercial".

### Music: the biggest job (Tier 1)

**The radio is half the game.** There are **21 stations**, and each needs
real tracks. Right now each plays a placeholder loop. For beta, aim for at
least **2 or 3 tracks on 5 or 6 stations**, starting with the core vibe:

- [ ] **SUBSPACE FM:** drum & bass, jungle (the brief's signature sound)
- [ ] **COZY COIL:** lo-fi hip hop, chillhop
- [ ] **NEON DRIFT:** synthwave, outrun
- [ ] **AFTERGLOW BLOCK:** downtempo, late-night electronica
- [ ] **HOSHIZORA 83:** J-pop, city pop
- [ ] **TIDE 77:** dub, trip-hop

Then the rest, as you find music:
- [ ] ASTEROID ROCK
- [ ] BLACK HOLE RADIO
- [ ] EVENT HORIZON
- [ ] FUEL INJECTION
- [ ] GLAM ROCKET
- [ ] HULL BREACH 101
- [ ] HYPERJUMP 180
- [ ] KRSH 666
- [ ] MIC CHECK MOON
- [ ] ORBIT 808
- [ ] STATIC CLING
- [ ] TRAP LANE 404
- [ ] WOBBLE BELT

Three need no music:
- LONG HAUL TALK (talk radio);
- the numbers station;
- MY TUNES (the player's own files).

**Music sources and licensing:**
- music you make yourself;
- music you commission;
- tracks with a license that allows commercial games (royalty-free packs
  that say "games" in the license, or CC0 / CC-BY with credit).

No songs from real artists without a written license. Keep the license
file next to each track. Format: `.ogg`. Details are in
`audio/radio/README.md`.

- [ ] **Radio-off ambient music:** 2 or 3 long, gentle pads (currently one
  math loop).
- [ ] **Docking waltz:** the current one is original and made from math.
  A real recording (piano and strings, a lounge waltz) would be lovely.
- [ ] **Title screen music** (M10): a short loop.

### Sound effects

**Flight (Tier 1)**
- [ ] **Engine:** a low hum, a mid whine, an air rush and a growl. Four
  seamless loops that blend by speed. Real recordings of a fan, a vacuum
  or a fridge compressor, pitched down, work great.
- [ ] **Boost** spool-up and **bonk** (soft, cartoony).
- [ ] **Cockpit:**
  - switch clicks (2 or 3);
  - dial turns;
  - the radio tuning knob.

**Hub (Tier 2)**
- [ ] **Footsteps:** metal floor, carpet, grating (3 or 4 each).
- [ ] **Room ambience loops:**
  - truck stop diner hum;
  - rig cabin;
  - cannery (water, machines);
  - casino (soft chimes, murmur).

**Set pieces (Tier 2)**
- [ ] Doppler whoosh and big-ship rumble.
- [ ] Space-whale song.
- [ ] Jellyfish chimes.
- [ ] Comet whoosh.
- [ ] Vending machine hum.

**Little moments (Tier 3)**
- [ ] Short jingles for:
  - leveling up the rig;
  - buying a new rig;
  - paying the weekly bills;
  - the first taste of a new snack.

  Use the game's three-note signature, E then A then C#.

### Voices

- **No voice acting needed.** Everyone talks in pitched gibberish blips
  (five voice types, already made). If you ever want to, record yourself
  saying "mm", "ba", "da" in a few voices and I'll turn them into blip
  sets.
- **DJ and ad lines** stay as text with blips. Real voice-over would be a
  big, optional job for much later.

---

## Suggested order

1. Jacki's face sheet, and the Thumper's exterior.
2. Truck stop textures, plus Marge, Lily and Dusty.
3. Music for Subspace FM and Cozy Coil.
4. Asteroids and planet textures.
5. Rig room textures and cockpit props.
6. Then work down Tier 2 at your own pace, a few assets per week.

Send me things in small batches (2 or 3 at a time) so we catch style
problems early.
