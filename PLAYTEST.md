# Playtest: M1 (The flight sandbox, "find the heart")

**Goal:** find out whether just *flying around* feels good. This is the heart
of the whole game: if cruising isn't pleasant, nothing built on top of it will
be. There's no job, no money, and no destination to reach yet. It's just you,
the rig, a field of tumbling rocks and a truck stop glowing in the distance.

**Time needed:** 10-15 minutes.

> Honest note: I can check that everything *works* (I flew it on autopilot
> and looked at hundreds of frames), but I can't *feel* it or hear it. Feel is
> your call, and your answers decide whether we tune more before M2.

---

## What to do

1. Press **F5** (Mac: **Cmd+B**). On the boot screen, press **Enter** (or
   **Start** on a gamepad, or click **PRESS START TO FLY**).
2. You're parked behind your rig, the *Lazy Susan*. Hold **W** (or **RT**) to
   push the throttle lever up. The lever stays where you leave it, like cruise
   control, so you don't have to hold anything. **S** (or **LT**) pulls it back.
3. **Put some music on in another app**, then just fly around for five
   minutes. Wander through the asteroid field and head for the **TRUCK STOP**
   (the cyan marker always points the way, even when it's behind you).
4. Try **boost** (**Space** / **A**): a short burst that drains a little tank
   (the inner cyan arc on the speed gauge) and refills on its own.
5. Press **C** (or **Y**) to switch to the **cockpit view**, and again to go
   back.
6. Try steering with the **keyboard**, the **mouse** (it's captured while
   flying, so just move it) and a **gamepad** if you have one.
7. Press **Esc** (or **Start**) for the pause menu. Flip **Invert Y** and
   **Camera roll** on and off to compare. **Back to the start** rescues you if
   you get lost.
8. *Optional, for the curious:* tweak a value and feel the difference. Good
   ones to try: in `data/tuning.tres`, *Chase Camera → Chase Turn Follow*
   (how lazily the camera swings around) and *Flying → Nose Auto Level*; in
   `data/ships/starter_rig.tres`, *Handling → Turn Response* (how heavy the rig
   feels) and *Speed → Max Speed*. The revert arrow puts any value back.

## What to pay attention to

- **Steering:** smooth and buttery, or twitchy? Too slow to respond?
- **Weight:** does the rig feel like a big, heavy truck in a good way, or just
  sluggish?
- **The camera:** comfortable? Any dizziness, or moments where you lose track
  of which way is up?
- **Speed:** do you *feel* fast at cruise (about 200 km/h)? Is boost a fun kick?
- **Sound:** is the engine hum a cozy drone under your music, or annoying?
- **Smoothness:** any stutter or jerky frames?
- Bumping into rocks just slides you along them for now. Cartoon "bonks" come
  in M2.

---

## Questions for you

1. **The big one:** with music playing in another app, is it pleasant to just
   fly around for five minutes? If something broke the spell, what was it?
2. **Handling:** does the rig feel heavy-but-pleasant, or sluggish? Is turning
   too slow, just right, or too twitchy? And the camera swinging in behind you:
   too lazy, too stiff, or right?
3. **Speed:** at cruise, do the dust, rocks and trails make you feel like
   you're moving? Is boost exciting without being too much?
4. **The engine hum:** cozy or annoying? Too loud, too quiet, too deep, too
   whiny?
5. **Left over from M0:** did it all run without red errors, and which
   computer/graphics card are you on? Gamepad or keyboard-and-mouse, which do
   you prefer here? And now that you've flown: should pushing **up** point the
   nose **up** (current default) or **down** (Invert Y)?

*Optional:* if you have mood-board images (cockpits, ships, planets...), drop
them in a folder called `reference/` in the project. I'll study them before
the art pass in M4.
