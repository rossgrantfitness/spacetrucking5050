# How to run Space Truckin' 5050

You don't need to know any code for this. It takes about 10 minutes the first
time, and after that it's just "open Godot, press Play".

---

## 1. Install Godot (one time)

Godot is the free game engine this game is built with. It's a single program;
there's no installer.

1. Go to **https://godotengine.org/download** and download **Godot 4.7.2**
   (or any newer **4.7.x**).
   - Pick the regular version, **not** the ".NET" one.
   - If the site already offers something newer than 4.7, the exact version
     we use is here:
     https://github.com/godotengine/godot/releases/tag/4.7.2-stable
     (under "Assets": `..._win64.exe.zip` for Windows, `..._macos.universal.zip`
     for Mac, `..._linux.x86_64.zip` for Linux; skip anything with "mono" in
     its name, those are the .NET versions).
2. Unzip it somewhere easy to find (Desktop, Documents, Applications...).
3. Double-click it to start. (Windows: `Godot_v4.7.2-stable_win64.exe`.
   Mac: `Godot.app`.)

## 2. Get the project files

The project lives on GitHub: https://github.com/rossgrantfitness/spacetrucking5050

All the current work is on the branch **`claude/serene-galileo-035l4z`**.
(There's also an old branch, `claude/fervent-albattani-prfaw0`, from back
in round 5. Don't use that one: it's very out of date.) On GitHub, pick
the branch from the branch menu (top-left of the file list, it may say
`main` or another name) **before** you download anything.

- **Recommended: GitHub Desktop** (free, https://desktop.github.com). Sign in,
  then *File → Clone repository*, pick `spacetrucking5050`, and click
  *Clone*. Use the *Current branch* menu at the top to switch to
  `claude/serene-galileo-035l4z`. Whenever I push new work, click
  *Fetch origin*, then *Pull origin*, and you're up to date.
- **Quick alternative: download a ZIP.** On GitHub, switch to the branch
  above, then click the green **Code** button → **Download ZIP**.
  **Unzip it before opening it:** right-click the ZIP → **Extract All...**
  → pick a normal folder (like Documents). Don't double-click
  `project.godot` *inside* the ZIP: Windows then copies just that one
  file into a temporary folder, so Godot finds no scenes ("Can't open
  file Boot.tscn") and can't save anything ("Unable to write to file").
  You'd also have to re-download after every update, so GitHub Desktop
  is nicer long-term.

## 3. Open the project in Godot

1. Start Godot. The **Project Manager** window appears (a list of projects,
   empty the first time).
2. Click **Import**, browse to the project folder, and select the file
   `project.godot` inside it. Confirm the import.
3. The project opens in the editor. The very first time, Godot spends a few
   seconds "importing" (preparing files). That's normal.

From now on, the project shows up in the Project Manager list: just
double-click it.

## 4. Press Play

- Press **F5** (Mac: **Cmd+B**), or click the **▶ Play** button at the
  top-right of the editor.
- A game window opens. To stop, close it, or press **F8** (Mac: **Cmd+.**).

First, a few seconds of **power-on intro** (a self test types itself out,
then the logo and a chime; any key skips it). Then the **title screen**: the title and a lazily tumbling cargo
crate. (A small "test your keys and gamepad" link opens an input check where
every control lights up when you press it.) Press **Enter** (or **Start** on a gamepad, or click **PRESS START**) to
start a new game in dispatch (inside your rig, the Thumper, parked out past the company HQ), where Raccoony starts talking, or to **continue** where you left off
(the game saves itself whenever you walk into a room, take a job, get paid
or buy something). The small buttons below jump straight into flying, or
start a **new game** (that forgets your save). See `PLAYTEST.md` for what
to try.

**Never lost:** a yellow line at the top left (on foot) or under the
compass (flying) always says what to do next. On foot, a **yellow
diamond** bobs over the door or stairs it means, and a **solid yellow
"!"** hangs over whoever has a job for you or who you're meant to talk
to. Story calls on the comm turn the radio down to half until they're
done.

---

## Controls

**In the game, press Esc (Start on a gamepad) and pick CONTROLS** for this
list on screen, any time.

Gamepad buttons use Xbox names, by position: **A** = bottom button, **B** =
right, **X** = left, **Y** = top. (On PlayStation: A = ✕, B = ○, X = □,
Y = △.)

### Flying

| What | Keyboard & mouse | Gamepad |
|---|---|---|
| Steer left / right | **J** / **L**, or **A** / **D**, or **←** / **→** | Left stick |
| Nose up / down | **I** / **K**, or **↑** / **↓** | Left stick |
| Look around the rig (any direction) | Move the mouse | Right stick |
| Pan the camera | Hold **right mouse button** and drag | — |
| Camera back behind the rig | **Middle-click** (or wait a few seconds) | (wait a few seconds) |
| Throttle lever up | **W** (hold) | **RT** (right trigger) |
| Throttle lever down (to idle, then reverse) | **S** (hold) | **LT** (left trigger) |
| Boost (hold; full throttle only) | **Space** | **A** |
| Switch camera (chase / cockpit) | **C** | **Y** |
| Zoom the chase camera in / out | Mouse wheel | — |
| Cinema camera (on autopilot): director, then free camera, then back | **V** | **R3** (click the right stick) |
| Radio: next / previous station | **E** / **Q** | D-pad **right** / **left** |
| Radio on / off | **R** | D-pad **up** |
| Hide / show the HUD | **H** | D-pad **down** |
| Chart a course (autopilot) | **M** | **Back** / **View** |
| Get up and walk around inside the rig (on autopilot) | **F** | **X** |
| Reply to a comm call, then pick one | **T**, then **Q** / **R** / **E** (or **1** / **2** / **3**) | **RB**, then D-pad **left** / **up** / **right** |
| Logbook (sights you've seen) | **N** | (pause menu) |
| Air horn (once you've bought one at Dusty's) | **B** | **L3** (click the left stick) |
| HUD demo (lights every warning, for checking the look) | **F9** | — |
| Pause menu | **Esc** | **Start** |

**The throttle is a lever.** Hold W to push it up and S to pull it down;
it stays where you leave it, and the rig speeds up or slows down to match,
then holds that speed (the yellow tick on the speed bar shows where it's
set). Pull it back and it stops at **idle** (the rig brakes to a stop);
it won't go into reverse while you're still holding. Let go and pull
again for a slow reverse. The rig is heavy: turns take a moment to start and
stop, carve, and slide at high speed. The tiny green **flight marker** (a
dot with little wings) shows where your momentum is really carrying you,
which isn't always where the nose points.

**Fuel:** thrusting burns fuel, more at high speed; coasting is free. The
little **ECO** arrow under the fuel gauge turns green, yellow or red to show
how thriftily you're flying. An empty tank never strands you: the engines
keep crawling along "on fumes".

Holding thrust at top speed only **sips** fuel: the engines' limiter just
holds your speed (a full tank cruises about 27 minutes).

**Boost** rockets you way past top speed (and gets slidey!). It's a
commitment: it only works with the throttle at full, it **spools up** for
a moment while you hold it (SPOOL blinks), and once lit it burns for at
least 3 seconds even if you let go. It burns **boost fuel** (the tiny
**BST** bar), which doesn't refill by itself; a full boost tank lasts 6
minutes. **Boosting gives you speed wobbles**, like a car going too fast
on the highway: the longer you hold it, the harder the rig shakes, and it
slowly pulls off course, so keep correcting. Jerky steering makes it shake
worse; let go of boost and it settles.

**Overdrive (going way too fast).** Keep holding boost once you hit
boost's top speed (about 800 km/h in the Thumper) and the rig **keeps
climbing**, about 30 km/h a second, with no ceiling. The faster you go:
- the worse the wobbles and the drift;
- the harder it is on the cargo;
- the speed number flashes red and **OVERDRIVE** shows by the speed bar.

Past about **1,800 km/h** the **HULL STRAIN** bar fills (above the
speed), faster the faster you're going. You get plenty of warning:
- banners repeat ("HULL STRAIN 40%: EASE OFF", then "HULL CRITICAL:
  LET GO OF BOOST");
- an alarm starts quietly and gets louder;
- Chang Ma, Raccoony and even Deputy Biscuit call in (the radio dips).

At full strain the rig can't take its own speed: she spins out and goes
up in a fireball. Uh oh, went too fast. Let go of boost any time and it
all calms down. (Numbers: "Overdrive" in tuning.tres.)

**Rocks all the way round.** Stations sit inside a ball of rocks (or ice,
or junk). Fly in down the clear **traffic lane** that leads to the approach
ring, or pick your way through. The autopilot always uses the lane.
Stations have no names painted on them: the green ID label (the one that
names passing ships) tells you which station you're looking at.

**Mind the cargo.** Hard turns, slides, hard braking and boosting flat out
rattle the load (the **RIDE** bar under the cargo readout, top right:
green is fine, yellow is bumpy, red is damaging it). When the load gets
knocked around you hear it thump in the hold, feel a jolt, the cargo hold
flashes orange on the little rig picture (bottom right), and a word under
the RIDE bar says why: HARD TURN, BRAKING or BOOST SHAKE. Damaged cargo
pays a smaller care bonus. Speeding up straight ahead never hurts it.
At the truck stop, Lily's pumps sell fuel, and Dusty's garage patches the hull and sells
upgrades, **new rigs** (each with its own handling; bigger holds pay more
per job) and **paint jobs**.

**Crashes:** bonks at cruise speed just knock the hull and cargo. But hit
something at boost speed (or let the hull wear down to nothing) and the
rig spins out of control and blows up. Press any key at the prompt and
you're back at your last save, nothing lost. (Crashes can be switched off in tuning.tres,
"Crashes".)

**Docking:** fly through the big glowing **ring** in front of a station's
bay and the autopilot takes over and parks you. Then you climb out and walk
around inside (the truck stop, Tidewater Cannery's canteen,
where Gill works, and The High Roller, Sal's casino in the Glimmer System). The **Gas-N-Go 47** is a drive-through: fly through
either ring, pull up under the canopy, buy cheap fuel, Moe's calming jerky
or a souvenir, maybe take a side job, and you roll out the far side still
moving. The
yellow diamond on the compass strip points at where you're headed.

**Chart a course (M):** a map with every place you can go, how far, how
long cruising vs. on full boost, and how much fuel it takes. Pick one (or
"via the Gas-N-Go") and the autopilot drives at cruise speed, steers around
rocks and traffic, and flies you through the ring. **Small nudges don't
switch it off:** a light touch on the stick just leans the rig a little,
and the autopilot steers back on course when you let go. To take over,
**hold** the stick firmly (or the throttle) for about half a second
("HOLD TO TAKE THE WHEEL" shows as you start), or hit boost (instant).

**The cinema camera (V / R3, on autopilot):** sit back and watch your rig.
A "director" picks shots by itself and cuts every 7-10 seconds: a slow
orbit, a tracking shot alongside, a fly-by (the camera waits ahead and the
rig whooshes past), a low hero shot from the front, a long-lens wide shot,
and a high shot from behind. Black film bars, and the HUD tucks away (calls
and messages still show). **Touch the stick or the mouse and you hold the
camera:** swing it all the way around the rig, and zoom with **W / S**
(triggers) or the **mouse wheel**. In this mode the stick never steers
the rig, so you can't knock off the autopilot. Press **V** again to go to
the free camera, and once more for the chase cam (or **C**). Getting up,
arriving, a crash, or the autopilot switching off also brings you back.

**Home is the inside of your rig.** Behind the cab are the dispatch office
(Raccoony rides along), a hallway with the airlock, and your apartment.
**Get up (F / X) while the autopilot drives:** you come down the cockpit
stairs into dispatch and can walk all of it while the rig keeps flying.
The **COCKPIT** door at the top of the stairs puts you back in the seat.
Lie down on your bed and choose **SLEEP TILL WE GET THERE**: you wake up
back in the seat just outside the next stop on your course. The trip still
uses its fuel, and a rush job's clock still runs. Arriving always puts
you back in the seat.

**Her computer** (the desk in the apartment, **E** / **A**): CARROT OS.
**Mail** arrives as the story goes along, **Invoices** lists everything
you've been paid for, and **Asteroid Alley** is a little game: hop lanes
with left / right, dodge rocks, grab fuel cans. Esc backs out; the mouse
works too. Parked, the bed starts a **new day**.

**Talk back:** after a comm call, "T: REPLY" shows under it. Press T (RB),
then pick one of three things Jacki says back. Just flavor; nothing changes.

**The logbook (N, or the pause menu):** every sight you get close to
(whales, the donut, the derelict, a comet...) goes in it. Some are rare:
you might drive fifty hauls before you see one.

**The long haul:** Tidewater, the teal system, is about 59 km past the
truck stop: 18 minutes cruising, about 4½ on full boost. Along the way: highway
signs, a junk spill, the Gas-N-Go, the world's biggest donut, the border
gate, a lighthouse, an old derelict, an ion storm (radio static, a few
jolts), icy rocks, whales, and a space-patrol speed trap near the cannery
(the **COPS** light warns you; over 250 km/h right past it costs a small
fine). Random sights come and go too: big ships crossing, convoys,
billboards, comets, jellyfish, junk.

**The Glimmer System** (the pink one) is the other way from the truck
stop, about 56 km: 17 minutes cruising. Raccoony at dispatch has the first
job out there (after your first delivery). Neon billboards get thicker the
closer you get, plus the world's biggest slot machine, two giant tumbling
dice, the Little Chapel of the Void, limos, and another speed trap by the
casino. At **The High Roller** you climb out on the casino floor: Sal (a
crocodile) has jobs for you, the board by the cashier cage has loads, and
the gold slot machine (**The Lucky Molar**, 10 credits a pull) is a little
mini game. Like real slots, it keeps a bit more than it pays out over time.

**The HUD** (in the style of Wipeout): speed and boost bottom-left, the
radar globe bottom-middle, fuel and the hull picture bottom-right, the
compass strip with distance and ETA at the top, the radio top-left, cargo
and pay top-right, and warning lights down the left edge. Calls from
dispatch, truck stop control and other truckers pop in at the top-left.

**The radio** has 20 stations (and a hidden one), each with its own DJ, ads
and genre; DJs react to what you do (storms, tickets, new systems, your
deliveries). Drop songs into a station's folder and they play (see
`audio/radio/README.md`). Until then each station plays a little
placeholder loop. The last station, **MY TUNES**, plays your own
music files from the game's `radio/custom/` folder.

**Volume:** the pause menu has three sliders: **Music (radio)**, **Sound
effects** (engine, boost, bonks...) and **Voices** (the little talking
blips). The engine is quieter than before so the music comes first.

**The little sounds** (menus, doors, money, the nav computer) are made
from math by `scenes/common/SfxSynth.gd` and saved as `cue_*.wav` files in
`audio/generated/`. They're all in one gentle key, made of soft wood,
glass and felt tones. To try your own, replace a file and keep its name
(the busy ones also have `_2` and `_3` versions, picked in turn so they
never repeat exactly).

**The mouse while flying looks around:** it's hidden and locked to the game
window, and moving it swings the camera all the way around your rig, which
stays in the middle of the screen. Hold the right button and drag to pan;
the wheel zooms. Let go for a few seconds and the camera eases back behind
the rig (middle-click snaps it back). The mouse never steers: steer with
**I J K L** (or A / D and the arrows, or the left stick). On autopilot the
pointer is free (watch mode): drag with the left button to look around.
Press **Esc** to get your pointer back any time (that opens the pause menu).

### Walking around (your rig and the stations)

| What | Keyboard & mouse | Gamepad |
|---|---|---|
| Walk | **W A S D** (or arrow keys) | Left stick |
| Run (hold) | **Shift** | **X** (or click the left stick) |
| Talk / use / board your rig | **E** | **A** |
| Leave a conversation (or just walk away) | **Esc** | **B** |
| Pause menu | **Esc** | **Start** |

"Up" always walks away from the camera. Doors take you to the next room
when you walk into them. Inside your rig: the **AIRLOCK** door in the
hallway steps out into whatever station you're parked at, and the
**COCKPIT** door at the top of the dispatch stairs takes the wheel. At a
station, its airlock (**BOARD YOUR RIG**) brings you back into your
hallway. Those need **E** / **A**. To get back from flying, dock at a
station by flying through its ring, or pause → **Get towed to the truck
stop**. Your money is in the top-right corner.

**Her TV** has a games console, the TATER-16: walk up to it and press
**E** / **A** to play Carrot Catch, Comet Tail or Paddle Pods (arrows or
stick to move, Esc / B to go back or switch it off).

**Your crew.** Raccoony (dispatch), Chang Ma (the engine room) and Clem (the
cargo bay) live aboard, along with the **GALLEY**, **ENGINE** and **CARGO**
doors off the hallway. Every trip and every day they're somewhere new doing
something new, so go find them and talk (**E** / **A**). Now and then
something happens aboard (card night, a lost wrench...); a notice tells
you. If something's lost, find it, pick it up, and take it back to its
owner. Jobs: talk to Raccoony at his counter, or use the **JOB BOARD**
terminal on the dispatch counter. In flight, the apartment window shows
where you're heading.

**Changing the crew's lines (no code).** Everything the crew do and say,
and the ship events, are plain lists in `tools/crew_data/make_crew.py`.
Edit a line, then run `python3 tools/crew_data/make_crew.py` from the
project folder (it rewrites `data/crew/crew.tres`). Lines can use
`{bunny}`, `{husband}`, `{company}`, `{cargo}` and `{place}`.

### Money and time on the road

- **The calendar and clock** sit under your money (and top right while
  flying): the time on the galaxy's clock (GST), the date, and how many
  days until the bills. The year has 365 days in 12 months (Kindling,
  Hearthfrost, Thawing, Wayfare, Blossom, Longlight, Highsun, Haulwind,
  Gleaning, Lantern, Driftfall, Starsleep). Time runs while you play:
  fast while you fly (about 2 days per 10 minutes of driving), gently while
  you walk around, and a whole night when you sleep. The date card shows
  when you load a game and when you wake up. The job board says about how
  many days a job takes on the road (**~2D**).
- **Weekly bills:** every 7 days, OrbitalEx takes its berth and dispatch
  fee (plus insurance, if you bought it). If you can't pay it all, the
  rest goes on a **TAB** (shown in orange). It's paid off from your next
  delivery. No interest, no penalty, nobody comes after you.
- **Insurance** (at Dusty's, the mechanic): a small weekly fee, and
  repairs cost half. Switch it on or off any time.
- **Rig levels:** every delivery earns your rig XP. Each level makes it
  a little faster, punchier, nimbler and longer-legged on fuel. Dusty's
  menu shows your level and how much XP is left to the next one. Some
  parts need a rig of a certain level (they show **LEVEL n** until then).
- **Job tags** on the board: **RUSH** (bonus for being quick), **FRAGILE**,
  **PERISHABLE**, **LIVE** (bonus that shrinks if you bump the cargo), and
  the trip length in days. Your invoices and bills are on the PC.
- **Where your load goes** is always **hot pink**: on the course chart (M)
  it's the pink target with the "YOUR LOAD" flag and the pink route, and
  in flight the waypoint is pink with "LOAD" under it.
- **Which rig you're in:** every rig has the same rooms inside, but each
  has its own soft color cast, and its name shows under the calendar.

### Upgrading your rig (Dusty's garage)

Dusty's parts are on four shelves: **ENGINE & HANDLING**, **HAULING**,
**NAVIGATION** and **CAB EXTRAS**. The number next to a shelf is how many
parts you could fit right now. Some parts need a rig of a certain level, or
another part first. Many show up on the outside of your rig: bumper bars,
a spinning radar dish, chrome horns, a roof light bar, exhaust stacks, a
crate rack and gold solar sails.

- **Docking computer** (Navigation): within 4 km of your load's drop-off
  (or a course you set) it takes the wheel, flies the lane through the
  rocks and the ring and docks you, to its own little waltz while the radio
  fades out. Touch the stick to take over (it won't grab the wheel again on
  that approach).
- **Air horn** (Cab extras): **B** / **L3** in flight. Truckers nearby
  sometimes honk back.

### Heavy loads

Every load has a weight, shown on the job board ("Weighs 450 million
tons") and on the flight HUD under PAY (**LOAD 450M T**). Space trucking
is big. What matters is how heavy it is **for your rig**:
- green: light;
- yellow: heavy;
- red: overloaded.

A heavy load takes longer to get going, much longer to **stop** (start
braking early before a ring), turns slower, swings wider, rocks a little
after a turn, and burns a bit more fuel. It still always goes where the
nose points: no drifting. Bigger rigs at Dusty's are rated for more.
(Numbers: "Load weight" in tuning.tres.)

### Watch mode

Set a course (**M**) and the autopilot drives. While it does, **the game
lets go of your mouse**, so you can leave it up on your screen (zoom out
with the mouse wheel first) and get on with other things on your
computer: it keeps playing in the background, docks itself at the end,
and never needs you. Drag with the left mouse button to look around the
rig. Grab the stick or keys to take the wheel back (the mouse locks to
the window again).

### The debug menu (F10)

For testing without a full run. Press **F10** anywhere:
- **Jump near a place** (Tidewater, the truck stop, the casino, the
  Gas-N-Go). Pick **1, 3 or 5 minutes out**, and the rig appears that far
  out, lined up, on autopilot. From on foot it takes off first.
- **Give me a job:** any job in the game, yours right now (handy for
  testing heavy loads).
- **Skip the opening.**
- **+5,000 credits.**
- **Fill up and fix up.**

To switch it off later (for a release build), untick **debug_menu** in
tuning.tres. From a terminal: `godot --path . -- --jump=tidewater:3`.

### Vending machines

At the truck stop, in your rig's hallway (it works in flight too), in
the Tidewater canteen and in the casino. Walk up, press **E** / **A**, and
pick something. The galaxy's brands (Moon Milk, Zoom Juice, Star-Stop
Ramen, Neon Soda, Galaxy Gumballs...) are the same ones on the radio and
the billboards. Local treats only sell at home: Marge's pie at the truck
stop, canned starfish at Tidewater, Chip Chips at the casino.

- She holds it, eats or drinks it, and says what she thinks. The first time
  she tries a brand, she reads its story off the back of the packet.
- Most snacks just taste of something. Food like jerky, noodles and pie
  gives **steady hands** for the next trip. Zoom Juice and coffee top up
  your **boost tank**.
- The machine counts how many of the galaxy's snacks you've tried.
- All brands and snacks are in `tools/brand_data/make_brands.py`: edit the
  lists and run `python3 tools/brand_data/make_brands.py`.

### The window

- The game starts in a window the first time (1280 x 720). Drag its edges to
  any size or shape you like: the game fills it, with no black bars (a wide
  window shows more to the sides; a taller one shows more above and below).
  It won't go smaller than 640 x 360.
- **Fullscreen:** **F11** or **Alt+Enter**, any time (or the switch in the
  pause menu, or the button on the title screen). It's borderless
  fullscreen, so switching is instant.
- **Menu and HUD size:** small, medium or large (pause menu or title
  screen), for big screens or small windows. Long menus scroll if they
  don't fit.
- All of it is remembered: next time the game starts fullscreen or
  windowed, at the same size and in the same spot, the way you left it.
  (It's all in `user://settings.json`; delete that file to reset.)

### Menus

| What | Keyboard & mouse | Gamepad |
|---|---|---|
| Move around a menu | Arrow keys, or the mouse | D-pad |
| Choose | **E** or **Enter**, or click | **A** |
| Back | **Esc** | **B** |

**Invert Y:** by default, pushing up points the ship's nose up. If you prefer
"pilot style" (push up = nose down), flip *Invert Y* in the pause menu (or on
the boot screen). The pause menu also has *Camera roll*, *Show HUD*, *Screen shake*,
*Gamepad rumble* and the three volume sliders. All of them are remembered between sessions.

You can change any binding in the editor: *Project → Project Settings →
Input Map*.

---

## Tweaking how things feel

Every "feel" number shared by all ships (steering smoothness, camera, field
of view, dust, trails, engine sound...) lives in one file:

1. In the **FileSystem** panel (bottom-left of the editor), open the `data`
   folder and double-click **`tuning.tres`**.
2. Its values appear in the **Inspector** panel (right side). **Hover over a
   value's name** to read what it does in plain English.
3. Change a value, press Play, and feel the difference.
4. Don't like it? Click the small circular **revert arrow** next to the value
   to put it back.

Numbers that belong to one ship (top speed, acceleration, how heavy it turns,
boost) live in that ship's own file: `data/ships/starter_rig.tres`. It works
the same way.

**The PS1 look** has its own group in `tuning.tres`, called *PS1 look*: how
much models wobble, how much textures swim, the number of colors, the dither,
and the distance haze. The game draws at your screen's own resolution (any
window from 800x600 up to 4K). The haze *color* belongs
to each solar system, in `data/systems/home_system.tres`.

**The look (round 14):** the hand-painted textures (walls, floors, hulls,
crates, machinery...) are painted by `tools/paint_textures.gd`; tweak and
re-run it with `godot --headless --path . -s tools/paint_textures.gd`.
Every box also gets painted bevels and shadow automatically
(`shaders/painted_edges.gdshaderinc`). **The bunny** is your 3D model in
`assets/characters/bunny/` (the .obj and its texture), cut into parts and
made chibi by `tools/build_bunny.gd`: the CHIBI numbers at the top of that
file set head size, leg length and so on. Replace the model (same file
names) and re-run it to update her.

**Your rig's rooms** are `scenes/hub/Apartment.tscn`, `Hallway.tscn` and
`Dispatch.tscn`. Open one and look under **Shots**: each shot has a
**Camera** (select it, then tick *Preview* in the 3D view to look through
it) and a **Zone** box (where that camera is used). Move and re-aim them
freely; the backgrounds repaint themselves from the new angle every time
the room loads. What people say lives in `data/npcs/` (Raccoony is
`dispatch_morning.tres`), and the big names (the bunny, her husband, the
base) are in `data/world_names.tres`.

**Traffic ships** around the base and the truck stop are nodes like
*Commuter* and *Orbiter* under *World* in `scenes/flight/FlightSandbox.tscn`.
Select one to change its speed or the list of spots it flies through
(*Waypoints*).

**The road to Tidewater** (signs, landmarks, debris, the speed trap, the
long-haul truckers) is `scenes/flight/TidewaterRoad.tscn`, made by
`tools/build_road.gd` (the road to Glimmer is `GlimmerRoad.tscn`, made by
`tools/build_glimmer_road.gd`): edit the numbers there ("how far along the road,
how far to the side") and run it again. The random sights (big ships,
convoys, billboards...) are in `data/events/route_events.tres`, and how
often they show up is in tuning.tres under "Route events". Bills, how
fast time runs, and rig levels are under "Time and bills" and "Rig
levels"; the month names (and the line about each) are in
`data/calendar.tres`; each rig's interior color is *Interior Tint* in its
file in `data/ships/`; and each part's price and level is in
`data/upgrades/`. Signs get their boards automatically
(`scenes/hub/SignBoards.gd`); to keep one floating, add the metadata
`no_board` = true to its Label3D. Planets and
suns are the *SkyBody* nodes under *World/SkyBodies*; each solar system's
colors are in `data/systems/`.

## Where your settings are saved

Player options (like Invert Y) are saved in `settings.json` in the game's user
data folder. To find it from the editor: *Project → Open User Data Folder*.
Deleting the file resets the options. The boot screen also shows the full path
at the bottom.

---

## If something goes wrong

- **Red text in the Output panel** (bottom of the editor) or the
  *Debugger → Errors* tab: copy it and send it to me. That's exactly what I
  need.
- **"Your video card drivers seem not to support..."**: update your graphics
  drivers. The project uses Godot's *Compatibility* renderer (OpenGL 3.3),
  which runs on nearly any computer from the last ten years.
- **The project won't open or looks broken:** make sure you're on Godot
  **4.7.x** (shown in the Project Manager's corner and on the boot screen).
- **My mouse pointer disappeared:** in flight the mouse looks around the
  rig. Press **Esc** to get it back.
- **Stuttery or slow:** tell me your computer and graphics card (shown at the
  bottom of the boot screen). Nothing here should be demanding.
- When reporting a problem, the bottom lines of the boot screen (Godot
  version, renderer, graphics card) are super helpful to include.

---

## For the curious: the `tools/` folder

You never need these to play or edit the game. They're helpers I use to check
the project without a screen:

- `tools/validate.sh` checks every script, scene and resource for errors and
  runs the self-tests.
- `tools/capture.sh` takes screenshots of the game on a computer with no
  monitor.

See `tools/README.md` for details.
