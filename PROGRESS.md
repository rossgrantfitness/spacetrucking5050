# Progress

**Current milestone:** M0 (Setup): built and validated, **waiting for your
playtest** (see `PLAYTEST.md`).
**Engine:** Godot 4.7.2 (GDScript), Compatibility renderer.
**Last updated:** 2026-10-03

---

## Milestones

- [x] **M0: Setup** *(waiting for playtest feedback)*
  - [x] Detected Godot 4.7.2 (latest stable) and created the project
  - [x] Folder structure: `autoload/`, `data/`, `scenes/`, `shaders/`, `audio/`, `tools/`
  - [x] Autoload stubs: Events, SaveSystem, Settings, GameState, Economy, TimeOfDay, Radio, Dialogue
  - [x] Input map for keyboard+mouse and gamepad (flying, walking, pause), plus an Invert Y option that saves
  - [x] Tuning resource: `data/tuning.tres` backed by `data/Tuning.gd`, every value explained in plain English
  - [x] Boot screen (main scene) with a live input check
  - [x] Git repo with Godot `.gitignore`; `HOW_TO_RUN.md`
  - [x] Headless validation (`tools/validate.sh`) and self-tests (`tools/tests/`)
  - [x] Cloud sessions auto-install Godot (`.claude/hooks/session-start.sh`)
- [ ] **M1: Flight sandbox ("find the heart")**: arcade flight with banking, chase cam + cockpit view, space dust, speed FOV, boost lines, engine hum, asteroids + a distant station
- [ ] **M2: The delivery loop**: job → fly → approach ring → auto-dock → payout → fly back → speed upgrade you can feel; fuel, bonks, save/load
- [ ] **M3: The walkable hub**: apartment → hallway → dispatch → hangar, on-foot controller, dialogue with voice blips
- [ ] **M4: PSX look + the radio**: PSX shaders, low-res rendering, per-system fog, radio stations
- [ ] **M5: Life in space**: comms, random sights, gentle hazards, cockpit gizmos, screen shake, route map
- [ ] **M6: Economy & time**: shifts, sleep, rent, fuel, repairs, insurance, job tiers, ship XP
- [ ] **M7: Home & style**: wardrobe, decor, bigger apartment, new ships, docking computer, forklift minigame
- [ ] **M8: Story & clients**: clients and systems with storylines; the husband's story
- [ ] **M9: Endgame & completion**: buy the company, completion percentage
- [ ] **M10: Polish & ship**: menus, options, credits, controller glyphs, exports, performance

---

## Next up: M1

Once M0's playtest is OK: the flight sandbox. A heavy, lazy starter rig you can
fly around an asteroid field toward a distant station: throttle, banking turns
that auto-level, boost, a level-horizon chase camera with lag, a cockpit view,
space dust that rushes past, a subtle speed FOV, and a procedural engine hum.
The M1 playtest question: *"With music playing in another app, is it pleasant
to just fly around for five minutes?"*

---

## Later ideas

Ideas that aren't in the plan. Nothing here gets built without your OK.

- **Photo mode** (pause, free camera, hide the HUD). Cozy, pretty games get
  shared through screenshots.
- **Dev shortcuts on the boot screen**: buttons that jump straight into the
  flight sandbox or the base, to make testing faster as the game grows.
