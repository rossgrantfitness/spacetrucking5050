# Progress

**Current status:** **Beta step 4, done: three more systems.**
- **The Dustbowl** (amber, far below the lane): Mags the goat's salvage yard.
- **Greenhouse Reach** (green, far above): Dr. Moss the tortoise's arboretum.
- **The Frostline** (lavender, the top of the map): Penny the penguin's creamery.
- Each has a client with a three-job story, a road with its own weather and
  landmarks, and a walk-around room. Each one is farther, steeper and stormier.

(Before that: your notes on crashes, the office, the boss's missions and the mouse.)
Built and validated, **waiting for your playtest** (see `PLAYTEST.md`).
**Art and sound to make for beta:** see `ASSETS.md` (a tiered checklist
plus tips for your sketch → AI → Meshy pipeline).
**Waiting for your go:** the remaining cards in `SYSTEMS_PLAN.md` (maintenance,
volatile cargo, contraband, multi-leg contracts, manual docking, the
spacewalk). Nothing is built until you pick.
**Next session:** your feedback on the new systems; then beta step 5, the
economy balance pass.
**Engine:** Godot 4.7.2 (GDScript), Compatibility renderer.
**Last updated:** 2026-10-07 (beta step 4: three more systems)

---

## Milestones

- [x] **M0: Setup** *(built; its playtest questions carried into M1's)*
  - [x] Detected Godot 4.7.2 (latest stable) and created the project
  - [x] Folder structure, autoload stubs, input map (keyboard+mouse and gamepad), Invert Y option
  - [x] Tuning resource (`data/tuning.tres`), boot screen with a live input check
  - [x] Headless validation (`tools/validate.sh`), self-tests, cloud-session Godot install
- [x] **M1: Flight sandbox ("find the heart")** *(round 1: "totally pleasant"; round 2: momentum and boost approved; round 3: "too early-3D"; round 4 waiting for playtest)*
  - [x] Arcade flight (round 1, since replaced by momentum below): throttle lever, banking that auto-levels, gentle nose auto-level, recharging boost
  - [x] Starter rig's personality in data (`data/ships/starter_rig.tres`): heavy and lazy
  - [x] Level-horizon chase cam with turn lag and boost pull-back; camera roll as an option
  - [x] Cockpit view with a placeholder hazard-striped frame and a green dash screen
  - [x] Space dust (endless, streaks with speed, tinted by the system color), speed FOV, boost-only speed lines, engine trails
  - [x] Engine hum: four layered loops whose pitch and volume follow speed, wobble in turns, growl on boost
  - [x] An asteroid field of tumbling low-poly rocks (with collision) and a distant truck-stop station
  - [x] Minimal corner HUD (speed gauge, station marker, mouse reticle), small pause menu, "Press Start" on the boot screen
  - [x] Self-tests for the flight rules, sound loops and rock meshes; an autopilot smoke test of the sandbox
  - [x] Round 9 (your request): a throttle lever that holds a speed, heavier turning, more sense of speed at cruise (spaceway beacons, more dust, near motes, wider view, road-feel rumble), boost that spools up, needs full throttle and burns at least 3 seconds
  - [x] Round 8 (your request): less dither (wobble kept); boost wanders off course and jerky steering makes it worse; cruising on the limiter sips fuel; a 6-minute boost tank
  - [x] Round 7 (your request): more wobble and dither (240-row wobble grid, more texture swim, 26 shades per color, stronger, chunkier dither, softer painted rooms)
  - [x] Round 6 (your HUD list): a Wipeout-style HUD drawn at low resolution with a tiny pixel font: speed bar with redline and throttle tick, boost bar, wireframe radar globe, fuel arc with economy arrow, hull picture that flashes where you bonked, compass strip with distance and ETA, radio ticker, cargo and pay, flight marker, five status lights, and pop-ins (comm calls, docking brackets, rush timer, ship ID labels, jump charge). Comm chatter from dispatch, truck stop control and two truckers. H hides the HUD, F9 is a demo of every warning
  - [x] Round 5 (from your feedback): more wobble and dither, ship damage (bonks, hull bar, sparks, smoke, rumble), a lived-in reactive 3D cockpit, and a CC0 courier ship
  - [x] Round 4 (from your feedback): late-PS1 look at native resolution (800x600 to 4K) with subtle wobble, mipmapped crisp textures, Wipeout/Colony Wars HUD with a pixel font, engine flares, nebula sky, and the rig rebuilt as a cargo hauler with eight containers
  - [x] Round 3 (from your feedback): the PS1 look (low-res, wobbly verts, swimming textures, 15-bit dithered color, per-system haze), a new BB 42-style rig, an oversized ringed planet, two traffic ships around the truck stop, and a parking deck with six parked trucks
  - [x] Round 2 (from your feedback): momentum (thrust, coast, reverse-thrust brake, carving turns with tunable grip, overshooting), rocket boost on a boost-fuel tank (top up at the truck stop for now), boost screen shake with an on/off switch, a drift marker on the HUD, and an engine hum that reacts to thrust, slides and boost
- [ ] **M2: The delivery loop** *(nearly all in, pulled forward in round 7)*
  - [x] Jobs in data with care and rush bonuses, job boards at both places, one job at a time
  - [x] Approach rings and the canned autopilot docking
  - [x] Getting paid on docking, with a payout card; money that's spent on fuel, repairs and upgrades
  - [x] Speed upgrade you can feel (Hot-Rod Injectors, +25% top speed), plus three more upgrades
  - [x] Fuel that burns faster at speed; bonks knock cargo condition; rough flying (hard turns, slides, braking, boost vibration) slowly damages cargo, shown on a RIDE bar (round 8)
  - [x] Round 8: the first mission is a long haul to Tidewater Cannery (59 km past the truck stop); drop-off docking (stay in the cab: get paid, take a load back, fuel up); four Tidewater jobs
  - [x] Saving and loading (`user://save.json`), Continue and New game on the boot screen
  - [x] Round 9: cargo damage you can read (thumps, rattle, jolt, the hold flashing, HARD TURN / BRAKING / BOOST SHAKE), one comment per trip; Tidewater is walkable (the cannery canteen and Gill)
  - [x] A route screen: the course chart (M) with distances, cruise and boost times, fuel, and "via" stops, plus a cruise autopilot (round 8)
  - [ ] Your playtest: can you finish a delivery, get paid, buy the upgrade and feel it?
- [ ] **M3: The walkable hub** *(started early, at your request)*
  - [x] Pre-rendered backgrounds with fixed FF8-style cameras and camera zones; camera-relative walking that doesn't flip on cuts
  - [x] Round 13: the camera always finds the bunny (arrival spots fixed, plus a switch to a camera that can see her if she's ever hidden)
  - [x] Round 14: home is the inside of the rig (apartment, hallway with the airlock, dispatch with Dottie and the cockpit stairs); walkable in flight; the old base is the company HQ (scenery)
  - [x] Round 14: the bunny is the developer's 3D model, cut into parts on the animator's joints and made chibi (2.5 heads tall)
  - [x] Round 15: the crew (Dottie, Digby, Clem) from your models; galley, engine room and cargo bay; life aboard that changes every trip and day (activities, ship events, lost things, friendship); a job terminal in dispatch
  - [x] Round 15: the apartment window shows what's outside, live, in flight
  - [x] Round 16: walk away (or Esc / B) to leave a conversation; voices in their own pitch, key and scale
  - [x] Round 17: doors under the camera take you through when you walk out of view toward them; the bed always works; the TATER-16 games console on her TV (three games)
  - [x] Round 14: her desktop PC (mail, invoices, Asteroid Alley); the bed sleeps to a new day (parked) or to the next stop (in flight)
  - [x] The chibi bunny on foot (walk, ear flop, blinks, blob shadow)
  - [x] Apartment, hallway and dispatch (from your sketch), connected by doors with fades
  - [x] Dialogue boxes with typewriter text and voice blips; Dottie the morning clerk; interact prompts
  - [x] Board the ship at the top of the dispatch stairs; "Dock at the base" from flight
  - [x] Taking jobs at dispatch (Dottie opens the job board after the first mission)
  - [x] The truck stop inside (round 7): a big concourse with Marge's diner, a job board, Dusty's garage, Lily's pumps, an arcade lounge, shuttered "coming soon" shops and the airlock; five people; things to use and look at
  - [x] The first mission: Dottie sends you to Marge, who offers her pie run; story flags and conditional conversations in data
  - [x] Round 9: run on foot (Shift / X); the apartment is the rig's sleeper cabin, walkable in flight while the autopilot drives, with a nap that fast-forwards the trip; people remember (Marge and Gill about the pies, Moe finishing his sentence); Jack Rabbit's name
  - [ ] The hangar at the base (inspect the rig; fuel, repairs and upgrades are at the truck stop for now), a hallway neighbor, evening and night clerks
  - [ ] The bunny rebuilt to `CHARACTER_BIBLE.md` (segmented parts, face sheet, lop ears and cap, vest, boots)
- [ ] **M4: PSX look + the radio** *(much of it pulled forward)*
  - [x] PSX shaders, dither, per-system haze, nebula, oversized planet, the low-res Wipeout HUD with its radar globe
  - [x] The radio plays real music from each station's folder, GTA-style (stations keep playing while you're away), with audio or text ads, tuning static, on/off with ambient music, weak-signal hiss, a radio volume slider, and MY TUNES for the player's own files; the truck stop's jukebox
  - [x] Placeholder beats per station until you add music; `audio/radio/README.md`
  - [x] Round 9: your 20-station lineup (DJs, slogans, ads, invented songs, placeholder loops per genre), DJs reacting to storms, tickets, new systems and deliveries, a regional station, a pirate station, a night-only station and a hidden numbers station
  - [x] Round 14: Mega Man Legends-style hand-painted textures and painted bevels on every box; calmer late-90s wobble
  - [x] Round 14: HOSHIZORA 83, the Japanese station, playing your first three tracks
  - [ ] Your music for the other stations, DJ voices
  - [ ] Glow pass, 3D cockpit radar globe, neon hub lighting polish
- [ ] **M5: Life in space** *(much of it pulled forward)*
  - [x] Comm calls with static and placeholder portraits; chatter from dispatch, truckers, traffic control, hosts and the space patrol; funny ship ID labels; screen shake
  - [x] Random sights along the road (round 8): big ship crossings with a Doppler rumble, convoys, billboards, comets, jellyfish, junk, derelicts, a rubber duck; whales and ion storms in Tidewater
  - [x] Fixed sights on the road to Tidewater (round 8): highway signs, a junk spill, the world's biggest donut, a border gate, a lighthouse, a derelict, an icy field, whales, long-haul traffic
  - [x] Hazards (round 8): ion storms (static, jolts, STORM light) and a speed trap (COPS light, small fine)
  - [x] An optional stop: the Gas-N-Go 47 drive-through (round 9: cheaper fuel, a calming snack, a souvenir, side jobs)
  - [x] Round 9: no repeating sights, rare sights (great migration, leviathans, a ghost ship, a comet storm), a logbook (L), comm replies (T)
  - [x] Round 12 (your call, overriding the brief's "no death"): catastrophic crashes: out of control, an explosion, the WRECKED card, back to your last save with nothing lost
  - [x] Round 13: the autopilot forgives small nudges and steers back on course; a cinema camera on autopilot (V / R3: a director cutting between six shots, or a free orbit camera); a quieter engine and Music / Sound effects / Voices sliders
  - [x] Round 10: your route events list (1-167) in the data, 49 playable now (signs, passing ships with stories, processions, calls with reply choices, radio moments, gentle hazards like hull pings, gravity eddies and gravity tides); a director with zones (deep space, traffic lanes, station approach, orbit, weather), haul cooldowns, one hazard at a time, one rare per haul, story and night-only events
  - [x] Route map: the course chart (see M2)
  - [x] Round 17: gentler speed wobbles; physical crashes (knocked away from what you hit, tumbling round the impact); no writing on stations, the green ID label names them
  - [x] Round 16: a 360-degree ball of rocks (or ice, junk, casino chips) round every station with a traffic lane in, and an autopilot that goes round it; engine flames, sparks and plasma trails; mouse wheel zoom; boost speed wobbles; MML / MGS1 painted planets and rocks; sounds for jobs, the nav computer, money, doors and menus
  - [ ] Gravity wells and slingshots
  - [ ] The rest of the route events: 118 of 167 need a new model or a small new system (the horn, hitchhikers, the convoy you can join, the rival, wipers...); 168-250 still to come
  - [ ] Cockpit gizmos and toys, rumble polish, real 3D comm heads, cockpit poses
- [x] **M6: Economy & time** *(round 18; your playtest pending)*
  - [x] Time: no shifts (your call). Round 19: a 365-day, 12-month calendar and a clock that runs while you play (about 2 days per 10 minutes of flying), the date card, the clock on both HUDs; sleeping parked takes you to the next morning
  - [x] Weekly bills (OrbitalEx berth and dispatch fee, insurance), with a no-penalty tab paid from the next delivery
  - [x] Fuel at the pumps (since round 7), repairs at Dusty's, insurance (repairs half price)
  - [x] Job tiers: standard, rush, fragile / perishable / live (tagged on the board), with bonuses
  - [x] Rig XP and ten levels with felt stat boosts; level-gated upgrades (nine upgrades now)
  - [x] Everything saved; tests for all of it
  - [x] Round 19 extras: the job's drop-off in pink (chart and flight); every sign on a board; each rig's rooms tinted their own color
- [ ] **M7: Home & style** *(round 20: the rig side done; the home side parked)*
  - [x] New ships with their own handling (round 9: three rigs to buy, a special-order Megahauler to save for), a paint shop
  - [x] Round 16: your nine design-sheet rigs at Dusty's (Garbage Scow, Ice-Tug, SLAB, Catamaran, Cryo Tanker, Hab-Brick, Bulk-Ore, Ore-Crawler, Omega Ore Crawler), each with its own model, handling and pay
  - [x] Docking computer upgrade with its own (original) lounge waltz; it docks you from 4 km out
  - [ ] ~~Cargo loading forklift minigame~~: built in round 21, **scrapped in round 25** at your call (the dock crew loads everything; the code is in git history).
  - [x] Round 21 extra: vending machines with 12 galaxy brands and 22 snacks (the same brands as the radio ads)
  - [x] Round 20 extras: Dusty's shelves, ten new upgrades (cargo cradles, bumpers, racks, eco injectors, radar dish, air horn...), and upgrades you can see on the rig
  - [ ] Outfit slots, sockets and wardrobe (parked: her cap is already its own piece); decor placement; a bigger apartment
- [ ] **M8: Story & clients** *(started early, at your request)*
  - [x] Round 11: a second client system: the Glimmer System (magenta, neon billboards everywhere), The High Roller casino, Sal Grinwell (crocodile), a three-job storyline (cards, sequined jumpsuits for Marge, a slot machine for Gill) with Marge and Gill reacting, a first quiet hint about the husband (Sal knew someone who drove a rig like hers)
  - [x] The husband's story: told through people who knew him, his old logs on the PC, two story deliveries, a message chip, and his mixtapes on the radio (`docs/STORY.md`)
  - [x] Beta step 4: three more client systems, each farther and steeper: the Dustbowl (Mags, goat, salvage yard), Greenhouse Reach (Dr. Moss, tortoise, arboretum), the Frostline (Penny, penguin, comet creamery). Six systems and five clients in all (the brief's 5-8)
  - [ ] Supporting cast on the shared skeleton for the rest (the clients are on it; reduced face sheets still to do)
  - [x] Beta step 2: people tell you their problems and call OrbitalEx; the boss hands you their order at check-in (Sal's two jobs converted; Gill's broken ice machine added); Jacki answers back in conversations
- [ ] **M9: Endgame & completion** *(mostly built in beta step 2)*
  - [x] The boss (Dale Pembrook, weasel, shirt and tie) and the OrbitalEx office (greeter, lobby, desk; FF8 cameras)
  - [x] Pay at 10× minus a 90% company cut, itemized; checks wait at the office until you check in
  - [x] Buy the company (2,500,000 credits): no more cut after that
  - [x] Completion % (pause menu and the office)
  - [ ] Post-buyout sandbox extras, and balancing the price (beta step 5)
- [ ] **M10: Polish & ship**: menus, options, credits, controller glyphs, exports, performance. *Partial:* the window (round 22) and pleasant sound design (round 23) are done early, at your request.

---

## Next up

**The beta push**, in your order (details and the tech debt list in
`AUDIT.md`). Each one ends with validation, a push to git and a check-in:
1. ~~Audit~~ (`AUDIT.md`)
2. ~~The trucking company~~: the boss, the office, the 90% cut, checking in, new orders, buying the company, completion %
3. ~~The husband's story~~: people who knew him, his old logs, two story deliveries, his message, his tapes on the radio (`docs/STORY.md`)
4. ~~Three more systems with clients~~: the Dustbowl, Greenhouse Reach, the Frostline
5. Balance
6. Ship-ready basics and a Windows beta build

## M2 in short

After M1 feels right (we tune first if it doesn't): the delivery loop. Pick a
job from a simple menu, fly from the base to a destination station, fly through
a glowing approach ring and let the autopilot dock, get paid, fly back, and buy
a speed upgrade you can actually feel. Plus fuel that burns faster at speed,
cartoon bonks that knock your cargo condition, and basic saving.

---

## Notes from your playtests (for upcoming milestones)

- **Travel between solar systems can take a lot longer** (round 8: the
  Tidewater haul is 18 minutes cruising, 6 on boost, at your request). The
  course chart's autopilot keeps long hauls chill.
- **The ship:** round 4 is a cargo hauler (truck cab + container rack +
  engine block). Real art can replace `scenes/flight/ShipVisual.tscn` any
  time.
- **A graphics options menu** (resolution, fullscreen, wobble amount) belongs
  in M10's options menu; for now the window can be resized freely down to
  800x600, and the PS1 knobs are in `tuning.tres`.
- **Your uploaded model packs:** not used yet (see `DECISIONS.md`). If you buy
  a pack from its official store, or find one with a clear free license
  (like CC0), drop it in and tell me; I'll wire it up as traffic or a ship.
- **Your route-map sketch** (`reference/sketch_station_rooms_and_route_map.png`):
  a space restaurant hub in the middle, with routes out to a space truck stop
  (in an asteroid field near ringed planets), a space airfield, a space
  office, a space Costco-style warehouse store (we'll invent a non-trademark
  name) and a space drug den. That's a great starting map for M5's route
  screen and M8's clients and systems.
- **Boost fuel is bought and stored** in a limited tank, like a real truck's
  fuel. Buying it arrives with the economy (M2: fuel; M6: purchases).

---

## Later ideas

Ideas that aren't in the plan. Nothing here gets built without your OK.

- **The Hyperway** (round 11 question): slingshot gates that warp you about 5,000x cruise speed between far-apart regions (a "30 days at cruise" trip in about 9 minutes), a toll road with its own sector of space. See the chat answer from round 11.
- **A casino lounge radio station** for the Glimmer System (like Tide 77
  is Tidewater's): a crooner, slot-machine jingles, ads for the buffet.
- **Locked places on the course chart** ("???" until reputation or story
  opens them), per your answer about unlocking places.

- **The Megahauler, for real**: is flying something the size of an
  aircraft carrier fun? It could be, if the game leans in: slow, majestic
  turns, a crew of tiny tugs to dock it, a bridge you walk around, cargo
  that's a whole shopping mall. A late-game dream to design properly.
- **Replies in on-foot conversations** (like the comm replies).
- **A live view out the cabin window** while you walk around on autopilot.
- **Photo mode for the logbook**: snap the sights you log.

- **A jog button on foot.** The truck stop is big on purpose (40 x 30 m);
  a "hold to jog" would make crossing it quicker. The bible says her jog is
  "rare and reluctant", which could be a fun animation.
- **Your rig visible through the truck stop's porthole and the base's
  hangar** (a painted copy of the real model).

- **From your HUD list, still to place in the cockpit and on a tablet:**
  an attitude ball, a clock, a check-engine light and a soda can on the dash
  (the fuel bar and odometer are already on the dash screens; the bobblehead,
  air freshener and taped photo were already there), and a tablet with the
  manifest, logbook, star chart and insurance.

- **Photo mode** (pause, free camera, hide the HUD). Cozy, pretty games get
  shared through screenshots.
- **Dev shortcuts on the boot screen**: buttons that jump straight into any
  scene, to make testing faster as the game grows.
- ~~**"Stop the ship" assist**~~: declined in the round-2 playtest.
- **The boot screen in PS1 style.** It's still a plain setup/input check;
  it becomes the main menu in M10, and gets the PS1 treatment then.
- **More things on the road** (from `docs/ROUTE_EVENTS.md`): a weigh
  station, a scenic overlook, a construction zone, a broken-down trucker to
  help, a hitchhiker beacon, lost cargo pods to return, message buoys with
  lore.
- **Look around** with the right stick (orbit the chase cam, or turn your head
  in the cockpit). The controls already exist in the input map; it would fit
  nicely with the 3D cockpit in M5.
