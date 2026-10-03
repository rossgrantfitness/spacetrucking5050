# Progress

**Current milestone:** M1 (Flight sandbox), **round 2**: reworked after your
first playtest (momentum, rocket boost on its own fuel, a more reactive engine
hum). Built and validated, **waiting for your playtest** (see `PLAYTEST.md`).
**Engine:** Godot 4.7.2 (GDScript), Compatibility renderer.
**Last updated:** 2026-10-03

---

## Milestones

- [x] **M0: Setup** *(built; its playtest questions carried into M1's)*
  - [x] Detected Godot 4.7.2 (latest stable) and created the project
  - [x] Folder structure, autoload stubs, input map (keyboard+mouse and gamepad), Invert Y option
  - [x] Tuning resource (`data/tuning.tres`), boot screen with a live input check
  - [x] Headless validation (`tools/validate.sh`), self-tests, cloud-session Godot install
- [x] **M1: Flight sandbox ("find the heart")** *(round 1 playtested: "totally pleasant"; round 2 waiting for playtest)*
  - [x] Arcade flight (round 1, since replaced by momentum below): throttle lever, banking that auto-levels, gentle nose auto-level, recharging boost
  - [x] Starter rig's personality in data (`data/ships/starter_rig.tres`): heavy and lazy
  - [x] Level-horizon chase cam with turn lag and boost pull-back; camera roll as an option
  - [x] Cockpit view with a placeholder hazard-striped frame and a green dash screen
  - [x] Space dust (endless, streaks with speed, tinted by the system color), speed FOV, boost-only speed lines, engine trails
  - [x] Engine hum: four layered loops whose pitch and volume follow speed, wobble in turns, growl on boost
  - [x] An asteroid field of tumbling low-poly rocks (with collision) and a distant truck-stop station
  - [x] Minimal corner HUD (speed gauge, station marker, mouse reticle), small pause menu, "Press Start" on the boot screen
  - [x] Self-tests for the flight rules, sound loops and rock meshes; an autopilot smoke test of the sandbox
  - [x] Round 2 (from your feedback): momentum (thrust, coast, reverse-thrust brake, carving turns with tunable grip, overshooting), rocket boost on a boost-fuel tank (top up at the truck stop for now), boost screen shake with an on/off switch, a drift marker on the HUD, and an engine hum that reacts to thrust, slides and boost
- [ ] **M2: The delivery loop**: job → fly → approach ring → auto-dock → payout → fly back → speed upgrade you can feel; fuel, bonks, save/load
- [ ] **M3: The walkable hub**: neon rooms with fixed FF8-style cameras, on-foot controller, dialogue with voice blips
- [ ] **M4: PSX look + the radio**: PSX shaders, low-res rendering, per-system fog, palette and references, radio stations
- [ ] **M5: Life in space**: comms, random sights, funny ship labels, gentle hazards, cockpit gizmos, screen shake, route map
- [ ] **M6: Economy & time**: shifts, sleep, rent, fuel, repairs, insurance, job tiers, ship XP
- [ ] **M7: Home & style**: wardrobe, decor, bigger apartment, new ships, docking computer, forklift minigame
- [ ] **M8: Story & clients**: clients and systems with storylines; the husband's story
- [ ] **M9: Endgame & completion**: buy the company, completion percentage
- [ ] **M10: Polish & ship**: menus, options, credits, controller glyphs, exports, performance

---

## Next up: M2

After M1 feels right (we tune first if it doesn't): the delivery loop. Pick a
job from a simple menu, fly from the base to a destination station, fly through
a glowing approach ring and let the autopilot dock, get paid, fly back, and buy
a speed upgrade you can actually feel. Plus fuel that burns faster at speed,
cartoon bonks that knock your cargo condition, and basic saving.

---

## Notes from your playtests (for upcoming milestones)

- **Travel between solar systems can take a lot longer** than the sandbox's
  5 km hop. We'll plan that when routes and systems arrive (M2 route length,
  M5 route map). Remember the brief's dev default of short legs so testing
  stays quick; the real length will be a tuning value.
- **The ship:** you're picturing something Cowboy Bebop-sized (room for 4-5
  people and months of supplies) rather than a literal space truck, and you've
  found other references. Waiting on those pictures for the next placeholder.
- **Boost fuel is bought and stored** in a limited tank, like a real truck's
  fuel. Buying it arrives with the economy (M2: fuel; M6: purchases).

---

## Later ideas

Ideas that aren't in the plan. Nothing here gets built without your OK.

- **Photo mode** (pause, free camera, hide the HUD). Cozy, pretty games get
  shared through screenshots.
- **Dev shortcuts on the boot screen**: buttons that jump straight into any
  scene, to make testing faster as the game grows.
- **"Stop the ship" assist** (auto-brake to a halt) for lazy cruising, now
  that braking takes reverse thrust. Asked about in the round-2 playtest.
- **Look around** with the right stick (orbit the chase cam, or turn your head
  in the cockpit). The controls already exist in the input map; it would fit
  nicely with the 3D cockpit in M5.
