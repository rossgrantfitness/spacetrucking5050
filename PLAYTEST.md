# Playtest: rounds 21 and 22 (round 20 below)

**Round 22, the window (try it first, it's quick):** drag the window's
edges to all sorts of shapes, press **F11** (or Alt+Enter) to go fullscreen
and back, and try **Menu and HUD size** in the pause menu. Quit and start
again: it should come back exactly the way you left it. Does anything look
wrong at some window shape?

---

# Round 21: the 3D forklift and vending brands

**What you asked for:** the forklift as a third-person 3D game where she
climbs on and drives it to pick up 3D boxes (or scrap it), and vending
machines with food and drink from in-game brands that are the same
across the galaxy.

**Time needed:** about 20 minutes.

> Honest note: a play-through test drives the forklift, loads every pallet
> and comes back, and I checked it with screenshots. Whether it handles
> nicely is a feel thing only you can judge. Every number (speed, steering,
> fork height) is at the top of `scenes/dock/Forklift.gd`.

## What's new

- **The loading dock:** take a job, pick **I'LL DRIVE THE FORKLIFT**, and
  once you're done talking you're at a 3D loading dock with your rig's hold
  open.
  - Walk to the forklift and press **E** to climb on.
  - Drive with **W/S** and **A/D** (it steers from the back, like a real
    one).
  - Slide the forks under a pallet and press **E** to lift it.
  - Drive into the hold and press **E** to set it down on a glowing spot.
  - Fill every spot for a snug load. Then you're back where you were.
- **Vending machines:** 12 brands, 22 snacks and drinks, the same brands
  as the radio ads and billboards. Machines are at the truck stop, in your
  rig's hallway, in the Tidewater canteen and in the casino.
  - She holds what you buy, eats or drinks it, and says what she thinks.
  - The first time she tries a brand, she reads its story off the back of
    the packet.
  - Food steadies her hands for the next trip; energy drinks top up the
    boost tank.

## What to do

1. Buy something from the truck stop machine. Watch her eat it, and read
   the packet. Try a few brands.
2. Try the machine in your rig's hallway, in flight.
3. Take a job and choose the forklift. Load the whole hold.
4. Try the Tidewater or casino machine for the local treats.

## Questions

1. The forklift: does driving it feel good? Too fast, too slow, too twitchy?
2. Is lining the forks up under a pallet satisfying, or fiddly?
3. Want more on the dock (a timer for a bonus, bigger loads, dock workers
   who chat)?
4. The brands: any you love, or want renamed? Ideas for more?
5. Should snacks do more (or less) than steady hands and boost?

---

# Round 20: M7 ship upgrades

**What you asked for:** M7, but "focus on ship upgrades and stuff" instead
of outfits; and the date card smaller, in a corner, in fewer colors, with a
quicker fade.

**Time needed:** about 30 minutes. You'll want money to try the parts:
play a few deliveries first, or keep your save.

> Honest note: I checked all of this with automated tests (a robot even
> loads the forklift) and screenshots. Whether the parts look good on each
> rig, and whether the forklift is fun, are things only you can judge. The
> bolt-on parts are placeholder shapes, like the rest of the art.

## What's new

- **The date card** is small, in the bottom-left corner, in gold and white,
  and gone in about 3 seconds.
- **Dusty's shelves:** ENGINE & HANDLING, HAULING, NAVIGATION, CAB EXTRAS.
- **New parts:**
  - Gel Cargo Cradles and Zero-G Suspension (gentler on cargo)
  - Bumper Bars (less hull damage)
  - Stacking Racks (+10% pay)
  - Eco Injectors and Solar Sail Trim (less fuel)
  - Long-Range Radar Dish
  - Docking Computer
  - Air Horn
  - Roof Light Bar (just looks)
- **You can see them on the rig:** bumper bars, a spinning radar dish,
  chrome horns, a light bar, exhaust stacks, a crate rack and gold solar
  sails, fitted to whichever rig you drive.
- **Docking computer:** near your load's drop-off it takes the wheel and
  docks you, to its own little waltz. Touch the stick to take over.
- **Air horn:** **B** (or click the left stick). Somebody might honk back.
- **The forklift:** when you take a job, pick **I'LL DRIVE THE FORKLIFT**.
  Carry the pallets into your rig's hold (arrows to drive, E to lift and
  set down). A full, tidy load is gentler on the cargo for that trip.

## What to do

1. Load your save (or play a few deliveries). Note the small date in the
   corner.
2. At Dusty's, look through the four shelves. Buy the Bumper Bars, the Air
   Horn and the Light Bar (cheap), and the Docking Computer if you can.
3. Take a job and **drive the forklift** to load it.
4. Fly out. Look at your rig from the chase cam (and the cinema camera on
   autopilot). Honk at passing traffic.
5. Fly toward your drop-off and let the **docking computer** take you in.
   Listen to the waltz.

## Questions

1. Which bolt-on parts look good, and which look silly (or don't sit right
   on your rig)?
2. Is the forklift fun for a minute, or a chore? Bigger hold, more
   pallets, a timer for a bonus?
3. The docking computer's waltz: charming, or should it be a different
   style?
4. Any upgrade you'd love that isn't there yet?
5. Want outfits and decor next, or story (M8)?

---

# Round 19 (calendar and clock, pink drop-offs, signs on boards, rig tints)

**What you asked for this time:**
- a calendar and an in-lore clock on the HUD, with a 10-minute delivery
  lasting one to three days;
- a 12-month, 365-day calendar with made-up month names, shown on screen
  when you sleep and when the game loads;
- a stronger "go here" for your job on the autopilot map, in its own color;
- signs on boards instead of floating (Lily's pumps and every other one);
- other rigs' interiors mostly the same, with a slight color tint so you
  know which rig you're in.

Round 18 (money: weekly bills, the tab, insurance, rig levels) is in this
build too. Its section is below; play both together. **Time needed:**
about 30 minutes. Start a **new game** to see the calendar from 1 Kindling.

> Honest note: I checked all of this with automated tests and screenshots.
> How fast time should run, and whether the tints are too subtle or too
> strong, are calls only you can make. Both are one number each to change.

## What's new

- **The calendar:** 365 days in 12 months: KINDLING, HEARTHFROST, THAWING,
  WAYFARE, BLOSSOM, LONGLIGHT, HIGHSUN, HAULWIND, GLEANING, LANTERN,
  DRIFTFALL, STARSLEEP (a year's life, from spark to sleep). Each has a
  little line about it.
- **The clock (GST, galactic standard time) runs while you play:** about
  an hour every 15 seconds while flying (so 10 minutes on the road is
  about a day and two-thirds; the long cruise to Tidewater is 3 to 4
  days), an hour a minute while you walk around parked, and a whole night
  when you sleep. Menus and pauses stop it.
- **On screen:** under your money (clock, date, bills countdown, which rig
  you're in), top right in flight (clock and date; the date flashes when
  a day rolls over), on loading screens, and on the **date card** that
  pops up when you load or start a game, and shows in the dark when you
  sleep.
- **Your load's drop-off is hot pink.** Course chart (M): a pulsing pink
  target with a "YOUR LOAD" flag, pink routes, pink menu options. In
  flight: a pink waypoint with "LOAD" under it. The chart also says how
  long each route takes on the calendar, and the job board shows ~days.
- **Signs on boards:** every sign in every room (Lily's pumps, the docks,
  the motel, DISPATCH, the door plates...) now sits on a dark board with
  a neon rim, hanging from the ceiling on cables if there's no wall
  behind it. The big signs in space (the donut, the slot machine, the
  chapel, the border gate) got boards on struts.
- **Rig tints:** every rig has the same rooms inside, with its own soft
  color (the Lazy Susan is unchanged). Its name shows under the calendar.

## What to do

1. **New game.** Watch for the date card (1 KINDLING 5050). Walk around
   for a minute: the clock ticks.
2. Look at **Lily's pumps** at the truck stop and the other signs in the
   rooms. Any still floating?
3. Take a job, take off, and press **M**. Find your load (pink). Pick it
   and fly a while: watch the clock top right.
4. Get up and **sleep in the bunk**: the date shows in the dark, and the
   days jump on.
5. Deliver: the payout card says how long it was on the road and the date.
6. Sleep in your bed while parked: the date card in the dark, and you wake
   at 7:00.
7. If you've got the money, buy a second rig at Dusty's and walk around
   inside. Can you tell it's a different rig?

## Questions

1. **Time speed:** does 10 minutes of flying = about a day and two-thirds
   feel right? Faster or slower?
2. Do the month names fit? Any you'd rename?
3. Is the pink drop-off easy to find now, on the chart and in flight?
4. Signs: any still floating, or any board that looks wrong (too big,
   cables in odd places)?
5. Rig tints: too subtle, too strong, or about right?

---

# Round 18: money and time on the road (M6)

**What you asked for:** build out the next phase of the game, with no
shifts: space truckers' deliveries take a long time (about a week), not
three a day.

**Time needed:** about 20 to 30 minutes. A **new game** is best, so you
start with a fresh calendar (continuing your save also works: you start
on day 1 with no XP).

> Honest note: I checked all of this with automated tests and screenshots,
> but whether the money feels right (too tight? too easy?) is something
> only playing can tell. Every number is in tuning.tres and the data files,
> so it's quick to change.

## What's new

- **No shifts. A calendar** (round 19 made it a real calendar with a clock:
  see above). Sleeping in your bed takes you to the next morning.
  "BILLS IN n DAYS" is under your money.
- **Weekly bills:** 1,500 credits a week to OrbitalEx (berth and dispatch).
  Can't pay? It goes on a **tab**, paid off from your next delivery. No
  interest, no game over.
- **Insurance** at Dusty's: 250 a week, repairs half price.
- **Rig levels 1 to 10:** deliveries earn XP; each level makes the rig a
  bit better at everything. The payout card shows XP and a fanfare on a
  level-up.
- **Better parts, locked by level:** Nitro Keg (L2), Mag-Tread Stabilizers
  (L2), Long-Haul Saddle Tanks (L3), Twin Afterburner Kit (now L3), Racing
  Gyros (L4), Ion Overdrive (L6).
- **Job tags:** RUSH, FRAGILE, PERISHABLE, LIVE and the trip length on the
  job board. Two new live-cargo jobs: glow guppies and space hens.
- **The PC** shows bills next to your invoices, and a few new emails turn
  up (OrbitalEx billing, Dottie, Dusty).

## What to do

1. New game. Look at the top-right corner: day 1, week 1, bills in 7 days.
2. Open the job board and read the tags. Take a long haul (the ~3D or ~4D ones).
3. Deliver it. Watch the payout card (days on the road, XP), then the
   **WEEKLY BILLS** card.
4. Visit Dusty: check your rig's level and XP, and switch insurance on.
   Look at the parts marked LEVEL n.
5. Do a few more deliveries. Try to run a tab once (spend most of your
   money first), then see it paid off by the next delivery.
6. Sleep in your bed a couple of times and watch the calendar move.

## Questions

1. Do trips feel long now, like a real haul, or should they be even longer?
2. Bills: 1,500 a week. Too tight, too easy, or about right?
3. Does levelling the rig feel rewarding? Can you feel it get better?
4. Is the tab a good "cozy" answer to running out of money, or should
   something else happen?
5. What next: **M7 home and style** (outfits, decor, new rigs' handling,
   the docking computer, forklift) or **M8 clients and story** (more
   clients and systems, the husband's story)?

---

# Round 17 (wobbles, doors, bed, TV console, crashes, station labels)

**What you asked for this time:**
- speed wobbles about 50% gentler;
- rooms switching sooner (no walking off-screen to find the hallway);
- the bed working every time;
- a console on Jacki's TV with small games;
- physics-based crashes;
- station names on the HUD instead of written on the stations.

## Try these

1. **Boost** for a few seconds: the wobbles should be half as wild.
2. Climb down the cockpit stairs and **walk toward the hallway door** in dispatch. You should go through as soon as you leave the picture, without hunting off-screen.
3. Set a course, get up, and **switch the autopilot off** (or wait until it arrives), then **sleep**. It should still work: it sets a course for your job and sleeps you there.
4. Walk up to the **TV** in Jacki's room and press E: the **TATER-16**. Try Carrot Catch, Comet Tail and Paddle Pods (against Digby).
5. **Crash on purpose:** boost into a big rock with its top edge above you, then with its edge to your left. You should be knocked down, then to the right, tumbling. (You'll go back to your last save, as before.)
6. Fly toward a station: **no writing on it**. The green ID label names it once you're within 6 km, and traffic control calls before you reach the rocks.

## Questions

1. Are the wobbles right now, or still too much (or now too little)?
2. Did any door still make you walk off-screen? Which room?
3. Which TATER-16 game is your favorite? Want more (a racing one, a fishing one...)?
4. Do the crashes feel physical now?
5. Is the green label enough to know where you are, or do you want the station's name on the radar too?

---

# Round 16 (leaving conversations, sounds and voices, rocks all around, thrusters, speed wobbles, nine rigs)

**What you asked for:**
- walk away from (or cancel) conversations;
- more sound effects;
- voices in different pitches and keys;
- asteroid fields that surround the stations in 360 degrees;
- MML / MGS1 textures on the asteroids and planets, with less smoothing on the planets;
- cooler thrusters and mouse wheel zoom;
- boost that shakes like speed wobbles instead of veering off;
- more of the main game: your design sheets as rigs to buy.

**Time needed:** about 30 to 40 minutes. Continue your save or start a new
game; both work. To try the rigs quickly, a new game won't have enough
money, so play a few deliveries first (or try the cheap Garbage Scow at
4,500).

> Honest note: I checked all of this with automated play-throughs and
> screenshots, but how the voices sound, how the speed wobbles feel and
> how hard the rocks are to fly through are things only you can judge.

---

## What's new

- **Leaving a conversation:** press **Esc / B** (it says "BYE" in the box's
  corner), or just **walk away**. Leave early and they'll say it again next
  time, job offers included.
- **Sounds:**
  - menus tick and blip;
  - accepting a job stamps it;
  - setting an autopilot course gets a nav computer beep-beep-boop, and two falling beeps when the autopilot lets go;
  - getting paid and buying things ring a cash register;
  - finding a lost thing sparkles, ship events chime, doors hiss.
- **Voices:** everyone has their own voice type, key and scale. Every letter is a real note, so each character's chatter is a little tune of their own:
  - Digby grumbles in C minor;
  - Pip squeaks in A major;
  - Sal croons the blues;
  - Jacki drawls in D blues.
- **Rocks all the way round:** the truck stop, Tidewater (ice), the Gas-N-Go (scrap) and Sal's casino (casino chips) sit inside a ball of rocks 1.5 to 2.7 km out.
  - No going over, under or around.
  - One clear **traffic lane** leads in to the approach ring; off the lane, you pick your way through.
  - The autopilot goes round the ball to the lane.
- **Thrusters:** flickering flames that stretch with the throttle and shower sparks; boost flashes, roars out long and blue-white, and gets shock-diamond bands. The trails pulse with plasma and fade to purple.
- **Mouse wheel** zooms the chase camera in and out.
- **Boost = speed wobbles:** the longer you hold boost, the harder it shakes (the nose shimmies, the hull rocks, the screen shakes), and it slowly pulls off course. Let go and it settles.
- **Planets and rocks** are repainted MML / MGS1 style, with crisp pixels on the planets.
- **Nine new rigs at Dusty's**, from your design sheets, each with its own handling and pay:
  - Garbage Scow
  - Ice-Tug
  - SLAB (Stack-Ship)
  - Catamaran
  - Cryo Tanker
  - Hab-Brick
  - Bulk-Ore
  - Ore-Crawler
  - Omega Ore Crawler

## What to do

1. Talk to the crew aboard. Walk away mid-sentence once, and press Esc once. Listen to how different everyone sounds.
2. Take a job and listen for the stamp. Undock and fly to the truck stop's rock ball.
3. Try to fly through the rocks off the lane. Then find the lane (follow the approach ring's direction) and fly it in.
4. Set a course (M), listen for the nav computer, and let the autopilot take you somewhere. Watch it go round the rocks.
5. Hold boost for a few seconds in open space. Feel the speed wobbles build, then let go.
6. Scroll the mouse wheel while flying.
7. Earn some money and buy a new rig at Dusty's (the mechanic's menu, then RIGS FOR SALE). Fly it and feel the difference.

## Questions

1. Do the voices sound like different characters now? Anyone's voice that doesn't fit them?
2. The rocks: too thick, too thin, or about right? Is the lane easy to find?
3. Boost speed wobbles: does it feel like what you described (shaking harder, drifting slowly)? More shake or less?
4. The thrusters and the plasma trails: cool enough, or do you want them bigger or brighter?
5. Which new rig is your favorite, and does any feel wrong for how it looks?
