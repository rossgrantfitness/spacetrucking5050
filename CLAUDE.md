# CLAUDE.md — Space Truckin' 5050

You are the lead (and only) programmer on **Space Truckin' 5050**, a cozy PSX-style space trucking sim built in **Godot 4**. This file is your standing brief. Read it fully at the start of every session, then read `PROGRESS.md` to see where we are. Work through the milestones below in order with as little hand-holding as possible.

---

## 0. Who you're working with (read this first)

- The developer is a **total beginner**: solo, hobbyist, no prior game dev or coding experience. Commercial release is a "maybe someday" goal.
- They will playtest, give feedback on feel, and make creative calls. You do the engineering.
- **Explain like a friendly senior dev talking to a smart newcomer.** When you finish something, tell them in plain language what you built, how to open/run it, and what to try. Avoid jargon or define it in one line.
- **Don't ask permission for routine engineering decisions.** Make a sensible choice, log it in `DECISIONS.md` (one line: what, why), and keep moving. Only stop to ask when a choice is genuinely creative/taste-based or would be expensive to undo.
- **Stop at the end of every milestone** for a playtest. Write the playtest instructions to `PLAYTEST.md` (what to do, what to pay attention to, 3–5 specific questions), summarize in chat, and wait for feedback before starting the next milestone.
- Game feel can't be verified by reading code. When a milestone's success depends on feel, say so honestly and ask the developer to judge it.

---

## 1. The vision in one paragraph

You play a 35-year-old indifferent, stoner-burnout bunny space trucker — an old salt who is tired of this shit — hauling cargo across a surreal, trippy galaxy in the rig she inherited from her late husband. Wake up in your apartment on a big starship base, grab a job from dispatch, load cargo, take off, and cruise through space for a few minutes with drum & bass on the radio. Avoid rocks and traffic, watch weird stuff drift by, dock, get paid, and spend it on rent, fuel, outfits, decor, and ship upgrades. The long goal is to **buy everything** — eventually the delivery company itself. Along the way, the story of her husband quietly surfaces.

**Tone:** cozy, cute, chill. Cowboy Bebop energy: a tired person in a beautiful, absurd universe. References: Cowboy Bebop, Heavy Metal, American/Euro Truck Simulator, Stardew Valley, EVE Online, Star Citizen, Star Fox 64 (camera, arcade controls, cockpit chatter), Rogue Squadron (free flight), Rebel Galaxy Outlaw (radio, space-trucker vibe).

### Design pillars (use these to settle any ambiguity)

1. **Cozy first.** Safety, abundance, softness. Nothing punishing. Failure is a bonk, not a death. Urgency is always opt-in.
2. **Trucking game first and foremost.** The core joy is the drive: cruising, radio, gizmos, getting paid, upgrading. No combat. No weapons. Ever.
3. **Arcade feel, not simulation.** "Airplane in space." The ship goes where it points. Never Newtonian drift.
4. **Strict PSX look, warm not creepy.** Wobbly verts, affine textures, dithering, low-res — but bright, saturated, colorful. The PSX look is strongly associated with horror right now; we deliberately counter that.
5. **Mundane + surreal.** Familiar trucker things (truck stops, billboards, traffic, dispatch, radio ads) make a fully surreal universe feel homey. The cockpit is a cozy pocket of home inside the void.
6. **Economy-driven progression.** Money gates progression. Everything is buyable.

---

## 2. Tech stack & project rules

- **Engine:** Godot 4, latest stable 4.x installed on the machine. Run `godot --version` at the start and adapt to that version. **GDScript only** (no C#) — it's easiest for a beginner to read.
- **Version control:** git. Commit at every working checkpoint with a clear message. If git isn't initialized, initialize it and add a Godot `.gitignore`.
- **Validate before handing off:** after code changes, run Godot headless to import the project and catch script/parse errors (e.g. `godot --headless --path . --quit`, or the equivalent for the installed version). Fix every error and warning you introduced. Never hand over a project that doesn't open.
- **No external asset dependencies to make progress.** Build placeholders from Godot primitives (BoxMesh, CylinderMesh, CSG, SurfaceTool low-poly meshes) and procedurally generated textures/audio. Every model must be **swappable** later for real art (keep visuals in their own child scene, e.g. `ShipVisual.tscn`, separate from logic).
- **Data-driven content.** Jobs, clients, ships, upgrades, solar systems, NPCs, outfits, furniture, radio stations, and dialogue live in data files (Godot `Resource` `.tres` files or JSON under `res://data/`), not hardcoded in scripts. Adding a new client should mean adding a data file, not writing code.
- **One tuning home.** Every feel-related number (speeds, turn rates, camera lag, FOV, shake, pay rates, fuel burn, flight duration) lives in a single tuning resource (`res://data/tuning.tres` backed by `Tuning.gd`) so the developer can tweak values in the Godot inspector without touching code. Comment each value in plain English.
- **Saves:** JSON in `user://`. Version the save format.
- **Input:** support both keyboard+mouse and gamepad from day one via the Input Map. Include an invert-Y option (some players feel "stick up = nose down" like a real pilot; others want the opposite).
- **Keep it simple.** Prefer readable code over clever code. Small scripts, clear names, comments explaining *why*. The developer will read this code to learn.

### Suggested structure (adjust if you have a good reason, and log it)

```
res://
  autoload/      GameState.gd, Economy.gd, TimeOfDay.gd, Radio.gd,
                 Dialogue.gd, SaveSystem.gd, Events.gd (signal bus)
  data/          tuning.tres, jobs/, clients/, ships/, upgrades/,
                 systems/, npcs/, outfits/, furniture/, radio/, dialogue/
  scenes/
    hub/         Apartment, Hallway, Dispatch, Hangar, Player (on-foot)
    flight/      Ship, ChaseCamera, CockpitView, SpaceDust, Route,
                 Station, DockingRing, events/, hazards/
    ui/          JobBoard, RouteMap, Shop, Garage, Wardrobe, HUD,
                 CommPortrait, Options, PauseMenu
  shaders/       psx_surface.gdshader, psx_post.gdshader
  audio/         generated/, radio/
  tools/         Python or GDScript helpers that generate placeholder assets
```

Docs you maintain at the project root: `PROGRESS.md` (milestone checklist + current status), `DECISIONS.md` (log), `PLAYTEST.md` (current playtest), `HOW_TO_RUN.md` (beginner instructions: open the project, press play, controls).

---

## 3. Characters & world

### The protagonist
- Anthropomorphic **bunny**, 35, anime-furry style with **chibi proportions**.
- Personality: indifferent, stoner burnout, old salt, dry and tired. Steady — she doesn't have a big arc. The world changes around her.
- Backstory (revealed slowly, never front-loaded): her husband was a space trucker who was killed. She inherited his rig; it's her only way to make a living. The player learns this gradually through ship logs, a client who knew him, a voicemail found after an upgrade, etc.
- **Customizable:** hat, jacket, boots, and one accessory (e.g. a cigarette, a stalk of wheat, a can of neon soda). Use generic/invented brands only — no real trademarks.

### Dialogue & voice
- Readable English text in RPG dialogue boxes.
- "Voice" is **Animal Crossing–style gibberish**: short pitched blips played per character as text types out. Each character has their own base pitch and variation. Generate blip sounds procedurally (AudioStreamGenerator or a script that writes small .wav files to `res://audio/generated/`).

### The starship base (hub)
- Home to ~250 animals; the player only meets 5–10 of them.
- Locations: **her apartment → hallway → dispatch (delivery station) → hangar.** Each room has at least one NPC with personality.
- **Dispatch has a different employee per shift** (morning / evening / night), each with their own personality and lines. She can also radio dispatch from the ship.

### Clients & solar systems
- 5–8 recurring clients, each in a different solar system, each with little storylines across multiple jobs.
- Each system has: **one signature color** (used for nebula fog/haze and lighting), **one gimmick**, **one client**. Starter examples (edit freely in data):
  - **Magenta casino system** — neon billboards everywhere; client: a sleazy casino owner.
  - **Teal ocean-planet system** — floating space whales; client: a sleepy fisherman.
  - **Amber desert system** — dust storms and old derelicts; client: TBD.
- The universe is **fully surreal**: cosmic jellyfish migrations, giant ships, weird billboards, derelicts, strange signals. Mysteries and lore are discovered passively (logs, signals, things you fly past).
- The year 5050 has no special significance. Don't invent lore that makes it significant.

### Open creative decisions (use these defaults; never block on them)
| Decision | Default until the developer decides |
|---|---|
| Protagonist name | `[BUNNY_NAME]` placeholder string in one data file |
| Husband's name | `[HUSBAND_NAME]` placeholder |
| Base/station name | `[BASE_NAME]` placeholder |
| Currency name | "credits" |
| Ship names | invent playful placeholders, keep in data |

Keep all names in data so they can be changed in one place.

---

## 4. Gameplay loop 1 — The hub (third person, on foot)

- Third-person low-poly character controller (CharacterBody3D).
- **Fixed camera angles, Final Fantasy VIII style** — no free-roaming camera in the hub. Each room has one or more hand-placed cameras composed like a painting. When the player walks into a trigger zone, the view cuts (or does a short, gentle pan) to that zone's camera. This is authentic to the era, avoids the camera clipping through walls in small rooms, and means we only build and dress what each camera can see.
  - Movement must be camera-relative and must not flip the instant the camera cuts: keep using the previous camera's orientation for movement until the player releases or substantially changes the stick input.
  - Store each camera and its trigger zone in the room scene so the developer can move and re-aim cameras in the Godot editor.
  - Camera angles are a composition tool: frame the rabbit small against big, glowing environments, and put the cozy details (neon signs, clutter, a window onto space) in every shot.
- Interact prompt when near objects/NPCs.
- **Apartment:** bed (sleep → advance to next day), wardrobe (outfits), furniture/decor placement (simple grid or slot-based), a terminal for jobs/news.
- **Hallway:** neighbor NPCs, ambient life.
- **Dispatch:** job board, talk to clients/shift employee to accept jobs.
- **Hangar:** inspect ship, buy upgrades, repairs (menu-based), refuel, insurance, view ship level, **cargo loading** (forklift minigame — later milestone; auto-load until then), take off.
- Jobs can be accepted three ways: job board, talking to an NPC, or radio/terminal.

## 5. Gameplay loop 2 — Space Truckin' (flight)

### Mission shape
- Fly from the base to a destination station in another system, dock, get paid, fly home (or chain another job).
- Target real-time flight length: **5–10 minutes** per leg in the final game. During development, keep this a tuning value and default it short (~2 minutes) so testing is fast.
- What the player does: steer, avoid rocks and traffic, play with the radio, fiddle with cockpit gizmos, look at stuff. Chill like Euro Truck Simulator.
- **Route map:** a "Google Maps for space" screen before launch showing route options (e.g. fast-but-risky vs. safe-but-long), distance, fuel estimate, hazards along the way.

### Skill & mild tension (all gentle)
- The skill is **efficiency, not combat**: avoid damage, save fuel. Flying faster burns more fuel.
- **Collisions** = a cartoon "bonk," small shake, slight cargo-condition drop. Never death or explosion.
- **Job tiers:**
  - *Standard:* no timer, normal pay.
  - *Rush:* bonus for beating a target time; still base pay if late. Never fail.
  - *Fragile/perishable/live cargo:* bonus that shrinks with damage taken.
- **Hazards (pick from these; add more in data):** traffic lanes near stations (slow ships to weave around); gravity wells near planets (pull you off course, but can be used to slingshot for free speed); solar storms (radio static + screen glitch); space cops who fine you for speeding in station zones (a speed trap, not a fight); cosmic jellyfish migrations you drift through slowly.
- **Random events / sights:** asteroids, space junk, moons, billboards, other ships passing, a BIG ship passing (huge Doppler moment), derelict spacecraft. Spawn these along the route at tunable rates; most are pure scenery.

### Docking
- Early game: fly into a glowing **approach ring**, then autopilot takes over with a short canned docking sequence.
- **Docking computer upgrade** (buyable): handles docking from farther out and plays its own lounge/waltz-style track (a homage to Elite's "Blue Danube" docking computer).
- Later, optional: a manual "pro docking" mode for players who want the skill.

---

## 6. Game feel spec (the most important section)

Game feel here has an unusual job: **make calm feel good**, not make action feel powerful. Implement these, expose every number in `tuning.tres`, and start from the suggested values.

### Flight model — arcade "airplane in space"
- The ship moves in the direction its nose points. Throttle sets target speed; the ship eases toward it (no instant stops, no endless drift).
- **Banks into turns** visually (roll the visual mesh proportional to yaw input) and **auto-levels** when input is released.
- Speed cap per ship. Use a kinematic approach (Node3D/CharacterBody3D with your own movement code) rather than RigidBody physics — it's easier to tune and keeps the feel arcadey.
- Light input smoothing and a sensible gamepad deadzone so steering feels buttery, not twitchy.
- **Each ship has its own personality:** mass/turn rate/acceleration/max speed per ship data file. The starter rig should feel heavy and lazy; upgraded/faster ships feel zippy. **Cargo weight reduces turn rate and acceleration slightly.** Upgrades must be *felt*, not just seen as numbers.
- Boost: optional short burst, costs extra fuel.
- **Developer decision from the M1 playtest (2026-10-03):** flight should have real momentum: inertia, coasting, braking by thrusting the opposite way, and easy overshooting, with a boost that truly rockets you and can get away from you if you're not on the controls. FUN and CHILL over everything. This deliberately relaxes "never Newtonian drift" and "short burst": a tunable **grip** keeps the ship's path gradually swinging back to its nose (so it never becomes a pure physics sim), a whisper of coast drag means nothing drifts forever, and boost burns its own **boost fuel** that you buy and store (limited tank), instead of a short recharging burst.

### Sense of speed (build this right after basic flight)
- **Space dust** is the #1 speed cue — empty space gives no reference. Surround the ship with a field of small particles that rush past proportional to speed and wrap/recycle around the ship (MultiMeshInstance3D or GPUParticles3D). Nearer dust moves faster across the screen than farther dust. Tint dust to the current system's color.
- **Speed-scaled FOV:** start from a base FOV (~70°); widen by up to ~8° once speed passes ~70% of max; lerp smoothly (~4.0 lerp speed). Subtle.
- **Speed lines only during boost**, not tied to raw speed (otherwise they're always on at max speed and stop meaning anything).
- Spawn scenery (rocks, billboards, debris) passing **close** to the ship; nearby objects sell speed better than effects.

### Camera
- **Chase cam** behind and slightly above the ship, with spring/lag smoothing so the ship visibly leads the camera in turns and when boosting (camera pulls back a little on boost).
- **Keep the horizon level by default** — the ship banks, the camera does not roll. Rolling camera is an *option*. A rolling chase cam makes players lose orientation and can cause motion sickness; this game is meant to be played for hours.
- **Cockpit view** toggle. The fixed cockpit frame doubles as a motion-sickness stabilizer.

### Screen shake
- Trauma-based shake (from Squirrel Eiserloh's GDC talk "Juicing Your Cameras With Math"): a `trauma` value 0–1 that decays over time; shake amount = trauma²; offsets/rotation driven by smooth noise (FastNoiseLite), never pure random.
- Use only for bonks, boost kick-in, and jumping between systems. Keep max amounts small. Option to turn it off.

### Audio feel
- **Engine hum:** layered loops whose pitch and volume follow throttle/speed (procedurally generated placeholder via AudioStreamGenerator is fine). Tiny pitch wobble when turning.
- **Doppler whoosh** when ships pass by — the big-ship flyby lives or dies on this sound.
- Interior cockpit ambience: soft hums, clicks, switch sounds for every gizmo.
- **Controller rumble:** a faint engine purr while flying, a thump on bonks. Optional.

### Cockpit gizmos (diegetic UI)
- Fuel, speed, cargo condition, and the radio dial live **in the cockpit** as physical-feeling instruments. Make them fiddly and satisfying: switches click, dials turn, lights blink.
- Pure-vibe toys: bobblehead, dangling air freshener, lighter, cup holder. They react to turning and bumps.
- **Cockpit look** (reference: hazard-striped PS1 cockpit): chunky yellow-and-black hazard-striped struts frame the window like a truck cab. Instruments are glowing monochrome screens (green by default; tintable per ship). Include a wireframe radar globe showing nearby ships and rocks.
- **Ship ID labels:** passing ships get a small target label with a mundane, funny name ("NAVY LEISURE BARGE", "Municipal Waste Hauler", "Retiree Cruise Liner", "Discount Mattress Freighter"). Store names in a data list and write lots of them; this is a cheap, constant source of humor and world-building.
- **HUD (chase cam):** minimal, tucked into the corners, using gradient arc gauges (fuel, speed, cargo condition). Never clutter the screen with lists, panels, or combat-style readouts. Provide a toggle to hide it.

### Comms / cockpit chatter
- Star Fox 64–style comm portrait: small character portrait that pops in with mouth flaps, text box, gibberish voice blips.
- **A short burst of radio static before and after each message.**
- Who talks: dispatch (shift employee), other truckers, station traffic control, clients. Lines come from data with conditions (time of day, system, recent events). Repetition is OK if lines have character.

### The radio (GTA-style)
- Multiple stations, each with a genre/identity: drum & bass, jungle, Toonami-style electronica, chill/lo-fi, etc. Each can have a DJ and **fake ads for surreal products** (these are cheap to write and do huge world-building work).
- **Custom station:** the game reads music files the player drops into a folder in `user://` (e.g. `user://radio/custom/`; support .ogg and .mp3). Write clear instructions for players.
- When the radio is off, play gentle adaptive ambient music.
- Solar storms add static/dropout to the radio.
- **No Spotify integration.** It isn't practical here (Premium-only, restrictive developer terms). Don't attempt it.
- Placeholder music: until the developer adds licensed/royalty-free/commissioned tracks, ship each station with a clearly labeled placeholder (generated tones or silence + DJ text). Keep a `res://audio/radio/README.md` explaining how to add tracks and the licensing reminder.

### Comfort & options
- Invert Y, camera roll on/off, shake on/off/amount, FOV, rumble on/off, HUD on/off, volume sliders (music, SFX, voice blips, radio).

---

## 7. Art direction — strict PSX

- **Low-poly everything.** Chibi anthro anime characters; chunky ships; simple stations.
- **Surface shader** (`psx_surface.gdshader`) applied to everything 3D:
  - **Vertex snapping/wobble:** snap clip-space vertex positions to a low-resolution grid (tunable).
  - **Affine texture warping:** emulate PS1-style non-perspective-correct UVs (common approach: multiply UVs by clip-space w in the vertex stage and divide in the fragment stage; verify against the installed Godot version's shading language).
  - Nearest-neighbor texture filtering, small textures (64×64 / 128×128), per-vertex or flat lighting.
- **Post-process** (`psx_post.gdshader`): reduced color depth + ordered dithering.
- **Low internal resolution:** render the 3D world into a low-res SubViewport (e.g. ~480×270 for 16:9; tunable) scaled up with nearest filtering. Render UI/text at a readable resolution so dialogue stays legible.
- **Distance fog tinted per solar system** (pink, teal, amber…). It hides pop-in, sets the mood, and is how the player knows where they are. Fog/haze color comes from the system's data file.
- **Bright, saturated, warm palette.** Avoid the gray/brown horror look.
- Placeholder textures can be generated procedurally (noise, stripes, checkers) at tiny sizes.

### Visual references (the developer's mood board)

The developer may put the actual reference images in `reference/` at the project root. If that folder exists, look at the images before doing art or UI work.

| Reference | What to take from it |
|---|---|
| Hazard-striped PS1 cockpit with a planet filling the window | Cockpit framing, monochrome green instruments, wireframe radar globe, funny ship ID labels. |
| PS1 chase-cam shot past a huge capital ship | The big-ship flyby: huge ships built from cheap flat-textured slabs that read as massive because they fill the screen and pass close. Pure black space, crisp white stars, oversized swirly planets. Minimal corner HUD with gradient arcs. |
| Freelancer asteroid field | Dense fields of chunky tumbling low-poly rocks; colorful engine trails behind every ship (a speed cue and a sense of traffic). Do not copy its cluttered combat HUD. |
| Neon low-poly station interior | The hub look: dark blue-gray walls and floors lit by glowing neon panels in green, purple, orange, and cyan; cluttered industrial props (crates, tanks, consoles, barrels). Cozy late-night truck stop, never horror. |
| Final Fantasy VIII's Ragnarok cockpit | Fixed cinematic camera angles for interiors (see section 4), and the ship as a lived-in place where characters hang out. |

### Palette

- **Space:** pure black to deep navy, crisp white star points, oversized planets with bold swirly cloud textures.
- **Accents:** hazard yellow, red, cyan, neon green, neon purple, warm orange.
- **Per-system tint:** each solar system's fog/haze color layers over everything as that region's signature (pink, teal, amber…).
- **Hub interiors:** dark cool base colors + saturated emissive accents. Darkness is fine as long as it's warmly lit.

### Faking neon glow in PSX style

- The PS1 had no real-time bloom. Get the neon-interior look with unlit emissive textures (panels, screens, signs) and vertex colors baked for colored light spill on nearby surfaces.
- An optional, subtle bloom/glow pass is allowed as a deliberate rule-bend for the neon look. Put it behind an on/off setting (default on), keep it soft, and apply it before the low-res and dither pass so it still looks crunchy. Log the final choice in `DECISIONS.md`.

### Engine trails

- Every ship (player and traffic) leaves a short, colorful, fading ribbon/particle trail from its engines. Trail length and brightness scale with speed. The player's trail color can be customized later (M7).

---

## 8. Economy, time & progression

- **Spend money on:** fuel, maintenance/repairs, insurance, weekly rent, apartment furniture & decor, outfits, ship upgrades, new ships, a bigger apartment, and eventually **buying the delivery company**.
- **Earn money from:** deliveries (base pay + optional rush/condition bonuses). Prices are fixed contracts at first; a fluctuating market is a stretch goal.
- **Ship leveling:** ships gain XP from deliveries and level up like RPG characters (small stat boosts, unlock upgrade slots). Upgrades: speed, cargo capacity, handling, fuel efficiency, hull, docking computer, cosmetics.
- **Time:** the base runs on three shifts (morning / evening / night). Each flight consumes one shift. Sleeping starts a new day. Rent is due weekly. A gentle rhythm, never a stressful clock.
- **End goal:** "buy everything" — show a Stardew-style **completion percentage**. Story + sandbox: once the husband's story is fully revealed, the sandbox continues.
- Balance targets (starting points; log changes in `DECISIONS.md`): a standard delivery pays enough that rent takes a few deliveries per week; the first speed upgrade is affordable after roughly 3–4 deliveries; buying the company should take many hours. Put all prices and pay rates in data.

---

## 9. Milestones

Work strictly in order. Don't build later-milestone features early. Each milestone ends with: headless validation passing, a git commit, `PROGRESS.md` updated, `PLAYTEST.md` written, and a stop for developer feedback.

### M0 — Setup
- Detect Godot version; create the project, folder structure, autoload stubs, input map (KB+M and gamepad), tuning resource, git repo, `HOW_TO_RUN.md`.
- **Done when:** the project opens and runs an empty scene; the developer knows how to open it and press Play.

### M1 — Flight sandbox ("find the heart")
- Arcade flight model with banking and auto-level, throttle, boost.
- Level-horizon chase cam with lag; cockpit view toggle (placeholder hazard-striped cockpit frame is fine).
- Space dust, speed-scaled FOV, boost speed lines, engine trail.
- Procedural engine hum tied to speed.
- An asteroid field and a distant station to fly toward.
- **Done when:** flying around feels smooth and relaxing. Playtest question: *"With music playing in another app, is it pleasant to just fly around for five minutes?"* If not, iterate on tuning before moving on — this is the heart of the game.

### M2 — The delivery loop (vertical slice of the core)
- Simple job menu → route → fly from base to a destination station → approach ring → auto-dock → payout screen → fly back → buy one speed upgrade that is **noticeably felt**.
- Fuel consumption tied to speed; bonk collisions with cargo-condition drop; basic save/load.
- **Done when:** the developer can complete a delivery, get paid, buy the speed upgrade, and feel the difference.

### M3 — The walkable hub
- Apartment, hallway, dispatch, hangar as connected low-poly rooms, dressed in the neon-interior style.
- On-foot controller with fixed FF8-style camera angles and trigger zones per room; camera-relative movement that doesn't flip on camera cuts; interact prompts.
- Dialogue system with typewriter text and gibberish voice blips; one NPC per room; dispatch shift employee.
- Accept jobs at dispatch; take off from the hangar (transition into flight); land back into the hangar.
- **Done when:** this full loop works: wake up in apartment → walk down hall → talk to dispatch → take job → get in ship → fly → deliver → get paid → fly back → upgrade speed. (This was the developer's own definition of the smallest version of the game.)

### M4 — PSX look + the radio
- PSX surface shader, post-process dither/color depth, low-res SubViewport, per-system fog.
- Apply the palette and visual references from section 7: oversized planets, black space, neon emissive hub lighting, optional soft glow pass, cockpit monochrome instruments and radar globe, corner arc HUD.
- Radio with multiple stations, tuning static, placeholder DJs/ads, custom-station folder, ambient music when off.
- **Done when:** screenshots read instantly as "PS1 game" but bright and cozy; switching stations feels satisfying.

### M5 — Life in space
- Comm portraits + radio static bursts; chatter from dispatch/truckers/traffic control.
- Random events & sights along routes (traffic, big-ship flyby with Doppler, billboards, derelicts, junk, jellyfish), with funny ship ID labels on passing traffic.
- Hazards: traffic lanes, gravity wells (with slingshot), solar storms, speed-trap cops.
- Cockpit gizmos and toys; trauma screen shake; rumble.
- Route map with route choices.

### M6 — Economy & time
- Three shifts, sleep, weekly rent, fuel purchases, repairs, insurance.
- Job tiers (standard / rush / fragile-perishable) with bonuses.
- Ship XP and levels; multiple upgrades; save/load of everything.

### M7 — Home & style
- Wardrobe (hat, jacket, boots, accessory), furniture/decor placement, buyable bigger apartment.
- New ships to buy, each with distinct handling.
- Docking computer upgrade with its lounge track.
- Cargo loading forklift minigame.

### M8 — Story & clients
- 5–8 clients across 5–8 systems with multi-job storylines (data-driven).
- The husband's story revealed through logs, a client who knew him, a voicemail, etc. Quiet and gentle, never melodramatic.
- Passive mysteries/lore.

### M9 — Endgame & completion
- Buying the delivery company; completion percentage; post-story sandbox.

### M10 — Polish & ship
- Options/accessibility menu complete, main menu, pause menu, credits, controller glyphs, export presets, performance pass, bug bash.

---

## 10. Hard "don'ts"

- No combat, weapons, enemies, or death.
- No pure Newtonian drift flight model. (Momentum with grip is in, per the developer's M1 playtest; see section 6.)
- No camera roll by default.
- No Spotify or other streaming-service integration.
- No real-world trademarks (brands, logos) and no copyrighted characters, music, or lyrics. All music must be original, royalty-free, or properly licensed by the developer.
- No punishing timers, failure states, daily-login pressure, or anything that makes the game feel like a chore.
- Don't silently expand scope. If you think a feature would help, propose it in chat and log it as a "Later idea" in `PROGRESS.md`.

---

## 11. How to start each session

1. Read this file, then `PROGRESS.md` and the latest `PLAYTEST.md` feedback (if any).
2. State in two or three sentences what milestone you're on and what you'll do this session.
3. Work autonomously until the milestone (or a clearly scoped chunk of it) is done and validated.
4. Commit, update docs, write the playtest, and stop with a friendly plain-language summary.

If this is the very first session: start **M0**.
