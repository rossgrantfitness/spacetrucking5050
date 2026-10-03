# Playtest: M1, round 2 (momentum + rocket boost)

**Your round-1 verdict:** flying is chill and pleasant, and the distances feel
right. You asked for real momentum (inertia, coasting, braking by thrusting
backward, overshooting), a boost that truly *rockets* you on its own buyable
fuel, and an engine hum that reacts more. This round checks that it's still
**FUN and CHILL** with all that added.

**Time needed:** 10-15 minutes, with music in another app again.

> Honest note: I flew it on autopilot and checked the numbers and frames
> (boost takes you from about 190 to 600 km/h in two seconds, and turning while
> boosting slides you hard), but only you can say whether it's fun.

---

## What's different

- **Thrust, coast, brake.** Hold **W** / **RT** to burn forward. Let go and you
  coast at that speed. To slow down, hold **S** / **LT** (reverse thrust); keep
  holding and you'll back up slowly.
- **Momentum in turns.** Your path swings around after the nose, so turns
  carve wide and you can overshoot, especially fast. The **gold ring** shows
  where you're actually heading.
- **Boost is a rocket** (**Space** / **A**): about three times top speed, a
  kick of screen shake, and much less grip, so it gets wild. The extra speed
  bleeds off slowly afterwards.
- **Boost fuel** (the inner cyan arc on the gauge) doesn't refill by itself.
  Fly close to the **TRUCK STOP** to top it up (the marker says so), or use
  *Back to the start*. Buying fuel arrives in M2.
- **The engine hum reacts to you:** it surges when you burn, settles when you
  coast, revs up at boost speed, dips in reverse and hisses when you slide.
- **Screen shake** has an on/off switch in the pause menu.

## What to do

1. Pull the update in GitHub Desktop (*Fetch origin*, then *Pull*), press
   **F5**, then **Enter** / **Start**.
2. Cruise around for a few minutes like last time. Get up to speed, let go,
   and just coast.
3. Try a hard turn at full speed and watch the gold ring slide.
4. Try to **stop right next to a big rock** or the station. Can you judge your
   braking?
5. Boost through the asteroid field. Try turning mid-boost.
6. Run the boost tank dry, then go top it up at the truck stop.
7. Optional knobs to play with (hover each for an explanation):
   `data/ships/starter_rig.tres` → **Grip** (lower = slidier), **Retro
   Thrust** (lower = harder to stop), **Boost Speed Bonus**; and
   `data/tuning.tres` → **Flying → Overspeed Drag** (how long boost speed
   lingers), **Boost Grip**.

## What to pay attention to

- Does momentum make cruising *more* fun, or does it get in the way of
  chilling?
- Is braking satisfying, or a chore?
- Is boost scary-fun, or just scary?
- Any motion sickness from the shake or the slides?

---

## Questions for you

1. **Momentum:** is it the right amount? More slide, less slide, or just
   right? (Grip is one number, easy to dial in.)
2. **Braking and overshooting:** fun challenge or annoying? Would you like a
   "stop the ship" assist button for lazy moments, or is that cheating?
3. **Boost:** does it finally *rocket*? Too much, too little, does the tank
   last the right amount of time?
4. **Engine hum:** does it feel alive now? Anything still missing?
5. **The ship itself:** you said you found other options than a literal space
   truck, and imagine something Cowboy Bebop-sized (room for 4-5 people and
   months of supplies). Could you drop those pictures into a `reference/`
   folder in the project (or describe them)? I'll design the rig's next
   placeholder from them.
