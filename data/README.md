# data/

Everything that's *content* rather than *code* lives here, so changing the
game's numbers, names and stuff never needs programming.

- **`tuning.tres`** (with its blueprint `Tuning.gd`): every feel number shared
  by all ships: steering, camera, field of view, dust, trails, engine sound.
  Double-click it and use the Inspector; hover a value to see what it does.
- **`ships/`**: one file per ship. `starter_rig.tres` is *The Lazy Susan*,
  your inherited rig: top speed, acceleration, how heavy it turns, boost,
  trail color, engine voice. Its blueprint is `ShipData.gd`.
- **`systems/`**: one file per solar system. `home_system.tres` holds the home
  system's signature color (tints the space dust) and haze color (the
  distance haze faraway things fade into).
  Its blueprint is `SystemData.gd`.
- **`npcs/`**: one file per person on the base: name, voice pitch and what
  they say. `dispatch_morning.tres` is Dottie. Blueprint: `NPCData.gd`.
- **`world_names.tres`**: the big names in one place: the bunny, her
  husband, the base, and what money is called. Dialogue fills them in where
  it says `{bunny}`, `{husband}`, `{base}` or `{currency}`.
- **The other folders are empty for now** and fill up as their milestones
  arrive: `upgrades/` and `jobs/` (M2), `dialogue/` (M3),
  `radio/` (M4), `clients/` (M5, M8), `outfits/` and `furniture/` (M7).

The pattern for each folder: one small blueprint script (like `ShipData.gd`)
that defines the fields, plus one `.tres` file per thing (like
`starter_rig.tres`). Adding a new ship or system means duplicating a `.tres`
file and editing it in the Inspector. No code.
