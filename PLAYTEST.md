# Playtest: round 6 (the Wipeout-style HUD and comm chatter)

**What you asked for:** a full HUD from your list, styled like Wipeout PSX:
a pixel font at low resolution, segmented bars, a strict palette, jittery
ticking numbers, pop-ins that slide in a few frames at a time, a hide
toggle, and HUD chatter. Lots of it tiny.

**Time needed:** 15 minutes.

> Honest note: I checked all of this with screenshots at 1280x720, 800x600
> and in cockpit view, plus automated test flights. Whether it has the
> *vibe*, whether anything is too tiny to read on your screen, and whether
> the chatter is charming or annoying are yours to judge.

---

## What's new

**The HUD is drawn small, then blown up with chunky square pixels**, so it
looks like a real PS1 HUD at any screen size. It ticks at 30 fps and its
numbers jump 8 times a second on purpose.

| Where | What |
|---|---|
| Bottom left | Speed in big slanted digits, a segmented bar with a **red redline**, yellow **overflow** segments when boosting past it, and a yellow **throttle tick**. The tiny **BST** bar under it is your boost tank. |
| Bottom middle | A spinning **wireframe radar globe**: rocks are dim green dots (red when close), ships are yellow with stalks, the truck stop is a blinking green diamond. |
| Bottom right | **Fuel** as a segmented arc, the **ECO** arrow (green / yellow / red), and a tiny **rig picture** that flashes red where you bonked, with the hull % on top. |
| Top middle | A sliding **compass strip** with a yellow diamond toward the truck stop and the distance, the **ETA** counting down, and the **RUSH** timer. |
| Top left | The **radio**: signal bars, station, and the song or ad scrolling like an LED sign. **Q / E** (D-pad left/right) flips stations with static. |
| Top right | **CARGO %** (ticks down when you bonk) and **PAY** (ticks up and down as bonuses come and go). |
| Middle | A tiny **flight marker** where your momentum is taking you (not a gun sight). |
| Left edge | Five dark **warning lights**: PROX, GRAV, STORM, COPS, FUEL. |
| Pop-ins | **Comm calls** (top left), **docking brackets** near the bay, **ship ID labels** ("PET GROOMING SHIP"), **jump charge**. |

**Comm chatter:** Dottie calls after takeoff; Marge at truck stop control
when you get close; Big Wendell and Pip make small talk, tease your bonks
and cheer your boosts. Static before and after, typed words, gibberish blips,
mouth flaps. (The portraits are placeholders; the character bible's real 3D
heads come in M5.)

**Also new, so the HUD has something to show:**
- **Main fuel.** Thrusting burns it, more at high speed. Coasting is free.
  An empty tank never strands you (you crawl on fumes). The truck stop
  tops you up.
- **A practice haul:** garden gnomes (fragile) for the truck stop diner, a
  rush job. Fly up to the docking bay to deliver; the top right flashes
  DELIVERED and what it paid. (Pretend money for now; real pay is M2.)
- **Hide the HUD** with **H** / D-pad down (calls still pop in).
- **F9 = HUD demo:** lights every warning and the jump charge, so you can
  see the ones that have nothing to trigger them yet (gravity wells, storms,
  cops and jump points arrive with M5).

## What to do

1. Pull the update, press **F5**, then the small "fly" button on the boot
   screen (or walk to the ship).
2. Fly to the truck stop normally. Watch the HUD, let Dottie talk, flip the
   radio a few times.
3. Bonk a rock or two: watch the rig picture, CARGO and PAY.
4. Hold **W** at top speed and watch the ECO arrow, then let go and coast.
5. Boost a bit. Then fly into the docking bay to deliver.
6. Press **F9** to see every warning lit, and **C** for cockpit view.
7. Press **H** to hide the HUD and fly a minute with only the cockpit.
8. Optional knobs in `data/tuning.tres`: **HUD** (pixel size, frame rate,
   number rate, pop-in steps, radar range) and **Comms chatter** (how often
   people call, how fast they talk).

## What to pay attention to

- Does it feel like a late-90s PlayStation HUD? Wipeout enough?
- Is anything too tiny to read, or too big? (`hud_rows` makes everything
  bigger or smaller at once: fewer rows = bigger pixels.)
- Is the screen calm enough while flying, or still cluttered?
- Is the chatter cozy, or too frequent?

---

## Questions for you

1. **Overall vibe:** does it read as Wipeout PSX? What's the first thing
   you'd change?
2. **Size:** right now the HUD is drawn as if your screen were 360 pixels
   tall. Want it chunkier (say 300) or finer (say 420)?
3. **Chatter:** how often should people call? (Small talk is every 50 to
   110 seconds now.) Any characters you want on the comms instead?
4. **Fuel and economy:** does the fuel/ECO arrow make you want to coast and
   save fuel, or does it feel like a chore?
5. **Next in the cockpit:** want the attitude ball, clock, check-engine
   light, soda can and the tablet (manifest, logbook, star chart,
   insurance) next round, or straight on to the audit and M2?

## Still open from round 5 (walking the base)

1. **The base:** do the pre-rendered rooms hit the look you wanted? Which
   camera angle do you like best, and which would you change?
2. **The bunny:** right proportions and outfit? (Fur color, cap, jacket and
   the wheat stalk are all easy to change.)
3. **Damage:** should a battered rig handle worse (say, a bit slower) until
   it's repaired, or stay purely cosmetic?
4. **The cockpit:** what other toys or gizmos do you want in there?
5. **Wobble/dither:** better now, or push further?
