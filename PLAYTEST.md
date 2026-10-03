# Playtest: M0 (Setup check)

**Goal:** make sure the project opens on *your* computer, and that your
keyboard, mouse and (if you have one) gamepad all reach the game. There's
nothing to "play" yet. This is the plumbing check before we start flying.

**Time needed:** about 10 minutes (plus installing Godot the first time).

---

## What to do

1. Follow steps 1–4 in `HOW_TO_RUN.md`: install Godot 4.7.2, open the
   project, press **F5** (Mac: **Cmd+B**).
2. You should see the title **SPACE TRUCKIN' 5050**, a slowly tumbling orange
   cargo crate, drifting stars, and an **INPUT CHECK** panel.
3. **Keyboard:** press W, A, S, D, the arrow keys, Space, C, E and Esc. The
   matching chips should light up orange while you hold each key.
4. **Mouse:** move the mouse around. The *Mouse steering* gauge's dot should
   follow your hand, then drift gently back to the middle.
5. **Gamepad** (if you have one): plug it in. The top-right of the panel should
   name it. Wiggle both sticks, squeeze both triggers, press A, Y and Start.
   Let go of the left stick: the steering dot should settle dead center.
   Squeeze a trigger slowly: its chip should glow brighter the harder you
   press.
6. Turn **Invert Y** on, watch how the "Ship would: ..." text changes when you
   push up, then close the game and press Play again. The switch should still
   be on, which means saving works. Then set it however you like.
7. **Optional, for fun:** open `data/tuning.tres` (see "Tweaking how things
   feel" in `HOW_TO_RUN.md`), change **Steer Response** to `2`, press Play, and
   move the stick or the arrow keys. The orange dot now drifts lazily after the
   white ring. That's input smoothing, and it'll matter a lot in M1. Click the
   revert arrow to put it back to 10.

## What to pay attention to

- Any **red text** in the Output panel at the bottom of the editor.
- Whether the crate turns **smoothly** (this tells us the 3D renderer is happy
  on your computer).
- Any key or button that **doesn't light up** what you expect.

---

## Questions for you

1. **Did it run?** Any red errors? What do the two small lines at the bottom
   of the boot screen say (Godot version, renderer, graphics card)?
2. **Gamepad:** do you have one you'd like to play with? Which kind (Xbox,
   PlayStation, Switch, other)? Did all the sticks, triggers and buttons light
   up the right chips?
3. **Invert Y:** when you imagine flying, should pushing UP point the nose
   **up** (current default) or **down** like a plane's control stick?
4. **Default controls:** look at the chips and the controls table in
   `HOW_TO_RUN.md`. Does anything feel wrong before we start flying? For
   example: W/S as throttle and Space as boost on keyboard, triggers as
   throttle and A as boost on gamepad, and the mouse for steering.
5. **Vibe check (optional):** anything you love or hate about the boot
   screen's look? It's a placeholder, but your taste steers the art direction.
