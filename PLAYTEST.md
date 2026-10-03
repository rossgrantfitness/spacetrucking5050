# Playtest: M1, round 4 (late-PS1 look, Wipeout HUD, cargo rig)

**Your round-3 verdict:** the PS1 look was too "early 3D" and kind of ugly.
You wanted end-of-the-PS1-era (1999-2000) instead, at modern resolutions
(800x600 up to 4K), a HUD with chunky Wipeout-style pixel design, and a rig
that looks like it's hauling lots of cargo rather than a fighter.

**Time needed:** 10 minutes.

> Honest note: I checked this with screenshots at 800x600, 1280x720 and 4K.
> The wobble is now subtle, and it only shows in motion, so tell me if it's
> too little. Flying itself wasn't touched.

---

## What's new

- **Late-PS1 look at full resolution.** The game draws at your screen's own
  resolution (resize the window freely; it stops at 800x600). Models still
  wobble a little and textures stay crunchy and pixel-crisp, but far
  cleaner: more detailed hull plating, colored lighting, a faint nebula
  across the sky, and the PS1's 15-bit color with a soft dither.
- **A Wipeout 3 / Colony Wars HUD.** Slanted rainbow THRUST bar, BOOST FUEL
  bar, a chunky segmented speed arc, and big slanted pixel digits. All the
  text is a custom blocky pixel font. The truck stop marker has cyan sci-fi
  brackets.
- **Engine star flares and hot-core trails,** like late-90s racers.
- **Your rig is a cargo hauler now:** a truck cab up front (amber glass,
  headlights, grille, chrome exhaust stacks, crew quarters on the roof), a
  rack of eight colorful cargo containers, and an engine block with three
  engines.

## What to do

1. Pull the update in GitHub Desktop (*Fetch origin*, then *Pull*), press
   **F5**, then **Enter** / **Start**.
2. Fly around for a few minutes like before. Boost through the asteroids.
3. Resize or maximize the game window. It should look sharp at any size.
4. Visit the truck stop and the parking lot.
5. Optional knobs in `data/tuning.tres` → **PS1 look**: **Vertex Snap Rows**
   (lower = wobblier; 240 was round 3), **Affine Strength** (texture swim),
   **Dither Strength**, **Color Levels**.

## What to pay attention to

- Does it feel like a late PS1 game now, and is it pretty?
- Is the HUD readable at a glance? Does it feel like Wipeout?
- Does the rig look like a hard-working truck with a load on?

---

## Questions for you

1. **The look:** closer? More wobble, or less? More or less dither?
2. **The HUD:** right style? Anything you'd want bigger, smaller, or moved?
3. **The rig:** does the cab + containers + engines read as *your* truck? Too
   boxy, or just right? Different colors?
4. **The trails and flares:** too much, or more please?
5. **Your model packs** (from last time): where did the *Zenith / Striker /
   Spitfire* archive come from? If it's free to use (CC0), I can use those
   ships as traffic.
