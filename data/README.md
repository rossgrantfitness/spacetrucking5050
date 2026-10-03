# data/

Everything that's *content* rather than *code* lives here, so changing the
game's numbers, names and stuff never needs programming.

- **`tuning.tres`** (with its blueprint `Tuning.gd`): every feel number in the
  game. Double-click it and use the Inspector; hover a value to see what it
  does.
- **The other folders are empty for now** and fill up as their milestones
  arrive: `ships/` and `upgrades/` (M1–M2), `jobs/` (M2), `npcs/` and
  `dialogue/` (M3), `radio/` (M4), `systems/` and `clients/` (M5, M8),
  `outfits/` and `furniture/` (M7).

The pattern for each folder: one small blueprint script (for example
`ShipData.gd`) that defines the fields, plus one `.tres` file per thing (for
example `starter_rig.tres`). Adding a new ship or client means duplicating a
`.tres` file and editing it in the Inspector. No code.
