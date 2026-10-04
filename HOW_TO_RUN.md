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

All the work so far is on the branch **`claude/fervent-albattani-prfaw0`**
(right now it's the only branch, so it's what GitHub shows by default).

- **Recommended: GitHub Desktop** (free, https://desktop.github.com). Sign in,
  then *File → Clone repository*, pick `spacetrucking5050`, and click
  *Clone*. Use the *Current branch* menu at the top to make sure you're on
  `claude/fervent-albattani-prfaw0`. Whenever I push new work, click
  *Fetch origin*, then *Pull origin*, and you're up to date.
- **Quick alternative: download a ZIP.** On the GitHub page, click the green
  **Code** button → **Download ZIP**, then unzip it. (You'd have to
  re-download it after every update, so GitHub Desktop is nicer long-term.)

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

First you'll see the **boot screen**: the title, a lazily tumbling cargo
crate, and an "INPUT CHECK" panel where every control lights up when you press
it. Press **Enter** (or **Start** on a gamepad, or click **PRESS START**) to
wake up in your apartment on the base. The small button below it jumps
straight into the **flight sandbox**. See `PLAYTEST.md` for what to try.

---

## Controls

Gamepad buttons use Xbox names, by position: **A** = bottom button, **B** =
right, **X** = left, **Y** = top. (On PlayStation: A = ✕, B = ○, X = □,
Y = △.)

### Flying

| What | Keyboard & mouse | Gamepad |
|---|---|---|
| Steer left / right | **A** / **D** (or **←** / **→**) | Left stick |
| Nose up / down | **↑** / **↓** | Left stick |
| Steer with the mouse | Move the mouse | — |
| Thrust forward | **W** | **RT** (right trigger) |
| Brake / thrust backward | **S** | **LT** (left trigger) |
| Boost | **Space** | **A** |
| Switch camera (chase / cockpit) | **C** | **Y** |
| Radio: next / previous station | **E** / **Q** | D-pad **right** / **left** |
| Hide / show the HUD | **H** | D-pad **down** |
| HUD demo (lights every warning, for checking the look) | **F9** | — |
| Pause menu | **Esc** | **Start** |

**Your rig has momentum.** Hold thrust to speed up, then let go and you
*coast*: you keep your speed, like cruise control. To slow down, thrust
backward. Turns carve and slide, especially at high speed, so you can
overshoot. The tiny green **flight marker** (a dot with little wings)
shows where your momentum is really carrying you, which isn't always where
the nose points.

**Fuel:** thrusting burns fuel, more at high speed; coasting is free. The
little **ECO** arrow under the fuel gauge turns green, yellow or red to show
how thriftily you're flying. An empty tank never strands you: the engines
keep crawling along "on fumes".

**Boost** rockets you way past top speed (and gets slidey!). It burns
**boost fuel** (the tiny **BST** bar), which doesn't refill by itself. Fly
close to the truck stop to top up both tanks and patch the hull (buying fuel
comes later).

**The HUD** (in the style of Wipeout): speed and boost bottom-left, the
radar globe bottom-middle, fuel and the hull picture bottom-right, the
compass strip with distance and ETA at the top, the radio top-left, cargo
and pay top-right, and warning lights down the left edge. Calls from
dispatch and other truckers pop in at the top-left. The **practice haul**
(garden gnomes for the truck stop diner, a rush job) is delivered when you
fly up to the docking bay; "Back to the start" in the pause menu gives you a
fresh one.

**The mouse while flying:** it's hidden and locked to the game window, and
moving it steers the rig. Press **Esc** to get your mouse pointer back (that
opens the pause menu); click the game window to pick the steering back up.

### Walking around the base

| What | Keyboard & mouse | Gamepad |
|---|---|---|
| Walk | **W A S D** (or arrow keys) | Left stick |
| Talk / use / board the ship | **E** | **A** |
| Pause menu | **Esc** | **Start** |

"Up" always walks away from the camera. Doors take you to the next room
when you walk into them. The ship door at the top of the dispatch stairs
needs **E** / **A**. To get back from flying, pause → **Dock at the base**.

### Menus

| What | Keyboard & mouse | Gamepad |
|---|---|---|
| Move around a menu | Arrow keys, or the mouse | D-pad |
| Choose | **Enter**, or click | **A** |
| Back | **Esc** | **B** |

**Invert Y:** by default, pushing up points the ship's nose up. If you prefer
"pilot style" (push up = nose down), flip *Invert Y* in the pause menu (or on
the boot screen). The pause menu also has *Camera roll*, *Show HUD* and *Screen shake*. All of
them are remembered between sessions.

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

**The base's rooms** are `scenes/hub/Apartment.tscn`, `Hallway.tscn` and
`Dispatch.tscn`. Open one and look under **Shots**: each shot has a
**Camera** (select it, then tick *Preview* in the 3D view to look through
it) and a **Zone** box (where that camera is used). Move and re-aim them
freely; the backgrounds repaint themselves from the new angle every time
the room loads. What people say lives in `data/npcs/` (Dottie is
`dispatch_morning.tres`), and the big names (the bunny, her husband, the
base) are in `data/world_names.tres`.

**Traffic ships** around the truck stop are the *Commuter* and *Orbiter*
nodes in `scenes/flight/FlightSandbox.tscn` (under *PSXView → Viewport →
World*). Select one to change its speed or the list of spots it flies
through (*Waypoints*).

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
- **My mouse pointer disappeared:** that's the flight steering. Press
  **Esc** to get it back.
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
