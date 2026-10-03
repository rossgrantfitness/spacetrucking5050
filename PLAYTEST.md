# Playtest: M1, round 3 (the PS1 look + station life)

**Your round-2 verdict:** the ship feels better, boost feels better, the hum is
great, no stop button. Flying is approved! You asked for the PS1 look ("make it
look like a 1997 PS1 game", wobbly verts are paramount), traffic around the
station, and trucks parked outside. You also sent ship pictures.

**Time needed:** 10 minutes.

> Honest note: I checked this with still screenshots. **Wobble and texture
> swim only show up in motion**, and only you can say whether they feel
> right, too much, or too little. Flying wasn't touched; only the camera
> pulled back to fit the bigger ship.

---

## What's new

- **The PS1 look.** The 3D world is drawn at about 240 rows of pixels and
  blown up with chunky pixels, in the PS1's 15-bit color with a fine dither
  pattern. Every model's corners snap to a coarse pixel grid, so things
  **wobble** as they move, and textures **swim** on big surfaces up close.
  Lighting is old-school per-corner shading. Faraway things fade into a
  lilac **haze** (each solar system will have its own color). The HUD and
  text stay sharp.
- **Your new rig,** built from your BB 42 picture: gunmetal body, amber
  cockpit glass, silver engine pods with yellow pinstripes, swept wings, a
  crew module with warm cabin windows on top, and a blinking nose probe.
  It's about 31 m long, room for a crew of 4-5.
- **A huge ringed planet** on the horizon.
- **Traffic:** a capsule hauler (from your sketch) commutes between the start
  and the truck stop, high above the asteroids. A boxy space-semi (our old
  rig!) circles the station.
- **A parking deck** under the truck stop's docking bay with six parked
  trucks, lamp posts and a "TRUCK PARKING" sign. Fly in and have a look.

## What to do

1. Pull the update in GitHub Desktop (*Fetch origin*, then *Pull*), press
   **F5**, then **Enter** / **Start**.
2. Cruise toward the truck stop. Watch the rocks and your rig as you turn:
   that shimmer is the wobble.
3. Look up and left early on for the commuter's engine trail.
4. Fly right up to the station and drop below the docking bay to see the
   parking deck. Hover between the parked trucks.
5. Try the cockpit view (**C** / **Y**) near the station.
6. Optional knobs, in `data/tuning.tres` → **PS1 look** (hover each for an
   explanation): **Psx Resolution Height** (lower = chunkier pixels),
   **Vertex Snap Scale** (lower = wobblier), **Affine Strength** (texture
   swim), **Color Levels**, **Dither Strength**, and the haze distances.

## What to pay attention to

- Does it feel like a 1997 PS1 game? Warm and cozy, not creepy?
- Is the wobble charming, or does it get tiring after a few minutes?
- Can you still judge distances and spot rocks with the chunky pixels?
- Any motion sickness?

---

## Questions for you

1. **The PS1 look:** right on, or push it further (chunkier pixels, more
   wobble) or pull it back?
2. **Your rig:** does it feel like *your* ship? The camera now sits farther
   back to fit it. Does that make flying feel slower?
3. **Station life:** is two traffic ships the right amount? Does the parking
   lot sell "truck stop"?
4. **The planet:** love it, too big, or in the way?
5. **Your uploaded model packs:** I didn't use them (see the reason in chat).
   Where did the *Zenith / Striker / Spitfire* archive come from? If it has
   a free license (like CC0), I can use those ships as traffic.
