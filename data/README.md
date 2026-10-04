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
  Callers on the comms also live here (Marge at truck stop control, Big
  Wendell, Pip), with their portrait colors and a short `comm_name`.
- **`world_names.tres`**: the big names in one place: the bunny, her
  husband, the base, and what money is called (plus its short form for the
  HUD). Dialogue fills them in where it says `{bunny}`, `{husband}`,
  `{base}` or `{currency}`.
- **`jobs/`**: one file per job: cargo, client, base pay, and the optional
  fragile (care) and rush bonuses. `practice_haul.tres` rides along in the
  flight sandbox for now. Blueprint: `JobData.gd`.
- **`radio/`**: one file per station (name, dial number, placeholder songs,
  fake ads), and `lineup.tres` listing the stations on the dial. No music
  yet; that's M4. Blueprints: `RadioStation.gd`, `RadioLineup.gd`.
- **`dialogue/flight_chatter.tres`**: what people say over the comms while
  you fly, grouped by who says it and when (takeoff, small talk, approach,
  bonks, boosts, low fuel, deliveries). Blueprints: `ChatterSet.gd`,
  `FlightChatter.gd`.
- **`traffic_names.tres`**: the funny names on passing ships' ID labels.
  Add as many as you like.
- **The other folders are empty for now** and fill up as their milestones
  arrive: `upgrades/` (M2), `clients/` (M5, M8), `outfits/` and
  `furniture/` (M7).

The pattern for each folder: one small blueprint script (like `ShipData.gd`)
that defines the fields, plus one `.tres` file per thing (like
`starter_rig.tres`). Adding a new ship or system means duplicating a `.tres`
file and editing it in the Inspector. No code.
