# Playtest: round 5 (walking the base, damage, the 3D cockpit)

**Your round-4 verdict:** the look is better but should feel *older* (more
wobble or dither). The HUD and truck are better, the flares are fine. You
asked for ship damage, a lived-in reactive cockpit, and to start on the RPG:
the bunny walking around the station on pre-rendered backgrounds.

**Time needed:** 15-20 minutes.

> Honest note: I checked all of this with screenshots and automated
> walk-throughs. How walking feels, whether the camera angles frame things
> nicely, and how chunky the wobble feels in motion are yours to judge.

---

## What's new

**On foot (new!)**
- **Press Start and you wake up in your apartment** (from your sketch): the
  big window onto space, unmade bed, old computer, socks everywhere, the
  framed photo, rug, plant, hanging lamp.
- **Pre-rendered backgrounds, FF8 style.** Each room has fixed camera angles,
  and the view cuts as you walk between areas. The rooms are painted once
  when you enter (that's the short fade), and your bunny walks around in
  front of the painting as a wobbly PS1 model.
- **Walk** with **WASD** / **left stick**. "Up" always means "away from the
  camera"; after a camera cut, keep holding the stick and she keeps going
  the same way.
- **Out the door → the hallway → dispatch.** Talk to **Dottie** (raccoon,
  mornings) at the counter with **E** / **A**. Her lines are typed out with
  little gibberish voice blips.
- **Climb the stairs to the SHIP door** and press **E** / **A** to board your
  rig. In flight, pause → **Dock at the base** to walk again.

**In flight**
- **Damage.** Bonk into rocks, the station or traffic: sparks, a cartoon
  "bonk", a shake, a little bounce, gamepad rumble, and a new **HULL** bar.
  A battered rig trails smoke and spits sparks. Nothing ever explodes. Park
  near the truck stop to patch up (paid repairs come later).
- **A real 3D cockpit** (press **C** / **Y**):
  - It reacts to you. The fuzzy pink steering wheel turns with your steering, the throttle lever moves, and the boost button lights up and sinks in.
  - Needles show speed and hull. A green status screen and an amber nav radar show the truck stop and traffic.
  - The fuzzy dice, air freshener and alien bobblehead swing when you turn, boost or bonk. The red alarm flashes on a bonk.
  - It's lived in: coffee, a clipboard, sticky notes, a taped photo.
- **More wobble and dither** for that older feel.
- **A third traffic ship:** one of the OpenGameArt ships (Quaternius,
  free to use) zips around the truck stop as a courier.

## What to do

1. Pull the update (*Fetch origin*, *Pull*), press **F5**, then **Enter** /
   **Start**.
2. Walk around the apartment. Walk behind the bed and the desk.
3. Leave by the door, walk the hallway to dispatch, talk to Dottie.
4. Climb the stairs, board the ship, fly around a bit in the cockpit view.
   Bonk into a rock or two on purpose.
5. Pause → **Dock at the base**.
6. Optional knobs (`data/tuning.tres`): **On foot** (walk speed, how softly
   the backgrounds are painted), **Bonks and damage**, **Cockpit view** (how
   loose the dice are), **PS1 look**.

## What to pay attention to

- Do the rooms feel like a late-PS1 RPG? Cozy?
- Do the camera angles show the rooms well? Any spot where you get lost or
  the bunny is too small or hidden?
- Does walking feel right (speed, turning), especially across camera cuts?
- Does damage feel like a gentle bonk, not a punishment?

---

## Questions for you

1. **The base:** do the pre-rendered rooms hit the look you wanted? Which
   camera angle do you like best, and which would you change?
2. **The bunny:** right proportions and outfit? (Fur color, cap, jacket and
   the wheat stalk are all easy to change.)
3. **Damage:** should a battered rig handle worse (say, a bit slower) until
   it's repaired, or stay purely cosmetic?
4. **The cockpit:** what other toys or gizmos do you want in there?
5. **Wobble/dither:** better now, or push further?
