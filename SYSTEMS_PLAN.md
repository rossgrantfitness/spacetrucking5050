# New systems: the plan (nothing built yet)

Seven systems you'd like, as **cards**. Each card says what it is, what
already exists to build on, and what it would cost. **Nothing here gets
built until you say "go"** on a card. Then it's built on its own, tested
and handed to you to playtest before the next one starts.

---

## How we add a system (the framework)

Every system goes through the same five steps:

1. **Card.** Its entry below: how it plays, the breakdown, and open
   questions.
2. **Your go.**
   - Reply with the card's name ("go truck weight") and answer its open
     questions. Or say "use your defaults".
   - You can also say "change X", "skip it" or "do it later".
3. **Smallest playable version first.**
   - I build the simplest version that's fun, behind an **on/off switch**
     (see step 0).
   - Its content goes in data files, not code: breakdowns, contraband
     goods, lines.
   - Its numbers go in `tuning.tres`, so you can adjust them without me.
4. **Checked and handed over.** The usual round:
   - tests and validation;
   - `DECISIONS.md`;
   - a `PLAYTEST.md` card with what to try and 3–5 questions.
5. **Your verdict: keep, tune or cut.**
   - Cut means flipping its switch off. Nothing else breaks.
   - Then we pick the next card.

**Rules every card follows** (from the brief's pillars):
- Cozy first: nothing can fail you, kill you or block a delivery.
- Ignoring a system is always allowed; it only costs a little.
- No explosions (volatile cargo fizzes, it doesn't blow up).
- No real brands.

### Step 0: shared groundwork (do this first, whichever card you pick)

Several cards need the same three pieces. I'd build them once, up front:

- **System switches.** One on/off switch per new system, in the pause
  menu's options and in `tuning.tres`. That's how "cut" stays painless,
  and how players who just want to drive can turn things off.
- **Aboard tasks.** One shared way for something aboard the rig to:
  - need attention ("the hallway fuse blew");
  - show itself (sparks, steam, a blinking light);
  - call you on the comm;
  - cost a little over time while ignored;
  - get fixed with a hold-the-button interaction.

  Each task is a data file. Maintenance, volatile-cargo clean-ups and the
  hull breach all use it.
- **Cargo traits.** Jobs get a few new data fields: `weight` (tons),
  `contraband` (yes/no) and a new care kind, `volatile`. Truck weight,
  contraband and volatile cargo all read these.

| | |
|---|---|
| **Time** | 1 round (a round is like the earlier ones: build, about 30 min of validation, docs) |
| **Difficulty** | ★★☆☆☆ |
| **Cost to the project** | Small. New data types and a menu section; touches nothing you play yet. |
| **Your effort** | None. Nothing to playtest until a card uses it. |
| **Risk** | Low |

---

## How to read the breakdowns

- **Time:** work rounds from me, plus your playtest time.
- **Difficulty:**
  - ★ = straightforward;
  - ★★★★★ = new territory, likely to need a couple of tuning passes.
- **Cost to the project:** how much existing game it touches, and what art
  or sound you'd want to make for it eventually (I always start with
  placeholders, so nothing waits on you).
- **In-game cost:** what it costs or pays the *player*. Starting numbers
  only, all tunable.

---

## The cards, in my recommended order

Cheap wins first. Shared parts get reused. The riskiest work comes last.

### 1. Truck weight (heavy loads feel heavy)

**How it plays:**
- Every load has a weight. Heavy loads give slower acceleration, wider
  turns and longer stopping.
- The cargo section has a little visible sway.
- It's the same arcade handling, just with heft.

**What exists:**
- The brief already asks for this ("cargo weight reduces turn rate and
  acceleration"), and **it isn't built yet**, so this also closes a gap.
- The flight model already has per-rig acceleration, turn and braking
  numbers. Weight would scale them.

**New:**
- A weight on each job.
- Weight scaling in the flight model.
- A gentle sway on the rig's back half.
- Weight shown on the job board ("12 t, HEAVY").

| | |
|---|---|
| **Time** | 1 round. Then 15 minutes of your flying. |
| **Difficulty** | ★★☆☆☆ (the code is easy; the feel needs your judgment) |
| **Cost to the project** | Small: the flight model, job data and the rig visuals. No new assets needed. |
| **In-game cost** | None directly. Heavy jobs could pay a bit more (+10–25%). |
| **Risk** | Low. Worst case, flying feels sluggish; one number fixes it. |

**Open questions:**
- How heavy is "heavy"? I suggest a full heavy load at about 70% of the
  turn rate and 60% of the acceleration.
- Should upgrades (Stacking Racks, the cradles) also cut how much weight
  hurts?

### 2. Internal maintenance during flight

**How it plays:**
- While the autopilot flies, small things break now and then:
  - a blown fuse in the hallway;
  - a clogged air filter;
  - a steam leak;
  - a sparking panel.
- A crew member calls on the comm. Jacki walks back and holds E for a
  couple of seconds to fix it.
- Ignore it and nothing bad happens, it just slowly costs a little fuel
  or cargo condition.

**What exists:**
- Walking the rig's rooms during autopilot.
- Crew comm calls.
- Ship events: the coffee machine already breaks.
- Interact prompts.

**New:**
- The breakdowns themselves (4 to start, as data).
- Effects for each: sparks, steam, a blinking fuse box.
- A warning light in the cockpit.
- The fix interaction (a short pose and sound).
- The slow cost while ignored.

| | |
|---|---|
| **Time** | 1–2 rounds. Then 20 minutes of your play. |
| **Difficulty** | ★★★☆☆ |
| **Cost to the project** | Medium: rig rooms, the flight scene, crew lines. Eventual assets you could make: a fuse box, an air filter panel, steam and spark sounds. |
| **In-game cost** | An ignored fault costs about 1% fuel or 1% cargo condition per in-game hour. At most one or two faults per trip. |
| **Risk** | Low–medium. The main risk is it feeling like a chore, so it starts rare (roughly every other trip). |

**Open questions:**
- ~~Who calls?~~ **Settled:** Chang Ma (the mole engineer, formerly
  Digby). The starter rig is now **the Thumper**.
- Should a fixed fault ever give a small reward (a crew thank-you, a
  little XP)?

### 3. Volatile cargo (fizz, never boom)

**How it plays:**
- A new kind of careful cargo: soda syrup, foaming bath bombs, yeast.
- Hard knocks make it **fizz, pop or foam over**:
  - a burst of foam in the cargo bay;
  - a sound;
  - the care bonus shrinks;
  - Clem grumbles about the mess.
- The mess can be mopped up (an aboard task) for a bit of the bonus back.

**What exists:**
- Careful cargo (fragile, perishable, live) with shrinking bonuses.
- The cargo bay room.
- Bonks.

**New:**
- The "volatile" kind.
- Foam and pop effects.
- Mess clean-up (reuses step 0's aboard tasks).
- 3–4 new jobs.
- Grumble lines.

| | |
|---|---|
| **Time** | 1 round (after step 0) |
| **Difficulty** | ★★☆☆☆ |
| **Cost to the project** | Small. Sounds you could make later: fizz, pop, a squelchy mop. |
| **In-game cost** | Pays like fragile cargo. Each fizz-over costs about 25% of the care bonus; mopping wins back half. |
| **Risk** | Low |

**Open questions:** none needed; I'll invent the cargo, unless you have
favorites.

### 4. Contraband, played for laughs

**How it plays:**
- Some jobs are a bit shady:
  - undeclared cheese wheels;
  - unlicensed rubber ducks;
  - bootleg mixtapes.
- They pay more. Deputy Biscuit's speed-trap buoys also **scan**, so
  passing near one is a chance to get caught.
- Getting caught means a fine and a very disappointed comm call. Never
  jail, never lost cargo, never a failed job.
- Raccoony disapproves loudly and pays you anyway.

**What exists:**
- Deputy Biscuit.
- Speed-trap buoys with fines and comm calls.
- Job data.
- Raccoony's lines.

**New:**
- Contraband jobs (5–6, as data).
- Scanning at the buoys.
- Fine rules.
- Biscuit's and Raccoony's new lines.
- A little "?" stamp on the job board.

| | |
|---|---|
| **Time** | 1 round |
| **Difficulty** | ★★☆☆☆ |
| **Cost to the project** | Small: jobs, the hazard buoys, dialogue. No assets needed. |
| **In-game cost** | Pays +40%. Fine is about 30% of the pay if scanned. About a 1-in-3 chance per buoy you pass close to. Fly wide of buoys to dodge (a little skill, not stress). |
| **Risk** | Low |

**Open questions:**
- ~~"Raccoony" is Raccoony?~~ **Settled:** the raccoon dispatcher is now
  Raccoony.
- Should getting caught ever confiscate the goods, or only fine you? My
  default: only a fine. Confiscation feels bad.

### 5. Multi-leg contracts (instead of 45–90 min hauls)

**How it plays:**
- Optional big contracts with 2–4 legs, each 10–20 minutes.
- Stops at the Gas-N-Go and the truck stop between legs: refuel, snack,
  crew time aboard.
- Paid per leg, with a completion bonus at the end. You can stop between
  legs and sleep; the contract waits.

**What exists:**
- Jobs.
- The course chart.
- Refuelling.
- The calendar (a 10-minute trip already spans 1–3 days).
- Crew life aboard.

**New:**
- A job with several stops: data, the job board, the course chart and the
  HUD all need to show "leg 2 of 3".
- Saving mid-contract (a save-format change).
- Leg payouts.
- 2–3 contracts to start.

| | |
|---|---|
| **Time** | 2–3 rounds. Then about 1 hour of your play (it's long by nature). |
| **Difficulty** | ★★★★☆ (touches the heart of the delivery loop) |
| **Cost to the project** | Large: jobs, saves, payouts, the course chart and HUD, and the play-through tests. No assets needed. |
| **In-game cost** | Each leg pays like a normal job. Finishing all legs adds +30%. |
| **Risk** | Medium. The most likely to break something that already works, which is why it comes after the small cards. |

**Open questions:**
- Leg length: is 10–20 minutes right as a default? Today's trips are
  about 10 (the Tidewater haul about 20).
- Can she take other small jobs between legs, or is the contract
  exclusive while active?

### 6. Manual docking (optional skill)

**How it plays:**
- At the approach ring, choose **AUTO** (as today) or **MANUAL**.
- Manual switches to a slow maneuvering mode. She backs the cargo section
  into the bay using:
  - a **rear camera feed** in a corner screen;
  - side mirrors;
  - guide lines.
- A clean dock (slow, lined up, no bumps) earns a tip. Bumping is just a
  bonk.

**What exists:**
- Approach rings.
- Auto-dock.
- The docking computer.
- The chase and cockpit cameras.

**New:**
- A slow maneuvering mode that can **reverse** (today the rig only goes
  forward).
- A docking bay at each of the 4 stations.
- The rear camera feed and mirror overlay.
- Guide lines.
- Scoring and the tip.

| | |
|---|---|
| **Time** | 2–3 rounds. Then 30 minutes of your play, probably twice (feel tuning). |
| **Difficulty** | ★★★★☆ |
| **Cost to the project** | Medium–large: the flight model, stations, cameras and HUD. Assets you could make later: bay interiors, a "reversing" beep. |
| **In-game cost** | Tip: +5–10% of the pay for a clean dock. |
| **Risk** | Medium. Feel-heavy: expect a tuning round. |

**Open questions:**
- Your note mentions "tip or reputation". There's no reputation system
  yet. Use tips only for now?
- Mirrors and a rear camera both, or start with just the rear camera?

### 7. Hull patching in a spacesuit (rare event)

**How it plays:**
- Rarely (about 1 trip in 10), a micrometeoroid pokes a hole.
- Air hisses and a light blinks. She goes to the airlock, suits up and
  steps outside onto a stretch of hull while the autopilot flies.
- She walks over with magnetic boots, holds a button to weld a patch, and
  comes back in. About 2 minutes. You can't fail and can't float away.
- Ignoring it just leaks a little cargo condition.

**What exists:**
- Walking the rig.
- Aboard tasks (step 0).
- The on-foot controller and fixed cameras.

**New:**
- A spacesuit look for Jacki.
- An airlock.
- A separate "outside the hull" scene: a hull section with the real space
  sky rushing past, not her actual rig's hull (14 rigs of different
  shapes would be a huge job).
- Walking with mag-boots.
- The weld.
- Suit sounds: breathing, muffled space.

| | |
|---|---|
| **Time** | 3+ rounds. Then 20 minutes of your play. |
| **Difficulty** | ★★★★★ (new scene type, new movement, a costume swap with outfits parked) |
| **Cost to the project** | Large. Assets you'd ideally make: Jacki in a spacesuit (a Meshy model from an A-pose sketch, same pipeline as before), a welding torch. Sounds: suit breathing, welding fizz. |
| **In-game cost** | Free to fix. Ignored, about 2% cargo condition per in-game hour until docked. |
| **Risk** | Medium–high, but isolated: it's its own scene, so it can't break flying. |

**Open questions:**
- Do you want to make the spacesuit model, or should I build a
  simple-shapes suit as a placeholder?
- Is the outside view fixed cinematic cameras (like the rooms), or a
  follow camera?

---

### 8. The forklift: rework it or scrap it (your call)

You said the loading dock "is cool but it sucks": not fun to play. The
two honest options:

**Option A: scrap it**
- The "who loads it?" question goes away; the dock crew always loads.
- The code stays in git history, so it can come back.

| | |
|---|---|
| **Time** | Under an hour |
| **Difficulty** | ★☆☆☆☆ |
| **Risk** | None |

**Option B: rebuild it to feel like GTA**

What makes a vehicle fun in GTA:
- **Weight and momentum.** The forklift leans, skids and bounces on its
  springs.
- **A physics mess you can make:** crates stacked on pallets that topple
  and tumble when you hit them, cardboard boxes that scatter.
- **Juice:**
  - a lagging chase camera that swings in turns;
  - an engine whine that rises with speed;
  - tire squeal, crash thumps, a horn.
- **Something to aim for:**
  - an optional timer for a bonus;
  - points for a neat stack;
  - dock workers and other forklifts to weave around;
  - maybe a ramp or two.

| | |
|---|---|
| **Time** | 2–3 rounds, plus 1–2 feel-tuning passes with you |
| **Difficulty** | ★★★★☆ (stacking physics in Godot can jitter and needs care) |
| **Cost to the project** | Medium: the dock scene and forklift are rewritten; nothing else changes. Assets you might make later: a forklift model, crates, engine and squeal sounds. |
| **Risk** | Medium. Fun can't be checked by tests; it needs your hands on it. |

**My recommendation: A for now** (scrap it). Loading isn't the heart of
the game; the drive is. If you still miss it after beta, Option B is a
self-contained project we can pick up any time.

---

### 9. Phones: iOS and Android versions

**Yes, it's possible.** Godot exports to both, and the game already uses
Godot's "Compatibility" renderer, the one made for phones and older
hardware. The game itself doesn't need rewriting. What's missing is
everything a phone needs that a PC doesn't.

**What it takes:**

| Piece | Why | Time |
|---|---|---|
| **Touch controls** | Right now it's keyboard, mouse and gamepad only. Phones need an on-screen stick for walking and steering, a throttle, and buttons for use, boost, radio and course chart. Phones can also pair a Bluetooth gamepad, and that already works. | 2 rounds |
| **Phone screen pass** | Bigger default text and buttons (the menu size setting helps), landscape-only, and hiding the PC-only bits (window size, fullscreen). | 1 round |
| **Speed pass** | Phones are slower than PCs. The asteroid fields (thousands of rocks), the painted room backgrounds and the HUD's extra rendering need a "phone" quality level. Needs testing on a real phone. | 1–2 rounds |
| **Your own music station** | Dropping music files into a folder is easy on Android, awkward on iPhone. Probably Android only. | small |
| **Builds** | **Android:** I can set up the export; you build and install it from your PC (free to test; Google Play costs a one-time $25 to publish). **iPhone:** building needs a **Mac with Xcode** and an Apple Developer account ($99 a year), and testing goes through TestFlight. | 1 round of setup |

| | |
|---|---|
| **Time** | About 5–6 rounds for a good Android test build; iPhone on top of that needs the Mac |
| **Difficulty** | ★★★☆☆ (well-trodden in Godot; the unknown is speed on real phones) |
| **Cost to the project** | Medium. Touch controls and quality levels touch input, the HUD and a few heavy scenes. Real-world costs: the store fees above, and a Mac for iPhone. |
| **Risk** | Low for the PC game: phone bits sit behind "is this a phone?" checks. |

**My recommendation:** finish the PC beta first (that's where your
playtesting is). Then do Android (cheaper, no Mac needed), then iPhone
if Android goes well. The brief puts export presets in M10, so this fits
there.

---

## The flight physics question: Newtonian inertia vs. heavy truck controls

You asked how achievable the "hybrid" model is before deciding. Short
answer: **it's not a monumental job. One part is cheap and fits the
game; one part fights your own design brief.**

### What exists today
- The flight model is **one script** (`FlightModel.gd`, about 300 lines).
- Every number lives in data: each rig has its own top speed,
  acceleration, retro-thrust (braking), turn rate and turn response.
- It already has a little "grip": the rig's motion is pulled toward
  where its nose points, and it can slide a bit when overspeeding.
- There's no strafing at all, which already matches the "semi-truck
  constraints" idea.

### The three parts, separately

| Part | What it means | Time | Difficulty | Fits the game? |
|---|---|---|---|---|
| **Momentum and mass** | Heavy loads take longer to get going, longer to stop (plan your braking before the ring), and swing wide in turns because the grip is lower. Still goes where the nose points, eventually. | 1–2 rounds (grows card 1, truck weight) | ★★☆☆☆ | **Yes.** This is the trucker fantasy, kept gentle. |
| **Trailer sway, reversing into a bay** | Visual sway of the cargo section: cheap (in card 1). A real hinged trailer that swings behind you and that you reverse into an airlock with mirrors and camera feeds is card 6 (manual docking) plus a trailer. | Sway: in card 1. Real trailer: +2 rounds on top of card 6. | ★★★★☆ | Optional skill content, if you want it. |
| **Flight Assist Off** (true drift) | Switch off the grip completely: the rig keeps sliding in whatever direction it was going until you fire thrusters to stop it. | The toggle itself: 1 round. Making the autopilot, docking rings, speed traps, gravity wells and cameras work in both modes: another 2–3. Then every future feature has to be tested twice. | ★★★★☆ | **Against your brief.** CLAUDE.md's "hard don'ts" say *no Newtonian drift flight model*, and pillar 3 says *arcade feel, never Newtonian drift*. |

### My recommendation
- **Do momentum and mass** as an upgraded truck-weight card (about 2
  rounds instead of 1). It gives the "200 tons of steel beams" feeling
  without the frustration.
- **Skip Flight Assist Off**, unless you decide to change the brief. If
  you ever want it, it fits best as an optional "hard mode" switch much
  later. It never belongs in the default game.
- **Real trailers:** decide after manual docking (card 6), since they
  only matter for reversing.

### "The thrust needs tweaking"
Happy to tune it right away (it's a few numbers in each rig's data file),
but I need to know which way. Is it:
- too slow to get going;
- too slow to stop;
- too floaty or too twitchy;
- boost too weak or too strong?

One sentence on what feels off and I'll adjust it in a round.

---

## Totals

| Card | Rounds | Difficulty | Touches existing game |
|---|---|---|---|
| 0. Groundwork | 1 | ★★ | barely |
| 1. Truck weight | 1 | ★★ | flight feel |
| 2. Maintenance | 1–2 | ★★★ | rig rooms, flight |
| 3. Volatile cargo | 1 | ★★ | jobs, cargo bay |
| 4. Contraband | 1 | ★★ | jobs, speed traps |
| 5. Multi-leg contracts | 2–3 | ★★★★ | the delivery loop, saves |
| 6. Manual docking | 2–3 | ★★★★ | flight, stations, cameras |
| 7. Spacewalk | 3+ | ★★★★★ | its own scene |
| 8. Forklift: scrap / rebuild | under an hour / 2–3 | ★ / ★★★★ | the dock only |
| Heavy-truck physics (momentum, no FA-off) | 1–2 (grows card 1) | ★★ | flight feel |
| 9. Phones (Android, then iOS) | 5–6 | ★★★ | input, HUD, quality levels |
| **All seven** | **about 12–15 rounds** | | |

**My recommendation:**
- Start with **0 + 1 together** (one round: groundwork plus truck weight,
  so you get something to feel right away).
- Then 2 → 3 → 4, each its own round.
- Decide on 5, 6 and 7 after playing those. You may find the game wants
  some of them more than others.
