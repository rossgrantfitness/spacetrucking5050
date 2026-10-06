# Playtest: round 27, looking around (round 26's overdrive below)

**What you asked for:** the mouse should swing the camera around the rig
in every direction, with the rig in the middle; maybe right-click to pan;
I J K L to fly the ship; gamepad first.

**Time needed:** 5 minutes.

## What to do

1. Fly (manual, no autopilot). Move the mouse: the camera swings round
   the rig. Look at it from the side, from the front, from underneath.
2. Hold the **right mouse button** and drag to pan. Wheel to zoom.
   **Middle-click** to snap back behind.
3. Let go of the mouse for 4 seconds: the camera drifts back behind.
4. Steer with **I J K L** (I/K nose, J/L turn; she leans into turns by
   herself).
5. On a gamepad: right stick looks around, left stick steers.
6. Set a course (M) and, with the mouse free, **left-drag** to look
   around while she drives.

## Questions

1. Is the mouse speed right? Too slow, too fast?
2. Should the camera drift back behind after 4 seconds, later, or never?
3. Mouse up = look up. Do you want that flipped?
4. Is J/L turning enough, or do you want a real barrel roll on a key?
5. Do you want the mouse to look around in the cockpit view too?

---

# Playtest: round 26, overdrive (round 25 below)

**What you asked for:** boost keeps climbing past ~800 km/h, toward
2,500 km/h and beyond. The wobbles and cargo damage get worse the faster
you go, with repeated warnings and comm chatter, until the rig can't take
its own speed and explodes. Then no WRECKED card: just the explosion and
a prompt to reload.

**Time needed:** about 10 minutes.

## What to do

1. Get flying with full boost (F10 → "FILL UP AND FIX UP" if you need
   it). Set the throttle to full and hold **boost** (Space / A), and
   keep holding past ~800 km/h.
2. Watch the speed climb (about 30 km/h a second).
   - **OVERDRIVE** shows by the speed bar.
   - Past about 1,800 km/h the **HULL STRAIN** bar fills above the
     speed.
   - Listen for the alarm and the calls, and read the banners.
3. Let go once at about 70% strain: it should calm right down.
4. Then do it again and don't let go. Enjoy the fireball. Press a key at
   the prompt.

## Questions

1. Is the climb past 800 too slow, too fast, or about right to build
   tension? (About a minute to 2,500 km/h.)
2. Are there enough warnings, or too many?
3. How long can you hang on at 2,500 km/h before it blows? (About 20 s
   now.) Too short, too long?
4. Does it feel out of control at 2,000+, or still too steady?
5. The reload prompt: good, or do you want it to restart by itself after
   a few seconds?

---

# Playtest: round 25, heavy loads, watch mode, the debug menu (round 24 below)

**What you asked for:**
- momentum and mass, no drift;
- the throttle stopping at zero before reverse;
- cargo weight on the HUD, in ridiculous numbers;
- a debug menu to start a few minutes out;
- leaving the game running while you work;
- the forklift scrapped.

**Time needed:** about 20 minutes (much less with the debug menu).

> Honest note: tests prove a full load speeds up slower, stops in a much
> longer distance, turns slower and still goes where its nose points.
> Whether it FEELS like hauling 1.8 billion tons is yours to judge. Every
> number is under "Load weight" in tuning.tres.

## What's new

- **Heavy loads:**
  - Your load's weight shows under PAY on the flight HUD
    (**LOAD 450M T**): green is light, yellow heavy, red overloaded for
    your rig.
  - A heavy load is slow to get going, slow to stop (brake early!), turns
    wider and rocks a little after a turn.
  - The job board tells you the weight and warns you when it's heavy for
    the Thumper.
- **Throttle:** holding S now stops at idle. Let go and press S again to
  back up.
- **Watch mode:** set a course with M and the game lets go of your mouse.
  Leave it running and do something else; it docks itself.
- **Debug menu: F10** anywhere.
  - Jump 1, 3 or 5 minutes out from any station, lined up on autopilot.
  - Skip the opening.
  - Get +5,000 credits.
  - Fill up and fix up.
- **Forklift:** gone. Jobs load instantly again.

## What to do

1. F10, "SKIP THE OPENING", then F10, "GIVE ME A JOB": pick a heavy one
   (**poker chips**, 1.8 billion tons, or **cannery parts**, 2.2
   billion).
2. Fly it by hand for a minute: speed up, turn, and brake hard. Then try
   a light one (mail bags, 150 million tons) and compare.
3. F10, jump 3 minutes out from Tidewater, and fly the approach yourself.
   Is braking for the ring a fun bit of planning, or annoying?
4. Set a course (M), zoom out with the wheel, click another window and
   leave it running for a few minutes. Does it keep going? Is the mouse
   free?
5. Slow down with S and keep holding: it should stop at zero, not
   reverse.

## Questions

1. Do heavy loads feel heavy? Too much, too little?
2. Is the braking distance with a heavy load OK, or does it make docking
   a chore?
3. The galactic tons on the HUD: funny? Readable?
4. Watch mode: anything that interrupted it (calls, popups)?
5. Is the debug menu missing anything that would save you time?

---

# Playtest: round 24, the opening and objectives (round 23's sounds below)

**What you asked for:**
- the bed fixed;
- the opening: Raccoony sends you to the wheel, then calls you to the
  truck stop, with a marker over Marge;
- an objective on screen at all times;
- the radio dipping for story calls;
- the names: Thumper, Chang Ma, Raccoony.

**Time needed:** about 15 minutes. **Start a NEW GAME** (title screen,
the small new-game button), or you'll skip the opening.

## What's new

- **The bed works in flight.** E at the bed now puts her to sleep till the
  next stop (the same press used to wake her straight back up).
- **The opening:**
  - You start in dispatch and Raccoony starts talking right away.
  - Go up the stairs and take the wheel. A moment later he calls you:
    pull into the truck stop.
  - Follow the yellow diamond, fly through the ring, walk out the airlock
    and find Marge.
- **Objective line:**
  - On foot it's at the top left; flying, it's under the compass.
  - On foot, a yellow diamond bobs over the door or stairs it means.
  - A solid yellow "!" hangs over the person you need, and over anyone
    with a job for you.
- **Story calls dip the radio** to half volume until they're done.
- **Names:** your rig is the Thumper; the engineer is Chang Ma; dispatch
  is Raccoony (he).

## What to do

1. New game. Listen to Raccoony, then follow only the objective line and
   markers. Never look anything up.
2. Take the wheel. Have the radio on (Subspace FM is good) when Raccoony
   calls: does the music dip and come back?
3. Fly to the truck stop, go in, find Marge, take her job.
4. In flight on the long haul, set a course (M), get up (F), go to your bed, press E. You
   should sleep and wake up near Tidewater.

## Questions

1. Did you ever not know what to do? Where?
2. Is the objective line easy to read, and in the right spots?
3. Is the "!" over Marge easy to spot? Too small?
4. The radio dip: right amount? Too slow or quick to come back?
5. Raccoony's opening lines: does his voice feel right as a "he"? Want
   different words?

## Waiting on you (not built)

See `SYSTEMS_PLAN.md`:
- **Forklift:** scrap it (my recommendation) or rebuild it GTA-style
  (2–3 rounds).
- **Flight physics:** momentum yes (about 2 rounds); "Flight Assist Off"
  breaks your brief's "no Newtonian drift" rule.
- **"The thrust needs tweaking":** tell me which way (too slow to get
  going, too slow to stop, too floaty, boost too weak or too strong) and
  I'll tune it.

---

# Playtest: round 23, pleasant sounds (rounds 21 and 22 below)

**What you asked for:** sound effects that feel good, following the
Japanese idea of pleasant product sounds: consonant notes, soft starts,
no shrill highs, sounds that don't nag when you hear them a lot.

**Time needed:** about 10 minutes. **Use headphones or decent speakers**
for at least part of it, and play at a normal volume.

> Honest note: I can measure sounds (how much harsh treble, how loud, how
> fast they start) but I can't hear them. Whether they *feel* nice is
> yours to judge. Every sound is made from math in
> `scenes/common/SfxSynth.gd`; tell me "warmer", "brighter", "shorter",
> "more wood", whatever you hear.

## What's new

- **One key, one signature:** every menu and game sound plays notes from
  one gentle five-note scale (A major pentatonic), so they never clash.
  The startup chime, taking a job, getting paid and notices all share a
  little three-note signature (up, then up again).
- **Wood, glass and felt** instead of electronic beeps: a little marimba
  tick when you move through menus, a glass "ba-ding" to confirm, soft
  felt notes stepping down to go back.
- **No sound plays exactly the same twice:** busy sounds have three
  versions, and the menu tick wanders between notes as you scroll, like a
  wind chime.
- **New startup chime:** a soft breath, the signature on glass, then a
  warm chord that blooms in slowly.
- **New little sounds:** the vending machine's clunk, the forklift's forks
  lifting, a padded bump, and a gentle "mm-mm" when something doesn't work
  (missing a pallet, not enough money). No buzzers.
- The out-of-control alarm is the only "sour" sound left (that's its job),
  but it's rounder now.

## What to do

1. Start the game and listen to the startup chime.
2. In the title screen and pause menu, scroll up and down through buttons
   for a while. Confirm and back out a few times.
3. Take a job, set a course, let the autopilot go. Get paid.
4. Buy something from a vending machine. Try to buy something you can't
   afford.
5. Walk through a few doors.
6. If you like, load a rig with the forklift.

## Questions

1. Does the startup chime feel like *your* game saying hello? Too long,
   too quiet, too sleepy?
2. Scrolling menus for a minute: pleasant or annoying? Should the tick
   stay on one note instead of wandering?
3. Is anything now too quiet or too soft to notice (doors, the menu tick)?
4. Getting paid: does it feel rewarding enough? (It used to be bright
   coins; now it's softer and warmer.)
5. Any sound you miss from before?

---

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
