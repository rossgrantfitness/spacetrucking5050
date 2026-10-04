# Playtest: round 8 (the long haul to Tidewater)

**What you asked for:** less dither (same wobble); a huge space world; a
first mission that takes 6 minutes on full boost but 18 at regular speed;
debris; procedural (or planned) things to pass on the road, researched
from what a space trucker might see; maybe an optional stop; cargo damage
from flying too fast or too erratically; boost that makes you lose course
if you're not steady; charting a course for the autopilot; and a new sun,
planet and nebula color in the new system.

**Time needed:** about 45-60 minutes (the haul is long on purpose: try it
once by hand, once on autopilot, and a bit of boosting).

> Honest note: I tested all of this with automated runs (the mission plays
> itself, including the autopilot docking at Tidewater and rolling through
> the Gas-N-Go) and looked at screenshots along the whole road. Whether 18
> minutes feels chill or long, whether boosting feels exciting or annoying,
> and whether the cargo damage feels fair are yours to judge. Feel can't be
> checked by reading code.

---

## What's new

**The first mission is a long haul**
- Start a **new game** (boot screen: "start a new game"), talk to Dottie,
  fly to the truck stop, dock, and talk to **Marge**. Her cousin **Gill**
  runs the canteen at **Tidewater Cannery**, way out in the teal system:
  haul nebula pies and coffee out there (1300 credits, up to +500 if
  they arrive perfect).
- Tidewater is about **59 km past the truck stop**: about **18 minutes**
  cruising at top speed, **6 minutes** on full boost (a full boost tank
  lasts exactly that long).
- At the cannery you **stay in the cab**: Gill says hi on the comms, you
  get paid, and a counter menu lets you look for a load back, fill up, or
  launch. Four Tidewater jobs open up after the first mission.

**Chart a course (press M, or Back on a gamepad)**
- A map plus a list: every place, its distance, time cruising, time on full
  boost, and fuel needed. "Via Gas-N-Go 47" shows up when it's on the way.
- Pick one and the **autopilot drives**: top speed on the limiter (cheap on
  fuel), gentle turns that don't rattle the cargo, steering around rocks,
  junk and traffic, and right through the approach ring.
- **Grab the stick, throttle or boost and you take over.** Press M again to
  switch it off or pick somewhere else.

**The road** (in order from the truck stop)
- Green **highway signs** counting down (they read both ways).
- A **junk spill** across the lane at about 18 km.
- **Gas-N-Go 47**, the optional stop, about 1.8 km to the right at 30 km:
  fly through either orange ring, pull up under the canopy, Moe sells you
  fuel... slowly... and you roll out the far side still moving.
- **The world's biggest donut**, the **border gate** into Tidewater (the
  colors change as you cross), a **lighthouse** with no rock, the derelict
  **Dorothy Mae**, an **ion storm** (static, jolts, the STORM light), an
  **icy rock field**, **space whales**, and a **speed trap** before the
  cannery (the COPS light comes on; zoom past it over 250 km/h and Deputy
  Biscuit writes you a 25-credit ticket).
- **Random sights** every few km: big ships crossing (listen for the
  rumble), convoys, billboards for weird products, comets, jellyfish, junk,
  a giant rubber duck. Some get a comment on the comms.

**Tidewater looks different**
- Its own **sun** (minty), a huge **ocean planet**, a **moon**, and a
  **teal nebula**. The space dust, haze, sunlight and HUD frames blend from
  home's purple to Tidewater's teal as you fly, with a "NOW ENTERING"
  banner at the crossover.

**Flying changes**
- **Less dither** (finer and softer), same wobble.
- **Boost is hard to hold steady:** the nose wanders off course, and jerky
  steering makes it shake worse. Small, smooth corrections calm it.
- **Cruising sips fuel:** holding thrust at top speed burns much less than
  speeding up (a full tank cruises about 27 minutes).
- **The cargo minds rough flying:** hard turns, slides, hard braking and
  boosting flat out slowly damage it. Watch the new **RIDE** bar under the
  cargo readout (top right): green is fine, yellow bumpy, red damaging.
  Speeding up straight ahead is always fine.

---

## Try this

1. **New game**, take Marge's long haul, then **fly the first stretch by
   hand** for 5 minutes or so with the radio on.
2. **Boost for a while.** Try holding it steady, then try yanking the stick
   around. Watch the RIDE bar and where the nose goes.
3. Press **M** and pick **Tidewater via Gas-N-Go 47**. Let the autopilot
   drive. Stop for fuel, roll out, and let it carry on.
4. Somewhere along the way, **take the wheel back** (just steer), look at
   something, then press **M** again to re-engage.
5. Try zooming past the **speed trap** near the cannery on boost (it's
   only 25 credits).
6. At the cannery: get paid, **look for a load**, and haul one back.

## What to pay attention to

- Does the long haul feel **chill** (radio on, watching stuff go by) or
  **too long**? Is there enough to look at?
- The **colors changing** from home to Tidewater, and the new sun, planet
  and moon.
- Whether the **boost wander** is fun-hard or just annoying.
- Whether **cargo damage** ever feels unfair.

## Questions for you

1. Is 18 minutes cruising the right length for a "big" haul, with the
   autopilot there to help? Would you like a shorter run in between?
2. Boosting now wanders off course and shakes if you're jerky. **More,
   less, or about right?** (The numbers are in tuning.tres under "Flying":
   `boost_wander_degrees`, `boost_wobble_degrees`, `boost_steer_gain`.)
3. Does the cargo damage from rough flying feel fair? Was the RIDE bar
   clear?
4. Of the things on the road, **which ones did you like, and which fell
   flat?** Want more fixed landmarks, or more random sights? (Ideas for
   later are in `docs/ROUTE_EVENTS.md`.)
5. Is the dither right now, or still too much / too little?
