# Playtest: round 9 (intro, throttle, the cabin, the radio, things to buy)

**What you asked for:** a fast power-on intro and loading screens; more
speed at cruise without making boost feel weaker; a throttle instead of a
go-kart; heavier turning; cargo damage you can understand (and feel) with
no nagging; a boost that's harder to start and stop; walking around the
rig while the autopilot drives; no repeating sights, a logbook and rare
sights; a Gas-N-Go worth stopping at; walking around every destination;
people who remember; Jack Rabbit; replies on the comms; your 20 radio
stations with DJs who react to the game; something to spend money on (a
new ship first, then paint); and running on foot.

**Time needed:** about an hour.

> Honest note: I tested everything with automated runs (the long haul
> plays itself, including docking at Tidewater's canteen, a drive-through,
> a comm reply, flipping all the stations, the cabin and a nap) and looked
> at screenshots. Whether the throttle, the heavier turning and the speed
> feel right is yours to judge. The placeholder music is made from math
> and I can't hear it, so some loops may sound odd (especially the metal).

---

## What's new

**Starting up**
- A ~9 second **power-on intro**: a self test types itself out ("CHECKING
  SPACESHIP... OK!"), then the logo and a chime. Any key skips it.
- **Loading screens** between flying and walking ("LOADING CARGO...
  MAPPING COORDINATES... ENTERING HYPERDRIVE... JUST KIDDING").

**Flying**
- **The throttle is a lever:** hold W to push it up, S to pull it down; it
  stays where you leave it and the rig holds that speed. All the way back
  stops you.
- **Heavier:** turns take a moment to start and stop, and lean more.
- **More speed at cruise:** more dust, bigger specks whipping past close,
  the view widening sooner, a faint road rumble, and **spaceway beacons**
  lining the lanes (with a pulse of light running toward where you're
  going).
- **Boost is a commitment:** full throttle only, it spools up while you
  hold it (SPOOL), and once lit it burns at least 3 seconds.
- **Cargo damage you can read:** thumps in the hold, a cab rattle, a jolt,
  the hold flashing orange on the rig picture, and HARD TURN / BRAKING /
  BOOST SHAKE under the RIDE bar. Someone mentions it once per trip.

**Your rig is your home**
- On autopilot, press **F** (X) to **get up and walk around the cabin**
  (your apartment is the rig's sleeper cabin). Walk out the door to get
  back in the seat. **Nap** on the bed to fast-forward the trip.
- **Run** on foot with **Shift** (X).

**People**
- The bunny is **Jack Rabbit**.
- **Talk back:** after a comm call, press **T** (RB), then **Q / R / E**
  (or 1 / 2 / 3, or the D-pad) to pick one of three replies.
- **They remember:** Marge and Gill say something different depending on
  how the pies arrived; Moe finishes last visit's sentence.

**The radio: your 20 stations**
- All of them, with DJs, slogans, ads and made-up songs (placeholder loops
  until you add music). **Tide 77** only comes in near Tidewater,
  **Fuel Injection** is a crackly pirate station, **Afterglow Block** only
  plays at night (9 p.m. to 6 a.m. on your computer's clock for now), and
  there's an unnamed station somewhere on the road...
- **DJs react:** fly into an ion storm, get a ticket, cross into Tidewater,
  or make a delivery (a shout-out next trip).

**Sights**
- No more repeats. **Rare sights** (about one every dozen long hauls).
- **The logbook** (**L**, or the pause menu): everything you've seen.

**Places and money**
- **Tidewater is walkable:** climb out in Gill's cannery canteen.
- **The Gas-N-Go:** cheaper fuel, Moe's calming jerky (steadier under
  boost), a souvenir keychain, side jobs.
- **Dusty's garage:** **RIGS FOR SALE** (three new rigs that handle
  differently; bigger holds pay more) and a **PAINT SHOP**. Plus the
  Megahauler, a special order to dream about.

---

## Try this

1. Start the game and watch the intro (then skip it next time).
2. New game. Fly to the truck stop by hand: try the **throttle lever**,
   some turns, and the **boost** (hold it at full throttle). How does it
   feel now?
3. Take Marge's long haul and **chart a course (M) via the Gas-N-Go**.
   Once the autopilot's driving, press **F** and **walk around the cabin**.
   Try a **nap**.
4. At the Gas-N-Go, try the **jerky** and the **keychain**. Then **flip
   through the radio** (Q / E) and find a favorite.
5. When someone calls, press **T** and **reply**.
6. Climb out at **Tidewater**, talk to Gill, take a load back.
7. Save up and **buy a new rig** (or paint the old one). Feel the
   difference?
8. Press **L** now and then to see your **logbook**.

## Questions for you

1. **The throttle lever and the heavier turning:** right, or too much / too
   little? (Numbers: tuning.tres "Throttle" and "Steering input"; the rig's
   own turn numbers are in `data/ships/starter_rig.tres`.)
2. **Speed at cruise:** do the spaceway beacons and extra dust sell it now,
   while boost still feels like a big deal?
3. **Boost:** with the spool-up, full-throttle rule and 3-second minimum
   burn, is choosing to boost a real decision now? Too fiddly?
4. **The cabin:** is walking around (and napping) while the autopilot
   drives what you imagined? What would you want to do in there?
5. **The radio:** which stations land, and do the DJ lines and ads come up
   too often, too rarely, or about right?
