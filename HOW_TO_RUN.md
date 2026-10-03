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

Right now (Milestone 0) you'll see the **boot screen**: the title, a lazily
tumbling cargo crate, and an "INPUT CHECK" panel where every control lights up
when you press it. See `PLAYTEST.md` for what to try.

---

## Controls

Gamepad buttons use Xbox names, by position: **A** = bottom button, **B** =
right, **X** = left, **Y** = top. (On PlayStation: A = ✕, B = ○, X = □,
Y = △.)

### Flying (from Milestone 1)

| What | Keyboard & mouse | Gamepad |
|---|---|---|
| Steer left / right | **A** / **D** (or **←** / **→**) | Left stick |
| Nose up / down | **↑** / **↓** | Left stick |
| Steer with the mouse | Move the mouse | — |
| Throttle up / down | **W** / **S** | **RT** / **LT** (triggers) |
| Boost | **Space** | **A** |
| Switch camera (chase / cockpit) | **C** | **Y** |
| Look around | — | Right stick |

### Walking around the base (from Milestone 3)

| What | Keyboard & mouse | Gamepad |
|---|---|---|
| Walk | **W A S D** (or arrow keys) | Left stick |
| Talk / use | **E** | **A** |

### Anywhere

| What | Keyboard & mouse | Gamepad |
|---|---|---|
| Pause | **Esc** | **Start** |
| Menus | Arrow keys, **Enter**, **Esc** | D-pad, **A**, **B** |

**Invert Y:** by default, pushing up points the ship's nose up. If you prefer
"pilot style" (push up = nose down), flip the *Invert Y* switch on the boot
screen. It's remembered between sessions.

You can change any binding in the editor: *Project → Project Settings →
Input Map*.

---

## Tweaking how things feel

Every "feel" number (steering smoothness, deadzones, later speeds, camera,
FOV...) lives in one file:

1. In the **FileSystem** panel (bottom-left of the editor), open the `data`
   folder and double-click **`tuning.tres`**.
2. Its values appear in the **Inspector** panel (right side). **Hover over a
   value's name** to read what it does in plain English.
3. Change a value, press Play, and feel the difference.
4. Don't like it? Click the small circular **revert arrow** next to the value
   to put it back.

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
